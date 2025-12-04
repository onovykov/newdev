@IsTest
private class OrderItemStageEventBatch_Tests {
    /* ======================================================
       HELPER: створення адмін-юзера
       ====================================================== */
    private static User createAdminUser() {

        Profile adminProfile = [
            SELECT Id
            FROM Profile
            WHERE Name = 'System Administrator'
            LIMIT 1
        ];

        User u = new User(
            Alias = 'adm1',
            Email = 'admin@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Admin',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'Europe/London',
            Username = 'admin_' + System.currentTimeMillis() + '@example.com',
            ProfileId = adminProfile.Id,
            BusinesDivision__c = 'Pipes',
            SalesDivision__c   = '00004',
            ID_ERP__c          = '00999',
            UID_ERP__c         = '99999',
            LoginERP__c        = 'ADMINUSER'
        );

        insert u;
        return u;
    }

    /* ======================================================
       TEST SETUP — базові дані
       ====================================================== */
    @TestSetup
    static void setupData() {

        // Reset static caches
        ERPMessageHandlerOrderItemStage.resetCacheForTest();
        ERPMessageHandlerOrderItemStage.resetAdminCacheForTest();

        // Stub stage mapping
        ERPMessageHandlerOrderItemStage.cachedStatus = new Map<String, String>{
            '_12' => 'Processing'
        };

        // ---- Product ----
        Product2 prod = new Product2(Name = 'TestProd', IsActive = true);
        insert prod;

        // ---- PricebookEntry ----
        PricebookEntry pbe = new PricebookEntry(
            Product2Id   = prod.Id,
            Pricebook2Id = Test.getStandardPricebookId(),
            IsActive     = true,
            UnitPrice    = 100
        );
        insert pbe;

        // ---- Account ----
        Account acc = new Account(Name = 'Test Acc');
        insert acc;

        // ---- Opportunity ----
        Opportunity opp = new Opportunity(
            Name       = 'Opp',
            StageName  = 'Prospecting',
            CloseDate  = Date.today(),
            AccountId  = acc.Id
        );
        insert opp;

        // ---- Order ----
        Order ord = new Order(
            AccountId     = acc.Id,
            EffectiveDate = Date.today(),
            Status        = 'Draft',
            Pricebook2Id  = Test.getStandardPricebookId()
        );
        insert ord;

        // ---- OLI + OrderItem (ERP_KEY = 111-222) ----
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId    = opp.Id,
            PricebookEntryId = pbe.Id,
            Quantity         = 1,
            UnitPrice        = 100,
            ID_ERP__c        = '111-222'
        );
        insert oli;

        OrderItem oi = new OrderItem(
            OrderId         = ord.Id,
            PricebookEntryId = pbe.Id,
            Quantity         = 1,
            UnitPrice        = 100,
            ID_ERP__c        = '111-222'
        );
        insert oi;

        // ---- Admin user ----
        User admin = createAdminUser();

        // ---- Admin group (safe create if missing) ----
        Group g;
        List<Group> groups = [
            SELECT Id FROM Group
            WHERE DeveloperName = 'AdminsForEmail'
            LIMIT 1
        ];

        if (groups.isEmpty()) {
            g = new Group(
                Name          = 'AdminsForEmail',
                DeveloperName = 'AdminsForEmail',
                Type          = 'Regular'
            );
            insert g;
        } else {
            g = groups[0];
        }

        // ---- Add admin into group if missing ----
        List<GroupMember> gm = [
            SELECT Id
            FROM GroupMember
            WHERE GroupId = :g.Id AND UserOrGroupId = :admin.Id
        ];

