public with sharing class ImportCmdtConfig {
    public Boolean dryRun = true;
    public Datetime since;
    public Boolean onlyActiveSource = false;
    public Boolean logToObject = true;
    public Boolean logToEvent  = false;
    public Boolean deactivateMissing = false;
    public Integer phase2DelayMinutes = 10;
}