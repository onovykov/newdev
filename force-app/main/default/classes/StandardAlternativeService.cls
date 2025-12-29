public with sharing class StandardAlternativeService {

    /**
     * Returns alternative standards for given Standard__c.
     * Never returns null. Never includes the same standard.
     */
    public static List<Standard__c> findAlternatives(Id standardId) {
        if (standardId == null) {
            return new List<Standard__c>();
        }

        // 1) знайти групи цього стандарту
        Set<Id> groupIds = new Set<Id>();
        for (StandardEquivalence__c se : [
            SELECT EquivalenceGroup__c
            FROM StandardEquivalence__c
            WHERE Standard__c = :standardId
        ]) {
            if (se.EquivalenceGroup__c != null) {
                groupIds.add(se.EquivalenceGroup__c);
            }
        }

        if (groupIds.isEmpty()) {
            return new List<Standard__c>();
        }

        // 2) витягнути всі інші стандарти з цих груп (без дублів)
        //    Дублі прибираємо Set'ом, а сортування робимо ORDER BY.
        Set<Id> altIds = new Set<Id>();
        for (StandardEquivalence__c se : [
            SELECT Standard__c
            FROM StandardEquivalence__c
            WHERE EquivalenceGroup__c IN :groupIds
              AND Standard__c != :standardId
        ]) {
            if (se.Standard__c != null) {
                altIds.add(se.Standard__c);
            }
        }

        if (altIds.isEmpty()) {
            return new List<Standard__c>();
        }

        return [
            SELECT Id, Name, NormalizedName__c, ID_ERP__c, OldId__c
            FROM Standard__c
            WHERE Id IN :altIds
            ORDER BY Name
        ];
    }
}