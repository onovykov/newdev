public with sharing class DelivStatusService {

    /* =========================
     * Localization
     * ========================= */

    private static Boolean isUkrainian() {
        String locale = UserInfo.getLocale();
        return locale != null && locale.toLowerCase().startsWith('uk');
    }

    private static String resolveLabel(String enLabel, String uaLabel) {
        if (isUkrainian() && String.isNotBlank(uaLabel)) {
            return uaLabel;
        }
        return enLabel;
    }

    /* =========================
     * Event groups
     * ========================= */

    // Події, де МОЖНА додавати транспорт
    private static final Set<String> IN_THE_EVENTS = new Set<String>{
        'LOADED',
        'DISCHARGED',
        'LOADIND_COMPLETE',
        'LOADING_START',
        'UNLOADING_COMPLETE',
        'UNLOADING_START'
    };

    // Transit-локації
    private static final Set<String> TRANSIT_LOCATIONS = new Set<String>{
        'IN_TRANSIT',
        'EN_ROUTE'
    };

    /* =========================
     * Public API
     * ========================= */

    public static String buildStatus(
        String eventKey,
        String locationKey,
        String shipTypeKey
    ) {
        if (String.isBlank(eventKey) || String.isBlank(locationKey)) {
            return null;
        }

        String eventDevName    = resolveEventDeveloperName(eventKey);
        String locationDevName = resolveLocationDeveloperName(locationKey);
        String shipTypeDevName = resolveShipTypeDeveloperName(shipTypeKey);

        // ---------- 1. FULL: Event + Location + ShipType ----------
        if (String.isNotBlank(shipTypeDevName)) {
            EventLocation__mdt elFull = findEventLocation(
                eventDevName, locationDevName, shipTypeDevName
            );

            if (elFull != null) {
                DeliveryEvent__mdt ev =
                    DeliveryEvent__mdt.getInstance(elFull.Event__r.DeveloperName);

                DeliveryLocation__mdt loc =
                    DeliveryLocation__mdt.getInstance(elFull.Location__r.DeveloperName);

                ShipmentType__mdt ship =
                    ShipmentType__mdt.getInstance(elFull.ShipType__r.DeveloperName);

                return buildStatusLabel(ev, loc, ship);
            }
        }

        // ---------- 2. Event + Location (fallback, але ship дозволений) ----------
        EventLocation__mdt elNoShip = findEventLocationNoShip(
            eventDevName, locationDevName
        );

        if (elNoShip != null) {
            DeliveryEvent__mdt ev =
                DeliveryEvent__mdt.getInstance(elNoShip.Event__r.DeveloperName);

            DeliveryLocation__mdt loc =
                DeliveryLocation__mdt.getInstance(elNoShip.Location__r.DeveloperName);

            ShipmentType__mdt ship =
                String.isNotBlank(shipTypeDevName)
                    ? ShipmentType__mdt.getInstance(shipTypeDevName)
                    : null;

            return buildStatusLabel(ev, loc, ship);
        }

        // ---------- 3. Event-only ----------
        DeliveryEvent__mdt ev = DeliveryEvent__mdt.getInstance(eventDevName);
        if (ev != null) {
            return resolveLabel(ev.MasterLabel, ev.LabelUA__c);
        }

        return null;
    }

    /* =========================
     * Core logic (text builder)
     * ========================= */

    public static String buildStatusLabel(
        DeliveryEvent__mdt eventMdt,
        DeliveryLocation__mdt locationMdt,
        ShipmentType__mdt shipTypeMdt
    ) {
        if (eventMdt == null || locationMdt == null) {
            return null;
        }

        String eventDevName    = eventMdt.DeveloperName;
        String locationDevName = locationMdt.DeveloperName;

        String eventLabel = resolveLabel(
            eventMdt.MasterLabel,
            eventMdt.LabelUA__c
        );

        String locationLabel = resolveLabel(
            locationMdt.MasterLabel,
            locationMdt.LabelUA__c
        );

        // ----- DEPARTURED + TRANSIT -----
        if (eventDevName == 'DEPARTURED'
            && TRANSIT_LOCATIONS.contains(locationDevName)) {
            return locationLabel;
        }

        // ----- Events with transport -----
        if (IN_THE_EVENTS.contains(eventDevName)) {
            String shipHuman = resolveShipTypeHuman(shipTypeMdt);

            if (String.isNotBlank(shipHuman)) {
                return eventLabel + ' ' + shipHuman + ' in the ' + locationLabel;
            }
            return eventLabel + ' in the ' + locationLabel;
        }

        // ----- ARRIVED -----
        if (eventDevName == 'ARRIVED') {
            return eventLabel + ' to the ' + locationLabel;
        }

        // ----- DEPARTURED (non-transit) -----
        if (eventDevName == 'DEPARTURED') {
            return eventLabel + ' the ' + locationLabel;
        }

        return eventLabel + ' ' + locationLabel;
    }

    /* =========================
     * Helpers
     * ========================= */

    private static String resolveShipTypeHuman(ShipmentType__mdt shipTypeMdt) {
        if (shipTypeMdt == null) return null;

        // EN → Name__c (cargo ship / truck / freight train)
        if (!isUkrainian() && String.isNotBlank(shipTypeMdt.Name__c)) {
            return shipTypeMdt.Name__c;
        }

        return shipTypeMdt.MasterLabel;
    }

    /* =========================
     * CMDT lookup (SAFE)
     * ========================= */

    private static EventLocation__mdt findEventLocation(
        String eventDevName,
        String locationDevName,
        String shipTypeDevName
    ) {
        List<EventLocation__mdt> rows = [
            SELECT
                Event__r.DeveloperName,
                Location__r.DeveloperName,
                ShipType__r.DeveloperName
            FROM EventLocation__mdt
            WHERE Event__r.DeveloperName = :eventDevName
              AND Location__r.DeveloperName = :locationDevName
              AND ShipType__r.DeveloperName = :shipTypeDevName
            LIMIT 1
        ];
        return rows.isEmpty() ? null : rows[0];
    }

    private static EventLocation__mdt findEventLocationNoShip(
        String eventDevName,
        String locationDevName
    ) {
        List<EventLocation__mdt> rows = [
            SELECT
                Event__r.DeveloperName,
                Location__r.DeveloperName
            FROM EventLocation__mdt
            WHERE Event__r.DeveloperName = :eventDevName
              AND Location__r.DeveloperName = :locationDevName
            LIMIT 1
        ];
        return rows.isEmpty() ? null : rows[0];
    }

    /* =========================
     * Resolver stubs (ERP)
     * ========================= */

    private static String resolveEventDeveloperName(String eventKey) {
        return eventKey;
    }

    private static String resolveLocationDeveloperName(String locationKey) {
        return locationKey;
    }

    private static String resolveShipTypeDeveloperName(String shipTypeKey) {
        return shipTypeKey;
    }
}