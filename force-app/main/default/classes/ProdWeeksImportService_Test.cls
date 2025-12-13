@IsTest
public class ProdWeeksImportService_Test {

    // JSON 2025
    private static String json2025() {
        return
        '{"W_Year":2025,"Data":['+
          '{"GODMEC":"202501","Weeks":['+
            '{"NWEEK":1,"DATN":"2025-01-01","DATK":"2025-01-07"},'+
            '{"NWEEK":2,"DATN":"2025-01-08","DATK":"2025-01-14"},'+
            '{"NWEEK":3,"DATN":"2025-01-15","DATK":"2025-01-21"}'+
          ']},'+
          '{"GODMEC":"202502","Weeks":[]}' +
        ']}';
    }

    private static String json2026() {
        return
        '{"W_Year":2026,"Data":['+
          '{"GODMEC":"202601","Weeks":['+
            '{"NWEEK":1,"DATN":"2026-01-01","DATK":"2026-01-07"}'+
          ']}' +
        ']}';
    }

    // Helper
    private static String asStr(SObject r, String fieldApi) {
        return String.valueOf(r.get(fieldApi));
    }

    @IsTest
    static void import_2025_and_reimport() {
        Test.startTest();
        ProdWeeksImportResult res = ProdWeeksImportService.importProdWeeks(json2025());
        Test.stopTest();

        System.assert(res.errors.isEmpty(), 'Import should not error');

        // Перевіряємо вузли
        Map<String,ProdWeeksH__c> byItem = new Map<String,ProdWeeksH__c>(
            [SELECT Id, ItemId__c, ParentId__c, Name, Level__c, Month__c, Year__c
             FROM ProdWeeksH__c
             WHERE ItemId__c IN ('MAIN','2025','202501','202502','202501_1','202501_2','202501_3')]
        );

        System.assert(byItem.containsKey('MAIN'));
        System.assert(byItem.containsKey('2025'));
        System.assertEquals('MAIN', byItem.get('2025').ParentId__c);

        // Місяць
        ProdWeeksH__c jan = byItem.get('202501');
        System.assertEquals('1', asStr(jan,'Month__c'));
        System.assertEquals(2, jan.Level__c);

        // Тиждень
        ProdWeeksH__c w2 = byItem.get('202501_2');
        System.assertEquals(3, w2.Level__c);
        System.assertEquals(Date.newInstance(2025,1,8),  w2.DateFrom__c);
        System.assertEquals(Date.newInstance(2025,1,14), w2.DateTo__c);

        // Ідемпотентність (не має створити дублікати)
        Integer before = [SELECT COUNT() FROM ProdWeeksH__c];
        ProdWeeksImportResult res2 = ProdWeeksImportService.importProdWeeks(json2025());
        Integer after = [SELECT COUNT() FROM ProdWeeksH__c];

        System.assertEquals(before, after, 'Reimport must not create duplicates');
    }

    @IsTest
    static void delete_year_flow() {
        // Заливаємо 2026
        ProdWeeksImportResult res = ProdWeeksImportService.importProdWeeks(json2026());
        System.assert(res.errors.isEmpty());

        Integer before = [SELECT COUNT() FROM ProdWeeksH__c WHERE ItemId__c LIKE '2026%'];

        // Dry run
        ProdWeeksImportService.DeleteSummary d1 =
            ProdWeeksImportService.deleteYear('2026', true);

        System.assert(d1.dryRun);
        System.assert(before > 0);

        // Commit
        ProdWeeksImportService.DeleteSummary d2 =
            ProdWeeksImportService.deleteYear('2026', false);

        Integer after = [SELECT COUNT() FROM ProdWeeksH__c WHERE ItemId__c LIKE '2026%'];

        System.assertEquals(0, after, 'Hierarchy must be deleted');
    }

    @IsTest
    static void empty_payload_errors() {
        ProdWeeksImportResult res = ProdWeeksImportService.importProdWeeks('');
        System.assert(res.errors.size() > 0);
    }
}