@isTest
private class deleteLeadControllerTest extends BaseTest{
	
	@isTest static void test_deleteLead() {
		Lead testLead = t.createLeads()[0];
		testLead.Email = 'test@test.com';
    	insert testLead;
		
		t.start();
		deleteLeadController.deleteLead(testLead.Id);
		t.stop();

		List<Ignored_Emails__c> ignEmailList = [SELECT Id, Email_address__c FROM Ignored_Emails__c];
		System.assertEquals(1, ignEmailList.size());
		System.assertEquals('test@test.com', ignEmailList[0].Email_address__c);

		List<Lead> leads = [SELECT Id FROM Lead];
		System.assertEquals(0, leads.size());
	}

	@isTest static void test_deleteLeadWithoutEmail() {
		Lead testLead = t.createLeads()[0];
    	insert testLead;
		
		t.start();
		deleteLeadController.deleteLead(testLead.Id);
		t.stop();

		List<Ignored_Emails__c> ignEmailList = [SELECT Id, Email_address__c FROM Ignored_Emails__c];
		System.assertEquals(0, ignEmailList.size());
		
		List<Lead> leads = [SELECT Id FROM Lead];
		System.assertEquals(0, leads.size());
	}
	
	
	static { BaseTest.t = new deleteLeadControllerTest(); }
  	static BaseTest t { get { return BaseTest.t; } }
}