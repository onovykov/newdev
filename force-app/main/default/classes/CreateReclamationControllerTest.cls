@isTest
public class CreateReclamationControllerTest extends BaseTest {
	
    public static String PROFILE_NAME_ADMINISTRATOR = 'System Administrator';
    
    @isTest static void initialInforTest(){
        
        User testUserAdministrator = CreateReclamationTestUtility.createTestUserAdministrator(PROFILE_NAME_ADMINISTRATOR);
		testUserAdministrator.SalesDivision__c = '00004';   
        testUserAdministrator.ID_ERP__c = 'ADM1';
        testUserAdministrator.EmployeeNumber = 'ADM1';
        insert testUserAdministrator;
        
        Id profileId = [SELECT Id FROM Profile WHERE Name ='Customer Community User (Custom)'].Id;
        Account acc = CreateReclamationTestUtility.createAccount('new account');
        insert acc;
        Contact con = CreateReclamationTestUtility.createContact('test','Contact','test@gmail.com',acc.Id);
        insert con;
        User u = CreateReclamationTestUtility.createCommunityUser(con.Id,profileId,'Amit','Singh');
        u.ID_ERP__c = 'TEST1';
        u.EmployeeNumber = 'TEST1';
        u.SalesDivision__c = '00004';
        u.ManagerId = testUserAdministrator.id;
        insert u;
        system.debug(u);
        System.runAs( u ){
        String res = CreateReclamationController.takeInitialInfo();
        }
    }
    	
    @isTest static void mapDependeciesTest(){
        string controllingFieldAPI = 'Mistmatch_Type__c';
        string dependingFieldAPI = 'Mistmatch_SubType__c';
        Reclamation_Detail__c obj = new Reclamation_Detail__c();
        CreateReclamationController.getDependentMap(obj,controllingFieldAPI,dependingFieldAPI);
        
    }
    
    @isTest static void getOrderItemsTest(){
       Order o = [SELECT id FROM order LIMIT 1];
        system.debug(o);
        Map<String,List<OrderItem>> reqValue = CreateReclamationController.getOrderItems(o.Id);
        system.assertEquals(1, reqValue.get(o.id).size(), 'not expected size');
    }
    
     @isTest static void createReclamationTest(){
       Order o = [SELECT id,ordernumber FROM order LIMIT 1];
       OrderItem oi = [SELECT id FROM orderItem LIMIT 1];
       Product2 p = [SELECT id FROM product2 LIMIT 1];  
         string reclamation = '{"orderNumber":"456456","reclSum":"6456456","contractDate":"2021-08-25","marketSegment":"00002","noRefund":true}';
         string data = '[{"Id":"'+oi.id+'","Product2Id":"'+p.id+'","UnitPrice":2,"Quantity":1,"OrderId":"'+o.id+'",'
            + '"ID_ERP__c":"0001","Product2":{"Name":"Axle","ID_ERP__c":"10","Id":"01t0Y00000823A6QAI"},"Order":{"Id":"8010E0000031cyxQAA","OrderNumber":"00049499"},'
              +'"selected":true,"claimPrice":"10","claimQuaintity":"5","mismatchType":"Logistic","mismatchSubType":"simple vehicle","mismatchSubDate":"2021-08-28"}]';
         CreateReclamationController.createReclamation(reclamation,data);
        List<Reclamation__c> reclList = [SELECT Id FROM Reclamation__c];
         
        Test.setMock(WebServiceMock.class, new ERP_WebServiceMock((String) reclList[0].Id, '123456', '22222'));
        
         t.start();            
 			ReclamationJSONGenerator.createJsonData(reclList);
		t.stop();
        
         
        system.assertEquals(1, reclList.size(), 'not expected size');
        List<Reclamation_Detail__c> reclDetailList = [SELECT Id FROM Reclamation_Detail__c];
         system.assertEquals(1, reclDetailList.size(), 'not expected size');
    }
    
