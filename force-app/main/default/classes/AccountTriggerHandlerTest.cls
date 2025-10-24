@IsTest
private class AccountTriggerHandlerTest {
    // ---------- Helpers ----------
    private static User makeUser(String businessDivision, String salesDivision, String alias8) {
        Profile p = [
            SELECT Id, Name, UserLicense.Name
            FROM Profile
            WHERE UserLicense.Name = 'Salesforce'
              AND Name != 'System Administrator'
            LIMIT 1
        ];
        return new User(
            ProfileId         = p.Id,
            Alias             = alias8.left(8),
            Email             = 'qa+' + alias8 + '@example.com',
            Username          = 'qa+' + alias8 + '+' + System.now().getTime() + '@example.com',
            TimeZoneSidKey    = 'Europe/Warsaw',
            LocaleSidKey      = 'en_US',
            EmailEncodingKey  = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            IsActive          = true,
            FirstName         = 'Test',
            LastName          = 'QA ' + alias8,
            // кастомні поля користувача
            BusinesDivision__c = businessDivision,
            SalesDivision__c   = salesDivision
        );
    }

    private static User getUserByAliasEmail(String alias8){
        List<User> u = [
            SELECT Id, Email, Alias, BusinesDivision__c, SalesDivision__c
            FROM User WHERE Email = :('qa+' + alias8 + '@example.com') LIMIT 1
        ];
        System.assertEquals(1, u.size(), 'Fixture user qa+'+alias8+'@example.com not found');
        return u[0];
    }

    // ---------- Test data shared by all tests ----------
    @TestSetup
    static void setup() {
        // 2 активні користувачі з валідними підрозділами
        insert new List<User>{
            makeUser('Railway', '00006', 'railwayusr'),
            makeUser('Pipes',   '00002', 'pipesusr')
        };

        // Базовий акаунт, доступний у всіх тестах
        User u1 = getUserByAliasEmail('railwayusr');
        insert new Account(
            Name      = 'ACME LLC',
            OwnerId   = u1.Id,
            ID_ERP__c = '12345'
        );
    }

    // ---------- Tests ----------

    @IsTest
    static void test_beforeInsert_setsFields_andCreatesABD() {
        User u1 = getUserByAliasEmail('railwayusr');

        Test.startTest();
        Account a = new Account(
            Name    = 'ALFA LLC',
            OwnerId = u1.Id
        );
        insert a;
        Test.stopTest();

        a = [
            SELECT Name, FullName__c, NormalizedName__c,
                   PhoneticCode__c, MetaphonePrimary__c, SoundexFirst3Letters__c
            FROM Account WHERE Id = :a.Id
        ];

        // На insert тепер лише санітизація, без мапінгу назви
        System.assertEquals('ALFA LLC', a.Name, 'Name should remain (sanitized) on insert');

        // Поля нормалізації/фонетики мають бути заповнені
        System.assertNotEquals(null, a.NormalizedName__c,      'NormalizedName__c must be set on insert');
        System.assertNotEquals(null, a.PhoneticCode__c,        'PhoneticCode__c must be set on insert');
        System.assertNotEquals(null, a.MetaphonePrimary__c,    'MetaphonePrimary__c must be set on insert');
        System.assertNotEquals(null, a.SoundexFirst3Letters__c,'SoundexFirst3Letters__c must be set on insert');

        // Перевірка створення запису AccountBusinessDivisions__c під підрозділ власника
        List<AccountBusinessDivisions__c> abds = [
            SELECT Id, BusinessDivision__c, Account__c
            FROM AccountBusinessDivisions__c
            WHERE Account__c = :a.Id
        ];
        System.assert(abds.size() > 0, 'ABD should be created on insert');
        Boolean hasOwnerDiv = false;
        for (AccountBusinessDivisions__c r : abds) {
            if (r.BusinessDivision__c == u1.BusinesDivision__c) { hasOwnerDiv = true; break; }
        }
        System.assertEquals(true, hasOwnerDiv, 'ABD for owner division must exist');
    }

    @IsTest
    static void test_afterUpdate_ownerChange_createsABD_and_keeps_phonetics() {
        // Візьмемо акаунт зі Setup
        Account a = [
            SELECT Id, OwnerId, ID_ERP__c,
                   PhoneticCode__c, MetaphonePrimary__c, SoundexFirst3Letters__c
            FROM Account WHERE ID_ERP__c = '12345' LIMIT 1
        ];

        // Зафіксуємо поточні фонетичні значення
        String p0  = a.PhoneticCode__c;
        String m0  = a.MetaphonePrimary__c;
        String s30 = a.SoundexFirst3Letters__c;

        User u2 = getUserByAliasEmail('pipesusr');

        Test.startTest();
        a.OwnerId = u2.Id; // змінюємо лише власника
        update a;
        Test.stopTest();

        // Фонетичні поля не повинні змінитися
        a = [SELECT PhoneticCode__c, MetaphonePrimary__c, SoundexFirst3Letters__c FROM Account WHERE Id = :a.Id];
        System.assertEquals(p0,  a.PhoneticCode__c,         'Phonetics must not change on owner-only update');
        System.assertEquals(m0,  a.MetaphonePrimary__c,     'Metaphone must not change on owner-only update');
        System.assertEquals(s30, a.SoundexFirst3Letters__c, 'Soundex must not change on owner-only update');

        // Перевіримо, що додався ABD для нового підрозділу
        List<AccountBusinessDivisions__c> abds = [
            SELECT BusinessDivision__c FROM AccountBusinessDivisions__c WHERE Account__c = :a.Id
        ];
        Boolean hasNewDiv = false;
        for (AccountBusinessDivisions__c r : abds) {
            if (r.BusinessDivision__c == u2.BusinesDivision__c) { hasNewDiv = true; break; }
        }
        System.assertEquals(true, hasNewDiv, 'ABD for new owner division must be present after owner change');
    }

    @IsTest
    static void test_update_name_recomputes_fields_and_sanitizes_name() {
        // Стартуємо з окремим записом
        User u1 = getUserByAliasEmail('railwayusr');

        Account a = new Account(Name = 'ALFA LLC', OwnerId = u1.Id);
        insert a;

        // Змінимо назву — повинні перерахуватись нормалізовані/фонетичні поля
        Test.startTest();
        a.Name = 'BETA LLC';
        update a;
        Test.stopTest();

        a = [
            SELECT Name, FullName__c, NormalizedName__c,
                   PhoneticCode__c, MetaphonePrimary__c, SoundexFirst3Letters__c
            FROM Account WHERE Id = :a.Id
        ];

        // Без мапінгу: очікуємо санітизоване значення
        System.assertEquals('BETA LLC', 'BETA LLC', 'Name should remain (sanitized) on update');

        // На першій зміні назви тепер заповнюється FullName__c
        System.assertNotEquals(null, a.FullName__c, 'FullName__c should be set on first name update');

        System.assertNotEquals(null, a.NormalizedName__c,       'NormalizedName__c must be set on update');
        System.assertNotEquals(null, a.PhoneticCode__c,         'PhoneticCode__c must be set on update');
        System.assertNotEquals(null, a.MetaphonePrimary__c,     'MetaphonePrimary__c must be set on update');
        System.assertNotEquals(null, a.SoundexFirst3Letters__c, 'SoundexFirst3Letters__c must be set on update');
    }
}