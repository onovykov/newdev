@isTest
private class InsertProdPlanBatchTest extends BaseTest {

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

    // Helper method to create test batch data
    private static InsertProdPlanBatch createBatchWithData(Boolean includeWeekPlans) {
        InsertProdPlanBatch batch = new InsertProdPlanBatch();

        // Create PeriodInfo
        batch.orderItemsPeriodInfo = new ERPMessageParser.PeriodInfo();
        batch.orderItemsPeriodInfo.YearMonth = String.valueOf(TEST_YEAR) + String.valueOf(TEST_MONTH).leftPad(2, '0');

        // Create ItemNode
        ERPMessageParser.ItemNode item = new ERPMessageParser.ItemNode();
        item.IteNumber = TEST_ITE_NUMBER;
        item.Shop = TEST_SHOP_ERP_ID;
        item.monthPlans = new List<ERPMessageParser.MonthPlanNode>();

        // Create MonthPlanNode
        ERPMessageParser.MonthPlanNode monthPlan = new ERPMessageParser.MonthPlanNode();
        monthPlan.ProdPlanType = '253';
        monthPlan.MonthPlanQty_t = 100.0;
        monthPlan.MonthProdBalance_t = 50.0;
        monthPlan.DateSnapshot = Date.today();
        monthPlan.Year = TEST_YEAR;
        monthPlan.Month = TEST_MONTH;
        monthPlan.ValidDate = Date.today().addDays(30);
        monthPlan.monthWeeks = new List<ERPMessageParser.WeekPlanNode>();

        if (includeWeekPlans) {
            // Create WeekPlanNodes
            for (Integer i = 1; i <= 2; i++) {
                ERPMessageParser.WeekPlanNode weekNode = new ERPMessageParser.WeekPlanNode();
                weekNode.ProdPlanType = '253';
                weekNode.ValidDate = Date.today().addDays(30);
                weekNode.WeekNum = i;
                weekNode.PlanQty_t = 25.0;
                weekNode.DateFrom = '2025-01-' + String.valueOf(1 + ((i - 1) * 7)).leftPad(2, '0');
                weekNode.DateTo = '2025-01-' + String.valueOf(7 + ((i - 1) * 7)).leftPad(2, '0');
                monthPlan.monthWeeks.add(weekNode);
            }
        }

        item.monthPlans.add(monthPlan);

        batch.items = new List<ERPMessageParser.ItemNode>{ item };
        batch.itemNumbers = new Set<String>{ TEST_ITE_NUMBER };

        return batch;
    }

    @isTest
    static void testBatchExecution_RecreatePlans_WithWeekPlans() {
        InsertProdPlanBatch batch = createBatchWithData(true);
        batch.recreatePlans = true;

        Test.startTest();
        Database.executeBatch(batch);
        Test.stopTest();

        // Verify monthly plans were created
        List<OrderItemMonthlyPlans__c> monthPlans = [
            SELECT Id, MonthlyProdPlan__c, BalanceForProduction__c, Year__c, Month__c
            FROM OrderItemMonthlyPlans__c
        ];
        System.assertNotEquals(0, monthPlans.size(), 'Monthly plans should be created');
        System.assertEquals(100.0, monthPlans[0].MonthlyProdPlan__c, 'Monthly plan quantity should match');

        // Verify weekly plans were created
        List<OrderItemWeekPlans__c> weekPlans = [
            SELECT Id, PlanQty_t__c
            FROM OrderItemWeekPlans__c
        ];
        System.assertNotEquals(0, weekPlans.size(), 'Weekly plans should be created');
    }

    @isTest
    static void testBatchExecution_RecreatePlans_WithoutWeekPlans() {
        InsertProdPlanBatch batch = createBatchWithData(false);
        batch.recreatePlans = true;

        Test.startTest();
        Database.executeBatch(batch);
        Test.stopTest();

        // Verify monthly plans were created
        List<OrderItemMonthlyPlans__c> monthPlans = [
            SELECT Id, MonthlyProdPlan__c, BalanceForProduction__c
            FROM OrderItemMonthlyPlans__c
        ];
        System.assertNotEquals(0, monthPlans.size(), 'Monthly plans should be created');

        // Verify no weekly plans were created
        List<OrderItemWeekPlans__c> weekPlans = [
            SELECT Id
            FROM OrderItemWeekPlans__c
        ];
        System.assertEquals(0, weekPlans.size(), 'No weekly plans should be created');
    }

    @isTest
    static void testBatchExecution_UpsertMode_NewPlans() {
        InsertProdPlanBatch batch = createBatchWithData(true);
        batch.recreatePlans = false;

        Test.startTest();
        Database.executeBatch(batch);
        Test.stopTest();

        // Verify monthly plans were created
        List<OrderItemMonthlyPlans__c> monthPlans = [
            SELECT Id, MonthlyProdPlan__c
            FROM OrderItemMonthlyPlans__c
        ];
        System.assertNotEquals(0, monthPlans.size(), 'Monthly plans should be created in upsert mode');

        // Verify weekly plans were created
        List<OrderItemWeekPlans__c> weekPlans = [
            SELECT Id
            FROM OrderItemWeekPlans__c
        ];
        System.assertNotEquals(0, weekPlans.size(), 'Weekly plans should be created in upsert mode');
    }

