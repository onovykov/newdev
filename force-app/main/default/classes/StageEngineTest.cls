@IsTest
private class StageEngineTest {

    @IsTest
    static void testBuildMask() {

        StageEngine.reset();

        StageEngine engine = StageEngine.get();

        List<String> stages = new List<String>{
            'Closed',
            'Cancelled'
        };

        Integer mask = engine.buildMask(stages);

        System.assert(mask > 0);
    }

    @IsTest
    static void testResolveOrderStage() {

        StageEngine.reset();

        StageEngine engine = StageEngine.get();

        List<String> stages = new List<String>{
            'Closed',
            'Cancelled'
        };

        Integer mask = engine.buildMask(stages);

        String orderStage = engine.resolveOrderStage(mask);

        System.assertEquals('Refused', orderStage);
    }

    @IsTest
    static void testSingleton() {

        StageEngine.reset();

        StageEngine e1 = StageEngine.get();
        StageEngine e2 = StageEngine.get();

        System.assertEquals(e1, e2);
    }
}