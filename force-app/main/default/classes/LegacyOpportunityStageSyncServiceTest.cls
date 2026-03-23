@IsTest
private class LegacyOpportunityStageSyncServiceTest {

    private static Opportunity createOpp() {
        Opportunity opp = new Opportunity(
            Name = 'Test',
            StageName = 'Qualification',
            CloseDate = Date.today(),
            Id_ERP__c = 'ERP123'
        );
        insert opp;
        return opp;
    }

    private static void ensureCredentials() {
        insert new Credentials__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            User_Login__c = 'test',
            User_Password__c = 'test',
            End_Point__c = 'https://erp.test'
        );
    }

    // 🔴 NULL
    @IsTest
    static void testNullOpp() {
        LegacyOpportunityStageSyncService.SyncResult res =
            LegacyOpportunityStageSyncService.send(null);

        System.assertEquals(false, res.success);
    }

    // 🔴 NO CREDENTIALS
    @IsTest
    static void testMissingCredentials() {

        Opportunity opp = createOpp();

        LegacyOpportunityStageSyncService.SyncResult res =
            LegacyOpportunityStageSyncService.send(opp);

        System.assertEquals(false, res.success);
    }

    // 🔴 LOGIN EXCEPTION
    @IsTest
    static void testLoginException() {

        ensureCredentials();
        Opportunity opp = createOpp();

        Test.setMock(WebServiceMock.class, new ERPWebServiceMock('LOGIN_EXCEPTION'));

        Test.startTest();
        LegacyOpportunityStageSyncService.SyncResult res =
            LegacyOpportunityStageSyncService.send(opp);
        Test.stopTest();

        System.assertEquals(false, res.success);
        System.assert(res.message.contains('LoginEx'));
    }

    // 🔴 EMPTY TICKET
    @IsTest
    static void testEmptyTicket() {

        ensureCredentials();
        Opportunity opp = createOpp();

        Test.setMock(WebServiceMock.class, new ERPWebServiceMock('EMPTY_TICKET'));

        Test.startTest();
        LegacyOpportunityStageSyncService.SyncResult res =
            LegacyOpportunityStageSyncService.send(opp);
        Test.stopTest();

        System.assertEquals(false, res.success);
    }

    // 🟢 SUCCESS
    @IsTest
    static void testSuccessFlow() {

        ensureCredentials();
        Opportunity opp = createOpp();

        Test.setMock(WebServiceMock.class, new ERPWebServiceMock('SUCCESS'));

        Test.startTest();
        LegacyOpportunityStageSyncService.SyncResult res =
            LegacyOpportunityStageSyncService.send(opp);
        Test.stopTest();

        System.assertEquals(true, res.success);
    }

    // 🔴 EXEC FAILURE
    @IsTest
    static void testExecuteFailure() {

        ensureCredentials();
        Opportunity opp = createOpp();

        Test.setMock(WebServiceMock.class, new ERPWebServiceMock('EXEC_FAILURE'));

        Test.startTest();
        LegacyOpportunityStageSyncService.SyncResult res =
            LegacyOpportunityStageSyncService.send(opp);
        Test.stopTest();

        System.assertEquals(false, res.success);
    }

    // 🔴 EXEC EXCEPTION
    @IsTest
    static void testExecuteException() {

        ensureCredentials();
        Opportunity opp = createOpp();

        Test.setMock(WebServiceMock.class, new ERPWebServiceMock('EXEC_EXCEPTION'));

        Test.startTest();
        LegacyOpportunityStageSyncService.SyncResult res =
            LegacyOpportunityStageSyncService.send(opp);
        Test.stopTest();

        System.assertEquals(false, res.success);
    }

    // 🔴 JSON ERROR
    @IsTest
    static void testJsonParseError() {

        ensureCredentials();
        Opportunity opp = createOpp();

        Test.setMock(WebServiceMock.class, new ERPWebServiceMock('JSON_ERROR'));

        Test.startTest();
        LegacyOpportunityStageSyncService.SyncResult res =
            LegacyOpportunityStageSyncService.send(opp);
        Test.stopTest();

        System.assertEquals(false, res.success);
    }
}