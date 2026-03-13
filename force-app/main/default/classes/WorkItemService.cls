/**
 * Сервіс для роботи з Notification_Work_Item__c.
 * Створює Work Items для ескалацій помилок.
 */
public with sharing class WorkItemService {

    /**
     * Створює Work Item для ескалації помилки.
     * @param errorKey - ключ помилки з Error_Classification__mdt
     * @param pharosLogId - ID Pharos Log запису (опціонально)
     * @param assigneeId - ID користувача (assignee, опціонально - можна null)
     * @param reactTimeHours - час реакції в годинах
     * @param errorDetails - додаткові деталі помилки
     * @param pharosLogs - список всіх pharos__Log__c за період (для escalation)
     * @return ID створеного Work Item
     */
    public static Id createWorkItem(
        String errorKey,
        Id pharosLogId,
        Id assigneeId,
        Decimal reactTimeHours,
        Map<String, Object> errorDetails,
        List<pharos__Log__c> pharosLogs
    ) {
        if (String.isBlank(errorKey)) {
            throw new WorkItemException('errorKey cannot be blank');
        }

        // Визначити DueDate = Now + reactTimeHours
        DateTime dueDate = DateTime.now();
        if (reactTimeHours != null && reactTimeHours > 0) {
            Long millisToAdd = (reactTimeHours * 60 * 60 * 1000).longValue();
            dueDate = DateTime.newInstance(dueDate.getTime() + millisToAdd);
        }

        // Побудувати Summary
        String summary = buildSummary(errorKey, errorDetails);

        // Побудувати Details з інформацією про всі pharos logs
        String details = buildDetails(errorKey, errorDetails, pharosLogs);

        // Побудувати Correlation Key (унікальний ключ для цього Work Item)
        String correlationKey = buildCorrelationKey(errorKey, pharosLogId);

        // Розрахувати час першого нагадування
        DateTime now = DateTime.now();
        DateTime firstReminderTime = WorkItemReminderService.calculateFirstReminderTime(now, reactTimeHours);

        // Створити Work Item (assigneeId може бути null)
        Notification_Work_Item__c workItem = new Notification_Work_Item__c(
            Summary__c = summary,
            Details__c = details,
            Work_Status__c = 'New',
            Notification_Type__c = errorKey,
            Reaction_Time_Hours__c = reactTimeHours,
            Correlation_Key__c = correlationKey,
            Reminder_Count__c = 0,
            Next_Reminder_At__c = firstReminderTime
        );

        // Додати OwnerId тільки якщо assigneeId не null
        if (assigneeId != null) {
            workItem.OwnerId = assigneeId;
        }

        try {
            insert workItem;
            System.debug('WorkItemService: Work Item created successfully, Id: ' + workItem.Id);
            return workItem.Id;
        } catch (DmlException e) {
            System.debug(LoggingLevel.ERROR,
                'WorkItemService: Failed to create Work Item: ' + e.getMessage());
            throw new WorkItemException('Failed to create Work Item: ' + e.getMessage(), e);
        }
    }

    /**
     * Будує Summary для Work Item.
     */
    private static String buildSummary(String errorKey, Map<String, Object> errorDetails) {
        String summary = 'Error Escalation: ' + errorKey;

        // Додати occurrence count якщо є
        if (errorDetails != null && errorDetails.containsKey('occurrenceCount')) {
            Integer count = (Integer) errorDetails.get('occurrenceCount');
            summary += ' (' + count + ' occurrences)';
        }

        // Обмежити до 255 символів (ліміт поля)
        if (summary.length() > 255) {
            summary = summary.substring(0, 255);
        }

        return summary;
    }

    /**
     * Будує Details для Work Item з інформацією про всі pharos logs.
     */
    private static String buildDetails(
        String errorKey,
        Map<String, Object> errorDetails,
        List<pharos__Log__c> pharosLogs
    ) {
        List<String> lines = new List<String>();

        lines.add('=== Error Escalation Details ===');
        lines.add('Error Key: ' + errorKey);
        lines.add('Escalated At: ' + DateTime.now().format('yyyy-MM-dd HH:mm:ss'));
        lines.add('');

        if (errorDetails != null) {
            // Occurrence Count
            if (errorDetails.containsKey('occurrenceCount')) {
                lines.add('Occurrence Count: ' + errorDetails.get('occurrenceCount'));
            }

            // Frequency Per Week
            if (errorDetails.containsKey('frequencyPerWeek')) {
                Decimal freq = (Decimal) errorDetails.get('frequencyPerWeek');
                lines.add('Frequency: ' + freq.setScale(1) + ' times per week');
            }

            // Oldest and Newest Occurrence
            if (errorDetails.containsKey('oldestOccurrence')) {
                DateTime oldest = (DateTime) errorDetails.get('oldestOccurrence');
                lines.add('Oldest Occurrence: ' + oldest.format('yyyy-MM-dd HH:mm:ss'));
            }
            if (errorDetails.containsKey('newestOccurrence')) {
                DateTime newest = (DateTime) errorDetails.get('newestOccurrence');
                lines.add('Newest Occurrence: ' + newest.format('yyyy-MM-dd HH:mm:ss'));
            }
        }

        // Додати список всіх pharos__Log__c за період
        if (pharosLogs != null && !pharosLogs.isEmpty()) {
            lines.add('');
            lines.add('=== All Error Occurrences (Last 7 Days) ===');
            lines.add('');

            Integer index = 1;
            for (pharos__Log__c log : pharosLogs) {
                lines.add('--- Occurrence #' + index + ' ---');
                lines.add('Pharos Log ID: ' + log.Id);
                lines.add('Created: ' + log.CreatedDate.format('yyyy-MM-dd HH:mm:ss'));

                if (!String.isBlank(log.pharos__Summary__c)) {
                    lines.add('Summary: ' + log.pharos__Summary__c);
                }

                if (!String.isBlank(log.pharos__Type__c)) {
                    lines.add('Type: ' + log.pharos__Type__c);
                }

                if (!String.isBlank(log.pharos__Area__c)) {
                    lines.add('Area: ' + log.pharos__Area__c);
                }

                if (!String.isBlank(log.pharos__Related_Objects__c)) {
                    lines.add('Related Objects: ' + log.pharos__Related_Objects__c);
                }

                lines.add('');
                index++;

                // Обмежити кількість логів для запобігання переповнення
                if (index > 20) {
                    lines.add('... (showing first 20 of ' + pharosLogs.size() + ' errors)');
                    break;
                }
            }
        }

        String details = String.join(lines, '\n');

        // Обмежити до 32768 символів (ліміт Long Text Area)
        if (details.length() > 32768) {
            details = details.substring(0, 32765) + '...';
        }

        return details;
    }

    /**
     * Будує Correlation Key для унікальної ідентифікації Work Item.
     */
    private static String buildCorrelationKey(String errorKey, Id pharosLogId) {
        String key = errorKey + '_' + String.valueOf(pharosLogId);

        // Обмежити до 255 символів
        if (key.length() > 255) {
            key = key.substring(0, 255);
        }

        return key;
    }

    /**
     * Custom exception для WorkItemService.
     */
    public class WorkItemException extends Exception {}
}