@IsTest
private class RecurringErrorAnalyzerTest {

    @IsTest
    static void testAnalyze_NoLogs() {
        // Тест: якщо немає логів для errorKey
        RecurringErrorAnalyzer.AnalysisResult result = RecurringErrorAnalyzer.analyze('NONEXISTENT_ERROR');

        System.assertEquals(false, result.isRecurring, 'Should not be recurring');
        System.assertEquals(0, result.occurrenceCount, 'Should have 0 occurrences');
        System.assertEquals(0, result.frequencyPerWeek, 'Should have 0 frequency');
    }

    @IsTest
    static void testAnalyze_LessThanThreshold() {
        // Створити 2 Pharos Logs (менше порогу 3)
        createPharosLogs('TEST_ERROR', 2);

        RecurringErrorAnalyzer.AnalysisResult result = RecurringErrorAnalyzer.analyze('TEST_ERROR');

        System.assertEquals(false, result.isRecurring, 'Should not be recurring with 2 logs');
        System.assertEquals(2, result.occurrenceCount, 'Should have 2 occurrences');
    }

    @IsTest
    static void testAnalyze_MeetsThreshold() {
        // Створити 3 Pharos Logs (поріг)
        createPharosLogs('TEST_ERROR', 3);

        RecurringErrorAnalyzer.AnalysisResult result = RecurringErrorAnalyzer.analyze('TEST_ERROR');

        System.assertEquals(true, result.isRecurring, 'Should be recurring with 3 logs');
        System.assertEquals(3, result.occurrenceCount, 'Should have 3 occurrences');
    }

    @IsTest
    static void testAnalyze_ExceedsThreshold() {
        // Створити 5 Pharos Logs (більше порогу)
        createPharosLogs('TEST_ERROR', 5);

        RecurringErrorAnalyzer.AnalysisResult result = RecurringErrorAnalyzer.analyze('TEST_ERROR');

        System.assertEquals(true, result.isRecurring, 'Should be recurring with 5 logs');
        System.assertEquals(5, result.occurrenceCount, 'Should have 5 occurrences');
        System.assert(result.frequencyPerWeek > 0, 'Frequency should be > 0');
    }

    @IsTest
    static void testAnalyze_FrequencyCalculation() {
        // Створити 4 логи розподілені на 2 дні
        List<pharos__Log__c> logs = new List<pharos__Log__c>();
        DateTime baseTime = DateTime.now().addDays(-2);

        for (Integer i = 0; i < 4; i++) {
            pharos__Log__c log = createPharosLog('TEST_FREQ');
            log.CreatedDate = baseTime.addHours(i * 12); // Кожні 12 годин
            logs.add(log);
        }

        // Force CreatedDate через Test.setCreatedDate (workaround для system field)
        insert logs;

        RecurringErrorAnalyzer.AnalysisResult result = RecurringErrorAnalyzer.analyze('TEST_FREQ');

        System.assertEquals(true, result.isRecurring, 'Should be recurring');
        System.assertEquals(4, result.occurrenceCount, 'Should have 4 occurrences');
        // Частота має бути екстрапольована на тиждень
        System.assert(result.frequencyPerWeek >= 4, 'Frequency should be >= 4');
    }

    @IsTest
    static void testAnalyze_BlankErrorKey() {
        RecurringErrorAnalyzer.AnalysisResult result = RecurringErrorAnalyzer.analyze('');

        System.assertEquals(false, result.isRecurring, 'Should not be recurring');
        System.assertEquals(0, result.occurrenceCount, 'Should have 0 occurrences');
    }

    // Helper методи
    private static void createPharosLogs(String errorKey, Integer count) {
        List<pharos__Log__c> logs = new List<pharos__Log__c>();
        for (Integer i = 0; i < count; i++) {
            logs.add(createPharosLog(errorKey));
        }
        insert logs;
    }

    private static pharos__Log__c createPharosLog(String errorKey) {
        return new pharos__Log__c(
            pharos__Summary__c = 'Test error',
            pharos__Category__c = 'Apex',
            pharos__Type__c = 'Exception',
            pharos__Area__c = 'OpportunityData',
            Error_Classification_ErrorKey__c = errorKey,
            Log_Source__c = 'ErrorService'
        );
    }
}