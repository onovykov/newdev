@IsTest
private class OrderStageMetadataCacheTest {

    @IsTest
    static void testStageBitsLoad() {

        OrderStageMetadataCache.reset();

        Map<String,Integer> bits =
            OrderStageMetadataCache.getStageBits();

        System.assertNotEquals(null, bits);
        System.assert(bits.size() > 0);
    }

    @IsTest
    static void testMaskRulesLoad() {

        OrderStageMetadataCache.reset();

        String[] rules =
            OrderStageMetadataCache.getMaskRules();

        System.assertNotEquals(null, rules);
        System.assertEquals(32, rules.size());
    }

    @IsTest
    static void testCacheReuse() {

        OrderStageMetadataCache.reset();

        Map<String,Integer> a =
            OrderStageMetadataCache.getStageBits();

        Map<String,Integer> b =
            OrderStageMetadataCache.getStageBits();

        System.assertEquals(a, b);
    }
}