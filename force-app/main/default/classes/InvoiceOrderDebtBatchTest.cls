@IsTest(SeeAllData=false)
private class InvoiceOrderDebtBatchTest {

    @isTest
    static void testProcessMessage_basicSmoke() {
        // minimally valid JSON
        String requestBody = '{\"Metadata\":{\"MsgType\":\"ERP-SF_Debit\",\"MsgTypeVersion\":0,\"MsgTimestamp\":\"2023-09-25T22:03:40.0652227+03:00\",\"PartNumber\":1,\"TotalParts\":1},\"Data\":[]}';
        ERPMessageParser.ErpToSfMessage_Debit parsed =
            (ERPMessageParser.ErpToSfMessage_Debit) JSON.deserialize(requestBody, ERPMessageParser.ErpToSfMessage_Debit.class);

        Test.startTest();
        ERPMessageHandlerDebit.MessageProcessingResult res =
            ERPMessageHandlerDebit.ProcessMessage(parsed, requestBody);
        Test.stopTest();

        System.assertEquals('ERP-SF_Debit', res.MessageType, 'MsgType should pass through');
    }

    @isTest
    static void testInvoiceOrderDebtBatch_endToEnd() {
        // Accounts
        Account acc = new Account(Name = 'Main Account', ID_ERP__c = '39');
        insert acc;

        Account internalAcc = new Account(Name = 'Internal Account', ID_ERP__c = '21833');
        insert internalAcc;

        // Pricebook (standard)
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;

        // Order (ВАЖЛИВО: виставляємо ID_ERP__c, який батч мапить з UNDOC_ORDER)
        Order ord = new Order(
            Name = 'Test Order',
            AccountId = acc.Id,
            Status = 'Draft',
            EffectiveDate = Date.today(),
            Pricebook2Id = standardPricebook.Id
        );
        insert ord;
        // Якщо поле custom і writeable — краще одразу перед insert; якщо ні — робимо update:
        ord.ID_ERP__c = '22061972';
        update ord;

        // PortalUser__c (кастомний об'єкт) + Contact, який на нього дивиться
        PortalUser__c portalUser = new PortalUser__c(Name = acc.Name);
        insert portalUser;

        Contact contact = new Contact(
            LastName = 'Test Contact',
            AccountId = acc.Id,
            PortalUser__c = portalUser.Id,
            MailingCountry = 'Ukraine'
        );
        insert contact;

        // Дані для батча
        ERPMessageParser.InvoiceOrderDebtMessageData rec = new ERPMessageParser.InvoiceOrderDebtMessageData();
        rec.ORG         = '39';
        rec.ORG_K       = '21833';
        rec.ORG_K_NAME  = 'Internal Account';
        rec.UNDOC_ORDER = '22061972';
        rec.NDM_INVOCE  = 'INV-001';
        rec.DT_OUT      = -1000.0;
        rec.NET_AMNT    = 900.0;
        rec.VAT_AMNT    = 100.0;
        rec.DAYS        = 15;
        rec.DUE_DATE    = '2023-12-15T00:00:00';
        rec.DDM         = '2023-12-01T00:00:00';
        rec.VAL         = 'USD'; // Переконайся, що USD валідна в org
        rec.Contract    = 'CONTRACT-123';

        List<ERPMessageParser.InvoiceOrderDebtMessageData> data = new List<ERPMessageParser.InvoiceOrderDebtMessageData>{ rec };

        Test.startTest();
        Database.executeBatch(new InvoiceOrderDebtBatch(data), 1);
        Test.stopTest();

        // Перевіряємо вставлену заборгованість
        List<InvoiceOrderDebt__c> invoices = [
            SELECT Id, Name, Account__c, InternalAccount__c, Order__c, NetAmount__c, PortalUser__c, CurrencyIsoCode, Contract__c, DaysOverdue__c
            FROM InvoiceOrderDebt__c
        ];
        System.assertEquals(1, invoices.size(), 'Expected one InvoiceOrderDebt__c');
        InvoiceOrderDebt__c inv = invoices[0];
        System.assertEquals('INV-001', inv.Name);
        System.assertEquals(acc.Id, inv.Account__c);
        System.assertEquals(internalAcc.Id, inv.InternalAccount__c);
        System.assertEquals(ord.Id, inv.Order__c, 'Order__c should be linked via ID_ERP__c mapping');
        System.assertEquals(portalUser.Id, inv.PortalUser__c, 'PortalUser__c should be mapped from Contact');
        System.assertEquals('USD', inv.CurrencyIsoCode);
        System.assertEquals('CONTRACT-123', inv.Contract__c);
        System.assertEquals(15, inv.DaysOverdue__c);

        // Перевіряємо підсумкові таблиці (finish())
        // AccountDebtSum__c: очікуємо два записи (Overdue та Total), або мінімум наявність обох типів.
        List<AccountDebtSum__c> debtSums = [
            SELECT Id, DebtType__c, Account__c, CurrencyIsoCode, SumDebt__c
            FROM AccountDebtSum__c
            WHERE Account__c = :acc.Id
        ];
        System.assert(debtSums.size() > 0, 'AccountDebtSum__c should be created');
        Set<String> adsTypes = new Set<String>();
        for (AccountDebtSum__c d : debtSums) adsTypes.add(d.DebtType__c);
        System.assert(adsTypes.contains('Summary Overdue Debt'), 'Expect Summary Overdue Debt row');
        System.assert(adsTypes.contains('Summary Total Debt'), 'Expect Summary Total Debt row');

        // InvoiceDebtSummary__c: Total Debt та Overdue Debt по PortalUser/Account/Currency
        List<InvoiceDebtSummary__c> summaries = [
            SELECT Id, DebtType__c, Account__c, PortalUser__c, CurrencyIsoCode, SumDebt__c
            FROM InvoiceDebtSummary__c
            WHERE Account__c = :acc.Id AND PortalUser__c = :portalUser.Id
        ];
        System.assert(summaries.size() > 0, 'InvoiceDebtSummary__c should be created');
        Set<String> idsTypes = new Set<String>();
        for (InvoiceDebtSummary__c s : summaries) idsTypes.add(s.DebtType__c);
        System.assert(idsTypes.contains('Total Debt'),   'Expect Total Debt summary');
        System.assert(idsTypes.contains('Overdue Debt'), 'Expect Overdue Debt summary');
    }
}