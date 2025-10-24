@isTest 
public class ReclamationDetailTriggerHandlerTest extends BaseTest {
	
    @isTest static void deleteReclamationItemTest(){     
        
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
    
    Order testOrder = new Order();
        testOrder.AccountId = testAccount.id;
		testOrder.EffectiveDate = date.TODAY();
		testOrder.Status = 'Draft';        
    	testOrder.ID_ERP__c = '12312331';
        testOrder.ITENumber__c = '34324234';
   		insert testOrder;
        
        Reclamation__c newReclamation = new Reclamation__c(
        Status__c = 'Draft'
        );
        insert newReclamation;
        system.debug(newReclamation.Status__c );
        Reclamation_Detail__c newReclamationDetail = new Reclamation_Detail__c();
        newReclamationDetail.ReclID__c = newReclamation.id;
        newReclamationDetail.OrderID__c = testOrder.id;
        insert newReclamationDetail;
        
         t.start();            
 		delete newReclamationDetail;	
		t.stop();
                        
    }
    
    
    static { BaseTest.t = new ReclamationDetailTriggerHandlerTest(); }
	static BaseTest t { get { return BaseTest.t; } }
}