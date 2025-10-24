@isTest
private class ERPMessageHandlerOrderProbabilityTest extends BaseTest{
    // Method to create mock ERPToSfMessage_OrderProbabilityQuery data
    private static ERPMessageParser.ERPToSfMessage_OrderProbabilityQuery createMockERPMessage() {
        ERPMessageParser.ERPToSfMessage_OrderProbabilityQuery mockMessage = new ERPMessageParser.ERPToSfMessage_OrderProbabilityQuery();

        // Mock Metadata
        mockMessage.Metadata = new ERPMessageParser.MessageMetadata();
        mockMessage.Metadata.MsgType = 'TestType';

        // Mock OrderProbabilityMessageData
        ERPMessageParser.OrderProbabilityMessageData orderData = new ERPMessageParser.OrderProbabilityMessageData();
        orderData.ID_SF = '001XXXXXXXXXXXXXXX'; // Replace with a valid Opportunity ID from your test data
        orderData.ID_ERP = 123;

        // Mock Items
        ERPMessageParser.Items item = new ERPMessageParser.Items();
        item.ITE_NUMBER = 'Item1';
        item.PROBABILITY = 0.8;
        item.KDO = '2023-01-01';
        item.PROD_START_DATE = '2023-06-01';
        item.EXPIRATION_DATE = '2023-12-31';

        orderData.Items = new List<ERPMessageParser.Items>{item};
        mockMessage.data = new List<ERPMessageParser.OrderProbabilityMessageData>{orderData};

        return mockMessage;
    }

    @isTest static void testProcessMessage() {
        createTestData();
        ERPMessageParser.ERPToSfMessage_OrderProbabilityQuery mockParsedMessage = createMockERPMessage();

        Test.startTest();
        ERPMessageHandlerOrderProbability.MessageProcessingResult result = 
            ERPMessageHandlerOrderProbability.processMessage(mockParsedMessage, 'test string');
        Test.stopTest();

        // Assertions
        System.assertNotEquals(null, result, 'Result should not be null');
        // Add more assertions here based on expected outcomes
    }

    @isTest static void testMapItemNumbersToOpportunityIds() {
        createTestData();
        ERPMessageParser.ERPToSfMessage_OrderProbabilityQuery mockParsedMessage = createMockERPMessage();

        Test.startTest();
        Map<String, String> itemNumToOppIdMap = 
            ERPMessageHandlerOrderProbability.mapItemNumbersToOpportunityIds(mockParsedMessage);
        Test.stopTest();

        // Assertions
        System.assertNotEquals(null, itemNumToOppIdMap, 'itemNumToOppIdMap should not be null');
        // Additional assertions based on expected results
    }

    @isTest static void testQueryOpportunityLineItems() {
        createTestData();
        Set<String> allItemNumbers = new Set<String>{'Item1', 'Item2'}; // Add item numbers as per your test data

        Test.startTest();
        Map<String, OpportunityLineItem> itemNumberToOpportunityLineItemMap = 
            ERPMessageHandlerOrderProbability.queryOpportunityLineItems(allItemNumbers);
        Test.stopTest();

        // Assertions
        System.assertNotEquals(null, itemNumberToOpportunityLineItemMap, 'itemNumberToOpportunityLineItemMap should not be null');
        // Additional assertions based on expected results
    }

    @isTest static void testDeleteRelatedOpportunityProductApprovals() {
        createTestData();
        Set<Id> oppLineItemIds = new Set<Id>{/* Add Opportunity Line Item Ids from your test data */};

        Test.startTest();
        // Call the method - since it doesn't return a value, we're testing to ensure no exceptions occur
        ERPMessageHandlerOrderProbability.deleteRelatedOpportunityProductApprovals(oppLineItemIds);
        Test.stopTest();

        // Assertions - mainly to check if the related records are deleted, if applicable
        // Example:
        // List<OpportunityProductApproval__c> approvals = [SELECT Id FROM OpportunityProductApproval__c WHERE OpportunityProduct__c IN :oppLineItemIds];
        // System.assertEquals(0, approvals.size(), 'Approvals should be deleted');
    }
    @isTest static void testSubmitForApproval() {
        // Create test opportunity and related approval records
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = System.today().addDays(10)
        );
        insert testOpportunity;

        OpportunityProductApproval__c approvalRecord = new OpportunityProductApproval__c(
            Opportunity__c = testOpportunity.Id,
            ExpirationDate__c = Date.today(), KDO__c = Date.today(), ProductionStartDate__c = Date.today()
        );
        insert approvalRecord;

        List<OpportunityProductApproval__c> approvalRecords = new List<OpportunityProductApproval__c>{approvalRecord};

        Test.startTest();
        ERPMessageHandlerOrderProbability.submitForApproval(approvalRecords);
        Test.stopTest();
    }

    private static List<Opportunity> createTestData() {
        List<Opportunity> opportunities = new List<Opportunity>{ /* ... */ };
        insert opportunities;
        return opportunities;
    }
    @isTest static void testGenerateResponseBody() {
        Map<Integer, String> statusCodesMap = new Map<Integer, String>{
            200 => 'OK',
            400 => 'Bad Request'
        };
        ERPMessageHandlerOrderProbability.MessageProcessingResult mpRes = new ERPMessageHandlerOrderProbability.MessageProcessingResult();
        mpRes.MessageType = 'OrderCreated';
        mpRes.MissingItemNumbers = new Set<String>(); // Assume no missing item numbers

        Blob responseBody = ERPMessageHandlerOrderProbability.generateResponseBody(statusCodesMap, 200, null, mpRes);
        String responseString = responseBody.toString();
        System.assert(responseString.contains('OrderCreated'), 'Response should contain the processed message type.');

        Blob errorResponseBody = ERPMessageHandlerOrderProbability.generateResponseBody(statusCodesMap, 400, 'An error occurred', mpRes);
        String errorResponseString = errorResponseBody.toString();
        System.assert(errorResponseString.contains('An error occurred'), 'Response should contain the error message.');

        // Test the response body with missing item numbers
        mpRes.MissingItemNumbers.add('Item123');
        Blob missingItemsResponseBody = ERPMessageHandlerOrderProbability.generateResponseBody(statusCodesMap, 200, null, mpRes);
        String missingItemsResponseString = missingItemsResponseBody.toString();
        System.assert(missingItemsResponseString.contains('Item123'), 'Response should contain the missing item numbers.');
    }
 
    
    static { BaseTest.t = new ERPMessageHandlerOrderProbabilityTest(); }
    static BaseTest t { get { return BaseTest.t; } } 
}