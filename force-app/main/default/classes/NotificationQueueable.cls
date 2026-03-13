public with sharing class NotificationQueueable
        implements Queueable, Database.AllowsCallouts {

    private final NotificationTypes.NotificationPayload payload;
    private final NotificationTypes.RecipientBundle recipients;
    private final NotificationTypes.NotificationEventCfg cfg;

    /** Створює асинхронну задачу відправки нотифікацій. */
    public NotificationQueueable(
            NotificationTypes.NotificationPayload payload,
            NotificationTypes.RecipientBundle recipients,
            NotificationTypes.NotificationEventCfg cfg
    ) {
        this.payload = payload;
        this.recipients = recipients;
        this.cfg = cfg;
    }

    /** Головний execute: дробить отримувачів, відправляє по каналу і логує результат. */
    public void execute(QueueableContext context) {

        if (recipients == null ||
            (recipients.userIds.isEmpty() && recipients.contactIds.isEmpty() && recipients.emails.isEmpty()) ||
            cfg == null) {
            NotificationLogRepo.logNoRecipients(payload, cfg, recipients);
            return;
        }

        Integer batchSize = (cfg.batchSize == null || cfg.batchSize <= 0)
                ? 100
                : cfg.batchSize;

        List<NotificationTypes.RecipientBundle> chunks =
                RecipientChunker.split(recipients, batchSize);

        NotificationChannel channel = ChannelFactory.get(cfg.channel);

        for (NotificationTypes.RecipientBundle chunk : chunks) {
            NotificationTypes.ChannelResult result;

            try {
                result = channel.send(payload, chunk, cfg);
            } catch (Exception e) {
                result = new NotificationTypes.ChannelResult();
                result.ok = false;
                result.message = e.getMessage();
                result.sentCount = 0;
            }

            NotificationLogRepo.save(payload, cfg, chunk, result);
        }
    }
}