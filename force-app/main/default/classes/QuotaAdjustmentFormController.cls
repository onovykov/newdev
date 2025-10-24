public class QuotaAdjustmentFormController {

    @AuraEnabled
    public static List<QuoteStructDetailWrapper> getQuoteStructureDetails(Id routeQuotaHierarchyId) {
        List<QuoteStructDetailWrapper> quoteStructDetailWrapperList = new List<QuoteStructDetailWrapper>();

        List<QuoteStructureDetail__c> quoteStructDetailList = [SELECT Id, FamilyType__c, FamilyType__r.Name, Family__c, 
                                                                      Family__r.Name, MarketSegment__c,
                                                                      Manager__r.Name, Group3__r.Name,
                                                                      Region__r.Name, Percent__c, Quote_t__c, AddQty_t__c
                                                               FROM QuoteStructureDetail__c 
                                                               WHERE RoutesQuotesH__c = :routeQuotaHierarchyId AND Archived__c = false
                                                               ORDER BY FamilyType__r.Name ASC];

        for (QuoteStructureDetail__c quoteStructDetail : quoteStructDetailList) {            
            QuoteStructDetailWrapper quoteStructDetailWrapper = new QuoteStructDetailWrapper(quoteStructDetail);
            quoteStructDetailWrapperList.add(quoteStructDetailWrapper);
        }

        return quoteStructDetailWrapperList;
    }

    @AuraEnabled(cacheable=true)
    public static List<QuoteSegmentStruct__c> getQuoteSegmentStruct(Id routeQuotaHierarchyId) {
        String marketSegment = [SELECT MarketSegment__c FROM RouteQuotesH__c WHERE Id = :routeQuotaHierarchyId].MarketSegment__c;

        List<QuoteSegmentStruct__c> quoteStructDetailList = [SELECT Id, ManagerStruct__c, Group3Struct__c, RegionStruct__c
                                                             FROM QuoteSegmentStruct__c 
                                                             WHERE MarketSegment__c = :marketSegment 
                                                             AND Is_Active__c = true];

        return quoteStructDetailList;
    }

    @AuraEnabled
    public static void createQuoteRequestRecords(Id routeQuotaHierarchyId, List<Map<String, Object>> families, List<Map<String, Object>> details) {
    Map<String, QuoteRequestFamily__c> familiesToInsertMap = new Map<String, QuoteRequestFamily__c>();
    List<QuoteRequestDetail__c> detailsToInsertList = new List<QuoteRequestDetail__c>();
    Set<Id> quoteStructDetailIdSet = new Set<Id>();

    for(Map<String, Object> detail : details) {
        quoteStructDetailIdSet.add((Id)detail.get('quoteStructDetailId'));
    }

    Map<Id, QuoteStructureDetail__c> quoteStructDetailMap = new Map<Id, QuoteStructureDetail__c>(
        [SELECT Id, FamilyType__c, Family__c, MarketSegment__c, Manager__c, Group3__c, Region__c, 
                Percent__c, Quote_t__c, AddQty_t__c, ID_ERP__c
        FROM QuoteStructureDetail__c 
        WHERE Id IN :quoteStructDetailIdSet]);

    RouteQuotesH__c routeQuotaHierarchy = [SELECT Id, MarketSegment__c, DateBegin__c, DateEnd__c, Shop__c
                                           FROM RouteQuotesH__c 
                                           WHERE Id = :routeQuotaHierarchyId];

    QuoteRequestHeader__c header = new QuoteRequestHeader__c();
    header.MarketSegment__c = routeQuotaHierarchy.MarketSegment__c;
    header.Month__c = String.valueOf(routeQuotaHierarchy.DateBegin__c.month());
    header.Year__c = routeQuotaHierarchy.DateBegin__c.year();
    header.DateFrom__c = routeQuotaHierarchy.DateBegin__c;
    header.DateTo__c = routeQuotaHierarchy.DateEnd__c;
    header.Status__c = '_1';
    header.Route_Quotes_Hierarchy__c = routeQuotaHierarchyId;
    
    insert header;

    for (Map<String, Object> family : families) {
        QuoteRequestFamily__c familyHeader = new QuoteRequestFamily__c(
            FamilyType__c = (String)family.get('familyTypeId'),
            Family__c = (String)family.get('familyId'),
            Shop__c = routeQuotaHierarchy.Shop__c,
            Quote_t__c = (Decimal)family.get('totalQuote'),
            AddQty_t__c = (Decimal)family.get('totalAddQty'),
            Percent__c = (Decimal)family.get('percent'),
            CorrectedPercent__c = (Decimal)family.get('newPercent'),
            QuoteRequestHeader__c = header.Id,
            RoutesQuotesH__c = routeQuotaHierarchyId
        );

        familiesToInsertMap.put((String)family.get('familyId'), familyHeader);
    }

    insert familiesToInsertMap.values();

    for (Map<String, Object> detail : details) {
        QuoteStructureDetail__c quoteStructureDetail = quoteStructDetailMap.get((Id)detail.get('quoteStructDetailId'));
        detailsToInsertList.add(new QuoteRequestDetail__c(
            MarketSegment__c = routeQuotaHierarchy.MarketSegment__c,
            DateBegin__c = routeQuotaHierarchy.DateBegin__c,
            DateEnd__c = routeQuotaHierarchy.DateEnd__c,
            Manager__c = quoteStructureDetail.Manager__c,
            Group3__c = quoteStructureDetail.Group3__c,
            Region__c = quoteStructureDetail.Region__c,
            FamilyType__c = quoteStructureDetail.FamilyType__c,
            Family__c = quoteStructureDetail.Family__c,
            ID_ERP__c = quoteStructureDetail.ID_ERP__c,
            Name = quoteStructureDetail.ID_ERP__c,
            QuoteStructureDetail__c = (Id)detail.get('quoteStructDetailId'),
            Quote_t__c = (Decimal)detail.get('quoteT'),
            AddQty_t__c = (Decimal)detail.get('addQty'),
            Percent__c = (Decimal)detail.get('percent'),
            QuoteRequestFamily__c = familiesToInsertMap.get((String)detail.get('familyId')).Id,
            QuoteRequestHeader__c = header.Id,
            RoutesQuotesH__c = routeQuotaHierarchyId
        ));
    }

    insert detailsToInsertList;
}


    public class QuoteStructDetailWrapper {
        @AuraEnabled public Id quoteStructDetailId {get; set;}
        @AuraEnabled public String familyTypeId {get; set;}
        @AuraEnabled public String familyType {get; set;}
        @AuraEnabled public String familyId {get; set;}
        @AuraEnabled public String family {get; set;}
        @AuraEnabled public String marketSegment {get; set;}
        @AuraEnabled public String manager {get; set;}
        @AuraEnabled public String group3 {get; set;}
        @AuraEnabled public String region {get; set;}
        @AuraEnabled public Decimal percent {get; set;}
        @AuraEnabled public Decimal quoteT {get; set;}
        @AuraEnabled public Decimal addQty {get; set;}
        @AuraEnabled public Decimal newQuota {get; set;}

        public QuoteStructDetailWrapper(QuoteStructureDetail__c quoteStructDetail) {
            this.quoteStructDetailId = quoteStructDetail.Id;
            this.familyTypeId = quoteStructDetail.FamilyType__c;
            this.familyType = quoteStructDetail.FamilyType__r.Name;
            this.familyId = quoteStructDetail.Family__c;
            this.family = quoteStructDetail.Family__r.Name;
            this.marketSegment = quoteStructDetail.MarketSegment__c;
            this.manager = quoteStructDetail.Manager__r.Name;
            this.group3 = quoteStructDetail.Group3__r.Name;
            this.region = quoteStructDetail.Region__r.Name;
            this.percent = quoteStructDetail.Percent__c;
            this.quoteT = quoteStructDetail.Quote_t__c;
            this.addQty = quoteStructDetail.AddQty_t__c != null ? quoteStructDetail.AddQty_t__c : 0;
            this.newQuota = quoteStructDetail.Quote_t__c;
        }
    }
}