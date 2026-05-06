public with sharing class LotRepository {

    public Map<String, Lot__c> getByExtKeys(Set<String> extKeys) {
        Map<String, Lot__c> result = new Map<String, Lot__c>();

        if (extKeys == null || extKeys.isEmpty()) {
            return result;
        }

        for (Lot__c lotRecord : [
            SELECT
                Id,
                Name,
                ExtKey__c,
                // ITENumber__c,
                // Order__c,
                OrderItem__c,
                ProdWeek__c,
                LotDate__c,
                LotQty_t__c,
                LotType__c
            FROM Lot__c
            WHERE ExtKey__c IN :extKeys
        ]) {
            result.put(lotRecord.ExtKey__c, lotRecord);
        }

        return result;
    }

    public Database.UpsertResult[] upsertByExtKey(List<Lot__c> lots) {
        if (lots == null || lots.isEmpty()) {
            return new List<Database.UpsertResult>();
        }

        return Database.upsert(
            lots,
            Lot__c.Fields.ExtKey__c,
            false
        );
    }
}