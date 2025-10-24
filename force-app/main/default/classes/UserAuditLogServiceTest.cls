@isTest
public class UserAuditLogServiceTest {
    @isTest
    static void testInsertLogs() {
        // Створюємо тестового користувача (неактивного, щоб не викликати помилок логіну)
        User testUser = new User(
            Username = 'testuser-' + Datetime.now().getTime() + '@example.com',
            LastName = 'Test',
            Email = 'testuser@example.com',
            Alias = 'tuser',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            TimeZoneSidKey = 'Europe/Kiev',
            LocaleSidKey = 'uk_UA',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'uk',
            IsActive = true
        );
        insert testUser;

        // Готуємо запис для логування
        List<UserAuditLog__c> logList = new List<UserAuditLog__c>{
            new UserAuditLog__c(
                User__c = testUser.Id,
                ChangedBy__c = UserInfo.getUserId(),
                OldStatus__c = 'true',
                NewStatus__c = 'false',
                ChangeDate__c = System.now()
            )
        };

        // Серіалізуємо у JSON
        String jsonLogs = JSON.serialize(logList);

        Test.startTest();
        UserAuditLogService.insertLogs(jsonLogs); // це @future виклик
        Test.stopTest();

        // Перевірка — чи створено запис у базі
        List<UserAuditLog__c> insertedLogs = [
            SELECT Id, User__c, OldStatus__c, NewStatus__c 
            FROM UserAuditLog__c 
            WHERE User__c = :testUser.Id
        ];

        System.assertEquals(1, insertedLogs.size(), 'Повинен бути один запис у логах');
        System.assertEquals('true', insertedLogs[0].OldStatus__c);
        System.assertEquals('false', insertedLogs[0].NewStatus__c);
    }
}