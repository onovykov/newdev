public with sharing class NotificationLogRepo {

    /** Створює запис Notification_Log__c для результату відправки (Sent/Failed/PartiallyFailed/Queued/SkippedNoRecipients). */
    public static void save(
            NotificationTypes.NotificationPayload p,
            NotificationTypes.NotificationEventCfg cfg,
            NotificationTypes.RecipientBundle rb,
            NotificationTypes.ChannelResult res
    ) {
        Notification_Log__c rec = buildBase(p, cfg, rb);

        if (res == null) {
            rec.Status__c = 'Queued';
        } else if (res.ok == true && safeInt(res.sentCount) > 0) {
            rec.Status__c = 'Sent';
        } else if (res.ok == true && safeInt(res.sentCount) == 0) {
            rec.Status__c = 'SkippedNoRecipients';
        } else if (res.ok == false && safeInt(res.sentCount) > 0) {
            rec.Status__c = 'PartiallyFailed';
        } else {
            rec.Status__c = 'Failed';
        }

        if (res != null && !String.isBlank(res.message)) {
            rec.ResolverTrace__c = appendTrace(rec.ResolverTrace__c, 'Channel: ' + res.message);
        }

        insert rec;
    }

    /** Логує, що подія була задушена throttling’ом. */
    public static void logThrottled(
            NotificationTypes.NotificationPayload p,
            NotificationTypes.NotificationEventCfg cfg,
            NotificationTypes.RecipientBundle rb
    ) {
        Notification_Log__c rec = buildBase(p, cfg, rb);
        rec.Status__c = 'Throttled';
        insert rec;
    }

    /** Логує, що отримувачів немає (і відправка не виконується). */
    public static void logNoRecipients(
            NotificationTypes.NotificationPayload p,
            NotificationTypes.NotificationEventCfg cfg,
            NotificationTypes.RecipientBundle rb
    ) {
        Notification_Log__c rec = buildBase(p, cfg, rb);
        rec.Status__c = 'SkippedNoRecipients';
        insert rec;
    }

    /** Формує “базовий” запис Notification_Log__c з контекстом, каналом, fingerprint, recipients count, resolver trace. */
    private static Notification_Log__c buildBase(
            NotificationTypes.NotificationPayload p,
            NotificationTypes.NotificationEventCfg cfg,
            NotificationTypes.RecipientBundle rb
    ) {
        Notification_Log__c rec = new Notification_Log__c();
        rec.EventKey__c = (p == null) ? null : p.eventKey;
        rec.Channel__c = (cfg == null) ? null : cfg.channel;

        if (p != null && p.context != null) {
            rec.ContextSObjectType__c = String.valueOf(p.context.getSObjectType());

            Object idVal = p.context.get('Id');
            if (idVal != null) {
                rec.ContextRecordId__c = String.valueOf(idVal);
            }
        }

        rec.RecipientsCount__c = countRecipients(rb);
        rec.Fingerprint__c = FingerprintUtil.build(p, cfg);

        if (rb != null && !String.isBlank(rb.resolverTrace)) {
            rec.ResolverTrace__c = rb.resolverTrace;
        }

        return rec;
    }

    /** Повертає кількість всіх отримувачів в bundle. */
    private static Integer countRecipients(NotificationTypes.RecipientBundle rb) {
        if (rb == null) return 0;

        Integer c = 0;
        if (rb.userIds != null) c += rb.userIds.size();
        if (rb.contactIds != null) c += rb.contactIds.size();
        if (rb.emails != null) c += rb.emails.size();
        return c;
    }

    /** Безпечне перетворення Integer (null -> 0). */
    private static Integer safeInt(Integer v) {
        return (v == null) ? 0 : v;
    }

    /** Додає рядок до ResolverTrace__c (обережно, щоб не переповнити поле). */
    private static String appendTrace(String existing, String addition) {
        String base = (existing == null) ? '' : existing;
        String add = (addition == null) ? '' : addition;

        String joined = String.isBlank(base) ? add : (base + ' | ' + add);

        Integer maxLen = 32768;
        if (joined != null && joined.length() > maxLen) {
            joined = joined.substring(0, maxLen);
        }
        return joined;
    }
}