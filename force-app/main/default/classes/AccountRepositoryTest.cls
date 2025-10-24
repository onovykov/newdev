@IsTest
private class AccountRepositoryTest {

    @testSetup
    static void seed() {
        // Базові акаунти для індексації
        insert new Account(
            Name = 'Acme Sp. z o.o.',
            ID_ERP__c = 'ERP-001',
            NormalizedName__c = 'ACME',
            PhoneticCode__c = 'ACM',
            MetaphonePrimary__c = 'AKM',
            MetaphoneAlternate__c = 'AKM',
            NYSIISFirstCode__c = 'AC',
            NYSIIS__c = 'AC',
            SoundexFirst3Letters__c = 'A250',
            SoundexFirstWord__c = 'A250',
            SoundexAllWords__c = 'A250'
        );
        insert new Account(
            Name = 'Acme Steel',
            ID_ERP__c = 'ERP-002',
            NormalizedName__c = 'ACME STEEL',
            PhoneticCode__c = 'ACM',
            MetaphonePrimary__c = 'AKM',
            MetaphoneAlternate__c = 'AKM',
            NYSIISFirstCode__c = 'AS',
            NYSIIS__c = 'AS',
            SoundexFirst3Letters__c = 'A250',
            SoundexFirstWord__c = 'A250',
            SoundexAllWords__c = 'A250'
        );
    }

    @IsTest
    static void test_getters_and_indexing_basic() {
        // Будуємо кеш та індекси
        AccountRepository.refresh();

        // 1) getAllAccounts()
        List<Account> all = AccountRepository.getAllAccounts();
        System.assertEquals(2, all.size(), 'Очікуємо 2 акаунти з @testSetup');

        // 2) getByErp() + getById()
        Account a1 = AccountRepository.getByErp('ERP-001');
        System.assertNotEquals(null, a1, 'Має знайти ERP-001');
        Account a1byId = AccountRepository.getById(a1.Id);
        System.assertEquals(a1.Id, a1byId.Id, 'getById має повертати той самий запис');

        // 3) getByFieldValue() по індексованих полях
        // NormalizedName__c
        List<Account> byNorm = AccountRepository.getByFieldValue('NormalizedName__c', 'ACME STEEL');
        System.assertEquals(1, byNorm.size(), 'ACME STEEL має бути індексовано');
        // PhoneticCode__c
        List<Account> byPh = AccountRepository.getByFieldValue('PhoneticCode__c', 'ACM');
        System.assertEquals(2, byPh.size(), 'ACM мали отримати для обох акаунтів');

        // 4) Неіндексоване поле → порожній результат
        List<Account> byName = AccountRepository.getByFieldValue('Name', 'Acme Steel');
        System.assertEquals(0, byName.size(), 'Name не індексується — очікуємо 0');

        // 5) Порожні аргументи → порожній результат
        System.assertEquals(0, AccountRepository.getByFieldValue(null, 'X').size());
        System.assertEquals(0, AccountRepository.getByFieldValue('NormalizedName__c', null).size());
        System.assertEquals(0, AccountRepository.getByFieldValue('', '').size());
    }

    @IsTest
    static void test_cache_refresh_behavior() {
        // 1) Перше завантаження
        AccountRepository.refresh();

        // 2) Вставляємо новий акаунт ПІСЛЯ побудови кешу
        insert new Account(
            Name = 'Omega LLC',
            ID_ERP__c = 'ERP-003',
            NormalizedName__c = 'OMEGA',
            PhoneticCode__c = 'OMG',
            MetaphonePrimary__c = 'OMG',
            MetaphoneAlternate__c = 'OMG',
            NYSIISFirstCode__c = 'OM',
            NYSIIS__c = 'OM',
            SoundexFirst3Letters__c = 'O520',
            SoundexFirstWord__c = 'O520',
            SoundexAllWords__c = 'O520'
        );

        // 3) Без refresh() нового запису в кеші немає
        System.assertEquals(null, AccountRepository.getByErp('ERP-003'),
            'Без refresh() ERP-003 ще не в індексі');

        // 4) Після refresh() — з’являється
        AccountRepository.refresh();
        System.assertNotEquals(null, AccountRepository.getByErp('ERP-003'),
            'Після refresh() ERP-003 має знайтись');
    }
}