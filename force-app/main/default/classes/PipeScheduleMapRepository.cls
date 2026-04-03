public with sharing class PipeScheduleMapRepository {

    private static Map<String, List<PipeScheduleMap__mdt>> byDimp;
    private static Boolean loaded = false;

    public static List<PipeScheduleMap__mdt> getByDimp(String dimpHex) {
        ensureLoaded();
        return byDimp.get(dimpHex);
    }

    private static void ensureLoaded() {
        if (loaded) return;

        byDimp = new Map<String, List<PipeScheduleMap__mdt>>();

        for (PipeScheduleMap__mdt rec : [
            SELECT DIMP_Key__c, SCH__c, ForCarbonSteel__c, Priority__c
            FROM PipeScheduleMap__mdt
        ]) {
            if (!byDimp.containsKey(rec.DIMP_Key__c)) {
                byDimp.put(rec.DIMP_Key__c, new List<PipeScheduleMap__mdt>());
            }
            byDimp.get(rec.DIMP_Key__c).add(rec);
        }

        loaded = true;
    }

    public static void clearCache() {
        loaded = false;
        byDimp = null;
    }
}