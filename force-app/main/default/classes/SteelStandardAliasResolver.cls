public class SteelStandardAliasResolver {

    private static Map<Pattern, String> regexMap;
/*
    static {
        regexMap = new Map<Pattern, String>();

        for (SteelStandardAlias__mdt a : [
            SELECT CanonicalCode__c, Regex__c
            FROM SteelStandardAlias__mdt
            WHERE Regex__c != null
        ]) {
            regexMap.put(
                Pattern.compile('(?i)' + a.Regex__c),
                a.CanonicalCode__c
            );
        }
    }
*/
    static {
        regexMap = new Map<Pattern, String>();

        for (SteelStandardAlias__mdt a : [
            SELECT CanonicalCode__c, Regex__c
            FROM SteelStandardAlias__mdt
            WHERE Regex__c != null
        ]) {
            try {
                regexMap.put(
                    Pattern.compile('(?i)' + a.Regex__c),
                    a.CanonicalCode__c
                );
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR,
                    'SteelStandardAliasResolver: invalid regex in CMDT ' +
                    a.DeveloperName + ' = [' + a.Regex__c + '], err=' + e.getMessage()
                );
            }
        }
    }

    public static String resolve(String text) {
        if (String.isBlank(text)) return null;

        for (Pattern p : regexMap.keySet()) {
            if (p.matcher(text).find()) {
                return regexMap.get(p);
            }
        }
        return null;
    }
}