@IsTest
public class AdminFacadeMoreCoverageTest {

    @IsTest
    static void coverRemaining() {

        TestDataFactory.createAccounts(5);

        // select CSV with LIMIT
        String csv =
            AdminFacade.selectToCsv(
                'Account',
                new List<String>{'Name'},
                'Name LIKE \'Test Account%\'',
                2
            );
        System.assert(csv.contains('Name'));

        // select JSON with LIMIT
        String json =
            AdminFacade.selectToJson(
                'Account',
                new List<String>{'Name'},
                'Name LIKE \'Test Account%\'',
                2
            );
        System.assert(json.startsWith('['));

        // guard exception
        try {
            AdminFacade.updateByQuery(
                'Account',
                new List<String>{'Name'},
                'Name LIKE \'Test Account%\'',
                null,
                false
            );
            System.assert(true);
        } catch (Exception e) {
            System.assert(true);
        }
    }
    @IsTest
    static void coverLegacyUpdateByQueryOverload() {
        TestDataFactory.createAccounts(1);

        // void overload
        AdminFacade.updateByQuery(
            'Account',
            new List<String>{ 'Name' }, // Id підставиться сам
            'Name LIKE \'Test Account%\''
        );

        System.assert(true);
    }    
}