public class DeliveryHistoryService {
    //--- будуємо історію з групуванням по фазах
    public static List<DelivServiceDTO.HistoryItemDto>
        buildHistory(DelivServiceDTO.ErpDeliveryDto dto) {

        List<DelivServiceDTO.HistoryItemDto> result =
            new List<DelivServiceDTO.HistoryItemDto>();

        // -------- SHIPMENT --------
        if (dto.shipmentInfo != null && dto.shipmentInfo.events != null) {
            for (DelivServiceDTO.ErpEvent e : dto.shipmentInfo.events) {
                result.add(
                    buildItem(
                        e,
                        dto.shipmentInfo.vehicle,
                        false
                    )
                );
            }
        }

        // -------- DELIVERY --------
        if (dto.deliveryInfo != null && dto.deliveryInfo.events != null) {
            for (DelivServiceDTO.ErpEvent e : dto.deliveryInfo.events) {
                result.add(
                    buildItem(
                        e,
                        dto.deliveryInfo.vehicle,
                        true
                    )
                );
            }
        }

        result.sort(new HistoryItemDateComparator());
        return result;
    }
    //--- Хелпер - побудова одного ітема історії
    private static DelivServiceDTO.HistoryItemDto buildItem(
        DelivServiceDTO.ErpEvent e,
        String transport,
        Boolean isDelivery
    ) {
        DelivServiceDTO.HistoryItemDto h =
            new DelivServiceDTO.HistoryItemDto();

        h.dt = e.dt;
        h.phase = isDelivery ? 'DELIVERY' : 'SHIPMENT';
        h.transportLabel = transport;
        h.isDeliveryPhase = isDelivery;

        h.statusLabel =
            DelivStatusService.buildStatus(
                e.eventCode,
                e.locationCode,
                e.shipTypeCode
            );

        if (e.geo != null) {
            h.placeCurrent = e.geo.placeCurrent;
            h.placeFrom    = e.geo.placeFrom;
            h.placeTo      = e.geo.placeTo;
        }

        h.description = h.statusLabel;
        return h;
    }

    //Групуємо хістори подій по phase (SHIPMENT/DELIVERY)
    public static Map<String, Map<Integer, DelivServiceDTO.HistoryItemDto>>
        groupHistoryByPhase(List<DelivServiceDTO.HistoryItemDto> history) {

        Map<String, Map<Integer, DelivServiceDTO.HistoryItemDto>> result =
            new Map<String, Map<Integer, DelivServiceDTO.HistoryItemDto>>();

        // якщо history вже відсортований по dt ↑ — ідеально
        for (DelivServiceDTO.HistoryItemDto item : history) {

            if (String.isBlank(item.phase)) {
                continue; // safety
            }

            // 1️. Ініціалізуємо фазу
            if (!result.containsKey(item.phase)) {
                result.put(
                    item.phase,
                    new Map<Integer, DelivServiceDTO.HistoryItemDto>()
                );
            }

            Map<Integer, DelivServiceDTO.HistoryItemDto> phaseMap =
                result.get(item.phase);

            // 2️. Наступний порядковий номер
            Integer nextIndex = phaseMap.size() + 1;

            phaseMap.put(nextIndex, item);
        }
        return result;
    }

    // History з сортуванням по phase та подіях A->Z / Z->A
    public static Map<String, List<DelivServiceDTO.HistoryItemDto>>
        buildHistoryByPhase(
            DelivServiceDTO.ErpDeliveryDto dto, //<===
            Boolean ascending
        ) {

        // 1) build flat history list
        List<DelivServiceDTO.HistoryItemDto> history =
            buildHistory(dto);

        // 2) sort A->Z, або Z->A
        history.sort(new HistoryItemDateComparator());

        if (!ascending) {
            history = reverseHistory(history);
        }

        // 3) group into UI contract
        Map<String, List<DelivServiceDTO.HistoryItemDto>> out =
            new Map<String, List<DelivServiceDTO.HistoryItemDto>>();

        out.put('SHIPMENT', new List<DelivServiceDTO.HistoryItemDto>());
        out.put('DELIVERY', new List<DelivServiceDTO.HistoryItemDto>());

        for (DelivServiceDTO.HistoryItemDto item : history) {
            String phase = String.isBlank(item.phase) ? 'UNKNOWN' : item.phase;

            if (!out.containsKey(phase)) {
                out.put(phase, new List<DelivServiceDTO.HistoryItemDto>());
            }

            out.get(phase).add(item);
        }

        return out;
    }

    //--- Перевизначений метод на параметр List<DelivServiceDTO.HistoryItemDto>
    public static Map<String, List<DelivServiceDTO.HistoryItemDto>>
        buildHistoryByPhase(
            List<DelivServiceDTO.HistoryItemDto> history, //<===
            Boolean ascending
        ) {

        if (history == null) {
            history = new List<DelivServiceDTO.HistoryItemDto>();
        }

        history.sort(new HistoryItemDateComparator());

        if (!ascending) {
            history = reverseHistory(history); // або inline reverse
        }

        Map<String, List<DelivServiceDTO.HistoryItemDto>> out =
            new Map<String, List<DelivServiceDTO.HistoryItemDto>>();

        out.put('SHIPMENT', new List<DelivServiceDTO.HistoryItemDto>());
        out.put('DELIVERY', new List<DelivServiceDTO.HistoryItemDto>());

        for (DelivServiceDTO.HistoryItemDto item : history) {
            String phase = String.isBlank(item.phase) ? 'UNKNOWN' : item.phase;

            if (!out.containsKey(phase)) {
                out.put(phase, new List<DelivServiceDTO.HistoryItemDto>());
            }

            out.get(phase).add(item);
        }

        return out;
    }
    // Перебудувати історію (було A->Z - стало Z->A; було Z->A - стало A->Z)
    private static List<DelivServiceDTO.HistoryItemDto> reverseHistory(
        List<DelivServiceDTO.HistoryItemDto> input
    ) {
        List<DelivServiceDTO.HistoryItemDto> reversed =
            new List<DelivServiceDTO.HistoryItemDto>();

        if (input == null) {
            return reversed;
        }

        for (Integer i = input.size() - 1; i >= 0; i--) {
            reversed.add(input[i]);
        }

        return reversed;
    }

}