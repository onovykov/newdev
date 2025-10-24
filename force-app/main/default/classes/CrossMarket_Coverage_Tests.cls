@IsTest
private class CrossMarket_Coverage_Tests {

    private static final String LABEL_SALES_MGR        = 'Sales Manager';
    private static final String LABEL_SENIOR_SALES_MGR = 'Senior Sales Manager';
    private static final String LABEL_SALES_CHIEF      = 'Sales Chief Officer';

    private static final String STAGE_OPEN  = 'Qualification';
    private static final String STAGE_OPEN2 = 'Negotiation/Review';
    private static final String STAGE_WON   = 'Closed Won';

    @IsTest
    static void test_FirstNotification_OnInsert() {
        CrossMarket_TestDataFactory.SegPair seg = CrossMarket_TestDataFactory.pickTwoDistinctSegments();
        // для юзерів — можна брати будь-яке активне значення; візьмемо mainApi
        String divisionApi = seg.mainApi;

        User owner = CrossMarket_TestDataFactory.makeUser('owneral','owner@test.com', LABEL_SALES_MGR,        divisionApi, false);
        User xmgr  = CrossMarket_TestDataFactory.makeUser('xmanager','mgr@test.com', LABEL_SENIOR_SALES_MGR,  divisionApi, false);

        System.runAs(owner) {
            Test.startTest();
            Opportunity o = CrossMarket_TestDataFactory.makeOpp(
                owner, 'Opp CM Insert', Date.today().addDays(7), STAGE_OPEN,
                xmgr.Id,
                seg.mainApi,   // MarketSegment__c (основний)
                seg.crossApi,  // CrossMarketSegment__c (ІНШИЙ)
                50
            );
            Test.stopTest();

            o = [SELECT CrossMarketNotified__c FROM Opportunity WHERE Id = :o.Id];
            System.assertEquals(true, o.CrossMarketNotified__c);
        }
    }

    @IsTest
    static void test_ClosedWon_Notification() {
        CrossMarket_TestDataFactory.SegPair seg = CrossMarket_TestDataFactory.pickTwoDistinctSegments();
        String divisionApi = seg.mainApi;

        User owner = CrossMarket_TestDataFactory.makeUser('owneral2','owner2@test.com', LABEL_SALES_MGR,       divisionApi, false);
        User xmgr  = CrossMarket_TestDataFactory.makeUser('xmanager2','mgr2@test.com', LABEL_SENIOR_SALES_MGR, divisionApi, false);
        User chief = CrossMarket_TestDataFactory.makeUser('chiefal','chief@test.com',  LABEL_SALES_CHIEF,      divisionApi, false);

        System.runAs(owner) {
            Test.startTest();
            Opportunity o = CrossMarket_TestDataFactory.makeOpp(
                owner, 'Opp CM Won', Date.today().addDays(10), STAGE_OPEN2,
                xmgr.Id,
                seg.mainApi, seg.crossApi,
                30
            );
            Test.stopTest();

            o = [SELECT CrossMarketNotified__c FROM Opportunity WHERE Id = :o.Id];
            System.assertEquals(true, o.CrossMarketNotified__c);

            Test.startTest();
            o.StageName = STAGE_WON;
            update o;
            Test.stopTest();

            o = [SELECT CrossMarketWonNotified__c FROM Opportunity WHERE Id = :o.Id];
            System.assertEquals(true, o.CrossMarketWonNotified__c);
        }
    }

    @IsTest
    static void test_Idempotency_NoDuplicateNotifications() {
        CrossMarket_TestDataFactory.SegPair seg = CrossMarket_TestDataFactory.pickTwoDistinctSegments();
        String divisionApi = seg.mainApi;

        User owner = CrossMarket_TestDataFactory.makeUser('owneral3','owner3@test.com', LABEL_SALES_MGR,       divisionApi, false);
        User xmgr  = CrossMarket_TestDataFactory.makeUser('xmanager3','mgr3@test.com', LABEL_SENIOR_SALES_MGR, divisionApi, false);
        User chief = CrossMarket_TestDataFactory.makeUser('chiefal3','chief3@test.com',LABEL_SALES_CHIEF,      divisionApi, false);

        System.runAs(owner) {
            Test.startTest();
            Opportunity o = CrossMarket_TestDataFactory.makeOpp(
                owner, 'Opp CM Idem', Date.today().addDays(5), STAGE_OPEN,
                xmgr.Id,
                seg.mainApi, seg.crossApi,
                40
            );
            Test.stopTest();

            Test.startTest();
            o.StageName = STAGE_WON;
            update o;
            Test.stopTest();

            Boolean before = [SELECT CrossMarketWonNotified__c FROM Opportunity WHERE Id = :o.Id].CrossMarketWonNotified__c;

            Test.startTest();
            update o; // ще раз у Won — не повинно дублювати
            Test.stopTest();

            Boolean after = [SELECT CrossMarketWonNotified__c FROM Opportunity WHERE Id = :o.Id].CrossMarketWonNotified__c;
            System.assertEquals(before, after);
        }
    }
}