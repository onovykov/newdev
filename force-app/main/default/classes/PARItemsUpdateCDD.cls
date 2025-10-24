global class PARItemsUpdateCDD implements Database.Batchable<SObject> {
	
    global Map<String,PriceApprovalRequestItem__c> oppIdToPARItems = new Map<String, PriceApprovalRequestItem__c>();
    global List<String> oppIdsFromPARItems = new List<String>();
    
    global PARItemsUpdateCDD() {
        List<PriceApprovalRequestItem__c> PARItems = [SELECT CDD__c, OpportunityLineItemId__c FROM PriceApprovalRequestItem__c WHERE OpportunityLineItemId__c != NULL AND CDD__c = NULL];
        for(PriceApprovalRequestItem__c parItem : PARItems){
            if(parItem.OpportunityLineItemId__c != null){
            	oppIdToPARItems.put(parItem.OpportunityLineItemId__c,parItem);
                oppIdsFromPARItems.add(parItem.OpportunityLineItemId__c);
            }
        }       
    }   
    
    global Database.QueryLocator start(Database.BatchableContext context) {
		return Database.getQueryLocator('SELECT Id, CDD__c, FinalCDD__c FROM OpportunityLineItem WHERE id in :oppIdsFromPARItems' );
	}
	
   	global void execute(Database.BatchableContext context, List<OpportunityLineItem> scope) {
			List<PriceApprovalRequestItem__c> PARItemsToUpdate = new List<PriceApprovalRequestItem__c>();
        for(OpportunityLineItem oli : scope){
            PriceApprovalRequestItem__c currentPARItem = oppIdToPARItems.get(oli.id);
            currentPARItem.CDD__c = oli.FinalCDD__c;
            PARItemsToUpdate.add(currentPARItem);
            system.debug(currentPARItem);
        }
        update PARItemsToUpdate;
	}
	
	
	global void finish(Database.BatchableContext context) {
       		
    }
}