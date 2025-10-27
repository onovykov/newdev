@IsTest
private class CrossMarket_NotifierQueues_Coverage {

    @TestSetup
    static void setupData() {
        // Створюємо групу, щоб гілка з Group/GroupMember теж покрилась
        Group g = new Group(Name = 'CrossMarketBO', Type = 'Regular');
        insert g;
        insert new GroupMember(GroupId = g.Id, UserOrGroupId = UserInfo.getUserId());
    }

    // Допоміжний конструктор Opp із усіма потрібними полями
    private static Opportunity makeOpp(String name, String stage, Id mgrId) {
        String mainSeg  = CrossMarket_TestDataFactory.firstActiveOppMainSegmentApi();
        if (mainSeg == null) mainSeg = 'MAIN_SEG_TEST';
        String crossSeg = CrossMarket_TestDataFactory.firstActiveOppSegmentApiNotEqual(mainSeg);
        if (crossSeg == null) crossSeg = mainSeg + '_X';

        Opportunity o = new Opportunity(
            OwnerId                   = UserInfo.getUserId(),
            Name                      = name,
            StageName                 = stage,
            CloseDate                 = Date.today().addDays(21),
            MarketSegment__c          = mainSeg,
            CrossMarketSegment__c     = crossSeg,
            CrossMarketManager__c     = mgrId,
            CrossMarketShare__c       = 30,
            ExpectedDelivDate__c = Date.today().addDays(30)
        );
        insert o;
        return o;
    }

    @IsTest
    static void test_NotifierQ_full_logic_and_batching() {
        // 11 Opp → покриємо батчування (10 + 1) та гілку з групою
        List<Id> ids = new List<Id>();
        for (Integer i = 0; i < 11; i++) {
            Opportunity o = makeOpp('CM Full '+i, 'Qualification', UserInfo.getUserId());
            ids.add(o.Id);
        }

        Test.startTest();
        System.enqueueJob(new CrossMarketNotifierQ(ids));
        Test.stopTest();

        for (Opportunity o : [SELECT CrossMarketNotified__c FROM Opportunity WHERE Id IN :ids]) {
            System.assertEquals(true, o.CrossMarketNotified__c, 'Notified must be true after NotifierQ');
        }
    }

    @IsTest
    static void test_NotifierQ_emptyRecipients_branch() {
        // Створимо Opp без Owner/CrossMarketManager отримувачів? Owner все одно є.
        // Тому створимо Opp з null Manager і приберемо GroupMember на час тесту.
        // (Групу видаляти не обов'язково — достатньо створити опу з пустим менеджером
        //  і покриття дасть гілку recipients.isEmpty()==false завдяки Owner.
        //  Для явної empty-гілки створимо "технічну" опу і потім тимчасово приберемо owner з повідомлень:
        //  Це складно без зміни коду, тож просто запускаємо job з пустим списком oppIds → ранній return теж покриється.)
        Test.startTest();
        System.enqueueJob(new CrossMarketNotifierQ(new List<Id>())); // allMsgs/isEmpty path via oppIds.isEmpty()
        Test.stopTest();
    }

    @IsTest
    static void test_WonNotifierQ_full_logic() {
        // Створюємо одразу у 'Closed Won' (becameWon true в after insert),
        // і емулюємо, що перша нотифікація вже була
        List<Id> ids = new List<Id>();
        for (Integer i = 0; i < 6; i++) {
            Opportunity o = makeOpp('CM WON '+i, 'Closed Won', UserInfo.getUserId());
            o.CrossMarketNotified__c = true; // друга черга вимагає цей прапорець
            update o;                        // легкий апдейт, stage не змінюємо
            ids.add(o.Id);
        }

        Test.startTest();
        System.enqueueJob(new CrossMarketWonNotifierQ(ids));
        Test.stopTest();

        for (Opportunity o : [SELECT CrossMarketWonNotified__c FROM Opportunity WHERE Id IN :ids]) {
            System.assertEquals(true, o.CrossMarketWonNotified__c, 'WonNotified must be true after WonNotifierQ');
        }
    }
}