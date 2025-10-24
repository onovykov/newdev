global class ProductionQuoteDeleteShopItemBatch implements Database.Batchable<SObject>{
        
    global Database.QueryLocator start(Database.BatchableContext context) {		              
        return Database.getQueryLocator('SELECT id FROM ProdQuoteToShopQuote__c' );
	}
    
    global void execute(Database.BatchableContext context, List<ProdQuoteToShopQuote__c> scope) {
        delete scope;
       
	}
    
    global void finish(Database.BatchableContext context) {
		     
	}
}