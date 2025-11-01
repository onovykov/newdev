/*
	AbortQueueJobs.apex
	Абортує всі активні Queueable-джоби цього класу (Queued/Processing). Є безпечний фільтр "старше N хвилин"
*/
// Запуск: sf apex run -f AbortQueueJobs.apex
// Налаштування:
String CLASS_NAME = 'GenericQueueHardDelete';  // змінити за потреби
Boolean ONLY_OLDER_THAN_MIN = true;            // true = абортити тільки джоби, старші за N хв
Integer MINUTES_OLD = 5;                       // поріг “старості” у хвилинах
Integer LIMIT_ROWS = 1000;                     // максимум рядків для підстраховки

Datetime threshold = Datetime.now().addMinutes(-MINUTES_OLD);

List<AsyncApexJob> victims = [
    SELECT Id, ApexClass.Name, Status, CreatedDate
    FROM AsyncApexJob
    WHERE ApexClass.Name = :CLASS_NAME
      AND Status IN ('Queued','Processing')
    ORDER BY CreatedDate ASC
    LIMIT :LIMIT_ROWS
];

Integer toAbort = 0;
for (AsyncApexJob j : victims) {
    if (!ONLY_OLDER_THAN_MIN || j.CreatedDate <= threshold) {
        try {
            System.abortJob(j.Id);
            toAbort++;
            System.debug('Aborted: ' + j.Id + ' | Status=' + j.Status + ' | Created=' + j.CreatedDate);
        } catch (Exception e) {
            System.debug('Failed to abort ' + j.Id + ': ' + e.getMessage());
        }
    } else {
        System.debug('Skipped (too new): ' + j.Id + ' | Created=' + j.CreatedDate);
    }
}
System.debug('Total aborted: ' + toAbort);
