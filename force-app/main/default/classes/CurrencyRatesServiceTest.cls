@IsTest(SeeAllData=true)
private class CurrencyRatesServiceTest {

    // Лічильники викликів
    private static Integer nbuCalls        = 0;
    private static Integer patchCtSession  = 0;
    private static Integer patchCtNc       = 0;
    private static Integer postDcrSession  = 0;
    private static Integer patchDcrSession = 0;
    private static Integer postDcrNc       = 0;
    private static Integer patchDcrNc      = 0;

    // Мок HTTP для нормального сценарію
    private class RouterMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            String ep = req.getEndpoint();

            // 1) НБУ
            if (ep != null && ep.startsWith('https://bank.gov.ua')) {
                CurrencyRatesServiceTest.nbuCalls++;
                res.setStatusCode(200);
                // USD (corporate) + EUR
                res.setBody('[{"r030":840,"txt":"US Dollar","rate":41.3722,"cc":"USD","exchangedate":"03.09.2025"},' +
                            ' {"r030":978,"txt":"Euro","rate":45.0000,"cc":"EUR","exchangedate":"03.09.2025"}]');
                return res;
            }

            Boolean isNC = (ep != null && ep.startsWith('callout:Interpipe_Self_Org'));
            Boolean isSF = (ep != null && !ep.startsWith('callout:') && ep.contains('/services/data/'));

            // 2) CurrencyType (PATCH)
            if (ep != null && ep.contains('/sobjects/CurrencyType/')) {
                if (isNC) CurrencyRatesServiceTest.patchCtNc++;
                if (isSF) CurrencyRatesServiceTest.patchCtSession++;
                res.setStatusCode(204); // No Content
                res.setBody('');
                return res;
            }

            // 3) DatedConversionRate (POST / PATCH)
            if (ep != null && ep.endsWith('/sobjects/DatedConversionRate')) {
                if (isNC) CurrencyRatesServiceTest.postDcrNc++;
                if (isSF) CurrencyRatesServiceTest.postDcrSession++;
                res.setStatusCode(201);
                res.setBody('{"id":"a01XXXXXXXXXXXX"}');
                return res;
            }
            if (ep != null && ep.contains('/sobjects/DatedConversionRate/')) {
                if (isNC) CurrencyRatesServiceTest.patchDcrNc++;
                if (isSF) CurrencyRatesServiceTest.patchDcrSession++;
                res.setStatusCode(204);
                res.setBody('');
                return res;
            }

