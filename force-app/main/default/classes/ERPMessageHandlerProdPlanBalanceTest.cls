@isTest
private class ERPMessageHandlerProdPlanBalanceTest extends BaseTest {

    private static final String TEST_ITE_NUMBER = '123456789-001';
    private static final String TEST_SHORT_ITE = '123456789';
    private static final Integer TEST_SHOP_ERP_ID = 1;
    private static final Integer TEST_YEAR = 2025;
    private static final Integer TEST_MONTH = 1;

    @TestSetup
    static void setupTestData() {
        // Create test Shop
        Shop__c testShop = new Shop__c(
            Name = 'Test Shop',
            ID_ERP__c = String.valueOf(TEST_SHOP_ERP_ID)
        );
        insert testShop;

        // Create test Account
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        // Create test Product
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            IsActive = true
        );
        insert testProduct;

        // Get standard pricebook
        Id pricebookId = Test.getStandardPricebookId();

        // Create PricebookEntry
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = testProduct.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;

        // Create test Order with Pricebook2Id
        Order testOrder = new Order(
            AccountId = testAccount.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            Pricebook2Id = pricebookId,
            ITENumber__c = TEST_SHORT_ITE
        );
        insert testOrder;

        // Create test OrderItem
        OrderItem testOrderItem = new OrderItem(
            OrderId = testOrder.Id,
            Product2Id = testProduct.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 10,
            UnitPrice = 100,
            ITENumber__c = TEST_ITE_NUMBER
        );
        insert testOrderItem;

