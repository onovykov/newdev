public class ProdTypeGroup3Repository {

    private static Map<Id, ProdType_Group3__c> allById;
    private static Map<String, ProdType_Group3__c> allByCompositeKey;

    private static Boolean isLoaded = false;

    //====================================================
    public static void loadAll() {
        if (isLoaded) return;

        allById = new Map<Id, ProdType_Group3__c>();
        allByCompositeKey = new Map<String, ProdType_Group3__c>();

        for (ProdType_Group3__c rec : [
            SELECT
                Id,
                ProductType__r.Code__c,
                ProductType__r.ShortName__c,
                ProductType__r.Name,
                Group3__c,
                Product2Id__c,
                Product2Id__r.Name,
                ProductType__c,
                CompositeKey__c
            FROM ProdType_Group3__c
            WHERE Product2Id__c != null
            AND ProductType__c != null
            AND CompositeKey__c != null
        ]) {
            allById.put(rec.Id, rec);

            if (!String.isBlank(rec.CompositeKey__c)) {
                allByCompositeKey.put(rec.CompositeKey__c, rec);
            }
        }

        isLoaded = true;
    }

    //====================================================
    public static ProdType_Group3__c getById(Id id) {
        loadAll();
        return allById.get(id);
    }

    //====================================================
    public static ProdType_Group3__c getByCompositeKey(String compositeKey) {
        loadAll();

        if (String.isBlank(compositeKey)) {
            return null;
        }

        return allByCompositeKey.get(compositeKey);
    }

    //====================================================
    public static ProdType_Group3__c getByProductAndType(
        Id product2Id,
        Id productTypeId
    ) {
        if (product2Id == null || productTypeId == null) {
            return null;
        }

        String compositeKey = buildCompositeKey(product2Id, productTypeId);

        return getByCompositeKey(compositeKey);
    }

    //====================================================
    public static ProdType_Group3__c getByErpGroupAndTypeCode(
        String group3ErpCode,
        String productTypeCode
    ) {
        if (String.isBlank(group3ErpCode) || String.isBlank(productTypeCode)) {
            return null;
        }

        Id product2Id = Product2Repository.getIdByErp(group3ErpCode.trim());
        Id productTypeId = ProdTypeRepository.getIdByCode(productTypeCode.trim());

        return getByProductAndType(product2Id, productTypeId);
    }

    //====================================================
    public static ProdType_Group3__c getByErpGroupAndKmat(
        String group3ErpCode,
        String kmat
    ) {
        String productTypeCode = extractProductTypeCodeFromKmat(kmat);

        return getByErpGroupAndTypeCode(group3ErpCode, productTypeCode);
    }

    //====================================================
    public static String extractProductTypeCodeFromKmat(String kmat) {
        if (String.isBlank(kmat)) {
            return null;
        }

        String normalized = kmat.trim();

        if (normalized.length() < 2) {
            return null;
        }

        return normalized.substring(0, 2);
    }

    //====================================================
    public static String buildCompositeKey(Id product2Id, Id productTypeId) {
        if (product2Id == null || productTypeId == null) {
            return null;
        }

        return String.valueOf(product2Id) + '_' + String.valueOf(productTypeId);
    }

    //====================================================
    public static List<ProdType_Group3__c> getAll() {
        loadAll();
        return new List<ProdType_Group3__c>(allById.values());
    }

    //====================================================
    public static void clearCache() {
        isLoaded = false;
        allById = null;
        allByCompositeKey = null;
    }

    //====================================================
    public static void refresh() {
        clearCache();
        loadAll();
    }
}