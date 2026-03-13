/**
 * Аналізує частоту помилок на базі Pharos Logs.
 * Визначає чи є помилка повторюваною (recurring) та скільки разів вона трапилася.
 */
public with sharing class RecurringErrorAnalyzer {

    // Поріг частоти: 3 рази на тиждень = ескалація
    private static final Integer FREQUENCY_THRESHOLD = 3;

    // Період аналізу: 7 днів
    private static final Integer LOOKBACK_DAYS = 7;

    /**
     * Результат аналізу помилки.
     */
    public class AnalysisResult {
        public Boolean isRecurring { get; set; }
        public Integer occurrenceCount { get; set; }
        public Decimal frequencyPerWeek { get; set; }
        public DateTime oldestOccurrence { get; set; }
        public DateTime newestOccurrence { get; set; }
        public List<pharos__Log__c> logs { get; set; }

        public AnalysisResult() {
            this.isRecurring = false;
            this.occurrenceCount = 0;
            this.frequencyPerWeek = 0;
            this.logs = new List<pharos__Log__c>();
        }
    }

    /**
     * Аналізує частоту помилки за останні LOOKBACK_DAYS днів.
     * @param errorKey - ключ помилки з Error_Classification__mdt
     * @return AnalysisResult з інформацією про частоту
     */
    public static AnalysisResult analyze(String errorKey) {
        if (String.isBlank(errorKey)) {
            return new AnalysisResult();
        }

        // Визначити дату початку аналізу
        DateTime lookbackStart = DateTime.now().addDays(-LOOKBACK_DAYS);

        // Знайти всі Pharos Logs для цього errorKey за період
        List<pharos__Log__c> logs = [
            SELECT Id, CreatedDate, Error_Classification_ErrorKey__c,
                   pharos__Summary__c, pharos__Type__c, pharos__Details__c,
                   pharos__Related_Objects__c, pharos__Area__c
            FROM pharos__Log__c
            WHERE Error_Classification_ErrorKey__c = :errorKey
                AND CreatedDate >= :lookbackStart
                AND Log_Source__c = 'ErrorService'
            ORDER BY CreatedDate DESC
            LIMIT 1000
        ];

        AnalysisResult result = new AnalysisResult();
        result.occurrenceCount = logs.size();
        result.logs = logs;

        if (result.occurrenceCount == 0) {
            return result;
        }

        // Визначити oldest та newest occurrence
        result.oldestOccurrence = logs[0].CreatedDate;
        result.newestOccurrence = logs[logs.size() - 1].CreatedDate;

        // Розрахувати частоту на тиждень
        // Якщо період між першою та останньою помилкою < 7 днів,
        // екстраполюємо на повний тиждень
        Long millisBetween = result.newestOccurrence.getTime() - result.oldestOccurrence.getTime();
        Decimal daysBetween = millisBetween / (1000.0 * 60 * 60 * 24);

        if (daysBetween < 1) {
            // Всі помилки за 1 день - вважаємо це occurrenceCount за тиждень
            result.frequencyPerWeek = result.occurrenceCount;
        } else {
            // Нормалізуємо на тиждень
            result.frequencyPerWeek = (result.occurrenceCount / daysBetween) * 7;
        }

        // Визначити чи це recurring
        result.isRecurring = (result.occurrenceCount >= FREQUENCY_THRESHOLD);

        System.debug('RecurringErrorAnalyzer: errorKey=' + errorKey +
            ', occurrenceCount=' + result.occurrenceCount +
            ', frequencyPerWeek=' + result.frequencyPerWeek +
            ', isRecurring=' + result.isRecurring);

        return result;
    }

    /**
     * Повертає поточний поріг частоти для тестів.
     */
    @TestVisible
    private static Integer getFrequencyThreshold() {
        return FREQUENCY_THRESHOLD;
    }

    /**
     * Повертає період lookback для тестів.
     */
    @TestVisible
    private static Integer getLookbackDays() {
        return LOOKBACK_DAYS;
    }
}