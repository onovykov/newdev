// CrossMarketWonNotifierQ.cls
public class CrossMarketWonNotifierQ implements Queueable {
    private final List<Id> oppIds;

    public CrossMarketWonNotifierQ(List<Id> oppIds) {
        // defensive copy + null-safe
        this.oppIds = (oppIds == null) ? new List<Id>() : new List<Id>(oppIds);
    }

    public void execute(QueueableContext qc) {
        if (oppIds.isEmpty()) return;

        // 1) Opps (мінімально потрібні поля)
        List<Opportunity> opps = [
            SELECT Id, Name,
                   CrossMarketSegment__c,
                   CrossMarketShare__c
            FROM Opportunity
            WHERE Id IN :oppIds
        ];
        if (opps.isEmpty()) return;

        // 2) Збираємо унікальні сегменти
        Set<String> segments = new Set<String>();
        for (Opportunity o : opps) {
            if (o.CrossMarketSegment__c != null) segments.add(o.CrossMarketSegment__c);
        }
        if (segments.isEmpty()) return;

        // 3) API-значення пікліста JobTitle__c (через ваш SysUtils)
        //    Нам потрібен саме "Sales Chief Officer"
        Map<String, String> jtLabelToValue =
            SysUtils.getPicklistFieldMap('User', 'JobTitle__c', /*valueAsKey*/ false);
        String CHIEF_API = jtLabelToValue.get('Sales Chief Officer');

        // 4) Тягнемо керівників по сегментах
        Map<String, List<User>> managersBySegment = new Map<String, List<User>>();
        for (User u : [
            SELECT Id, Name, Email, SalesDivision__c
            FROM User
            WHERE SalesDivision__c IN :segments
              AND JobTitle__c = :CHIEF_API
              AND IsActive = true
        ]) {
            List<User> bucket = managersBySegment.get(u.SalesDivision__c);
            if (bucket == null) {
                bucket = new List<User>();
                managersBySegment.put(u.SalesDivision__c, bucket);
            }
            bucket.add(u);
        }

        // 5) Формуємо повідомлення керівникам (по одному на користувача)
        List<Messaging.SingleEmailMessage> allMsgs = new List<Messaging.SingleEmailMessage>();
        List<Id> msgOppIds = new List<Id>();

        for (Opportunity o : opps) {
            List<User> managers = managersBySegment.get(o.CrossMarketSegment__c);
            if (managers == null || managers.isEmpty()) continue;

            for (User m : managers) {
                Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();
                msg.setTargetObjectId(m.Id);      // email береться з User.Email
                msg.setSaveAsActivity(false);
                msg.setSubject('Closed Won з крос-сегментом: ' + o.Name);
                msg.setPlainTextBody(
                    'Оппортюнті "' + o.Name + '" перейшла в Closed Won з крос-сегментом ' +
                    String.valueOf(o.CrossMarketSegment__c) + '.' + '\n' +
                    'Частка: ' + String.valueOf(o.CrossMarketShare__c) + '%.'
                );
                allMsgs.add(msg);
                msgOppIds.add(o.Id);
            }
        }
        if (allMsgs.isEmpty()) return;

        // 6) Батчимо відправку по 10 та збираємо успішні OppId
        Set<Id> oppsWithSuccess = new Set<Id>();
        final Integer BATCH = 10;
        Integer i = 0;
        while (i < allMsgs.size()) {
            List<Messaging.SingleEmailMessage> chunkMsgs = new List<Messaging.SingleEmailMessage>();
            List<Id> chunkOppIds = new List<Id>();

            Integer taken = 0;
            while (i < allMsgs.size() && taken < BATCH) {
                chunkMsgs.add(allMsgs[i]);
                chunkOppIds.add(msgOppIds[i]);
                i++; taken++;
            }

            Messaging.SendEmailResult[] results = Messaging.sendEmail(chunkMsgs);
            for (Integer j = 0; j < results.size(); j++) {
                if (results[j].isSuccess()) oppsWithSuccess.add(chunkOppIds[j]);
                // за потреби: results[j].getErrors()
            }
        }

        // 7) Позначаємо WonNotified тільки там, де був успіх
        if (!oppsWithSuccess.isEmpty()) {
            List<Opportunity> toUpdate = new List<Opportunity>();
            for (Id oid : oppsWithSuccess) {
                toUpdate.add(new Opportunity(
                    Id = oid,
                    CrossMarketWonNotified__c = true,
                    CrossMarketWonNotifiedAt__c = System.now()
                ));
            }
            update toUpdate;
        }
    }
}