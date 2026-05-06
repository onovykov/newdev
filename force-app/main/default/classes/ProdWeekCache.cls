public with sharing class ProdWeekCache {

    private static List<ProdWeeksH__c> weeks;

    public class WeekRec {
        public Date DateFrom {get; set;}
        public Date DateTo {get; set;}
        public String Month {get; set;}
        public Integer Year {get; set;}
        public Integer WeekNum {get; set;}

        public WeekRec() {}

        public WeekRec(
            Date fromDate,
            Date toDate,
            String month,
            Integer year,
            Integer weekNum
        ) {
            this.DateFrom = fromDate;
            this.DateTo = toDate;
            this.Month = month;
            this.Year = year;
            this.WeekNum = weekNum;
        }
    }

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
    //---
    public static WeekRec getRecById(Id targetId) {
        if (targetId == null) {
            return null;
        }
        load();
        for (ProdWeeksH__c week : weeks) {
            if (week.Id == targetId) {
                return new WeekRec(
                    week.DateFrom__c,
                    week.DateTo__c,
                    String.valueOf(week.Month__c),
                    Integer.valueOf(week.Year__c),
                    Integer.valueOf(week.WeekNum__c)
                );
            }
        }
        return null;
    }
    //---
    public static ProdWeeksH__c getRecByDate(Date targetDate) {
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
                return week;
            }
        }
        return null;
    }
     //===== Load all data in the cache ====
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

    //===== Reset cache =======
    @TestVisible
    static void reset() {
        weeks = null;
    }
}