        if (gm.isEmpty()) {
            insert new GroupMember(GroupId = g.Id, UserOrGroupId = admin.Id);
        }
    }

    /* ======================================================
       TEST 1: Success case — one event processed correctly
       ====================================================== */
    @IsTest
    static void testSuccessSingle() {

        insert new OrderItemStageEvent__c(
            ERP_Key__c            = '111-222',
            ERP_Opportunity_Id__c = '111',
            ERP_Item_Id__c        = '222',
            Raw_Stage_Code__c     = '_12',
            SF_Stage__c           = 'Processing',
            Stage__c              = 'Pending'
        );

        Test.startTest();
            Database.executeBatch(new OrderItemStageEventBatch(), 10);
        Test.stopTest();

        OrderItemStageEvent__c evt = [
            SELECT Stage__c, Error_Message__c
            FROM OrderItemStageEvent__c
            LIMIT 1
        ];

        System.assertEquals('Processed', evt.Stage__c);
        System.assertEquals(null, evt.Error_Message__c);
    }

    /* ======================================================
       TEST 2: Failed — no matching targets
       ====================================================== */
    @IsTest
    static void testFailed_NoTargets() {

        insert new OrderItemStageEvent__c(
            ERP_Key__c            = '999-888', // no OLI/OrderItem
            ERP_Opportunity_Id__c = '999',
            ERP_Item_Id__c        = '888',
            Raw_Stage_Code__c     = '_12',
            SF_Stage__c           = 'Processing',
            Stage__c              = 'Pending'
        );

        Test.startTest();
            Database.executeBatch(new OrderItemStageEventBatch(), 10);
        Test.stopTest();

        OrderItemStageEvent__c evt = [
            SELECT Stage__c, Error_Message__c
            FROM OrderItemStageEvent__c
            WHERE ERP_Key__c = '999-888'
            LIMIT 1
        ];

        System.assertEquals('Failed', evt.Stage__c);
        System.assert(evt.Error_Message__c.contains('No related'));
    }

    /* ======================================================
       TEST 3: Failed — empty ERP_Key__c
       ====================================================== */
    @IsTest
    static void testFailed_EmptyKey() {

        insert new OrderItemStageEvent__c(
            ERP_Key__c            = null,
            ERP_Opportunity_Id__c = '111',
            ERP_Item_Id__c        = '222',
            Raw_Stage_Code__c     = '_12',
            SF_Stage__c           = 'Processing',
            Stage__c              = 'Pending'
        );

        Test.startTest();
            Database.executeBatch(new OrderItemStageEventBatch(), 10);
        Test.stopTest();

        OrderItemStageEvent__c evt = [
            SELECT Stage__c, Error_Message__c
            FROM OrderItemStageEvent__c
            WHERE ERP_Opportunity_Id__c = '111'
            LIMIT 1
        ];

        System.assertEquals('Failed', evt.Stage__c);
        System.assert(evt.Error_Message__c.contains('Empty ERP_Key__c'));
    }

    /* ======================================================
    TEST 4: Unknown stage → event processed, not lost
    ====================================================== */
    @IsTest
    static void testUnknownStage_Processed() {

        insert new OrderItemStageEvent__c(
            ERP_Key__c            = '111-222',
            ERP_Opportunity_Id__c = '111',
            ERP_Item_Id__c        = '222',
            Raw_Stage_Code__c     = 'WTF_STAGE',
            SF_Stage__c           = 'Processing',
            Is_Unknown_Stage__c   = true,
            Stage__c              = 'Pending'
        );

        Test.startTest();
            Database.executeBatch(new OrderItemStageEventBatch(), 10);
        Test.stopTest();

        OrderItemStageEvent__c evt = [
            SELECT Stage__c, Error_Message__c, Is_Unknown_Stage__c, Raw_Stage_Code__c
            FROM OrderItemStageEvent__c
            WHERE ERP_Key__c = '111-222'
            LIMIT 1
        ];

        System.assertEquals('Processed', evt.Stage__c, 'Event with unknown stage must still be processed.');
        System.assertEquals(true, evt.Is_Unknown_Stage__c, 'Unknown flag should be preserved.');
        System.assertEquals('WTF_STAGE', evt.Raw_Stage_Code__c, 'Raw stage code should be preserved.');
        System.assertEquals(null, evt.Error_Message__c, 'No error expected for valid unknown-stage event.');
    }

    /* ======================================================
       TEST 5: Multiple events with same key
       ====================================================== */
    @IsTest
    static void testMultipleEventsSameKey() {

        insert new OrderItemStageEvent__c(
            ERP_Key__c            = '111-222',
            ERP_Opportunity_Id__c = '111',
            ERP_Item_Id__c        = '222',
            Raw_Stage_Code__c     = '_12',
            SF_Stage__c           = 'Processing',
            Stage__c              = 'Pending'
        );

        insert new OrderItemStageEvent__c(
            ERP_Key__c            = '111-222',
            ERP_Opportunity_Id__c = '111',
            ERP_Item_Id__c        = '222',
            Raw_Stage_Code__c     = '_12',
            SF_Stage__c           = 'Processing',
            Stage__c              = 'Pending'
        );

        Test.startTest();
            Database.executeBatch(new OrderItemStageEventBatch(), 10);
        Test.stopTest();

        Integer processedCount = [
            SELECT COUNT()
            FROM OrderItemStageEvent__c
            WHERE Stage__c = 'Processed'
        ];

        System.assertEquals(2, processedCount);
    }
}