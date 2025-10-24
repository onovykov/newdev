@IsTest
public class ERPMessageHandlerRouteTest {

    @TestSetup
    static void makeDate() {
        Shop__c shop = new Shop__c(Name = 'Shop Name', ID_ERP__c = '1');
        insert shop;

        Route__c route1 = new Route__c(Name = 'Route Name', ID_ERP__c = 1);
        Route__c route20 = new Route__c(Name = 'Route Name', ID_ERP__c = 20);
        insert new List<Route__c>{route1, route20};

        ItemNames__c itemName = new ItemNames__c(ItemId__c = route1.Id, Language__c = 'EN', ItemNameInLng__c = 'Test Name');
        insert itemName;
    }

    @IsTest
    static void testMergeRoutes() {
        ERPMessageParser.ErpToSfMessage_Route mockParsedMessage = createMockERPMessage('MERGE');

        Test.startTest();
        ERPMessageHandlerRoute.MessageProcessingResult result = ERPMessageHandlerRoute.processMessage(mockParsedMessage);
        Test.stopTest();

        List<Route__c> upsertedRoutes = [SELECT Id FROM Route__c];

        Assert.areEqual(10, upsertedRoutes.size(), 'There should be 10 records - оne route should be deleted');
    }

    @IsTest
    static void testModifyRoutes() {
        ERPMessageParser.ErpToSfMessage_Route mockParsedMessage = createMockERPMessage('MODIFY');

        Test.startTest();
        ERPMessageHandlerRoute.MessageProcessingResult result = ERPMessageHandlerRoute.processMessage(mockParsedMessage);
        Test.stopTest();

        List<Route__c> upsertedRoutes = [SELECT Id FROM Route__c];

        Assert.areEqual(11, upsertedRoutes.size(), 'There should be 11 records');
    }

    @IsTest
    static void testDeleteRoutes() {
        ERPMessageParser.ErpToSfMessage_Route mockParsedMessage = createMockERPMessage('DELETE');

        Test.startTest();
        ERPMessageHandlerRoute.MessageProcessingResult result = ERPMessageHandlerRoute.processMessage(mockParsedMessage);
        Test.stopTest();

        List<Route__c> upsertedRoutes = [SELECT Id FROM Route__c];

        Assert.areEqual(1, upsertedRoutes.size(), 'There should be 1 record');
    }

    @IsTest
    static void testUnsupportedMode() {
        ERPMessageParser.ErpToSfMessage_Route mockParsedMessage = createMockERPMessage('Insert');

        Test.startTest();
        ERPMessageHandlerRoute.MessageProcessingResult result = ERPMessageHandlerRoute.processMessage(mockParsedMessage);
        Test.stopTest();

        Assert.isTrue(result.error.contains('Unsupported mode'), 'Result should not be null');
    }

    @isTest static void testGenerateResponseBody() {
        Map<Integer, String> statusCodesMap = new Map<Integer, String>{
            200 => 'OK',
            400 => 'Bad Request'
        };
        ERPMessageHandlerRoute.MessageProcessingResult mpRes = new ERPMessageHandlerRoute.MessageProcessingResult();
        mpRes.MessageType = 'ERP-SF_Route';

        Blob responseBody = ERPMessageHandlerRoute.generateResponseBody(statusCodesMap, 200, null, mpRes);
        String responseString = responseBody.toString();
        Assert.isTrue(responseString.contains('ERP-SF_Route'), 'Response should contain the processed message type.');

        Blob errorResponseBody = ERPMessageHandlerRoute.generateResponseBody(statusCodesMap, 400, 'An error occurred', mpRes);
        String errorResponseString = errorResponseBody.toString();
        Assert.isTrue(errorResponseString.contains('An error occurred'), 'Response should contain the error message.');
    }

    private static ERPMessageParser.ErpToSfMessage_Route createMockERPMessage(String mode) {
        ERPMessageParser.ErpToSfMessage_Route mockMessage = new ERPMessageParser.ErpToSfMessage_Route();

        // Mock Metadata
        mockMessage.Metadata = new ERPMessageParser.MessageMetadata();
        mockMessage.Metadata.MsgType = 'TestType';

        // Mock RouteMessageData
        ERPMessageParser.RouteMessageData routeData = new ERPMessageParser.RouteMessageData();
        routeData.Mode = mode;

        //Mock Names
        ERPMessageParser.NameObject itemName = new ERPMessageParser.NameObject();
        itemName.DefaultName = 'Test Name';
        itemName.Uk = 'Тестова Назва';
        itemName.Ru = 'Тестовое Название';

        // Mock Items
        List<ERPMessageParser.RouteItem> ItemList = new List<ERPMessageParser.RouteItem>();
        for(Integer i = 1; i < 11; i++) {
            ERPMessageParser.RouteItem item = new ERPMessageParser.RouteItem();
            item.RouteId = i;
            item.ShopId = 1;
            item.IsEmpty = false;
            item.UsePcs = false;
            item.ProdDays = 0;
            item.Comment = 'ТПЦ2;ТПЦ2;Shop2: lp GOST;0;';
            item.IsActive = true;
            item.Name = itemName;
            ItemList.add(Item);
        }

        routeData.Items = ItemList;
        mockMessage.data = routeData;

        return mockMessage;
    }
}