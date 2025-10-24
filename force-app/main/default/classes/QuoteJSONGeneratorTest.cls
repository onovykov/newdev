@isTest
public class QuoteJSONGeneratorTest extends BaseTest {

    @isTest
    static void testCreateQuoteSuccess(){
       	
         OpportunityLineItem oli = [SELECT Id, OpportunityId, PriceBookEntryId, Product2Id, TubeEnds__c, LengthSize__c, InquiryUnit__c, TubeOD__c, Name__c, 
                            ProductSpecLevel__c, ProductStandard__c, InquiryQuantity__c, InquiryUnitPrice__c, Quantity, UnitPrice, 
                            ShippingPoint__c, Shop__c, SteelGrade__c, Weight_kpm__c, Weight_ppf__c, TubeWT__c,ID_ERP__c,ITENumber__c
                            FROM OpportunityLineItem LIMIT 1];
        Quote testQuote = new Quote(Name='Test',ExpirationDate = Date.today(), OpportunityId = oli.OpportunityId, Pricebook2Id = Test.getStandardPricebookId());
        
        insert testQuote;
        Quote testQuoteJson = [SELECT ID, ExpirationDate, QuoteNumber FROM Quote WHERE ID=:testQuote.id];
        QuoteLineItem qli = new QuoteLineItem(OpportunityLineItemId = oli.Id, QuoteId = testQuote.Id, PriceBookEntryId = oli.PriceBookEntryId,
                                              Quantity=oli.Quantity, UnitPrice=oli.UnitPrice, InquiryQuantity__c=oli.InquiryQuantity__c, InquiryUnitPrice__c=oli.InquiryUnitPrice__c, Product2Id = oli.Product2Id);
        insert qli;
        
        QuoteLineItem qliJson = [SELECT id, QuoteId, PriceBookEntryId,Quantity ,UnitPrice ,OpportunityLineItemId,
                                 InquiryQuantity__c ,InquiryUnitPrice__c,Product2Id,LastModifiedDate,InquiryUnit__c FROM QuoteLineItem WHERE ID=:qli.id ];
        
        List<QuoteLineItem> qItems = new List<QuoteLineItem>();
        List<OpportunityLineItem> oItems = new List<OpportunityLineItem>();
        qItems.add(qliJson);
        oItems.add(oli);
    	String expectedStr = generateJSON(testQuoteJson, qItems, oItems);
        Test.setMock(WebServiceMock.class, new ERP_WebServiceMock((String) testQuote.Id, '123456', '22222'));              
    	
        t.start();            
 			QuoteJSONGenerator.createJsonData(new List<String>{testQuote.id}); 
        	System.assertEquals(0, Limits.getEmailInvocations(),'email was send');
		t.stop();
        
        //System.assertEquals(1, Limits.getEmailInvocations(),'email was send');
	               
    }
    
