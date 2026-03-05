public with sharing class AccountLookupImpl implements AccountLookup {

    private final ExternalIdCache iteCache;
    private final ExternalIdCache erpCache;

    public AccountLookupImpl() {
        erpCache =
            ExternalIdCache.forObject(
                'Account',
                'ID_ERP__c',
                'local_AccountCache'
            );
    }

    public Id findByErp(String erpId) {
        if (String.isBlank(erpId)) {
            return null;
        }
        return erpCache.getOne(erpId);
    }

}