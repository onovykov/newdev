public with sharing class DeliverySegmentService {
    /* =========================================================
     * PUBLIC API
     * ========================================================= */

    public static List<DelivServiceDTO.DeliverySegmentDto>
        buildSegmentsFromErpJson(String jsonStr) {

        DelivServiceDTO.ErpDeliveryDto erp =
            (DelivServiceDTO.ErpDeliveryDto)
                JSON.deserialize(jsonStr, DelivServiceDTO.ErpDeliveryDto.class);

        return buildSegmentsFromDto(erp);
    }

    public static List<DelivServiceDTO.DeliverySegmentDto>
        buildSegmentsFromDto(DelivServiceDTO.ErpDeliveryDto erp) {

        List<DelivServiceDTO.DeliverySegmentDto> segments =
            new List<DelivServiceDTO.DeliverySegmentDto>();

        // -----------------------------------------------------
        // Shipment segments
        // -----------------------------------------------------
        if (erp.shipmentInfo != null && erp.shipmentInfo.events != null) {
            segments.addAll(
                buildShipmentSegments(erp.shipmentInfo)
            );
        }

        // -----------------------------------------------------
        // Delivery segment (final leg)
        // -----------------------------------------------------
        if (erp.deliveryInfo != null && erp.deliveryInfo.events != null) {
            segments.add(
                buildDeliverySegment(
                    erp.shipmentInfo,
                    erp.deliveryInfo
                )
            );
        }

        return segments;
    }

    /* =========================================================
     * SHIPMENT SEGMENTS
     * ========================================================= */

    private static List<DelivServiceDTO.DeliverySegmentDto>
        buildShipmentSegments(
            DelivServiceDTO.ErpShipmentInfo shipment
        ) {

        List<DelivServiceDTO.DeliverySegmentDto> result =
            new List<DelivServiceDTO.DeliverySegmentDto>();

        // Групуємо події за транспортом (наразі vehicle)
        Map<String, List<DelivServiceDTO.ErpEvent>> byTransport =
            new Map<String, List<DelivServiceDTO.ErpEvent>>();

        for (DelivServiceDTO.ErpEvent e : shipment.events) {
            String key = shipment.vehicle;
            if (!byTransport.containsKey(key)) {
                byTransport.put(
                    key,
                    new List<DelivServiceDTO.ErpEvent>()
                );
            }
            byTransport.get(key).add(e);
        }

        for (String transport : byTransport.keySet()) {
            List<DelivServiceDTO.ErpEvent> events =
                byTransport.get(transport);

            events.sort(new ErpEventDateComparator());

            DelivServiceDTO.ErpEvent first = events[0];
            // DelivServiceDTO.ErpEvent last  = events[events.size() - 1];
            // Отримуємо дату останньої події через ресолвер
            DelivServiceDTO.ErpEvent last = pickLastEvent(events);

            DelivServiceDTO.DeliverySegmentDto seg =
                new DelivServiceDTO.DeliverySegmentDto();

            seg.segmentId = 'SHIPMENT_' + transport;
            seg.isDeliveryPhase = false;

            seg.segmentType =
                detectSegmentType(last.shipTypeCode);

            seg.transportLabel = transport;
            seg.reference      = transport;
            /*
            seg.fromPlace =
                first.geo != null ? first.geo.placeFrom : null;
            seg.toPlace =
                last.geo != null ? last.geo.placeTo : null;
            */
            if (last.geo != null) {
                seg.fromPlace =
                    String.isNotBlank(last.geo.placeFrom)
                        ? last.geo.placeFrom
                        : last.geo.placeCurrent;

                seg.toPlace = last.geo.placeTo;
            }
            seg.title =
                seg.segmentType + ': ' +
                safe(seg.fromPlace) + ' → ' +
                safe(seg.toPlace);

            seg.currentStatus =
                DelivStatusService.buildStatus(
                    last.eventCode,
                    last.locationCode,
                    last.shipTypeCode
                );

            // shipment-фаза не має progress / eta
            seg.progressPercent = null;
            seg.eta = null;

            result.add(seg);
        }

        return result;
    }

    /* =========================================================
     * DELIVERY SEGMENT (FINAL LEG)
     * ========================================================= */
    private static DelivServiceDTO.DeliverySegmentDto
        buildDeliverySegment(
            DelivServiceDTO.ErpShipmentInfo shipment,
            DelivServiceDTO.ErpDeliveryInfo delivery
        ) {

        List<DelivServiceDTO.ErpEvent> events =
            delivery.events;

        events.sort(new ErpEventDateComparator());

        DelivServiceDTO.ErpEvent first = events[0];
        // DelivServiceDTO.ErpEvent last  = events[events.size() - 1];
        // Отримуємо дату останньої події через ресолвер
        DelivServiceDTO.ErpEvent last = pickLastEvent(events);

        DelivServiceDTO.DeliverySegmentDto seg =
            new DelivServiceDTO.DeliverySegmentDto();

        seg.segmentId = 'DELIVERY_MAIN';
        seg.isDeliveryPhase = true;

        seg.segmentType =
            detectSegmentType(last.shipTypeCode);

        seg.transportLabel = delivery.vehicle;
        seg.reference      = delivery.vehicle;

        if (last.geo != null) {
            seg.fromPlace =
                String.isNotBlank(last.geo.placeFrom)
                    ? last.geo.placeFrom
                    : last.geo.placeCurrent;

            seg.toPlace = last.geo.placeTo;
        }

        seg.title =
            seg.segmentType + ': ' +
            safe(seg.fromPlace) + ' → ' +
            safe(seg.toPlace);

        seg.currentStatus =
            DelivStatusService.buildStatus(
                last.eventCode,
                last.locationCode,
                last.shipTypeCode
            );

        seg.eta = delivery.estimatedArrivalDate;

        // ---- Progress calculation ----
        Datetime startDt =
            pickShipmentEndDate(shipment);
        // ETA Date
        Datetime etaDt =
            delivery.estimatedArrivalDate;
        // Current Date
        Datetime nowDt = System.now();  

        Datetime startDate =
            resolveShipmentCompletionDate(
                shipment != null ? shipment.events : null
            );

        seg.progressPercent =
            DeliveryProgressCalculator.calculate(
                startDate,
                delivery.estimatedArrivalDate,
                System.now()
            );
        // delay
        seg.isDelayed =
            isDelayed(
                etaDt,
                nowDt,
                last
            );

        return seg;
    }

    /* =========================================================
    *  HISTORY
    * ========================================================== */
    private static DelivServiceDTO.HistoryItemDto buildHistoryItem(
        DelivServiceDTO.ErpEvent e,
        String transportLabel,
        Boolean isDeliveryPhase
    ) {
        DelivServiceDTO.HistoryItemDto h =
            new DelivServiceDTO.HistoryItemDto();

        h.dt = e.dt;
        h.transportLabel = transportLabel;
        h.isDeliveryPhase = isDeliveryPhase;

        //h.eventLabel =
        h.statusLabel = 
            DelivStatusService.buildStatus(
                e.eventCode,
                e.locationCode,
                e.shipTypeCode
            );

        //h.locationLabel =
        h.locationCode = 
            e.geo != null ? e.geo.placeCurrent : null;

        h.description = h.statusLabel; //h.eventLabel;

        return h;
    }    
    /* =========================================================
     * HELPERS
     * ========================================================= */
    //--- Ресолвер дати останньої події
    private static Datetime resolveShipmentCompletionDate(
        List<DelivServiceDTO.ErpEvent> shipmentEvents
    ) {
        if (shipmentEvents == null || shipmentEvents.isEmpty()) {
            return null;
        }

        Datetime last = shipmentEvents[0].dt;
        for (DelivServiceDTO.ErpEvent e : shipmentEvents) {
            if (e.dt > last) {
                last = e.dt;
            }
        }
        return last;
    }

    //--- Визначає "сегмент доправи" (Sea/Rail/Road)
    private static String detectSegmentType(String shipTypeCode) {
        if (shipTypeCode == 'Vessel')  return 'Sea freight';
        if (shipTypeCode == 'Railway') return 'Rail segment';
        return 'Road delivery';
    }
    //--- Сайфер виводу рядка (перехоплю null)
    private static String safe(String s) {
        return s == null ? '?' : s;
    }

    //--- Визначає, яку саме подію вважати “останньою” для сегмента
    private static DelivServiceDTO.ErpEvent pickLastEvent(
        List<DelivServiceDTO.ErpEvent> events
    ) {
        if (events == null || events.isEmpty()) {
            return null;
        }

        // defensive copy (на майбутнє)
        List<DelivServiceDTO.ErpEvent> sorted =
            new List<DelivServiceDTO.ErpEvent>(events);

        sorted.sort(new ErpEventDateComparator());
        return sorted[sorted.size() - 1];
    }

    //--- Знайти Start Date
    private static Datetime pickShipmentEndDate(
        DelivServiceDTO.ErpShipmentInfo shipment
    ) {
        if (shipment == null || shipment.events == null || shipment.events.isEmpty()) {
            return null;
        }

        List<DelivServiceDTO.ErpEvent> events =
            new List<DelivServiceDTO.ErpEvent>(shipment.events);

        events.sort(new ErpEventDateComparator());
        return events[events.size() - 1].dt;
    }

    //--- Порахувати progressPercent
    private static Integer calculateProgressPercent(
        Datetime startDt,
        Datetime etaDt,
        Datetime nowDt
    ) {
        if (startDt == null || etaDt == null || nowDt == null) {
            return null;
        }

        Long totalMs = etaDt.getTime() - startDt.getTime();
        if (totalMs <= 0) {
            return 100;
        }

        Long passedMs = nowDt.getTime() - startDt.getTime();

        Decimal progress =
            Decimal.valueOf(passedMs) / Decimal.valueOf(totalMs);

        Integer percent =
            Integer.valueOf(Math.round(progress * 100));

        if (percent < 0) return 0;
        if (percent > 100) return 100;

        return percent;
    }

    //--- Визначити delay
    private static Boolean isDelayed (
        Datetime etaDt,
        Datetime nowDt,
        DelivServiceDTO.ErpEvent lastDeliveryEvent
    ) {
        if (etaDt == null || nowDt == null) {
            return false;
        }

        // якщо ETA вже минула, а доправу ще не завершено (спізнюємося)
        if (nowDt > etaDt) {
            // умовно: якщо остання подія НЕ ARRIVED / DELIVERED
            return lastDeliveryEvent != null
                && lastDeliveryEvent.eventCode != 'ARRIVED'
                && lastDeliveryEvent.eventCode != 'DELIVERED';
        }

        return false;
    }
    /*
    private static DelivServiceDTO.ErpEvent pickLastEvent(
        List<DelivServiceDTO.ErpEvent> events
    ) {
        if (events == null || events.isEmpty()) {
            return null;
        }

        events.sort(new ErpEventDateComparator());
        return events[events.size() - 1];
    }
    */
}