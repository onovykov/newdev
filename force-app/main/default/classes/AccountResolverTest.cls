@IsTest
private class AccountResolverTest {

    @IsTest
    static void test_resolve_by_erp_id_found() {
        Account acc = new Account(
            Name = 'Test Account',
            ID_ERP__c = 'ERP-1'
        );
        insert acc;

        AccountResolution res =
            AccountResolver.resolveByErpId('ERP-1');

        System.assert(res.found);
        System.assertEquals(acc.Id, res.account.Id);
    }

    @IsTest
    static void test_resolve_by_erp_id_not_found() {
        AccountResolution res =
            AccountResolver.resolveByErpId('NOPE');

        System.assert(!res.found);
    }
}
