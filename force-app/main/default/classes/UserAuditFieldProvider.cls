public with sharing class UserAuditFieldProvider {

    private static Set<String> cachedFields;

    public static Set<String> getEnabledFields() {
        if (cachedFields != null) {
            return cachedFields;
        }

        cachedFields = new Set<String>();

        for (UserAuditFields__mdt cfg : [
            SELECT FieldApiName__c
            FROM UserAuditFields__mdt
            WHERE IsAuditEnabled__c = true
        ]) {
            cachedFields.add(cfg.FieldApiName__c);
        }

        return cachedFields;
    }

    @TestVisible
    static void clearCache() {
        cachedFields = null;
    }
}