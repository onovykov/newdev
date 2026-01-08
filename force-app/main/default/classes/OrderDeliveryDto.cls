public class OrderDeliveryDto {
    // ---------------- HEADER ----------------
    public Integer orderIdErp;
    public String orderIteNumber;
    public String deliveryMode;
    public List<OrderLineItemDto> orderLineItems;

    public class OrderLineItemDto {
        public String iteNumber;
        public PacketDto packet;
        public ShipmentInfoDto shipmentInfo;
        public DeliveryInfoDto deliveryInfo;
    }

    // ---------------- PACKET ----------------
    public class PacketDto {
        public String packNum;
        public String iteNumber;
        public String certNumber;
        public Integer qtyPcs;
        public Decimal qtyTBrutto;
        public Decimal qtyTNetto;
        public LenMeasUnitDto lenMeasUnit;
        public Decimal length;
    }

    public class LenMeasUnitDto {
        public String eventCode;
        public String name;
    }

    // ---------------- SHIPMENT ----------------
    public class ShipmentInfoDto {
        public List<TransportItemDto> transport;
    }
    public class TransportItemDto {
        public CargoDto cargo;
        public VehicleDto vehicle;
        public List<StatusDto> status;
    }

    public class CargoDto {
        public Integer qtyPcs;
        public Decimal qtyTBrutto;
        public Decimal qtyTNetto;
        public LenMeasUnitDto lenMeasUnit;
        public Decimal length;
    }

    public class VehicleDto {
        public String typeCode;
        public String plate;
    }

    // ---------------- DELIVERY ----------------
    public class DeliveryInfoDto {
        public DeliveryTransportDto transport;
        public List<StatusDto> status;
    }

    public class DeliveryTransportDto {
        public String typeCode;
        public VesselDto vessel;
    }

    public class VesselDto {
        public String seaBooking;
        public String terminal;
        public Datetime departureDate;
        public String destination;
        public Datetime estimatedArrivalDate;
    }

    // ---------------- STATUS / GEO ----------------
    public class StatusDto {
        public String eventCode;
        public String location;
        public Datetime dateTracking;
        public GeoDto geo;
        public String trackingNote;
    }

    public class GeoDto {
        public Decimal latitude;
        public Decimal longitude;
        public String placeCurrent;
        public String placeFrom;
        public String placeTo;
        public String httpTracking;
    }
}