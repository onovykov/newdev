public with sharing class BitmaskRuleEngine {

    private static Map<Integer,String> rules;
    private static void ensureLoaded() {
        if (rules != null) {
            return;
        }

        rules = new Map<Integer,String>();

        for (OrderStageBitmaskRule__mdt r : [
            SELECT Mask__c, OrderStage__c
            FROM OrderStageBitmaskRule__mdt
        ]) {
            rules.put((Integer)r.Mask__c, r.OrderStage__c);
        }
    }

    public static String resolve(Integer mask) {
        ensureLoaded();

        String stage = rules.get(mask);

        if (stage == null) {
            throw new AuraHandledException(
                'Unknown order stage mask: ' + mask
            );
        }

        return stage;
    }
}