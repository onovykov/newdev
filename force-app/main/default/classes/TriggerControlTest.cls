@IsTest
private class TriggerControlTest {

    private class DummyHandler {}

    @IsTest
    static void testDisableEnableByString() {

        // Act
        TriggerControl.disable('DummyHandler');

        // Assert
        System.assertEquals(true, TriggerControl.isDisabled('DummyHandler'));

        // Act
        TriggerControl.enable('DummyHandler');

        // Assert
        System.assertEquals(false, TriggerControl.isDisabled('DummyHandler'));
    }

    @IsTest
    static void testDisableEnableByType() {

        // Act
        TriggerControl.disable(DummyHandler.class);

        // Assert
        System.assertEquals(true, TriggerControl.isDisabled(DummyHandler.class));

        // Act
        TriggerControl.enable(DummyHandler.class);

        // Assert
        System.assertEquals(false, TriggerControl.isDisabled(DummyHandler.class));
    }

    @IsTest
    static void testReset() {

        // Arrange
        TriggerControl.disable('A');
        TriggerControl.disable('B');

        // Act
        TriggerControl.reset();

        // Assert
        System.assertEquals(false, TriggerControl.isDisabled('A'));
        System.assertEquals(false, TriggerControl.isDisabled('B'));
    }

    @IsTest
    static void testMultipleHandlers() {

        // Arrange
        TriggerControl.disable('Handler1');
        TriggerControl.disable('Handler2');

        // Assert
        System.assertEquals(true, TriggerControl.isDisabled('Handler1'));
        System.assertEquals(true, TriggerControl.isDisabled('Handler2'));

        // Act
        TriggerControl.enable('Handler1');

        // Assert
        System.assertEquals(false, TriggerControl.isDisabled('Handler1'));
        System.assertEquals(true, TriggerControl.isDisabled('Handler2'));
    }

    @IsTest
    static void testIdempotentDisable() {

        // Act
        TriggerControl.disable('HandlerX');
        TriggerControl.disable('HandlerX');

        // Assert
        System.assertEquals(true, TriggerControl.isDisabled('HandlerX'));
    }
}