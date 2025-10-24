@isTest
private class PriceApprovalRequestTriggerHandlerTest extends BaseTest {
	
	//@IsTest
	//static void testGetJsonString() {
		//PriceApprovalRequestTriggerHandler.getJsonString('111111', 'SalesRep:1', '55616', 'Salesforce Administrator');
	//}

	@IsTest
	static void testChangeDocName() {
		PriceApprovalRequest__c par = [select Id, Name from PriceApprovalRequest__c].get(0);
		par.name = '2020/0002';
		update par;
	}

	@testSetup 
	static void testSetup() {
		
		Account testAccount = t.newAccounts('Test Account')[0];
		insert testAccount;

		PriceApprovalRequest__c par = new PriceApprovalRequest__c();
		par.Account__c = testAccount.Id;
		par.Name = '2020/0001';
		insert par;
	}

	static { BaseTest.t = new PriceApprovalRequestTriggerHandlerTest(); }
	static BaseTest t { get { return BaseTest.t; } }
}