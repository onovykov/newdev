public with sharing class OrderStageMetadataCache {

    private static Map<String,Integer> stageBits;
    private static String[] maskRules;

    public static Map<String,Integer> getStageBits() {

        if (stageBits != null) {
            return stageBits;
        }

        stageBits = new Map<String,Integer>();

        for (OrderItemStagePriority__mdt r : [
            SELECT Stage__c, Bit__c
            FROM OrderItemStagePriority__mdt
        ]) {
            stageBits.put(r.Stage__c, (Integer)r.Bit__c);
        }

        return stageBits;
    }

    public static String[] getMaskRules() {

        if (maskRules != null) {
            return maskRules;
        }

        maskRules = new String[32];

        for (OrderStageBitmaskRule__mdt r : [
            SELECT Mask__c, OrderStage__c
            FROM OrderStageBitmaskRule__mdt
        ]) {

            Integer mask = (Integer)r.Mask__c;

            if (mask >= 0 && mask < 32) {
                maskRules[mask] = r.OrderStage__c;
            }
        }

        return maskRules;
    }

    @TestVisible
    public static void reset() {
        stageBits = null;
        maskRules = null;
    }
}