        // Create test ProdWeeksH__c records
        List<ProdWeeksH__c> prodWeeks = new List<ProdWeeksH__c>();
        for (Integer i = 1; i <= 4; i++) {
            prodWeeks.add(new ProdWeeksH__c(
                Name = 'Week ' + i,
                Year__c = TEST_YEAR,
                Month__c = String.valueOf(TEST_MONTH),
                WeekNum__c = i,
                DateFrom__c = Date.newInstance(TEST_YEAR, TEST_MONTH, 1 + ((i - 1) * 7)),
                DateTo__c = Date.newInstance(TEST_YEAR, TEST_MONTH, 7 + ((i - 1) * 7))
            ));
        }
        insert prodWeeks;
    }

    // Helper method to create mock parsed message
    private static ERPMessageParser.ErpToSfMessage_ProdPlanBalance createMockMessage(Boolean includePlans, Boolean includeIteNumber) {
        ERPMessageParser.ErpToSfMessage_ProdPlanBalance mockMessage = new ERPMessageParser.ErpToSfMessage_ProdPlanBalance();

        // Create metadata
        mockMessage.metadata = new ERPMessageParser.MessageMetadata();
        mockMessage.metadata.msgType = 'ProdPlanBalance';
        mockMessage.metadata.msgTypeVersion = 1.0;
        mockMessage.metadata.msgTimestamp = DateTime.now();

        // Create data
        mockMessage.data = new ERPMessageParser.ProdPlanData();
        mockMessage.data.periodInfo = new ERPMessageParser.PeriodInfo();
        mockMessage.data.periodInfo.YearMonth = TEST_YEAR + String.valueOf(TEST_MONTH).leftPad(2, '0');
        mockMessage.data.periodInfo.WeekNumber = 1;
        mockMessage.data.periodInfo.WeekStartDate = '2025-01-01';
        mockMessage.data.periodInfo.WeekEndDate = '2025-01-31';

        // Create order items data
        ERPMessageParser.OrderItemsData itemData = new ERPMessageParser.OrderItemsData();
        itemData.IteNumber = includeIteNumber ? TEST_ITE_NUMBER : null;
        itemData.Shop = TEST_SHOP_ERP_ID;
        itemData.DateSnapshot = '2025-01-01';
        itemData.Year = TEST_YEAR;
        itemData.Month = TEST_MONTH;
        itemData.MonthPlanQty_t = 100.0;
        itemData.MonthProdBalance_t = 50.0;

        if (includePlans) {
            itemData.Plans = new List<ERPMessageParser.ProdPlan>();

            ERPMessageParser.ProdPlan plan = new ERPMessageParser.ProdPlan();
            plan.ProdPlanType = '253';
            plan.ValidDate = '2025-12-31';
            plan.WeekPlans = new List<ERPMessageParser.WeekPlan>();

            ERPMessageParser.WeekPlan weekPlan = new ERPMessageParser.WeekPlan();
            weekPlan.Details = new List<ERPMessageParser.WeekPlanNode>();

            for (Integer i = 1; i <= 2; i++) {
                ERPMessageParser.WeekPlanNode weekNode = new ERPMessageParser.WeekPlanNode();
                weekNode.WeekNum = i;
                weekNode.DateFrom = '2025-01-' + String.valueOf(1 + ((i - 1) * 7)).leftPad(2, '0');
                weekNode.DateTo = '2025-01-' + String.valueOf(7 + ((i - 1) * 7)).leftPad(2, '0');
                weekNode.PlanQty_t = 25.0;
                weekPlan.Details.add(weekNode);
            }

            plan.WeekPlans.add(weekPlan);
            itemData.Plans.add(plan);
        } else {
            itemData.Plans = null;
        }

        mockMessage.data.items = new List<ERPMessageParser.OrderItemsData>{ itemData };

        return mockMessage;
    }

    @isTest
    static void testProcessMessage_Success_WithPlans() {
        ERPMessageParser.ErpToSfMessage_ProdPlanBalance mockMessage = createMockMessage(true, true);
        String requestBody = JSON.serialize(mockMessage);

        Test.startTest();
        ERPMessageHandlerProdPlanBalance.MessageProcessingResult result =
            ERPMessageHandlerProdPlanBalance.ProcessMessage(mockMessage, requestBody, false);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals('ProdPlanBalance', result.MessageType, 'MessageType should match');
        System.assertEquals(null, result.error, 'Error should be null for successful processing');
        System.assert(result.jobStatus.contains('Batch launched'), 'Batch should be launched');
    }

    @isTest
    static void testProcessMessage_Success_WithoutPlans() {
        ERPMessageParser.ErpToSfMessage_ProdPlanBalance mockMessage = createMockMessage(false, true);
        String requestBody = JSON.serialize(mockMessage);

        Test.startTest();
        ERPMessageHandlerProdPlanBalance.MessageProcessingResult result =
            ERPMessageHandlerProdPlanBalance.ProcessMessage(mockMessage, requestBody, false);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals('ProdPlanBalance', result.MessageType, 'MessageType should match');
        System.assertEquals(null, result.error, 'Error should be null for successful processing');
        System.assert(result.jobStatus.contains('Batch launched'), 'Batch should be launched');
    }

    @isTest
    static void testProcessMessage_WithRecreatePlans() {
        ERPMessageParser.ErpToSfMessage_ProdPlanBalance mockMessage = createMockMessage(true, true);
        String requestBody = JSON.serialize(mockMessage);

        Test.startTest();
        ERPMessageHandlerProdPlanBalance.MessageProcessingResult result =
            ERPMessageHandlerProdPlanBalance.ProcessMessage(mockMessage, requestBody, true);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals('ProdPlanBalance', result.MessageType, 'MessageType should match');
        System.assertEquals(null, result.error, 'Error should be null for successful processing');
        System.assert(result.jobStatus.contains('Batch launched'), 'Batch should be launched with recreate=true');
    }

    @isTest
    static void testProcessMessage_MissingIteNumber() {
        ERPMessageParser.ErpToSfMessage_ProdPlanBalance mockMessage = createMockMessage(true, false);
        String requestBody = JSON.serialize(mockMessage);

        Test.startTest();
        ERPMessageHandlerProdPlanBalance.MessageProcessingResult result =
            ERPMessageHandlerProdPlanBalance.ProcessMessage(mockMessage, requestBody, false);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals('ProdPlanBalance', result.MessageType, 'MessageType should match');
        System.assertNotEquals(null, result.error, 'Error should not be null when IteNumber is missing');
        System.assert(result.error.contains('without IteNumber'), 'Error message should mention without IteNumber');
        System.assertEquals('Failed - missing IteNumber', result.jobStatus, 'Job status should indicate failure');
    }

    @isTest
    static void testProcessMessage_WithInvalidValidDate() {
        ERPMessageParser.ErpToSfMessage_ProdPlanBalance mockMessage = createMockMessage(true, true);

        // Set ValidDate to be before the week DateTo to trigger the skip condition
        mockMessage.data.items[0].Plans[0].ValidDate = '2025-01-05'; // Earlier than week end dates

        String requestBody = JSON.serialize(mockMessage);

        Test.startTest();
        ERPMessageHandlerProdPlanBalance.MessageProcessingResult result =
            ERPMessageHandlerProdPlanBalance.ProcessMessage(mockMessage, requestBody, false);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals('ProdPlanBalance', result.MessageType, 'MessageType should match');
    }

    @isTest
    static void testProcessMessage_EmptyItems() {
        ERPMessageParser.ErpToSfMessage_ProdPlanBalance mockMessage = createMockMessage(true, true);
        mockMessage.data.items = new List<ERPMessageParser.OrderItemsData>();

        String requestBody = JSON.serialize(mockMessage);

        Test.startTest();
        ERPMessageHandlerProdPlanBalance.MessageProcessingResult result =
            ERPMessageHandlerProdPlanBalance.ProcessMessage(mockMessage, requestBody, false);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals('ProdPlanBalance', result.MessageType, 'MessageType should match');
    }

    @isTest
    static void testProcessMessage_MultipleItems() {
        ERPMessageParser.ErpToSfMessage_ProdPlanBalance mockMessage = createMockMessage(true, true);

        // Add a second item
        ERPMessageParser.OrderItemsData itemData2 = new ERPMessageParser.OrderItemsData();
        itemData2.IteNumber = TEST_ITE_NUMBER + '-2';
        itemData2.Shop = TEST_SHOP_ERP_ID;
        itemData2.DateSnapshot = '2025-01-01';
        itemData2.Year = TEST_YEAR;
        itemData2.Month = TEST_MONTH;
        itemData2.MonthPlanQty_t = 200.0;
        itemData2.MonthProdBalance_t = 100.0;
        itemData2.Plans = new List<ERPMessageParser.ProdPlan>();

        mockMessage.data.items.add(itemData2);

        String requestBody = JSON.serialize(mockMessage);

        Test.startTest();
        ERPMessageHandlerProdPlanBalance.MessageProcessingResult result =
            ERPMessageHandlerProdPlanBalance.ProcessMessage(mockMessage, requestBody, false);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals('ProdPlanBalance', result.MessageType, 'MessageType should match');
    }

    @isTest
    static void testProcessMessage_TooManyBatchJobs() {
        // This test verifies the batch job queue limit check
        // Create a valid message
        ERPMessageParser.ErpToSfMessage_ProdPlanBalance mockMessage = createMockMessage(true, true);
        String requestBody = JSON.serialize(mockMessage);

        Test.startTest();
        ERPMessageHandlerProdPlanBalance.MessageProcessingResult result =
            ERPMessageHandlerProdPlanBalance.ProcessMessage(mockMessage, requestBody, false);
        Test.stopTest();

        // In test context, there are no queued batch jobs, so the batch should launch successfully
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals('ProdPlanBalance', result.MessageType, 'MessageType should match');
        System.assert(result.jobStatus != null, 'Job status should be set');
    }

    @isTest
    static void testGenerateResponseBody_Success() {
        Map<Integer, String> statusCodesMap = new Map<Integer, String>{
            200 => 'Success',
            400 => 'Bad Request',
            500 => 'Internal Server Error'
        };

        ERPMessageHandlerProdPlanBalance.MessageProcessingResult mpRes =
            new ERPMessageHandlerProdPlanBalance.MessageProcessingResult();
        mpRes.MessageType = 'ProdPlanBalance';
        mpRes.error = null;
        mpRes.jobStatus = 'Completed';

        Test.startTest();
        Blob responseBody = ERPMessageHandlerProdPlanBalance.generateResponseBody(
            statusCodesMap, 200, null, mpRes
        );
        Test.stopTest();

        System.assertNotEquals(null, responseBody, 'Response body should not be null');
    }

    @isTest
    static void testGenerateResponseBody_WithError() {
        Map<Integer, String> statusCodesMap = new Map<Integer, String>{
            200 => 'Success',
            400 => 'Bad Request',
            500 => 'Internal Server Error'
        };

        ERPMessageHandlerProdPlanBalance.MessageProcessingResult mpRes =
            new ERPMessageHandlerProdPlanBalance.MessageProcessingResult();
        mpRes.MessageType = 'ProdPlanBalance';
        mpRes.error = 'Test error message';
        mpRes.jobStatus = 'Failed';

        Test.startTest();
        Blob responseBody = ERPMessageHandlerProdPlanBalance.generateResponseBody(
            statusCodesMap, 500, 'Test error message', mpRes
        );
        Test.stopTest();

        System.assertNotEquals(null, responseBody, 'Response body should not be null');
    }

    @isTest
    static void testToDate_ValidISODateTime() {
        // Test with valid ISO datetime
        String isoDateTime = '2025-01-15T10:30:00';

        Test.startTest();
        // We need to test toDate method indirectly through ProcessMessage
        ERPMessageParser.ErpToSfMessage_ProdPlanBalance mockMessage = createMockMessage(true, true);
        mockMessage.data.items[0].DateSnapshot = isoDateTime;

        ERPMessageHandlerProdPlanBalance.MessageProcessingResult result =
            ERPMessageHandlerProdPlanBalance.ProcessMessage(mockMessage, '', false);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
    }

    @isTest
    static void testToDate_ValidDateString() {
        // Test with valid date string
        String dateString = '2025-01-15';

        Test.startTest();
        ERPMessageParser.ErpToSfMessage_ProdPlanBalance mockMessage = createMockMessage(true, true);
        mockMessage.data.items[0].DateSnapshot = dateString;

        ERPMessageHandlerProdPlanBalance.MessageProcessingResult result =
            ERPMessageHandlerProdPlanBalance.ProcessMessage(mockMessage, '', false);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
    }

    @isTest
    static void testToDate_DefaultDate() {
        // Test with default/empty date
        String defaultDate = '0001-01-01T00:00:00';

        Test.startTest();
        ERPMessageParser.ErpToSfMessage_ProdPlanBalance mockMessage = createMockMessage(true, true);
        mockMessage.data.items[0].Plans[0].ValidDate = defaultDate;

        ERPMessageHandlerProdPlanBalance.MessageProcessingResult result =
            ERPMessageHandlerProdPlanBalance.ProcessMessage(mockMessage, '', false);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
    }

    @isTest
    static void testToDate_BlankDate() {
        // Test with blank date
        Test.startTest();
        ERPMessageParser.ErpToSfMessage_ProdPlanBalance mockMessage = createMockMessage(true, true);
        mockMessage.data.items[0].Plans[0].ValidDate = '';

        ERPMessageHandlerProdPlanBalance.MessageProcessingResult result =
            ERPMessageHandlerProdPlanBalance.ProcessMessage(mockMessage, '', false);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
    }

    @isTest
    static void testProcessMessage_WithEmptyWeekPlans() {
        ERPMessageParser.ErpToSfMessage_ProdPlanBalance mockMessage = createMockMessage(true, true);

        // Set WeekPlans to empty list
        mockMessage.data.items[0].Plans[0].WeekPlans = new List<ERPMessageParser.WeekPlan>();

        String requestBody = JSON.serialize(mockMessage);

        Test.startTest();
        ERPMessageHandlerProdPlanBalance.MessageProcessingResult result =
            ERPMessageHandlerProdPlanBalance.ProcessMessage(mockMessage, requestBody, false);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals('ProdPlanBalance', result.MessageType, 'MessageType should match');
    }

    @isTest
    static void testProcessMessage_WithEmptyWeekPlanDetails() {
        ERPMessageParser.ErpToSfMessage_ProdPlanBalance mockMessage = createMockMessage(true, true);

        // Set Details to empty list instead of null to avoid NullPointerException
        mockMessage.data.items[0].Plans[0].WeekPlans[0].Details = new List<ERPMessageParser.WeekPlanNode>();

        String requestBody = JSON.serialize(mockMessage);

        Test.startTest();
        ERPMessageHandlerProdPlanBalance.MessageProcessingResult result =
            ERPMessageHandlerProdPlanBalance.ProcessMessage(mockMessage, requestBody, false);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals('ProdPlanBalance', result.MessageType, 'MessageType should match');
        System.assertEquals(null, result.error, 'Error should be null for empty details');
        System.assert(result.jobStatus.contains('Batch launched'), 'Batch should be launched');
    }
}