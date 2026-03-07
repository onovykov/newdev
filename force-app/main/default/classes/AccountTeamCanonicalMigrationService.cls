public with sharing class AccountTeamCanonicalMigrationService {
	//--- canonical logic
    public class Config {
        public Boolean isDryRun = true;

        public String segmentationRole = 'Sales Manager';
        public String bosRole = 'BO Specialist';
    }

    private static Integer accessRank(String level) {
        if (level == 'Edit') return 2;
        if (level == 'Read') return 1;
        return 0;
    }

    public static AccountTeamCanonicalMigrationResult process(
        List<AccountSalesSegmentation__c> segScope,
        List<AccountBOS__c> bosScope,
        Config config
    ) {
        AccountTeamCanonicalMigrationResult result =
            new AccountTeamCanonicalMigrationResult();

        Set<Id> accountIds = new Set<Id>();
        Set<Id> userIds = new Set<Id>();

        // Collect IDs
        for (AccountSalesSegmentation__c s : segScope) {
            result.segmentationProcessed++;
            if (s.Account__c != null && s.Manager__c != null) {
                accountIds.add(s.Account__c);
                userIds.add(s.Manager__c);
            }
        }

        for (AccountBOS__c b : bosScope) {
            result.bosProcessed++;
            if (b.Account__c != null && b.User__c != null) {
                accountIds.add(b.Account__c);
                userIds.add(b.User__c);
            }
        }

        Map<Id, Account> accounts = new Map<Id, Account>([
            SELECT Id, OwnerId
            FROM Account
            WHERE Id IN :accountIds
        ]);

        Map<Id, User> users = new Map<Id, User>([
            SELECT Id, IsActive
            FROM User
            WHERE Id IN :userIds
        ]);

        Map<String, AccountTeamMember> existingMap = new Map<String, AccountTeamMember>();

        for (AccountTeamMember atm : [
            SELECT Id, AccountId, UserId,
                   AccountAccessLevel, OpportunityAccessLevel,
                   ContactAccessLevel, CaseAccessLevel
            FROM AccountTeamMember
            WHERE AccountId IN :accountIds
        ]) {
            String key = atm.AccountId + '-' + atm.UserId;
            existingMap.put(key, atm);
        }

        List<AccountTeamMember> inserts = new List<AccountTeamMember>();
        List<AccountTeamMember> updates = new List<AccountTeamMember>();

        // Helper
        processSegmentation(segScope, config, result,
            accounts, users, existingMap, inserts, updates);

        processBOS(bosScope, config, result,
            accounts, users, existingMap, inserts, updates);

        result.preparedInsert = inserts.size();
        result.preparedUpgrade = updates.size();

        if (config.isDryRun) {
            return result;
        }

        // INSERT
        if (!inserts.isEmpty()) {
            Database.SaveResult[] sr = Database.insert(inserts, false);
            for (Integer i = 0; i < sr.size(); i++) {
                if (sr[i].isSuccess()) {
                    result.inserted++;
                } else {
                    result.failed++;
                    result.errors.add(sr[i].getErrors()[0].getMessage());
                }
            }
        }

        // UPDATE (upgrade only)
        if (!updates.isEmpty()) {
            Database.SaveResult[] sr2 = Database.update(updates, false);
            for (Integer i = 0; i < sr2.size(); i++) {
                if (sr2[i].isSuccess()) {
                    result.upgraded++;
                } else {
                    result.failed++;
                    result.errors.add(sr2[i].getErrors()[0].getMessage());
                }
            }
        }

        return result;
    }
	
	//--- Segmentation logic (Edit)
    private static void processSegmentation(
        List<AccountSalesSegmentation__c> segScope,
        Config config,
        AccountTeamCanonicalMigrationResult result,
        Map<Id, Account> accounts,
        Map<Id, User> users,
        Map<String, AccountTeamMember> existingMap,
        List<AccountTeamMember> inserts,
        List<AccountTeamMember> updates
    ) {
        for (AccountSalesSegmentation__c s : segScope) {

            if (s.Account__c == null || s.Manager__c == null) continue;

            Account acc = accounts.get(s.Account__c);
            User usr = users.get(s.Manager__c);

            if (acc == null || usr == null) continue;

            if (!usr.IsActive) {
                result.skippedInactive++;
                continue;
            }

            if (s.Manager__c == acc.OwnerId) {
                result.skippedOwner++;
                continue;
            }

            String key = acc.Id + '-' + usr.Id;

            if (!existingMap.containsKey(key)) {
                AccountTeamMember atm = new AccountTeamMember(
                    AccountId = acc.Id,
                    UserId = usr.Id,
                    TeamMemberRole = config.segmentationRole,
                    AccountAccessLevel = 'Edit',
                    OpportunityAccessLevel = 'Edit',
                    ContactAccessLevel = 'Edit',
                    CaseAccessLevel = 'Edit'
                );
                inserts.add(atm);
            } else {
                AccountTeamMember existing = existingMap.get(key);

                if (accessRank(existing.AccountAccessLevel) < 2) {
                    existing.AccountAccessLevel = 'Edit';
                    existing.OpportunityAccessLevel = 'Edit';
                    existing.ContactAccessLevel = 'Edit';
                    existing.CaseAccessLevel = 'Edit';
                    updates.add(existing);
                }
            }
        }
    }
	
	//--- BOS logic (Read Only)	
    private static void processBOS(
        List<AccountBOS__c> bosScope,
        Config config,
        AccountTeamCanonicalMigrationResult result,
        Map<Id, Account> accounts,
        Map<Id, User> users,
        Map<String, AccountTeamMember> existingMap,
        List<AccountTeamMember> inserts,
        List<AccountTeamMember> updates
    ) {
        for (AccountBOS__c b : bosScope) {

            if (b.Account__c == null || b.User__c == null) continue;

            Account acc = accounts.get(b.Account__c);
            User usr = users.get(b.User__c);

            if (acc == null || usr == null) continue;

            if (!usr.IsActive) {
                result.skippedInactive++;
                continue;
            }

            String key = acc.Id + '-' + usr.Id;

            if (!existingMap.containsKey(key)) {
                AccountTeamMember atm = new AccountTeamMember(
                    AccountId = acc.Id,
                    UserId = usr.Id,
                    TeamMemberRole = config.bosRole,
                    AccountAccessLevel = 'Read',
                    OpportunityAccessLevel = 'Read',
                    ContactAccessLevel = 'Read',
                    CaseAccessLevel = 'None'
                );
                inserts.add(atm);
            } else {
                // якщо вже є Edit — нічого не робимо
                // downgrade ніколи не робимо
            }
        }
    }
}