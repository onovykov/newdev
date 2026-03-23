@IsTest
private class OpportunityTriggerHandlerTest {

    private static final String SALES_DIVISION_A = '00001';
    private static final String SALES_DIVISION_B = '00004';
	private static final String BUSINESS_DIVISION = 'Pipes';

    @TestSetup
    static void setupData() {
        Account acc = new Account(
            Name = 'Test Account',
            ID_ERP__c = 'ACC-ERP-001'
        );
        insert acc;
    }

	private static User createUser(String uniqueKey, String salesDivision) {
		Profile p = [
			SELECT Id
			FROM Profile
			WHERE Name = 'System Administrator'
			LIMIT 1
		];

		String cleanKey = uniqueKey.replaceAll('[^A-Za-z0-9]', '');
		if (String.isBlank(cleanKey)) {
			cleanKey = 'USR';
		}
		if (cleanKey.length() > 6) {
			cleanKey = cleanKey.substring(0, 6);
		}

		User u = new User(
			FirstName = 'Test',
			LastName = 'User ' + cleanKey,
			Alias = ('u' + cleanKey).left(8),
			Email = 'test.' + cleanKey + '@example.com',
			Username = 'test.' + cleanKey + '.' + System.currentTimeMillis() + '@example.com',
			TimeZoneSidKey = 'Europe/Kiev',
			LocaleSidKey = 'en_US',
			EmailEncodingKey = 'UTF-8',
			LanguageLocaleKey = 'en_US',
			ProfileId = p.Id,
			BusinesDivision__c = BUSINESS_DIVISION,
			SalesDivision__c = salesDivision,
			ID_ERP__c = 'ERP' + cleanKey,
			EmployeeNumber = 'EMP' + cleanKey,
			LoginERP__c = 'LGN' + cleanKey
		);
		insert u;
		return u;
	}

    private static Account getAccount() {
        return [
            SELECT Id, Name
            FROM Account
            LIMIT 1
        ];
    }

    private static Opportunity createOpportunity(Id accountId, Id ownerId) {
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = accountId,
            OwnerId = ownerId,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert opp;
        return opp;
    }

    private static Product2 createProduct() {
        Product2 p = new Product2(
            Name = 'Test Product',
            IsActive = true,
            ID_ERP__c = 'PROD-ERP-001',
            Type__c = 'Tube'
        );
        insert p;
        return p;
    }

    private static PricebookEntry createStandardPbe(Id productId) {
        Id standardPbId = Test.getStandardPricebookId();

        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = standardPbId,
            Product2Id = productId,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;
        return pbe;
    }

    private static Opportunity createOpportunityWithOLI(Id accountId, Id ownerId, Boolean withErpOnOli) {
        Product2 prod = createProduct();
        PricebookEntry pbe = createStandardPbe(prod.Id);

        Opportunity opp = new Opportunity(
            Name = 'Opportunity With OLI',
            AccountId = accountId,
            OwnerId = ownerId,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert opp;

        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 100,
            ServiceDate = Date.today().addDays(10),
            ID_ERP__c = withErpOnOli ? 'OLI-ERP-001' : null
        );
        insert oli;

        return opp;
    }

    private static Quote createQuote(Id opportunityId, Boolean createdFromOpa) {
        Quote q = new Quote(
            Name = 'Test Quote',
            OpportunityId = opportunityId,
            Pricebook2Id = Test.getStandardPricebookId(),
            Created_From_OPA_process__c = createdFromOpa
        );
        insert q;
        return q;
    }

    @IsTest
    static void testBeforeInsert_setsStandardFields() {
        User owner = createUser('ownerA', SALES_DIVISION_A);
        Account acc = getAccount();

        Opportunity opp = new Opportunity(
            Name = 'Insert Test Opp',
            AccountId = acc.Id,
            OwnerId = owner.Id,
            CloseDate = Date.today().addDays(10)
        );

        Test.startTest();
        insert opp;
        Test.stopTest();

        Opportunity insertedOpp = [
            SELECT Id, StageName, Pricebook2Id, MarketSegment__c, Owner__c
            FROM Opportunity
            WHERE Id = :opp.Id
        ];

        System.assertEquals('Qualification', insertedOpp.StageName);
        System.assertEquals(Test.getStandardPricebookId(), insertedOpp.Pricebook2Id);
        System.assertEquals(owner.Id, insertedOpp.Owner__c);
        System.assertEquals(SALES_DIVISION_A, insertedOpp.MarketSegment__c);
    }

