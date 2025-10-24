public with sharing class SiteIPCamsController {
    @AuraEnabled(cacheable=true)
    public static List<Site_IPCams_Setting__mdt> getCameraSettings() {
        return [SELECT MasterLabel, Camera_Id__c, IP_Camera_URL__c, Preview_IMG__c,Description__c FROM Site_IPCams_Setting__mdt];
    }
    @AuraEnabled(cacheable=true)
    public static String getCameraCredentials() {
        IPCams_Credentials__c creds = IPCams_Credentials__c.getOrgDefaults();
        if (creds != null) {
            return JSON.serialize(new Map<String, String>{
                'username' => creds.Login__c,
                'password' => creds.Password__c
            });
        }
        return null;
    }
}