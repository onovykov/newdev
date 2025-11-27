public class BackfillTubeODFromSource {

    // Простіший логер результатів деплою
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

    private static Metadata.CustomMetadataValue mv(String field, String value) {
        Metadata.CustomMetadataValue v = new Metadata.CustomMetadataValue();
        v.field = field;
        v.value = value;
        return v;
    }

    /**
     * Дозаповнює TubeOD__c у SCH_OD_WT__mdt, беручи референс з OD_SCH_WT__c по SF_ID__c.
     * @param chunkSize розмір пачки для одного enqueueDeployment (рекомендовано 50–200)
     * @param maxRows   верхня межа кількості оновлюваних записів за один прогін (safety cap)
     */
    public static void run(Integer chunkSize, Integer maxRows) {
        Integer CHUNK = (chunkSize == null || chunkSize <= 0) ? 100 : chunkSize;
        Integer LIMIT_ROWS = (maxRows == null || maxRows <= 0) ? 5000 : maxRows;

        // 1) Беремо дітей без TubeOD__c (але беремо всіх — незалежно від TubeOD_Lookup__c)
        List<SCH_OD_WT__mdt> kids = [
            SELECT DeveloperName, SF_ID__c, TubeOD_Lookup__c
            FROM SCH_OD_WT__mdt
            WHERE TubeOD__c = null
            LIMIT :LIMIT_ROWS
        ];
        System.debug('Kids missing TubeOD__c: ' + kids.size());
        if (kids.isEmpty()) return;

        // 2) Збираємо IDS джерела (SF_ID__c зберігає Id запису OD_SCH_WT__c як текст)
        Set<Id> sourceIds = new Set<Id>();
        for (SCH_OD_WT__mdt k : kids) {
            if (k.SF_ID__c != null && k.SF_ID__c.length() == 18) {
                try { sourceIds.add(Id.valueOf(k.SF_ID__c)); } catch (Exception e) {/*skip bad*/}
            }
        }
        System.debug('Source Ids to resolve: ' + sourceIds.size());
        if (sourceIds.isEmpty()) return;

        // 3) Тягнемо з джерела TubeOD__c (це DevName батьківського CMDT)
        Map<Id, String> srcId2ParentDev = new Map<Id, String>();
        for (OD_SCH_WT__c s : [
            SELECT Id, TubeOD__c
            FROM OD_SCH_WT__c
            WHERE Id IN :sourceIds
        ]) {
            // важливо: у CMDT-lookup значенням має бути DeveloperName (string)
            srcId2ParentDev.put(s.Id, String.valueOf(s.TubeOD__c));
        }

        // 4) Готуємо оновлення CMDT батчами
        List<Metadata.DeployContainer> containers = new List<Metadata.DeployContainer>();
        Metadata.DeployContainer dc = new Metadata.DeployContainer();
        Integer inBatch = 0;

        for (SCH_OD_WT__mdt k : kids) {
            String parentDev = null;
            if (k.SF_ID__c != null && k.SF_ID__c.length() == 18) {
                try { parentDev = srcId2ParentDev.get(Id.valueOf(k.SF_ID__c)); } catch (Exception e) {}
            }
            if (String.isBlank(parentDev)) {
                // немає батька в джерелі — пропускаємо, потім зможемо діагностувати окремо
                continue;
            }

            Metadata.CustomMetadata cmd = new Metadata.CustomMetadata();
            cmd.fullName = 'SCH_OD_WT__mdt.' + k.DeveloperName;
            // ставимо metadata-lookup на батька (значення = DeveloperName батька)
            cmd.values.add(mv('TubeOD__c', parentDev));
            // опціонально — синхронізуємо текстовий "якір", щоб надалі простіше діагностувати
            if (k.TubeOD_Lookup__c == null || k.TubeOD_Lookup__c != parentDev) {
                cmd.values.add(mv('TubeOD_Lookup__c', parentDev));
            }

            dc.addMetadata(cmd);
            inBatch++;
            if (inBatch >= CHUNK) {
                containers.add(dc);
                dc = new Metadata.DeployContainer();
                inBatch = 0;
            }
        }
        if (inBatch > 0) containers.add(dc);

        // 5) Шлемо деплої
        System.debug('Deploy containers: ' + containers.size());
        for (Metadata.DeployContainer bag : containers) {
            Id jobId = Metadata.Operations.enqueueDeployment(bag, new LogCb());
            System.debug('Enqueued jobId=' + jobId);
        }
    }
}