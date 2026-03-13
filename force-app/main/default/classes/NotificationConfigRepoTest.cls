@IsTest
private class NotificationConfigRepoTest {

    private class MockMdt {
        public String DeveloperName;
        public Boolean Active_c;
        public String Channel_c;
        public String RecipientGroups_c;
        public Decimal ThrottleMinutes_c;
        public Decimal BatchSize_c;
    }

    @IsTest
    static void testGetEventCfg_WithInjection() {
        String testKey = 'TEST_EVENT';
        NotificationTypes.NotificationEventCfg mockCfg = new NotificationTypes.NotificationEventCfg();
        mockCfg.eventKey = testKey;

        NotificationConfigRepo.testConfigs = new Map<String, NotificationTypes.NotificationEventCfg>{
                testKey => mockCfg
        };

        Test.startTest();
        NotificationTypes.ChannelResult resultNone = NotificationResultFactory.none();
        NotificationTypes.NotificationEventCfg result = NotificationConfigRepo.getEventCfg(testKey);
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals(testKey, result.eventKey);
    }

    @IsTest
    static void testParseCsvKeys() {
        // Використовуємо одинарні лапки для Apex
        String csv = 'group1, group2, group1, , group3';

        Test.startTest();
        // Якщо помилка 'Method is not visible' лишається,
        // переконайтеся що NotificationConfigRepo задеплоєний з @TestVisible
        List<String> results = NotificationConfigRepo.parseCsvKeys(csv);
        Test.stopTest();

        System.assertEquals(3, results.size());
        System.assertEquals('group1', results[0]);
        System.assertEquals('group2', results[1]);
        System.assertEquals('group3', results[2]);
    }

    @IsTest
    static void testMapToCfg() {
        // Екранування для JSON: подвійні лапки всередині одинарних
        String mdtJson = '{"DeveloperName": "JSON_EVENT", "Active__c": true, "Channel__c": "Email", "RecipientGroups__c": "A,B"}';

        Notification_Event__mdt mdt = (Notification_Event__mdt)JSON.deserialize(
                mdtJson,
                Notification_Event__mdt.class
        );

        Test.startTest();
        NotificationTypes.NotificationEventCfg cfg = NotificationConfigRepo.mapToCfg(mdt);
        Test.stopTest();

        System.assertEquals('JSON_EVENT', cfg.eventKey);
        System.assertEquals(true, cfg.active);
        System.assertEquals('Email', cfg.channel);
        System.assertEquals(2, cfg.recipientGroupKeys.size());
    }

    @IsTest
    static void testClearCache() {
        Test.startTest();
        NotificationConfigRepo.clearCache();
        Test.stopTest();
        System.assert(true);
    }
}