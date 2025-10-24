@IsTest
public class ERPMessageHandlerRouteQuotaTest {

    @TestSetup
    static void makeDate() {
        Family__c family1 = new Family__c(Name = 'Family Name', ID_ERP__c = 1);
        Family__c family2 = new Family__c(Name = 'Family Name', ID_ERP__c = 2);
        insert new List<Family__c>{family1, family2};

        Route__c route = new Route__c(Name = 'Route Name', ID_ERP__c = 1);
        insert route;

        Route_Quota__c routeQuota1 = new Route_Quota__c(ID_ERP__c = '1', Route__c = route.Id, DateBegin__c = date.newinstance(2024, 9, 1), DateEnd__c = date.newinstance(2024, 9, 30));
        Route_Quota__c routeQuota11 = new Route_Quota__c(ID_ERP__c = '11', Route__c = route.Id, DateBegin__c = date.newinstance(2024, 6, 1), DateEnd__c = date.newinstance(2024, 6, 30));
        insert new List<Route_Quota__c>{routeQuota1, routeQuota11};

        QBA_Families__c quotaFamily = new QBA_Families__c(QuotesBudgetAll__c = routeQuota1.Id, Family__c = family2.Id);
        insert quotaFamily;
    }

    @IsTest
    static void testMergeRouteQuotas() {
        ERPMessageParser.ErpToSfMessage_RouteQuota mockParsedMessage = createMockERPMessage('MERGE', 1, 1);

        Test.startTest();
        ERPMessageHandlerRouteQuota.MessageProcessingResult result = ERPMessageHandlerRouteQuota.processMessage(mockParsedMessage);
        Test.stopTest();

        List<Route_Quota__c> upsertedRouteQuotas = [SELECT Id FROM Route_Quota__c];
        Route_Quota__c upsertedRouteQuota1 = [SELECT Id FROM Route_Quota__c WHERE ID_ERP__c = '1'];
        List<QBA_Families__c> upsertedQuotaFamilies = [SELECT Id, Family__r.ID_ERP__c, QuotesBudgetAll__c FROM QBA_Families__c WHERE QuotesBudgetAll__c = :upsertedRouteQuota1.Id];

        Assert.areEqual(10, upsertedRouteQuotas.size(), 'There should be 10 Route Quotas records  - оne record should be deleted');
        Assert.areEqual(1, upsertedQuotaFamilies.size(), 'There should be 1 Quota Family record - оne record should be deleted');
        Assert.areEqual(1, upsertedQuotaFamilies.get(0).Family__r.ID_ERP__c, 'The Family Id in ERP should be 1');
    }

    @IsTest
    static void testMergePartialRouteQuotas() {
        ERPMessageParser.ErpToSfMessage_RouteQuota mockParsedMessage = createMockERPMessage('MERGE_PARTIAL', 1, 1);

        Test.startTest();
        ERPMessageHandlerRouteQuota.MessageProcessingResult result = ERPMessageHandlerRouteQuota.processMessage(mockParsedMessage);
        Test.stopTest();

        List<Route_Quota__c> upsertedRouteQuotas = [SELECT Id FROM Route_Quota__c];

        Assert.areEqual(11, upsertedRouteQuotas.size(), 'There should be 11 Route Quotas records');
    }

