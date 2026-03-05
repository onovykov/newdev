public with sharing class OrderItemStageResolver {

    private static Map<String,String> cache;

    private static void ensureLoaded() {
        if (cache != null) {
            return;
        }

        cache = new Map<String,String>();

        for (OrderItemStage__mdt r : [
            SELECT Code__c, StatusSF__c
            FROM OrderItemStage__mdt
        ]) {
            cache.put(r.Code__c, r.StatusSF__c);
        }
    }

    /**
     * Soft resolver.
     * Returns null if stage is unknown.
     */
    public static String resolve(String erpStage) {
        ensureLoaded();
        return cache.get(erpStage);
    }

    /**
     * Strict resolver.
     * Throws exception if ERP stage is unknown.
     */
    public static String resolveOrThrow(String erpStage) {
        ensureLoaded();

        String stage = cache.get(erpStage);

        if (stage == null) {
            System.debug(LoggingLevel.ERROR,
                'Unknown ERP stage: ' + erpStage
            );            
            throw new ERPStageMappingException(
                'Unknown ERP OrderItem stage: ' + erpStage
            );
        }
        return stage;
    }

}