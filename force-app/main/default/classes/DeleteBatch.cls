public with sharing class DeleteBatch
    implements Database.Batchable<SObject> {

    private List<SObject> records;

    public DeleteBatch(List<SObject> records) {
        this.records = records;
    }

    public Iterable<SObject> start(Database.BatchableContext bc) {
        return records;
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        DmlService.deleteRecords(scope, false);
    }

    public void finish(Database.BatchableContext bc) {}
}