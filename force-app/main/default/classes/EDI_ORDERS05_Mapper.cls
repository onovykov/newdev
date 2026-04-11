public with sharing class EDI_ORDERS05_Mapper {

    public static OrderInboundDTO mapToCanonical(EDI_ORDERS05_DTO source) {

        OrderInboundDTO target = new OrderInboundDTO();

        target.externalOrderNumber = source.documentNumber;
        target.requestedDeliveryDate = source.requestedDeliveryDate;

        for (EDI_ORDERS05_DTO.Item srcItem : source.items) {

            OrderInboundDTO.Item tgtItem =
                new OrderInboundDTO.Item();

            tgtItem.externalItemKey = srcItem.extKey;
            tgtItem.sapItemNumber   = srcItem.sapItemNumber;
            tgtItem.materialNumber = srcItem.materialNumber;
            tgtItem.quantity       = srcItem.quantity;

            target.items.add(tgtItem);
        }

        return target;
    }
}
