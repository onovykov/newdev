public with sharing class PARPendingApprovalService {

    public static void syncStageTasks(
        PriceApprovalRequest__c par,
        String stageERPCode,
        String stageName,
        String ownersId
    ) {

        // 1️⃣ Resolve users (strict mode ON)
        ERPUserResolutionResult resolution =
            ERPUserResolverService.resolveFromOwnersId(
                ownersId,
                true
            );

        Map<String, User> usersByLogin =
            resolution.resolvedUsers;

        if(usersByLogin.isEmpty()){
            return;
        }

        // 2️⃣ Cancel old pending tasks
        cancelExistingPendingTasks(par.Id);

        // 3️⃣ Create new tasks
        List<PARPendingApproval__c> tasks =
            new List<PARPendingApproval__c>();

        for(String login : usersByLogin.keySet()){

            User u = usersByLogin.get(login);

            PARPendingApproval__c task =
                new PARPendingApproval__c();

            task.PAR__c = par.Id;
            task.Approver__c = u.Id;
            task.StageERP__c = stageERPCode;
            task.StageName__c = stageName;
            task.Status__c = 'Pending';
            task.CreatedFromERP__c = true;

            task.ExternalKey__c =
                buildExternalKey(par.ID_ERP__c,
                                 stageERPCode,
                                 login);

            tasks.add(task);
        }

        if(!tasks.isEmpty()){
            upsert tasks ExternalKey__c;
        }

        // 4️⃣ Notify users
        sendNotifications(tasks);
    }

    private static void cancelExistingPendingTasks(Id parId){

        List<PARPendingApproval__c> existing =
            [SELECT Id, Status__c
             FROM PARPendingApproval__c
             WHERE PAR__c = :parId
             AND Status__c = 'Pending'];

        for(PARPendingApproval__c t : existing){
            t.Status__c = 'Cancelled';
        }

        if(!existing.isEmpty()){
            update existing;
        }
    }

    private static String buildExternalKey(
        String parIdERP,
        String stageCode,
        String login
    ){
        return SysUtils.buildERPHash(
            new List<String>{
                parIdERP,
                stageCode,
                login
            }
        );
    }

    private static void sendNotifications(
        List<PARPendingApproval__c> tasks
    ){
        /*
        if(tasks.isEmpty()) return;

        Id notificationTypeId = getNotificationTypeId();

        List<Messaging.CustomNotification> notifications =
            new List<Messaging.CustomNotification>();

        for(PARPendingApproval__c t : tasks){

            Messaging.CustomNotification notification =
                new Messaging.CustomNotification();

            notification.setNotificationTypeId(notificationTypeId);
            notification.setTitle('New Price Approval Request');
            notification.setBody('You have a new document to confirm.');
            notification.setTargetId(t.PAR__c);
            notification.setRecipientIds(
                new List<Id>{ t.Approver__c }
            );

            notifications.add(notification);
        }

        if(!notifications.isEmpty()){
            Database.insert(notifications);
        }
            */
    }

    private static Id getNotificationTypeId(){

        return [
            SELECT Id
            FROM CustomNotificationType
            WHERE DeveloperName = 'PAR_Notification'
            LIMIT 1
        ].Id;
    }

}