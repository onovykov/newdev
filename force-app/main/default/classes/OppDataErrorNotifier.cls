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
                System.debug('No recipients resolved');
                return;
            }

            // 2. Save payload
            Id contentVersionId = savePayloadToFile();

            // 3. Send email через EmailService
            EmailService.send(
                recipients,
                buildSubject(),
                buildBody(contentVersionId)
            );

            // 4. Log
            logSuccess(recipients, contentVersionId);

        } catch (Exception e) {
            System.debug('OppDataErrorNotifier failed: ' + e.getMessage());
        }
    }

    // -------------------------
    // Payload
    // -------------------------

    @TestVisible
    private Id savePayloadToFile() {
        if (String.isBlank(rawPayload)) {
            return null;
        }

        ContentVersion cv = new ContentVersion();
        cv.Title = buildFileName();
        cv.PathOnClient = buildFileName() + '.json';
        cv.VersionData = Blob.valueOf(rawPayload);
        cv.FirstPublishLocationId = UserInfo.getUserId();

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

        if (errors.warnings != null && !errors.warnings.isEmpty()) {
            body += '\nWarnings:\n';
            i = 1;
            for (String warn : errors.warnings) {
                body += i + ') ' + warn + '\n';
                i++;
            }
        }

        if (contentVersionId != null) {
            body += '\nPayload saved as File (ContentVersion Id): '
                 + contentVersionId + '\n';
        }

        body += '\n---\n';
        body += 'MessageType: OpportunityData\n';
        body += 'Timestamp: ' + String.valueOf(System.now()) + '\n';
        body += 'CorrelationId: ' +
            (String.isBlank(errors.correlationId) ? 'N/A' : errors.correlationId) + '\n';

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