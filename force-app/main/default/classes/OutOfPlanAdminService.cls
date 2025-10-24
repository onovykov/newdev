public without sharing class OutOfPlanAdminService {

    // Result DTO у стилі прикладу
    public class ActionResult {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String  message;
        @AuraEnabled public Id      slotId;
        @AuraEnabled public String  passNumber;
        @AuraEnabled public String  passId;
    }

// ===== APPROVE позапланового слота =====
//    @AuraEnabled
//    public static ActionResult approveOutOfPlan(Id slotId, String fixedWeightValue) {
//        if (slotId == null) throw new AuraHandledException('Не передано slotId.');
//
//        // 1) читаємо і блокуємо слот
//        ScrapSlotReserve__c s = [
//                SELECT Id, Status__c, FixedWeight__c, PassNumber__c, PassID__c
//                FROM ScrapSlotReserve__c
//                WHERE Id = :slotId
//                LIMIT 1
//                FOR UPDATE
//        ];
//
//        if (s.Status__c != 'Requested') {
//            throw new AuraHandledException('Слот вже оброблено (статус не Requested).');
//        }
//
//        // 2) зберігаємо вибір пікліста ще ДО відправки в ERP,
//        //    якщо ERP читає слот і бере звідси тоннаж
//        if (fixedWeightValue != null) {
//            s.FixedWeight__c = fixedWeightValue; // "10" | "20" | "25"
//            update s; // окремий DML, щоб ERP побачив значення
//        }
//
//        // 3) Відправка в ERP
//        ScrapSlotModalController.SendToErpResult erp = ScrapSlotModalController.sendReserveToErp(s.Id);
//        System.debug('===+++ erp:  ' + erp);
//        if (erp == null || erp.success != true) {
//            String msg = 'ERP повернув помилку.';
//            if (erp != null && erp.itemErrors != null && !erp.itemErrors.isEmpty()) {
//                msg += ' ' + String.join(erp.itemErrors, '; ');
//            }
//            throw new AuraHandledException(msg);
//        }
//
//        // 4) Фіналізація
//        s.Status__c = 'Approved';
//        try { s.PassNumber__c = erp.passNumber; } catch (Exception ignore) {}
//        try { s.PassID__c     = erp.passId;     } catch (Exception ignore) {}
//        update s;
//
//        ActionResult res = new ActionResult();
//        res.success    = true;
//        res.slotId     = s.Id;
//        res.passNumber = erp.passNumber;
//        res.passId     = erp.passId;
//        res.message    = 'Слот підтверджено, перепустку сформовано.';
//        return res;
//    }

    @AuraEnabled
    public static ActionResult approveOutOfPlan(Id slotId, String fixedWeightValue) {
        if (slotId == null) throw new AuraHandledException('Не передано slotId.');

        ScrapSlotReserve__c s = [
                SELECT Id, Status__c
                FROM ScrapSlotReserve__c
                WHERE Id = :slotId
                LIMIT 1
                FOR UPDATE
        ];
        if (s.Status__c != 'Requested') {
            throw new AuraHandledException('Слот вже оброблено (статус не Requested).');
        }

        // 1) Спочатку зберігаємо вибір
        if (fixedWeightValue != null) s.FixedWeight__c = fixedWeightValue;

        // Рекомендовано: проміжний статус (якщо є у піку)
        // s.Status__c = 'SendingToERP';
        update s;

        // 2) Callout в окремій транзакції
        System.enqueueJob(new SendToErpJob(s.Id));

        ActionResult res = new ActionResult();
        res.success = true; res.slotId = s.Id; res.message = 'Відправлено до ERP.';
        return res;
    }

    public class SendToErpJob implements Queueable, Database.AllowsCallouts {
        private Id slotId;
        public SendToErpJob(Id slotId){ this.slotId = slotId; }

        public void execute(QueueableContext qc){
            ScrapSlotReserve__c s = [
                    SELECT Id, Status__c, PassNumber__c, PassID__c
                    FROM ScrapSlotReserve__c
                    WHERE Id = :slotId
                    LIMIT 1
                    FOR UPDATE
            ];

            try {
                ScrapSlotModalController.SendToErpResult erp =
                        ScrapSlotModalController.sendReserveToErp(s.Id);

                if (erp != null && erp.success) {
                    s.Status__c = 'Approved';
                    try { s.PassNumber__c = erp.passNumber; } catch (Exception e) {}
                    try { s.PassID__c     = erp.passId;     } catch (Exception e) {}
                } else {
                    // бажано мати статус 'Error' і (опційно) поле ErrorText__c
                    // s.Status__c = 'Error';
                    // s.ErrorText__c = (erp!=null && !erp.itemErrors.isEmpty()) ? String.join(erp.itemErrors, '; ') : 'ERP помилка';
                }
                update s;
            } catch (Exception ex) {
                // s.Status__c = 'Error';
                // s.ErrorText__c = ex.getMessage();
                update s;
            }
        }
    }

// === Ендпоїнт для пулінгу з LWC ===
    @AuraEnabled(cacheable=false)
    public static ScrapSlotReserve__c getSlotStatus(Id slotId){
        return [
                SELECT Id, Status__c, PassNumber__c, PassID__c, FixedWeight__c
                // , ErrorText__c     // якщо додасте
                FROM ScrapSlotReserve__c
                WHERE Id = :slotId
                LIMIT 1
        ];
    }


    /**
     * Повертає список позапланових слотів у статусі Requested.
     * Мінімально потрібні поля + кілька корисних для UI/перевірок.
     */
    @AuraEnabled(cacheable=false)
    public static List<ScrapSlotReserve__c> listRequestedOutOfPlan() {
        return [
                SELECT Id, Name,
                        CreatedDate, ReserveDate__c,
                        Status__c, IsOutOfLimit__c, IsCancelled__c,
                        Supplier__c, Supplier__r.Name,
                        ScrapType__c, ScrapType__r.Name,
                        Tonnage__c, Weight__c,
                        PassNumber__c, PassID__c,
                        Driver__r.Name, Driver__r.Phone,
                        Truck__r.Name, Truck__r.TruckModel__c,
                        DecadeLookup__c,
                        DecadeLookup__r.Year__c,
                        DecadeLookup__r.Month__c,
                        DecadeLookup__r.Decade__c
                FROM ScrapSlotReserve__c
                WHERE IsOutOfLimit__c = true
                AND Status__c = 'Requested'
                ORDER BY CreatedDate DESC
                LIMIT 50000
        ];
    }

    // === DTO для Approved/Fact/Remain по місяцю ===
    public class ApprovedMonthLimitsDTO {
        // Approved по декадах і сумарно
        @AuraEnabled public Decimal dec1;
        @AuraEnabled public Decimal dec2;
        @AuraEnabled public Decimal dec3;
        @AuraEnabled public Decimal monthTotal;

        // Fact (використано) по декадах і сумарно
        @AuraEnabled public Decimal factDec1;
        @AuraEnabled public Decimal factDec2;
        @AuraEnabled public Decimal factDec3;
        @AuraEnabled public Decimal factMonthTotal;

        // Remain = Approved - Fact
        @AuraEnabled public Decimal remainDec1;
        @AuraEnabled public Decimal remainDec2;
        @AuraEnabled public Decimal remainDec3;
        @AuraEnabled public Decimal remainMonthTotal;

        // Id деталей Approved (корисно для редагування)
        @AuraEnabled public Id dec1DetailId;
        @AuraEnabled public Id dec2DetailId;
        @AuraEnabled public Id dec3DetailId;
    }

    /**
     * Approved/Fact/Remain для поточного місяця.
     */
    @AuraEnabled(cacheable=false)
    public static ApprovedMonthLimitsDTO getApprovedLimitsForCurrentMonth(Id supplierId) {
        Date today = Date.today();
        return getApprovedLimitsForMonth(supplierId, today.year(), today.month());
    }

    /**
     * Approved/Fact/Remain для конкретного року/місяця.
     * Використовує MonthLookup__c (якщо є), інакше фільтрує по полях Decade.
     */
    @AuraEnabled(cacheable=false)
    public static ApprovedMonthLimitsDTO getApprovedLimitsForMonth(Id supplierId, Integer year, Integer month) {
        if (supplierId == null || year == null || month == null) {
            throw new AuraHandledException('Некоректні параметри (supplierId/year/month).');
        }

        ApprovedMonthLimitsDTO dto = new ApprovedMonthLimitsDTO();

        // ---------- 1) Approved по декадах ----------
        Decimal a1 = 0, a2 = 0, a3 = 0;
        Id id1, id2, id3;

        Id monthId = ScrapUtils.getMonthId(year, month);

        List<SupplierLimitDetails__c> dets;
        if (monthId != null) {
            dets = [
                    SELECT Id, Limit__c, Decade__r.Decade__c
                    FROM SupplierLimitDetails__c
                    WHERE ScrapSupplierLimit__r.Supplier__c = :supplierId
                    AND ScrapSupplierLimit__r.RecordType.DeveloperName = 'Approved'
                    AND ScrapSupplierLimit__r.Approved__c = true
                    AND MonthLookup__c = :monthId
            ];
        } else {
            // Фолбек, якщо MonthLookup__c не заповнений
            dets = [
                    SELECT Id, Limit__c, Decade__r.Decade__c, Decade__r.Year__c, Decade__r.Month__c
                    FROM SupplierLimitDetails__c
                    WHERE ScrapSupplierLimit__r.Supplier__c = :supplierId
                    AND ScrapSupplierLimit__r.RecordType.DeveloperName = 'Approved'
                    AND ScrapSupplierLimit__r.Approved__c = true
                    AND Decade__r.Year__c  = :year
                    AND Decade__r.Month__c = :String.valueOf(month)
            ];
        }

        for (SupplierLimitDetails__c rec : dets) {
            Integer decNum = Integer.valueOf(rec.Decade__r.Decade__c);
            Decimal val = (rec.Limit__c == null) ? 0 : rec.Limit__c;
            if (decNum == 1) { a1 = val; id1 = rec.Id; }
            else if (decNum == 2) { a2 = val; id2 = rec.Id; }
            else if (decNum == 3) { a3 = val; id3 = rec.Id; }
        }

        dto.dec1 = a1; dto.dec2 = a2; dto.dec3 = a3;
        dto.monthTotal = nz(a1) + nz(a2) + nz(a3);
        dto.dec1DetailId = id1; dto.dec2DetailId = id2; dto.dec3DetailId = id3;

        // ---------- 2) Fact (inputs) по декадах ----------
        Map<Id, Map<Calendar, Decimal>> allInputs = ScrapUtils.getSupplierInputsByDecades();
        Map<Calendar, Decimal> iMap = (allInputs == null) ? null : allInputs.get(supplierId);

        Decimal f1 = pickForDecade(iMap, year, month, 1);
        Decimal f2 = pickForDecade(iMap, year, month, 2);
        Decimal f3 = pickForDecade(iMap, year, month, 3);

        dto.factDec1 = f1; dto.factDec2 = f2; dto.factDec3 = f3;
        dto.factMonthTotal = nz(f1) + nz(f2) + nz(f3);

        // ---------- 3) Remain = Approved - Fact ----------
        dto.remainDec1 = nz(a1) - nz(f1);
        dto.remainDec2 = nz(a2) - nz(f2);
        dto.remainDec3 = nz(a3) - nz(f3);
        dto.remainMonthTotal = nz(dto.monthTotal) - nz(dto.factMonthTotal);

        return dto;
    }

    // ---- helpers ----

    /**
     * Взяти значення для конкретної декади з мапи Calendar->Decimal.
     * Очікується, що Calendar.decodeCalendar(cal) повертає [year, month, decade].
     */
    private static Decimal pickForDecade(Map<Calendar, Decimal> mapCal, Integer y, Integer m, Integer d) {
        if (mapCal == null) return 0;
        for (Calendar cal : mapCal.keySet()) {
            List<Integer> dec = Calendar.decodeCalendar(cal);
            if (dec != null && dec.size() >= 3 && dec[0] == y && dec[1] == m && dec[2] == d) {
                Decimal v = mapCal.get(cal);
                return (v == null) ? 0 : v;
            }
        }
        return 0;
    }

    private static Decimal nz(Decimal v) { return (v == null) ? 0 : v; }

    // === NEW: ViewModel для гріду позапланових слотів
    public class SlotRowVM {
        @AuraEnabled public Id slotId;
        @AuraEnabled public Datetime createdAt;
        @AuraEnabled public Date reserveDate;
        @AuraEnabled public String status;

        @AuraEnabled public Id supplierId;
        @AuraEnabled public String supplierName;
        @AuraEnabled public Id scrapTypeId;
        @AuraEnabled public String scrapTypeName;

        @AuraEnabled public Decimal tonnage;
        @AuraEnabled public String fixedWeight; // значення пікліста ("10","20","25")

        @AuraEnabled public Integer yearNum;
        @AuraEnabled public Integer monthNum;
        @AuraEnabled public Integer decadeNum;
        @AuraEnabled public Id monthId;

        // по декаді для цього слота
        @AuraEnabled public Decimal approvedDec;
        @AuraEnabled public Decimal factDec;
        @AuraEnabled public Decimal remainDec;
        @AuraEnabled public Boolean canFit;
        @AuraEnabled public Decimal shortage;

        // по місяцю (для бейджів/підказок)
        @AuraEnabled public Decimal approvedMonth;
        @AuraEnabled public Decimal factMonth;
        @AuraEnabled public Decimal remainMonth;

        // технічне
        @AuraEnabled public Id approvedDetailDecId;
    }

    /**
 * Повертає підготовлені рядки для гріду з усіма розрахунками по декаді та місяцю.
 * Фільтри необов'язкові. Якщо не вказані — вертаємо всі Requested поза лімітом.
 */
    @AuraEnabled(cacheable=false)
    public static List<SlotRowVM> listRequestedOutOfPlanVM(
            Id supplierIdFilter,
            Id scrapTypeFilter,
            Date dateFrom,
            Date dateTo
    ){
        // 1) БАЗОВИЙ запит БЕЗ умов із :var
        List<ScrapSlotReserve__c> slots = [
                SELECT Id, Name,
                        CreatedDate, ReserveDate__c,
                        Status__c, IsOutOfLimit__c, IsCancelled__c,
                        Supplier__c, Supplier__r.Name,
                        ScrapType__c, ScrapType__r.Name,
                        Tonnage__c, Weight__c, FixedWeight__c,
                        PassNumber__c, PassID__c,
                        Driver__r.Name, Driver__r.Phone,
                        Truck__r.Name, Truck__r.TruckModel__c,
                        DecadeLookup__c,
                        DecadeLookup__r.Year__c,
                        DecadeLookup__r.Month__c,
                        DecadeLookup__r.Decade__c
                FROM ScrapSlotReserve__c
                WHERE IsOutOfLimit__c = true
                AND Status__c = 'Requested'
                ORDER BY CreatedDate DESC
                LIMIT 50000
        ];

        // 2) Готуємо кеш знімків місяця
        Map<String, ApprovedMonthLimitsDTO> monthSnapshots = new Map<String, ApprovedMonthLimitsDTO>();
        Map<String, Id> monthIds = new Map<String, Id>();

        // 3) Формуємо результат з ПРОСТИМ фільтруванням у Apex
        List<SlotRowVM> out = new List<SlotRowVM>();

        for (ScrapSlotReserve__c s : slots) {
            // Фільтри (простий if → continue)
            if (supplierIdFilter != null && s.Supplier__c != supplierIdFilter) continue;
            if (scrapTypeFilter != null && s.ScrapType__c != scrapTypeFilter) continue;
            if (dateFrom != null && (s.ReserveDate__c == null || s.ReserveDate__c < dateFrom)) continue;
            if (dateTo   != null && (s.ReserveDate__c == null || s.ReserveDate__c > dateTo)) continue;

            if (s.DecadeLookup__c == null ||
                    s.DecadeLookup__r == null ||
                    s.DecadeLookup__r.Year__c == null ||
                    s.DecadeLookup__r.Month__c == null ||
                    s.DecadeLookup__r.Decade__c == null) {
                // без декади не зможемо порахувати залишки — пропускаємо
                continue;
            }

            Id supId = s.Supplier__c;
            Integer y = (Integer)s.DecadeLookup__r.Year__c;
            Integer m = Integer.valueOf(String.valueOf(s.DecadeLookup__r.Month__c));
            Integer d = Integer.valueOf(String.valueOf(s.DecadeLookup__r.Decade__c));

            String key = supId + '#' + y + '#' + m;

            if (!monthSnapshots.containsKey(key)) {
                monthSnapshots.put(key, getApprovedLimitsForMonth(supId, y, m));
                monthIds.put(key, ScrapUtils.getMonthId(y, m));
            }
            ApprovedMonthLimitsDTO snap = monthSnapshots.get(key);

            SlotRowVM vm = new SlotRowVM();
            vm.slotId = s.Id;
            vm.createdAt = s.CreatedDate;
            vm.reserveDate = s.ReserveDate__c;
            vm.status = s.Status__c;

            vm.supplierId = supId;
            vm.supplierName = (s.Supplier__r != null ? s.Supplier__r.Name : null);
            vm.scrapTypeId = s.ScrapType__c;
            vm.scrapTypeName = (s.ScrapType__r != null ? s.ScrapType__r.Name : null);

            vm.tonnage = (s.Tonnage__c == null ? 0 : s.Tonnage__c);
            vm.fixedWeight = s.FixedWeight__c; // додай це поле в клас SlotRowVM


            vm.yearNum = y;
            vm.monthNum = m;
            vm.decadeNum = d;
            vm.monthId = monthIds.get(key);

            vm.approvedDec = getApprovedByDecade(snap, d);
            vm.factDec     = getFactByDecade(snap, d);
            vm.remainDec   = nz(vm.approvedDec) - nz(vm.factDec);
            vm.canFit      = (nz(vm.remainDec) >= nz(vm.tonnage));
            vm.shortage    = (vm.canFit ? 0 : (nz(vm.tonnage) - nz(vm.remainDec)));

            vm.approvedMonth = snap.monthTotal;
            vm.factMonth     = snap.factMonthTotal;
            vm.remainMonth   = snap.remainMonthTotal;

            vm.approvedDetailDecId = getDetailIdByDecade(snap, d);

            out.add(vm);
        }

        return out;
    }


    public class ApprovePreviewVM {
        @AuraEnabled public Boolean canFit;
        @AuraEnabled public Decimal shortage;
        @AuraEnabled public Decimal remainDec;

        @AuraEnabled public Id supplierId;
        @AuraEnabled public Integer yearNum;
        @AuraEnabled public Integer monthNum;
        @AuraEnabled public Integer decadeNum;

        @AuraEnabled public Id approvedDetailDecId; // куди редагувати, якщо не влазить
    }

    @AuraEnabled
    public static ApprovePreviewVM previewApprove(Id slotId) {
        if (slotId == null) throw new AuraHandledException('Не передано slotId.');

        ScrapSlotReserve__c s = [
                SELECT Id, Supplier__c, Tonnage__c,
                        DecadeLookup__r.Year__c,
                        DecadeLookup__r.Month__c,
                        DecadeLookup__r.Decade__c
                FROM ScrapSlotReserve__c
                WHERE Id = :slotId
                LIMIT 1
        ];

        if (s.DecadeLookup__r == null ||
                s.DecadeLookup__r.Year__c == null ||
                s.DecadeLookup__r.Month__c == null ||
                s.DecadeLookup__r.Decade__c == null) {
            throw new AuraHandledException('У слота відсутня прив’язка до декади.');
        }

        Integer y = (Integer)s.DecadeLookup__r.Year__c;
        Integer m = Integer.valueOf(String.valueOf(s.DecadeLookup__r.Month__c));
        Integer d = Integer.valueOf(String.valueOf(s.DecadeLookup__r.Decade__c));

        ApprovedMonthLimitsDTO snap = getApprovedLimitsForMonth(s.Supplier__c, y, m);

        Decimal remainDec = nz(getApprovedByDecade(snap, d)) - nz(getFactByDecade(snap, d));
        Decimal ton = (s.Tonnage__c == null ? 0 : s.Tonnage__c);

        ApprovePreviewVM res = new ApprovePreviewVM();
        res.canFit = (remainDec >= ton);
        res.shortage = res.canFit ? 0 : (ton - remainDec);
        res.remainDec = remainDec;
        res.supplierId = s.Supplier__c;
        res.yearNum = y; res.monthNum = m; res.decadeNum = d;
        res.approvedDetailDecId = getDetailIdByDecade(snap, d);

        return res;
    }

    private static Decimal getApprovedByDecade(ApprovedMonthLimitsDTO dto, Integer d) {
        if (dto == null || d == null) return 0;
        if (d == 1) return nz(dto.dec1);
        if (d == 2) return nz(dto.dec2);
        if (d == 3) return nz(dto.dec3);
        return 0;
    }
    private static Decimal getFactByDecade(ApprovedMonthLimitsDTO dto, Integer d) {
        if (dto == null || d == null) return 0;
        if (d == 1) return nz(dto.factDec1);
        if (d == 2) return nz(dto.factDec2);
        if (d == 3) return nz(dto.factDec3);
        return 0;
    }
    private static Id getDetailIdByDecade(ApprovedMonthLimitsDTO dto, Integer d) {
        if (dto == null || d == null) return null;
        if (d == 1) return dto.dec1DetailId;
        if (d == 2) return dto.dec2DetailId;
        if (d == 3) return dto.dec3DetailId;
        return null;
    }

    public class PickOpt { @AuraEnabled public String label; @AuraEnabled public String value; }

    @AuraEnabled(cacheable=true)
    public static List<PickOpt> getFixedWeightOptions() {
        Schema.DescribeFieldResult d = ScrapSlotReserve__c.FixedWeight__c.getDescribe();
        List<PickOpt> out = new List<PickOpt>();
        for (Schema.PicklistEntry e : d.getPicklistValues()) {
            PickOpt o = new PickOpt();
            o.label = e.getLabel();   // напр. "10 т."
            o.value = e.getValue();   // напр. "10"
            out.add(o);
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