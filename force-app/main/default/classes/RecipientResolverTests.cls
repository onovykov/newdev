@IsTest
public class RecipientResolverTests {

    @TestSetup
    static void setup() {
        // 1. СПОЧАТКУ SETUP ОБ'ЄКТИ
        // Використовуємо runAs, щоб виділити це в окремий контекст
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        System.runAs(thisUser) {
            String groupDevName = 'BACKOFFICE_00100';
            // Шукаємо або створюємо групу
            List<Group> existingGroups = [SELECT Id FROM Group WHERE DeveloperName = :groupDevName LIMIT 1];
            Id grpId;

            if (existingGroups.isEmpty()) {
                Group testGrp = new Group(Name = 'Backoffice Steel', DeveloperName = groupDevName);
                insert testGrp;
                grpId = testGrp.Id;
            } else {
                grpId = existingGroups[0].Id;
            }

            // Додаємо юзера в групу
            insert new GroupMember(GroupId = grpId, UserOrGroupId = thisUser.Id);
        }

        // 2. ТЕПЕР DATA ОБ'ЄКТИ (Account, Opportunity)
        // Це вже інший контекст, MIXED DML не буде

        // Створюємо Account
        Account acc = new Account(Name = 'Test Account', MarketSegment__c = '00100');
        insert acc;

        // Створюємо Opportunity
        Opportunity opp = new Opportunity(
                Name = 'Test Opp',
                AccountId = acc.Id,
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(10)
        );
        insert opp;

        // DLRS краще викликати в кінці або взагалі не чіпати в Setup,
        // якщо він не критичний для створення даних
        if (Type.forName('dlrs.RollupService') != null) {
            dlrs.RollupService.rollup(new List<SObject>());
        }
    }

    @IsTest
    static void testResolve_CompleteCoverage() {
        Opportunity opp = [SELECT Id, OwnerId, AccountId FROM Opportunity LIMIT 1];

        setupMockGroup('G_USER_OPP', 'Users', 'OPP_OWNER');
        setupMockGroup('G_USER_ACC', 'Users', 'ACCOUNT_OWNER');
        setupMockGroup('G_USER_SYS', 'Users', 'SYSADMINS');
        setupMockGroup('G_USER_BO',  'Users', 'BACKOFFICE_BY_SEGMENT');
        setupMockGroup('G_USER_HD',  'Users', 'HELPDESK_ADMIN');
        setupMockGroup('G_USER_CH',  'Users', 'SEGMENT_CHIEF');
        setupMockGroup('G_EMAIL',    'Emails', 'test@test.com, dev@test.com');
        setupMockGroup('G_CONTACT',  'Contacts', 'IT_ADMIN_INTERPIPE_UA');
        setupMockGroup('G_INVALID',  'Unknown', 'something');
        setupMockGroup('G_BLANK',    'Users', '');

        NotificationTypes.NotificationEventCfg cfg = new NotificationTypes.NotificationEventCfg();
        cfg.recipientGroupKeys = new List<String>{
                'G_USER_OPP', 'G_USER_ACC', 'G_USER_SYS', 'G_USER_BO',
                'G_USER_HD', 'G_USER_CH', 'G_EMAIL', 'G_CONTACT', 'G_INVALID', 'G_BLANK'
        };

        Test.startTest();
        NotificationTypes.RecipientBundle result = RecipientResolver.resolve(cfg, opp);
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assert(result.emails.contains('test@test.com'));
    }
//
//    @IsTest
//    static void testExpandGroup_Recursive() {
//        // Тут ТЕЖ може бути Mixed DML, тому створюємо групи через runAs
//        System.runAs(new User(Id = UserInfo.getUserId())) {
//            Group parentGrp = new Group(Name = 'Parent', DeveloperName = 'P_GRP');
//            insert parentGrp;
//            Group childGrp = new Group(Name = 'Child', DeveloperName = 'C_GRP');
//            insert childGrp;
//
//            insert new GroupMember(GroupId = parentGrp.Id, UserOrGroupId = childGrp.Id);
//            insert new GroupMember(GroupId = childGrp.Id, UserOrGroupId = UserInfo.getUserId());
//        }
//
//        Account acc = [SELECT Id FROM Account LIMIT 1];
//        acc.MarketSegment__c = 'P_GRP'; // Прив'язуємо до назви групи
//
//        setupMockGroup('NESTED', 'Users', 'BACKOFFICE_BY_SEGMENT');
//
//        NotificationTypes.NotificationEventCfg cfg = new NotificationTypes.NotificationEventCfg();
//        cfg.recipientGroupKeys = new List<String>{'NESTED'};
//
//        Test.startTest();
//        RecipientResolver.resolve(cfg, acc);
//        Test.stopTest();
//    }

    @IsTest
    static void testResolve_NullCfg() {
        Test.startTest();
        NotificationTypes.RecipientBundle result = RecipientResolver.resolve(null, null);
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals('No recipient groups in event cfg', result.resolverTrace);
    }

    @IsTest
    static void testResolve_EmptyRecipientGroups() {
        NotificationTypes.NotificationEventCfg cfg = new NotificationTypes.NotificationEventCfg();
        cfg.recipientGroupKeys = new List<String>();

        Test.startTest();
        NotificationTypes.RecipientBundle result = RecipientResolver.resolve(cfg, null);
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals('No recipient groups in event cfg', result.resolverTrace);
    }

    @IsTest
    static void testResolve_GroupNotFound() {
        NotificationTypes.NotificationEventCfg cfg = new NotificationTypes.NotificationEventCfg();
        cfg.recipientGroupKeys = new List<String>{'NON_EXISTENT_GROUP'};

        Test.startTest();
        NotificationTypes.RecipientBundle result = RecipientResolver.resolve(cfg, null);
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assert(result.resolverTrace.contains('group not found'));
    }

