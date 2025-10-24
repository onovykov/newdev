global class AccountsBlockedUpdate implements Database.Batchable<SObject> {
	global Set<String> accIdErpSet = new Set<String>();
    
    global AccountsBlockedUpdate(Set<String> accIdSet) {
        system.debug(accIdSet);
        accIdErpSet = accIdSet;
    }
    
    global Database.QueryLocator start(Database.BatchableContext context) {
		return Database.getQueryLocator('SELECT Id, ID_ERP__c, Name FROM Account WHERE Id_ERP__c not in :accIdErpSet AND (DealingStatus__c ='+'\'10\' OR '+'DealingStatus__c ='+'\'40\')' );
	}
    
    global void execute(Database.BatchableContext context, List<Account> scope) {
		system.debug(accIdErpSet);
        List<Account> accListToUpdate = new List<Account>();
        for (Account acc : scope) {
            acc.Balance__c = 0;
            acc.PastDueDebt__c = 0;
            acc.PastDueDebt15More__c = 0;
            acc.GroupPastDueDebt__c = 0;
            acc.GroupPastDueDebt15More__c = 0;  
            acc.DealingStatus__c = '0';
            accListToUpdate.add(acc);
        }
        update accListToUpdate;

	}
    
    global void finish(Database.BatchableContext context) {
		
	}
}