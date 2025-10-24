public class AccountTriggerHandler extends TriggerHandler implements ITrigger {
    public AccountTriggerHandler(Map<Id, SObject> oldMap, Map<Id, SObject> newMap, List<SObject> oldList, List<SObject> newList) {
        super(oldMap, newMap, oldList, newList);
    }

    public static Map<Id, User> IdToOwnerMap;
    private static Boolean isAlreadyRunQueue = false;

    // ---------- Lifecycle hooks required by ITrigger ----------
    public void bulkBefore() {
        if (Trigger.isInsert || Trigger.isUpdate) {
            IdToOwnerMap = new Map<Id, User>(UserRepository.getUsersBisDev());
        }
    }
    
    public void bulkAfter() { /* no-op */ }

    public void beforeInsert(SObject so) { /* no-op */ }
    public void beforeInsert(List<SObject> newRecords) {
        for (SObject rec : newRecords) {
            Account newAcc = (Account) rec;

            String s = StringNormalize.getClearName(
                newAcc.Name,
                Consts.ToUpperCase.YES,
                Consts.QuestionMarkRule.REMOVE_SIGN,
                Consts.ClearCountryName.YES
            );
            newAcc.NormalizedName__c = s;
            newAcc.FullName__c = StringUtilsEx.sanitizeQuotes(newAcc.Name).normalizeSpace().toUpperCase();
            //newAcc.Name = AccountRepository.getAccChangedName(newAcc.Name);

            MetaphoneUtils.MetaphoneResult mph = MetaphoneUtils.getMetaphoneFull(s);
            String phonetic     = PhoneticTranscoder.toPhoneticCode(s);
            String soundexAll   = String.join(StringUtilsEx.getSoundexEx(s), ' ');
            String soundexFirst = StringUtilsEx.getFirstWord(soundexAll);
            String nysiisAll    = StringUtilsEx.getNYSIIS(s);
            String nysiisFirst  = StringUtilsEx.getFirstWord(nysiisAll);

            newAcc.PhoneticCode__c         = phonetic.replace('&',' ');
            newAcc.MetaphonePrimary__c     = mph.primary.replace('&',' ');
            newAcc.MetaphoneAlternate__c   = mph.alternate.replace('&',' ');
            newAcc.NYSIIS__c               = nysiisAll.replace('&',' ');
            newAcc.NYSIISFirstCode__c      = nysiisFirst.replace('&',' ');
            newAcc.SoundexAllWords__c      = soundexAll.replace('&',' ');
            newAcc.SoundexFirstWord__c     = soundexFirst.replace('&',' ');
            newAcc.SoundexFirst3Letters__c = soundexFirst.left(3).replace('&',' ');
        }
    }

    public void beforeUpdate(SObject oldSo, SObject so) { /* no-op */ }
    public void beforeUpdate(List<SObject> oldRecords, List<SObject> newRecords) {
        for (Integer i = 0; i < newRecords.size(); i++) {
            Account newAcc = (Account) newRecords[i];
            Account oldAcc = (Account) oldRecords[i];

            Boolean nameChanged =
                (oldAcc == null && !String.isBlank(newAcc.Name)) ||
                (oldAcc != null && newAcc.Name != oldAcc.Name);

            if (nameChanged) {
                String s = StringNormalize.getClearName(
                    newAcc.Name,
                    Consts.ToUpperCase.YES,
                    Consts.QuestionMarkRule.REMOVE_SIGN,
                    Consts.ClearCountryName.YES
                );
                newAcc.NormalizedName__c = s;

                if (String.isBlank(newAcc.FullName__c)) {
                    newAcc.FullName__c = StringUtilsEx.sanitizeQuotes(newAcc.Name).normalizeSpace().toUpperCase();
                }

                //newAcc.Name = AccountRepository.getAccChangedName(newAcc.Name);

                MetaphoneUtils.MetaphoneResult mph = MetaphoneUtils.getMetaphoneFull(s);
                String phonetic     = PhoneticTranscoder.toPhoneticCode(s);
                String soundexAll   = String.join(StringUtilsEx.getSoundexEx(s), ' ');
                String soundexFirst = StringUtilsEx.getFirstWord(soundexAll);
                String nysiisAll    = StringUtilsEx.getNYSIIS(s);
                String nysiisFirst  = StringUtilsEx.getFirstWord(nysiisAll);

                newAcc.PhoneticCode__c         = phonetic.replace('&',' ');
                newAcc.MetaphonePrimary__c     = mph.primary.replace('&',' ');
                newAcc.MetaphoneAlternate__c   = mph.alternate.replace('&',' ');
                newAcc.NYSIIS__c               = nysiisAll.replace('&',' ');
                newAcc.NYSIISFirstCode__c      = nysiisFirst.replace('&',' ');
                newAcc.SoundexAllWords__c      = soundexAll.replace('&',' ');
                newAcc.SoundexFirstWord__c     = soundexFirst.replace('&',' ');
                newAcc.SoundexFirst3Letters__c = soundexFirst.left(3).replace('&',' ');
            }
        }
    }

    public void beforeDelete(SObject so) { /* no-op */ }
    public void beforeDelete(List<SObject> records) { /* no-op */ }

    public void afterInsert(SObject so) { /* no-op */ }
    public void afterInsert(List<SObject> newRecords) {
        List<Account> accs = new List<Account>();
        for (SObject rec : newRecords) accs.add((Account) rec);
        if (!accs.isEmpty()) {
            createAccountBusinessDivisions(accs);
            // enqueueNormalizationIfNeeded(accs, null);
        }
    }

    public void afterUpdate(SObject oldSo, SObject so) { /* no-op */ }
    public void afterUpdate(List<SObject> newRecords, Map<Id, SObject> oldMap) {
        List<Account> accs = new List<Account>();
        Map<Id, Account> oldAccMap = new Map<Id, Account>();
        for (SObject rec : newRecords) accs.add((Account) rec);
        for (Id k : oldMap.keySet()) oldAccMap.put(k, (Account) oldMap.get(k));

        List<Account> ownerChanged = new List<Account>();
        for (Account acc : accs) {
            Account oldAcc = oldAccMap.get(acc.Id);
            if (oldAcc != null && acc.OwnerId != oldAcc.OwnerId) {
                ownerChanged.add(acc);
            }
        }
        if (!ownerChanged.isEmpty()) {
            checkAbdForUpdatedAccounts(ownerChanged);
            shareAccounts(ownerChanged);
        }
        // enqueueNormalizationIfNeeded(accs, oldAccMap);
    }

    public void afterDelete(SObject so) { /* no-op */ }
    public void afterDelete(List<SObject> records) { /* no-op */ }

    public void afterUndelete(SObject so) { /* no-op */ }
    public void afterUndelete(List<SObject> records) { /* no-op */ }

    // NEW: required by ITrigger
    public void postProcessing() {
        // no-op (залишено гачок для можливих відкладених дій)
        // Напр., можна один раз запускати dispatcher, використовуючи isAlreadyRunQueue.
    }

    // ---------- Helpers ----------
    private void createAccountBusinessDivisions(List<Account> newRecords) {
        List<AccountBusinessDivisions__c> toInsert = new List<AccountBusinessDivisions__c>();
        for (Account acc : newRecords) {
            User owner = IdToOwnerMap != null ? IdToOwnerMap.get(acc.OwnerId) : null;

            AccountBusinessDivisions__c abd = new AccountBusinessDivisions__c();
            abd.Account__c = acc.Id;

            if (owner != null && !String.isBlank(owner.BusinesDivision__c)) {
                abd.BusinessDivision__c = owner.BusinesDivision__c;
                abd.OwnerId = owner.Id;
                abd.Name = owner.BusinesDivision__c;
            } else {
                abd.BusinessDivision__c = 'IT';
                abd.OwnerId = getUserIdByUsername('sf-ite@interpipe.biz');
                abd.Name = 'Default (IT)';
            }
            toInsert.add(abd);
        }
        if (!toInsert.isEmpty()) insert toInsert;
    }

    private void checkAbdForUpdatedAccounts(List<Account> accounts) {
        Set<Id> accIds   = new Set<Id>();
        Set<Id> ownerIds = new Set<Id>();
        for (Account a : accounts) { accIds.add(a.Id); ownerIds.add(a.OwnerId); }

        Map<String, AccountBusinessDivisions__c> abdMap = getAbdMap(accIds);

        List<AccountBusinessDivisions__c> abdMissing = new List<AccountBusinessDivisions__c>();
        for (Account a : accounts) {
            User owner = IdToOwnerMap != null ? IdToOwnerMap.get(a.OwnerId) : null;
            String key = a.Id + ':' + (owner != null ? owner.BusinesDivision__c : null);

            if (owner != null && String.isNotBlank(owner.BusinesDivision__c)
                && !abdMap.containsKey(key)) {

                abdMissing.add(new AccountBusinessDivisions__c(
                    Account__c = a.Id,
                    BusinessDivision__c = owner.BusinesDivision__c,
                    OwnerId = a.OwnerId,
                    Name = owner.BusinesDivision__c
                ));
            }
        }
        if (!abdMissing.isEmpty()) insert abdMissing;

        checkAssForUpdatedAccounts(accIds, ownerIds);
    }

    private static void checkAssForUpdatedAccounts(Set<Id> accountIdSet, Set<Id> ownerIdSet) {
        Map<String, AccountSalesSegmentation__c> assMap = getAssMap(accountIdSet, ownerIdSet);

        List<AccountBusinessDivisions__c> needAss = [
            SELECT Id, Account__c, Account__r.OwnerId, BusinessDivision__c
            FROM AccountBusinessDivisions__c
            WHERE Account__c IN :accountIdSet
        ];

        List<AccountBusinessDivisions__c> toCreate = new List<AccountBusinessDivisions__c>();
        for (AccountBusinessDivisions__c abd : needAss) {
            String key = abd.Account__c + ':' + abd.Account__r.OwnerId;
            if (!assMap.containsKey(key)) {
                toCreate.add(abd);
            }
        }
        if (!toCreate.isEmpty()) {
            AccountBisDevTrigger.createAccountSalesSegmentation(toCreate);
        }
    }

    private static void shareAccounts(List<Account> accounts) {
        if (accounts == null || accounts.isEmpty()) return;

        Organization org = [
                SELECT DefaultAccountAccess, DefaultContactAccess, DefaultOpportunityAccess, DefaultCaseAccess
                FROM Organization LIMIT 1
        ];

        // Нормалізуємо значення OWD до уніфікованих прапорів
        String accOWD = String.valueOf(org.DefaultAccountAccess);
        Boolean accIsPRW  = (accOWD == 'PublicReadWrite' || accOWD == 'Edit');
        Boolean accIsPRO  = (accOWD == 'PublicReadOnly'  || accOWD == 'Read');
        Boolean accIsPriv = (accOWD == 'Private');

        String oppOWD = String.valueOf(org.DefaultOpportunityAccess);
        Boolean oppIsPriv = (oppOWD == 'Private');

        String caseOWD = String.valueOf(org.DefaultCaseAccess);
        Boolean caseIsPriv = (caseOWD == 'Private');

        Schema.DescribeSObjectResult d = AccountShare.SObjectType.getDescribe();
        Map<String, Schema.SObjectField> f = d.fields.getMap();
        Boolean canSetOpp  = f.get('OpportunityAccessLevel').getDescribe().isCreateable();
        Boolean canSetCase = f.get('CaseAccessLevel').getDescribe().isCreateable();

        Set<Id> accIds = new Set<Id>();
        for (Account a : accounts) accIds.add(a.Id);

        Set<String> existing = new Set<String>();
        for (AccountShare sh : [
                SELECT AccountId, UserOrGroupId
                FROM AccountShare
                WHERE AccountId IN :accIds
        ]) {
            existing.add(sh.AccountId + ':' + String.valueOf(sh.UserOrGroupId));
        }

        List<AccountSharingCustom__c> rules = [
                SELECT Id, Account__c, UserOrGroupId__c,
                        User__r.IsActive,
                        AccountAccessLevel__c, OpportunityAccessLevel__c
                FROM AccountSharingCustom__c
                WHERE Account__c IN :accIds
        ];

        List<AccountShare> toInsert = new List<AccountShare>();

        for (AccountSharingCustom__c r : rules) {
            String key = r.Account__c + ':' + String.valueOf(r.UserOrGroupId__c);
            if (existing.contains(key)) continue;
            if (r.User__r != null && !r.User__r.IsActive) continue; // ігноруємо неактивних юзерів; групи проходять

            String accLevel = String.isBlank(r.AccountAccessLevel__c) ? 'Read' : r.AccountAccessLevel__c;
            if (accIsPRW)        accLevel = 'Edit';     // мінімум при PRW
            else if (accIsPRO)   accLevel = (accLevel == 'Edit' ? 'Edit' : 'Read');
            else if (accIsPriv)  accLevel = (accLevel == 'Edit' ? 'Edit' : 'Read'); // обидва ок
            if (accLevel != 'Edit' && accLevel != 'Read') accLevel = 'Edit';        // захист від сміття

            String oppLevel = String.isBlank(r.OpportunityAccessLevel__c) ? 'None' : r.OpportunityAccessLevel__c;
            if (!oppIsPriv && oppLevel == 'None') oppLevel = 'Read';
            if (oppLevel != 'None' && oppLevel != 'Read' && oppLevel != 'Edit') oppLevel = 'Read';

            AccountShare sh = new AccountShare();
            sh.AccountId          = r.Account__c;
            sh.UserOrGroupId      = r.UserOrGroupId__c;
            sh.AccountAccessLevel = accLevel;
            sh.RowCause           = 'Manual';

            if (canSetOpp) {
                sh.OpportunityAccessLevel = oppLevel;
            }
            if (canSetCase) {
                sh.CaseAccessLevel = caseIsPriv ? 'None' : 'Read';
            }

            toInsert.add(sh);
        }

        // 5) DML
        if (!toInsert.isEmpty()) {
            insert toInsert;
        }
    }

    private static Map<String, AccountBusinessDivisions__c> getAbdMap(Set<Id> accountIds) {
        Map<String, AccountBusinessDivisions__c> res = new Map<String, AccountBusinessDivisions__c>();
        for (AccountBusinessDivisions__c abd : [
            SELECT Account__c, BusinessDivision__c, Account__r.OwnerId
            FROM AccountBusinessDivisions__c
            WHERE Account__c IN :accountIds
        ]) {
            res.put(abd.Account__c + ':' + abd.BusinessDivision__c, abd);
        }
        return res;
    }

    private static Map<String, AccountSalesSegmentation__c> getAssMap(Set<Id> accountIds, Set<Id> ownerIds) {
        Map<String, AccountSalesSegmentation__c> res = new Map<String, AccountSalesSegmentation__c>();
        for (AccountSalesSegmentation__c ass : [
            SELECT Account__c, Manager__c
            FROM AccountSalesSegmentation__c
            WHERE Account__c IN :accountIds AND Manager__c IN :ownerIds
        ]) {
            res.put(ass.Account__c + ':' + ass.Manager__c, ass);
        }
        return res;
    }

    private static Id getUserIdByUsername(String username) {
        List<User> u = [SELECT Id FROM User WHERE Username = :username LIMIT 1];
        return u.isEmpty() ? UserInfo.getUserId() : u[0].Id;
    }

    private static void enqueueNormalizationIfNeeded(List<Account> input, Map<Id, Account> oldMapOpt) {
        List<Account> listToProcess = new List<Account>();
        for (Account acc : input) {
            if (String.isBlank(acc.Name)) continue;
            if (oldMapOpt == null || oldMapOpt.get(acc.Id) == null || acc.Name != oldMapOpt.get(acc.Id).Name) {
                listToProcess.add(new Account(Id = acc.Id, Name = acc.Name));
            }
        }
        if (!listToProcess.isEmpty()) {
            System.enqueueJob(new QueueUpdateAccountNormName(listToProcess));
        }
    }
}