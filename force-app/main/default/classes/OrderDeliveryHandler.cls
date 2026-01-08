public class OrderDeliveryHandler {
    // =========================
    // ENTRY POINT
    // =========================
    public static OrderDeliveryDto getDTO(String jsonString) {

        if (String.isBlank(jsonString)) {
            throw new IllegalArgumentException('Empty JSON payload');
        }

        // Швидка перевірка: є "Data"?
        if (jsonString.contains('"Data"')) {
            OrderDeliveryEnvelopeDto envelope =
                (OrderDeliveryEnvelopeDto) JSON.deserialize(
                    jsonString,
                    OrderDeliveryEnvelopeDto.class
                );

            if (envelope == null || envelope.Data == null) {
                throw new IllegalArgumentException('Invalid envelope payload');
            }

            return envelope.Data;
        }

        // Старий формат (без шапки)
        return (OrderDeliveryDto) JSON.deserialize(
            jsonString,
            OrderDeliveryDto.class
        );
    }

    // =========================
    // HELPERS
    // =========================
    //--- Тип доправи - Multimodal?
    public static Boolean isMultimodal(OrderDeliveryDto dto) {
        return dto != null && dto.deliveryMode == 'Multimodal';
    }
    //--- Повертає лист ітемів  основного DTO
    public static List<OrderDeliveryDto.OrderLineItemDto>
        getLineItems(OrderDeliveryDto dto)
    {
        if (dto == null || dto.orderLineItems == null) {
            return new List<OrderDeliveryDto.OrderLineItemDto>();
        }
        return dto.orderLineItems;
    }
    //--- Повертає основні дані ордера
    public static Order getOrder(OrderDeliveryDto dto) {

        if (dto == null || dto.orderIdErp == null) {
            return null;
        }

        List<Order> ordList = [
            SELECT Id, ITENumber__c, AdditionalNumber__c,
                   PO_Number__c, AccountId, ID_ERP__c,
                   EffectiveDate, EndDate, TotalOrderQuantity__c,
                   Quantity_pcs__c
            FROM Order
            WHERE ID_ERP__c = :String.valueOf(dto.orderIdErp)
            LIMIT 1
        ];

        return ordList.isEmpty() ? null : ordList[0];
    }
}