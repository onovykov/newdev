@isTest
private class OrderItemDatatableControllerTest {
	
    public static final String PROFILE_NAME_ADMINISTRATOR = 'System Administrator';
    private static final String SYS_ADMIN_ROLE = 'System_Admin';
    
    @testSetup
    static void setupTestData() {
        Account testAccount = new Account(Name = 'Test Account', MarketSegment__c = '00004');
        insert testAccount;

        Contact testContact = new Contact(FirstName = 'Test', LastName = 'User', AccountId = testAccount.Id, MailingCountry = 'Ukraine');
        insert testContact;

        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;

        Order testOrder = new Order(
            Name = 'Test Order',
            AccountId = testAccount.Id,
            Status = 'Draft',
            EffectiveDate = Date.today(),
            Pricebook2Id = standardPricebook.Id
        );
        insert testOrder;

        Product2 testProduct = new Product2(Name = 'Test Product', IsActive = true);
        insert testProduct;

        PricebookEntry testPricebookEntry = new PricebookEntry(
            Product2Id = testProduct.Id,
            Pricebook2Id = standardPricebook.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert testPricebookEntry;

        OrderItem testOrderItem = new OrderItem(
            OrderId = testOrder.Id,
            PricebookEntryId = testPricebookEntry.Id,
            Quantity = 10,
            UnitPrice = 100
        );
        insert testOrderItem;

        User testUserAdministrator = CreateReclamationTestUtility.createTestUserAdministrator(PROFILE_NAME_ADMINISTRATOR);
        testUserAdministrator.BusinesDivision__c = 'Pipes';
        testUserAdministrator.SalesDivision__c = '00004';
        testUserAdministrator.ID_ERP__c = 'ADM1';
        testUserAdministrator.EmployeeNumber = 'ADM1';
        
        System.runAs(new User(Id = UserInfo.getUserId())) { 
            UserRole roleTest = new UserRole(DeveloperName = SYS_ADMIN_ROLE, Name = 'r0');
            insert roleTest;
    
            testUserAdministrator.UserRoleId = roleTest.Id;
            insert testUserAdministrator;
        }

        testAccount.OwnerId = testUserAdministrator.Id;
        update testAccount;

        System.runAs(testUserAdministrator) {
            Id profileId = [SELECT Id FROM Profile WHERE Name ='Customer Community User (Custom)'].Id;
            User testUser = CreateReclamationTestUtility.createCommunityUser(testContact.Id, profileId, 'Amit', 'Singh');
            testUser.BusinesDivision__c = 'Pipes';
            testUser.ID_ERP__c = 'TEST1';
            testUser.EmployeeNumber = 'TEST1';
            testUser.SalesDivision__c = '00004';
            testUser.ManagerId = testUserAdministrator.id;
            insert testUser;
        }
    }

    @isTest
    static void testGetOrderItems() {
        Order testOrder = [SELECT Id FROM Order LIMIT 1];

        Test.startTest();
        Order resultOrder = OrderItemDatatableController.getOrderItems(testOrder.Id);
        Test.stopTest();

        System.assertNotEquals(null, resultOrder, 'Order should not be null');
        System.assertEquals(testOrder.Id, resultOrder.Id, 'Returned order ID should match test order ID');
    }

    @isTest
    static void testGetOrderItemSpecification() {
        OrderItem testOrderItem = [SELECT Id FROM OrderItem LIMIT 1];

        Test.startTest();
        OrderItem resultOrderItem = OrderItemDatatableController.getOrderItemSpecification(testOrderItem.Id);
        Test.stopTest();

        System.assertNotEquals(null, resultOrderItem, 'Order Item should not be null');
        System.assertEquals(testOrderItem.Id, resultOrderItem.Id, 'Returned order item ID should match test order ID');
    }

    @isTest
    static void testGetUserMarketSegment() {
        User testUser = [SELECT Id FROM User WHERE LastName = 'Singh' LIMIT 1];
        System.runAs(testUser) {
            Test.startTest();
            String marketSegment = OrderItemDatatableController.getUserMarketSegment();
            Test.stopTest();

            System.assertEquals('00004', marketSegment, 'Market Segment should match the test data');
        }
    }
}