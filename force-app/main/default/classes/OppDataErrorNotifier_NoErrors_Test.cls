@IsTest
private class OppDataErrorNotifier_NoErrors_Test {

    @IsTest
    static void testNotifier_NoErrors_NoFileCreated() {

        OppDataErrors errors = new OppDataErrors();
        errors.salesRepEmail = 'test@test.com';

        String rawJson = '{"test":"payload"}';

        Test.startTest();
        System.enqueueJob(new OppDataErrorNotifier(errors, rawJson));
        Test.stopTest();

        // не має бути файлів
        List<ContentVersion> files = [
            SELECT Id FROM ContentVersion
        ];

        System.assertEquals(0, files.size(),
            'No file should be created if no errors');
    }
}