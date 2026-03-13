public with sharing class AccountTeamUserSelector {

    @AuraEnabled(cacheable=true)
    public static List<User> getUsersForRole(
        Id accountId,
        String roleType
    ) {

        if (accountId == null) {
            return new List<User>();
        }

        Account acc = [
            SELECT OwnerId
            FROM Account
            WHERE Id = :accountId
            LIMIT 1
        ];

        Set<Id> userIds = new Set<Id>();

        // Manager case
        if (roleType == 'MANAGER') {
            userIds.add(acc.OwnerId);
        }

        for (AccountTeamMember atm : [
            SELECT UserId, TeamMemberRole
            FROM AccountTeamMember
            WHERE AccountId = :accountId
        ]) {

            if (roleType == 'BOS'
                && atm.TeamMemberRole == 'BO Specialist') {

                userIds.add(atm.UserId);
            }

            if (roleType == 'MANAGER'
                && atm.TeamMemberRole != 'BO Specialist') {

                userIds.add(atm.UserId);
            }
        }

        return [
            SELECT Id, Name
            FROM User
            WHERE Id IN :userIds
              AND IsActive = true
            ORDER BY Name
        ];
    }
}