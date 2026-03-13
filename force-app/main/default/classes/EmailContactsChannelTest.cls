@IsTest
private class EmailContactsChannelTest {

    @TestSetup
    static void setup() {
        // Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Contacts з різними статусами
        List<Contact> contacts = new List<Contact>();

        // Contact з email, не opted out
        contacts.add(new Contact(
            FirstName = 'Valid',
            LastName = 'Contact',
            Email = 'valid@test.com',
            AccountId = acc.Id,
            HasOptedOutOfEmail = false
        ));

        // Contact без email
        contacts.add(new Contact(
            FirstName = 'No',
            LastName = 'Email',
            AccountId = acc.Id,
            HasOptedOutOfEmail = false
        ));

        // Contact opted out
        contacts.add(new Contact(
            FirstName = 'Opted',
            LastName = 'Out',
            Email = 'optedout@test.com',
            AccountId = acc.Id,
            HasOptedOutOfEmail = true
        ));

        // Contact з blank email
        contacts.add(new Contact(
            FirstName = 'Blank',
            LastName = 'Email',
            Email = '',
            AccountId = acc.Id,
            HasOptedOutOfEmail = false
        ));

        insert contacts;
    }

    static void createTemplate() {
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
        EmailContactsChannel channel = new EmailContactsChannel();
        NotificationTypes.NotificationPayload payload = new NotificationTypes.NotificationPayload();
        NotificationTypes.RecipientBundle recipients = new NotificationTypes.RecipientBundle();
        NotificationTypes.NotificationEventCfg cfg = new NotificationTypes.NotificationEventCfg();

        Test.startTest();
        NotificationTypes.ChannelResult result = channel.send(payload, recipients, cfg);
        Test.stopTest();

        System.assertEquals(true, result.ok);
        System.assertEquals(0, result.sentCount);
        System.assertEquals('No contact recipients', result.message);
    }

    @IsTest
    static void testSend_NullRecipients() {
        EmailContactsChannel channel = new EmailContactsChannel();
        NotificationTypes.NotificationPayload payload = new NotificationTypes.NotificationPayload();
        NotificationTypes.NotificationEventCfg cfg = new NotificationTypes.NotificationEventCfg();

        Test.startTest();
        NotificationTypes.ChannelResult result = channel.send(payload, null, cfg);
        Test.stopTest();

        System.assertEquals(true, result.ok);
        System.assertEquals(0, result.sentCount);
    }

    @IsTest
    static void testSend_NullContactIds() {
        EmailContactsChannel channel = new EmailContactsChannel();
        NotificationTypes.NotificationPayload payload = new NotificationTypes.NotificationPayload();
        NotificationTypes.RecipientBundle recipients = new NotificationTypes.RecipientBundle();
        recipients.contactIds = null;
        NotificationTypes.NotificationEventCfg cfg = new NotificationTypes.NotificationEventCfg();

        Test.startTest();
        NotificationTypes.ChannelResult result = channel.send(payload, recipients, cfg);
        Test.stopTest();

        System.assertEquals(true, result.ok);
        System.assertEquals(0, result.sentCount);
    }

    @IsTest
    static void testSend_NoTemplate() {
        Contact c = [SELECT Id FROM Contact WHERE Email = 'valid@test.com' LIMIT 1];

        EmailContactsChannel channel = new EmailContactsChannel();
        NotificationTypes.NotificationPayload payload = new NotificationTypes.NotificationPayload();
        NotificationTypes.RecipientBundle recipients = new NotificationTypes.RecipientBundle();
        recipients.contactIds.add(c.Id);
        NotificationTypes.NotificationEventCfg cfg = new NotificationTypes.NotificationEventCfg();

        Test.startTest();
        NotificationTypes.ChannelResult result = channel.send(payload, recipients, cfg);
        Test.stopTest();

        System.assertEquals(false, result.ok);
        System.assertEquals(0, result.sentCount);
        System.assert(result.message.contains('TemplateApiName is blank'));
    }

