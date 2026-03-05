public with sharing class StageBitRegistry {

    private static Map<String,Integer> bits;

    private static void ensureLoaded() {
        if (bits != null) {
            return;
        }

        bits = new Map<String,Integer>();

        for (OrderItemStagePriority__mdt r : [
            SELECT Stage__c, Priority__c
            FROM OrderItemStagePriority__mdt
        ]) {
            Integer bit =
                1 << ((Integer)r.Priority__c - 1);

            bits.put(r.Stage__c, bit);
        }
    }

    public static Integer getBit(String stage) {
        ensureLoaded();
        return bits.get(stage);
    }
}