public with sharing class DeliveryStatusValidator {
    public class ValidationResult {
        public List<String> warnings = new List<String>();
        public List<String> errors   = new List<String>();
        public Boolean ok() { return errors.isEmpty(); }
    }

    public static ValidationResult validate(DeliveryStatusDTO dto) {
        ValidationResult vr = new ValidationResult();
        if (dto == null) { vr.errors.add('Empty payload'); return vr; }
        if (dto.orderLineItems == null || dto.orderLineItems.isEmpty()) {
            vr.warnings.add('No orderLineItems'); 
        }
        // Валідації
        for (DeliveryStatusDTO.OrderLineItemDTO oli : (dto.orderLineItems == null ? new List<DeliveryStatusDTO.OrderLineItemDTO>() : dto.orderLineItems)) {
            if (oli == null) continue;
            if (oli.packet != null) {
                if (oli.packet.lenMeasUnit != null && !DeliveryStatusCaches.measUnitExists(oli.packet.lenMeasUnit.code)) {
                    vr.warnings.add('Unknown lenMeasUnit.code: ' + oli.packet.lenMeasUnit.code);
                }
            }
            if (oli.shipmentInfo != null) {
                for (DeliveryStatusDTO.ShipmentDTO sh : oli.shipmentInfo) {
                    if (sh == null) continue;
                    String stCode = (sh.shipmentType != null ? sh.shipmentType.code : null);
                    if (!DeliveryStatusCaches.shipTypeExists(stCode)) {
                        vr.warnings.add('Unknown shipmentType.code: ' + stCode);
                    }
                    if (oli.packet != null) {
                        // відповідність кількостей пакет ↔ shipment
                        if (sh.qtyPcs != oli.packet.qtyPcs || sh.qtyTBrutto != oli.packet.qtyTBrutto || sh.qtyTNetto != oli.packet.qtyTNetto) {
                            vr.warnings.add('Qty mismatch for ITE ' + oli.packet.iteNumber + ' / PACK ' + oli.packet.packNum);
                        }
                    }
                }
            }
        }
        return vr;
    }
}