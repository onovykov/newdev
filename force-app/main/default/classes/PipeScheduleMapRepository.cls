public with sharing class PipeScheduleMapRepository {

    private static Map<String, PipeScheduleMap__mdt> byComposite;
    private static Boolean loaded = false;

    public static PipeScheduleMap__mdt getByComposite(String key) {
        ensureLoaded();
        return byComposite.get(key);
    }

    private static void ensureLoaded() {
        if (loaded) return;

        byComposite = new Map<String, PipeScheduleMap__mdt>();

        for (PipeScheduleMap__mdt rec : [
            SELECT CompositeKey__c, SCH__c, Priority__c
            FROM PipeScheduleMap__mdt
        ]) {
            byComposite.put(rec.CompositeKey__c, rec);
        }

        loaded = true;
    }

    public static void clearCache() {
        loaded = false;
        byComposite = null;
    }
}