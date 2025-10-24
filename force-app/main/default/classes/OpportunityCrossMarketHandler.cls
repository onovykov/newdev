public class OpportunityCrossMarketHandler {
    //--- Надсилаємо першу нотифікацію на продавця крос-маркет сегменту
    public static void enqueueNotifications(List<Opportunity> newList, Map<Id, Opportunity> oldMap) {
        List<Id> toNotify = new List<Id>();
        for (Opportunity o : newList) {
            Boolean wasComplete = oldMap != null && oldMap.containsKey(o.Id)
                ? oldMap.get(o.Id).CrossMarketComplete__c
                : false;

            // Спрацювати, якщо тепер всі три поля крос-маркету заповнено, раніше не був, і ще не відправляли
            if (o.CrossMarketComplete__c == true
                && wasComplete == false
                && (o.CrossMarketNotified__c == false || o.CrossMarketNotified__c == null)) {
                toNotify.add(o.Id);
            }
        }
        if (!toNotify.isEmpty()) {
            System.enqueueJob(new CrossMarketNotifierQ(toNotify));
        }
    }

    //--- Надсилаємо другу нотифікацію на керівника крос-маркет сегменту
    //    коли крос-маркет оппа стала Closed Won
     public static void enqueueClosedWonNotifications(
        List<Opportunity> newList,
        Map<Id, Opportunity> oldMap
    ) {
        List<Id> toNotifyOnWon = new List<Id>();

        for (Opportunity o : newList) {
            Boolean becameWon = o.StageName == 'Closed Won' &&
                                (oldMap == null || oldMap.get(o.Id).StageName != 'Closed Won');

            if (becameWon
                && o.CrossMarketComplete__c == true
                && o.CrossMarketNotified__c == true
                && (o.CrossMarketWonNotified__c == false || o.CrossMarketWonNotified__c == null)) {
                toNotifyOnWon.add(o.Id);
            }
        }

        if (!toNotifyOnWon.isEmpty()) {
            System.enqueueJob(new CrossMarketWonNotifierQ(toNotifyOnWon));
        }
    }   
}