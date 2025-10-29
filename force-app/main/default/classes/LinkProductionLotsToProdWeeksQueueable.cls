// force-app/main/default/classes/LinkProductionLotsToProdWeeksQueueable.cls
public class LinkProductionLotsToProdWeeksQueueable implements Queueable, Database.AllowsCallouts
{
    private final Set<Id> lotIds;
    private final Date fromDate;
    private final Date toDate;
    private final Boolean dryRun;

    public LinkProductionLotsToProdWeeksQueueable() {
        this(null, null, null, true);
    }
    public LinkProductionLotsToProdWeeksQueueable(Set<Id> lotIds, Date fromDate, Date toDate, Boolean dryRun) {
        this.lotIds  = lotIds;
        this.fromDate = fromDate;
        this.toDate   = toDate;
        this.dryRun   = (dryRun == null ? true : dryRun);
    }

    public void execute(QueueableContext qc) {
        System.debug(LoggingLevel.INFO,
            'LinkProductionLotsToProdWeeksQueueable start. lotIds=' + lotIds +
            ', fromDate=' + fromDate + ', toDate=' + toDate + ', dryRun=' + dryRun);

        // 1) Які партії обробляємо
        List<ProductionLot__c> lots = new List<ProductionLot__c>();
        if (lotIds != null && !lotIds.isEmpty()) {
            lots = [
                SELECT Id, LotDate__c, ProdWeek__c
                FROM ProductionLot__c
                WHERE Id IN :lotIds AND LotDate__c != NULL
            ];
        } else {
            Date effectiveFrom = fromDate;
            if (effectiveFrom == null) {
                AggregateResult[] agg = [
                    SELECT MIN(DateFrom__c) minDate
                    FROM ProdWeeksH__c
                    WHERE Level__c = 3
                ];
                effectiveFrom = (Date) (agg.isEmpty() ? null : agg[0].get('minDate'));
            }
            Date effectiveTo = (toDate == null ? Date.today().addDays(365) : toDate);
            if (effectiveFrom == null) {
                System.debug(LoggingLevel.WARN, 'No effectiveFrom date (no ProdWeeksH__c?). Nothing to do.');
                return;
            }
            lots = [
                SELECT Id, LotDate__c, ProdWeek__c
                FROM ProductionLot__c
                WHERE LotDate__c != NULL
                  AND LotDate__c >= :effectiveFrom
                  AND LotDate__c <= :effectiveTo
            ];
        }

        if (lots.isEmpty()) {
            System.debug(LoggingLevel.INFO, 'No production lots to process. Exit.');
            return;
        }

        // 2) Діапазон дат партій
        Date minLotDate = lots[0].LotDate__c;
        Date maxLotDate = lots[0].LotDate__c;
        for (ProductionLot__c l : lots) {
            if (l.LotDate__c < minLotDate) minLotDate = l.LotDate__c;
            if (l.LotDate__c > maxLotDate) maxLotDate = l.LotDate__c;
        }

        // 3) Підтягуємо тижні (Level=3), що перетинають діапазон
        List<ProdWeeksH__c> weeks = [
            SELECT Id, DateFrom__c, DateTo__c
            FROM ProdWeeksH__c
            WHERE Level__c = 3
              AND DateFrom__c <= :maxLotDate
              AND DateTo__c   >= :minLotDate
            ORDER BY DateFrom__c ASC
        ];
        if (weeks.isEmpty()) {
            System.debug(LoggingLevel.WARN,
                'No ProdWeeksH__c(Level=3) for range [' + minLotDate + ' .. ' + maxLotDate + '].');
            return;
        }

        // 4) Обчислюємо оновлення
        List<ProductionLot__c> toUpdate = new List<ProductionLot__c>();
        Integer linked = 0, skippedNoMatch = 0, unchanged = 0;

        for (ProductionLot__c lot : lots) {
            Id matchedWeekId = findWeekIdForDate(weeks, lot.LotDate__c);
            if (matchedWeekId == null) { skippedNoMatch++; continue; }
            if (lot.ProdWeek__c == matchedWeekId) { unchanged++; continue; }
            toUpdate.add(new ProductionLot__c(Id = lot.Id, ProdWeek__c = matchedWeekId));
            linked++;
        }

        System.debug(LoggingLevel.INFO,
            'Lots evaluated=' + lots.size() +
            ', toLink=' + linked + ', unchanged=' + unchanged +
            ', noMatchingWeek=' + skippedNoMatch);

        // 5) DML по чанках
        if (!dryRun && !toUpdate.isEmpty()) {
            updateInChunks(toUpdate, 200);
        } else if (dryRun && !toUpdate.isEmpty()) {
            System.debug(LoggingLevel.INFO, 'DryRun ON — skipping DML. Would update ' + toUpdate.size() + ' lots.');
        }

        System.debug(LoggingLevel.INFO, 'LinkProductionLotsToProdWeeksQueueable finished.');
    }

    private static Id findWeekIdForDate(List<ProdWeeksH__c> weeks, Date d) {
        for (ProdWeeksH__c w : weeks) {
            if (w.DateFrom__c <= d && d <= w.DateTo__c) return w.Id;
        }
        return null;
    }

    private static void updateInChunks(List<ProductionLot__c> rows, Integer chunkSize) {
        Integer i = 0;
        Integer n = rows.size();
        while (i < n) {
            Integer endIdx = i + chunkSize;
            if (endIdx > n) endIdx = n;

            // формуємо "зріз" вручну
            List<ProductionLot__c> slice = new List<ProductionLot__c>();
            for (Integer j = i; j < endIdx; j++) {
                slice.add(rows[j]);
            }

            Database.SaveResult[] sr = Database.update(slice, false);
            for (Integer k = 0; k < sr.size(); k++) {
                if (!sr[k].isSuccess()) {
                    Database.Error e = sr[k].getErrors()[0];
                    System.debug(LoggingLevel.ERROR,
                        'Update failed for lotId=' + slice[k].Id + ': ' + e.getStatusCode() + ' - ' + e.getMessage());
                }
            }
            i = endIdx;
        }
    }
}