    @IsTest
    static void testMergeRouteQuotasBulk() {
        ERPMessageParser.ErpToSfMessage_RouteQuota mockParsedMessage = createMockERPMessage('MERGE', 3, 1);
        ERPMessageParser.ErpToSfMessage_RouteQuota mockParsedMessage2 = createMockERPMessage('MERGE', 3, 21);
        ERPMessageParser.ErpToSfMessage_RouteQuota mockParsedMessage3 = createMockERPMessage('MERGE', 3, 31);

        Test.startTest();
        ERPMessageHandlerRouteQuota.MessageProcessingResult result = ERPMessageHandlerRouteQuota.processMessage(mockParsedMessage);
        ERPMessageHandlerRouteQuota.MessageProcessingResult result2 = ERPMessageHandlerRouteQuota.processMessage(mockParsedMessage2);
        ERPMessageHandlerRouteQuota.MessageProcessingResult result3 = ERPMessageHandlerRouteQuota.processMessage(mockParsedMessage3);
        Test.stopTest();

        List<Route_Quota__c> upsertedRouteQuotas = [SELECT Id FROM Route_Quota__c];
        Route_Quota__c upsertedRouteQuota1 = [SELECT Id FROM Route_Quota__c WHERE ID_ERP__c = '1'];
        List<QBA_Families__c> upsertedQuotaFamilies = [SELECT Id, Family__r.ID_ERP__c, QuotesBudgetAll__c FROM QBA_Families__c WHERE QuotesBudgetAll__c = :upsertedRouteQuota1.Id];

        Assert.areEqual(30, upsertedRouteQuotas.size(), 'There should be 10 Route Quotas records  - оne record should be deleted');
        Assert.areEqual(1, upsertedQuotaFamilies.size(), 'There should be 1 Quota Family record - оne record should be deleted');
        Assert.areEqual(1, upsertedQuotaFamilies.get(0).Family__r.ID_ERP__c, 'The Family Id in ERP should be 1');
    }

    @IsTest
    static void testMergePartialRouteQuotasBulk() {
        ERPMessageParser.ErpToSfMessage_RouteQuota mockParsedMessage = createMockERPMessage('MERGE_PARTIAL', 2, 1);
        ERPMessageParser.ErpToSfMessage_RouteQuota mockParsedMessage2 = createMockERPMessage('MERGE_PARTIAL', 2, 21);

        Test.startTest();
        ERPMessageHandlerRouteQuota.MessageProcessingResult result = ERPMessageHandlerRouteQuota.processMessage(mockParsedMessage);
        ERPMessageHandlerRouteQuota.MessageProcessingResult result2 = ERPMessageHandlerRouteQuota.processMessage(mockParsedMessage2);
        Test.stopTest();

        List<Route_Quota__c> upsertedRouteQuotas = [SELECT Id FROM Route_Quota__c];

        Assert.areEqual(21, upsertedRouteQuotas.size(), 'There should be 11 Route Quotas records');
    }

    @IsTest
    static void testModifyRouteQuotas() {
        ERPMessageParser.ErpToSfMessage_RouteQuota mockParsedMessage = createMockERPMessage('MODIFY', 1, 1);

        Test.startTest();
        ERPMessageHandlerRouteQuota.MessageProcessingResult result = ERPMessageHandlerRouteQuota.processMessage(mockParsedMessage);
        Test.stopTest();

        List<Route_Quota__c> upsertedRouteQuotas = [SELECT Id FROM Route_Quota__c];

        Assert.areEqual(11, upsertedRouteQuotas.size(), 'There should be 11 Route Quotas records');
    }
    
    @IsTest
    static void testDeleteRouteQuotas() {
        ERPMessageParser.ErpToSfMessage_RouteQuota mockParsedMessage = createMockERPMessage('DELETE', 1, 1);

        Test.startTest();
        ERPMessageHandlerRouteQuota.MessageProcessingResult result = ERPMessageHandlerRouteQuota.processMessage(mockParsedMessage);
        Test.stopTest();

        List<Route_Quota__c> upsertedRouteQuotas = [SELECT Id FROM Route_Quota__c];

        Assert.areEqual(1, upsertedRouteQuotas.size(), 'There should be 1 record');
    }

    @IsTest
    static void testUnsupportedMode() {
        ERPMessageParser.ErpToSfMessage_RouteQuota mockParsedMessage = createMockERPMessage('Insert', 1, 1);

        Test.startTest();
        ERPMessageHandlerRouteQuota.MessageProcessingResult result = ERPMessageHandlerRouteQuota.processMessage(mockParsedMessage);
        Test.stopTest();

        Assert.isTrue(result.error.contains('Unsupported mode'), 'Result should not be null');
    }

