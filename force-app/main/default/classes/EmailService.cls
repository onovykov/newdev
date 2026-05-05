public with sharing class EmailService {

    // -------------------------
    // Test controls
    // -------------------------

    @TestVisible private static Boolean sandboxOverride;
    @TestVisible private static Id oweaOverride;
    @TestVisible private static Integer sendInvocationCount = 0;

    private static Boolean isSandboxCached;

    // -------------------------
    // Config
    // -------------------------

    private static final String SANDBOX_FALLBACK_EMAIL =
        Label.OppDataErrorFallbackEmail;

    // -------------------------
    // Public API
    // -------------------------

    public static void send(
        Set<String> recipients,
        String subject,
        String body
    ) {
        if (recipients == null || recipients.isEmpty()) {
            System.debug('EmailService: no recipients');
            return;
        }

        List<String> finalRecipients = buildRecipientList(recipients);

        if (finalRecipients.isEmpty()) {
            System.debug('EmailService: no valid recipients after routing');
            return;
        }

        Messaging.SingleEmailMessage email = buildEmail(
            finalRecipients,
            subject,
            body
        );

        applyOrgWideEmailIfNeeded(email);

        doSend(email);
    }

    // -------------------------
    // Core steps (розбиті для coverage)
    // -------------------------

    @TestVisible
    private static List<String> buildRecipientList(Set<String> recipients) {

        List<String> result = new List<String>();

        if (isSandbox()) {
            result.add(SANDBOX_FALLBACK_EMAIL);
            return result;
        }

        for (String r : recipients) {
            String normalized = normalizeEmail(r);
            if (normalized != null) {
                result.add(normalized);
            }
        }

        return result;
    }

    @TestVisible
    private static Messaging.SingleEmailMessage buildEmail(
        List<String> recipients,
        String subject,
        String body
    ) {
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(recipients);
        email.setSubject(subject);
        email.setPlainTextBody(body);
        return email;
    }

    @TestVisible
    private static void applyOrgWideEmailIfNeeded(
        Messaging.SingleEmailMessage email
    ) {
        if (isSandbox()) {
            return;
        }

        Id oweaId = resolveOWEA();
        if (oweaId != null) {
            email.setOrgWideEmailAddressId(oweaId);
        }
    }

    @TestVisible
    private static void doSend(Messaging.SingleEmailMessage email) {
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
        sendInvocationCount++;
    }

    // -------------------------
    // Utils
    // -------------------------

    @TestVisible
    private static String normalizeEmail(String email) {
        if (String.isBlank(email)) return null;

        String result = email.trim().toLowerCase();
        result = result.replaceAll('\\s+', '');
        result = result.replace('\u00A0', '');

        return result;
    }

    @TestVisible
    private static Id resolveOWEA() {
        if (oweaOverride != null) {
            return oweaOverride;
        }

        try {
            return [
                SELECT Id
                FROM OrgWideEmailAddress
                WHERE IsAllowAllProfiles = true
                LIMIT 1
            ].Id;
        } catch (Exception e) {
            return null;
        }
    }

    @TestVisible
    private static Boolean isSandbox() {
        if (sandboxOverride != null) {
            return sandboxOverride;
        }

        if (isSandboxCached == null) {
            isSandboxCached =
                [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
        }

        return isSandboxCached;
    }
}