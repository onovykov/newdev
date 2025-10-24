@IsTest
public class ERPMessageHandlerRouteFamilyTest {

    @TestSetup
    static void makeDate() {
        List<Family__c> familyToInsertList = new List<Family__c>();
        for(Integer i = 1; i < 11; i++) {
            Family__c family = new Family__c(Name = 'Family Name', ID_ERP__c = i);
            familyToInsertList.add(family);
        }
        insert familyToInsertList;

        List<Route__c> routeToInsertList = new List<Route__c>();
        for(Integer i = 1; i < 11; i++) {
            Route__c route = new Route__c(Name = 'Route Name', ID_ERP__c = i);
            routeToInsertList.add(route);
        }
        insert routeToInsertList;

        RouteFamilyLink__c routeFamily = new RouteFamilyLink__c(Family__c = familyToInsertList.get(0).Id, Route__c = routeToInsertList.get(1).Id);
        insert routeFamily;
    }

    @IsTest
    static void testMergeRoutes() {
        ERPMessageParser.ErpToSfMessage_RouteFamilies mockParsedMessage = createMockERPMessage('MERGE');

        Test.startTest();
        ERPMessageHandlerRouteFamily.MessageProcessingResult result = ERPMessageHandlerRouteFamily.processMessage(mockParsedMessage);
        Test.stopTest();

        List<RouteFamilyLink__c> upsertedRoutesFamilies = [SELECT Id FROM RouteFamilyLink__c];

        Assert.areEqual(10, upsertedRoutesFamilies.size(), 'There should be 10 records - оne route family should be deleted');
    }

    @IsTest
    static void testModifyRoutes() {
        ERPMessageParser.ErpToSfMessage_RouteFamilies mockParsedMessage = createMockERPMessage('MODIFY');

        Test.startTest();
        ERPMessageHandlerRouteFamily.MessageProcessingResult result = ERPMessageHandlerRouteFamily.processMessage(mockParsedMessage);
        Test.stopTest();

        List<RouteFamilyLink__c> upsertedRoutesFamilies = [SELECT Id FROM RouteFamilyLink__c];

        Assert.areEqual(11, upsertedRoutesFamilies.size(), 'There should be 11 records');
    }

    @IsTest
    static void testDeleteRoutes() {
        ERPMessageParser.ErpToSfMessage_RouteFamilies mockParsedMessage = createMockERPMessage('DELETE');

        Test.startTest();
        ERPMessageHandlerRouteFamily.MessageProcessingResult result = ERPMessageHandlerRouteFamily.processMessage(mockParsedMessage);
        Test.stopTest();

        List<RouteFamilyLink__c> upsertedRoutesFamilies = [SELECT Id FROM RouteFamilyLink__c];

        Assert.areEqual(1, upsertedRoutesFamilies.size(), 'There should be 1 record');
    }

    @IsTest
    static void testUnsupportedMode() {
        ERPMessageParser.ErpToSfMessage_RouteFamilies mockParsedMessage = createMockERPMessage('Insert');

        Test.startTest();
        ERPMessageHandlerRouteFamily.MessageProcessingResult result = ERPMessageHandlerRouteFamily.processMessage(mockParsedMessage);
        Test.stopTest();

        Assert.isTrue(result.error.contains('Unsupported mode'), 'Result should not be null');
    }

    @isTest static void testGenerateResponseBody() {
        Map<Integer, String> statusCodesMap = new Map<Integer, String>{
            200 => 'OK',
            400 => 'Bad Request'
        };
        ERPMessageHandlerRouteFamily.MessageProcessingResult mpRes = new ERPMessageHandlerRouteFamily.MessageProcessingResult();
        mpRes.MessageType = 'ERP-SF_RouteFamilies';

        Blob responseBody = ERPMessageHandlerRouteFamily.generateResponseBody(statusCodesMap, 200, null, mpRes);
        String responseString = responseBody.toString();
        Assert.isTrue(responseString.contains('ERP-SF_Route'), 'Response should contain the processed message type.');

        Blob errorResponseBody = ERPMessageHandlerRouteFamily.generateResponseBody(statusCodesMap, 400, 'An error occurred', mpRes);
        String errorResponseString = errorResponseBody.toString();
        Assert.isTrue(errorResponseString.contains('An error occurred'), 'Response should contain the error message.');
    }

    private static ERPMessageParser.ErpToSfMessage_RouteFamilies createMockERPMessage(String mode) {
        ERPMessageParser.ErpToSfMessage_RouteFamilies mockMessage = new ERPMessageParser.ErpToSfMessage_RouteFamilies();

        // Mock Metadata
        mockMessage.Metadata = new ERPMessageParser.MessageMetadata();
        mockMessage.Metadata.MsgType = 'TestType';

        // Mock RouteFamilyMessageData
        ERPMessageParser.RouteFamilyMessageData familyRouteData = new ERPMessageParser.RouteFamilyMessageData();
        familyRouteData.Mode = mode;

        // Mock Items
        List<ERPMessageParser.RouteFamilyItem> ItemList = new List<ERPMessageParser.RouteFamilyItem>();
        for(Integer i = 1; i < 11; i++) {
            ERPMessageParser.FamilyItem familyItem = new ERPMessageParser.FamilyItem();
            familyItem.FamilyId = i;

            ERPMessageParser.RouteItem routeItem = new ERPMessageParser.RouteItem();
            routeItem.RouteId = i;

            ERPMessageParser.RouteFamilyItem item = new ERPMessageParser.RouteFamilyItem();
            item.Route = routeItem;
            item.Families = new List<ERPMessageParser.FamilyItem>{familyItem};
            ItemList.add(Item);
        }

        familyRouteData.Items = ItemList;
        mockMessage.data = familyRouteData;

        return mockMessage;
    }
    
}