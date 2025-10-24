public with sharing class ExperienceCloudShowToastEventController {
    @AuraEnabled(cacheable=true)
    public static List<Account> getCustomerComunityUserAccount() {

        List<User> u = [SELECT Name, AccountId FROM User WHERE Id = :UserInfo.getUserId()];
        System.debug('accId = ' + u[0].AccountId);
        Id accountId = u[0].AccountId;
        return [SELECT Name, DealingStatus__c, PastDueDebt__c, CurrencyIsoCode, BlockDate__c FROM Account WHERE id =: accountId];
    }
}