@IsTest
private class SubjectBuilderTest {

    @IsTest
    static void testBuild_NullPayload() {
        // Тестуємо: if (p == null) return 'Notification';
        Test.startTest();
        String result = SubjectBuilder.build(null, null, null);
        Test.stopTest();

        System.assertEquals('Notification', result, 'Має повернути дефолтну назву для null payload');
    }

    @IsTest
    static void testBuild_OppClosedWon() {
        // Тестуємо: p.eventKey == 'OPP_CLOSED_WON_USERS'
        Opportunity opp = new Opportunity(Name = 'Big Deal');
        // Ми не робимо insert opp, бо код використовує пам'ять, а не базу (SObject.get)

        NotificationTypes.NotificationPayload payload = new NotificationTypes.NotificationPayload(
                'OPP_CLOSED_WON_USERS',
                opp,
                null
        );

        Test.startTest();
        String result = SubjectBuilder.build(payload, null, null);
        Test.stopTest();

        System.assertEquals('Closed Won: Big Deal', result);
    }

    @IsTest
    static void testBuild_ArOverdue() {
        // Тестуємо: p.eventKey == 'AR_OVERDUE_7D_USERS'
        Account acc = new Account(Name = 'Customer Corp');

        NotificationTypes.NotificationPayload payload = new NotificationTypes.NotificationPayload(
                'AR_OVERDUE_7D_USERS',
                acc,
                null
        );

        Test.startTest();
        String result = SubjectBuilder.build(payload, null, null);
        Test.stopTest();

        System.assertEquals('[AR 7d] Customer Corp', result);
    }

    @IsTest
    static void testBuild_Error() {
        // Тестуємо: p.eventKey.startsWith('ERR_')
        NotificationTypes.NotificationPayload payload = new NotificationTypes.NotificationPayload(
                'ERR_TIMEOUT_EXCEPTION',
                null,
                null
        );

        Test.startTest();
        String result = SubjectBuilder.build(payload, null, null);
        Test.stopTest();

        System.assertEquals('[SF ERROR] ERR_TIMEOUT_EXCEPTION', result);
    }

    @IsTest
    static void testBuild_Default() {
        // Тестуємо дефолтний return в кінці
        NotificationTypes.NotificationPayload payload = new NotificationTypes.NotificationPayload(
                'UNKNOWN_EVENT',
                null,
                null
        );

        Test.startTest();
        String result = SubjectBuilder.build(payload, null, null);
        Test.stopTest();

        System.assertEquals('Notification: UNKNOWN_EVENT', result);
    }

    @IsTest
    static void testBuild_EmptyContext() {
        // Перевірка надійності: що буде, якщо context == null для спец. ключів
        NotificationTypes.NotificationPayload payload = new NotificationTypes.NotificationPayload(
                'OPP_CLOSED_WON_USERS',
                null,
                null
        );

        Test.startTest();
        String result = SubjectBuilder.build(payload, null, null);
        Test.stopTest();

        // Очікуємо "Closed Won: ", бо name буде '' згідно з тернарним оператором у коді
        System.assertEquals('Closed Won: ', result);
    }
}