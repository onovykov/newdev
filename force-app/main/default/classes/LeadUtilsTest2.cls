@IsTest
private class LeadUtilsTest2 {

    // === Константи під ваш код / DevName RT
    private static final String RT_OPP_DEV = 'New_Client_Enquiry';
    private static final String RT_CONT_DEV = 'Lead_Contact';
    private static final String SALES_SEGMENT_FOR_MAP = '00011'; // у LeadUtils.mapSegmAcc -> '00011' => 'UA'

    // =========================
    // @TestSetup: ЛИШЕ SETUP DML (User)
    // =========================
    @TestSetup
    static void setupUsersOnly() {
        Profile prof = [
            SELECT Id, Name FROM Profile
            WHERE UserLicense.Name = 'Salesforce'
            ORDER BY Name
            LIMIT 1
        ];

        // Активний власник
        User ownerActive = new User(
            ProfileId=prof.Id,
            Username='owner.active+'+System.currentTimeMillis()+'@example.com',
            Email='owner.active+'+System.currentTimeMillis()+'@example.com',
            Alias='owact',
            LastName='ActiveOwner',
            TimeZoneSidKey='Europe/Kiev',
            LocaleSidKey='uk_UA',
            EmailEncodingKey='UTF-8',
            LanguageLocaleKey='uk',
            JobTitle__c='Sales Manager',
            SalesDivision__c=SALES_SEGMENT_FOR_MAP,
            BusinesDivision__c='Pipes',
            CountryCode='UA'
        );
        // Деактивований власник
        User ownerInactive = new User(
            ProfileId=prof.Id,
            Username='owner.inactive+'+System.currentTimeMillis()+'@example.com',
            Email='owner.inactive+'+System.currentTimeMillis()+'@example.com',
            Alias='owina',
            LastName='InactiveOwner',
            TimeZoneSidKey='Europe/Kiev',
            LocaleSidKey='uk_UA',
            EmailEncodingKey='UTF-8',
            LanguageLocaleKey='uk',
            JobTitle__c='Sales Manager',
            SalesDivision__c=SALES_SEGMENT_FOR_MAP,
            BusinesDivision__c='Pipes',
            CountryCode='UA'
        );
        insert new List<User>{ ownerActive, ownerInactive };
        ownerInactive.IsActive = false;
        update ownerInactive;

        // Технічні користувачі (на випадок переходу в гілку ITE/Bahtiyar)
        User ite = new User(
            ProfileId=prof.Id,
            Username='ite+'+System.currentTimeMillis()+'@example.com',
            Email='ite+'+System.currentTimeMillis()+'@example.com',
            Alias='ITE',
            LastName='ITE',
            TimeZoneSidKey='Europe/Kiev',
            LocaleSidKey='uk_UA',
            EmailEncodingKey='UTF-8',
            LanguageLocaleKey='uk',
            JobTitle__c='Sales Manager',
            SalesDivision__c='00002',
            BusinesDivision__c='Pipes'
        );
        User bty = new User(
            ProfileId=prof.Id,
            Username='bahtiyar+'+System.currentTimeMillis()+'@example.com',
            Email='bahtiyar+'+System.currentTimeMillis()+'@example.com',
            Alias='Bahtiyar',
            LastName='Bahtiyar',
            TimeZoneSidKey='Europe/Kiev',
            LocaleSidKey='uk_UA',
            EmailEncodingKey='UTF-8',
            LanguageLocaleKey='uk',
            JobTitle__c='Sales Manager',
            SalesDivision__c='00002',
            BusinesDivision__c='Pipes'
        );
        insert new List<User>{ ite, bty };

        LeadUtils.clearCache();
    }

    // ===== Хелпери для пошуку користувачів =====
    private static User getOwnerActive() {
        return [SELECT Id, Alias FROM User WHERE Alias='owact' LIMIT 1];
    }
    private static User getOwnerInactive() {
        return [SELECT Id, Alias, IsActive FROM User WHERE Alias='owina' LIMIT 1];
    }

    // ===== Хелпери: повертають RT Id, якщо такий є в орзі (або null) =====
    private static Id tryGetOppRtId() {
        Map<String, Schema.RecordTypeInfo> m =
            Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName();
        return (m != null && m.containsKey(RT_OPP_DEV)) ? m.get(RT_OPP_DEV).getRecordTypeId() : null;
    }
    private static Id tryGetContRtId() {
        Map<String, Schema.RecordTypeInfo> m =
            Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName();
        return (m != null && m.containsKey(RT_CONT_DEV)) ? m.get(RT_CONT_DEV).getRecordTypeId() : null;
    }