    @isTest
    static void testCreateQuoteError(){
       	 OpportunityLineItem oli = [SELECT Id, OpportunityId, PriceBookEntryId, Product2Id, TubeEnds__c, LengthSize__c, InquiryUnit__c, TubeOD__c, Name__c, 
                            ProductSpecLevel__c, ProductStandard__c, InquiryQuantity__c, InquiryUnitPrice__c, Quantity, UnitPrice, 
                            ShippingPoint__c, Shop__c, SteelGrade__c, Weight_kpm__c, Weight_ppf__c, TubeWT__c,ID_ERP__c,ITENumber__c
                            FROM OpportunityLineItem LIMIT 1];
        Quote testQuote = new Quote(Name='Test',ExpirationDate = Date.today(), OpportunityId = oli.OpportunityId, Pricebook2Id = Test.getStandardPricebookId());
        
        insert testQuote;
        Quote testQuoteJson = [SELECT ID, ExpirationDate, QuoteNumber FROM Quote WHERE ID=:testQuote.id];
        QuoteLineItem qli = new QuoteLineItem(OpportunityLineItemId = oli.Id, QuoteId = testQuote.Id, PriceBookEntryId = oli.PriceBookEntryId,
                                              Quantity=oli.Quantity, UnitPrice=oli.UnitPrice, InquiryQuantity__c=oli.InquiryQuantity__c, InquiryUnitPrice__c=oli.InquiryUnitPrice__c, Product2Id = oli.Product2Id);
        insert qli;
        
        QuoteLineItem qliJson = [SELECT id, QuoteId, PriceBookEntryId,Quantity ,UnitPrice , OpportunityLineItemId,
                                 InquiryQuantity__c ,InquiryUnitPrice__c,Product2Id,LastModifiedDate,InquiryUnit__c FROM QuoteLineItem WHERE ID=:qli.id ];
        
        List<QuoteLineItem> qItems = new List<QuoteLineItem>();
        List<OpportunityLineItem> oItems = new List<OpportunityLineItem>();
        qItems.add(qliJson);
        oItems.add(oli);
    	String expectedStr = generateJSON(testQuoteJson, qItems, oItems);
        Test.setMock(WebServiceMock.class, new ERP_WebServiceMock((String) testQuote.Id, '123456', '22222','falseSuccess')); 
        
        t.start();            
 			QuoteJSONGenerator.createJsonData(new List<String>{testQuote.id}); 
        	QuoteJSONGenerator.makeCallout(expectedStr);
        system.assertEquals(1, Limits.getFutureCalls());
			//System.assertEquals(1, 1);        	
		t.stop();
                              	               
    }
    
    @isTest
    static void test_Error_ERPCalloutException(){
       	
         OpportunityLineItem oli = [SELECT Id, OpportunityId, PriceBookEntryId, Product2Id, TubeEnds__c, LengthSize__c, InquiryUnit__c, TubeOD__c, Name__c, 
                            ProductSpecLevel__c, ProductStandard__c, InquiryQuantity__c, InquiryUnitPrice__c, Quantity, UnitPrice, 
                            ShippingPoint__c, Shop__c, SteelGrade__c, Weight_kpm__c, Weight_ppf__c, TubeWT__c,ID_ERP__c,ITENumber__c
                            FROM OpportunityLineItem LIMIT 1];
        Quote testQuote = new Quote(Name='Test',ExpirationDate = Date.today(), OpportunityId = oli.OpportunityId, Pricebook2Id = Test.getStandardPricebookId());
        
        insert testQuote;
        Quote testQuoteJson = [SELECT ID, ExpirationDate, QuoteNumber FROM Quote WHERE ID=:testQuote.id];
        QuoteLineItem qli = new QuoteLineItem(OpportunityLineItemId = oli.Id, QuoteId = testQuote.Id, PriceBookEntryId = oli.PriceBookEntryId,
                                              Quantity=oli.Quantity, UnitPrice=oli.UnitPrice, InquiryQuantity__c=oli.InquiryQuantity__c, InquiryUnitPrice__c=oli.InquiryUnitPrice__c, Product2Id = oli.Product2Id);
        insert qli;
        
        QuoteLineItem qliJson = [SELECT id, QuoteId, PriceBookEntryId,Quantity ,UnitPrice ,OpportunityLineItemId,
                                 InquiryQuantity__c ,InquiryUnitPrice__c,Product2Id,LastModifiedDate,InquiryUnit__c FROM QuoteLineItem WHERE ID=:qli.id ];
        
        List<QuoteLineItem> qItems = new List<QuoteLineItem>();
        List<OpportunityLineItem> oItems = new List<OpportunityLineItem>();
        qItems.add(qliJson);
        oItems.add(oli);
    	String expectedStr = generateJSON(testQuoteJson, qItems, oItems);
        Test.setMock(WebServiceMock.class, new ERP_WebServiceMock((String) testQuote.Id, '123456', '22222','exception'));              
    	
        String errorMsg;
         
        	try {
               t.start();  
 			QuoteJSONGenerator.createJsonData(new List<String>{testQuote.id});
                t.stop();
        	} catch(AuraHandledException e){
             System.Debug('Hi inside Catch block');   
			system.assert(e.getMessage().contains('Call invalid for json quote item'));
            System.debug(e.getMessage());
            System.debug(e.getTypeName());  
                
			}
		
        
        //System.assertEquals(1, Limits.getEmailInvocations(),'email was send');
	               
    }
    
