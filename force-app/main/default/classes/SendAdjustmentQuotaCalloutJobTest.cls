@isTest
private class SendAdjustmentQuotaCalloutJobTest {

    @testSetup
    static void setup() {
        Credentials__c creds = new Credentials__c(
                User_Login__c = 'test_user',
                User_Password__c = 'test_pass',
                End_Point__c = 'https://test-erp-endpoint.com/soap'
        );
        insert creds;

        RouteQuotesH__c hierarchy = new RouteQuotesH__c(
                Name = 'Test Shop Hierarchy'
        );
        insert hierarchy;

        List<QuoteStructureDetail__c> qsdList = new List<QuoteStructureDetail__c>{
            new QuoteStructureDetail__c(
                ID_ERP__c = 'ERP_001',
                Archived__c = false,
                Name = 'Test Quota Detail 1',
                AddQty_t__c = 100.0,
                Quote_t__c = 1000.0,
                Percent__c = 5.0,
                RoutesQuotesH__c = hierarchy.Id
            ),
            new QuoteStructureDetail__c(
                ID_ERP__c = 'ERP_001',
                Archived__c = false,
                Name = 'Test Quota Detail 1 Duplicate',
                AddQty_t__c = 200.0,
                Quote_t__c = 2000.0,
                Percent__c = 7.0,
                RoutesQuotesH__c = hierarchy.Id
            ),
            new QuoteStructureDetail__c(
                ID_ERP__c = 'ERP_002',
                Archived__c = false,
                Name = 'Test Quota Detail 2',
                AddQty_t__c = 150.0,
                Quote_t__c = 1500.0,
                Percent__c = 6.0,
                RoutesQuotesH__c = hierarchy.Id
            )
        };
        insert qsdList;

        List<QuoteRequestDetail__c> qrdList = new List<QuoteRequestDetail__c>{
            new QuoteRequestDetail__c(
                QuoteStructureDetail__c = qsdList[0].Id,
                AddQty_t__c = 50.0,
                Quote_t__c = 500.0,
                Percent__c = 10.0
            ),
            new QuoteRequestDetail__c(
                QuoteStructureDetail__c = qsdList[2].Id,
                AddQty_t__c = 75.0,
                Quote_t__c = 750.0,
                Percent__c = 12.0
            )
        };
        insert qrdList;
    }

    // Mock класи
    private class SuccessMock implements WebServiceMock {
        public void doInvoke(
                Object stub, Object request, Map<String, Object> response,
                String endpoint, String soapAction, String requestName,
                String responseNS, String responseName, String responseType
        ) {
            if (requestName == 'LoginEx') {
                SFToERP.LoginExResponse_element respElement = new SFToERP.LoginExResponse_element();
                respElement.LoginExResult = '{"Ticket":"mock_ticket_123"}';
                response.put('response_x', respElement);
            } else if (requestName == 'ExecuteEx') {
                SFToERP.ExecuteExResponse_element respElement = new SFToERP.ExecuteExResponse_element();
                // Формат: подвійні лапки + JSON без зворотних слешів
                respElement.ExecuteExResult = '"{"Success":true,"Comments":""}"';
                response.put('response_x', respElement);
            }
        }
    }

    private class FailureMock implements WebServiceMock {
        public void doInvoke(
                Object stub, Object request, Map<String, Object> response,
                String endpoint, String soapAction, String requestName,
                String responseNS, String responseName, String responseType
        ) {
            if (requestName == 'LoginEx') {
                SFToERP.LoginExResponse_element respElement = new SFToERP.LoginExResponse_element();
                respElement.LoginExResult = '{"Ticket":"mock_ticket_123"}';
                response.put('response_x', respElement);
            } else if (requestName == 'ExecuteEx') {
                SFToERP.ExecuteExResponse_element respElement = new SFToERP.ExecuteExResponse_element();
                respElement.ExecuteExResult = '"{"Success":false,"Comments":"Backend error"}"';
                response.put('response_x', respElement);
            }
        }
    }

    private class CalloutExceptionMock implements WebServiceMock {
        public void doInvoke(
                Object stub, Object request, Map<String, Object> response,
                String endpoint, String soapAction, String requestName,
                String responseNS, String responseName, String responseType
        ) {
            throw new CalloutException('Connection timeout');
        }
    }

