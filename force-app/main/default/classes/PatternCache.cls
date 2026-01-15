public class PatternCache {

    private static List<PatternSetting__c> rsmpSteel;

    public static List<PatternSetting__c> getRSMPSteelPatterns() {
        if (rsmpSteel == null) {
            rsmpSteel = [
                SELECT Regex__c, Type__c
                FROM PatternSetting__c
                WHERE ObjectType__c = 'SteelGrade'
                  AND Domain__c = 'Wheels'
                  AND ERP_FacetGroup__c = 'RSMP'
            ];
        }
        return rsmpSteel;
    }
}