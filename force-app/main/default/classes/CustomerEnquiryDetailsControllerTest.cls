@isTest
public class CustomerEnquiryDetailsControllerTest extends BaseTest {
	
        public static String PROFILE_NAME = 'Customer Community User (Custom)';
    	public static String PROFILE_NAME_ADMINISTRATOR = 'System Administrator';
        public static String COUNTRY_NAME = 'Andorra';
        public static String COUNTRY_A2CODE = 'AD';
        public static String COUNTRY_A3CODE = 'AND';
        public static String COUNTRY_NUMCODE = '20';
       
    @isTest static void takeInitialInfoTest(){
        
        CustomerEnquiry__c customerEnquiry = [SELECT id FROM CustomerEnquiry__c LIMIT 1];
        String idod = [SELECT id FROM TubeOD__c LIMIT 1].id ;
        String idwt = [SELECT id FROM TubeWT__c LIMIT 1].id;
        String idsize = [SELECT id FROM TubeLengthSize__c LIMIT 1].id;
        String oppId = [SELECT OpportunityId__c FROM CustomerEnquiry__c WHERE id=:customerEnquiry.id LIMIT 1].OpportunityId__c;                                
        
        //set line items for new created opp 
        createItemForEnquity(oppId,idod,idwt,idsize); 
        
        Test.startTest();
        	List<CustomerEnquiryDetailsController.WrapperProducts> checkProducts = CustomerEnquiryDetailsController.takeInitialInfo(customerEnquiry.id);
        Test.stopTest();
        
         //System.assertEquals(2, checkProducts.size(),'Not expected size of array');
    }    
    
    
    @testSetup static void testSetup() {
        
        User testUserAdmin = CustomNewEnquiryControllerTestFactory.createTestUserAdministrator(PROFILE_NAME_ADMINISTRATOR);
        insert testUserAdmin;
        
      	Country__c userContactCountry = CustomNewEnquiryControllerTestFactory.createUserContactCountry(COUNTRY_NAME, COUNTRY_A2CODE, COUNTRY_A3CODE, COUNTRY_NUMCODE);
        insert userContactCountry;
        
        Account userAccountQueried = CustomNewEnquiryControllerTestFactory.createUserAccount();
        
        Contact userContact = CustomNewEnquiryControllerTestFactory.createUserContact(userAccountQueried.Id, COUNTRY_NAME);
        insert userContact;
        
        User testUser = CustomNewEnquiryControllerTestFactory.createTestUser(PROFILE_NAME, userContact.Id);
        testUser.ManagerId = testUserAdmin.id;
        insert testUser; 
                  			                         
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
       

		Opportunity testOpp = t.newOpportunities('Test', testAccount.Id, 'Qualification', Date.today()) [0];
        testOpp.StageName = 'Qualification';
        //testOpp.AssignedBOS__c = bo_user.id;
        testOpp.OwnerId = testUser.Id;
		insert testOpp;

		Id pricebookId = Test.getStandardPricebookId();
		Product2 testProd1 = t.newProducts('Test product', '0000') [0];
		
        testProd1.ID_ERP__c = 'pr1';
		testProd1.Type__c = 'Tube';
        testProd1.Family = 'LP/GU';
		insert testProd1;
		Product2 testProd2 = t.newProducts('Test product2', '0001') [0];
		testProd2.ID_ERP__c = 'pr2';
		testProd2.Type__c = 'Tube';
        testProd2.Family = 'OCTG';
		insert testProd2;

		PricebookEntry testPriceBookEntry1 = new PricebookEntry(
		                                                        Pricebook2Id = pricebookId,
		                                                        Product2Id = testProd1.Id,
		                                                        UnitPrice = 1000.00,
		                                                        IsActive = true
		);
		insert testPriceBookEntry1;
		PricebookEntry testPriceBookEntry2 = new PricebookEntry(
		                                                        Pricebook2Id = pricebookId,
		                                                        Product2Id = testProd2.Id,
		                                                        UnitPrice = 1000.00,
		                                                        IsActive = true
		);
		insert testPriceBookEntry2;

		TubeOD__c od = new TubeOD__c(ID_ERP__c = 'od', OD_mm__c = 48.30, OD_inch__c = 1.9);
		insert od;

		TubeWT__c wt = new TubeWT__c(ID_ERP__c = 'wt', Name = 'TestWT', WT_mm__c = 5.08, WT_inch__c = 0.2);
		insert wt;

		TubeLengthSize__c size = new TubeLengthSize__c(ID_ERP__c = 'si', Name = 'testLS');
		size.MaxLength__c = 5800;
		size.MinLength__c = 5600;
		size.Type__c = 'R1';
		insert size;

		OpportunityLineItem testOppProd1 = t.newOpportunityProducts(testPriceBookEntry1.Id, testOpp.Id) [0];
		
        testOppProd1.InquiryUnit__c = '20';
		testOppProd1.InquiryQuantity__c = 18484.288;
		testOppProd1.TubeOD__c = od.Id;
		testOppProd1.TubeWT__c = wt.Id;
		testOppProd1.Weight_kpm__c = 5.41;
		testOppProd1.Weight_ppf__c = 3.63;
		testOppProd1.LengthSize__c = size.Id;
		testOppProd1.ID_ERP__c = '0001';
		testOppProd1.ProductType__c = 'Tube';
		testOppProd1.UnitPrice = testPriceBookEntry1.UnitPrice;
		testOppProd1.InquiryUnitPrice__c = 5.41;
        testOppProd1.ITENumber__c = 'tett2';
		insert testOppProd1;
		OpportunityLineItem testOppProd2 = t.newOpportunityProducts(testPriceBookEntry2.Id, testOpp.Id) [0];
		
        testOppProd2.InquiryUnit__c = '20';
		testOppProd2.Quantity = 100;
		testOppProd2.InquiryQuantity__c = 18484.288;
		testOppProd2.ID_ERP__c = '0002';
		testOppProd2.ProductType__c = 'Tube';
		testOppProd2.InquiryUnitPrice__c = 5.41;
        testOppProd2.ITENumber__c = 'tett';
		insert testOppProd2;
           
        CustomerEnquiry__c customerEnquiry = new CustomerEnquiry__c();
        customerEnquiry.OpportunityId__c = testOpp.id;
        customerEnquiry.OwnerId = testUser.Id;
        customerEnquiry.SalesRepId__c = testUser.Id;
        insert customerEnquiry;
              
    }
    