    @isTest
    static void testBatchExecution_UpsertMode_UpdateExistingPlans() {
        // First, create existing plans
        InsertProdPlanBatch batch1 = createBatchWithData(true);
        batch1.recreatePlans = false;
        Database.executeBatch(batch1);
        Test.startTest();

        // Now update with new values
        InsertProdPlanBatch batch2 = createBatchWithData(true);
        batch2.recreatePlans = false;
        batch2.items[0].monthPlans[0].MonthPlanQty_t = 200.0; // Changed value
        batch2.items[0].monthPlans[0].monthWeeks[0].PlanQty_t = 50.0; // Changed value
        Database.executeBatch(batch2);
        Test.stopTest();

        // Verify monthly plans were updated
        List<OrderItemMonthlyPlans__c> monthPlans = [
            SELECT Id, MonthlyProdPlan__c
            FROM OrderItemMonthlyPlans__c
        ];
        System.assertEquals(1, monthPlans.size(), 'Should still have one monthly plan');
        System.assertEquals(200.0, monthPlans[0].MonthlyProdPlan__c, 'Monthly plan should be updated');

        // Verify weekly plans were updated
        List<OrderItemWeekPlans__c> weekPlans = [
            SELECT Id, PlanQty_t__c
            FROM OrderItemWeekPlans__c
            ORDER BY WeekNum__c
        ];
        System.assertNotEquals(0, weekPlans.size(), 'Weekly plans should exist');
    }

//    @isTest
//    static void testBatchExecution_RecreatePlans_DeletesExisting() {
//        // First, create existing plans
//        InsertProdPlanBatch batch1 = createBatchWithData(true);
//        batch1.recreatePlans = false;
//        Database.executeBatch(batch1);
//        Test.startTest();
//
//        // Get count of existing plans
//        Integer initialMonthCount = [SELECT COUNT() FROM OrderItemMonthlyPlans__c];
//        Integer initialWeekCount = [SELECT COUNT() FROM OrderItemWeekPlans__c];
//
//        // Now recreate plans
//        InsertProdPlanBatch batch2 = createBatchWithData(true);
//        batch2.recreatePlans = true;
//        Database.executeBatch(batch2);
//        Test.stopTest();
//
//        // Verify plans were recreated (count should be the same, but records are new)
//        Integer finalMonthCount = [SELECT COUNT() FROM OrderItemMonthlyPlans__c];
//        Integer finalWeekCount = [SELECT COUNT() FROM OrderItemWeekPlans__c];
//
//        System.assertEquals(initialMonthCount, finalMonthCount, 'Monthly plan count should be same');
//        System.assertNotEquals(0, finalWeekCount, 'Weekly plans should be recreated');
//    }

    @isTest
    static void testBatchExecution_EmptyItemNumbers() {
        InsertProdPlanBatch batch = new InsertProdPlanBatch();
        batch.items = new List<ERPMessageParser.ItemNode>();
        batch.itemNumbers = new Set<String>();
        batch.orderItemsPeriodInfo = new ERPMessageParser.PeriodInfo();
        batch.orderItemsPeriodInfo.YearMonth = '202501';

        Test.startTest();
        Database.executeBatch(batch);
        Test.stopTest();

        // Should complete without errors
        List<OrderItemMonthlyPlans__c> monthPlans = [
            SELECT Id
            FROM OrderItemMonthlyPlans__c
        ];
        System.assertEquals(0, monthPlans.size(), 'No plans should be created');
    }

    @isTest
    static void testBatchExecution_MissingOrderItem() {
        InsertProdPlanBatch batch = createBatchWithData(true);
        batch.itemNumbers = new Set<String>{ 'NONEXISTENT-001' };
        batch.items[0].IteNumber = 'NONEXISTENT-001';

        Test.startTest();
        Database.executeBatch(batch);
        Test.stopTest();

        // Should complete without errors, but no plans created
        List<OrderItemMonthlyPlans__c> monthPlans = [
            SELECT Id
            FROM OrderItemMonthlyPlans__c
        ];
        System.assertEquals(0, monthPlans.size(), 'No plans should be created for missing OrderItem');
    }

    @isTest
    static void testBatchExecution_MissingShop() {
        InsertProdPlanBatch batch = createBatchWithData(true);
        batch.items[0].Shop = 999; // Non-existent shop

        Test.startTest();
        Database.executeBatch(batch);
        Test.stopTest();

        // Should complete without errors, but no plans created
        List<OrderItemMonthlyPlans__c> monthPlans = [
            SELECT Id
            FROM OrderItemMonthlyPlans__c
        ];
        System.assertEquals(0, monthPlans.size(), 'No plans should be created for missing Shop');
    }

