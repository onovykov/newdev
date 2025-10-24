public with sharing class ERPMessageHandlerStructQuotaConfig {
    
    public static MessageProcessingResult processMessage(ERPMessageParser.ErpToSfMessage_StructQuotaConfig parsedMessage) {
        MessageProcessingResult res = new MessageProcessingResult();
        res.MessageType = parsedMessage.metadata.MsgType;

        try {
            String operationMode = String.valueOf(parsedMessage.data.Mode);
            Map<String, QuoteSegmentStruct__c> quoteSegmentStructMap = getQuoteSegmentStructMap();

            switch on operationMode {
                when 'MERGE' {
                    modifyQuoteSegmentStructures(parsedMessage, quoteSegmentStructMap);
                    deleteQuoteSegmentStructs(parsedMessage, quoteSegmentStructMap, false);
                } when 'MODIFY' {
                    modifyQuoteSegmentStructures(parsedMessage, quoteSegmentStructMap);
                } when 'DELETE' {
                    deleteQuoteSegmentStructs(parsedMessage, quoteSegmentStructMap, true);
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

    private static void modifyQuoteSegmentStructures(ERPMessageParser.ErpToSfMessage_StructQuotaConfig parsedMessage, Map<String, QuoteSegmentStruct__c> quoteSegmentStructMap) {
        List<QuoteSegmentStruct__c> quoteSegmentStructToUpsertList = new List<QuoteSegmentStruct__c>();

        for (ERPMessageParser.StructQuotaConfigItem quoteSegmentStructItem : parsedMessage.data.Items) {
            QuoteSegmentStruct__c quoteSegmentStructToUpsert = new QuoteSegmentStruct__c();
            if(quoteSegmentStructMap.get(quoteSegmentStructItem.SegmentCode) != null) {
                quoteSegmentStructToUpsert.Id = quoteSegmentStructMap.get(quoteSegmentStructItem.SegmentCode).Id;
            }
            quoteSegmentStructToUpsert.MarketSegment__c = quoteSegmentStructItem.SegmentCode;
            quoteSegmentStructToUpsert.ManagerStruct__c = quoteSegmentStructItem.IncludeSaleKdk;
            quoteSegmentStructToUpsert.RegionStruct__c = quoteSegmentStructItem.IncludeRegion;
            quoteSegmentStructToUpsert.Group3Struct__c = quoteSegmentStructItem.IncludeGrp3;
            quoteSegmentStructToUpsert.Is_Active__c = quoteSegmentStructItem.IsActive;

            quoteSegmentStructToUpsertList.add(quoteSegmentStructToUpsert);
        }

        upsert quoteSegmentStructToUpsertList;
    }

    private static void deleteQuoteSegmentStructs(ERPMessageParser.ErpToSfMessage_StructQuotaConfig parsedMessage, Map<String, QuoteSegmentStruct__c> quoteSegmentStructMap, Boolean isDeleteMode) {
        List<String> quoteSegmentStructERPIdList = new List<String>();
        List<QuoteSegmentStruct__c> quoteSegmentStructToDeleteList = new List<QuoteSegmentStruct__c>();

        for(ERPMessageParser.StructQuotaConfigItem quoteSegmentStructItem : parsedMessage.data.Items) {
            if(isDeleteMode && quoteSegmentStructMap.get(quoteSegmentStructItem.SegmentCode) != null) {
                quoteSegmentStructToDeleteList.add(quoteSegmentStructMap.get(quoteSegmentStructItem.SegmentCode));
            } else if(!isDeleteMode) {
                quoteSegmentStructERPIdList.add(quoteSegmentStructItem.SegmentCode);
            }
        }

        if(!isDeleteMode) {
            for(QuoteSegmentStruct__c quoteSegmentStructItem : quoteSegmentStructMap.values()) {
                if(!quoteSegmentStructERPIdList.contains(quoteSegmentStructItem.MarketSegment__c)) {
                    quoteSegmentStructToDeleteList.add(quoteSegmentStructItem);
                } 
            }
        }

        delete quoteSegmentStructToDeleteList;
    }

    private static Map<String, QuoteSegmentStruct__c> getQuoteSegmentStructMap() {
        Map<String, QuoteSegmentStruct__c> quoteSegmentStructMap = new Map<String, QuoteSegmentStruct__c>();
        List<QuoteSegmentStruct__c> quoteSegmentStructList = [SELECT Id, MarketSegment__c FROM QuoteSegmentStruct__c];

        for(QuoteSegmentStruct__c quoteSegmentStruct : quoteSegmentStructList) {
            quoteSegmentStructMap.put(quoteSegmentStruct.MarketSegment__c, quoteSegmentStruct);
        }

        return quoteSegmentStructMap;
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