public class AutomatedAccountSegments implements Queueable {
	
    Set<id> accliList = new Set<id>();
    public AutomatedAccountSegments(Set<id> newList ) {
        this.accliList = newList;
        
    }
    
    public void execute(QueueableContext context) {
        for(Id acc : this.accliList){
            set<String> allMarketValues = new Set<String>();
            Account currentAcc = [SELECT id,All_Market_Segments__c FROM Account WHERE id=:acc LIMIT 1];
			List<Additional_Account_User__c> addUsers = [SELECT Market_Segment__c FROM Additional_Account_User__c WHERE Account__c=:acc];
            for(Additional_Account_User__c addU : addUsers){
               allMarketValues.add(addU.Market_Segment__c);
            }
            system.debug(allMarketValues);
            String completedFieldValue ='';
            for(String str:allMarketValues){
                system.debug(completedFieldValue);
                system.debug(str);
                completedFieldValue+= str+';';
            }
            system.debug(completedFieldValue);
            completedFieldValue = completedFieldValue.removeEnd(';');
            system.debug(completedFieldValue);
            currentAcc.All_Market_Segments__c = completedFieldValue;
            system.debug(currentAcc.All_Market_Segments__c);
            update currentAcc;
        }
    }
}