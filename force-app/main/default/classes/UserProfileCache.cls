public with sharing class UserProfileCache {
    private static Map<String, Set<Id>> cache = new Map<String, Set<Id>>();
    public static Set<Id> userIdsByProfile(String profileName) {
        if (String.isBlank(profileName)) return new Set<Id>();
        if (!cache.containsKey(profileName)) {
            Set<Id> ids = new Set<Id>();
            for (User u : [
                SELECT Id, Email, IsActive
                FROM User
                WHERE IsActive = true
                  AND Profile.Name = :profileName
                  AND Email != null
            ]) ids.add(u.Id);
            cache.put(profileName, ids);
        }
        return cache.get(profileName);
    }
}