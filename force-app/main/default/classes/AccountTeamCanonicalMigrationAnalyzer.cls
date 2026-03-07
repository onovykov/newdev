public with sharing class AccountTeamCanonicalMigrationAnalyzer {

    public static AccountTeamCanonicalMigrationResult analyzeAll() {

        List<AccountSalesSegmentation__c> seg =
            [SELECT Id, Account__c, Manager__c
             FROM AccountSalesSegmentation__c
             WHERE Account__c != null
               AND Manager__c != null
               AND Manager__r.IsActive = true];

        Set<Id> accountIds = new Set<Id>();
        for (AccountSalesSegmentation__c s : seg) {
            accountIds.add(s.Account__c);
        }

        List<AccountBOS__c> bos =
            [SELECT Id, Account__c, User__c
             FROM AccountBOS__c
             WHERE Account__c IN :accountIds];

        AccountTeamCanonicalMigrationService.Config cfg =
            new AccountTeamCanonicalMigrationService.Config();

        cfg.isDryRun = true;

        return AccountTeamCanonicalMigrationService.process(seg, bos, cfg);
    }
}