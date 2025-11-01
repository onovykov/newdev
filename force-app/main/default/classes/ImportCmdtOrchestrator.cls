// ImportCmdtOrchestrator.cls
public with sharing class ImportCmdtOrchestrator {

    public static void run(ImportCmdtConfig cfg){
        System.enqueueJob(new ImportTubeODCmdt(cfg));
        System.enqueueJob(new ImportTubeWTCmdt(cfg));

        Integer delay = (cfg.phase2DelayMinutes == null || cfg.phase2DelayMinutes < 1) ? 5 : cfg.phase2DelayMinutes;
        String cron = buildCronAfterMinutes(delay);
        System.schedule('SCH_OD_WT import (+' + delay + 'm)', cron, new SchedSch(cfg));
    }

    // ВАЖЛИВО: робимо public, не global
    public class SchedSch implements Schedulable {
        private ImportCmdtConfig cfg;
        public SchedSch(ImportCmdtConfig cfg){ this.cfg = cfg; }

        // теж public
        public void execute(SchedulableContext sc){
            System.enqueueJob(new ImportSchOdWtCmdt(cfg));
        }
    }

    private static String buildCronAfterMinutes(Integer m){
        Datetime t = Datetime.now().addMinutes(m);
        // sec min hour dayOfMonth month dayOfWeek year
        return String.format('0 {0} {1} {2} {3} ? {4}',
            new List<Object>{ t.minute(), t.hour(), t.day(), t.month(), t.year() });
    }
}