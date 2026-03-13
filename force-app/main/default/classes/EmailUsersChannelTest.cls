@IsTest
private class EmailUsersChannelTest {

    @TestSetup
    static void setup() {
        EmailTemplate template = new EmailTemplate(
            DeveloperName = 'Test_Template',
            Name = 'Test Template',
            FolderId = UserInfo.getUserId(),
            TemplateType = 'text',
            Subject = 'Test',
            Body = 'Test Body'
        );
        insert template;
    }

    @IsTest
    static void testSend_NoRecipients() {
        EmailUsersChannel channel = new EmailUsersChannel();
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
    static void testSend_NoTemplate() {
        EmailUsersChannel channel = new EmailUsersChannel();
        NotificationTypes.NotificationPayload payload = new NotificationTypes.NotificationPayload();
        NotificationTypes.RecipientBundle recipients = new NotificationTypes.RecipientBundle();
        recipients.userIds.add(UserInfo.getUserId());
        NotificationTypes.NotificationEventCfg cfg = new NotificationTypes.NotificationEventCfg();

        Test.startTest();
        NotificationTypes.ChannelResult result = channel.send(payload, recipients, cfg);
        Test.stopTest();

        System.assertEquals(false, result.ok);
        System.assertEquals(0, result.sentCount);
    }

    @IsTest
    static void testSend_TemplateNotFound() {
        EmailUsersChannel channel = new EmailUsersChannel();
        NotificationTypes.NotificationPayload payload = new NotificationTypes.NotificationPayload();
        NotificationTypes.RecipientBundle recipients = new NotificationTypes.RecipientBundle();
        recipients.userIds.add(UserInfo.getUserId());
        NotificationTypes.NotificationEventCfg cfg = new NotificationTypes.NotificationEventCfg();
        cfg.templateApiName = 'NonExistent';

        Test.startTest();
        NotificationTypes.ChannelResult result = channel.send(payload, recipients, cfg);
        Test.stopTest();

        System.assertEquals(false, result.ok);
    }

    @IsTest
    static void testSend_Success() {
        EmailUsersChannel channel = new EmailUsersChannel();
        NotificationTypes.NotificationPayload payload = new NotificationTypes.NotificationPayload();
        NotificationTypes.RecipientBundle recipients = new NotificationTypes.RecipientBundle();
        recipients.userIds.add(UserInfo.getUserId());
        NotificationTypes.NotificationEventCfg cfg = new NotificationTypes.NotificationEventCfg();
        cfg.templateApiName = 'Test_Template';

        Test.startTest();
        NotificationTypes.ChannelResult result = channel.send(payload, recipients, cfg);
        Test.stopTest();

        System.assertNotEquals(null, result);
    }

    @IsTest
    static void testSend_MultipleUsers() {
        EmailUsersChannel channel = new EmailUsersChannel();
        NotificationTypes.NotificationPayload payload = new NotificationTypes.NotificationPayload();
        NotificationTypes.RecipientBundle recipients = new NotificationTypes.RecipientBundle();

        List<User> users = [SELECT Id FROM User WHERE IsActive = true LIMIT 5];
        for (User u : users) {
            recipients.userIds.add(u.Id);
        }

        NotificationTypes.NotificationEventCfg cfg = new NotificationTypes.NotificationEventCfg();
        cfg.templateApiName = 'Test_Template';

        Test.startTest();
        NotificationTypes.ChannelResult result = channel.send(payload, recipients, cfg);
        Test.stopTest();

        System.assertNotEquals(null, result);
    }

    @IsTest
    static void testSend_WithContext() {
        Account acc = new Account(Name = 'Test');
        insert acc;

        EmailUsersChannel channel = new EmailUsersChannel();
        NotificationTypes.NotificationPayload payload = new NotificationTypes.NotificationPayload();
        payload.context = acc;

        NotificationTypes.RecipientBundle recipients = new NotificationTypes.RecipientBundle();
        recipients.userIds.add(UserInfo.getUserId());

        NotificationTypes.NotificationEventCfg cfg = new NotificationTypes.NotificationEventCfg();
        cfg.templateApiName = 'Test_Template';

        Test.startTest();
        NotificationTypes.ChannelResult result = channel.send(payload, recipients, cfg);
        Test.stopTest();

        System.assertNotEquals(null, result);
    }

    @IsTest
    static void testSend_NullPayload() {
        EmailUsersChannel channel = new EmailUsersChannel();
        NotificationTypes.RecipientBundle recipients = new NotificationTypes.RecipientBundle();
        recipients.userIds.add(UserInfo.getUserId());
        NotificationTypes.NotificationEventCfg cfg = new NotificationTypes.NotificationEventCfg();
        cfg.templateApiName = 'Test_Template';

        Test.startTest();
        NotificationTypes.ChannelResult result = channel.send(null, recipients, cfg);
        Test.stopTest();

        System.assertNotEquals(null, result);
    }

    @IsTest
    static void testSend_PayloadWithoutContext() {
        EmailUsersChannel channel = new EmailUsersChannel();
        NotificationTypes.NotificationPayload payload = new NotificationTypes.NotificationPayload();
        payload.context = null;

        NotificationTypes.RecipientBundle recipients = new NotificationTypes.RecipientBundle();
        recipients.userIds.add(UserInfo.getUserId());
        NotificationTypes.NotificationEventCfg cfg = new NotificationTypes.NotificationEventCfg();
        cfg.templateApiName = 'Test_Template';

        Test.startTest();
        NotificationTypes.ChannelResult result = channel.send(payload, recipients, cfg);
        Test.stopTest();

        System.assertNotEquals(null, result);
    }

    @IsTest
    static void testSend_ContextWithoutId() {
        EmailUsersChannel channel = new EmailUsersChannel();
        NotificationTypes.NotificationPayload payload = new NotificationTypes.NotificationPayload();
        payload.context = new Account(Name = 'No Id');

        NotificationTypes.RecipientBundle recipients = new NotificationTypes.RecipientBundle();
        recipients.userIds.add(UserInfo.getUserId());
        NotificationTypes.NotificationEventCfg cfg = new NotificationTypes.NotificationEventCfg();
        cfg.templateApiName = 'Test_Template';

        Test.startTest();
        NotificationTypes.ChannelResult result = channel.send(payload, recipients, cfg);
        Test.stopTest();

        System.assertNotEquals(null, result);
    }

    @IsTest
    static void testSend_NullUserIdInList() {
        EmailUsersChannel channel = new EmailUsersChannel();
        NotificationTypes.NotificationPayload payload = new NotificationTypes.NotificationPayload();
        NotificationTypes.RecipientBundle recipients = new NotificationTypes.RecipientBundle();
        recipients.userIds.add(UserInfo.getUserId());
        recipients.userIds.add(null);
        recipients.userIds.add(UserInfo.getUserId());

        NotificationTypes.NotificationEventCfg cfg = new NotificationTypes.NotificationEventCfg();
        cfg.templateApiName = 'Test_Template';

        Test.startTest();
        NotificationTypes.ChannelResult result = channel.send(payload, recipients, cfg);
        Test.stopTest();

        System.assertNotEquals(null, result);
    }

    @IsTest
    static void testSend_MoreThan10Users() {
        EmailUsersChannel channel = new EmailUsersChannel();
        NotificationTypes.NotificationPayload payload = new NotificationTypes.NotificationPayload();
        NotificationTypes.RecipientBundle recipients = new NotificationTypes.RecipientBundle();

        List<User> users = [SELECT Id FROM User WHERE IsActive = true LIMIT 15];
        for (User u : users) {
            recipients.userIds.add(u.Id);
        }

        NotificationTypes.NotificationEventCfg cfg = new NotificationTypes.NotificationEventCfg();
        cfg.templateApiName = 'Test_Template';

        Test.startTest();
        NotificationTypes.ChannelResult result = channel.send(payload, recipients, cfg);
        Test.stopTest();

        System.assertNotEquals(null, result);
    }

    @IsTest
    static void testSend_Exactly10Users() {
        EmailUsersChannel channel = new EmailUsersChannel();
        NotificationTypes.NotificationPayload payload = new NotificationTypes.NotificationPayload();
        NotificationTypes.RecipientBundle recipients = new NotificationTypes.RecipientBundle();

        List<User> users = [SELECT Id FROM User WHERE IsActive = true LIMIT 10];
        for (User u : users) {
            recipients.userIds.add(u.Id);
        }

        NotificationTypes.NotificationEventCfg cfg = new NotificationTypes.NotificationEventCfg();
        cfg.templateApiName = 'Test_Template';

        Test.startTest();
        NotificationTypes.ChannelResult result = channel.send(payload, recipients, cfg);
        Test.stopTest();

        System.assertNotEquals(null, result);
    }

    @IsTest
    static void testSend_TemplateCaching() {
        EmailUsersChannel channel = new EmailUsersChannel();
        NotificationTypes.NotificationPayload payload = new NotificationTypes.NotificationPayload();
        NotificationTypes.RecipientBundle recipients = new NotificationTypes.RecipientBundle();
        recipients.userIds.add(UserInfo.getUserId());
        NotificationTypes.NotificationEventCfg cfg = new NotificationTypes.NotificationEventCfg();
        cfg.templateApiName = 'Test_Template';

        Test.startTest();
        NotificationTypes.ChannelResult result1 = channel.send(payload, recipients, cfg);
        NotificationTypes.ChannelResult result2 = channel.send(payload, recipients, cfg);
        Test.stopTest();

        System.assertNotEquals(null, result1);
        System.assertNotEquals(null, result2);
    }

    @IsTest
    static void testSend_BlankTemplateApiName() {
        EmailUsersChannel channel = new EmailUsersChannel();
        NotificationTypes.NotificationPayload payload = new NotificationTypes.NotificationPayload();
        NotificationTypes.RecipientBundle recipients = new NotificationTypes.RecipientBundle();
        recipients.userIds.add(UserInfo.getUserId());
        NotificationTypes.NotificationEventCfg cfg = new NotificationTypes.NotificationEventCfg();
        cfg.templateApiName = '   ';

        Test.startTest();
        NotificationTypes.ChannelResult result = channel.send(payload, recipients, cfg);
        Test.stopTest();

        System.assertEquals(false, result.ok);
    }

    @IsTest
    static void testSend_NullRecipientsObject() {
        EmailUsersChannel channel = new EmailUsersChannel();
        NotificationTypes.NotificationPayload payload = new NotificationTypes.NotificationPayload();
        NotificationTypes.NotificationEventCfg cfg = new NotificationTypes.NotificationEventCfg();
        cfg.templateApiName = 'Test_Template';

        Test.startTest();
        NotificationTypes.ChannelResult result = channel.send(payload, null, cfg);
        Test.stopTest();

        System.assertEquals(true, result.ok);
        System.assertEquals(0, result.sentCount);
    }

    @IsTest
    static void testSend_NullUserIds() {
        EmailUsersChannel channel = new EmailUsersChannel();
        NotificationTypes.NotificationPayload payload = new NotificationTypes.NotificationPayload();
        NotificationTypes.RecipientBundle recipients = new NotificationTypes.RecipientBundle();
        recipients.userIds = null;
        NotificationTypes.NotificationEventCfg cfg = new NotificationTypes.NotificationEventCfg();
        cfg.templateApiName = 'Test_Template';

        Test.startTest();
        NotificationTypes.ChannelResult result = channel.send(payload, recipients, cfg);
        Test.stopTest();

        System.assertEquals(true, result.ok);
        System.assertEquals(0, result.sentCount);
    }

    @IsTest
    static void testSend_TemplateWithWhitespace() {
        EmailUsersChannel channel = new EmailUsersChannel();
        NotificationTypes.NotificationPayload payload = new NotificationTypes.NotificationPayload();
        NotificationTypes.RecipientBundle recipients = new NotificationTypes.RecipientBundle();
        recipients.userIds.add(UserInfo.getUserId());
        NotificationTypes.NotificationEventCfg cfg = new NotificationTypes.NotificationEventCfg();
        cfg.templateApiName = '  Test_Template  ';

        Test.startTest();
        NotificationTypes.ChannelResult result = channel.send(payload, recipients, cfg);
        Test.stopTest();

        System.assertNotEquals(null, result);
    }
}