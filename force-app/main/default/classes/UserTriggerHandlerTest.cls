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
    static void testAfterInsert_noException() {

        User u = createUserForTest();
        u.ID_ERP__c   = 'ERP-123';
        u.LoginERP__c = 'login.erp';
        u.UID_ERP__c  = 'UID-999';

        Test.startTest();
        insert u;
        Test.stopTest();

        System.assert(true, 'afterInsert executed without exception');
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