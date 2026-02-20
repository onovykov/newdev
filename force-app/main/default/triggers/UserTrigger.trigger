trigger UserTrigger on User (
    before update,
    after update,
    after insert
) {
    if (Trigger.isBefore && Trigger.isUpdate) {
        // універсальний аудит (best effort)
        UserTriggerHandler.beforeUpdateBulk(
            (Map<Id, User>) Trigger.oldMap,
            (Map<Id, User>) Trigger.newMap
        );
    }

    if (Trigger.isAfter && Trigger.isUpdate) {
        // snapshot ключів (стабільно для User)
        UserKeySnapshotHook.afterUpdate(
            (Map<Id, User>) Trigger.oldMap,
            (Map<Id, User>) Trigger.newMap
        );
    }

    if (Trigger.isAfter && Trigger.isInsert) {
        // legacy, тимчасово
        UserTriggerHandler.afterInsert(
            (List<User>) Trigger.new
        );
    }
}