@isTest
public class LookupSearchComponentControllerTest  extends BaseTest {

    @isTest
	public static void testLookUpSearch() {
		LookupSearchComponentController.getResults('Account', 'ID_ERP__c', '1');
	}
    
    @testSetup
	static void testSetup() {

		Account testAccount = t.newAccounts('Test Account') [0];
		testAccount.ID_ERP__c = '1';
		testAccount.BillingCity = 'City';
		testAccount.BillingCountry = 'Ukraine';
		testAccount.BillingStreet = 'Street';
		testAccount.BillingPostalCode = '12345';
		testAccount.ShippingCity = 'ShipCity';
		testAccount.ShippingCountry = 'Ukraine';
		testAccount.ShippingStreet = 'ShipStreet';
		testAccount.ShippingPostalCode = '54321';
		testAccount.Description = 'Test';
		insert testAccount;
    }
    
    static { BaseTest.t = new LookupSearchComponentControllerTest(); }
	static BaseTest t { get { return BaseTest.t; } }
    
}