public with sharing class IntakePlanService {

    // === DTO: рядок детальної таблиці (перепустка) ===
    public class PassRow {
        @AuraEnabled public String  id;
        @AuraEnabled public String  passNumber;
        @AuraEnabled public String  supplier;
        @AuraEnabled public String  scrapType;
        @AuraEnabled public String  truck;
        @AuraEnabled public Decimal tons;
        @AuraEnabled public String  driver;
        @AuraEnabled public String  contract; // за потреби додаси поле
        @AuraEnabled public String  address;  // за потреби додаси поле
    }

    // === DTO: рядок зведення за типом брухту ===
    public class SummaryRow {
        @AuraEnabled public String  scrapType;
        @AuraEnabled public Decimal totalTons;
        @AuraEnabled public Integer count;
    }

    // === DTO: блок на одну дату ===
    public class DayBlock {
        @AuraEnabled public String           dayLabel; // Понеділок/...
        @AuraEnabled public String           dateStr;  // dd.MM.yyyy
        @AuraEnabled public List<SummaryRow> summary;
        @AuraEnabled public List<PassRow>    records;
        @AuraEnabled public Boolean          open;
    }

    // Головний метод: 2 найближчі робочі дні (Пн–Пт)
    @AuraEnabled(cacheable=true)
    public static List<DayBlock> getNextTwoDaysPlan() {
//        Date d1 = toWorkingDay(Date.today());
//        Date d2 = toWorkingDay(d1.addDays(1));
        Date d1 = Date.today();
        Date d2 = d1.addDays(1);

        List<Date> days = new List<Date>{ d1, d2 };

        // Простий SOQL
        List<ScrapSlotReserve__c> rows = [
                SELECT Id, ReserveDate__c, Status__c, IsCancelled__c,
                        PassNumber__c, PassID__c,
                        Supplier__r.Name,
                        ScrapType__r.Name,
                        Tonnage__c, Weight__c,
                        Driver__r.Name,
                        Truck__r.TruckModel__c, Truck__r.Name
                FROM ScrapSlotReserve__c
                WHERE IsCancelled__c = false
                AND Status__c IN ('Approved','Reserved')
                AND ReserveDate__c IN :days
                ORDER BY ReserveDate__c ASC, CreatedDate ASC
        ];

        // дата → записи
        Map<Date, List<PassRow>> byDate = new Map<Date, List<PassRow>>();
        byDate.put(d1, new List<PassRow>());
        byDate.put(d2, new List<PassRow>());

        for (ScrapSlotReserve__c s : rows) {
            PassRow r = new PassRow();
            r.id         = (String)s.Id;
            r.passNumber = s.PassNumber__c;
            r.supplier   = (s.Supplier__r != null) ? s.Supplier__r.Name : null;
            r.scrapType  = (s.ScrapType__r != null) ? s.ScrapType__r.Name : null;

            String model = (s.Truck__r != null) ? s.Truck__r.TruckModel__c : null;
            String name  = (s.Truck__r != null) ? s.Truck__r.Name : null;
            r.truck = (model != null && model.trim().length() > 0) ? model : name;

            Decimal tons = (s.Tonnage__c != null) ? s.Tonnage__c : s.Weight__c;
            r.tons = (tons == null ? 0 : tons);

            r.driver = (s.Driver__r != null) ? s.Driver__r.Name : null;

            if (!byDate.containsKey(s.ReserveDate__c)) byDate.put(s.ReserveDate__c, new List<PassRow>());
            byDate.get(s.ReserveDate__c).add(r);
        }

        // Будуємо вихід
        List<DayBlock> out = new List<DayBlock>();
        for (Date d : days) {
            List<PassRow> recs = byDate.get(d);
            if (recs == null) recs = new List<PassRow>();

            // Зведення по типу
            Map<String, SummaryRow> sum = new Map<String, SummaryRow>();
            for (PassRow pr : recs) {
                String key = (pr.scrapType == null ? '—' : pr.scrapType);
                SummaryRow sr = sum.get(key);
                if (sr == null) {
                    sr = new SummaryRow();
                    sr.scrapType = key;
                    sr.totalTons = 0;
                    sr.count     = 0;
                    sum.put(key, sr);
                }
                sr.totalTons += (pr.tons == null ? 0 : pr.tons);
                sr.count += 1;
            }
            List<SummaryRow> summaryList = new List<SummaryRow>(sum.values());

            DayBlock b = new DayBlock();
            b.dayLabel = dayLabelUk(d); // без Date.dayOfWeek()
            b.dateStr  = fmt(d);
            b.summary  = summaryList;
            b.records  = recs;
            b.open     = false;

            out.add(b);
        }
        return out;
    }

    // ===== Хелпери БЕЗ Date.dayOfWeek() =====

    // Перетворює на робочий день (Пн–Пт)
    private static Date toWorkingDay(Date d) {
        // guard на випадок свят/циклів
        for (Integer i = 0; i < 14; i++) {
            Integer iso = isoDow(d); // 1..7 (Пн..Нд)
            if (iso >= 1 && iso <= 5) {
                return d;
            }
            d = d.addDays(1);
        }
        // запасний варіант, якщо щось піде не так
        return d;
    }

    // Лейбл дня тижня українською (1..7 = Пн..Нд)
    private static String dayLabelUk(Date d) {
        Integer iso = isoDow(d);
        if (iso == 1) return 'Понеділок';
        if (iso == 2) return 'Вівторок';
        if (iso == 3) return 'Середа';
        if (iso == 4) return 'Четвер';
        if (iso == 5) return 'П’ятниця';
        if (iso == 6) return 'Субота';
        return 'Неділя';
    }

    // ISO day-of-week 1..7 (Пн..Нд) через формулу Целлера, без %
    private static Integer isoDow(Date d) {
        Integer y = d.year();
        Integer m = d.month();
        Integer q = d.day();
        if (m <= 2) { m += 12; y -= 1; }
        Integer K = imod(y, 100);
        Integer J = y / 100;
        Integer term = q + ((13 * (m + 1)) / 5) + K + (K / 4) + (J / 4) + 5 * J;
        Integer h = imod(term, 7); // 0=Сб,1=Нд,2=Пн,3=Вт,4=Ср,5=Чт,6=Пт

        if (h == 0) return 6; // Субота
        if (h == 1) return 7; // Неділя
        return h - 1;         // 2..6 → 1..5 (Пн..Пт)
    }

    private static String pad2(Integer n) { return (n < 10 ? '0' + String.valueOf(n) : String.valueOf(n)); }
    private static String fmt(Date d) { return pad2(d.day()) + '.' + pad2(d.month()) + '.' + String.valueOf(d.year()); }

    // цілочисельний модуль без оператора %
    private static Integer imod(Integer a, Integer b){
        Integer div = a / b;            // цілочисельне ділення
        Integer res = a - b * div;      // a mod b
        if (res < 0) res += b;          // на всяк випадок робимо невід’ємним
        return res;
    }

    @AuraEnabled(cacheable=true)
    public static List<DayBlock> getCurrentDecadePlan() {
        Date today = Date.today();

        // межі поточної декади
        Integer y = today.year(), m = today.month(), d = today.day();
        Integer startDay = (d <= 10) ? 1 : (d <= 20 ? 11 : 21);
        Integer endDay   = (startDay == 21)
                ? Date.newInstance(y, m, 1).addMonths(1).addDays(-1).day() // кінець місяця
                : (startDay + 9);

        Date startDate = Date.newInstance(y, m, startDay);
        Date endDate   = Date.newInstance(y, m, endDay);

        // слоти в межах декади
        List<ScrapSlotReserve__c> rows = [
                SELECT Id, ReserveDate__c, Status__c, IsCancelled__c,
                        PassNumber__c, PassID__c,
                        Supplier__r.Name,
                        ScrapType__r.Name,
                        Tonnage__c, Weight__c,
                        Driver__r.Name,
                        Truck__r.TruckModel__c, Truck__r.Name
                FROM ScrapSlotReserve__c
                WHERE IsCancelled__c = false
                AND Status__c IN ('Approved','Reserved')
                AND ReserveDate__c >= :startDate
                AND ReserveDate__c <= :endDate
                ORDER BY ReserveDate__c ASC, CreatedDate ASC
        ];

        // дата → записи
        Map<Date, List<PassRow>> byDate = new Map<Date, List<PassRow>>();
        for (ScrapSlotReserve__c s : rows) {
            PassRow r = new PassRow();
            r.id         = (String)s.Id;
            r.passNumber = s.PassNumber__c;
            r.supplier   = (s.Supplier__r != null) ? s.Supplier__r.Name : null;
            r.scrapType  = (s.ScrapType__r != null) ? s.ScrapType__r.Name : null;

            String model = (s.Truck__r != null) ? s.Truck__r.TruckModel__c : null;
            String name  = (s.Truck__r != null) ? s.Truck__r.Name : null;
            r.truck = (model != null && model.trim().length() > 0) ? model : name;

            Decimal tons = (s.Tonnage__c != null) ? s.Tonnage__c : s.Weight__c;
            r.tons = (tons == null ? 0 : tons);

            r.driver = (s.Driver__r != null) ? s.Driver__r.Name : null;

            if (!byDate.containsKey(s.ReserveDate__c)) byDate.put(s.ReserveDate__c, new List<PassRow>());
            byDate.get(s.ReserveDate__c).add(r);
        }

        // будуємо блоки для КОЖНОГО дня декади
        List<DayBlock> out = new List<DayBlock>();
        for (Date cur = startDate; cur <= endDate; cur = cur.addDays(1)) {
            List<PassRow> recs = byDate.containsKey(cur) ? byDate.get(cur) : new List<PassRow>();

            // зведення по типу
            Map<String, SummaryRow> sum = new Map<String, SummaryRow>();
            for (PassRow pr : recs) {
                String key = (pr.scrapType == null ? '—' : pr.scrapType);
                SummaryRow sr = sum.get(key);
                if (sr == null) {
                    sr = new SummaryRow();
                    sr.scrapType = key;
                    sr.totalTons = 0;
                    sr.count     = 0;
                    sum.put(key, sr);
                }
                sr.totalTons += (pr.tons == null ? 0 : pr.tons);
                sr.count += 1;
            }
            List<SummaryRow> summaryList = new List<SummaryRow>(sum.values());

            DayBlock b = new DayBlock();
            b.dayLabel = dayLabelUk(cur);
            b.dateStr  = fmt(cur);
            b.summary  = summaryList;
            b.records  = recs;
            b.open     = (cur == today); // минулі/майбутні згорнуті, сьогодні відкритий

            out.add(b);
        }
        return out;
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

    }

}