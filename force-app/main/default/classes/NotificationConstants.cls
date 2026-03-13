public with sharing class NotificationConstants {

    /**
     * ID акаунту "ІНТЕРПАЙП УКРАЇНА" для резолву IT-адмінів.
     * TODO: Винести в Custom Metadata або Custom Settings для різних org.
     * Для sandbox/production використовуйте відповідні ID.
     */
    public static Id getInterpipeUkraineAccountId() {
        // Спроба отримати з Custom Settings або Custom Metadata
        // Якщо не знайдено - повертаємо hardcoded для production

        // Опція 1: Через Custom Label (найпростіше, але не type-safe)
        // return Id.valueOf(Label.Interpipe_Ukraine_Account_Id);

        // Опція 2: Через SOQL за Name (повільніше, але динамічно)
        List<Account> acc = [
            SELECT Id
            FROM Account
            WHERE Name = 'ІНТЕРПАЙП УКРАЇНА'
            LIMIT 1
        ];

        if (!acc.isEmpty()) {
            return acc[0].Id;
        }

        // Fallback для існуючого коду (production org)
        return '0011n00002MXoKYAA1';
    }
}