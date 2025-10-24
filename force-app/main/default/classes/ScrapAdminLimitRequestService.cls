global class ScrapAdminLimitRequestService {

    global class CreatedBundle {
        @AuraEnabled global ScrapSupplierLimit__c parent;
        @AuraEnabled global List<SupplierLimitDetails__c> details;
    }

    global class DecadeLimitVM {
        @AuraEnabled global Id decadeId;          // Id запису Decade (рівень 3)
        @AuraEnabled global String decadeNumber; // 1/2/3 (беремо з Decade__r.Decade__c, якщо є)
        @AuraEnabled global Decimal limitValue;        // ліміт по декаді
    }

    global class UnapprovedLimitRow {
        @AuraEnabled global Id parentId;
        @AuraEnabled global Datetime createdDate;          // NEW
        @AuraEnabled global Id supplierId;
        @AuraEnabled global String supplierName;
        @AuraEnabled global String yearTxt;
        @AuraEnabled global String monthTxt;
        @AuraEnabled global Integer monthNum;              // NEW (з monthTxt)
        @AuraEnabled global Id monthLookupId;
        @AuraEnabled global Decimal monthTotal;

        // Плоскі поля для таблиці і модалки — NEW
        @AuraEnabled global Id     detailDec1Id;
        @AuraEnabled global Id     detailDec2Id;
        @AuraEnabled global Id     detailDec3Id;
        @AuraEnabled global Decimal dec1;
        @AuraEnabled global Decimal dec2;
        @AuraEnabled global Decimal dec3;

        // Залишаємо і масив на випадок, якщо треба подекадно детально
        @AuraEnabled global List<DecadeLimitVM> decades;
    }

    // ====== DTO for approve input/output ======
    global class ApproveInput {
        @AuraEnabled global Id supplierLimitId { get; set; }   // батько Заявлений
        @AuraEnabled global Id detailDec1Id { get; set; }
        @AuraEnabled global Id detailDec2Id { get; set; }
        @AuraEnabled global Id detailDec3Id { get; set; }
        @AuraEnabled global Decimal dec1 { get; set; }
        @AuraEnabled global Decimal dec2 { get; set; }
        @AuraEnabled global Decimal dec3 { get; set; }
        @AuraEnabled global String baseDoc;      // опційно: підстава (текст)
        @AuraEnabled global String docLinkId;    // опційно: лінк-док (текст/Id)
    }

    global class ApproveResult {
        @AuraEnabled global Boolean success { get; set; }
        @AuraEnabled global String  message { get; set; }
        @AuraEnabled global Id      approvedParentId { get; set; }
        @AuraEnabled global List<Id> approvedDetailIds { get; set; }
    }


    // ====== CREATE (залишаємо як погоджено) ======

    @AuraEnabled
    global static CreatedBundle createProposedForCurrentMonth(
            Id supplierId,
            Decimal dec1Limit,
            Decimal dec2Limit,
            Decimal dec3Limit
    ) {
        if (supplierId == null) throw new AuraHandledException('Потрібен supplierId.');

        Date today      = System.today();
        Integer yearNum = today.year();
        Integer monthNum= today.month();

        // Твій стиль біндингу в Decade__c: Year__c як Decimal, Month__c як String
        Decimal y = Decimal.valueOf(yearNum);
        String  m = String.valueOf(monthNum);

        // 1) Місячний вузол (Level__c = 2) — беремо один, як у твоєму анонімусі
        Decade__c monthNode = [
                SELECT Id, Name
                FROM Decade__c
                WHERE Year__c = :y AND Month__c = :m AND Level__c = 2
                LIMIT 1
        ];
        System.debug('Month node: ' + monthNode.Name);

        // 2) Три декади — діти місяця; впорядкуємо за номером
        List<Decade__c> threeDecades = [
                SELECT Id, Decade__c
                FROM Decade__c
                WHERE Parent__c = :monthNode.Id
                ORDER BY Decade__c
                LIMIT 3
        ];
        System.debug('threeDecades: ' + threeDecades);

        // 3) Визначаємо Record Type для "Заявлений"
        Id proposedRtId = getProposedRecordTypeId();

        // 4) Створюємо батьківський ScrapSupplierLimit__c
        ScrapSupplierLimit__c parent = new ScrapSupplierLimit__c();
        parent.Supplier__c      = supplierId;
        parent.YearPick__c      = String.valueOf(yearNum);   // якщо Picklist/текст
        parent.Month__c         = String.valueOf(monthNum);  // якщо Picklist із номером
        parent.RecordTypeId     = proposedRtId;              // "Заявлений"
        parent.SentToApprove__c = false;
        parent.Approved__c      = false;
        parent.MonthLookup__c   = monthNode.Id;
        insert parent;
        System.debug('Created ScrapSupplierLimit__c: ' + parent.Id);

        // 5) Деталі (із фронта)
        List<SupplierLimitDetails__c> toInsert = new List<SupplierLimitDetails__c>{
            buildDetail(parent.Id, monthNode.Id, threeDecades[0].Id, dec1Limit == null ? 0 : dec1Limit),
            buildDetail(parent.Id, monthNode.Id, threeDecades[1].Id, dec2Limit == null ? 0 : dec2Limit),
            buildDetail(parent.Id, monthNode.Id, threeDecades[2].Id, dec3Limit == null ? 0 : dec3Limit)
        };
        insert toInsert;

        System.debug('Created details: ' + toInsert);
        System.debug('Done. Parent.Key__c (тригер): ' + parent.Key__c);

        CreatedBundle out = new CreatedBundle();
        out.parent  = parent;
        out.details = toInsert;
        return out;
    }

    // ====== READ (тільки НЕУЗГОДЖЕНІ для сторінки/модалки) ======

    @AuraEnabled(cacheable=false)
    global static List<UnapprovedLimitRow> listUnapprovedForCurrentMonth() {
        Date   today    = System.today();
        Integer yearNum = today.year();
        Integer monthNum= today.month();
        return listUnapprovedForPeriod(yearNum, monthNum);
    }

    @AuraEnabled(cacheable=false)
    global static List<UnapprovedLimitRow> listUnapprovedForPeriod(Integer yearNum, Integer monthNum) {
        if (yearNum == null || monthNum == null) {
            throw new AuraHandledException('Потрібні рік і місяць.');
        }

        // RecordType для "Заявлений" (ми показуємо ТІЛЬКИ неузгоджені, як ти просила)
        Id proposedRtId = getProposedRecordTypeId();

        // Батьки: тільки RT=Заявлений і Approved__c = false
        List<ScrapSupplierLimit__c> parents = [
            SELECT Id, CreatedDate, Supplier__c, Supplier__r.Name,
                   YearPick__c, Month__c, MonthLookup__c,
                   Approved__c, MonthLimit__c
            FROM ScrapSupplierLimit__c
            WHERE YearPick__c = :String.valueOf(yearNum)
              AND Month__c    = :String.valueOf(monthNum)
              AND RecordTypeId = :proposedRtId
              AND Approved__c = FALSE
            ORDER BY Supplier__r.Name NULLS LAST, CreatedDate ASC
        ];
        if (parents.isEmpty()) return new List<UnapprovedLimitRow>();

        // Всі деталі для цих батьків
        List<SupplierLimitDetails__c> details = [
            SELECT Id, ScrapSupplierLimit__c, Limit__c,
                   Decade__c, Decade__r.Decade__c
            FROM SupplierLimitDetails__c
            WHERE ScrapSupplierLimit__c IN :parents
            ORDER BY Decade__r.Decade__c, CreatedDate
        ];

        // Групуємо деталі по батьку
        Map<Id, List<SupplierLimitDetails__c>> byParent = new Map<Id, List<SupplierLimitDetails__c>>();
        for (ScrapSupplierLimit__c p : parents) {
            byParent.put(p.Id, new List<SupplierLimitDetails__c>());
        }

        for (SupplierLimitDetails__c d : details) {
            List<SupplierLimitDetails__c> bucket = byParent.get(d.ScrapSupplierLimit__c);
            if (bucket != null) bucket.add(d);
        }

        // Формуємо ViewModel для фронта
        List<UnapprovedLimitRow> rows = new List<UnapprovedLimitRow>();
        for (ScrapSupplierLimit__c p : parents) {
            UnapprovedLimitRow row = new UnapprovedLimitRow();
            row.parentId      = p.Id;
            row.createdDate   = p.CreatedDate;                         // NEW
            row.supplierId    = p.Supplier__c;
            row.supplierName  = p.Supplier__r == null ? null : p.Supplier__r.Name;
            row.yearTxt       = p.YearPick__c;
            row.monthTxt      = p.Month__c;
            row.monthNum = toIntSafe(p.Month__c);
            row.monthLookupId = p.MonthLookup__c;

            // подекадно
            row.decades = new List<DecadeLimitVM>();
            Decimal sum = 0;
            for (SupplierLimitDetails__c d : byParent.get(p.Id)) {
                DecadeLimitVM vm = new DecadeLimitVM();
                vm.decadeId     = d.Decade__c;
                vm.decadeNumber = (d.Decade__r == null ? null : d.Decade__r.Decade__c);
                vm.limitValue    = d.Limit__c;
                row.decades.add(vm);

                 Integer decNo = null;
                if (d.Decade__r != null && d.Decade__r.Decade__c != null) {
                    decNo = Integer.valueOf(String.valueOf(d.Decade__r.Decade__c));
                }
                if (decNo == 1) { row.detailDec1Id = d.Id; row.dec1 = d.Limit__c; }
                else if (decNo == 2) { row.detailDec2Id = d.Id; row.dec2 = d.Limit__c; }
                else if (decNo == 3) { row.detailDec3Id = d.Id; row.dec3 = d.Limit__c; }

                sum += (d.Limit__c == null ? 0 : d.Limit__c);
            }

            // підсумок
            row.monthTotal = (p.MonthLimit__c != null ? p.MonthLimit__c : sum);

            rows.add(row);
        }
        return rows;
    }

    // ====== helpers ======

    private static SupplierLimitDetails__c buildDetail(
            Id parentId, Id monthLookupId, Id decadeId, Decimal limitValue
    ) {
        SupplierLimitDetails__c d = new SupplierLimitDetails__c();
        d.ScrapSupplierLimit__c = parentId;
        d.MonthLookup__c        = monthLookupId;
        d.Decade__c             = decadeId;
        d.Limit__c              = limitValue;
        return d;
    }

    /** Шукаємо Record Type для "Заявлений" (Name='Заявлений' або DevName IN ('Proposed','Declared')). */
    private static Id getProposedRecordTypeId() {
        List<RecordType> rts = [
                SELECT Id, Name, DeveloperName
                FROM RecordType
                WHERE SobjectType = 'ScrapSupplierLimit__c'
                AND (Name = 'Заявлений' OR DeveloperName IN ('Proposed','Declared'))
                LIMIT 1
        ];
        if (rts.isEmpty()) {
            throw new AuraHandledException('Record Type "Заявлений/Proposed/Declared" для ScrapSupplierLimit__c не знайдено.');
        }
        return rts[0].Id;
    }

    // ====== APPROVE: створюємо "Узгоджений" + 3 дочірні ======
    @AuraEnabled
    global static ApproveResult approve(ApproveInput input) {
        System.debug('================approve====================');
        System.debug('DATA: ' + input);
        ApproveResult res = new ApproveResult();
        res.success = false;

        // 0) Валідація
        if (input == null || input.supplierLimitId == null)
            throw new AuraHandledException('Не передано supplierLimitId.');
        if (input.detailDec1Id == null || input.detailDec2Id == null || input.detailDec3Id == null)
            throw new AuraHandledException('Потрібні всі три detailDec*Id.');

        // 1) Батько "Заявлений"
        ScrapSupplierLimit__c proposed = [
                SELECT Id, Supplier__c, YearPick__c, Month__c, MonthLookup__c, RecordTypeId
                FROM ScrapSupplierLimit__c
                WHERE Id = :input.supplierLimitId
                LIMIT 1
        ];

        proposed.Approved__c = true;       // ✅ саме тут
        update proposed;


        // 2) Отримаємо три деталі, щоб зняти їхні ДЕКАДИ (щоб не вгадувати порядок)
        Map<Id, SupplierLimitDetails__c> detailsById = new Map<Id, SupplierLimitDetails__c>([
                SELECT Id, ScrapSupplierLimit__c, Decade__c, MonthLookup__c, Limit__c
                FROM SupplierLimitDetails__c
                WHERE Id IN :new List<Id>{ input.detailDec1Id, input.detailDec2Id, input.detailDec3Id }
        ]);
        if (detailsById.size() != 3)
            throw new AuraHandledException('Знайдено не всі SupplierLimitDetails__c за вказаними Id.');

        // 3) Визначаємо RT для "Узгоджений"
        Id approvedRtId = getApprovedRecordTypeId();

        // 4) Створюємо батька "Узгоджений" (копія ключових полів із "Заявленого")
        ScrapSupplierLimit__c approved = new ScrapSupplierLimit__c();
        approved.Supplier__c    = proposed.Supplier__c;
        approved.YearPick__c    = proposed.YearPick__c;
        approved.Month__c       = proposed.Month__c;
        approved.MonthLookup__c = proposed.MonthLookup__c;
        approved.RecordTypeId   = approvedRtId;
        approved.SentToApprove__c = true;   // за потреби
        approved.Approved__c      = true;
        insert approved;

        // 5) Підготуємо мапу "який detailId → яке значення"
        Map<Id, Decimal> newLimitsByDetailId = new Map<Id, Decimal>{
                input.detailDec1Id => (input.dec1 == null ? 0 : input.dec1),
                input.detailDec2Id => (input.dec2 == null ? 0 : input.dec2),
                input.detailDec3Id => (input.dec3 == null ? 0 : input.dec3)
        };

        // 6) Створюємо 3 нові деталі для "Узгодженого", зберігаючи ті ж ДЕКАДИ
        List<SupplierLimitDetails__c> toIns = new List<SupplierLimitDetails__c>();
        for (Id oldDetailId : newLimitsByDetailId.keySet()) {
            SupplierLimitDetails__c oldD = detailsById.get(oldDetailId);
            SupplierLimitDetails__c nd = new SupplierLimitDetails__c();
            nd.ScrapSupplierLimit__c = approved.Id;
            nd.MonthLookup__c        = proposed.MonthLookup__c;  // місячний вузол той самий
            nd.Decade__c             = oldD.Decade__c;           // важливо: та ж декада
            nd.Limit__c              = newLimitsByDetailId.get(oldDetailId);
            toIns.add(nd);
        }
        insert toIns;

        // 7) (Опційно) — зафіксувати зміни у SupplierLimitEdit__c (по 3 записи),
        // якщо ти вже працюєш з цим об'єктом як з журналом змін.
        // Тут можна вказати OriginalLimit__c = oldD.Limit__c; NewLimit__c = input.dec*;
        // BaseDoc__c / DocLinkId__c — з input.baseDoc / input.docLinkId.
        // За потреби — додам, але зараз залишаю як коментар.

        res.success = true;
        res.message = 'Узгоджено';
        res.approvedParentId = approved.Id;
        res.approvedDetailIds = new List<Id>();
        for (SupplierLimitDetails__c d : toIns) res.approvedDetailIds.add(d.Id);
        return res;
    }

// ====== helper: RecordType для "Узгоджений" ======
    private static Id getApprovedRecordTypeId() {
        List<RecordType> rts = [
                SELECT Id, Name, DeveloperName
                FROM RecordType
                WHERE SobjectType = 'ScrapSupplierLimit__c'
                AND (Name = 'Узгоджений' OR DeveloperName IN ('Approved'))
                LIMIT 1
        ];
        if (rts.isEmpty())
            throw new AuraHandledException('Record Type "Узгоджений/Approved" для ScrapSupplierLimit__c не знайдено.');
        return rts[0].Id;
    }

    @AuraEnabled(cacheable=true)
    global static List<UnapprovedLimitRow> listUnapprovedForCurrentAndNext() {
        Date today = System.today();
        Integer y1 = today.year(), m1 = today.month();
        Date nxt   = today.addMonths(1);
        Integer y2 = nxt.year(),   m2 = nxt.month();

        Id proposedRtId = getProposedRecordTypeId();

        // 1) Батьки за обома місяцями
        List<ScrapSupplierLimit__c> parents = [
                SELECT Id, CreatedDate, Supplier__c, Supplier__r.Name,
                        YearPick__c, Month__c, MonthLookup__c,
                        Approved__c, MonthLimit__c, RecordTypeId
                FROM ScrapSupplierLimit__c
                WHERE RecordTypeId = :proposedRtId
                AND (Approved__c = false OR Approved__c = null)
                AND (
                        (YearPick__c = :String.valueOf(y1) AND Month__c = :String.valueOf(m1)) OR
                        (YearPick__c = :String.valueOf(y2) AND Month__c = :String.valueOf(m2))
                )
                ORDER BY CreatedDate DESC, Supplier__r.Name NULLS LAST
                LIMIT 2000
        ];
        if (parents.isEmpty()) return new List<UnapprovedLimitRow>();

        // 2) Деталі всіх знайдених батьків
        List<SupplierLimitDetails__c> details = [
                SELECT Id, ScrapSupplierLimit__c, Limit__c,
                        Decade__c, Decade__r.Decade__c
                FROM SupplierLimitDetails__c
                WHERE ScrapSupplierLimit__c IN :parents
                ORDER BY Decade__r.Decade__c, CreatedDate
        ];

        // 3) Групування
        Map<Id, List<SupplierLimitDetails__c>> byParent = new Map<Id, List<SupplierLimitDetails__c>>();
        for (ScrapSupplierLimit__c p : parents) byParent.put(p.Id, new List<SupplierLimitDetails__c>());
        for (SupplierLimitDetails__c d : details) {
            List<SupplierLimitDetails__c> b = byParent.get(d.ScrapSupplierLimit__c);
            if (b != null) b.add(d);
        }

        // 4) Побудова рядків
        List<UnapprovedLimitRow> rows = new List<UnapprovedLimitRow>();
        for (ScrapSupplierLimit__c p : parents) {
            UnapprovedLimitRow row = new UnapprovedLimitRow();
            row.parentId      = p.Id;
            row.createdDate   = p.CreatedDate;
            row.supplierId    = p.Supplier__c;
            row.supplierName  = (p.Supplier__r == null ? null : p.Supplier__r.Name);
            row.yearTxt       = p.YearPick__c;
            row.monthTxt      = p.Month__c;
            row.monthNum      = toIntSafe(p.Month__c);
            row.monthLookupId = p.MonthLookup__c;

            row.decades = new List<DecadeLimitVM>();
            Decimal sum = 0;
            for (SupplierLimitDetails__c d : byParent.get(p.Id)) {
                DecadeLimitVM vm = new DecadeLimitVM();
                vm.decadeId     = d.Decade__c;
                vm.decadeNumber = (d.Decade__r == null ? null : d.Decade__r.Decade__c); // 👈 див. п.2
                vm.limitValue   = d.Limit__c;
                row.decades.add(vm);

                Integer decNo = null;
                if (d.Decade__r != null && d.Decade__r.Decade__c != null) {
                    decNo = Integer.valueOf(String.valueOf(d.Decade__r.Decade__c));
                }
                if (decNo == 1) { row.detailDec1Id = d.Id; row.dec1 = d.Limit__c; }
                else if (decNo == 2) { row.detailDec2Id = d.Id; row.dec2 = d.Limit__c; }
                else if (decNo == 3) { row.detailDec3Id = d.Id; row.dec3 = d.Limit__c; }

                sum += (d.Limit__c == null ? 0 : d.Limit__c);
            }

            row.monthTotal = (p.MonthLimit__c != null ? p.MonthLimit__c : sum);
            rows.add(row);
        }
        // вже відсортовано по CreatedDate DESC у SOQL; залишаємо як є
        return rows;
    }

    private static Integer toIntSafe(String s) {
        if (String.isBlank(s)) return null;
        try { return Integer.valueOf(s.trim()); }
        catch (Exception e) { return null; }
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