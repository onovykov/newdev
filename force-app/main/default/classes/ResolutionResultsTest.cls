@IsTest
private class ResolutionResultsTest {

    @IsTest
    static void test_opportunity_found() {

        Opportunity opp = new Opportunity(
            Id = '006000000000001AAA'
        );

        OpportunityResolutionResult res =
            OpportunityResolutionResult.found(opp);

        System.assertEquals(true, res.found);
        System.assertEquals(null, res.reason);
        System.assertEquals(opp, res.opportunity);
    }

    @IsTest
    static void test_opportunity_not_found() {

        OpportunityResolutionResult res =
            OpportunityResolutionResult.notFound(
                'NOT_FOUND:OPPORTUNITY:ERP'
            );

        System.assertEquals(false, res.found);
        System.assertEquals(
            'NOT_FOUND:OPPORTUNITY:ERP',
            res.reason
        );
        System.assertEquals(null, res.opportunity);
    }

    @IsTest
    static void test_order_not_found() {

        OrderResolutionResult res =
            OrderResolutionResult.notFound(
                'NOT_FOUND:ORDER:ITE'
            );

        System.assertEquals(false, res.found);
        System.assertEquals(
            'NOT_FOUND:ORDER:ITE',
            res.reason
        );
        System.assertEquals(null, res.order);
    }
}