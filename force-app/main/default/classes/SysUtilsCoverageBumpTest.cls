@IsTest
private class SysUtilsCoverageBumpTest {

    @IsTest
    static void test_jobs_noop_and_showChildRels() {
        // 1) getJobsInWork() — навіть якщо порожньо, тіло методу покривається
        Map<String, Id> jobs = SysUtils.getJobsInWork();
        System.assertNotEquals(null, jobs, 'Map must be non-null');

        // 2) stopActiveJobs() — дві “ранні” гілки (null та empty)
        SysUtils.stopActiveJobs(null);
        SysUtils.stopActiveJobs(new Set<Id>());

        // 3) showChildRelationships() — загальна гілка (всі = 2)
        List<SysUtils.ChildRelResult> rels = SysUtils.showChildRelationships('Account', 2);
        System.assertNotEquals(null, rels);
        // Не вимагаємо ненульовий розмір (у різних оргах може відрізнятися)
    }

    @IsTest
    static void test_getPicklistFieldMap_error_branches() {
        // A) Невірний об'єкт
        Boolean thrownWrongObj = false;
        try {
            SysUtils.getPicklistFieldMap('NoSuchObject__c', 'Any__c', true);
        } catch (IllegalArgumentException e) {
            thrownWrongObj = e.getMessage().contains('does not exist');
        }
        System.assertEquals(true, thrownWrongObj, 'Should throw on non-existing object');

        // B) Невірне поле
        Boolean thrownWrongField = false;
        try {
            SysUtils.getPicklistFieldMap('Account', 'NoSuchField__c', true);
        } catch (IllegalArgumentException e) {
            thrownWrongField = e.getMessage().contains('does not exist in object');
        }
        System.assertEquals(true, thrownWrongField, 'Should throw on non-existing field');

        // C) Поле не picklist (наприклад, Account.Name)
        Boolean thrownNotPicklist = false;
        try {
            SysUtils.getPicklistFieldMap('Account', 'Name', true);
        } catch (IllegalArgumentException e) {
            thrownNotPicklist = e.getMessage().contains('is not a Picklist');
        }
        System.assertEquals(true, thrownNotPicklist, 'Should throw on non-picklist field');
    }
}