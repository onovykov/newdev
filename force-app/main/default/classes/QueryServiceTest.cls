@IsTest
public class QueryServiceTest {

    @IsTest
    static void testSelectRecords_basic() {
        TestDataFactory.createAccounts(3);

        List<SObject> res =
            QueryService.selectRecords(
                'Account',
                new List<String>{ 'Id', 'Name' },
                'Name LIKE \'Test Account%\'',
                10
            );

        System.assertEquals(3, res.size());
    }

    @IsTest
    static void testSelectRecords_limit() {
        TestDataFactory.createAccounts(5);

        List<SObject> res =
            QueryService.selectRecords(
                'Account',
                new List<String>{ 'Id' },
                null,
                2
            );

        System.assertEquals(2, res.size());
    }
}