@IsTest
private class AccountCacheTest {

    @TestSetup
    static void setup() {
        insert new Account(
            Name = 'T-Acc',
            ID_ERP__c = 'ERP-ACC-001'
        );
    }

    @IsTest
    static void test_getByExternalId() {
        Account a = [
            SELECT Id, ID_ERP__c
            FROM Account
            WHERE ID_ERP__c = 'ERP-ACC-001'
            LIMIT 1
        ];

        Id id = AccountCache.getOne(a.ID_ERP__c);
        System.assertEquals(a.Id, id);
    }
}