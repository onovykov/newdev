public with sharing class ERPLotBuilder {

    public List<ERPLotAggregate> buildAggregatesWithOrderItems(
        Map<String, List<ERPLotAggregate>> aggregatesByIte,
        Map<String, OrderItem> orderItemsByIte
    ) {
        List<ERPLotAggregate> result = new List<ERPLotAggregate>();

        for (String iteNumber : aggregatesByIte.keySet()) {
            OrderItem oi = orderItemsByIte.get(iteNumber);

            if (oi == null) {
                continue;
            }

            for (ERPLotAggregate agg : aggregatesByIte.get(iteNumber)) {
                agg.orderItemId = oi.Id;
                //agg.orderId = oi.OrderId;
                agg.extKey = ERPLotKeyUtil.buildExtKey(
                    oi.Id,
                    agg.prodWeekId,
                    agg.lotType
                );

                result.add(agg);
            }
        }

        return result;
    }

    public List<Lot__c> buildLotsForUpsert(
        List<ERPLotAggregate> aggregates,
        Map<String, Lot__c> existingLotsByExtKey
    ) {
        List<Lot__c> result = new List<Lot__c>();

        for (ERPLotAggregate agg : aggregates) {
            Lot__c lotRecord;

            if (existingLotsByExtKey != null && existingLotsByExtKey.containsKey(agg.extKey)) {
                lotRecord = existingLotsByExtKey.get(agg.extKey);
            } else {
                lotRecord = new Lot__c();
                lotRecord.ExtKey__c = agg.extKey;
            }

            //lotRecord.ITENumber__c = agg.iteNumber;
            // lotRecord.Order__c = agg.orderId;
            lotRecord.OrderItem__c = agg.orderItemId;
            lotRecord.ProdWeek__c = agg.prodWeekId;
            lotRecord.LotDate__c = agg.lotDate;
            lotRecord.LotType__c = agg.lotType;
            lotRecord.LotQty_t__c = agg.lotQty;
            /*
            lotRecord.Name =
                agg.iteNumber + ' ' +
                String.valueOf(Date.today()) + ' ' +
                agg.lotType;
            */
            result.add(lotRecord);
        }

        return result;
    }
}