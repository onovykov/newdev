global class AccountDuplicatesBatch implements Database.Batchable<sObject> {
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
        
		String query = 'SELECT Name, Shortened_Name__c FROM Account';		
		return Database.getQueryLocator(query);
	}
	
	global void execute(Database.BatchableContext BC, List<Account> scope) {
		for(Account a : scope) {
			a.Shortened_Name__c = a.Name.toUpperCase().deleteWhitespace().replaceAll('\\p{Punct}','');
            system.debug('acc Shortened Name  ---> ' + a.Shortened_Name__c +'/ / / / / / ' + 'acc Name ----------------------------->>>' + a.name);
            system.debug(a.id);
		}
		update scope;
        
	}
	
	global void finish(Database.BatchableContext BC) {
	}
}