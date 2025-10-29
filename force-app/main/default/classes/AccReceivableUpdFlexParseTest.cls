@IsTest
private class AccReceivableUpdFlexParseTest {

    private static String iso(Datetime dt) {
        return dt == null ? null : dt.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
    }

    @IsTest
    static void should_Parse_Flexible_Types_From_Raw_JSON() {
        Account a1 = new Account(Name = 'Flex 1', ID_ERP__c = 'ERP-FLEX-1');
        Account a2 = new Account(Name = 'Flex 2', ID_ERP__c = 'ERP-FLEX-2');
        insert new List<Account>{ a1, a2 };

        Datetime ts   = Datetime.newInstance(2025, 3, 10, 9, 30, 0);
        Datetime due1 = Datetime.newInstance(2025, 3, 15, 0, 0, 0);
        Datetime perm2= Datetime.newInstance(2025, 4, 1, 0, 0, 0);

        String body =
        '{' +
          '"metadata": {"msgTimestamp": "' + iso(ts) + '"},' +     // ISO string
          '"data": {"items": [' +
             '{' +
               '"account":{"id":"ERP-FLEX-1"},' +
               '"balance":"120.5",' +                               // number as string
               '"pastDueDebt":"20.5",' +
               '"pastDueDebt15More":"10",' +
               '"groupPastDueDebt":"5",' +
               '"groupPastDueDebt15More":"2",' +
               '"dueDate":"' + iso(due1) + '",' +                   // ISO string
               '"receipts":"11.1",' +                               // string
               '"toBlock":"Y",' +                                   // string-boolean
               '"permissionDate":null,' +
               '"permittedProductionAmount":"1000",' +
               '"permittedShipmentAmount":"500",' +
               '"permissionComment":"Hold credit",' +
               '"status":"10"' +
             '},' +
             '{' +
               '"account":{"id":"ERP-FLEX-2"},' +
               '"balance":300,' +                                   // number
               '"pastDueDebt":0,' +
               '"pastDueDebt15More":"0",' +
               '"groupPastDueDebt":0,' +
               '"groupPastDueDebt15More":0,' +
               '"dueDate":null,' +
               '"receipts":77.77,' +
               '"toBlock":"N",' +                                   // string-boolean
               '"permissionDate": ' + perm2.getTime() + ',' +       // epoch ms (number)
               '"permittedProductionAmount":222,' +
               '"permittedShipmentAmount":333,' +
               '"permissionComment":"OK",' +
               '"status":"30"' +
             '}' +
          ']}}';

        Test.startTest();
        Database.executeBatch(new AccountsReceivableUpdate(body), 50);
        Test.stopTest();

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

        System.assertEquals(ts.getTime(), r1.AccountsReceivableExchangeTimestamp__c);
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
        System.assertEquals('40',  r1.DealingStatus__c);

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