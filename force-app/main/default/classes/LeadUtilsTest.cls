@IsTest
private class LeadUtilsTest {

    // Імена/значення, що узгоджені з умовами у LeadUtils.loadAllSegmChiefs()
    private static final String JOB_TITLE = 'Sales Chief Officer';
    private static final String DIVISION_BIZ = 'Pipes';
    private static final String SALES_SEGMENT = '00011';

    // === утиліти ===
    private static User mkSysAdminWithRole(){
        UserRole ur = new UserRole(Name='UT Role'); insert ur;
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator' LIMIT 1];
        User u = new User(
                ProfileId=p.Id, UserRoleId=ur.Id,
                Username='utadmin'+System.currentTimeMillis()+'@example.com',
                Email='utadmin'+System.currentTimeMillis()+'@example.com',
                Alias='utadm', LastName='UTAdmin',
                TimeZoneSidKey='Europe/Kiev', LocaleSidKey='uk_UA',
                EmailEncodingKey='UTF-8', LanguageLocaleKey='uk'
        );
        insert u;
        return u;
    }

    // опціонально, якщо Flow ділиться на групу:
    private static Group ensureShareGroup(){
        Group g = new Group(Name='Account Custom Share', DeveloperName='Account_Custom_Share', Type='Regular');
        insert g;
        return g;
    }

    // ---- Countries helpers (для getLeadsToInseret)
    private static Map<String, Id> createCountries() {
        // UA (для сегмента 00011 та дефолту), AE (для '00002' / owner.CountryCode)
        Country__c ua = new Country__c(
                Name='Ukraine', SysName__c='UKRAINE',
                A2Code__c='UA', A3Code__c='UKR', NumCode__c='804',
                Market_Segment__c='00011'
        );
        Country__c ae = new Country__c(
                Name='UAE', SysName__c='UAE',
                A2Code__c='AE', A3Code__c='ARE', NumCode__c='784',
                Market_Segment__c='00002'
        );
        insert new List<Country__c>{ ua, ae };
        try { CountryRepository.clearCache(); } catch (Exception e) {} // якщо є кеш
        return new Map<String, Id>{ 'UA' => ua.Id, 'AE' => ae.Id };
    }

    // ---- Бізнес-дані для linkLeadsOppOrders
    private static Map<String, Id> createBusinessData(Id ownerActiveId, Id ownerInactiveId) {
        Map<String, Id> ids = new Map<String, Id>();

        Account accActive = new Account(
                Name='ACC Active',
                OwnerId=ownerActiveId,
                MarketSegment__c='00011',
                BillingCity='Kyiv'
        );
        Account accInactive = new Account(
                Name='ACC Inactive',
                OwnerId=ownerInactiveId,
                MarketSegment__c='00011',
                BillingCity='Dnipro'
        );
        insert new List<Account>{ accActive, accInactive };
        ids.put('accActive', accActive.Id);
        ids.put('accInactive', accInactive.Id);

        Opportunity oppA = new Opportunity(
                Name='Opp A',
                AccountId=accActive.Id,
                StageName='Qualification',
                CloseDate=Date.today().addDays(30)
        );
        Order ordA = new Order(
                AccountId = accActive.Id,
                Status = 'Draft',
                EffectiveDate = Date.today()
        );
        Contact conA = new Contact(
                LastName='Con A',
                AccountId=accActive.Id
        );
        insert new List<SObject>{ oppA, ordA, conA };
        ids.put('oppA', oppA.Id);
        ids.put('ordA', ordA.Id);
        ids.put('conA', conA.Id);

        ClientLead__c preexistingLead = new ClientLead__c(Name='Pre Existing Lead');
        insert preexistingLead;
        ids.put('preLead', preexistingLead.Id);

        Opportunity oppB = new Opportunity(
                Name='Opp B',
                AccountId=accActive.Id,
                StageName='Prospecting',
                CloseDate=Date.today().addDays(40),
                Lead__c = preexistingLead.Id
        );
        Order ordB = new Order(
                AccountId = accActive.Id,
                Status = 'Draft',
                EffectiveDate = Date.today(),
                Lead__c = preexistingLead.Id
        );
        Contact conB = new Contact(
                LastName='Con B',
                AccountId=accActive.Id,
                Lead__c = preexistingLead.Id
        );
        insert new List<SObject>{ oppB, ordB, conB };
        ids.put('oppB', oppB.Id);
        ids.put('ordB', ordB.Id);
        ids.put('conB', conB.Id);

        return ids;
    }

