public class AdditionalAccountUserHandler extends TriggerHandler implements ITrigger{
	
  public static Map<Id, SObject> oldMap;
  public static Map<Id, SObject> newMap; 
  List<SObject> oldList;
  List<SObject> newList;
       
  public AdditionalAccountUserHandler(Map<Id, SObject> oldMap, Map<Id, SObject> newMap, List<SObject> oldList, List<SObject> newList) {
      super(oldMap, newMap, oldList, newList);
  }
    
  public void bulkBefore() {
      if(Trigger.isDelete){
            system.debug('delete event');
       }
  } //bulkBefore   
    
	public void bulkAfter() {
		System.debug('bulkAfter');		
        
	}

	public void beforeInsert(SObject so) {
		System.debug('beforeInsert');	     
        Additional_Account_User__c additionalUsers = (Additional_Account_User__c) so;
        Set<id> accSetIds = new Set<id>();
        checkUserDivision(additionalUsers.User__c,so);
  		accSetIds.add(additionalUsers.Account__c);      
        AutomatedAccountSegments updateJob = new AutomatedAccountSegments(accSetIds);
        ID jobID = System.enqueueJob(updateJob);
        
	}

	public void beforeUpdate(SObject oldSo, SObject so) {
		System.debug('beforeUpdate');
	}

	public void beforeDelete(SObject so) {
        System.debug('beforeDelete');	
       
        Additional_Account_User__c additionalUsers = (Additional_Account_User__c) so;
        Set<id> accSetIds = new Set<id>();
		accSetIds.add(additionalUsers.Account__c);      
        AutomatedAccountSegments updateJob = new AutomatedAccountSegments(accSetIds);
        ID jobID = System.enqueueJob(updateJob);
	}

	public void afterInsert(SObject so) {
		System.debug('afterInsert');
      
	}

	public void afterUpdate(SObject oldSo, SObject so) {
		System.debug('afterUpdate');
	}

	public void afterDelete(SObject so) {        
        System.debug('afterDelete');	       
        Additional_Account_User__c additionalUsers = (Additional_Account_User__c) so;
        Set<id> accSetIds = new Set<id>();
		accSetIds.add(additionalUsers.Account__c);      
        AutomatedAccountSegments updateJob = new AutomatedAccountSegments(accSetIds);
        ID jobID = System.enqueueJob(updateJob);
	}
	
	public void postProcessing() {
		
	}	
    
    private void checkUserDivision(Id userId,sObject so){
        User findAttachedUser = [SELECT SalesDivision__c FROM User WHERE id=:userId LIMIT 1];
        if(findAttachedUser.SalesDivision__c==null){
            so.addError('Fill Sales Division field for specified user, please.');
        }
    }
    
   
}