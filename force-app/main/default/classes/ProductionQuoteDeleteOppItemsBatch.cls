global class ProductionQuoteDeleteOppItemsBatch implements Database.Batchable<SObject>{
        
    global Database.QueryLocator start(Database.BatchableContext context) {		              
        return Database.getQueryLocator('SELECT id FROM ProdQuoteToOppProduct__c' );
	}
    
    global void execute(Database.BatchableContext context, List<ProdQuoteToOppProduct__c> scope) {
        Database.delete(scope, false);
	}
    
    global void finish(Database.BatchableContext context) {
		     
	}
}