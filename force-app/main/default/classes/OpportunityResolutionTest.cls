@IsTest
private class OpportunityResolutionTest {

    private static Opportunity createOpportunity() {

        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Opportunity opp = new Opportunity(
            Name        = 'Test Opportunity',
            StageName   = 'Prospecting',
            CloseDate   = Date.today().addDays(10),
            AccountId   = acc.Id
        );
        insert opp;

        return opp;
    }

    @IsTest
    static void test_found_resolution() {

        Opportunity opp = createOpportunity();

        OpportunityResolution res =
            OpportunityResolution.found(opp);

        // базовий клас
        System.assertEquals(true, res.found);
        System.assertEquals(null, res.reason);

        // конкретний клас
        System.assertNotEquals(null, res.opportunity);
        System.assertEquals(opp.Id, res.opportunity.Id);
    }

    @IsTest
    static void test_not_found_resolution() {

        String reason = 'Opportunity not found';

        OpportunityResolution res =
            OpportunityResolution.notFound(reason);

        System.assertEquals(false, res.found);
        System.assertEquals(reason, res.reason);
        System.assertEquals(null, res.opportunity);
    }

    @IsTest
    static void test_polymorphic_access() {

        IntegrationResolution base =
            OpportunityResolution.notFound('ERR');

        System.assertEquals(false, base.found);
        System.assertEquals('ERR', base.reason);
    }
}