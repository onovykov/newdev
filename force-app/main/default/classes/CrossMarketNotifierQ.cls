public class CrossMarketNotifierQ implements Queueable {

    private final List<Id> oppIds;
    public CrossMarketNotifierQ(List<Id> oppIds) {
        this.oppIds = (oppIds == null) ? new List<Id>() : new List<Id>(oppIds);
    }

    public void execute(QueueableContext qc) {
        if (oppIds.isEmpty()) return;

        // 1) Витягуємо потрібні Opp
        List<Opportunity> opps = [
            SELECT Id, Name, OwnerId,
                   CrossMarketManager__c,
                   CrossMarketSegment__c,
                   CrossMarketShare__c
            FROM Opportunity
            WHERE Id IN :oppIds
        ];
        if (opps.isEmpty()) return;

        // 2) Разово зчитуємо BO-групу та її користувачів
        Id boGroupId = null;
        List<Group> grList = [SELECT Id FROM Group WHERE Name='CrossMarketBO' AND Type='Regular' LIMIT 1];
        if (!grList.isEmpty()) boGroupId = grList[0].Id;

        Set<Id> boUserIds = new Set<Id>();
        if (boGroupId != null) {
            for (GroupMember gm : [SELECT UserOrGroupId FROM GroupMember WHERE GroupId = :boGroupId]) {
                // залишаємо лише користувачів
                String idStr = String.valueOf(gm.UserOrGroupId);
                if (idStr != null && idStr.startsWith('005')) {
                    boUserIds.add((Id)gm.UserOrGroupId);
                }
            }
        }

        // 3) Готуємо листи
        List<Messaging.SingleEmailMessage> allMsgs = new List<Messaging.SingleEmailMessage>();
        List<Id> msgOppIds = new List<Id>();

        for (Opportunity o : opps) {
            Set<Id> recipients = new Set<Id>();
            if (o.CrossMarketManager__c != null) recipients.add(o.CrossMarketManager__c);
            if (o.OwnerId != null)               recipients.add(o.OwnerId);
            if (!boUserIds.isEmpty())            recipients.addAll(boUserIds);

            if (recipients.isEmpty()) continue;

            for (Id uid : recipients) {
                Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();
                msg.setTargetObjectId(uid);
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

        // 4) Відправляємо батчами по 10 і збираємо, де було успішно
        final Integer BATCH = 10;
        Set<Id> oppsWithSuccess = new Set<Id>();

        for (Integer i = 0; i < allMsgs.size(); ) {
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
            }
        }

        // 5) Позначаємо Opp
        if (!oppsWithSuccess.isEmpty()) {
            List<Opportunity> toUpdate = new List<Opportunity>();
            for (Id oid : oppsWithSuccess) {
                toUpdate.add(new Opportunity(
                    Id = oid,
                    CrossMarketNotified__c   = true,
                    CrossMarketNotifiedAt__c = System.now()
                ));
            }
            update toUpdate;
        }
    }
}