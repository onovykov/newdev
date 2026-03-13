public with sharing class EmailTemplateRepo {
    private static Map<String, Id> byApiName = new Map<String, Id>();
    public static Id getIdByApiName(String apiName){
        if (String.isBlank(apiName)) return null;
        if (!byApiName.containsKey(apiName)) {
            List<EmailTemplate> rows = [SELECT Id, DeveloperName FROM EmailTemplate WHERE DeveloperName = :apiName LIMIT 1];
            byApiName.put(apiName, rows.isEmpty()? null : rows[0].Id);
        }
        return byApiName.get(apiName);
    }
}