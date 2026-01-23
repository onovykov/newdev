public with sharing class UpdateBatch
    implements Database.Batchable<SObject> {

    private List<SObject> records;

    public UpdateBatch(List<SObject> records) {
        this.records = records;
    }

    public Iterable<SObject> start(Database.BatchableContext bc) {
        return records;
    }

    public void execute(
        Database.BatchableContext bc,
        List<SObject> scope
    ) {
        DmlService.updateRecords(scope, false);
    }

    public void finish(Database.BatchableContext bc) {}
}