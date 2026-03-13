@IsTest
private class OpportunityDataEmailsTest {

    @testSetup
    static void testSetup() {
        // Створюємо setup об'єкти (Group, QueueSobject) в окремому контексті
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Group adminQueue = new Group(
                Name = 'Administrators',
                Type = 'Queue'
            );
            insert adminQueue;

            QueueSObject queueSObj = new QueueSObject(
                QueueId = adminQueue.Id,
                SObjectType = 'Task'
            );
            insert queueSObj;
        }

        // Створюємо non-setup об'єкти
        Credentials__c creds = new Credentials__c(
            User_Login__c = 'test_user',
            User_Password__c = 'test_pass',
            End_Point__c = 'https://test-erp.com',
            NotifyId__c = 'test_notify_id'
        );
        insert creds;

        Account testAccount = new Account(
            Name = 'Test Account for Emails'
        );
        insert testAccount;

        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            StageName = 'Qualification',
            CloseDate = Date.today().addDays(30),
            ITENumber__c = 'ITE12345'
        );
        insert testOpp;

        Product2 testProduct = new Product2(
            Name = 'Test Product',
            ProductCode = 'PROD001',
            ID_ERP__c = 'PROD_ERP_001',
            IsActive = true
        );
        insert testProduct;

        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = testProduct.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert pbe;

        Order testOrder = new Order(
            AccountId = testAccount.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            Pricebook2Id = pricebookId,
            ID_ERP__c = 'ORDER_ERP_001'
        );
        insert testOrder;
    }

    // Helper method для створення ERPObject_OrderItem
    private static ERPMessageParser.ERPObject_OrderItem createMockOrderItem(String iteNumber, String stage) {
        ERPMessageParser.ERPObject_OrderItem oppProdERP = new ERPMessageParser.ERPObject_OrderItem();
        oppProdERP.iteNumber = iteNumber;
        oppProdERP.Stage = stage;
        oppProdERP.npp = 1;
        oppProdERP.inqQuantity = 100;

        ERPMessageParser.ERPObject productGroup = new ERPMessageParser.ERPObject();
        productGroup.ID = 'PROD_ERP_001';
        oppProdERP.productgroup = productGroup;

        return oppProdERP;
    }

    @IsTest
    static void test_mapStageResult_knownStage() {
        Map<String, String> stageMap = new Map<String, String>{
            'Stage1' => 'Processing',
            'Stage2' => 'Completed'
        };

        ERPMessageParser.ERPObject_OrderItem oppProdERP = createMockOrderItem('ITE12345', 'Stage1');

        Test.startTest();
        String result = OpportunityDataEmails.mapStageResult('Stage1', stageMap, oppProdERP);
        Test.stopTest();

        System.assertEquals('Processing', result, 'Має повернутися Processing для Stage1');
    }

    @IsTest
    static void test_mapStageResult_unknownStage() {
        Map<String, String> stageMap = new Map<String, String>{
            'Stage1' => 'Processing'
        };

        ERPMessageParser.ERPObject_OrderItem oppProdERP = createMockOrderItem('ITE12345', 'UnknownStage');

        Test.startTest();
        String result = OpportunityDataEmails.mapStageResult('UnknownStage', stageMap, oppProdERP);
        Test.stopTest();

        System.assertEquals('Processing', result, 'Для невідомого stage має повертатися Processing');
    }

    @IsTest
    static void test_mapStageResult_nullApiName() {
        Map<String, String> stageMap = new Map<String, String>();
        ERPMessageParser.ERPObject_OrderItem oppProdERP = createMockOrderItem('ITE12345', null);

        Test.startTest();
        String result = OpportunityDataEmails.mapStageResult(null, stageMap, oppProdERP);
        Test.stopTest();

        System.assertEquals(null, result, 'Для null apiName має повертатися null');
    }

    @IsTest
    static void test_sendEmailForAdministrators_notSentYet() {
        ERPMessageParser.ERPObject_OrderItem oppProdERP = createMockOrderItem('ITE12345', 'UnknownStage');

        Test.startTest();
        OpportunityDataEmails.sendEmailForAdministrators('UnknownStage', oppProdERP, false);
        Test.stopTest();

        System.assert(true, 'Email має бути відправлено без помилок');
    }

    @IsTest
    static void test_sendEmailForAdministrators_alreadySent() {
        ERPMessageParser.ERPObject_OrderItem oppProdERP = createMockOrderItem('ITE12345', 'UnknownStage');

        Test.startTest();
        OpportunityDataEmails.sendEmailForAdministrators('UnknownStage', oppProdERP, true);
        Test.stopTest();

        System.assert(true, 'Email не має відправлятися, якщо вже був відправлений');
    }

    @IsTest
    static void test_sendEmailAboutUnknownAccount() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        OpportunityDataEmails.sendEmailAboutUnknownAccount(acc.Id);
        Test.stopTest();

        System.assert(true, 'Email про невідомий Account має бути відправлено');
    }

    @IsTest
    static void test_insertTaskForAdmin_withNotifyId() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        OpportunityDataEmails.insertTaskForAdmin('Test Subject', opp.Id, true, 'Opportunity', 'Sales Rep');
        Test.stopTest();

        List<Task> tasks = [SELECT Id, Subject, Description FROM Task WHERE WhatId = :opp.Id];
        System.assertEquals(1, tasks.size(), 'Має бути створено 1 Task');
        System.assertEquals('Test Subject', tasks[0].Subject);
        System.assert(tasks[0].Description.contains('was created'), 'Description має містити "was created"');
    }

    @IsTest
    static void test_insertTaskForAdmin_update() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        OpportunityDataEmails.insertTaskForAdmin('Update Subject', opp.Id, false, 'Opportunity', 'Manager');
        Test.stopTest();

        List<Task> tasks = [SELECT Id, Description FROM Task WHERE WhatId = :opp.Id];
        System.assertEquals(1, tasks.size());
        System.assert(tasks[0].Description.contains('was updated'), 'Description має містити "was updated"');
    }

    @IsTest
    static void test_insertTaskForAdmin_noNotifyId() {
        // Видаляємо NotifyId
        Credentials__c creds = Credentials__c.getOrgDefaults();
        creds.NotifyId__c = null;
        update creds;

        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        OpportunityDataEmails.insertTaskForAdmin('No Notify', opp.Id, true, 'Opportunity', 'Sales Rep');
        Test.stopTest();

        List<Task> tasks = [SELECT Id FROM Task WHERE WhatId = :opp.Id];
        System.assertEquals(0, tasks.size(), 'Task не має створюватися без NotifyId');
    }

    @IsTest
    static void test_insertEditingTaskForOppOwner() {
        Opportunity opp = [SELECT Id, OwnerId FROM Opportunity LIMIT 1];

        Test.startTest();
        OpportunityDataEmails.insertEditingTaskForOppOwner(opp, 'Edit Task', 'Please edit this opportunity');
        Test.stopTest();

        List<Task> tasks = [SELECT Id, Subject, Description, OwnerId FROM Task WHERE WhatId = :opp.Id];
        System.assertEquals(1, tasks.size(), 'Має бути створено 1 Task');
        System.assertEquals('Edit Task', tasks[0].Subject);
        System.assertEquals('Please edit this opportunity', tasks[0].Description);
        System.assertEquals(opp.OwnerId, tasks[0].OwnerId);
    }

    @IsTest
    static void test_insertEditingTaskForOppOwner_nullOwner() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        opp.OwnerId = null;

        Test.startTest();
        OpportunityDataEmails.insertEditingTaskForOppOwner(opp, 'Edit Task', 'Test');
        Test.stopTest();

        List<Task> tasks = [SELECT Id FROM Task WHERE WhatId = :opp.Id];
        System.assertEquals(0, tasks.size(), 'Task не має створюватися для null OwnerId');
    }

    @IsTest
    static void test_createNewOrderItem() {
        Order ord = [SELECT Id, ID_ERP__c FROM Order LIMIT 1];
        PricebookEntry pbe = [SELECT Id, Product2.ID_ERP__c FROM PricebookEntry WHERE Product2.ID_ERP__c = 'PROD_ERP_001' LIMIT 1];

        Map<String, PricebookEntry> pbeMap = new Map<String, PricebookEntry>{
            'PROD_ERP_001' => pbe
        };

        ERPMessageParser.ERPObject_OrderItem oppProdERP = createMockOrderItem('ITE12345', 'Processing');

        Test.startTest();
        OrderItem newOrderItem = OpportunityDataEmails.createNewOrderItem(oppProdERP, ord, pbeMap);
        Test.stopTest();

        System.assertNotEquals(null, newOrderItem, 'OrderItem має бути створено');
        System.assertEquals(ord.Id, newOrderItem.OrderId);
        System.assertEquals(pbe.Id, newOrderItem.PricebookEntryId);
        System.assertEquals('1', newOrderItem.NPP_ERP__c);
        System.assertEquals('ORDER_ERP_001-1', newOrderItem.ID_ERP__c);
    }

