@IsTest
private class InvoiceOrderDebtBatchTest {

    @TestSetup
    static void setupData() {
        insert new Account(Name = 'Main Account', ID_ERP__c = '39');
        insert new Account(Name = 'Internal Account', ID_ERP__c = '21833');

        Pricebook2 pb = new Pricebook2(Id = Test.getStandardPricebookId(), IsActive = true);
        update pb;

        Account acc = [SELECT Id FROM Account WHERE ID_ERP__c = '39' LIMIT 1];
        insert new Order(
                Name = 'Test Order',
                AccountId = acc.Id,
                Status = 'Draft',
                EffectiveDate = Date.today(),
                Pricebook2Id = pb.Id,
                ID_ERP__c = '22061972'
        );

        PortalUser__c pu = new PortalUser__c(Name = 'PU for 39');
        insert pu;
        insert new Contact(LastName = 'Test Contact', AccountId = acc.Id, PortalUser__c = pu.Id);
    }

    // ========== 1. Хендлер викликає батч ==========
    @IsTest
    static void testProcessMessage_runsBatchAndCreatesDebt() {
        String requestBody =
                '{'+
                        '"Metadata":{"MsgType":"ERP-SF_Debit","MsgTypeVersion":0,"MsgTimestamp":"2025-11-03T12:00:00+03:00","PartNumber":1,"TotalParts":1},'+
                        '"Data":[{' +
                        '"ORG":"39",' +
                        '"ORG_NAME":"\\"AYDINBORUEND.AS\\"",' +
                        '"ORG_K":"21833",' +
                        '"ORG_K_NAME":"InterpipeM.EFZE",' +
                        '"UNDOC_ORDER":"22061972",' +
                        '"NDM_INVOCE":"INV-HANDLER",' +
                        '"DDM":"0001-01-01T00:00:00",' +
                        '"DUE_DATE":"0001-01-01T00:00:00",' +
                        '"DAYS":0,' +
                        '"VAL":"USD",' +
                        '"NET_AMNT":150.0,' +
                        '"VAT_AMNT":30.0,' +
                        '"DT_OUT":-150.0' +
                        '}]' +
                        '}';

        ERPMessageParser.ErpToSfMessage_Debit parsed =
                (ERPMessageParser.ErpToSfMessage_Debit)JSON.deserialize(
                        requestBody,
                        ERPMessageParser.ErpToSfMessage_Debit.class
                );

        Test.startTest();
        ERPMessageHandlerDebit.MessageProcessingResult res =
                ERPMessageHandlerDebit.ProcessMessage(parsed, requestBody);
        Test.stopTest();

        System.assertEquals('ERP-SF_Debit', res.MessageType);

        List<InvoiceOrderDebt__c> created = [
                SELECT Id, Name FROM InvoiceOrderDebt__c WHERE Name = 'INV-HANDLER'
        ];
        System.assertEquals(1, created.size(), 'Handler must lead to created debt');
    }

    // ========== 2. Батч створює борг і summary ==========
    @IsTest
    static void testBatch_createsDebt_andSummaries_withCompositeKey() {
        ERPMessageParser.InvoiceOrderDebtMessageData m = new ERPMessageParser.InvoiceOrderDebtMessageData();
        m.ORG         = '39';
        m.ORG_K       = '21833';
        m.ORG_K_NAME  = 'Internal Account';
        m.UNDOC_ORDER = '22061972';
        m.NDM_INVOCE  = 'INV-001';
        m.DT_OUT      = -1000;
        m.NET_AMNT    = 900;
        m.VAT_AMNT    = 100;
        m.DAYS        = 10;
        m.DUE_DATE    = '2025-11-10T00:00:00';
        m.DDM         = '2025-11-01T00:00:00';
        m.VAL         = 'USD';
        m.Contract    = 'C-123';

        Test.startTest();
        Database.executeBatch(new InvoiceOrderDebtBatch(new List<ERPMessageParser.InvoiceOrderDebtMessageData>{ m }), 1);
        Test.stopTest();

        InvoiceOrderDebt__c inv = [
                SELECT Id, Name, Account__c, InternalAccount__c, Order__c, NetAmount__c
                FROM InvoiceOrderDebt__c
                WHERE Name = 'INV-001'
                LIMIT 1
        ];
        System.assertEquals(900, inv.NetAmount__c);
        System.assertNotEquals(null, inv.Account__c);

        List<InvoiceDebtSummary__c> summaries = [
                SELECT Id, Account__c, DebtType__c, SumDebt__c, CurrencyIsoCode, CompositeKey__c
                FROM InvoiceDebtSummary__c
        ];
        System.assert(summaries.size() > 0, 'Summary must be rebuilt');

        Boolean foundTotal = false;
        for (InvoiceDebtSummary__c s : summaries) {
            if (s.Account__c == inv.Account__c) {
                foundTotal = true;
                System.assertNotEquals(null, s.CompositeKey__c, 'CompositeKey__c must be set by batch');
            }
        }
        System.assert(foundTotal, 'Summary for our account must exist');
    }

