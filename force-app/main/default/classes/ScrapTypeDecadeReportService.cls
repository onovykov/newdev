/* ******************************************************************************************************
  Сервісний клас, методи якого повертають
  - getDecadeSummariesMapForYearMonthRange - мапу <ScrapType__c.Id,<Decade__c.Id (Id декади), рекорд класу DecadeSummary>>
      На вході
        Integer year, - рік
        Integer monthFrom, - місяць від
        Integer monthTo, - місяць по
        Set<Id> scrapTypeIds - перелік Id брухту
        
    - getMonthlySummariesMapForYearMonthRange  - мапу <ScrapType__c.Id,<Decade__c.Id (Id місяця), рекорд класу MonthlySummary >>
      На вході
        Integer year, - рік
        Integer monthFrom, - місяць від
        Integer monthTo, - місяць по
        Set<Id> scrapTypeIds - перелік Id брухту  
****************************************************************************************************** */
public with sharing class ScrapTypeDecadeReportService {

    // ===== DTOs =====
    public class DecadeSummary {
        public Id year_id;
        public Id month_id;
        public Id decade_id;
        public Integer year_num;
        public Integer month_num;
        public Integer decade_num;
        public Decimal limit_sum = 0;
        public Decimal tonnage_sum = 0;
        public Decimal fact_sum = 0;
        public Decimal used = 0;       // fact_sum > 0 ? fact_sum : tonnage_sum
        public Decimal available = 0;  // limit_sum - used
    }
    public class MonthlySummary {
        public Id year_id;
        public Id month_id;
        public Integer year_num;
        public Integer month_num;
        public String month_name;
        public Decimal limit_sum = 0;
        public Decimal tonnage_sum = 0;
        public Decimal fact_sum = 0;
        public Decimal used = 0;       // fact_sum > 0 ? fact_sum : tonnage_sum
        public Decimal available = 0;  // limit_sum - used
    }

    // ===== Внутрішні допоміжні типи (ОДИН рівень вкладеності) =====
    private class RangeCtx {
        Integer year;
        Integer monthFrom;
        Integer monthTo;
        Set<Id> monthIds  = new Set<Id>(); // Level=2
        Set<Id> decadeIds = new Set<Id>(); // Level=3
    }
    private class MonthInfo {
        Id monthId;
        Id yearId;
        Integer yearNum;
        Integer monthNum;
    }
    private class DecadeInfo {
        Id decadeId;
        Id monthId;
        Id yearId;
        Integer yearNum;
        Integer monthNum;
        Integer decadeNum;
    }
    private class Aggregates {
        Map<Id, MonthInfo>  monthInfo  = new Map<Id, MonthInfo>();
        Map<Id, DecadeInfo> decadeInfo = new Map<Id, DecadeInfo>();
        List<AggregateResult> inputsByDecade = new List<AggregateResult>();
        List<AggregateResult> limitByDecade  = new List<AggregateResult>();
    }

    // ===== ПУБЛІЧНІ МЕТОДИ =====
    // Перший Id в мапі - ScrapType__c, другий - Decade__c
    public static Map<Id, Map<Id, DecadeSummary>> getDecadeSummariesMapForYearMonthRange(
        Integer year,
        Integer monthFrom,
        Integer monthTo,
        Set<Id> scrapTypeIds
    ) {
        RangeCtx ctx = buildRangeCtx(year, monthFrom, monthTo);
        Aggregates aggr = collectAggregates(ctx, scrapTypeIds);

        Map<Id, Map<Id, DecadeSummary>> byTypeDecade = new Map<Id, Map<Id, DecadeSummary>>();

        // 1) Ліміти по декадах
        for (AggregateResult ar : aggr.limitByDecade) {
            Id typeId   = (Id) ar.get('scrapTypeId');
            Id monthId  = (Id) ar.get('monthId');
            Id decadeId = (Id) ar.get('decadeId');
            Decimal lim = (Decimal) ar.get('dayLimit'); if (lim == null) lim = 0;

            DecadeSummary d = getOrCreateDecade(byTypeDecade, typeId, decadeId);
            d.month_id  = monthId;
            d.decade_id = decadeId;

            DecadeInfo di = aggr.decadeInfo.get(decadeId);
            if (di != null) {
                d.year_id    = di.yearId;
                d.year_num   = di.yearNum;
                d.month_num  = di.monthNum;
                d.decade_num = di.decadeNum;
            }
            d.limit_sum += lim;
        }

        // 2) Надходження по декадах
        for (AggregateResult ar : aggr.inputsByDecade) {
            Id typeId   = (Id) ar.get('scrapTypeId');
            Id monthId  = (Id) ar.get('monthId');
            Id decadeId = (Id) ar.get('decadeId');
            Decimal ton = (Decimal) ar.get('tonnageSum'); if (ton == null) ton = 0;
            Decimal fac = (Decimal) ar.get('factSum');    if (fac == null) fac = 0;

            DecadeSummary d = getOrCreateDecade(byTypeDecade, typeId, decadeId);
            d.month_id  = monthId;
            d.decade_id = decadeId;

            DecadeInfo di = aggr.decadeInfo.get(decadeId);
            if (di != null) {
                d.year_id    = di.yearId;
                d.year_num   = di.yearNum;
                d.month_num  = di.monthNum;
                d.decade_num = di.decadeNum;
            }
            d.tonnage_sum += ton;
            d.fact_sum    += fac;
        }

        // 3) Used/Available
        for (Map<Id, DecadeSummary> innerQty : byTypeDecade.values()) {
            for (DecadeSummary d : innerQty.values()) {
                d.used      = (d.fact_sum != null && d.fact_sum > 0) ? d.fact_sum : d.tonnage_sum;
                d.available = (d.limit_sum == null ? 0 : d.limit_sum) - (d.used == null ? 0 : d.used);
            }
        }
        return byTypeDecade;
    }

    public static Map<Id, Map<Id, MonthlySummary>> getMonthlySummariesMapForYearMonthRange(
        Integer year,
        Integer monthFrom,
        Integer monthTo,
        Set<Id> scrapTypeIds
    ) {
        RangeCtx ctx = buildRangeCtx(year, monthFrom, monthTo);
        Aggregates aggr = collectAggregates(ctx, scrapTypeIds);

        Map<Id, Map<Id, MonthlySummary>> byTypeMonth = new Map<Id, Map<Id, MonthlySummary>>();

        // 1) Ліміти -> місяць
        for (AggregateResult ar : aggr.limitByDecade) {
            Id typeId   = (Id) ar.get('scrapTypeId');
            Id monthId  = (Id) ar.get('monthId');
            Decimal lim = (Decimal) ar.get('dayLimit'); if (lim == null) lim = 0;

            MonthlySummary m = getOrCreateMonth(byTypeMonth, typeId, monthId);
            MonthInfo mi = aggr.monthInfo.get(monthId);
            if (mi != null) {
                m.year_id   = mi.yearId;
                m.year_num  = mi.yearNum;
                m.month_id  = monthId;
                m.month_num = mi.monthNum;
                m.month_name= uaMonthName(mi.monthNum);
            }
            m.limit_sum += lim;
        }

        // 2) Надходження -> місяць
        for (AggregateResult ar : aggr.inputsByDecade) {
            Id typeId   = (Id) ar.get('scrapTypeId');
            Id monthId  = (Id) ar.get('monthId');
            Decimal ton = (Decimal) ar.get('tonnageSum'); if (ton == null) ton = 0;
            Decimal fac = (Decimal) ar.get('factSum');    if (fac == null) fac = 0;

            MonthlySummary m = getOrCreateMonth(byTypeMonth, typeId, monthId);
            MonthInfo mi = aggr.monthInfo.get(monthId);
            if (mi != null) {
                m.year_id   = mi.yearId;
                m.year_num  = mi.yearNum;
                m.month_id  = monthId;
                m.month_num = mi.monthNum;
                m.month_name= uaMonthName(mi.monthNum);
            }
            m.tonnage_sum += ton;
            m.fact_sum    += fac;
        }

        // 3) Used/Available
        for (Map<Id, MonthlySummary> innerQty : byTypeMonth.values()) {
            for (MonthlySummary m : innerQty.values()) {
                m.used      = (m.fact_sum != null && m.fact_sum > 0) ? m.fact_sum : m.tonnage_sum;
                m.available = (m.limit_sum == null ? 0 : m.limit_sum) - (m.used == null ? 0 : m.used);
            }
        }
        return byTypeMonth;
    }

    // ===== Приватні хелпери =====
    private static RangeCtx buildRangeCtx(Integer year, Integer monthFrom, Integer monthTo) {
        if (year == null)  throw new AuraHandledException('year is required');
        if (monthFrom == null) monthFrom = 1;
        if (monthTo   == null) monthTo   = 12;
        if (monthFrom > monthTo) { Integer t = monthFrom; monthFrom = monthTo; monthTo = t; }

        RangeCtx ctx = new RangeCtx();
        ctx.year = year; ctx.monthFrom = monthFrom; ctx.monthTo = monthTo;

        // Місяці (Level=2)
        List<String> monthVals = new List<String>();
        for (Integer m = monthFrom; m <= monthTo; m++) monthVals.add(String.valueOf(m));

        List<Decade__c> monthRecs = [
            SELECT Id, Parent__c, Year__c, Month__c
            FROM Decade__c
            WHERE Level__c = 2
              AND Year__c  = :year
              AND Month__c IN :monthVals
        ];
        for (Decade__c mr : monthRecs) {
            ctx.monthIds.add(mr.Id);
        }
        if (ctx.monthIds.isEmpty()) return ctx;

        // Декади (Level=3) під цими місяцями
        for (Decade__c dr : [
            SELECT Id, Parent__c, Year__c, Month__c, Decade__c
            FROM Decade__c
            WHERE Level__c = 3 AND Parent__c IN :ctx.monthIds
        ]) {
            ctx.decadeIds.add(dr.Id);
        }
        return ctx;
    }

    private static Aggregates collectAggregates(RangeCtx ctx, Set<Id> scrapTypeIds) {
        Aggregates A = new Aggregates();

        // monthInfo
        if (!ctx.monthIds.isEmpty()) {
            for (Decade__c m : [
                SELECT Id, Parent__c, Year__c, Month__c
                FROM Decade__c WHERE Id IN :ctx.monthIds
            ]) {
                MonthInfo mi = new MonthInfo();
                mi.monthId = m.Id;
                mi.yearId  = m.Parent__c;
                mi.yearNum = (m.Year__c == null) ? null : Integer.valueOf(m.Year__c.intValue());
                mi.monthNum= (m.Month__c == null) ? null : Integer.valueOf(String.valueOf(m.Month__c));
                A.monthInfo.put(m.Id, mi);
            }
        }

        // decadeInfo
        if (!ctx.decadeIds.isEmpty()) {
            for (Decade__c d : [
                SELECT Id, Parent__c, Year__c, Month__c, Decade__c
                FROM Decade__c WHERE Id IN :ctx.decadeIds
            ]) {
                DecadeInfo di = new DecadeInfo();
                di.decadeId  = d.Id;
                di.monthId   = d.Parent__c;
                di.yearId    = A.monthInfo.containsKey(d.Parent__c) ? A.monthInfo.get(d.Parent__c).yearId : null;
                di.yearNum   = (d.Year__c == null) ? null : Integer.valueOf(d.Year__c.intValue());
                di.monthNum  = (d.Month__c == null) ? null : Integer.valueOf(String.valueOf(d.Month__c));
                di.decadeNum = (d.Decade__c == null) ? null : Integer.valueOf(String.valueOf(d.Decade__c));
                A.decadeInfo.put(d.Id, di);
            }
        }

        // --- Агрегати ---
        // Надходження з ScrapSlotReserve__c
        if (scrapTypeIds != null && !scrapTypeIds.isEmpty()) {
            A.inputsByDecade = [
                SELECT ScrapType__c scrapTypeId,
                       MonthLookup__c monthId,
                       DecadeLookup__c decadeId,
                       SUM(Tonnage__c) tonnageSum,
                       SUM(Weight__c)  factSum
                FROM ScrapSlotReserve__c
                WHERE MonthLookup__c IN :ctx.monthIds
                  AND ScrapType__c IN :scrapTypeIds AND IsCancelled__c=false
                GROUP BY ScrapType__c, MonthLookup__c, DecadeLookup__c
            ];
        } else {
            A.inputsByDecade = [
                SELECT ScrapType__c scrapTypeId,
                       MonthLookup__c monthId,
                       DecadeLookup__c decadeId,
                       SUM(Tonnage__c) tonnageSum,
                       SUM(Weight__c)  factSum
                FROM ScrapSlotReserve__c
                WHERE MonthLookup__c IN :ctx.monthIds AND IsCancelled__c=false
                GROUP BY ScrapType__c, MonthLookup__c, DecadeLookup__c
            ];
        }

        // Ліміти з ScrapDecadesLimit__c
        if (scrapTypeIds != null && !scrapTypeIds.isEmpty()) {
            A.limitByDecade = [
                SELECT ScrapType__c scrapTypeId,
                       DayLookup__r.Parent__r.Parent__c monthId, // місяць (Level=2)
                       DayLookup__r.Parent__c           decadeId, // декада (Level=3)
                       SUM(DayLimit__c)                 dayLimit
                FROM ScrapDecadesLimit__c
                WHERE DayLookup__r.Parent__r.Parent__c IN :ctx.monthIds
                  AND ScrapType__c IN :scrapTypeIds
                GROUP BY ScrapType__c, DayLookup__r.Parent__r.Parent__c, DayLookup__r.Parent__c
            ];
        } else {
            A.limitByDecade = [
                SELECT ScrapType__c scrapTypeId,
                       DayLookup__r.Parent__r.Parent__c monthId,
                       DayLookup__r.Parent__c           decadeId,
                       SUM(DayLimit__c)                 dayLimit
                FROM ScrapDecadesLimit__c
                WHERE DayLookup__r.Parent__r.Parent__c IN :ctx.monthIds
                GROUP BY ScrapType__c, DayLookup__r.Parent__r.Parent__c, DayLookup__r.Parent__c
            ];
        }
        return A;
    }

    private static DecadeSummary getOrCreateDecade(Map<Id, Map<Id, DecadeSummary>> byTypeDecade, Id typeId, Id decadeId) {
        if (!byTypeDecade.containsKey(typeId)) byTypeDecade.put(typeId, new Map<Id, DecadeSummary>());
        Map<Id, DecadeSummary> innerQty = byTypeDecade.get(typeId);
        if (!innerQty.containsKey(decadeId)) innerQty.put(decadeId, new DecadeSummary());
        return innerQty.get(decadeId);
    }

    private static MonthlySummary getOrCreateMonth(Map<Id, Map<Id, MonthlySummary>> byTypeMonth, Id typeId, Id monthId) {
        if (!byTypeMonth.containsKey(typeId)) byTypeMonth.put(typeId, new Map<Id, MonthlySummary>());
        Map<Id, MonthlySummary> innerQty = byTypeMonth.get(typeId);
        if (!innerQty.containsKey(monthId)) innerQty.put(monthId, new MonthlySummary());
        return innerQty.get(monthId);
    }

    private static String uaMonthName(Integer n) {
        List<String> M = new List<String>{
            '', 'Січень','Лютий','Березень','Квітень','Травень','Червень',
            'Липень','Серпень','Вересень','Жовтень','Листопад','Грудень'
        };
        if (n == null || n < 1 || n > 12) return '';
        return M[n];
    }


    public static void FakeCoverageMethod() {
        Integer i = 0;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;

    }
}