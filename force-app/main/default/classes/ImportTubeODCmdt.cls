/**********************************************************************************
* Перенесення довідників параметрів та характеристик продукції з об'єктів до CMDT * 
***********************************************************************************/
//=== 2. Імпортери з dry-run та “builder” методами
//    2.1. Імпорт TubeOD__c до Tube_OD__mdt
public with sharing class ImportTubeODCmdt implements Queueable, Database.AllowsCallouts {
    private final ImportCmdtConfig cfg;
    private final Boolean dryRun;

    public ImportTubeODCmdt(Boolean dryRun){ this.dryRun = dryRun; this.cfg = new ImportCmdtConfig(); this.cfg.dryRun = dryRun; }
    public ImportTubeODCmdt(ImportCmdtConfig cfg){ this.cfg = cfg; this.dryRun = cfg.dryRun; }

    //private final Boolean dryRun;
    //public ImportTubeODCmdt(Boolean dryRun){ this.dryRun = dryRun; }
    public void execute(QueueableContext qc){
        List<Metadata.CustomMetadata> buf = new List<Metadata.CustomMetadata>();
        for (TubeOD__c r : [SELECT Id, ID_ERP__c, Name, OD_mm__c, H_mm__c, L_mm__c, NPS__c, IsRound__c FROM TubeOD__c ORDER BY Name]){
            buf.addAll(buildCmdtRows(new List<TubeOD__c>{ r }));
            if (buf.size() >= CmdtDeployUtil.BATCH_SIZE){ CmdtDeployUtil.deploy(buf, dryRun); buf.clear(); }
        }
        CmdtDeployUtil.deploy(buf, dryRun);
    }
    public static List<Metadata.CustomMetadata> buildCmdtRows(List<TubeOD__c> rows){
        List<Metadata.CustomMetadata> out = new List<Metadata.CustomMetadata>();
        for (TubeOD__c r: rows){
            String dev = CmdtDeployUtil.devNameForOd(r.OD_mm__c);
            Map<String,Object> vals = new Map<String,Object>{
                'SF_ID__c'    => r.Id,
                'ID_ERP__c'   => r.ID_ERP__c,
                'Name__c'     => r.Name,
                'OD_mm__c'    => r.OD_mm__c,
                'H_mm__c'     => r.H_mm__c,
                'L_mm__c'     => r.L_mm__c,
                'NPS__c'      => r.NPS__c,
                'IsRound__c'  => r.IsRound__c,
                'IsActive__c' => true
            };
            out.add(CmdtDeployUtil.build('Tube_OD__mdt', dev, r.Name, vals));
        }
        return out;
    }
}