@IsTest
public class QuotaAdjustmentFormControllerTest {

    @TestSetup
    static void makeData(){
        Shop__c shop = new Shop__c(Name = 'Test Shop');
        insert shop;

        FamiliesTypes__c familyType = new FamiliesTypes__c(Name = 'Test Family Type');
        insert familyType;

        Family__c family = new Family__c(Name = 'Test Family');
        insert family;

        Integer month = Date.today().month();

        RouteQuotesH__c routeQuotaHierarchy = new RouteQuotesH__c(
            Name = shop.Name,
            MarketSegment__c = '00004',
            DateBegin__c = Date.newInstance(2024, month, 1),
            DateEnd__c = Date.newInstance(2024, month, 31),
            Shop__c = shop.Id
        );
        insert routeQuotaHierarchy;

        QuoteStructureDetail__c quoteDetail = new QuoteStructureDetail__c(
            FamilyType__c = familyType.Id,
            Family__c = family.Id,
            MarketSegment__c = '00004',
            RoutesQuotesH__c = routeQuotaHierarchy.Id,
            Percent__c = 10.0,
            Quote_t__c = 100.0,
            AddQty_t__c = 20.0,
            ID_ERP__c = '12345'
        );
        insert quoteDetail;   

        QuoteSegmentStruct__c quoteSegmentStruct = new QuoteSegmentStruct__c(
            MarketSegment__c = '00004',
            ManagerStruct__c = true,
            Is_Active__c = true
        );

        insert quoteSegmentStruct;
    }

    @IsTest
    static void testGetQuoteStructureDetails() {
        Id routeQuotaHierarchyId = [SELECT Id FROM RouteQuotesH__c LIMIT 1].Id;

        List<QuotaAdjustmentFormController.QuoteStructDetailWrapper> result = QuotaAdjustmentFormController.getQuoteStructureDetails(routeQuotaHierarchyId);
        
        Assert.areNotEqual(0, result.size(), 'There should be result');
        Assert.areEqual('00004', result.get(0).marketSegment, 'Wrong Market Segment');
    }

    @IsTest
    static void testGetQuoteSegmentStruct() {
        Id routeQuotaHierarchyId = [SELECT Id FROM RouteQuotesH__c LIMIT 1].Id;

        List<QuoteSegmentStruct__c> result = QuotaAdjustmentFormController.getQuoteSegmentStruct(routeQuotaHierarchyId);
        
        Assert.isTrue(result.size() == 1, 'One QuoteSegmentStruct__c should be returned');
    }

    @IsTest
    static void testCreateQuoteRequestRecords() {
        Id routeQuotaHierarchyId = [SELECT Id FROM RouteQuotesH__c LIMIT 1].Id;
        Id familyTypeId = [SELECT Id FROM FamiliesTypes__c LIMIT 1].Id;
        Id familyId = [SELECT Id FROM Family__c LIMIT 1].Id;

        List<Map<String, Object>> families = new List<Map<String, Object>>();
        Map<String, Object> familyData = new Map<String, Object>();
        familyData.put('familyTypeId', familyTypeId);
        familyData.put('familyId', familyId);
        familyData.put('totalQuote', 150.0);
        familyData.put('newTotalQuote', 140.0);
        familyData.put('totalAddQty', 30.0);
        familyData.put('percent', 10.0);
        familyData.put('newPercent', 9.5);
        families.add(familyData);

        List<Map<String, Object>> details = new List<Map<String, Object>>();
        Map<String, Object> detailData = new Map<String, Object>();
        detailData.put('quoteStructDetailId', [SELECT Id FROM QuoteStructureDetail__c LIMIT 1].Id);
        detailData.put('quoteT', 200.0);
        detailData.put('addQty', 40.0);
        detailData.put('percent', 15.0);
        detailData.put('familyId', familyId);
        details.add(detailData);

        Test.startTest();
        QuotaAdjustmentFormController.createQuoteRequestRecords(routeQuotaHierarchyId, families, details);
        Test.stopTest();

        Integer headerCount = [SELECT COUNT() FROM QuoteRequestHeader__c];
        Integer familyCount = [SELECT COUNT() FROM QuoteRequestFamily__c];
        Integer detailCount = [SELECT COUNT() FROM QuoteRequestDetail__c];

        Assert.areEqual(1, headerCount, 'One QuoteRequestHeader__c should be created');
        Assert.areEqual(1, familyCount, 'One QuoteRequestFamily__c should be created');
        Assert.areEqual(1, detailCount, 'One QuoteRequestDetail__c should be created');
    }
}