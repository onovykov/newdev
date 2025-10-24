public with sharing class DeliveryStatusFacade {
    /*** Фасад для LWC/Aura ***/
    @AuraEnabled(cacheable=false)
    public static DeliveryStatusUiModel buildUi(String rawJson) {
        DeliveryStatusDTO dto = DeliveryStatusDTO.fromJson(rawJson);
        DeliveryStatusValidator.ValidationResult vr = DeliveryStatusValidator.validate(dto);
        return DeliveryStatusUiBuilder.build(dto, vr.warnings);
    }
}