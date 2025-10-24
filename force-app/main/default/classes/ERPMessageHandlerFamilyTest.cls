@IsTest
public class ERPMessageHandlerFamilyTest {

    @TestSetup
    static void makeDate() {
        FamiliesTypes__c familyType = new FamiliesTypes__c(Name = 'Family Type Name', ID_ERP__c = '1');
        insert familyType;

        Family__c family1 = new Family__c(Name = 'Family Name', ID_ERP__c = 1);
        Family__c family20 = new Family__c(Name = 'Family Name', ID_ERP__c = 20);
        insert new List<Family__c>{family1, family20};

        ItemNames__c itemName = new ItemNames__c(ItemId__c = family1.Id, Language__c = 'EN', ItemNameInLng__c = 'Test Name');
        insert itemName;
    }

    @IsTest
    static void testMergeFamilies() {
        ERPMessageParser.ErpToSfMessage_Family mockParsedMessage = createMockERPMessage('MERGE');

        Test.startTest();
        ERPMessageHandlerFamily.MessageProcessingResult result = ERPMessageHandlerFamily.processMessage(mockParsedMessage);
        Test.stopTest();

        List<Family__c> upsertedFamilies = [SELECT Id FROM Family__c];

        Assert.areEqual(10, upsertedFamilies.size(), 'There should be 10 records - оne family should be deleted');
    }

    @IsTest
    static void testModifyFamilies() {
        ERPMessageParser.ErpToSfMessage_Family mockParsedMessage = createMockERPMessage('MODIFY');

        Test.startTest();
        ERPMessageHandlerFamily.MessageProcessingResult result = ERPMessageHandlerFamily.processMessage(mockParsedMessage);
        Test.stopTest();

        List<Family__c> upsertedFamilies = [SELECT Id FROM Family__c];

        Assert.areEqual(11, upsertedFamilies.size(), 'There should be 11 records');
    }

    @IsTest
    static void testDeleteFamilies() {
        ERPMessageParser.ErpToSfMessage_Family mockParsedMessage = createMockERPMessage('DELETE');

        Test.startTest();
        ERPMessageHandlerFamily.MessageProcessingResult result = ERPMessageHandlerFamily.processMessage(mockParsedMessage);
        Test.stopTest();

        List<Family__c> upsertedFamilies = [SELECT Id FROM Family__c];

        Assert.areEqual(1, upsertedFamilies.size(), 'There should be 1 record');
    }

    @IsTest
    static void testUnsupportedMode() {
        ERPMessageParser.ErpToSfMessage_Family mockParsedMessage = createMockERPMessage('Insert');

        Test.startTest();
        ERPMessageHandlerFamily.MessageProcessingResult result = ERPMessageHandlerFamily.processMessage(mockParsedMessage);
        Test.stopTest();

        Assert.isTrue(result.error.contains('Unsupported mode'), 'Result should not be null');
    }

    @isTest static void testGenerateResponseBody() {
        Map<Integer, String> statusCodesMap = new Map<Integer, String>{
            200 => 'OK',
            400 => 'Bad Request'
        };
        ERPMessageHandlerFamily.MessageProcessingResult mpRes = new ERPMessageHandlerFamily.MessageProcessingResult();
        mpRes.MessageType = 'ERP-SF_Family';

        Blob responseBody = ERPMessageHandlerFamily.generateResponseBody(statusCodesMap, 200, null, mpRes);
        String responseString = responseBody.toString();
        Assert.isTrue(responseString.contains('ERP-SF_Family'), 'Response should contain the processed message type.');

        Blob errorResponseBody = ERPMessageHandlerFamily.generateResponseBody(statusCodesMap, 400, 'An error occurred', mpRes);
        String errorResponseString = errorResponseBody.toString();
        Assert.isTrue(errorResponseString.contains('An error occurred'), 'Response should contain the error message.');
    }

    private static ERPMessageParser.ErpToSfMessage_Family createMockERPMessage(String mode) {
        ERPMessageParser.ErpToSfMessage_Family mockMessage = new ERPMessageParser.ErpToSfMessage_Family();

        // Mock Metadata
        mockMessage.Metadata = new ERPMessageParser.MessageMetadata();
        mockMessage.Metadata.MsgType = 'TestType';

        // Mock FamilyMessageData
        ERPMessageParser.FamilyMessageData FamilyData = new ERPMessageParser.FamilyMessageData();
        FamilyData.Mode = mode;

        //Mock Names
        ERPMessageParser.NameObject itemName = new ERPMessageParser.NameObject();
        itemName.DefaultName = 'Тестовое Название';
        itemName.En = 'Test Name';
        itemName.Uk = 'Тестова Назва';

        ERPMessageParser.FamilyTypeItem familyType = new ERPMessageParser.FamilyTypeItem();
        familyType.FamilyTypeId = 1;
        familyType.IsActive = true;
        familyType.Name = itemName;
        familyType.NameS = itemName;

        // Mock Items
        List<ERPMessageParser.FamilyItem> ItemList = new List<ERPMessageParser.FamilyItem>();
        for(Integer i = 1; i < 11; i++) {
            ERPMessageParser.FamilyItem item = new ERPMessageParser.FamilyItem();
            item.FamilyId = i;
            item.IsActive = true;
            item.Name = itemName;
            item.NameS = itemName;
            item.FamilyType = familyType;
            ItemList.add(Item);
        }

        FamilyData.Items = ItemList;
        mockMessage.data = FamilyData;

        return mockMessage;
    }
}