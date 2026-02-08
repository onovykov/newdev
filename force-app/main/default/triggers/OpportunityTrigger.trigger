trigger OpportunityTrigger on Opportunity(
    after delete, after insert, after undelete, after update,
    before delete, before insert, before update
) {

    // ======================================
    // TEST / INFRASTRUCTURE BYPASS
    // ======================================
    if (
        OpportunityTriggerHandler.bypassAll &&
        Trigger.isBefore &&
        (Trigger.isInsert || Trigger.isUpdate)
    ) {
        return;
    }
        
    OpportunityTriggerHandler handler =
        new OpportunityTriggerHandler(
            Trigger.oldMap,
            Trigger.newMap,
            Trigger.old,
            Trigger.new
        );

    if (Trigger.isBefore) {

        handler.bulkBefore();

        if (Trigger.isUpdate) {

            //  Новий ізольований audit hook
            OpportunityFieldAuditHook.beforeUpdate(
                (Map<Id, Opportunity>) Trigger.oldMap,
                (Map<Id, Opportunity>) Trigger.newMap
            );

            // Стара логіка (лишаємо AS IS)
            for (Id oppId : Trigger.newMap.keySet()) {
                handler.beforeUpdate(
                    Trigger.oldMap.get(oppId),
                    Trigger.newMap.get(oppId)
                );
            }

        } else if (Trigger.isInsert) {
            for (SObject so : Trigger.new)
                handler.beforeInsert(so);

        } else if (Trigger.isDelete) {
            for (SObject so : Trigger.old)
                handler.beforeDelete(so);
        }

        handler.beforePostProcessing();
    } else {

        handler.bulkAfter();

        if (Trigger.isInsert) {
            for (SObject so : Trigger.new)
                handler.afterInsert(so);

        } else if (Trigger.isUpdate) {
            for (SObject so : Trigger.old)
                handler.afterUpdate(
                    so,
                    Trigger.newMap.get(so.Id)
                );

        } else if (Trigger.isDelete) {
            for (SObject so : Trigger.old)
                handler.afterDelete(so);
        }

        // === ВСТАВЛЕНО 16.10.2025 (ON): крос-маркет нотифікації ===
        if (Trigger.isInsert || Trigger.isUpdate) {
            OpportunityCrossMarketHandler.enqueueNotifications(Trigger.new, Trigger.oldMap);
            OpportunityCrossMarketHandler.enqueueClosedWonNotifications(Trigger.new, Trigger.oldMap);
        }
        // === кінець вставки ===
        handler.postProcessing();
    }
}