public class ProdTypeRepository {

    private static Map<Id, ProductType__c> allProdTypesById;
    private static Map<String, ProductType__c> allProdTypesByCode;
	private static Map<String, ProductType__c> allProdTypesByNormCode;

    private static Boolean isLoaded = false;

    //====================================================
    public static void loadAllProdTypes() {
        if (isLoaded) return;

        // Re-init core maps
        allProdTypesById   = new Map<Id, ProductType__c>();
        allProdTypesByCode  = new Map<String, ProductType__c>();
        allProdTypesByNormCode = new Map<String, ProductType__c>();

        // Single SOQL + index population
        for (ProductType__c pt : [
            SELECT
            Id, Name, ShortName__c, Code__c,NormalizedCode__c,IsActive__c
            FROM ProductType__c
        ]) {
            // 1) Index by Id
            allProdTypesById.put(pt.Id, pt);

            // 2) Index by Code__c
            if (!String.isBlank(pt.Code__c)) {
                allProdTypesByCode.put(pt.Code__c, pt);
            }

            // 3) Index by NormalizedCode__c
            if (!String.isBlank(pt.NormalizedCode__c)) {
                allProdTypesByNormCode.put(pt.NormalizedCode__c, pt);
            }
        }

        isLoaded = true;
    }

    //--- Повертаємо ProdType по Id
    public static ProductType__c getById(Id id) {
        loadAllProdTypes();
        return allProdTypesById.get(id);
    }

    //--- Повертаємо ProdType по Code__c
    public static ProductType__c getByCode(String code) {
        loadAllProdTypes();
        return allProdTypesByCode.get(code);
    }

    //--- Повертаємо ProdType по NormalizedCode__c
    public static ProductType__c getByNormCode(String normNode) {
        loadAllProdTypes();
        return allProdTypesByNormCode.get(normNode);
    }

    //--- Вибираємо всі ProdType
    public static List<ProductType__c> getAllProdTypes() {
        loadAllProdTypes();
        return new List<ProductType__c>(allProdTypesById.values());
    }

    //--- ProdType.Id по Code__c
    public static Id getIdByCode(String code) {
        loadAllProdTypes();
        ProductType__c pt = allProdTypesByCode.get(code);
        return(pt == null ? null : pt.Id);
    }

    //--- ProdType.Id по NormalizedCode__c
    public static Id getIdByNormCode(String normCode) {
        loadAllProdTypes();
        ProductType__c pt = allProdTypesByNormCode.get(normCode);
        return(pt == null ? null : pt.Id);
    }

    //--- Чистимо кеш
    public static void clearCache() {
        isLoaded = false;
        allProdTypesById = null;
        allProdTypesByCode = null;
        allProdTypesByNormCode = null;
    }

    public static void refresh() {
        clearCache();
        loadAllProdTypes();
    }
}