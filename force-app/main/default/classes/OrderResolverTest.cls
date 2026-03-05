@IsTest
private class OrderResolverTest {

    private class OrderLookupStub implements OrderLookup {

        public Id findByIte(String ite) {
            if (ite == '25-ORDER-FOUND') {
                return '801000000000001AAA';
            }
            return null;
        }

        public Id findByErp(String erpId) {
            if (erpId == '98765') {
                return '801000000000001AAA';
            }
            return null;
        }
    }

    @IsTest
    static void test_resolve_by_ite_found() {

        OrderResolver.lookup = new OrderLookupStub();

        ERPMessageParser.ErpToSfMessage_OpportunityData msg =
            new ERPMessageParser.ErpToSfMessage_OpportunityData();

        msg.data = new ERPMessageParser.OrderMessageData();
        msg.data.header = new ERPMessageParser.ERPObject_OrderHeader();
        msg.data.header.iteNumber = '25-ORDER-FOUND';
        msg.data.header.unDoc = 111;

        OrderResolutionResult res = OrderResolver.resolve(msg);

        System.assertEquals(true, res.found);
        System.assertNotEquals(null, res.order);
    }

    @IsTest
    static void test_resolve_by_erp_fallback() {

        OrderResolver.lookup = new OrderLookupStub();

        ERPMessageParser.ErpToSfMessage_OpportunityData msg =
            new ERPMessageParser.ErpToSfMessage_OpportunityData();

        msg.data = new ERPMessageParser.OrderMessageData();
        msg.data.header = new ERPMessageParser.ERPObject_OrderHeader();
        msg.data.header.iteNumber = 'NOT_FOUND';
        msg.data.header.unDoc = 98765;

        OrderResolutionResult res = OrderResolver.resolve(msg);

        System.assertEquals(true, res.found);
    }

    @IsTest
    static void test_resolve_not_found() {

        OrderResolver.lookup = new OrderLookupStub();

        ERPMessageParser.ErpToSfMessage_OpportunityData msg =
            new ERPMessageParser.ErpToSfMessage_OpportunityData();

        msg.data = new ERPMessageParser.OrderMessageData();
        msg.data.header = new ERPMessageParser.ERPObject_OrderHeader();
        msg.data.header.iteNumber = 'X';
        msg.data.header.unDoc = 123;

        OrderResolutionResult res = OrderResolver.resolve(msg);

        System.assertEquals(false, res.found);
        System.assertNotEquals(null, res.reason);
    }
}