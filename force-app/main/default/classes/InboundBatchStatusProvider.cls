public with sharing class InboundBatchStatusProvider {

    private static Boolean loaded = false;

    private static Map<String, Inbound_Batch_Status__mdt> byDevName;
    private static Map<String, Inbound_Batch_Status__mdt> byRole;

    private static void load() {
        if (loaded) return;

        byDevName = new Map<String, Inbound_Batch_Status__mdt>();
        byRole    = new Map<String, Inbound_Batch_Status__mdt>();

        for (Inbound_Batch_Status__mdt s : [
            SELECT DeveloperName,
                   Role__c,
                   IsTerminal__c,
                   IsTimeoutEligible__c
            FROM Inbound_Batch_Status__mdt
        ]) {
            byDevName.put(s.DeveloperName, s);

            if (String.isNotBlank(s.Role__c)) {
                byRole.put(s.Role__c, s);
            }
        }

        loaded = true;
    }

    // =========================================================
    // Access by ROLE
    // =========================================================

    public static String keyByRole(String role) {
        load();

        if (!byRole.containsKey(role)) {
            throw new IntegrationDomainException(
                'InboundBatch status ACCEPTED not configured'
            );            
            /*throw new IllegalStateException(
                'Inbound batch status role not found: ' + role
            );*/
        }

        return byRole.get(role).DeveloperName;
    }

    public static Boolean isTerminal(String statusKey) {
        load();
        return byDevName.containsKey(statusKey)
            && byDevName.get(statusKey).IsTerminal__c;
    }

    public static Boolean canTimeout(String statusKey) {
        load();
        return byDevName.containsKey(statusKey)
            && byDevName.get(statusKey).IsTimeoutEligible__c;
    }

    // =========================================================
    // Common helpers
    // =========================================================

    public static Set<String> liveStatusKeys() {
        load();

        Set<String> res = new Set<String>();
        for (Inbound_Batch_Status__mdt s : byDevName.values()) {
            if (!s.IsTerminal__c) {
                res.add(s.DeveloperName);
            }
        }
        return res;
    }

    public static String accepted()   { return keyByRole('ACCEPTED'); }
    public static String processing() { return keyByRole('PROCESSING'); }
    public static String completed()  { return keyByRole('COMPLETED'); }
    public static String failed()     { return keyByRole('FAILED'); }
    public static String timeout()    { return keyByRole('TIMEOUT'); }
    public static String duplicate()  { return keyByRole('DUPLICATE'); }
}