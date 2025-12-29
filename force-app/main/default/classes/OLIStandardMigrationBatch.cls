global class OLIStandardMigrationBatch
    implements Database.Batchable<SObject>, Database.Stateful {

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id,
                   ProductStandard__c,
                   ProductStandard__r.FullName__c,
                   Standard__c,
                   StandardGroup__c
            FROM OpportunityLineItem
            WHERE ProductStandard__c != null
              //AND Standard__c = null
        ]);
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope) {

        List<OpportunityLineItem> items =
            (List<OpportunityLineItem>) scope;

        Map<Id, Set<String>> itemToStandards = new Map<Id, Set<String>>();
        Set<String> allNorms = new Set<String>();

        for (OpportunityLineItem oli : items) {
            if (oli.ProductStandard__r == null) continue;

            Set<String> norms =
                StandardNormalizer.splitNormalizeAndFilter(
                    oli.ProductStandard__r.FullName__c
                );

            if (!norms.isEmpty()) {
                itemToStandards.put(oli.Id, norms);
                allNorms.addAll(norms);
            }
        }

        if (itemToStandards.isEmpty()) return;

        Map<String, Id> standardByNorm = new Map<String, Id>();
        for (Standard__c s : [
            SELECT Id, NormalizedName__c
            FROM Standard__c
            WHERE NormalizedName__c IN :allNorms
        ]) {
            standardByNorm.put(s.NormalizedName__c, s.Id);
        }

        Map<String, Id> groupByHash = new Map<String, Id>();
        Set<String> hashes = new Set<String>();
        Map<Id, String> itemToHash = new Map<Id, String>();

        for (Id oliId : itemToStandards.keySet()) {
            List<String> sorted =
                new List<String>(itemToStandards.get(oliId));
            sorted.sort();

            String joined = String.join(sorted, '|');
            String hash = EncodingUtil.convertToHex(
                Crypto.generateDigest('SHA1', Blob.valueOf(joined))
            );

            hashes.add(hash);
            itemToHash.put(oliId, hash);
        }

        for (StandardEquivalenceGroup__c g : [
            SELECT Id, Hash__c
            FROM StandardEquivalenceGroup__c
            WHERE Hash__c IN :hashes
        ]) {
            groupByHash.put(g.Hash__c, g.Id);
        }

        List<OpportunityLineItem> toUpdate =
            new List<OpportunityLineItem>();

        for (OpportunityLineItem oli : items) {
            Set<String> norms = itemToStandards.get(oli.Id);
            if (norms == null || norms.isEmpty()) continue;

            List<String> sorted = new List<String>(norms);
            sorted.sort();

            Id stdId = standardByNorm.get(sorted[0]);
            if (stdId != null) {
                oli.Standard__c = stdId;
            }

            String hash = itemToHash.get(oli.Id);
            if (groupByHash.containsKey(hash)) {
                oli.StandardGroup__c = groupByHash.get(hash);
            }

            toUpdate.add(oli);
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }

    global void finish(Database.BatchableContext bc) {
        System.debug('OpportunityLineItem standard migration finished');
    }
}