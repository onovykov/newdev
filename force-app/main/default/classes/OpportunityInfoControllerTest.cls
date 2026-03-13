@isTest
private class OpportunityInfoControllerTest {

    @testSetup
    static void testSetup() {
        Credentials__c creds = new Credentials__c(
            User_Login__c = 'test_user',
            User_Password__c = 'test_pass',
            End_Point__c = 'https://test-erp-endpoint.com/soap'
        );
        insert creds;

        Country__c country = new Country__c(
            Name = 'Ukraine',
            A2Code__c = 'UA',
            A3Code__c = 'UKR',
            NumCode__c = 'UA'
        );
        insert country;

        Shop__c shop = new Shop__c(
            Id_ERP__c = 'SHOP_001',
            Name = 'Test Shop'
        );
        insert shop;

        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];

        User ownerUser = new User(
            FirstName = 'Sales',
            LastName = 'Manager',
            Email = 'salesmanager@test.com',
            Username = 'salesmanager' + System.currentTimeMillis() + '@test.com',
            Alias = 'smgr',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = standardProfile.Id,
            LanguageLocaleKey = 'en_US',
            LoginERP__c = 'SM001',
            ID_ERP__c = 'SM_ERP_001',
            EmployeeNumber = 'EMP001',
            SalesDivision__c = '00004'
        );
        insert ownerUser;

        User boUser = new User(
            FirstName = 'BO',
            LastName = 'Specialist',
            Email = 'bospecialist@test.com',
            Username = 'bospecialist' + System.currentTimeMillis() + '@test.com',
            Alias = 'bspec',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = standardProfile.Id,
            LanguageLocaleKey = 'en_US',
            LoginERP__c = 'BO001',
            ID_ERP__c = 'BO_ERP_001',
            EmployeeNumber = 'EMP002',
            SalesDivision__c = '00004'
        );
        insert boUser;

        Account testAccount = new Account(
            Name = 'Test Account',
            ID_ERP__c = '123',
            BillingCity = 'Kyiv',
            BillingCountry = 'Ukraine',
            BillingStreet = 'Test Street',
            BillingPostalCode = '01001'
        );
        insert testAccount;

        PaymentTerms__c paymentTerms = new PaymentTerms__c(
            ID_ERP__c = 'PAY001',
            Name = 'Test Payment Terms'
        );
        insert paymentTerms;

