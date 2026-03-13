@IsTest
public class WebhookChannelTesting {

    // Mock для успішного HTTP response
    public class SuccessHttpMock implements HttpCalloutMock {
        public Integer statusCode = 200;
        public String responseBody = '{"success": true}';

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(statusCode);
            res.setBody(responseBody);
            return res;
        }
    }

    // Mock для помилкового HTTP response
    public class ErrorHttpMock implements HttpCalloutMock {
        public Integer statusCode = 500;
        public String responseBody = '{"error": "Internal Server Error"}';

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(statusCode);
            res.setBody(responseBody);
            return res;
        }
    }

    @IsTest
    static void testSend_NoWebhookPath() {
        // Arrange
        Notification_Settings__c settings = new Notification_Settings__c(
                WebhookPath__c = null
        );
        insert settings;

        WebhookChannel channel = new WebhookChannel();
        NotificationTypes.NotificationPayload payload = new NotificationTypes.NotificationPayload();
        NotificationTypes.RecipientBundle recipients = new NotificationTypes.RecipientBundle();
        NotificationTypes.NotificationEventCfg cfg = new NotificationTypes.NotificationEventCfg();

        Test.startTest();
        NotificationTypes.ChannelResult result = channel.send(payload, recipients, cfg);
        Test.stopTest();

        System.assertEquals(true, result.ok);
        System.assertEquals(0, result.sentCount);
    }

    @IsTest
    static void testSend_BlankWebhookPath() {
        // Arrange
        Notification_Settings__c settings = new Notification_Settings__c(
                WebhookPath__c = '   '
        );
        insert settings;

        WebhookChannel channel = new WebhookChannel();
        NotificationTypes.NotificationPayload payload = new NotificationTypes.NotificationPayload();
        NotificationTypes.RecipientBundle recipients = new NotificationTypes.RecipientBundle();
        NotificationTypes.NotificationEventCfg cfg = new NotificationTypes.NotificationEventCfg();

        Test.startTest();
        NotificationTypes.ChannelResult result = channel.send(payload, recipients, cfg);
        Test.stopTest();

        System.assertEquals(true, result.ok);
        System.assertEquals(0, result.sentCount);
    }

    @IsTest
    static void testSend_Success_200() {
        // Arrange
        Notification_Settings__c settings = new Notification_Settings__c(
                WebhookPath__c = '/test/webhook'
        );
        insert settings;

        Test.setMock(HttpCalloutMock.class, new SuccessHttpMock());

        WebhookChannel channel = new WebhookChannel();
        NotificationTypes.NotificationPayload payload = new NotificationTypes.NotificationPayload();
        payload.eventKey = 'TEST_EVENT';
        NotificationTypes.RecipientBundle recipients = new NotificationTypes.RecipientBundle();
        NotificationTypes.NotificationEventCfg cfg = new NotificationTypes.NotificationEventCfg();
        cfg.channel = 'Webhook';

        Test.startTest();
        NotificationTypes.ChannelResult result = channel.send(payload, recipients, cfg);
        Test.stopTest();

        System.assertEquals(true, result.ok);
        System.assertEquals(1, result.sentCount);
        System.assertNotEquals(null, result.message);
    }

    @IsTest
    static void testSend_Success_204() {
        // Arrange
        Notification_Settings__c settings = new Notification_Settings__c(
                WebhookPath__c = '/test/webhook'
        );
        insert settings;

        SuccessHttpMock mock = new SuccessHttpMock();
        mock.statusCode = 204;
        Test.setMock(HttpCalloutMock.class, mock);

        WebhookChannel channel = new WebhookChannel();
        NotificationTypes.NotificationPayload payload = new NotificationTypes.NotificationPayload();
        NotificationTypes.RecipientBundle recipients = new NotificationTypes.RecipientBundle();
        NotificationTypes.NotificationEventCfg cfg = new NotificationTypes.NotificationEventCfg();

        Test.startTest();
        NotificationTypes.ChannelResult result = channel.send(payload, recipients, cfg);
        Test.stopTest();

        System.assertEquals(true, result.ok);
        System.assertEquals(1, result.sentCount);
    }

    @IsTest
    static void testSend_Error_400() {
        // Arrange
        Notification_Settings__c settings = new Notification_Settings__c(
                WebhookPath__c = '/test/webhook'
        );
        insert settings;

        ErrorHttpMock mock = new ErrorHttpMock();
        mock.statusCode = 400;
        mock.responseBody = 'Bad Request';
        Test.setMock(HttpCalloutMock.class, mock);

        WebhookChannel channel = new WebhookChannel();
        NotificationTypes.NotificationPayload payload = new NotificationTypes.NotificationPayload();
        NotificationTypes.RecipientBundle recipients = new NotificationTypes.RecipientBundle();
        NotificationTypes.NotificationEventCfg cfg = new NotificationTypes.NotificationEventCfg();

        Test.startTest();
        NotificationTypes.ChannelResult result = channel.send(payload, recipients, cfg);
        Test.stopTest();

        System.assertEquals(false, result.ok);
        System.assertEquals(0, result.sentCount);
        System.assertEquals('Bad Request', result.message);
    }

    @IsTest
    static void testSend_Error_500() {
        // Arrange
        Notification_Settings__c settings = new Notification_Settings__c(
                WebhookPath__c = '/test/webhook'
        );
        insert settings;

        Test.setMock(HttpCalloutMock.class, new ErrorHttpMock());

        WebhookChannel channel = new WebhookChannel();
        NotificationTypes.NotificationPayload payload = new NotificationTypes.NotificationPayload();
        NotificationTypes.RecipientBundle recipients = new NotificationTypes.RecipientBundle();
        NotificationTypes.NotificationEventCfg cfg = new NotificationTypes.NotificationEventCfg();

        Test.startTest();
        NotificationTypes.ChannelResult result = channel.send(payload, recipients, cfg);
        Test.stopTest();

        System.assertEquals(false, result.ok);
        System.assertEquals(0, result.sentCount);
    }

    @IsTest
    static void testSend_WithContext() {
        // Arrange
        Notification_Settings__c settings = new Notification_Settings__c(
                WebhookPath__c = '/test/webhook'
        );
        insert settings;

        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Test.setMock(HttpCalloutMock.class, new SuccessHttpMock());

        WebhookChannel channel = new WebhookChannel();
        NotificationTypes.NotificationPayload payload = new NotificationTypes.NotificationPayload();
        payload.eventKey = 'ACCOUNT_CREATED';
        payload.context = acc;
        NotificationTypes.RecipientBundle recipients = new NotificationTypes.RecipientBundle();
        NotificationTypes.NotificationEventCfg cfg = new NotificationTypes.NotificationEventCfg();
        cfg.channel = 'Webhook';

        Test.startTest();
        NotificationTypes.ChannelResult result = channel.send(payload, recipients, cfg);
        Test.stopTest();

        System.assertEquals(true, result.ok);
        System.assertEquals(1, result.sentCount);
    }

    @IsTest
    static void testSend_WithVars() {
        // Arrange
        Notification_Settings__c settings = new Notification_Settings__c(
                WebhookPath__c = '/test/webhook'
        );
        insert settings;

        Test.setMock(HttpCalloutMock.class, new SuccessHttpMock());

        WebhookChannel channel = new WebhookChannel();
        NotificationTypes.NotificationPayload payload = new NotificationTypes.NotificationPayload();
        payload.eventKey = 'CUSTOM_EVENT';
        payload.vars = new Map<String, Object>{
                'key1' => 'value1',
                'key2' => 123,
                'key3' => true
        };
        NotificationTypes.RecipientBundle recipients = new NotificationTypes.RecipientBundle();
        NotificationTypes.NotificationEventCfg cfg = new NotificationTypes.NotificationEventCfg();
        cfg.channel = 'Webhook';

        Test.startTest();
        NotificationTypes.ChannelResult result = channel.send(payload, recipients, cfg);
        Test.stopTest();

        System.assertEquals(true, result.ok);
        System.assertEquals(1, result.sentCount);
    }

    @IsTest
    static void testSend_NullRecipients() {
        // Arrange
        Notification_Settings__c settings = new Notification_Settings__c(
                WebhookPath__c = '/test/webhook'
        );
        insert settings;

        Test.setMock(HttpCalloutMock.class, new SuccessHttpMock());

        WebhookChannel channel = new WebhookChannel();
        NotificationTypes.NotificationPayload payload = new NotificationTypes.NotificationPayload();
        NotificationTypes.NotificationEventCfg cfg = new NotificationTypes.NotificationEventCfg();

        Test.startTest();
        NotificationTypes.ChannelResult result = channel.send(payload, null, cfg);
        Test.stopTest();

        System.assertEquals(true, result.ok);
    }

    @IsTest
    static void testSend_ContextWithoutId() {
        // Arrange
        Notification_Settings__c settings = new Notification_Settings__c(
                WebhookPath__c = '/test/webhook'
        );
        insert settings;

        Test.setMock(HttpCalloutMock.class, new SuccessHttpMock());

        WebhookChannel channel = new WebhookChannel();
        NotificationTypes.NotificationPayload payload = new NotificationTypes.NotificationPayload();
        payload.context = new Account(Name = 'No Id');
        NotificationTypes.RecipientBundle recipients = new NotificationTypes.RecipientBundle();
        NotificationTypes.NotificationEventCfg cfg = new NotificationTypes.NotificationEventCfg();

        Test.startTest();
        NotificationTypes.ChannelResult result = channel.send(payload, recipients, cfg);
        Test.stopTest();

        System.assertEquals(true, result.ok);
    }
}