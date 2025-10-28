public with sharing class LangSysCmdtLoader {
    // Запуск: LangSysCmdtLoader.upsertFromUserLocales();
    public static void upsertFromUserLocales() {
        // 1) Picklist локалей користувача
        Schema.DescribeFieldResult fieldResult = User.LanguageLocaleKey.getDescribe();
        List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();

        // 2) Контейнер для деплою CMDT
        Metadata.DeployContainer container = new Metadata.DeployContainer();

        // 3) Формуємо CustomMetadata записи для upsert (по fullName)
        for (Schema.PicklistEntry entry : picklistValues) {
            String sLngCodeFull = String.valueOf(entry.getValue());   // напр. "uk_UA"
            String sLngCode     = safe2(sLngCodeFull);                 // "uk"
            String sLngNameFull = String.valueOf(entry.getLabel());    // "Ukrainian (Ukraine)"
            List<String> parts  = sLngNameFull.split('\\s+');
            String sLngName     = (parts.isEmpty() ? sLngNameFull : parts[0]);

            // DeveloperName — стабільний ключ із коду локалі
            String devName = sanitizeDevName(sLngCodeFull);

            Metadata.CustomMetadata cmdt = new Metadata.CustomMetadata();
            // fullName = ObjectAPIName.RecordDeveloperName
            cmdt.fullName = 'LangSys__mdt.' + devName;
            cmdt.label    = sLngCodeFull; // MasterLabel

            List<Metadata.CustomMetadataValue> values = new List<Metadata.CustomMetadataValue>();
            values.add(newValue('LngCode__c',     sLngCode));
            values.add(newValue('LngName__c',     sLngName));
            values.add(newValue('LngFullName__c', sLngNameFull));
            cmdt.values = values;

            container.addMetadata(cmdt);
        }

        // 4) Деплой (async) + простий колбек без messages
        Id asyncJobId = Metadata.Operations.enqueueDeployment(container, new DeployCb());
        System.debug(LoggingLevel.INFO, 'LangSys__mdt deploy enqueued. Async job id = ' + asyncJobId);
    }

    // === HELPERS ===
    private static String sanitizeDevName(String raw) {
        String v = String.isBlank(raw) ? 'XX' : raw;
        v = v.replaceAll('[^A-Za-z0-9]+', '_');  // тільки [A-Za-z0-9_]
        v = v.replaceAll('^_+|_+$', '');         // прибрати підкреслення з країв
        if (String.isBlank(v)) v = 'XX';
        if (v.length() > 40) v = v.substring(0, 40); // ліміт DeveloperName
        return v;
    }
    private static String safe2(String raw) {
        if (String.isBlank(raw)) return 'xx';
        return (raw.length() >= 2) ? raw.substring(0, 2) : (raw + 'x').substring(0, 2);
    }
    private static Metadata.CustomMetadataValue newValue(String fieldApiName, Object val) {
        Metadata.CustomMetadataValue v = new Metadata.CustomMetadataValue();
        v.field = fieldApiName;
        v.value = val;
        return v;
    }

    // === DEPLOY CALLBACK (без result.messages) ===
    public class DeployCb implements Metadata.DeployCallback {
        public void handleResult(Metadata.DeployResult result, Metadata.DeployCallbackContext ctx) {
            if (result == null) {
                System.debug(LoggingLevel.ERROR, 'CMDT deploy: no result');
                return;
            }
            System.debug(LoggingLevel.INFO, 'CMDT deploy status: ' + String.valueOf(result.status));
            System.debug(
                LoggingLevel.INFO,
                'Components deployed: ' + result.numberComponentsDeployed +
                '/' + result.numberComponentsTotal +
                ', errors=' + result.numberComponentErrors
            );
            // Деталі дивись у Setup → Deployment Status або Debug Logs
        }
    }
}