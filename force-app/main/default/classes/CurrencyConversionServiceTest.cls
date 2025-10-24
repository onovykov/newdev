@IsTest
private class CurrencyConversionServiceTest {

    // Фейковий провайдер курсів для тестів (без DatedConversionRate)
    // УВАГА: значення у table зберігаємо як ISO/CORP (наприклад, якщо CORP = USD:
    // GBP/USD = 0.800000000, EUR/USD = 0.909090909)
    private class FakeRatesProvider implements CurrencyConversionService.RatesProvider {
        public Integer calls = 0; // лічильник звернень (перевірка кешу)
        private Map<String, Decimal> table; // ISO/CORP
        private String corpIso;

        public FakeRatesProvider(String corpIso, Map<String, Decimal> table) {
            this.corpIso = corpIso;
            this.table = new Map<String, Decimal>(table);
        }

        // Повертаємо "курс до корпоративної валюти"? Наш сервіс очікує значення, сумісні з його формулою.
        // Оскільки сервіс рахує cross = toToCorp / fromToCorp, а ми зберігаємо ISO/CORP,
        // то просто віддаємо table.get(iso) як ISO/CORP — і все буде коректно.
        public Decimal getToCorporateRate(String iso, Date onDate) {
            calls++;
            String k = iso.toUpperCase();
            if (!table.containsKey(k)) {
                throw new CurrencyConversionService.CurrencyConversionException('No rate for ' + k);
            }
            return table.get(k); // ISO/CORP
        }

        public String getCorporateIso() {
            return corpIso;
        }
    }

    @IsTest
    static void testConvert_GbpToEur_withCrossRate_andRounding() {
        // CORP = USD
        // Використовуємо ISO/CORP:
        // GBP/USD = 0.800000000; EUR/USD = 0.909090909
        // Тоді GBP→EUR = (EUR/USD) / (GBP/USD) = 0.909090909 / 0.800000000 = 1.136363636
        Map<String, Decimal> rates = new Map<String, Decimal>{
            'GBP' => 0.800000000,
            'EUR' => 0.909090909
        };
        FakeRatesProvider fake = new FakeRatesProvider('USD', rates);
        CurrencyConversionService.setRatesProvider(fake);

        Date d = Date.newInstance(2025, 10, 16);
        Decimal amountGbp = 75;
        Decimal amountEur = CurrencyConversionService.convert(amountGbp, 'GBP', 'EUR', d);

        // 75 * 1.136363636... = 85.22727... → 85.23
        System.assertEquals(85.23, amountEur, 'Converted amount should be rounded to 2 decimals');

        Decimal cross = CurrencyConversionService.getCrossRate('GBP', 'EUR', d);
        System.assertEquals(1.136363636, cross.setScale(9), 'Cross rate should match (EUR/USD)/(GBP/USD)');

        Integer callsAfterFirst = fake.calls; // має бути 2 (GBP та EUR)
        Decimal amountEur2 = CurrencyConversionService.convert(amountGbp, 'GBP', 'EUR', d);
        System.assertEquals(85.23, amountEur2);
        System.assertEquals(callsAfterFirst, fake.calls,
            'Rates should be served from cache on repeated same-day requests');
    }

    @IsTest
    static void testConvert_SameCurrency_returnsAmount() {
        Map<String, Decimal> rates = new Map<String, Decimal>{
            'USD' => 1.00000 // ISO/CORP для USD/USD
        };
        FakeRatesProvider fake = new FakeRatesProvider('USD', rates);
        CurrencyConversionService.setRatesProvider(fake);

        Decimal res = CurrencyConversionService.convert(100, 'EUR', 'EUR', Date.today());
        System.assertEquals(100.00, res);
        System.assertEquals(0, fake.calls, 'Same ISO should not query rates');
    }

