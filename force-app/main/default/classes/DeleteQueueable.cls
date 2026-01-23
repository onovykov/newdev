public with sharing class DeleteQueueable implements Queueable {

    private List<SObject> records;

    public DeleteQueueable(List<SObject> records) {
        this.records = records;
    }

    public void execute(QueueableContext context) {
        DmlService.deleteRecords(records, false);
    }
}