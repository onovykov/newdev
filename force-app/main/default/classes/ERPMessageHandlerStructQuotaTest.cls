@IsTest
public class ERPMessageHandlerStructQuotaTest {

    @TestSetup
    static void makeDate() {
        Family__c family = new Family__c(Name = 'Family Name', ID_ERP__c = 1);
        insert family;

        Group3__c group3 = new Group3__c(Name = 'Group Name', ID_ERP__c = 1);
        insert group3;

        Region__c region = new Region__c(Name = 'Region Name', ID_ERP__c = 1);
        insert region;

        QuotesStructure__c structQuota1 = new QuotesStructure__c(ID_ERP__c = '1', Group3__c = group3.Id, Region__c = region.Id, Family__c = family.Id, MarketSegment__c = '00001', DateBegin__c = date.newinstance(2024, 9, 1), DateEnd__c = date.newinstance(2024, 9, 30));
        QuotesStructure__c structQuota11 = new QuotesStructure__c(ID_ERP__c = '11', Group3__c = group3.Id, Region__c = region.Id, Family__c = family.Id, MarketSegment__c = '00001', DateBegin__c = date.newinstance(2024, 6, 1), DateEnd__c = date.newinstance(2024, 6, 30));
        insert new List<QuotesStructure__c>{structQuota1, structQuota11};
    }

    @IsTest
    static void testMergeStructQuotas() {
        ERPMessageParser.ErpToSfMessage_StructQuota mockParsedMessage = createMockERPMessage('MERGE', 1, 1);

        Test.startTest();
        ERPMessageHandlerStructQuota.MessageProcessingResult result = ERPMessageHandlerStructQuota.processMessage(mockParsedMessage);
        Test.stopTest();

        List<QuotesStructure__c> upsertedStructQuotas = [SELECT Id FROM QuotesStructure__c];

        Assert.areEqual(10, upsertedStructQuotas.size(), 'There should be 10 Route Quotas records  - оne record should be deleted');
    }

    @IsTest
    static void testMergePartialStructQuotas() {
        ERPMessageParser.ErpToSfMessage_StructQuota mockParsedMessage = createMockERPMessage('MERGE_PARTIAL', 1, 1);

        Test.startTest();
        ERPMessageHandlerStructQuota.MessageProcessingResult result = ERPMessageHandlerStructQuota.processMessage(mockParsedMessage);
        Test.stopTest();

        List<QuotesStructure__c> upsertedStructQuotas = [SELECT Id FROM QuotesStructure__c];

        Assert.areEqual(11, upsertedStructQuotas.size(), 'There should be 11 Route Quotas records');
    }

    @IsTest
    static void testModifyStructQuotas() {
        ERPMessageParser.ErpToSfMessage_StructQuota mockParsedMessage = createMockERPMessage('MODIFY', 1, 1);

        Test.startTest();
        ERPMessageHandlerStructQuota.MessageProcessingResult result = ERPMessageHandlerStructQuota.processMessage(mockParsedMessage);
        Test.stopTest();

        List<QuotesStructure__c> upsertedStructQuotas = [SELECT Id FROM QuotesStructure__c];

        Assert.areEqual(11, upsertedStructQuotas.size(), 'There should be 11 Route Quotas records');
    }

    @IsTest
    static void testMergeStructQuotasBulk() {
        ERPMessageParser.ErpToSfMessage_StructQuota mockParsedMessage = createMockERPMessage('MERGE', 3, 1);
        ERPMessageParser.ErpToSfMessage_StructQuota mockParsedMessage2 = createMockERPMessage('MERGE', 3, 21);
        ERPMessageParser.ErpToSfMessage_StructQuota mockParsedMessage3 = createMockERPMessage('MERGE', 3, 31);

        Test.startTest();
        ERPMessageHandlerStructQuota.MessageProcessingResult result = ERPMessageHandlerStructQuota.processMessage(mockParsedMessage);
        ERPMessageHandlerStructQuota.MessageProcessingResult result2 = ERPMessageHandlerStructQuota.processMessage(mockParsedMessage2);
        ERPMessageHandlerStructQuota.MessageProcessingResult result3 = ERPMessageHandlerStructQuota.processMessage(mockParsedMessage3);
        Test.stopTest();

        List<QuotesStructure__c> upsertedStructQuotas = [SELECT Id FROM QuotesStructure__c];

        Assert.areEqual(30, upsertedStructQuotas.size(), 'There should be 10 Route Quotas records  - оne record should be deleted');
    }

