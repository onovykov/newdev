public with sharing class RecipientChunker {

    /** Розбиває один RecipientBundle на список чанків розміру chunkSize (якщо null/<=0 — 100). */
    public static List<NotificationTypes.RecipientBundle> split(
            NotificationTypes.RecipientBundle input,
            Integer chunkSize
    ) {
        Integer size = normalizeChunkSize(chunkSize);
        List<NotificationTypes.RecipientBundle> out = new List<NotificationTypes.RecipientBundle>();

        if (input == null) {
            return out;
        }

        addUserChunks(input.userIds, size, out);
        addContactChunks(input.contactIds, size, out);
        addEmailChunks(input.emails, size, out);

        return out;
    }

    /** Нормалізує chunkSize: якщо null або <=0 — повертає 100. */
    private static Integer normalizeChunkSize(Integer chunkSize) {
        return (chunkSize == null || chunkSize <= 0) ? 100 : chunkSize;
    }

    /** Додає чанки для UserIds у вихідний список out. */
    private static void addUserChunks(Set<Id> ids, Integer chunkSize, List<NotificationTypes.RecipientBundle> out) {
        if (ids == null || ids.isEmpty()) {
            return;
        }

        List<Id> listIds = new List<Id>();
        listIds.addAll(ids);

        NotificationTypes.RecipientBundle current = new NotificationTypes.RecipientBundle();
        Integer count = 0;

        for (Id i : listIds) {
            if (i == null) continue;

            current.userIds.add(i);
            count++;

            if (count >= chunkSize) {
                out.add(current);
                current = new NotificationTypes.RecipientBundle();
                count = 0;
            }
        }

        if (count > 0) {
            out.add(current);
        }
    }

    /** Додає чанки для ContactIds у вихідний список out. */
    private static void addContactChunks(Set<Id> ids, Integer chunkSize, List<NotificationTypes.RecipientBundle> out) {
        if (ids == null || ids.isEmpty()) {
            return;
        }

        List<Id> listIds = new List<Id>();
        listIds.addAll(ids);

        NotificationTypes.RecipientBundle current = new NotificationTypes.RecipientBundle();
        Integer count = 0;

        for (Id i : listIds) {
            if (i == null) continue;

            current.contactIds.add(i);
            count++;

            if (count >= chunkSize) {
                out.add(current);
                current = new NotificationTypes.RecipientBundle();
                count = 0;
            }
        }

        if (count > 0) {
            out.add(current);
        }
    }

    /** Додає чанки для Emails у вихідний список out. */
    private static void addEmailChunks(Set<String> emails, Integer chunkSize, List<NotificationTypes.RecipientBundle> out) {
        if (emails == null || emails.isEmpty()) {
            return;
        }

        List<String> listEmails = new List<String>();
        listEmails.addAll(emails);

        NotificationTypes.RecipientBundle current = new NotificationTypes.RecipientBundle();
        Integer count = 0;

        for (String e : listEmails) {
            String v = safeTrim(e);
            if (String.isBlank(v)) continue;

            current.emails.add(v);
            count++;

            if (count >= chunkSize) {
                out.add(current);
                current = new NotificationTypes.RecipientBundle();
                count = 0;
            }
        }

        if (count > 0) {
            out.add(current);
        }
    }

    /** Безпечний trim для String. */
    private static String safeTrim(String s) {
        return (s == null) ? null : s.trim();
    }
}