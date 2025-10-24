public with sharing class ERPMessageHandlerRouteQuota {
    
    public static MessageProcessingResult processMessage(ERPMessageParser.ErpToSfMessage_RouteQuota parsedMessage) {
        MessageProcessingResult res = new MessageProcessingResult();
        res.MessageType = parsedMessage.metadata.MsgType;

        try {
            String operationMode = String.valueOf(parsedMessage.data.Mode);

            switch on operationMode {
                when 'MERGE' {
                    Map<String, Route_Quota__c> routeQuotaMap = getRouteQuotaMap();
                    modifyRoutesQuotes(parsedMessage, routeQuotaMap);
                    ERPDeleteRecordsForMergeOperation.checkAndDeleteRecords(parsedMessage.metadata, 'Route_Quota__c', null, null);
                    //deleteRoutesQuotes(parsedMessage, routeQuotaMap, false);
                } when 'MERGE_PARTIAL' {
                    if(String.valueOf(parsedMessage.data.Partial.Type) == 'PERIOD') {
                        Date dateBegin = parsedMessage.data.Partial.Options.DATEFROM.date();
                        Date dateEnd = parsedMessage.data.Partial.Options.DATETO.date();
                        Map<String, Route_Quota__c> routeQuotaMap = getRouteQuotaByPeriodMap(dateBegin, dateEnd);
                        modifyRoutesQuotes(parsedMessage, routeQuotaMap);
                        ERPDeleteRecordsForMergeOperation.checkAndDeleteRecords(parsedMessage.metadata, 'Route_Quota__c', dateBegin, dateEnd);
                        //deleteRoutesQuotes(parsedMessage, routeQuotaMap, false);
                    }
                } when 'MODIFY' {
                    Map<String, Route_Quota__c> routeQuotaMap = getRouteQuotaMap();
                    modifyRoutesQuotes(parsedMessage, routeQuotaMap);
                }when 'DELETE' {
                    Map<String, Route_Quota__c> routeQuotaMap = getRouteQuotaMap();
                    deleteRoutesQuotes(parsedMessage, routeQuotaMap, true);
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

    private static void modifyRoutesQuotes(ERPMessageParser.ErpToSfMessage_RouteQuota parsedMessage, Map<String, Route_Quota__c> routeQuotaMap) {
        Map<Decimal, Id> routeMap = getRouteMap();
        Map<String, Route_Quota__c> routeQuotaToUpsertMap = new Map<String, Route_Quota__c>();

        for (ERPMessageParser.RouteQuotaItem routeQuotaItem : parsedMessage.data.Items) {
            Route_Quota__c routeQuotaToUpsert = new Route_Quota__c();
            String rowId = String.valueOf(routeQuotaItem.RowId);

            if(routeQuotaMap.get(rowId) != null) {
                routeQuotaToUpsert.Id = routeQuotaMap.get(rowId).Id;
            }
            routeQuotaToUpsert.Name = populateName(routeQuotaItem);
            routeQuotaToUpsert.ID_ERP__c = rowId;
            routeQuotaToUpsert.MarketSegment__c = routeQuotaItem.SegmentCode;
            routeQuotaToUpsert.DateBegin__c = routeQuotaItem.DateFrom.date();
            routeQuotaToUpsert.DateEnd__c = routeQuotaItem.DateTo.date();
            routeQuotaToUpsert.Quote_t__c = routeQuotaItem.Quota_t;
            routeQuotaToUpsert.Quote_pcs__c = routeQuotaItem.Quota_pcs;
            routeQuotaToUpsert.Budget_t__c = routeQuotaItem.Budget_t;
            routeQuotaToUpsert.Budget_pcs__c = routeQuotaItem.Budget_pcs;
            routeQuotaToUpsert.Margin__c = routeQuotaItem.Marginall;
            routeQuotaToUpsert.Route__c = routeMap.get(routeQuotaItem.RouteFamilies.Route.RouteId);
            routeQuotaToUpsert.Transaction_Id__c = parsedMessage.Metadata.msgTimestamp.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');

            routeQuotaToUpsertMap.put(rowId, routeQuotaToUpsert);
        }

        upsert routeQuotaToUpsertMap.values();
        insertQuotaFamilies(parsedMessage, routeQuotaToUpsertMap);
    }

    private static void deleteRoutesQuotes(ERPMessageParser.ErpToSfMessage_RouteQuota parsedMessage, Map<String, Route_Quota__c> routeQuotaMap, Boolean isDeleteMode) {
        List<String> routeQuotaERPIdList = new List<String>();
        List<Route_Quota__c> routeQuotaToDeleteList = new List<Route_Quota__c>();

        for(ERPMessageParser.RouteQuotaItem routeQuotaItem : parsedMessage.data.Items) {
            String rowId = String.valueOf(routeQuotaItem.RowId);
            if(isDeleteMode && routeQuotaMap.get(rowId) != null) {
                routeQuotaToDeleteList.add(routeQuotaMap.get(rowId));
            } else if(!isDeleteMode) {
                routeQuotaERPIdList.add(rowId);
            }
        }

        if(!isDeleteMode) {
            for(Route_Quota__c routeQuotaItem : routeQuotaMap.values()) {
                if(!routeQuotaERPIdList.contains(routeQuotaItem.ID_ERP__c)) {
                    routeQuotaToDeleteList.add(routeQuotaItem);
                } 
            }
        }

        delete routeQuotaToDeleteList;
    }

    private static void insertQuotaFamilies(ERPMessageParser.ErpToSfMessage_RouteQuota parsedMessage, Map<String, Route_Quota__c> routeQuotaMap) {
        Map<String, QBA_Families__c> quotaFamiliesMap = getQuotaFamiliesMap(parsedMessage);
        Map<Decimal, Id> familyMap = getFamilyMap();
        List<QBA_Families__c> quotaFamiliesToInsert = new List<QBA_Families__c>();
        List<QBA_Families__c> quotaFamiliesToDelete = new List<QBA_Families__c>();
        Set<String> routeQuotaFamilyIdSet = new Set<String>();


        for (ERPMessageParser.RouteQuotaItem routeQuotaItem : parsedMessage.data.Items) {
            for(ERPMessageParser.FamilyItem familyItem : routeQuotaItem.RouteFamilies.Families) {
                if(quotaFamiliesMap.get(routeQuotaItem.RowId + '' + familyItem.FamilyId) == null) {
                    QBA_Families__c quotaFamily = new QBA_Families__c();
                    quotaFamily.QuotesBudgetAll__c = routeQuotaMap.get(String.valueOf(routeQuotaItem.RowId)).Id;
                    quotaFamily.Family__c = familyMap.get(familyItem.FamilyId);
                    quotaFamiliesToInsert.add(quotaFamily);
                }
                routeQuotaFamilyIdSet.add(routeQuotaItem.RowId + '' + familyItem.FamilyId);
            }
        }

        for(String routeQuotaFamilyId : quotaFamiliesMap.keySet()) {
            if(!routeQuotaFamilyIdSet.contains(routeQuotaFamilyId)) {
                quotaFamiliesToDelete.add(quotaFamiliesMap.get(routeQuotaFamilyId));
            }
        }

        insert quotaFamiliesToInsert;
        delete quotaFamiliesToDelete;
    }

    private static String populateName(ERPMessageParser.RouteQuotaItem routeQuotaItem) {
        String routeQuotaName = '';
        for(ERPMessageParser.FamilyItem familyItem : routeQuotaItem.RouteFamilies.Families) {
            routeQuotaName += familyItem.Name.DefaultName + ', ';
        }
        routeQuotaName = routeQuotaName.removeEnd(', ');

        return routeQuotaName;
    }

    private static Map<String, Route_Quota__c> getRouteQuotaMap() {
        Map<String, Route_Quota__c> routeQuotaMap = new Map<String, Route_Quota__c>();
        List<Route_Quota__c> routeQuotaList = [SELECT Id, ID_ERP__c FROM Route_Quota__c];

        for(Route_Quota__c routeQuota : routeQuotaList) {
            routeQuotaMap.put(routeQuota.ID_ERP__c, routeQuota);
        }

        return routeQuotaMap;
    }

    private static Map<String, Route_Quota__c> getRouteQuotaByPeriodMap(Date dateBegin, Date dateEnd) {
        Map<String, Route_Quota__c> routeQuotaMap = new Map<String, Route_Quota__c>();
        List<Route_Quota__c> routeQuotaList = [SELECT Id, ID_ERP__c FROM Route_Quota__c WHERE DateBegin__c >= :dateBegin AND DateEnd__c <= :dateEnd];

        for(Route_Quota__c routeQuota : routeQuotaList) {
            routeQuotaMap.put(routeQuota.ID_ERP__c, routeQuota);
        }

        return routeQuotaMap;
    }

    private static Map<Decimal, Id> getRouteMap() {
        Map<Decimal, Id> routeMap = new Map<Decimal, Id>();
        List<Route__c> routeList = [SELECT Id, ID_ERP__c FROM Route__c];

        for(Route__c route : routeList) {
            routeMap.put(route.ID_ERP__c, route.Id);
        }

        return routeMap;
    }

    private static Map<Decimal, Id> getFamilyMap() {
        Map<Decimal, Id> familyMap = new Map<Decimal, Id>();
        List<Family__c> familyList = [SELECT Id, ID_ERP__c FROM Family__c];

        for(Family__c family : familyList) {
            familyMap.put(family.ID_ERP__c, family.Id);
        }

        return familyMap;
    }

    private static Map<String, QBA_Families__c> getQuotaFamiliesMap(ERPMessageParser.ErpToSfMessage_RouteQuota parsedMessage) {
        Set<String> routeQuotaRowIdSet = new Set<String>();
        for(ERPMessageParser.RouteQuotaItem routeQuotaItem : parsedMessage.data.Items) {
            routeQuotaRowIdSet.add(String.valueOf(routeQuotaItem.RowId));
        }

        Map<String, QBA_Families__c> quotaFamiliesMap = new Map<String, QBA_Families__c>();
        List<QBA_Families__c> quotaFamilyList = [SELECT QuotesBudgetAll__r.ID_ERP__c, Family__r.ID_ERP__c FROM QBA_Families__c WHERE QuotesBudgetAll__r.ID_ERP__c IN :routeQuotaRowIdSet];

        for(QBA_Families__c quotaFamily : quotaFamilyList) {
            quotaFamiliesMap.put(quotaFamily.QuotesBudgetAll__r.ID_ERP__c + '' + quotaFamily.Family__r.ID_ERP__c, quotaFamily);
        }

        return quotaFamiliesMap;
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