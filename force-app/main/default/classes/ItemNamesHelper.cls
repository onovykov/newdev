public class ItemNamesHelper {

    public static List<ItemNames__c> getItemNamesToInsert(ERPMessageParser.NameObject parsedName, ERPMessageParser.NameObject parsedNameS, Id recordId, String objectName) {
        List<ItemNames__c> itemNamesToInsert = new List<ItemNames__c>();
        if(String.isNotBlank(parsedName.En)) {
            itemNamesToInsert.add(createItemNames(parsedName.En, parsedNameS.En, recordId, 'EN', objectName));
        } else if(parsedName.En == null) {
            itemNamesToInsert.add(createItemNames(parsedName.DefaultName, parsedNameS.DefaultName, recordId, 'EN', objectName));
        }
        if(String.isNotBlank(parsedName.Uk)) {
            itemNamesToInsert.add(createItemNames(parsedName.Uk, parsedNameS.Uk, recordId, 'UK', objectName));
        } else if(parsedName.Uk == null) {
            itemNamesToInsert.add(createItemNames(parsedName.DefaultName, parsedNameS.DefaultName, recordId, 'UK', objectName));
        }
        if(String.isNotBlank(parsedName.Ru)) {
            itemNamesToInsert.add(createItemNames(parsedName.Ru, parsedNameS.Ru, recordId, 'RU', objectName));
        } else if(parsedName.Ru == null) {
            itemNamesToInsert.add(createItemNames(parsedName.DefaultName, parsedNameS.DefaultName, recordId, 'RU', objectName));
        }

        return itemNamesToInsert;
    }

    private static ItemNames__c createItemNames(String itemName, String itemNameShort, String itemId, String language, String objectName) {
        ItemNames__c itemNames = new ItemNames__c();
        itemNames.ItemNameInLng__c = itemName;
        itemNames.ItemShortName__c = itemNameShort;
        itemNames.ItemId__c = itemId;
        itemNames.Language__c = language;
        itemNames.KeyPrefix__c = itemId.substring(0, 3); 
        itemNames.Object__c = objectName;

        return itemNames;
    }
}