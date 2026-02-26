@IsTest
private class UserIdErpQueueableTest {

    @IsTest
    static void testUserIdErpCreatedViaQueueable() {
        // ---------- Arrange ----------
        Profile p = [
            SELECT Id
            FROM Profile
            WHERE Name = 'Standard User'
            LIMIT 1
        ];

        User u = new User(
            FirstName = 'Test',
            LastName  = 'User',
            Email     = 'test.user+' + System.currentTimeMillis() + '@example.com',
            Username  = 'test.user+' + System.currentTimeMillis() + '@example.com',
            Alias     = 'tuser',
            TimeZoneSidKey = 'Europe/Warsaw',
            LocaleSidKey   = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id,

            // поля, які тригер обробляє
            ID_ERP__c    = 'ERP_ID_001',
            LoginERP__c = 'LOGIN_001',
            UID_ERP__c  = 'ERP_UID_001'
        );

        // ---------- Act ----------
        Test.startTest();
        insert u;
        Test.stopTest(); // <-- тут виконується Queueable

        // ---------- Assert ----------
        List<UserID_ERP__c> records = [
            SELECT Id, User__c, Name
            FROM UserID_ERP__c
            WHERE User__c = :u.Id
        ];

        System.assertEquals(
            3,
            records.size(),
            'Повинно бути створено 3 записи UserID_ERP__c'
        );

        Set<String> values = new Set<String>();
        for (UserID_ERP__c rec : records) {
            values.add(rec.Name);
        }

        System.assert(values.contains('ERP_ID_001'));
        System.assert(values.contains('LOGIN_001'));
        System.assert(values.contains('ERP_UID_001'));
    }
}