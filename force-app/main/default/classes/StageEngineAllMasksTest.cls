@IsTest
private class StageEngineAllMasksTest {

    private static final List<String> STAGES = new List<String>{
        'Drafting',
        'Hold',
        'Placed',
        'Closed',
        'Cancelled'
    };

    @IsTest
    static void testAll32Masks() {

        StageEngine.reset();
        OrderStageMetadataCache.reset();
        StageEngine engine = StageEngine.get();

        for (Integer mask = 0; mask < 32; mask++) {

            List<String> stages = new List<String>();

            for (Integer i = 0; i < STAGES.size(); i++) {
                if ((mask & (1 << i)) != 0) {
                    stages.add(STAGES[i]);
                }
            }

            String orderStage =
                OrderStageProvider.resolveFromItemStages(stages);

            System.assertNotEquals(
                null,
                orderStage,
                'Mask ' + mask + ' returned null'
            );
        }
    }
}