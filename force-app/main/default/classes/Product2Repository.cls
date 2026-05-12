public class Product2Repository {

    private static Map<Id, Product2> allProdsById;
    private static Map<String, Product2> allProdsByErp;

    private static Boolean isLoaded = false;

    //====================================================
    public static void loadAllProds() {
        if (isLoaded) return;

        // Re-init core maps
        allProdsById   = new Map<Id, Product2>();
        allProdsByErp  = new Map<String, Product2>();

        // Single SOQL + index population
        for (Product2 pt : [
            SELECT
            Id, Type__c, Family, Name, Dencity__c, Material__c,ID_ERP__c
            FROM Product2
        ]) {
            // 1) Index by Id
            allProdsById.put(pt.Id, pt);

            // 2) Index by ID_ERP__c
            if (!String.isBlank(pt.ID_ERP__c)) {
                allProdsByErp.put(pt.ID_ERP__c, pt);
            }
        }
        isLoaded = true;
    }

    //--- Повертаємо по Id
    public static Product2 getById(Id id) {
        loadAllProds();
        return allProdsById.get(id);
    }

    //--- Повертаємо по ID_ERP__c
    public static Product2 getByErp(String erpId) {
        loadAllProds();
        return allProdsByErp.get(erpId);
    }

    //--- Вибираємо всі Products
    public static List<Product2> getAllProds() {
        loadAllProds();
        return new List<Product2>(allProdsById.values());
    }
    
    //--- Product2.Id по коду ID_ERP__c
    public static Id getIdByErp(String erpId) {
        loadAllProds();
        Product2 p = allProdsByErp.get(erpId);
        return (p != null) ? p.Id : null;
    }

    //--- Чистимо кеш
    public static void clearCache() {
        isLoaded = false;
        allProdsById = null;
        allProdsByErp = null;
    }

    public static void refresh() {
        clearCache();
        loadAllProds();
    }
}
