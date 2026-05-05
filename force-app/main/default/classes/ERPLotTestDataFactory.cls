@IsTest
public class ERPLotTestDataFactory {

    public static final String ITE_1 = '24-007149-001';
    public static final String ITE_2 = '24-007149-002';

    public class DataBundle {
        public Account acc;
        public Product2 product;
        public PricebookEntry pbe;
        public Order ord;
        public OrderItem oi1;
        public OrderItem oi2;
        public ProdWeeksH__c julyWeek;
        public ProdWeeksH__c augustWeek;
    }

    public static DataBundle createBaseData() {
        DataBundle b = new DataBundle();

        b.acc = new Account(Name = 'ERPLot Test Account');
        insert b.acc;

        b.product = new Product2(
            Name = 'ERPLot Test Product',
            IsActive = true
        );
        insert b.product;

        Pricebook2 pb = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update pb;

        b.pbe = new PricebookEntry(
            Pricebook2Id = pb.Id,
            Product2Id = b.product.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert b.pbe;

        b.ord = new Order(
            AccountId = b.acc.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            Pricebook2Id = pb.Id
        );
        insert b.ord;

        b.oi1 = new OrderItem(
            OrderId = b.ord.Id,
            PricebookEntryId = b.pbe.Id,
            Quantity = 1,
            UnitPrice = 100,
            ITENumber__c = ITE_1
        );

        b.oi2 = new OrderItem(
            OrderId = b.ord.Id,
            PricebookEntryId = b.pbe.Id,
            Quantity = 1,
            UnitPrice = 100,
            ITENumber__c = ITE_2
        );

        insert new List<OrderItem>{ b.oi1, b.oi2 };

        b.julyWeek = new ProdWeeksH__c(
            DateFrom__c = Date.newInstance(2024, 7, 22),
            DateTo__c = Date.newInstance(2024, 7, 28),
            Month__c = '7',
            Year__c = 2024,
            WeekNum__c = 4
        );

        b.augustWeek = new ProdWeeksH__c(
            DateFrom__c = Date.newInstance(2024, 8, 5),
            DateTo__c = Date.newInstance(2024, 8, 11),
            Month__c = '8',
            Year__c = 2024,
            WeekNum__c = 2
        );

        insert new List<ProdWeeksH__c>{ b.julyWeek, b.augustWeek };

        ProdWeekCache.reset();

        return b;
    }

    public static ERPMessageParser.ErpToSfMessage_OpportunityData buildMainParsedMessage() {
        ERPMessageParser.ErpToSfMessage_OpportunityData parsed =
            new ERPMessageParser.ErpToSfMessage_OpportunityData();

        parsed.data = new ERPMessageParser.OrderMessageData();
        parsed.data.items = new List<ERPMessageParser.ERPObject_OrderItem>();

        ERPMessageParser.ERPObject_OrderItem item =
            new ERPMessageParser.ERPObject_OrderItem();

        item.iteNumber = ITE_1;
        item.lots = new List<ERPMessageParser.ERPObject_ProductLot>{
            buildLot('2024-07-25T00:00:00', '60.210', '40.140', '0.0'),
            buildLot('2024-07-26T00:00:00', '40.140', '60.210', '0.0'),
            buildLot('2024-08-05T00:00:00', '0.0', '0.0', '40.140'),
            buildLot('2024-08-06T00:00:00', '0.0', '0.0', '60.210')
        };

        parsed.data.items.add(item);
        return parsed;
    }

    public static ERPMessageParser.ErpToSfMessage_OpportunityData buildSingleItemMessage(
        String iteNumber,
        List<ERPMessageParser.ERPObject_ProductLot> lots
    ) {
        ERPMessageParser.ErpToSfMessage_OpportunityData parsed =
            new ERPMessageParser.ErpToSfMessage_OpportunityData();

        parsed.data = new ERPMessageParser.OrderMessageData();
        parsed.data.items = new List<ERPMessageParser.ERPObject_OrderItem>();

        ERPMessageParser.ERPObject_OrderItem item =
            new ERPMessageParser.ERPObject_OrderItem();

        item.iteNumber = iteNumber;
        item.lots = lots;

        parsed.data.items.add(item);
        return parsed;
    }

    public static ERPMessageParser.ERPObject_ProductLot buildLot(
        String lotDate,
        String produced,
        String dispatched,
        String shipped
    ) {
        ERPMessageParser.ERPObject_ProductLot lot =
            new ERPMessageParser.ERPObject_ProductLot();

        lot.lotDate = lotDate;
        lot.produced = produced;
        lot.dispatched = dispatched;
        lot.shipped = shipped;

        return lot;
    }
}