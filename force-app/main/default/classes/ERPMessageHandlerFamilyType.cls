public class ERPMessageHandlerFamilyType {
    public static MessageProcessingResult processMessage(ERPMessageParser.ErpToSfMessage_FamilyType parsedMessage) {
        MessageProcessingResult res = new MessageProcessingResult();
        res.MessageType = parsedMessage.metadata.MsgType;

        try {
            String operationMode = String.valueOf(parsedMessage.data.Mode);
            Map<String, FamiliesTypes__c> familyTypeMap = getFamilyTypeMap();

            switch on operationMode {
                when 'MERGE' {
                    Map<String, FamiliesTypes__c> upsertedFamilyTypeMap = modifyFamilyTypes(parsedMessage, familyTypeMap);
                    deleteFamilyTypes(parsedMessage, familyTypeMap, false);
                    insertNames(parsedMessage, upsertedfamilyTypeMap);
                } when 'MODIFY' {
                    Map<String, FamiliesTypes__c> upsertedFamilyTypeMap = modifyFamilyTypes(parsedMessage, familyTypeMap);
                    insertNames(parsedMessage, upsertedfamilyTypeMap);
                } when 'DELETE' {
                    deleteFamilyTypes(parsedMessage, familyTypeMap, true);
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

    private static Map<String, FamiliesTypes__c> modifyFamilyTypes(ERPMessageParser.ErpToSfMessage_FamilyType parsedMessage, Map<String, FamiliesTypes__c> familyTypeMap) {
        Map<String, FamiliesTypes__c> familyTypeToUpsertMap = new Map<String, FamiliesTypes__c>();

        for (ERPMessageParser.FamilyTypeItem familyTypeItem : parsedMessage.data.Items) {
            FamiliesTypes__c familyTypeToUpsert = new FamiliesTypes__c();
            if(familyTypeMap.get(String.valueOf(familyTypeItem.FamilyTypeId)) != null) {
                familyTypeToUpsert.Id = familyTypeMap.get(String.valueOf(familyTypeItem.FamilyTypeId)).Id;
            }
            familyTypeToUpsert.Name = familyTypeItem.Name.DefaultName;
            familyTypeToUpsert.ShortName__c = familyTypeItem.NameS.DefaultName;
            familyTypeToUpsert.ID_ERP__c = String.valueOf(familyTypeItem.FamilyTypeId);
            familyTypeToUpsert.Is_Active__c = familyTypeItem.IsActive;

            familyTypeToUpsertMap.put(String.valueOf(familyTypeItem.FamilyTypeId), familyTypeToUpsert);
        }
        upsert familyTypeToUpsertMap.values();

        return familyTypeToUpsertMap;
    }

    private static void deleteFamilyTypes(ERPMessageParser.ErpToSfMessage_FamilyType parsedMessage, Map<String, FamiliesTypes__c> familyTypeMap, Boolean isDeleteMode) {
        List<String> familyTypeERPIdList = new List<String>();
        Set<Id> familyTypeToDeleteIdSet = new Set<Id>();
        List<FamiliesTypes__c> familyTypeToDeleteList = new List<FamiliesTypes__c>();

        for(ERPMessageParser.FamilyTypeItem familyTypeItem : parsedMessage.data.Items) {
            if(isDeleteMode && familyTypeMap.get(String.valueOf(familyTypeItem.FamilyTypeId)) != null) {
                familyTypeToDeleteList.add(familyTypeMap.get(String.valueOf(familyTypeItem.FamilyTypeId)));
                familyTypeToDeleteIdSet.add(familyTypeMap.get(String.valueOf(familyTypeItem.FamilyTypeId)).Id);
            } else if(!isDeleteMode) {
                familyTypeERPIdList.add(String.valueOf(String.valueOf(familyTypeItem.FamilyTypeId)));
            }
        }

        if(!isDeleteMode) {
            for(FamiliesTypes__c familyTypeItem : familyTypeMap.values()) {
                if(!familyTypeERPIdList.contains(familyTypeItem.ID_ERP__c)) {
                    familyTypeToDeleteList.add(familyTypeItem);
                    familyTypeToDeleteIdSet.add(familyTypeItem.Id);
                } 
            }
        }

        delete familyTypeToDeleteList;
        delete new List<ItemNames__c>([SELECT Id FROM ItemNames__c WHERE ItemId__c IN :familyTypeToDeleteIdSet]);
    }

    private static void insertNames(ERPMessageParser.ErpToSfMessage_FamilyType parsedMessage, Map<String, FamiliesTypes__c> upsertedFamilyTypeMap) {
        List<ItemNames__c> itemNamesToInsert = new List<ItemNames__c>();
        List<ItemNames__c> itemNamesToDelete = new List<ItemNames__c>();
        Set<Id> upsertedFamilyTypeIdSet = new Set<Id>();
        for(FamiliesTypes__c upsertedFamilyType : upsertedfamilyTypeMap.values()) {
            upsertedFamilyTypeIdSet.add(upsertedFamilyType.Id);
        }

        List<ItemNames__c> itemNamesList = [SELECT Id, ItemId__c FROM ItemNames__c WHERE ItemId__c IN :upsertedFamilyTypeIdSet];
        Map<String, List<ItemNames__c>> FamilyTypeIdToItemNamesMap = new Map<String, List<ItemNames__c>>();
        for(ItemNames__c itemNames : itemNamesList) {
            if(FamilyTypeIdToItemNamesMap.get(itemNames.ItemId__c) == null) {
                FamilyTypeIdToItemNamesMap.put(itemNames.ItemId__c, new List<ItemNames__c>());
            }
            FamilyTypeIdToItemNamesMap.get(itemNames.ItemId__c).add(itemNames);
        }
        

        for (ERPMessageParser.FamilyTypeItem familyTypeItem : parsedMessage.data.Items) {
            FamiliesTypes__c upsertedFamilyType = upsertedfamilyTypeMap.get(String.valueOf(familyTypeItem.FamilyTypeId));
            if(FamilyTypeIdToItemNamesMap.get(upsertedFamilyType.Id) != null) {
                itemNamesToDelete.addAll(FamilyTypeIdToItemNamesMap.get(upsertedFamilyType.Id));
            }

            itemNamesToInsert.addAll(ItemNamesHelper.getItemNamesToInsert(familyTypeItem.Name, familyTypeItem.NameS, upsertedFamilyType.Id, 'Family Type'));
        }

        if(!itemNamesToDelete.isEmpty()) {
            delete itemNamesToDelete;
        }

        insert itemNamesToInsert;
    }

    private static Map<String, FamiliesTypes__c> getFamilyTypeMap() {
        Map<String, FamiliesTypes__c> familyTypeMap = new Map<String, FamiliesTypes__c>();
        List<FamiliesTypes__c> familyTypeList = [SELECT Id, ID_ERP__c FROM FamiliesTypes__c];

        for(FamiliesTypes__c familyType : familyTypeList) {
            familyTypeMap.put(familyType.ID_ERP__c, familyType);
        }

        return familyTypeMap;
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