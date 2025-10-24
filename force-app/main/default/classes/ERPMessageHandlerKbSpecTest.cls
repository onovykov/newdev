@isTest
public class ERPMessageHandlerKbSpecTest {
    private static final Integer SPEC_ID = 123;
    private static final String PRODUCT_ID = 'P1';
    private static final String PRODUCT_KIND_ID = 'PK1';
    private static final String CLIENT_ID = '1111';
    private static final String ASSEMBLY_ID = 'WA1';
    private static final String CERTIFICATE1_ID = 'QC1';
    private static final String CERTIFICATE2_ID = 'QC2';

    @testSetup
    static void setupTestData() {
        insert new ProdKind__c(ID_ERP__c = PRODUCT_KIND_ID, Name = 'Product Kind 1');
        insert new WheelProdType__c(ID_ERP__c = PRODUCT_ID, Name = 'Product Type 1');
        insert new Account(ID_ERP__c = CLIENT_ID, Name = 'Test Client');
        insert new WheelAssembly__c(ID_ERP__c = ASSEMBLY_ID, Name = 'Assembly 1');

        QualityCertificates__c certificate1 = new QualityCertificates__c(ID_ERP__c = CERTIFICATE1_ID, Name = 'Certificate 1');
        QualityCertificates__c certificate2 = new QualityCertificates__c(ID_ERP__c = CERTIFICATE2_ID, Name = 'Certificate 2');
        insert new List<QualityCertificates__c>{certificate1, certificate2};
        SpecVersion__c specVersion = new SpecVersion__c(ID_ERP__c = String.valueOf(SPEC_ID), Name = 'Spec Version');
        insert specVersion;

        insert new Specification_Version_to_Certificate__c(Certificate__c = certificate1.Id, Specification_Version__c = specVersion.Id);
    }

    @isTest
    static void testProcessMessage_Success() {
        ERPMessageParser.ErpToSfMessage_KbSpec mockMessage = createMockMessage();

        Test.startTest();
        ERPMessageHandlerKbSpec.MessageProcessingResult result = ERPMessageHandlerKbSpec.processMessage(mockMessage);
        Test.stopTest();

        System.assertEquals('SomeMessageType', result.MessageType, 'Message type should match');
        System.assertEquals(null, result.error, 'No error should occur');

        List<DrawingBase__c> drawingBases = [SELECT ID_ERP__c, Name, ProductKind__r.ID_ERP__c, Product__r.ID_ERP__c FROM DrawingBase__c];
        System.assertEquals(1, drawingBases.size(), 'One DrawingBase record should be created.');
        System.assertEquals(PRODUCT_ID, drawingBases.get(0).Product__r.ID_ERP__c, 'Product__c should be set correctly.');
        System.assertEquals(PRODUCT_KIND_ID, drawingBases.get(0).ProductKind__r.ID_ERP__c, 'ProductKind__c should be set correctly.');

        List<DrawingVersion__c> drawingVersions = [SELECT ID_ERP__c, Name FROM DrawingVersion__c];
        System.assertEquals(1, drawingVersions.size(), 'One DrawingVersion record should be created.');

        List<SpecificationBase__c> specBases = [SELECT ID_ERP__c, Name, Account__r.ID_ERP__c FROM SpecificationBase__c];
        System.assertEquals(1, specBases.size(), 'One SpecificationBase record should be created.');
        System.assertEquals(CLIENT_ID, specBases.get(0).Account__r.ID_ERP__c, 'Account__c should be set correctly.');

        List<SpecVersion__c> specVersions = [SELECT ID_ERP__c, Name FROM SpecVersion__c];
        System.assertEquals(1, specVersions.size(), 'Additional SpecVersion record should not be created.');

        List<Specification_Version_to_Assembly__c> assemblies = [SELECT Assembly__r.ID_ERP__c FROM Specification_Version_to_Assembly__c];
        System.assertEquals(1, assemblies.size(), 'One Specification_Version_to_Assembly record should be created.');
        System.assertEquals(ASSEMBLY_ID, assemblies.get(0).Assembly__r.ID_ERP__c, 'Assembly__c should be set correctly.');

        List<Specification_Version_to_Certificate__c> certificates = [SELECT Certificate__r.ID_ERP__c FROM Specification_Version_to_Certificate__c];
        System.assertEquals(2, certificates.size(), 'Additional Specification_Version_to_Certificate record should be created.');
    }

