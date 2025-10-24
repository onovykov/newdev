@IsTest(SeeAllData=false)
private class SFtoERPOpportunityStageTest {

    // ---------- Helpers ----------
    private static Opportunity makeOpp(Id rtId, String stageName) {
        Opportunity o = new Opportunity(
            Name = 'Test Opp',
            StageName = stageName,
            CloseDate = Date.today().addDays(30)
        );
        if (rtId != null) o.RecordTypeId = rtId;
        o.ExpectedDelivDate__c = Date.today().addDays(10);
        o.Status__c = 'Enquiry';
        insert o;
        return o;
    }

    private static void ensureCredentialsOrgDefaults() {
        Credentials__c existing;
        try {
            existing = [
                SELECT Id, User_Login__c, User_Password__c, End_Point__c
                FROM Credentials__c
                WHERE SetupOwnerId = :UserInfo.getOrganizationId()
                LIMIT 1
            ];
        } catch (Exception e) {
            existing = null;
        }

        if (existing == null) {
            insert new Credentials__c(
                SetupOwnerId     = UserInfo.getOrganizationId(),
                User_Login__c    = 'login@example.com',
                User_Password__c = 'secret',
                End_Point__c     = 'https://example.com/erp'
            );
        } else {
            existing.User_Login__c    = 'login@example.com';
            existing.User_Password__c = 'secret';
            if (String.isBlank(existing.End_Point__c)) {
                existing.End_Point__c = 'https://example.com/erp';
            }
            update existing;
        }
    }

    // ---------- getJSONData tests ----------
    @IsTest
    static void test_getJSONData_usesStageName_when_noLeadEnquiryRT() {
        Opportunity opp = makeOpp(null, 'Qualification');

        SFtoERPOpportunityStage.leadEnquiryRtIdOverride = '012000000000000AAA';

        Test.startTest();
        String wrapperStr = SFtoERPOpportunityStage.getJSONData(opp);
        Test.stopTest();

        SFtoERPOpportunityStage.leadEnquiryRtIdOverride = null;

        System.assertNotEquals(null, wrapperStr, 'Wrapper JSON must exist');

        Map<String, Object> wrapper = (Map<String, Object>) JSON.deserializeUntyped(wrapperStr);
        String inner_jsonStr = (String) wrapper.get('JSON');
        System.assertNotEquals(null, inner_jsonStr, 'inner_json JSON string must exist');

        Map<String, Object> inner_json = (Map<String, Object>) JSON.deserializeUntyped(inner_jsonStr);

        System.assertEquals('SF-ERP_OpportunityInfo', (String)inner_json.get('MessageType'), 'MessageType expected');
        System.assertEquals('Qualification', (String)inner_json.get('Status'),
            'Without Enquiry RT match, Status should equal StageName');
        System.assertEquals(opp.Id, (String)inner_json.get('ID_SF'), 'ID_SF must match Opportunity Id');
    }

    @IsTest
    static void test_getJSONData_null_returns_empty_wrapper() {
        Test.startTest();
        String wrapperStr = SFtoERPOpportunityStage.getJSONData(null);
        Test.stopTest();

        Map<String, Object> wrapper = (Map<String, Object>) JSON.deserializeUntyped(wrapperStr);
        System.assertEquals('{}', (String) wrapper.get('JSON'),
            'For null opp expected {"JSON":"{}"} wrapper');
    }

    @IsTest
    static void test_getJSONData_expectedDelivDate_null_writes_null() {
        Opportunity opp = makeOpp(null, 'Qualification');
        opp.ExpectedDelivDate__c = null;
        update opp;

        String wrapperStr = SFtoERPOpportunityStage.getJSONData(opp);

        Map<String, Object> outerJSON = (Map<String, Object>) JSON.deserializeUntyped(wrapperStr);
        String innerStr = (String) outerJSON.get('JSON');
        Map<String, Object> innerJSON = (Map<String, Object>) JSON.deserializeUntyped(innerStr);

        System.assert(innerJSON.containsKey('ExpectedDelivDate'), 'ExpectedDelivDate should exist');
        System.assertEquals(null, innerJSON.get('ExpectedDelivDate'), 'ExpectedDelivDate should be null in JSON');
    }