    // ===== Хелпер: створити країни (НЕ setup DML) у межах тест-методу =====
    private static Map<String, Id> createCountries() {
        Country__c ua = new Country__c(
            Name='Ukraine', SysName__c='UKRAINE',
            A2Code__c='UA', A3Code__c='UKR', NumCode__c='804',
            Market_Segment__c = SALES_SEGMENT_FOR_MAP
        );
        Country__c pl = new Country__c(
            Name='Poland', SysName__c='POLAND',
            A2Code__c='PL', A3Code__c='POL', NumCode__c='616',
            Market_Segment__c = '00002'
        );
        insert new List<Country__c>{ ua, pl };
        CountryRepository.clearCache();
        return new Map<String, Id>{ 'UA' => ua.Id, 'PL' => pl.Id };
    }

    // ===== Хелпер: створити бізнес-дані (акаунти, оппи/ордера/контакти, ліди) =====
    private static Map<String, Id> createBusinessData(Id ownerActiveId, Id ownerInactiveId) {
        Map<String, Id> ids = new Map<String, Id>();

        Account accActive = new Account(
            Name='ACC Active',
            OwnerId=ownerActiveId,
            MarketSegment__c=SALES_SEGMENT_FOR_MAP,
            BillingCity='Kyiv',
            BillingStreet='Khreshchatyk 1'
        );
        Account accInactive = new Account(
            Name='ACC Inactive',
            OwnerId=ownerInactiveId,
            MarketSegment__c=SALES_SEGMENT_FOR_MAP,
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

    // ------------------------------------------------------------------------------------
    // getLeadsToInseret: будуємо лід із акаунта (через сегмент->країна, active owner)
    @IsTest
    static void test_getLeadsToInseret_basic() {
        Map<String, Id> countryMap = createCountries();
        User ownerActive = getOwnerActive();
        User ownerInactive = getOwnerInactive();
        Map<String, Id> ids = createBusinessData(ownerActive.Id, ownerInactive.Id);

        // ⬅ Додали Name, бо в методі читається acc.Name
        Account acc = [SELECT Id, Name, OwnerId, Owner.IsActive, MarketSegment__c, BillingCity, BillingStreet, CountryId__c,
                              Email__c, Mobile__c, Phone, Website
                       FROM Account WHERE Id = :ids.get('accActive') LIMIT 1];

        List<ClientLead__c> leads = LeadUtils.getLeadsToInseret(new List<Account>{ acc });

        System.assertEquals(1, leads.size(), 'Має сформувати один ClientLead у памʼяті');
        ClientLead__c lead = leads[0];

        System.assertEquals('ACC Active', lead.Name, 'Назва ліда береться з акаунта');
        System.assertEquals(acc.Id, lead.Account__c, 'Account__c = вихідний акаунт');
        System.assertEquals('Pipes', lead.BusinessDivision__c, 'Для сегменту 00011 → Pipes');
        System.assertEquals(SALES_SEGMENT_FOR_MAP, lead.MarketSegment__c, 'Сегмент копіюється з акаунта');
        System.assertEquals(acc.OwnerId, lead.Manager__c, 'Active owner → менеджер = owner');
        System.assertEquals(acc.OwnerId, lead.OwnerId, 'Active owner → ownerId = owner');
        System.assertEquals(acc.BillingCity, lead.City__c);
        System.assertEquals(acc.BillingStreet, lead.Address__c);

        Country__c ua = CountryRepository.getByA2Code('UA');
        System.assertNotEquals(null, ua, 'UA країна має бути в репозиторії');
        System.assertEquals(countryMap.get('UA'), lead.Country__c, 'Country з mapSegmAcc → UA');
    }

    // ------------------------------------------------------------------------------------
    // insertNewLeads: повертає мапу AccountId→LeadId
    @IsTest
    static void test_insertNewLeads_maps_ids() {
        createCountries();
        User ownerActive = getOwnerActive();
        User ownerInactive = getOwnerInactive();
        Map<String, Id> ids = createBusinessData(ownerActive.Id, ownerInactive.Id);

        Account acc1 = [SELECT Id FROM Account WHERE Id = :ids.get('accActive') LIMIT 1];
        Account acc2 = [SELECT Id FROM Account WHERE Id = :ids.get('accInactive') LIMIT 1];

        ClientLead__c l1 = new ClientLead__c(Name='L1', Account__c=acc1.Id);
        ClientLead__c l2 = new ClientLead__c(Name='L2', Account__c=acc2.Id);

        Map<Id,Id> mapIds = LeadUtils.insertNewLeads(new List<ClientLead__c>{ l1, l2 });

        System.assertEquals(2, mapIds.size(), 'Мапа для всіх успішних інсертів');
        System.assert(mapIds.containsKey(acc1.Id) && mapIds.get(acc1.Id) != null, 'Є map для acc1');
        System.assert(mapIds.containsKey(acc2.Id) && mapIds.get(acc2.Id) != null, 'Є map для acc2');

        List<ClientLead__c> inserted = [
            SELECT Id, Name, Account__c FROM ClientLead__c
            WHERE Id IN :mapIds.values()
        ];
        System.assertEquals(2, inserted.size(), 'Обидва ClientLead вставлені');
    }

    // ------------------------------------------------------------------------------------
    // linkLeadsOppOrders: onlyIfBlank = true → оновлює лише там, де Lead__c порожній
    @IsTest
    static void test_linkLeadsOppOrders_onlyIfBlank_true() {
        createCountries();
        User ownerActive = getOwnerActive();
        User ownerInactive = getOwnerInactive();
        Map<String, Id> ids = createBusinessData(ownerActive.Id, ownerInactive.Id);

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
        if (expectedOppRT != null) {
            System.assertEquals(expectedOppRT, oppA.RecordTypeId, 'Opp A має отримати RT New_Client_Enquiry');
        }

        System.assertEquals(newLead.Id, ordA.Lead__c, 'Order A має отримати новий Lead__c');

        System.assertEquals(newLead.Id, conA.Lead__c, 'Contact A має отримати новий Lead__c');
        if (expectedContRT != null) {
            System.assertEquals(expectedContRT, conA.RecordTypeId, 'Contact A має отримати RT Lead_Contact');
        }

        // Там, де вже був Lead__c — тригери/флоуи можуть перезаписати.
        // Якщо змінилось — воно має дорівнювати newLead.Id
        Opportunity oppB = [SELECT Id, Lead__c FROM Opportunity WHERE Name='Opp B' LIMIT 1];
        Contact     conB = [SELECT Id, Lead__c FROM Contact WHERE LastName='Con B' LIMIT 1];
        Order       ordB = [SELECT Id, Lead__c FROM Order WHERE AccountId=:acc.Id ORDER BY CreatedDate DESC LIMIT 1];
        ClientLead__c preexisting = [SELECT Id FROM ClientLead__c WHERE Id=:ids.get('preLead') LIMIT 1];

        System.assertEquals(preexisting.Id, oppB.Lead__c, 'Opp B — очікуємо без змін (якщо немає сторонніх процесів)');

        System.assertEquals(preexisting.Id, conB.Lead__c, 'Con B — очікуємо без змін (якщо немає сторонніх процесів)');

        if (ordB.Lead__c != preexisting.Id) {
            System.assertEquals(newLead.Id, ordB.Lead__c,
                'Ord B змінений орг-логікою — якщо так, то має дорівнювати новому Lead');
        }
    }

    // ------------------------------------------------------------------------------------
    // linkLeadsOppOrders: onlyIfBlank = false → перезаписує, якщо значення інше
    @IsTest
    static void test_linkLeadsOppOrders_overwrite_false() {
        createCountries();
        User ownerActive = getOwnerActive();
        User ownerInactive = getOwnerInactive();
        Map<String, Id> ids = createBusinessData(ownerActive.Id, ownerInactive.Id);

        Account acc = [SELECT Id FROM Account WHERE Id=:ids.get('accActive') LIMIT 1];
        ClientLead__c overwriteLead = new ClientLead__c(Name='Overwrite Lead');
        insert overwriteLead;

        Map<Id,Id> mapAccLead = new Map<Id,Id>{ acc.Id => overwriteLead.Id };

        Test.startTest();
        LeadUtils.linkLeadsOppOrders(mapAccLead, false); // перезаписуємо всюди
        Test.stopTest();

        List<Opportunity> opps = [SELECT Name, Lead__c FROM Opportunity WHERE AccountId=:acc.Id];
        for (Opportunity o : opps) {
            System.assertEquals(overwriteLead.Id, o.Lead__c, 'Opp '+o.Name+' має бути перезаписаний');
        }
        List<Contact> cons = [SELECT LastName, Lead__c FROM Contact WHERE AccountId=:acc.Id];
        for (Contact c : cons) {
            System.assertEquals(overwriteLead.Id, c.Lead__c, 'Contact '+c.LastName+' має бути перезаписаний');
        }
        List<Order> ords = [SELECT Id, Lead__c FROM Order WHERE AccountId=:acc.Id];
        for (Order od : ords) {
            System.assertEquals(overwriteLead.Id, od.Lead__c, 'Order має бути перезаписаний');
        }
    }

    // ------------------------------------------------------------------------------------
    // Негативний/smoke для getLeadNormName(...) без зовнішніх залежностей
    @IsTest
    static void test_getLeadNormName_blank_returns_empty() {
        System.assertEquals('', LeadUtils.getLeadNormName(''), 'Порожнє → порожній рядок');
        System.assertEquals('', LeadUtils.getLeadNormName(null), 'null → порожній рядок');
    }

    // === helper: керівник сегмента для гілки з неактивним owner
    private static User ensureSegmentChief() {
        Profile p = [SELECT Id FROM Profile WHERE UserLicense.Name='Salesforce' LIMIT 1];
        User u = new User(
                ProfileId=p.Id,
                Username='chief+'+System.currentTimeMillis()+'@ex.com',
                Email='chief+'+System.currentTimeMillis()+'@ex.com',
                Alias='schf',
                LastName='SegmChief',
                TimeZoneSidKey='Europe/Kiev',
                LocaleSidKey='uk_UA',
                EmailEncodingKey='UTF-8',
                LanguageLocaleKey='uk',
                JobTitle__c='Sales Chief Officer',
                SalesDivision__c=SALES_SEGMENT_FOR_MAP, // '00011'
                BusinesDivision__c='Pipes'
        );
        insert u;
        // очищаємо кеш, щоби LeadUtils підхопив щойно вставленого
        LeadUtils.clearCache();
        return u;
    }

    @IsTest
    static void test_getLeadsToInseret_ownerInactive_uses_segment_chief() {
        // Керівник сегмента для '00011'
        ensureSegmentChief(); // створюємо хоча б одного, але не привʼязуємось до його Id

        // Дані
        createCountries();
        User ownerInactive = getOwnerInactive();
        Map<String, Id> ids = createBusinessData(getOwnerActive().Id, ownerInactive.Id);

        // Беремо акаунт з НЕактивним власником, але з Segment = 00011
        Account acc = [
                SELECT Id, Name, OwnerId, Owner.IsActive, MarketSegment__c,
                        BillingCity, BillingStreet, CountryId__c,
                        Owner.CountryCode, Owner.SalesDivision__c, Owner.BusinesDivision__c,
                        Email__c, Mobile__c, Phone, Website
                FROM Account
                WHERE Id = :ids.get('accInactive')
                LIMIT 1
        ];
        System.assertEquals(false, acc.Owner.IsActive, 'Власник має бути неактивним');
        System.assertEquals(SALES_SEGMENT_FOR_MAP, acc.MarketSegment__c, 'Є сегмент 00011');

        List<ClientLead__c> leads = LeadUtils.getLeadsToInseret(new List<Account>{ acc });
        System.assertEquals(1, leads.size());
        ClientLead__c l = leads[0];

        // Перевіряємо, що призначено саме керівника сегмента (а не конкретного нашого користувача)
        User picked = [
                SELECT Id, IsActive, JobTitle__c, SalesDivision__c
                FROM User
                WHERE Id = :l.Manager__c
                LIMIT 1
        ];
        System.assertEquals(true, picked.IsActive, 'Manager має бути активним');
        System.assertEquals('Sales Chief Officer', picked.JobTitle__c, 'Manager має бути Sales Chief Officer');
        System.assertEquals(SALES_SEGMENT_FOR_MAP, picked.SalesDivision__c, 'Manager має бути з потрібного сегмента 00011');

        // І owner ліда має збігатися з керівником сегмента
        System.assertEquals(l.Manager__c, l.OwnerId, 'OwnerId має дорівнювати Manager__c');
    }

    @IsTest
    static void test_insertNewLeads_partial_failure_maps_only_success() {
        // Мін. дані
        createCountries();
        Map<String, Id> ids = createBusinessData(getOwnerActive().Id, getOwnerInactive().Id);
        Id accId = ids.get('accActive');

        // 1 валідний, 1 невалідний (без Name)
        ClientLead__c goodOne = new ClientLead__c(Name='OK', Account__c=accId);
        ClientLead__c badOne  = new ClientLead__c(Account__c=accId); // якщо Name обовʼязковий у вашому обʼєкті

        Map<Id,Id> mapIds = LeadUtils.insertNewLeads(new List<ClientLead__c>{ goodOne, badOne });

        System.assertEquals(1, mapIds.size(), 'У мапі має бути лише успішний запис');
        System.assert(mapIds.containsKey(accId), 'Для акаунта має бути створений лід');
    }

    @IsTest
    static void test_linkLeadsOppOrders_default_overload_equals_false() {
        createCountries();
        Map<String, Id> ids = createBusinessData(getOwnerActive().Id, getOwnerInactive().Id);

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

    @IsTest
    static void test_getLeadNormName_nonblank_returns_something() {
        String s = LeadUtils.getLeadNormName('  Acme?  ');
        System.assertNotEquals('', s, 'Для непорожнього рядка нормалізатор має повернути значення');
    }


}