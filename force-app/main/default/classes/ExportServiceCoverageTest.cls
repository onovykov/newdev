@IsTest
public class ExportServiceCoverageTest {

    @IsTest
    static void coverSmallCsv() {
        ContentVersion cv =
            ExportService.exportCsvToFile(
                'test',
                'a,b\n1,2'
            );

        System.assertNotEquals(null, cv.Id);
    }

    @IsTest
    static void coverExport() {
        ContentVersion cv =
            ExportService.exportCsvToFile(
                'test-file',
                'a,b\n1,2'
            );

        System.assertNotEquals(null, cv.Id);
        System.assertEquals('test-file', cv.Title);
    }   

    @IsTest
    static void coverCsvAndJsonFileExport() {

        ContentVersion csv =
            ExportService.exportCsvToFile(
                'csv-test',
                'a,b\n1,2'
            );
        System.assertNotEquals(null, csv.Id);

        ContentVersion json =
            ExportService.exportJsonToFile(
                'json-test',
                '{"a":1}'
            );
        System.assertNotEquals(null, json.Id);
    }  
}