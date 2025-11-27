public class BackfillTubeODLookup {
    // Логгер результатів деплою
    public class LogCb implements Metadata.DeployCallback {
        public void handleResult(Metadata.DeployResult result,
                                 Metadata.DeployCallbackContext context) {
            System.debug('DEPLOY status=' + result.status +
                         ', success=' + result.success +
                         ', err=' + result.errorMessage);
            if (result.details != null && result.details.componentFailures != null) {
                for (Metadata.DeployMessage m : result.details.componentFailures) {
                    System.debug('FAIL ' + m.fullName + ' :: ' + m.problem);
                }
            }
        }
    }

    // Допоміжний конструктор значень CMDT
    private static Metadata.CustomMetadataValue mv(String field, String value) {
        Metadata.CustomMetadataValue v = new Metadata.CustomMetadataValue();
        v.field = field;
        v.value = value; // для Metadata Relationship — це DeveloperName батька (string)
        return v;
    }

    /** Дозаповнює TubeOD__c там, де воно null.
     *  @param chunkSize скільки записів оновлювати за один enqueue (реком. 50–200)
     */
    public static void run(Integer chunkSize) {
        Integer CHUNK = (chunkSize == null || chunkSize <= 0) ? 100 : chunkSize;

        // Беремо тільки ті дитячі записи, де lookup ще порожній, але є наш «якір» TubeOD_Lookup__c
        List<SCH_OD_WT__mdt> rows = [
            SELECT DeveloperName, TubeOD_Lookup__c
            FROM SCH_OD_WT__mdt
            WHERE TubeOD__c = null AND TubeOD_Lookup__c != null
            LIMIT 5000
        ];
        System.debug('Rows to fix: ' + rows.size());

        for (Integer i = 0; i < rows.size(); i += CHUNK) {
            Metadata.DeployContainer dc = new Metadata.DeployContainer();

            Integer endvar = Math.min(i + CHUNK, rows.size());
            for (Integer j = i; j < endvar; j++) {
                SCH_OD_WT__mdt r = rows[j];

                Metadata.CustomMetadata cmd = new Metadata.CustomMetadata();
                // Оновлюємо існуючий запис — тому вказуємо fullName з DeveloperName дитини
                cmd.fullName = 'SCH_OD_WT__mdt.' + r.DeveloperName;

                // Встановлюємо Metadata Relationship (значенням є DeveloperName батька, тобто наш TubeOD_Lookup__c)
                cmd.values.add(mv('TubeOD__c', String.valueOf(r.TubeOD_Lookup__c)));

                dc.addMetadata(cmd);
            }

            Id jobId = Metadata.Operations.enqueueDeployment(dc, new LogCb());
            System.debug('Enqueued jobId=' + jobId + ' for rows ' + i + '..' + (endvar - 1));
        }
    }
}