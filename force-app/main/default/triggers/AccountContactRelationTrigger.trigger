trigger AccountContactRelationTrigger on AccountContactRelation (before insert, before update) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            AccountContactRelationHandler.assignBusinessDivisionAndSegment(Trigger.new);
        }
    }
}