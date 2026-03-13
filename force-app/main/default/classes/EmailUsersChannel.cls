public with sharing class EmailUsersChannel implements NotificationChannel {

    private static Map<String, Id> templateIdByApiName = new Map<String, Id>();

    /** Відправляє email юзерам через EmailTemplate (cfg.templateApiName). Підтримує WhatId як context.Id, якщо є. */
    public NotificationTypes.ChannelResult send(
            NotificationTypes.NotificationPayload payload,
            NotificationTypes.RecipientBundle recipients,
            NotificationTypes.NotificationEventCfg cfg
    ) {
        if (recipients == null || recipients.userIds == null || recipients.userIds.isEmpty()) {
            NotificationTypes.ChannelResult r = new NotificationTypes.ChannelResult();
            r.ok = true;
            r.sentCount = 0;
            r.message = 'No user recipients';
            return r;
        }

        if (cfg == null || String.isBlank(cfg.templateApiName)) {
            NotificationTypes.ChannelResult r = new NotificationTypes.ChannelResult();
            r.ok = false;
            r.sentCount = 0;
            r.message = 'TemplateApiName is blank for EmailUsers channel';
            return r;
        }

        Id templateId;
        try {
            templateId = getTemplateId(cfg.templateApiName);
        } catch (Exception e) {
            NotificationTypes.ChannelResult r = new NotificationTypes.ChannelResult();
            r.ok = false;
            r.sentCount = 0;
            r.message = 'Template lookup failed: ' + e.getMessage();
            return r;
        }

        Id whatId = extractContextId(payload);

        List<Messaging.SingleEmailMessage> buffer = new List<Messaging.SingleEmailMessage>();
        Integer sentOk = 0;
        List<String> errors = new List<String>();

        try {
            for (Id userId : recipients.userIds) {
                if (userId == null) continue;

                Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();
                msg.setTargetObjectId(userId);
                msg.setTemplateId(templateId);

                // Salesforce обмеження: WhatId НЕ підтримується для Users (тільки для Contacts)
                // Також для Users saveAsActivity завжди має бути false
                msg.setSaveAsActivity(false);

                buffer.add(msg);

                if (buffer.size() == 10) {
                    SendBatchResult br = sendBatch(buffer);
                    sentOk += br.successCount;
                    errors.addAll(br.errors);
                    buffer.clear();
                }
            }

            if (!buffer.isEmpty()) {
                SendBatchResult br = sendBatch(buffer);
                sentOk += br.successCount;
                errors.addAll(br.errors);
                buffer.clear();
            }
        } catch (Exception e) {
            NotificationTypes.ChannelResult r = new NotificationTypes.ChannelResult();
            r.ok = false;
            r.sentCount = sentOk;
            r.message = 'EmailUsers send failed: ' + e.getMessage();
            return r;
        }

        NotificationTypes.ChannelResult r = new NotificationTypes.ChannelResult();
        r.sentCount = sentOk;

        if (errors.isEmpty()) {
            r.ok = true;
        } else if (sentOk > 0) {
            r.ok = false;
            r.message = String.join(trimToMax(errors, 10), ' | ');
        } else {
            r.ok = false;
            r.message = String.join(trimToMax(errors, 10), ' | ');
        }

        return r;
    }

    /** Дістає Id контекстного запису (payload.context.Id), якщо передано. */
    private static Id extractContextId(NotificationTypes.NotificationPayload payload) {
        if (payload == null || payload.context == null) {
            return null;
        }
        Object idVal = payload.context.get('Id');
        if (idVal == null) {
            return null;
        }
        try {
            return (Id) idVal;
        } catch (Exception e) {
            return null;
        }
    }

    /** Повертає Id EmailTemplate за API name (DeveloperName). Кешує результат у межах транзакції. */
    private static Id getTemplateId(String templateApiName) {
        String key = safeTrim(templateApiName);
        if (String.isBlank(key)) {
            throw new TemplateNotFoundException('Blank templateApiName');
        }

        if (templateIdByApiName.containsKey(key)) {
            Id cached = templateIdByApiName.get(key);
            if (cached == null) {
                throw new TemplateNotFoundException('EmailTemplate not found: ' + key);
            }
            return cached;
        }

        List<EmailTemplate> t = [
                SELECT Id
                FROM EmailTemplate
                WHERE DeveloperName = :key
                LIMIT 1
        ];

        Id found = t.isEmpty() ? null : t[0].Id;
        templateIdByApiName.put(key, found);

        if (found == null) {
            throw new TemplateNotFoundException('EmailTemplate not found: ' + key);
        }
        return found;
    }

    /** Відправляє пачку SingleEmailMessage і повертає підсумок (скільки успішно і які помилки). */
    private static SendBatchResult sendBatch(List<Messaging.SingleEmailMessage> msgs) {
        SendBatchResult br = new SendBatchResult();
        br.successCount = 0;
        br.errors = new List<String>();

        if (msgs == null || msgs.isEmpty()) {
            return br;
        }

        List<Messaging.SendEmailResult> results = Messaging.sendEmail(msgs, false);
        for (Integer i = 0; i < results.size(); i++) {
            Messaging.SendEmailResult r = results[i];
            if (r != null && r.isSuccess()) {
                br.successCount++;
            } else {
                if (r != null && r.getErrors() != null && !r.getErrors().isEmpty()) {
                    br.errors.add(r.getErrors()[0].getMessage());
                } else {
                    br.errors.add('Unknown email send error');
                }
            }
        }

        return br;
    }

    /** Обрізає список помилок до maxItems, щоб не роздувати логи/повідомлення. */
    private static List<String> trimToMax(List<String> items, Integer maxItems) {
        if (items == null || items.isEmpty() || maxItems == null || maxItems <= 0) {
            return new List<String>();
        }
        if (items.size() <= maxItems) {
            return items;
        }
        List<String> out = new List<String>();
        for (Integer i = 0; i < maxItems; i++) {
            out.add(items[i]);
        }
        return out;
    }

    /** Безпечний trim для String. */
    private static String safeTrim(String s) {
        return (s == null) ? null : s.trim();
    }

    private class SendBatchResult {
        public Integer successCount;
        public List<String> errors;
    }

    public class TemplateNotFoundException extends Exception {}
}