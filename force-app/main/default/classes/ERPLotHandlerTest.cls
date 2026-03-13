@IsTest(SeeAllData=true)
public class ERPLotHandlerTest {

    // ---------------------------
    // Test Data helpers
    // ---------------------------

    private static Pricebook2 ensureStdPricebookActive() {
        Id stdId = Test.getStandardPricebookId();
        Pricebook2 pb = [SELECT Id, IsActive FROM Pricebook2 WHERE Id = :stdId LIMIT 1];
        if (!pb.IsActive) {
            pb.IsActive = true;
            update pb;
        }
        return pb;
    }

    /**
     * Creates minimal Opportunity + OLI, then updates underlying OrderItem.ITENumber__c
     * so OrderItemPlatformCache.getMany(Set<String>) can resolve by ITE number.
     */
    private static OrderItem createOrderItemByIte(String iteNumber) {

        // Account
        Account acc = new Account(Name = 'Test Acc ' + iteNumber);
        insert acc;

        // Standard Pricebook
        Id stdPbId = Test.getStandardPricebookId();

        // Order (ВАЖЛИВО: з Pricebook2Id)
        Order ord = new Order(
            Name = 'Test Order ' + iteNumber,
            AccountId = acc.Id,
            Status = 'Draft',
            EffectiveDate = Date.today(),
            Pricebook2Id = stdPbId
        );
        insert ord;

        // Product
        Product2 p = new Product2(
            Name = 'Test Product ' + iteNumber,
            IsActive = true
        );
        insert p;

        // PricebookEntry
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = stdPbId,
            Product2Id   = p.Id,
            UnitPrice    = 100,
            IsActive     = true
        );
        insert pbe;

        // OrderItem (КЛЮЧОВЕ!)
        OrderItem oi = new OrderItem(
            OrderId = ord.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 100,
            ITENumber__c = iteNumber
        );
        insert oi;

