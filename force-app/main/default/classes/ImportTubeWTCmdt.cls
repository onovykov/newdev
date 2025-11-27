/**********************************************************************************
* Імпорт TubeWT__c → Tube_WT__mdt (один deploy на виконання, upsert у CmdtDeployUtil)
**********************************************************************************/
public with sharing class ImportTubeWTCmdt implements Queueable, Database.AllowsCallouts {
    private final ImportCmdtConfig cfg;
    private final Boolean dryRun;

    public ImportTubeWTCmdt(Boolean dryRun){
        this.dryRun = dryRun;
        this.cfg = new ImportCmdtConfig(); this.cfg.dryRun = dryRun;
    }
    public ImportTubeWTCmdt(ImportCmdtConfig cfg){
        this.cfg = cfg; this.dryRun = cfg.dryRun;
    }

    public void execute(QueueableContext qc){
        // 1) SOQL з урахуванням cfg
        String soql = buildSoql(cfg);

        // 2) Збір усіх CMDT-записів (одним буфером)
        List<Metadata.CustomMetadata> all = new List<Metadata.CustomMetadata>();
        for (SObject sobj : Database.query(soql)){
            TubeWT__c r = (TubeWT__c) sobj;
            all.add(buildSingle(r));
        }

        // 3) Один-єдиний deploy
        CmdtDeployUtil.deploy(all, dryRun);

        // 4) Опційна деактивація відсутніх
        if (cfg.deactivateMissing == true){
            Set<String> seen = new Set<String>();
            for (Metadata.CustomMetadata m : all){
                String[] p = m.fullName != null ? m.fullName.split('\\.') : new String[]{};
                if (p.size() == 2) seen.add(p[1]);
            }
            CmdtDeactivateUtil.deactivateMissing('Tube_WT__mdt', seen, dryRun);
        }
    }

    private static Metadata.CustomMetadata buildSingle(TubeWT__c r){
        //String dev = CmdtDeployUtil.devNameForWt(r.WT_mm__c);
        //String dev = CmdtDeployUtil.devName((r.Id != null ? String.valueOf(r.Id) : null));
        String dev = CmdtDeployUtil.devNameFromId(r.Id);
        Map<String,Object> vals = new Map<String,Object>{
            'SF_ID__c'    => (r.Id != null ? String.valueOf(r.Id) : null),
            'ID_ERP__c'   => r.ID_ERP__c,
            'Name__c'     => r.Name,
            'WT_mm__c'    => r.WT_mm__c,
            'IsActive__c' => true
        };
        return CmdtDeployUtil.build('Tube_WT__mdt', dev, r.Name, vals);
    }

    private static String buildSoql(ImportCmdtConfig cfg){
        String base = 'SELECT Id, ID_ERP__c, Name, WT_mm__c FROM TubeWT__c';
        List<String> wh = new List<String>();

        if (cfg != null && cfg.since != null){
            wh.add('LastModifiedDate >= :dt');
        }
        Boolean hasIsActive = Schema.getGlobalDescribe().get('TubeWT__c')
            .getDescribe().fields.getMap().containsKey('IsActive__c');
        if (cfg != null && cfg.onlyActiveSource == true && hasIsActive){
            wh.add('IsActive__c = true');
        }

        String wherePart = wh.isEmpty() ? '' : (' WHERE ' + String.join(wh, ' AND '));
        String orderPart = ' ORDER BY Name';

        String soql = base + wherePart + orderPart;
        if (cfg != null && cfg.since != null){
            soql = soql.replace(':dt', ':' + String.valueOf(cfg.since));
        }
        return soql;
    }
}