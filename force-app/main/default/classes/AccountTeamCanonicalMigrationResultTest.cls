@IsTest
private class AccountTeamCanonicalMigrationResultTest {

    @IsTest
    static void test_merge_and_pretty_string() {

        AccountTeamCanonicalMigrationResult r1 =
            new AccountTeamCanonicalMigrationResult();
        r1.segmentationProcessed = 10;
        r1.inserted = 5;
        r1.errors.add('Error1');

        AccountTeamCanonicalMigrationResult r2 =
            new AccountTeamCanonicalMigrationResult();
        r2.bosProcessed = 3;
        r2.upgraded = 2;
        r2.errors.add('Error2');

        r1.mergeATCM(r2);

        System.assertEquals(10, r1.segmentationProcessed);
        System.assertEquals(3, r1.bosProcessed);
        System.assertEquals(5, r1.inserted);
        System.assertEquals(2, r1.upgraded);
        System.assertEquals(2, r1.errors.size());

        String json = r1.toPrettyString();
        System.assert(json.contains('segmentationProcessed'));
    }
}