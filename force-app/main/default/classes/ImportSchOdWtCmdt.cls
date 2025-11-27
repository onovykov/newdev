public with sharing class ImportSchOdWtCmdt {

    // Приватний callback як звичайний внутрішній клас (жодних анонімних конструкцій)
    private class DeployCb implements Metadata.DeployCallback {
        public void handleResult(Metadata.DeployResult result,
                                 Metadata.DeployCallbackContext context) {
            System.debug('CMDT deploy finished. Success=' + result.success + ', status=' + result.status);
            if (result.details != null && result.details.componentFailures != null) {
                for (Metadata.DeployMessage m : result.details.componentFailures) {
                    System.debug('FAIL in ' + m.fileName + ' :: ' + m.problem);
                }
            }
        }
    }

    // Зручний helper для значень CMDT
    private static Metadata.CustomMetadataValue cmv(String fieldApi, String val) {
        Metadata.CustomMetadataValue v = new Metadata.CustomMetadataValue();
        v.field = fieldApi;
        v.value = val;
        return v;
    }

    public static void runNow(ImportCmdtConfig cfg) {
        System.debug('=== START SCH runCore ===');

        // 1) Мапи SF_ID__c -> DeveloperName з батьківських CMDT
        Map<String,String> odDevBySfId = new Map<String,String>();
        for (Tube_OD__mdt r : [SELECT SF_ID__c, DeveloperName FROM Tube_OD__mdt WHERE SF_ID__c != null]) {
            odDevBySfId.put(r.SF_ID__c, r.DeveloperName);
        }
        Map<String,String> wtDevBySfId = new Map<String,String>();
        for (Tube_WT__mdt r : [SELECT SF_ID__c, DeveloperName FROM Tube_WT__mdt WHERE SF_ID__c != null]) {
            wtDevBySfId.put(r.SF_ID__c, r.DeveloperName);
        }

        // 2) Джерело
        List<OD_SCH_WT__c> src = [
            SELECT Id, TubeOD__c, TubeWT__c, SCH__c
            FROM OD_SCH_WT__c
            ORDER BY TubeOD__c, TubeWT__c, SCH__c
        ];
        System.debug('Rows fetched: ' + src.size());

        Metadata.DeployContainer dc = new Metadata.DeployContainer();
        Integer prepared = 0;

        for (OD_SCH_WT__c s : src) {
            String odSf = String.valueOf(s.TubeOD__c);
            String wtSf = String.valueOf(s.TubeWT__c);
            String odDev = odDevBySfId.get(odSf);
            String wtDev = wtDevBySfId.get(wtSf);

            Metadata.CustomMetadata cmd = new Metadata.CustomMetadata();
            String devName = String.valueOf(s.Id);               // upsert-ключ
            cmd.fullName = 'SCH_OD_WT__mdt.' + devName;
            cmd.label    = devName;

            List<Metadata.CustomMetadataValue> vals = new List<Metadata.CustomMetadataValue>();
            vals.add(cmv('SF_ID__c',          devName));
            vals.add(cmv('TubeOD_Lookup__c',  odSf));
            vals.add(cmv('TubeWT_Lookup__c',  wtSf));
            vals.add(cmv('SCH__c',            String.valueOf(s.SCH__c)));

            // У metadata-lookup поля пишемо DEVNAME батьків
            if (odDev != null) vals.add(cmv('TubeOD__c', odDev));
            if (wtDev != null) vals.add(cmv('TubeWT__c', wtDev));

            cmd.values = vals;
            dc.addMetadata(cmd);
            prepared++;
        }

        System.debug('Prepared CMDT rows: ' + prepared);

        if (cfg != null && cfg.dryRun) {
            System.debug('Dry-run: deploy is skipped');
            System.debug('=== END SCH runCore ===');
            return;
        }

        Id jobId = Metadata.Operations.enqueueDeployment(dc, new DeployCb());
        System.debug('CMDT deploy enqueued: ' + jobId);
        System.debug('=== END SCH runCore ===');
    }
}