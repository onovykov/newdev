/**********************************************************************************
* Універсальна утиліта для деплою Custom Metadata (CMDT) із підтримкою UPSERT-логіки *
* Oleksander Novykov, 2025-11-01
***********************************************************************************/
public with sharing class CmdtDeployUtil {
    public static final Integer BATCH_SIZE = 100;

    //=== Колбек, який отримує результат деплою (Metadata API callback)
    public class DeployCb implements Metadata.DeployCallback {
        public void handleResult(Metadata.DeployResult res, Metadata.DeployCallbackContext ctx) {
            if (res.status == Metadata.DeployStatus.Succeeded) {
                System.debug(LoggingLevel.INFO, 'CMDT deploy OK');
            } else {
                System.debug(LoggingLevel.ERROR, 'CMDT deploy FAILED: ' + res.errorMessage);
                System.debug(LoggingLevel.ERROR, JSON.serialize(res.details));
            }
        }
    }

    //=== Основний метод деплою (із підтримкою UPSERT)
    public static void deploy(List<Metadata.CustomMetadata> mdRecords, Boolean dryRun) {
        if (mdRecords == null || mdRecords.isEmpty()) return;

        // --- DRY-RUN MODE ---
        if (dryRun) {
            System.debug(LoggingLevel.INFO, 'DRY-RUN: would deploy ' + mdRecords.size() + ' CMDT recs');
            System.debug(LoggingLevel.DEBUG, JSON.serialize(mdRecords));
            return;
        }

        // === Отримуємо наявні DeveloperName для кожного типу CMDT
        Set<String> typeApiNames = new Set<String>();
        for (Metadata.CustomMetadata rec : mdRecords) {
            if (rec.fullName != null && rec.fullName.contains('.')) {
                String t = rec.fullName.split('\\.')[0];
                if (!String.isBlank(t)) typeApiNames.add(t);
            }
        }

        Map<String, Set<String>> existingNamesByType = new Map<String, Set<String>>();
        for (String typeApi : typeApiNames) {
            Set<String> names = new Set<String>();
            try {
                String soql = 'SELECT DeveloperName FROM ' + typeApi;
                for (SObject s : Database.query(soql)) {
                    names.add((String) s.get('DeveloperName'));
                }
            } catch (Exception e) {
                System.debug(LoggingLevel.WARN, 'Cannot query existing CMDT for ' + typeApi + ': ' + e.getMessage());
            }
            existingNamesByType.put(typeApi, names);
        }

        // === Ділимо записи на нові й ті, що треба оновити
        List<Metadata.CustomMetadata> newRecords = new List<Metadata.CustomMetadata>();
        List<Metadata.CustomMetadata> updateRecords = new List<Metadata.CustomMetadata>();

        for (Metadata.CustomMetadata rec : mdRecords) {
            String[] parts = rec.fullName != null ? rec.fullName.split('\\.') : new String[]{};
            if (parts.size() == 2) {
                String typeApi = parts[0];
                String devName = parts[1];
                if (existingNamesByType.containsKey(typeApi) &&
                    existingNamesByType.get(typeApi).contains(devName)) {
                    updateRecords.add(rec);
                } else {
                    newRecords.add(rec);
                }
            } else {
                newRecords.add(rec);
            }
        }

        System.debug(LoggingLevel.INFO, 'Preparing CMDT deploy: '
            + newRecords.size() + ' new, '
            + updateRecords.size() + ' updates');

        // === Створюємо контейнер деплою
        Metadata.DeployContainer dc = new Metadata.DeployContainer();
        for (Metadata.CustomMetadata rec : newRecords) dc.addMetadata(rec);
        for (Metadata.CustomMetadata rec : updateRecords) dc.addMetadata(rec);

        // === Запускаємо деплой
        try {
            Id jobId = Metadata.Operations.enqueueDeployment(dc, new DeployCb());
            if (jobId == null) {
                System.debug(LoggingLevel.ERROR, 'CMDT deploy not enqueued (jobId=null)');
            } else {
                System.debug(LoggingLevel.INFO, 'CMDT deploy enqueued: ' + jobId + ' (' + mdRecords.size() + ' total)');
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'CMDT deploy enqueue failed: ' + e.getMessage());
        }
    }

    //=== Створює об’єкт Metadata.CustomMetadata із полями
    public static Metadata.CustomMetadata build(
        String typeApiName, String developerName, String label, Map<String, Object> fieldValues
    ) {
        Metadata.CustomMetadata cmd = new Metadata.CustomMetadata();
        cmd.fullName = typeApiName + '.' + developerName;

        // 🔧 Label у CMDT має граничну довжину ~40 символів (UI нав’язує це ж)
        String safeLabel = String.isBlank(label) ? developerName : label;
        if (safeLabel != null && safeLabel.length() > 40) {
            safeLabel = safeLabel.substring(0, 40);
        }
        cmd.label = safeLabel;

        cmd.protected_x = false;

        for (String f : fieldValues.keySet()) {
            Metadata.CustomMetadataValue v = new Metadata.CustomMetadataValue();
            v.field = f;
            v.value = fieldValues.get(f);
            cmd.values.add(v);
        }
        return cmd;
    }
    // Заглушка - генеруємо DeveloperName з Id
    // Пекредаємо сюди String.valueOf(r.Id)
    public static String devName(String raw) {
        return raw;
    } 
    // Новий генератор DeveloperName з Id
    public static String devNameFromId(Id idVal){
        return String.valueOf(idVal); // 18-символьний SFID валідний для DeveloperName
    }

    public static String devNameForSchFromIds(String odId, String wtId, String sch){
        String key = (odId == null ? '' : odId) + '|' + (wtId == null ? '' : wtId) + '|' + (sch == null ? '' : sch);
        String digest = EncodingUtil.convertToHex(Crypto.generateDigest('MD5', Blob.valueOf(key)));
        // 32 hex -> візьмемо перші 16, щоб гарантовано <= 40 з префіксом
        return 'SCH_' + digest.substring(0, 16);
    }

   
    
/*
    //=== Генератор DeveloperName (заміна пробілів, символів, обмеження 255)
    public static String devName(String raw) {
        String s = (raw == null ? 'N' : raw)
            .trim()
            .replaceAll('[^A-Za-z0-9_\\-]+', '_')
            .toUpperCase();
        if (String.isBlank(s)) s = 'N';
        if (s.length() > 255) s = s.substring(0, 255);
        return s;
    }
*/
    //=== Генератори для різних типів CMDT (OD, WT, SCH)
    public static String devNameForOd(Decimal odMm) {
        return devName('OD_' + (odMm == null ? 'N' : String.valueOf(odMm).replace('.', '_')));
    }   
    public static String devNameForWt(Decimal wtMm) {
        return devName('WT_' + (wtMm == null ? 'N' : String.valueOf(wtMm).replace('.', '_')));
    }
    public static String devNameForSch(String odDev, String wtDev, String sch) {
        return devName(odDev + '__' + wtDev + '__SCH_' + (String.isBlank(sch) ? 'N' : sch));
    }
}