@IsTest
private class OrderLookupImplTest {

    @IsTest
    static void test_find_by_erp_and_ite() {

        // Вимикаємо важкі тригери
        TriggerControl.disable('OpportunityLineItemHandler');

        Account acc = new Account(
            Name = 'Acc',
            ID_ERP__c = 'A2'
        );
        insert acc;

        Order ord = new Order(
            AccountId = acc.Id,
            Status = 'Draft',
            EffectiveDate = Date.today(),
            ID_ERP__c = 'ERP-ORD',
            ITENumber__c = '25-000010'
        );
        insert ord;

        // стабілізуємо поле після insert
        ord.ID_ERP__c = 'ERP-ORD';
        update ord;

        Test.startTest();

        OrderLookup lookup = new OrderLookupImpl();

        Id byErp = lookup.findByErp('ERP-ORD');
        Id byIte = lookup.findByIte('25-000010');

        Test.stopTest();

        System.assertEquals(ord.Id, byErp);
        System.assertEquals(ord.Id, byIte);
    }
}