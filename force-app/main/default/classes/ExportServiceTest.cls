@IsTest
public class ExportServiceTest {

    @IsTest
    static void testExportCsvToFile() {
        // Arrange
        List<Account> accs = TestDataFactory.createAccounts(1);

        String csv =
            'Id,Name\n' +
            accs[0].Id + ',' + accs[0].Name;

        // Act
        ContentVersion cv =
            ExportService.exportCsvToFile(
                'AdminSnapshot_Test',
                csv
            );

        // Assert – базові перевірки
        System.assertNotEquals(
            null,
            cv,
            'ContentVersion must be returned'
        );
        System.assertNotEquals(
            null,
            cv.Id,
            'ContentVersion must be inserted'
        );

        // Assert – перевірка з БД
        ContentVersion stored = [
            SELECT Title, PathOnClient, VersionData
            FROM ContentVersion
            WHERE Id = :cv.Id
            LIMIT 1
        ];

        System.assertEquals(
            'AdminSnapshot_Test',
            stored.Title,
            'Snapshot title mismatch'
        );

        System.assert(
            stored.PathOnClient.endsWith('.csv'),
            'CSV file extension expected'
        );

        System.assertNotEquals(
            null,
            stored.VersionData,
            'CSV content must be stored'
        );
    }
}