@IsTest
private class OrderItemLookupImplTest {

    @IsTest
    static void testLookup_basic() {
        TriggerControl.disable(OrderItemHandler.class);

        // 1. Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // 2. Standard Pricebook
        Id pbId = Test.getStandardPricebookId();

        // 3. Product
        Product2 p = new Product2(
            Name = 'Test Product',
            IsActive = true
        );
        insert p;

        // 4. PricebookEntry (ОБОВʼЯЗКОВО!)
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = pbId,
            Product2Id = p.Id,
            UnitPrice = 0,
            IsActive = true
        );
        insert pbe;

        // 5. Order
        Order o = new Order(
            Name = 'Test Order',
            AccountId = acc.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            Pricebook2Id = pbId,
            CurrencyIsoCode = 'USD',
            MarketSegment__c = '00002'
        );
        insert o;

        // 6. OrderItem (ТЕПЕР ВСЕ ОК)
        OrderItem oi = new OrderItem(
            OrderId = o.Id,
            Quantity = 1,
            UnitPrice = 0,
            PricebookEntryId = pbe.Id,
            ITENumber__c = 'ITE-001'
        );
        insert oi;

        OrderItemLookup lookup = new OrderItemLookupImpl();

        Test.startTest();
        Id idResult = lookup.findByIte('ITE-001');
        OrderItem entity = lookup.findEntityByIte('ITE-001');
        Test.stopTest();

        System.assertEquals(oi.Id, idResult);
        System.assertEquals(oi.Id, entity.Id);
    }
}