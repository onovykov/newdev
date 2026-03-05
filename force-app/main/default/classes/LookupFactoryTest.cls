@IsTest
private class LookupFactoryTest {

    @IsTest
    static void test_accountLookupFactory() {

        AccountLookup lookup = LookupFactory.account();

        System.assertNotEquals(null, lookup);
        System.assert(lookup instanceof AccountLookupImpl);

    }

    @IsTest
    static void test_opportunityLookupFactory() {

        OpportunityLookup lookup = LookupFactory.opportunity();

        System.assertNotEquals(null, lookup);
        System.assert(lookup instanceof OpportunityLookupImpl);

    }

    @IsTest
    static void test_orderLookupFactory() {

        OrderLookup lookup = LookupFactory.order();

        System.assertNotEquals(null, lookup);
        System.assert(lookup instanceof OrderLookupImpl);

    }

}