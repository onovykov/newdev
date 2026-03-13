public interface NotificationChannel {
    NotificationTypes.ChannelResult send(
        NotificationTypes.NotificationPayload payload,
        NotificationTypes.RecipientBundle recipients,
        NotificationTypes.NotificationEventCfg cfg
    );
}