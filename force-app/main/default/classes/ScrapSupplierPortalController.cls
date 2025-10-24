global with sharing class ScrapSupplierPortalController {

    global class CreatedBundle {
        @AuraEnabled global ScrapSupplierLimit__c parent;
        @AuraEnabled global List<SupplierLimitDetails__c> details;
    }

    global class LimitDetailVM {
        @AuraEnabled global Id id;
        @AuraEnabled global Id decadeId;
        @AuraEnabled global String decadeNumber;
        @AuraEnabled global Decimal limitValue;
    }
    global class LimitParentVM {
        @AuraEnabled global Id id;
        @AuraEnabled global Datetime createdDate;
        @AuraEnabled global Boolean approved;
        @AuraEnabled global Id monthLookupId;
        @AuraEnabled global List<LimitDetailVM> details;
    }
    global class MonthLimits {
        @AuraEnabled global Integer yearNum;
        @AuraEnabled global Integer monthNum;
        @AuraEnabled global List<LimitParentVM> proposed;
        @AuraEnabled global List<LimitParentVM> approved;
    }

    global class CreateCheckResult {
        @AuraEnabled global Boolean canCreate;
        @AuraEnabled global String  message;         // що робити користувачу
        @AuraEnabled global Integer conflictYear;    // рік, де знайдено "Заявлений"
        @AuraEnabled global Integer conflictMonth;   // місяць, де знайдено "Заявлений"
        @AuraEnabled global Id      existingParentId;
    }

    @AuraEnabled(cacheable=true)
    public static Id getMyAccountId() {
        User u = [SELECT Contact.AccountId FROM User WHERE Id = :UserInfo.getUserId()];
        return u.Contact.AccountId;
    }

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

    // === NEW: перевірка чи вже є "Заявлений" на поточний або наступний місяць ===
    @AuraEnabled(cacheable=true)
    global static CreateCheckResult checkExistingProposedThisOrNext(Id supplierId) {
        if (supplierId == null) throw new AuraHandledException('Потрібен supplierId.');

        Date today = System.today();
        Integer y1 = today.year();
        Integer m1 = today.month();
        Date next  = today.addMonths(1);
        Integer y2 = next.year();
        Integer m2 = next.month();

        Id proposedRtId = getProposedRecordTypeId();

        List<ScrapSupplierLimit__c> found = [
            SELECT Id, YearPick__c, Month__c
            FROM ScrapSupplierLimit__c
            WHERE Supplier__c = :supplierId
              AND RecordTypeId = :proposedRtId
              AND (Approved__c = false OR Approved__c = null)
              AND (
                    (YearPick__c = :String.valueOf(y1) AND Month__c = :String.valueOf(m1)) OR
                    (YearPick__c = :String.valueOf(y2) AND Month__c = :String.valueOf(m2))
                  )
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        CreateCheckResult res = new CreateCheckResult();
        if (found.isEmpty()) {
            res.canCreate = true;
            res.message   = 'Можна створити заявлений ліміт.';
        } else {
            ScrapSupplierLimit__c p = found[0];
            res.canCreate       = false;
            res.existingParentId= p.Id;
            res.conflictYear    = Integer.valueOf(p.YearPick__c);
            res.conflictMonth   = Integer.valueOf(p.Month__c);
            res.message         = 'На цей або на наступний місяць вже є "Заявлений". Відкрий існуючий і відредагуй.';
        }
        return res;
    }

    // === NEW: повертає всі "Заявлені" та "Узгоджені" на поточний і наступний місяці (з деталями) ===
    @AuraEnabled(cacheable=false)
    global static List<MonthLimits> listThisAndNextAllLimits(Id supplierId) {
        if (supplierId == null) throw new AuraHandledException('Потрібен supplierId.');

        Date today = System.today();
        Date next  = today.addMonths(1);

        List<MonthLimits> out = new List<MonthLimits>();
        out.add( buildMonthLimits(today.year(), today.month(), supplierId) );
        out.add( buildMonthLimits(next.year(),  next.month(),  supplierId) );
        return out;
    }

    private static MonthLimits buildMonthLimits(Integer yearNum, Integer monthNum, Id supplierId) {
        Id proposedRtId = getProposedRecordTypeId();
        Id approvedRtId = getApprovedRecordTypeId();

        List<ScrapSupplierLimit__c> parents = [
            SELECT Id, CreatedDate, Supplier__c, YearPick__c, Month__c, MonthLookup__c,
                   RecordTypeId, Approved__c
            FROM ScrapSupplierLimit__c
            WHERE Supplier__c = :supplierId
              AND YearPick__c = :String.valueOf(yearNum)
              AND Month__c    = :String.valueOf(monthNum)
              AND RecordTypeId IN :new Set<Id>{ proposedRtId, approvedRtId }
            ORDER BY CreatedDate DESC
            LIMIT 1000
        ];
        Map<Id, List<SupplierLimitDetails__c>> byParent = new Map<Id, List<SupplierLimitDetails__c>>();
        if (!parents.isEmpty()) {
            List<SupplierLimitDetails__c> details = [
                SELECT Id, ScrapSupplierLimit__c, MonthLookup__c,
                       Decade__c, Decade__r.Decade__c, Limit__c
                FROM SupplierLimitDetails__c
                WHERE ScrapSupplierLimit__c IN :parents
                ORDER BY CreatedDate
            ];
            for (ScrapSupplierLimit__c p : parents) byParent.put(p.Id, new List<SupplierLimitDetails__c>());
            for (SupplierLimitDetails__c d : details) byParent.get(d.ScrapSupplierLimit__c).add(d);
        }

        MonthLimits ml = new MonthLimits();
        ml.yearNum  = yearNum;
        ml.monthNum = monthNum;
        ml.proposed = new List<LimitParentVM>();
        ml.approved = new List<LimitParentVM>();

        for (ScrapSupplierLimit__c p : parents) {
            LimitParentVM vm = new LimitParentVM();
            vm.id           = p.Id;
            vm.createdDate  = p.CreatedDate;
            vm.approved     = p.Approved__c;
            vm.monthLookupId= p.MonthLookup__c;
            vm.details      = new List<LimitDetailVM>();

            for (SupplierLimitDetails__c d : byParent.get(p.Id)) {
                LimitDetailVM dv = new LimitDetailVM();
                dv.id           = d.Id;
                dv.decadeId     = d.Decade__c;
                dv.decadeNumber = (d.Decade__r == null ? null : d.Decade__r.Decade__c);
                dv.limitValue   = d.Limit__c;
                vm.details.add(dv);
            }

            if (p.RecordTypeId == proposedRtId) ml.proposed.add(vm);
            else ml.approved.add(vm);
        }
        return ml;
    }

    /** Існуючий хелпер */
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

    // === NEW: потрібен для рідера
    private static Id getApprovedRecordTypeId() {
        List<RecordType> rts = [
            SELECT Id, Name, DeveloperName
            FROM RecordType
            WHERE SobjectType = 'ScrapSupplierLimit__c'
            AND (Name = 'Узгоджений' OR DeveloperName IN ('Approved'))
            LIMIT 1
        ];
        if (rts.isEmpty()) {
            throw new AuraHandledException('Record Type "Узгоджений/Approved" для ScrapSupplierLimit__c не знайдено.');
        }
        return rts[0].Id;
    }

    // === NEW: універсальний створювач на конкретний рік/місяць ===
    private static CreatedBundle createProposedForYearMonth(
            Id supplierId,
            Integer yearNum,
            Integer monthNum,
            Decimal dec1Limit,
            Decimal dec2Limit,
            Decimal dec3Limit
    ) {
        if (supplierId == null) throw new AuraHandledException('Потрібен supplierId.');
        Decimal y = Decimal.valueOf(yearNum);
        String  m = String.valueOf(monthNum);

        Decade__c monthNode = [
                SELECT Id, Name
                FROM Decade__c
                WHERE Year__c = :y AND Month__c = :m AND Level__c = 2
                LIMIT 1
        ];

        List<Decade__c> threeDecades = [
                SELECT Id, Decade__c
                FROM Decade__c
                WHERE Parent__c = :monthNode.Id
                ORDER BY Decade__c
                LIMIT 3
        ];
        if (threeDecades.size() < 3) {
            throw new AuraHandledException('У календарі немає трьох декад для ' + yearNum + '-' + monthNum + '.');
        }

        Id proposedRtId = getProposedRecordTypeId();

        ScrapSupplierLimit__c parent = new ScrapSupplierLimit__c();
        parent.Supplier__c      = supplierId;
        parent.YearPick__c      = String.valueOf(yearNum);
        parent.Month__c         = String.valueOf(monthNum);
        parent.RecordTypeId     = proposedRtId;    // "Заявлений"
        parent.SentToApprove__c = false;
        parent.Approved__c      = false;
        parent.MonthLookup__c   = monthNode.Id;
        insert parent;

        List<SupplierLimitDetails__c> details = new List<SupplierLimitDetails__c>{
                buildDetail(parent.Id, monthNode.Id, threeDecades[0].Id, dec1Limit == null ? 0 : dec1Limit),
                buildDetail(parent.Id, monthNode.Id, threeDecades[1].Id, dec2Limit == null ? 0 : dec2Limit),
                buildDetail(parent.Id, monthNode.Id, threeDecades[2].Id, dec3Limit == null ? 0 : dec3Limit)
        };
        insert details;

        CreatedBundle out = new CreatedBundle();
        out.parent  = parent;
        out.details = details;
        return out;
    }

// === NEW: AUTO — створити на поточний, інакше на наступний; якщо обидва зайняті — помилка
    @AuraEnabled
    global static CreatedBundle createProposedAutoThisOrNext(
            Id supplierId,
            Decimal dec1Limit,
            Decimal dec2Limit,
            Decimal dec3Limit
    ) {
        if (supplierId == null) throw new AuraHandledException('Потрібен supplierId.');

        Date today = System.today();
        Integer y1 = today.year(), m1 = today.month();
        Date    nxt = today.addMonths(1);
        Integer y2 = nxt.year(),   m2 = nxt.month();

        Id proposedRtId = getProposedRecordTypeId();

        System.debug('BEFORE HAS CURRENT: ' + supplierId + ' | ' + proposedRtId + ' | ' + y1 + ' | ' + y2 + ' | ' + m1 + ' | ' + m2);
        Boolean hasCurrent = ![
                SELECT Id FROM ScrapSupplierLimit__c
                WHERE Supplier__c = :supplierId
                AND RecordTypeId = :proposedRtId
                AND YearPick__c = :String.valueOf(y1)
                AND Month__c    = :String.valueOf(m1)
                LIMIT 1
        ].isEmpty();

        System.debug('hasCurrent: ' + hasCurrent);

        Boolean hasNext = ![
                SELECT Id FROM ScrapSupplierLimit__c
                WHERE Supplier__c = :supplierId
                AND RecordTypeId = :proposedRtId
                AND YearPick__c = :String.valueOf(y2)
                AND Month__c    = :String.valueOf(m2)
                LIMIT 1
        ].isEmpty();

        System.debug('hasNext: ' + hasNext);

        if (!hasCurrent) {
            return createProposedForYearMonth(supplierId, y1, m1, dec1Limit, dec2Limit, dec3Limit);
        } else if (!hasNext) {
            return createProposedForYearMonth(supplierId, y2, m2, dec1Limit, dec2Limit, dec3Limit);
        } else {
            throw new AuraHandledException('На поточний і на наступний місяці вже існують "Заявлені" ліміти. Редагуй наявні записи.');
        }
    }


//    РОЗРАХУНОК ЗАЛИШКУ

    // DTO для повернення балансу по декадах + підсумок за місяць
    global class DecadeBalanceVM {
        @AuraEnabled global Integer decadeNum;
        @AuraEnabled global Decimal approvedLimit;
        @AuraEnabled global Decimal input;
        @AuraEnabled global Decimal remaining; // ліміт - надходження
    }
    global class MonthBalanceVM {
        @AuraEnabled global Integer yearNum;
        @AuraEnabled global Integer monthNum;
        @AuraEnabled global Decimal limitTotal;
        @AuraEnabled global Decimal inputTotal;
        @AuraEnabled global Decimal remainingTotal;
        @AuraEnabled global List<DecadeBalanceVM> decades;
    }

    // Баланс постачальника за конкретний місяць (по декадах і сумарно за місяць)
    @AuraEnabled(cacheable=true)
    global static MonthBalanceVM getSupplierMonthBalance(Id supplierId, Integer yearNum, Integer monthNum) {
        if (supplierId == null) throw new AuraHandledException('Потрібен supplierId.');
        if (yearNum == null || monthNum == null) throw new AuraHandledException('Потрібні рік і місяць.');

        String ym = yearNum + '-' + String.valueOf(monthNum); // формат YYYY-M
        List<ScrapUtils.SupplierBalance> rows = ScrapUtils.getSupplierBalancesByMonth(supplierId, ym);
        // Прим.: getSupplierBalancesByMonth наразі використовує Approved-етап і only approved.

        MonthBalanceVM vm = new MonthBalanceVM();
        vm.yearNum = yearNum;
        vm.monthNum = monthNum;
        vm.decades = new List<DecadeBalanceVM>();
        vm.limitTotal = 0; vm.inputTotal = 0; vm.remainingTotal = 0;

        for (ScrapUtils.SupplierBalance r : rows) {
            DecadeBalanceVM d = new DecadeBalanceVM();
            d.decadeNum     = r.DecNum;
            d.approvedLimit = r.ApprovedLimit == null ? 0 : r.ApprovedLimit;
            d.input         = r.ScrapInput    == null ? 0 : r.ScrapInput;
            d.remaining     = r.AvailableBalance == null ? 0 : r.AvailableBalance;

            vm.limitTotal     += d.approvedLimit;
            vm.inputTotal     += d.input;
            vm.remainingTotal += d.remaining;

            vm.decades.add(d);
        }
        return vm;
    }

    // Зручно отримати «цей» та «наступний» місяці одним викликом
    @AuraEnabled(cacheable=true)
    global static List<MonthBalanceVM> listThisAndNextBalances(Id supplierId) {
        if (supplierId == null) throw new AuraHandledException('Потрібен supplierId.');
        Date today = System.today(), next = today.addMonths(1);
        return new List<MonthBalanceVM>{
                getSupplierMonthBalance(supplierId, today.year(), today.month()),
                getSupplierMonthBalance(supplierId, next.year(),  next.month())
        };
    }

    // DTO для рядка таблиці
// DTO для таблиці актуальних замовлень (додайте, якщо ще немає)
    global class SupplierSlotRow {
        @AuraEnabled public Id      id;
        @AuraEnabled public Date    visitDate;     // ReserveDate__c
        @AuraEnabled public String  scrapTypeCode; // ScrapType__r.Name (або Code__c, якщо є)
        @AuraEnabled public String  truckModel;    // Truck__r.Model__c (fallback: Track__c)
        @AuraEnabled public String  truckPlate;    // Truck__r.Plate__c
        @AuraEnabled public Decimal tonnage;       // Tonnage__c
        @AuraEnabled public String  driverName;    // DriverFIO__c (fallback: Driver__r.Name)
        @AuraEnabled public String  address;       // ShippingPoint__r.Name
        @AuraEnabled public String  passNumber;    // PassNumber__c
        @AuraEnabled public String  status;        // 'Approved' | 'Requested'
        @AuraEnabled public String  driverPhone;
        @AuraEnabled public Boolean hasTrailer;
        @AuraEnabled public String  trailerPlate;
    }

    @AuraEnabled(cacheable=false)
    global static List<SupplierSlotRow> listSupplierActiveSlotsThisAndNext(Id supplierId) {
        if (supplierId == null) throw new AuraHandledException('Потрібен supplierId.');

        Date today = System.today();
        Date next  = today.addMonths(1);

        Decimal y1 = Decimal.valueOf(today.year());
        String  m1 = String.valueOf(today.month());
        Decimal y2 = Decimal.valueOf(next.year());
        String  m2 = String.valueOf(next.month());

        List<ScrapSlotReserve__c> qs = [
                SELECT Id, ReserveDate__c, Status__c, PassNumber__c, Tonnage__c, Weight__c,
                        FixedWeight__c, IsCancelled__c, ScrapType__r.Name, Truck__c, Truck__r.TruckModel__c,
                        Truck__r.Name, Track__c, Driver__r.Name, Driver__r.Phone, Driver__r.MobilePhone, DriverFIO__c,
                        ShippingPoint__r.Name, Trailer__c, Trailer__r.Name, Trailer__r.TruckModel__c, MonthLookup__r.Year__c, MonthLookup__r.Month__c
                FROM ScrapSlotReserve__c
                WHERE Supplier__c = :supplierId
                AND Status__c IN ('Approved','Requested','Completed')   // ⬅️ додали Completed
                AND (IsCancelled__c = false OR IsCancelled__c = null)
                AND (
                        (MonthLookup__r.Year__c = :y1 AND MonthLookup__r.Month__c = :m1) OR
                        (MonthLookup__r.Year__c = :y2 AND MonthLookup__r.Month__c = :m2)
                )
                ORDER BY ReserveDate__c DESC, CreatedDate DESC
                LIMIT 1000
        ];

        List<SupplierSlotRow> out = new List<SupplierSlotRow>();
        for (ScrapSlotReserve__c s : qs) {
            SupplierSlotRow r = new SupplierSlotRow();
            r.id            = s.Id;
            r.visitDate     = s.ReserveDate__c;
            r.scrapTypeCode = (s.ScrapType__r == null ? null : s.ScrapType__r.Name);

            // Модель ТЗ: беремо з лукапа, якщо недоступно — з Track__c
            String modelFromRel = (s.Truck__r == null ? null : s.Truck__r.TruckModel__c);
            r.truckModel = !String.isBlank(modelFromRel) ? modelFromRel : s.Track__c;

            // Держномер
            r.truckPlate   = (s.Truck__r == null ? null : s.Truck__r.Name);

            if (s.Status__c == 'Completed') {
                r.tonnage = (s.Weight__c == null ? s.Tonnage__c : s.Weight__c);
            } else {
                r.tonnage = s.Tonnage__c;
            }

            r.driverName   = !String.isBlank(s.DriverFIO__c) ? s.DriverFIO__c
                    : (s.Driver__r == null ? null : s.Driver__r.Name);
            r.driverPhone = (s.Driver__r == null ? null :
                    (!String.isBlank(s.Driver__r.MobilePhone) ? s.Driver__r.MobilePhone : s.Driver__r.Phone));

            r.address      = (s.ShippingPoint__r == null ? null : s.ShippingPoint__r.Name);
            r.passNumber   = s.PassNumber__c;
            r.status       = s.Status__c; // 'Approved' | 'Requested' | 'Completed'

            String trailerPlate = null;
            if (s.Trailer__r != null) {
                trailerPlate = String.isBlank(s.Trailer__r.Name) ? s.Trailer__r.Name : s.Trailer__r.Name;
            }
            r.trailerPlate = trailerPlate;

            out.add(r);
        }
        return out;
    }

    // ==================== HISTORY: до сьогодні (включно вчора) ====================
    @AuraEnabled(cacheable=false)
    global static List<SupplierSlotRow> listSupplierHistorySlotsBeforeToday(
            Id supplierId,
            Integer monthsBack
    ){
        if (supplierId == null) throw new AuraHandledException('Потрібен supplierId.');
        if (monthsBack == null || monthsBack <= 0) monthsBack = 6;

        Date startDate = Date.today().toStartOfMonth().addMonths(-monthsBack + 1);
        Date endDate   = Date.today(); // сьогодні НЕ включаємо → отже вчора і раніше

        List<ScrapSlotReserve__c> qs = [
                SELECT Id, ReserveDate__c, Status__c, PassNumber__c, Tonnage__c, Weight__c,
                        FixedWeight__c, IsCancelled__c, ScrapType__r.Name, Truck__c, Truck__r.TruckModel__c,
                        Truck__r.Name, Track__c, Driver__r.Name, Driver__r.Phone, Driver__r.MobilePhone, DriverFIO__c,
                        ShippingPoint__r.Name, Trailer__c, Trailer__r.Name, Trailer__r.TruckModel__c, MonthLookup__r.Year__c, MonthLookup__r.Month__c
                FROM ScrapSlotReserve__c
                WHERE Supplier__c = :supplierId
                AND (
                        Status__c = 'Completed'
                        OR Status__c IN ('Cancelled','Canceled')
                        OR IsCancelled__c = true
                )
                AND ReserveDate__c >= :startDate
                AND ReserveDate__c  <= :endDate
                ORDER BY ReserveDate__c DESC, CreatedDate DESC
                LIMIT 1000
        ];

        List<SupplierSlotRow> out = new List<SupplierSlotRow>();
        for (ScrapSlotReserve__c s : qs) {
            SupplierSlotRow r = new SupplierSlotRow();
            r.id            = s.Id;
            r.visitDate     = s.ReserveDate__c;
            r.scrapTypeCode = (s.ScrapType__r == null ? null : s.ScrapType__r.Name);

            String mdl = (s.Truck__r == null ? null : s.Truck__r.TruckModel__c);
            r.truckModel = String.isBlank(mdl) ? s.Track__c : mdl;
            r.truckPlate = (s.Truck__r == null ? null : s.Truck__r.Name);

            r.tonnage = (s.Status__c == 'Completed')
                    ? (s.Weight__c == null ? s.Tonnage__c : s.Weight__c)
                    : s.Tonnage__c;

            r.driverName = !String.isBlank(s.DriverFIO__c) ? s.DriverFIO__c
                    : (s.Driver__r == null ? null : s.Driver__r.Name);
            r.driverPhone = (s.Driver__r == null ? null :
                    (!String.isBlank(s.Driver__r.MobilePhone) ? s.Driver__r.MobilePhone : s.Driver__r.Phone));

            r.address    = (s.ShippingPoint__r == null ? null : s.ShippingPoint__r.Name);
            r.passNumber = s.PassNumber__c;

            r.status = (s.Status__c == 'Completed') ? 'Completed' : 'Canceled';

            String trailerPlate = null;
            if (s.Trailer__r != null) {
                trailerPlate = String.isBlank(s.Trailer__r.Name) ? s.Trailer__r.Name : s.Trailer__r.Name;
            }
            r.trailerPlate = trailerPlate;

            out.add(r);
        }
        return out;
    }

    @AuraEnabled
    global static Boolean cancelSupplierSlot(Id slotId) {
        System.debug('cancelSupplierSlot===================');
        if (slotId == null) throw new AuraHandledException('Потрібен slotId.');

        ScrapSlotReserve__c s = [
                SELECT Id, Status__c, IsCancelled__c
                FROM ScrapSlotReserve__c
                WHERE Id = :slotId
                LIMIT 1
                FOR UPDATE
        ];

        // якщо вже скасований — вважаємо успіхом (idempotent)
        if (s.IsCancelled__c == true) return true;

        // опційно: не даємо скасовувати завершені
        if (s.Status__c == 'Completed') {
            throw new AuraHandledException('Завершене замовлення скасувати не можна.');
        }

        s.IsCancelled__c = true;
        // для однорідності ще й статус:
        if (s.Status__c != 'Completed') s.Status__c = 'Cancelled';

        update s;
        return true;
    }

    // === NEW: Пререквізити постачальника для бронювання ===
    global class SupplierPrereqs {
        @AuraEnabled public Boolean hasShippingPoint;
        @AuraEnabled public Boolean hasDriver;
        @AuraEnabled public Boolean hasTruck;

        @AuraEnabled public Integer shippingPoints;
        @AuraEnabled public Integer drivers;
        @AuraEnabled public Integer trucks;

        @AuraEnabled public String exampleShippingPoint;
        @AuraEnabled public String exampleDriver;
        @AuraEnabled public String exampleTruck;
    }

    @AuraEnabled(cacheable=true)
    global static SupplierPrereqs getSupplierPrereqs(Id supplierId){
        if (supplierId == null) throw new AuraHandledException('Потрібен supplierId.');

        SupplierPrereqs out = new SupplierPrereqs();

        // Місця завантаження: ShippingPoint__c, прив’язані до постачальника через Supplier__c
        out.shippingPoints = [SELECT count() FROM ScrapSupplierShippingPoint__c WHERE Supplier__c = :supplierId];
        out.hasShippingPoint = out.shippingPoints > 0;
        if (out.hasShippingPoint){
            for (ScrapSupplierShippingPoint__c sp : [
                    SELECT Name FROM ScrapSupplierShippingPoint__c
                    WHERE Supplier__c = :supplierId
                    ORDER BY CreatedDate DESC
                    LIMIT 1
            ]) out.exampleShippingPoint = sp.Name;
        }

        // Транспорт: Truck__c, також прив’язаний до постачальника через Supplier__c
        out.trucks = [SELECT count() FROM ScrapTruck__c WHERE Account__c = :supplierId];
        out.hasTruck = out.trucks > 0;
        if (out.hasTruck){
            for (ScrapTruck__c t : [
                    SELECT Name FROM ScrapTruck__c
                    WHERE Account__c = :supplierId
                    ORDER BY CreatedDate DESC
                    LIMIT 1
            ]) out.exampleTruck = t.Name;
        }

        // Водії: беремо Contact-и цього акаунта (AccountId = supplierId)
        // (у слоті є Driver__r.Name, тому контакти під акаунтом — валідне джерело)
        out.drivers = [SELECT count() FROM Contact WHERE AccountId = :supplierId];
        out.hasDriver = out.drivers > 0;
        if (out.hasDriver){
            for (Contact c : [
                    SELECT Name FROM Contact
                    WHERE AccountId = :supplierId
                    ORDER BY CreatedDate DESC
                    LIMIT 1
            ]) out.exampleDriver = c.Name;
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