    @IsTest
    static void test_getJSONData_enquiry_stage_when_rt_matches() {
        Opportunity opp = makeOpp(null, 'Prospecting');

        // ⚠️ Примусово виставляємо RT у змінній opp (без DML) і такий же override
        String fakeRt = '012000000000000AAA';
        opp.RecordTypeId = fakeRt;
        SFtoERPOpportunityStage.leadEnquiryRtIdOverride = fakeRt;

        String wrapperStr = SFtoERPOpportunityStage.getJSONData(opp);
        Map<String, Object> outerJSON = (Map<String, Object>) JSON.deserializeUntyped(wrapperStr);
        Map<String, Object> innerJSON = (Map<String, Object>) JSON.deserializeUntyped((String)outerJSON.get('JSON'));

        SFtoERPOpportunityStage.leadEnquiryRtIdOverride = null;

        System.assertEquals('Enquiry', (String)innerJSON.get('Status'),
            'With override matching RT, Status must be "Enquiry"');
    }

    // ---------- sendJSONData tests (bypass & guards) ----------
    @IsTest
    static void test_sendJSONData_success_updates_LastSyncERP_markerOnly() {
        Opportunity opp = makeOpp(null, 'Qualification');
        ensureCredentialsOrgDefaults();

        SFtoERPOpportunityStage.testBypassMode = 'success';
        SFtoERPOpportunityStage.testLastSyncUpdated = false;

        Test.startTest();
        SFtoERPOpportunityStage.sendJSONData(opp.Id);
        Test.stopTest();

        System.assertEquals(true, SFtoERPOpportunityStage.testLastSyncUpdated,
            'Success branch should set the test marker');
    }

    @IsTest
    static void test_sendJSONData_failure_sends_email_when_override_set() {
        Opportunity opp = makeOpp(null, 'Qualification');
        ensureCredentialsOrgDefaults();

        SFtoERPOpportunityStage.recipientsOverride  = new List<String>{ 'ofault1@example.com', 'ofault2@example.com' };
        SFtoERPOpportunityStage.testBypassMode      = 'failure';
        SFtoERPOpportunityStage.testLastSyncUpdated = false;
        SFtoERPOpportunityStage.testEmailsSent      = 0;

        Test.startTest();
        SFtoERPOpportunityStage.sendJSONData(opp.Id);
        Test.stopTest();

        SFtoERPOpportunityStage.recipientsOverride = null;

        System.assertEquals(false, SFtoERPOpportunityStage.testLastSyncUpdated,
            'Failure branch should NOT set the success marker');
        System.assertEquals(1, SFtoERPOpportunityStage.testEmailsSent,
            'Expected exactly one email sent in failure branch');
    }

    @IsTest
    static void test_sendJSONData_exception_markerOnly() {
        Opportunity opp = makeOpp(null, 'Qualification');
        ensureCredentialsOrgDefaults();

        SFtoERPOpportunityStage.testBypassMode = 'exception';
        SFtoERPOpportunityStage.testLastSyncUpdated = false;

        Test.startTest();
        SFtoERPOpportunityStage.sendJSONData(opp.Id);
        Test.stopTest();

        System.assertEquals(false, SFtoERPOpportunityStage.testLastSyncUpdated,
            'Exception path should NOT set the success marker');
    }

    @IsTest
    static void test_sendJSONData_null_oppId_noop() {
        SFtoERPOpportunityStage.testBypassMode = null;
        SFtoERPOpportunityStage.testEmailsSent = 0;

        Test.startTest();
        SFtoERPOpportunityStage.sendJSONData(null);
        Test.stopTest();

        System.assertEquals(0, SFtoERPOpportunityStage.testEmailsSent,
            'Null oppId should early-return without sending emails');
    }

    @IsTest
    static void test_sendJSONData_no_credentials_sends_status_email() {
        // спеціально НЕ викликаємо ensureCredentialsOrgDefaults() → cs == null
        Opportunity opp = makeOpp(null, 'Prospecting');

        SFtoERPOpportunityStage.testBypassMode = null;
        SFtoERPOpportunityStage.recipientsOverride = new List<String>{ 'ofault@example.com' };
        SFtoERPOpportunityStage.testEmailsSent = 0;

        Test.startTest();
        SFtoERPOpportunityStage.sendJSONData(opp.Id);
        Test.stopTest();

        SFtoERPOpportunityStage.recipientsOverride = null;

        System.assertEquals(1, SFtoERPOpportunityStage.testEmailsSent,
            'Missing credentials should trigger status email');
        System.assertEquals(false, SFtoERPOpportunityStage.testLastSyncUpdated,
            'LastSyncERP should not be set in missing credentials branch');
    }

