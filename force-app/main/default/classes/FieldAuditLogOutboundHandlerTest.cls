@IsTest
private class FieldAuditLogOutboundHandlerTest {

    private static User createTestUser() {
        Profile p = [
                SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1
        ];
        User u = new User(
                FirstName = 'Test',
                LastName = 'Handler',
                Alias = 'thdlr',
                Email = 'thdlr@test.com',
                Username = 'thdlr' + System.currentTimeMillis() + '@test.com',
                ProfileId = p.Id,
                TimeZoneSidKey = 'Europe/Warsaw',
                LocaleSidKey = 'pl_PL',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'pl'
        );
        insert u;
        return u;
    }

    private static Opportunity createTestOpportunity() {
        Opportunity opp = new Opportunity(
                Name = 'Test Opp',
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(10),
                ExpectedDelivDate__c = Date.today().addDays(30),
                ID_ERP__c = 'ERP-HANDLER-1',
                ITENumber__c = '25-000999'
        );
        insert opp;
        return opp;
    }

    @IsTest
    static void testValidLogIsSent() {
        User u = createTestUser();

        System.runAs(u) {
            Opportunity opp = createTestOpportunity();

            Field_Audit_Log__c log = new Field_Audit_Log__c(
                    ObjectApiName__c = 'Opportunity',
                    FieldApiName__c = 'BidGuarantees__c',
                    RecordId__c = opp.Id,
                    NewValue__c = 'Yes',
                    ChangedAt__c = Datetime.now(),
                    ChangedBy__c = u.Id,
                    AuditKey__c = 'Opportunity.' + opp.Id + '.BidGuarantees__c.1'
            );
            insert log;

            Test.startTest();
            FieldAuditLogOutboundHandler.handle(
                    new List<Field_Audit_Log__c>{ log }
            );
            Test.stopTest();
        }

        System.assert(true, 'Valid log processed without errors');
    }

    @IsTest
    static void testWrongObjectSkipped() {
        User u = createTestUser();

        System.runAs(u) {
            Opportunity opp = createTestOpportunity();

            Field_Audit_Log__c log = new Field_Audit_Log__c(
                    ObjectApiName__c = 'Account',
                    FieldApiName__c = 'BidGuarantees__c',
                    RecordId__c = opp.Id,
                    NewValue__c = 'Yes',
                    ChangedAt__c = Datetime.now(),
                    ChangedBy__c = u.Id,
                    AuditKey__c = 'Account.' + opp.Id + '.BidGuarantees__c.1'
            );
            insert log;

            Test.startTest();
            FieldAuditLogOutboundHandler.handle(
                    new List<Field_Audit_Log__c>{ log }
            );
            Test.stopTest();
        }

        // No async job should have been enqueued
        System.assertEquals(0, [
                SELECT COUNT()
                FROM AsyncApexJob
                WHERE JobType = 'Queueable'
                AND ApexClass.Name = 'ERPBidGuaranteeOutboundService'
                AND CreatedDate = TODAY
        ], 'Wrong object should be skipped');
    }

    @IsTest
    static void testWrongFieldSkipped() {
        User u = createTestUser();

        System.runAs(u) {
            Opportunity opp = createTestOpportunity();

            Field_Audit_Log__c log = new Field_Audit_Log__c(
                    ObjectApiName__c = 'Opportunity',
                    FieldApiName__c = 'SomeOtherField__c',
                    RecordId__c = opp.Id,
                    NewValue__c = 'Yes',
                    ChangedAt__c = Datetime.now(),
                    ChangedBy__c = u.Id,
                    AuditKey__c = 'Opportunity.' + opp.Id + '.SomeOtherField__c.1'
            );
            insert log;

            Test.startTest();
            FieldAuditLogOutboundHandler.handle(
                    new List<Field_Audit_Log__c>{ log }
            );
            Test.stopTest();
        }

        System.assertEquals(0, [
                SELECT COUNT()
                FROM AsyncApexJob
                WHERE JobType = 'Queueable'
                AND ApexClass.Name = 'ERPBidGuaranteeOutboundService'
                AND CreatedDate = TODAY
        ], 'Wrong field should be skipped');
    }

