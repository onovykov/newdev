@IsTest
private class ChannelFactoryTest {

    @IsTest
    static void testGet_EmailUsers() {
        Test.startTest();
        NotificationChannel channel = ChannelFactory.get('EmailUsers');
        Test.stopTest();

        System.assertNotEquals(null, channel);
        System.assert(channel instanceof EmailUsersChannel);
    }

    @IsTest
    static void testGet_EmailContacts() {
        Test.startTest();
        NotificationChannel channel = ChannelFactory.get('EmailContacts');
        Test.stopTest();

        System.assertNotEquals(null, channel);
        System.assert(channel instanceof EmailContactsChannel);
    }

    @IsTest
    static void testGet_EmailRaw() {
        Test.startTest();
        NotificationChannel channel = ChannelFactory.get('EmailRaw');
        Test.stopTest();

        System.assertNotEquals(null, channel);
        System.assert(channel instanceof EmailRawChannel);
    }

    @IsTest
    static void testGet_Slack() {
        Test.startTest();
        NotificationChannel channel = ChannelFactory.get('Slack');
        Test.stopTest();

        System.assertNotEquals(null, channel);
        System.assert(channel instanceof SlackChannel);
    }

    @IsTest
    static void testGet_Webhook() {
        Test.startTest();
        NotificationChannel channel = ChannelFactory.get('Webhook');
        Test.stopTest();

        System.assertNotEquals(null, channel);
        System.assert(channel instanceof WebhookChannel);
    }

    @IsTest
    static void testGet_UnsupportedChannel() {
        Test.startTest();
        try {
            ChannelFactory.get('UnknownChannel');
            System.assert(false, 'Should throw exception');
        } catch (ChannelFactory.NotificationServiceException e) {
            System.assert(e.getMessage().contains('Unsupported channel'));
        }
        Test.stopTest();
    }

    @IsTest
    static void testGet_NullChannel() {
        Test.startTest();
        try {
            ChannelFactory.get(null);
            System.assert(false, 'Should throw exception');
        } catch (ChannelFactory.NotificationServiceException e) {
            System.assertNotEquals(null, e);
        }
        Test.stopTest();
    }

    @IsTest
    static void testGet_BlankChannel() {
        Test.startTest();
        try {
            ChannelFactory.get('   ');
            System.assert(false, 'Should throw exception');
        } catch (ChannelFactory.NotificationServiceException e) {
            System.assertNotEquals(null, e);
        }
        Test.stopTest();
    }

    @IsTest
    static void testGet_EmptyChannel() {
        Test.startTest();
        try {
            ChannelFactory.get('');
            System.assert(false, 'Should throw exception');
        } catch (ChannelFactory.NotificationServiceException e) {
            System.assertNotEquals(null, e);
        }
        Test.stopTest();
    }

    @IsTest
    static void testGet_WithWhitespace() {
        Test.startTest();
        NotificationChannel channel = ChannelFactory.get('  EmailUsers  ');
        Test.stopTest();

        System.assertNotEquals(null, channel);
        System.assert(channel instanceof EmailUsersChannel);
    }

    @IsTest
    static void testGet_CaseSensitive() {
        Test.startTest();
        try {
            ChannelFactory.get('emailusers');
            System.assert(false, 'Should be case sensitive');
        } catch (ChannelFactory.NotificationServiceException e) {
            System.assert(e.getMessage().contains('Unsupported channel'));
        }
        Test.stopTest();
    }

    @IsTest
    static void testGet_AllChannels() {
        List<String> channelNames = new List<String>{
            'EmailUsers', 'EmailContacts', 'EmailRaw', 'Slack', 'Webhook'
        };

        Test.startTest();
        for (String name : channelNames) {
            NotificationChannel channel = ChannelFactory.get(name);
            System.assertNotEquals(null, channel, 'Channel should be created: ' + name);
        }
        Test.stopTest();
    }

    @IsTest
    static void testGet_MultipleCallsSameChannel() {
        Test.startTest();
        NotificationChannel channel1 = ChannelFactory.get('EmailUsers');
        NotificationChannel channel2 = ChannelFactory.get('EmailUsers');
        Test.stopTest();

        System.assertNotEquals(null, channel1);
        System.assertNotEquals(null, channel2);
        System.assertNotEquals(channel1, channel2, 'Should create new instances');
    }
}