        return oi;
    }

    private static ERPMessageParser.ErpToSfMessage_OpportunityData buildParsedOneItem(
        String iteNumber,
        List<Map<String, String>> lotsRows
    ) {
        ERPMessageParser.ErpToSfMessage_OpportunityData msg =
            new ERPMessageParser.ErpToSfMessage_OpportunityData();

        msg.data = new ERPMessageParser.OrderMessageData();

        ERPMessageParser.ERPObject_OrderItem item = new ERPMessageParser.ERPObject_OrderItem();
        item.iteNumber = iteNumber;
        item.lots = new List<ERPMessageParser.ERPObject_ProductLot>();

        for (Map<String, String> r : lotsRows) {
            ERPMessageParser.ERPObject_ProductLot lot = new ERPMessageParser.ERPObject_ProductLot();
            lot.lotDate     = r.get('LotDate');     // "YYYY-MM-DDTHH:MM:SS"
            lot.produced    = r.get('Produced');    // String
            lot.dispatched  = r.get('Dispatched');  // String
            lot.shipped     = r.get('Shipped');     // String
            item.lots.add(lot);
        }

        msg.data.items = new ERPMessageParser.ERPObject_OrderItem[] { item };
        return msg;
    }

    // ---------------------------
    // Tests
    // ---------------------------

    @IsTest
    static void test_getLotList_buildsThreeLotsAndKeys() {
        String ite = '25-007717-TEST-001';
        OrderItem oi = createOrderItemByIte(ite);

        Date d1 = Date.today();
        Date d2 = Date.today().addDays(7);
        Date d3 = Date.today().addDays(14);

        ERPMessageParser.ErpToSfMessage_OpportunityData parsed = buildParsedOneItem(
            ite,
            new List<Map<String, String>>{
                new Map<String, String>{
                    'LotDate'    => String.valueOf(d1) + 'T00:00:00',
                    'Produced'   => '6.84',
                    'Dispatched' => '0',
                    'Shipped'    => '0'
                },
                new Map<String, String>{
                    'LotDate'    => String.valueOf(d2) + 'T00:00:00',
                    'Produced'   => '0',
                    'Dispatched' => '6.84',
                    'Shipped'    => '0'
                },
                new Map<String, String>{
                    'LotDate'    => String.valueOf(d3) + 'T00:00:00',
                    'Produced'   => '0',
                    'Dispatched' => '0',
                    'Shipped'    => '6.84'
                }
            }
        );

        Test.startTest();
        List<Lot__c> lots = ERPLotHandler.getLotList(parsed);
        Test.stopTest();

        System.assertNotEquals(null, lots, 'Expected not-null lots list');
        System.assertEquals(3, lots.size(), 'Expected 3 lots (Produced/Shipped/Delivered)');

        Set<String> types = new Set<String>();
        for (Lot__c l : lots) {
            types.add(l.LotType__c);

            System.assertEquals(oi.Id, l.OrderItem__c, 'OrderItem__c must point to resolved OrderItem');
            System.assertNotEquals(null, l.LotDate__c, 'LotDate__c must be set');
            System.assertNotEquals(null, l.ProdWeek__c, 'ProdWeek__c must be resolved via DTUtils.getPWeekByDate');
            System.assertNotEquals(null, l.ExtKey__c, 'ExtKey__c must be generated');
            System.assert(l.ExtKey__c.contains(String.valueOf(oi.Id) + '#'), 'ExtKey__c must start with OrderItemId#');
        }

        System.assertEquals(
            new Set<String>{ 'Produced', 'Shipped', 'Delivered' },
            types,
            'Expected Produced + Shipped (from Dispatched) + Delivered (from Shipped)'
        );
    }

    @IsTest
    static void test_aggregation_sumsAndUsesMaxDate() {
        String ite = '25-007717-TEST-002';
        createOrderItemByIte(ite);

        Date earlier = Date.today();
        Date later   = Date.today().addDays(7);

        ERPMessageParser.ErpToSfMessage_OpportunityData parsed = buildParsedOneItem(
            ite,
            new List<Map<String, String>>{
                new Map<String, String>{
                    'LotDate'    => String.valueOf(earlier) + 'T00:00:00',
                    'Produced'   => '1.11',
                    'Dispatched' => '0',
                    'Shipped'    => '0'
                },
                new Map<String, String>{
                    'LotDate'    => String.valueOf(later) + 'T00:00:00',
                    'Produced'   => '2.22',
                    'Dispatched' => '0',
                    'Shipped'    => '0'
                }
            }
        );

        List<Lot__c> lots = ERPLotHandler.getLotList(parsed);

        System.assertEquals(1, lots.size(), 'Expected only 1 Produced lot');
        System.assertEquals('Produced', lots[0].LotType__c);
        System.assertEquals(3.33, lots[0].LotQty_t__c, 'Expected summed qty with scale=2');
        System.assertEquals(later, lots[0].LotDate__c, 'Expected max produced date to be used');
    }

    @IsTest
    static void test_invalidDecimals_doNotCreateLots() {
        String ite = '25-007717-TEST-003';
        createOrderItemByIte(ite);

        Date d1 = Date.today();

        ERPMessageParser.ErpToSfMessage_OpportunityData parsed = buildParsedOneItem(
            ite,
            new List<Map<String, String>>{
                new Map<String, String>{
                    'LotDate'    => String.valueOf(d1) + 'T00:00:00',
                    'Produced'   => 'abc', // invalid -> parseDecimal() -> 0
                    'Dispatched' => '0',
                    'Shipped'    => '0'
                }
            }
        );

        List<Lot__c> lots = ERPLotHandler.getLotList(parsed);
        System.assertEquals(0, lots.size(), 'Invalid decimal should result in no lots created');
    }

    @IsTest
    static void test_fillAggregateLots_dryRun_noThrow() {
        // smoke: just ensure it doesn't throw on dryRun / null
        Test.startTest();
        ERPLotHandler.fillAggregateLots(null, true);
        Test.stopTest();
        System.assert(true, 'Should not throw on null input');
    }
}