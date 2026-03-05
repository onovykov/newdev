@IsTest
private class OpportunityResolverTest {

    private class OpportunityLookupStub
        implements OpportunityLookup {

        public Id findByIte(String ite) {
            if (ite == '25-FOUND') {
                return '006000000000001AAA';
            }
            return null;
        }

        public Id findByErp(String erpId) {
            if (erpId == '12345') {
                return '006000000000001AAA';
            }
            return null;
        }
    }

    @IsTest
    static void test_resolve_by_ite_found() {

        OpportunityResolver.lookup = new OpportunityLookupStub();

        ERPMessageParser.ErpToSfMessage_OpportunityData msg =
            new ERPMessageParser.ErpToSfMessage_OpportunityData();

        msg.data = new ERPMessageParser.OrderMessageData();
        msg.data.header = new ERPMessageParser.ERPObject_OrderHeader();
        msg.data.header.iteNumber = '25-FOUND';
        msg.data.header.unDoc = 999;

        OpportunityResolutionResult res =
            OpportunityResolver.resolve(msg);

        System.assertEquals(true, res.found);
        System.assertNotEquals(null, res.opportunity);
    }

    @IsTest
    static void test_resolve_by_erp_fallback() {

        OpportunityResolver.lookup = new OpportunityLookupStub();

        ERPMessageParser.ErpToSfMessage_OpportunityData msg =
            new ERPMessageParser.ErpToSfMessage_OpportunityData();

        msg.data = new ERPMessageParser.OrderMessageData();
        msg.data.header = new ERPMessageParser.ERPObject_OrderHeader();
        msg.data.header.iteNumber = 'NOT_FOUND';
        msg.data.header.unDoc = 12345;

        OpportunityResolutionResult res =
            OpportunityResolver.resolve(msg);

        System.assertEquals(true, res.found);
    }

    @IsTest
    static void test_resolve_not_found() {

        OpportunityResolver.lookup = new OpportunityLookupStub();

        ERPMessageParser.ErpToSfMessage_OpportunityData msg =
            new ERPMessageParser.ErpToSfMessage_OpportunityData();

        msg.data = new ERPMessageParser.OrderMessageData();
        msg.data.header = new ERPMessageParser.ERPObject_OrderHeader();
        msg.data.header.iteNumber = 'X';
        msg.data.header.unDoc = 111;

        OpportunityResolutionResult res =
            OpportunityResolver.resolve(msg);

        System.assertEquals(false, res.found);
        System.assertNotEquals(null, res.reason);
    }
}