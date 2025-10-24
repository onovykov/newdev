public with sharing class ERPMessageHandlerFamily {

    public static MessageProcessingResult processMessage(ERPMessageParser.ErpToSfMessage_Family parsedMessage) {
        MessageProcessingResult res = new MessageProcessingResult();
        res.MessageType = parsedMessage.metadata.MsgType;

        try {
            String operationMode = String.valueOf(parsedMessage.data.Mode);
            Map<Decimal, Family__c> familyMap = getFamilyMap();

            switch on operationMode {
                when 'MERGE' {
                    Map<Decimal, Family__c> upsertedFamilyMap = modifyFamilies(parsedMessage, familyMap);
                    deleteFamilipes(parsedMessage, familyMap, false);
                    insertNames(parsedMessage, upsertedFamilyMap);
                } when 'MODIFY' {
                    Map<Decimal, Family__c> upsertedFamilyMap = modifyFamilies(parsedMessage, familyMap);
                    insertNames(parsedMessage, upsertedFamilyMap);
                } when 'DELETE' {
                    deleteFamilipes(parsedMessage, familyMap, true);
                } when else {
                    throw new ExecutionException('Unsupported mode: ' + operationMode);
                }
            }

            return res;

        } catch (Exception e) {
            res.error = e.getMessage();
            return res;
        }
    }

    private static Map<Decimal, Family__c> modifyFamilies(ERPMessageParser.ErpToSfMessage_Family parsedMessage, Map<Decimal, Family__c> familyMap) {
        Map<String, Id> familiesTypesMap = getFamiliesTypesMap();
        Map<Decimal, Family__c> familiesToUpsertMap = new Map<Decimal, Family__c>();

        for (ERPMessageParser.FamilyItem familyItem : parsedMessage.data.Items) {
            Family__c familyToUpsert = new Family__c();
            if(familyMap.get(familyItem.FamilyId) != null) {
                familyToUpsert.Id = familyMap.get(familyItem.FamilyId).Id;
            }
            familyToUpsert.Name = familyItem.Name.DefaultName;
            familyToUpsert.ShortName__c = familyItem.NameS.DefaultName;
            familyToUpsert.ID_ERP__c = familyItem.FamilyId;
            familyToUpsert.Is_Active__c = familyItem.IsActive;
            familyToUpsert.FamilyType__c = familiesTypesMap.get(String.valueOf(familyItem.FamilyType.FamilyTypeId));

            familiesToUpsertMap.put(familyItem.FamilyId, familyToUpsert);
        }
        upsert familiesToUpsertMap.values();

        return familiesToUpsertMap;
    }

    private static void deleteFamilipes(ERPMessageParser.ErpToSfMessage_Family parsedMessage, Map<Decimal, Family__c> familyMap, Boolean isDeleteMode) {
        List<Decimal> familyERPIdList = new List<Decimal>();
        Set<Id> familyToDeleteIdSet = new Set<Id>();
        List<Family__c> familyToDeleteList = new List<Family__c>();

        for(ERPMessageParser.FamilyItem familyItem : parsedMessage.data.Items) {
            if(isDeleteMode && familyMap.get(familyItem.FamilyId) != null) {
                familyToDeleteList.add(familyMap.get(familyItem.FamilyId));
                familyToDeleteIdSet.add(familyMap.get(familyItem.FamilyId).Id);
            } else if(!isDeleteMode) {
                familyERPIdList.add(familyItem.FamilyId);
            }
        }

        if(!isDeleteMode) {
            for(Family__c familyItem : familyMap.values()) {
                if(!familyERPIdList.contains(familyItem.ID_ERP__c)) {
                    familyToDeleteList.add(familyItem);
                    familyToDeleteIdSet.add(familyItem.Id);
                } 
            }
        }

        delete familyToDeleteList;
        delete new List<ItemNames__c>([SELECT Id FROM ItemNames__c WHERE ItemId__c IN :familyToDeleteIdSet]);
    }

    private static void insertNames(ERPMessageParser.ErpToSfMessage_Family parsedMessage, Map<Decimal, Family__c> upsertedFamilyMap) {
        List<ItemNames__c> itemNamesToInsert = new List<ItemNames__c>();
        List<ItemNames__c> itemNamesToDelete = new List<ItemNames__c>();
        Set<Id> upsertedFamilyIdSet = new Set<Id>();
        for(Family__c upsertedFamily : upsertedFamilyMap.values()) {
            upsertedFamilyIdSet.add(upsertedFamily.Id);
        }

        List<ItemNames__c> itemNamesList = [SELECT Id, ItemId__c FROM ItemNames__c WHERE ItemId__c IN :upsertedFamilyIdSet];
        Map<String, List<ItemNames__c>> familyIdToItemNamesMap = new Map<String, List<ItemNames__c>>();
        for(ItemNames__c itemNames : itemNamesList) {
            if(familyIdToItemNamesMap.get(itemNames.ItemId__c) == null) {
                familyIdToItemNamesMap.put(itemNames.ItemId__c, new List<ItemNames__c>());
            }
            familyIdToItemNamesMap.get(itemNames.ItemId__c).add(itemNames);
        }
        

        for (ERPMessageParser.FamilyItem familyItem : parsedMessage.data.Items) {
            Family__c upsertedFamily = upsertedFamilyMap.get(familyItem.FamilyId);
            if(familyIdToItemNamesMap.get(upsertedFamily.Id) != null) {
                itemNamesToDelete.addAll(familyIdToItemNamesMap.get(upsertedFamily.Id));
            }

            itemNamesToInsert.addAll(ItemNamesHelper.getItemNamesToInsert(familyItem.Name, familyItem.NameS, upsertedFamily.Id, 'Family'));
        }

        if(!itemNamesToDelete.isEmpty()) {
            delete itemNamesToDelete;
        }

        insert itemNamesToInsert;
    }

    private static Map<Decimal, Family__c> getFamilyMap() {
        Map<Decimal, Family__c> familyMap = new Map<Decimal, Family__c>();
        List<Family__c> familyList = [SELECT Id, ID_ERP__c FROM Family__c];

        for(Family__c family : familyList) {
            familyMap.put(family.ID_ERP__c, family);
        }

        return familyMap;
    }

    private static Map<String, Id> getFamiliesTypesMap() {
        Map<String, Id> FamiliesTypesMap = new Map<String, Id>();
        List<FamiliesTypes__c> FamiliesTypesList = [SELECT Id, ID_ERP__c FROM FamiliesTypes__c];

        for(FamiliesTypes__c FamiliesTypes : FamiliesTypesList) {
            FamiliesTypesMap.put(FamiliesTypes.ID_ERP__c, FamiliesTypes.Id);
        }

        return FamiliesTypesMap;
    }

    public static Blob generateResponseBody(Map<Integer, String> statusCodesMap, Integer statusCode, String error, MessageProcessingResult mpRes) {
            JSONGenerator gen = JSON.createGenerator(true);
            gen.writeStartObject();
            gen.writeNumberField('Status Code', statusCode);
            gen.writeStringField('Status', statusCodesMap.get(statusCode));
            gen.writeStringField('Processed message type', mpRes.MessageType);
            if (error != NULL) {
                gen.writeStringField('Error Message', error);
            }
            gen.writeEndObject();
            
            String res = gen.getAsString();
            System.debug('Response body text generated: ' + res);
            return Blob.valueOf(res);
        }

    public class MessageProcessingResult {
        public String MessageType;		
        public String error;
    } 

    public class ExecutionException extends Exception {
    }      
}