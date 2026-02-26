public with sharing class UserAuditLogQueueable implements Queueable {

    private List<Field_Audit_Log__c> logs;

    public UserAuditLogQueueable(List<Field_Audit_Log__c> logs) {
        this.logs = logs;
    }

    public void execute(QueueableContext context) {
        if (logs == null || logs.isEmpty()) {
            return;
        }
        insert logs;
    }
}