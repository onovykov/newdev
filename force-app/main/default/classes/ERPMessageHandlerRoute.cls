public with sharing class ERPMessageHandlerRoute {

    public static MessageProcessingResult processMessage(ERPMessageParser.ErpToSfMessage_Route parsedMessage) {
        MessageProcessingResult res = new MessageProcessingResult();
        res.MessageType = parsedMessage.metadata.MsgType;

        try {
            String operationMode = String.valueOf(parsedMessage.data.Mode);
            Map<Decimal, Route__c> routeMap = getRouteMap();

            switch on operationMode {
                when 'MERGE' {
                    Map<Decimal, Route__c> upsertedRouteMap = modifyRoutes(parsedMessage, routeMap);
                    deleteRoutes(parsedMessage, routeMap, false);
                    insertNames(parsedMessage, upsertedRouteMap);
                } when 'MODIFY' {
                    Map<Decimal, Route__c> upsertedRouteMap = modifyRoutes(parsedMessage, routeMap);
                    insertNames(parsedMessage, upsertedRouteMap);
                } when 'DELETE' {
                    deleteRoutes(parsedMessage, routeMap, true);
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

    private static Map<Decimal, Route__c> modifyRoutes(ERPMessageParser.ErpToSfMessage_Route parsedMessage, Map<Decimal, Route__c> routeMap) {
        Map<String, Id> shopMap = getShopMap();
        Map<Decimal, Route__c> routeToUpsertMap = new Map<Decimal, Route__c>();

        for (ERPMessageParser.RouteItem routeItem : parsedMessage.data.Items) {
            Route__c routeToUpsert = new Route__c();
            if(routeMap.get(routeItem.RouteId) != null) {
                routeToUpsert.Id = routeMap.get(routeItem.RouteId).Id;
            }
            routeToUpsert.Name = routeItem.Name.DefaultName;
            routeToUpsert.ID_ERP__c = routeItem.RouteId;
            routeToUpsert.RouteEmpty__c = routeItem.IsEmpty;
            routeToUpsert.USE_PCS__c = routeItem.UsePcs;
            routeToUpsert.PROD_DAYS__c = routeItem.ProdDays;
            routeToUpsert.Comment__c = routeItem.Comment;
            routeToUpsert.IsActive__c = routeItem.IsActive;
            routeToUpsert.Shop__c = shopMap.get(String.valueOf(routeItem.ShopId));

            routeToUpsertMap.put(routeItem.RouteId, routeToUpsert);
        }
        upsert routeToUpsertMap.values();

        return routeToUpsertMap;
    }

    private static void deleteRoutes(ERPMessageParser.ErpToSfMessage_Route parsedMessage, Map<Decimal, Route__c> routeMap, Boolean isDeleteMode) {
        List<Decimal> routeERPIdList = new List<Decimal>();
        Set<Id> routeToDeleteIdSet = new Set<Id>();
        List<Route__c> routeToDeleteList = new List<Route__c>();

        for(ERPMessageParser.RouteItem routeItem : parsedMessage.data.Items) {
            if(isDeleteMode && routeMap.get(routeItem.RouteId) != null) {
                routeToDeleteList.add(routeMap.get(routeItem.RouteId));
                routeToDeleteIdSet.add(routeMap.get(routeItem.RouteId).Id);
            } else if(!isDeleteMode) {
                routeERPIdList.add(routeItem.RouteId);
            }
        }

        if(!isDeleteMode) {
            for(Route__c routeItem : routeMap.values()) {
                if(!routeERPIdList.contains(routeItem.ID_ERP__c)) {
                    routeToDeleteList.add(routeItem);
                    routeToDeleteIdSet.add(routeItem.Id);
                } 
            }
        }

        delete routeToDeleteList;
        delete new List<ItemNames__c>([SELECT Id FROM ItemNames__c WHERE ItemId__c IN :routeToDeleteIdSet]);
    }

    private static void insertNames(ERPMessageParser.ErpToSfMessage_Route parsedMessage, Map<Decimal, Route__c> upsertedRouteMap) {
        List<ItemNames__c> itemNamesToInsert = new List<ItemNames__c>();
        List<ItemNames__c> itemNamesToDelete = new List<ItemNames__c>();
        Set<Id> upsertedRuoteIdSet = new Set<Id>();
        for(Route__c upsertedRoute : upsertedRouteMap.values()) {
            upsertedRuoteIdSet.add(upsertedRoute.Id);
        }

        List<ItemNames__c> itemNamesList = [SELECT Id, ItemId__c FROM ItemNames__c WHERE ItemId__c IN :upsertedRuoteIdSet];
        Map<String, List<ItemNames__c>> routeIdToItemNamesMap = new Map<String, List<ItemNames__c>>();
        for(ItemNames__c itemNames : itemNamesList) {
            if(routeIdToItemNamesMap.get(itemNames.ItemId__c) == null) {
                routeIdToItemNamesMap.put(itemNames.ItemId__c, new List<ItemNames__c>());
            }
            routeIdToItemNamesMap.get(itemNames.ItemId__c).add(itemNames);
        }
        

        for (ERPMessageParser.RouteItem routeItem : parsedMessage.data.Items) {
            Route__c upsertedRoute = upsertedRouteMap.get(routeItem.RouteId);
            if(routeIdToItemNamesMap.get(upsertedRoute.Id) != null) {
                itemNamesToDelete.addAll(routeIdToItemNamesMap.get(upsertedRoute.Id));
            }

            itemNamesToInsert.addAll(ItemNamesHelper.getItemNamesToInsert(routeItem.Name, new ERPMessageParser.NameObject(), upsertedRoute.Id, 'Route'));
        }

        if(!itemNamesToDelete.isEmpty()) {
            delete itemNamesToDelete;
        }

        insert itemNamesToInsert;
    }

    private static Map<Decimal, Route__c> getRouteMap() {
        Map<Decimal, Route__c> routeMap = new Map<Decimal, Route__c>();
        List<Route__c> routeList = [SELECT Id, ID_ERP__c FROM Route__c];

        for(Route__c route : routeList) {
            routeMap.put(route.ID_ERP__c, route);
        }

        return routeMap;
    }

    private static Map<String, Id> getShopMap() {
        Map<String, Id> shopMap = new Map<String, Id>();
        List<Shop__c> shopList = [SELECT Id, ID_ERP__c FROM Shop__c];

        for(Shop__c shop : shopList) {
            shopMap.put(shop.ID_ERP__c, shop.Id);
        }

        return shopMap;
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