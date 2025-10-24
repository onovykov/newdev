@IsTest
public class RouteQuotesHierarchyVisibilityTest {

    @TestSetup
    static void setup() {
        RouteQuotesH__c allRoutesQuotesParent = new RouteQuotesH__c(Name = 'ALL ROUTES QUOTES', Level__c = 0);
        insert allRoutesQuotesParent;

        List<RouteQuotesH__c> routeQuotesHList = new List<RouteQuotesH__c>();

        routeQuotesHList.add(new RouteQuotesH__c(
            DateBegin__c = Date.today().toStartOfMonth().addMonths(-1),
            DateEnd__c = Date.today().toStartOfMonth().addDays(-1),
            Parent__c = allRoutesQuotesParent.Id,
            Level__c = 1
        ));

        routeQuotesHList.add(new RouteQuotesH__c(
            DateBegin__c = Date.today().toStartOfMonth(),
            DateEnd__c = Date.today().toStartOfMonth().addMonths(1).addDays(-1),
            Parent__c = allRoutesQuotesParent.Id,
            Level__c = 1
        ));

        routeQuotesHList.add(new RouteQuotesH__c(
            DateBegin__c = Date.today().toStartOfMonth().addMonths(4),
            DateEnd__c = Date.today().toStartOfMonth().addMonths(5).addDays(-1),
            ParentId__c = allRoutesQuotesParent.Id,
            Level__c = 1
        ));

        insert routeQuotesHList;
    }

    @IsTest
    static void testCheckHierarchyVisibility() {

        Test.startTest();
        RouteQuotesHierarchyVisibilitySched scheduler = new RouteQuotesHierarchyVisibilitySched();
        scheduler.execute(null);
        Test.stopTest();

        RouteQuotesH__c prevRouteQuotesH = [SELECT Id, Parent__c, ParentId__c FROM RouteQuotesH__c WHERE DateBegin__c = :Date.today().toStartOfMonth().addMonths(-1)];
        RouteQuotesH__c currentRouteQuotesH = [SELECT Id, Parent__c, ParentId__c FROM RouteQuotesH__c WHERE DateBegin__c = :Date.today().toStartOfMonth()];
        RouteQuotesH__c nextRouteQuotesH = [SELECT Id, Parent__c, ParentId__c FROM RouteQuotesH__c WHERE DateBegin__c = :Date.today().toStartOfMonth().addMonths(4)];

        System.assert(prevRouteQuotesH.Parent__c == null);
        System.assert(prevRouteQuotesH.ParentId__c != null);
        System.assert(currentRouteQuotesH.Parent__c != null);
        System.assert(currentRouteQuotesH.ParentId__c == null);
        System.assert(nextRouteQuotesH.Parent__c != null);
        System.assert(nextRouteQuotesH.ParentId__c == null);
    }

}