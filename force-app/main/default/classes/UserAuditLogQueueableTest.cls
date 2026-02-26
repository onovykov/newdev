@IsTest
private class UserAuditLogQueueableTest {

    @IsTest
    static void testQueueableInsertsLogs() {
        Field_Audit_Log__c log = new Field_Audit_Log__c(
            AuditKey__c      = 'TEST_KEY',
            ObjectApiName__c = 'User',
            FieldApiName__c  = 'IsActive',
            RecordId__c      = UserInfo.getUserId(),
            OldValue__c      = 'true',
            NewValue__c      = 'false',
            ChangedAt__c     = System.now(),
            ChangedBy__c     = UserInfo.getUserId()
        );

        Test.startTest();
        System.enqueueJob(
            new UserAuditLogQueueable(
                new List<Field_Audit_Log__c>{ log }
            )
        );
        Test.stopTest();

        System.assertEquals(
            1,
            [SELECT count() FROM Field_Audit_Log__c WHERE AuditKey__c = 'TEST_KEY']
        );
    }
}