    // ========== 3. ORG немає в SF → запис скіпається ==========
    @IsTest
    static void testBatch_skipsMissingAccount() {
        ERPMessageParser.InvoiceOrderDebtMessageData m = new ERPMessageParser.InvoiceOrderDebtMessageData();
        m.ORG        = '99999';
        m.ORG_NAME   = 'Created from ERP';
        m.NDM_INVOCE = 'INV-NEW-ACC';
        m.NET_AMNT   = 50;
        m.VAL        = 'USD';

        Test.startTest();
        Database.executeBatch(new InvoiceOrderDebtBatch(new List<ERPMessageParser.InvoiceOrderDebtMessageData>{ m }), 1);
        Test.stopTest();

        List<InvoiceOrderDebt__c> created = [
                SELECT Id FROM InvoiceOrderDebt__c WHERE Name = 'INV-NEW-ACC'
        ];
        System.assertEquals(0, created.size(), 'Invoice must be skipped when Account not found');
    }

    // ========== 4. finish(): зайвий summary видаляється ==========
    @IsTest
    static void testFinish_deletesObsoleteSummary_byCompositeKey() {
        Account a = [SELECT Id FROM Account WHERE ID_ERP__c = '39' LIMIT 1];
        InvoiceDebtSummary__c oldSummary = new InvoiceDebtSummary__c(
                Account__c      = a.Id,
                DebtType__c     = 'Total Debt',
                SumDebt__c      = 999,
                CurrencyIsoCode = 'USD',
                CompositeKey__c = 'OBSOLETE|KEY'
        );
        insert oldSummary;

        ERPMessageParser.InvoiceOrderDebtMessageData m = new ERPMessageParser.InvoiceOrderDebtMessageData();
        m.ORG        = '39';
        m.NDM_INVOCE = 'INV-FOR-REBUILD';
        m.NET_AMNT   = 100;
        m.VAL        = 'USD';

        Test.startTest();
        Database.executeBatch(new InvoiceOrderDebtBatch(new List<ERPMessageParser.InvoiceOrderDebtMessageData>{ m }), 1);
        Test.stopTest();

        List<InvoiceDebtSummary__c> stillThere = [
                SELECT Id FROM InvoiceDebtSummary__c WHERE CompositeKey__c = 'OBSOLETE|KEY'
        ];
        System.assertEquals(0, stillThere.size(), 'Obsolete summary must be deleted in finish()');
    }

    // ========== 5. generateResponseBody — з помилкою і без ==========
    @IsTest
    static void testGenerateResponseBody() {
        Map<Integer, String> statusMap = new Map<Integer, String>{
                200 => 'OK',
                500 => 'ERROR'
        };
        ERPMessageHandlerDebit.MessageProcessingResult mp = new ERPMessageHandlerDebit.MessageProcessingResult();
        mp.MessageType = 'ERP-SF_Debit';
        mp.jobStatus   = 'Batch job 123 started';

        Blob ok = ERPMessageHandlerDebit.generateResponseBody(statusMap, 200, null, mp);
        System.assert(ok.toString().contains('ERP-SF_Debit'));
        System.assert(ok.toString().contains('Batch job 123 started'));

        Blob err = ERPMessageHandlerDebit.generateResponseBody(statusMap, 500, 'Bad things', mp);
        System.assert(err.toString().contains('Bad things'));
    }

