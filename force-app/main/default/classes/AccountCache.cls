public class AccountCache {

    private static final ExternalIdCache CACHE =
        ExternalIdCache.forObject(
            'Account',
            'ID_ERP__c',
            'local_AccountCache'
        );

    public static Id getByExternalId(String extId) {
        return CACHE.getOne(extId);
    }

    public static Map<String, Id> getByExternalIds(Set<String> extIds) {
        return CACHE.getMany(extIds, true);
    }
}