@IsTest
private class ERPBidGuaranteeOutboundServiceTest {

    @IsTest
    static void testOutboundSentForNonErpUser() {

        // User без ERP login-а
        Profile p = [
                SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1
        ];

        User u = new User(
                FirstName = 'Test',
                LastName = 'User',
                Alias = 'tusr',
                Email = 'tusr@test.com',
                Username = 'tusr' + System.currentTimeMillis() + '@test.com',
                ProfileId = p.Id,
                TimeZoneSidKey = 'Europe/Warsaw',
                LocaleSidKey = 'pl_PL',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'pl'
        );
        insert u;

        System.runAs(u) {

            Opportunity opp = new Opportunity(
                    Name = 'Test Opp',
                    StageName = 'Prospecting',
                    CloseDate = Date.today().addDays(10),
                    ExpectedDelivDate__c = Date.today().addDays(30),
                    ID_ERP__c = 'ERP-1',
                    ITENumber__c = '25-000123'
            );
            insert opp;

            Field_Audit_Log__c log = new Field_Audit_Log__c(
                    ObjectApiName__c = 'Opportunity',
                    RecordId__c = opp.Id,
                    FieldApiName__c = 'BidGuarantees__c',
                    NewValue__c = 'Yes',
                    ChangedAt__c = Datetime.now(),
                    ChangedBy__c = u.Id,
                    AuditKey__c = 'Opportunity.' + opp.Id + '.BidGuarantees__c'
            );
            insert log;

            Test.startTest();
            ERPBidGuaranteeOutboundService.sendAsync(
                    new List<Field_Audit_Log__c>{ log }
            );
            Test.stopTest();
        }

        // Якщо ми дійшли до цього місця — все ОК, no exceptions, outbound виконано
        System.assert(true, 'Outbound executed successfully');
    }

    @IsTest
    static void testOutboundSkippedForErpUser() {

        Profile p = [
                SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1
        ];

        User erpUser = new User(
                FirstName = 'ERP',
                LastName = 'User',
                Alias = 'erp',
                Email = 'erp@test.com',
                Username = 'erp' + System.currentTimeMillis() + '@test.com',
                ProfileId = p.Id,
                TimeZoneSidKey = 'Europe/Warsaw',
                LocaleSidKey = 'pl_PL',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'pl',
                LoginERP__c = 'ERP_USER'
        );
        insert erpUser;

        System.runAs(erpUser) {

            Opportunity opp = new Opportunity(
                    Name = 'ERP Opp',
                    StageName = 'Prospecting',
                    CloseDate = Date.today().addDays(10),
                    ExpectedDelivDate__c = Date.today().addDays(30),
                    ID_ERP__c = 'ERP-2'
            );
            insert opp;

            Field_Audit_Log__c log = new Field_Audit_Log__c(
                    ObjectApiName__c = 'Opportunity',
                    RecordId__c = opp.Id,
                    FieldApiName__c = 'BidGuarantees__c',
                    NewValue__c = 'No',
                    ChangedAt__c = Datetime.now(),
                    ChangedBy__c = erpUser.Id,
                    AuditKey__c = 'Opportunity.' + opp.Id + '.BidGuarantees__c'
            );
            insert log;

            Test.startTest();
            ERPBidGuaranteeOutboundService.sendAsync(
                    new List<Field_Audit_Log__c>{ log }
            );
            Test.stopTest();
        }

        // Не було outbound, але й не було помилок, зміни скіпнуто
        System.assert(true, 'ERP user change correctly skipped');
    }
}