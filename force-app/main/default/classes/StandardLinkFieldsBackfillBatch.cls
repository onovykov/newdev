// One-time batch - апсерт ID_ERP__c + OldId__c
global class StandardLinkFieldsBackfillBatch
    implements Database.Batchable<SObject> {

    // ----------------------------------------
    // START
    // ----------------------------------------
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, ID_ERP__c, OldId__c
            FROM Standard__c
            WHERE ID_ERP__c = null
               OR OldId__c = null
        ]);
    }

    // ----------------------------------------
    // EXECUTE
    // ----------------------------------------
    global void execute(Database.BatchableContext bc, List<SObject> scope) {

        List<Standard__c> toUpdate = new List<Standard__c>();

        for (Standard__c s : (List<Standard__c>) scope) {

            Boolean changed = false;

            // fallback — мінімум, щоб поле не було null
            if (s.OldId__c == null) {
                s.OldId__c = s.Id;
                changed = true;
            }

            // ID_ERP__c — якщо з legacy підтягнути нема звідки, не чіпаємо
            // (краще null, ніж вигаданий)
            if (changed) {
                toUpdate.add(s);
            }
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }

    // ----------------------------------------
    // FINISH (обовʼязковий)
    // ----------------------------------------
    global void finish(Database.BatchableContext bc) {
        System.debug('StandardLinkFieldsBackfillBatch finished');
    }
}
