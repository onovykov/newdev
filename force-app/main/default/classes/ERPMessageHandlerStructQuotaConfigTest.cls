@IsTest
public class ERPMessageHandlerStructQuotaConfigTest {

    @TestSetup
    static void makeDate() {
        QuoteSegmentStruct__c quoteSegmentStructAmericas = new QuoteSegmentStruct__c(MarketSegment__c = '00001');
        QuoteSegmentStruct__c quoteSegmentStructMENA = new QuoteSegmentStruct__c(MarketSegment__c = '00002');
        insert new List<QuoteSegmentStruct__c>{quoteSegmentStructAmericas, quoteSegmentStructMENA};
    }

    @IsTest
    static void testMergeQuoteSegmentStruct() {
        ERPMessageParser.ErpToSfMessage_StructQuotaConfig mockParsedMessage = createMockERPMessage('MERGE');

        Test.startTest();
        ERPMessageHandlerStructQuotaConfig.MessageProcessingResult result = ERPMessageHandlerStructQuotaConfig.processMessage(mockParsedMessage);
        Test.stopTest();

        List<QuoteSegmentStruct__c> upsertedQuoteSegmentStruct = [SELECT Id FROM QuoteSegmentStruct__c];

        Assert.areEqual(2, upsertedQuoteSegmentStruct.size(), 'There should be 2 records - оne route should be deleted');
    }

    @IsTest
    static void testModifyQuoteSegmentStruct() {
        ERPMessageParser.ErpToSfMessage_StructQuotaConfig mockParsedMessage = createMockERPMessage('MODIFY');

        Test.startTest();
        ERPMessageHandlerStructQuotaConfig.MessageProcessingResult result = ERPMessageHandlerStructQuotaConfig.processMessage(mockParsedMessage);
        Test.stopTest();

        List<QuoteSegmentStruct__c> upsertedQuoteSegmentStruct = [SELECT Id FROM QuoteSegmentStruct__c];

        Assert.areEqual(3, upsertedQuoteSegmentStruct.size(), 'There should be 3 records');
    }

    @IsTest
    static void testDeleteQuoteSegmentStruct() {
        ERPMessageParser.ErpToSfMessage_StructQuotaConfig mockParsedMessage = createMockERPMessage('DELETE');

        Test.startTest();
        ERPMessageHandlerStructQuotaConfig.MessageProcessingResult result = ERPMessageHandlerStructQuotaConfig.processMessage(mockParsedMessage);
        Test.stopTest();

        List<QuoteSegmentStruct__c> upsertedQuoteSegmentStruct = [SELECT Id FROM QuoteSegmentStruct__c];

        Assert.areEqual(1, upsertedQuoteSegmentStruct.size(), 'There should be 1 record');
    }

    @IsTest
    static void testUnsupportedMode() {
        ERPMessageParser.ErpToSfMessage_StructQuotaConfig mockParsedMessage = createMockERPMessage('Insert');

        Test.startTest();
        ERPMessageHandlerStructQuotaConfig.MessageProcessingResult result = ERPMessageHandlerStructQuotaConfig.processMessage(mockParsedMessage);
        Test.stopTest();

        Assert.isTrue(result.error.contains('Unsupported mode'), 'Result should not be null');
    }

    @isTest static void testGenerateResponseBody() {
        Map<Integer, String> statusCodesMap = new Map<Integer, String>{
            200 => 'OK',
            400 => 'Bad Request'
        };
        ERPMessageHandlerStructQuotaConfig.MessageProcessingResult mpRes = new ERPMessageHandlerStructQuotaConfig.MessageProcessingResult();
        mpRes.MessageType = 'ErpToSfMessage_StructQuotaConfig';

        Blob responseBody = ERPMessageHandlerStructQuotaConfig.generateResponseBody(statusCodesMap, 200, null, mpRes);
        String responseString = responseBody.toString();
        Assert.isTrue(responseString.contains('ErpToSfMessage_StructQuotaConfig'), 'Response should contain the processed message type.');

        Blob errorResponseBody = ERPMessageHandlerStructQuotaConfig.generateResponseBody(statusCodesMap, 400, 'An error occurred', mpRes);
        String errorResponseString = errorResponseBody.toString();
        Assert.isTrue(errorResponseString.contains('An error occurred'), 'Response should contain the error message.');
    }

    private static ERPMessageParser.ErpToSfMessage_StructQuotaConfig createMockERPMessage(String mode) {
        ERPMessageParser.ErpToSfMessage_StructQuotaConfig mockMessage = new ERPMessageParser.ErpToSfMessage_StructQuotaConfig();

        // Mock Metadata
        mockMessage.Metadata = new ERPMessageParser.MessageMetadata();
        mockMessage.Metadata.MsgType = 'TestType';

        // Mock StructQuotaConfigMessageData
        ERPMessageParser.StructQuotaConfigMessageData quoteSegmentStructData = new ERPMessageParser.StructQuotaConfigMessageData();
        quoteSegmentStructData.Mode = mode;

        // Mock Items
        ERPMessageParser.StructQuotaConfigItem itemAmericas = new ERPMessageParser.StructQuotaConfigItem();
        itemAmericas.SegmentCode = '00001';
        itemAmericas.IncludeRegion = true;
        itemAmericas.IncludeSaleKdk = false;
        itemAmericas.IncludeGrp3 = false;
        itemAmericas.IsActive = true;

        ERPMessageParser.StructQuotaConfigItem itemEurope = new ERPMessageParser.StructQuotaConfigItem();
        itemEurope.SegmentCode = '00004';
        itemEurope.IncludeRegion = false;
        itemEurope.IncludeSaleKdk = true;
        itemEurope.IncludeGrp3 = false;
        itemEurope.IsActive = true;

        quoteSegmentStructData.Items = new List<ERPMessageParser.StructQuotaConfigItem>{itemAmericas, itemEurope};
        mockMessage.data = quoteSegmentStructData;

        return mockMessage;
    }

}