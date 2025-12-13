public with sharing class SyncUsers {

    public static void syncUsersToERP() {

        List<User> users = [
            SELECT Id, LoginERP__c
            FROM User
            WHERE LoginERP__c != null
              AND IsActive = true
              AND SyncWithERP__c = true
        ];

        if (users.isEmpty()) {
            System.debug('SyncUsers: No users to sync');
            return;
        }

        // build JSON
        List<String> logins = new List<String>();
        for (User u : users) {
            if (String.isNotBlank(u.LoginERP__c)) {
                logins.add(u.LoginERP__c);
            }
        }

        String jsonPayload = JSON.serialize(new Map<String, Object>{ 'USERIDS' => logins });

        if (!Test.isRunningTest()) {
            System.enqueueJob(new SyncUsersQueueable(jsonPayload));
        }
    }
}