            // дефолт
            res.setStatusCode(200);
            res.setBody('{}');
            return res;
        }
    }

    // Мок HTTP для помилки з боку НБУ (щоб покрити гілку non-200 у getNBURates)
    private class BankErrorMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            String ep = req.getEndpoint();
            if (ep != null && ep.startsWith('https://bank.gov.ua')) {
                res.setStatusCode(500);
                res.setBody('Internal Error');
                return res;
            }
            res.setStatusCode(200);
            res.setBody('{}');
            return res;
        }
    }

    @IsTest
    static void test_GetNBURates_and_Apply_CT_Session() {
        resetCounters();
        Test.setMock(HttpCalloutMock.class, new RouterMock());

        Test.startTest();
        // 1) Отримати курси з НБУ
        List<CurrencyRatesService.RatesPayload> pl = CurrencyRatesService.getNBURates();
        System.assert(pl != null && !pl.isEmpty(), 'NBURates should not be empty');

        // 2) Пишемо в CurrencyType через SessionId
        CurrencyRatesService.applyRatesViaSessionIdToCurrencyType(pl);
        Test.stopTest();

        System.assert(nbuCalls > 0, 'Expected NBU call');
        System.assert(patchCtSession > 0 || patchCtNc > 0,
            'Expected at least one CurrencyType PATCH via Session or NC');
    }

    @IsTest
    static void test_Auto_And_DCR_Branches_And_Previews() {
        resetCounters();
        Test.setMock(HttpCalloutMock.class, new RouterMock());

        List<CurrencyRatesService.RatesPayload> pl = CurrencyRatesService.getNBURates();

        Test.startTest();
        // Авто-гілка (піде в CT або DCR, залежно від ACM/прав)
        CurrencyRatesService.applyRates(pl);

        // Примусово в DCR через SessionId
        CurrencyRatesService.applyRatesViaSessionIdToDCR(pl);

        // Хелпери перегляду/перевірки
        CurrencyRatesService.previewDcrHumanEffective(Date.today(), 5);
        CurrencyRatesService.verifyLastRun(Date.today());
        Test.stopTest();

        System.assert(nbuCalls > 0, 'Expected at least one NBU call');
        // DCR виклики можуть бути 0, якщо активна лише corporate — це норм.
    }

    // 🔹 Чистий сценарій без Named Credential — лише SessionId-виклики
    @IsTest
    static void test_SessionOnly_NoNC() {
        resetCounters();
        Test.setMock(HttpCalloutMock.class, new RouterMock());

        Test.startTest();
        List<CurrencyRatesService.RatesPayload> pl = CurrencyRatesService.getNBURates();

        // Запис лише через SessionId-шлях
        CurrencyRatesService.applyRatesViaSessionIdToCurrencyType(pl);
        CurrencyRatesService.applyRatesViaSessionIdToDCR(pl);
        Test.stopTest();

        // Очікуємо, що були session-виклики...
        System.assert(patchCtSession > 0 || postDcrSession > 0 || patchDcrSession > 0,
            'Expected at least one SessionId callout (CT or DCR)');

        // ...і що НЕ було жодного виклику через NC
        System.assertEquals(0, patchCtNc, 'NC (CT) should not be called');
        System.assertEquals(0, postDcrNc, 'NC (DCR POST) should not be called');
        System.assertEquals(0, patchDcrNc, 'NC (DCR PATCH) should not be called');
    }

    // 🔹 НОВЕ: авто-сесійний шлях + exact-date прев’ю + покриття порожніх/нульових прев’ю
    @IsTest
    static void test_ApplySessionAuto_And_PreviewsExactAndEmpty() {
        resetCounters();
        Test.setMock(HttpCalloutMock.class, new RouterMock());

        List<CurrencyRatesService.RatesPayload> pl = CurrencyRatesService.getNBURates();

        Test.startTest();
        // Авто-сесійний шлях
        CurrencyRatesService.applyRatesViaSessionId(pl);

        // Exact-date прев’ю (може нічого не показати, але лінії покриє)
        CurrencyRatesService.previewDcrHuman(Date.today(), 10);

        // Покриття ранніх return у logPreview
        CurrencyRatesService.logPreview(null, 10);
        CurrencyRatesService.logPreview(new List<CurrencyRatesService.RatesPayload>(), 10);

        // Також викличемо "exact-date" читання списком (без логів)
        List<CurrencyRatesService.RatesPayload> dcrExact =
            CurrencyRatesService.getOrgRatesFromDcr(Date.today());
        Test.stopTest();

        System.assert(nbuCalls > 0, 'Expected NBU call');
        System.assertNotEquals(null, dcrExact, 'List should not be null');
    }

    // 🔹 НОВЕ: покриваємо гілку помилки (non-200) у getNBURates()
    @IsTest
    static void test_NBU_ErrorBranch() {
        Test.setMock(HttpCalloutMock.class, new BankErrorMock());
        Boolean thrown = false;
        try {
            CurrencyRatesService.getNBURates();
        } catch (Exception e) {
            thrown = true;
            System.assert(e.getMessage().contains('NBU API error'), 'Expected NBU API error branch');
        }
        System.assert(thrown, 'Expected exception for non-200 NBU response');
    }

    // Допоміжне
    private static void resetCounters() {
        nbuCalls = 0;
        patchCtSession = 0;
        patchCtNc = 0;
        postDcrSession = 0;
        patchDcrSession = 0;
        postDcrNc = 0;
        patchDcrNc = 0;
    }
}