@IsTest
private class ProdWeeksImportService_Test {

    // ---------- helpers ----------
    private static String sampleJson2025() {
        // 2025: місяць 01 з трьома тижнями + порожній місяць 02 (для перевірки вузла місяця без тижнів)
        return
        '{"W_Year":2025,"Data":['+
          '{"GODMEC":"202501","Weeks":['+
            '{"NWEEK":1,"DATN":"2025-01-01","DATK":"2025-01-07"},'+
            '{"NWEEK":2,"DATN":"2025-01-08","DATK":"2025-01-14"},'+
            '{"NWEEK":3,"DATN":"2025-01-15","DATK":"2025-01-21"}'+
          ']},'+
          '{"GODMEC":"202502","Weeks":[]}'+
        ']}';
    }

    private static String sampleJson2026() {
        return
        '{"W_Year":2026,"Data":['+
          '{"GODMEC":"202601","Weeks":['+
            '{"NWEEK":1,"DATN":"2026-01-01","DATK":"2026-01-07"}'+
          ']}' +
        ']}';
    }

    // Універсальний геттер як String, щоб не спіткнутися об Number/Text
    private static String asStr(SObject r, String fieldApi) {
        return String.valueOf(r.get(fieldApi));
    }

    // ---------- tests ----------
    @IsTest
    static void import_formats_and_hierarchy_ok() {
        // Старт чистий
        System.assertEquals(0, [SELECT COUNT() FROM ProdWeeksH__c]);

        // Імпорт 2025
        ProdWeeksImportResult res = ProdWeeksImportService.importProdWeeks(sampleJson2025());
        System.assertEquals(true, res.errors.isEmpty(), 'Import must not produce errors');

        // Перевіряємо ключові вузли
        Map<String, ProdWeeksH__c> byItem = new Map<String, ProdWeeksH__c>();
        for (ProdWeeksH__c r : [
            SELECT Id, ItemId__c, Name, ParentId__c, Level__c,
                   Year__c, Month__c, WeekNum__c, DateFrom__c, DateTo__c
            FROM ProdWeeksH__c
            WHERE ItemId__c IN ('MAIN','2025','202501','202501_1','202501_2','202501_3','202502')
            ORDER BY Level__c, ItemId__c
        ]) byItem.put(r.ItemId__c, r);

        // MAIN
        System.assert(byItem.containsKey('MAIN'));
        System.assertEquals('MAIN', byItem.get('2025').ParentId__c);
        System.assertEquals('2025', asStr(byItem.get('2025'), 'ItemId__c'));
        System.assertEquals('2025', asStr(byItem.get('2025'), 'Year__c'));

        // МІСЯЦЬ 202501: Name = 'JANUARY', Month__c = '1', ParentId__c='2025'
        ProdWeeksH__c mJan = byItem.get('202501');
        System.assertNotEquals(null, mJan, 'Month node must exist');
        System.assertEquals(2, mJan.Level__c);
        System.assertEquals('2025', mJan.ParentId__c);
        System.assertEquals('1',   asStr(mJan, 'Month__c'));
        System.assertEquals('JANUARY', mJan.Name);

        // МІСЯЦЬ 202502: порожній, але вузол є, Name має бути 'FEBRUARY'
        ProdWeeksH__c mFeb = byItem.get('202502');
        System.assertNotEquals(null, mFeb, 'Empty month node still must exist');
        System.assertEquals('2', asStr(mFeb, 'Level__c'));
        System.assertEquals('2025', mFeb.ParentId__c);
        System.assertEquals('2', asStr(mFeb, 'Month__c'));
        System.assertEquals('FEBRUARY', mFeb.Name);

        // ТИЖДЕНЬ 202501_2: Name = 'Week 2', дати за JSON, ParentId__c='202501'
        ProdWeeksH__c w2 = byItem.get('202501_2');
        System.assertNotEquals(null, w2, 'Week 2 must exist');
        System.assertEquals(3, w2.Level__c);
        System.assertEquals('202501', w2.ParentId__c);
        System.assertEquals('Week 2', w2.Name);
        System.assertEquals(Date.newInstance(2025,1,8),  w2.DateFrom__c);
        System.assertEquals(Date.newInstance(2025,1,14), w2.DateTo__c);

        // Перезапуск (idempotent): не створює дублів — кількість записів не зросте
        Integer countBefore = [SELECT COUNT() FROM ProdWeeksH__c];
        ProdWeeksImportResult res2 = ProdWeeksImportService.importProdWeeks(sampleJson2025());
        System.assertEquals(true, res2.errors.isEmpty(), 'Reimport must not err');
        Integer countAfter = [SELECT COUNT() FROM ProdWeeksH__c];
        System.assertEquals(countBefore, countAfter, 'Reimport must not create duplicates');
    }

    @IsTest
    static void deleteYear_dryrun_and_commit() {
        // 1) Заливаємо 2026
        ProdWeeksImportResult res = ProdWeeksImportService.importProdWeeks(sampleJson2026());
        System.assertEquals(true, res.errors.isEmpty());

        // 2) Dry-run: показує, що буде видалено, але не видаляє
        ProdWeeksImportService.DeleteSummary s1 = ProdWeeksImportService.deleteYear('2026', true);
        System.assertEquals('2026', s1.year);
        System.assertEquals(true, s1.dryRun);
        System.assert(s1.weeksFound > 0 || s1.monthsFound > 0 || s1.yearsFound > 0, 'Dry-run must see something to delete');

        Integer cntBefore = [SELECT COUNT() FROM ProdWeeksH__c WHERE ItemId__c LIKE '2026%'];
        System.assert(cntBefore > 0, 'We expect 2026 hierarchy to exist after dry-run');

        // 3) Commit-delete: реально видалить 2026
        ProdWeeksImportService.DeleteSummary s2 = ProdWeeksImportService.deleteYear('2026', false);
        System.assertEquals(false, s2.dryRun);
        Integer cntAfter = [SELECT COUNT() FROM ProdWeeksH__c WHERE ItemId__c LIKE '2026%'];
        System.assertEquals(0, cntAfter, '2026 hierarchy must be deleted');
    }

    @IsTest
    static void empty_payload_returns_error() {
        ProdWeeksImportResult res = ProdWeeksImportService.importProdWeeks('');
        System.assert(res.errors.size() > 0, 'Empty payload must produce an error');
    }
}