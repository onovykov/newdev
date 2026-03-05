@IsTest(SeeAllData=true)
private class IntegrationOrchestratorTest {

    @IsTest
    static void test_happy_path() {

        IntegrationResult r = IntegrationOrchestrator.process(
            'TEST_DUMMY',
            IntegrationDirection.ERP_SF,
            '{}'
        );

        System.assert(
            r.success,
            'IntegrationOrchestrator must resolve TEST_DUMMY route'
        );
    }

    @IsTest
    static void test_no_route() {

        IntegrationResult r = IntegrationOrchestrator.process(
            'NO_SUCH_MESSAGE',
            IntegrationDirection.ERP_SF,
            '{}'
        );

        System.assertEquals(
            false,
            r.success,
            'IntegrationOrchestrator must fail when route is missing'
        );
    }
}