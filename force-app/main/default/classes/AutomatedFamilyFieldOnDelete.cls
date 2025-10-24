public class AutomatedFamilyFieldOnDelete implements Queueable {

    List<OpportunityLineItem> oppliList = new  List<OpportunityLineItem>();
    
     public AutomatedFamilyFieldOnDelete(List<OpportunityLineItem> oldList ) {
        this.oppliList = oldList;
        
    }
    
    
    public void execute(QueueableContext context) {
        
        system.debug('delete event');
            Set<Id> oppIds = new Set<Id>();
            Set<id> products2idDeletedItems = new Set<id>();
            List<OpportunityLineItem> oppliList =  this.oppliList;
           
            
           //copy products and opp ids from deleted items for future searhcing 
            for(OpportunityLineItem oli : oppliList){
                oppIds.add(oli.OpportunityId);
                products2idDeletedItems.add(oli.Product2Id);
            }
             List<OpportunityLineItem> itemsExists = [SELECT id,Opportunityid,Product2.Family FROM OpportunityLineItem WHERE Opportunityid in: oppIds];
            Map<id,Opportunity> opportunitiesMap = new Map<id,Opportunity>([SELECT Product_Family__c FROM Opportunity WHERE id in:oppIds ]);           
            Map<id,list<OpportunityLineItem>> mapOfExistLineItems = new Map<id,list<OpportunityLineItem>>();
            
            //create map Opportunity with existing items
            for(id oppId :oppIds){
                mapOfExistLineItems.put(oppId,new list<OpportunityLineItem>());
            	 List<OpportunityLineItem> newSome = new List<OpportunityLineItem>();
            for(OpportunityLineItem ile:itemsExists){
              // mapOfExistLineItems.put(ile.Opportunityid,mapOfExistLineItems.get());
                if(ile.OpportunityId == oppId){
                       newSome.add(ile);                
                }
            }
            	 mapOfExistLineItems.put(oppId,newSome);
                system.debug(mapOfExistLineItems.get(oppId));
            }
            
            Map<id,Product2> productsDeletedItems = new Map<id,Product2>([SELECT Family FROM Product2 WHERE id in:products2idDeletedItems]);
            
            //compare existing values Family field with deleted for update familly_c field in opportunity
            for(OpportunityLineItem oli : oppliList){
               
                List<OpportunityLineItem> existItemsOpp = mapOfExistLineItems.get(oli.OpportunityId);
                String oldFamilyValue = productsDeletedItems.get(oli.Product2Id).Family;
                Boolean valueExist = false;
                for(OpportunityLineItem oliExist : existItemsOpp){
                    if(oliExist.Product2.Family == oldFamilyValue){
                        valueExist = true;
                        break;
                    }
                }
                if(!valueExist){
                    String newValue = '';
                     system.debug(oli.id);
                    system.debug(oldFamilyValue);
                    Opportunity currentOpp = opportunitiesMap.get(oli.OpportunityId);
                    system.debug(currentOpp);
                    if(currentOpp.Product_Family__c != null){
                        String[] valuesFamilyList = currentOpp.Product_Family__c.split(';');
                        if(valuesFamilyList.contains(oldFamilyValue)){
                        valuesFamilyList.remove(valuesFamilyList.indexOf(oldFamilyValue));
                        for(String val :valuesFamilyList){
                            
                            if(val!='null'){
                                newValue += val + ';';
                            }
                            
                        }
                        system.debug(newValue);
                        currentOpp.Product_Family__c = newValue;
                        opportunitiesMap.put(oli.OpportunityId,currentOpp);
                        }
                }
                }
            }
        if(opportunitiesMap.values().size() > 0){
            update opportunitiesMap.values();
        }
            
    }
}