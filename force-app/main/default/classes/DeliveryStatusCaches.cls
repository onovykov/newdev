public with sharing class DeliveryStatusCaches {
    //--- Повертаємо назву MeasUnit по коду 
    public static String getMeasUnitByCode(String code) {
		if (String.isBlank(code)) return '';
        Map<String, String> valueLabelMap = SysUtils.getPicklistFieldMap('OrderItem', 'MeasUnit__c', true);
		return valueLabelMap.containsKey(code) ? String.valueOf(valueLabelMap.get(code)) : '';
    }
	//--- Перевіряємо, чи існує одиниця виміру (по коду)
    public static Boolean measUnitExists(String code) {
        return !String.isBlank(getMeasUnitByCode(code));
    }
	
    //--- Кеш репо ShipmentType__mdt
    private static Map<String, String> mapShipTypes; // code -> name
    private static Boolean isLoadedST = false;

    public static void loadAllShipTypes() {
        if(isLoadedST) return;
		mapShipTypes = new Map<String, String>();
        List<ShipmentType__mdt> stList = [SELECT ID__c,Name__c FROM ShipmentType__mdt];
        if(!stList.isEmpty()) {
            for(ShipmentType__mdt st : stList) {
               mapShipTypes.put(st.ID__c, st.Name__c);
            }
        }
        isLoadedST = true;
    }

    public static String getShipTypeByCode(String code) {
        if (String.isBlank(code)) return '';
        loadAllShipTypes();
        String key = code.trim().toUpperCase();
        return mapShipTypes != null && mapShipTypes.containsKey(key)
            ? mapShipTypes.get(key)
            : '';
    }

    public static Boolean shipTypeExists(String code) {
        return !String.isBlank(getShipTypeByCode(code));
    }

    public static void clearCacheST() {
        mapShipTypes = null;
        isLoadedST = false;
    }

    public static void refreshST() {
        clearCacheST();
        loadAllShipTypes();
    }
}