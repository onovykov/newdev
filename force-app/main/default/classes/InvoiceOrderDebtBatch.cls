// InvoiceOrderDebtBatch.cls
// Перерахунок зведених боргів без повного delete: upsert + селективне видалення
public without sharing class InvoiceOrderDebtBatch
    implements Database.Batchable<SObject>, Database.Stateful {

    // Backward-compatible no-op constructors (for callers that still pass message lists)
    public InvoiceOrderDebtBatch() {
        // nothing to init
    }
    public InvoiceOrderDebtBatch(List<ERPMessageParser.InvoiceOrderDebtMessageData> legacyMessages) {
        // kept for backward compatibility; not used by current logic
    }

    // Вмикаємо upsert за зовнішнім ключем CompositeKey__c (Text, Unique, External Id)
    private static final Boolean USE_COMPOSITE_EXTERNAL_ID = true;

    // --- BATCHABLE ---

    public Database.QueryLocator start(Database.BatchableContext bc) {
        // Мінімальний скоп: вся робота робиться у finish()
        return Database.getQueryLocator('SELECT Id FROM InvoiceOrderDebt__c LIMIT 1');
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        // Порожньо: зведення перерахуємо у finish єдиним проходом
    }

    public void finish(Database.BatchableContext bc) {
        rebuildSummaries();
    }

    // --- ЛОГІКА ПЕРЕРАХУНКУ ---

    private static void rebuildSummaries() {
        // 1) Total Debt
        Map<String, InvoiceDebtSummary__c> newByKey = new Map<String, InvoiceDebtSummary__c>();

        for (AggregateResult ar : [
            SELECT
                Account__c acc,
                PortalUser__c pu,
                CurrencyIsoCode ccy,
                SUM(NetAmount__c) sumAmt
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

        // 2) Overdue Debt
        for (AggregateResult ar : [
            SELECT
                Account__c acc,
                PortalUser__c pu,
                CurrencyIsoCode ccy,
                SUM(NetAmount__c) sumAmt
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

        // 3) Поточні підсумки
        Map<String, InvoiceDebtSummary__c> oldByKey = new Map<String, InvoiceDebtSummary__c>();
        for (InvoiceDebtSummary__c oldRec : [
            SELECT Id, CompositeKey__c
            FROM InvoiceDebtSummary__c
        ]) {
            oldByKey.put(oldRec.CompositeKey__c, oldRec);
        }

        // 4) Upsert нових
        if (!USE_COMPOSITE_EXTERNAL_ID) {
            // Без зовн. ключа — проставляємо Id, щоб upsert перетворився на update
            for (String k : newByKey.keySet()) {
                if (oldByKey.containsKey(k)) {
                    newByKey.get(k).Id = oldByKey.get(k).Id;
                }
            }
            upsert new List<InvoiceDebtSummary__c>(newByKey.values()); // за Id
        } else {
            // Рекомендовано: upsert за External Id CompositeKey__c
            upsert new List<InvoiceDebtSummary__c>(newByKey.values()) InvoiceDebtSummary__c.CompositeKey__c;
        }

        // 5) Видалення тільки «зайвих» (яких вже немає у newByKey)
        List<InvoiceDebtSummary__c> toDelete = new List<InvoiceDebtSummary__c>();
        for (String k : oldByKey.keySet()) {
            if (!newByKey.containsKey(k)) {
                toDelete.add(oldByKey.get(k));
            }
        }
        safeDeleteChunks(toDelete, 200);
    }

    // --- ХЕЛПЕРИ ---

    private static String buildKey(Id acc, Id pu, String ccy, String debtType) {
        // null-safe
        String accStr = acc == null ? '' : String.valueOf(acc);
        String puStr  = pu  == null ? '' : String.valueOf(pu);
        String ccyStr = ccy == null ? '' : ccy;
        String dtStr  = debtType == null ? '' : debtType;
        return accStr + '|' + puStr + '|' + ccyStr + '|' + dtStr;
    }

    // Часткове видалення порціями
    private static void safeDeleteChunks(List<InvoiceDebtSummary__c> recs, Integer chunkSize) {
        if (recs == null || recs.isEmpty()) return;

        Integer size = Math.max(1, chunkSize);
        Integer n = recs.size();

        for (Integer i = 0; i < n; i += size) {
            Integer toIdx = Math.min(i + size, n);

            // Ручне формування зрізу, щоб не використовувати
            List<InvoiceDebtSummary__c> slice = new List<InvoiceDebtSummary__c>();
            for (Integer j = i; j < toIdx; j++) {
                slice.add(recs[j]);
            }

            Database.DeleteResult[] results = Database.delete(slice, /*allOrNone*/ false);
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