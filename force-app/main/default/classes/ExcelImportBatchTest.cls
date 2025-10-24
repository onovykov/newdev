@isTest
private class ExcelImportBatchTest {
	static testmethod void importBatch() {        
        List<trade_data__c> tradeData = new List<trade_data__c>();
       		for (Integer i=0;i<200;i++) {
            	tradeData.add(new Trade_Data__c(Exporter__c='test'+i));
            }
        insert tradeData;
        Test.startTest();
        String q = 'Select Id from Trade_data__c';
        ExcelImportBatch tb = new ExcelImportBatch(tradeData);
        Id batchId = Database.executeBatch(tb);
        Test.stopTest();
            Integer td=[select count() from Trade_Data__c];
        
        System.assertEquals(200, td);
             }
}