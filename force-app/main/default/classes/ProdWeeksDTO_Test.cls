@IsTest
private class ProdWeeksDTO_Test {

    @IsTest
    static void parse_and_helpers_ok() {
        // unordered NWEEK, щоб пройти гілку sort() у validate()
        String payload =
        '{"W_Year":2025,"Data":['+
          '{"GODMEC":"202501","Weeks":['+
            '{"NWEEK":2,"DATN":"2025-01-08","DATK":"2025-01-14"},'+
            '{"NWEEK":1,"DATN":"2025-01-01","DATK":"2025-01-07"}'+
          ']},'+
          '{"GODMEC":"202502","Weeks":['+
            '{"NWEEK":1,"DATN":"2025-02-01","DATK":"2025-02-04"}'+
          ']}'+
        ']}';

        ProdWeeksDTO dto = ProdWeeksDTO.fromJson(payload);
        System.assertNotEquals(null, dto, 'DTO must be parsed');
        System.assertEquals(2025, dto.W_Year);

        // Хелпери
        List<ProdWeeksDTO.WeekItem> all = dto.allWeeks();
        System.assertEquals(3, all.size(), 'Total weeks should be 3');

        List<ProdWeeksDTO.WeekItem> jan = dto.weeksByGODMEC('202501');
        System.assertEquals(2, jan.size(), 'Jan should have 2 weeks');

        Map<String, List<ProdWeeksDTO.WeekItem>> monthMap = dto.toMonthMap();
        System.assertEquals(true, monthMap.containsKey('202501'));
        System.assertEquals(2, monthMap.get('202501').size());

        // Утиліти GODMEC
        System.assertEquals(true, ProdWeeksDTO.isValidGodmec('202512'));
        System.assertEquals(2025, ProdWeeksDTO.yearOf('202512'));
        System.assertEquals(12,   ProdWeeksDTO.monthOf('202512'));

        // Валідація відсортує тижні та не має знаходити проблем
        List<String> issues = dto.validate();
        System.assertEquals(0, issues.size(), 'No validation issues expected');

        // Серіалізація назад
        String pretty = dto.toJson(true);
        System.assert(pretty.contains('"W_Year"'));
        System.assert(pretty.contains('"GODMEC"'));
    }

    @IsTest
    static void validation_flags_issues() {
        // Тут навмисно заженемо помилки:
        //  - GODMEC рік != W_Year
        //  - Дата не в тому році
        //  - DATN > DATK
        String bad =
        '{"W_Year":2025,"Data":['+
          '{"GODMEC":"202601","Weeks":['+ // інший рік
            '{"NWEEK":1,"DATN":"2025-12-31","DATK":"2025-12-30"},'+ // DATN > DATK
            '{"NWEEK":2,"DATN":"2026-01-02","DATK":"2026-01-05"}'+ // дати не в 2025
          ']},'+
          '{"GODMEC":"2025AA","Weeks":[{"NWEEK":1,"DATN":"2025-03-01","DATK":"2025-03-02"}]}' + // invalid GODMEC
        ']}';

        ProdWeeksDTO dto = ProdWeeksDTO.fromJson(bad);
        List<String> issues = dto.validate();

        // Очікуємо кілька проблем
        System.assert(issues.size() >= 3,
            'Should flag year mismatch, DATN>DATK, invalid GODMEC, and out-of-year dates. Got: ' + String.join(issues, ' | '));
    }

    @IsTest
    static void utils_and_edges() {
        // Перевіримо edge-cases утиліт
        System.assertEquals(false, ProdWeeksDTO.isValidGodmec(null));
        System.assertEquals(false, ProdWeeksDTO.isValidGodmec(''));
        System.assertEquals(false, ProdWeeksDTO.isValidGodmec('20251'));     // 5 цифр
        System.assertEquals(false, ProdWeeksDTO.isValidGodmec('20a501'));    // літера
        System.assertEquals(null,  ProdWeeksDTO.yearOf('20x501'));
        System.assertEquals(null,  ProdWeeksDTO.monthOf('20251'));
        System.assertEquals(null,  ProdWeeksDTO.yearOf(null));
        System.assertEquals(null,  ProdWeeksDTO.monthOf(null));

        // DTO без Data
        ProdWeeksDTO empty = new ProdWeeksDTO();
        empty.W_Year = 2025;
        System.assertEquals(0, empty.allWeeks().size());
        System.assertEquals(0, empty.weeksByGODMEC('202501').size());
        System.assertEquals(0, empty.toMonthMap().size());
        System.assertEquals(0, empty.validate().size());

        // DTO з null-елементами, null-NWEK — пройде через компаратор і гілки validate()
        ProdWeeksDTO withNulls = new ProdWeeksDTO();
        withNulls.W_Year = 2025;
        withNulls.Data = new List<ProdWeeksDTO.MonthBlock>{
            null,
            new ProdWeeksDTO.MonthBlock()
        };
        withNulls.Data[1].GODMEC = '202501';
        withNulls.Data[1].Weeks = new List<ProdWeeksDTO.WeekItem>{
            new ProdWeeksDTO.WeekItem(),
            new ProdWeeksDTO.WeekItem()
        };
        // перший тиждень пустий (NWEEK null) — перевіряємо компаратор
        withNulls.Data[1].Weeks[1].NWEEK = 2;
        withNulls.Data[1].Weeks[1].DATN = Date.newInstance(2025, 1, 10);
        withNulls.Data[1].Weeks[1].DATK = Date.newInstance(2025, 1, 15);

        List<String> issues = withNulls.validate();
        // має бути хоча б 1 issue через Null MonthBlock (з першого елемента)
        System.assert(issues.size() >= 1, 'Expected at least one issue due to null MonthBlock');
        // Переконаємось, що хелпери не падають
        System.assertEquals(2, withNulls.weeksByGODMEC('202501').size());
        System.assertEquals(1, withNulls.toMonthMap().size());
        // Серіалізація
        System.assertNotEquals(null, withNulls.toJson(false));
    }
}