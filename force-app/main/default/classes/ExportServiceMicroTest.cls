@IsTest
public class ExportServiceMicroTest {
    @IsTest
    static void coverExport() {
        ContentVersion cv =
            ExportService.exportCsvToFile(
                'test',
                'a,b\n1,2'
            );
        System.assertNotEquals(null, cv.Id);
    }
}