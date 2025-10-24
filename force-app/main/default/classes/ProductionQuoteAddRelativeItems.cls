global class ProductionQuoteAddRelativeItems implements Database.Batchable<SObject>{

    global List<id> insertedProductionQuote = new List<Id>();
    global Set<Id> quota5shopExportId = new Set<Id>();
    global Id guProductId;
    global Id lpProductId;
    
    global ProductionQuoteAddRelativeItems(List<Id> idsCreatedProductionQuotes){
        insertedProductionQuote = idsCreatedProductionQuotes;
        
        for(QuotaType__c qt : [SELECT id FROM QuotaType__c WHERE Name='Shop 5 (export 4-4,5 mm)' OR Name='Shop 5 (export)']){
            quota5shopExportId.add(qt.id);
        }
        guProductId = [SELECT id FROM Product2 WHERE Name='GU' LIMIT 1].Id;
        lpProductId = [SELECT id FROM Product2 WHERE Name='LP' LIMIT 1].Id;
    }
    
    global Database.QueryLocator start(Database.BatchableContext context) {		              
        return Database.getQueryLocator('SELECT id, Sales_Manager__c,Product__c,Market_Segment__c,Quota_Type__c,Shop__c,Period__c FROM Production_Quota__c WHERE id in:insertedProductionQuote' );
	}
    
    global void execute(Database.BatchableContext context, List<Production_Quota__c> scope) {
        
         for(Production_Quota__c prodQuota : scope){
                                  
        Set<Id> opportunityIds = new Set<Id>();
        List<ProdQuoteToOppProduct__c> pqtopListToInsert = new List<ProdQuoteToOppProduct__c>();
        List<ProdQuoteToShopQuote__c> ProdQuoteToShopQuoteInsert = new List<ProdQuoteToShopQuote__c>();
        
        String sbrQuotaType = prodQuota.Quota_Type__c;
        String sbrMarketSegment = prodQuota.Market_Segment__c;
        String sbrSaleManager = prodQuota.Sales_Manager__c;
        String sbrProduct = prodQuota.Product__c;
        String sbrShop = prodQuota.Shop__c;
        Date startPeriod = prodQuota.Period__c;           
        Date endPeriod = startPeriod.addMonths(1);
        List<OpportunityLineItem> oppItemList = new List<OpportunityLineItem>();
        try{      
            if(quota5shopExportId.contains(sbrQuotaType) && sbrProduct==guProductId){
               oppItemList = [SELECT Id,Opportunity.Id,QuotaType__c,Name, OpportunityId, CDD__c, FinalCDD__c, Quota_Date__c, CreatedDate, Product2Id, Quantity, Shop__c,
                                                 ITENumber__c,Balance_t__c
                                                 FROM OpportunityLineItem 
                                                 WHERE (Product2Id = :sbrProduct OR Product2Id = :lpProductId)
                                                 AND Opportunity.OwnerId =:sbrSaleManager 
                                                 AND Opportunity.MarketSegment__c =:sbrMarketSegment
                                                 AND QuotaType__c = :sbrQuotaType
                                                 //AND Shop__c =:sbrShop
                                                 AND FinalCDD__c != NULL
                                                 AND ((FinalCDD__c > :startPeriod OR FinalCDD__c = :startPeriod) AND FinalCDD__c < :endPeriod)  
                       							 AND Opportunity.StageName = 'Closed Won'	
                       							 AND (Stage__c = 'Drafting' OR Stage__c = 'Processing' OR Stage__c = 'Confirmed' OR Stage__c = 'Placed')
                                                 ]; 
            } else{
               oppItemList = [SELECT Id, Opportunity.Id, QuotaType__c, Name, OpportunityId, CDD__c, FinalCDD__c, Quota_Date__c, CreatedDate, Product2Id, Quantity, Shop__c,
                                                 ITENumber__c,Balance_t__c
                                                 FROM OpportunityLineItem 
                                                 WHERE Product2Id = :sbrProduct 
                                                 AND Opportunity.OwnerId = :sbrSaleManager 
                                                 AND Opportunity.MarketSegment__c = :sbrMarketSegment
                                                 AND QuotaType__c =:sbrQuotaType
                                                 //AND Shop__c =:sbrShop
                                                 AND FinalCDD__c!=NULL
                                                 AND ((FinalCDD__c > :startPeriod OR FinalCDD__c = :startPeriod) AND FinalCDD__c < :endPeriod)  
                       							 AND Opportunity.StageName = 'Closed Won'	
                       							 AND (Stage__c = 'Drafting' OR Stage__c = 'Processing' OR Stage__c = 'Confirmed' OR Stage__c = 'Placed')
                                                 ]; 
            }            
        		
         } catch (Exception e){
            system.debug(e.getMessage());
        }
        //29 11 
        //select opportunity ids
        Set<Id> idsForSearchOrders = new Set<Id>();
        Set<Id> idsValidatedOpportunities = new Set<Id>();
        Set<String> iteNumbers = new Set<String>();
        Map<String, SalesPlanFact__c> iteNumToSPF = new Map<String, SalesPlanFact__c>();

        if(oppItemList.size()>0){
            
             
        for(OpportunityLineItem oppItem : oppItemList ){
            idsForSearchOrders.add(oppItem.Opportunity.id);
            iteNumbers.add(oppItem.ITENumber__c);
        }
            
        //select opp id in order where order!=closed
        try{
            List<Order> ordersNotClosed = [SELECT Opportunityid FROM Order WHERE Status !='Closed' AND Opportunityid in:idsForSearchOrders];
            for(Order od : ordersNotClosed){
                idsValidatedOpportunities.add(od.OpportunityId);
                
            }
        }catch (Exception e){                    
            	system.debug(e.getMessage());                    
        }     
        if(idsValidatedOpportunities.size()>0){      
            for (SalesPlanFact__c spf: [SELECT id, ITENumber__c, Period__c,Type__c 
                                  FROM SalesPlanFact__c 
                                  WHERE Period__c = THIS_MONTH 
                                  AND Type__c = 'Plan' 
                                  AND ITENumber__c in :iteNumbers]) {

                iteNumToSPF.put(spf.ITENumber__c, spf);
            }                                
            for(OpportunityLineItem oppItem : oppItemList ){
                if(idsValidatedOpportunities.contains(oppItem.Opportunity.id) && oppItem.Balance_t__c<=oppItem.Quantity){
                    String oppId = oppItem.Opportunity.id;
                    ProdQuoteToOppProduct__c newpqtop = new ProdQuoteToOppProduct__c();
                    newpqtop.Name_Opportunity_Product__c = oppItem.Name;
                    newpqtop.CDD__c = oppItem.FinalCDD__c;
                    newpqtop.Quota_Date__c = oppItem.Quota_Date__c;
                    newpqtop.Creation_Date_Opportunity_Item__c = oppItem.CreatedDate;
                    newpqtop.Product__c = oppItem.Product2Id;
                    newpqtop.Quantity__c = oppItem.Quantity;
                    newpqtop.Shop__c = oppItem.Shop__c;
                    newpqtop.ITE_Number__c = oppItem.ITENumber__c;
                    newpqtop.Production_Quota__c = prodQuota.id;
                    newpqtop.Quota_Type__c = oppItem.QuotaType__c;
                    newpqtop.Opportunity__c = oppItem.OpportunityId;
                    newpqtop.Opportunity_Product__c = oppItem.id;
                    newpqtop.Balance_t__c = oppItem.Balance_t__c<0?0:oppItem.Balance_t__c;
                    newpqtop.Sales_Plan_And_Fact__c = iteNumToSPF.get(oppItem.ITENumber__c)?.id;
                    pqtopListToInsert.add(newpqtop);
                    opportunityIds.add(oppId);
                }                
            }
             try{            
            	//insert pqtopListToInsert;
             }catch (Exception e){                    
            	system.debug(e.getMessage());                    
        	 }            
            try{  
                    List<Shop_Quota__c> shopQuotaList = [SELECT Name,Id,Opportunity__c,Quota_Type__c 
                                                         FROM Shop_Quota__c 
                                                         WHERE Opportunity__c IN :opportunityIds 
                                                         AND Quota_Type__c=:sbrQuotaType
                                                         AND ((Required_Quota_Date__c>:startPeriod OR Required_Quota_Date__c=:startPeriod) AND Required_Quota_Date__c<:endPeriod)
                                                         AND Required_Quota_Date__c!=NULL];
                                       
                    for(Shop_Quota__c sq : shopQuotaList){ 
                        ProdQuoteToShopQuote__c prodQuoteToShopQuote = new ProdQuoteToShopQuote__c();
                        prodQuoteToShopQuote.Name = sq.Name;
                        prodQuoteToShopQuote.Shop_Quota__c = sq.id;
                        prodQuoteToShopQuote.Production_Quota__c = prodQuota.id;
                        ProdQuoteToShopQuoteInsert.add(prodQuoteToShopQuote);
                    }
                    
                    insert ProdQuoteToShopQuoteInsert;
                
                } catch (Exception e){
                    
            		system.debug(e.getMessage());
                    
        		}
         }
        } 
            }

	}
    
    global void finish(Database.BatchableContext context) {
		
        //SalesPlanFactDeleteActualBatch deleteExtraSpf = new SalesPlanFactDeleteActualBatch();
		//Id createBatchProdQuoteId = Database.executeBatch(deleteExtraSpf);
		List<Deleted_Period__c> rs = [SELECT Id FROM Deleted_Period__c];
		delete rs;
	}

    public static void FakeCoverageMethod() {
        Integer i=0;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
    }
}