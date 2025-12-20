public class ErpRawResponseDto {

    public Integer idErp;
    public String iteNumber;
    public Boolean success;
    public String comments;

    public List<OrderLineItem> orderLineItems;

    // =========================
    // ORDER LINE ITEM
    // =========================
    public class OrderLineItem {
        public Packet packet;
        public ShipmentInfo shipmentInfo;
        public DeliveryInfo deliveryInfo;
    }

    public class Packet {
        public String packNum;
        public String iteNumber;
        public String certNumber;
        public Decimal qtyPcs;
        public Decimal qtyTBrutto;
        public Decimal qtyTNetto;
        public Decimal length;
    }

    // =========================
    // SHIPMENT
    // =========================
    public class ShipmentInfo {
        public String dateOtgr;
        public Decimal qtyPcs;
        public Decimal qtyTBrutto;
        public Decimal qtyTNetto;
        public Decimal length;
        public Vehicle vehicle;
        public List<ShipmentEvent> events;
    }

    // =========================
    // DELIVERY
    // =========================
    public class DeliveryInfo {
        public Vehicle vehicle;
        public List<DeliveryEvent> events;
    }

    // =========================
    // VEHICLE
    // =========================
    public class Vehicle {
        public String typeCode; // 2=Auto, 3=Railway, A=Vessel
        public Auto auto;
        public Railway railway;
        public Vessel vessel;
    }

    public class Auto {
        public String plate;
    }

    public class Railway {
        public String wagon;
    }

    public class Vessel {
        public String seaBooking;
        public String terminal;
        public String destination;
        public String estimatedArrivalDate;
    }

    // =========================
    // EVENTS
    // =========================
    public class ShipmentEvent {
        public String code;
        public String location;
        public String dateTracking;
        public Geo geo;
        public String trackingNote;
    }

    public class DeliveryEvent {
        public String code;
        public String location;
        public String dateTracking;
        public Geo geo;
        public String trackingNote;
    }

    // =========================
    // GEO
    // =========================
    public class Geo {
        public Decimal latitude;
        public Decimal longitude;
        public String placeCurrent;
        public String placeFrom;
        public String placeTo;
        public String httpTracking;
    }
}