     @isTest
    static void test_Error_JSONException(){
       	
         OpportunityLineItem oli = [SELECT Id, OpportunityId, PriceBookEntryId, Product2Id, TubeEnds__c, LengthSize__c, InquiryUnit__c, TubeOD__c, Name__c, 
                            ProductSpecLevel__c, ProductStandard__c, InquiryQuantity__c, InquiryUnitPrice__c, Quantity, UnitPrice, 
                            ShippingPoint__c, Shop__c, SteelGrade__c, Weight_kpm__c, Weight_ppf__c, TubeWT__c,ID_ERP__c,ITENumber__c
                            FROM OpportunityLineItem LIMIT 1];
        Quote testQuote = new Quote(Name='Test', ExpirationDate = Date.today(), OpportunityId = oli.OpportunityId, Pricebook2Id = Test.getStandardPricebookId());
        
        insert testQuote;
        Quote testQuoteJson = [SELECT ID, ExpirationDate, QuoteNumber FROM Quote WHERE ID=:testQuote.id];
        QuoteLineItem qli = new QuoteLineItem(OpportunityLineItemId = oli.Id, QuoteId = testQuote.Id, PriceBookEntryId = oli.PriceBookEntryId,
                                              Quantity=oli.Quantity, UnitPrice=oli.UnitPrice, InquiryQuantity__c=oli.InquiryQuantity__c, InquiryUnitPrice__c=oli.InquiryUnitPrice__c, Product2Id = oli.Product2Id);
        insert qli;
        
        QuoteLineItem qliJson = [SELECT id, QuoteId, PriceBookEntryId,Quantity ,UnitPrice ,OpportunityLineItemId,
                                 InquiryQuantity__c ,InquiryUnitPrice__c,Product2Id,LastModifiedDate,InquiryUnit__c FROM QuoteLineItem WHERE ID=:qli.id ];
        
        List<QuoteLineItem> qItems = new List<QuoteLineItem>();
        List<OpportunityLineItem> oItems = new List<OpportunityLineItem>();
        qItems.add(qliJson);
        oItems.add(oli);
    	String expectedStr = generateJSON(testQuoteJson, qItems, oItems);
        Test.setMock(WebServiceMock.class, new ERP_WebServiceMock((String) testQuote.Id, '123456', '22222','jsonError'));              
    	
        String errorMsg;
         
        	try {
               t.start();  
 			QuoteJSONGenerator.createJsonData(new List<String>{testQuote.id});
                t.stop();
        	} catch(AuraHandledException e){
             System.Debug('Hi inside Catch block');   
			//system.assert(e.getMessage().contains('call invalid'));
            System.debug(e.getMessage());
            System.debug(e.getTypeName());  
                
			}
		
        
        //System.assertEquals(1, Limits.getEmailInvocations(),'email was send');
	               
    }
      
