@IsTest
private class AccountsReceivableUpdateTest {

    // Допоміжний конструктор ISO-дат заради зручності
    private static String iso(Datetime dt) {
        return dt == null ? null : dt.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
    }

    @IsTest
    static void should_Update_Accounts_From_ERP_Message_With_Retries_SafeFinish() {
        // ---- Arrange: дані в SF ----
        Account a1 = new Account(Name = 'Acme 1', ID_ERP__c = 'ERP-1001');
        Account a2 = new Account(Name = 'Acme 2', ID_ERP__c = 'ERP-1002');
        insert new List<Account>{ a1, a2 };

        // ---- Arrange: формуємо JSON під ERPMessageParser ----
        Datetime ts = Datetime.newInstance(2025, 1, 1, 12, 0, 0);
        Datetime due1 = Datetime.newInstance(2025, 1, 15, 0, 0, 0);
        Datetime perm2 = Datetime.newInstance(2025, 2, 10, 0, 0, 0);

        // item для a1: toBlock = true → DealingStatus__c має бути '40'
        // item для a2: toBlock = false → DealingStatus__c = status із ERP (наприклад, "30")
        String body =
        '{' +
          '"metadata": {' +
            '"msgTimestamp": "' + iso(ts) + '"' +
          '},' +
          '"data": {' +
            '"items": [' +
              '{' +
                '"account": {"id":"ERP-1001"},' +
                '"balance": 120.5,' +
                '"pastDueDebt": 20.5,' +
                '"pastDueDebt15More": 10,' +
                '"groupPastDueDebt": 5,' +
                '"groupPastDueDebt15More": 2,' +
                '"dueDate": "' + iso(due1) + '",' +
                '"receipts": 11.1,' +
                '"toBlock": true,' +
                '"permissionDate": null,' +
                '"permittedProductionAmount": 1000,' +
                '"permittedShipmentAmount": 500,' +
                '"permissionComment": "Hold credit",' +
                '"status": "10"' +        // буде ігноровано, бо toBlock=true → '40'
              '},' +
              '{' +
                '"account": {"id":"ERP-1002"},' +
                '"balance": 300,' +
                '"pastDueDebt": 0,' +
                '"pastDueDebt15More": 0,' +
                '"groupPastDueDebt": 0,' +
                '"groupPastDueDebt15More": 0,' +
                '"dueDate": null,' +
                '"receipts": 77.77,' +
                '"toBlock": false,' +
                '"permissionDate": "' + iso(perm2) + '",' +
                '"permittedProductionAmount": 222,' +
                '"permittedShipmentAmount": 333,' +
                '"permissionComment": "OK",' +
                '"status": "30"' +        // очікуємо DealingStatus__c = '30'
              '}' +
            ']' +
          '}' +
        '}';

        Test.startTest();
        // Менший розмір чанку одразу (менше шансів на локи, навіть у бою)
        Id jobId = Database.executeBatch(new AccountsReceivableUpdate(body), 50);
        Test.stopTest();

        // ---- Assert: свіжі значення підтягнулись з ERP ----
        Account r1 = [
            SELECT AccountsReceivableExchangeTimestamp__c, AccountsReceivableLastSync__c,
                   Balance__c, PastDueDebt__c, PastDueDebt15More__c,
                   GroupPastDueDebt__c, GroupPastDueDebt15More__c,
                   BlockDate__c, CurrentMonthReceipts__c, StopListRisk__c,
                   PermissionDate__c, PermittedProductionAmount__c, PermittedShipmentAmount__c,
                   PermissionComment__c, DealingStatus__c
            FROM Account WHERE Id = :a1.Id
        ];
        Account r2 = [
            SELECT AccountsReceivableExchangeTimestamp__c, AccountsReceivableLastSync__c,
                   Balance__c, PastDueDebt__c, PastDueDebt15More__c,
                   GroupPastDueDebt__c, GroupPastDueDebt15More__c,
                   BlockDate__c, CurrentMonthReceipts__c, StopListRisk__c,
                   PermissionDate__c, PermittedProductionAmount__c, PermittedShipmentAmount__c,
                   PermissionComment__c, DealingStatus__c
            FROM Account WHERE Id = :a2.Id
        ];

        System.assertEquals(ts.getTime(), r1.AccountsReceivableExchangeTimestamp__c,
            'Exchange timestamp (ms) must come from metadata.msgTimestamp');
        // LastSync зберігається як Datetime, створений із ms epoch
        System.assertNotEquals(null, r1.AccountsReceivableLastSync__c);

        System.assertEquals(120.5, r1.Balance__c);
        System.assertEquals(20.5,  r1.PastDueDebt__c);
        System.assertEquals(10,    r1.PastDueDebt15More__c);
        System.assertEquals(5,     r1.GroupPastDueDebt__c);
        System.assertEquals(2,     r1.GroupPastDueDebt15More__c);
        System.assertEquals(due1.date(), r1.BlockDate__c);
        System.assertEquals(11.1,  r1.CurrentMonthReceipts__c);
        System.assertEquals(true,  r1.StopListRisk__c);
        System.assertEquals(null,  r1.PermissionDate__c);
        System.assertEquals(1000,  r1.PermittedProductionAmount__c);
        System.assertEquals(500,   r1.PermittedShipmentAmount__c);
        System.assertEquals('Hold credit', r1.PermissionComment__c);
        System.assertEquals('40',  r1.DealingStatus__c, 'toBlock=true → DealingStatus__c must be 40');

        System.assertEquals(300,   r2.Balance__c);
        System.assertEquals(0,     r2.PastDueDebt__c);
        System.assertEquals(0,     r2.PastDueDebt15More__c);
        System.assertEquals(0,     r2.GroupPastDueDebt__c);
        System.assertEquals(0,     r2.GroupPastDueDebt15More__c);
        System.assertEquals(null,  r2.BlockDate__c);
        System.assertEquals(77.77, r2.CurrentMonthReceipts__c);
        System.assertEquals(false, r2.StopListRisk__c);
        System.assertEquals(perm2.date(), r2.PermissionDate__c);
        System.assertEquals(222,   r2.PermittedProductionAmount__c);
        System.assertEquals(333,   r2.PermittedShipmentAmount__c);
        System.assertEquals('OK',  r2.PermissionComment__c);
        System.assertEquals('30',  r2.DealingStatus__c);
    }
}