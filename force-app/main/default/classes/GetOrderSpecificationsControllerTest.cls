@IsTest
public class GetOrderSpecificationsControllerTest {

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
    
        Order testOrder = new Order();
        testOrder.AccountId = testAccount.id;
		testOrder.EffectiveDate = date.TODAY();
		testOrder.Status = 'Draft';        
    	testOrder.ID_ERP__c = '12312331';
        testOrder.ITENumber__c = '34324234';
   		insert testOrder;
    }

    @isTest
    public static void testRequestForOrderSpecList() {
        Order order = [SELECT id FROM ORDER LIMIT 1];
        Test.setMock(WebServiceMock.class, new ERP_WebServiceMock((String) order.Id, '123456', 'today', ''));
        
        t.start();  
        GetOrderSpecificationsController.requestForOrderSpecList(order.id);
        t.stop();   
    }

    @isTest
    public static void testRequestForOrderSpec() {
        Order order = [SELECT id FROM ORDER LIMIT 1];
        Test.setMock(WebServiceMock.class, new ERP_WebServiceMock((String) order.Id, '123456', 'today', ''));
        
        t.start();  
        GetOrderSpecificationsController.requestForOrderSpec(order.id, '123456');
        t.stop();   
    }
    
    private class ERP_WebServiceMock implements WebServiceMock {

		String oppId;
		String ERP_ID;
		String SyncDateTime;
		String isError;

		public ERP_WebServiceMock(String oppId, String ERP_Id, String SyncDateTime, String isError) {
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
                      
    static { BaseTest.t = new orderDeliveryControllerTest(); }
    static BaseTest t { get { return BaseTest.t; } }
}