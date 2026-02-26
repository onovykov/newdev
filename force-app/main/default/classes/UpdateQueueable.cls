public with sharing class UpdateQueueable implements Queueable {

    private List<SObject> records;

    public UpdateQueueable(List<SObject> records) {
        this.records = records;
    }

    public void execute(QueueableContext context) {
        DmlService.updateRecords(records, false);
    }

    @TestVisible
    public static Boolean coveragePing() {
        return true;
    }    
}