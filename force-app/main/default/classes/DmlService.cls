public with sharing class DmlService {

    public static List<Database.SaveResult> updateRecords(
        List<SObject> records,
        Boolean allOrNone
    ) {
        return Database.update(records, allOrNone);
    }

    public static List<Database.SaveResult> insertRecords(
        List<SObject> records,
        Boolean allOrNone
    ) {
        return Database.insert(records, allOrNone);
    }

    public static List<Database.UpsertResult> upsertRecords(
        List<SObject> records,
        Schema.SObjectField extId,
        Boolean allOrNone
    ) {
        return Database.upsert(records, extId, allOrNone);
    }

    public static void deleteRecords(
        List<SObject> records,
        Boolean allOrNone
    ) {
        Database.delete(records, allOrNone);
    }
}