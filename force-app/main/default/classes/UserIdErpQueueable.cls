public with sharing class UserIdErpQueueable implements Queueable {

    private List<UserID_ERP__c> recordsToInsert;

    public UserIdErpQueueable(List<UserID_ERP__c> recordsToInsert) {
        this.recordsToInsert = recordsToInsert;
    }

    public void execute(QueueableContext context) {
        if (recordsToInsert == null || recordsToInsert.isEmpty()) {
            return;
        }
        insert recordsToInsert;
    }
}