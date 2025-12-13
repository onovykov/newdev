@IsTest
public class ProdWeeksDTO_Test {

    @IsTest
    static void dto_parsing_and_validation() {
        // unordered NWEEK → перевірка сортування
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
        System.assertNotEquals(null, dto);
        System.assertEquals(2025, dto.W_Year);

        // Хелпери
        System.assertEquals(3, dto.allWeeks().size());
        System.assertEquals(2, dto.weeksByGODMEC('202501').size());
        System.assert(dto.toMonthMap().containsKey('202501'));

        // Утиліти
        System.assert(ProdWeeksDTO.isValidGodmec('202512'));
        System.assertEquals(2025, ProdWeeksDTO.yearOf('202512'));
        System.assertEquals(12, ProdWeeksDTO.monthOf('202512'));

        // Валідація
        List<String> issues = dto.validate();
        System.assertEquals(0, issues.size());
    }

    @IsTest
    static void dto_validation_flags_errors() {
        String bad =
        '{"W_Year":2025,"Data":['+
          '{"GODMEC":"202601","Weeks":['+
            '{"NWEEK":1,"DATN":"2025-12-31","DATK":"2025-12-30"},'+
            '{"NWEEK":2,"DATN":"2026-01-02","DATK":"2026-01-05"}'+
          ']},'+
          '{"GODMEC":"2025AA","Weeks":[{"NWEEK":1,"DATN":"2025-03-01","DATK":"2025-03-02"}]}'+
        ']}';

        ProdWeeksDTO dto = ProdWeeksDTO.fromJson(bad);
        List<String> issues = dto.validate();
        System.assert(issues.size() > 0, 'Expected validation errors');
    }
}