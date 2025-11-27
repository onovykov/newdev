public class BackfillTubeODUsingAnchor {

    // Колбек для логування результатів metadata deploy
    public class LogCb implements Metadata.DeployCallback {
        public void handleResult(Metadata.DeployResult res, Metadata.DeployCallbackContext ctx) {
            System.debug('OD BACKFILL DEPLOY status=' + res.status + ', success=' + res.success + ', err=' + res.errorMessage);
            if (res.details != null && res.details.componentFailures != null) {
                for (Metadata.DeployMessage m : res.details.componentFailures) {
                    System.debug('OD BACKFILL FAIL ' + m.fullName + ' :: ' + m.problem);
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
     * Робить 2 речі:
     *  1) ДІАГНОСТИКА: рахує, скільки дітей без TubeOD__c мають валідний якір, скільки батьків відсутні,
     *     скільки якорів порожні/некоректні.
     *  2) ФІКС: для валідних якірів, у яких існує батько в Tube_OD__mdt, оновлює дітям TubeOD__c.
     *
     * @param limitKids  — обмеження кількості дітей, яких обробляємо за раз (наприклад, 5000)
     * @param chunkSize  — розмір одного Metadata.DeployContainer (100–200 безпечно)
     */
    public static void run(Integer limitKids, Integer chunkSize) {
        Integer LIMIT_KIDS = (limitKids == null || limitKids <= 0) ? 5000 : limitKids;
        Integer CHUNK      = (chunkSize == null || chunkSize <= 0) ? 100   : chunkSize;

        // 1) Діти без встановленого TubeOD__c
        List<SCH_OD_WT__mdt> kids = [
            SELECT DeveloperName, TubeOD__c, TubeOD_Lookup__c
            FROM SCH_OD_WT__mdt
            WHERE TubeOD__c = null
            LIMIT :LIMIT_KIDS
        ];
        System.debug('KIDS missing TubeOD__c (fetched): ' + kids.size());
        if (kids.isEmpty()) return;

        // 2) Зібрати якорі
        Set<String> anchors = new Set<String>();
        Integer emptyAnchor = 0;
        for (SCH_OD_WT__mdt k : kids) {
            if (String.isBlank(k.TubeOD_Lookup__c)) {
                emptyAnchor++;
            } else {
                anchors.add(k.TubeOD_Lookup__c.trim());
            }
        }
        System.debug('Empty/blank anchors: ' + emptyAnchor + ', distinct non-empty anchors: ' + anchors.size());
        if (anchors.isEmpty()) {
            System.debug('Nothing to do: all anchors are empty/blank.');
            return;
        }

        // 3) Перевірити існування батьків із такими DeveloperName у Tube_OD__mdt
        Set<String> existingParents = new Set<String>();
        for (Tube_OD__mdt od : [
            SELECT DeveloperName
            FROM Tube_OD__mdt
            WHERE DeveloperName IN :anchors
        ]) {
            existingParents.add(od.DeveloperName);
        }
        System.debug('Existing OD parents found: ' + existingParents.size());
        Set<String> missingParents = new Set<String>(anchors);
        missingParents.removeAll(existingParents);
        System.debug('Missing OD parents (by DeveloperName): ' + missingParents.size());

        // 4) Шиємо оновлення тільки тим дітям, у кого якір веде до існуючого батька
        List<Metadata.DeployContainer> containers = new List<Metadata.DeployContainer>();
        Metadata.DeployContainer bag = new Metadata.DeployContainer();
        Integer inBag = 0;
        Integer candidates = 0;

        for (SCH_OD_WT__mdt k : kids) {
            String anchor = (k.TubeOD_Lookup__c == null) ? null : k.TubeOD_Lookup__c.trim();
            if (String.isBlank(anchor)) continue;
            if (!existingParents.contains(anchor)) continue; // батька немає — пропускаємо

            // Готуємо оновлення: ставимо metadata-lookup TubeOD__c рівним DeveloperName батька (тобто anchor)
            Metadata.CustomMetadata cmd = new Metadata.CustomMetadata();
            cmd.fullName = 'SCH_OD_WT__mdt.' + k.DeveloperName;
            cmd.values.add(mv('TubeOD__c', 'Tube_OD__mdt.' + anchor));
            // опційно синхронізуємо якір (на випадок розходжень)
            if (k.TubeOD_Lookup__c != anchor) {
                cmd.values.add(mv('TubeOD_Lookup__c', anchor));
            }

            bag.addMetadata(cmd);
            inBag++;
            candidates++;

            if (inBag >= CHUNK) {
                containers.add(bag);
                bag = new Metadata.DeployContainer();
                inBag = 0;
            }
        }
        if (inBag > 0) containers.add(bag);

        System.debug('Backfill candidates (children to update): ' + candidates);
        System.debug('Deploy containers to enqueue: ' + containers.size());

        // 5) Деплой
        for (Metadata.DeployContainer dc : containers) {
            Id jobId = Metadata.Operations.enqueueDeployment(dc, new LogCb());
            System.debug('OD backfill jobId=' + jobId);
        }

        // 6) Звіт (короткий)
        System.debug('DIAG: kidsFetched=' + kids.size()
            + ', emptyAnchor=' + emptyAnchor
            + ', parentsExisting=' + existingParents.size()
            + ', parentsMissing=' + missingParents.size()
            + ', willUpdate=' + candidates);
    }
}