    @isTest
    static void testBatchExecution_MissingProdWeek() {
        InsertProdPlanBatch batch = createBatchWithData(true);
        // Set week number that doesn't exist
        batch.items[0].monthPlans[0].monthWeeks[0].WeekNum = 99;

        Test.startTest();
        Database.executeBatch(batch);
        Test.stopTest();

        // Monthly plan should be created, but weekly plan should be skipped
        List<OrderItemMonthlyPlans__c> monthPlans = [
            SELECT Id
            FROM OrderItemMonthlyPlans__c
        ];
        System.assertNotEquals(0, monthPlans.size(), 'Monthly plan should be created');

        List<OrderItemWeekPlans__c> weekPlans = [
            SELECT Id
            FROM OrderItemWeekPlans__c
        ];
        // Should have fewer weekly plans than expected (missing week 99)
        System.assert(weekPlans.size() < 2, 'Should skip weekly plan with invalid week number');
    }

    @isTest
    static void testBatchFinish_LaunchesNextBatch() {
        InsertProdPlanBatch batch = createBatchWithData(false);

        Test.startTest();
        Database.executeBatch(batch);
        Test.stopTest();

        // Verify that LinkProductionLotsToProdWeeksBatch was queued
        List<AsyncApexJob> jobs = [
            SELECT Id, ApexClass.Name, Status
            FROM AsyncApexJob
            WHERE ApexClass.Name = 'LinkProductionLotsToProdWeeksBatch'
            AND JobType = 'BatchApex'
        ];

        System.assertNotEquals(0, jobs.size(), 'LinkProductionLotsToProdWeeksBatch should be queued');
    }

    @isTest
    static void testBatchExecution_MultipleItems() {
        InsertProdPlanBatch batch = createBatchWithData(true);

        // Add second item
        ERPMessageParser.ItemNode item2 = new ERPMessageParser.ItemNode();
        item2.IteNumber = TEST_ITE_NUMBER;
        item2.Shop = TEST_SHOP_ERP_ID;
        item2.monthPlans = new List<ERPMessageParser.MonthPlanNode>();

        ERPMessageParser.MonthPlanNode monthPlan2 = new ERPMessageParser.MonthPlanNode();
        monthPlan2.ProdPlanType = '254';
        monthPlan2.MonthPlanQty_t = 150.0;
        monthPlan2.MonthProdBalance_t = 75.0;
        monthPlan2.DateSnapshot = Date.today();
        monthPlan2.Year = TEST_YEAR;
        monthPlan2.Month = 2;
        monthPlan2.ValidDate = Date.today().addDays(60);
        monthPlan2.monthWeeks = new List<ERPMessageParser.WeekPlanNode>();

        item2.monthPlans.add(monthPlan2);
        batch.items.add(item2);

        Test.startTest();
        Database.executeBatch(batch);
        Test.stopTest();

        // Verify multiple monthly plans were created
        List<OrderItemMonthlyPlans__c> monthPlans = [
            SELECT Id, Month__c, ProdPlanType__c
            FROM OrderItemMonthlyPlans__c
            ORDER BY Month__c
        ];
        System.assertEquals(2, monthPlans.size(), 'Two monthly plans should be created');
    }

    @isTest
    static void testBatchStart() {
        InsertProdPlanBatch batch = createBatchWithData(false);

        Test.startTest();
        Database.QueryLocator ql = batch.start(null);
        Test.stopTest();

        System.assertNotEquals(null, ql, 'QueryLocator should not be null');
    }

    @isTest
    static void testLoadOrders_WithShortIte() {
        InsertProdPlanBatch batch = createBatchWithData(false);

        Test.startTest();
        Database.executeBatch(batch);
        Test.stopTest();

        // Verify Order__c field is populated in monthly plans
        List<OrderItemMonthlyPlans__c> monthPlans = [
            SELECT Id, Order__c
            FROM OrderItemMonthlyPlans__c
        ];
        System.assertNotEquals(0, monthPlans.size(), 'Monthly plans should be created');
        System.assertNotEquals(null, monthPlans[0].Order__c, 'Order should be linked');
    }

    @isTest
    static void testMonthlyPlanName_Format() {
        InsertProdPlanBatch batch = createBatchWithData(false);

        Test.startTest();
        Database.executeBatch(batch);
        Test.stopTest();

        // Verify Name format: ITE#Month#Year
        List<OrderItemMonthlyPlans__c> monthPlans = [
            SELECT Id, Name
            FROM OrderItemMonthlyPlans__c
        ];
        System.assertNotEquals(0, monthPlans.size(), 'Monthly plans should be created');
        System.assert(monthPlans[0].Name.contains(TEST_ITE_NUMBER), 'Name should contain ITE number');
        System.assert(monthPlans[0].Name.contains('#'), 'Name should contain # separator');
    }
}