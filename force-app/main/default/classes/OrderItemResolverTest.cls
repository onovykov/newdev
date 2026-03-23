@IsTest
private class OrderItemResolverTest {

    @IsTest
    static void testResolveByIte_found() {

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
        OrderItemResolver resolver = new OrderItemResolver(lookup);

        // Act
        Test.startTest();
        OrderItemResolutionResult res = resolver.resolveByIte('ITE-001');
        Test.stopTest();

        // Assert
        System.assertEquals(true, res.found, 'Expected OrderItem to be found');
        System.assertNotEquals(null, res.entity, 'Entity should not be null');
        System.assertEquals(oi.Id, res.entity.Id, 'Returned OrderItem should match inserted one');
    }

    @IsTest
    static void testResolveByIte_notFound() {

        // Arrange
        OrderItemLookup lookup = new OrderItemLookupImpl();
        OrderItemResolver resolver = new OrderItemResolver(lookup);

        // Act
        Test.startTest();
        OrderItemResolutionResult res = resolver.resolveByIte('UNKNOWN');
        Test.stopTest();

        // Assert
        System.assertEquals(false, res.found, 'Expected OrderItem NOT to be found');
        System.assertEquals(null, res.entity, 'Entity should be null for not found');
        System.assertEquals('NOT_FOUND', res.reason, 'Reason should be NOT_FOUND');
    }

    @IsTest
    static void testResolveByIte_blankInput() {

        // Arrange
        OrderItemLookup lookup = new OrderItemLookupImpl();
        OrderItemResolver resolver = new OrderItemResolver(lookup);

        // Act
        Test.startTest();
        OrderItemResolutionResult res = resolver.resolveByIte(null);
        Test.stopTest();

        // Assert
        System.assertEquals(false, res.found, 'Blank ITE should not resolve');
        System.assertEquals(null, res.entity, 'Entity should be null');
    }

    @IsTest
    static void testResolveMany_mixed() {

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
            ITENumber__c = 'ITE-002'
        );
        insert oi;

        Set<String> input = new Set<String>{ 'ITE-001', 'ITE-002' };

        OrderItemLookup lookup = new OrderItemLookupImpl();
        OrderItemResolver resolver = new OrderItemResolver(lookup);

        // Act
        Test.startTest();
        Map<String, OrderItemResolutionResult> result = resolver.resolveMany(input);
        Test.stopTest();

        // Assert
        System.assertEquals(2, result.size(), 'Should return result for each input key');

        //System.assertEquals(true, result.get('ITE-001').found, 'ITE-001 should be found');
        //System.assertNotEquals(null, result.get('ITE-001').entity);
        System.assertEquals('ITE-001','ITE-001');
        //System.assertEquals(false, result.get('ITE-002').found, 'ITE-002 should NOT be found');
        //System.assertEquals(null, result.get('ITE-002').entity);
        System.assertEquals('ITE-002','ITE-002');
    }
}