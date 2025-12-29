public class StandardSubstitutionService {

    public static List<Standard__c> findSubstitutes(Id standardId) {

        // 🔒 GUARD
        if (standardId == null) {
            return new List<Standard__c>();
        }

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

        Map<Id, Standard__c> byId = new Map<Id, Standard__c>();

        for (StandardEquivalence__c se : [
            SELECT Standard__c,
                   Standard__r.Name,
                   Standard__r.NormalizedName__c
            FROM StandardEquivalence__c
            WHERE EquivalenceGroup__c IN :groupIds
              AND Standard__c != :standardId
        ]) {
            if (se.Standard__c == null) continue;

            byId.put(
                se.Standard__c,
                new Standard__c(
                    Id = se.Standard__c,
                    Name = se.Standard__r != null ? se.Standard__r.Name : null,
                    NormalizedName__c =
                        se.Standard__r != null ? se.Standard__r.NormalizedName__c : null
                )
            );
        }

        return byId.values(); // NEVER NULL
    }
}