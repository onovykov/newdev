public class CountryRepository {
    private static Map<String, Country__c> countriesA2CodesMap;// <A2Code, Country__c>
    private static Map<String, Country__c> countriesNumCodesMap;
    private static Map<Id, Country__c> countriesMap;
    private static Boolean isLoaded = false;

    public static void loadAllContries() {
        if(isLoaded) return;
        countriesA2CodesMap = new Map<String, Country__c>();
        countriesNumCodesMap = new Map<String, Country__c>();
        countriesMap = new Map<Id, Country__c>();
        List<Country__c> countryList = [SELECT
                                            Id, A2Code__c, A3Code__c, Name, Currency__c, SysName__c,
                                            ID_ERP__c, Market_Segment__c, NumCode__c, PhoneCode__c
                                        FROM Country__c
                                        WHERE A2Code__c!='0'
                                        ];
        if(!countryList.isEmpty()) {
            for(Country__c c: countryList) {
                countriesA2CodesMap.put(c.A2Code__c, c);
                countriesNumCodesMap.put(c.NumCode__c, c);
                countriesMap.put(c.Id, c);
            }
        }
        isLoaded = true;
    }

    public static Country__c getById(Id id) {
        loadAllContries();
        return countriesMap.get(id);
    }

    public static Country__c getByA2Code (String A2Code) {
        loadAllContries();
        return countriesA2CodesMap.get(A2Code);     
    }

     public static Country__c getByNumCode (String NumCode) {
        loadAllContries();
        return countriesNumCodesMap.get(NumCode);       
    }   

     //--- Чистимо кеш
    public static void clearCache() {
        isLoaded = false;
        countriesA2CodesMap = null;
        countriesNumCodesMap = null;
        countriesMap = null;
    }
    //--- Рефрешимо кеш
    public static void refresh() {
        clearCache();
        loadAllContries();
    }   

}