public with sharing class NotificationLogController {
    @AuraEnabled(cacheable=true)
    public static List<Notification_Log__c> fetchLogs(String eventKey, String status, String contextId){
        String soql = 'SELECT Id, CreatedDate, EventKey__c, Status__c, Channel__c, RecipientsCount__c, ContextSObjectType__c, ContextRecordId__c FROM Notification_Log__c WHERE Id != null';
        if (!String.isBlank(eventKey)) soql += ' AND EventKey__c = :eventKey';
        if (!String.isBlank(status)) soql += ' AND Status__c = :status';
        if (!String.isBlank(contextId)) soql += ' AND ContextRecordId__c = :contextId';
        soql += ' ORDER BY CreatedDate DESC LIMIT 500';
        return Database.query(soql);
    }
}