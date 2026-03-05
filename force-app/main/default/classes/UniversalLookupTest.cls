@IsTest
private class UniversalLookupTest {

    @IsTest
    static void test_all_lookups() {

        // відключаємо legacy trigger hell
        TriggerControl.disable('OpportunityLineItemHandler');

        /*
         * ACCOUNT
         */
        Account acc = new Account(
            Name = 'Lookup Test Account',
            ID_ERP__c = 'ACC-ERP-1'
        );
        insert acc;

        acc.ID_ERP__c = 'ACC-ERP-1';
        update acc;

        /*
         * OPPORTUNITY
         */
        Opportunity opp = new Opportunity(
            Name = 'Lookup Test Opp',
            StageName = 'Qualification',
            CloseDate = Date.today().addDays(10),
            AccountId = acc.Id,
            ID_ERP__c = 'OPP-ERP-1',
            ITENumber__c = '25-000001'
        );
        insert opp;

        opp.ID_ERP__c = 'OPP-ERP-1';
        update opp;

        /*
         * ORDER
         */
        Order ord = new Order(
            AccountId = acc.Id,
            OpportunityId = opp.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            ID_ERP__c = 'ORD-ERP-1',
            ITENumber__c = '25-000010'
        );
        insert ord;

        ord.ID_ERP__c = 'ORD-ERP-1';
        update ord;

        Test.startTest();

        /*
         * ACCOUNT LOOKUP
         */
        AccountLookup accLookup = new AccountLookupImpl();

        System.assertEquals(
            acc.Id,
            accLookup.findByErp('ACC-ERP-1')
        );

        /*
         * OPPORTUNITY LOOKUP
         */
        OpportunityLookup oppLookup = new OpportunityLookupImpl();

        System.assertEquals(
            opp.Id,
            oppLookup.findByErp('OPP-ERP-1')
        );

        System.assertEquals(
            opp.Id,
            oppLookup.findByIte('25-000001')
        );

        /*
         * ORDER LOOKUP
         */
        OrderLookup ordLookup = new OrderLookupImpl();

        System.assertEquals(
            ord.Id,
            ordLookup.findByErp('ORD-ERP-1')
        );

        System.assertEquals(
            ord.Id,
            ordLookup.findByIte('25-000010')
        );

        Test.stopTest();
    }
}