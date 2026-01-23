public with sharing class InsertQueueable implements Queueable {

    private List<SObject> records;

    public InsertQueueable(List<SObject> records) {
        this.records = records;
    }

    public void execute(QueueableContext context) {
        DmlService.insertRecords(records, false);
    }
}
