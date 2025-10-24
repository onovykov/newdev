@isTest
public class RouteQuotesHierarchyQueueableTest {
    private static final Integer CURRENT_YEAR = Date.today().year();
    private static final Integer PREVIOUS_MONTH = Date.today().addMonths(-1).month();
    
    @testSetup
    static void setup() {
        List<Route_Quota__c> routeQuotas = new List<Route_Quota__c>();
        for (Integer i = 0; i < 3; i++) {
            Integer month = PREVIOUS_MONTH + i > 12 ? PREVIOUS_MONTH + i - 12 : PREVIOUS_MONTH + i;
            Integer year = PREVIOUS_MONTH == 11 && month == 1 ? CURRENT_YEAR + 1 : CURRENT_YEAR;
            Route_Quota__c routeQuota = new Route_Quota__c(
                DateBegin__c = Date.newInstance(year, month, 1),
                DateEnd__c = Date.newInstance(year, month, 31),
                MarketSegment__c = '0000' + (4 + i),
                Budget_t__c = 220,
                Budget_pcs__c = 0,
                Quote_t__c = 630,
                Quote_pcs__c = 0,
                Margin__c = 545000
            );
            routeQuotas.add(routeQuota);
        }
        insert routeQuotas;

        Family__c family = new Family__c(Name = 'Цех1. Нарезные');
        insert family;
        
        List<QBA_Families__c> qbaFamilies = new List<QBA_Families__c>();
        for (Route_Quota__c routeQuota : routeQuotas) {
            QBA_Families__c qbaFamily = new QBA_Families__c(
                QuotesBudgetAll__c = routeQuota.Id,
                Family__c = family.Id
            );
            qbaFamilies.add(qbaFamily);
        }
        insert qbaFamilies;

        List<QuotesStructure__c> quotesStructures = new List<QuotesStructure__c>();
        for (Route_Quota__c routeQuota : routeQuotas) {
            QuotesStructure__c quotesStructure = new QuotesStructure__c(
                DateBegin__c = routeQuota.DateBegin__c,
                DateEnd__c = routeQuota.DateEnd__c,
                MarketSegment__c = routeQuota.MarketSegment__c,
                Family__c = family.Id,
                Percent__c = 100
            );
            quotesStructures.add(quotesStructure);
        }
        insert quotesStructures;
    }

    @isTest
    static void testRouteQuotesHierarchyQueueable() {
        Test.startTest();
        RouteQuotesHierarchyQueueable job = new RouteQuotesHierarchyQueueable(false);
        ID jobId = System.enqueueJob(job);
        Test.stopTest();

        List<RouteQuotesH__c> routeQuotesHierarchy = [SELECT Id FROM RouteQuotesH__c];
        System.assert(routeQuotesHierarchy.size() > 0, 'RouteQuotesH__c records should be created');

        List<RouteQuotesRelated__c> routeQuotesRelated = [SELECT Id FROM RouteQuotesRelated__c];
        System.assert(routeQuotesRelated.size() > 0, 'RouteQuotesRelated__c records should be created');

        List<QuoteStructureDetail__c> quoteStructDetails = [SELECT Id FROM QuoteStructureDetail__c];
        System.assert(quoteStructDetails.size() > 0, 'QuoteStructureDetail__c records should be created');

        List<RouteQuotesH__c> routeQuotesHierarchyWithoutParent = [SELECT Id FROM RouteQuotesH__c WHERE Parent__c = null AND ParentId__c != null];
        System.assertEquals(1, routeQuotesHierarchyWithoutParent.size(), 'There shoud be one record without active parent');
    }

    @isTest
    static void testRouteQuotesHierarchyQueueableOnUpdate() {
        RouteQuotesH__c allRoutesQuotesParent = new RouteQuotesH__c(Name = 'ALL ROUTES QUOTES', Level__c = 0);
        insert allRoutesQuotesParent;

        Test.startTest();
        RouteQuotesHierarchyQueueable job = new RouteQuotesHierarchyQueueable(true);
        ID jobId = System.enqueueJob(job);
        Test.stopTest();

        List<RouteQuotesH__c> routeQuotesHierarchy = [SELECT Id FROM RouteQuotesH__c WHERE DateBegin__c = :Date.newInstance(CURRENT_YEAR, PREVIOUS_MONTH, 1)];
        System.assert(routeQuotesHierarchy.size() == 0, 'RouteQuotesH__c with previous month should not be created');

        List<RouteQuotesRelated__c> routeQuotesRelated = [SELECT Id FROM RouteQuotesRelated__c WHERE DateBegin__c = :Date.newInstance(CURRENT_YEAR, PREVIOUS_MONTH, 1)];
        System.assert(routeQuotesRelated.size() == 0, 'RouteQuotesRelated__c with previous month should not be created');

        List<QuoteStructureDetail__c> quoteStructDetails = [SELECT Id FROM QuoteStructureDetail__c WHERE DateBegin__c = :Date.newInstance(CURRENT_YEAR, PREVIOUS_MONTH, 1)];
        System.assert(quoteStructDetails.size() == 0, 'QuoteStructureDetail__c with previous month should not be created');

    }
}