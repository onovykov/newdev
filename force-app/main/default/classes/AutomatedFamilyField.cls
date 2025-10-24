public class AutomatedFamilyField implements Queueable {
	
    List<OpportunityLineItem> oppliList = new  List<OpportunityLineItem>();
    
    
    
    public AutomatedFamilyField(List<OpportunityLineItem> newList ) {
        this.oppliList = newList;
        
    }
    
    public void execute(QueueableContext context) {
       Set<id> opportunitySetIds = new Set<id>();
            Set<id> productSetIds = new Set<id>();
            List<OpportunityLineItem> oppliList = this.oppliList;
            
            for(OpportunityLineItem oli: oppliList){
                opportunitySetIds.add(oli.OpportunityId);
                productSetIds.add(oli.Product2Id);
            }
            system.debug('BBEFRORE INSERT BULk HERE');
            Map<id,Opportunity> opportunitiesMap = new Map<id,Opportunity>([SELECT Product_Family__c FROM Opportunity WHERE id in:opportunitySetIds ]);
            Map<id,List<String>> oppMapListFamilyValues= new Map<id,List<String>>();
            system.debug('AFTERrr INSERT BULk HERE');
            //check if family field has any value
            for(Id key : opportunitiesMap.keySet()){
                
                system.debug('inarray');
                if(opportunitiesMap.get(key).Product_Family__c != null){
                    oppMapListFamilyValues.put(key,opportunitiesMap.get(key).Product_Family__c.split(';'));
                    system.debug('not null');
                    system.debug(opportunitiesMap.get(key).Product_Family__c);
                } else {
                    system.debug('null');
                    oppMapListFamilyValues.put(key,new List<String>());
                }
                
            }
            system.debug(oppMapListFamilyValues);
            Map<id,Product2> product2Map = new Map<id,Product2>([SELECT Family FROM Product2 WHERE id in:productSetIds ]);
            system.debug(product2Map);
            //move through array of items and get their family
            for(OpportunityLineItem oli: oppliList){
                List<String> familyValOpp = oppMapListFamilyValues.get(oli.OpportunityId);
                String familyValProd = product2Map.get(oli.Product2Id).Family;
                system.debug('oppMapListFamilyValues');
                system.debug(familyValProd);
                system.debug(familyValOpp);
                if(familyValOpp.contains(familyValProd) || familyValProd==null){
                    system.debug('work');
                }else{
                    
                    if(opportunitiesMap.get(oli.OpportunityId).Product_Family__c != null){
                        opportunitiesMap.get(oli.OpportunityId).Product_Family__c = opportunitiesMap.get(oli.OpportunityId).Product_Family__c+';'+familyValProd;
                        List<String> newFamilyValues = oppMapListFamilyValues.get(oli.OpportunityId);
                        newFamilyValues.add(familyValProd);
                        oppMapListFamilyValues.put(oli.OpportunityId, newFamilyValues);
                                                
                    } else {
                        opportunitiesMap.get(oli.OpportunityId).Product_Family__c = familyValProd +';';
                        List<String> newFamilyValues = oppMapListFamilyValues.get(oli.OpportunityId);
                        newFamilyValues.add(familyValProd);
                        oppMapListFamilyValues.put(oli.OpportunityId, newFamilyValues);
                    }
                }
            }
            update opportunitiesMap.values();
    }
}