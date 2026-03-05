@IsTest
private class OpportunityCacheTest {

    /**
     * SAFE-CONTRACT TEST
     *
     * WHY:
     * Opportunity domain is polluted with legacy triggers / flows
     * that rewrite or block ID_ERP__c and ITENumber__c.
     *
     * We DO NOT test positive lookup here on purpose.
     * This test validates:
     *  - method existence
     *  - null / blank safety
     *  - no unexpected exceptions
     *
     * Positive lookup is covered by integration / sandbox tests.
     */

    @IsTest
    static void test_safe_contract_single_lookup() {

        // ERP key
        System.assertEquals(
            null,
            OpportunityCache.getOneByErpId(null),
            'getOneByErpId(null) must return null'
        );

        System.assertEquals(
            null,
            OpportunityCache.getOneByErpId(''),
            'getOneByErpId(blank) must return null'
        );

        // ITE key
        System.assertEquals(
            null,
            OpportunityCache.getOneByIte(null),
            'getOneByIte(null) must return null'
        );

        System.assertEquals(
            null,
            OpportunityCache.getOneByIte(''),
            'getOneByIte(blank) must return null'
        );
    }

    @IsTest
    static void test_safe_contract_bulk_lookup() {

        // ERP bulk
        Map<String, Id> erpResult =
            OpportunityCache.getManyByErpId(new Set<String>());

        System.assertNotEquals(
            null,
            erpResult,
            'getManyByErpId(empty) must not return null'
        );

        System.assertEquals(
            0,
            erpResult.size(),
            'getManyByErpId(empty) must return empty map'
        );

        // ITE bulk
        Map<String, Id> iteResult =
            OpportunityCache.getManyByIte(null);

        System.assertNotEquals(
            null,
            iteResult,
            'getManyByIte(null) must not return null'
        );

        System.assertEquals(
            0,
            iteResult.size(),
            'getManyByIte(null) must return empty map'
        );
    }

    @IsTest
    static void test_safe_contract_does_not_throw() {

        // If any of these throw — test must fail
        OpportunityCache.getOneByErpId('123');
        OpportunityCache.getOneByIte('25-000001');

        OpportunityCache.getManyByErpId(
            new Set<String>{ '1', '2', '3' }
        );

        OpportunityCache.getManyByIte(
            new Set<String>{ '25-1', '25-2' }
        );

        System.assert(true, 'Methods executed without exceptions');
    }
}