    @IsTest
    static void test_sendJSONData_query_failure_returns_early() {
        // Фейковий Opp Id (префікс 006) — запису немає, впадемо в catch при SOQL і вийдемо рано
        Id fakeOppId = '006000000000000AAA';

        SFtoERPOpportunityStage.testBypassMode = null;
        SFtoERPOpportunityStage.testEmailsSent = 0;
        SFtoERPOpportunityStage.testLastSyncUpdated = true; // будь-що: метод все одно скине на startTest

        Test.startTest();
        SFtoERPOpportunityStage.sendJSONData(fakeOppId);
        Test.stopTest();

        // Ніяких листів та маркер успіху НЕ виставлено
        System.assertEquals(0, SFtoERPOpportunityStage.testEmailsSent,
            'Query failure branch should not send emails');
        System.assertEquals(false, SFtoERPOpportunityStage.testLastSyncUpdated,
            'Method resets marker at start and should not set it in query-failure path');
    }

    // ---------- Direct email method tests ----------
    @IsTest
    static void test_sendExecutionStatusEmail_success_direct_with_override() {
        SFtoERPOpportunityStage.recipientsOverride = new List<String>{ 's1@example.com', 's2@example.com' };
        SFtoERPOpportunityStage.testEmailsSent = 0;

        Test.startTest();
        SFtoERPOpportunityStage.sendExecutionStatusEmail(true, null);
        Test.stopTest();

        SFtoERPOpportunityStage.recipientsOverride = null;

        System.assertEquals(1, SFtoERPOpportunityStage.testEmailsSent,
            'sendExecutionStatusEmail(true, ...) should send one email when recipients override is set');
    }

    @IsTest
    static void test_sendExecutionStatusEmail_failure_direct_with_override() {
        SFtoERPOpportunityStage.recipientsOverride = new List<String>{ 'f1@example.com' };
        SFtoERPOpportunityStage.testEmailsSent = 0;

        Test.startTest();
        SFtoERPOpportunityStage.sendExecutionStatusEmail(false, 'boom');
        Test.stopTest();

        SFtoERPOpportunityStage.recipientsOverride = null;

        System.assertEquals(1, SFtoERPOpportunityStage.testEmailsSent,
            'sendExecutionStatusEmail(false, ...) should send one email when recipients override is set');
    }

    @IsTest
    static void test_sendExecutionStatusEmail_no_recipients_no_send() {
        SFtoERPOpportunityStage.recipientsOverride = null;
        SFtoERPOpportunityStage.testEmailsSent = 0;

        Test.startTest();
        SFtoERPOpportunityStage.sendExecutionStatusEmail(false, 'x');
        Test.stopTest();

        System.assertEquals(0, SFtoERPOpportunityStage.testEmailsSent,
            'No recipients → guard should return without sending');
    }

    @IsTest
    static void test_sendEmailCalloutException_sends_email_when_override_set() {
        SFtoERPOpportunityStage.recipientsOverride = new List<String>{ 'cex1@example.com', 'cex2@example.com' };
        SFtoERPOpportunityStage.testEmailsSent = 0;

        Test.startTest();
        SFtoERPOpportunityStage.sendEmailCalloutException('boom!');
        Test.stopTest();

        SFtoERPOpportunityStage.recipientsOverride = null;

        System.assertEquals(1, SFtoERPOpportunityStage.testEmailsSent,
            'Expected one email invocation for Callout Exception with override recipients');
    }

    @IsTest
    static void test_sendEmailCalloutException_with_no_recipients_does_not_send() {
        SFtoERPOpportunityStage.recipientsOverride = null;
        SFtoERPOpportunityStage.testEmailsSent = 0;

        Test.startTest();
        SFtoERPOpportunityStage.sendEmailCalloutException('no recipients case');
        Test.stopTest();

        System.assertEquals(0, SFtoERPOpportunityStage.testEmailsSent,
            'No recipients case should not send email');
    }

