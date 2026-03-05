@IsTest
private class IntegrationContextTest {
    @IsTest
    static void test_errors_and_results() {
        IntegrationContext ctx = new IntegrationContext();
        ctx.putResult('k', 'v');
        System.assertEquals('v', ctx.getResult('k'));

        ctx.addError('ERR');
        System.assert(ctx.hasErrors());
        System.assertEquals(true, ctx.stopProcessing);
        System.assertEquals('ERR', ctx.getErrorsAsString());

        List<String> copy = ctx.getErrors();
        copy.add('HACK');
        System.assertEquals(1, ctx.getErrors().size());
    }

    @IsTest
    static void test_direction_constants() {
        System.assertEquals('ERP_SF', IntegrationDirection.ERP_SF);
        System.assertEquals('SF_ERP', IntegrationDirection.SF_ERP);
    }
}
