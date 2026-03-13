public with sharing class FingerprintUtil {

    /** Будує стабільний fingerprint для події: eventKey + channel + context type/id + (опційно) важливі vars. */
    public static String build(
            NotificationTypes.NotificationPayload p,
            NotificationTypes.NotificationEventCfg cfg
    ) {
        String eventKey = (p == null) ? null : p.eventKey;
        String channel = (cfg == null) ? null : cfg.channel;

        String ctxType = null;
        String ctxId = null;

        if (p != null && p.context != null) {
            ctxType = String.valueOf(p.context.getSObjectType());
            Object idVal = p.context.get('Id');
            if (idVal != null) {
                ctxId = String.valueOf(idVal);
            }
        }

        // vars у fingerprint не включаємо "все підряд", інакше ключ буде нестабільний.
        // Беремо event+channel+context+recipientGroups для унікальності.
        String recipientGroups = '';
        if (cfg != null && cfg.recipientGroupKeys != null && !cfg.recipientGroupKeys.isEmpty()) {
            List<String> sorted = new List<String>(cfg.recipientGroupKeys);
            sorted.sort();
            recipientGroups = String.join(sorted, ',');
        }

        String raw = safe(eventKey) + '|' + safe(channel) + '|' + safe(ctxType) + '|' + safe(ctxId) + '|' + safe(recipientGroups);

        // Хешуємо, щоб влізти у 255 і не світити зайве в логах
        Blob b = Blob.valueOf(raw);
        String hashHex = EncodingUtil.convertToHex(Crypto.generateDigest('SHA-256', b));

        return hashHex;
    }

    private static String safe(String s) {
        return (s == null) ? '' : s.trim();
    }
}