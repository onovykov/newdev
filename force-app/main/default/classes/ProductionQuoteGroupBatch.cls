global class ProductionQuoteGroupBatch implements Database.Batchable<SObject>  {
	
    global Set<Id> idsChecked = new Set<Id>();
    //global Set<Id> idsForDelete = new Set<Id>();
    
    global Database.QueryLocator start(Database.BatchableContext context) {		              
        return Database.getQueryLocator('SELECT Market_Segment__c,Period__c,Product__c,Quota_Type__c,Sales_Manager__c,Shop__c,Production_Amount_t__c,Quota_Mt__c,createdDate FROM Production_Quota__c order by createdDate' );
	}
    
    global void execute(Database.BatchableContext context, List<Production_Quota__c> scope) {
        system.debug('ProductionQuoteGroupBatch run');
        for(Production_Quota__c productionQuota : scope){
        //Production_Quota__c productionQuota = scope[0];
        String currentRecordId = productionQuota.id;                  
        system.debug(currentRecordId);
        try{ 
        	Production_Quota__c recordDeleted = [Select IsDeleted FROM Production_Quota__c WHERE Id =:currentRecordId LIMIT 1 ];  
            
        if(currentRecordId != null && !idsChecked.contains(currentRecordId)){
            
            system.debug('in if');
            String marketSegment =  productionQuota.Market_Segment__c;
            Date period = productionQuota.Period__c;
            String product = productionQuota.Product__c;
            String quotaType = productionQuota.Quota_Type__c;
            String salesManager = productionQuota.Sales_Manager__c;
            String shop = productionQuota.Shop__c;
        	
        
        List<Production_Quota__c> sameQuotas = [SELECT id,Production_Amount_t__c FROM Production_Quota__c WHERE 
                                                Market_Segment__c=:marketSegment AND
                                                Period__c=:period  AND
                                                Product__c=:product AND
                                                Quota_Type__c=:quotaType AND
                                                Sales_Manager__c=:salesManager AND
                                                Shop__c=:shop AND
                                                id!=:productionQuota.id];
          system.debug(sameQuotas);  
        for(Production_Quota__c pq:sameQuotas){
            
            productionQuota.Production_Amount_t__c = productionQuota.Production_Amount_t__c==null?0:productionQuota.Production_Amount_t__c;
            pq.Production_Amount_t__c = pq.Production_Amount_t__c==null?0:pq.Production_Amount_t__c;
            
            productionQuota.Production_Amount_t__c += pq.Production_Amount_t__c;        
            idsChecked.add(pq.id);
                  
        }
            
        productionQuota.Quota_Mt__c = productionQuota.Production_Amount_t__c;
        update productionQuota;
        delete sameQuotas;
        }
          } catch(Exception e) {             
    		System.debug('An exception occurred: ' + e.getMessage());              
		} 
        }
                             
	}
    
    global void finish(Database.BatchableContext context) {
		
	}
}