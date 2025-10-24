global class BalanceUpdaOppProdAndOrderProdBatch implements Database.Batchable<SObject> {
	
    
    
    global Database.QueryLocator start(Database.BatchableContext context) {		              
        return Database.getQueryLocator('SELECT ITENumber__c,Balance_t__c,Quantity  FROM OpportunityLineItem WHERE ITENumber__c!=null' );
	}
    
    global void execute(Database.BatchableContext context, List<OpportunityLineItem> scope) {
       List<OpportunityLineItem> oliToUpdate = new List<OpportunityLineItem>();
        Set<String> iteNumberSet = new Set<String>();
       Map<String,OpportunityLineItem> iteOrderMap = new Map<String,OpportunityLineItem>();
       system.debug(oliToUpdate);  
        try{ 
        for(OpportunityLineItem oli : scope){
            iteNumberSet.add(oli.ITENumber__c);
            iteOrderMap.put(oli.ITENumber__c,oli);
        }
        
        List<OrderItem> orderItems = [SELECT ProducedQuantity__c,ITENumber__c FROM OrderItem WHERE ITENumber__c in:iteNumberSet AND ProducedQuantity__c!=null];
        system.debug(orderItems); 
        for(OrderItem oi : orderItems){
            OpportunityLineItem choosenOli = iteOrderMap.get(oi.ITENumber__c);
            choosenOli.Balance_t__c = choosenOli.Quantity - oi.ProducedQuantity__c;
            oliToUpdate.add(choosenOli);
        }
        
        update oliToUpdate;
            } catch(Exception e){
            system.debug(e.getMessage());
        }
	}
    
    global void finish(Database.BatchableContext context) {
        
	}
}