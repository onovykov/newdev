public class AccountContactRelationHandler {
    public static void assignBusinessDivisionAndSegment(List<AccountContactRelation> acrList) {
        Set<Id> accountIds = new Set<Id>();
        for (AccountContactRelation acr : acrList) {
            if (acr.AccountId != null &&
                    (String.isBlank(acr.BusinessDivision__c) || String.isBlank(acr.MarketSegment__c))) {
                accountIds.add(acr.AccountId);
            }
        }

        if (accountIds.isEmpty()) return;

        Map<Id, Account> accountMap = new Map<Id, Account>(
                [SELECT Id, MarketSegment__c FROM Account WHERE Id IN :accountIds]
        );

        for (AccountContactRelation acr : acrList) {
            if (!(String.isBlank(acr.BusinessDivision__c) && String.isBlank(acr.MarketSegment__c))) continue;

            Account acc = accountMap.get(acr.AccountId);
            if (acc == null) continue;

            if (acc.MarketSegment__c == '00006') {
                acr.BusinessDivision__c = 'Railway';
                acr.MarketSegment__c = '00006';
            } else {
                acr.BusinessDivision__c = 'Pipes';
                acr.MarketSegment__c = acc.MarketSegment__c;
            }
        }
    }
}