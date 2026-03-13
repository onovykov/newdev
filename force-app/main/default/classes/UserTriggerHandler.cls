public with sharing class UserTriggerHandler {

    // === BYPASS для тестів ===
    @TestVisible
    static Boolean bypassUserIdErpCreation = false;

    /* =====================================================
       FIELD AUDIT — BULK HOOK
       ===================================================== */
    public static void beforeUpdateBulk(
        Map<Id, User> oldMap,
        Map<Id, User> newMap
    ) {
        FieldAuditService.publishChanges(oldMap, newMap);
    }

    /* =====================================================
       AFTER INSERT — LEGACY UserID_ERP__c LOGIC (Тимчасово для сумісності)
       ===================================================== */
    public static void afterInsert(List<User> newUsers) {
        if (Test.isRunningTest() && bypassUserIdErpCreation) {
            System.debug('\nBypass is ON\n');
            return;
        }

        List<UserID_ERP__c> recordsToInsert = new List<UserID_ERP__c>();

        for (User u : newUsers) {
            if (u.ID_ERP__c != null) {
                recordsToInsert.add(build(u.Id, u.ID_ERP__c));
            }
            if (u.LoginERP__c != null) {
                recordsToInsert.add(build(u.Id, u.LoginERP__c));
            }
            if (u.UID_ERP__c != null) {
                recordsToInsert.add(build(u.Id, u.UID_ERP__c));
            }
        }

        if (!recordsToInsert.isEmpty()) {
            System.enqueueJob(
                new UserIdErpQueueable(recordsToInsert)
            );
        }
        /*
        if (!recordsToInsert.isEmpty()) {
            System.enqueueJob(
                new InsertQueueable(
                    new List<UserID_ERP__c>(recordsToInsert)
                )
            );
        }
            */
        /*
        if (!recordsToInsert.isEmpty()) {
            insert recordsToInsert;
        }
            */
    }

    /* =====================================================
       HELPERS
       ===================================================== */
    @TestVisible
    private static UserID_ERP__c build(Id userId, String value) {
        return new UserID_ERP__c(
            User__c = userId,
            Name    = value
        );
    }
}