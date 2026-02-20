public with sharing class UserAuditHook {

    public static void afterUpdate(
        Map<Id, User> oldMap,
        Map<Id, User> newMap
    ) {
        // Safety-net для User (IsActive, LoginERP__c, etc.)
        FieldAuditService.publishChanges(oldMap, newMap);
    }
}
