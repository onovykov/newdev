@IsTest
private class IntegrationResolutionTest {

    /**
     * Test-only stub for abstract IntegrationResolution
     */
    private class IntegrationResolutionStub
        extends IntegrationResolution {

        public IntegrationResolutionStub(Boolean found, String reason) {
            super(found, reason);
        }
    }

    @IsTest
    static void test_found_true() {

        IntegrationResolution res =
            new IntegrationResolutionStub(true, null);

        System.assertEquals(
            true,
            res.found,
            'found must be true'
        );

        System.assertEquals(
            null,
            res.reason,
            'reason must be null when found'
        );
    }

    @IsTest
    static void test_found_false_with_reason() {

        IntegrationResolution res =
            new IntegrationResolutionStub(false, 'ERR_CODE');

        System.assertEquals(
            false,
            res.found,
            'found must be false'
        );

        System.assertEquals(
            'ERR_CODE',
            res.reason,
            'reason must be preserved'
        );
    }
}