    @IsTest
    static void testResolve_AccountContext() {
        Account acc = [SELECT Id, OwnerId, MarketSegment__c FROM Account LIMIT 1];

        setupMockGroup('G_ACC_OWNER', 'Users', 'ACCOUNT_OWNER');

        NotificationTypes.NotificationEventCfg cfg = new NotificationTypes.NotificationEventCfg();
        cfg.recipientGroupKeys = new List<String>{'G_ACC_OWNER'};

        Test.startTest();
        NotificationTypes.RecipientBundle result = RecipientResolver.resolve(cfg, acc);
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assert(result.userIds.contains(acc.OwnerId));
    }

    @IsTest
    static void testResolveContacts_ITAdminInterpipeUA() {
        Opportunity opp = [SELECT Id, OwnerId, AccountId FROM Opportunity LIMIT 1];

        setupMockGroup('G_IT_ADMIN', 'Contacts', 'IT_ADMIN_INTERPIPE_UA');

        NotificationTypes.NotificationEventCfg cfg = new NotificationTypes.NotificationEventCfg();
        cfg.recipientGroupKeys = new List<String>{'G_IT_ADMIN'};

        Test.startTest();
        NotificationTypes.RecipientBundle result = RecipientResolver.resolve(cfg, opp);
        Test.stopTest();

        System.assertNotEquals(null, result);
        // Має бути викликано ContactRepository.getByAccountAndType
    }

    @IsTest
    static void testResolveContacts_OrdersAdminWithoutOpportunity() {
        setupMockGroup('G_ORDERS_ADMIN', 'Contacts', 'ORDERS_ADMIN_INTERPIPE_UA');

        NotificationTypes.NotificationEventCfg cfg = new NotificationTypes.NotificationEventCfg();
        cfg.recipientGroupKeys = new List<String>{'G_ORDERS_ADMIN'};

        Test.startTest();
        // Без Opportunity контексту - має повернути 0 contacts
        NotificationTypes.RecipientBundle result = RecipientResolver.resolve(cfg, null);
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals(0, result.contactIds.size());
    }

    @IsTest
    static void testResolveEmails_BlankDefinition() {
        setupMockGroup('G_BLANK_EMAIL', 'Emails', '');

        NotificationTypes.NotificationEventCfg cfg = new NotificationTypes.NotificationEventCfg();
        cfg.recipientGroupKeys = new List<String>{'G_BLANK_EMAIL'};

        Test.startTest();
        NotificationTypes.RecipientBundle result = RecipientResolver.resolve(cfg, null);
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals(0, result.emails.size());
    }

    @IsTest
    static void testResolveEmails_MultipleEmails() {
        setupMockGroup('G_MULTI_EMAIL', 'Emails', 'test1@test.com, test2@test.com,  test3@test.com  ');

        NotificationTypes.NotificationEventCfg cfg = new NotificationTypes.NotificationEventCfg();
        cfg.recipientGroupKeys = new List<String>{'G_MULTI_EMAIL'};

        Test.startTest();
        NotificationTypes.RecipientBundle result = RecipientResolver.resolve(cfg, null);
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals(3, result.emails.size());
        System.assert(result.emails.contains('test1@test.com'));
        System.assert(result.emails.contains('test2@test.com'));
        System.assert(result.emails.contains('test3@test.com'));
    }

    @IsTest
    static void testResolveUsers_WithoutOpportunity() {
        setupMockGroup('G_OPP_OWNER', 'Users', 'OPP_OWNER');

        NotificationTypes.NotificationEventCfg cfg = new NotificationTypes.NotificationEventCfg();
        cfg.recipientGroupKeys = new List<String>{'G_OPP_OWNER'};

        Test.startTest();
        // Передаємо null context - не буде opp
        NotificationTypes.RecipientBundle result = RecipientResolver.resolve(cfg, null);
        Test.stopTest();

        System.assertNotEquals(null, result);
        // Не має додати userIds, бо немає opp
        System.assertEquals(0, result.userIds.size());
    }

    @IsTest
    static void testResolveUsers_WithoutAccount() {
        setupMockGroup('G_ACC_OWNER', 'Users', 'ACCOUNT_OWNER');

        NotificationTypes.NotificationEventCfg cfg = new NotificationTypes.NotificationEventCfg();
        cfg.recipientGroupKeys = new List<String>{'G_ACC_OWNER'};

        Test.startTest();
        // Передаємо null context - не буде acc
        NotificationTypes.RecipientBundle result = RecipientResolver.resolve(cfg, null);
        Test.stopTest();

        System.assertNotEquals(null, result);
        // Не має додати userIds, бо немає acc
        System.assertEquals(0, result.userIds.size());
    }

    @IsTest
    static void testResolve_GroupWithBlankKindOrDefinition() {
        setupMockGroup('G_BLANK_KIND', null, 'some definition');
        setupMockGroup('G_BLANK_DEF', 'Users', null);

        NotificationTypes.NotificationEventCfg cfg = new NotificationTypes.NotificationEventCfg();
        cfg.recipientGroupKeys = new List<String>{'G_BLANK_KIND', 'G_BLANK_DEF'};

        Test.startTest();
        NotificationTypes.RecipientBundle result = RecipientResolver.resolve(cfg, null);
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assert(result.resolverTrace.contains('kind/definition is blank'));
    }

    private static void setupMockGroup(String key, String kind, String definition) {
        RecipientGroupRepo.RecipientGroupCfg mock = new RecipientGroupRepo.RecipientGroupCfg();
        mock.key = key;
        mock.kind = kind;
        mock.definition = definition;
        mock.includeInactive = false;
        RecipientGroupRepo.cacheByKey.put(key, mock);
    }
}