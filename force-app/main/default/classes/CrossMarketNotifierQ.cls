// CrossMarketNotifierQ.cls
public class CrossMarketNotifierQ implements Queueable {
    private final List<Id> oppIds;

    public CrossMarketNotifierQ(List<Id> oppIds) {
        // defensive copy + null-safe
        this.oppIds = (oppIds == null) ? new List<Id>() : new List<Id>(oppIds);
    }

    public void execute(QueueableContext qc) {
        if (oppIds.isEmpty()) return;

        // 1) Витягуємо необхідні поля Opp
        List<Opportunity> opps = [
            SELECT Id, Name, OwnerId,
                   CrossMarketManager__c,
                   CrossMarketSegment__c,
                   CrossMarketShare__c
            FROM Opportunity
            WHERE Id IN :oppIds
        ];
        if (opps.isEmpty()) return;

        // 2) Формуємо повідомлення (по одному на кожного отримувача)
        List<Messaging.SingleEmailMessage> allMsgs = new List<Messaging.SingleEmailMessage>();
        List<Id> msgOppIds = new List<Id>(); // паралельний список для мапування результатів

        for (Opportunity o : opps) {
            Set<Id> recipients = new Set<Id>();
            if (o.CrossMarketManager__c != null) recipients.add(o.CrossMarketManager__c);
            if (o.OwnerId != null)               recipients.add(o.OwnerId);

            if (recipients.isEmpty()) continue;

            for (Id uid : recipients) {
                Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();
                msg.setTargetObjectId(uid);          // email береться з User.Email
                msg.setSaveAsActivity(false);
                msg.setSubject('Cross-market on Opportunity ' + o.Name);
                msg.setPlainTextBody(
                    'На опортюнті "' + o.Name + '" встановлено крос-сегмент:' + '\n' +
                    'Segment: ' + String.valueOf(o.CrossMarketSegment__c) + '\n' +
                    'Share: ' + String.valueOf(o.CrossMarketShare__c) + '%.'
                );
                allMsgs.add(msg);
                msgOppIds.add(o.Id);
            }
        }
        if (allMsgs.isEmpty()) return;

        // 3) Відправляємо батчами по 10 (ліміт SingleEmailMessage у транзакції)
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
                // за потреби: обробити results[j].getErrors()
            }
        }

        // 4) Позначаємо Notified, якщо був хоча б один успішний лист по оппі
        if (!oppsWithSuccess.isEmpty()) {
            List<Opportunity> toUpdate = new List<Opportunity>();
            for (Id oid : oppsWithSuccess) {
                toUpdate.add(new Opportunity(
                    Id = oid,
                    CrossMarketNotified__c = true,
                    CrossMarketNotifiedAt__c = System.now()
                ));
            }
            update toUpdate;
        }
    }
}