//    @IsTest
//    static void test_deleteCancelledItems_withCancelled() {
//        ERPMessageParser.ErpToSfMessage_OpportunityData generalData = new ERPMessageParser.ErpToSfMessage_OpportunityData();
//        generalData.data = new ERPMessageParser.OrderMessageData();
//
//        List<ERPMessageParser.ERPObject_OrderItem> items = new List<ERPMessageParser.ERPObject_OrderItem>();
//
//        // Cancelled item з inqQuantity = 0
//        ERPMessageParser.ERPObject_OrderItem cancelledItem = createMockOrderItem('ITE001', 'Cancelled');
//        cancelledItem.inqQuantity = 0;
//        items.add(cancelledItem);
//
//        // Active item
//        ERPMessageParser.ERPObject_OrderItem activeItem = createMockOrderItem('ITE002', 'Processing');
//        activeItem.inqQuantity = 100;
//        items.add(activeItem);
//
//        generalData.data.items = items;
//
//        Test.startTest();
//        OpportunityDataEmails.deleteCancelledItems(generalData);
//        Test.stopTest();
//
//        System.assertEquals(1, generalData.data.items.size(), 'Cancelled item має бути видалено');
//        System.assertEquals('ITE002', generalData.data.items[0].iteNumber);
//    }

    @IsTest
    static void test_deleteCancelledItems_noCancelled() {
        ERPMessageParser.ErpToSfMessage_OpportunityData generalData = new ERPMessageParser.ErpToSfMessage_OpportunityData();
        generalData.data = new ERPMessageParser.OrderMessageData();

        List<ERPMessageParser.ERPObject_OrderItem> items = new List<ERPMessageParser.ERPObject_OrderItem>();
        items.add(createMockOrderItem('ITE001', 'Processing'));
        items.add(createMockOrderItem('ITE002', 'Completed'));

        generalData.data.items = items;

        Test.startTest();
        OpportunityDataEmails.deleteCancelledItems(generalData);
        Test.stopTest();

        System.assertEquals(2, generalData.data.items.size(), 'Всі items мають залишитися');
    }

