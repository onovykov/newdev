@IsTest
private class UserKeySnapshotHookTest {

    private static User createUser() {
        Profile p = [
            SELECT Id FROM Profile
            WHERE Name = 'Standard User'
            LIMIT 1
        ];

        return new User(
            Alias = 'snap',
            Email = 'snapshot@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Snapshot',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'Europe/Warsaw',
            Username = 'snapshot_' + System.now().getTime() + '@test.com',
            ProfileId = p.Id
        );
    }

    @IsTest
    static void testSnapshotCreatedOnUserUpdate() {

        User u = createUser();
        insert u;

        Test.startTest();
        u.ID_ERP__c = 'ERP-001';
        u.LoginERP__c = 'login.erp';
        update u;
        Test.stopTest();

        List<Field_Audit_Log__c> logs = [
            SELECT FieldApiName__c, OldValue__c, NewValue__c
            FROM Field_Audit_Log__c
            WHERE RecordId__c = :u.Id
        ];

        Set<String> auditedFields = new Set<String>();
        for (Field_Audit_Log__c l : logs) {
            auditedFields.add(l.FieldApiName__c);
        }

        System.assert(auditedFields.contains('ID_ERP__c'));
        System.assert(auditedFields.contains('LoginERP__c'));

        Set<String> fields = new Set<String>();
        for (Field_Audit_Log__c l : logs) {
            fields.add(l.FieldApiName__c);
        }

        System.assert(fields.contains('ID_ERP__c'));
        System.assert(fields.contains('LoginERP__c'));
    }
}
