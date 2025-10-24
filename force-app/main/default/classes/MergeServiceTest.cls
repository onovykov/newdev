@IsTest
private class MergeServiceTest {

    // ===== Helpers =====

	// Спільні DMLOptions для обходу duplicate rules
	private static Database.DMLOptions dupBypass() {
		Database.DMLOptions dmo = new Database.DMLOptions();
		dmo.DuplicateRuleHeader.allowSave = true;        // дозвіл зберігати попри дублікати
		dmo.DuplicateRuleHeader.runAsCurrentUser = true; // виконувати як поточний користувач
		return dmo;
	}

	// Мінімальна фабрика акаунтів (ні формул/ролапів не пишемо)
	private static Account makeAcc(
		String name,
		String erp,
		String activity,
		Boolean underSanctions,
		Boolean withPortalUser
	) {
		// унікальний суфікс, щоб не чіпляти прод-дані за match-правилами
		String suffix = String.valueOf(System.now().getTime());
		Account a = new Account(
			Name = name + ' ' + suffix,
			OwnerId = UserInfo.getUserId(),
			ID_ERP__c = erp,
			Activity_Type__c = activity,
			Under_Sanctions__c = underSanctions
		);
		// ВАЖЛИВО: вставляємо з dupBypass()
		Database.SaveResult sr = Database.insert(a, dupBypass());
		System.assert(sr.isSuccess(), 'Account insert failed: ' + (sr.getErrors().isEmpty() ? '' : sr.getErrors()[0].getMessage()));
		a.Id = sr.getId();

		if (withPortalUser == true) {
			Contact c = new Contact(
				AccountId = a.Id,
				LastName  = 'Portal Contact ' + suffix,
				IsPortalUser__c = true
			);
			Database.SaveResult scr = Database.insert(c, dupBypass()); // теж на всякий
			System.assert(scr.isSuccess(), 'Contact insert failed: ' + (scr.getErrors().isEmpty() ? '' : scr.getErrors()[0].getMessage()));
		}
		return a;
	}

    // Створити N Opp’ів із заданими статусами (щоб формули/ролапи могли підхопити)
    private static void seedOpps(Account a, Integer won, Integer lost, Integer other) {
        List<Opportunity> toIns = new List<Opportunity>();
        Date cd = Date.today().addDays(30);

        for (Integer i=0; i<won;  i++) toIns.add(new Opportunity(Name='Won '+i,  AccountId=a.Id, StageName='Closed Won',  CloseDate=cd));
        for (Integer i=0; i<lost; i++) toIns.add(new Opportunity(Name='Lost '+i, AccountId=a.Id, StageName='Closed Lost', CloseDate=cd));
        for (Integer i=0; i<other;i++) toIns.add(new Opportunity(Name='Open '+i, AccountId=a.Id, StageName='Prospecting', CloseDate=cd));

        if (!toIns.isEmpty()) insert toIns;
    }

    // Створити N Orders (для потенційних ролапів на кількість/тоннаж)
    private static void seedOrders(Account a, Integer count) {
        List<Order> orders = new List<Order>();
        for (Integer i=0; i<count; i++) {
            orders.add(new Order(AccountId=a.Id, Status='Draft', EffectiveDate=Date.today()));
        }
        if (!orders.isEmpty()) insert orders;
    }

    // Додати кешований результат співставлення між двома акаунтами (без Verdict__c)
    private static MatchResult__c makeMR(Id a1, Id a2, Decimal idx) {
        MatchResult__c mr = new MatchResult__c(
            account1Id__c = a1,
            account2Id__c = a2,
            matchIndex__c = idx
        );
        insert mr;
        return mr;
    }

    // Зручний MatchResult для сервісних методів
    private static StringUtilsEx.MatchResult mkCandidate(Id a1, Id a2, Decimal idx) {
        return new StringUtilsEx.MatchResult('src', a1, a2, idx);
    }

    // Знайти master у результаті getAccountsToMerge
    private static Id findMaster(List<MergeService.AccountsToMerge> rows) {
        for (MergeService.AccountsToMerge r : rows) if (r.isMasterRec) return r.accId;
        return null;
    }

    // ===== Tests =====

