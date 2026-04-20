@IsTest
private class AccountCsvQuickImportTest {

    // ---------- HELPERS ----------

    private static User createUser() {

        String uniq = String.valueOf(DateTime.now().getTime()) + Math.random();

        Profile p = [
            SELECT Id
            FROM Profile
            LIMIT 1
        ];

        User u = new User(
            FirstName = 'Test',
            LastName = 'User',
            Alias = ('t' + uniq).substring(0, 8),
            Email = 'test' + uniq + '@example.com',
            Username = 'test' + uniq + '@example.com',
            ProfileId = p.Id,
            TimeZoneSidKey = 'Europe/Bucharest',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ID_ERP__c = uniq
        );

        insert u;
        return u;
    }

    private static Country__c createCountry(String numCode) {
        Country__c c = new Country__c(
            Name = 'Country ' + numCode,
            NumCode__c = numCode,
            A2Code__c = 'TC',
            A3Code__c = 'TC1',
            SysName__c = 'TestCountry'
        );
        insert c;
        return c;
    }

    // ---------- TESTS ----------

    @IsTest
    static void testImportFromCsv_DryRun_Success() {

        User u = createUser();
        createCountry('203');

        String csv =
            'ORG__c,NORG__c,NORG_S__c,Addr__c,CITY__c,CountryCode__c,MarketSegment__c,PostalCode__c,User_ID_ERP__c\n' +
            '999999,VZV STEEL,VZV STEEL,Addr,City,203,00001,72000,' + u.ID_ERP__c;

        Test.startTest();
        AccountCsvQuickImport.ImportResult res =
            AccountCsvQuickImport.importFromCsv(csv, true);
        Test.stopTest();

        System.assertEquals(1, res.totalRows);
        System.assertEquals(1, res.successCount);
        System.assertEquals(0, res.errorCount);
    }

    @IsTest
    static void testImportFromCsv_AccountAlreadyExists() {

        User u = createUser();
        createCountry('203');

        Account acc = new Account(
            Name = 'Existing',
            ID_ERP__c = '999999'
        );
        insert acc;

        String csv =
            'ORG__c,NORG__c,NORG_S__c,Addr__c,CITY__c,CountryCode__c,MarketSegment__c,PostalCode__c,User_ID_ERP__c\n' +
            '999999,Test,Test,Addr,City,203,00001,72000,' + u.ID_ERP__c;

        Test.startTest();
        AccountCsvQuickImport.ImportResult res =
            AccountCsvQuickImport.importFromCsv(csv, true);
        Test.stopTest();

        System.assertEquals(1, res.errorCount);
        System.assert(res.errors[0].message.contains('already exists'));
    }

    @IsTest
    static void testImportFromCsv_UserNotFound() {

        createCountry('203');

        String csv =
            'ORG__c,NORG__c,NORG_S__c,Addr__c,CITY__c,CountryCode__c,MarketSegment__c,PostalCode__c,User_ID_ERP__c\n' +
            '888888,Test,Test,Addr,City,203,00001,72000,NON_EXISTING_USER';

        Test.startTest();
        AccountCsvQuickImport.ImportResult res =
            AccountCsvQuickImport.importFromCsv(csv, true);
        Test.stopTest();

        System.assertEquals(1, res.errorCount);
        System.assert(res.errors[0].message.contains('User not found'));
    }

    @IsTest
    static void testImportFromCsv_CountryNotFound() {

        User u = createUser();

        String csv =
            'ORG__c,NORG__c,NORG_S__c,Addr__c,CITY__c,CountryCode__c,MarketSegment__c,PostalCode__c,User_ID_ERP__c\n' +
            '205431,Test,Test,Addr,City,999,00001,72000,' + u.ID_ERP__c;

        Test.startTest();
        AccountCsvQuickImport.ImportResult res =
            AccountCsvQuickImport.importFromCsv(csv, true);
        Test.stopTest();

        System.assertEquals(1, res.errorCount);
        System.assert(res.errors[0].message.contains('Country not found'));
    }

    @IsTest
    static void testImportFromLatestFileByTitle() {

        User u = createUser();
        createCountry('203');

        String csv =
            'ORG__c,NORG__c,NORG_S__c,Addr__c,CITY__c,CountryCode__c,MarketSegment__c,PostalCode__c,User_ID_ERP__c\n' +
            '205432,Test,Test,Addr,City,203,00001,72000,' + u.ID_ERP__c;

        ContentVersion cv = new ContentVersion(
            Title = 'AccImportTest',
            PathOnClient = 'AccImportTest.csv',
            VersionData = Blob.valueOf(csv)
        );
        insert cv;

        Test.startTest();
        AccountCsvQuickImport.ImportResult res =
            AccountCsvQuickImport.importFromLatestFileByTitle('AccImportTest', true);
        Test.stopTest();

        System.assertEquals(1, res.totalRows);
        System.assertEquals(1, res.successCount);
    }
}