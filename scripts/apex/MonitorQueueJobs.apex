/*
	MonitorQueueJobs.apex
	Показує зведення по Queueable-джобах (Completed/Processing/Queued/Failed), 
	останні помилки та тривалих "довгожителів"
*/
// Запуск: sf apex run -f MonitorQueueJobs.apex
// Налаштування:
String CLASS_NAME = 'GenericQueueHardDelete';   // змінити за потреби
Integer LIMIT_ROWS = 200;                       // скільки останніх джобів аналізувати

List<AsyncApexJob> jobs = [
    SELECT Id, ApexClass.Name, JobType, Status, CreatedDate, CompletedDate,
           NumberOfErrors, ExtendedStatus, ParentJobId
    FROM AsyncApexJob
    WHERE ApexClass.Name = :CLASS_NAME
    ORDER BY CreatedDate DESC
    LIMIT :LIMIT_ROWS
];

Map<String, Integer> byStatus = new Map<String, Integer>();
Integer total = 0;
Datetime nowTs = Datetime.now();

System.debug('--- Queueable monitor for class: ' + CLASS_NAME + ' ---');
for (AsyncApexJob j : jobs) {
    total++;
    byStatus.put(j.Status, (byStatus.containsKey(j.Status) ? byStatus.get(j.Status) + 1 : 1));
}
System.debug('Total jobs scanned: ' + total);
for (String s : byStatus.keySet()) {
    System.debug(String.format('Status {0}: {1}', new List<Object>{ s, byStatus.get(s) }));
}

// Top 10 longest running "Processing"
List<AsyncApexJob> longRunning = new List<AsyncApexJob>();
for (AsyncApexJob j : jobs) {
    if (j.Status == 'Processing') {
        longRunning.add(j);
    }
}
longRunning.sort(new SObjectFieldOrder(AsyncApexJob.CreatedDate)); // oldest first
Integer show = Math.min(10, longRunning.size());
if (show > 0) {
    System.debug('--- Long running (Processing) ---');
    for (Integer i = 0; i < show; i++) {
        AsyncApexJob j = longRunning[i];
        Long secs = (nowTs.getTime() - j.CreatedDate.getTime())/1000;
        System.debug(j.Id + ' | started: ' + j.CreatedDate + ' | running ~' + secs + ' sec'
                     + (j.ExtendedStatus != null ? ' | ' + j.ExtendedStatus : ''));
    }
}

// Last 10 failures with ExtendedStatus
List<AsyncApexJob> failures = new List<AsyncApexJob>();
for (AsyncApexJob j : jobs) {
    if (j.Status == 'Failed' || (j.NumberOfErrors != null && j.NumberOfErrors > 0)) {
        failures.add(j);
    }
}
Integer showFail = Math.min(10, failures.size());
if (showFail > 0) {
    System.debug('--- Recent failures ---');
    for (Integer i = 0; i < showFail; i++) {
        AsyncApexJob j = failures[i];
        System.debug(j.Id + ' | ' + j.Status + ' | err=' + j.NumberOfErrors
                     + (j.ExtendedStatus != null ? ' | ' + j.ExtendedStatus : '')
                     + ' | created ' + j.CreatedDate + ' | completed ' + j.CompletedDate);
    }
}

public class SObjectFieldOrder implements Comparator<AsyncApexJob> {
    SObjectField field;
    public SObjectFieldOrder(SObjectField field) { this.field = field; }
    public Integer compare(AsyncApexJob a, AsyncApexJob b) {
        Datetime da = (Datetime)a.get(this.field);
        Datetime db = (Datetime)b.get(this.field);
        if (da == db) return 0;
        return da < db ? -1 : 1;
    }
}

