@IsTest
private class OpportunityCsvQuickImportTest {

    private static User createTestUser(String uniqueSuffix) {
        Profile p = [
            SELECT Id
            FROM Profile
            WHERE Name = 'Standard User'
            LIMIT 1
        ];

        User u = new User(
            FirstName = 'Test',
            LastName = 'User' + uniqueSuffix,
            Alias = ('tu' + uniqueSuffix).left(8),
            Email = 'testuser' + uniqueSuffix + '@example.com',
            Username = 'testuser' + uniqueSuffix + '@example.com.' + System.currentTimeMillis(),
            ProfileId = p.Id,
            TimeZoneSidKey = 'Europe/Bucharest',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ID_ERP__c = uniqueSuffix
        );
        insert u;
        return u;
    }

    private static Account createTestAccount(String erpId, String name) {
        Account a = new Account(
            Name = name,
            ID_ERP__c = erpId
        );
        insert a;
        return a;
    }

    private static Country__c createTestCountry(String numCode, String name, String a2Code, String a3Code) {
        Country__c c = new Country__c(
            Name = name,
            NumCode__c = numCode,
            A2Code__c = a2Code,
            A3Code__c = a3Code
        );
        insert c;
        return c;
    }

    private static RecordType getOpportunityRecordType() {
        return [
            SELECT Id, DeveloperName
            FROM RecordType
            WHERE SObjectType = 'Opportunity'
            AND IsActive = true
            LIMIT 1
        ];
    }

    private static String buildCsv(String recordTypeDevName) {
        List<String> lines = new List<String>();

        lines.add('AccountId,MarketSegment,Region,Owner,AssignedBOS,Country,RecordType,Name,StageName,CloseDate');
        lines.add('ERP_ACC_1,SEG_A,EU,ERP_OWNER_1,ERP_BOS_1,840,' + recordTypeDevName + ',"Valid Opp",Prospecting,2026-04-14');
        lines.add('ERP_ACC_MISSING,SEG_B,EU,ERP_OWNER_1,ERP_BOS_1,840,' + recordTypeDevName + ',"Missing Account Opp",Prospecting,2026-04-14');

        return String.join(lines, '\n');
    }

    @IsTest
    static void testImportFromCsv_DryRun_WithErrors() {
        User ownerUser = createTestUser('ERP_OWNER_1');
        User bosUser = createTestUser('ERP_BOS_1');
        Account acc = createTestAccount('ERP_ACC_1', 'Test Account 1');
        Country__c country = createTestCountry('840', 'USA', 'US', 'USA');
        RecordType rt = getOpportunityRecordType();

        String csvText = buildCsv(rt.DeveloperName);

        Test.startTest();
        OpportunityCsvQuickImport.ImportResult res =
            OpportunityCsvQuickImport.importFromCsv(csvText, true);
        Test.stopTest();

        System.assertEquals(2, res.totalRows, 'Total rows should be 2');
        System.assertEquals(1, res.successCount, 'One row should be prepared successfully in dry run');
        System.assertEquals(1, res.errorCount, 'One row should fail');
        System.assertEquals(1, res.errors.size(), 'Should contain one collected error');

        System.assertEquals(3, res.errors[0].rowNum, 'Second data row should be row 3 in CSV');
        System.assert(res.errors[0].message.contains('Account not found'), 'Error should mention missing account');
        System.assertEquals('ERP_ACC_MISSING', res.errors[0].accountErp, 'Missing account ERP should be captured');
        System.assertEquals('ERP_OWNER_1', res.errors[0].ownerErp, 'Owner ERP should be captured');
        System.assertEquals('ERP_BOS_1', res.errors[0].assignedBosErp, 'Assigned BOS ERP should be captured');
        System.assertEquals('840', res.errors[0].countryNumCode, 'Country should be captured');
        System.assertEquals('Missing Account Opp', res.errors[0].opportunityName, 'Opportunity name should be captured');
    }

    @IsTest
    static void testBuildErrorsCsv() {
        OpportunityCsvQuickImport.ImportResult res = new OpportunityCsvQuickImport.ImportResult();
        res.errorCount = 1;
        res.errors.add(
            new OpportunityCsvQuickImport.ImportError(
                5,
                '205374',
                '44538',
                '45715',
                '840',
                'Europe_RT',
                'Some Opportunity',
                'Account not found: 205374'
            )
        );

        String csv = OpportunityCsvQuickImport.buildErrorsCsv(res);

        System.assert(csv.startsWith('RowNum,AccountId,Owner,AssignedBOS,Country,RecordType,Name,Message'),
            'CSV should contain header');
        System.assert(csv.contains('"205374"'), 'CSV should contain AccountId');
        System.assert(csv.contains('"Account not found: 205374"'), 'CSV should contain message');
        System.assert(csv.contains('"Some Opportunity"'), 'CSV should contain opportunity name');
    }

    @IsTest
    static void testSaveErrorsCsvAsFile() {
        OpportunityCsvQuickImport.ImportResult res = new OpportunityCsvQuickImport.ImportResult();
        res.errorCount = 1;
        res.errors.add(
            new OpportunityCsvQuickImport.ImportError(
                7,
                '205350',
                '44538',
                '45715',
                '840',
                'Europe_RT',
                'Another Opportunity',
                'Account not found: 205350'
            )
        );

        Test.startTest();
        Id cvId = OpportunityCsvQuickImport.saveErrorsCsvAsFile('OppImport_Errors_Test', res);
        Test.stopTest();

        System.assertNotEquals(null, cvId, 'ContentVersion Id should be returned');

        ContentVersion cv = [
            SELECT Id, Title, PathOnClient, VersionData
            FROM ContentVersion
            WHERE Id = :cvId
            LIMIT 1
        ];

        System.assertEquals('OppImport_Errors_Test', cv.Title, 'Title should match');
        System.assertEquals('OppImport_Errors_Test.csv', cv.PathOnClient, 'PathOnClient should match');

        String savedCsv = cv.VersionData.toString();
        System.assert(savedCsv.contains('Account not found: 205350'), 'Saved file should contain error text');
    }

    @IsTest
    static void testImportFromLatestFileByTitle_DryRun() {
        User ownerUser = createTestUser('ERP_OWNER_1X');
        User bosUser = createTestUser('ERP_BOS_1X');
        Account acc = createTestAccount('ERP_ACC_1', 'Test Account File');
        Country__c country = createTestCountry('840', 'USA', 'US', 'USA');
        RecordType rt = getOpportunityRecordType();

        String csvText =
            'AccountId,MarketSegment,Region,Owner,AssignedBOS,Country,RecordType,Name,StageName,CloseDate\n' +
            'ERP_ACC_1,SEG_A,EU,ERP_OWNER_1X,ERP_BOS_1X,840,' + rt.DeveloperName + ',"File Opp",Prospecting,2026-04-14';

        ContentVersion cv = new ContentVersion(
            Title = 'OppImport_Test_File',
            PathOnClient = 'OppImport_Test_File.csv',
            VersionData = Blob.valueOf(csvText)
        );
        insert cv;

        Test.startTest();
        OpportunityCsvQuickImport.ImportResult res =
            OpportunityCsvQuickImport.importFromLatestFileByTitle('OppImport_Test_File', true);
        Test.stopTest();

        System.assertEquals(1, res.totalRows, 'Should read one data row from file');
        System.assertEquals(1, res.successCount, 'One row should be prepared successfully');
        System.assertEquals(0, res.errorCount, 'No errors expected');
    }
}