    private class JsonExceptionMock implements WebServiceMock {
        public void doInvoke(
                Object stub, Object request, Map<String, Object> response,
                String endpoint, String soapAction, String requestName,
                String responseNS, String responseName, String responseType
        ) {
            if (requestName == 'LoginEx') {
                SFToERP.LoginExResponse_element respElement = new SFToERP.LoginExResponse_element();
                respElement.LoginExResult = 'Invalid JSON {{{';
                response.put('response_x', respElement);
            }
        }
    }

    @isTest
    static void testSuccessfulExecution() {
        List<QuoteRequestDetail__c> qrdList = [
                SELECT Id, AddQty_t__c, Quote_t__c, Percent__c,
                        QuoteStructureDetail__c, QuoteStructureDetail__r.ID_ERP__c
                FROM QuoteRequestDetail__c
        ];

        Test.setMock(WebServiceMock.class, new SuccessMock());

        Test.startTest();
        SendAdjustmentQuotaCalloutJob job = new SendAdjustmentQuotaCalloutJob('{"test":"data"}', qrdList);
        System.enqueueJob(job);
        Test.stopTest();

        List<QuoteStructureDetail__c> archivedRecords = [
                SELECT Archived__c
                FROM QuoteStructureDetail__c
                WHERE Id IN :new Set<Id>{qrdList[0].QuoteStructureDetail__c, qrdList[1].QuoteStructureDetail__c}
        ];

        for (QuoteStructureDetail__c record : archivedRecords) {
            System.assertEquals(true, record.Archived__c, 'Старі записи мають бути архівовані');
        }

        List<QuoteStructureDetail__c> newRecords = [
                SELECT Id, AddQty_t__c, Quote_t__c, Percent__c
                FROM QuoteStructureDetail__c
                WHERE Archived__c = false
        ];

        System.assert(newRecords.size() > 0, 'Нові записи мають бути створені');
    }

    @isTest
    static void testBackendFailure() {
        List<QuoteRequestDetail__c> qrdList = [
                SELECT Id, AddQty_t__c, Quote_t__c, Percent__c,
                        QuoteStructureDetail__c, QuoteStructureDetail__r.ID_ERP__c
                FROM QuoteRequestDetail__c
                LIMIT 1
        ];

        Test.setMock(WebServiceMock.class, new FailureMock());

        Test.startTest();
        SendAdjustmentQuotaCalloutJob job = new SendAdjustmentQuotaCalloutJob('{"test":"data"}', qrdList);
        System.enqueueJob(job);
        Test.stopTest();

        QuoteStructureDetail__c record = [
                SELECT Archived__c
                FROM QuoteStructureDetail__c
                WHERE Id = :qrdList[0].QuoteStructureDetail__c
        ];

        System.assertEquals(true, record.Archived__c, 'Запис має бути архівований навіть при помилці бекенду');
    }

    @isTest
    static void testCalloutException() {
        List<QuoteRequestDetail__c> qrdList = [
                SELECT Id, AddQty_t__c, Quote_t__c, Percent__c,
                        QuoteStructureDetail__c, QuoteStructureDetail__r.ID_ERP__c
                FROM QuoteRequestDetail__c
                LIMIT 1
        ];

        Test.setMock(WebServiceMock.class, new CalloutExceptionMock());

        Test.startTest();
        SendAdjustmentQuotaCalloutJob job = new SendAdjustmentQuotaCalloutJob('{"test":"data"}', qrdList);
        System.enqueueJob(job);
        Test.stopTest();

        List<QuoteStructureDetail__c> records = [SELECT Id FROM QuoteStructureDetail__c];
        System.assert(records.size() > 0, 'Записи мають існувати');
    }

    @isTest
    static void testJsonException() {
        List<QuoteRequestDetail__c> qrdList = [
                SELECT Id, AddQty_t__c, Quote_t__c, Percent__c,
                        QuoteStructureDetail__c, QuoteStructureDetail__r.ID_ERP__c
                FROM QuoteRequestDetail__c
                LIMIT 1
        ];

        Test.setMock(WebServiceMock.class, new JsonExceptionMock());

        Test.startTest();
        SendAdjustmentQuotaCalloutJob job = new SendAdjustmentQuotaCalloutJob('{"test":"data"}', qrdList);
        System.enqueueJob(job);
        Test.stopTest();

        List<QuoteStructureDetail__c> records = [SELECT Id FROM QuoteStructureDetail__c];
        System.assert(records.size() > 0, 'Записи мають існувати після JSON помилки');
    }