    @IsTest
    static void testBeforeUpdate_ownerChange_updatesDerivedFields() {
        User ownerA = createUser('ownerB1', SALES_DIVISION_A);
        User ownerB = createUser('ownerB2', SALES_DIVISION_B);
        Account acc = getAccount();

        Opportunity opp = createOpportunity(acc.Id, ownerA.Id);

        Test.startTest();
        opp.OwnerId = ownerB.Id;
        update opp;
        Test.stopTest();

        Opportunity updatedOpp = [
            SELECT Id, OwnerId, Owner__c, MarketSegment__c
            FROM Opportunity
            WHERE Id = :opp.Id
        ];

        System.assertEquals(ownerB.Id, updatedOpp.OwnerId);
        System.assertEquals(ownerB.Id, updatedOpp.Owner__c);
        System.assertEquals(SALES_DIVISION_B, updatedOpp.MarketSegment__c);
    }

    @IsTest
    static void testBeforeUpdate_closedWonWithMissingOliErp_throwsError() {
        User owner = createUser('ownerC', SALES_DIVISION_A);
        Account acc = getAccount();

        Opportunity opp = createOpportunityWithOLI(acc.Id, owner.Id, false);

        Test.startTest();
        Database.SaveResult sr = Database.update(new Opportunity(
            Id = opp.Id,
            StageName = 'Closed Won'
        ), false);
        Test.stopTest();

        System.assertEquals(false, sr.isSuccess());
        System.assert(
            sr.getErrors()[0].getMessage().contains('ID in ERP'),
            'Expected validation error about missing Opportunity Product ERP Id'
        );
    }

    @IsTest
    static void testBeforeUpdate_closedWonWithValidOliErp_allowsUpdate() {
        User owner = createUser('ownerD', SALES_DIVISION_A);
        Account acc = getAccount();

        Opportunity opp = createOpportunityWithOLI(acc.Id, owner.Id, true);

        Test.startTest();
        opp.StageName = 'Closed Won';
        update opp;
        Test.stopTest();

        Opportunity updatedOpp = [
            SELECT Id, StageName
            FROM Opportunity
            WHERE Id = :opp.Id
        ];

        System.assertEquals('Closed Won', updatedOpp.StageName);
    }

    @IsTest
    static void testAfterUpdate_stageChangeWithErp_dispatchesAsyncFlow() {
        OpportunityStageSyncContext.reset();
        OpportunityStageSyncContext.allowDispatchInTest = true;

        User owner = createUser('ownerE', SALES_DIVISION_A);
        Account acc = getAccount();

        Opportunity opp = createOpportunity(acc.Id, owner.Id);

        opp.ID_ERP__c = 'OPP-ERP-001';

        Test.startTest();
        update opp;

        opp.StageName = 'Closed Won';
        update opp;
        Test.stopTest();

        System.assert(
            OpportunityStageSyncContext.queuedOpportunityIds.contains(opp.Id),
            'Opportunity Id must be collected for async sync dispatch'
        );

        OpportunityStageSyncContext.reset();
    }

    @IsTest
    static void testAfterUpdate_erpFilledLater_dispatchesAsyncFlow() {
        OpportunityStageSyncContext.reset();
        OpportunityStageSyncContext.allowDispatchInTest = true;

        User owner = createUser('ownerF', SALES_DIVISION_A);
        Account acc = getAccount();

        Opportunity opp = createOpportunity(acc.Id, owner.Id);

        Test.startTest();
        opp.ID_ERP__c = 'OPP-ERP-LATE';
        update opp;
        Test.stopTest();

        System.assert(
            OpportunityStageSyncContext.queuedOpportunityIds.contains(opp.Id),
            'Opportunity Id must be queued when ID_ERP__c becomes populated'
        );

        OpportunityStageSyncContext.reset();
    }

    @IsTest
    static void testAfterUpdate_probabilityChangeWithNormalQuote_doesNotFail() {
        OpportunityStageSyncContext.reset();
        OpportunityStageSyncContext.allowDispatchInTest = true;

        User owner = createUser('ownerG', SALES_DIVISION_A);
        Account acc = getAccount();

        Opportunity opp = createOpportunity(acc.Id, owner.Id);
        createQuote(opp.Id, false);

        Test.startTest();
        opp.Probability = 55;
        update opp;
        Test.stopTest();

        Opportunity updatedOpp = [
            SELECT Id, Probability
            FROM Opportunity
            WHERE Id = :opp.Id
        ];

        System.assertEquals(55, updatedOpp.Probability);

        OpportunityStageSyncContext.reset();
    }

    @IsTest
    static void testAfterUpdate_probabilityChangeWithOpaQuote_doesNotFail() {
        OpportunityStageSyncContext.reset();
        OpportunityStageSyncContext.allowDispatchInTest = true;

        User owner = createUser('ownerH', SALES_DIVISION_A);
        Account acc = getAccount();

        Opportunity opp = createOpportunity(acc.Id, owner.Id);
        createQuote(opp.Id, true);

        Test.startTest();
        opp.Probability = 65;
        update opp;
        Test.stopTest();

        Opportunity updatedOpp = [
            SELECT Id, Probability
            FROM Opportunity
            WHERE Id = :opp.Id
        ];

        System.assertEquals(65, updatedOpp.Probability);

        OpportunityStageSyncContext.reset();
    }
}