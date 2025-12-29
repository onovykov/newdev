public with sharing class ERPMessageUtils {
    //--- Статична мапа HTTP статусів
    public static Map<Integer, String> httpStatus = new Map<Integer, String>();
    static {
        for(HttpStatus__mdt hs : [SELECT 
                                    Code__c,Status__c
                                FROM HttpStatus__mdt 
                                ORDER BY Code__c ]) {
            httpStatus.put(Integer.valueOf(hs.Code__c), hs.Status__c);                    
        }
    }
    
    public static List<OrderItemStage__mdt> oisList = [
                                        SELECT 
                                          Code__c, StatusSF__c 
                                        FROM OrderItemStage__mdt];
    //--- Статична мапа статусів OrderItems                                    
    public static Map<String, String> itemStatusMap = new Map<String, String>();
    static {
        for(OrderItemStage__mdt m : oisList) {
            itemStatusMap.put(m.Code__c, m.StatusSF__c);
        }
    }   
    //--- Чи статус позиції - це Placed?
    public static boolean checkIfPlaced(String apiName){
        return itemStatusMap.containsKey(apiName);
    }    
    /*** Кеш- репо юзерів */
    public static List<User> usrList = [
        SELECT
        Id, Name, Username, Email, BusinesDivision__c, SalesDivision__c, 
        LoginERP__c, UID_ERP__c, ID_ERP__c, User_Type__c
        FROM User
        WHERE IsActive=true AND User_Type__c IN ('SALES MANAGERS','BACK OFFICE') 
        AND SalesDivision__c!=null AND LoginERP__c!=null        
    ];
    //--- Мапи юзерів, ключ LoginERP__c
    public static Map<String, User> mapSalesUsersByLogin = new Map<String, User>();
    public static Map<String, User> mapBOUsersByLogin = new Map<String, User>();
    //--- Мапи юзерів, ключ LoginERP__c
    public static Map<String, User> mapSalesUsersByIdErp = new Map<String, User>();
    public static Map<String, User> mapBOUsersByIdErp = new Map<String, User>();

    static {
        for(User usr : usrList) {
            if(usr.User_Type__c=='SALES MANAGERS') {
                mapSalesUsersByLogin.put(usr.LoginERP__c, usr);
                mapSalesUsersByIdErp.put(usr.ID_ERP__c, usr);
            } else { // BACK OFFICE
                mapBOUsersByLogin.put(usr.LoginERP__c, usr);
                mapBOUsersByIdErp.put(usr.ID_ERP__c, usr);                
            }
        }
    }
    //========= Хелпери кеша юзерів ===========
    public static User getSaleUserByLogin(String erpLogin) {
        if(String.isBlank(erpLogin)) return new User();
        if(mapSalesUsersByLogin.containsKey(erpLogin)) {
            return mapSalesUsersByLogin.get(erpLogin);
        } 
       return new User();
    }

    public static User getSaleUserByIdErp(String IdErp) {
        if(String.isBlank(IdErp)) return new User();
        if(mapSalesUsersByIdErp.containsKey(IdErp)) {
            return mapSalesUsersByIdErp.get(IdErp);
        } 
       return new User();
    }  

    public static User getBOUserByLogin(String erpLogin) {
        if(String.isBlank(erpLogin)) return new User();
        if(mapBOUsersByLogin.containsKey(erpLogin)) {
            return mapBOUsersByLogin.get(erpLogin);
        } 
       return new User();
    }

    public static User getBOUserByIdErp(String IdErp) {
        if(String.isBlank(IdErp)) return new User();
        if(mapBOUsersByIdErp.containsKey(IdErp)) {
            return mapBOUsersByIdErp.get(IdErp);
        } 
       return new User();
    }

    //--- Статична мапа MarketSegment
    public static Map<String, String> mapSegments = new Map<String, String>();
    public static List<MarketSegment__mdt> mdtMS = [SELECT
                                  Code__c, DeveloperName
                                FROM MarketSegment__mdt];
    static {
        for(MarketSegment__mdt ms : mdtMS) {
            mapSegments.put(ms.Code__c, ms.DeveloperName);
        }
    }

    //--- Ігнор-акаунти
    public static List<IgnoredAccount__mdt> ignAccList =
        [SELECT ID_ERP__c FROM IgnoredAccount__mdt];
    //--- Ignired accounts - static Set
    public static Set<String> ignoredAccSet = new Set<String>();
    static {
        for (IgnoredAccount__mdt ign : IgnoredAccount__mdt.getAll().values()) {
            if (String.isNotBlank(ign.ID_ERP__c)) ignoredAccSet.add(ign.ID_ERP__c.trim());
        }
    }

    //--- Мапа відповідності JSON.BusinessDivision => Picklist.BusinessDivision
    public static Map<String, String> mapBusinessDivision = new Map<String, String>();
    static {
        mapBusinessDivision.put('Tubes','Pipes');
        mapBusinessDivision.put('Wheels','Railway');
    }

    //--- Кеш Delivery Terms
    public static Map<String, DeliveryTerms__c> mapDelivTerms;
    static {
        mapDelivTerms = new Map<String, DeliveryTerms__c>();
        for(DeliveryTerms__c d : [SELECT Id,ID_ERP__c,Name FROM DeliveryTerms__c]) {
            mapDelivTerms.put(d.ID_ERP__c,d);
        }
    } 
    //--- Helper
    public static DeliveryTerms__c getDelivTermByIdErp(String idErp) {
        DeliveryTerms__c resMap = new DeliveryTerms__c();
        if(mapDelivTerms.containsKey(idErp)) {
            resMap = mapDelivTerms.get(idErp);
        }
        return resMap;
    }     
    //--- Кеш Payment Terms
    public static Map<String, PaymentTerms__c> mapPayTerms;
    static {
        mapPayTerms = new Map<String, PaymentTerms__c>();
        for(PaymentTerms__c p : [SELECT Id,ID_ERP__c,Name FROM PaymentTerms__c
                                WHERE Obsolete__c=false]) {
            mapPayTerms.put(p.ID_ERP__c, p);
        }
    }
    //--- Helper
    public static PaymentTerms__c getPayTermByIdErp(String idErp) {
        PaymentTerms__c res = new PaymentTerms__c();
        if(mapPayTerms.containsKey(idErp)) {
            res = mapPayTerms.get(idErp);
        }
        return res;
    }    

    public static Boolean isIgnoredAccount(String idErp) {
        return (String.isBlank(idErp)) ||
               (ignoredAccSet.contains(idErp));
    }

    // Статична мапа віртуальних акаунтів (для лідів)
    public static Map<String, Id> virtAccMap;
    public static List<Account> virtAccList = [
        SELECT Id, ID_ERP__c,  Name, BillingCountry, BillingCountryCode
        FROM Account WHERE IsVirtual__c=true
    ];

    static {
        virtAccMap = new Map<String, Id>();
        for(Account acc: virtAccList) {
            virtAccMap.put(acc.ID_ERP__c, acc.Id);
        }
    }

    public static Boolean isAccVirtual(String erpId) {
        return (String.isBlank(erpId)) ||
               (virtAccMap.containsKey(erpId));
    }
}