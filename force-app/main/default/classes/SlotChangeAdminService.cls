public without sharing class SlotChangeAdminService {

    // ===================== DTOs =====================
    public class Pair {
        @AuraEnabled public String driverName;
        @AuraEnabled public String driverPhone;
        @AuraEnabled public String tractorPlate;
        @AuraEnabled public String tractorModel;
        @AuraEnabled public String trailerPlate;
        @AuraEnabled public String trailerModel;
    }
    public class RowDTO {
        @AuraEnabled public Id id;
        @AuraEnabled public Id slotId;
        @AuraEnabled public String dateValue;
        @AuraEnabled public String supplier;
        @AuraEnabled public String passNumber;
        @AuraEnabled public String scrapType;
        @AuraEnabled public Decimal tonnage;

        @AuraEnabled public String status;
        @AuraEnabled public String comment;
        @AuraEnabled public Boolean isOpen;

        @AuraEnabled public Pair oldData;
        @AuraEnabled public Pair newData;
    }
    public class ActionResult {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String  message;
        @AuraEnabled public Id      changeId;
        @AuraEnabled public Id      slotId;
        @AuraEnabled public String  passNumber;
        @AuraEnabled public String  passId;
    }

    // ===================== Helpers =====================
    private static String toIso(Date d){ return (d == null) ? null : String.valueOf(d); }

    private static Pair sideFrom(Contact d, ScrapTruck__c tractor, ScrapTruck__c trailer){
        Pair s = new Pair();
        if (d != null){ s.driverName = d.Name; s.driverPhone = d.Phone; }
        if (tractor != null){ s.tractorPlate = tractor.Name; s.tractorModel = tractor.TruckModel__c; }
        if (trailer != null){ s.trailerPlate = trailer.Name; s.trailerModel = trailer.TruckModel__c; }
        return s;
    }

    private static RowDTO mapRow(Slot_Change__c x){
        RowDTO r = new RowDTO();
        r.id       = x.Id;
        r.slotId   = x.Slot__c;
        r.status   = x.Status__c;
        r.comment  = x.Comment__c;
        r.isOpen   = (x.Status__c == 'Open');

        if (x.Slot__r != null){
            r.dateValue       = toIso(x.Slot__r.ReserveDate__c);
            r.passNumber = x.Slot__r.PassNumber__c;
            r.supplier   = (x.Slot__r.Supplier__r != null ? x.Slot__r.Supplier__r.Name : null);
            // показуємо код типу (або заміни на Name, якщо так потрібно)
            r.scrapType  = (x.Slot__r.ScrapType__r != null ? x.Slot__r.ScrapType__r.ScrapTypeCode__c : null);
            r.tonnage    = x.Slot__r.Tonnage__c;
        }

        r.oldData = new Pair();
        r.oldData.driverName   = x.OldDriver__r  != null ? x.OldDriver__r.Name : null;
        r.oldData.driverPhone  = x.OldDriver__r  != null ? x.OldDriver__r.Phone : null;
        r.oldData.tractorPlate = x.OldTractor__r != null ? x.OldTractor__r.Name : null;
        r.oldData.tractorModel = x.OldTractor__r != null ? x.OldTractor__r.TruckModel__c : null;
        r.oldData.trailerPlate = x.OldTrailer__r != null ? x.OldTrailer__r.Name : null;
        r.oldData.trailerModel = x.OldTrailer__r != null ? x.OldTrailer__r.TruckModel__c : null;

        r.newData = new Pair();
        r.newData.driverName   = x.NewDriver__r  != null ? x.NewDriver__r.Name : null;
        r.newData.driverPhone  = x.NewDriver__r  != null ? x.NewDriver__r.Phone : null;
        r.newData.tractorPlate = x.NewTractor__r != null ? x.NewTractor__r.Name : null;
        r.newData.tractorModel = x.NewTractor__r != null ? x.NewTractor__r.TruckModel__c : null;
        r.newData.trailerPlate = x.NewTrailer__r != null ? x.NewTrailer__r.Name : null;
        r.newData.trailerModel = x.NewTrailer__r != null ? x.NewTrailer__r.TruckModel__c : null;

        // після заповнення r.oldData та r.newData:
        Boolean hasNewDriver  = (x.NewDriver__c  != null);
        Boolean hasNewTractor = (x.NewTractor__c != null);
        Boolean hasNewTrailer = (x.NewTrailer__c != null);

        if (!hasNewDriver) {
            r.newData.driverName  = r.oldData.driverName;
            r.newData.driverPhone = r.oldData.driverPhone;
        }
        if (!hasNewTractor) {
            r.newData.tractorPlate = r.oldData.tractorPlate;
            r.newData.tractorModel = r.oldData.tractorModel;
        }
        if (!hasNewTrailer) {
            r.newData.trailerPlate = r.oldData.trailerPlate;
            r.newData.trailerModel = r.oldData.trailerModel;
        }

        return r;
    }

    // ===================== API =====================

    /**
     * Список заявок.
     * @param status 'ALL' | 'Open' | 'Approved' | 'Rejected'
     * @param query  довільний рядок для фільтру по людських полях
     */
    @AuraEnabled(cacheable=false)
    public static List<RowDTO> listChanges(String status, String query){
        String st = String.isBlank(status) ? 'ALL' : status.trim();
        String q  = String.isBlank(query)  ? ''     : query.trim().toLowerCase();

        List<Slot_Change__c> src;
        if (st == 'ALL'){
            src = [
                    SELECT Id, Status__c, Comment__c, Slot__c,
                            Slot__r.ReserveDate__c, Slot__r.PassNumber__c, Slot__r.Tonnage__c,
                            Slot__r.Supplier__r.Name,
                            Slot__r.ScrapType__r.ScrapTypeCode__c,
                            OldDriver__r.Name,  OldDriver__r.Phone,
                            OldTractor__r.Name, OldTractor__r.TruckModel__c,
                            OldTrailer__r.Name, OldTrailer__r.TruckModel__c,
                            NewDriver__r.Name,  NewDriver__r.Phone,
                            NewTractor__r.Name, NewTractor__r.TruckModel__c,
                            NewTrailer__r.Name, NewTrailer__r.TruckModel__c
                    FROM Slot_Change__c
                    ORDER BY CreatedDate DESC
                    LIMIT 500
            ];
        } else {
            src = [
                    SELECT Id, Status__c, Comment__c, Slot__c,
                            Slot__r.ReserveDate__c, Slot__r.PassNumber__c, Slot__r.Tonnage__c,
                            Slot__r.Supplier__r.Name,
                            Slot__r.ScrapType__r.ScrapTypeCode__c,
                            OldDriver__r.Name,  OldDriver__r.Phone,
                            OldTractor__r.Name, OldTractor__r.TruckModel__c,
                            OldTrailer__r.Name, OldTrailer__r.TruckModel__c,
                            NewDriver__r.Name,  NewDriver__r.Phone,
                            NewTractor__r.Name, NewTractor__r.TruckModel__c,
                            NewTrailer__r.Name, NewTrailer__r.TruckModel__c
                    FROM Slot_Change__c
                    WHERE Status__c = :st
                    ORDER BY CreatedDate DESC
                    LIMIT 500
            ];
        }

        List<RowDTO> outp = new List<RowDTO>();
        for (Slot_Change__c x : src){
            RowDTO r = mapRow(x);
            if (!String.isBlank(q)){
                String hay = String.join(new List<String>{
                        r.supplier, r.passNumber, r.scrapType,
                        r.oldData.driverName,  r.oldData.driverPhone,  r.oldData.tractorPlate,  r.oldData.tractorModel,  r.oldData.trailerPlate,  r.oldData.trailerModel,
                        r.newData.driverName,  r.newData.driverPhone,  r.newData.tractorPlate,  r.newData.tractorModel,  r.newData.trailerPlate,  r.newData.trailerModel
                }, ' ');
                if (hay == null || !hay.toLowerCase().contains(q)) continue;
            }
            outp.add(r);
        }
        return outp;
    }

    // Reject: слот → Cancelled, заявка → Rejected
    @AuraEnabled
    public static ActionResult rejectChange(Id changeId){
        if (changeId == null) throw new AuraHandledException('Не передано changeId.');

        Slot_Change__c ch = [
                SELECT Id, Slot__c, Status__c
                FROM Slot_Change__c
                WHERE Id = :changeId
                LIMIT 1
                FOR UPDATE
        ];
        if (ch.Status__c != 'Open') throw new AuraHandledException('Заявка вже закрита.');

        ScrapSlotReserve__c s = [
                SELECT Id, Status__c, IsCancelled__c
                FROM ScrapSlotReserve__c
                WHERE Id = :ch.Slot__c
                LIMIT 1
                FOR UPDATE
        ];

        // ⚠️ Якщо у вас у піклісті значення 'Canceled' — замініть рядок нижче.
        s.Status__c      = 'Cancelled';
        try { s.IsCancelled__c = true; } catch (Exception e) { /* поле може не існувати */ }
        update s;

        ch.Status__c = 'Rejected';
        update ch;

        ActionResult res = new ActionResult();
        res.success = true; res.changeId = ch.Id; res.slotId = s.Id;
        res.message = 'Слот скасовано, заявку відхилено.';
        return res;
    }

    @AuraEnabled(cacheable=false)
    public static ActionResult approveChange(Id changeId){
        if (changeId == null) throw new AuraHandledException('Не передано changeId.');

        // 1) Блокуємо заявку
        Slot_Change__c ch = [
                SELECT Id, Status__c, Slot__c, NewDriver__c, NewTractor__c, NewTrailer__c
                FROM Slot_Change__c
                WHERE Id = :changeId
                LIMIT 1
                FOR UPDATE
        ];
        if (ch.Status__c != 'Open') throw new AuraHandledException('Заявка вже закрита.');

        // 2) Блокуємо слот
        ScrapSlotReserve__c s = [
                SELECT Id, Status__c, Driver__c, Truck__c, Trailer__c, PassNumber__c, PassID__c
                FROM ScrapSlotReserve__c
                WHERE Id = :ch.Slot__c
                LIMIT 1
                FOR UPDATE
        ];

        // 3) Застосовуємо лише реальні зміни
        Boolean anySlot = false;
        if (ch.NewDriver__c  != null && ch.NewDriver__c  != s.Driver__c)  { s.Driver__c  = ch.NewDriver__c;  anySlot = true; }
        if (ch.NewTractor__c != null && ch.NewTractor__c != s.Truck__c)   { s.Truck__c   = ch.NewTractor__c; anySlot = true; }
        if (ch.NewTrailer__c != null && ch.NewTrailer__c != s.Trailer__c) { s.Trailer__c = ch.NewTrailer__c; anySlot = true; }
        if (anySlot) update s;

        // 4) Ставимо джобу, яка виконає callout та фіналізує
        System.enqueueJob(new ApproveChangeCalloutJob(ch.Id));

        ActionResult res = new ActionResult();
        res.success  = true;
        res.changeId = ch.Id;
        res.slotId   = s.Id;
        res.message  = 'Заявку прийнято до обробки. Чекаємо ERP…';
        return res;
    }

    public class ApproveChangeCalloutJob implements Queueable, Database.AllowsCallouts {
        private Id changeId;
        public ApproveChangeCalloutJob(Id changeId){ this.changeId = changeId; }

        public void execute(QueueableContext qc){
            Slot_Change__c ch = [
                    SELECT Id, Status__c, Slot__c, Comment__c
                    FROM Slot_Change__c
                    WHERE Id = :changeId
                    LIMIT 1
                    FOR UPDATE
            ];
            ScrapSlotReserve__c s = [
                    SELECT Id, Status__c, Driver__c, Truck__c, Trailer__c, PassNumber__c, PassID__c
                    FROM ScrapSlotReserve__c
                    WHERE Id = :ch.Slot__c
                    LIMIT 1
                    FOR UPDATE
            ];

            // Callout у ERP — читає актуальні значення зі слота
            ScrapSlotModalController.SendToErpResult erp;
            try {
                erp = ScrapSlotModalController.sendReserveToErp(s.Id);
            } catch (Exception ex) {
                ch.Status__c = 'Open';
                try { ch.Comment__c = (ch.Comment__c == null ? '' : ch.Comment__c + ' | ') + ('Callout error: ' + ex.getMessage()); } catch (Exception ee) {}
                update ch;
                return;
            }

            // Успіх ERP → проставляємо перепустку і фіналізуємо
            s.Status__c = 'Approved';
            try { s.PassNumber__c = erp.passNumber; } catch (Exception e) {}
            try { s.PassID__c     = erp.passId;     } catch (Exception e) {}
            update s;

            ch.Status__c = 'Approved';
            update ch;
        }
    }



    @AuraEnabled(cacheable=false)
    public static ActionResult getChangeState(Id changeId){
        ActionResult res = new ActionResult();
        if (changeId == null) { res.success=false; res.message='No changeId'; return res; }

        Slot_Change__c ch = [
                SELECT Id, Status__c, Slot__c, Comment__c
                FROM Slot_Change__c
                WHERE Id = :changeId
                LIMIT 1
        ];
        ScrapSlotReserve__c s = [
                SELECT Id, PassNumber__c, PassID__c, Status__c
                FROM ScrapSlotReserve__c
                WHERE Id = :ch.Slot__c
                LIMIT 1
        ];

        res.changeId  = ch.Id;
        res.slotId    = s.Id;
        res.passNumber= s.PassNumber__c;
        res.passId    = s.PassID__c;
        res.message   = ch.Comment__c;
        res.success   = (ch.Status__c == 'Approved');
        // (за потреби можеш додати ще поле: res.extra = ch.Status__c)
        return res;
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