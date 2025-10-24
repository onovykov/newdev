global class ProductionQuoteFromSalBudgetBatch implements Database.Batchable<SObject> {
	       
    global Database.QueryLocator start(Database.BatchableContext context) {		              
        return Database.getQueryLocator('SELECT id, QuotaType__c,MarketSegment__c,Period__c,Production_Amount__c,SalesManager__c,Product__c,Shop__c FROM SalesBudgetRecord__c WHERE Period__c>2022-03-01 and Period__c<2022-07-01 and CreatedDate>2021-12-30T21:21:55.000+0000' );
	}
    
    global void execute(Database.BatchableContext context, List<SalesBudgetRecord__c> scope) {
        List<Production_Quota__c> productionQuotaToInsert = new List<Production_Quota__c>();
        
        for(SalesBudgetRecord__c sbr:scope){
            String sbrQuotaType = sbr.QuotaType__c;
            String sbrMarketSegment = sbr.MarketSegment__c;
            Date sbrPeriod = sbr.Period__c;
            Decimal sbrProductionAmount = sbr.Production_Amount__c;
            String sbrSaleManager = sbr.SalesManager__c;
            String sbrProduct = sbr.Product__c;
            
            
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
       // SalesBudgetRecord__c sbr = scope[0];     
        insert productionQuotaToInsert;
	}
    
    global void finish(Database.BatchableContext context) {
        system.debug('ProductionQuoteFromSalBudgetBatch finish');
		
	}
}