public class SchCmdtRebuild {
    public static void run(Integer batchSize) {
        if (batchSize == null || batchSize <= 0) batchSize = 200;

        List<OD_SCH_WT__c> src = [
            SELECT Id, TubeOD__c, TubeWT__c, SCH__c
            FROM OD_SCH_WT__c
            ORDER BY TubeOD__c, TubeWT__c, SCH__c
        ];
        System.debug('Source rows: ' + src.size());

        for (Integer i = 0; i < src.size(); i += batchSize) {
            Integer to = Math.min(i + batchSize, src.size());
            Metadata.DeployContainer dc = new Metadata.DeployContainer();

            for (Integer k = i; k < to; k++) {
                OD_SCH_WT__c s = src[k];

                Metadata.CustomMetadata md = new Metadata.CustomMetadata();
                md.fullName = 'SCH_OD_WT__mdt.' + String.valueOf(s.Id); // DevName = SF Id
                // IsActive=true
                Metadata.CustomMetadataValue vA = new Metadata.CustomMetadataValue();
                vA.field = 'IsActive__c'; vA.value = true; md.values.add(vA);

                // SF_ID__c
                Metadata.CustomMetadataValue vSf = new Metadata.CustomMetadataValue();
                vSf.field = 'SF_ID__c'; vSf.value = String.valueOf(s.Id); md.values.add(vSf);

                // Якорі
                Metadata.CustomMetadataValue vOd = new Metadata.CustomMetadataValue();
                vOd.field = 'TubeOD_Lookup__c'; vOd.value = String.valueOf(s.TubeOD__c); md.values.add(vOd);

                Metadata.CustomMetadataValue vWt = new Metadata.CustomMetadataValue();
                vWt.field = 'TubeWT_Lookup__c'; vWt.value = String.valueOf(s.TubeWT__c); md.values.add(vWt);

                // SCH__c
                Metadata.CustomMetadataValue vSch = new Metadata.CustomMetadataValue();
                vSch.field = 'SCH__c'; vSch.value = String.valueOf(s.SCH__c); md.values.add(vSch);

                dc.addMetadata(md);
            }

            Id jobId = Metadata.Operations.enqueueDeployment(dc, null);
            System.debug('Rebuild batch enqueued: ' + jobId + ' (rows ' + i + '..' + (to-1) + ')');
        }
    }
}