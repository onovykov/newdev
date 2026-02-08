@IsTest
private class FieldAuditEventTriggerHelperTest {

    @IsTest
    static void lastOnly_upsert_behaviour() {

        // Arrange: fake PE event
        Field_Audit_Event__e evt = new Field_Audit_Event__e(
            ObjectApiName__c = 'Opportunity',
            FieldApiName__c  = 'BidGuarantees__c',
            RecordId__c      = '006000000000001AAA',
            OldValue__c      = 'Unknown',
            NewValue__c      = 'Yes',
            ChangedAt__c     = System.now(),
            ChangedById__c   = UserInfo.getUserId()
        );

        // Act
        Test.startTest();
        FieldAuditEventTriggerHelper.handle(
            new List<Field_Audit_Event__e>{ evt }
        );
        Test.stopTest();

        // Assert
        List<Field_Audit_Log__c> logs = [
            SELECT OldValue__c, NewValue__c, ValueHash__c
            FROM Field_Audit_Log__c
        ];

        System.assertEquals(1, logs.size(), 'One audit record expected');
        System.assertEquals('Unknown', logs[0].OldValue__c);
        System.assertEquals('Yes', logs[0].NewValue__c);
        System.assertNotEquals(null, logs[0].ValueHash__c);
    }

    @IsTest
    static void lastOnly_secondEvent_overwrites() {

        // Arrange
        String recId = '006000000000002AAA';

        Field_Audit_Event__e e1 = new Field_Audit_Event__e(
            ObjectApiName__c = 'Opportunity',
            FieldApiName__c  = 'BidGuarantees__c',
            RecordId__c      = recId,
            OldValue__c      = 'Unknown',
            NewValue__c      = 'Yes',
            ChangedAt__c     = System.now().addMinutes(-5),
            ChangedById__c   = UserInfo.getUserId()
        );

        Field_Audit_Event__e e2 = new Field_Audit_Event__e(
            ObjectApiName__c = 'Opportunity',
            FieldApiName__c  = 'BidGuarantees__c',
            RecordId__c      = recId,
            OldValue__c      = 'Yes',
            NewValue__c      = 'No',
            ChangedAt__c     = System.now(),
            ChangedById__c   = UserInfo.getUserId()
        );

        // Act
        Test.startTest();
        FieldAuditEventTriggerHelper.handle(
            new List<Field_Audit_Event__e>{ e1 }
        );
        FieldAuditEventTriggerHelper.handle(
            new List<Field_Audit_Event__e>{ e2 }
        );
        Test.stopTest();

        // Assert
        List<Field_Audit_Log__c> logs = [
            SELECT OldValue__c, NewValue__c
            FROM Field_Audit_Log__c
            WHERE RecordId__c = :recId
        ];

        System.assertEquals(1, logs.size(), 'LAST_ONLY → still one row');
        System.assertEquals('Yes', logs[0].OldValue__c);
        System.assertEquals('No', logs[0].NewValue__c);
    }
}