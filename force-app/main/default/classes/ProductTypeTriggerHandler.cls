public with sharing class ProductTypeTriggerHandler {

    public static void handleBefore(
        List<ProductType__c> newList,
        Map<Id, ProductType__c> oldMap,
        Boolean isInsert,
        Boolean isUpdate
    ) {
        if (newList == null || newList.isEmpty()) {
            return;
        }
        for (ProductType__c rec : newList) {
            String newCode = rec.Code__c;
            // 1. Пропускаємо null / blank
            if (String.isBlank(newCode)) {
                rec.NormalizedCode__c = null;
                continue;
            }
            // 2. Пропускаємо ті, ще не змінилися (only for update)
            if (isUpdate && oldMap != null) {
                ProductType__c oldRec = oldMap.get(rec.Id);

                if (oldRec != null && newCode == oldRec.Code__c) {
                    continue;
                }
            }
            // 3. safe encode
            rec.NormalizedCode__c = safeEncode(newCode);
        }
    }

    private static String safeEncode(String code) {
        try {
            return CanonicalKeyService.encode(code);
        } catch (Exception e) {
            // логіку можна змінити:
            // або null, або щось інше
            System.debug('Encoding failed: ' + e.getMessage());
            return null;
        }
    }
}
