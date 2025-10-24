global class PARUpdateOpportunityBatch implements Database.Batchable<SObject> {
	
    global Set<String> oppIdsSet = new Set<String>();
    List<Opportunitylineitem> oppItemsToUpdate = new List<Opportunitylineitem>();
    
    global PARUpdateOpportunityBatch(){
        List<aggregateresult> oppIds = [SELECT Opportunity__r.id FROM OpportunityPARRelationship__c where PriceApprovalRequest__r.stage__c = 'Resolved' group by Opportunity__r.id ];
        for(aggregateresult ar : oppIds){
            oppIdsSet.add(ar.id);
        }
    }
    
    global Database.QueryLocator start(Database.BatchableContext context) {
		
        List<Id> oppsWithPar = new List<Id>(); 
        
        return Database.getQueryLocator('SELECT id FROM Opportunity WHERE id in :oppIdsSet' );
	}
    
    global void execute(Database.BatchableContext context, List<Opportunity> scope) {
		String oppId = scope[0].id;
	   
       system.debug(oppId); 
       OpportunityPARRelationship__c selectPARrelate = [SELECT id,Opportunity__r.id, PriceApprovalRequest__r.id,PriceApprovalRequest__r.LastModifiedDate 
                                                        FROM OpportunityPARRelationship__c where opportunity__r.id =:oppId AND PriceApprovalRequest__r.stage__c = 'Resolved'
                                                        ORDER BY PriceApprovalRequest__r.LastModifiedDate DESC LIMIT 1];
       String parId = selectPARrelate.PriceApprovalRequest__r.id;
       system.debug(parId); 
       List<PriceApprovalRequestItem__c> parItems= [SELECT OpportunityLineItemId__c,Margin_t__c,id FROM PriceApprovalRequestItem__c WHERE PriceApprovalRequestId__c = :parId];
       Map<id,Opportunitylineitem> oppItemsMap = new Map<id,Opportunitylineitem>([SELECT id, Margin_t__c FROM Opportunitylineitem WHERE Opportunity.id =:oppId ]); 
       system.debug(oppItemsMap); 
        for(PriceApprovalRequestItem__c paritem : parItems){
            Opportunitylineitem opp = oppItemsMap.get(paritem.OpportunityLineItemId__c);
            system.debug(opp);
            system.debug(paritem); 
            if(opp != null){
                opp.Margin_t__c = opp.Margin_t__c==0?paritem.Margin_t__c:opp.Margin_t__c;
                oppItemsToUpdate.add(opp);
            }
        } 
        system.debug('worked');
        system.debug(oppItemsToUpdate);
        if(oppItemsToUpdate.size()>0){
            update oppItemsToUpdate;
        }
        
	}
    
    global void finish(Database.BatchableContext context) {
		system.debug('finish');
        system.debug(oppItemsToUpdate);
        //update oppItemsToUpdate;
	}
    
}