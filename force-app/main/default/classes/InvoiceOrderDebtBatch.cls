public without sharing class InvoiceOrderDebtBatch
        implements Database.Batchable<ERPMessageParser.InvoiceOrderDebtMessageData>, Database.Stateful {

    private Integer insertedCount = 0;
    private Integer errorCount    = 0;
    private final List<String> errorMessages = new List<String>();
    private final List<ERPMessageParser.InvoiceOrderDebtMessageData> source;
    private final List<InvoiceOrderDebt__c> failedRecords = new List<InvoiceOrderDebt__c>();
    private final Set<String> missingAccounts = new Set<String>();

    public InvoiceOrderDebtBatch(List<ERPMessageParser.InvoiceOrderDebtMessageData> invoiceOrderDebts) {
        source = invoiceOrderDebts;
    }

    // ========================
    // BATCH: start
    // ========================
    public List<ERPMessageParser.InvoiceOrderDebtMessageData> start(Database.BatchableContext bc) {
        return source;
    }

    // ========================
    // BATCH: execute
    // ========================
    public void execute(Database.BatchableContext bc, List<ERPMessageParser.InvoiceOrderDebtMessageData> scope) {

        // Збираємо тільки потрібні ID з поточного scope
        Set<String> orgIds   = new Set<String>();
        Set<String> orderIds = new Set<String>();
        for (ERPMessageParser.InvoiceOrderDebtMessageData invoice : scope) {
            if (invoice.ORG        != null) orgIds.add(invoice.ORG);
            if (invoice.ORG_K      != null) orgIds.add(invoice.ORG_K);
            if (invoice.UNDOC_ORDER != null) orderIds.add(invoice.UNDOC_ORDER);
        }

        Map<String, Id> accidErpToId = new Map<String, Id>();
        Map<String, Id> ordidErpToId = new Map<String, Id>();
        Map<Id, Id> accountToPortalUserMap = new Map<Id, Id>();

        for (Account a : [SELECT Id, ID_ERP__c FROM Account WHERE ID_ERP__c IN :orgIds]) {
            accidErpToId.put(a.ID_ERP__c, a.Id);
        }
        for (Order o : [SELECT Id, ID_ERP__c FROM Order WHERE ID_ERP__c IN :orderIds]) {
            ordidErpToId.put(o.ID_ERP__c, o.Id);
        }
        for (Contact c : [SELECT AccountId, PortalUser__c FROM Contact
                          WHERE PortalUser__c != NULL AND AccountId IN :accidErpToId.values()]) {
            accountToPortalUserMap.put(c.AccountId, c.PortalUser__c);
        }

        List<InvoiceOrderDebt__c> invoicesToInsert = new List<InvoiceOrderDebt__c>();

        for (ERPMessageParser.InvoiceOrderDebtMessageData invoice : scope) {

            InvoiceOrderDebt__c inv = new InvoiceOrderDebt__c();
            inv.Name         = invoice.NDM_INVOCE;
            inv.ITENumber__c = invoice.NDM_INVOCE;

            // ===== головний Account (ORG) =====
            if (invoice.ORG != null && accidErpToId.containsKey(invoice.ORG)) {
                inv.Account__c = accidErpToId.get(invoice.ORG);
            } else {
                missingAccounts.add(invoice.ORG != null ? invoice.ORG : 'NULL_ORG');
                continue;
            }

            // ===== internal Account (ORG_K) =====
            if (invoice.ORG_K != null && accidErpToId.containsKey(invoice.ORG_K)) {
                inv.InternalAccount__c = accidErpToId.get(invoice.ORG_K);
            }

            // ===== Order =====
            if (invoice.UNDOC_ORDER != null && ordidErpToId.containsKey(invoice.UNDOC_ORDER)) {
                inv.Order__c = ordidErpToId.get(invoice.UNDOC_ORDER);
            }

            // ===== суми/дати =====
            inv.OutstandingDebt__c = invoice.DT_OUT;
            inv.NetAmount__c       = invoice.NET_AMNT;
            inv.VATAmount__c       = invoice.VAT_AMNT;
            inv.DaysOverdue__c     = invoice.DAYS;

            if (invoice.DUE_DATE != null && invoice.DUE_DATE != '0001-01-01T00:00:00') {
                inv.DueDate__c = Date.valueOf(invoice.DUE_DATE);
            }
            if (invoice.DDM != null && invoice.DDM != '0001-01-01T00:00:00') {
                inv.InvoiceDate__c = Date.valueOf(invoice.DDM);
            }

            inv.CurrencyIsoCode = invoice.VAL;
            inv.Contract__c     = invoice.Contract;

            // ===== Portal user =====
            if (accountToPortalUserMap.containsKey(inv.Account__c)) {
                inv.PortalUser__c = accountToPortalUserMap.get(inv.Account__c);
            }

            invoicesToInsert.add(inv);
        }

        try {
            List<Database.SaveResult> results = Database.insert(invoicesToInsert, false);
            for (Integer i = 0; i < results.size(); i++) {
                if (!results[i].isSuccess()) {
                    errorCount++;
                    errorMessages.add(results[i].getErrors()[0].getMessage());
                    failedRecords.add(invoicesToInsert[i]);
                } else {
                    insertedCount++;
                }
            }
        } catch (Exception e) {
            errorCount++;
            errorMessages.add(e.getMessage());
        }
    }

    // ========================
    // BATCH: finish
    // ========================
    public void finish(Database.BatchableContext bc) {
        System.debug(LoggingLevel.INFO,
            'InvoiceOrderDebtBatch finish — jobId=' + bc.getJobId() +
            ', inserted=' + insertedCount +
            ', errors=' + errorCount +
            ', skippedMissingAccount=' + missingAccounts.size());

        if (errorCount > 0) {
            System.debug(LoggingLevel.ERROR, 'InvoiceOrderDebtBatch errors: ' + errorMessages);
            System.debug(LoggingLevel.ERROR, 'InvoiceOrderDebtBatch failedRecords: ' + failedRecords);
        }
        if (!missingAccounts.isEmpty()) {
            System.debug(LoggingLevel.WARN, 'InvoiceOrderDebtBatch missing Accounts (skipped): ' + missingAccounts);
        }

        rebuildSummaries();
    }

    // ========================
    // перерахунок InvoiceDebtSummary__c
    // ========================
    private static void rebuildSummaries() {

        // ========================
        // 1️. Побудувати нові summaries (target state)
        // ========================
        Map<String, InvoiceDebtSummary__c> targetByKey =
            new Map<String, InvoiceDebtSummary__c>();

        // ---- Total Debt
        for (AggregateResult ar : [
            SELECT Account__c acc,
                PortalUser__c pu,
                CurrencyIsoCode ccy,
                SUM(NetAmount__c) sumAmt
            FROM InvoiceOrderDebt__c
            GROUP BY Account__c, PortalUser__c, CurrencyIsoCode
        ]) {

            InvoiceDebtSummary__c rec = new InvoiceDebtSummary__c();
            rec.Account__c      = (Id)      ar.get('acc');
            rec.PortalUser__c   = (Id)      ar.get('pu');
            rec.CurrencyIsoCode = (String)  ar.get('ccy');
            rec.DebtType__c     = 'Total Debt';
            rec.SumDebt__c      = (Decimal) ar.get('sumAmt');

            rec.CompositeKey__c =
                buildKey(rec.Account__c,
                        rec.PortalUser__c,
                        rec.CurrencyIsoCode,
                        rec.DebtType__c);

            targetByKey.put(rec.CompositeKey__c, rec);
        }

        // ---- Overdue Debt
        for (AggregateResult ar : [
            SELECT Account__c acc,
                PortalUser__c pu,
                CurrencyIsoCode ccy,
                SUM(NetAmount__c) sumAmt
            FROM InvoiceOrderDebt__c
            WHERE DaysOverdue__c > 0
            GROUP BY Account__c, PortalUser__c, CurrencyIsoCode
        ]) {

            InvoiceDebtSummary__c rec = new InvoiceDebtSummary__c();
            rec.Account__c      = (Id)      ar.get('acc');
            rec.PortalUser__c   = (Id)      ar.get('pu');
            rec.CurrencyIsoCode = (String)  ar.get('ccy');
            rec.DebtType__c     = 'Overdue Debt';
            rec.SumDebt__c      = (Decimal) ar.get('sumAmt');

            rec.CompositeKey__c =
                buildKey(rec.Account__c,
                        rec.PortalUser__c,
                        rec.CurrencyIsoCode,
                        rec.DebtType__c);

            targetByKey.put(rec.CompositeKey__c, rec);
        }

        // ========================
        // 2️. Зчитати всі наявні summaries
        // ========================
        Map<String, List<InvoiceDebtSummary__c>> existingGrouped =
            new Map<String, List<InvoiceDebtSummary__c>>();

        for (InvoiceDebtSummary__c r : [
            SELECT Id, CompositeKey__c
            FROM InvoiceDebtSummary__c
        ]) {
            if (!existingGrouped.containsKey(r.CompositeKey__c)) {
                existingGrouped.put(r.CompositeKey__c,
                                    new List<InvoiceDebtSummary__c>());
            }
            existingGrouped.get(r.CompositeKey__c).add(r);
        }

        // ========================
        // 3️. Self-healing: видалити дублікати
        // ========================
        List<InvoiceDebtSummary__c> duplicatesToDelete =
            new List<InvoiceDebtSummary__c>();

        for (String key : existingGrouped.keySet()) {
            List<InvoiceDebtSummary__c> recs = existingGrouped.get(key);
            if (recs.size() > 1) {
                // залишаємо перший запис
                for (Integer i = 1; i < recs.size(); i++) {
                    duplicatesToDelete.add(recs[i]);
                }
            }
        }

        safeDeleteChunks(duplicatesToDelete, 200);

        // ========================
        // 4️. Upsert target state (allOrNone = false)
        // ========================
        if (!targetByKey.isEmpty()) {

            Database.UpsertResult[] results =
                Database.upsert(
                    new List<InvoiceDebtSummary__c>(targetByKey.values()),
                    InvoiceDebtSummary__c.CompositeKey__c,
                    false
                );

            for (Database.UpsertResult r : results) {
                if (!r.isSuccess()) {
                    System.debug(LoggingLevel.ERROR,
                        'Summary upsert error: ' +
                        r.getErrors()[0].getMessage()
                    );
                }
            }
        }

        // ========================
        // 5️. Видалити "orphan summaries"
        // ========================

        List<InvoiceDebtSummary__c> toDelete =
            new List<InvoiceDebtSummary__c>();

        for (String key : existingGrouped.keySet()) {
            if (!targetByKey.containsKey(key)) {
                // після дедуплікації залишився максимум 1
                toDelete.add(existingGrouped.get(key)[0]);
            }
        }

        safeDeleteChunks(toDelete, 200);
    }

    private static String buildKey(Id acc, Id pu, String ccy, String debtType) {
        String accStr = acc      == null ? '' : String.valueOf(acc);
        String puStr  = pu       == null ? '' : String.valueOf(pu);
        String ccyStr = ccy      == null ? '' : ccy;
        String dtStr  = debtType == null ? '' : debtType;
        return accStr + '|' + puStr + '|' + ccyStr + '|' + dtStr;
    }

    private static void safeDeleteChunks(List<InvoiceDebtSummary__c> recs, Integer chunkSize) {
        if (recs == null || recs.isEmpty()) return;
        Integer size = Math.max(1, chunkSize);
        Integer n = recs.size();

        for (Integer i = 0; i < n; i += size) {
            Integer toIdx = Math.min(i + size, n);

            List<InvoiceDebtSummary__c> slice = new List<InvoiceDebtSummary__c>();
            for (Integer j = i; j < toIdx; j++) {
                slice.add(recs[j]);
            }

            Database.DeleteResult[] results = Database.delete(slice, false);
            for (Database.DeleteResult r : results) {
                if (!r.isSuccess()) {
                    for (Database.Error e : r.getErrors()) {
                        if (e.getStatusCode() != StatusCode.ENTITY_IS_DELETED) {
                            System.debug(LoggingLevel.WARN, 'Delete error: ' + e);
                        }
                    }
                }
            }
        }
    }
}