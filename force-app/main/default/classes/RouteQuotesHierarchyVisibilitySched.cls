public class RouteQuotesHierarchyVisibilitySched implements Schedulable {

    public void execute(SchedulableContext SC) {
        List<RouteQuotesH__c> routeQuotesHList = [SELECT Id, DateBegin__c, DateEnd__c, Parent__c, ParentId__c FROM RouteQuotesH__c WHERE Level__c = 1];
        List<RouteQuotesH__c> routeQuotesHToUpdateList = new List<RouteQuotesH__c>();

        Date startDate = Date.today().toStartOfMonth();
        Date endDate = Date.today().toStartOfMonth().addMonths(6);

        for(RouteQuotesH__c routeQuotesH : routeQuotesHList) {
            if(routeQuotesH.DateBegin__c >= startDate && routeQuotesH.DateEnd__c <= endDate && routeQuotesH.Parent__c == null) {
                routeQuotesH.Parent__c = routeQuotesH.ParentId__c;
                routeQuotesH.ParentId__c = null;
                routeQuotesHToUpdateList.add(routeQuotesH);
            } else if((routeQuotesH.DateBegin__c < startDate || routeQuotesH.DateEnd__c > endDate) && routeQuotesH.Parent__c != null) {
                routeQuotesH.ParentId__c = routeQuotesH.Parent__c;
                routeQuotesH.Parent__c = null;
                routeQuotesHToUpdateList.add(routeQuotesH);
            }
        }

        update routeQuotesHToUpdateList;
    }
}