global class OpportunitiesWithoutOrderBatch implements Database.Batchable<SObject> {
	global String oppIdsWihoutOrder; 
    
    global Database.QueryLocator start(Database.BatchableContext context) {		              
        return Database.getQueryLocator('SELECT id, Sales_Manager__c,Product__c,Market_Segment__c,Quota_Type__c,Shop__c,Period__c FROM Production_Quota__c' );
	}
    
    global void execute(Database.BatchableContext context, List<Production_Quota__c> scope) {       
        
        
        for(Production_Quota__c prodQuota : scope){                                 
        Set<Id> opportunityIds = new Set<Id>();  
        Set<Id> oppWithoutOrder = new Set<Id>();  
       
       
              
        String sbrQuotaType = prodQuota.Quota_Type__c;
        String sbrMarketSegment = prodQuota.Market_Segment__c;
        String sbrSaleManager = prodQuota.Sales_Manager__c;
        String sbrProduct = prodQuota.Product__c;
        String sbrShop = prodQuota.Shop__c;
        Date startPeriod = prodQuota.Period__c;
        Date endPeriod = startPeriod.addMonths(1);
        List<OpportunityLineItem> oppItemList = new List<OpportunityLineItem>();
              
        try{                  
        oppItemList = [SELECT Id, Opportunity.StageName, Opportunity.Id, QuotaType__c, Name, OpportunityId, CDD__c, FinalCDD__c, Quota_Date__c, CreatedDate, Product2Id, Quantity, Shop__c,
                                                 ITENumber__c,Balance_t__c
                                                 FROM OpportunityLineItem 
                                                 WHERE Product2Id=:sbrProduct 
                                                 AND Opportunity.OwnerId =:sbrSaleManager 
                                                 AND Opportunity.MarketSegment__c =:sbrMarketSegment
                                                 AND QuotaType__c =:sbrQuotaType
                                                 AND Shop__c =:sbrShop
                                                 AND FinalCDD__c != NULL
                                                 AND ((FinalCDD__c > :startPeriod OR FinalCDD__c = :startPeriod) AND FinalCDD__c < :endPeriod)  
                       							 AND Opportunity.StageName = 'Closed Won'	
                       							 AND (Stage__c = 'Drafting' OR Stage__c = 'Processing' OR Stage__c = 'Confirmed' OR Stage__c = 'Placed')
                                                 ];
               
         } catch (Exception e){
            system.debug(e.getMessage());
        }
        
        Set<Id> idsForSearchOrders = new Set<Id>();
        Set<Id> idsValidatedOpportunities = new Set<Id>();
        if(oppItemList.size()>0){                        
            for(OpportunityLineItem oppItem : oppItemList ){
                idsForSearchOrders.add(oppItem.Opportunity.id);
            }       
        for(Id oppId:idsForSearchOrders){
            try{
                Order ordersNotClosed = [SELECT Opportunityid FROM Order WHERE Opportunityid = :oppId limit 1];
            } catch(Exception e){
                oppIdsWihoutOrder = oppId + '; ';
                system.debug(e.getMessage());
            }
             
        }                   
        } 
            }
        if(oppIdsWihoutOrder!=null){
            sendNotificationEmail('yayarik98@gmail.com',oppIdsWihoutOrder);
        }

	}
    
    global void finish(Database.BatchableContext context) {
		
	}
    
    global static void sendNotificationEmail(String email,String oppIds){
        
        List<String> orderOwnerEmails = new List<String>();
        orderOwnerEmails.add(email);
        String mailBody = oppIds;
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.toAddresses = orderOwnerEmails;
        message.optOutPolicy = 'FILTER';
        message.subject = 'Opportunities without orders';
        message.htmlbody = mailBody;
        Messaging.SingleEmailMessage[] messages =   new List<Messaging.SingleEmailMessage> {message};
        Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
        
    }
}