    // ========== 6. finish(): успішна гілка ==========
    @IsTest
    static void testFinish_successBranch() {
        ERPMessageParser.InvoiceOrderDebtMessageData msg = new ERPMessageParser.InvoiceOrderDebtMessageData();
        msg.ORG        = '39';
        msg.NDM_INVOCE = 'INV-SUCCESS';
        msg.NET_AMNT   = 100;
        msg.VAL        = 'USD';

        Test.startTest();
        Database.executeBatch(new InvoiceOrderDebtBatch(
                new List<ERPMessageParser.InvoiceOrderDebtMessageData>{ msg }
        ), 1);
        Test.stopTest();

        InvoiceOrderDebt__c inv = [
                SELECT Id, Name FROM InvoiceOrderDebt__c WHERE Name = 'INV-SUCCESS' LIMIT 1
        ];
        System.assertNotEquals(null, inv.Id, 'Invoice must be inserted in success branch');
    }

    // ========== 7. finish(): гілка з помилкою ==========
    @IsTest
    static void testFinish_errorBranch() {
        ERPMessageParser.InvoiceOrderDebtMessageData bad = new ERPMessageParser.InvoiceOrderDebtMessageData();
        bad.ORG        = '39';
        bad.NDM_INVOCE = 'INV-ERROR';
        bad.NET_AMNT   = 50;
        bad.VAL        = 'XYZ'; // невалідна валюта → DML error

        Test.startTest();
        Database.executeBatch(new InvoiceOrderDebtBatch(
                new List<ERPMessageParser.InvoiceOrderDebtMessageData>{ bad }
        ), 1);
        Test.stopTest();

        List<InvoiceOrderDebt__c> failed = [
                SELECT Id FROM InvoiceOrderDebt__c WHERE Name = 'INV-ERROR'
        ];
        System.assertEquals(0, failed.size(), 'Bad invoice should not be inserted');
    }

    //--- Тест на дублікати CompositeKey__c
    @IsTest
    static void testRebuildSummaries_removesOrphanAndRebuildsCorrectly() {

        // === GIVEN: існує orphan summary (якого не буде в target state)
        Account a = [SELECT Id FROM Account WHERE ID_ERP__c = '39' LIMIT 1];

        InvoiceDebtSummary__c orphan = new InvoiceDebtSummary__c(
                Account__c      = a.Id,
                DebtType__c     = 'Total Debt',
                SumDebt__c      = 999,
                CurrencyIsoCode = 'USD',
                CompositeKey__c = 'ORPHAN|KEY'
        );
        insert orphan;

        // === AND: є реальний invoice, який створить правильний summary
        ERPMessageParser.InvoiceOrderDebtMessageData msg =
                new ERPMessageParser.InvoiceOrderDebtMessageData();

        msg.ORG        = '39';
        msg.NDM_INVOCE = 'INV-REBUILD';
        msg.NET_AMNT   = 500;
        msg.VAL        = 'USD';
        msg.DAYS       = 5;
        msg.DUE_DATE   = '2025-11-10T00:00:00';
        msg.DDM        = '2025-11-01T00:00:00';

        // === WHEN: запускаємо batch
        Test.startTest();
        Database.executeBatch(
                new InvoiceOrderDebtBatch(
                new List<ERPMessageParser.InvoiceOrderDebtMessageData>{ msg }
                ),
                1
        );
        Test.stopTest();

        // === THEN: orphan summary має бути видалений
        List<InvoiceDebtSummary__c> orphanCheck = [
                SELECT Id
                FROM InvoiceDebtSummary__c
                WHERE CompositeKey__c = 'ORPHAN|KEY'
        ];

        System.assertEquals(
                0,
                orphanCheck.size(),
                'Orphan summary must be removed during rebuild'
        );

        // === AND: правильний summary має бути створений
        List<InvoiceDebtSummary__c> summaries = [
                SELECT Id, Account__c, DebtType__c, SumDebt__c, CompositeKey__c
                FROM InvoiceDebtSummary__c
                WHERE Account__c = :a.Id
        ];

        System.assert(
                summaries.size() > 0,
                'At least one valid summary must be rebuilt'
        );

        Boolean foundValid = false;

        for (InvoiceDebtSummary__c s : summaries) {
                if (s.SumDebt__c == 500) {
                foundValid = true;
                System.assertNotEquals(
                        null,
                        s.CompositeKey__c,
                        'Rebuilt summary must have CompositeKey__c'
                );
                }
        }

        System.assert(
                foundValid,
                'Rebuilt summary must reflect aggregated invoice amount'
        );
    }  
}