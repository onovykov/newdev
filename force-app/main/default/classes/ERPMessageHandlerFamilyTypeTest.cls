@IsTest
public class ERPMessageHandlerFamilyTypeTest {

    @TestSetup
    static void makeDate() {
        FamiliesTypes__c familyType1 = new FamiliesTypes__c(Name = 'Family Type Name', ID_ERP__c = '1');
        FamiliesTypes__c familyType20 = new FamiliesTypes__c(Name = 'Family Type Name', ID_ERP__c = '20');
        insert new List<FamiliesTypes__c>{familyType1, familyType20};

        ItemNames__c itemName = new ItemNames__c(ItemId__c = familyType1.Id, Language__c = 'EN', ItemNameInLng__c = 'Test Name');
        insert itemName;
    }

    @IsTest
    static void testMergeFamilyTypes() {
        ERPMessageParser.ErpToSfMessage_FamilyType mockParsedMessage = createMockERPMessage('MERGE');

        Test.startTest();
        ERPMessageHandlerFamilyType.MessageProcessingResult result = ERPMessageHandlerFamilyType.processMessage(mockParsedMessage);
        Test.stopTest();

        List<FamiliesTypes__c> upsertedFamilyTypes = [SELECT Id FROM FamiliesTypes__c];

        Assert.areEqual(10, upsertedFamilyTypes.size(), 'There should be 10 records - оne Family Type should be deleted');
    }

    @IsTest
    static void testModifyFamilyTypes() {
        ERPMessageParser.ErpToSfMessage_FamilyType mockParsedMessage = createMockERPMessage('MODIFY');

        Test.startTest();
        ERPMessageHandlerFamilyType.MessageProcessingResult result = ERPMessageHandlerFamilyType.processMessage(mockParsedMessage);
        Test.stopTest();

        List<FamiliesTypes__c> upsertedFamilyTypes = [SELECT Id FROM FamiliesTypes__c];

        Assert.areEqual(11, upsertedFamilyTypes.size(), 'There should be 11 records');
    }

    @IsTest
    static void testDeleteFamilyTypes() {
        ERPMessageParser.ErpToSfMessage_FamilyType mockParsedMessage = createMockERPMessage('DELETE');

        Test.startTest();
        ERPMessageHandlerFamilyType.MessageProcessingResult result = ERPMessageHandlerFamilyType.processMessage(mockParsedMessage);
        Test.stopTest();

        List<FamiliesTypes__c> upsertedFamilyTypes = [SELECT Id FROM FamiliesTypes__c];

        Assert.areEqual(1, upsertedFamilyTypes.size(), 'There should be 1 record');
    }

    @IsTest
    static void testUnsupportedMode() {
        ERPMessageParser.ErpToSfMessage_FamilyType mockParsedMessage = createMockERPMessage('Insert');

        Test.startTest();
        ERPMessageHandlerFamilyType.MessageProcessingResult result = ERPMessageHandlerFamilyType.processMessage(mockParsedMessage);
        Test.stopTest();

        Assert.isTrue(result.error.contains('Unsupported mode'), 'Result should not be null');
    }

    @isTest static void testGenerateResponseBody() {
        Map<Integer, String> statusCodesMap = new Map<Integer, String>{
            200 => 'OK',
            400 => 'Bad Request'
        };
        ERPMessageHandlerFamilyType.MessageProcessingResult mpRes = new ERPMessageHandlerFamilyType.MessageProcessingResult();
        mpRes.MessageType = 'ERP-SF_FamilyTypes';

        Blob responseBody = ERPMessageHandlerFamilyType.generateResponseBody(statusCodesMap, 200, null, mpRes);
        String responseString = responseBody.toString();
        Assert.isTrue(responseString.contains('ERP-SF_FamilyTypes'), 'Response should contain the processed message type.');

        Blob errorResponseBody = ERPMessageHandlerFamilyType.generateResponseBody(statusCodesMap, 400, 'An error occurred', mpRes);
        String errorResponseString = errorResponseBody.toString();
        Assert.isTrue(errorResponseString.contains('An error occurred'), 'Response should contain the error message.');
    }

    private static ERPMessageParser.ErpToSfMessage_FamilyType createMockERPMessage(String mode) {
        ERPMessageParser.ErpToSfMessage_FamilyType mockMessage = new ERPMessageParser.ErpToSfMessage_FamilyType();

        // Mock Metadata
        mockMessage.Metadata = new ERPMessageParser.MessageMetadata();
        mockMessage.Metadata.MsgType = 'TestType';

        // Mock FamilyTypeMessageData
        ERPMessageParser.FamilyTypeMessageData FamilyTypeData = new ERPMessageParser.FamilyTypeMessageData();
        FamilyTypeData.Mode = mode;

        //Mock Names
        ERPMessageParser.NameObject itemName = new ERPMessageParser.NameObject();
        itemName.DefaultName = 'Тестова Назва';
        itemName.En = 'Test Name';
        itemName.Ru = 'Тестовое Название';

        // Mock Items
        List<ERPMessageParser.FamilyTypeItem> ItemList = new List<ERPMessageParser.FamilyTypeItem>();
        for(Integer i = 1; i < 11; i++) {
            ERPMessageParser.FamilyTypeItem item = new ERPMessageParser.FamilyTypeItem();
            item.FamilyTypeId = i;
            item.IsActive = true;
            item.Name = itemName;
            item.NameS = itemName;
            ItemList.add(Item);
        }

        FamilyTypeData.Items = ItemList;
        mockMessage.data = FamilyTypeData;

        return mockMessage;
    }
}