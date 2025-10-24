public with sharing class ERPMessageHandlerRouteFamily {

    public static MessageProcessingResult processMessage(ERPMessageParser.ErpToSfMessage_RouteFamilies parsedMessage) {
        MessageProcessingResult res = new MessageProcessingResult();
        res.MessageType = parsedMessage.metadata.MsgType;

        try {
            String operationMode = String.valueOf(parsedMessage.data.Mode);
            Map<String, RouteFamilyLink__c> routeFamilyMap = getRouteFamilyMap();

            switch on operationMode {
                when 'MERGE' {
                    modifyRoutesFamilies(parsedMessage, routeFamilyMap);
                    deleteRoutesFamilies(parsedMessage, routeFamilyMap, false);
                } when 'MODIFY' {
                    modifyRoutesFamilies(parsedMessage, routeFamilyMap);
                } when 'DELETE' {
                    deleteRoutesFamilies(parsedMessage, routeFamilyMap, true);
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

    private static void modifyRoutesFamilies(ERPMessageParser.ErpToSfMessage_RouteFamilies parsedMessage, Map<String, RouteFamilyLink__c> routeFamilyMap) {
        Map<Decimal, Id> routeMap = getRouteMap();
        Map<Decimal, Id> familyMap = getFamilyMap();
        List<RouteFamilyLink__c> routeFamilyToInsertList = new List<RouteFamilyLink__c>();

        for (ERPMessageParser.RouteFamilyItem routeFamilyItem : parsedMessage.data.Items) {
            for(ERPMessageParser.FamilyItem familyItem : routeFamilyItem.Families) {
                RouteFamilyLink__c routeFamilyToInsert = new RouteFamilyLink__c();
                if(routeFamilyMap.get(routeFamilyItem.Route.RouteId + '' + familyItem.FamilyId) == null) {
                    routeFamilyToInsert.Route__c = routeMap.get(routeFamilyItem.Route.RouteId);
                    routeFamilyToInsert.Family__c = familyMap.get(familyItem.FamilyId);
                    routeFamilyToInsertList.add(routeFamilyToInsert);
                }
            }
        }
        insert routeFamilyToInsertList;
    }

    private static void deleteRoutesFamilies(ERPMessageParser.ErpToSfMessage_RouteFamilies parsedMessage, Map<String, RouteFamilyLink__c> routeFamilyMap, Boolean isDeleteMode) {
        List<String> routeFamilyERPIdList = new List<String>();
        List<RouteFamilyLink__c> routeFamilyToDeleteList = new List<RouteFamilyLink__c>();

        for(ERPMessageParser.RouteFamilyItem routeFamilyItem : parsedMessage.data.Items) {
            for(ERPMessageParser.FamilyItem familyItem : routeFamilyItem.Families) {
                if(isDeleteMode && routeFamilyMap.get(routeFamilyItem.Route.RouteId + '' + familyItem.FamilyId) != null) {
                    routeFamilyToDeleteList.add(routeFamilyMap.get(routeFamilyItem.Route.RouteId + '' + familyItem.FamilyId));
                } else if(!isDeleteMode) {
                    routeFamilyERPIdList.add(routeFamilyItem.Route.RouteId + '' + familyItem.FamilyId);
                }
            }
        }

        if(!isDeleteMode) {
            for(RouteFamilyLink__c routeFamily : routeFamilyMap.values()) {
                if(!routeFamilyERPIdList.contains(routeFamily.Route__r.ID_ERP__c + '' + routeFamily.Family__r.ID_ERP__c)) {
                    routeFamilyToDeleteList.add(routeFamily);
                } 
            }
        }

        delete routeFamilyToDeleteList;
    }

    private static Map<String, RouteFamilyLink__c> getRouteFamilyMap() {
        Map<String, RouteFamilyLink__c> routeFamilyMap = new Map<String, RouteFamilyLink__c>();
        List<RouteFamilyLink__c> routeFamilyList = [SELECT Id, Family__c, Family__r.ID_ERP__c, Route__c, Route__r.ID_ERP__c FROM RouteFamilyLink__c];

        for(RouteFamilyLink__c routeFamily : routeFamilyList) {
            routeFamilyMap.put(routeFamily.Route__r.ID_ERP__c + '' + routeFamily.Family__r.ID_ERP__c, routeFamily);
        }

        return routeFamilyMap;
    }

    private static Map<Decimal, Id> getRouteMap() {
        Map<Decimal, ID> routeMap = new Map<Decimal, Id>();
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