    /*
    @isTest
    static void testCreateQuoteManyItems(){
       	
        OpportunityLineItem oli = [SELECT Id, OpportunityId, PriceBookEntryId, Product2Id, TubeEnds__c, LengthSize__c, InquiryUnit__c, TubeOD__c, Name__c, 
                            ProductSpecLevel__c, ProductStandard__c, InquiryQuantity__c, InquiryUnitPrice__c, Quantity, UnitPrice, 
                            ShippingPoint__c, Shop__c, SteelGrade__c, Weight_kpm__c, Weight_ppf__c, TubeWT__c,ID_ERP__c,ITENumber__c
                            FROM OpportunityLineItem LIMIT 1];
        Quote testQuote = new Quote(Name='Test', OpportunityId = oli.OpportunityId, Pricebook2Id = Test.getStandardPricebookId());
        insert testQuote;
        
        Quote testQuoteJson = [SELECT ID, QuoteNumber FROM Quote WHERE ID=:testQuote.id];
        system.debug(testQuote);
        
        QuoteLineItem qli = new QuoteLineItem(OpportunityLineItemId = oli.Id, QuoteId = testQuote.Id, PriceBookEntryId = oli.PriceBookEntryId,
                                              Quantity=oli.Quantity, UnitPrice=oli.UnitPrice, InquiryQuantity__c=oli.InquiryQuantity__c, InquiryUnitPrice__c=oli.InquiryUnitPrice__c, Product2Id = oli.Product2Id);
        insert qli;
        
        QuoteLineItem qliJson = [SELECT id, QuoteId, PriceBookEntryId,Quantity ,UnitPrice ,
                                 InquiryQuantity__c ,InquiryUnitPrice__c,Product2Id,LastModifiedDate,InquiryUnit__c FROM QuoteLineItem WHERE ID=:qli.id ];
        
        List<QuoteLineItem> qItems = new List<QuoteLineItem>();
        List<OpportunityLineItem> oItems = new List<OpportunityLineItem>();
        qItems.add(qliJson);
        oItems.add(oli);
        
        Test.setMock(WebServiceMock.class, new ERP_WebServiceMock((String) testQuote.Id, '123456', 'today'));
        
        String testResp;      
    	t.start();
 		//	QuoteJSONGenerator.createJsonData(new List<String>{testQuote.id});  
        //	QuoteJSONGenerator.callout(testResp);        	        	       	
       		//System.assertEquals(1, Limits.getEmailInvocations(),'msg error');        	
				testResp = QuoteJSONGenerator.generateAndSendJSON(testQuoteJson, qItems, oItems); 			
		t.stop();
		        	
        	String expectedStr = generateJSON(testQuoteJson, qItems, oItems);
            System.debug(testResp);
        	System.assertEquals(expectedStr, testResp,'error');
    }
  */
    
 
    @isTest
    static void testUpdateQuoteItem(){
       	
        OpportunityLineItem oli = [SELECT Id, OpportunityId, PriceBookEntryId, Product2Id, TubeEnds__c, LengthSize__c, InquiryUnit__c, TubeOD__c, Name__c, 
                            ProductSpecLevel__c, ProductStandard__c, InquiryQuantity__c, InquiryUnitPrice__c, Quantity, UnitPrice, 
                            ShippingPoint__c, Shop__c, SteelGrade__c, Weight_kpm__c, Weight_ppf__c, TubeWT__c,ID_ERP__c,ITENumber__c
                            FROM OpportunityLineItem LIMIT 1];
        Quote testQuote = new Quote(Name='Test', ExpirationDate = Date.today(), OpportunityId = oli.OpportunityId, Pricebook2Id = Test.getStandardPricebookId());
        
        insert testQuote;
        Quote testQuoteJson = [SELECT ID, ExpirationDate, QuoteNumber FROM Quote WHERE ID=:testQuote.id];
        QuoteLineItem qli = new QuoteLineItem(OpportunityLineItemId = oli.Id, QuoteId = testQuote.Id, PriceBookEntryId = oli.PriceBookEntryId,
                                              Quantity=oli.Quantity, UnitPrice=oli.UnitPrice, InquiryQuantity__c=oli.InquiryQuantity__c, InquiryUnitPrice__c=oli.InquiryUnitPrice__c, Product2Id = oli.Product2Id);
        insert qli;
        
       
        
        List<QuoteLineItem> qItems = new List<QuoteLineItem>();
        List<OpportunityLineItem> oItems = new List<OpportunityLineItem>();
        
        oItems.add(oli);
    	
        qli.Quantity = qli.Quantity + 1;
        
        Test.setMock(WebServiceMock.class, new ERP_WebServiceMock((String) testQuote.Id, '123456', 'today'));
           update qli;    
    	t.start();       
 			
        	 QuoteLineItem qliJson = [SELECT id, QuoteId, PriceBookEntryId,Quantity ,UnitPrice ,OpportunityLineItemId,
                                 InquiryQuantity__c ,InquiryUnitPrice__c,Product2Id,LastModifiedDate,InquiryUnit__c FROM QuoteLineItem WHERE ID=:qli.id ];
        	qItems.add(qliJson);
        	String expectedStr = generateJSON(testQuoteJson, qItems, oItems);
        	QuoteJSONGenerator.makeCallout(expectedStr);
        	System.assertEquals(0, Limits.getEmailInvocations(),'email was send');
		t.stop();
               
    }
    
