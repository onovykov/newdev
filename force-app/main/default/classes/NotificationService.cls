public with sharing class NotificationService {

    @TestVisible
    private static IDeps deps = new RealDeps();

    /** Дозволяє тестам підмінити залежності. */
    @TestVisible
    static void setDepsForTest(IDeps d) {
        deps = (d == null) ? new RealDeps() : d;
    }

    public interface IDeps {
        NotificationTypes.NotificationEventCfg getEventCfg(String eventKey);
        NotificationTypes.RecipientBundle resolveRecipients(NotificationTypes.NotificationEventCfg cfg, SObject context);
        String buildFingerprint(NotificationTypes.NotificationPayload payload, NotificationTypes.NotificationEventCfg cfg);
        Boolean isThrottled(String fingerprint, Integer throttleMinutes);

        void logThrottled(NotificationTypes.NotificationPayload payload,
                NotificationTypes.NotificationEventCfg cfg,
                NotificationTypes.RecipientBundle recipients);

        void logNoRecipients(NotificationTypes.NotificationPayload payload,
                NotificationTypes.NotificationEventCfg cfg,
                NotificationTypes.RecipientBundle recipients);

        Id enqueue(NotificationTypes.NotificationPayload payload,
                NotificationTypes.RecipientBundle recipients,
                NotificationTypes.NotificationEventCfg cfg);
    }

    private class RealDeps implements IDeps {
        public NotificationTypes.NotificationEventCfg getEventCfg(String eventKey) {
            return NotificationConfigRepo.getEventCfg(eventKey);
        }
        public NotificationTypes.RecipientBundle resolveRecipients(NotificationTypes.NotificationEventCfg cfg, SObject context) {
            return RecipientResolver.resolve(cfg, context);
        }
        public String buildFingerprint(NotificationTypes.NotificationPayload payload, NotificationTypes.NotificationEventCfg cfg) {
            return FingerprintUtil.build(payload, cfg);
        }
        public Boolean isThrottled(String fingerprint, Integer throttleMinutes) {
            return ThrottleGuard.isThrottled(fingerprint, throttleMinutes);
        }
        public void logThrottled(NotificationTypes.NotificationPayload payload,
                NotificationTypes.NotificationEventCfg cfg,
                NotificationTypes.RecipientBundle recipients) {
            NotificationLogRepo.logThrottled(payload, cfg, recipients);
        }
        public void logNoRecipients(NotificationTypes.NotificationPayload payload,
                NotificationTypes.NotificationEventCfg cfg,
                NotificationTypes.RecipientBundle recipients) {
            NotificationLogRepo.logNoRecipients(payload, cfg, recipients);
        }
        public Id enqueue(NotificationTypes.NotificationPayload payload,
                NotificationTypes.RecipientBundle recipients,
                NotificationTypes.NotificationEventCfg cfg) {
            return System.enqueueJob(new NotificationQueueable(payload, recipients, cfg));
        }
    }

    /** Єдина точка входу: викликається з коду/тригерів/батчів/інтеграцій (в т.ч. Pharos). */
    public static void notify(String eventKey, SObject context, Map<String, Object> vars) {

        if (String.isBlank(eventKey)) {
            return;
        }

        NotificationTypes.NotificationPayload payload =
                new NotificationTypes.NotificationPayload(eventKey.trim(), context, vars);

        NotificationTypes.NotificationEventCfg cfg =
                deps.getEventCfg(payload.eventKey);

        if (cfg == null || cfg.active != true) {
            return;
        }

        NotificationTypes.RecipientBundle recipients =
                deps.resolveRecipients(cfg, context);

        // Fingerprint для логу + throttling
        String fingerprint = deps.buildFingerprint(payload, cfg);

        // Throttle
        if (deps.isThrottled(fingerprint, cfg.throttleMinutes)) {
            deps.logThrottled(payload, cfg, recipients);
            return;
        }

        // Якщо немає отримувачів — лог і вихід
        if (isEmptyRecipients(recipients)) {
            deps.logNoRecipients(payload, cfg, recipients);
            return;
        }

        // Асинхронна відправка
        deps.enqueue(payload, recipients, cfg);
    }

    /** Перевіряє, чи RecipientBundle порожній (без залежності від методів у RecipientBundle). */
    private static Boolean isEmptyRecipients(NotificationTypes.RecipientBundle r) {
        if (r == null) return true;

        Boolean noUsers = (r.userIds == null || r.userIds.isEmpty());
        Boolean noContacts = (r.contactIds == null || r.contactIds.isEmpty());
        Boolean noEmails = (r.emails == null || r.emails.isEmpty());

        return noUsers && noContacts && noEmails;
    }
}