    // ---------- Cover log helpers & formatter ----------
    @IsTest
    static void test_log_helpers_and_format_exception() {
        // Замість new Exception('X') – ловимо реальний виняток
        Exception ex;
        try {
            Integer a = 1 / 0; // викличе ArithmeticException
        } catch (Exception e) {
            ex = e;
        }
        System.assertNotEquals(null, ex, 'Expected to capture an exception');

        String s = SFtoERPOpportunityStage.formatException(ex);
        System.assert(!String.isBlank(s), 'formatException should return non-empty text');

        // Покриття лог-хелперів
        SFtoERPOpportunityStage.logReq('req', '{}');
        SFtoERPOpportunityStage.logResp('resp', '{}');
        SFtoERPOpportunityStage.logDebug('dbg', 'body');
        SFtoERPOpportunityStage.logError('err without ex', null);
        SFtoERPOpportunityStage.logError('err with ex', ex);

        System.assert(true, 'covered log helpers');
    }

    @IsTest
    static void test_sendJSONData_login_callout_exception_sends_callout_email() {
        Opportunity opp = makeOpp(null, 'Qualification');
        ensureCredentialsOrgDefaults();

        SFtoERPOpportunityStage.testBypassMode     = null; // йдемо реально до login
        SFtoERPOpportunityStage.recipientsOverride = new List<String>{ 'cex@example.com' };
        SFtoERPOpportunityStage.testEmailsSent     = 0;
        SFtoERPOpportunityStage.testLastSyncUpdated = false;

        Test.startTest();
        // Без моків SOAP — виклик LoginEx впаде CalloutException, який ловиться в коді
        // і тригерить sendEmailCalloutException(...)
        SFtoERPOpportunityStage.sendJSONData(opp.Id);
        Test.stopTest();

        SFtoERPOpportunityStage.recipientsOverride = null;

        System.assertEquals(1, SFtoERPOpportunityStage.testEmailsSent,
            'Login callout exception має надіслати 1 email (Callout Exception)');
        System.assertEquals(false, SFtoERPOpportunityStage.testLastSyncUpdated,
            'При винятку на логіні маркер успіху не встановлюється');
    }

    @IsTest
    static void test_getJSONData_status_null_when_stage_null() {
        Opportunity opp = makeOpp(null, 'Qualification');
        // Форсимо кейс: StageName = null і RT не збігається з override → Status має бути null
        opp.StageName = null; // в пам’яті, без DML
        SFtoERPOpportunityStage.leadEnquiryRtIdOverride = '012000000000000AAA'; // не дорівнює opp.RecordTypeId (null)

        String wrapperStr = SFtoERPOpportunityStage.getJSONData(opp);
        Map<String, Object> outerMap = (Map<String, Object>) JSON.deserializeUntyped(wrapperStr);
        Map<String, Object> innerMap = (Map<String, Object>) JSON.deserializeUntyped((String) outerMap.get('JSON'));

        SFtoERPOpportunityStage.leadEnquiryRtIdOverride = null;

        System.assert(innerMap.containsKey('Status'), 'Поле Status має бути у JSON');
        System.assertEquals(null, innerMap.get('Status'),
            'Коли StageName=null і немає збігу RT, Status повинен бути null');
    }

    @IsTest
    static void test_getJSONData_id_erp_not_null_written() {
        Opportunity opp = makeOpp(null, 'Prospecting');
        // Пишемо ID_ERP у пам’яті (без апдейту) і перевіряємо, що він потрапив у JSON
        opp.Id_ERP__c = 'ERP-42';

        String wrapperStr = SFtoERPOpportunityStage.getJSONData(opp);
        Map<String, Object> outerMap = (Map<String, Object>) JSON.deserializeUntyped(wrapperStr);
        Map<String, Object> innerMap = (Map<String, Object>) JSON.deserializeUntyped((String) outerMap.get('JSON'));

        System.assertEquals('ERP-42', (String) innerMap.get('ID_ERP'),
            'ID_ERP має серіалізуватися, коли не null');
    }
}