     @isTest
    static void testUpdateQuoteItemError(){
       	
        OpportunityLineItem oli = [SELECT Id, OpportunityId, PriceBookEntryId, Product2Id, TubeEnds__c, LengthSize__c, InquiryUnit__c, TubeOD__c, Name__c, 
                            ProductSpecLevel__c, ProductStandard__c, InquiryQuantity__c, InquiryUnitPrice__c, Quantity, UnitPrice, 
                            ShippingPoint__c, Shop__c, SteelGrade__c, Weight_kpm__c, Weight_ppf__c, TubeWT__c,ID_ERP__c,ITENumber__c
                            FROM OpportunityLineItem LIMIT 1];
        Quote testQuote = new Quote(Name='Test',ExpirationDate = Date.today(), OpportunityId = oli.OpportunityId, Pricebook2Id = Test.getStandardPricebookId());
        
        insert testQuote;
        Quote testQuoteJson = [SELECT ID, ExpirationDate, QuoteNumber FROM Quote WHERE ID=:testQuote.id];
        QuoteLineItem qli = new QuoteLineItem(OpportunityLineItemId = oli.Id, QuoteId = testQuote.Id, PriceBookEntryId = oli.PriceBookEntryId,
                                              Quantity=oli.Quantity, UnitPrice=oli.UnitPrice, InquiryQuantity__c=oli.InquiryQuantity__c, InquiryUnitPrice__c=oli.InquiryUnitPrice__c, Product2Id = oli.Product2Id);
        insert qli;
        
       
        
        List<QuoteLineItem> qItems = new List<QuoteLineItem>();
        List<OpportunityLineItem> oItems = new List<OpportunityLineItem>();
        
        oItems.add(oli);
    	
        qli.Quantity = qli.Quantity + 1;
        
        Test.setMock(WebServiceMock.class, new ERP_WebServiceMock((String) testQuote.Id, '123456', 'today','falseSuccess'));
           update qli;    
    	t.start();         
 			
        	 QuoteLineItem qliJson = [SELECT id, QuoteId, PriceBookEntryId,Quantity ,UnitPrice ,OpportunityLineItemId,
                                 InquiryQuantity__c ,InquiryUnitPrice__c,Product2Id,LastModifiedDate,InquiryUnit__c FROM QuoteLineItem WHERE ID=:qli.id ];
        	qItems.add(qliJson);
        	String expectedStr = generateJSON(testQuoteJson, qItems, oItems);
        	QuoteJSONGenerator.makeCallout(expectedStr);
        	System.assertEquals(1, Limits.getEmailInvocations(),'email wasnt send');
		t.stop();
               
    }
  
    
    
