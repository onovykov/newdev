global class ProductionQuoteAddShopQuota implements Database.Batchable<SObject> {
	global Set<Id> shopQuotasIds = new Set<Id>();
       
    global ProductionQuoteAddShopQuota(List<Shop_Quota__c> shopQuotasList){
        for(Shop_Quota__c sq : shopQuotasList){
            shopQuotasIds.add(sq.id);
        }
    }
    
    global Database.QueryLocator start(Database.BatchableContext context) {		              
        return Database.getQueryLocator('SELECT id,Quota_Type__c,Opportunity__r.OwnerId,Opportunity__r.MarketSegment__c,Name FROM Shop_Quota__c WHERE id in :shopQuotasIds' );
	}
    
    global void execute(Database.BatchableContext context, List<Shop_Quota__c> scope) {
        system.debug('ProductionQuoteAddShopQuota run');
        Shop_Quota__c shopQuotaItem = scope[0];
        List<ProdQuoteToShopQuote__c> ProdQuoteToShopQuoteInsert = new List<ProdQuoteToShopQuote__c>();
        
        List<Production_Quota__c> pqList = [SELECT Id,(SELECT Shop_Quota__c FROM ProdQuoteToShopQuotes__r) FROM Production_Quota__c WHERE Sales_Manager__c=:shopQuotaItem.Opportunity__r.OwnerId
                                             AND Market_Segment__c=:shopQuotaItem.Opportunity__r.MarketSegment__c AND Quota_Type__c =:shopQuotaItem.Quota_Type__c];
        if(pqList.size()>0){
            for(Production_Quota__c pq:pqList){
                boolean shopQuoteExist = false;
                for(ProdQuoteToShopQuote__c prodQ :pq.ProdQuoteToShopQuotes__r){
                    if(prodQ.Shop_Quota__c == shopQuotaItem.id){
                        shopQuoteExist = true;
                    }
                }
                if(!shopQuoteExist){
                    ProdQuoteToShopQuote__c prodQuoteToShopQuote = new ProdQuoteToShopQuote__c();
                    prodQuoteToShopQuote.Name = shopQuotaItem.Name;
                    prodQuoteToShopQuote.Shop_Quota__c = shopQuotaItem.id;
                    prodQuoteToShopQuote.Production_Quota__c = pq.id;
                    ProdQuoteToShopQuoteInsert.add(prodQuoteToShopQuote);
                }
                
            }
           insert ProdQuoteToShopQuoteInsert;
        }
        
	}
    
    global void finish(Database.BatchableContext context) {
        try{
            List<ProdQuoteToShopQuote__c> prodQuotes = [SELECT id FROM ProdQuoteToShopQuote__c WHERE Shop_Quota__c=NULL];
        	delete prodQuotes;
        } catch(Exception e) {
    		System.debug('An exception occurred: ' + e.getMessage());
		}
		
	}
}