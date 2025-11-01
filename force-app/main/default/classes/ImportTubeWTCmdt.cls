/**********************************************************************************
* Перенесення довідників параметрів та характеристик продукції з об'єктів до CMDT * 
***********************************************************************************/
//=== 2. Імпортери з dry-run та “builder” методами
//    2.2. Імпорт TubeWT__c до Tube_WT__mdt
public with sharing class ImportTubeWTCmdt implements Queueable, Database.AllowsCallouts {
    private final ImportCmdtConfig cfg;
    private final Boolean dryRun;

    public ImportTubeWTCmdt(Boolean dryRun){ this.dryRun = dryRun; this.cfg = new ImportCmdtConfig(); this.cfg.dryRun = dryRun; }
    public ImportTubeWTCmdt(ImportCmdtConfig cfg){ this.cfg = cfg; this.dryRun = cfg.dryRun; }     
    //private final Boolean dryRun;
    //public ImportTubeWTCmdt(Boolean dryRun){ this.dryRun = dryRun; }
    public void execute(QueueableContext qc){
        List<Metadata.CustomMetadata> buf = new List<Metadata.CustomMetadata>();
        for (TubeWT__c r : [SELECT Id, ID_ERP__c, Name, WT_mm__c FROM TubeWT__c ORDER BY Name]){
            buf.addAll(buildCmdtRows(new List<TubeWT__c>{ r }));
            if (buf.size() >= CmdtDeployUtil.BATCH_SIZE){ CmdtDeployUtil.deploy(buf, dryRun); buf.clear(); }
        }
        CmdtDeployUtil.deploy(buf, dryRun);
    }
    public static List<Metadata.CustomMetadata> buildCmdtRows(List<TubeWT__c> rows){
        List<Metadata.CustomMetadata> out = new List<Metadata.CustomMetadata>();
        for (TubeWT__c r: rows){
            String dev = CmdtDeployUtil.devNameForWt(r.WT_mm__c);
            Map<String,Object> vals = new Map<String,Object>{
                'SF_ID__c'    => r.Id,
                'ID_ERP__c'   => r.ID_ERP__c,
                'Name__c'     => r.Name,
                'WT_mm__c'    => r.WT_mm__c,
                'IsActive__c' => true
            };
            out.add(CmdtDeployUtil.build('Tube_WT__mdt', dev, r.Name, vals));
        }
        return out;
    }
}