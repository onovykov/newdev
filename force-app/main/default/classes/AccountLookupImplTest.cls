@IsTest
private class AccountLookupImplTest {
    @IsTest
    static void test_findByErp() {

        Account a = new Account(
            Name = 'Test Account ERP',
            ID_ERP__c = 'ERP-ACC-001'
        );

        insert a;

        Test.startTest();

        AccountLookup lookup = new AccountLookupImpl();

        Id foundId = lookup.findByErp('ERP-ACC-001');

        Test.stopTest();

        System.assertEquals(a.Id, foundId);
    }

    @IsTest
    static void test_notFound() {

        AccountLookup lookup = new AccountLookupImpl();

        Id found = lookup.findByErp('UNKNOWN');

        System.assertEquals(null, found);
    }

}