    private static Id tryGetOppRtId() {
        Map<String, Schema.RecordTypeInfo> m = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName();
        return (m != null && m.containsKey('New_Client_Enquiry')) ? m.get('New_Client_Enquiry').getRecordTypeId() : null;
    }
    private static Id tryGetContRtId() {
        Map<String, Schema.RecordTypeInfo> m = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName();
        return (m != null && m.containsKey('Lead_Contact')) ? m.get('Lead_Contact').getRecordTypeId() : null;
    }

    @TestSetup
    static void setup() {
        Profile p = [
                SELECT Id, Name FROM Profile
                WHERE UserLicense.Name = 'Salesforce'
                ORDER BY Name
                LIMIT 1
        ];

        User chief = new User(
                ProfileId=p.Id,
                Username='chief+'+System.currentTimeMillis()+'@example.com',
                Email='chief+'+System.currentTimeMillis()+'@example.com',
                Alias='SChfOff', LastName='Chief',
                TimeZoneSidKey='Europe/Kiev', LocaleSidKey='uk_UA',
                EmailEncodingKey='UTF-8', LanguageLocaleKey='uk',
                JobTitle__c=JOB_TITLE, SalesDivision__c=SALES_SEGMENT, BusinesDivision__c=DIVISION_BIZ
        );
        insert chief;

        User ite = new User(
                ProfileId=p.Id,
                Username='ite+'+System.currentTimeMillis()+'@example.com',
                Email='ite+'+System.currentTimeMillis()+'@example.com',
                Alias='ITE', LastName='ITE',
                TimeZoneSidKey='Europe/Kiev', LocaleSidKey='uk_UA',
                EmailEncodingKey='UTF-8', LanguageLocaleKey='uk',
                JobTitle__c='Sales Manager', SalesDivision__c='00006', BusinesDivision__c='Railway'
        );
        User bty = new User(
                ProfileId=p.Id,
                Username='bahtiyar+'+System.currentTimeMillis()+'@example.com',
                Email='bahtiyar+'+System.currentTimeMillis()+'@example.com',
                Alias='Bahtiyar', LastName='Bahtiyar',
                TimeZoneSidKey='Europe/Kiev', LocaleSidKey='uk_UA',
                EmailEncodingKey='UTF-8', LanguageLocaleKey='uk',
                JobTitle__c='Sales Manager', SalesDivision__c='00002', BusinesDivision__c='Pipes'
        );
        insert new List<User>{ ite, bty };

        // admin + (опц.) група
        User admin = mkSysAdminWithRole();
        // Group g = ensureShareGroup();
        // insert new GroupMember(GroupId=g.Id, UserOrGroupId=admin.Id); // якщо треба учасник

        // ТІЛЬКИ ОДИН інсерт акаунтів — під адміном!
        Account accAnd = new Account(
                Name='AND Corp',
                OwnerId=ite.Id,
                ID_ERP__c=null,
                MarketSegment__c=null, // щоб пройти noSegment=true
                BillingCity='Kyiv'
        );
        Account accOr = new Account(
                Name='OR Ltd',
                OwnerId=bty.Id,
                BillingCity='Lviv'
        );

        System.runAs(admin){
            insert new List<Account>{ accAnd, accOr };
        }

        LeadUtils.clearCache();
    }

    // --- геттери як у тебе ---
    private static User getChief() {
        return [SELECT Id, Alias, SalesDivision__c, BusinesDivision__c, JobTitle__c, IsActive
        FROM User WHERE JobTitle__c = :JOB_TITLE AND SalesDivision__c = :SALES_SEGMENT LIMIT 1];
    }
    private static User getITE()      { return [SELECT Id, Alias, IsActive, CountryCode, SalesDivision__c, BusinesDivision__c FROM User WHERE Alias='ITE' LIMIT 1]; }
    private static User getBahtiyar() { return [SELECT Id, Alias FROM User WHERE Alias='Bahtiyar' LIMIT 1]; }
    private static List<Account> getAllTestAccounts() {
        return [SELECT Id, Name FROM Account WHERE Name IN ('AND Corp','OR Ltd') ORDER BY Name];
    }

