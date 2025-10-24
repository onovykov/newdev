@isTest
public class ERPMessageHandlerOrderItemStageTest  extends BaseTest {

      
    @isTest static void updateOppOrderRecordsTest(){
      
		
        String receivedBody = ' {"Metadata": {"MsgType": "ERP-SF_OrderItemStage","MsgTypeVersion": 0.0,"MsgTimestamp": "2022-02-13T12:48:06.8509695+02:00","PartNumber": 1,"TotalParts": 1},"Data": { "Undoc": 1335452,"Npp": 1,"Stage": "_12"}}';
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
    
        req.requestURI = '/ERPtoSF/v1/*';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(receivedBody);
        RestContext.request = req;
        RestContext.response = res;
    
        Test.startTest();       
        ERPtoSF.postCST();
        Test.stopTest();
        
       
    }
    
    @isTest static void cancelOpportunityTest(){
      
		
        String receivedBody = ' {"Metadata": {"MsgType": "ERP-SF_OrderItemStage","MsgTypeVersion": 0.0,"MsgTimestamp": "2022-02-13T12:48:06.8509695+02:00","PartNumber": 1,"TotalParts": 1},"Data": { "Undoc": 1335452,"Npp": 1,"Stage": "_5"}}';
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
    
        req.requestURI = '/ERPtoSF/v1/*';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(receivedBody);
        RestContext.request = req;
        RestContext.response = res;
    
        Test.startTest();       
        ERPtoSF.postCST();
        Test.stopTest();
        
       
    }
    
    @isTest static void updateOppOrderRecordsUnknownStageTest(){
       
		
        String receivedBody = ' {"Metadata": {"MsgType": "ERP-SF_OrderItemStage","MsgTypeVersion": 0.0,"MsgTimestamp": "2022-02-13T12:48:06.8509695+02:00","PartNumber": 1,"TotalParts": 1},"Data": { "Undoc": 1335452,"Npp": 1,"Stage": "_56"}}';
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
    
        req.requestURI = '/ERPtoSF/v1/*';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(receivedBody);
        RestContext.request = req;
        RestContext.response = res;
    
        Test.startTest();       
        ERPtoSF.postCST();
        Test.stopTest();
        
      
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
            
            Account acc = t.newAccounts('Test Account')[0];
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
       
            Country__c country = new Country__c(Name = 'test', A2Code__c = '15', A3Code__c = '25', NumCode__c = '0');
        insert country;
    
        Shop__c shop_n_s = new Shop__c(Id_ERP__c = '0', Name = 'Not specified');
        insert shop_n_s;
    
        User newUser = t.newUser('john@acme.com');
        insert newUser;
    
        UserID_ERP__c user_id_in_erp = new UserID_ERP__c(Name = '54124', User__c = newUser.Id);
        insert user_id_in_erp;
    
        Account testAccount = t.newAccounts('Test Account') [0];
        testAccount.ID_ERP__c = '22449';
        insert testAccount;
    
        ProductStandard__c qStan = new ProductStandard__c();
        insert qStan;
    
        SteelGrade__c sGrade = new SteelGrade__c(ShortName__c = 'sg1');
        insert sGrade;
    
        TubeEnds__c tubeEnds = new TubeEnds__c(ShortName__c = 'EUE',Id_ERP__C='Г');
        insert tubeEnds;
    
        Plant__c plant = new Plant__c(FullName__c = 'Plant Full Name');
        insert plant;
        
        Shop__c shop = new Shop__c(Plant__c = plant.Id);
        insert shop;
        
        TubeOD__c tubeOD = new TubeOD__c(ID_ERP__c = '0H');
        insert tubeOD;
        
        TubeWT__c tubeWT = new TubeWT__c(ID_ERP__c = '2B');
        insert tubeWT;
        
        Opportunity testOpp = t.newOpportunities('Test', testAccount.Id, 'Qualification', Date.today()) [0];
        testOpp.ID_ERP__c = '1335452';
        
        insert testOpp;
                   
        List<Product2> prodList = new List<Product2>();
        Product2 testProd1 = t.newProducts('Test product', '0000') [0];
        testProd1.ID_ERP__c = 'tt';
        //testProd1.Family = 'OCTG';
        prodList.add(testProd1);
        Product2 testProd2 = t.newProducts('Test product2', '0001') [0];
        testProd2.ID_ERP__c = 'tq';
        //testProd2.Family = 'OCTG';
        prodList.add(testProd2);
        insert prodList;
    
        List<PricebookEntry> pbeList = new List<PricebookEntry>();
        PricebookEntry testPriceBookEntry1 = new PricebookEntry(
                                                                Pricebook2Id = pricebookId,
                                                                Product2Id = testProd1.Id,
                                                                UnitPrice = 100.00,
                                                                IsActive = true
        );
        pbeList.add(testPriceBookEntry1);
        PricebookEntry testPriceBookEntry2 = new PricebookEntry(
                                                                Pricebook2Id = pricebookId,
                                                                Product2Id = testProd2.Id,
                                                                UnitPrice = 200.00,
                                                                IsActive = true
        );
        pbeList.add(testPriceBookEntry2);
        insert pbeList;
    
        List<OpportunityLineItem> oplineItems = new List<OpportunityLineItem>();
    
        OpportunityLineItem testOppProd1 = t.newOpportunityProducts(testPriceBookEntry1.Id, testOpp.Id) [0];
        testOppProd1.Quantity = 3;
        testOppProd1.InquiryQuantity__c = 3;
        testOppProd1.InquiryUnit__c = '34';
        
        testOppProd1.NPP_ERP__c = '1';
        testOppProd1.ProductType__c = 'Tube';
        testOppProd1.TotalPrice = testPriceBookEntry1.UnitPrice;
        testOppProd1.SteelGrade__c = sGrade.Id;
        testOppProd1.TubeEnds__c = tubeEnds.Id;
        testOppProd1.Shop__c = shop.Id;
        testOppProd1.TubeOD__c = tubeOD.Id;
        //testOppProd1.ID_ERP__c = '12345';
       
	
		insert testOppProd1;
        OpportunityLineItem getInsertedOppItem = [SELECT ID_ERP__c FROM OpportunityLineItem WHERE id=:testOppProd1.id LIMIT 1];
        
        OrderItem i = new OrderItem();
            i.OrderId = orderTest.id;
            i.Quantity = 24;
            i.UnitPrice = 240;
            i.Product2id = p.id;
            i.PricebookEntryId=standardPrice.id;
        	i.ID_ERP__c = getInsertedOppItem.ID_ERP__c;
        insert i; 

	}
    
    static { BaseTest.t = new ERPMessageHandlerOrderItemStageTest(); }
    static BaseTest t { get { return BaseTest.t; } }
}