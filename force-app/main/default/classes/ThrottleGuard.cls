public with sharing class ThrottleGuard {

    /** Повертає true, якщо подію з таким fingerprint не можна повторювати в межах throttleMinutes. */
    public static Boolean isThrottled(String fingerprint, Integer throttleMinutes) {
        if (String.isBlank(fingerprint)) {
            return false;
        }
        if (throttleMinutes == null || throttleMinutes <= 0) {
            return false;
        }

        // Часовий поріг
        Datetime threshold = System.now().addMinutes(-throttleMinutes);

        // Беремо останній лог по fingerprint (тільки успішно відправлені)
        List<Notification_Log__c> lastLogs = [
                SELECT Id, CreatedDate, Status__c
                FROM Notification_Log__c
                WHERE Fingerprint__c = :fingerprint
                AND Status__c IN ('Sent', 'PartiallyFailed')
                ORDER BY CreatedDate DESC
                LIMIT 1
        ];

        if (lastLogs.isEmpty()) {
            return false;
        }

        return lastLogs[0].CreatedDate >= threshold;
    }
}