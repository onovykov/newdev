global class StandardEquivalenceGroupBackfillBatch
    implements Database.Batchable<SObject> {

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, OldId__c, ID_ERP__c
            FROM StandardEquivalenceGroup__c
            WHERE OldId__c = null
               OR ID_ERP__c = null
        ]);
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope) {

        Set<Id> groupIds = new Set<Id>();
        for (StandardEquivalenceGroup__c g : (List<StandardEquivalenceGroup__c>)scope) {
            groupIds.add(g.Id);
        }

        // беремо будь-який стандарт з групи
        Map<Id, Standard__c> sampleStdByGroup = new Map<Id, Standard__c>();

        for (StandardEquivalence__c se : [
            SELECT EquivalenceGroup__c,
                   Standard__r.OldId__c,
                   Standard__r.ID_ERP__c
            FROM StandardEquivalence__c
            WHERE EquivalenceGroup__c IN :groupIds
        ]) {
            if (!sampleStdByGroup.containsKey(se.EquivalenceGroup__c)
                && se.Standard__r != null
                && se.Standard__r.OldId__c != null) {

                sampleStdByGroup.put(se.EquivalenceGroup__c, se.Standard__r);
            }
        }

        List<StandardEquivalenceGroup__c> toUpdate =
            new List<StandardEquivalenceGroup__c>();

        for (StandardEquivalenceGroup__c g :
             (List<StandardEquivalenceGroup__c>)scope) {

            Standard__c std = sampleStdByGroup.get(g.Id);
            if (std == null) continue;

            Boolean changed = false;

            if (g.OldId__c == null && std.OldId__c != null) {
                g.OldId__c = std.OldId__c;
                changed = true;
            }

            if (g.ID_ERP__c == null && std.ID_ERP__c != null) {
                g.ID_ERP__c = std.ID_ERP__c;
                changed = true;
            }

            if (changed) {
                toUpdate.add(g);
            }
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }

    global void finish(Database.BatchableContext bc) {
        System.debug('StandardEquivalenceGroupBackfillBatch finished');
    }
}