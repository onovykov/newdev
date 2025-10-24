public class ShopsRepository {
	public class Shops {
		public Id ShopId;
		public String ShopErpId;
		public String ShopName;
		public Id MillId;
		public String MillName;

		public Shops () {
			this.ShopId=null;
			this.ShopErpId = '';
			this.ShopName = '';
			this.MillId = null;
			this.MillName = '';
		}
	}

	private static Map<Id, Shops> shopMapById;
    private static Map<String, Shops> shopMapByErp;
    private static Boolean isLoaded = false;

	public static void loadAllShops() {
		if(isLoaded) return;
		shopMapById = new Map<Id, Shops>();
		shopMapByErp = new Map<String, Shops>();
		List<Shop__c> shopList = [SELECT
									Id, ID_ERP__c, Name, Plant__c, Plant__r.Name
								  FROM Shop__c 
								  WHERE Plant__c!=null];		

		if(!shopList.isEmpty()) {
			for(Shop__c shop : shopList) {
				Shops shopRec = new Shops();
				shopRec.ShopId = shop.Id;
				shopRec.ShopErpId = shop.ID_ERP__c;
				shopRec.ShopName = shop.Name;
				shopRec.MillId = shop.Plant__c;
				shopRec.MillName = shop.Plant__r.Name;

				shopMapById.put(shop.Id, shopRec);
				shopMapByErp.put(shop.ID_ERP__c, shopRec);
			}
		}
		isLoaded = true;
	}
    public static Shops getShopById(Id id) {
        loadAllShops();
        return shopMapById.get(id);
    }

     public static Shops getShopByErp(String erp) {
        loadAllShops();
        return shopMapByErp.get(erp);
    }   

    //--- Чистимо кеш
    public static void clearCacheShops() {
        isLoaded = false;
        shopMapById = null;
        shopMapByErp = null;
    }
    //--- Рефрешимо кеш
    public static void refreshShops() {
        clearCacheShops();
        loadAllShops();
    }
}