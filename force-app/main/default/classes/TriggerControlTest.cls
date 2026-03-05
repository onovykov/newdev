@IsTest
private class TriggerControlTest {

    private class DummyHandler {}

    @IsTest
    static void test_disable_enable_by_name() {

        TriggerControl.reset();

        System.assertEquals(
            false,
            TriggerControl.isDisabled('DummyHandler')
        );

        TriggerControl.disable('DummyHandler');

        System.assertEquals(
            true,
            TriggerControl.isDisabled('DummyHandler')
        );

        TriggerControl.enable('DummyHandler');

        System.assertEquals(
            false,
            TriggerControl.isDisabled('DummyHandler')
        );
    }

    @IsTest
    static void test_disable_enable_by_type() {

        TriggerControl.reset();

        System.assertEquals(
            false,
            TriggerControl.isDisabled(DummyHandler.class)
        );

        TriggerControl.disable(DummyHandler.class);

        System.assertEquals(
            true,
            TriggerControl.isDisabled(DummyHandler.class)
        );

        TriggerControl.enable(DummyHandler.class);

        System.assertEquals(
            false,
            TriggerControl.isDisabled(DummyHandler.class)
        );
    }

    @IsTest
    static void test_reset() {

        TriggerControl.disable('TestHandler');

        System.assertEquals(
            true,
            TriggerControl.isDisabled('TestHandler')
        );

        TriggerControl.reset();

        System.assertEquals(
            false,
            TriggerControl.isDisabled('TestHandler')
        );
    }

}