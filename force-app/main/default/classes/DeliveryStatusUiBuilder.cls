/*** Builder: DTO → ViewModel ***/
public with sharing class DeliveryStatusUiBuilder {
    /* ==== ISO UTC helper for LWC ====
            Повертаємо дату в ISO 8601 (UTC) для всіх дат, 
            а у фронті (LWC) відображаємо її локалізовано
    */
    private static String toIsoUtc(Datetime dt) {
        return (dt == null) ? null : dt.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
    }

    /*=== Back-End Locale Helpers: локалізуємо дати в бек-енді ===*/
     // 1) Локалізовано для поточного користувача (мова + таймзона профілю)
    private static String fmtDtLocal(Datetime dt) {
        return (dt == null) ? '' : dt.format(); 
        // Використовує локаль та часову зону користувача автоматично
    }

    // 2) Локалізовано, але з власним патерном (та все одно в таймзоні користувача)
    private static String fmtDtLocal(Datetime dt, String pattern) {
        return (dt == null) ? '' : dt.format(pattern, UserInfo.getTimeZone().getID());
        // приклад pattern: 'dd.MM.yyyy HH:mm', 'dd.MM.yyyy', 'HH:mm'
    }

    // 3) Стандартизовано для API/трасування (ISO 8601, UTC)
    private static String fmtDtIsoUtc(Datetime dt) {
        return (dt == null) ? '' : dt.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
    }

    // 4) Лише дата в локалі користувача (без часу)
    private static String fmtDateLocal(Datetime dt) {
        return (dt == null) ? '' : dt.format('yyyy-MM-dd', UserInfo.getTimeZone().getID()).replace('-', '.');
        // або віддємо як є: dt.format('yyyy-MM-dd', UserInfo.getTimeZone().getID())
    }   

    //--- Повертаємо номер ТЗ: або бляху авта, або № вагона, або букинг судна
    private static String vehicleId(DeliveryStatusDTO.VehicleDTO v) {
        if (v == null) return '';
        if (v.auto != null && String.isNotBlank(v.auto.plate)) return v.auto.plate;
        if (v.railway != null && String.isNotBlank(v.railway.wagonNum)) return v.railway.wagonNum;
        if (v.vessel != null && String.isNotBlank(v.vessel.seaBooking)) return v.vessel.seaBooking;
        return v.typeCode;
    }
    //--- Повертаємо назву типу ТЗ по коду
    private static String transportLabel(String code) {
        String lbl = DeliveryStatusCaches.getShipTypeByCode(code);
        return String.isBlank(lbl) ? code : lbl;
    }
    //--- Повертаємо довжину разом з од. вим.
    private static String lenWithUnit(Decimal len, DeliveryStatusDTO.MeasureUnitDTO unit) {
        String unitLabel = unit == null ? '' : DeliveryStatusCaches.getMeasUnitByCode(unit.code);
        if (String.isBlank(unitLabel)) unitLabel = (unit != null ? unit.name : '');
        return (len == null ? '' : String.valueOf(len)) + (String.isBlank(unitLabel) ? '' : ' ' + unitLabel);
    }
    //--- Повертаємо клас статусу StatusVM по статусу з DTO
    private static DeliveryStatusUiModel.StatusVM toStatus(DeliveryStatusDTO.StatusDTO s) {
        DeliveryStatusUiModel.StatusVM vm = new DeliveryStatusUiModel.StatusVM();
        if (s == null) return vm;
        vm.code = s.code;
        vm.label = s.name != null
            ? (!String.isBlank(s.name.uk) ? s.name.uk : (!String.isBlank(s.name.en) ? s.name.en : s.name.defaultText))
            : '';
        // ВАЖЛИВО: повертаємо ISO, а не локальний рядок
        vm.trackedAt = toIsoUtc(s.dateTracking);
        vm.eta       = toIsoUtc(s.estimatedArrivalDate);
        vm.arrivedAt = toIsoUtc(s.arrivedAt);
        if (s.geo != null) {
            // geo як і було: якщо є httpTracking — віддаємо URL; інакше координати
            String place = String.isBlank(s.geo.place) ? '' : ' (' + s.geo.place + ')';
            if (!String.isBlank(s.geo.httpTracking)) {
                vm.geo = s.geo.httpTracking;
            } else if (s.geo.latitude != null || s.geo.longitude != null) {
                vm.geo = String.valueOf(s.geo.latitude) + ', ' + String.valueOf(s.geo.longitude) + place;
            }
        }
        vm.note = s.trackingNote;
        return vm;
    }
    //--- Будуємо UI модель
    public static DeliveryStatusUiModel build(DeliveryStatusDTO dto, List<String> warningsFromValidator) {
        DeliveryStatusUiModel ui = new DeliveryStatusUiModel();
        ui.iteNumber = dto.iteNumber;
        if (warningsFromValidator != null) ui.warnings.addAll(warningsFromValidator);

        for (DeliveryStatusDTO.OrderLineItemDTO oli :
             (dto.orderLineItems == null ? new List<DeliveryStatusDTO.OrderLineItemDTO>() : dto.orderLineItems)) {
            if (oli == null) continue;

            // Packets
            if (oli.packet != null) {
                DeliveryStatusUiModel.PacketVM p = new DeliveryStatusUiModel.PacketVM();
                p.packNum   = oli.packet.packNum;
                p.iteNumber = oli.packet.iteNumber;
                p.certNumber= oli.packet.certNumber;
                p.qtyPcs    = oli.packet.qtyPcs;
                p.qtyTBrutto= oli.packet.qtyTBrutto;
                p.qtyTNetto = oli.packet.qtyTNetto;
                p.length    = lenWithUnit(oli.packet.length, oli.packet.lenMeasUnit);
                ui.packets.add(p);
            }

            // Shipments
            if (oli.shipmentInfo != null) {
                for (DeliveryStatusDTO.ShipmentDTO sh : oli.shipmentInfo) {
                    if (sh == null) continue;
                    DeliveryStatusUiModel.ShipmentVM s = new DeliveryStatusUiModel.ShipmentVM();
                    s.packetKey     = (oli.packet != null) ? (oli.packet.iteNumber + '|' + oli.packet.packNum) : '';
                    s.transportType = transportLabel(sh.shipmentType != null ? sh.shipmentType.code : null);
                    s.transportId   = vehicleId(sh.vehicle);
                    s.dateShipped   = toIsoUtc(sh.dateOtgr); // ISO!
                    s.qtySummary    = 'Pcs: ' + (sh.qtyPcs==null?0:sh.qtyPcs)
                                      + ', Brutto: ' + String.valueOf(sh.qtyTBrutto)
                                      + ', Netto: '  + String.valueOf(sh.qtyTNetto);
                    s.status        = toStatus(sh.status);
                    ui.shipments.add(s);
                }
            }

            // Delivery (aggregate live)
            if (oli.deliveryInfo != null) {
                DeliveryStatusDTO.DeliveryInfoDTO di = oli.deliveryInfo;
                DeliveryStatusUiModel.DeliveryVM d = new DeliveryStatusUiModel.DeliveryVM();
                d.transportType = transportLabel(di.shipmentType != null ? di.shipmentType.code : null);
                d.transportId   = vehicleId(di.vehicle);
                d.status        = toStatus(di.status);
                ui.deliveries.add(d);
            }
        }

        // History
        for (DeliveryStatusDTO.HistoryChainDTO hc :
             (dto.historyChains == null ? new List<DeliveryStatusDTO.HistoryChainDTO>() : dto.historyChains)) {
            if (hc == null) continue;
            DeliveryStatusUiModel.HistoryChainVM h = new DeliveryStatusUiModel.HistoryChainVM();
            h.id = hc.id;
            for (DeliveryStatusDTO.HistoryEventDTO ev :
                 (hc.events == null ? new List<DeliveryStatusDTO.HistoryEventDTO>() : hc.events)) {
                DeliveryStatusUiModel.HistoryEventVM e = new DeliveryStatusUiModel.HistoryEventVM();
                e.timeStamp = toIsoUtc(ev.timeStamp); // ISO!
                e.code      = ev.code;
                e.label     = ev.label;
                h.events.add(e);
            }
            ui.history.add(h);
        }

        return ui;
    }
}