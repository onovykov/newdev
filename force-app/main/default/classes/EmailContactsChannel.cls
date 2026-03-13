public with sharing class EmailContactsChannel implements NotificationChannel {

    private static Map<String, Id> templateIdByApiName = new Map<String, Id>();

    /** Відправляє email контактам через EmailTemplate (cfg.templateApiName). Підтримує WhatId як context.Id, якщо є. */
    public NotificationTypes.ChannelResult send(
            NotificationTypes.NotificationPayload payload,
            NotificationTypes.RecipientBundle recipients,
            NotificationTypes.NotificationEventCfg cfg
    ) {
        if (recipients == null || recipients.contactIds == null || recipients.contactIds.isEmpty()) {
            NotificationTypes.ChannelResult r = new NotificationTypes.ChannelResult();
            r.ok = true;
            r.sentCount = 0;
            r.message = 'No contact recipients';
            return r;
        }

        if (cfg == null || String.isBlank(cfg.templateApiName)) {
            NotificationTypes.ChannelResult r = new NotificationTypes.ChannelResult();
            r.ok = false;
            r.sentCount = 0;
            r.message = 'TemplateApiName is blank for EmailContacts channel';
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

        // Фільтруємо контакти: тільки ті, хто має Email і не Opted Out
        Set<Id> eligible = new Set<Id>();
        List<Contact> contacts = [
                SELECT Id, Email, HasOptedOutOfEmail
                FROM Contact
                WHERE Id IN :recipients.contactIds
        ];
        for (Contact c : contacts) {
            if (!String.isBlank(c.Email) && c.HasOptedOutOfEmail != true) {
                eligible.add(c.Id);
            }
        }

        if (eligible.isEmpty()) {
            NotificationTypes.ChannelResult r = new NotificationTypes.ChannelResult();
            r.ok = true;
            r.sentCount = 0;
            r.message = 'No eligible contacts (blank email or opted out)';
            return r;
        }

        Id whatId = extractContextId(payload);
        System.debug('EmailContactsChannel: Extracted WhatId = ' + whatId);
        System.debug('EmailContactsChannel: TemplateId = ' + templateId);
        System.debug('EmailContactsChannel: Eligible contacts = ' + eligible.size());

        List<Messaging.SingleEmailMessage> buffer = new List<Messaging.SingleEmailMessage>();
        Integer sentOk = 0;
        List<String> errors = new List<String>();

        try {
            for (Id contactId : eligible) {
                if (contactId == null) continue;

                Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();
                msg.setTargetObjectId(contactId);
                msg.setTemplateId(templateId);

                if (whatId != null) {
                    System.debug('EmailContactsChannel: Setting WhatId = ' + whatId + ' for Contact = ' + contactId);
                    msg.setWhatId(whatId);
                } else {
                    System.debug('EmailContactsChannel: WhatId is NULL - skipping setWhatId');
                }

                msg.setSaveAsActivity(cfg.saveAsActivity == true);

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
            r.message = 'EmailContacts send failed: ' + e.getMessage();
            return r;
        }

        NotificationTypes.ChannelResult r = new NotificationTypes.ChannelResult();
        r.sentCount = sentOk;

        if (errors.isEmpty()) {
            r.ok = true;
        } else {
            r.ok = false;
            r.message = String.join(trimToMax(errors, 10), ' | ');
        }

        return r;
    }

    /** Дістає Id контекстного запису для WhatId в Email Template.
     * Пріоритет: vars.workItemId → vars.pharosLogId → context.Id
     */
    private static Id extractContextId(NotificationTypes.NotificationPayload payload) {
        if (payload == null) {
            System.debug('extractContextId: payload is null');
            return null;
        }

        // Пріоритет 1: vars.workItemId (для escalation - Notification_Work_Item__c)
        System.debug('extractContextId: Checking vars.workItemId');
        if (payload.vars != null && payload.vars.containsKey('workItemId')) {
            Object workItemIdVal = payload.vars.get('workItemId');
            System.debug('extractContextId: Found workItemId in vars = ' + workItemIdVal);
            if (workItemIdVal != null) {
                try {
                    Id result = (Id) workItemIdVal;
                    System.debug('extractContextId: Returning workItemId = ' + result);
                    return result;
                } catch (Exception e) {
                    System.debug('extractContextId: Failed to cast workItemId: ' + e.getMessage());
                }
            }
        }

        // Пріоритет 2: vars.pharosLogId (для SYSTEM_CALLOUT - pharos__Log__c)
        System.debug('extractContextId: Checking vars.pharosLogId');
        if (payload.vars != null && payload.vars.containsKey('pharosLogId')) {
            Object pharosIdVal = payload.vars.get('pharosLogId');
            System.debug('extractContextId: Found pharosLogId in vars = ' + pharosIdVal);
            if (pharosIdVal != null) {
                try {
                    Id result = (Id) pharosIdVal;
                    System.debug('extractContextId: Returning pharosLogId = ' + result);
                    return result;
                } catch (Exception e) {
                    System.debug('extractContextId: Failed to cast pharosLogId: ' + e.getMessage());
                }
            }
        }

        // Пріоритет 3: payload.context.Id (fallback)
        System.debug('extractContextId: Checking payload.context.Id');
        if (payload.context == null) {
            System.debug('extractContextId: context is null');
            return null;
        }
        Object idVal = payload.context.get('Id');
        System.debug('extractContextId: context.Id = ' + idVal);
        if (idVal == null) {
            return null;
        }
        try {
            Id result = (Id) idVal;
            System.debug('extractContextId: Returning context.Id = ' + result);
            return result;
        } catch (Exception e) {
            System.debug('extractContextId: Failed to cast context.Id: ' + e.getMessage());
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