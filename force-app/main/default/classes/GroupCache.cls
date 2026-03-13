public with sharing class GroupCache {
    private static Map<String, Id> byDev = new Map<String, Id>();
    public static Id byDeveloperName(String devName) {
        if (String.isBlank(devName)) return null;
        if (!byDev.containsKey(devName)) {
            List<Group> rows = [SELECT Id FROM Group WHERE Type='Regular' AND DeveloperName = :devName LIMIT 1];
            byDev.put(devName, rows.isEmpty() ? null : rows[0].Id);
        }
        return byDev.get(devName);
    }
}