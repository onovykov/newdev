public class DelivStatusService {
    /**************** Хелпери ****************/
    // Коректність коду події
    public static Boolean isEventCodeCorrect(Decimal eventCode) {
        return ![
            SELECT Id
            FROM ShipmentEvent__mdt
            WHERE Code__c = :eventCode
            LIMIT 1
        ].isEmpty();
    }
    // Коректність коду типу транспорту Shipment Types
    public static Boolean isShipTypeCorrect(String shipTypeCode) {
        return ![
            SELECT Id
            FROM ShipmentType__mdt
            WHERE ID__c = :shipTypeCode
            LIMIT 1
        ].isEmpty();
    }
    // Мапа типів транспорту
    public static Map<String, String> mapShipTypes;
    static {
        mapShipTypes = new Map<String, String>();
        for(ShipmentType__mdt st : [SELECT
                                    ID__c, DeveloperName
                                    FROM ShipmentType__mdt]) {
            mapShipTypes.put(st.ID__c, st.DeveloperName);
        }
    }
    // Мапа подій Shipmet Events
    public static Map<Integer, String> mapEvents;
    static {
        mapEvents = new Map<Integer, String>();
        for(ShipmentEvent__mdt se : [SELECT
                                    Code__c, DeveloperName
                                    FROM ShipmentEvent__mdt]) {
            mapEvents.put(Integer.valueOf(se.Code__c), se.DeveloperName);
        }
    }
    // Мапа дефолтних статусів для подій
    public static Map<Integer, String> mapEventDefStatus;
    static {
        mapEventDefStatus = new Map<Integer, String>();
        for(ShipmentEvent__mdt se : [SELECT
                                    Code__c, DefaultStatus__c
                                    FROM ShipmentEvent__mdt]) {
            mapEventDefStatus.put(Integer.valueOf(se.Code__c), se.DefaultStatus__c);
        }
    } 

    /**************** Основний метод  ***************/
    public static String getDelivStatusName(Integer eventCode, String shipTypeCode) {
        String eventDevName = mapEvents.get(eventCode);
        String shipTypeDevName = mapShipTypes.get(shipTypeCode);
        // Справдимо, чи є коректними параметри
        if (eventDevName == null || shipTypeDevName == null) {
            System.debug(LoggingLevel.WARN,
                String.format('Invalid parameters: eventCode={0}, shipTypeCode={1}',
                    new List<Object>{ eventCode, shipTypeCode }
                )
            );
            return '';
        }
        // Отримуємо перелік значень  Event_Status__r.DeveloperName -
        // всі можливі поєднання Event-Status
        List<Event_Status__mdt> eventStatusList = [
            SELECT DeveloperName
            FROM Event_Status__mdt
            WHERE ShipmentEvent__c = :eventDevName
        ];
        // Якщо лист порожній - повертаємо дефолтне значення статусу
        if (eventStatusList.isEmpty()) {
            return mapEventDefStatus.get(eventCode);
        }
        // Формуємо сет Event_Status__mdt.DeveloperName для побудови реляцій
        Set<String> eventStatusSet = new Set<String>();
        for (Event_Status__mdt ev : eventStatusList) eventStatusSet.add(ev.DeveloperName);

        // Формуємо остаточне значення статусу
        List<Event_Status_ShipType__mdt> mapList = [
            SELECT Event_Status__r.ShipmentStatus__r.MasterLabel
            FROM Event_Status_ShipType__mdt
            WHERE Event_Status__r.DeveloperName IN :eventStatusSet
              AND ShipmentType__c = :shipTypeDevName
            LIMIT 1
        ];

        if (!mapList.isEmpty()) {
            return mapList[0].Event_Status__r.ShipmentStatus__r.MasterLabel;
        }

        return mapEventDefStatus.get(eventCode);
    }
}