@IsTest
public class ERPMessageHandlerOrderItemStage_Tests {
    /* ======================================================
       HELPER: створення адмін-юзера
       ====================================================== */
    private static User createAdminUser() {
        Profile adminProfile = [
            SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1
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
       TEST SETUP
       ====================================================== */
    @TestSetup
    static void setup() {

        // Reset кешів
        ERPMessageHandlerOrderItemStage.resetCacheForTest();
        ERPMessageHandlerOrderItemStage.resetAdminCacheForTest();

        // Створюємо адмін юзера
        User admin = createAdminUser();

        // Admin group
        Group g;
        List<Group> groups = [
            SELECT Id FROM Group WHERE DeveloperName = 'AdminsForEmail'
        ];

        if (groups.isEmpty()) {
            g = new Group(
                Name = 'AdminsForEmail',
                DeveloperName = 'AdminsForEmail',
                Type = 'Regular'
            );
            insert g;
        } else {
            g = groups[0];
        }

        // Ensure group membership
        if ([
            SELECT COUNT() FROM GroupMember
            WHERE GroupId = :g.Id AND UserOrGroupId = :admin.Id
        ] == 0) {
            insert new GroupMember(GroupId = g.Id, UserOrGroupId = admin.Id);
        }
    }


    /* ======================================================
       TEST 1: processMessage → створює staging запис
       ====================================================== */
    @IsTest
    static void testProcessMessageCreatesEvent() {

        // Reset cache & stub mapping
        ERPMessageHandlerOrderItemStage.resetCacheForTest();
        ERPMessageHandlerOrderItemStage.cachedStatus = new Map<String,String>{
            '_12' => 'Processing'
        };

        ERPMessageParser.ErpToSfMessage_OrderItemStage msg =
            new ERPMessageParser.ErpToSfMessage_OrderItemStage();

        msg.metadata = new ERPMessageParser.MessageMetadata();
        msg.metadata.MsgType = 'ERP-SF_ItemStage';

        msg.data = new ERPMessageParser.ErpToSfMessage_StageData();
        msg.data.Undoc = 111;
        msg.data.Npp   = 222;
        msg.data.Stage = '_12';

        String payload = '{"hello":"world"}';

        Test.startTest();
            ERPMessageHandlerOrderItemStage.processMessage(msg, payload);
        Test.stopTest();

        OrderItemStageEvent__c evt = [
            SELECT ERP_Key__c, SF_Stage__c, Stage__c, Payload_JSON__c
            FROM OrderItemStageEvent__c
            LIMIT 1
        ];

        System.assertEquals('111-222', evt.ERP_Key__c);
        System.assertEquals('Processing', evt.SF_Stage__c);
        System.assertEquals('Pending', evt.Stage__c);
        System.assert(evt.Payload_JSON__c.contains('hello'));
    }


    /* ======================================================
       TEST 2: unknown stage → Is_Unknown_Stage__c встановлено
       ====================================================== */
    @IsTest
    static void testProcessMessage_UnknownStage() {

        // Force empty mapping
        ERPMessageHandlerOrderItemStage.resetCacheForTest();
        ERPMessageHandlerOrderItemStage.cachedStatus = new Map<String,String>();

        ERPMessageParser.ErpToSfMessage_OrderItemStage msg =
            new ERPMessageParser.ErpToSfMessage_OrderItemStage();

        msg.metadata = new ERPMessageParser.MessageMetadata();
        msg.metadata.MsgType = 'ERP-SF_ItemStage';

        msg.data = new ERPMessageParser.ErpToSfMessage_StageData();
        msg.data.Undoc = 555;
        msg.data.Npp   = 666;
        msg.data.Stage = '_99';

        Test.startTest();
            ERPMessageHandlerOrderItemStage.processMessage(msg, '{}');
        Test.stopTest();

        OrderItemStageEvent__c evt = [
            SELECT SF_Stage__c, Is_Unknown_Stage__c, Raw_Stage_Code__c
            FROM OrderItemStageEvent__c
            WHERE ERP_Key__c = '555-666'
            LIMIT 1
        ];

        System.assertEquals('Processing', evt.SF_Stage__c); // fallback
        System.assertEquals(true, evt.Is_Unknown_Stage__c);
        System.assertEquals('_99', evt.Raw_Stage_Code__c);
    }


    /* ======================================================
       TEST 3: generateResponseBody
       ====================================================== */
    @IsTest
    static void testGenerateResponseBody() {

        ERPMessageHandlerOrderItemStage.MessageProcessingResult res =
            new ERPMessageHandlerOrderItemStage.MessageProcessingResult();

        res.messageType = 'ERP-SF_ItemStage';
        res.numberOfUpdatedRecords = 7;

        Map<Integer,String> statusMap = new Map<Integer,String>{
            200 => 'OK'
        };

        Blob b = ERPMessageHandlerOrderItemStage.generateResponseBody(
            statusMap, 200, null, res
        );

        String text = b.toString();

        System.assert(text.contains('OK'));
        System.assert(text.contains('7'));
        System.assert(text.contains('ERP-SF_ItemStage'));
    }


    /* ======================================================
       TEST 4: sendEmailForAdministrators → 1 email
       ====================================================== */
    @IsTest
    static void testSendEmail() {

        // Reset admin cache (critical!)
        ERPMessageHandlerOrderItemStage.resetAdminCacheForTest();

        Test.startTest();
            ERPMessageHandlerOrderItemStage.sendEmailForAdministrators('STAGE_XYZ');
            Integer count = Limits.getEmailInvocations();
        Test.stopTest();

        System.assertEquals(1, count, 'Email must be sent exactly once');
    }
}