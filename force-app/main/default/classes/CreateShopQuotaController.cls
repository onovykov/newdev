public with sharing class CreateShopQuotaController {
	 @AuraEnabled
    public static List<QuotaType__c> searchShopQuota( String searchTerm ) {
        List<QuotaType__c> accounts = new List<QuotaType__c>();
        if ( String.isNotBlank( searchTerm ) 	&& searchTerm.length() > 1 ) {
            List<List<SObject>> searchResults = [
                FIND :searchTerm
                RETURNING QuotaType__c(
                    Id, Name ORDER BY Name
                    LIMIT 10
                )
            ];
            system.debug(searchTerm);
            system.debug(searchResults);
            accounts = searchResults[0];
        }
        return accounts;
    }
}