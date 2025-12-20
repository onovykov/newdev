public with sharing class ErpToDeliveryMapper {

    /**
     * Entry point:
     * ERP raw DTO -> normalized delivery DTO
     */
    public static DelivServiceDTO.ErpDeliveryDto fromErpRaw(
        ErpRawResponseDto raw
    ) {
        DelivServiceDTO.ErpDeliveryDto dto =
            new DelivServiceDTO.ErpDeliveryDto();

        if (raw == null ||
            raw.orderLineItems == null ||
            raw.orderLineItems.isEmpty()) {
            return dto;
        }

        // Беремо перший orderLineItem
        ErpRawResponseDto.OrderLineItem oli =
            raw.orderLineItems[0];

        dto.shipmentInfo = mapShipment(oli.shipmentInfo);
        dto.deliveryInfo = mapDelivery(oli.deliveryInfo);

        return dto;
    }

    // =====================================================
    // SHIPMENT
    // =====================================================
    private static DelivServiceDTO.ErpShipmentInfo mapShipment(
        ErpRawResponseDto.ShipmentInfo src
    ) {
        if (src == null) return null;

        DelivServiceDTO.ErpShipmentInfo sh =
            new DelivServiceDTO.ErpShipmentInfo();

        sh.vehicle = resolveVehicleLabel(src.vehicle);
        sh.events = new List<DelivServiceDTO.ErpEvent>();

        if (src.events != null) {
            for (ErpRawResponseDto.ShipmentEvent e : src.events) {
                sh.events.add(
                    mapEvent(e, src.vehicle)
                );
            }
        }

        return sh;
    }

    // =====================================================
    // DELIVERY
    // =====================================================
    private static DelivServiceDTO.ErpDeliveryInfo mapDelivery(
        ErpRawResponseDto.DeliveryInfo src
    ) {
        if (src == null) return null;

        DelivServiceDTO.ErpDeliveryInfo d =
            new DelivServiceDTO.ErpDeliveryInfo();

        d.vehicle = resolveVehicleLabel(src.vehicle);

        if (src.vehicle != null && src.vehicle.vessel != null) {
            d.destination = src.vehicle.vessel.destination;

            if (src.vehicle.vessel.estimatedArrivalDate != null) {
                d.estimatedArrivalDate =
                    parseGmt(
                        src.vehicle.vessel.estimatedArrivalDate
                    );
            }
        }

        d.events = new List<DelivServiceDTO.ErpEvent>();

        if (src.events != null) {
            for (ErpRawResponseDto.DeliveryEvent e : src.events) {

                // deliveryEvent → shipmentEvent-compatible
                ErpRawResponseDto.ShipmentEvent se =
                    new ErpRawResponseDto.ShipmentEvent();

                se.code = e.code;
                se.location = e.location;
                se.dateTracking = e.dateTracking;
                se.geo = e.geo;

                d.events.add(
                    mapEvent(se, src.vehicle)
                );
            }
        }

        return d;
    }

    // =====================================================
    // EVENT MAPPING
    // =====================================================
    private static DelivServiceDTO.ErpEvent mapEvent(
        ErpRawResponseDto.ShipmentEvent e,
        ErpRawResponseDto.Vehicle vehicle
    ) {
        DelivServiceDTO.ErpEvent ev =
            new DelivServiceDTO.ErpEvent();

        ev.eventCode = e.code;
        ev.locationCode = e.location;
        ev.dt = parseGmt(e.dateTracking);
        ev.geo = mapGeo(e.geo);

        // ✔ правильний shipType
        ev.shipTypeCode = resolveShipTypeDevName(vehicle);

        return ev;
    }

    // =====================================================
    // GEO
    // =====================================================
    private static DelivServiceDTO.ErpGeoContext mapGeo(
        ErpRawResponseDto.Geo g
    ) {
        if (g == null) return null;

        DelivServiceDTO.ErpGeoContext geo =
            new DelivServiceDTO.ErpGeoContext();

        geo.placeCurrent = g.placeCurrent;
        geo.placeFrom = g.placeFrom;
        geo.placeTo = g.placeTo;

        return geo;
    }

    // =====================================================
    // VEHICLE LABEL
    // =====================================================
    private static String resolveVehicleLabel(
        ErpRawResponseDto.Vehicle v
    ) {
        if (v == null) return null;

        if (v.auto != null) {
            return 'truck ' + v.auto.plate;
        }
        if (v.railway != null) {
            return 'wagon ' + v.railway.wagon;
        }
        if (v.vessel != null) {
            return 'vessel ' + v.vessel.seaBooking;
        }
        return null;
    }

    // =====================================================
    // HELPER
    // =====================================================
    private static Datetime parseGmt(String isoDate) {
        if (String.isBlank(isoDate)) {
            return null;
        }

        // ISO-8601 → Apex format
        // 2025-08-12T07:54:29Z
        // -> 2025-08-12 07:54:29
        String normalized = isoDate;

        // remove Z
        if (normalized.endsWith('Z')) {
            normalized = normalized.substring(0, normalized.length() - 1);
        }

        // replace T with space
        normalized = normalized.replace('T', ' ');

        try {
            return Datetime.valueOfGmt(normalized);
        } catch (Exception e) {
            System.debug(
                LoggingLevel.ERROR,
                'Failed to parse datetime (normalized): ' + normalized
            );
            return null;
        }
    }

    private static String resolveShipTypeDevName(
        ErpRawResponseDto.Vehicle v
    ) {
        if (v == null || String.isBlank(v.typeCode)) {
            return null;
        }

        initShipTypeCache();

        String devName = shipTypeByErpCode.get(v.typeCode);

        if (devName == null) {
            System.debug(
                LoggingLevel.WARN,
                'Unknown ERP shipTypeCode: ' + v.typeCode
            );
        }

        return devName;
    }

    // Cache: ERP typeCode -> ShipmentType DeveloperName
    private static Map<String, String> shipTypeByErpCode;

    private static void initShipTypeCache() {
        if (shipTypeByErpCode != null) {
            return;
        }

        shipTypeByErpCode = new Map<String, String>();

        for (ShipmentType__mdt st : [
            SELECT DeveloperName, ID__c
            FROM ShipmentType__mdt
            WHERE IsActive__c = true
        ]) {
            if (String.isNotBlank(st.ID__c)) {
                shipTypeByErpCode.put(st.ID__c, st.DeveloperName);
            }
        }
    }

}