    @IsTest
    static void testMergePartialStructQuotasBulk() {
        ERPMessageParser.ErpToSfMessage_StructQuota mockParsedMessage = createMockERPMessage('MERGE_PARTIAL', 2, 1);
        ERPMessageParser.ErpToSfMessage_StructQuota mockParsedMessage2 = createMockERPMessage('MERGE_PARTIAL', 2, 21);

        Test.startTest();
        ERPMessageHandlerStructQuota.MessageProcessingResult result = ERPMessageHandlerStructQuota.processMessage(mockParsedMessage);
        ERPMessageHandlerStructQuota.MessageProcessingResult result2 = ERPMessageHandlerStructQuota.processMessage(mockParsedMessage2);
        Test.stopTest();

        List<QuotesStructure__c> upsertedStructQuotas = [SELECT Id FROM QuotesStructure__c];

        Assert.areEqual(21, upsertedStructQuotas.size(), 'There should be 11 Route Quotas records');
    }

    @IsTest
    static void testDeleteStructQuotas() {
        ERPMessageParser.ErpToSfMessage_StructQuota mockParsedMessage = createMockERPMessage('DELETE', 1, 1);

        Test.startTest();
        ERPMessageHandlerStructQuota.MessageProcessingResult result = ERPMessageHandlerStructQuota.processMessage(mockParsedMessage);
        Test.stopTest();

        List<QuotesStructure__c> upsertedStructQuotas = [SELECT Id FROM QuotesStructure__c];

        Assert.areEqual(1, upsertedStructQuotas.size(), 'There should be 1 record');
    }

    @IsTest
    static void testUnsupportedMode() {
        ERPMessageParser.ErpToSfMessage_StructQuota mockParsedMessage = createMockERPMessage('Insert', 1, 1);

        Test.startTest();
        ERPMessageHandlerStructQuota.MessageProcessingResult result = ERPMessageHandlerStructQuota.processMessage(mockParsedMessage);
        Test.stopTest();

        Assert.isTrue(result.error.contains('Unsupported mode'), 'Result should not be null');
    }

    @IsTest
    static void testStructQuotasWithoutFamily() {
        ERPMessageParser.ErpToSfMessage_StructQuota mockParsedMessage = createMockERPMessageWithoutFamily();

        Test.startTest();
        ERPMessageHandlerStructQuota.MessageProcessingResult result = ERPMessageHandlerStructQuota.processMessage(mockParsedMessage);
        Test.stopTest();

        List<QuotesStructure__c> upsertedStructQuotas = [SELECT Id FROM QuotesStructure__c WHERE ID_ERP__c = '2'];

        Assert.areEqual(0, upsertedStructQuotas.size(), 'The record with ID 2 should not be created');
    }

    @isTest 
    static void testGenerateResponseBody() {
        Map<Integer, String> statusCodesMap = new Map<Integer, String>{
            200 => 'OK',
            400 => 'Bad Request'
        };
        ERPMessageHandlerStructQuota.MessageProcessingResult mpRes = new ERPMessageHandlerStructQuota.MessageProcessingResult();
        mpRes.MessageType = 'ERP-SF_StructQuota';

        Blob responseBody = ERPMessageHandlerStructQuota.generateResponseBody(statusCodesMap, 200, null, mpRes);
        String responseString = responseBody.toString();
        Assert.isTrue(responseString.contains('ERP-SF_StructQuota'), 'Response should contain the processed message type.');

        Blob errorResponseBody = ERPMessageHandlerStructQuota.generateResponseBody(statusCodesMap, 400, 'An error occurred', mpRes);
        String errorResponseString = errorResponseBody.toString();
        Assert.isTrue(errorResponseString.contains('An error occurred'), 'Response should contain the error message.');
    }

