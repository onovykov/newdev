public with sharing class OppDataErrorNotifier implements Queueable {

    private OppDataErrors errors;
    private String rawPayload;

    public OppDataErrorNotifier(OppDataErrors errors, String rawPayload) {
        this.errors = errors;
        this.rawPayload = rawPayload;
    }

    public void execute(QueueableContext qc) {
        try {
            if (errors == null || !errors.hasErrors()) {
                return;
            }

            // 1. Resolve recipients
            IntegrationErrorContext ctx = new IntegrationErrorContext();
            ctx.salesRepEmail = errors.salesRepEmail;
            ctx.bosEmail = errors.bosEmail;
            ctx.messageType = 'OpportunityData';
            ctx.iteNumber = errors.iteNumber;

            Set<String> recipients =
                IntegrationErrorRecipientResolver.resolve(ctx);

            if (recipients.isEmpty()) {
                System.debug('No recipients resolved, skipping notification');
                return;
            }

            // 2. Save payload as File (ContentVersion)
            Id contentVersionId = savePayloadToFile();

            // 3. Build email
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new List<String>(recipients));
            email.setSubject(buildSubject());
            email.setPlainTextBody(buildBody(contentVersionId));

            // 4. Send email
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });

            // 5. Logging (basic)
            logSuccess(recipients, contentVersionId);

            // 6. Triton stub
            // TODO: Must be log into Triton
            // Example future call:
            // TritonLogSink.log(errors, contentVersionId);

        } catch (Exception e) {
            System.debug('OppDataErrorNotifier failed: ' + e.getMessage());
        }
    }

    // -------------------------
    // Payload → ContentVersion
    // -------------------------

    private Id savePayloadToFile() {
        if (String.isBlank(rawPayload)) {
            return null;
        }

        ContentVersion cv = new ContentVersion();
        cv.Title = buildFileName();
        cv.PathOnClient = buildFileName() + '.json';
        cv.VersionData = Blob.valueOf(rawPayload);

        insert cv;

        return cv.Id;
    }

    private String buildFileName() {
        String ite = errors.iteNumber != null ? errors.iteNumber : 'UNKNOWN';
        return 'OppSyncPayload_' + ite;
    }

    // -------------------------
    // Email
    // -------------------------

    private String buildSubject() {
        return 'Opportunity Sync Error';
    }

    private String buildBody(Id contentVersionId) {
        String body = '';

        body += 'Errors occurred while synchronizing the order:\n\n';

        body += safe(errors.altNumber)
             + ' ('
             + safe(errors.iteNumber)
             + ')\n\n';

        body += 'Errors:\n';

        Integer i = 1;
        for (String err : errors.errors) {
            body += i + ') ' + err + '\n';
            i++;
        }

        // optional warnings
        if (errors.warnings != null && !errors.warnings.isEmpty()) {
            body += '\nWarnings:\n';
            i = 1;
            for (String warn : errors.warnings) {
                body += i + ') ' + warn + '\n';
                i++;
            }
        }

        // payload reference
        if (contentVersionId != null) {
            body += '\nPayload saved as File (ContentVersion Id): '
                 + contentVersionId + '\n';
        }

        // debug context
        body += '\n---\n';
        body += 'MessageType: OpportunityData\n';
        body += 'Timestamp: ' + String.valueOf(System.now()) + '\n';
        body += 'CorrelationId: ' + (errors.correlationId != null ? errors.correlationId : 'N/A') + '\n';

        return body;
    }

    private String safe(String val) {
        return String.isBlank(val) ? 'N/A' : val.trim();
    }

    // -------------------------
    // Logging
    // -------------------------

    private void logSuccess(Set<String> recipients, Id contentVersionId) {
        System.debug('OppDataErrorNotifier sent to: ' + recipients);
        System.debug('Payload file: ' + contentVersionId);
    }
}