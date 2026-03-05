@IsTest
private class IntegrationResultTest {
    @IsTest
    static void test_success() {
        IntegrationResult r = IntegrationResult.success();
        System.assertEquals(true, r.success);
    }

    @IsTest
    static void test_fail() {
        IntegrationResult r = IntegrationResult.fail('ERR');
        System.assertEquals(false, r.success);
        System.assertEquals('ERR', r.message);
    }
}
