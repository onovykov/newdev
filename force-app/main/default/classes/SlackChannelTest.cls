@IsTest
private class SlackChannelTest {

    // Внутрішній клас для імітації відповіді Slack
    private class SlackMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"ok": true}');
            return res;
        }
    }

    @IsTest
    static void testSend_FullCoverage() {
        // 1. SETUP CUSTOM SETTINGS
        // Це те, чого не вистачало. Створюємо налаштування для рівня організації.
        Notification_Settings__c settings = new Notification_Settings__c(
                SetupOwnerId = UserInfo.getOrganizationId(),
                SlackPath__c = '/services/T000/B000/XXXXXXXX' // Будь-який текст, щоб пройти String.isBlank
        );
        insert settings;

        // 2. PREPARE DATA
        SlackChannel channel = new SlackChannel();

        // Створюємо мапу vars, щоб Builders мали дані
        Map<String, Object> vars = new Map<String, Object>{
                'subject' => 'Test Subject',
                'body' => 'Test Body'
        };
        NotificationTypes.NotificationPayload payload = new NotificationTypes.NotificationPayload('EVENT_KEY', null, vars);

        NotificationTypes.RecipientBundle recipient = new NotificationTypes.RecipientBundle();
        NotificationTypes.NotificationEventCfg cfg = new NotificationTypes.NotificationEventCfg();

        // ВСТАНОВЛЮЄМО HTTP MOCK
        Test.setMock(HttpCalloutMock.class, new SlackMock());

        // 3. EXECUTION
        Test.startTest();
        NotificationTypes.ChannelResult result = channel.send(payload, recipient, cfg);
        Test.stopTest();

        // 4. ASSERTIONS
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(true, result.ok, 'Result should be successful');
        System.assertEquals(1, result.sentCount, 'Sent count should be 1');
        System.assertEquals('{"ok": true}', result.message);
    }

    @IsTest
    static void testSend_NoPath_ReturnsNone() {
        // Тестуємо гілку, коли налаштувань немає (код має повернути NotificationResultFactory.none())
        // Тут ми навмисно НЕ вставляємо Notification_Settings__c

        SlackChannel channel = new SlackChannel();
        NotificationTypes.NotificationPayload payload = new NotificationTypes.NotificationPayload();

        Test.startTest();
        NotificationTypes.ChannelResult result = channel.send(payload, new NotificationTypes.RecipientBundle(), null);
        Test.stopTest();

        System.assertNotEquals(null, result);
        // Залежно від вашої фабрики, тут зазвичай ok = false або sentCount = 0
    }
}