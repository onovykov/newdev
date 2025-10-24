public with sharing class ERPMessageHandlerStructQuota {
    
    public static MessageProcessingResult processMessage(ERPMessageParser.ErpToSfMessage_StructQuota parsedMessage) {
        MessageProcessingResult res = new MessageProcessingResult();
        res.MessageType = parsedMessage.metadata.MsgType;

        try {
            String operationMode = String.valueOf(parsedMessage.data.Mode);

            switch on operationMode {
                when 'MERGE' {
                    Map<String, QuotesStructure__c> structQuotaMap = getStructQuotaMap();
                    modifyStructQuotas(parsedMessage, structQuotaMap, res);
                    ERPDeleteRecordsForMergeOperation.checkAndDeleteRecords(parsedMessage.metadata, 'QuotesStructure__c', null, null);
                    //deleteStructQuotas(parsedMessage, structQuotaMap, false);
                } when 'MERGE_PARTIAL' {
                    if(String.valueOf(parsedMessage.data.Partial.Type) == 'PERIOD') {
                        Date dateBegin = parsedMessage.data.Partial.Options.DATEFROM.date();
                        Date dateEnd = parsedMessage.data.Partial.Options.DATETO.date();
                        Map<String, QuotesStructure__c> structQuotaMap = getStructQuotaByPeriodMap(dateBegin, dateEnd);
                        modifyStructQuotas(parsedMessage, structQuotaMap, res);
                        ERPDeleteRecordsForMergeOperation.checkAndDeleteRecords(parsedMessage.metadata, 'QuotesStructure__c', dateBegin, dateEnd);
                        //deleteStructQuotas(parsedMessage, structQuotaMap, false);
                    }
                } when 'MODIFY' {
                    Map<String, QuotesStructure__c> structQuotaMap = getStructQuotaMap();
                    modifyStructQuotas(parsedMessage, structQuotaMap, res);
                }when 'DELETE' {
                    Map<String, QuotesStructure__c> structQuotaMap = getStructQuotaMap();
                    deleteStructQuotas(parsedMessage, structQuotaMap, true);
                } when else {
                    throw new ExecutionException('Unsupported mode: ' + operationMode);
                }
            }

            return res;

        } catch (Exception e) {
            res.error = e.getMessage() + ' : ' + e.getLineNumber();
            return res;
        }
    }

    private static void modifyStructQuotas(ERPMessageParser.ErpToSfMessage_StructQuota parsedMessage, Map<String, QuotesStructure__c> structQuotaMap, MessageProcessingResult res) {
        Map<Decimal, Id> regionMap = getRegionMap();
        Map<Decimal, Id> groupMap = getGroupMap();
        Map<Decimal, Id> familyMap = getFamilyMap();
        Map<String, Id> managerMap = getManagerMap();
        List<QuotesStructure__c> structQuotaToUpsertList = new List<QuotesStructure__c>();
        String structQuotaIdsWithoutFamily = '';
        //Log.instance.startTransaction();

        for (ERPMessageParser.StructQuotaItem structQuotaItem : parsedMessage.data.Items) {
            String rowId = String.valueOf(structQuotaItem.RowId);
            if(structQuotaItem.Family != null) {
                QuotesStructure__c structQuotaToUpsert = new QuotesStructure__c();
    
                if(structQuotaMap.get(rowId) != null) {
                    structQuotaToUpsert.Id = structQuotaMap.get(rowId).Id;
                } else {
                    structQuotaToUpsert.Family__c = familyMap.get(structQuotaItem.Family.FamilyId);
                }
                structQuotaToUpsert.ID_ERP__c = String.valueOf(rowId);
                structQuotaToUpsert.MarketSegment__c = structQuotaItem.StructConfig.SegmentCode;
                structQuotaToUpsert.DateBegin__c = structQuotaItem.DateFrom.date();
                structQuotaToUpsert.DateEnd__c = structQuotaItem.DateTo.date();
                structQuotaToUpsert.Percent__c = structQuotaItem.Qty_percent;
                structQuotaToUpsert.AddQty_t__c = structQuotaItem.Qty_add_t;
                structQuotaToUpsert.Add_Qty_pcs__c = structQuotaItem.Qty_add_pcs;
                structQuotaToUpsert.Group3__c = groupMap.get(structQuotaItem.Grp3);
                structQuotaToUpsert.Region__c = regionMap.get(structQuotaItem.Region);
                structQuotaToUpsert.Manager__c = managerMap.get(structQuotaItem.SaleKdk.deleteWhitespace());
                structQuotaToUpsert.Transaction_Id__c = parsedMessage.Metadata.msgTimestamp.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
    
                structQuotaToUpsertList.add(structQuotaToUpsert);
            } else {
                structQuotaIdsWithoutFamily += rowId + '; ';
                // Log.instance.debug(Log.Type.Backend, 
				// 	               Log.Area.Families,   
				// 	               'Quota Structure without Family',
				//                    'Quota Structure with Id in ERP ' + rowId + ' has not been created because of an unspecified family.');	
            }
        }
        //Log.instance.stopTransaction();

        upsert structQuotaToUpsertList;

        if(String.isNotBlank(structQuotaIdsWithoutFamily)) {
            structQuotaIdsWithoutFamily = structQuotaIdsWithoutFamily.removeEnd('; ');
            res.error = 'Quotas Structures with the following Ids have not been created because of an unspecified family : ' + structQuotaIdsWithoutFamily;
        }
    }

    private static void deleteStructQuotas(ERPMessageParser.ErpToSfMessage_StructQuota parsedMessage, Map<String, QuotesStructure__c> structQuotaMap, Boolean isDeleteMode) {
        List<String> structQuotaERPIdList = new List<String>();
        List<QuotesStructure__c> structQuotaToDeleteList = new List<QuotesStructure__c>();

        for(ERPMessageParser.StructQuotaItem structQuotaItem : parsedMessage.data.Items) {
            String rowId = String.valueOf(structQuotaItem.RowId);
            if(isDeleteMode && structQuotaMap.get(rowId) != null) {
                structQuotaToDeleteList.add(structQuotaMap.get(rowId));
            } else if(!isDeleteMode) {
                structQuotaERPIdList.add(rowId);
            }
        }

        if(!isDeleteMode) {
            for(QuotesStructure__c structQuotaItem : structQuotaMap.values()) {
                if(!structQuotaERPIdList.contains(structQuotaItem.ID_ERP__c)) {
                    structQuotaToDeleteList.add(structQuotaItem);
                } 
            }
        }

        delete structQuotaToDeleteList;
    }

    private static Map<String, QuotesStructure__c> getStructQuotaMap() {
        Map<String, QuotesStructure__c> structQuotaMap = new Map<String, QuotesStructure__c>();
        List<QuotesStructure__c> structQuotaList = [SELECT Id, ID_ERP__c FROM QuotesStructure__c];

        for(QuotesStructure__c structQuota : structQuotaList) {
            structQuotaMap.put(structQuota.ID_ERP__c, structQuota);
        }

        return structQuotaMap;
    }

    private static Map<String, QuotesStructure__c> getStructQuotaByPeriodMap(Date dateBegin, Date dateEnd) {
        Map<String, QuotesStructure__c> structQuotaMap = new Map<String, QuotesStructure__c>();
        List<QuotesStructure__c> structQuotaList = [SELECT Id, ID_ERP__c FROM QuotesStructure__c WHERE DateBegin__c >= :dateBegin AND DateEnd__c <= :dateEnd];

        for(QuotesStructure__c structQuota : structQuotaList) {
            structQuotaMap.put(structQuota.ID_ERP__c, structQuota);
        }

        return structQuotaMap;
    }

    private static Map<Decimal, Id> getRegionMap() {
        Map<Decimal, Id> regionMap = new Map<Decimal, Id>();
        List<Region__c> regionList = [SELECT Id, ID_ERP__c FROM Region__c];

        for(Region__c region : regionList) {
            regionMap.put(region.ID_ERP__c, region.Id);
        }

        return regionMap;
    }

    private static Map<Decimal, Id> getGroupMap() {
        Map<Decimal, Id> groupMap = new Map<Decimal, Id>();
        List<Group3__c> groupList = [SELECT Id, ID_ERP__c FROM Group3__c];

        for(Group3__c groupItem : groupList) {
            groupMap.put(groupItem.ID_ERP__c, groupItem.Id);
        }

        return groupMap;
    }

    private static Map<Decimal, Id> getFamilyMap() {
        Map<Decimal, Id> familyMap = new Map<Decimal, Id>();
        List<Family__c> familyList = [SELECT Id, ID_ERP__c FROM Family__c];

        for(Family__c family : familyList) {
            familyMap.put(family.ID_ERP__c, family.Id);
        }

        return familyMap;
    }

    private static Map<String, Id> getManagerMap() {
        Map<String, Id> managerMap = new Map<String, Id>();
        List<User> managerList = [SELECT Id, ID_ERP__c FROM User WHERE ID_ERP__c != null AND IsActive = true];

        for(User manager : managerList) {
            managerMap.put(manager.ID_ERP__c, manager.Id);
        }

        return managerMap;
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