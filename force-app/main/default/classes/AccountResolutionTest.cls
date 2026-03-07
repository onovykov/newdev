@IsTest
private class AccountResolutionTest {

    @IsTest
    static void test_found_resolution() {

        Account acc = new Account(Name = 'Test Account');
        insert acc;

        AccountResolution res = AccountResolution.found(acc);

        // Перевірка базового класу
        System.assertEquals(true, res.found);
        System.assertEquals(null, res.reason);

        // Перевірка дочірнього класу
        System.assertNotEquals(null, res.account);
        System.assertEquals(acc.Id, res.account.Id);
    }

    @IsTest
    static void test_not_found_resolution() {

        String reason = 'Account not found by ERP ID';

        AccountResolution res =
            AccountResolution.notFound(reason);

        // Перевірка базового класу
        System.assertEquals(false, res.found);
        System.assertEquals(reason, res.reason);

        // Перевірка дочірнього класу
        System.assertEquals(null, res.account);
		
		// Перевірка полімофізму
		IntegrationResolution base =
			AccountResolution.notFound('X');

		System.assertEquals(false, base.found);
		System.assertEquals('X', base.reason);		
    }
}