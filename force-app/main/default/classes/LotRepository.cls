public with sharing class LotRepository {

    //=============== GET METHODS ================================
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
                ITENumber__c,
                OrderItem__c,
                ProdWeek__c,
                LotDate__c,
                LotQty_t__c,
                LotType__c
            FROM Lot__c
            WHERE ExtKey__c IN :extKeys
        ]) {
            if (!String.isBlank(lotRecord.ExtKey__c)) {
                result.put(lotRecord.ExtKey__c, lotRecord);
            }
        }
        return result;
    }
    //-------------------------------------------------------------
    public Map<String, Lot__c> getLotsByIteNum(String iteNum) {
        Map<String, Lot__c> result = new Map<String, Lot__c>();

        if (String.isBlank(iteNum)) {
            return result;
        }

        for (Lot__c lotRecord : [
            SELECT
                Id,
                Name,
                ExtKey__c,
                ITENumber__c,
                OrderItem__c,
                ProdWeek__c,
                LotDate__c,
                LotQty_t__c,
                LotType__c
            FROM Lot__c
            WHERE ITENumber__c = :iteNum
        ]) {
            putByExtKey(result, lotRecord);
        }
        return result;
    }
    //-------------------------------------------------------------
    public Map<String, Lot__c> getLotsByDates(Date dateFrom, Date dateTo) {
        Map<String, Lot__c> result = new Map<String, Lot__c>();

        if (dateFrom == null || dateTo == null) {
            return result;
        }

        if (dateFrom > dateTo) {
            return result;
        }

        for (Lot__c lotRecord : [
            SELECT
                Id,
                Name,
                ExtKey__c,
                ITENumber__c,
                OrderItem__c,
                ProdWeek__c,
                LotDate__c,
                LotQty_t__c,
                LotType__c
            FROM Lot__c
            WHERE LotDate__c >= :dateFrom
              AND LotDate__c <= :dateTo
        ]) {
            putByExtKey(result, lotRecord);
        }
        return result;
    }
    //-------------------------------------------------------------
    public Map<String, Lot__c> getLotsByYM(Integer year, Integer month) {
        Map<String, Lot__c> result = new Map<String, Lot__c>();

        if (year == null || year <= 0 || month == null || month < 1 || month > 12) {
            return result;
        }

        Date firstDay = Date.newInstance(year, month, 1);
        Date lastDay = firstDay.addMonths(1).addDays(-1);

        return getLotsByDates(firstDay, lastDay);
    }
    //-------------------------------------------------------------
    public Map<String, Lot__c> getLotsByProdWeekId(Id prodWeekId) {
        Map<String, Lot__c> result = new Map<String, Lot__c>();

        if (prodWeekId == null) {
            return result;
        }

        for (Lot__c lotRecord : [
            SELECT
                Id,
                Name,
                ExtKey__c,
                ITENumber__c,
                OrderItem__c,
                ProdWeek__c,
                LotDate__c,
                LotQty_t__c,
                LotType__c
            FROM Lot__c
            WHERE ProdWeek__c = :prodWeekId
        ]) {
            putByExtKey(result, lotRecord);
        }
        return result;
    }

    //========================= HELPERS ===========================
    private static void putByExtKey(Map<String, Lot__c> targetMap, Lot__c lotRecord) {
        if (targetMap == null || lotRecord == null || String.isBlank(lotRecord.ExtKey__c)) {
            return;
        }

        targetMap.put(lotRecord.ExtKey__c, lotRecord);
    }
    //-------------------------------------------------------------
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