    @isTest
    static void testProcessMessage_Error() {
        ERPMessageParser.ErpToSfMessage_KbSpec mockMessage = createMockMessage();

        Test.startTest();
        ERPMessageHandlerKbSpec.MessageProcessingResult result = ERPMessageHandlerKbSpec.processMessage(mockMessage);
        Test.stopTest();

        System.assertEquals('SomeMessageType', result.MessageType, 'Message type should match');
        System.assertEquals(null, result.error, 'No error should occur');
    }

    @isTest 
    static void testGenerateResponseBody() {
        Map<Integer, String> statusCodesMap = new Map<Integer, String>{
            200 => 'OK',
            400 => 'Bad Request'
        };
        ERPMessageHandlerKbSpec.MessageProcessingResult mpRes = new ERPMessageHandlerKbSpec.MessageProcessingResult();
        mpRes.MessageType = 'ERP-SF_KBSPEC_WHEEL';

        Blob responseBody = ERPMessageHandlerKbSpec.generateResponseBody(statusCodesMap, 200, null, mpRes);
        String responseString = responseBody.toString();
        Assert.isTrue(responseString.contains('ERP-SF_KBSPEC_WHEEL'), 'Response should contain the processed message type.');

        Blob errorResponseBody = ERPMessageHandlerKbSpec.generateResponseBody(statusCodesMap, 400, 'An error occurred', mpRes);
        String errorResponseString = errorResponseBody.toString();
        Assert.isTrue(errorResponseString.contains('An error occurred'), 'Response should contain the error message.');
    }

    private static ERPMessageParser.ErpToSfMessage_KbSpec createMockMessage() {
        ERPMessageParser.ErpToSfMessage_KbSpec message = new ERPMessageParser.ErpToSfMessage_KbSpec();
        message.metadata = new ERPMessageParser.MessageMetadata();
        message.metadata.MsgType = 'SomeMessageType';

        message.data = new ERPMessageParser.SpecMessageData();
        message.data.Items = new List<ERPMessageParser.ERPObject_SpecItem>();

        ERPMessageParser.ERPObject_SpecItem item = new ERPMessageParser.ERPObject_SpecItem();
        item.Id = SPEC_ID;
        item.Client = new ERPMessageParser.ERPObject_Client();
        item.Client.Id = CLIENT_ID;
        item.IsActive = true;
        item.DrawingVersion = new ERPMessageParser.ERPObject_DrawingVersion();
        item.DrawingVersion.IsActive = true;
        item.DrawingVersion.Id = 456;
        item.DrawingVersion.DrawingId = 789;
        item.DrawingVersion.Product = new ERPMessageParser.ERPObject_Product();
        item.DrawingVersion.Product.ProductType = new ERPMessageParser.ERPObject_BaseObject();
        item.DrawingVersion.Product.Id = PRODUCT_ID;
        item.DrawingVersion.Product.ProductType.Id = PRODUCT_KIND_ID;
        
        ERPMessageParser.ERPObject_BaseObject assembly = new ERPMessageParser.ERPObject_BaseObject();
        assembly.Id = ASSEMBLY_ID;
        item.Assembly = new List<ERPMessageParser.ERPObject_BaseObject>{ assembly };

        
        ERPMessageParser.ERPObject_BaseObject certificate1 = new ERPMessageParser.ERPObject_BaseObject();
        certificate1.Id = CERTIFICATE1_ID;
        ERPMessageParser.ERPObject_BaseObject certificate2 = new ERPMessageParser.ERPObject_BaseObject();
        certificate2.Id = CERTIFICATE2_ID;
        item.QualityCertificates = new List<ERPMessageParser.ERPObject_BaseObject>{ certificate1, certificate2};
        message.data.Items.add(item);

        return message;
    }
}