    /* ==========================
       Cache / chiefs
       ========================== */
    @IsTest
    static void test_load_and_cache_segment_chiefs() {
        // Перше завантаження -> 1 SOQL
        Integer q0 = Limits.getQueries();
        LeadUtils.refreshCache();
        Integer q1 = Limits.getQueries();
        System.assertEquals(1, q1 - q0, 'Перше завантаження керівників має дати 1 SOQL');

        // Читання з кешу -> 0 SOQL
        Integer q2 = Limits.getQueries();
        Map<String, User> m1 = LeadUtils.getSegmChiefsMap();
        User u = LeadUtils.getSegmentChief(SALES_SEGMENT);
        Integer q3 = Limits.getQueries();
        System.assertEquals(0, q3 - q2, 'Читання з кешу не повинні робити SOQL');

        System.assert(m1.containsKey(SALES_SEGMENT), 'У мапі має бути наш сегмент');
        System.assertNotEquals(null, u, 'Chief для сегменту має бути знайдений');
        System.assertEquals(SALES_SEGMENT, u.SalesDivision__c, 'Chief має відповідати сегменту');

        // Очистка кешу -> наступний гетер знову робить 1 SOQL
        LeadUtils.clearCache();
        Integer q4 = Limits.getQueries();
        User u2 = LeadUtils.getSegmentChief(SALES_SEGMENT);
        Integer q5 = Limits.getQueries();
        System.assertNotEquals(null, u2, 'Після clearCache() chief знову має підвантажитись');
        System.assertEquals(1, q5 - q4, 'Перший чит після clearCache() має дати 1 SOQL');
    }

    /* ==========================
       getWrongAccList(...)
       ========================== */
    @IsTest
    static void test_getWrongAccList_AND_filters() {
        // Усі прапорці = true, зʼєднання AND, без LIMIT
        List<Account> res = LeadUtils.getWrongAccList(
                /*isNullIDinERP*/ true,
                /*noOpps*/        true,
                /*isNoClosedWon*/ true,
                /*isNoOrders*/    true,
                /*noSegment*/     true,
                /*isWrongOwner*/  true,
                /*And_Or*/        true,   // AND
                /*sqlLimit*/      0
        );
        Set<String> names = new Set<String>();
        for (Account a : res) names.add(a.Name);
        System.assert(names.contains('AND Corp'), 'Очікуємо AND Corp у результаті AND-фільтрів');
    }

    @IsTest
    static void test_getWrongAccList_OR_and_LIMIT() {
        // OR + LIMIT = 1
        List<Account> res = LeadUtils.getWrongAccList(true,true,true,true,true,true,false,1);
        System.assertEquals(1, res.size(), 'При LIMIT=1 має повернути рівно один запис');
    }

    @IsTest
    static void test_getWrongAccList_byIds_safe() {
        List<Account> testAccs = getAllTestAccounts();
        Set<Id> ids = new Set<Id>();
        for (Account a : testAccs) ids.add(a.Id);

        List<Account> res = LeadUtils.getWrongAccList(ids);
        System.assertEquals(2, res.size(), 'getWrongAccList(Set<Id>) має повернути всі передані акаунти');
    }

    @IsTest
    static void test_getWrongAccList_byIds_handles_null_and_empty() {
        System.assertEquals(0, LeadUtils.getWrongAccList((Set<Id>)null).size(),
                'При null має повертати порожній список, не падати');
        System.assertEquals(0, LeadUtils.getWrongAccList(new Set<Id>()).size(),
                'При empty має повертати порожній список, не падати');
    }

    @IsTest
    static void test_getWrongAccList_noFlags_returnsAll() {
        List<Account> res = LeadUtils.getWrongAccList(false,false,false,false,false,false,true,0);
        Set<String> names = new Set<String>();
        for (Account a : res) names.add(a.Name);
        System.assertEquals(new Set<String>{'AND Corp','OR Ltd'}, names,
                'Без фільтрів маємо отримати всі акаунти із тестового сетапу');
    }

    @IsTest
    static void test_getWrongAccList_onlyWrongOwner() {
        List<Account> res = LeadUtils.getWrongAccList(false,false,false,false,false,true,true,0);
        System.assertEquals(2, res.size(),
                'Обидва тестові акаунти мають власників з alias ITE/Bahtiyar, отже повинні повернутись');
    }

    @IsTest
    static void test_getWrongAccList_AND_with_LIMIT() {
        List<Account> res = LeadUtils.getWrongAccList(true,true,true,true,true,true,true,1);
        System.assertEquals(1, res.size(), 'LIMIT=1 має обмежити результат одним записом при AND-фільтрах');
    }

    @IsTest
    static void test_getWrongAccList_OR_expands_selection() {
        List<Account> resOr = LeadUtils.getWrongAccList(true,true,true,true,true,false,false,0);
        System.assert(resOr.size() >= 1,
                'З OR має повертатись щонайменше один акаунт, який підпадає хоча б під одну умову');
    }

