@IsTest  
private class CrossMarket_Coverage_Tests {

    private static final String LABEL_SALES_MGR        = 'Sales Manager';
    private static final String LABEL_SENIOR_SALES_MGR = 'Senior Sales Manager';
    private static final String LABEL_SALES_CHIEF      = 'Sales Chief Officer';

    private static final String STAGE_OPEN  = 'Qualification';
    private static final String STAGE_OPEN2 = 'Negotiation/Review';
    private static final String STAGE_WON   = 'Closed Won';

    // 1) Перша нотифікація на вставці
    @IsTest
    static void test_FirstNotification_OnInsert() {
        CrossMarket_TestDataFactory.SegPair seg = CrossMarket_TestDataFactory.pickTwoDistinctSegments();
        String divisionApi = CrossMarket_TestDataFactory.firstActiveUserSalesDivisionApi();

        User owner = CrossMarket_TestDataFactory.makeUser('owneral','owner@test.com', LABEL_SALES_MGR,       divisionApi, false);
        User xmgr  = CrossMarket_TestDataFactory.makeUser('xmanager','mgr@test.com',  LABEL_SENIOR_SALES_MGR, divisionApi, false);

        System.runAs(owner) {
            Test.startTest();

            Opportunity o = CrossMarket_TestDataFactory.makeOpp(
                owner, 'Opp CM Insert', Date.today().addDays(7), STAGE_OPEN,
                xmgr.Id,
                seg.mainApi,   // MarketSegment__c
                seg.crossApi,  // CrossMarketSegment__c
                50
            );

            // Додатковий update — формула CrossMarketComplete__c гарантовано стане true,
            // і enqueueNotifications спрацює в after update
            update o;

            Test.stopTest();

            o = [SELECT CrossMarketComplete__c, CrossMarketNotified__c FROM Opportunity WHERE Id = :o.Id];
            System.assertEquals(true, o.CrossMarketComplete__c, 'CrossMarketComplete__c має бути true після insert+update');
            System.assertEquals(true, o.CrossMarketNotified__c,
                'При створенні Opp має виставлятися CrossMarketNotified__c = true');
        }
    }

    // 2) Нотифікація при переході в Closed Won
    @IsTest
    static void test_ClosedWon_Notification() {
        CrossMarket_TestDataFactory.SegPair seg = CrossMarket_TestDataFactory.pickTwoDistinctSegments();
        String divisionApi = CrossMarket_TestDataFactory.firstActiveUserSalesDivisionApi();

        User owner = CrossMarket_TestDataFactory.makeUser('owneral2','owner2@test.com', LABEL_SALES_MGR,       divisionApi, false);
        User xmgr  = CrossMarket_TestDataFactory.makeUser('xmanager2','mgr2@test.com', LABEL_SENIOR_SALES_MGR, divisionApi, false);
        User chief = CrossMarket_TestDataFactory.makeUser('chiefal','chief@test.com',  LABEL_SALES_CHIEF,      divisionApi, false);

        System.runAs(owner) {
            Test.startTest();

            // Insert
            Opportunity o = CrossMarket_TestDataFactory.makeOpp(
                owner, 'Opp CM Won', Date.today().addDays(10), STAGE_OPEN2,
                xmgr.Id,
                seg.mainApi, seg.crossApi,
                30
            );

            // Дати формулі дозріти та повторно ініціювати enqueueNotifications
            o.CrossMarketNotified__c = true;   // ⬅️ додамо емулювання першої нотифікації
            update o;

            // Перехід у Won — тепер має поставитись друга черга
            o.StageName = STAGE_WON;
            update o;

            Test.stopTest();

            o = [
                SELECT CrossMarketComplete__c, CrossMarketNotified__c, CrossMarketWonNotified__c
                FROM Opportunity WHERE Id = :o.Id
            ];
            System.assertEquals(true, o.CrossMarketComplete__c, 'CrossMarketComplete__c має бути true');
            System.assertEquals(true, o.CrossMarketNotified__c, 'Opp має бути позначена як повідомлена по CrossMarket');
            System.assertEquals(true, o.CrossMarketWonNotified__c,
                'Opp у Closed Won має бути позначена по CrossMarketWon');
        }
    }

    // 3) Ідемпотентність — повторні апдейти не дублюють Won-нотифікацію
    @IsTest
    static void test_Idempotency_NoDuplicateNotifications() {
        CrossMarket_TestDataFactory.SegPair seg = CrossMarket_TestDataFactory.pickTwoDistinctSegments();
        String divisionApi = CrossMarket_TestDataFactory.firstActiveUserSalesDivisionApi();

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

            // Дозріває формула + перша черга
            update o;

            // Won — друга черга
            o.StageName = STAGE_WON;
            update o;

            Boolean before = [
                SELECT CrossMarketWonNotified__c FROM Opportunity WHERE Id = :o.Id
            ].CrossMarketWonNotified__c;

            // Повторний апдейт у Won — не повинно дублювати
            update o;

            Test.stopTest();

            Boolean after = [
                SELECT CrossMarketWonNotified__c FROM Opportunity WHERE Id = :o.Id
            ].CrossMarketWonNotified__c;

            System.assertEquals(before, after,
                'Повторне оновлення Opp у Closed Won не повинно дублювати нотифікацію');
        }
    }
}