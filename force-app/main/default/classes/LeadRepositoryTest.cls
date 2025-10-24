@IsTest
private class LeadRepositoryTest {

    // Дзеркало списку індексованих полів
    private static final List<String> INDEXED_FIELDS = new List<String>{
        'PhoneticCode__c', 'MetaphonePrimary__c', 'MetaphoneAlternate__c',
        'NYSIISFirstCode__c', 'NYSIIS__c', 'NormalizedName__c',
        'SoundexFirst3Letters__c', 'SoundexFirstWord__c', 'SoundexAllWords__c'
    };

    // === ХЕЛПЕР: зібрати валідний 18-символьний Id для ClientLead__c без DML ===
    private static Id fakeLeadId(Integer n) {
        String kp = ClientLead__c.SObjectType.getDescribe().getKeyPrefix(); // 3-симв. префікс об'єкта
        String num = String.valueOf(n);
        // допадимо до 12 символів (бо 3 префікс + 12 = 15 базових, + 'AAA' = 18)
        while (num.length() < 12) num = '0' + num;
        return (Id)(kp + num + 'AAA');
    }

    @IsTest
    static void test_empty_behaviour_and_basic_getters() {
        LeadRepository.clearCache();

        System.assertEquals(0,
            LeadRepository.getByFieldValue('DoesNotExist__c', 'X').size(),
            'Unknown field must return empty list');

        for (String f : INDEXED_FIELDS) {
            List<ClientLead__c> rows = LeadRepository.getByFieldValue(f, '___no_such_value___');
            System.assertNotEquals(null, rows, 'Must not be null for field ' + f);
            System.assertEquals(0, rows.size(), 'No data expected for field ' + f);
        }

        System.assertEquals(0, LeadRepository.getByFieldValue(null, 'x').size());
        System.assertEquals(0, LeadRepository.getByFieldValue('PhoneticCode__c', null).size());
        System.assertEquals(0, LeadRepository.getByFieldValue('', '').size());

        ClientLead__c byId = LeadRepository.getById((Id) '001000000000001AAA'); // не існує серед кешу
        System.assertEquals(null, byId, 'No cached record must be returned when DB is empty');

        Integer dbCount = [SELECT COUNT() FROM ClientLead__c];
        System.assertEquals(dbCount, LeadRepository.getAllLeads().size(),
            'Cached size must equal DB count');
    }

    @IsTest
    static void test_loading_is_idempotent() {
        LeadRepository.clearCache();

        Integer q0 = Limits.getQueries();
        LeadRepository.getAllLeads(); // перший доступ -> будує кеш
        Integer q1 = Limits.getQueries();

        LeadRepository.getAllLeads(); // другий доступ -> з кешу
        Integer q2 = Limits.getQueries();

        System.assert(q1 > q0, 'First access should execute SOQL to build cache');
        System.assertEquals(q1, q2, 'Second access must use cache (no extra SOQL)');
    }

    @IsTest
    static void test_clearCache_triggers_reload() {
        LeadRepository.clearCache();

        LeadRepository.getAllLeads();
        Integer afterFirstLoad = Limits.getQueries();

        LeadRepository.clearCache();
        Integer beforeReload = Limits.getQueries();

        LeadRepository.getAllLeads(); // знову має робити SOQL
        Integer afterReload = Limits.getQueries();

        System.assert(afterReload > beforeReload,
            'After clearCache, a subsequent access must re-query the DB');
        System.assert(afterFirstLoad < afterReload,
            'Reload should increase total SOQL count compared to after first load');
    }

    @IsTest
    static void test_indexes_exist_for_all_declared_fields() {
        LeadRepository.clearCache();
        LeadRepository.getAllLeads();

        for (String f : INDEXED_FIELDS) {
            List<ClientLead__c> r = LeadRepository.getByFieldValue(f, 'unlikely_value');
            System.assertNotEquals(null, r, 'Index map must exist for ' + f);
            System.assertEquals(0, r.size(), 'No matches expected for ' + f);
        }
    }

    @IsTest
    static void test_positive_indexing_and_copy_semantics() {
        LeadRepository.clearCache();

        // Штучні "ліди" без DML з валідними Id під конкретний об'єкт
        ClientLead__c a = new ClientLead__c();
        a.Id   = fakeLeadId(1);
        a.Name = 'Acme';
        a.NormalizedName__c     = 'acme';
        a.PhoneticCode__c       = 'AKM';
        a.MetaphonePrimary__c   = 'AKM';
        a.SoundexFirstWord__c   = 'A250';

        ClientLead__c b = new ClientLead__c();
        b.Id   = fakeLeadId(2);
        b.Name = 'Akmi';
        b.NormalizedName__c     = 'acmi';
        b.PhoneticCode__c       = 'AKM'; // той самий ключ -> очікуємо 2 записи
        b.MetaphonePrimary__c   = 'AKM';
        b.SoundexFirstWord__c   = 'A250';

        ClientLead__c c = new ClientLead__c();
        c.Id   = fakeLeadId(3);
        c.Name = 'Space Co';
        c.NormalizedName__c     = '   ';   // пробіли -> має ігноруватись після trim()
        c.MetaphoneAlternate__c = 'XYZ';   // інше поле індексації

        // Інжектимо у кеш без DML
        LeadRepository.injectForTest(new List<ClientLead__c>{ a, b, c });

        // getById: знаходить "a"
        System.assertEquals(a, LeadRepository.getById(a.Id), 'getById must return injected record');

        // Пошук за індексом (AKM -> a,b)
        List<ClientLead__c> ph = LeadRepository.getByFieldValue('PhoneticCode__c', 'AKM');
        System.assertEquals(2, ph.size(), 'Two records must share the same PhoneticCode__c');

        // Copy semantics: очищення зовнішнього списку не ламає кеш
        ph.clear();
        System.assertEquals(2,
            LeadRepository.getByFieldValue('PhoneticCode__c', 'AKM').size(),
            'Repository must return a fresh copy, not internal bucket');

        // Інший індекс (MetaphoneAlternate__c -> c)
        List<ClientLead__c> alt = LeadRepository.getByFieldValue('MetaphoneAlternate__c', 'XYZ');
        System.assertEquals(1, alt.size(), 'Alternate index should return the single matching record');
        System.assertEquals(c, alt[0], 'Returned record must be c');

        // Пробіли не індексуються
        System.assertEquals(0,
            LeadRepository.getByFieldValue('NormalizedName__c', '   ').size(),
            'Blank (after trim) values must not be indexed');
    }
}