    static void createItemForEnquity(String idNewOpp,String od,String wt, String size ){
        Id pricebookId = Test.getStandardPricebookId();
		Product2 testProd1 = t.newProducts('Test product2', '0000') [0];
		
        testProd1.ID_ERP__c = 'pr12';
		testProd1.Type__c = 'Tube';
        testProd1.Family = 'LP/GU';
		insert testProd1;
		Product2 testProd2 = t.newProducts('Test product22', '0001') [0];
		testProd2.ID_ERP__c = 'pr22';
		testProd2.Type__c = 'Tube';
        testProd2.Family = 'OCTG';
		insert testProd2;

		PricebookEntry testPriceBookEntry1 = new PricebookEntry(
		                                                        Pricebook2Id = pricebookId,
		                                                        Product2Id = testProd1.Id,
		                                                        UnitPrice = 1000.00,
		                                                        IsActive = true
		);
		insert testPriceBookEntry1;
		PricebookEntry testPriceBookEntry2 = new PricebookEntry(
		                                                        Pricebook2Id = pricebookId,
		                                                        Product2Id = testProd2.Id,
		                                                        UnitPrice = 1000.00,
		                                                        IsActive = true
		);
		insert testPriceBookEntry2;

		

		OpportunityLineItem testOppProd1 = t.newOpportunityProducts(testPriceBookEntry1.Id, idNewOpp) [0];
		
        testOppProd1.InquiryUnit__c = '20';
		testOppProd1.InquiryQuantity__c = 18484.288;
		testOppProd1.TubeOD__c = od;
		testOppProd1.TubeWT__c = wt;
		testOppProd1.Weight_kpm__c = 5.41;
		testOppProd1.Weight_ppf__c = 3.63;
		testOppProd1.LengthSize__c = size;
		testOppProd1.ID_ERP__c = '00010';
		testOppProd1.ProductType__c = 'Tube';
		testOppProd1.UnitPrice = testPriceBookEntry1.UnitPrice;
		testOppProd1.InquiryUnitPrice__c = 5.41;
        testOppProd1.ITENumber__c = 'tett222';
		insert testOppProd1;
		OpportunityLineItem testOppProd2 = t.newOpportunityProducts(testPriceBookEntry2.Id, idNewOpp) [0];
		
        testOppProd2.InquiryUnit__c = '20';
		testOppProd2.Quantity = 100;
		testOppProd2.InquiryQuantity__c = 18484.288;
		testOppProd2.ID_ERP__c = '00020';
		testOppProd2.ProductType__c = 'Tube';
		testOppProd2.InquiryUnitPrice__c = 5.41;
        testOppProd2.ITENumber__c = 'tett22';
		insert testOppProd2;
        
    }
         	        
    	static { BaseTest.t = new CustomerEnquiryDetailsControllerTest(); }
		static BaseTest t { get { return BaseTest.t; } }
}