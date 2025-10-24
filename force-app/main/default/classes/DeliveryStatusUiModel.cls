public with sharing class DeliveryStatusUiModel {
    /****  
    * ViewModel для UI
    * Ідея: віддати фронту готові “плоскі” списки для відмалювання: 
    * пакети, шипменти (лінійка подій), агрегований delivery-стан. 
    * Це буде зручно і для таблиць, і для таймлайнів/мапи
    ****/
    public String iteNumber;
    public List<PacketVM> packets    = new List<PacketVM>();
    public List<ShipmentVM> shipments= new List<ShipmentVM>();
    public List<DeliveryVM> deliveries = new List<DeliveryVM>();
    public List<HistoryChainVM> history = new List<HistoryChainVM>();
    public List<String> warnings = new List<String>();

    public class PacketVM {
        public String packNum;
        public String iteNumber;
        public String certNumber;
        public Integer qtyPcs;
        public Decimal qtyTBrutto;
        public Decimal qtyTNetto;
        public String length;   // '12.0 ft' чи '3.67 m' - вже форматований
    }
    public class ShipmentVM {
        public String packetKey;         // ITE|PACK
        public String transportType;     // label з CMDT
        public String transportId;       // plate / wagon / booking
        public String dateShipped;       // форматовано
        public String qtySummary;        // 'Pcs: 10, Brutto: 12.3, Netto: 12.0'
        public StatusVM status;
    }
    public class DeliveryVM {
        public String transportType;
        public String transportId;
        public StatusVM status;
    }
    public class StatusVM {
        public String code;
        public String label;           // name.uk або name.en або defaultText
        public String trackedAt;
        public String eta;
        public String arrivedAt;
        public String geo;             // "50.45, 30.52 (Kyiv)" або URL-трекінгу
        public String note;
    }
    public class HistoryChainVM {
        public Integer id;
        public List<HistoryEventVM> events = new List<HistoryEventVM>();
    }
    public class HistoryEventVM {
        public String timeStamp;
        public String code;
        public String label;
    }
}