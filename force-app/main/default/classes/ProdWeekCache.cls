public with sharing class ProdWeekCache {

    private static List<ProdWeeksH__c> weeks;

    public static Id getByDate(Date targetDate) {
        if (targetDate == null) {
            return null;
        }

        load();

        for (ProdWeeksH__c week : weeks) {
            if (
                week.DateFrom__c != null &&
                week.DateTo__c != null &&
                targetDate >= week.DateFrom__c &&
                targetDate <= week.DateTo__c
            ) {
                return week.Id;
            }
        }

        return null;
    }

    @TestVisible
    private static void load() {
        if (weeks != null) {
            return;
        }

        weeks = [
            SELECT Id, DateFrom__c, DateTo__c, Month__c, Year__c, WeekNum__c
            FROM ProdWeeksH__c
            WHERE DateFrom__c != null
              AND DateTo__c != null
            ORDER BY DateFrom__c ASC
        ];
    }

    @TestVisible
    static void reset() {
        weeks = null;
    }
}