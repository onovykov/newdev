public class GenericQueueHardDelete implements Queueable, Database.AllowsCallouts {

    // Параметри
    private String objectApiName;
    private String whereClause;      // без ключового слова WHERE; можна null/порожній
    private Boolean performHardDelete;
    private Integer pageSize;        // 50..1000 рекомендовано 100–500
    private Id lastId;               // курсор пагінації
    private Integer pagesLeft;       // страховка проти нескінченного ланцюжка

    public GenericQueueHardDelete(String objectApiName,
                                  String whereClause,
                                  Boolean performHardDelete,
                                  Integer pageSize) {
        this(objectApiName, whereClause, performHardDelete, pageSize, null, 5000);
    }

    private GenericQueueHardDelete(String objectApiName,
                                   String whereClause,
                                   Boolean performHardDelete,
                                   Integer pageSize,
                                   Id lastId,
                                   Integer pagesLeft) {
        this.objectApiName     = objectApiName;
        this.whereClause       = String.isBlank(whereClause) ? null : whereClause;
        this.performHardDelete = (performHardDelete == null ? true : performHardDelete);
        this.pageSize          = (pageSize == null ? 200 : Math.max(50, Math.min(pageSize, 1000)));
        this.lastId            = lastId;
        this.pagesLeft         = (pagesLeft == null ? 5000 : Math.max(1, pagesLeft));
    }

    public void execute(QueueableContext qc) {
        // 1) Валідація
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        if (!gd.containsKey(objectApiName)) {
            System.debug(LoggingLevel.ERROR, 'Unknown sObject: ' + objectApiName);
            return;
        }
        Schema.DescribeSObjectResult d = gd.get(objectApiName).getDescribe();
        if (!d.isDeletable()) {
            System.debug(LoggingLevel.ERROR, 'sObject is not deletable: ' + objectApiName);
            return;
        }

        // 2) Динамічний SOQL із пагінацією по Id
        //    Використовуємо іншу назву для змінної (не "where"), і додаємо WHERE тільки якщо є фільтри
        List<String> filterParts = new List<String>();
        if (whereClause != null) filterParts.add('(' + whereClause + ')');
        if (lastId != null)      filterParts.add('Id > \'' + String.valueOf(lastId) + '\'');

        String filterSql = filterParts.isEmpty() ? '' : ' WHERE ' + String.join(filterParts, ' AND ');
        String soql = 'SELECT Id FROM ' + objectApiName + filterSql +
                      ' ORDER BY Id ASC LIMIT ' + String.valueOf(pageSize);

        List<SObject> rows = Database.query(soql);
        if (rows.isEmpty()) {
            System.debug(LoggingLevel.INFO, 'No more rows to delete for ' + objectApiName);
            return; // готово
        }

        // 3) Soft delete із частковими успіхами
        Database.DeleteResult[] dr;
        try {
            dr = Database.delete(rows, /*allOrNone*/ false);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Soft delete failed: ' + e.getMessage());
            // Перейдемо до наступної сторінки, щоб не зациклитись на «поганому» чанку
            chainNext(rows);
            return;
        }

        // 4) Зібрати успішні Id для hard delete
        List<Id> ok = new List<Id>();
        for (Integer i = 0; i < dr.size(); i++) {
            if (dr[i].isSuccess()) {
                ok.add((Id)rows[i].get('Id'));
            } else {
                for (Database.Error e : dr[i].getErrors()) {
                    System.debug(LoggingLevel.WARN, 'Delete failed for ' + rows[i].get('Id') + ': ' + e.getMessage());
                }
            }
        }

        // 5) Hard delete (опціонально)
        if (!ok.isEmpty() && performHardDelete) {
            try {
                Database.emptyRecycleBin(ok);
            } catch (Exception e) {
                System.debug(LoggingLevel.WARN, 'emptyRecycleBin failed: ' + e.getMessage());
            }
        }

        // 6) Ланцюжимо наступну сторінку — останній Id як курсор
        chainNext(rows);
    }

    private void chainNext(List<SObject> rowsJustProcessed) {
        // Якщо це, схоже, остання сторінка (менше за pageSize) — не ланцюжимо далі
        if (rowsJustProcessed == null || rowsJustProcessed.isEmpty() || rowsJustProcessed.size() < pageSize) {
            System.debug(LoggingLevel.INFO, 'Last page reached. Stopping chain for ' + objectApiName);
            return;
        }
        if (pagesLeft <= 1) {
            System.debug(LoggingLevel.INFO, 'Page limit reached. Stopping chain for ' + objectApiName);
            return;
        }
        Id newLast = (Id)rowsJustProcessed.get(rowsJustProcessed.size() - 1).get('Id');
        System.enqueueJob(new GenericQueueHardDelete(
            objectApiName, whereClause, performHardDelete, pageSize, newLast, pagesLeft - 1
        ));
    }
}