    @testSetup static void testSetup() {
        
        List<Product2> prList = new List<Product2>();
        for(Integer i=0; i<3; i++){
            Product2 pr = t.newProducts('test'+i, '000')[0];
            if(i==0){
                pr.Type__c = 'Tube';
				pr.Family='OCTG';
            }
            else{
                pr.Type__c = 'Wheel';
            }
            
            prList.add(pr);
        }
        insert prList;
        
        Account acc = CreateReclamationTestUtility.createAccount('Test Account');
        insert acc;
        
       Id pricebookId = Test.getStandardPricebookId();
        
            // Insert Product
    Product2 p = new Product2();
    p.Name = ' Test Product ';
    p.Description='Test Product Entry 1';
    p.productCode = 'ABC';
    p.isActive = true;
    insert p;
        
        // Insert PricebookEntry

    PricebookEntry standardPrice = new PricebookEntry();
    standardPrice.Pricebook2Id = pricebookId;
    standardPrice.Product2Id = p.Id;
    standardPrice.UnitPrice = 1;
    standardPrice.IsActive = true;
    standardPrice.UseStandardPrice = false;
    insert standardPrice ;
        
     Order orderTest = new Order(
        		AccountId = acc.Id,
            	EffectiveDate = system.today(),
            	EndDate = system.today() + 4,
            	Status = 'Draft',
         		Pricebook2Id =  pricebookId,
         		ID_ERP__c = '12312331',
        		ITENumber__c = '34324234'
        );
        insert orderTest;    
        
        OrderItem i = new OrderItem();
    i.OrderId = orderTest.id;
    i.Quantity = 24;
    i.UnitPrice = 240;
    i.Product2id = p.id;
    i.PricebookEntryId=standardPrice.id;
    insert i;  
        
    Account testAccount = t.newAccounts('for test') [0];
		testAccount.ID_ERP__c = '12';
		testAccount.BillingCity = 'City';
		testAccount.BillingCountry = 'Ukraine';
		testAccount.BillingStreet = 'Street';
		testAccount.BillingPostalCode = '123456';
		testAccount.ShippingCity = 'ShipCity';
		testAccount.ShippingCountry = 'Ukraine';
		testAccount.ShippingStreet = 'ShipStreet';
		testAccount.ShippingPostalCode = '54321';
		testAccount.Description = 'Testnewtest';
        testAccount.MarketSegment__c = '00002';
		insert testAccount;


		Opportunity testOpp = t.newOpportunities('Test', testAccount.Id, 'Qualification', Date.today()) [0];
		insert testOpp;

		Id pricebookId2 = Test.getStandardPricebookId();
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
		                                                        Pricebook2Id = pricebookId2,
		                                                        Product2Id = testProd1.Id,
		                                                        UnitPrice = 1000.00,
		                                                        IsActive = true
		);
		insert testPriceBookEntry1;
		PricebookEntry testPriceBookEntry2 = new PricebookEntry(
		                                                        Pricebook2Id = pricebookId2,
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
        testOppProd1.Quantity = 10;
		insert testOppProd1;
        
        User TestUser = t.newUser('test@test.com');
		insert TestUser;
        
		Contact Testcontact = t.newContacts('Test', 'Birthday') [0];
		Testcontact.AccountId = TestAccount.Id;
		Testcontact.Birthdate = Date.today().addDays(5);
		insert Testcontact;
               		
        
        
    }
    
    private class ERP_WebServiceMock implements WebServiceMock {

		String oppId;
		String ERP_ID;
		String SyncDateTime;
		String isError;

		public ERP_WebServiceMock(String oppId, String ERP_Id, String SyncDateTime, String isError) {
			//this(oppId, ERP_Id);
			this.oppId = oppId;
			this.ERP_ID = ERP_Id;
			this.isError = isError;
			this.SyncDateTime = SyncDateTime;
		}

		public ERP_WebServiceMock(String oppId, String ERP_Id, String SyncDateTime) {
			this.oppId = oppId;
			this.ERP_ID = ERP_Id;
			this.SyncDateTime = SyncDateTime;
			isError = '';
		}

		private final String LOGIN_RESPONCE = '{"Success":true,"UserName":"IT_SF","Ticket":"11917DDC-C039-4C59-B010-ED6335073AF7","FailReason":null,"NeedChangePassword":false,"TempPasswordRequired":false,"TempPasswordMessage":null}';
		private final String ACCEPTED_RESPONCE = '{"Success":true,"Comments":""}';
        private final String DENIED_RESPONCE = '{"Success":false,"Comments":"* ERROR *nЗначение не может быть неопределенным.rnИмя параметра: valuen* INBOUND DATA *n"}';
        private final String WRONGJSON_RESPONCE = '"{"Success":false,"Comments":"* ERROR *nЗначение не может быть неопределенным.rnИмя параметра: valuen* INBOUND DATA *n"}"';
		//private final String OPPO_ACCEPTED_RESPONCE = '"{\"Opportunity_ID\":{\"ID_SF\":\"%oppID%\",\"ID_ERP\":\"%erpId%\"}}"';
		private final String ERROR_RESPONSE = '"{\"ErrorType\": \"JSON Data Error\",\"ErrorMessage\": \"Wrong Account_ID_ERP value, expected int.\"}"';

		public void doInvoke(
		                     Object stub,
		                     Object request,
		                     Map<String, Object> response,
		                     String endpoint,
		                     String soapAction,
		                     String requestName,
		                     String responseNS,
		                     String responseName,
		                     String responseType) {

			if (request instanceOf SFToERP.LoginEx_element) {
				SFToERP.LoginExResponse_element resp = new SFToERP.LoginExResponse_element();
				resp.LoginExResult = LOGIN_RESPONCE;
				response.put('response_x', resp);
			} else if (request instanceOf SFToERP.ExecuteEx_element) {
				if(isError.equals('falseSuccess')){
                    SFToERP.ExecuteExResponse_element resp = new SFToERP.ExecuteExResponse_element();
					resp.ExecuteExResult = DENIED_RESPONCE;
					system.debug(request);
					response.put('response_x', resp);
                }else if (isError.equals('exception')) {
					throw new CalloutException('Test');
				}else if (isError.equals('jsonError')) {
					SFToERP.ExecuteExResponse_element resp = new SFToERP.ExecuteExResponse_element();
					resp.ExecuteExResult = WRONGJSON_RESPONCE;
					system.debug(request);
					response.put('response_x', resp);
				}else {
					SFToERP.ExecuteExResponse_element resp = new SFToERP.ExecuteExResponse_element();
					resp.ExecuteExResult = ACCEPTED_RESPONCE;
					system.debug(request);
					response.put('response_x', resp);
				}
			}
		}
	}
    	        
    	static { BaseTest.t = new CreateReclamationControllerTest(); }
		static BaseTest t { get { return BaseTest.t; } }
    
}