    @IsTest
    static void testSend_TemplateNotFound() {
        Contact c = [SELECT Id FROM Contact WHERE Email = 'valid@test.com' LIMIT 1];

        EmailContactsChannel channel = new EmailContactsChannel();
        NotificationTypes.NotificationPayload payload = new NotificationTypes.NotificationPayload();
        NotificationTypes.RecipientBundle recipients = new NotificationTypes.RecipientBundle();
        recipients.contactIds.add(c.Id);
        NotificationTypes.NotificationEventCfg cfg = new NotificationTypes.NotificationEventCfg();
        cfg.templateApiName = 'NonExistent';

        Test.startTest();
        NotificationTypes.ChannelResult result = channel.send(payload, recipients, cfg);
        Test.stopTest();

        System.assertEquals(false, result.ok);
        System.assert(result.message.contains('Template lookup failed'));
    }

    @IsTest
    static void testSend_ValidContact() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            createTemplate();
        }

        Contact c = [SELECT Id FROM Contact WHERE Email = 'valid@test.com' LIMIT 1];

        EmailContactsChannel channel = new EmailContactsChannel();
        NotificationTypes.NotificationPayload payload = new NotificationTypes.NotificationPayload();
        NotificationTypes.RecipientBundle recipients = new NotificationTypes.RecipientBundle();
        recipients.contactIds.add(c.Id);
        NotificationTypes.NotificationEventCfg cfg = new NotificationTypes.NotificationEventCfg();
        cfg.templateApiName = 'Test_Template';

        Test.startTest();
        NotificationTypes.ChannelResult result = channel.send(payload, recipients, cfg);
        Test.stopTest();

        System.assertNotEquals(null, result);
    }

    @IsTest
    static void testSend_ContactWithoutEmail() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            createTemplate();
        }

        Contact c = [SELECT Id FROM Contact WHERE LastName = 'Email' AND Email = null LIMIT 1];

        EmailContactsChannel channel = new EmailContactsChannel();
        NotificationTypes.NotificationPayload payload = new NotificationTypes.NotificationPayload();
        NotificationTypes.RecipientBundle recipients = new NotificationTypes.RecipientBundle();
        recipients.contactIds.add(c.Id);
        NotificationTypes.NotificationEventCfg cfg = new NotificationTypes.NotificationEventCfg();
        cfg.templateApiName = 'Test_Template';

        Test.startTest();
        NotificationTypes.ChannelResult result = channel.send(payload, recipients, cfg);
        Test.stopTest();

        System.assertEquals(true, result.ok);
        System.assertEquals(0, result.sentCount);
        System.assert(result.message.contains('No eligible contacts'));
    }

    @IsTest
    static void testSend_ContactOptedOut() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            createTemplate();
        }

        Contact c = [SELECT Id FROM Contact WHERE Email = 'optedout@test.com' LIMIT 1];

        EmailContactsChannel channel = new EmailContactsChannel();
        NotificationTypes.NotificationPayload payload = new NotificationTypes.NotificationPayload();
        NotificationTypes.RecipientBundle recipients = new NotificationTypes.RecipientBundle();
        recipients.contactIds.add(c.Id);
        NotificationTypes.NotificationEventCfg cfg = new NotificationTypes.NotificationEventCfg();
        cfg.templateApiName = 'Test_Template';

        Test.startTest();
        NotificationTypes.ChannelResult result = channel.send(payload, recipients, cfg);
        Test.stopTest();

        System.assertEquals(true, result.ok);
        System.assertEquals(0, result.sentCount);
        System.assert(result.message.contains('No eligible contacts'));
    }

    @IsTest
    static void testSend_ContactBlankEmail() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            createTemplate();
        }

        Contact c = [SELECT Id FROM Contact WHERE LastName = 'Email' AND Email = '' LIMIT 1];

        EmailContactsChannel channel = new EmailContactsChannel();
        NotificationTypes.NotificationPayload payload = new NotificationTypes.NotificationPayload();
        NotificationTypes.RecipientBundle recipients = new NotificationTypes.RecipientBundle();
        recipients.contactIds.add(c.Id);
        NotificationTypes.NotificationEventCfg cfg = new NotificationTypes.NotificationEventCfg();
        cfg.templateApiName = 'Test_Template';

        Test.startTest();
        NotificationTypes.ChannelResult result = channel.send(payload, recipients, cfg);
        Test.stopTest();

        System.assertEquals(true, result.ok);
        System.assertEquals(0, result.sentCount);
    }

    @IsTest
    static void testSend_MixedContacts() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            createTemplate();
        }

        List<Contact> contacts = [SELECT Id FROM Contact];

        EmailContactsChannel channel = new EmailContactsChannel();
        NotificationTypes.NotificationPayload payload = new NotificationTypes.NotificationPayload();
        NotificationTypes.RecipientBundle recipients = new NotificationTypes.RecipientBundle();
        for (Contact c : contacts) {
            recipients.contactIds.add(c.Id);
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
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Contact c = [SELECT Id FROM Contact WHERE Email = 'valid@test.com' LIMIT 1];

        EmailContactsChannel channel = new EmailContactsChannel();
        NotificationTypes.NotificationPayload payload = new NotificationTypes.NotificationPayload();
        payload.context = acc;

        NotificationTypes.RecipientBundle recipients = new NotificationTypes.RecipientBundle();
        recipients.contactIds.add(c.Id);
        NotificationTypes.NotificationEventCfg cfg = new NotificationTypes.NotificationEventCfg();
        cfg.templateApiName = 'Test_Template';

        Test.startTest();
        NotificationTypes.ChannelResult result = channel.send(payload, recipients, cfg);
        Test.stopTest();

        System.assertNotEquals(null, result);
    }

    @IsTest
    static void testSend_NullPayload() {
        Contact c = [SELECT Id FROM Contact WHERE Email = 'valid@test.com' LIMIT 1];

        EmailContactsChannel channel = new EmailContactsChannel();
        NotificationTypes.RecipientBundle recipients = new NotificationTypes.RecipientBundle();
        recipients.contactIds.add(c.Id);
        NotificationTypes.NotificationEventCfg cfg = new NotificationTypes.NotificationEventCfg();
        cfg.templateApiName = 'Test_Template';

        Test.startTest();
        NotificationTypes.ChannelResult result = channel.send(null, recipients, cfg);
        Test.stopTest();

        System.assertNotEquals(null, result);
    }

    @IsTest
    static void testSend_SaveAsActivityTrue() {
        Contact c = [SELECT Id FROM Contact WHERE Email = 'valid@test.com' LIMIT 1];

        EmailContactsChannel channel = new EmailContactsChannel();
        NotificationTypes.NotificationPayload payload = new NotificationTypes.NotificationPayload();
        NotificationTypes.RecipientBundle recipients = new NotificationTypes.RecipientBundle();
        recipients.contactIds.add(c.Id);
        NotificationTypes.NotificationEventCfg cfg = new NotificationTypes.NotificationEventCfg();
        cfg.templateApiName = 'Test_Template';
        cfg.saveAsActivity = true;

        Test.startTest();
        NotificationTypes.ChannelResult result = channel.send(payload, recipients, cfg);
        Test.stopTest();

        System.assertNotEquals(null, result);
    }

    @IsTest
    static void testSend_SaveAsActivityFalse() {
        Contact c = [SELECT Id FROM Contact WHERE Email = 'valid@test.com' LIMIT 1];

        EmailContactsChannel channel = new EmailContactsChannel();
        NotificationTypes.NotificationPayload payload = new NotificationTypes.NotificationPayload();
        NotificationTypes.RecipientBundle recipients = new NotificationTypes.RecipientBundle();
        recipients.contactIds.add(c.Id);
        NotificationTypes.NotificationEventCfg cfg = new NotificationTypes.NotificationEventCfg();
        cfg.templateApiName = 'Test_Template';
        cfg.saveAsActivity = false;

        Test.startTest();
        NotificationTypes.ChannelResult result = channel.send(payload, recipients, cfg);
        Test.stopTest();

        System.assertNotEquals(null, result);
    }

    @IsTest
    static void testSend_TemplateCaching() {
        Contact c = [SELECT Id FROM Contact WHERE Email = 'valid@test.com' LIMIT 1];

        EmailContactsChannel channel = new EmailContactsChannel();
        NotificationTypes.NotificationPayload payload = new NotificationTypes.NotificationPayload();
        NotificationTypes.RecipientBundle recipients = new NotificationTypes.RecipientBundle();
        recipients.contactIds.add(c.Id);
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
        Contact c = [SELECT Id FROM Contact WHERE Email = 'valid@test.com' LIMIT 1];

        EmailContactsChannel channel = new EmailContactsChannel();
        NotificationTypes.NotificationPayload payload = new NotificationTypes.NotificationPayload();
        NotificationTypes.RecipientBundle recipients = new NotificationTypes.RecipientBundle();
        recipients.contactIds.add(c.Id);
        NotificationTypes.NotificationEventCfg cfg = new NotificationTypes.NotificationEventCfg();
        cfg.templateApiName = '   ';

        Test.startTest();
        NotificationTypes.ChannelResult result = channel.send(payload, recipients, cfg);
        Test.stopTest();

        System.assertEquals(false, result.ok);
    }

    @IsTest
    static void testSend_TemplateWithWhitespace() {
        Contact c = [SELECT Id FROM Contact WHERE Email = 'valid@test.com' LIMIT 1];

        EmailContactsChannel channel = new EmailContactsChannel();
        NotificationTypes.NotificationPayload payload = new NotificationTypes.NotificationPayload();
        NotificationTypes.RecipientBundle recipients = new NotificationTypes.RecipientBundle();
        recipients.contactIds.add(c.Id);
        NotificationTypes.NotificationEventCfg cfg = new NotificationTypes.NotificationEventCfg();
        cfg.templateApiName = '  Test_Template  ';

        Test.startTest();
        NotificationTypes.ChannelResult result = channel.send(payload, recipients, cfg);
        Test.stopTest();

        System.assertNotEquals(null, result);
    }

    @IsTest
    static void testSend_NullContactIdInList() {
        Contact c = [SELECT Id FROM Contact WHERE Email = 'valid@test.com' LIMIT 1];

        EmailContactsChannel channel = new EmailContactsChannel();
        NotificationTypes.NotificationPayload payload = new NotificationTypes.NotificationPayload();
        NotificationTypes.RecipientBundle recipients = new NotificationTypes.RecipientBundle();
        recipients.contactIds.add(c.Id);
        recipients.contactIds.add(null);
        recipients.contactIds.add(c.Id);
        NotificationTypes.NotificationEventCfg cfg = new NotificationTypes.NotificationEventCfg();
        cfg.templateApiName = 'Test_Template';

        Test.startTest();
        NotificationTypes.ChannelResult result = channel.send(payload, recipients, cfg);
        Test.stopTest();

        System.assertNotEquals(null, result);
    }

    @IsTest
    static void testSend_NullConfig() {
        Contact c = [SELECT Id FROM Contact WHERE Email = 'valid@test.com' LIMIT 1];

        EmailContactsChannel channel = new EmailContactsChannel();
        NotificationTypes.NotificationPayload payload = new NotificationTypes.NotificationPayload();
        NotificationTypes.RecipientBundle recipients = new NotificationTypes.RecipientBundle();
        recipients.contactIds.add(c.Id);

        Test.startTest();
        NotificationTypes.ChannelResult result = channel.send(payload, recipients, null);
        Test.stopTest();

        System.assertEquals(false, result.ok);
    }

    @IsTest
    static void testSend_ContextWithoutId() {
        Contact c = [SELECT Id FROM Contact WHERE Email = 'valid@test.com' LIMIT 1];

        EmailContactsChannel channel = new EmailContactsChannel();
        NotificationTypes.NotificationPayload payload = new NotificationTypes.NotificationPayload();
        payload.context = new Account(Name = 'No Id');

        NotificationTypes.RecipientBundle recipients = new NotificationTypes.RecipientBundle();
        recipients.contactIds.add(c.Id);
        NotificationTypes.NotificationEventCfg cfg = new NotificationTypes.NotificationEventCfg();
        cfg.templateApiName = 'Test_Template';

        Test.startTest();
        NotificationTypes.ChannelResult result = channel.send(payload, recipients, cfg);
        Test.stopTest();

        System.assertNotEquals(null, result);
    }
}