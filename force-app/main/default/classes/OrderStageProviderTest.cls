@IsTest
private class OrderStageProviderTest {

    private static void resetEngine() {
        StageEngine.reset();
    }

    @IsTest
    static void testDraft() {

        resetEngine();

        List<String> stages = new List<String>{'Drafting'};

        String result =
            OrderStageProvider.resolveFromItemStages(stages);

        System.assertEquals('Draft', result);
    }

    @IsTest
    static void testProgress() {

        resetEngine();

        List<String> stages = new List<String>{'Hold'};

        String result =
            OrderStageProvider.resolveFromItemStages(stages);

        System.assertEquals('Progress', result);
    }

    @IsTest
    static void testActive() {

        resetEngine();

        List<String> stages = new List<String>{'Placed'};

        String result =
            OrderStageProvider.resolveFromItemStages(stages);

        System.assertEquals('Active', result);
    }

    @IsTest
    static void testClosed() {

        resetEngine();

        List<String> stages = new List<String>{'Closed'};

        String result =
            OrderStageProvider.resolveFromItemStages(stages);

        System.assertEquals('Closed', result);
    }

    @IsTest
    static void testFreezed() {

        resetEngine();

        List<String> stages = new List<String>{'Cancelled'};

        String result =
            OrderStageProvider.resolveFromItemStages(stages);

        System.assertEquals('Freezed', result);
    }

    @IsTest
    static void testRefusedClosedCancelled() {

        resetEngine();

        List<String> stages =
            new List<String>{'Closed','Cancelled'};

        String result =
            OrderStageProvider.resolveFromItemStages(stages);

        System.assertEquals('Refused', result);
    }

    @IsTest
    static void testDraftDraftingCancelled() {

        resetEngine();

        List<String> stages =
            new List<String>{'Drafting','Cancelled'};

        String result =
            OrderStageProvider.resolveFromItemStages(stages);

        System.assertEquals('Draft', result);
    }

}