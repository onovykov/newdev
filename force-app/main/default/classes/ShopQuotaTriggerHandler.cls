public class ShopQuotaTriggerHandler {
    public static void onBeforeInsert(List<Shop_Quota__c> newList) {
       // ShopQuotaTriggerHelper.calculateActualQuantityByQuoteType(newList);
    }
    public static void onAfterInsert(List<Shop_Quota__c> newList) {
        ShopQuotaTriggerHelper.calculateActualQuantityByQuoteType(newList, true);
    }
}