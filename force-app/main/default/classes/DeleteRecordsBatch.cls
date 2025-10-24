public class DeleteRecordsBatch implements Database.Batchable<sObject> {
    public String query;

    public DeleteRecordsBatch(String queryString) {
        this.query = queryString;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<Sobject> scope) {
        delete scope;
    }

    public void finish(Database.BatchableContext bc){

    }
}