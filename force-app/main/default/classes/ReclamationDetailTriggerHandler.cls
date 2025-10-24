public class ReclamationDetailTriggerHandler  extends TriggerHandler implements ITrigger {
	
	public ReclamationDetailTriggerHandler(Map<Id, SObject> oldMap, Map<Id, SObject> newMap, List<SObject> oldList, List<SObject> newList) {
		super(oldMap, newMap, oldList, newList);
	}
    
    public void bulkBefore() {
		System.debug('bulkBefore ReclamationTriggerHandler');
        if(Trigger.isDelete){
            System.debug(oldList);
            Set<Id> parentReclamationSet = new Set<Id>();
            for (Reclamation_Detail__c reclDet: (List<Reclamation_Detail__c>)oldList) {
                parentReclamationSet.add(reclDet.ReclID__c);
            }
            Map<Id,Reclamation__c> parentReclamation = new Map<Id,Reclamation__c>([SELECT STATUS__C FROM Reclamation__c WHERE Id in:parentReclamationSet]);
            
            //Map<Id,Reclamation__c> parentReclamation = 
            for (Reclamation_Detail__c reclDet: (List<Reclamation_Detail__c>)oldList) {
              id idParentReclamation = reclDet.ReclID__c;
                if (parentReclamation.get(idParentReclamation).Status__c != 'Draft') {   
                 
                 reclDet.adderror('You cannot delete the Reclamation Detail with non "Draft" status Reclamation');
    			}
        	}	
        }
    }

	public void bulkAfter() {
		System.debug('bulkAfter');
		
	}

	public void beforeInsert(SObject so) {
		System.debug('beforeInsert');
		
	}

	public void beforeUpdate(SObject oldSo, SObject so) {

		System.debug('beforeUpdate');

		
	}

	public void beforeDelete(SObject so) {
	}

	public void afterInsert(SObject so) {

		System.debug('afterInsert');
	
	}

	public void afterUpdate(SObject oldSo, SObject so) {
		System.debug('afterUpdate');
	}

	public void afterDelete(SObject so) {
	}

	public void postProcessing() {
		
	}

}