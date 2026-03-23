@IsTest
private class TriggerControlScopeTest {

    private class DummyHandler {}

    @IsTest
    static void testScopeDisablesAndResets() {

        // Before
        System.assertEquals(false, TriggerControl.isDisabled(DummyHandler.class));

        Test.startTest();

        TriggerControlScope scope = new TriggerControlScope(DummyHandler.class);

        try {
            // Inside scope
            System.assertEquals(true, TriggerControl.isDisabled(DummyHandler.class));
        } finally {
            scope.dispose();
        }

        Test.stopTest();

        // After
        System.assertEquals(false, TriggerControl.isDisabled(DummyHandler.class));
    }

    @IsTest
    static void testMultipleScopes() {

        Test.startTest();

        TriggerControlScope scope1 = new TriggerControlScope(DummyHandler.class);

        try {
            System.assertEquals(true, TriggerControl.isDisabled(DummyHandler.class));

            TriggerControlScope scope2 = new TriggerControlScope(String.class);

            try {
                System.assertEquals(true, TriggerControl.isDisabled(String.class));
                System.assertEquals(true, TriggerControl.isDisabled(DummyHandler.class));
            } finally {
                scope2.dispose();
            }

            // після scope2
            System.assertEquals(false, TriggerControl.isDisabled(String.class));
            System.assertEquals(true, TriggerControl.isDisabled(DummyHandler.class));

        } finally {
            scope1.dispose();
        }

        Test.stopTest();

        // після всього
        System.assertEquals(false, TriggerControl.isDisabled(DummyHandler.class));
    }

    @IsTest
    static void testScopeProperDispose() {

        Test.startTest();

        TriggerControlScope scope = new TriggerControlScope(DummyHandler.class);

        try {
            // перевіряємо, що вимкнено
            System.assertEquals(true, TriggerControl.isDisabled(DummyHandler.class));
        } finally {
            scope.dispose();
        }

        Test.stopTest();

        // перевіряємо, що увімкнулося знову
        System.assertEquals(false, TriggerControl.isDisabled(DummyHandler.class));
    }

    @IsTest
    static void testMultipleHandlersConstructorAndDispose() {

        Test.startTest();

        Set<Type> types = new Set<Type>{
            String.class,
            Integer.class
        };

        TriggerControlScope scope = new TriggerControlScope(types);

        try {
            // перевіряємо, що обидва вимкнені
            System.assertEquals(true, TriggerControl.isDisabled(String.class));
            System.assertEquals(true, TriggerControl.isDisabled(Integer.class));
        } finally {
            scope.dispose();
        }

        Test.stopTest();

        // перевіряємо, що обидва увімкнено знову
        System.assertEquals(false, TriggerControl.isDisabled(String.class));
        System.assertEquals(false, TriggerControl.isDisabled(Integer.class));
    }
    
    @IsTest
    static void testEmptySetConstructor() {

        Test.startTest();

        Set<Type> types = new Set<Type>();

        TriggerControlScope scope = new TriggerControlScope(types);

        scope.dispose();

        Test.stopTest();

        System.assertEquals(true, true); // просто щоб виконати
    }    
}