public with sharing class SettingsService {
    private static Notification_Settings__c cached;
    private static Notification_Settings__c cfg() {
        if (cached == null) {
            cached = Notification_Settings__c.getOrgDefaults();
            if (cached == null) cached = new Notification_Settings__c(UseReposOnly__c=false, AllowSoqlFallback__c=true);
        }
        return cached;
    }
    public static Boolean useReposOnly(){ return cfg().UseReposOnly__c == true; }
    public static Boolean allowSoqlFallback(){ return !useReposOnly() && (cfg().AllowSoqlFallback__c == true); }
    public static String slackPath(){ return cfg().SlackPath__c; }
    public static String webhookPath(){ return cfg().WebhookPath__c; }
}