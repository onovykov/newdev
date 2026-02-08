public with sharing class OpportunityFieldAuditHook {

    /**
     * Bulk hook for field audit (before update only)
     */
    public static void beforeUpdate(
        Map<Id, Opportunity> oldMap,
        Map<Id, Opportunity> newMap
    ) {
        if (oldMap == null || newMap == null) return;
        if (oldMap.isEmpty()) return;

        FieldAuditService.publishChanges(
            oldMap,
            newMap
        );
    }
}