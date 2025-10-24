@IsTest
private class SysUtilsTest {

    @IsTest
    static void test_getMonthName() {
        System.assertEquals('СІЧЕНЬ', SysUtils.getMonthName(1, SysUtils.UA));
        System.assertEquals('JANUARY', SysUtils.getMonthName(1, SysUtils.EN));
        System.assertEquals('', SysUtils.getMonthName(0, SysUtils.EN));
        System.assertEquals('', SysUtils.getMonthName(13, SysUtils.UA));
    }

    @IsTest
    static void test_getPicklistLabel_onStandardField() {
        // Account.Industry — стандартний picklist (label == value у більшості локалей)
        Account a = new Account(Name='A', Industry='Manufacturing');
        String label = SysUtils.getPicklistLabel(a, 'Industry');
        System.assertEquals('Manufacturing', label, 'Should resolve label for Industry picklist value');
    }

    @IsTest
    static void test_isFieldChanged_and_lists() {
        Account oldA = new Account(Name='Old', Industry='Manufacturing', BillingCountry='PL');
        Account newA = new Account(Name='New', Industry='Manufacturing', BillingCountry='PL');

        System.assertEquals(true, SysUtils.isFieldChanged(oldA, newA, 'Name'));
        System.assertEquals(false, SysUtils.isFieldChanged(oldA, newA, 'Industry'));

        List<String> fields = new List<String>{'Name','Industry','BillingCountry'};
        System.assertEquals(true, SysUtils.isAnyFieldChanged(oldA, newA, fields));

        List<String> changed = SysUtils.getChangedFields(oldA, newA, fields);
        System.assertEquals(1, changed.size());
        System.assertEquals('Name', changed[0]);
    }

    @IsTest
    static void test_getObjectFieldsInfo() {
        List<Map<String, Object>> info = SysUtils.getObjectFieldsInfo('Account');
        System.assert(info != null && !info.isEmpty(), 'Fields info should not be empty');
        // Переконаємось, що серед полів є Name
        Boolean hasName = false;
        for (Map<String,Object> m : info) {
            if ((String)m.get('FieldName') == 'Name') { hasName = true; break; }
        }
        System.assertEquals(true, hasName, 'Account.Name must be present');
    }

    private static String norm(String s) {
        // NBSP символ (вставлено буквально між лапками)
        String NBSP = ' ';
        if (s == null) return null;
        // замінити NBSP на звичайний пробіл, стиснути будь-який пробіл/таб/перенос до одного пробілу
        return s.replace(NBSP, ' ').replaceAll('\\s+', ' ').trim();
    }

    @IsTest
    static void test_getSelectFieldsSOQL() {
        String soql = SysUtils.getSelectFieldsSOQL('Account',
                        new List<String>{'Id','Name'}, 'BillingCountry = \'PL\'');

        String expected = 'SELECT Id,Name FROM Account WHERE BillingCountry = \'PL\'';

        System.assertEquals(norm(expected), norm(soql));
    }

    @IsTest
    static void test_trimToNearestSlash() {
        System.assertEquals('A/B/', SysUtils.trimToNearestSlash('A / B / C', 4));
        System.assertEquals('', SysUtils.trimToNearestSlash('ABC', 2)); // без слешів — порожньо
        System.assertEquals('A/B/C', SysUtils.trimToNearestSlash('A/B/C', 20)); // коротше за ліміт — як є
    }

    @IsTest
    static void test_getSortedKeyPrefixes_and_getIdPrefixMap() {
        Map<String,String> sorted = SysUtils.getSortedKeyPrefixes();
        System.assert(sorted != null && !sorted.isEmpty());
        // Для Account стандартно 001
        System.assertEquals('Account', sorted.get('001'));

        Map<String,String> idMap = SysUtils.getIdPrefixMap();
        System.assertEquals('Account', idMap.get('001'));
    }

    @IsTest
    static void test_shortenSteelGrade() {
        System.assertEquals('A/B', SysUtils.shortenSteelGrade(' A / B / C ', 2));
        System.assertEquals('A;B', SysUtils.shortenSteelGrade('A ; B ; C', 2).replace('/', ';')); // для ; теж стискає
        System.assertEquals('A/B/C', SysUtils.shortenSteelGrade('A/B/C', 5)); // partsCount > фактичного
        System.assertEquals('A/B/C', SysUtils.shortenSteelGrade('A/B/C (note) [x] {y}', 5));
    }

    @IsTest
    static void test_getObjLngVer_safe() {
        // Не перевіряємо конкретну мову — лише що метод повертає щось із mapLangConv або ''
        String res = SysUtils.getObjLngVer(UserInfo.getUserId());
        System.assertNotEquals(null, res);
    }

    @IsTest
    static void test_getFields_and_getSimpleSqlString() {
        List<SysUtils.FieldInfo> fi = SysUtils.getFields('Account');
        System.assert(!fi.isEmpty());
        Boolean seenName = false;
        for (SysUtils.FieldInfo f : fi) if (f.apiName == 'Name') { seenName = true; break; }
        System.assertEquals(true, seenName);

        // Випадок з явним переліком полів
        String s1 = SysUtils.getSimpleSqlString('Account', null, new List<String>{'Id','Name'}, null);
        System.assertEquals('SELECT Id,Name FROM Account', s1);

        // Випадок з '*'
        String s2 = SysUtils.getSimpleSqlString('Account', '*', null, new List<String>{'OwnerId'});
        System.assert(s2.startsWith('SELECT '));
        System.assert(s2.contains('OwnerId'));
        System.assert(s2.endsWith(' FROM Account'));
    }

    @IsTest
    static void test_getActiveJobsNames_nullsafe() {
        System.assertEquals(new Set<String>(), SysUtils.getActiveJobsNames(null));
        System.assertEquals(new Set<String>(), SysUtils.getActiveJobsNames(new Map<String,Id>()));
        Map<String,Id> m = new Map<String,Id>{ 'BatchA' => '707000000000001AAA' };
        Set<String> names = SysUtils.getActiveJobsNames(m);
        System.assertEquals(1, names.size());
        System.assertEquals(true, names.contains('BatchA'));
    }

    @IsTest
    static void test_isACMEnabled_no_throw() {
        // Значення залежить від налаштувань орґу; головне — метод не падає
        Boolean acm = SysUtils.isACMEnabled();
        System.assertNotEquals(null, acm);
    }

    @IsTest
    static void test_getSegmentName_guard() {
        String res = SysUtils.getSegmentName('ANY');
        System.assertNotEquals(null, res); // '' або будь-що інше — головне не null
    }
}