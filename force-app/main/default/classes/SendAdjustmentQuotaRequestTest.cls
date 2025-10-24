@isTest
public class SendAdjustmentQuotaRequestTest extends BaseTest{

    @testSetup
    static void setupTestData() {
        QuoteRequestHeader__c quotaHeader = new QuoteRequestHeader__c();
        insert quotaHeader;

        Region__c regoin = new Region__c(Name = 'Region', ID_ERP__c = 1111); 
        insert regoin;

        Family__c family = new Family__c(Name = 'Family', ID_ERP__c = 2222); 
        insert family;

        RouteQuotesH__c hierarchy = new RouteQuotesH__c(Name = 'Shop Name');
        insert hierarchy;

        QuoteStructureDetail__c quotaStructDetail = new QuoteStructureDetail__c(
            Family__c = family.Id,
            MarketSegment__c = '00004',
            Percent__c = 10.0,
            Quote_t__c = 100.0,
            AddQty_t__c = 0,
            Region__c = regoin.Id,
            ID_ERP__c = '12345',
            RoutesQuotesH__c = hierarchy.Id
        );
        insert quotaStructDetail;

        QuoteRequestDetail__c quotaDetail = new QuoteRequestDetail__c(
            QuoteRequestHeader__c = quotaHeader.Id,
            MarketSegment__c = '00004',
            DateBegin__c = Date.today(),
            Percent__c = 10.0,
            AddQty_t__c = 100.0,
            Add_Qty_pcs__c = 20,
            Region__c = regoin.Id,
            Family__c = family.Id,
            RoutesQuotesH__c = hierarchy.Id,
            QuoteStructureDetail__c = quotaStructDetail.Id
        );
        insert quotaDetail;

    }

    @isTest
	public static void test_sendJsonData_sendEmail() {
		Id headerId = [SELECT Id FROM QuoteRequestHeader__c].Id;

		Test.setMock(WebServiceMock.class, new ERP_WebServiceMock((String) headerId, '123456', '22222', ''));

		t.start();
		SendAdjustmentQuotaRequest.SendQuotaRequest(new List<Id>{headerId});
		t.stop();

        List<QuoteStructureDetail__c> archivedQuotaList = [SELECT Id FROM QuoteStructureDetail__c WHERE Archived__c = true];
        List<QuoteStructureDetail__c> activeQuotaList = [SELECT Id FROM QuoteStructureDetail__c WHERE Archived__c = false];

        Assert.areEqual(1, archivedQuotaList.size(), 'One record should be archived');
        Assert.areEqual(1, activeQuotaList.size(), 'One record should be active');
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
		private final String ACCEPTED_RESPONCE = '{"Success":true,"Comment":""}';
        private final String DENIED_RESPONCE = '{"Success":false,"Comment":"* ERROR *nЗначение не может быть неопределенным.rnИмя параметра: valuen* INBOUND DATA *n"}';
        private final String WRONGJSON_RESPONCE = '"{"Success":false,"Comment":"* ERROR *nЗначение не может быть неопределенным.rnИмя параметра: valuen* INBOUND DATA *n"}"';
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

    static { BaseTest.t = new SendAdjustmentQuotaRequestTest(); }
	static BaseTest t { get { return BaseTest.t; } }
}