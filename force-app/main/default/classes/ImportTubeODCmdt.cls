/**********************************************************************************
* Імпорт TubeOD__c → Tube_OD__mdt (один deploy на виконання, upsert у CmdtDeployUtil)
**********************************************************************************/
public with sharing class ImportTubeODCmdt implements Queueable, Database.AllowsCallouts {
    private final ImportCmdtConfig cfg;
    private final Boolean dryRun;

    public ImportTubeODCmdt(Boolean dryRun){
        this.dryRun = dryRun;
        this.cfg = new ImportCmdtConfig(); this.cfg.dryRun = dryRun;
    }
    public ImportTubeODCmdt(ImportCmdtConfig cfg){
        this.cfg = cfg; this.dryRun = cfg.dryRun;
    }

    public void execute(QueueableContext qc){
        // 1) Побудувати SOQL з урахуванням cfg
        String soql = buildSoql(cfg);

        // 2) Зібрати всі CMDT-записи (одним буфером)
        List<Metadata.CustomMetadata> all = new List<Metadata.CustomMetadata>();
        for (SObject sobj : Database.query(soql)){
            TubeOD__c r = (TubeOD__c) sobj;
            all.add(buildSingle(r));
        }

        // 3) ЄРС — один виклик deploy на все виконання (жодного повторного enqueue)
        CmdtDeployUtil.deploy(all, dryRun);

        // 4) Після деплою — опційна деактивація відсутніх
        if (cfg.deactivateMissing == true){
            // зібрати множину DevNames, які ми щойно імпортували
            Set<String> seen = new Set<String>();
            for (Metadata.CustomMetadata m : all){
                String[] p = m.fullName != null ? m.fullName.split('\\.') : new String[]{};
                if (p.size() == 2) seen.add(p[1]);
            }
            CmdtDeactivateUtil.deactivateMissing('Tube_OD__mdt', seen, dryRun);
        }
    }

    // Побудова одного CustomMetadata для Tube_OD__mdt
    private static Metadata.CustomMetadata buildSingle(TubeOD__c r){
        //String dev = CmdtDeployUtil.devNameForOd(r.OD_mm__c);
        //String dev = CmdtDeployUtil.devName((r.Id != null ? String.valueOf(r.Id) : null));
        String dev = CmdtDeployUtil.devNameFromId(r.Id);
        Map<String,Object> vals = new Map<String,Object>{
            'SF_ID__c'    => (r.Id != null ? String.valueOf(r.Id) : null),
            'ID_ERP__c'   => r.ID_ERP__c,
            'Name__c'     => r.Name,
            'OD_mm__c'    => r.OD_mm__c,
            'H_mm__c'     => r.H_mm__c,
            'L_mm__c'     => r.L_mm__c,
            'NPS__c'      => r.NPS__c,
            'IsRound__c'  => r.IsRound__c,
            'IsActive__c' => true
        };
        return CmdtDeployUtil.build('Tube_OD__mdt', dev, r.Name, vals);
    }

    // Динамічний SOQL з урахуванням cfg.since та cfg.onlyActiveSource (якщо поле існує)
    private static String buildSoql(ImportCmdtConfig cfg){
        String base = 'SELECT Id, ID_ERP__c, Name, OD_mm__c, H_mm__c, L_mm__c, NPS__c, IsRound__c FROM TubeOD__c';
        List<String> wh = new List<String>();

        if (cfg != null && cfg.since != null){ wh.add('LastModifiedDate >= :dt'); }
        Boolean hasIsActive = Schema.getGlobalDescribe().get('TubeOD__c')
            .getDescribe().fields.getMap().containsKey('IsActive__c');
        if (cfg != null && cfg.onlyActiveSource == true && hasIsActive){ wh.add('IsActive__c = true'); }

        String soql = base + (wh.isEmpty() ? '' : ' WHERE ' + String.join(wh, ' AND '))
                            + ' ORDER BY Id';

        if (cfg != null && cfg.since != null){
            soql = soql.replace(':dt', ':' + String.valueOf(cfg.since));
        }
        if (cfg != null && cfg.limitPerType != null && cfg.limitPerType > 0){
            soql += ' LIMIT ' + String.valueOf(cfg.limitPerType);
        }
        return soql;
    }
}