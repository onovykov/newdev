@IsTest
public class FullCoverage_ProdWeeks_Test {

    // -----------------------------
    // JSON helpers
    // -----------------------------
    private static String json2025() {
        return
        '{"W_Year":2025,"Data":[' +
          '{"GODMEC":"202501","Weeks":[' +
            '{"NWEEK":1,"DATN":"2025-01-01","DATK":"2025-01-07"},' +
            '{"NWEEK":3,"DATN":"2025-01-15","DATK":"2025-01-21"},' +
            '{"NWEEK":2,"DATN":"2025-01-08","DATK":"2025-01-14"}' +
          ']},' +
          '{"GODMEC":"202502","Weeks":[]}' +
        ']}';
    }

    private static String json2026() {
        return
        '{"W_Year":2026,"Data":[' +
          '{"GODMEC":"202601","Weeks":[' +
            '{"NWEEK":1,"DATN":"2026-01-01","DATK":"2026-01-07"}' +
          ']}' +
        ']}';
    }

    // -----------------------------
    // 1. DTO tests
    // -----------------------------
    @IsTest
    static void dto_ok_validation() {

        ProdWeeksDTO dto = ProdWeeksDTO.fromJson(json2025());
        System.assertNotEquals(null, dto);
        System.assertEquals(2025, dto.W_Year);

        System.assertEquals(3, dto.allWeeks().size());
        System.assert(dto.validate().isEmpty());
    }

    @IsTest
    static void dto_validation_errors() {

        String bad =
        '{"W_Year":2025,"Data":[' +
          '{"GODMEC":"2026AA","Weeks":[' +
            '{"NWEEK":1,"DATN":"2025-12-31","DATK":"2025-12-30"}' +
          ']}' +
        ']}';

        ProdWeeksDTO dto = ProdWeeksDTO.fromJson(bad);
        System.assert(!dto.validate().isEmpty());
    }
    
    @IsTest
    static void dto_full_coverage() {

        // ---------- 0. fromJson blank ----------
        ProdWeeksDTO blank = ProdWeeksDTO.fromJson('');
        System.assertEquals(null, blank);

        // ---------- 1. normal DTO ----------
        ProdWeeksDTO dto = ProdWeeksDTO.fromJson(json2025());
        System.assertNotEquals(null, dto);

        // ----- toMonthMap() -----
        Map<String, List<ProdWeeksDTO.WeekItem>> mm = dto.toMonthMap();
        System.assert(mm.containsKey('202501'));
        System.assert(mm.containsKey('202502'));
        System.assertEquals(3, mm.get('202501').size());
        System.assertEquals(0, mm.get('202502').size());

        // ----- weeksByGODMEC() -----
        System.assertEquals(3, dto.weeksByGODMEC('202501').size());
        System.assertEquals(0, dto.weeksByGODMEC('202502').size());

        // ----- allWeeks() -----
        System.assertEquals(3, dto.allWeeks().size());

        // ----- GODMEC utils -----
        System.assert(ProdWeeksDTO.isValidGodmec('202501'));
        System.assert(!ProdWeeksDTO.isValidGodmec('20A501'));

        System.assertEquals(2025, ProdWeeksDTO.yearOf('202501'));
        System.assertEquals(1, ProdWeeksDTO.monthOf('202501'));

        // ----- 2. VALIDATION: ERROR CASES -----

        // Start from a valid DTO, then break it manually
        ProdWeeksDTO badDto = ProdWeeksDTO.fromJson(json2025());

        // 1) Make invalid GODMEC
        badDto.Data[0].GODMEC = 'BADVAL';

        // 2) Make year mismatch
        badDto.Data[1].GODMEC = '202401';

        // 3) Force null WeekItem without breaking JSON
        badDto.Data[0].Weeks.add(null);

        // 4) Force DATN > DATK
        ProdWeeksDTO.WeekItem badW = new ProdWeeksDTO.WeekItem();
        badW.NWEEK = 99;
        badW.DATN = Date.newInstance(2025, 5, 10);
        badW.DATK = Date.newInstance(2025, 5, 5);
        badDto.Data[0].Weeks.add(badW);

        // Collect errors
        List<String> err = badDto.validate();
        System.assert(err.size() > 0);


        // ---------- 3. toMonthMap edge case (blank GODMEC) ----------
        ProdWeeksDTO skipDto = ProdWeeksDTO.fromJson(json2025());
        skipDto.Data[0].GODMEC = '';   // blank → should skip
        Map<String, List<ProdWeeksDTO.WeekItem>> skipMap = skipDto.toMonthMap();
        System.assert(!skipMap.containsKey(''));  // blank skipped


        // ---------- 4. Comparator coverage ----------
        ProdWeeksDTO.WeekComparator cmp = new ProdWeeksDTO.WeekComparator();

        ProdWeeksDTO.WeekItem a = new ProdWeeksDTO.WeekItem();
        a.NWEEK = 3;

        ProdWeeksDTO.WeekItem b = new ProdWeeksDTO.WeekItem();
        b.NWEEK = 1;

        System.assertEquals(1, cmp.compare(a, b));  
        System.assertEquals(-1, cmp.compare(b, a)); 
        System.assertEquals(0, cmp.compare(a, a));  

        // null-handling
        System.assertEquals(-1, cmp.compare(null, b));
        System.assertEquals(1, cmp.compare(a, null));
    }

