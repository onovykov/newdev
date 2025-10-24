trigger OrderItemTrigger on OrderItem (after delete, after insert, after undelete, after update, before delete, before insert, before update)  {
	OrderItemHandler handler = new OrderItemHandler(Trigger.oldMap, Trigger.newMap, Trigger.old, Trigger.new);

	if (Trigger.isBefore) {
		handler.bulkBefore();
		if (Trigger.isDelete) {
			for (SObject so : Trigger.old) {
				handler.beforeDelete(so);
			}
		} else if (Trigger.isInsert) {
			for (SObject so : Trigger.new) {
				handler.beforeInsert(so);
			}
		} else if (Trigger.isUpdate) {
			for (SObject so : Trigger.old) {
				handler.beforeUpdate(so, Trigger.newMap.get(so.Id));
			}
		}
		handler.beforePostProcessing();
	} else {
		handler.bulkAfter();
		if (Trigger.isDelete) {
			for (SObject so : Trigger.old) {
				handler.afterDelete(so);
			}
		} else if (Trigger.isInsert) {
			for (SObject so : Trigger.new) {
				handler.afterInsert(so);
			}
		} else if (Trigger.isUpdate) {
			for (SObject so : Trigger.old) {
				handler.afterUpdate(so, Trigger.newMap.get(so.Id));
			}
		}
		handler.postProcessing();
	}
 }