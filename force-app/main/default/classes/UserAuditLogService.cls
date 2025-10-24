public class UserAuditLogService {
    @future
    public static void insertLogs(String jsonLogs) {
        List<UserAuditLog__c> logs = (List<UserAuditLog__c>) JSON.deserialize(jsonLogs, List<UserAuditLog__c>.class);
        insert logs;
    }
}