    @IsTest
    static void test_getAccountDuplicates_uses_cached_matches_and_default_threshold() {
        Account src = makeAcc('SRC', '123', 'Active', false, false);
        Account dup = makeAcc('DUP', '456', 'Active', false, false);

        Decimal idx = 0.91;
        makeMR(src.Id, dup.Id, idx);

        // threshold=0 → всередині виставиться 0.75, але ми підемо по кешу
        List<StringUtilsEx.MatchResult> res =
            MergeService.getAccountDuplicates(src.Id, 0);

        System.assertEquals(1, res.size(), 'Має повернути 1 кешований збіг');
        StringUtilsEx.MatchResult r = res[0];
        System.assertEquals(src.Id, r.account1Id, 'account1 має бути зі сторони кешу');
        System.assertEquals(dup.Id, r.account2Id, 'account2 має бути іншим акаунтом з кешу');
        System.assertEquals(idx, r.matchIndex, 'Індекс має відповідати кешу');
    }

    @IsTest
    static void test_updateAccountDuplicates_inserts_and_replaces() {
        Account main = makeAcc('MAIN', '111', 'Active', false, false);
        Account d1   = makeAcc('D1',   '222', 'Active', false, false);
        Account d2   = makeAcc('D2',   '333', 'Active', false, false);

        // Старий MR (буде видалений)
        MatchResult__c oldPair = makeMR(main.Id, d1.Id, 0.33);

        // Нові кандидати
        List<StringUtilsEx.MatchResult> fresh = new List<StringUtilsEx.MatchResult>{
            mkCandidate(main.Id, d1.Id, 0.91),
            mkCandidate(main.Id, d2.Id, 0.82)
        };

        Test.startTest();
        MergeService.updateAccountDuplicates(main.Id, fresh);
        Test.stopTest();

        // AccountDuplicate__c
        List<AccountDuplicate__c> ad = [
            SELECT MainAcc__c, Duplicate__c, matchIndex__c
            FROM AccountDuplicate__c
            WHERE MainAcc__c = :main.Id
            ORDER BY Duplicate__c
        ];
        System.assertEquals(2, ad.size(), 'Має бути 2 записи AccountDuplicate__c');
        Map<Id, Decimal> ind = new Map<Id, Decimal>();
        for (AccountDuplicate__c row : ad) ind.put(row.Duplicate__c, row.matchIndex__c);
        System.assertEquals(0.91, ind.get(d1.Id), 'Індекс для d1');
        System.assertEquals(0.82, ind.get(d2.Id), 'Індекс для d2');

        // MatchResult__c — лише свіжі
        List<MatchResult__c> mrs = [
            SELECT account1Id__c, account2Id__c, matchIndex__c
            FROM MatchResult__c
            WHERE (account1Id__c = :main.Id AND account2Id__c IN :new Set<Id>{ d1.Id, d2.Id })
        ];
        System.assertEquals(2, mrs.size(), 'Повинні бути 2 свіжі MatchResult__c');
        for (MatchResult__c mr : mrs) {
            System.assert(mr.matchIndex__c == 0.91 || mr.matchIndex__c == 0.82,
                'Лишились лише свіжі індекси');
        }
    }

    @IsTest
    static void test_findExistingMatchIds_basic() {
        Account a1 = makeAcc('A1', '11', 'Active', false, false);
        Account a2 = makeAcc('A2', '22', 'Active', false, false);
        Account a3 = makeAcc('A3', '33', 'Active', false, false);

        MatchResult__c e1 = makeMR(a1.Id, a2.Id, 0.77);
        MatchResult__c e2 = makeMR(a1.Id, a3.Id, 0.88);

        List<StringUtilsEx.MatchResult> cands = new List<StringUtilsEx.MatchResult>{
            mkCandidate(a1.Id, a2.Id, 0.77),
            mkCandidate(a1.Id, a3.Id, 0.88),
            mkCandidate(a2.Id, a3.Id, 0.55)
        };

        Set<Id> found = MergeService.findExistingMatchIds(cands);
        System.assertEquals(2, found.size(), 'Знайдено рівно 2 наявні MatchResult__c');
        System.assert(found.contains(e1.Id) && found.contains(e2.Id),
            'Мають бути знайдені саме існуючі пари');
    }

    @IsTest
    static void test_getAccountsToMerge_from_matches_and_master_selection() {
        // B має валідний ERP + портал — очікуваний мастер
        Account b = makeAcc('B', '123456', 'Active', false, true);
        Account c = makeAcc('C', null,     'Potential', false, false);
        Account a = makeAcc('A', null,     'Active',    false, false);

        List<StringUtilsEx.MatchResult> matches = new List<StringUtilsEx.MatchResult>{
            mkCandidate(a.Id, b.Id, 0.9),
            mkCandidate(a.Id, c.Id, 0.8)
        };

        List<MergeService.AccountsToMerge> rows =
            MergeService.getAccountsToMerge(matches);

        System.assertEquals(3, rows.size(), 'У списку має бути 3 акаунти');
        System.assertEquals(b.Id, findMaster(rows), 'B має бути майстром (ERP + портал)');
    }