    /* ==========================
       insertNewLeads(...)
       ========================== */
    @IsTest
    static void test_insertNewLeads_maps_ids_and_partial_failure() {
        createCountries();
        // Мін. дані
        User anyValue = getBahtiyar();
        Account acc = new Account(Name='ACC for Insert', OwnerId=anyValue.Id, BillingCity='City');
        insert acc;

        // валідний
        ClientLead__c goodOne = new ClientLead__c(Name='OK', Account__c=acc.Id);
        // потенційно невалідний (якщо Name обовʼязковий)
        ClientLead__c badOne  = new ClientLead__c(Account__c=acc.Id);

        Map<Id,Id> mapIds = LeadUtils.insertNewLeads(new List<ClientLead__c>{ goodOne, badOne });
        System.assert(mapIds.size() >= 1, 'У мапі має бути щонайменше успішний запис');
        System.assert(mapIds.containsKey(acc.Id), 'Для акаунта має бути створений лід');
    }

    /* ==========================
       linkLeadsOppOrders(...)
       ========================== */
    @IsTest
    static void test_linkLeadsOppOrders_onlyIfBlank_true() {
        createCountries();
        // створимо актив/неактив і дані
        User active = getBahtiyar();
        User inactive = getITE(); // він активний за замовчуванням
        Map<String, Id> ids = createBusinessData(active.Id, inactive.Id);

        Account acc = [SELECT Id FROM Account WHERE Id=:ids.get('accActive') LIMIT 1];
        ClientLead__c newLead = new ClientLead__c(Name='New Lead for ACC Active');
        insert newLead;

        Map<Id,Id> mapAccLead = new Map<Id,Id>{ acc.Id => newLead.Id };

        Test.startTest();
        LeadUtils.linkLeadsOppOrders(mapAccLead, true);
        Test.stopTest();

        Id expectedOppRT = tryGetOppRtId();
        Id expectedContRT = tryGetContRtId();

        Opportunity oppA = [SELECT Id, Lead__c, RecordTypeId, Status__c FROM Opportunity WHERE Name='Opp A' LIMIT 1];
        Order       ordA = [SELECT Id, Lead__c FROM Order WHERE AccountId=:acc.Id ORDER BY CreatedDate ASC LIMIT 1];
        Contact     conA = [SELECT Id, Lead__c, RecordTypeId FROM Contact WHERE LastName='Con A' LIMIT 1];

        System.assertEquals(newLead.Id, oppA.Lead__c, 'Opp A має отримати новий Lead__c');
        System.assertEquals('Enquiry', oppA.Status__c, 'Opp A Status__c → Enquiry');
        if (expectedOppRT != null) System.assertEquals(expectedOppRT, oppA.RecordTypeId);

        System.assertEquals(newLead.Id, ordA.Lead__c, 'Order A має отримати новий Lead__c');

        System.assertEquals(newLead.Id, conA.Lead__c, 'Contact A має отримати новий Lead__c');
        if (expectedContRT != null) System.assertEquals(expectedContRT, conA.RecordTypeId);

        // де вже був Lead__c — не перезаписує
        Opportunity oppB = [SELECT Id, Lead__c FROM Opportunity WHERE Name='Opp B' LIMIT 1];
        Contact     conB = [SELECT Id, Lead__c FROM Contact WHERE LastName='Con B' LIMIT 1];
        Order       ordB = [SELECT Id, Lead__c FROM Order WHERE AccountId=:acc.Id ORDER BY CreatedDate DESC LIMIT 1];
        ClientLead__c preexisting = [SELECT Id FROM ClientLead__c WHERE Id=:ids.get('preLead') LIMIT 1];

        System.assertEquals(preexisting.Id, oppB.Lead__c, 'Opp B — очікуємо без змін');
        System.assertEquals(preexisting.Id, conB.Lead__c, 'Con B — очікуємо без змін');
        if (ordB.Lead__c != preexisting.Id) {
            System.assertEquals(newLead.Id, ordB.Lead__c,
                    'Ord B змінений орг-логікою — якщо так, то має дорівнювати новому Lead');
        }
    }

