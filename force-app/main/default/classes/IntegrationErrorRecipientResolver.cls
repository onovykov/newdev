public with sharing class IntegrationErrorRecipientResolver {

    public static final String PS_ERROR_NOTIFICATION = 'ErrorNotification';

    public static Set<String> resolve(IntegrationErrorContext ctx) {
        Set<String> recipients = new Set<String>();

        if (ctx == null) {
            return fallbackRecipients(recipients);
        }

        // 1. JSON emails
        addIfValid(recipients, ctx.salesRepEmail);
        addIfValid(recipients, ctx.bosEmail);

        // 2. Permission Set fallback
        if (recipients.isEmpty()) {
            for (User u : [
                SELECT Email
                FROM User
                WHERE Id IN (
                    SELECT AssigneeId
                    FROM PermissionSetAssignment
                    WHERE PermissionSet.Name = :PS_ERROR_NOTIFICATION
                )
                AND IsActive = true
            ]) {
                addIfValid(recipients, u.Email);
            }
        }

        // 3. Hard fallback
        if (recipients.isEmpty()) {
            recipients.add(getHardFallbackEmail());
        }

        return recipients;
    }

    // -------------------------
    // Helpers
    // -------------------------

    private static void addIfValid(Set<String> setRef, String email) {
        if (isValidEmail(email)) {
            setRef.add(email.trim());
        }
    }

    private static Boolean isValidEmail(String email) {
        if (String.isBlank(email)) return false;

        // Apex-compatible case-insensitive regex
        Pattern p = Pattern.compile(
            '(?i)^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}$'
        );

        return p.matcher(email).matches();
    }

    private static Set<String> fallbackRecipients(Set<String> recipients) {
        recipients.add(getHardFallbackEmail());
        return recipients;
    }

    private static String getHardFallbackEmail() {
        String email = System.Label.OppDataErrorFallbackEmail;

        return String.isNotBlank(email)
            ? email.trim()
            : 'Aleksandr.Novikov@m.interpipe.biz'; // safety fallback
    }
}