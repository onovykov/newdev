global class ExcelImportBatch implements Database.Batchable<sObject> {
  global List<sObject> source;
  global ExcelImportBatch(List<sObject> records) {
    source = records;
  }
  public  List<sObject> start(Database.BatchableContext context) {
    return source;
  }
  public void execute(Database.BatchableContext context, List<sObject> scope) {
        Schema.SObjectField field = Schema.getGlobalDescribe().get(''+scope.getSobjectType()+'').getDescribe().fields.getMap().get('Primary_Key__c'); 
        try {
            Database.upsert(scope ,field);
        } catch(Exception e) {
            System.debug(e);
        }
  }
  public void finish(Database.BatchableContext context) {
      system.debug('finish');
  }
}