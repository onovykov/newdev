public class DeleteExtraShopQuotaOpportunity implements Queueable  {

    List<Id> shopQuotaExist = new List<Id>();
    Set<id> oppIdsForCheck = new Set<id>();
    Set<id> test = new Set<id>();
    
    public DeleteExtraShopQuotaOpportunity(Set<id> quotaTypesIds,  Set<Id> oppIds){
                
        this.test = quotaTypesIds;
        system.debug(quotaTypesIds);
        system.debug(oppIds);
        List<Shop_Quota__c> existingShopQuota = [SELECT Id                    
                    FROM Shop_Quota__c
                    WHERE Opportunity__c in :oppIds
                    AND Quota_Type__c in :quotaTypesIds];
        
        for(Shop_Quota__c sqe : existingShopQuota){
			this.shopQuotaExist.add(sqe.id) ;           
        }
               
        this.oppIdsForCheck = oppIds;
    }
    
    
    public void execute(QueueableContext context) { 
        Map<Id,List<OpportunityLineItem>> oppLi = new Map<Id,List<OpportunityLineItem>>();
        for(OpportunityLineItem li : [select QuotaType__c,OpportunityId from OpportunityLineItem where OpportunityId in:this.oppIdsForCheck  ]){
            system.debug(li.QuotaType__c);
            if(oppLi.get(li.OpportunityId)==null){
                oppLi.put(li.OpportunityId,new List<OpportunityLineItem>());
            }
            List<OpportunityLineItem> updateList = oppLi.get(li.OpportunityId);
            updateList.add(li);
            oppLi.put(li.OpportunityId,updateList);
        }
        system.debug(oppLi);
        
        Map<Id,Set<id>> oppLiQuotasType = new Map<Id,Set<id>>();
        for(OpportunityLineItem li : [select QuotaType__c,OpportunityId from OpportunityLineItem where OpportunityId in:this.oppIdsForCheck  ]){
            system.debug(li.QuotaType__c);
            if(oppLiQuotasType.get(li.OpportunityId)==null){
                oppLiQuotasType.put(li.OpportunityId,new Set<id>());
            }
            Set<id> updateLista = oppLiQuotasType.get(li.OpportunityId);
            updateLista.add(li.QuotaType__c);
            oppLiQuotasType.put(li.OpportunityId,updateLista);
        }
        system.debug(oppLiQuotasType);
        
        Map<Id,List<Shop_Quota__c>> oppShopQuotass = new Map<Id,List<Shop_Quota__c>>();
        for(Shop_Quota__c sq : [SELECT Name,Opportunity__c,Quota_Type__c,Id,Quota_Type__r.Name FROM Shop_Quota__c WHERE Opportunity__c in:this.oppIdsForCheck ]){
            if(oppShopQuotass.get(sq.Opportunity__c)==null){
                oppShopQuotass.put(sq.Opportunity__c,new List<Shop_Quota__c>());
            }
            List<Shop_Quota__c> listToUpdate = oppShopQuotass.get(sq.Opportunity__c);
            listToUpdate.add(sq);
             oppShopQuotass.put(sq.Opportunity__c,listToUpdate);
        }
        system.debug(oppShopQuotass);
        
        List<Shop_Quota__c> shopQuotesToDelete = new  List<Shop_Quota__c>();
        for(Id idOpp : oppShopQuotass.keySet()){
            List<Shop_Quota__c> shopQuotaListCheck = oppShopQuotass.get(idOpp);
            Set<Id> oppQuotaTypeIds = oppLiQuotasType.get(idOpp);
            for(Shop_Quota__c sqc : shopQuotaListCheck){
                system.debug(sqc.Quota_Type__r.Name);
                system.debug(oppQuotaTypeIds);
                system.debug(sqc);
                if (oppQuotaTypeIds == null  && sqc.Quota_Type__r.Name == 'Not Added'){
                    shopQuotesToDelete.add(sqc);
                } else if(oppQuotaTypeIds != null && !oppQuotaTypeIds.contains(sqc.Quota_Type__c) && sqc.Quota_Type__r.Name == 'Not Added'){
                    shopQuotesToDelete.add(sqc);
                } 
            }                            
        }
        system.debug('');
        system.debug(shopQuotesToDelete);
        delete shopQuotesToDelete;
        /*
    	List<Shop_Quota__c> allShopQuotas = [SELECT id FROM Shop_Quota__c WHERE Opportunity__c in :this.oppIdsForCheck];
        List<Shop_Quota__c> shopQuotasForDelete = new List<Shop_Quota__c>();
        system.debug(this.oppIdsForCheck);
        system.debug(allShopQuotas);
        system.debug(this.shopQuotaExist);
        system.debug(this.test);
        
        if(this.shopQuotaExist.size()>0){
            for(Shop_Quota__c sq : allShopQuotas){
            if(!this.shopQuotaExist.contains(sq.id)){
                shopQuotasForDelete.add(sq);
                system.debug(shopQuotasForDelete);
            }
        }
        }
        
        system.debug(shopQuotasForDelete);
        delete shopQuotasForDelete;
*/
    }
}