    @IsTest
    static void testConvert_ThrowsWhenNoRate() {
        Map<String, Decimal> rates = new Map<String, Decimal>{
            'EUR' => 0.909090909 // тільки EUR, без GBP
        };
        FakeRatesProvider fake = new FakeRatesProvider('USD', rates);
        CurrencyConversionService.setRatesProvider(fake);

        try {
            CurrencyConversionService.convert(10, 'GBP', 'EUR', Date.today());
            System.assert(false, 'Expected exception due to missing GBP rate');
        } catch (CurrencyConversionService.CurrencyConversionException ex) {
            System.assert(ex.getMessage().contains('No rate'), 'Should indicate missing rate');
        }
    }

    @IsTest
    static void testCrossRate_IdentityIsOne() {
        Map<String, Decimal> rates = new Map<String, Decimal>{
            'USD' => 1.00000
        };
        FakeRatesProvider fake = new FakeRatesProvider('USD', rates);
        CurrencyConversionService.setRatesProvider(fake);

        Decimal r = CurrencyConversionService.getCrossRate('USD', 'USD', Date.today());
        System.assertEquals(1, r);
        System.assertEquals(0, fake.calls);
    }

    @IsTest
    static void testConvert_NullAmount_ReturnsNull() {
        Map<String, Decimal> rates = new Map<String, Decimal>{ 'USD' => 1 };
        CurrencyConversionService.setRatesProvider(new FakeRatesProvider('USD', rates));

        Decimal res = CurrencyConversionService.convert(null, 'USD', 'USD', Date.today());
        System.assertEquals(null, res, 'Null amount should return null');
    }

    @IsTest
    static void testConvert_BlankFromIso_Throws() {
        Map<String, Decimal> rates = new Map<String, Decimal>{ 'USD' => 1 };
        CurrencyConversionService.setRatesProvider(new FakeRatesProvider('USD', rates));
        try {
            CurrencyConversionService.convert(10, '', 'USD', Date.today());
            System.assert(false, 'Expected exception for blank fromIso');
        } catch (CurrencyConversionService.CurrencyConversionException e) {
            System.assert(e.getMessage().contains('ISO codes'), 'Message should mention ISO codes');
        }
    }

    @IsTest
    static void testConvert_BlankToIso_Throws() {
        Map<String, Decimal> rates = new Map<String, Decimal>{ 'USD' => 1 };
        CurrencyConversionService.setRatesProvider(new FakeRatesProvider('USD', rates));
        try {
            CurrencyConversionService.convert(10, 'USD', null, Date.today());
            System.assert(false, 'Expected exception for blank toIso');
        } catch (CurrencyConversionService.CurrencyConversionException e) {
            System.assert(e.getMessage().contains('ISO codes'), 'Message should mention ISO codes');
        }
    }

    @IsTest
    static void testGetCrossRate_OnDateNull_UsesTodayAndCaches() {
        // ISO/CORP
        // GBP/USD = 0.800000000; EUR/USD = 0.909090909 → GBP→EUR = 1.136363636
        Map<String, Decimal> rates = new Map<String, Decimal>{ 'GBP' => 0.800000000, 'EUR' => 0.909090909 };
        FakeRatesProvider fake = new FakeRatesProvider('USD', rates);
        CurrencyConversionService.setRatesProvider(fake);

        Decimal cross1 = CurrencyConversionService.getCrossRate('GBP', 'EUR', null);
        System.assertEquals( (0.909090909/0.800000000).setScale(9), cross1.setScale(9) );
        Integer callsAfterFirst = fake.calls;
        System.assertEquals(2, callsAfterFirst, 'Should load two rates on first call');

        Decimal cross2 = CurrencyConversionService.getCrossRate('GBP', 'EUR', null);
        System.assertEquals(cross1.setScale(9), cross2.setScale(9));
        System.assertEquals(callsAfterFirst, fake.calls, 'Second call same day should be served from cache');
    }

