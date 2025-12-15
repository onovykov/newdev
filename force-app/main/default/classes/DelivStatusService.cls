public class DelivStatusService {

    /**************** Хелпери ****************/

    // Коректність коду події
    public static Boolean isEventCodeCorrect(Integer eventCode) {
        return ![
            SELECT Id
            FROM ShipmentEvent__mdt
            WHERE Code__c = :eventCode
            LIMIT 1
        ].isEmpty();
    }

    // Коректність коду типу транспорту
    public static Boolean isShipTypeCorrect(String shipTypeCode) {
        return ![
            SELECT Id
            FROM ShipmentType__mdt
            WHERE ID__c = :shipTypeCode
            LIMIT 1
        ].isEmpty();
    }

    /**************** Cached maps ****************/

    // Мапа типів транспорту
    public static Map<String, String> mapShipTypes = new Map<String, String>();
    static {
        for (ShipmentType__mdt st : [
            SELECT ID__c, DeveloperName
            FROM ShipmentType__mdt
        ]) {
            mapShipTypes.put(st.ID__c, st.DeveloperName);
        }
    }

    // Мапа подій
    public static Map<Integer, String> mapEvents = new Map<Integer, String>();
    static {
        for (ShipmentEvent__mdt se : [
            SELECT Code__c, DeveloperName
            FROM ShipmentEvent__mdt
        ]) {
            if (se.Code__c != null) {
                mapEvents.put(Integer.valueOf(se.Code__c), se.DeveloperName);
            }
        }
    }

    // Мапа дефолтних статусів
    public static Map<Integer, String> mapEventDefStatus = new Map<Integer, String>();
    static {
        for (ShipmentEvent__mdt se : [
            SELECT Code__c, DefaultStatus__c
            FROM ShipmentEvent__mdt
        ]) {
            if (se.Code__c != null) {
                mapEventDefStatus.put(Integer.valueOf(se.Code__c), se.DefaultStatus__c);
            }
        }
    }

    /**************** Основний метод ****************/

    public static String getDelivStatusName(Integer eventCode, String shipTypeCode) {

        String statusLabel = '';

        // Валідація параметрів
        if (!isEventCodeCorrect(eventCode) || !isShipTypeCorrect(shipTypeCode)) {
            System.debug(
                LoggingLevel.WARN,
                String.format(
                    'Invalid parameters: eventCode={0}, shipTypeCode={1}',
                    new List<Object>{ eventCode, shipTypeCode }
                )
            );
            return statusLabel;
        }

        // Отримуємо можливі Event_Status
        List<Event_Status__mdt> eventStatusList = [
            SELECT DeveloperName
            FROM Event_Status__mdt
            WHERE ShipmentEvent__r.DeveloperName = :mapEvents.get(eventCode)
        ];

        Set<String> eventStatusSet = new Set<String>();
        for (Event_Status__mdt ev : eventStatusList) {
            eventStatusSet.add(ev.DeveloperName);
        }

        // Якщо немає статусів — одразу дефолт
        if (eventStatusSet.isEmpty()) {
            return mapEventDefStatus.get(eventCode);
        }

        // Отримуємо статус з урахуванням типу транспорту
        List<Event_Status_ShipType__mdt> mapList = [
            SELECT
                Event_Status__r.ShipmentStatus__r.MasterLabel,
                Event_Status__r.ShipmentStatus__r.Code__c
            FROM Event_Status_ShipType__mdt
            WHERE Event_Status__r.DeveloperName IN :eventStatusSet
              AND ShipmentType__r.DeveloperName = :mapShipTypes.get(shipTypeCode)
            LIMIT 1
        ];

        if (!mapList.isEmpty()) {
            statusLabel = mapList[0]
                .Event_Status__r
                .ShipmentStatus__r
                .MasterLabel;
        } else {
            // fallback на дефолтний статус події
            statusLabel = mapEventDefStatus.get(eventCode);
        }

        return statusLabel;
    }
}