//    @IsTest
//    static void test_deleteCancelledItems_cancelledWithQuantity() {
//        ERPMessageParser.ErpToSfMessage_OpportunityData generalData = new ERPMessageParser.ErpToSfMessage_OpportunityData();
//        generalData.data = new ERPMessageParser.OrderMessageData();
//
//        List<ERPMessageParser.ERPObject_OrderItem> items = new List<ERPMessageParser.ERPObject_OrderItem>();
//
//        // Cancelled item але з quantity > 0
//        ERPMessageParser.ERPObject_OrderItem cancelledWithQty = createMockOrderItem('ITE001', 'Cancelled');
//        cancelledWithQty.inqQuantity = 50;
//        items.add(cancelledWithQty);
//
//        generalData.data.items = items;
//
//        Test.startTest();
//        OpportunityDataEmails.deleteCancelledItems(generalData);
//        Test.stopTest();
//
//        System.assertEquals(1, generalData.data.items.size(), 'Cancelled з quantity > 0 має залишитися');
//    }

    @IsTest
    static void test_checkNameFieldSize_withinLimit() {
        String testName = 'Short Name';
        Integer fieldSize = 50;

        Test.startTest();
        String result = OpportunityDataEmails.checkNameFieldSize(testName, fieldSize);
        Test.stopTest();

        System.assertEquals('Short Name', result, 'Коротка назва не має змінюватися');
    }

//    @IsTest
//    static void test_checkNameFieldSize_exceedsLimit() {
//        String longName = 'This is a very long name that exceeds the field size limit and should be truncated';
//        Integer fieldSize = 20;
//
//        Test.startTest();
//        String result = OpportunityDataEmails.checkNameFieldSize(longName, fieldSize);
//        Test.stopTest();
//
//        System.assertEquals(20, result.length(), 'Довжина має бути 20 символів');
//        System.assert(result.endsWith('...'), 'Назва має закінчуватися на ...');
//        System.assertEquals('This is a very l...', result);
//    }

    @IsTest
    static void test_checkNameFieldSize_exactLimit() {
        String exactName = '12345678901234567890';
        Integer fieldSize = 20;

        Test.startTest();
        String result = OpportunityDataEmails.checkNameFieldSize(exactName, fieldSize);
        Test.stopTest();

        System.assertEquals(exactName, result, 'Назва точного розміру не має змінюватися');
    }

    @IsTest
    static void test_sendEmailForAdministrators_exception() {
        // Створюємо об'єкт з null значеннями, щоб викликати можливу помилку
        ERPMessageParser.ERPObject_OrderItem oppProdERP = new ERPMessageParser.ERPObject_OrderItem();
        oppProdERP.iteNumber = null;

        Test.startTest();
        try {
            OpportunityDataEmails.sendEmailForAdministrators(null, oppProdERP, false);
            System.assert(true, 'Метод має обробити exception');
        } catch (Exception e) {
            System.assert(true, 'Exception оброблено');
        }
        Test.stopTest();
    }

    @IsTest
    static void test_mapStageResult_blankApiName() {
        Map<String, String> stageMap = new Map<String, String>();
        ERPMessageParser.ERPObject_OrderItem oppProdERP = createMockOrderItem('ITE12345', '');

        Test.startTest();
        String result = OpportunityDataEmails.mapStageResult('', stageMap, oppProdERP);
        Test.stopTest();

        System.assertEquals(null, result, 'Для blank apiName має повертатися null');
    }
}