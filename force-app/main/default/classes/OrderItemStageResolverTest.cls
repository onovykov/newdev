@IsTest
private class OrderItemStageResolverTest {

    @IsTest
    static void testResolveKnownStage() {

        String stage =
            OrderItemStageResolver.resolve('_45');

        System.assertNotEquals(null, stage);
    }

    @IsTest
    static void testResolveOrThrow() {

        Test.startTest();

        Boolean thrown = false;

        try {

            OrderItemStageResolver.resolveOrThrow('_UNKNOWN');

        } catch (ERPStageMappingException e) {

            thrown = true;
        }

        Test.stopTest();

        System.assertEquals(true, thrown);
    }

}