    private static ERPMessageParser.ErpToSfMessage_StructQuota createMockERPMessage(String mode, Integer totalParts, Integer startNumber) {
        ERPMessageParser.ErpToSfMessage_StructQuota mockMessage = new ERPMessageParser.ErpToSfMessage_StructQuota();

        // Mock Metadata
        mockMessage.Metadata = new ERPMessageParser.MessageMetadata();
        mockMessage.Metadata.MsgType = 'TestType';
        mockMessage.Metadata.msgTimestamp = (DateTime)JSON.deserialize('"2024-09-01T00:00:00"', DateTime.class);
        mockMessage.Metadata.totalParts = totalParts;

        // Mock StructQuotaData
        ERPMessageParser.Options options = new ERPMessageParser.Options();
        options.DATEFROM = (DateTime)JSON.deserialize('"2024-09-01T00:00:00"', DateTime.class);
        options.DATETO = (DateTime)JSON.deserialize('"2024-09-30T00:00:00"', DateTime.class);
        
        ERPMessageParser.Partial partial = new ERPMessageParser.Partial();
        partial.Type = 'PERIOD';
        partial.Options = options;

        ERPMessageParser.StructQuotaData structQuotaData = new ERPMessageParser.StructQuotaData();
        structQuotaData.Mode = mode;
        structQuotaData.Partial = partial;

        // Mock Items

        ERPMessageParser.FamilyItem familyItem = new ERPMessageParser.FamilyItem();
        familyItem.FamilyId = 1;

        ERPMessageParser.StructQuotaConfigItem structConfigItem = new ERPMessageParser.StructQuotaConfigItem();
        structConfigItem.SegmentCode = '00001';

        List<ERPMessageParser.StructQuotaItem> ItemList = new List<ERPMessageParser.StructQuotaItem>();
        for(Integer i = startNumber; i < startNumber + 10; i++) {
            ERPMessageParser.StructQuotaItem item = new ERPMessageParser.StructQuotaItem();
            item.RowId = i;
            item.DateFrom = (DateTime)JSON.deserialize('"2024-09-01T00:00:00"', DateTime.class);
            item.DateTo = (DateTime)JSON.deserialize('"2024-09-30T00:00:00"', DateTime.class);
            item.Qty_percent = 26.65;
            item.Qty_add_pcs = 0.0000;
            item.Qty_add_t = 0.0000;
            item.Region = 1;
            item.Grp3 = 1;
            item.SaleKdk = '1';
            item.Family = familyItem;
            item.StructConfig = structConfigItem;
            ItemList.add(Item);
        }

        structQuotaData.Items = ItemList;
        mockMessage.data = structQuotaData;

        return mockMessage;
    }

    private static ERPMessageParser.ErpToSfMessage_StructQuota createMockERPMessageWithoutFamily() {
        ERPMessageParser.ErpToSfMessage_StructQuota mockMessage = new ERPMessageParser.ErpToSfMessage_StructQuota();

        // Mock Metadata
        mockMessage.Metadata = new ERPMessageParser.MessageMetadata();
        mockMessage.Metadata.MsgType = 'TestType';
        mockMessage.Metadata.msgTimestamp = (DateTime)JSON.deserialize('"2024-09-01T00:00:00"', DateTime.class);
        mockMessage.Metadata.totalParts = 1;

        // Mock StructQuotaData
        ERPMessageParser.Options options = new ERPMessageParser.Options();
        options.DATEFROM = (DateTime)JSON.deserialize('"2024-09-01T00:00:00"', DateTime.class);
        options.DATETO = (DateTime)JSON.deserialize('"2024-09-30T00:00:00"', DateTime.class);
        
        ERPMessageParser.Partial partial = new ERPMessageParser.Partial();
        partial.Type = 'PERIOD';
        partial.Options = options;

        ERPMessageParser.StructQuotaData structQuotaData = new ERPMessageParser.StructQuotaData();
        structQuotaData.Mode = 'MODIFY';
        structQuotaData.Partial = partial;

        ERPMessageParser.StructQuotaItem item = new ERPMessageParser.StructQuotaItem();
        item.RowId = 2;
        List<ERPMessageParser.StructQuotaItem> ItemList = new List<ERPMessageParser.StructQuotaItem>{item};

        structQuotaData.Items = ItemList;
        mockMessage.data = structQuotaData;

        return mockMessage;
    }
}