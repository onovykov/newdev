public with sharing class InsertBatch
    implements Database.Batchable<SObject> {

    private List<SObject> records;

    public InsertBatch(List<SObject> records) {
        this.records = records;
    }

    public Iterable<SObject> start(Database.BatchableContext bc) {
        return records;
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        DmlService.insertRecords(scope, false);
    }

    public void finish(Database.BatchableContext bc) {}
}