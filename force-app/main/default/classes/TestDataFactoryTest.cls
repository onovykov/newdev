@IsTest
private class TestDataFactoryTest {

    @IsTest
    static void coverZeroRecords() {
        List<Account> accs = TestDataFactory.createAccounts(0);
        System.assertEquals(0, accs.size());
    }

    @IsTest
    static void coverPositiveRecords() {

        List<Account> accs = TestDataFactory.createAccounts(3);

        System.assertEquals(3, accs.size());

        // Перевіряємо, що записи реально вставлені
        List<Account> fromDb =
            [SELECT Id, Name, Type, MarketSegment__c
             FROM Account
             WHERE Id IN :accs];

        System.assertEquals(3, fromDb.size());

        // Перевіряємо, що поля заповнені
        for (Account a : fromDb) {
            System.assertNotEquals(null, a.Name);
            System.assertEquals('Test', a.Type);
            System.assertEquals('00002', a.MarketSegment__c);
        }
    }

    @IsTest
    static void coverZero() {
        List<Account> accs = TestDataFactory.createAccounts(0);
        System.assertEquals(0, accs.size());
    }

    @IsTest
    static void coverPositive() {
        List<Account> accs = TestDataFactory.createAccounts(3);
        System.assertEquals(3, accs.size());

        List<Account> fromDb = [
            SELECT Id, Name, Type, MarketSegment__c
            FROM Account
            WHERE Id IN :accs
        ];
        System.assertEquals(3, fromDb.size());
    } 

    @IsTest
    static void coverCreateAccounts_basic() {
        List<Account> accs = TestDataFactory.createAccounts(2);
        System.assertEquals(2, accs.size());
        System.assertNotEquals(null, accs[0].Id);
    }    

    @IsTest
    static void coverHelper() {
        System.assertEquals(true, TestDataFactory.isTestFactory());
    }    

    @IsTest
    static void coverPing() {
        System.assertEquals(true, TestDataFactory.coveragePing());
    }    
}