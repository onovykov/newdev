public with sharing class ImportCmdtConfig {
    public Boolean dryRun = true;
    public Datetime since = null;
    public Boolean onlyActiveSource = false;
    public Boolean logToObject = true;
    public Boolean logToEvent  = false;
    public Boolean deactivateMissing = false;
    public Integer phase2DelayMinutes = 10;
    public Integer limitPerType = 100;

    // нове поле: чи абортувати попередні заплановані фази-2 (SCH)
    public Boolean abortExistingPhase2 = false;
}