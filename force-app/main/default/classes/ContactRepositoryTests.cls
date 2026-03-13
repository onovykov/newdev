@IsTest
private class ContactRepositoryTests {

    @TestSetup
    static void setup() {
        // Створюємо тестові дані
        Account acc = new Account(Name = 'Test Acc');
        insert acc;

        // ВИПРАВЛЕНО: Використовуємо 'IT-Admin' замість Billing/Technical
        Contact c1 = new Contact(
                LastName = 'Jones',
                AccountId = acc.Id,
                Email = 'jones@test.com',
                Type__c = 'IT-Admin', // Реальне значення з вашого скріншоту
                HasOptedOutOfEmail = false
        );
        Contact c2 = new Contact(
                LastName = 'Smith',
                AccountId = acc.Id,
                Email = 'smith@test.com',
                Type__c = 'IT-Admin',
                HasOptedOutOfEmail = true
        );
        insert new List<Contact>{ c1, c2 };
    }

    private static void setSoqlFallback(Boolean allowed) {
        // Переконайтеся, що об'єкт Notification_Settings__c існує
        Notification_Settings__c settings = Notification_Settings__c.getOrgDefaults();
        settings.AllowSoqlFallback__c = allowed;
        upsert settings;
    }

    @IsTest
    static void testGetByAccountAndType_WithSoql() {
        setSoqlFallback(true);
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        // Шукаємо за реальним типом
        List<Contact> results = ContactRepository.getByAccountAndType(acc.Id, 'IT-Admin');
        Test.stopTest();

        // Має знайти тільки Jones, бо у Smith стоїть HasOptedOutOfEmail = true
        System.assertEquals(1, results.size(), 'Має бути знайдено 1 контакт типу IT-Admin');
        System.assertEquals('jones@test.com', results[0].Email);
    }

    @IsTest
    static void testPrimeByAccountIds() {
        setSoqlFallback(true);
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        ContactRepository.primeByAccountIds(new Set<Id>{acc.Id}, 'IT-Admin');

        setSoqlFallback(false);
        List<Contact> results = ContactRepository.getByAccountAndType(acc.Id, 'IT-Admin');
        Test.stopTest();

        System.assertEquals(1, results.size());
    }

    @IsTest
    static void testGetById() {
        setSoqlFallback(true);
        Contact c = [SELECT Id FROM Contact WHERE Email = 'jones@test.com' LIMIT 1];

        Test.startTest();
        Contact result = ContactRepository.getById(c.Id);
        Test.stopTest();

        System.assertEquals(c.Id, result.Id);
    }

    @IsTest
    static void testGetByEmail() {
        setSoqlFallback(true);

        Test.startTest();
        Contact result = ContactRepository.getByEmail('jones@test.com');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Контакт має бути знайдений');
        System.assertEquals('jones@test.com', result.Email);
    }

    @IsTest
    static void testPutManual() {
        // Для методу put ми можемо використовувати будь-який рядок для Type__c,
        // якщо не робимо реальний insert в базу, бо логіка в пам'яті не валідує піклісти
        Contact c = new Contact(LastName = 'Manual', Email = 'm@t.com', Type__c = 'AnyType');

        ContactRepository.put(c);
        Contact cached = ContactRepository.getByEmail('m@t.com');
        System.assertEquals('Manual', cached.LastName);
    }
}