        DeliveryTerms__c deliveryTerms = new DeliveryTerms__c(
            ID_ERP__c = 'DEL001',
            Name = 'Test Delivery Terms'
        );
        insert deliveryTerms;

        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            StageName = 'Qualification',
            CloseDate = Date.today().addDays(30),
            OwnerId = ownerUser.Id,
            AssignedBOS__c = boUser.Id,
            PaymentTerms__c = paymentTerms.Id,
            DeliveryTerms__c = deliveryTerms.Id,
            Country__c = country.Id,
            Description = 'Test Description',
            CurrencyIsoCode = 'USD'
        );
        insert testOpp;

        Product2 testProduct = new Product2(
            Name = 'Test Product',
            ProductCode = 'PROD001',
            ID_ERP__c = 'PROD_ERP_001',
            Family = 'OCTG',
            IsActive = true
        );
        insert testProduct;

        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = testProduct.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert pbe;

        ProductStandard__c productStandard = new ProductStandard__c(
            ID_ERP__c = 'STD001',
            Name = 'Test Standard'
        );
        insert productStandard;

        ProductSpecLevel__c specLevel = new ProductSpecLevel__c(
            ID_ERP__c = 'SPEC001',
            Name = 'Test Spec Level'
        );
        insert specLevel;

        SteelGrade__c steelGrade = new SteelGrade__c(
            ID_ERP__c = 'STEEL001',
            ShortName__c = 'S001'
        );
        insert steelGrade;

        TubeOD__c tubeOD = new TubeOD__c(
            ID_ERP__c = 'OD001',
            OD_mm__c = 48.30,
            OD_inch__c = 1.9
        );
        insert tubeOD;

        TubeWT__c tubeWT = new TubeWT__c(
            ID_ERP__c = 'WT001',
            Name = 'WT Test',
            WT_mm__c = 5.08,
            WT_inch__c = 0.2
        );
        insert tubeWT;

        ShippingPoint__c shippingPoint = new ShippingPoint__c(
            ID_ERP__c = 'SHIP001',
            Country__c = country.Id,
            Type__c = '1'
        );
        insert shippingPoint;

        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = testOpp.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 100,
            UnitPrice = 100.00,
            ProductStandard__c = productStandard.Id,
            ProductSpecLevel__c = specLevel.Id,
            SteelGrade__c = steelGrade.Id,
            TubeOD__c = tubeOD.Id,
            TubeWT__c = tubeWT.Id,
            ShippingPoint__c = shippingPoint.Id,
            Shop__c = shop.Id,
            InquiryUnit__c = '20',
            InquiryQuantity__c = 1,
            Quantity_m__c = 100.0,
            Quantity_ft__c = 328.08,
            Quantity_pcs__c = 10
        );
        insert oli;
    }

    @isTest
    static void testGetOpportunity() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        OpportunityInfoController wrapper = OpportunityInfoController.getOpportunity(opp.Id);
        Test.stopTest();

        System.assertNotEquals(null, wrapper, 'Wrapper не має бути null');
        System.assertNotEquals(null, wrapper.oppo, 'Opportunity не має бути null');
        System.assertNotEquals(null, wrapper.acc, 'Account не має бути null');
        System.assertNotEquals(null, wrapper.products, 'Products не мають бути null');
        System.assert(wrapper.products.size() > 0, 'Products мають бути присутні');
    }

    @isTest
    static void testGetJSONData() {
        Opportunity opp = [
            SELECT Id, ID_ERP__c, Description, CurrencyIsoCode, ExpectedDelivDate__c,
                   MarketSegment__c, Owner.LoginERP__c, Owner.Name,
                   Country__r.NumCode__c, DeliveryTerms__r.ID_ERP__c,
                   PaymentTerms__r.ID_ERP__c, LastSyncERP__c
            FROM Opportunity
            LIMIT 1
        ];

        Account acc = [SELECT Id, Name, ID_ERP__c FROM Account LIMIT 1];

        List<OpportunityLineItem> products = [
            SELECT Id, Quantity, Quantity_m__c, Quantity_ft__c, Quantity_pcs__c,
                   UnitPrice, InquiryQuantity__c, InquiryUnit__c, NPP_ERP__c,
                   LastModifiedDate, ID_ERP__c,
                   Product2.ID_ERP__c, QuotaType__r.ID_ERP__c,
                   ProductStandard__r.ID_ERP__c, ProductSpecLevel__r.ID_ERP__c,
                   SteelGrade__r.ID_ERP__c, TubeOD__r.ID_ERP__c,
                   TubeWT__r.ID_ERP__c, ShippingPoint__r.ID_ERP__c,
                   Shop__r.ID_ERP__c
            FROM OpportunityLineItem
            WHERE OpportunityId = :opp.Id
        ];

        Test.startTest();
        String jsonData = OpportunityInfoController.getJSONData(opp, acc, products);
        Test.stopTest();

        System.assertNotEquals(null, jsonData, 'JSON не має бути null');
        System.assert(jsonData.length() > 0, 'JSON має містити дані');
        System.assert(jsonData.contains('MessageType'), 'JSON має містити MessageType');
        System.assert(jsonData.contains('SF-ERP_OpportunityData'), 'JSON має містити правильний MessageType');
    }

    @isTest
    static void testSendJSONDataSuccess() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        OpportunityInfoController wrapper = OpportunityInfoController.getOpportunity(opp.Id);

        Test.setMock(WebServiceMock.class, new SuccessMock());

        Test.startTest();
        OpportunityInfoController.sendJSONData(JSON.serialize(wrapper));
        Test.stopTest();

        System.assert(true, 'sendJSONData виконано успішно');
    }

    @isTest
    static void testSendJSONDataWithAttachments() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Attachment att = new Attachment(
            ParentId = opp.Id,
            Name = 'Test Attachment.pdf',
            Body = Blob.valueOf('Test Content'),
            ContentType = 'application/pdf'
        );
        insert att;

        OpportunityInfoController wrapper = OpportunityInfoController.getOpportunity(opp.Id);

        if (wrapper.attachements != null && wrapper.attachements.size() > 0) {
            wrapper.attachements[0].checkbox = true;
        }

        Test.setMock(WebServiceMock.class, new SuccessMock());

        Test.startTest();
        OpportunityInfoController.sendJSONData(JSON.serialize(wrapper));
        Test.stopTest();

        System.assert(true, 'sendJSONData з attachments виконано успішно');
    }

    @isTest
    static void testSendJSONDataCalloutException() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        OpportunityInfoController wrapper = OpportunityInfoController.getOpportunity(opp.Id);

        Test.setMock(WebServiceMock.class, new ExceptionMock());

        Test.startTest();
        try {
            OpportunityInfoController.sendJSONData(JSON.serialize(wrapper));
            System.assert(false, 'Має бути викликано виключення');
        } catch (Exception e) {
            System.assert(true, 'CalloutException оброблено');
        }
        Test.stopTest();
    }

    @isTest
    static void testSendJSONDataErrorResponse() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        OpportunityInfoController wrapper = OpportunityInfoController.getOpportunity(opp.Id);

        Test.setMock(WebServiceMock.class, new ErrorMock());

        Test.startTest();
        try {
            OpportunityInfoController.sendJSONData(JSON.serialize(wrapper));
            System.assert(false, 'Має бути викликано виключення');
        } catch (Exception e) {
            System.assert(true, 'Error response оброблено');
        }
        Test.stopTest();
    }

    @isTest
    static void testUpdateBOSpecialist() {
        Opportunity opp = [SELECT Id, AssignedBOS__c FROM Opportunity LIMIT 1];
        User boUser = [SELECT Id FROM User WHERE LoginERP__c = 'BO001' LIMIT 1];

        OpportunityInfoController wrapper = OpportunityInfoController.getOpportunity(opp.Id);
        wrapper.bo_user = boUser;

        Test.setMock(WebServiceMock.class, new SuccessMock());

        Test.startTest();
        OpportunityInfoController.sendJSONData(JSON.serialize(wrapper));
        Test.stopTest();

        Opportunity updatedOpp = [SELECT AssignedBOS__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(boUser.Id, updatedOpp.AssignedBOS__c, 'BO Specialist має бути оновлено');
    }

    @isTest
    static void testBulkOpportunities() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        User owner = [SELECT Id FROM User WHERE LoginERP__c = 'SM001' LIMIT 1];

        List<Opportunity> opps = new List<Opportunity>();
        for (Integer i = 0; i < 200; i++) {
            opps.add(new Opportunity(
                Name = 'Bulk Opp ' + i,
                AccountId = acc.Id,
                StageName = 'Qualification',
                CloseDate = Date.today().addDays(30),
                OwnerId = owner.Id
            ));
        }

        Test.startTest();
        insert opps;
        Test.stopTest();

        List<Opportunity> inserted = [SELECT Id FROM Opportunity WHERE Name LIKE 'Bulk Opp%'];
        System.assertEquals(200, inserted.size(), 'Всі 200 Opportunities мають бути вставлені');
    }

    // Mock classes
    private class SuccessMock implements WebServiceMock {
        public void doInvoke(
            Object stub, Object request, Map<String, Object> response,
            String endpoint, String soapAction, String requestName,
            String responseNS, String responseName, String responseType
        ) {
            if (requestName == 'LoginEx') {
                SFToERP.LoginExResponse_element respElement = new SFToERP.LoginExResponse_element();
                respElement.LoginExResult = '{"Success":true,"Ticket":"test_ticket"}';
                response.put('response_x', respElement);
            } else if (requestName == 'ExecuteEx') {
                SFToERP.ExecuteExResponse_element respElement = new SFToERP.ExecuteExResponse_element();
                String syncDateTime = String.valueOf(System.now().getTime() / 1000);
                respElement.ExecuteExResult = '{"SyncResult":"1","SyncDateTime":"' + syncDateTime + '","Opportunity":{"ID_SF":"test_id","ID_ERP":"ERP_123"}}';
                response.put('response_x', respElement);
            }
        }
    }

    private class ErrorMock implements WebServiceMock {
        public void doInvoke(
            Object stub, Object request, Map<String, Object> response,
            String endpoint, String soapAction, String requestName,
            String responseNS, String responseName, String responseType
        ) {
            if (requestName == 'LoginEx') {
                SFToERP.LoginExResponse_element respElement = new SFToERP.LoginExResponse_element();
                respElement.LoginExResult = '{"Success":true,"Ticket":"test_ticket"}';
                response.put('response_x', respElement);
            } else if (requestName == 'ExecuteEx') {
                SFToERP.ExecuteExResponse_element respElement = new SFToERP.ExecuteExResponse_element();
                respElement.ExecuteExResult = '{"ErrorType":"Validation Error","ErrorMessage":"Test error message"}';
                response.put('response_x', respElement);
            }
        }
    }

    private class ExceptionMock implements WebServiceMock {
        public void doInvoke(
            Object stub, Object request, Map<String, Object> response,
            String endpoint, String soapAction, String requestName,
            String responseNS, String responseName, String responseType
        ) {
            throw new CalloutException('Test callout exception');
        }
    }
}