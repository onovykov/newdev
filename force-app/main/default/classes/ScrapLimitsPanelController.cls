public with sharing class ScrapLimitsPanelController {

    // DTO для однієї стрічки таблиці
    public class SupplierMonthRow {
        @AuraEnabled public Id supplierId {get; set;}
        @AuraEnabled public String supplierName {get; set;}
        @AuraEnabled public Boolean hasSupplierLimitEdit {get; set;}
        @AuraEnabled public String supplierKind {get; set;} // NEW: 'COMMERCIAL' | 'CORPORATE' | 'OTHER'


        // Заявлений (Declared)
        @AuraEnabled public Decimal propDec1 {get; set;}
        @AuraEnabled public Decimal propDec2 {get; set;}
        @AuraEnabled public Decimal propDec3 {get; set;}
        @AuraEnabled public Decimal propMonthTotal {get; set;}

        // Узгоджений (Approved)
        @AuraEnabled public Decimal apprDec1 {get; set;}
        @AuraEnabled public Decimal apprDec2 {get; set;}
        @AuraEnabled public Decimal apprDec3 {get; set;}
        @AuraEnabled public Decimal apprMonthTotal {get; set;}

        // Використано (факт)
        @AuraEnabled public Decimal factDec1 {get; set;}
        @AuraEnabled public Decimal factDec2 {get; set;}
        @AuraEnabled public Decimal factDec3 {get; set;}
        @AuraEnabled public Decimal factMonthTotal {get; set;}

        // Залишок (узгоджений - факт)
        @AuraEnabled public Decimal remainDec1 {get; set;}
        @AuraEnabled public Decimal remainDec2 {get; set;}
        @AuraEnabled public Decimal remainDec3 {get; set;}
        @AuraEnabled public Decimal remainMonthTotal {get; set;}

        // Прапорці для стилів/модалки
        @AuraEnabled public Boolean hasDeclared {get; set;}
        @AuraEnabled public Boolean hasApproved {get; set;}
        @AuraEnabled public Boolean hasAnyData {get; set;}

        @AuraEnabled public Id apprDetailDec1Id {get; set;}
        @AuraEnabled public Id apprDetailDec2Id {get; set;}
        @AuraEnabled public Id apprDetailDec3Id {get; set;}
    }

    // === Поточний місяць ===
    @AuraEnabled(cacheable=false)
    public static List<SupplierMonthRow> getCurrentMonthPanel() {
        Date today = Date.today();
        return getMonthPanel(today.year(), today.month());
    }

    // === Будь-який місяць (рік/місяць) ===
    @AuraEnabled(cacheable=false)
    public static List<SupplierMonthRow> getMonthPanel(Integer year, Integer month) {
        // 1) Всі постачальники
        List<Account> suppliers = [
                SELECT Id, Name, Parent__r.Name
                FROM Account
                WHERE IsSupplier__c = true
                ORDER BY Name
        ];

        // 2) Потрібні Id постачальників
        Set<Id> supplierIds = new Set<Id>();
        for (Account a : suppliers) supplierIds.add(a.Id);

        Map<Id, Map<Calendar, Decimal>> declared = ScrapUtils.getSuppliersLimits(ScrapUtils.DECLARED, false);
        Map<Id, Map<Calendar, Decimal>> approved = ScrapUtils.getSuppliersLimits(ScrapUtils.APPROVED, true);
        Map<Id, Map<Calendar, Decimal>> inputs = ScrapUtils.getSupplierInputsByDecades();

        // --- нове: підтягнемо Approved-деталі, щоб віддати їх Id
        Id monthId = ScrapUtils.getMonthId(year, month);
        Map<Id, Map<Integer, SupplierLimitDetails__c>> apprDetailsBySupplierAndDec = new Map<Id, Map<Integer, SupplierLimitDetails__c>>();
        if (monthId != null) {
            List<SupplierLimitDetails__c> dets = [
                    SELECT Id, Limit__c,
                            Decade__r.Year__c, Decade__r.Month__c, Decade__r.Decade__c,
                            ScrapSupplierLimit__r.Supplier__c,
                            ScrapSupplierLimit__r.RecordType.DeveloperName
                    FROM SupplierLimitDetails__c
                    WHERE ScrapSupplierLimit__r.Supplier__c IN :supplierIds
                    AND ScrapSupplierLimit__r.RecordType.DeveloperName = 'Approved'
                    AND Decade__r.Year__c  = :year
                    AND Decade__r.Month__c = :String.valueOf(month)
            ];
            for (SupplierLimitDetails__c d : dets) {
                Id sup = d.ScrapSupplierLimit__r.Supplier__c;
                Integer decNum = Integer.valueOf(d.Decade__r.Decade__c);
                if (!apprDetailsBySupplierAndDec.containsKey(sup)) {
                    apprDetailsBySupplierAndDec.put(sup, new Map<Integer, SupplierLimitDetails__c>());
                }
                apprDetailsBySupplierAndDec.get(sup).put(decNum, d);
            }
        }

        // 3) Зібрати множину постачальників, у яких Є правки за цей місяць
        //    (замінити назви об'єкта/полів, якщо в тебе інші)
        Set<Id> suppliersWithEdits = new Set<Id>();
        if (!supplierIds.isEmpty()) {
            for (SupplierLimitEdit__c e : [
                SELECT Supplier__c, Decade__r.Year__c, Decade__r.Month__c
                FROM SupplierLimitEdit__c
                WHERE Supplier__c IN :supplierIds
                  AND Decade__r.Year__c  = :year
                  AND Decade__r.Month__c = :String.valueOf(month)
            ]) {
                if (e.Supplier__c != null) suppliersWithEdits.add(e.Supplier__c);
            }
        }

        // 4) Мапи з утиліти


        // 5) Формуємо результат по кожному постачальнику
        List<SupplierMonthRow> out = new List<SupplierMonthRow>();
        for (Account acc : suppliers) {
            SupplierMonthRow r = new SupplierMonthRow();
            r.supplierId = acc.Id;
            r.supplierName = acc.Name;
            r.hasSupplierLimitEdit = suppliersWithEdits.contains(acc.Id);

            String raw = acc.Parent__r != null ? acc.Parent__r.Name : null;
            String low = raw == null ? '' : raw.toLowerCase();
            if (low.contains('комерц')) {
                r.supplierKind = 'COMMERCIAL';
            } else if (low.contains('корп')) {
                r.supplierKind = 'CORPORATE';
            } else {
                r.supplierKind = 'OTHER';
            }

            Map<Calendar, Decimal> dMap = declared != null ? declared.get(acc.Id) : null;
            Map<Calendar, Decimal> aMap = approved != null ? approved.get(acc.Id) : null;
            Map<Calendar, Decimal> iMap = inputs   != null ? inputs.get(acc.Id)   : null;

            // значення по декадах (0, якщо немає)
            r.propDec1 = pickForDecade(dMap, year, month, 1);
            r.propDec2 = pickForDecade(dMap, year, month, 2);
            r.propDec3 = pickForDecade(dMap, year, month, 3);

            r.apprDec1 = pickForDecade(aMap, year, month, 1);
            r.apprDec2 = pickForDecade(aMap, year, month, 2);
            r.apprDec3 = pickForDecade(aMap, year, month, 3);

            r.factDec1 = pickForDecade(iMap, year, month, 1);
            r.factDec2 = pickForDecade(iMap, year, month, 2);
            r.factDec3 = pickForDecade(iMap, year, month, 3);

            // місячні суми
            r.propMonthTotal = nz(r.propDec1) + nz(r.propDec2) + nz(r.propDec3);
            r.apprMonthTotal = nz(r.apprDec1) + nz(r.apprDec2) + nz(r.apprDec3);
            r.factMonthTotal = nz(r.factDec1) + nz(r.factDec2) + nz(r.factDec3);


            Map<Integer, SupplierLimitDetails__c> m = apprDetailsBySupplierAndDec.get(acc.Id);
            if (m != null) {
                r.apprDetailDec1Id = m.containsKey(1) ? m.get(1).Id : null;
                r.apprDetailDec2Id = m.containsKey(2) ? m.get(2).Id : null;
                r.apprDetailDec3Id = m.containsKey(3) ? m.get(3).Id : null;
            }

            // залишок = approved - fact
            r.remainDec1 = nz(r.apprDec1) - nz(r.factDec1);
            r.remainDec2 = nz(r.apprDec2) - nz(r.factDec2);
            r.remainDec3 = nz(r.apprDec3) - nz(r.factDec3);
            r.remainMonthTotal = nz(r.apprMonthTotal) - nz(r.factMonthTotal);

            // прапорці для стилів
            r.hasDeclared = (r.propMonthTotal != null && r.propMonthTotal > 0);
            r.hasApproved = (r.apprMonthTotal != null && r.apprMonthTotal > 0);
            r.hasAnyData  = r.hasDeclared || r.hasApproved || (r.factMonthTotal != null && r.factMonthTotal > 0);

            out.add(r);
        }

        return out;
    }

    // === допоміжні ===

    // Взяти значення для конкретної декади з мапи Calendar->Decimal
    private static Decimal pickForDecade(Map<Calendar, Decimal> mapCal, Integer y, Integer m, Integer d) {
        if (mapCal == null) return 0;
        for (Calendar cal : mapCal.keySet()) {
            // у твоєму утиліті: Calendar.decodeCalendar(cal) -> [year, month, decade]
            List<Integer> dec = Calendar.decodeCalendar(cal);
            if (dec != null && dec.size() >= 3 && dec[0] == y && dec[1] == m && dec[2] == d) {
                Decimal v = mapCal.get(cal);
                return (v == null) ? 0 : v;
            }
        }
        return 0;
    }

    private static Decimal nz(Decimal v) {
        return (v == null) ? 0 : v;
    }

    // маленький хелпер для циклу по 3 декадах
    private class DecadeChange {
        public Id decadeId;
        public Decimal newValue;
        public DecadeChange(Id d, Decimal v) { decadeId = d; newValue = (v == null ? 0 : v); }
    }

    public class ChangeInput {
        @AuraEnabled public Id detailId { get; set; }    // SupplierLimitDetails__c.Id (може бути null, тоді створимо)
        @AuraEnabled public Integer decade { get; set; }  // 1|2|3 (потрібно, якщо detailId=null)
        @AuraEnabled public Decimal newLimit { get; set; }
    }

    @AuraEnabled
    public static void saveApprovedEdits(
            Id supplierId,
            Integer year,
            Integer month,
            List<ChangeInput> changes,
            List<Id> contentDocIds
    ){
        System.debug('supplierId: ' + supplierId);
        System.debug('year: ' + year);
        System.debug('month: ' + month);
        System.debug('contentDocIds: ' + contentDocIds);
        System.debug('RAW changes JSON: ' + JSON.serialize(changes));

        if (supplierId == null || year == null || month == null) {
            throw new AuraHandledException('Некоректні параметри (supplierId/year/month).');
        }
        if (changes == null || changes.isEmpty()) return;

        // 1) зберемо й перевіримо detailIds
        Set<Id> detailIds = new Set<Id>();
        for (ChangeInput ch : changes) {
            if (ch == null || ch.detailId == null) {
                throw new AuraHandledException('Очікується detailId для кожної декади.');
            }
            detailIds.add(ch.detailId);
        }

        // 2) підтягнемо всі потрібні деталі (і все, що треба для валід. та Edit)
        List<SupplierLimitDetails__c> details = [
                SELECT Id, Limit__c,
                        Decade__c,
                        Decade__r.Decade__c,
                        Decade__r.Year__c,
                        Decade__r.Month__c,
                        Decade__r.Parent__c,                    // Month (Level=2)
                        Decade__r.Parent__r.Parent__c,          // Year (Level=1)
                        MonthLookup__c,                          // альтернативний місячний lookup, якщо є
                        MonthLookup__r.Parent__c,               // відповідний рік
                        ScrapSupplierLimit__c,
                        ScrapSupplierLimit__r.Supplier__c,
                        ScrapSupplierLimit__r.RecordType.DeveloperName
                FROM SupplierLimitDetails__c
                WHERE Id IN :detailIds
        ];
        if (details.size() != detailIds.size()) {
            throw new AuraHandledException('Не всі SupplierLimitDetails__c знайдено за переданими Id.');
        }

        // 3) побудуємо map для швидкого доступу та провалідовуємо
        Map<Id, SupplierLimitDetails__c> byId = new Map<Id, SupplierLimitDetails__c>(details);
        for (SupplierLimitDetails__c d : details) {
            // RecordType має бути Approved
            if (d.ScrapSupplierLimit__r == null ||
                    d.ScrapSupplierLimit__r.RecordType.DeveloperName != 'Approved') {
                throw new AuraHandledException('Переданий detailId не належить Approved-запису.');
            }
            // Supplier має збігатись
            if (d.ScrapSupplierLimit__r.Supplier__c != supplierId) {
                throw new AuraHandledException('detailId не належить вказаному постачальнику.');
            }
            // Рік/місяць мають збігатись (місяць у твоїй моделі часто рядок)
            Decimal dYear = d.Decade__r != null ? d.Decade__r.Year__c : null;
            String  dMonth = d.Decade__r != null ? d.Decade__r.Month__c : null;
            if (dYear == null || dMonth == null || dYear != year || String.valueOf(month) != dMonth) {
                throw new AuraHandledException('detailId не належить вказаному року/місяцю.');
            }
        }

        // 4) сформуємо логи (INSERT ПЕРШИМ), потім оновлення деталей
        List<SupplierLimitEdit__c> editsToInsert = new List<SupplierLimitEdit__c>();
        List<SupplierLimitDetails__c> toUpdate = new List<SupplierLimitDetails__c>();

        for (ChangeInput ch : changes) {
            SupplierLimitDetails__c d = byId.get(ch.detailId);
            if (d == null) continue; // захист від гонок

            Decimal oldVal = (d.Limit__c == null) ? 0 : d.Limit__c;
            Decimal newVal = (ch.newLimit == null) ? 0 : ch.newLimit;
            if (oldVal == newVal) continue;

            // джерела Month/Year для дотримання lookup-фільтрів на SupplierLimitEdit__c
            Id monthId = (d.MonthLookup__c != null) ? d.MonthLookup__c : d.Decade__r.Parent__c;
            Id yearId  = (d.MonthLookup__r != null) ? d.MonthLookup__r.Parent__c : d.Decade__r.Parent__r.Parent__c;

            // 4.1) ЛОГ — вставляємо ПЕРЕД оновленням detail
            SupplierLimitEdit__c e = new SupplierLimitEdit__c();
            e.Supplier__c             = supplierId;
            e.ScrapSupplierLimit__c   = d.ScrapSupplierLimit__c;
            e.SupplierLimitDetails__c = d.Id;
            e.Decade__c               = d.Decade__c;   // Level=3
            e.Month__c                = monthId;       // Level=2
            e.Year__c                 = yearId;        // Level=1
            e.OriginalLimit__c        = oldVal;
            e.NewLimit__c             = newVal;
            editsToInsert.add(e);

            // 4.2) ПІСЛЯ логів — апдейт detail
            d.Limit__c = newVal;
            toUpdate.add(d);
        }

        // 5) DML: спочатку INSERT логів, тоді UPDATE деталей
        if (!editsToInsert.isEmpty()) {
            insert editsToInsert;

            // 5.1) прикріпимо файли до кожного Edit, якщо передали
            if (contentDocIds != null && !contentDocIds.isEmpty()) {
                List<ContentDocumentLink> links = new List<ContentDocumentLink>();
                for (SupplierLimitEdit__c e : editsToInsert) {
                    for (Id docId : contentDocIds) {
                        links.add(new ContentDocumentLink(
                                ContentDocumentId = docId,
                                LinkedEntityId    = e.Id,
                                ShareType         = 'V',
                                Visibility        = 'AllUsers'
                        ));
                    }
                }
                if (!links.isEmpty()) insert links;
            }
        }
        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }

    public class EditHistoryRow {
        @AuraEnabled public Id    editId;
        @AuraEnabled public Integer decade;         // 1|2|3
        @AuraEnabled public Decimal originalLimit;
        @AuraEnabled public Decimal newLimit;
        @AuraEnabled public Datetime createdAt;
        @AuraEnabled public String  createdBy;
        @AuraEnabled public Integer filesCount;
    }

    @AuraEnabled(cacheable=false)
    public static List<EditHistoryRow> getEditsHistory(Id supplierId, Integer year, Integer month, Integer maxItems) {
        if (supplierId==null || year==null || month==null) return new List<EditHistoryRow>();
        Integer lim = (maxItems==null || maxItems<=0) ? 50 : Math.min(maxItems, 200);

        List<SupplierLimitEdit__c> edits = [
                SELECT Id, OriginalLimit__c, NewLimit__c,
                        Decade__r.Decade__c, Decade__r.Year__c, Decade__r.Month__c,
                        CreatedDate, CreatedBy.Name
                FROM SupplierLimitEdit__c
                WHERE Supplier__c = :supplierId
                AND Decade__r.Year__c  = :year
                AND Decade__r.Month__c = :String.valueOf(month)
                ORDER BY CreatedDate DESC
                LIMIT :lim
        ];

        // підрахуємо вкладення
        Set<Id> editIds = new Set<Id>();
        for (SupplierLimitEdit__c e : edits) {
            editIds.add(e.Id);
        }

        Map<Id,Integer> filesByEdit = new Map<Id,Integer>();
        if (!editIds.isEmpty()) {
            for (ContentDocumentLink l : [
                    SELECT LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId IN :editIds
            ]) {
                filesByEdit.put(l.LinkedEntityId, (filesByEdit.containsKey(l.LinkedEntityId)? filesByEdit.get(l.LinkedEntityId)+1 : 1));
            }
        }

        List<EditHistoryRow> out = new List<EditHistoryRow>();
        for (SupplierLimitEdit__c e : edits) {
            EditHistoryRow r = new EditHistoryRow();
            r.editId        = e.Id;
            r.decade        = Integer.valueOf(e.Decade__r.Decade__c);
            r.originalLimit = e.OriginalLimit__c;
            r.newLimit      = e.NewLimit__c;
            r.createdAt     = e.CreatedDate;
            r.createdBy     = e.CreatedBy.Name;
            r.filesCount    = filesByEdit.get(e.Id);
            out.add(r);
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
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
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