    @IsTest
    static void testCaching_ByDifferentDates_MissesCache() {
        // Значення ISO/CORP довільні, нам важлива поведінка кешу
        Map<String, Decimal> rates = new Map<String, Decimal>{ 'JPY' => 150.00000, 'EUR' => 0.909090909 };
        CurrencyConversionServiceTest.FakeRatesProvider fake = new CurrencyConversionServiceTest.FakeRatesProvider('USD', rates);
        CurrencyConversionService.setRatesProvider(fake);

        Date d1 = Date.newInstance(2025, 10, 16);
        Date d2 = d1.addDays(1); // інша дата → інший ключ кешу

        Decimal r1 = CurrencyConversionService.getCrossRate('JPY', 'EUR', d1);
        Integer callsAfterD1 = fake.calls;  // очікуємо 2 (JPY і EUR на d1)
        System.assertEquals(2, callsAfterD1, 'First date should load two rates into cache');

        Decimal r2 = CurrencyConversionService.getCrossRate('JPY', 'EUR', d2);
        System.assertEquals(4, fake.calls,
            'Different date should bypass cache (new keys) → total 4 provider calls');

        // Значення можуть співпасти — це ок, нас цікавить саме кеш
        System.assertEquals(r1.setScale(9), r2.setScale(9));

        // Перевіримо, що в кеші тепер 4 записи (2 ISO × 2 дати)
        System.assertEquals(4, CurrencyConversionService.rateCache.size(),
            'Cache should contain two currencies for two dates (4 entries total)');
    } 

    @IsTest
    static void testConvert_SameIso_Rounds() {
        Map<String, Decimal> rates = new Map<String, Decimal>{ 'USD' => 1 };
        CurrencyConversionService.setRatesProvider(new FakeRatesProvider('USD', rates));
        System.assertEquals(12.35, CurrencyConversionService.convert(12.345, 'USD', 'USD', Date.today()));
    }
 
    @IsTest(SeeAllData=true)
    static void test_DefaultProvider_withRealACMData() {
        CurrencyType corpRec = [
            SELECT IsoCode
            FROM CurrencyType
            WHERE IsCorporate = true
            LIMIT 1
        ];
        String corp = corpRec.IsoCode;

        List<DatedConversionRate> dr = [
            SELECT IsoCode, ConversionRate, StartDate
            FROM DatedConversionRate
            WHERE StartDate <= :Date.today()
              AND IsoCode != :corp
            ORDER BY StartDate DESC
            LIMIT 1
        ];
        if (dr.isEmpty()) {
            System.assert(true, 'No non-corporate DatedConversionRate available — skipping execution.');
            return;
        }
        String other = dr[0].IsoCode;

        CurrencyConversionService.setRatesProvider(null);

        Decimal cross = CurrencyConversionService.getCrossRate(other, corp, Date.today());
        System.assert(cross > 0, 'Cross rate should be positive');

        Decimal amt = CurrencyConversionService.convert(10, other, corp, Date.today());
        System.assert(amt > 0, 'Converted amount should be positive');

        Integer cacheSizeAfter = CurrencyConversionService.rateCache.size();
        Decimal cross2 = CurrencyConversionService.getCrossRate(other, corp, Date.today());
        System.assertEquals(cross.setScale(9), cross2.setScale(9), 'Same-date cross must be cached');
        System.assertEquals(cacheSizeAfter, CurrencyConversionService.rateCache.size(),
            'Cache size should remain unchanged for same day');
    }

    @IsTest
    static void test_SetRatesProvider_Null_ResetsCache() {
        Map<String, Decimal> rates = new Map<String, Decimal>{ 'EUR' => 0.909090909, 'USD' => 1.0 };
        CurrencyConversionService.setRatesProvider(new FakeRatesProvider('USD', rates));
        CurrencyConversionService.getCrossRate('EUR', 'USD', Date.today());
        System.assert(CurrencyConversionService.rateCache.size() >= 1);

        CurrencyConversionService.setRatesProvider(null);
        System.assertEquals(0, CurrencyConversionService.rateCache.size(), 'Cache must be cleared when provider is reset');
    }
}