    // -----------------------------
    // 2. Import + Reimport (NO ItemId checks)
    // -----------------------------
    @IsTest
    static void import_and_reimport() {

        // ---------- FIRST IMPORT ----------
        Test.startTest();
        ProdWeeksImportResult r1 = ProdWeeksImportService.importProdWeeks(json2025());
        Test.stopTest();

        System.assert(r1.errors.isEmpty());

        // Check at least some records created
        List<ProdWeeksH__c> afterImport = [
            SELECT Id, ItemId__c, Level__c
            FROM ProdWeeksH__c
            WHERE Year__c = 2025
        ];
        System.assert(afterImport.size() > 0);

        Integer beforeSize = afterImport.size();

        // ---------- REIMPORT ----------
        // No second startTest() — avoids "Testing already started"
        ProdWeeksImportResult r2 = ProdWeeksImportService.importProdWeeks(json2025());

        System.assert(r2.errors.isEmpty());

        List<ProdWeeksH__c> afterReimport = [
            SELECT Id
            FROM ProdWeeksH__c
            WHERE Year__c = 2025
        ];

        // No duplicates
        System.assertEquals(beforeSize, afterReimport.size());
    }


    // -----------------------------
    // 3. deleteYear flow
    // -----------------------------
    @IsTest
    static void delete_year_flow() {

        ProdWeeksImportService.importProdWeeks(json2026());

        Integer before = [
            SELECT COUNT() FROM ProdWeeksH__c WHERE Year__c = 2026
        ];
        System.assert(before > 0);

        // dry run
        ProdWeeksImportService.DeleteSummary dry =
            ProdWeeksImportService.deleteYear('2026', true);
        System.assert(dry.dryRun);

        // invalid
        ProdWeeksImportService.DeleteSummary bad =
            ProdWeeksImportService.deleteYear('20xx', false);
        System.assert(!bad.errors.isEmpty());

        // real delete
        ProdWeeksImportService.deleteYear('2026', false);

        Integer after = [
            SELECT COUNT() FROM ProdWeeksH__c WHERE Year__c = 2026
        ];
        System.assertEquals(0, after);
    }

    // -----------------------------
    // 4. Error cases
    // -----------------------------
    @IsTest
    static void error_cases() {

        System.assert(!ProdWeeksImportService.importProdWeeks('').errors.isEmpty());
        System.assert(!ProdWeeksImportService.importProdWeeks('{invalid').errors.isEmpty());
        System.assert(!ProdWeeksImportService.importProdWeeks('null').errors.isEmpty());
    }
}