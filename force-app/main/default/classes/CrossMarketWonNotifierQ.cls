public class CrossMarketWonNotifierQ implements Queueable {

    private final List<Id> oppIds;
    public CrossMarketWonNotifierQ(List<Id> oppIds) {
        this.oppIds = (oppIds == null) ? new List<Id>() : new List<Id>(oppIds);
    }

    public void execute(QueueableContext qc) {
        if (oppIds.isEmpty()) return;

        // 1) Підтягуємо Opp (тільки потрібні поля)
        List<Opportunity> opps = [
            SELECT Id, Name, OwnerId,
                   CrossMarketManager__c,
                   CrossMarketSegment__c,
                   CrossMarketShare__c,
                   StageName
            FROM Opportunity
            WHERE Id IN :oppIds
        ];
        if (opps.isEmpty()) return;

        // 2) Група BO (разово)
        Id boGroupId = null;
        List<Group> grList = [SELECT Id FROM Group WHERE Name='CrossMarketBO' AND Type='Regular' LIMIT 1];
        if (!grList.isEmpty()) boGroupId = grList[0].Id;

        Set<Id> boUserIds = new Set<Id>();
        if (boGroupId != null) {
            for (GroupMember gm : [SELECT UserOrGroupId FROM GroupMember WHERE GroupId = :boGroupId]) {
                String idStr = String.valueOf(gm.UserOrGroupId);
                if (idStr != null && idStr.startsWith('005')) {
                    boUserIds.add((Id)gm.UserOrGroupId);
                }
            }
        }

        // 3) Будуємо листи лише для Closed Won
        List<Messaging.SingleEmailMessage> allMsgs = new List<Messaging.SingleEmailMessage>();
        List<Id> msgOppIds = new List<Id>();

        for (Opportunity o : opps) {
            if (o.StageName != 'Closed Won') continue;

            Set<Id> recipients = new Set<Id>();
            if (o.CrossMarketManager__c != null) recipients.add(o.CrossMarketManager__c);
            if (o.OwnerId != null)               recipients.add(o.OwnerId);
            if (!boUserIds.isEmpty())            recipients.addAll(boUserIds);

            if (recipients.isEmpty()) continue;

            for (Id uid : recipients) {
                Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();
                msg.setTargetObjectId(uid);
                msg.setSaveAsActivity(false);
                msg.setSubject('Cross-market WON on Opportunity ' + o.Name);
                msg.setPlainTextBody(
                    'Opportunity "' + o.Name + '" стала Closed Won.' + '\n' +
                    'Cross-market segment: ' + String.valueOf(o.CrossMarketSegment__c) + '\n' +
                    'Share: ' + String.valueOf(o.CrossMarketShare__c) + '%.'
                );
                allMsgs.add(msg);
                msgOppIds.add(o.Id);
            }
        }

        if (allMsgs.isEmpty()) return;

        // 4) Відправляємо батчами по 10
        final Integer BATCH = 10;
        Set<Id> oppsWithSuccess = new Set<Id>();

        for (Integer i = 0; i < allMsgs.size(); ) {
            List<Messaging.SingleEmailMessage> chunk = new List<Messaging.SingleEmailMessage>();
            List<Id> chunkOppIds = new List<Id>();
            Integer taken = 0;
            while (i < allMsgs.size() && taken < BATCH) {
                chunk.add(allMsgs[i]);
                chunkOppIds.add(msgOppIds[i]);
                i++; taken++;
            }
            Messaging.SendEmailResult[] res = Messaging.sendEmail(chunk);
            for (Integer j = 0; j < res.size(); j++) {
                if (res[j].isSuccess()) oppsWithSuccess.add(chunkOppIds[j]);
            }
        }

        // 5) Позначаємо Opp
        if (!oppsWithSuccess.isEmpty()) {
            List<Opportunity> toUpd = new List<Opportunity>();
            for (Id oid : oppsWithSuccess) {
                toUpd.add(new Opportunity(
                    Id = oid,
                    CrossMarketWonNotified__c   = true,
                    CrossMarketWonNotifiedAt__c = System.now()
                ));
            }
            update toUpd;
        }
    }
}