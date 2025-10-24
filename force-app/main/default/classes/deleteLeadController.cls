public with sharing class deleteLeadController {
	@AuraEnabled
    public static void deleteLead(Id leadId) {
    	Lead selectedLead = [SELECT Id, Email FROM Lead WHERE Id=:leadId];
    	if(selectedLead.Email!=null){
    		Ignored_Emails__c ignEmail = new Ignored_Emails__c(Email_address__c = selectedLead.Email);
    		insert ignEmail;
    	}
    	delete selectedLead;
    }
}