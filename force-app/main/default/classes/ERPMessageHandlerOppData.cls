public with sharing class ERPMessageHandlerOppData {

    /* ===================== ENTRY POINT ===================== */

    public static void syncOrderFromErp(
            ERPMessageParser.ErpToSfMessage_OpportunityData msg,
            String rawPayload
    ) {
        validateMessage(msg);

        String erpOrderId = String.valueOf(msg.data.header.unDoc);
        Order existing = findOrderByErpId(erpOrderId);

        // -------- Idempotency --------
        String payloadHash = sha256(rawPayload);
        if (existing != null &&
                existing.ERP_LastPayloadHash__c == payloadHash
        ) {
            return;
        }

        Order ord = upsertOrder(msg, existing);

        List<OrderItem> processedItems =
                syncOrderItems(msg, ord.Id);

        String orderSyncState =
                aggregateOrderSyncState(processedItems);

        update new Order(
                Id = ord.Id,
                ERP_LastPayloadHash__c = payloadHash,
                ERP_LastSyncAt__c = System.now(),
                ERP_SyncState__c = orderSyncState
        );
    }

    /* ===================== VALIDATION ===================== */

    private static void validateMessage(
            ERPMessageParser.ErpToSfMessage_OpportunityData msg
    ) {
        if (msg == null || msg.data == null || msg.data.header == null) {
            throw new erpException('Invalid ERP OpportunityData payload');
        }
        if (msg.data.header.unDoc == null) {
            throw new erpException('ERP OpportunityData: unDoc is null');
        }
    }

    /* ===================== ORDER ===================== */

    private static Order findOrderByErpId(String erpOrderId) {
        List<Order> lst = [
                SELECT Id, EffectiveDate, ERP_LastPayloadHash__c
                FROM Order
                WHERE ID_ERP__c = :erpOrderId
                LIMIT 1
        ];
        return lst.isEmpty() ? null : lst[0];
    }

    private static Order upsertOrder(
            ERPMessageParser.ErpToSfMessage_OpportunityData msg,
            Order existing
    ) {
        Order ord = existing != null ? existing : new Order();

        ord.ID_ERP__c = String.valueOf(msg.data.header.unDoc);
        ord.CurrencyIsoCode = msg.data.orderCurrency;

        Date erpOrderDate = parseErpDate(msg.data.header.orderDate);
        DateTime erpCreated = parseErpDateTime(msg.data.header.createdDate);

        if (erpCreated != null) {
            ord.ERP_CreatedDateTime__c = erpCreated;
        }
        if (erpOrderDate != null) {
            ord.ERP_OrderDate__c = erpOrderDate;
        }

        if (ord.EffectiveDate == null) {
            ord.EffectiveDate =
                    erpOrderDate != null ? erpOrderDate : Date.today();
        }

        if (ord.AccountId == null) {
            Opportunity opp = findOpportunityByErpId(ord.ID_ERP__c);
            if (opp == null) {
                throw new erpException(
                        'Cannot resolve Opportunity for ERP Order ' + ord.ID_ERP__c
                );
            }
            ord.AccountId = opp.AccountId;
            ord.OpportunityId = opp.Id;
            ord.Pricebook2Id = opp.Pricebook2Id;
            ord.ContractId = opp.ContractId;
        }

        upsert ord ID_ERP__c;
        return ord;
    }

    private static Opportunity findOpportunityByErpId(String erpId) {
        List<Opportunity> lst = [
                SELECT Id, AccountId, Pricebook2Id, ContractId
                FROM Opportunity
                WHERE ID_ERP__c = :erpId
                LIMIT 1
        ];
        return lst.isEmpty() ? null : lst[0];
    }

    /* ===================== ORDER ITEMS ===================== */

    private static List<OrderItem> syncOrderItems(
            ERPMessageParser.ErpToSfMessage_OpportunityData msg,
            Id orderId
    ) {
        Map<String, String> stageMap = makeMapForStage();

        Map<String, OrderItem> existingByKey = new Map<String, OrderItem>();
        for (OrderItem oi : [
                SELECT Id, ERP_LineKey__c, Stage__c,
                        ERP_Missing__c, ERP_SyncState__c
                FROM OrderItem
                WHERE OrderId = :orderId
        ]) {
            if (oi.ERP_LineKey__c != null) {
                existingByKey.put(oi.ERP_LineKey__c, oi);
            }
        }

        Set<String> incomingKeys = new Set<String>();
        List<OrderItem> toUpsert = new List<OrderItem>();
        List<OrderItem> toCancel = new List<OrderItem>();
        List<OrderItem> processed = new List<OrderItem>();

        for (ERPMessageParser.ERPObject_OrderItem it : msg.data.items) {
            if (it == null || it.npp == null) continue;

            String erpKey = orderId + '#' + it.npp;
            incomingKeys.add(erpKey);

            OrderItem oi = existingByKey.containsKey(erpKey)
                    ? existingByKey.get(erpKey)
                    : new OrderItem(OrderId = orderId);

            oi.ERP_LineKey__c = erpKey;
            oi.NPP_ERP__c = String.valueOf(it.npp);
            oi.ITENumber__c = it.iteNumber;
            oi.ERP_Missing__c = false;

            if (stageMap.containsKey(it.Stage)) {
                oi.Stage__c = stageMap.get(it.Stage);
                oi.ERP_SyncState__c = 'OK';
            } else {
                oi.ERP_SyncState__c = 'WARNING';
                System.debug(LoggingLevel.WARN, '[ERP_UNKNOWN_ITEM_STAGE] Unknown ERP OrderItem stage | orderId=' + orderId + ' npp=' + it.npp + ' erpStage=' + it.stage);
            }

            Id pbeId = selectPBEbyProduct2ERPId(it.ProductGroup.ID);
            if (pbeId == null) {
                oi.ERP_SyncState__c = 'ERROR';
                System.debug(LoggingLevel.ERROR, '[ERP_PBE_NOT_FOUND] PricebookEntry not found | orderId=' + orderId + ' npp=' + it.npp + ' productGroupId=' + it.productgroup.id);
                processed.add(oi);
                continue;
            }

            oi.PricebookEntryId = pbeId;
            oi.Quantity =
                    it.Quantity_Mt != null && it.Quantity_Mt > 0
                            ? it.Quantity_Mt
                            : 1;

            toUpsert.add(oi);
            processed.add(oi);
        }

        for (String key : existingByKey.keySet()) {
            if (!incomingKeys.contains(key)) {
                OrderItem oi = existingByKey.get(key);
                oi.Stage__c = 'Cancelled';
                oi.ERP_Missing__c = true;
                oi.ERP_SyncState__c = 'MISSING_IN_ERP';
                toCancel.add(oi);
                processed.add(oi);
            }
        }

        if (!toUpsert.isEmpty()) {
            Database.upsert(toUpsert, OrderItem.Fields.ERP_LineKey__c, false);
        }
        if (!toCancel.isEmpty()) {
            update toCancel;
        }

        return processed;
    }

    /* ===================== AGGREGATION ===================== */

    private static String aggregateOrderSyncState(List<OrderItem> items) {
        Boolean hasError = false;
        Boolean hasWarning = false;

        for (OrderItem oi : items) {
            if (oi.ERP_SyncState__c == 'ERROR') hasError = true;
            else if (oi.ERP_SyncState__c == 'WARNING') hasWarning = true;
        }
        if (hasError) return 'ERROR';
        if (hasWarning) return 'WARNING';
        return 'OK';
    }

    /* ===================== UTILS ===================== */

    private static Date parseErpDate(String s) {
        try {
            return String.isBlank(s) ? null : Date.valueOf(s.substring(0, 10));
        } catch (Exception e) {
            return null;
        }
    }

    private static Date parseErpDate(DateTime dt) {
        return dt != null ? dt.date() : null;
    }

    private static DateTime parseErpDateTime(String s) {
        try {
            if (String.isBlank(s)) return null;
            String norm = s.replace('T', ' ');
            if (norm.length() == 19) norm += '.000';
            return DateTime.valueOf(norm);
        } catch (Exception e) {
            return null;
        }
    }

    private static DateTime parseErpDateTime(DateTime dt) {
        return dt;
    }

    private static Id selectPBEbyProduct2ERPId(String erpProductGroupId) {
        if (String.isBlank(erpProductGroupId)) return null;
        List<Product2> prods = [
                SELECT Id FROM Product2
                WHERE ID_ERP__c = :erpProductGroupId
                LIMIT 1
        ];
        if (prods.isEmpty()) return null;
        List<PricebookEntry> pbes = [
                SELECT Id FROM PricebookEntry
                WHERE Product2Id = :prods[0].Id AND IsActive = true
                LIMIT 1
        ];
        return pbes.isEmpty() ? null : pbes[0].Id;
    }

    private static Map<String, String> makeMapForStage() {
        Map<String, String> result = new Map<String, String>();
        Schema.DescribeFieldResult fieldResult =
                Product_Picklist_Stage__mdt.Stage__c.getDescribe();
        for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
            result.put(entry.getValue(), entry.getLabel());
        }
        return result;
    }

    private static String sha256(String body) {
        return EncodingUtil.convertToHex(
                Crypto.generateDigest(
                        'SHA-256',
                        Blob.valueOf(body != null ? body : '')
                )
        );
    }

    public class erpException extends Exception {}
}