    @testSetup 
	static void testSetup() {

		Account testAccount = t.newAccounts('Test Account')[0];
		insert testAccount;

		Opportunity testOpp = t.newOpportunities('Test', testAccount.Id, 'Qualification', Date.today())[0];
		insert testOpp;

		Id pricebookId = Test.getStandardPricebookId();
		Product2 testProd1 = t.newProducts('Test product', '0000')[0];
		testProd1.ID_ERP__c = 'pr1';
		insert testProd1;

		PricebookEntry testPriceBookEntry1 = new PricebookEntry(
			Pricebook2Id = pricebookId,
			Product2Id = testProd1.Id,
			UnitPrice = 1000.00,
			IsActive = true
		);
		insert testPriceBookEntry1;

		TubeOD__c od = new TubeOD__c(ID_ERP__c = 'od', OD_mm__c = 48.30, OD_inch__c = 1.9);
		insert od;

		TubeWT__c wt = new TubeWT__c(ID_ERP__c = 'wt', Name = 'TestWT', WT_mm__c = 5.08, WT_inch__c = 0.2);
		insert wt;
		
		TubeLengthSize__c size = new TubeLengthSize__c(ID_ERP__c = 'si', Name = 'testLS');
		size.MaxLength__c = 5800;
		size.MinLength__c = 5600;
		size.Type__c = 'R1';
		insert size;
    
		OpportunityLineItem testOppProd1 = t.newOpportunityProducts(testPriceBookEntry1.Id, testOpp.Id)[0];
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
		insert testOppProd1;
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
    
     public static String generateJSON(Quote curQuote, List<QuoteLineItem> quoLineItems,List<OpportunityLineItem> oppLineItems){
         JSONGenerator jsonToSend = JSON.createGenerator(true);
		jsonToSend.writeStartObject();
        jsonToSend.writeObjectField('QuoteId',curQuote.id);
        jsonToSend.writeObjectField('QuoteNumber',curQuote.QuoteNumber);
        jsonToSend.writeFieldName('QuoteLineItems');
        jsonToSend.writeStartArray();
        
        for(QuoteLineItem quoteItem: quoLineItems){
           jsonToSend.writeStartObject();
           jsonToSend.writeObjectField('ID_ERP__c',searchERP(quoteItem,oppLineItems));
           jsonToSend.writeObjectField('OpportunityLineItemITENumber__c',searchITE(quoteItem,oppLineItems)); 
           jsonToSend.writeObjectField('LastModifiedDate',quoteItem.LastModifiedDate);
           jsonToSend.writeObjectField('InquiryUnit__c',quoteItem.InquiryUnit__c);
           jsonToSend.writeObjectField('Quantity',quoteItem.Quantity); 
           jsonToSend.writeObjectField('InquiryQuantity__c',quoteItem.InquiryQuantity__c); 
           jsonToSend.writeObjectField('UnitPrice',quoteItem.UnitPrice); 
           jsonToSend.writeObjectField('InquiryUnitPrice__c',quoteItem.InquiryUnitPrice__c); 
             
			jsonToSend.writeEndObject();           
        }
        
        jsonToSend.writeEndArray();       
        jsonToSend.writeEndObject();
        
         JSONGenerator jsonWrapper = JSON.createGenerator(true);
		jsonWrapper.writeStartObject();
		jsonWrapper.writeStringField('JSON', jsonToSend.getAsString());
		jsonWrapper.writeEndObject();
        
        system.debug(jsonToSend.getAsString());
        system.debug(jsonToSend);
        return jsonToSend.getAsString();
    }
    
     public static String searchERP(QuoteLineItem qlt, List<OpportunityLineItem> oppItems){
        String erp = '';
        for(OpportunityLineItem o: oppItems){
            if(qlt.Product2Id == o.Product2Id){
                erp = o.ID_ERP__c;
            }
        }
        
        if(erp==null){
            erp = 'default';
        }
        
        return erp;
    }
    
    public static String searchITE(QuoteLineItem qlt, List<OpportunityLineItem> oppItems){
        String ite = '';
        for(OpportunityLineItem o: oppItems){
            if(qlt.Product2Id == o.Product2Id){
                ite = o.ITENumber__c;
            }
        }       
        if(ite==null){
            ite = 'default';
        }
        
        return ite;
    }
    
    
           
    static { BaseTest.t = new QuoteJSONGeneratorTest(); }
    static BaseTest t { get { return BaseTest.t; } }
}