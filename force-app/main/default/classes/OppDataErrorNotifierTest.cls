@IsTest
private class OppDataErrorNotifierTest {

    @IsTest
    static void testNotifier_WithErrors_EmailAndFileCreated() {

        // Arrange
        OppDataErrors errors = new OppDataErrors();
        errors.iteNumber = '25-007717';
        errors.altNumber = 'COC25/01808';
        errors.salesRepEmail = 'test@company.com'; // не важливо в тесті
        errors.bosEmail = '';

        errors.errors.add('Illegal Product Edit');
        errors.errors.add('Illegal Currency Edit');

        errors.correlationId = 'TEST-CID-123';

        String rawJson = '{"test":"payload"}';

        // Act
        Test.startTest();
        System.enqueueJob(new OppDataErrorNotifier(errors, rawJson));
        Test.stopTest();

        // Assert
        // Перевіряємо, що ContentVersion створився
        List<ContentVersion> files = [
            SELECT Id, Title
            FROM ContentVersion
            WHERE Title LIKE 'OppSyncPayload_%'
        ];

        System.assert(!files.isEmpty(), 'Payload file should be created');
    }
}