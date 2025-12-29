// One-time batch для фіксу API Spec
global class ApiSpec5LRepairBatch
    implements Database.Batchable<SObject> {

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, NormalizedName__c
            FROM Standard__c
            WHERE NormalizedName__c IN (
                'API 5L PSL1-2012',
                'API SPEC 5L-2012'
            )
        ]);
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope) {

        Map<String, Id> stdByName = new Map<String, Id>();
        for (Standard__c s : (List<Standard__c>)scope) {
            stdByName.put(s.NormalizedName__c, s.Id);
        }

        // якщо SPEC ще нема — створюємо
        if (!stdByName.containsKey('API SPEC 5L-2012')) {
            Standard__c spec = new Standard__c(
                Name = 'API SPEC 5L-2012',
                NormalizedName__c = 'API SPEC 5L-2012'
            );
            insert spec;
            stdByName.put('API SPEC 5L-2012', spec.Id);
        }

        Id api5lId  = stdByName.get('API 5L PSL1-2012');
        Id specId   = stdByName.get('API SPEC 5L-2012');

        if (api5lId == null || specId == null) return;

        // всі групи, де є API 5L
        Set<Id> groupIds = new Set<Id>();
        for (StandardEquivalence__c se : [
            SELECT EquivalenceGroup__c
            FROM StandardEquivalence__c
            WHERE Standard__c = :api5lId
        ]) {
            groupIds.add(se.EquivalenceGroup__c);
        }

        // додаємо SPEC у ті ж групи
        List<StandardEquivalence__c> toUpsert = new List<StandardEquivalence__c>();
        for (Id gId : groupIds) {
            toUpsert.add(new StandardEquivalence__c(
                Standard__c = specId,
                EquivalenceGroup__c = gId,
                UniqueKey__c = specId + '_' + gId
            ));
        }

        if (!toUpsert.isEmpty()) {
            upsert toUpsert UniqueKey__c;
        }
    }

    global void finish(Database.BatchableContext bc) {
        System.debug('API SPEC 5L repair finished');
    }
}