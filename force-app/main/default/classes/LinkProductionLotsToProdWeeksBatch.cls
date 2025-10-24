global class LinkProductionLotsToProdWeeksBatch implements Database.Batchable<SObject>, Database.Stateful {

    global Database.QueryLocator start(Database.BatchableContext BC) {
        Date minDate = (Date) [
                SELECT MIN(DateFrom__c) minDate
                FROM ProdWeeksH__c
                WHERE Level__c = 3
        ][0].get('minDate');

        return Database.getQueryLocator([
                SELECT Id, LotDate__c
                FROM ProductionLot__c
                WHERE LotDate__c >= :minDate
        ]);
    }

    global void execute(Database.BatchableContext BC, List<ProductionLot__c> scope) {
        // Завантажуємо всі ProdWeeksH__c
        List<ProdWeeksH__c> prodWeeks = [
                SELECT Id, DateFrom__c, DateTo__c
                FROM ProdWeeksH__c
                WHERE DateFrom__c <= :Date.today().addDays(365)
                AND DateTo__c >= :Date.today().addDays(-365)
        ];

        List<ProductionLot__c> lotsToUpdate = new List<ProductionLot__c>();

        for (ProductionLot__c lot : scope) {
            Date lotDate = lot.LotDate__c;
            for (ProdWeeksH__c week : prodWeeks) {
                if (week.DateFrom__c <= lotDate && lotDate <= week.DateTo__c) {
                    lot.ProdWeek__c = week.Id;
                    lotsToUpdate.add(lot);
                    // break; ← видалено, як просив
                }
            }
        }

        if (!lotsToUpdate.isEmpty()) {
            update lotsToUpdate;
        }
    }

    global void finish(Database.BatchableContext BC) {
        System.debug('Batch completed.');
    }
}