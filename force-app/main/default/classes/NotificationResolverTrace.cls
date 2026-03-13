public with sharing class NotificationResolverTrace {
    private static Map<Id, String> byContext = new Map<Id, String>();

    public static void put(SObject ctx, String trace) {
        // Додаємо перевірку ctx != null на самому початку
        if (ctx == null || String.isBlank(trace)) {
            return;
        }

        try {
            Id id = (Id)ctx.get('Id');
            if (id != null) {
                byContext.put(id, trace);
            }
        } catch (Exception e) {
            // Захист на випадок, якщо в об'єкті взагалі немає поля Id
        }
    }

    public static String get(SObject ctx) {
        // Додаємо перевірку ctx != null
        if (ctx == null) {
            return null;
        }

        try {
            Id id = (Id)ctx.get('Id');
            return id == null ? null : byContext.get(id);
        } catch (Exception e) {
            return null;
        }
    }
}