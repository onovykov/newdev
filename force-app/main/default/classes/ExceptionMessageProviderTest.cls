@IsTest(SeeAllData=true)
private class ExceptionMessageProviderTest {

    @IsTest
    static void test_getByDeveloperName() {
        String msg = ExceptionMessageProvider.getByDeveloperName(
            'NOT_FOUND_OPPORTUNITY_ERP'
        );

        System.assertNotEquals(
            null,
            msg,
            'Message must be resolved from CMDT'
        );
    }

    @IsTest
    static void test_buildMessage() {
        String msg = ExceptionMessageProvider.buildByDeveloperName(
            'NOT_FOUND_OPPORTUNITY_ERP',
            '12345',false
        );

        System.assert(
            msg.contains('12345'),
            'Message must contain value'
        );
    }
}