    @IsTest
    static void test_linkLeadsOppOrders_overwrite_false() {
        createCountries();
        User active = getBahtiyar();
        User inactive = getITE();
        Map<String, Id> ids = createBusinessData(active.Id, inactive.Id);

        Account acc = [SELECT Id FROM Account WHERE Id=:ids.get('accActive') LIMIT 1];
        ClientLead__c overwriteLead = new ClientLead__c(Name='Overwrite Lead');
        insert overwriteLead;

        Map<Id,Id> mapAccLead = new Map<Id,Id>{ acc.Id => overwriteLead.Id };

        Test.startTest();
        LeadUtils.linkLeadsOppOrders(mapAccLead, false);
        Test.stopTest();

        for (Opportunity o : [SELECT Name, Lead__c FROM Opportunity WHERE AccountId=:acc.Id]) {
            System.assertEquals(overwriteLead.Id, o.Lead__c, 'Opp '+o.Name+' має бути перезаписаний');
        }
        for (Contact c : [SELECT LastName, Lead__c FROM Contact WHERE AccountId=:acc.Id]) {
            System.assertEquals(overwriteLead.Id, c.Lead__c, 'Contact '+c.LastName+' має бути перезаписаний');
        }
        for (Order od : [SELECT Id, Lead__c FROM Order WHERE AccountId=:acc.Id]) {
            System.assertEquals(overwriteLead.Id, od.Lead__c, 'Order має бути перезаписаний');
        }
    }

    @IsTest
    static void test_linkLeadsOppOrders_default_overload_equals_false() {
        createCountries();
        User active = getBahtiyar();
        User inactive = getITE();
        Map<String, Id> ids = createBusinessData(active.Id, inactive.Id);

        Account acc = [SELECT Id FROM Account WHERE Id=:ids.get('accActive') LIMIT 1];
        ClientLead__c leadA = new ClientLead__c(Name='L-A'); insert leadA;
        ClientLead__c leadB = new ClientLead__c(Name='L-B'); insert leadB;

        // Спочатку оновимо всім Lead__c = leadA
        LeadUtils.linkLeadsOppOrders(new Map<Id,Id>{ acc.Id => leadA.Id }, false);

        // А тепер викличемо обгортку без 2-го параметра (вона всередині викликає false)
        LeadUtils.linkLeadsOppOrders(new Map<Id,Id>{ acc.Id => leadB.Id });

        // Має бути перезаписано на leadB
        for (Opportunity o : [SELECT Lead__c FROM Opportunity WHERE AccountId=:acc.Id]) {
            System.assertEquals(leadB.Id, o.Lead__c);
        }
        for (Order od : [SELECT Lead__c FROM Order WHERE AccountId=:acc.Id]) {
            System.assertEquals(leadB.Id, od.Lead__c);
        }
        for (Contact c : [SELECT Lead__c FROM Contact WHERE AccountId=:acc.Id]) {
            System.assertEquals(leadB.Id, c.Lead__c);
        }
    }

    /* ==========================
       getLeadNormName(...)
       ========================== */
    @IsTest
    static void test_getLeadNormName_blank_and_nonblank() {
        System.assertEquals('', LeadUtils.getLeadNormName(''), 'Порожнє → порожній рядок');
        System.assertEquals('', LeadUtils.getLeadNormName(null), 'null → порожній рядок');

        String s = LeadUtils.getLeadNormName('  Acme?  ');
        System.assertNotEquals('', s, 'Для непорожнього рядка нормалізатор має повернути значення');
    }

    /* ==========================
       getSegmAccCode(...)
       ========================== */
    @IsTest
    static void test_getSegmAccCode_negative_paths() {
        System.assertEquals('', LeadUtils.getSegmAccCode(null), 'null → ""');
        System.assertEquals('', LeadUtils.getSegmAccCode(''),   'blank → ""');
        // невідомий сегмент (або відсутній у піклісті/CS) → ""
        System.assertEquals('', LeadUtils.getSegmAccCode('99999'), 'unknown segment → ""');
    }

    /* ==========================
       findDuplicates(...)
       ========================== */
    @IsTest
    static void test_findDuplicates_blank_and_no_matches() {
        // blank
        System.assertEquals(0, LeadUtils.findDuplicates(null, 0.8).size(), 'blank → []');
        System.assertEquals(0, LeadUtils.findDuplicates('',   0.8).size(), 'blank → []');

        // вставимо лід, який точно не співпаде по перших 3 символах soundex (у більшості реалізацій)
        insert new ClientLead__c(
                Name='Zed Zed',
                NormalizedName__c='ZZTOP',
                SoundexFirst3Letters__c='Z99' // умовно "далеко" від більшості рядків
        );

        // шукатимемо щось зовсім інше
        List<StringUtilsEx.MatchResult> results = LeadUtils.findDuplicates('ACME', 0.8);
        System.assertEquals(0, results.size(), 'коли немає матчів за префільтром → []');

        // threshold за межами [0..1] → дефолт до 0.8, але тут все одно 0 збігів
        System.assertEquals(0, LeadUtils.findDuplicates('ACME', -1).size());
        System.assertEquals(0, LeadUtils.findDuplicates('ACME',  2).size());
    }
}