@IsTest
private class ApexUtilTest {

    @IsTest
    static void test_getFieldValues_and_getIds() {
        // Test data
        Account a1 = new Account(Name = 'Acme One',  Phone = '111-111');
        Account a2 = new Account(Name = 'Acme Two',  Phone = null);
        Account a3 = new Account(Name = 'Acme Three', Phone = '111-111'); // дубль Phone
        insert new List<Account>{ a1, a2, a3 };

        // Перевірка getFieldValues(SObject[], SObjectField) на Id (через токен)
        Set<String> idsFromToken = ApexUtil.getFieldValues(new SObject[]{a1, a2, a3}, Account.Id);
        System.assertEquals(3, idsFromToken.size(), 'Має повернути всі 3 Id');

        // Перевірка getFieldValues(SObject[], String) на Phone (унікальність + відсів null)
        Set<String> phones = ApexUtil.getFieldValues(new SObject[]{a1, a2, a3}, 'Phone');
        System.assertEquals(1, phones.size(), 'Null має бути відфільтровано, а дублікати зведено до одного значення');
        System.assert(phones.contains('111-111'));

        // Перевірка getIds (повинна повертати ті ж Id)
        Set<String> ids = ApexUtil.getIds(new SObject[]{a1, a2, a3});
        System.assertEquals(idsFromToken, ids, 'getIds має збігатися з getFieldValues по Id');
    }

    @IsTest
    static void test_getPageParam_string_and_integer() {
        // Ініціалізуємо "сторінку" та параметри
        PageReference pr = new PageReference('/apex/fake');
        Test.setCurrentPage(pr);
        ApexPages.currentPage().getParameters().put('q', 'hello');
        ApexPages.currentPage().getParameters().put('limit', '25');
        ApexPages.currentPage().getParameters().put('badInt', 'NaN');

        // String параметр
        System.assertEquals('hello', ApexUtil.getPageParam('q', 'default'), 'Повинен повернути значення параметра');
        System.assertEquals('fallback', ApexUtil.getPageParam('missing', 'fallback'), 'Повинен повернути дефолт для відсутнього параметра');

        // Integer параметр (коректний)
        System.assertEquals(25, ApexUtil.getPageParam('limit', 10), 'Повинен розпарсити ціле число');

        // Integer параметр (некоректний → дефолт)
        System.assertEquals(10, ApexUtil.getPageParam('badInt', 10), 'Некоректне число має повертати дефолт');
        System.assertEquals(99, ApexUtil.getPageParam('absentInt', 99), 'Відсутній параметр має повертати дефолт');
    }

    @IsTest
    static void test_getPicklistFieldMap() {
        // Візьмемо стабільний стандартний пікліст — наприклад, Account.Type
        Map<String, String> mapLblVal = ApexUtil.getPicklistFieldMap('Account', 'Type');

        System.assert(mapLblVal != null, 'Мапа не повинна бути null');
        System.assert(mapLblVal.size() > 0, 'Мапа не повинна бути порожня');

        // Перевіримо, що немає null у ключах/значеннях
        for (String k : mapLblVal.keySet()) {
            System.assertNotEquals(null, k, 'Label не повинен бути null');
            System.assertNotEquals(null, mapLblVal.get(k), 'Value не повинен бути null');
        }
    }

    @IsTest
    static void test_getCreatableFieldsSOQL_and_null_case() {
        // null / '' → повинні повернути null
        System.assertEquals(null, ApexUtil.getCreatableFieldsSOQL('Account', null));
        System.assertEquals(null, ApexUtil.getCreatableFieldsSOQL('Account', '' ));

        // Створимо запис і згенеруємо запит
        Account a = new Account(Name = 'Creatable SOQL Check');
        insert a;

        String q = ApexUtil.getCreatableFieldsSOQL('Account', a.Id);
        System.assert(q != null && q.startsWith('SELECT '), 'Повинен повернути валідний SELECT');
        System.assert(q.contains(' FROM Account '), 'Має містити FROM Account');
        System.assert(q.endsWith(' WHERE ID=\'' + a.Id + '\''), 'Має фільтрувати по конкретному Id');

        // Спробуємо виконати динамічний SOQL і переконатися, що повернувся саме наш запис.
        // Оскільки вибираються лише "creatable" поля, Id може не бути в списку, але Name має бути.
        SObject sobj = Database.query(q);
        System.assertNotEquals(null, sobj, 'Запит має повернути один запис');
        String nameFromQuery = (String) sobj.get('Name');
        System.assertEquals('Creatable SOQL Check', nameFromQuery, 'Повертається саме потрібний запис за Name');
    }
}