public class SchCmdtSoftWipe {
    public static void run() {
        // підтвердження обсягів
        Integer kids = [SELECT COUNT() FROM SCH_OD_WT__mdt];
        System.debug('SCH_OD_WT__mdt total currently: ' + kids);

        // пакетне вимкнення IsActive (без видалення)
        List<SCH_OD_WT__mdt> rows = [
            SELECT DeveloperName, IsActive__c
            FROM SCH_OD_WT__mdt
        ];
        if (rows.isEmpty()) { System.debug('Nothing to disable.'); return; }

        Metadata.DeployContainer dc = new Metadata.DeployContainer();
        for (SCH_OD_WT__mdt r : rows) {
            Metadata.CustomMetadata md = new Metadata.CustomMetadata();
            md.fullName = 'SCH_OD_WT__mdt.' + r.DeveloperName;

            Metadata.CustomMetadataValue v = new Metadata.CustomMetadataValue();
            v.field = 'IsActive__c';
            v.value = false;
            md.values.add(v);

            dc.addMetadata(md);
        }
        Id jobId = Metadata.Operations.enqueueDeployment(dc, null);
        System.debug('Soft-wipe enqueued: ' + jobId);
    }
}