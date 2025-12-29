global class OrderItemStandardMigrationBatch
    implements Database.Batchable<SObject>, Database.Stateful {

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id,
                   ProductStandard__c,
                   ProductStandard__r.FullName__c,
                   Standard__c,
                   StandardGroup__c
            FROM OrderItem
            WHERE ProductStandard__c != null
              //AND Standard__c = null
        ]);
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope) {

        List<OrderItem> items = (List<OrderItem>) scope;

        // 1. Collect normalized standards per item
        Map<Id, Set<String>> itemToStandards = new Map<Id, Set<String>>();
        Set<String> allNorms = new Set<String>();

        for (OrderItem oi : items) {
            if (oi.ProductStandard__r == null) continue;

            Set<String> norms =
                StandardNormalizer.splitNormalizeAndFilter(
                    oi.ProductStandard__r.FullName__c
                );

            if (!norms.isEmpty()) {
                itemToStandards.put(oi.Id, norms);
                allNorms.addAll(norms);
            }
        }

        if (itemToStandards.isEmpty()) return;

        // 2. Load Standard__c
        Map<String, Id> standardByNorm = new Map<String, Id>();
        for (Standard__c s : [
            SELECT Id, NormalizedName__c
            FROM Standard__c
            WHERE NormalizedName__c IN :allNorms
        ]) {
            standardByNorm.put(s.NormalizedName__c, s.Id);
        }

        // 3. Load Equivalence Groups by hash
        Map<String, Id> groupByHash = new Map<String, Id>();

        Set<String> hashes = new Set<String>();
        Map<Id, String> itemToHash = new Map<Id, String>();

        for (Id oiId : itemToStandards.keySet()) {
            List<String> sorted = new List<String>(itemToStandards.get(oiId));
            sorted.sort();

            String joined = String.join(sorted, '|');
            String hash = EncodingUtil.convertToHex(
                Crypto.generateDigest('SHA1', Blob.valueOf(joined))
            );

            hashes.add(hash);
            itemToHash.put(oiId, hash);
        }

        for (StandardEquivalenceGroup__c g : [
            SELECT Id, Hash__c
            FROM StandardEquivalenceGroup__c
            WHERE Hash__c IN :hashes
        ]) {
            groupByHash.put(g.Hash__c, g.Id);
        }

        // 4. Update OrderItems
        List<OrderItem> toUpdate = new List<OrderItem>();

        for (OrderItem oi : items) {
            Set<String> norms = itemToStandards.get(oi.Id);
            if (norms == null || norms.isEmpty()) continue;

            // deterministic standard (first sorted)
            List<String> sorted = new List<String>(norms);
            sorted.sort();

            String mainNorm = sorted[0];
            Id stdId = standardByNorm.get(mainNorm);

            if (stdId != null) {
                oi.Standard__c = stdId;
            }

            String hash = itemToHash.get(oi.Id);
            if (groupByHash.containsKey(hash)) {
                oi.StandardGroup__c = groupByHash.get(hash);
            }

            toUpdate.add(oi);
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }

    global void finish(Database.BatchableContext bc) {
        System.debug('OrderItem standard migration finished');
    }
}