public with sharing class ProdTechRefDetailsTriggerHandler {

    public static void handleBefore(
        List<ProdTechRefDetails__c> newList,
        Map<Id, ProdTechRefDetails__c> oldMap,
        Boolean isInsert,
        Boolean isUpdate
    ) {
        if (newList == null || newList.isEmpty()) {
            return;
        }

        // 1. Збираємо всі lookup-и
        Set<Id> refIds = new Set<Id>();
        for (ProdTechRefDetails__c rec : newList) {
            if (rec.ProdTechRef__c != null) {
                refIds.add(rec.ProdTechRef__c);
            }
        }

        Map<Id, ProdTechRef__c> refMap = new Map<Id, ProdTechRef__c>();
        if (!refIds.isEmpty()) {
            for (ProdTechRef__c ref : [
                SELECT Id, ITRef__c
                FROM ProdTechRef__c
                WHERE Id IN :refIds
            ]) {
                refMap.put(ref.Id, ref);
            }
        }

        // 2. Основна логіка
        for (ProdTechRefDetails__c rec : newList) {

            String newCode = rec.ID_ERP__c;
            String encoded = null;

            Boolean shouldRecalculate = true;

            // 1. blank → чистимо все
            if (String.isBlank(newCode)) {
                rec.NormalizedCode__c = null;
                rec.CompositeKey__c = null;
                continue;
            }

            // 2. перевірка update
            if (isUpdate && oldMap != null) {
                ProdTechRefDetails__c oldRec = oldMap.get(rec.Id);

                if (oldRec != null && newCode == oldRec.ID_ERP__c
                    && rec.ProdTechRef__c == oldRec.ProdTechRef__c) {

                    shouldRecalculate = false;
                }
            }

            if (!shouldRecalculate) {
                continue;
            }

            // 3. encode
            encoded = safeEncode(newCode);
            rec.NormalizedCode__c = encoded;

            // 4. composite key
            if (encoded != null && rec.ProdTechRef__c != null) {
                ProdTechRef__c ref = refMap.get(rec.ProdTechRef__c);

                if (ref != null && !String.isBlank(ref.ITRef__c)) {
                    rec.CompositeKey__c = ref.ITRef__c + '|' + encoded;
                } else {
                    rec.CompositeKey__c = null;
                }
            } else {
                rec.CompositeKey__c = null;
            }
        }
    }

    private static String safeEncode(String code) {
        try {
            return CanonicalKeyService.encode(code);
        } catch (Exception e) {
            System.debug('Encoding failed: ' + e.getMessage());
            return null;
        }
    }
}