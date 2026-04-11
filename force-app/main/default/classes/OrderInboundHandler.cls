public with sharing class OrderInboundHandler {

    // =========================================================
    // STATUS ENUM (string-based, щоб не морочитись з enum)
    // =========================================================

    public static final String STATUS_FULL_SUCCESS = 'FULL_SUCCESS';
    public static final String STATUS_PARTIAL_SUCCESS = 'PARTIAL_SUCCESS';
    public static final String STATUS_ERROR = 'ERROR';

    // =========================================================
    // RESULT CLASSES
    // =========================================================

    public class Result {
        public Id orderId;
        public String externalOrderNumber;

        public String status; // FULL_SUCCESS / PARTIAL_SUCCESS / ERROR

        public List<ItemResult> items = new List<ItemResult>();
        public List<String> errors = new List<String>();
        public List<String> warnings = new List<String>();
    }

    public class ItemResult {
        public String externalItemKey;
        public String sapItemNumber;

        public Id orderItemId;
        public String matchedBy; // EXT_KEY / NONE

        public Boolean success;
        public String message;
    }

    // =========================================================
    // MAIN ENTRY POINT
    // =========================================================

    public static Result handle(OrderInboundDTO dto) {

        validateInput(dto);

        Result result = new Result();
        result.externalOrderNumber = dto.externalOrderNumber;

        Boolean hasSuccess = false;
        Boolean hasErrors = false;
        Boolean hasWarnings = false;

        // -----------------------------------------
        // 1. Collect extKeys
        // -----------------------------------------
        Set<String> extKeys = new Set<String>();

        for (OrderInboundDTO.Item i : dto.items) {
            if (String.isNotBlank(i.externalItemKey)) {
                extKeys.add(i.externalItemKey);
            }
        }

        // -----------------------------------------
        // 2. Load OrderItems
        // -----------------------------------------
        Map<String, OrderItem> itemsByExtKey = new Map<String, OrderItem>();

        if (!extKeys.isEmpty()) {
            for (OrderItem oi : [
                SELECT Id, OrderId, ITENumber__c, SAPItemNumber__c
                FROM OrderItem
                WHERE ITENumber__c IN :extKeys
            ]) {
                itemsByExtKey.put(oi.ITENumber__c, oi);
            }
        }

        // -----------------------------------------
        // 3. Load Orders
        // -----------------------------------------
        Set<Id> orderIds = new Set<Id>();

        for (OrderItem oi : itemsByExtKey.values()) {
            orderIds.add(oi.OrderId);
        }

        Map<Id, Order> orders = new Map<Id, Order>();

        if (!orderIds.isEmpty()) {
            orders = new Map<Id, Order>([
                SELECT Id, ERP_OrderNumber__c
                FROM Order
                WHERE Id IN :orderIds
            ]);
        }

        // -----------------------------------------
        // 4. Prepare updates
        // -----------------------------------------
        List<OrderItem> itemsToUpdate = new List<OrderItem>();
        List<Order> ordersToUpdate = new List<Order>();
        Set<Id> updatedOrderIds = new Set<Id>();

        // -----------------------------------------
        // 5. Process items
        // -----------------------------------------
        for (OrderInboundDTO.Item inboundItem : dto.items) {

            ItemResult itemResult = new ItemResult();
            itemResult.externalItemKey = inboundItem.externalItemKey;
            itemResult.sapItemNumber = inboundItem.sapItemNumber;

            // -------------------------------------
            // CASE 1: Missing extKey → WARNING
            // -------------------------------------
            if (String.isBlank(inboundItem.externalItemKey)) {

                itemResult.success = false;
                itemResult.matchedBy = 'NONE';
                itemResult.message = 'Missing extKey (ZIT)';

                result.items.add(itemResult);
                result.warnings.add(itemResult.message);

                hasWarnings = true;
                continue;
            }

            OrderItem matchedItem = itemsByExtKey.get(inboundItem.externalItemKey);

            // -------------------------------------
            // CASE 2: NOT FOUND → ERROR
            // -------------------------------------
            if (matchedItem == null) {

                itemResult.success = false;
                itemResult.matchedBy = 'NONE';
                itemResult.message =
                    'OrderItem not found for extKey=' + inboundItem.externalItemKey;

                result.items.add(itemResult);
                result.errors.add(itemResult.message);

                hasErrors = true;
                continue;
            }

            // -------------------------------------
            // CASE 3: MATCHED → SUCCESS
            // -------------------------------------
            itemResult.success = true;
            itemResult.matchedBy = 'EXT_KEY';
            itemResult.orderItemId = matchedItem.Id;
            itemResult.message = 'Matched by ITENumber__c';

            hasSuccess = true;

            // ENRICH OrderItem
            if (String.isBlank(matchedItem.SAPItemNumber__c)
                && String.isNotBlank(inboundItem.sapItemNumber)) {

                matchedItem.SAPItemNumber__c = inboundItem.sapItemNumber;
                itemsToUpdate.add(matchedItem);
            }

            // ENRICH Order
            Order parentOrder = orders.get(matchedItem.OrderId);

            if (parentOrder != null
                && String.isBlank(parentOrder.ERP_OrderNumber__c)
                && String.isNotBlank(dto.externalOrderNumber)
                && !updatedOrderIds.contains(parentOrder.Id)) {

                parentOrder.ERP_OrderNumber__c = dto.externalOrderNumber;
                ordersToUpdate.add(parentOrder);
                updatedOrderIds.add(parentOrder.Id);
            }

            result.orderId = matchedItem.OrderId;
            result.items.add(itemResult);
        }

        // -----------------------------------------
        // 6. Update DB
        // -----------------------------------------
        if (!itemsToUpdate.isEmpty()) {
            update itemsToUpdate;
        }

        if (!ordersToUpdate.isEmpty()) {
            update ordersToUpdate;
        }

        // -----------------------------------------
        // 7. FINAL STATUS
        // -----------------------------------------
        if (hasErrors) {
            result.status = STATUS_ERROR;
        } else if (hasWarnings) {
            result.status = STATUS_PARTIAL_SUCCESS;
        } else {
            result.status = STATUS_FULL_SUCCESS;
        }

        // -----------------------------------------
        // 8. DEBUG OUTPUT (заглушка)
        // -----------------------------------------
        if (result.status == STATUS_FULL_SUCCESS) {
            System.debug('FULL SUCCESS');
        } else if (result.status == STATUS_PARTIAL_SUCCESS) {
            System.debug('PARTIAL SUCCESS');
        } else {
            System.debug('ERROR');
        }

        return result;
    }

    // =========================================================
    // VALIDATION
    // =========================================================

    private static void validateInput(OrderInboundDTO dto) {

        if (dto == null) {
            throw new IntegrationDomainException(
                'OrderInboundHandler',
                'EMPTY_DTO',
                null
            );
        }

        if (dto.items == null || dto.items.isEmpty()) {
            throw new IntegrationDomainException(
                'OrderInboundHandler',
                'NO_ITEMS',
                dto.externalOrderNumber
            );
        }
    }
}