@IsTest
private class CrossMarket_Queueables_Tests {

    @TestSetup
    static void data() {
        // Група для логіки отримувачів (в тестах SeeAllData=false, тож створюємо самі)
        Group g = new Group(Name = 'CrossMarketBO', Type = 'Regular');
        insert g;
        insert new GroupMember(GroupId = g.Id, UserOrGroupId = UserInfo.getUserId());
    }

    // Допоміжний метод створення Opp із заповненими полями та required датою
    private static Opportunity makeOpp(Id ownerId, Id mgrId, String name, String stage) {
        // значення сегментів: беремо два перших активних (через Describe), або задаємо «технічні» якщо порожньо
        String mainSeg  = CrossMarket_TestDataFactory.firstActiveOppMainSegmentApi();
        if (mainSeg == null) mainSeg = 'MAIN_SEG_TEST';
        String crossSeg = CrossMarket_TestDataFactory.firstActiveOppSegmentApiNotEqual(mainSeg);
        if (crossSeg == null) crossSeg = mainSeg + '_X';

        Opportunity o = new Opportunity(
            OwnerId               = ownerId,
            Name                  = name,
            StageName             = stage,
            CloseDate             = Date.today().addDays(14),
            MarketSegment__c      = mainSeg,
            CrossMarketSegment__c = crossSeg,
            CrossMarketManager__c = mgrId,
            CrossMarketShare__c   = 25,
            ExpectedDelivDate__c = Date.today().addDays(30)
        );
        insert o;
        return o;
    }

    @IsTest
    static void test_CrossMarketNotifierQ_fullpath_with_batching() {
        List<Id> ids = new List<Id>();
        for (Integer i = 0; i < 11; i++) { // 11 => покриємо батчування (10 + 1)
            Opportunity o = makeOpp(UserInfo.getUserId(), UserInfo.getUserId(), 'CM ' + i, 'Qualification');
            ids.add(o.Id);
        }

        Test.startTest();
        System.enqueueJob(new CrossMarketNotifierQ(ids));
        Test.stopTest();

        // Перевірка: усі мають бути позначені
        for (Opportunity o : [SELECT CrossMarketNotified__c FROM Opportunity WHERE Id IN :ids]) {
            System.assertEquals(true, o.CrossMarketNotified__c, 'Notified flag must be true');
        }
    }

    @IsTest
    static void test_CrossMarketWonNotifierQ_fullpath() {
        List<Id> ids = new List<Id>();
        for (Integer i = 0; i < 5; i++) {
            Opportunity o = makeOpp(UserInfo.getUserId(), UserInfo.getUserId(), 'CMW ' + i, 'Closed Won'); // ⬅️ одразу Won
            o.CrossMarketNotified__c = true; // емулюємо першу нотифікацію
            update o;                        // легкий апдейт (StageName не змінюємо)
            ids.add(o.Id);
        }

        Test.startTest();
        System.enqueueJob(new CrossMarketWonNotifierQ(ids));
        Test.stopTest();

        for (Opportunity o : [SELECT CrossMarketWonNotified__c FROM Opportunity WHERE Id IN :ids]) {
            System.assertEquals(true, o.CrossMarketWonNotified__c, 'WonNotified flag must be true');
        }
    }
}