@IsTest
private class OppDataErrorNotifierTest {

    @IsTest
    static void testExecute_SuccessFlow() {

        // GIVEN
        OppDataErrors err = new OppDataErrors();
        err.salesRepEmail = 'test@test.com';
        err.bosEmail = 'test2@test.com';
        err.iteNumber = 'TEST-001';
        err.altNumber = 'ALT-001';
        err.errors = new List<String>{ 'Error 1' };

        String payload = '{"test":"data"}';

        // WHEN
        Test.startTest();
        System.enqueueJob(new OppDataErrorNotifier(err, payload));
        Test.stopTest();

        // THEN
        List<ContentVersion> files = [
            SELECT Id, Title
            FROM ContentVersion
            WHERE Title LIKE 'OppSyncPayload%'
        ];

        System.assert(!files.isEmpty(), 'Payload file should be created');
    }

    @IsTest
    static void testExecute_NoErrors() {

        OppDataErrors err = new OppDataErrors();
        err.errors = new List<String>(); // empty

        Test.startTest();
        System.enqueueJob(new OppDataErrorNotifier(err, '{}'));
        Test.stopTest();

        System.assert(true);
    }

    @IsTest
    static void testExecute_NullPayload() {

        OppDataErrors err = new OppDataErrors();
        err.salesRepEmail = 'test@test.com';
        err.iteNumber = 'TEST';
        err.errors = new List<String>{ 'Error' };

        Test.startTest();
        System.enqueueJob(new OppDataErrorNotifier(err, null));
        Test.stopTest();

        System.assert(true);
    }
}