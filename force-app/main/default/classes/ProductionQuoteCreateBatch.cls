global class ProductionQuoteCreateBatch implements Database.Batchable<SObject> {
	
    global Set<Id> sbrIdsSet = new Set<Id>();
    //List<Opportunitylineitem> oppItemsToUpdate = new List<Opportunitylineitem>();
    
    global ProductionQuoteCreateBatch(Set<Id> idsSalesBudgetRecords){
        system.debug('start ProductionQuoteCreateBatch');
        sbrIdsSet = idsSalesBudgetRecords; 
    }
    
    global Database.QueryLocator start(Database.BatchableContext context) {		              
        return Database.getQueryLocator('SELECT id, QuotaType__c,MarketSegment__c,Period__c,Production_Amount__c,SalesManager__c,Product__c,Shop__c FROM SalesBudgetRecord__c WHERE SalesBudget__c in :sbrIdsSet' );
	}
    
    global void execute(Database.BatchableContext context, List<SalesBudgetRecord__c> scope) {
        //SalesBudgetRecord__c sbr = scope[0];
        List<SalesBudgetRecord__c> recordsToInsert = new List<SalesBudgetRecord__c>();
        List<Production_Quota__c> productionQuotaToInsert = new List<Production_Quota__c>();
        for(SalesBudgetRecord__c sbr :scope){
            String sbrQuotaType = sbr.QuotaType__c;
            String sbrMarketSegment = sbr.MarketSegment__c;
            Date sbrPeriod = sbr.Period__c;
            Decimal sbrProductionAmount = sbr.Production_Amount__c;
            String sbrSaleManager = sbr.SalesManager__c;
            String sbrProduct = sbr.Product__c;
            //Set<Id> opportunityIds = new Set<Id>();
        
       
            Production_Quota__c pq = new Production_Quota__c();
            pq.Quota_Type__c = sbrQuotaType;
            pq.Market_Segment__c = sbrMarketSegment;
            pq.Period__c = sbrPeriod;
            pq.Production_Amount_t__c = sbrProductionAmount;
            pq.Sales_Manager__c = sbrSaleManager;
            pq.Product__c = sbrProduct;
        	pq.Shop__c = sbr.Shop__c;
            productionQuotaToInsert.add(pq);
        }                             
           // productionQuotaToInsert.add(pq);
        //}
        try{ 
        	insert productionQuotaToInsert;
        } catch(Exception e) {             
    		System.debug('An exception occurred: ' + e.getMessage());              
		} 
	}
    
    global void finish(Database.BatchableContext context) {
       // if(!Test.isRunningTest()){
        system.debug('finish ProductionQuoteCreateBatch');
		ProductionQuoteGroupAllBatch groupBatchProdQuote = new ProductionQuoteGroupAllBatch();
		
        if(test.isRunningTest()){
            Id groupBatchProdQuoteId = Database.executeBatch(groupBatchProdQuote,10);
        } else {
            System.scheduleBatch( groupBatchProdQuote, 'groupBatchProdQuote', 1,10);
        }       		      
        //
       // }
	}
}