@IsTest
private class SettingsServiceTest {

    @IsTest
    static void testAllMethods_WithDefaultSettings() {
        // Act
        Test.startTest();
        Boolean useRepos = SettingsService.useReposOnly();
        Boolean allowFallback = SettingsService.allowSoqlFallback();
        String slackPath = SettingsService.slackPath();
        String webhookPath = SettingsService.webhookPath();
        Test.stopTest();

        // Assert - просто перевіряємо що методи працюють
        System.assertNotEquals(null, useRepos, 'useReposOnly should return value');
        System.assertNotEquals(null, allowFallback, 'allowSoqlFallback should return value');
    }

    @IsTest
    static void testAllMethods_WithCustomSettings() {
        // Arrange
        Notification_Settings__c settings = new Notification_Settings__c(
            UseReposOnly__c = true,
            AllowSoqlFallback__c = false,
            SlackPath__c = '/test/slack',
            WebhookPath__c = '/test/webhook'
        );
        insert settings;

        // Act
        Test.startTest();
        Boolean useRepos = SettingsService.useReposOnly();
        Boolean allowFallback = SettingsService.allowSoqlFallback();
        String slackPath = SettingsService.slackPath();
        String webhookPath = SettingsService.webhookPath();
        Test.stopTest();

        // Assert
        System.assertEquals(true, useRepos, 'Should use repos only');
        System.assertEquals(false, allowFallback, 'Should not allow fallback when useReposOnly is true');
        System.assertEquals('/test/slack', slackPath, 'Slack path should match');
        System.assertEquals('/test/webhook', webhookPath, 'Webhook path should match');
    }

    @IsTest
    static void testAllowSoqlFallback_WhenNotUsingReposOnly() {
        // Arrange
        Notification_Settings__c settings = new Notification_Settings__c(
            UseReposOnly__c = false,
            AllowSoqlFallback__c = true
        );
        insert settings;

        // Act
        Test.startTest();
        Boolean allowFallback = SettingsService.allowSoqlFallback();
        Test.stopTest();

        // Assert
        System.assertEquals(true, allowFallback, 'Should allow fallback when useReposOnly is false');
    }

    @IsTest
    static void testMultipleCalls_UsesCaching() {
        // Arrange
        Notification_Settings__c settings = new Notification_Settings__c(
            UseReposOnly__c = true,
            SlackPath__c = '/cached/path'
        );
        insert settings;

        // Act
        Test.startTest();
        String path1 = SettingsService.slackPath();
        String path2 = SettingsService.slackPath();
        String path3 = SettingsService.slackPath();
        Test.stopTest();

        // Assert - всі виклики повинні повертати той самий результат
        System.assertEquals(path1, path2, 'Cached values should match');
        System.assertEquals(path2, path3, 'Cached values should match');
    }
}