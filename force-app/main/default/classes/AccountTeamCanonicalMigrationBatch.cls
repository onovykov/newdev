//--- Migration Batch v.2
public without sharing class AccountTeamCanonicalMigrationBatch
    implements Database.Batchable<SObject>, Database.Stateful {

    private Boolean isDryRun;
    private AccountTeamCanonicalMigrationResult total =
        new AccountTeamCanonicalMigrationResult();

    public AccountTeamCanonicalMigrationBatch(Boolean isDryRun) {
        this.isDryRun = isDryRun == null ? true : isDryRun;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT 
                Id, Account__c, Manager__c, Manager__r.IsActive 
            FROM AccountSalesSegmentation__c
        ]);
    }

    public void execute(Database.BatchableContext bc,
                        List<AccountSalesSegmentation__c> scope) {

        Set<Id> accountIds = new Set<Id>();
        for (AccountSalesSegmentation__c s : scope) {
            if (s.Account__c != null) accountIds.add(s.Account__c);
        }

        List<AccountBOS__c> bos = [
            SELECT Id, Account__c, User__c
            FROM AccountBOS__c
            WHERE Account__c IN :accountIds
        ];

        AccountTeamCanonicalMigrationService.Config cfg =
            new AccountTeamCanonicalMigrationService.Config();
        cfg.isDryRun = isDryRun;

        AccountTeamCanonicalMigrationResult res =
            AccountTeamCanonicalMigrationService.process(scope, bos, cfg);

        total.mergeATCM(res);

        System.debug(LoggingLevel.INFO,
            'Scope result: ' + res.toPrettyString());
    }

    public void finish(Database.BatchableContext bc) {
        System.debug(LoggingLevel.INFO,
            'FINAL RESULT: DryRun=' + isDryRun +
            ' ' + total.toPrettyString());
    }
}
/*
	Запуск
	Dry-run // параметр isDryRun=true
	Database.executeBatch(
		new AccountTeamCanonicalMigrationBatch(true),
		200
	);
	Реальний запуск // параметр isDryRun=false
	Database.executeBatch(
		new AccountTeamCanonicalMigrationBatch(false),
		200
	);
*/