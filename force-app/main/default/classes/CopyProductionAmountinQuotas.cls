global class CopyProductionAmountinQuotas implements Database.Batchable<sObject> {
    @InvocableMethod
    public static void callBatch(){
        id JobId = Database.executeBatch(new CopyProductionAmountInQuotas());
    }
    global Database.QueryLocator start(Database.BatchableContext bc) {
        // collect the batches of records or objects to be passed to execute
        return Database.getQueryLocator([SELECT id,Production_Amount_t__c,Quota_Mt__c  FROM Production_Quota__c]);
    }
    global void execute(Database.BatchableContext bc, List<Production_Quota__c> records){
       for(Production_Quota__c pq : records){
         pq.Quota_Mt__c = pq.Production_Amount_t__c;
       }
       update records;
    }    
    global void finish(Database.BatchableContext bc){
        // execute any post-processing operations
    }    
}