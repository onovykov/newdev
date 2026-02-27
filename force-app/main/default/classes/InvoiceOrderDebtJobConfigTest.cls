@IsTest
private class InvoiceOrderDebtJobConfigTest {

    @IsTest
    static void testValidValues() {
        List<ERPMessageParser.InvoiceOrderDebtMessageData> src =
            new List<ERPMessageParser.InvoiceOrderDebtMessageData>();

        InvoiceOrderDebtJobConfig cfg = new InvoiceOrderDebtJobConfig(src, 'myOrigin', 2, 5);

        System.assertEquals(src,        cfg.source);
        System.assertEquals('myOrigin', cfg.origin);
        System.assertEquals(2,          cfg.retry);
        System.assertEquals(5,          cfg.retryMax);
    }

    @IsTest
    static void testNullOrigin_becomesUnknown() {
        InvoiceOrderDebtJobConfig cfg = new InvoiceOrderDebtJobConfig(null, null, 0, 6);
        System.assertEquals('unknown', cfg.origin);
    }

    @IsTest
    static void testBlankOrigin_becomesUnknown() {
        InvoiceOrderDebtJobConfig cfg = new InvoiceOrderDebtJobConfig(null, '   ', 0, 6);
        System.assertEquals('unknown', cfg.origin);
    }

    @IsTest
    static void testNullRetry_becomesZero() {
        InvoiceOrderDebtJobConfig cfg = new InvoiceOrderDebtJobConfig(null, 'x', null, 6);
        System.assertEquals(0, cfg.retry);
    }

    @IsTest
    static void testNullRetryMax_becomesSix() {
        InvoiceOrderDebtJobConfig cfg = new InvoiceOrderDebtJobConfig(null, 'x', 0, null);
        System.assertEquals(6, cfg.retryMax);
    }
}