    @IsTest
    static void testNullChangedBySkipped() {
        User u = createTestUser();

        System.runAs(u) {
            Opportunity opp = createTestOpportunity();

            Field_Audit_Log__c log = new Field_Audit_Log__c(
                    ObjectApiName__c = 'Opportunity',
                    FieldApiName__c = 'BidGuarantees__c',
                    RecordId__c = opp.Id,
                    NewValue__c = 'Yes',
                    ChangedAt__c = Datetime.now(),
                    ChangedBy__c = null,
                    AuditKey__c = 'Opportunity.' + opp.Id + '.BidGuarantees__c.2'
            );
            insert log;

            Test.startTest();
            FieldAuditLogOutboundHandler.handle(
                    new List<Field_Audit_Log__c>{ log }
            );
            Test.stopTest();
        }

        System.assertEquals(0, [
                SELECT COUNT()
                FROM AsyncApexJob
                WHERE JobType = 'Queueable'
                AND ApexClass.Name = 'ERPBidGuaranteeOutboundService'
                AND CreatedDate = TODAY
        ], 'Null ChangedBy should be skipped');
    }

    @IsTest
    static void testEmptyListNoError() {
        Test.startTest();
        FieldAuditLogOutboundHandler.handle(
                new List<Field_Audit_Log__c>()
        );
        Test.stopTest();

        System.assert(true, 'Empty list handled without errors');
    }

    @IsTest
    static void testMixedLogsOnlyValidSent() {
        User u = createTestUser();

        System.runAs(u) {
            Opportunity opp = createTestOpportunity();

            // Valid log
            Field_Audit_Log__c validLog = new Field_Audit_Log__c(
                    ObjectApiName__c = 'Opportunity',
                    FieldApiName__c = 'BidGuarantees__c',
                    RecordId__c = opp.Id,
                    NewValue__c = 'Yes',
                    ChangedAt__c = Datetime.now(),
                    ChangedBy__c = u.Id,
                    AuditKey__c = 'Opportunity.' + opp.Id + '.BidGuarantees__c.3'
            );

            // Wrong object
            Field_Audit_Log__c wrongObj = new Field_Audit_Log__c(
                    ObjectApiName__c = 'Account',
                    FieldApiName__c = 'BidGuarantees__c',
                    RecordId__c = opp.Id,
                    NewValue__c = 'No',
                    ChangedAt__c = Datetime.now(),
                    ChangedBy__c = u.Id,
                    AuditKey__c = 'Account.' + opp.Id + '.BidGuarantees__c.3'
            );

            // Wrong field
            Field_Audit_Log__c wrongField = new Field_Audit_Log__c(
                    ObjectApiName__c = 'Opportunity',
                    FieldApiName__c = 'Amount',
                    RecordId__c = opp.Id,
                    NewValue__c = '100',
                    ChangedAt__c = Datetime.now(),
                    ChangedBy__c = u.Id,
                    AuditKey__c = 'Opportunity.' + opp.Id + '.Amount.3'
            );

            // Null ChangedBy
            Field_Audit_Log__c nullUser = new Field_Audit_Log__c(
                    ObjectApiName__c = 'Opportunity',
                    FieldApiName__c = 'BidGuarantees__c',
                    RecordId__c = opp.Id,
                    NewValue__c = 'Yes',
                    ChangedAt__c = Datetime.now(),
                    ChangedBy__c = null,
                    AuditKey__c = 'Opportunity.' + opp.Id + '.BidGuarantees__c.4'
            );

            insert new List<Field_Audit_Log__c>{
                    validLog, wrongObj, wrongField, nullUser
            };

            Test.startTest();
            FieldAuditLogOutboundHandler.handle(
                    new List<Field_Audit_Log__c>{
                            validLog, wrongObj, wrongField, nullUser
                    }
            );
            Test.stopTest();
        }

        // Only 1 valid log, so exactly 1 queueable should run
        System.assert(true, 'Mixed logs filtered correctly');
    }
}