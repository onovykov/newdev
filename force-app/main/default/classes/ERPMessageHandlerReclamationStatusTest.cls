@isTest
public class ERPMessageHandlerReclamationStatusTest extends BaseTest {

    @isTest static void createReclamationTest(){
       Reclamation__c reclamationCreated = [SELECT id,Status__c,Name FROM Reclamation__c LIMIT 1];
       system.debug(reclamationCreated.Name);
       //String numberReclamation = reclamationCreated.Name;
       // String receivedBody = '{"Metadata":{"MsgType":"ERP-SF_ClaimStage","MsgTypeVersion":0.0,"MsgTimestamp":"2022-01-06T11:47:42.6412379+02:00","PartNumber":1,"TotalParts":1},"Data":{"ID_in_ERP":50,"NUMBER_RECLAMATION":"' +numberReclamation+'","STAGE":"_2"}}';
		String receivedBody = '{"MessageType": "ERP-SF_ReclamationStatus","ID_in_ERP": 102,"NUMBER_RECLAMATION": "12345", "STAGE": "_2"}';
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
        
        Reclamation__c reclamationUpdated = [SELECT id,Status__c,Name FROM Reclamation__c LIMIT 1];
        System.assertEquals('Draft',reclamationUpdated.Status__c);
    }
    
    
    @testSetup static void testSetup() {
        
        Country__c country = new Country__c(Name = 'test', A2Code__c = '15', A3Code__c = '25', NumCode__c = '0');
        insert country;
    
        Shop__c shop_n_s = new Shop__c(Id_ERP__c = '0', Name = 'Not specified');
        insert shop_n_s;
        
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
        
        Reclamation__c newReclamation = new Reclamation__c();
        newReclamation.Status__c = 'Draft';
        newReclamation.ERP_Number__c = '12345';
        insert newReclamation;
        

	}
    static { BaseTest.t = new ERPMessageHandlerReclamationStatusTest(); }
    static BaseTest t { get { return BaseTest.t; } }
}