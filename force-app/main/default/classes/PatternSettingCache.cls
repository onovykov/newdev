public with sharing class PatternSettingCache {

    // =========================
    // Caches
    // =========================
    private static List<PatternSetting__c> rsmpBasePatterns;
    private static List<PatternSetting__c> rsmpTrashPatterns;

    // =========================
    // BASE patterns
    // =========================

    /**
     * BASE-патерни для RSMP / SteelGrade / Wheels
     */
    public static List<PatternSetting__c> getRSMPBasePatterns() {

        if (rsmpBasePatterns == null) {
            rsmpBasePatterns = [
                SELECT Id, Regex__c
                FROM PatternSetting__c
                WHERE IsActive__c = true
                  AND ObjectType__c = 'SteelGrade'
                  AND Domain__c = 'Wheels'
                  AND ERP_FacetGroup__c = 'RSMP'
                  AND Type__c = 'Base'
                ORDER BY CreatedDate ASC
            ];
        }

        return rsmpBasePatterns;
    }

    // =========================
    // TRASH patterns
    // =========================

    /**
     * TRASH-патерни (сміття типу C-mod-1, [MS], Class A тощо)
     */
    public static List<PatternSetting__c> getRSMPTrashPatterns() {

        if (rsmpTrashPatterns == null) {
            rsmpTrashPatterns = [
                SELECT Id, Regex__c
                FROM PatternSetting__c
                WHERE IsActive__c = true
                  AND ObjectType__c = 'SteelGrade'
                  AND Domain__c = 'Wheels'
                  AND ERP_FacetGroup__c = 'RSMP'
                  AND Type__c = 'Trash'
                ORDER BY CreatedDate ASC
            ];
        }

        return rsmpTrashPatterns;
    }

    // =========================
    // Cache control
    // =========================

    /**
     * Викликати, якщо патерни змінилися
     */
    public static void clear() {
        rsmpBasePatterns = null;
        rsmpTrashPatterns = null;
    }
}