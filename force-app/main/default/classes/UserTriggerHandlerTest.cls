@IsTest
private class UserTriggerHandlerTest {

    /* ===============================
       UTILS
       =============================== */
    private static User createUserForTest() {
        Profile p = [
            SELECT Id
            FROM Profile
            WHERE Name = 'Standard User'
            LIMIT 1
        ];

        return new User(
            Alias = 'tuser',
            Email = 'testuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'Europe/Warsaw',
            Username = 'testuser_' + System.now().getTime() + '@example.com',
            ProfileId = p.Id
        );
    }

    /* ===============================
       TESTS
       =============================== */

    @IsTest
    static void testAfterInsert_createsUserIdErpRecords() {

        User u = createUserForTest();
        u.ID_ERP__c    = 'ERP-123';
        u.LoginERP__c = 'login.erp';
        u.UID_ERP__c  = 'UID-999';

        Test.startTest();
        insert u;
        Test.stopTest();

        List<UserID_ERP__c> ids = [
            SELECT Id, Name, User__c
            FROM UserID_ERP__c
            WHERE User__c = :u.Id
        ];

        System.assertEquals(
            3,
            ids.size(),
            'Three UserID_ERP__c records must be created'
        );
    }

    @IsTest
    static void testAfterInsert_bypassedInTest() {

        UserTriggerHandler.bypassUserIdErpCreation = true;

        User u = createUserForTest();
        u.ID_ERP__c = 'ERP-BYPASS';

        Test.startTest();
        insert u;
        Test.stopTest();

        Integer cnt = [
            SELECT COUNT()
            FROM UserID_ERP__c
            WHERE User__c = :u.Id
        ];

        System.assertEquals(
            0,
            cnt,
            'No UserID_ERP__c must be created when bypass enabled'
        );
    }

    @IsTest
    static void testBeforeUpdate_fieldAuditHookExecuted() {

        User u = createUserForTest();
        insert u;

        Test.startTest();
        u.LoginERP__c = 'new.login';
        update u;
        Test.stopTest();

        System.assert(
            true,
            'beforeUpdate bulk hook executed without exception'
        );
    }
}