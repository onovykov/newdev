public without sharing class InvoiceOrderDebtBatch
        implements Database.Batchable<ERPMessageParser.InvoiceOrderDebtMessageData>, Database.Stateful {

    // ========================
    // поля для логування
    // ========================
    private Integer insertedCount = 0;
    private Integer errorCount    = 0;
    private List<String> errorMessages = new List<String>();
    private List<ERPMessageParser.InvoiceOrderDebtMessageData> source;
    private DateTime batchStartTime;
    private String batchId;
    private List<InvoiceOrderDebt__c> failedRecords = new List<InvoiceOrderDebt__c>();
    private Set<String> missingAccounts = new Set<String>();

    // для нового перерахунку
    private static final Boolean USE_COMPOSITE_EXTERNAL_ID = true;

    public InvoiceOrderDebtBatch(List<ERPMessageParser.InvoiceOrderDebtMessageData> invoiceOrderDebts) {
        source = invoiceOrderDebts;
    }

    // ========================
    // BATCH: start
    // ========================
    public List<ERPMessageParser.InvoiceOrderDebtMessageData> start(Database.BatchableContext bc) {
        batchStartTime = System.now();
        return source;
    }

    // ========================
    // BATCH: execute
    // створюємо самі InvoiceOrderDebt__c
    // ========================
    public void execute(Database.BatchableContext bc, List<ERPMessageParser.InvoiceOrderDebtMessageData> scope) {
        System.debug('InvoiceOrderDebtBatch scope: ' + scope);

        List<InvoiceOrderDebt__c> invoicesToInsert = new List<InvoiceOrderDebt__c>();

        // підтягуємо все, як у тебе було
        Map<String, Id> accidErpToId = new Map<String,Id>();
        Map<String, Id> ordidErpToId = new Map<String,Id>();
        Map<Id, Id> accountToPortalUserMap = new Map<Id, Id>();

        // тут у тебе було "всі акаунти" — я залишу як є, щоб не міняти твою логіку
        for (Account a : [SELECT Id, ID_ERP__c FROM Account]) {
            accidErpToId.put(a.ID_ERP__c, a.Id);
        }
        for (Order o : [SELECT Id, ID_ERP__c FROM Order]) {
            ordidErpToId.put(o.ID_ERP__c, o.Id);
        }
        for (Contact c : [SELECT AccountId, PortalUser__c FROM Contact WHERE PortalUser__c != NULL]) {
            accountToPortalUserMap.put(c.AccountId, c.PortalUser__c);
        }

        for (ERPMessageParser.InvoiceOrderDebtMessageData invoice : scope) {

            InvoiceOrderDebt__c inv = new InvoiceOrderDebt__c();
            inv.Name        = invoice.NDM_INVOCE;
            inv.ITENumber__c= invoice.NDM_INVOCE;

            // ===== головний Account (ORG) =====
            if (invoice.ORG != null && accidErpToId.containsKey(invoice.ORG)) {
                inv.Account__c = accidErpToId.get(invoice.ORG);
            } else {
                // РАНІШЕ: missingAccounts.add(...) і continue;
                // ТЕПЕР: створюємо, щоб запис НЕ скіпався
                if (invoice.ORG != null) {
                    Account newAcc = new Account();
                    newAcc.Name      = (invoice.ORG_NAME != null ? invoice.ORG_NAME : invoice.ORG);
                    newAcc.ID_ERP__c = invoice.ORG;
                    insert newAcc;
                    accidErpToId.put(invoice.ORG, newAcc.Id);
                    inv.Account__c = newAcc.Id;
                } else {
                    // якщо взагалі немає ORG — тоді вже не запишемо
                    missingAccounts.add('NULL_ORG');
                    continue;
                }
            }

            // ===== internal Account (ORG_K) =====
            if (invoice.ORG_K != null && accidErpToId.containsKey(invoice.ORG_K)) {
                inv.InternalAccount__c = accidErpToId.get(invoice.ORG_K);
            } else if (invoice.ORG_K != null) {
                Account newInternalAcc = new Account();
                newInternalAcc.Name      = invoice.ORG_K_NAME;
                newInternalAcc.ID_ERP__c = invoice.ORG_K;
                insert newInternalAcc;
                System.debug('Created internal Account: ' + newInternalAcc);
                accidErpToId.put(invoice.ORG_K, newInternalAcc.Id);
                inv.InternalAccount__c = newInternalAcc.Id;
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
            if (inv.Account__c != null && accountToPortalUserMap.containsKey(inv.Account__c)) {
                inv.PortalUser__c = accountToPortalUserMap.get(inv.Account__c);
            }

            invoicesToInsert.add(inv);
            System.debug('Prepared InvoiceOrderDebt__c: ' + inv);
        }

        batchId = bc.getJobId();

        try {
            List<Database.SaveResult> results = Database.insert(invoicesToInsert, false);
            for (Integer i = 0; i < results.size(); i++) {
                if (!results[i].isSuccess()) {
                    errorCount++;
                    errorMessages.add(results[i].getErrors()[0].getMessage());
                    failedRecords.add(invoicesToInsert[i]);
                    System.debug(errorMessages);
                    System.debug(failedRecords);
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
    // тут уже не робимо "delete all and insert"
    // а робимо твій розумний upsert + селективне delete
    // ========================
    public void finish(Database.BatchableContext bc) {
        rebuildSummaries();

        // лишаємо твою розсилку
        String subject;
        String body;
        if (errorCount > 0) {
            subject = 'Error occurred during Invoice Order Debt insert';
            body = '<html><body>';
            body += '<p>An error occurred while inserting Invoice Order Debts in a batch job.</p>';
            body += '<p><strong>Total records:</strong> ' + source.size() + '</p>';
            body += '<p><strong>Inserted Invoice Order Debts:</strong> ' + insertedCount + '</p>';
            body += '<p><strong>Errors:</strong> ' + errorCount + '</p>';
            body += '<table style="border: 1px solid black; border-collapse: collapse;"><tr><th>Error</th><th>Error Message</th><th>Record Information</th></tr>';
            for (Integer i = 0; i < errorMessages.size(); i++) {
                body += '<tr>';
                body += '<td style="border: 1px solid black; padding: 5px;">' + (i+1) + '</td>';
                body += '<td style="border: 1px solid black; padding: 5px;">' + errorMessages[i] + '</td>';
                body += '<td style="border: 1px solid black; padding: 5px;">';
                if (i < failedRecords.size()) {
                    body += '<strong>ITENumber__c:</strong> ' + failedRecords[i].ITENumber__c + '<br/>';
                    body += '<strong>Order ID:</strong> ' + failedRecords[i].Order__c + '<br/>';
                    body += '<strong>Account ID:</strong> ' + failedRecords[i].Account__c + '<br/>';
                    body += '<strong>Outstanding Debt:</strong> ' + failedRecords[i].OutstandingDebt__c + '<br/>';
                    body += '<strong>Due Date:</strong> ' + failedRecords[i].DueDate__c + '<br/>';
                }
                body += '</td></tr>';
            }
            body += '<p><strong>Records without account (created or skipped): </strong> ' + missingAccounts.size() +'</p>';
            Integer i = 0;
            for (String accORG : missingAccounts) {
                body += '<tr>';
                body += '<td style="border: 1px solid black; padding: 5px;">' + (i+1) + '</td>';
                body += '<td style="border: 1px solid black; padding: 5px;">' +'ORG: ' + accORG + '</td>';
                body += '</td></tr>';
                i++;
            }
            body += '</table>';
            body += '<p><strong>Batch Job Id:</strong> ' + bc.getJobId() + '</p>';
            body += '<p><strong>Batch Start Time:</strong> ' + batchStartTime  + '</p>';
            body += '<p><strong>Batch End Time:</strong> ' + System.now() + '</p>';
            body += '</body></html>';
        } else {
            subject = 'Invoice Order Debt insert completed successfully';
            body = '<html><body><p>All Invoice Order Debts have been inserted successfully in a batch job.</p>';
            body += '<p><strong>Inserted Invoice Order Debts:</strong> ' + insertedCount + '</p>';
            body += '<p><strong>Batch Job Id:</strong> ' + bc.getJobId() + '</p>';
            body += '<p><strong>Batch Start Time:</strong> ' + batchStartTime  + '</p>';
            body += '<p><strong>Batch End Time:</strong> ' + System.now() + '</p>';
            body += '<p><strong>Records without account (initially): </strong> ' + missingAccounts.size() +'</p>';
            body += '</body></html>';
        }

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[] { 'a.d.tsyganova@gmail.com' });
        mail.setSubject(subject);
        mail.setHtmlBody(body);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }

    // =====================================================
    // НОВА ЧАСТИНА: перерахунок summary з upsert + селективне delete
    // =====================================================
    private static void rebuildSummaries() {
        // 1) збираємо нові
        Map<String, InvoiceDebtSummary__c> newByKey = new Map<String, InvoiceDebtSummary__c>();

        // Total Debt
        for (AggregateResult ar : [
                SELECT Account__c acc, PortalUser__c pu, CurrencyIsoCode ccy, SUM(NetAmount__c) sumAmt
                FROM InvoiceOrderDebt__c
                GROUP BY Account__c, PortalUser__c, CurrencyIsoCode
        ]) {
            InvoiceDebtSummary__c rec = new InvoiceDebtSummary__c();
            rec.Account__c      = (Id)     ar.get('acc');
            rec.PortalUser__c   = (Id)     ar.get('pu');
            rec.CurrencyIsoCode = (String) ar.get('ccy');
            rec.DebtType__c     = 'Total Debt';
            rec.SumDebt__c      = (Decimal) ar.get('sumAmt');
            rec.CompositeKey__c = buildKey(rec.Account__c, rec.PortalUser__c, rec.CurrencyIsoCode, rec.DebtType__c);
            newByKey.put(rec.CompositeKey__c, rec);
        }

        // Overdue Debt
        for (AggregateResult ar : [
                SELECT Account__c acc, PortalUser__c pu, CurrencyIsoCode ccy, SUM(NetAmount__c) sumAmt
                FROM InvoiceOrderDebt__c
                WHERE DaysOverdue__c > 0
                GROUP BY Account__c, PortalUser__c, CurrencyIsoCode
        ]) {
            InvoiceDebtSummary__c rec = new InvoiceDebtSummary__c();
            rec.Account__c      = (Id)     ar.get('acc');
            rec.PortalUser__c   = (Id)     ar.get('pu');
            rec.CurrencyIsoCode = (String) ar.get('ccy');
            rec.DebtType__c     = 'Overdue Debt';
            rec.SumDebt__c      = (Decimal) ar.get('sumAmt');
            rec.CompositeKey__c = buildKey(rec.Account__c, rec.PortalUser__c, rec.CurrencyIsoCode, rec.DebtType__c);
            newByKey.put(rec.CompositeKey__c, rec);
        }

        // 2) що було
        Map<String, InvoiceDebtSummary__c> oldByKey = new Map<String, InvoiceDebtSummary__c>();
        for (InvoiceDebtSummary__c oldRec : [
                SELECT Id, CompositeKey__c FROM InvoiceDebtSummary__c
        ]) {
            oldByKey.put(oldRec.CompositeKey__c, oldRec);
        }

        // 3) upsert
        if (!USE_COMPOSITE_EXTERNAL_ID) {
            // upsert за Id
            for (String k : newByKey.keySet()) {
                if (oldByKey.containsKey(k)) {
                    newByKey.get(k).Id = oldByKey.get(k).Id;
                }
            }
            upsert new List<InvoiceDebtSummary__c>(newByKey.values());
        } else {
            // upsert за зовнішнім CompositeKey__c
            upsert new List<InvoiceDebtSummary__c>(newByKey.values()) InvoiceDebtSummary__c.CompositeKey__c;
        }

        // 4) видаляємо тільки зайве
        List<InvoiceDebtSummary__c> toDelete = new List<InvoiceDebtSummary__c>();
        for (String k : oldByKey.keySet()) {
            if (!newByKey.containsKey(k)) {
                toDelete.add(oldByKey.get(k));
            }
        }
        safeDeleteChunks(toDelete, 200);
    }

    private static String buildKey(Id acc, Id pu, String ccy, String debtType) {
        String accStr = acc == null ? '' : String.valueOf(acc);
        String puStr  = pu  == null ? '' : String.valueOf(pu);
        String ccyStr = ccy == null ? '' : ccy;
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