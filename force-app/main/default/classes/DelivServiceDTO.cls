public class DelivServiceDTO {

    // ===============================
    // ROOT
    // ===============================
    public class ErpDeliveryDto {
        public ErpShipmentInfo shipmentInfo;
        public ErpDeliveryInfo deliveryInfo;
    }

    // ===============================
    // SHIPMENT
    // ===============================
    public class ErpShipmentInfo {
        public String vehicle;
        public List<ErpEvent> events;
    }

    // ===============================
    // DELIVERY
    // ===============================
    public class ErpDeliveryInfo {
        public String vehicle;
        public String destination;
        public Datetime estimatedArrivalDate;
        public List<ErpEvent> events;
    }

    // ===============================
    // EVENT
    // ===============================
    public class ErpEvent {
        public Datetime dt;
        public String eventCode;
        public String locationCode;
        public String shipTypeCode;
        public ErpGeoContext geo;
    }

    // ===============================
    // GEO
    // ===============================
    public class ErpGeoContext {
        public String placeCurrent;
        public String placeFrom;
        public String placeTo;
    }

    // ===============================
    // SEGMENT (UI)
    // ===============================
    public class DeliverySegmentDto {
        public String segmentId;
        public Boolean isDeliveryPhase;
        public String segmentType;
        public String title;
        public String transportLabel;
        public String reference;
        public String fromPlace;
        public String toPlace;
        public String currentStatus;
        public Datetime eta;
        public Integer progressPercent;
        public Boolean isDelayed;
    }

    // ===============================
    // HISTORY
    // ===============================
    public class HistoryBlock {
        public Datetime dt;
        public String transport;
        public String eventText;
        public String placeFrom;
        public String placeTo;
        public String destination;
        public String phase;
    }
    public class HistoryItemDto {
        public Datetime dt;

        public String phase;            // 'SHIPMENT' | 'DELIVERY'
        public String transportLabel;   // truck #..., vessel bookong

        public String eventCode;
        public String locationCode;

        public String statusLabel;      // готовий людський текст
        public String placeCurrent;
        public String placeFrom;
        public String placeTo;
        public Boolean isDeliveryPhase;
        public String description;      // можна = statusLabel (на старті)
    }
}