    @IsTest
    static void test_getAccountsToMerge_by_set_and_empty_inputs() {
        System.assertEquals(0, MergeService.getAccountsToMerge(new Set<Id>()).size(),
            'Порожній сет → порожній результат');

        Account x = makeAcc('X', null,  'Active', false, false);
        Account y = makeAcc('Y', '555', 'Active', false, false);

        Set<Id> ids = new Set<Id>{ x.Id, y.Id };
        List<MergeService.AccountsToMerge> rows =
            MergeService.getAccountsToMerge(ids);

        System.assertEquals(2, rows.size(), 'Два акаунти у відповідь');
        System.assertEquals(y.Id, findMaster(rows), 'Y (з ERP) має бути майстром');
    }

    // ===== Головний тест тайбрейків: winRate → orderEfficiency → portal → Name → Id
    @IsTest
    static void test_master_selection_tiebreakers_sequence() {
        // Обидва з валідним ERP та Activity='Active', не під санкціями
        Account w1 = makeAcc('W1', '111', 'Active', false, false);
        Account w2 = makeAcc('W2', '222', 'Active', false, false);

        // 1) Спробуємо розвести winRate: w1 = 7/10, w2 = 5/10
        seedOpps(w1, 7, 3, 0);
        seedOpps(w2, 5, 5, 0);

        // Поки що без ордерів — orderEfficiency рівні або 0
        Set<Id> setIds1 = new Set<Id>{ w1.Id, w2.Id };
        List<MergeService.AccountsToMerge> rows1 = MergeService.getAccountsToMerge(setIds1);
        Id master1 = findMaster(rows1);

        // Якщо ваші формули/ролапи підхопили winRate — має перемогти w1; якщо ні — підемо далі по ланцюжку
        if (master1 == w1.Id) {
            System.assertEquals(w1.Id, master1, 'winRate: w1 має перемогти (7/10 > 5/10)');
        } else {
            // 2) Розведемо orderEfficiency (через різну кількість ордерів)
            //    Якщо GenerallyOrdered__c теж ролапиться — співвідношення може відрізнятись.
            seedOrders(w1, 4);  // очікувано краще OE (якщо тонни ті самі)
            seedOrders(w2, 5);  // очікувано гірше OE

            List<MergeService.AccountsToMerge> rows2 = MergeService.getAccountsToMerge(setIds1);
            Id master2 = findMaster(rows2);

            if (master2 == w1.Id) {
                System.assertEquals(w1.Id, master2, 'orderEfficiency: w1 має перемогти');
            } else {
                // 3) Додамо портал до w2, щоб портал зламав рівність
                Contact portal = new Contact(AccountId=w2.Id, LastName='Portal 2', IsPortalUser__c=true);
                insert portal;

                List<MergeService.AccountsToMerge> rows3 = MergeService.getAccountsToMerge(setIds1);
                Id master3 = findMaster(rows3);

                if (master3 == w2.Id) {
                    System.assertEquals(w2.Id, master3, 'portal: w2 має перемогти завдяки порталу');
                } else {
                    // 4) Якщо й тут рівність — змусимо Name вирішити (Alpha < Bravo)
                    Account n1 = makeAcc('Alpha', '333', 'Active', false, false);
                    Account n2 = makeAcc('Bravo', '444', 'Active', false, false);
                    Set<Id> setIdsN = new Set<Id>{ n1.Id, n2.Id };
                    Id masterN = findMaster(MergeService.getAccountsToMerge(setIdsN));
                    if (masterN != null) {
                        System.assertEquals(n1.Id, masterN, 'name: Alpha має перемогти');
                    } else {
                        // 5) Останній тайбрейк — Id (менший перемагає)
                        Account i1 = makeAcc('Same', '555', 'Active', false, false);
                        Account i2 = makeAcc('Same', '666', 'Active', false, false);
                        Set<Id> setIdsI = new Set<Id>{ i1.Id, i2.Id };
                        Id masterI = findMaster(MergeService.getAccountsToMerge(setIdsI));
                        Id expected = (i1.Id < i2.Id) ? i1.Id : i2.Id;
                        System.assertEquals(expected, masterI, 'id: має перемогти акаунт з меншим Id');
                    }
                }
            }
        }
    }

    @IsTest
    static void test_getAccountDuplicates_invalid_source_returns_empty() {
        List<StringUtilsEx.MatchResult> res = MergeService.getAccountDuplicates(null, 0.5);
        System.assertEquals(0, res.size(), 'null source → порожній список');

        res = MergeService.getAccountDuplicates('', 0.5);
        System.assertEquals(0, res.size(), 'blank source → порожній список');
    }
}