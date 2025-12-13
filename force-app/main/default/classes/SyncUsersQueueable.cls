public with sharing class SyncUsersQueueable implements Queueable, Database.AllowsCallouts {

    private String jsonPayload;

    public SyncUsersQueueable(String jsonPayload) {
        this.jsonPayload = jsonPayload;
    }

    public void execute(QueueableContext qc) {

        List<String> logins = SyncUsersERPClient.getLoginsToDeactivate(jsonPayload);

        if (logins.isEmpty()) {
            System.debug('SyncUsersQueueable: No logins returned from ERP');
            return;
        }

        SyncUsersService.deactivateUsersByLogin(logins);
    }
}