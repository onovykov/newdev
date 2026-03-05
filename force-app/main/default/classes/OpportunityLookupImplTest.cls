@IsTest
private class OpportunityLookupImplTest {

    @IsTest
    static void test_find_by_erp_and_ite() {
        //--- Вимикаємо той прибацаний тригер
        TriggerControl.disable('OpportunityLineItemHandler');
        
        Account acc = new Account(
            Name='Acc',
            ID_ERP__c='A1'
        );
        insert acc;

        Opportunity opp = new Opportunity(
            Name='Opp',
            StageName='Qualification',
            CloseDate=Date.today().addDays(10),
            AccountId=acc.Id,
            ID_ERP__c='ERP-OPP',
            ITENumber__c='25-000001'
        );
        insert opp;

        opp.ID_ERP__c = 'ERP-OPP';
        update opp;

        Test.startTest();

        OpportunityLookup lookup = new OpportunityLookupImpl();

        Id byErp = lookup.findByErp('ERP-OPP');
        Id byIte = lookup.findByIte('25-000001');

        Test.stopTest();

        System.assertEquals(opp.Id, byErp);
        System.assertEquals(opp.Id, byIte);
        //System.assertEquals(0, 0);
        //System.assertEquals(1, 1);        
    }
}