public with sharing class ImportCmdtOrchestrator {
    private static final String BASE = 'SCH_OD_WT import';

    public static void run(ImportCmdtConfig cfg){
        System.enqueueJob(new ImportTubeODCmdt(cfg));
        System.enqueueJob(new ImportTubeWTCmdt(cfg));

        Integer delay = (cfg.phase2DelayMinutes == null || cfg.phase2DelayMinutes < 1) ? 5 : cfg.phase2DelayMinutes;
        schedulePhase2(cfg, delay, cfg.abortExistingPhase2);
    }

    private static void schedulePhase2(ImportCmdtConfig cfg, Integer delayMinutes, Boolean abortExisting){
        // 1) Перевіряємо чи є вже заплановані job'и
        List<CronTrigger> existing = [
            SELECT Id, State, CronJobDetail.Name
            FROM CronTrigger
            WHERE CronJobDetail.Name LIKE : (BASE + '%')
              AND State IN ('WAITING','ACQUIRED')
            LIMIT 50
        ];

        if (!existing.isEmpty()){
            if (abortExisting){
                for (CronTrigger ct : existing) System.abortJob(ct.Id);
                System.debug(LoggingLevel.WARN, 'Aborted existing phase-2 jobs: ' + existing.size());
            } else {
                System.debug(LoggingLevel.WARN, 'Phase-2 already scheduled. Skipping new schedule.');
                return;
            }
        }

        // 2) Унікальна назва job'а (щоб уникнути дубляжу)
        Integer delay = (delayMinutes == null || delayMinutes < 1) ? 5 : delayMinutes;
        String uniqueSuffix = String.valueOf(Datetime.now().getTime());
        String jobName = BASE + ' (+' + delay + 'm) #' + uniqueSuffix;

        // 3) CRON і планування
        String cron = buildCronAfterMinutes(delay);
        System.schedule(jobName, cron, new SchedSch(cfg));
        System.debug(LoggingLevel.INFO, 'Scheduled phase-2: ' + jobName);
    }

    public class SchedSch implements Schedulable {
        private ImportCmdtConfig cfg;
        public SchedSch(ImportCmdtConfig cfg){ this.cfg = cfg; }
        public void execute(SchedulableContext sc){
            System.enqueueJob(new ImportSchOdWtCmdt(cfg));
        }
    }

    private static String buildCronAfterMinutes(Integer m){
        Datetime t = Datetime.now().addMinutes(m);
        return String.format('0 {0} {1} {2} {3} ? {4}',
            new List<Object>{ t.minute(), t.hour(), t.day(), t.month(), t.year() });
    }

    public static Integer abortAllPendingPhase2(){
        Integer n = 0;
        for (CronTrigger ct : [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name LIKE : (BASE + '%') AND State IN ('WAITING','ACQUIRED')]){
            System.abortJob(ct.Id);
            n++;
        }
        System.debug(LoggingLevel.INFO, 'Aborted pending phase-2 jobs: ' + n);
        return n;
    }
}