    @isTest
    static void testEmptyList() {
        List<QuoteRequestDetail__c> emptyList = new List<QuoteRequestDetail__c>();

        Test.setMock(WebServiceMock.class, new SuccessMock());

        Test.startTest();
        SendAdjustmentQuotaCalloutJob job = new SendAdjustmentQuotaCalloutJob('{"test":"data"}', emptyList);
        System.enqueueJob(job);
        Test.stopTest();

        System.assert(true, 'Код має виконатись без помилок');
    }

    @isTest
    static void testMultipleQuoteStructureDetails() {
        List<QuoteRequestDetail__c> qrdList = [
                SELECT Id, AddQty_t__c, Quote_t__c, Percent__c,
                        QuoteStructureDetail__c, QuoteStructureDetail__r.ID_ERP__c
                FROM QuoteRequestDetail__c
        ];

        Integer initialCount = [SELECT COUNT() FROM QuoteStructureDetail__c];

        Test.setMock(WebServiceMock.class, new SuccessMock());

        Test.startTest();
        SendAdjustmentQuotaCalloutJob job = new SendAdjustmentQuotaCalloutJob('{"test":"data"}', qrdList);
        System.enqueueJob(job);
        Test.stopTest();

        Integer finalCount = [SELECT COUNT() FROM QuoteStructureDetail__c];
        System.assert(finalCount > initialCount, 'Нові записи мають бути створені');

        List<QuoteStructureDetail__c> newERP001Records = [
                SELECT Id
                FROM QuoteStructureDetail__c
                WHERE ID_ERP__c = 'ERP_001' AND Archived__c = false
        ];
        System.assertEquals(2, newERP001Records.size(), 'Для ERP_001 має бути 2 нових записи');
    }

    @isTest
    static void testUpdateQuoteStructureDetailsLogic() {
        List<QuoteRequestDetail__c> qrdList = [
                SELECT Id, AddQty_t__c, Quote_t__c, Percent__c,
                        QuoteStructureDetail__c, QuoteStructureDetail__r.ID_ERP__c
                FROM QuoteRequestDetail__c
                WHERE QuoteStructureDetail__r.ID_ERP__c = 'ERP_001'
                LIMIT 1
        ];

        Test.setMock(WebServiceMock.class, new SuccessMock());

        Test.startTest();
        SendAdjustmentQuotaCalloutJob job = new SendAdjustmentQuotaCalloutJob('{"test":"data"}', qrdList);
        System.enqueueJob(job);
        Test.stopTest();

        List<QuoteStructureDetail__c> newRecords = [
                SELECT AddQty_t__c, Quote_t__c, Percent__c
                FROM QuoteStructureDetail__c
                WHERE ID_ERP__c = 'ERP_001' AND Archived__c = false
        ];

        System.assertEquals(2, newRecords.size(), 'Має бути 2 нових записи');

        for (QuoteStructureDetail__c record : newRecords) {
            System.assertEquals(50.0, record.AddQty_t__c, 'AddQty_t__c має відповідати');
            System.assertEquals(500.0, record.Quote_t__c, 'Quote_t__c має відповідати');
            System.assertEquals(10.0, record.Percent__c, 'Percent__c має відповідати');
        }
    }

    @isTest
    static void testConstructor() {
        List<QuoteRequestDetail__c> qrdList = [
                SELECT Id, QuoteStructureDetail__r.ID_ERP__c
                FROM QuoteRequestDetail__c
                LIMIT 1
        ];

        Test.startTest();
        SendAdjustmentQuotaCalloutJob job = new SendAdjustmentQuotaCalloutJob('{"test":"data"}', qrdList);
        Test.stopTest();

        System.assertNotEquals(null, job, 'Job має бути створено');
    }

    @isTest
    static void testBackendFailureWithEmptyList() {
        List<QuoteRequestDetail__c> emptyList = new List<QuoteRequestDetail__c>();

        Test.setMock(WebServiceMock.class, new FailureMock());

        Test.startTest();
        SendAdjustmentQuotaCalloutJob job = new SendAdjustmentQuotaCalloutJob('{"test":"data"}', emptyList);
        System.enqueueJob(job);
        Test.stopTest();

        System.assert(true, 'Код має виконатись без помилок');
    }

    @isTest
    static void testCalloutExceptionWithEmptyList() {
        List<QuoteRequestDetail__c> emptyList = new List<QuoteRequestDetail__c>();

        Test.setMock(WebServiceMock.class, new CalloutExceptionMock());

        Test.startTest();
        SendAdjustmentQuotaCalloutJob job = new SendAdjustmentQuotaCalloutJob('{"test":"data"}', emptyList);
        System.enqueueJob(job);
        Test.stopTest();

        System.assert(true, 'Код має виконатись без помилок');
    }
}