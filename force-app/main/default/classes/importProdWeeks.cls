
public static void importProdWeeks(String jsonString) {
        // Розбираємо JSON в DTO
        ProdWeeksDTO dto = (ProdWeeksDTO) JSON.deserialize(jsonString, ProdWeeksDTO.class);
        List<ProdWeeksH__c> recordsToInsert = new List<ProdWeeksH__c>();
        // ID головного запису
        Map<String, Id> idMap = new Map<String, Id>();
        // Створюємо кореневий запис "MAIN" - якщо його ще немає
        List<ProdWeeksH__c> pwMain = [SELECT Id FROM ProdWeeksH__c
                                      WHERE ItemId__c='MAIN' AND Level__c=0 LIMIT 1];
        if(pwMain.isEmpty()) {
            ProdWeeksH__c mainRec = new ProdWeeksH__c(ItemId__c = 'MAIN', Name='PRODUCTION WEEKS', Level__c=0, ParentId__c = null);
            insert mainRec;
            // Зберігаємо ID головного запису
            idMap.put('MAIN', mainRec.Id);
        } esle {
            idMap.put('MAIN', pwMain[0].Id);
        }
        // Перевіряємо, чи є такий рік у ProdWeeksH__c
        List<ProdWeeksH__c> curYearList = [SELECT Id FROM ProdWeeksH__c
                                           WHERE ItemId__c='2025' AND Level__c=1 LIMIT 1];
        // Такого року ще немає - додаємо тижні                                   
        if(curYearList.isEmpty()) {
            // Обробляємо кожен рік (GODMEC)
            for (Object item : dataList) {
                Map<String, Object> yearData = (Map<String, Object>) item;
                String godmec = String.valueOf(yearData.get('GODMEC'));

                ProdWeeksH__c yearRec = new ProdWeeksH__c(
                    ItemId__c = godmec,
                    ParentId__c = idMap.get('MAIN'),
                    Year__c = Integer.valueOf(godmec.substring(0, 4))
                );
                recordsToInsert.add(yearRec);
                idMap.put(godmec, yearRec.Id);

                // Отримуємо всі тижні
                List<Object> weeks = (List<Object>) yearData.get('Weeks');
                for (Object weekItem : weeks) {
                    Map<String, Object> weekData = (Map<String, Object>) weekItem;
                    Integer weekNum = Integer.valueOf(weekData.get('NWEEK'));
                    Date dateFrom = Date.valueOf(String.valueOf(weekData.get('DATN')));
                    Date dateTo = Date.valueOf(String.valueOf(weekData.get('DATK')));

                    String weekId = godmec + '_' + weekNum;

                    ProdWeeksH__c weekRec = new ProdWeeksH__c(
                        ItemId__c = weekId,
                        ParentId__c = idMap.get(godmec),
                        DateFrom__c = dateFrom,
                        DateTo__c = dateTo,
                        Year__c = Integer.valueOf(godmec.substring(0, 4)),
                        Month__c = Integer.valueOf(godmec.substring(4, 6)),
                        WeekNum__c = weekNum
                    );
                    recordsToInsert.add(weekRec);
                }
            }
            // Вставляємо всі записи
            insert recordsToInsert;
        }
    }
}