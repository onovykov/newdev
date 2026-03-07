public class ExceptionMessageProvider {

    private static Map<String, ExceptionMessages__mdt> byDevName;
    private static Map<String, ExceptionMessages__mdt> byHandlerAndCode;

    private static void ensureLoaded() {
        if (byDevName != null) {
            return;
        }

        byDevName = new Map<String, ExceptionMessages__mdt>();
        byHandlerAndCode = new Map<String, ExceptionMessages__mdt>();

        for (ExceptionMessages__mdt m : [
            SELECT DeveloperName, Handler__c, MessageText__c
            FROM ExceptionMessages__mdt
        ]) {

            // lookup by DeveloperName
            byDevName.put(m.DeveloperName, m);

            // composite key: Handler + DeveloperName
            if (!String.isBlank(m.Handler__c)
                && !String.isBlank(m.DeveloperName)) {

                String compositeKey =
                    m.Handler__c + '|' + m.DeveloperName;

                byHandlerAndCode.put(compositeKey, m);
            }
        }
    }

    // ---------- BASIC ----------
    @TestVisible
    public static String getByDeveloperName(String devName) {
        ensureLoaded();

        if (String.isBlank(devName)) {
            return null;
        }

        if (!byDevName.containsKey(devName)) {
            return devName; // safe fallback
        }

        return byDevName.get(devName).MessageText__c;
    }

    // ---------- DOMAIN + CODE ----------
    public static String getByHandlerAndCode(
        String handler,
        String code
    ) {
        ensureLoaded();

        if (String.isBlank(handler)
            || String.isBlank(code)) {

            return handler + ':' + code;
        }

        String key = handler + '|' + code;

        if (!byHandlerAndCode.containsKey(key)) {
            return handler + ':' + code;
        }

        return byHandlerAndCode.get(key).MessageText__c;
    }

    // ---------- BUILDERS ----------
    private static String build(
        String base,
        String value,
        Boolean withValue
    ) {
        if (String.isBlank(base)) {
            return null;
        }

        if (!withValue || String.isBlank(value)) {
            return base;
        }

        return base + '=' + value;
    }

    public static String buildByDeveloperName(
        String devName,
        String value,
        Boolean withValue
    ) {
        return build(
            getByDeveloperName(devName),
            value,
            withValue
        );
    }

    public static String buildByHandler(
        String handler,
        String code,
        String value,
        Boolean withValue
    ) {
        return build(
            getByHandlerAndCode(handler, code),
            value,
            withValue
        );
    }
}