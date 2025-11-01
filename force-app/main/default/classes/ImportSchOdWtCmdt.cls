/**********************************************************************************
* Перенесення довідників параметрів та характеристик продукції з об'єктів до CMDT * 
***********************************************************************************/
//=== 2. Імпортери з dry-run та “builder” методами
//    2.3. Імпорт OD_SCH_WT__c до SCH_OD_WT__mdt
//--- Зауваження:
//      OD_SCH_WT__c - об'єкт зв'язку TubeOD__c та TubeWT__c з відповідними SCH
//      Існує тільки на сенді NewDev, на проді немає
//      Перед деплоєм на прод треба спочатку перенести об'єкт OD_SCH_WT__c
//      та наповнити його даними (з перекодуванням відповідних лукапів)
//-------------------------------------------------------------------------
public with sharing class ImportSchOdWtCmdt implements Queueable, Database.AllowsCallouts {
    private final ImportCmdtConfig cfg;
    private final Boolean dryRun;

    public ImportSchOdWtCmdt(Boolean dryRun){ this.dryRun = dryRun; this.cfg = new ImportCmdtConfig(); this.cfg.dryRun = dryRun; }
    public ImportSchOdWtCmdt(ImportCmdtConfig cfg){ this.cfg = cfg; this.dryRun = cfg.dryRun; }   
    //private final Boolean dryRun;
    //public ImportSchOdWtCmdt(Boolean dryRun){ this.dryRun = dryRun; }
    public void execute(QueueableContext qc){
        List<Metadata.CustomMetadata> buf = new List<Metadata.CustomMetadata>();
        for (OD_SCH_WT__c r : [
            SELECT Id, Name, SCH__c, TubeOD__r.OD_mm__c, TubeWT__r.WT_mm__c
            FROM OD_SCH_WT__c
            WHERE TubeOD__c != null AND TubeWT__c != null
            ORDER BY Name
        ]){
            buf.addAll(buildCmdtRows(new List<OD_SCH_WT__c>{ r }));
            if (buf.size() >= CmdtDeployUtil.BATCH_SIZE){ CmdtDeployUtil.deploy(buf, dryRun); buf.clear(); }
        }
        CmdtDeployUtil.deploy(buf, dryRun);
    }
    public static List<Metadata.CustomMetadata> buildCmdtRows(List<OD_SCH_WT__c> rows){
        List<Metadata.CustomMetadata> out = new List<Metadata.CustomMetadata>();
        for (OD_SCH_WT__c r: rows){
            String odDev = CmdtDeployUtil.devNameForOd(r.TubeOD__r.OD_mm__c);
            String wtDev = CmdtDeployUtil.devNameForWt(r.TubeWT__r.WT_mm__c);
            String dev   = CmdtDeployUtil.devNameForSch(odDev, wtDev, r.SCH__c);
            Map<String,Object> vals = new Map<String,Object>{
                'TubeOD__c'   => 'Tube_OD__mdt.' + odDev,      // relationship value = "Type.DevName"
                'TubeWT__c'   => 'Tube_WT__mdt.' + wtDev,
                'SCH__c'      => r.SCH__c,                     // TEXT (STD, XS, …)
                'IsActive__c' => true
            };
            out.add(CmdtDeployUtil.build('SCH_OD_WT__mdt', dev, r.Name, vals));
        }
        return out;
    }
}