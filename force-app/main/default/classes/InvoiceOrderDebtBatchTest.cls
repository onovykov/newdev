@IsTest
private class InvoiceOrderDebtBatchTest {

    // Той самий формат, що й у прод-коді
    private static String buildKey(Id acc, Id pu, String ccy, String debtType) {
        String accStr = acc == null ? '' : String.valueOf(acc);
        String puStr  = pu  == null ? '' : String.valueOf(pu);
        String ccyStr = ccy == null ? '' : ccy;
        String dtStr  = debtType == null ? '' : debtType;
        return accStr + '|' + puStr + '|' + ccyStr + '|' + dtStr;
    }

    @IsTest
    static void should_Rebuild_Summaries_Upsert_And_Prune() {
        // A1, A2 мають борги; A3 — «сміттєвий» підсумок для prune
        Account a1 = new Account(Name = 'A1');
        Account a2 = new Account(Name = 'A2');
        Account a3 = new Account(Name = 'A3');
        insert new List<Account>{ a1, a2, a3 };

        // Борги:
        // A1 USD: 100 (current) + 40 (overdue)
        // A2 EUR: 70 (current)
        insert new List<InvoiceOrderDebt__c>{
            new InvoiceOrderDebt__c(Account__c = a1.Id, CurrencyIsoCode = 'USD', NetAmount__c = 100, DaysOverdue__c = 0),
            new InvoiceOrderDebt__c(Account__c = a1.Id, CurrencyIsoCode = 'USD', NetAmount__c =  40, DaysOverdue__c = 5),
            new InvoiceOrderDebt__c(Account__c = a2.Id, CurrencyIsoCode = 'EUR', NetAmount__c =  70, DaysOverdue__c = 0)
        };

        // Сміттєвий запис (валідне значення пікліста), для акаунта без боргів → має бути видалений
        InvoiceDebtSummary__c garbage = new InvoiceDebtSummary__c(
            Account__c      = a3.Id,
            CurrencyIsoCode = 'USD',
            DebtType__c     = 'Total Debt',
            SumDebt__c      = 999
        );
        garbage.CompositeKey__c = buildKey(a3.Id, null, 'USD', 'Total Debt');
        insert garbage;

        Test.startTest();
        Database.executeBatch(new InvoiceOrderDebtBatch(), 1);
        Test.stopTest();

        // Очікуємо:
        // A1 USD Total = 140, A1 USD Overdue = 40, A2 EUR Total = 70
        InvoiceDebtSummary__c a1UsdTotal = [
            SELECT SumDebt__c
            FROM InvoiceDebtSummary__c
            WHERE Account__c = :a1.Id AND CurrencyIsoCode = 'USD' AND DebtType__c = 'Total Debt'
            LIMIT 1
        ];
        InvoiceDebtSummary__c a1UsdOverdue = [
            SELECT SumDebt__c
            FROM InvoiceDebtSummary__c
            WHERE Account__c = :a1.Id AND CurrencyIsoCode = 'USD' AND DebtType__c = 'Overdue Debt'
            LIMIT 1
        ];
        InvoiceDebtSummary__c a2EurTotal = [
            SELECT SumDebt__c
            FROM InvoiceDebtSummary__c
            WHERE Account__c = :a2.Id AND CurrencyIsoCode = 'EUR' AND DebtType__c = 'Total Debt'
            LIMIT 1
        ];

        System.assertEquals(140, a1UsdTotal.SumDebt__c,   'A1 USD Total should be 140');
        System.assertEquals( 40, a1UsdOverdue.SumDebt__c, 'A1 USD Overdue should be 40');
        System.assertEquals( 70, a2EurTotal.SumDebt__c,   'A2 EUR Total should be 70');

        // Переконаємося, що сміттєвий запис видалено
        Integer garbageCnt = [
            SELECT COUNT()
            FROM InvoiceDebtSummary__c
            WHERE Account__c = :a3.Id AND CurrencyIsoCode = 'USD' AND DebtType__c = 'Total Debt'
        ];
        System.assertEquals(0, garbageCnt, 'Garbage summary (A3) must be pruned');
    }

    @IsTest
    static void should_Upsert_And_Create_Overdue_On_First_Run_When_Existing_Summary_Present() {
        Account a = new Account(Name = 'A');
        insert a;

        // Існуючий підсумок (імітує попередній стан), але без відповідних вихідних боргів
        InvoiceDebtSummary__c existing = new InvoiceDebtSummary__c(
            Account__c      = a.Id,
            CurrencyIsoCode = 'USD',
            DebtType__c     = 'Total Debt',
            SumDebt__c      = 50
        );
        existing.CompositeKey__c = buildKey(a.Id, null, 'USD', 'Total Debt');
        insert existing;

        // Реальні борги, які бачить батч: 20 current + 10 overdue => Total має стати 30
        insert new List<InvoiceOrderDebt__c>{
            new InvoiceOrderDebt__c(Account__c = a.Id, CurrencyIsoCode = 'USD', NetAmount__c = 20, DaysOverdue__c = 0),
            new InvoiceOrderDebt__c(Account__c = a.Id, CurrencyIsoCode = 'USD', NetAmount__c = 10, DaysOverdue__c = 2)
        };

        Test.startTest();
        Database.executeBatch(new InvoiceOrderDebtBatch(), 1);
        Test.stopTest();

        InvoiceDebtSummary__c total = [
            SELECT SumDebt__c
            FROM InvoiceDebtSummary__c
            WHERE Account__c = :a.Id AND CurrencyIsoCode = 'USD' AND DebtType__c = 'Total Debt'
            LIMIT 1
        ];
        InvoiceDebtSummary__c overdue = [
            SELECT SumDebt__c
            FROM InvoiceDebtSummary__c
            WHERE Account__c = :a.Id AND CurrencyIsoCode = 'USD' AND DebtType__c = 'Overdue Debt'
            LIMIT 1
        ];

        System.assertEquals(30, total.SumDebt__c,   'Total must reflect source data (20+10)');
        System.assertEquals(10, overdue.SumDebt__c, 'Overdue should be 10');
    }
}