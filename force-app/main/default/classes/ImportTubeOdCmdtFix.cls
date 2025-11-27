public with sharing class ImportTubeOdCmdtFix {
    public class Stats { public Integer needed, present, toCreate, enqueued; }

    public static Stats run() {
        Stats st = new Stats();

        // 1) Унікальні потрібні OD зі «джерела»
        Set<String> need = new Set<String>();
        for (AggregateResult ar : [
            SELECT TubeOD__c od
            FROM OD_SCH_WT__c
            GROUP BY TubeOD__c
        ]) {
            String sfid = String.valueOf(ar.get('od'));
            if (sfid != null) need.add(sfid);
        }
        st.needed = need.size();

        // 2) Що вже є в CMDT (DevName = SF_ID__c)
        Set<String> present = new Set<String>();
        for (Tube_OD__mdt m : [
            SELECT DeveloperName
            FROM Tube_OD__mdt
            WHERE DeveloperName IN :need
        ]) {
            if (m.DeveloperName != null) present.add(m.DeveloperName);
        }
        st.present = present.size();

        // 3) До створення = need − present (чистий Set без дублів)
        need.removeAll(present);
        st.toCreate = need.size();
        if (st.toCreate == 0) return st;

        // 4) Формуємо деплой контейнер БЕЗ дублікатів
        Metadata.DeployContainer dc = new Metadata.DeployContainer();
        for (String devName : need) {
            Metadata.CustomMetadata cmd = new Metadata.CustomMetadata();
            cmd.fullName = 'Tube_OD__mdt.' + devName;
            cmd.label    = devName;

            Metadata.CustomMetadataValue v = new Metadata.CustomMetadataValue();
            v.field = 'SF_ID__c';
            v.value = devName; // зберігаємо SF Id як текст
            cmd.values.add(v);

            dc.addMetadata(cmd);
        }

        // 5) Синхронний деплой (простий варіант) — дочекаємось результату
        Id jobId = Metadata.Operations.enqueueDeployment(dc, null);
        Metadata.DeployResult res = Metadata.Operations.checkDeployStatus(String.valueOf(jobId), true);
        if (!res.success) {
            // Проллогуємо деталі помилок (зручно для дебагу)
            if (res.details != null && res.details.componentFailures != null) {
                for (Metadata.DeployMessage m : res.details.componentFailures) {
                    System.debug('FAIL ' + m.fileName + ' :: ' + m.problem);
                }
            }
            // кинути виняток, щоб не замовчувати проблему
            throw new AuraHandledException('OD CMDT deploy failed: ' + res.errorMessage);
        }
        st.enqueued = st.toCreate;
        return st;
    }
}