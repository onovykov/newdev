// file: classes/CurrencyRatesDashboardCtrlTest.cls
@IsTest(SeeAllData=true)
private class CurrencyRatesDashboardCtrlTest {

    // Mock all callouts: NBU + REST back to SF
    private class RouterMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            String ep = req.getEndpoint();

            // NBU API
            if (ep != null && ep.startsWith('https://bank.gov.ua')) {
                res.setStatusCode(200);
                res.setBody('[{"r030":840,"txt":"US Dollar","rate":41.3722,"cc":"USD","exchangedate":"03.09.2025"},' +
                            ' {"r030":978,"txt":"Euro","rate":45.0000,"cc":"EUR","exchangedate":"03.09.2025"}]');
                return res;
            }
            // CurrencyType PATCH
            if (ep != null && ep.contains('/sobjects/CurrencyType/')) {
                res.setStatusCode(204); res.setBody(''); return res;
            }
            // DCR POST
            if (ep != null && ep.endsWith('/sobjects/DatedConversionRate')) {
                res.setStatusCode(201); res.setBody('{"id":"a01XXXXXXXXXXXX"}'); return res;
            }
            // DCR PATCH
            if (ep != null && ep.contains('/sobjects/DatedConversionRate/')) {
                res.setStatusCode(204); res.setBody(''); return res;
            }
            res.setStatusCode(200); res.setBody('{}'); return res;
        }
    }

    @IsTest static void testGetRates() {
        List<String> ex = new List<String>{'BYN','RUB'};
        CurrencyRatesDashboardCtrl.Resp r = CurrencyRatesDashboardCtrl.getRates(ex);
        System.assertNotEquals(null, r);
        System.assertNotEquals(null, r.corporateIso);
        System.assertNotEquals(null, r.rows);
        System.assertNotEquals(null, r.generatedAt);
    }

    @IsTest static void testRefreshFromNbu() {
        Test.setMock(HttpCalloutMock.class, new RouterMock());
        List<String> ex = new List<String>{'BYN','RUB'};
        Test.startTest();
        CurrencyRatesDashboardCtrl.Resp r = CurrencyRatesDashboardCtrl.refreshFromNbu(true, true, ex);
        Test.stopTest();
        System.assertNotEquals(null, r);
        System.assertNotEquals(null, r.rows);
    }
}