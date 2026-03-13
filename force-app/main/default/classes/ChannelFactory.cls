public with sharing class ChannelFactory {

    /** Повертає реалізацію NotificationChannel за назвою каналу з конфіга (cfg.channel). */
    public static NotificationChannel get(String channelName) {
        String c = safeTrim(channelName);
        if (c == null) throw new NotificationServiceException('Unsupported channel: null');

        // Метод .equals() чутливий до регістру
        if (c.equals('EmailUsers'))   return new EmailUsersChannel();
        if (c.equals('EmailContacts')) return new EmailContactsChannel();
        if (c.equals('EmailRaw'))     return new EmailRawChannel();
        if (c.equals('Slack'))        return new SlackChannel();
        if (c.equals('Webhook'))      return new WebhookChannel();

        throw new NotificationServiceException('Unsupported channel: ' + channelName);
    }

    /** Безпечний trim для String. */
    private static String safeTrim(String s) {
        return (s == null) ? null : s.trim();
    }

    public class NotificationServiceException extends Exception {}
}