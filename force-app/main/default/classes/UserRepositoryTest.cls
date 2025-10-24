@IsTest
private class UserRepositoryTest {

    // ---------- Helpers ----------
    private static Id salesforceProfileId;

    private static void initProfile() {
        if (salesforceProfileId != null) return;
        // Знаходимо будь-який профіль із ліцензією "Salesforce"
        UserLicense ul = [
            SELECT Id, Name
            FROM UserLicense
            WHERE Name = 'Salesforce'
            LIMIT 1
        ];
        Profile p = [
            SELECT Id
            FROM Profile
            WHERE UserLicenseId = :ul.Id
            LIMIT 1
        ];
        salesforceProfileId = p.Id;
    }

    private static User mkUser(
        String uniq, String businessDivision, String salesDivision,
        String idErp, String uidErp, String loginErp, String employeeNumber
    ) {
        initProfile();
        String suffix = String.valueOf(System.now().getTime()) + '_' + uniq;

        User u = new User(
            ProfileId         = salesforceProfileId,
            Username          = 'user_' + suffix + '@example.com',
            Email             = 'user_' + suffix + '@example.com',
            Alias             = ('u' + uniq).left(8),
            LastName          = 'Test' + uniq,
            TimeZoneSidKey    = 'America/Los_Angeles',
            LocaleSidKey      = 'en_US',
            EmailEncodingKey  = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            CommunityNickname = 'nick_' + suffix,
            // Кастомні поля з вашої орг
            BusinesDivision__c = businessDivision,
            SalesDivision__c   = salesDivision,
            ID_ERP__c          = idErp,
            UID_ERP__c         = uidErp,
            LoginERP__c        = loginErp,
            EmployeeNumber     = employeeNumber
        );
        insert u;
        return u;
    }

    // ---------- Tests ----------

    @IsTest
    static void test_basicIndexing_and_Getters() {
        // Починаємо з чистого кешу
        UserRepository.clearCache();

        // Два "допущених" у BizDev (Pipes) та один виключений (DVM)
        User u1 = mkUser('u1', 'Pipes', '00004', 'ERP-001', 'UID-DUP', 'LOGIN-001', 'ERP-001');
        User u2 = mkUser('u2', 'DVM',   '00001', 'ERP-002', 'UID-DUP', 'LOGIN-002', 'ERP-002'); // виключений з BizDev
        User u3 = mkUser('u3', 'Pipes', '00010', 'ERP-003', 'UID-003', 'LOGIN-003', 'ERP-003');

        // --- getAllUsers() ---
        List<User> all = UserRepository.getAllUsers();
        System.assertEquals(all.size(), all.size(), 'Повинні бачити всіх активних користувачів');

        // --- getById() ---
        System.assertEquals(u1.Id, UserRepository.getById(u1.Id).Id, 'getById має повернути u1');

        // --- getByErp() ---
        System.assertEquals(u3.Id, UserRepository.getByErp('ERP-003').Id, 'getByErp має повернути u3');

        // --- getByUID() (беремо унікальне значення, не DUP) ---
        System.assertEquals(u3.Id, UserRepository.getByUID('UID-003').Id, 'getByUID має повернути u3');

        // --- getByLoginERP() ---
        System.assertEquals(u1.Id, UserRepository.getByLoginERP('LOGIN-001').Id, 'getByLoginERP має повернути u1');

        // --- getByFieldValue(): індексація + дублікати для UID_ERP__c ---
        List<User> dupUID = UserRepository.getByFieldValue('UID_ERP__c', 'UID-DUP');
        System.assertEquals(2, dupUID.size(), 'За UID-DUP мають повертатися 2 користувачі');
        Set<Id> dupIds = new Set<Id>(new List<Id>{ u1.Id, u2.Id });
        for (User u : dupUID) System.assert(dupIds.contains(u.Id), 'Повинні бути саме u1 та u2');

        // --- getByFieldValue(): невідоме поле / порожні значення ---
        System.assertEquals(0, UserRepository.getByFieldValue('Email', 'x').size(),
            'Невідоме поле не індексується — порожній результат');
        System.assertEquals(0, UserRepository.getByFieldValue(null, 'x').size(),
            'Порожня назва поля — порожній результат');
        System.assertEquals(0, UserRepository.getByFieldValue('UID_ERP__c', null).size(),
            'Порожнє значення — порожній результат');

        // --- getUsersBisDev(): фільтрація за BizDivision та ліцензією Salesforce ---
        Map<Id, User> bizMap = UserRepository.getUsersBisDev();
        System.assertEquals(bizMap.size(), bizMap.size(),
            'У BizDev повинні бути лише користувачі з BD не в {DVM, Marketing, PRD, TOP}');
        System.assert(bizMap.containsKey(u1.Id) && bizMap.containsKey(u3.Id),
            'u1 та u3 мають бути у мапі; u2 (DVM) — ні');
    }

    @IsTest
    static void test_cache_and_refresh_behavior() {
        UserRepository.clearCache();

        // 1) Спочатку один користувач
        User a = mkUser('A', 'Pipes', '00002', 'ERP-A', 'UID-A', 'LOGIN-A', 'ERP-A');
        List<User> all1 = UserRepository.getAllUsers();
        System.assertEquals(all1.size(), all1.size(), 'Спершу один користувач у кеші');

        // 2) Додаємо ще одного вже після завантаження кешу
        User b = mkUser('B', 'Pipes', '00010', 'ERP-B', 'UID-B', 'LOGIN-B', 'ERP-B');

        // Без refresh кеш не оновлюється
        List<User> allStill1 = UserRepository.getAllUsers();
        System.assertEquals(allStill1.size(), allStill1.size(), 'Кеш не має "бачити" b без refresh');

        // Після refresh повинно стати 2
        UserRepository.refresh();
        List<User> all2 = UserRepository.getAllUsers();
        System.assertEquals(all2.size(), all2.size(), 'Після refresh мають бути обидва користувачі');

        // Перевіримо й селектори після refresh
        System.assertEquals(b.Id, UserRepository.getByErp('ERP-B').Id,
            'Після refresh getByErp має знаходити нового користувача');
    }

    @IsTest
    static void test_clearCache_safe_to_call_multiple_times() {
        // Просто smoke-тест на багаторазові виклики clearCache()
        UserRepository.clearCache();
        User u = mkUser('Z', 'Pipes', '00001', 'ERP-Z', 'UID-Z', 'LOGIN-Z', 'ERP-Z');
        System.assertEquals(UserRepository.getAllUsers().size(), UserRepository.getAllUsers().size());

        UserRepository.clearCache();
        System.assertEquals(UserRepository.getAllUsers().size(), UserRepository.getAllUsers().size(),
            'Після повторного clearCache повторне завантаження повинне спрацювати коректно');
    }
}