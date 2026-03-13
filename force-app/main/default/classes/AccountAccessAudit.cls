public with sharing class AccountAccessAudit {

    public class Stats {
        public Integer manualTotal = 0;
        public Integer teamTotal = 0;
        public Integer coveredExact = 0;
        public Integer missingInTeam = 0;
        public Integer accessMismatch = 0;
        public Integer orphanCandidates = 0;
        public Integer overProvisioning = 0;
    }

    public static void run(Boolean debugDetails) {

        System.debug('=== ACCESS AUDIT V3 START ===');

        List<AccountShare> manualShares = [
            SELECT Id,
                   AccountId,
                   UserOrGroupId,
                   AccountAccessLevel,
                   OpportunityAccessLevel,
                   ContactAccessLevel
            FROM AccountShare
            WHERE RowCause = 'Manual'
        ];

        List<AccountTeamMember> teamMembers = [
            SELECT Id,
                   AccountId,
                   UserId,
                   AccountAccessLevel,
                   OpportunityAccessLevel,
                   ContactAccessLevel
            FROM AccountTeamMember
        ];

        Stats s = new Stats();
        s.manualTotal = manualShares.size();
        s.teamTotal = teamMembers.size();

        Map<String, AccountShare> manualMap = new Map<String, AccountShare>();
        for (AccountShare sh : manualShares) {
            manualMap.put(sh.AccountId + '_' + sh.UserOrGroupId, sh);
        }

        Map<String, AccountTeamMember> teamMap = new Map<String, AccountTeamMember>();
        for (AccountTeamMember tm : teamMembers) {
            teamMap.put(tm.AccountId + '_' + tm.UserId, tm);
        }

        // ============================
        // 1️. Manual -> Team coverage
        // ============================
        for (String key : manualMap.keySet()) {

            AccountShare sh = manualMap.get(key);

            if (!teamMap.containsKey(key)) {
                s.missingInTeam++;
                if (debugDetails)
                    System.debug('MISSING_IN_TEAM,' + key);
                continue;
            }

            AccountTeamMember tm = teamMap.get(key);

            Boolean exactMatch =
                sh.AccountAccessLevel == tm.AccountAccessLevel &&
                sh.OpportunityAccessLevel == tm.OpportunityAccessLevel &&
                sh.ContactAccessLevel == tm.ContactAccessLevel;

            if (exactMatch) {
                s.coveredExact++;
                s.orphanCandidates++;
                if (debugDetails)
                    System.debug('ORPHAN_CANDIDATE,' + sh.Id + ',' + key);
            } else {
                s.accessMismatch++;
                if (debugDetails) {
                    System.debug(
                        'ACCESS_MISMATCH,' + key +
                        ',SHARE:' + sh.AccountAccessLevel + '/' +
                        sh.OpportunityAccessLevel + '/' +
                        sh.ContactAccessLevel +
                        ',TEAM:' + tm.AccountAccessLevel + '/' +
                        tm.OpportunityAccessLevel + '/' +
                        tm.ContactAccessLevel
                    );
                }
            }
        }

        // ============================
        // 2️. Over-provisioning check
        // ============================
        for (String key : teamMap.keySet()) {
            if (!manualMap.containsKey(key)) {
                s.overProvisioning++;
                if (debugDetails)
                    System.debug('OVER_PROVISIONING,' + key);
            }
        }

        Decimal coveragePct = 0;
        if (s.manualTotal > 0) {
            coveragePct = (Decimal.valueOf(s.coveredExact) / s.manualTotal) * 100;
        }

        System.debug('=== SUMMARY ===');
        System.debug('Manual Shares Total: ' + s.manualTotal);
        System.debug('Team Members Total : ' + s.teamTotal);
        System.debug('Exact Coverage     : ' + s.coveredExact);
        System.debug('Coverage %         : ' + coveragePct.setScale(2));
        System.debug('Missing In Team    : ' + s.missingInTeam);
        System.debug('Access Mismatch    : ' + s.accessMismatch);
        System.debug('Orphan Candidates  : ' + s.orphanCandidates);
        System.debug('Over Provisioning  : ' + s.overProvisioning);
        System.debug('=== END ===');
    }
}