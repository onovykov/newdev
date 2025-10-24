@IsTest
private class CountryRepositoryTest {

    @TestSetup
    static void setupData() {
        Country__c ua = new Country__c(
            Name        = 'Ukraine',
            SysName__c  = 'UKRAINE',
            A2Code__c   = 'UA',
            A3Code__c   = 'UKR',
            NumCode__c  = '804'
        );
        Country__c pl = new Country__c(
            Name        = 'Poland',
            SysName__c  = 'POLAND',
            A2Code__c   = 'PL',
            A3Code__c   = 'POL',
            NumCode__c  = '616'
        );
        // Має ігноруватись фільтром A2Code__c!='0'
        Country__c zero = new Country__c(
            Name        = 'Zero Country',
            SysName__c  = 'ZERO_COUNTRY',
            A2Code__c   = '0',
            A3Code__c   = 'ZER',
            NumCode__c  = '000'
        );

        insert new List<Country__c>{ ua, pl, zero };
        CountryRepository.clearCache();
    }

    // Допоміжний метод: знайти Id країни за A2
    private static Id idByA2(String a2) {
        return [SELECT Id FROM Country__c WHERE A2Code__c = :a2 LIMIT 1].Id;
    }

    @IsTest
    static void test_getters_basic() {
        Id uaId = idByA2('UA');

        Test.startTest();
        Country__c byId  = CountryRepository.getById(uaId);
        Country__c byA2  = CountryRepository.getByA2Code('PL');
        Country__c byNum = CountryRepository.getByNumCode('804');
        Test.stopTest();

        System.assertNotEquals(null, byId,  'getById() має повернути UA');
        System.assertEquals('UA',  byId.A2Code__c);
        System.assertEquals('UKR', byId.A3Code__c);

        System.assertNotEquals(null, byA2,  'getByA2Code() має знайти PL');
        System.assertEquals('PL',  byA2.A2Code__c);
        System.assertEquals('POL', byA2.A3Code__c);

        System.assertNotEquals(null, byNum, 'getByNumCode() має знайти UA');
        System.assertEquals('804', byNum.NumCode__c);
    }

    @IsTest
    static void test_excludes_a2code_zero() {
        CountryRepository.refresh();
        Country__c shouldBeNull = CountryRepository.getByA2Code('0');
        System.assertEquals(null, shouldBeNull,
            'Запис з A2Code__c="0" має бути проігнорований фільтром у SOQL');
    }

    @IsTest
    static void test_cache_avoids_extra_queries() {
        Id uaId = idByA2('UA'); // робимо до вимірювань, щоб не впливати на метрики

        Integer before = Limits.getQueries();
        CountryRepository.refresh(); // 1 SOQL
        Integer after = Limits.getQueries();
        System.assertEquals(1, after - before,
            'refresh() має виконати рівно 1 SOQL для завантаження довідника');

        Integer q1 = Limits.getQueries();
        CountryRepository.getByA2Code('PL');
        CountryRepository.getByNumCode('616');
        CountryRepository.getById(uaId);
        Integer q2 = Limits.getQueries();
        System.assertEquals(0, q2 - q1, 'Гетери мають працювати з кешу без додаткових SOQL');
    }

    @IsTest
    static void test_clearCache_triggers_reload_on_next_call() {
        Id uaId = idByA2('UA');

        CountryRepository.refresh();
        CountryRepository.clearCache();

        Integer before = Limits.getQueries();
        Country__c c = CountryRepository.getById(uaId); // перший виклик після clearCache()
        Integer after = Limits.getQueries();

        System.assertNotEquals(null, c, 'Після clearCache() маємо знайти країну UA');
        System.assertEquals(1, after - before,
            'Перший гетер після clearCache() має спричинити 1 SOQL для перезавантаження кешу');
    }

    @IsTest
    static void test_null_or_unknown_returns_null() {
        CountryRepository.refresh();
        System.assertEquals(null, CountryRepository.getByA2Code('ZZ'));
        System.assertEquals(null, CountryRepository.getByNumCode('999'));
        System.assertEquals(null, CountryRepository.getById((Id)'001000000000000AAA'));
    }
}