public with sharing class DeliveryStatusDTO {

    public Long idErp;
    public String iteNumber;
    public List<OrderLineItemDTO> orderLineItems;
    public List<HistoryChainDTO> historyChains;
    public Boolean success;
    public String comments;

    public class OrderLineItemDTO {
        public PacketDTO packet;
        public List<ShipmentDTO> shipmentInfo;
        public DeliveryInfoDTO deliveryInfo;
        public List<Integer> historyChainIds;
    }

    public class PacketDTO {
        public String packNum;
        public String iteNumber;
        public String certNumber;
        public Integer qtyPcs;
        public Decimal qtyTBrutto;
        public Decimal qtyTNetto;
        public MeasureUnitDTO lenMeasUnit;
        public Decimal length;
    }

    public class MeasureUnitDTO {
        public String code;
        public String name;
    }

    // Спільна форма події відвантаження
    public class ShipmentDTO {
        public CodeRef shipmentType;      // CMDT code: '2','3','A',...
        public VehicleDTO vehicle;        // поліморфний транспорт
        public StatusDTO status;

        // кількісні поля (для атомарного shipment)
        public Datetime dateOtgr;
        public Integer qtyPcs;
        public Decimal qtyTBrutto;
        public Decimal qtyTNetto;
        public MeasureUnitDTO lenMeasUnit;
        public Decimal length;
    }

    // Агреговане «живе» відстеження
    public class DeliveryInfoDTO {
        public CodeRef shipmentType;
        public VehicleDTO vehicle;
        public StatusDTO status;
    }

    public class CodeRef {
        public String code;
    }

    // РІВЕНЬ 1
    public class VehicleDTO {
        public String typeCode;   // '2' (Auto), '3' (Railway), 'A' (Vessel) ...
        public AutoDTO auto;
        public RailwayDTO railway;
        public VesselDTO vessel;
    }

    // ВИНЕСЕНО ОКРЕМО (типи транспорту)
    public class AutoDTO    { public String plate; }
    public class RailwayDTO { public String wagonNum; }
    public class VesselDTO  {
        public String seaBooking;
        public String terminal;
        public Datetime departureDate;
        public String destination;
        public Datetime estimatedArrivalDate;
    }

    public class StatusDTO {
        public String code;
        public LocalizedNameDTO name;
        public Datetime dateTracking;
        public Datetime estimatedArrivalDate;
        public Datetime arrivedAt;
        public GeoDTO geo;
        public String trackingNote;
    }

    public class LocalizedNameDTO {
        public String en;
        public String uk;
        public String defaultText; // <-- не 'default', бо default - зарезервоване слово!
    }

    public class GeoDTO {
        public Decimal latitude;
        public Decimal longitude;
        public String place;
        public String httpTracking;
    }

    public class HistoryChainDTO {
        public Integer id;
        public List<HistoryEventDTO> events;
    }

    public class HistoryEventDTO {
        public Datetime timeStamp;
        public String code;
        public String label;
    }

    // Helper для десеріалізації
    public static DeliveryStatusDTO fromJson(String body) {
        return (DeliveryStatusDTO) JSON.deserialize(body, DeliveryStatusDTO.class);
    }
}