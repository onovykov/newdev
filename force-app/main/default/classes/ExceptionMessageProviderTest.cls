@IsTest(SeeAllData=true)
private class ExceptionMessageProviderTest {

    @IsTest
    static void test_getByDeveloperName_found() {
        String msg =
            ExceptionMessageProvider.getByDeveloperName(
                'NOT_FOUND_OPPORTUNITY_ERP'
            );

        System.assertNotEquals(null, msg);
    }

    @IsTest
    static void test_getByDeveloperName_fallback() {

        String msg =
            ExceptionMessageProvider.getByDeveloperName(
                'UNKNOWN_DEV_NAME'
            );

        System.assertEquals(
            'UNKNOWN_DEV_NAME',
            msg,
            'Fallback must return dev name'
        );
    }

    @IsTest
    static void test_getByHandlerAndCode_fallback() {

        String msg =
            ExceptionMessageProvider.getByHandlerAndCode(
                'UNKNOWN_HANDLER',
                'UNKNOWN_CODE'
            );

        System.assertEquals(
            'UNKNOWN_HANDLER:UNKNOWN_CODE',
            msg
        );
    }

    @IsTest
    static void test_build_without_value_flag_false() {

        String msg =
            ExceptionMessageProvider.buildByDeveloperName(
                'NOT_FOUND_OPPORTUNITY_ERP',
                '12345',
                false
            );

        System.assert(
            !msg.contains('12345'),
            'Value must NOT be appended when withValue=false'
        );
    }

    @IsTest
    static void test_build_with_value_flag_true() {

        String msg =
            ExceptionMessageProvider.buildByDeveloperName(
                'NOT_FOUND_OPPORTUNITY_ERP',
                '12345',
                true
            );

        System.assert(
            msg.contains('12345'),
            'Value must be appended when withValue=true'
        );
    }

    @IsTest
    static void test_build_blank_value() {

        String msg =
            ExceptionMessageProvider.buildByDeveloperName(
                'NOT_FOUND_OPPORTUNITY_ERP',
                '',
                true
            );

        System.assert(
            !msg.contains('='),
            'Blank value must not append "="'
        );
    }

    @IsTest
    static void test_build_null_base() {

        String msg =
            ExceptionMessageProvider.buildByDeveloperName(
                'UNKNOWN_DEV_NAME',
                '123',
                true
            );

        // UNKNOWN_DEV_NAME повертається як base,
        // тому null не буде.
        System.assertNotEquals(null, msg);
    }
}