    @isTest static void testGenerateResponseBody() {
        Map<Integer, String> statusCodesMap = new Map<Integer, String>{
            200 => 'OK',
            400 => 'Bad Request'
        };
        ERPMessageHandlerRouteQuota.MessageProcessingResult mpRes = new ERPMessageHandlerRouteQuota.MessageProcessingResult();
        mpRes.MessageType = 'ERP-SF_RouteQuota';

        Blob responseBody = ERPMessageHandlerRouteQuota.generateResponseBody(statusCodesMap, 200, null, mpRes);
        String responseString = responseBody.toString();
        Assert.isTrue(responseString.contains('ERP-SF_RouteQuota'), 'Response should contain the processed message type.');

        Blob errorResponseBody = ERPMessageHandlerRouteQuota.generateResponseBody(statusCodesMap, 400, 'An error occurred', mpRes);
        String errorResponseString = errorResponseBody.toString();
        Assert.isTrue(errorResponseString.contains('An error occurred'), 'Response should contain the error message.');
    }

    private static ERPMessageParser.ErpToSfMessage_RouteQuota createMockERPMessage(String mode, Integer totalParts, Integer startNumber) {
        ERPMessageParser.ErpToSfMessage_RouteQuota mockMessage = new ERPMessageParser.ErpToSfMessage_RouteQuota();

        // Mock Metadata
        mockMessage.Metadata = new ERPMessageParser.MessageMetadata();
        mockMessage.Metadata.MsgType = 'TestType';
        mockMessage.Metadata.msgTimestamp = (DateTime)JSON.deserialize('"2024-09-01T00:00:00"', DateTime.class);
        mockMessage.Metadata.totalParts = totalParts;

        // Mock RouteQuotaMessageData
        ERPMessageParser.Options options = new ERPMessageParser.Options();
        options.DATEFROM = (DateTime)JSON.deserialize('"2024-09-01T00:00:00"', DateTime.class);
        options.DATETO = (DateTime)JSON.deserialize('"2024-09-30T00:00:00"', DateTime.class);
        
        ERPMessageParser.Partial partial = new ERPMessageParser.Partial();
        partial.Type = 'PERIOD';
        partial.Options = options;

        ERPMessageParser.RouteQuotaMessageData routeQuotaData = new ERPMessageParser.RouteQuotaMessageData();
        routeQuotaData.Mode = mode;
        routeQuotaData.Partial = partial;

        // Mock Items
        ERPMessageParser.NameObject familyName = new ERPMessageParser.NameObject();
        familyName.DefaultName = 'Test Name';
        familyName.Uk = 'Тестова Назва';
        familyName.Ru = 'Тестовое Название';

        ERPMessageParser.FamilyItem familyItem = new ERPMessageParser.FamilyItem();
        familyItem.FamilyId = 1;
        familyItem.Name = familyName;

        ERPMessageParser.RouteItem routeItem = new ERPMessageParser.RouteItem();
        routeItem.RouteId = 1;

        ERPMessageParser.RouteFamilyItem routeFamilyItem = new ERPMessageParser.RouteFamilyItem();
        routeFamilyItem.Route = routeItem;
        routeFamilyItem.Families = new List<ERPMessageParser.FamilyItem>{familyItem};

        List<ERPMessageParser.RouteQuotaItem> ItemList = new List<ERPMessageParser.RouteQuotaItem>();
        for(Integer i = startNumber; i < startNumber + 10; i++) {
            ERPMessageParser.RouteQuotaItem item = new ERPMessageParser.RouteQuotaItem();
            item.RowId = i;
            item.SegmentCode = '00011';
            item.DateFrom = (DateTime)JSON.deserialize('"2024-09-01T00:00:00"', DateTime.class);
            item.DateTo = (DateTime)JSON.deserialize('"2024-09-30T00:00:00"', DateTime.class);
            item.Quota_t = 60.0120;
            item.Quota_pcs = 0.0000;
            item.Budget_t = 60.0120;
            item.Budget_pcs = 0.0000;
            item.Marginall = 92796.38277;
            item.RouteFamilies = routeFamilyItem;
            ItemList.add(Item);
        }

        routeQuotaData.Items = ItemList;
        mockMessage.data = routeQuotaData;

        return mockMessage;
    }
}