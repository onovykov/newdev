public with sharing class MergeService {
    public static List<StringUtilsEx.MatchResult> getAccountDuplicates(String sourceId, Decimal threshold) {
        List<StringUtilsEx.MatchResult> matches = new List<StringUtilsEx.MatchResult>();
        if (String.isBlank(sourceId)) {
            System.debug('Source Id is incorrect');
            return matches;
        }
        if (threshold == null || threshold == 0.0 || threshold < 0 || threshold > 1.0) {
            System.debug('Parameter threshold was set to default value 0.75');
            threshold = 0.75;
        }

        //--- Шукаємо по об'єкту MatchResult__c
        List<MatchResult__c> match = [
            SELECT account1Id__c, account2Id__c, matchIndex__c, verdict__c
            FROM MatchResult__c
            WHERE account1Id__c = :sourceId OR account2Id__c = :sourceId
        ];
        Account acc = AccountRepository.getById((Id)sourceId);

        if (!match.isEmpty()) {
            for (MatchResult__c rec : match) {
                StringUtilsEx.MatchResult matchRec = new StringUtilsEx.MatchResult(
                    acc.Name,
                    (Id)rec.account1Id__c,
                    (Id)rec.account2Id__c,
                    rec.matchIndex__c
                );
                matches.add(matchRec);
            }
        } else {
            // Якщо нічого немає — запускаємо пошук
            IndexWeights idxWeights = IndexWeights.getDefault();
            WeightSet pairWeights = WeightSet.getDefault();

            matches = NameSimilarityUtil.finalDuplicateCheck(
                Consts.FIND_BY_CODE, '',
                Consts.FIND_BY_SF_ID, '',
                sourceId,
                threshold,
                false,
                idxWeights,
                pairWeights
            );
        }
        return matches;
    }

    //--- Оновлюємо записи дублікатів
    public static void updateAccountDuplicates(String sourceId, List<StringUtilsEx.MatchResult> matches) {
        // Підготуємо MatchResult__c для інсерта
        List<MatchResult__c> matchesIns = new List<MatchResult__c>();

        // Отримуємо мапу Id→matchIndex усіх контрагентів (окрім sourceId)
        Map<Id, Decimal> mapIdsMatch = new Map<Id, Decimal>();
        for (StringUtilsEx.MatchResult m : matches) {
            if (m.account1Id != (Id)sourceId) mapIdsMatch.put(m.account1Id, m.matchIndex);
            if (m.account2Id != (Id)sourceId) mapIdsMatch.put(m.account2Id, m.matchIndex);

            matchesIns.add(new MatchResult__c(
                account1Id__c = m.account1Id,
                account2Id__c = m.account2Id,
                matchIndex__c = m.matchIndex
            ));
        }

        // Почистимо AccountDuplicate__c для цього sourceId
        List<AccountDuplicate__c> accDuplList = [
            SELECT Id FROM AccountDuplicate__c WHERE MainAcc__c = :((Id)sourceId)
        ];
        delete accDuplList;

        // Створюємо нові AccountDuplicate__c
        if (!mapIdsMatch.isEmpty()) {
            List<AccountDuplicate__c> toInsert = new List<AccountDuplicate__c>();
            for (Id key : mapIdsMatch.keySet()) {
                toInsert.add(new AccountDuplicate__c(
                    MainAcc__c = (Id)sourceId,
                    Duplicate__c = key,
                    matchIndex__c = mapIdsMatch.get(key)
                ));
            }
            insert toInsert;
        }

        // Оновлюємо MatchResult__c: видалимо існуючі пари й вставимо свіжі
        Set<Id> existing = findExistingMatchIds(matches);
        if (!existing.isEmpty()) {
            delete [SELECT Id FROM MatchResult__c WHERE Id IN :existing];
        }
        if (!matchesIns.isEmpty()) {
            insert matchesIns;
        }
    }

    //--- Знаходимо наявні пари MatchResult__c серед переданих кандидатів
    public static Set<Id> findExistingMatchIds(List<StringUtilsEx.MatchResult> candidates) {
        if (candidates == null || candidates.isEmpty()) return new Set<Id>();

        Set<Id> a1Set = new Set<Id>();
        Map<Id, Set<Id>> pairs = new Map<Id, Set<Id>>();
        for (StringUtilsEx.MatchResult mr : candidates) {
            if (mr == null || mr.account1Id == null || mr.account2Id == null) continue;
            a1Set.add(mr.account1Id);
            if (!pairs.containsKey(mr.account1Id)) pairs.put(mr.account1Id, new Set<Id>());
            pairs.get(mr.account1Id).add(mr.account2Id);
        }
        if (a1Set.isEmpty()) return new Set<Id>();

        Set<Id> a2Set = new Set<Id>();
        for (Set<Id> s : pairs.values()) a2Set.addAll(s);
        if (a2Set.isEmpty()) return new Set<Id>();

        List<MatchResult__c> rows = [
            SELECT Id, account1Id__c, account2Id__c
            FROM MatchResult__c
            WHERE account1Id__c IN :a1Set AND account2Id__c IN :a2Set
        ];

        Set<Id> resultIds = new Set<Id>();
        for (MatchResult__c r : rows) {
            Id a1 = r.account1Id__c, a2 = r.account2Id__c;
            if (pairs.containsKey(a1) && pairs.get(a1).contains(a2)) {
                resultIds.add(r.Id);
            }
        }
        return resultIds;
    }

    //--- Формуємо перелік акаунтів на Merge з переліку дублів
    public static List<AccountsToMerge> getAccountsToMerge(List<StringUtilsEx.MatchResult> matches) {
        List<AccountsToMerge> mergeList = new List<AccountsToMerge>();
        if (matches == null || matches.isEmpty()) {
            System.debug('Matches List is incorrect');
            return mergeList;
        }

        Set<Id> accIds = new Set<Id>();
        for (StringUtilsEx.MatchResult m : matches) {
            accIds.add(m.account1Id);
            accIds.add(m.account2Id);
        }

        Map<Id, Account> accMap = new Map<Id, Account>([
            SELECT
                Id, Name, ID_ERP__c, MarketSegment__c,
                CountryId__c,
                BillingCountryCode, BillingCity,
                OwnerId,
                OppsCount__c, ClosedWonOpps__c, ClosedLost__c, OrdersCount__c,
                Activity_Type__c, Under_Sanctions__c, GenerallyOrdered__c
            FROM Account
            WHERE Id IN :accIds
        ]);

        for (Id id : accIds) {
            Account a = accMap.get(id);
            if (a == null) continue;
            mergeList.add(new AccountsToMerge(
                a.Name, id, a.ID_ERP__c, a.MarketSegment__c,
                a.CountryId__c,
                a.BillingCountryCode, a.BillingCity,
                a.OwnerId,
                a.OppsCount__c, a.ClosedWonOpps__c, a.ClosedLost__c, a.OrdersCount__c,
                a.Activity_Type__c, a.Under_Sanctions__c, a.GenerallyOrdered__c,
                false
            ));
        }

        Id masterId = selectMasterId(accMap, accIds);
        if (masterId != null) {
            for (AccountsToMerge row : mergeList) row.isMasterRec = (row.accId == masterId);
        }
        return mergeList;
    }


    //--- Формуємо перелік акаунтів на Merge з сету Id вибраних акаунтів
    public static List<AccountsToMerge> getAccountsToMerge(Set<Id> accIds) {
        List<AccountsToMerge> mergeList = new List<AccountsToMerge>();
        if (accIds == null || accIds.isEmpty()) {
            System.debug('Account List is incorrect');
            return mergeList;
        }

        Map<Id, Account> accMap = new Map<Id, Account>([
            SELECT
                Id, Name, ID_ERP__c, MarketSegment__c,
                CountryId__c,
                BillingCountryCode, BillingCity,
                OwnerId,
                OppsCount__c, ClosedWonOpps__c, ClosedLost__c, OrdersCount__c,
                Activity_Type__c, Under_Sanctions__c, GenerallyOrdered__c
            FROM Account
            WHERE Id IN :accIds
        ]);

        for (Id id : accIds) {
            Account a = accMap.get(id);
            if (a == null) continue;
            mergeList.add(new AccountsToMerge(
                a.Name, id, a.ID_ERP__c, a.MarketSegment__c,
                a.CountryId__c,
                a.BillingCountryCode, a.BillingCity,
                a.OwnerId,
                a.OppsCount__c, a.ClosedWonOpps__c, a.ClosedLost__c, a.OrdersCount__c,
                a.Activity_Type__c, a.Under_Sanctions__c, a.GenerallyOrdered__c,
                false
            ));
        }

        Id masterId = selectMasterId(accMap, accIds);
        if (masterId != null) {
            for (AccountsToMerge row : mergeList) row.isMasterRec = (row.accId == masterId);
        }
        return mergeList;
    }

    // ----------- Helpers -----------
    // Валідний ERP = лише цифри й не "0"
    private static Boolean hasValidErp(String s) {
        if (String.isBlank(s)) return false;
        String t = s.trim();
        if (t == '0') return false;
        for (Integer i = 0; i < t.length(); i++) {
            String ch = t.substring(i, i + 1);
            if (ch < '0' || ch > '9') return false;
        }
        return true;
    }

    private static Decimal getWinRate(Account a) {
        Decimal opps = (a.OppsCount__c == null ? 0 : a.OppsCount__c);
        Decimal won  = (a.ClosedWonOpps__c == null ? 0 : a.ClosedWonOpps__c);
        return (opps > 0 ? (won / opps) : 0);
    }

    private static Decimal getOrderEfficiency(Account a) {
        Decimal orders = (a.OrdersCount__c == null ? 0 : a.OrdersCount__c);
        Decimal tons   = (a.GenerallyOrdered__c == null ? 0 : a.GenerallyOrdered__c);
        return (orders > 0 ? (tons / orders) : 0);
    }

    /**
     * Обирає master за правилами:
     *  - виключаємо під санкціями;
     *  - якщо серед НЕзаблокованих є валідний ERP → кандидати з Activity=Potential відкидаємо;
     *  - тайбрейки: валідний ERP → winRate → orderEfficiency → (NEW: isPortalAccount)
     *               → Name (asc, null last) → Id (asc).
     */
    private static Id selectMasterId(Map<Id, Account> accMap, Set<Id> accIds) {
        // 1) Відкидаємо під санкціями
        List<Account> nonBlocked = new List<Account>();
        for (Id id : accIds) {
            Account a = accMap.get(id);
            if (a == null) continue;
            if (a.Under_Sanctions__c == true) continue;
            nonBlocked.add(a);
        }
        if (nonBlocked.isEmpty()) return null;

        // 2) Чи є валідний ERP серед незаблокованих
        Boolean anyHasValidErp = false;
        for (Account a : nonBlocked) {
            if (hasValidErp(a.ID_ERP__c)) { anyHasValidErp = true; break; }
        }

        // 3) Кандидати до порівняння (за правилом Potential)
        List<Account> candidates = new List<Account>();
        for (Account a : nonBlocked) {
            if (anyHasValidErp && a.Activity_Type__c == 'Potential') continue;
            candidates.add(a);
        }
        if (candidates.isEmpty()) return null;

        // 4) (NEW) Зібрати Set<Id> акаунтів, що мають контакт-portal user
        Set<Id> portalAccIds = new Set<Id>();
        if (!accIds.isEmpty()) {
            for (Contact c : [
                SELECT AccountId
                FROM Contact
                WHERE IsPortalUser__c = true AND AccountId IN :accIds
            ]) {
                if (c.AccountId != null) portalAccIds.add(c.AccountId);
            }
        }

        // 5) Порівняння кандидатів
        Account best = null;
        for (Account a : candidates) {
            if (best == null) { best = a; continue; }

            // 5.1 ERP
            Boolean aErp = hasValidErp(a.ID_ERP__c), bErp = hasValidErp(best.ID_ERP__c);
            if (aErp != bErp) { if (aErp) best = a; continue; }

            // 5.2 WinRate
            Decimal aWR = getWinRate(a), bWR = getWinRate(best);
            if (aWR != bWR) { if (aWR > bWR) best = a; continue; }

            // 5.3 OrderEfficiency
            Decimal aOE = getOrderEfficiency(a), bOE = getOrderEfficiency(best);
            if (aOE != bOE) { if (aOE > bOE) best = a; continue; }

            // 5.4 (NEW) Перевага акаунту з portal user
            Boolean aPortal = portalAccIds.contains(a.Id);
            Boolean bPortal = portalAccIds.contains(best.Id);
            if (aPortal != bPortal) { if (aPortal) best = a; continue; }

            // 5.5 Name (asc, null last)
            String aName = a.Name, bName = best.Name;
            if (aName == null && bName != null) { /* best залишається */ }
            else if (aName != null && bName == null) { best = a; }
            else if (aName != null && bName != null && aName != bName) {
                if (aName < bName) best = a;
            } else {
                // 5.6 Id (asc) — "хай буде перший у списку"
                if (a.Id < best.Id) best = a;
            }
        }
        return (best == null ? null : best.Id);
    }


    // Рядок результатів для таблиці Merge
    public class AccountsToMerge {
        public String accName;
        public Id accId;
        public String accErp;
        public String accSegment;
        public Id accCountry;
        public String accCountryCode;
        public String accCity;
        public Id accOwnerId;
        public Decimal accOppsCount;
        public Decimal accOppsWon;
        public Decimal accOppsLost;
        public Decimal accOrdersCount;
        public String accActivity;
        public Boolean accSanctions;
        public Decimal accGenerallyOrdered;
        public Boolean isMasterRec;

        public Decimal winRate;
        public Decimal orderEfficiency;

        public AccountsToMerge(
            String accName, Id accId, String accErp, String accSegment,
            Id accCountry, String accCountryCode, String accCity,
            Id accOwnerId,
            Decimal accOppsCount, Decimal accOppsWon, Decimal accOppsLost, Decimal accOrdersCount,
            String accActivity, Boolean accSanctions, Decimal accGenerallyOrdered,
            Boolean isMasterRec
        ) {
            this.accName = accName;
            this.accId = accId;
            this.accErp = accErp;
            this.accSegment = accSegment;
            this.accCountry = accCountry;
            this.accCountryCode = accCountryCode;
            this.accCity = accCity;
            this.accOwnerId = accOwnerId;
            this.accOppsCount = accOppsCount;
            this.accOppsWon = accOppsWon;
            this.accOppsLost = accOppsLost;
            this.accOrdersCount = accOrdersCount;
            this.accActivity = accActivity;
            this.accSanctions = accSanctions;
            this.accGenerallyOrdered = accGenerallyOrdered;
            this.isMasterRec = isMasterRec;

            Decimal opps = (accOppsCount == null ? 0 : accOppsCount);
            Decimal won  = (accOppsWon   == null ? 0 : accOppsWon);
            this.winRate = (opps > 0 ? (won / opps) : 0);

            Decimal orders = (accOrdersCount == null ? 0 : accOrdersCount);
            Decimal tons   = (accGenerallyOrdered == null ? 0 : accGenerallyOrdered);
            this.orderEfficiency = (orders > 0 ? (tons / orders) : 0);
        }
    }
}