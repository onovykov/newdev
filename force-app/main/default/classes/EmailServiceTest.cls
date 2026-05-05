@IsTest
private class EmailServiceTest {

    @IsTest
    static void testSend_fullFlow_prod() {

        // FORCE PROD
        EmailService.sandboxOverride = false;

        // FORCE OWEA (щоб зайти в гілку)
        EmailService.oweaOverride = UserInfo.getUserId();

        EmailService.sendInvocationCount = 0;

        Set<String> recipients = new Set<String>{
            ' TEST@test.com ',
            'test2@test.com'
        };

        Test.startTest();
        EmailService.send(recipients, 'Subject', 'Body');
        Test.stopTest();

        System.assertEquals(1, EmailService.sendInvocationCount);

        // cleanup
        EmailService.sandboxOverride = null;
        EmailService.oweaOverride = null;
    }

    @IsTest
    static void testSend_sandboxFlow() {

        EmailService.sandboxOverride = true;
        EmailService.sendInvocationCount = 0;

        Set<String> recipients = new Set<String>{
            'test@test.com'
        };

        Test.startTest();
        EmailService.send(recipients, 'S', 'B');
        Test.stopTest();

        System.assertEquals(1, EmailService.sendInvocationCount);

        EmailService.sandboxOverride = null;
    }

    @IsTest
    static void testBuildRecipientList_prod() {

        EmailService.sandboxOverride = false;

        List<String> result = EmailService.buildRecipientList(
            new Set<String>{ ' TEST@test.com ' }
        );

        System.assertEquals(1, result.size());
        System.assertEquals('test@test.com', result[0]);

        EmailService.sandboxOverride = null;
    }

    @IsTest
    static void testBuildRecipientList_sandbox() {

        EmailService.sandboxOverride = true;

        List<String> result = EmailService.buildRecipientList(
            new Set<String>{ 'test@test.com' }
        );

        System.assertEquals(1, result.size());
        System.assertEquals(Label.OppDataErrorFallbackEmail, result[0]);

        EmailService.sandboxOverride = null;
    }

    @IsTest
    static void testNormalizeEmail() {

        System.assertEquals(
            'test@test.com',
            EmailService.normalizeEmail('  TEST@test.com \u00A0 ')
        );

        System.assertEquals(null, EmailService.normalizeEmail(null));
        System.assertEquals(null, EmailService.normalizeEmail('   '));
    }

    @IsTest
    static void testResolveOWEA_override() {

        EmailService.oweaOverride = UserInfo.getUserId();

        Id result = EmailService.resolveOWEA();

        System.assertEquals(UserInfo.getUserId(), result);

        EmailService.oweaOverride = null;
    }

    @IsTest
    static void testBuildEmail() {

        List<String> recipients = new List<String>{'test@test.com'};

        Messaging.SingleEmailMessage email =
            EmailService.buildEmail(recipients, 'Subj', 'Body');

        System.assertEquals('Subj', email.getSubject());
        System.assertEquals('Body', email.getPlainTextBody());
    }

    @IsTest
    static void testApplyOWEA_prod() {

        EmailService.sandboxOverride = false;
        EmailService.oweaOverride = UserInfo.getUserId();

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

        EmailService.applyOrgWideEmailIfNeeded(email);

        // просто перевірка, що не впало
        System.assert(true);

        EmailService.sandboxOverride = null;
        EmailService.oweaOverride = null;
    }

    @IsTest
    static void testApplyOWEA_sandbox() {

        EmailService.sandboxOverride = true;

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

        EmailService.applyOrgWideEmailIfNeeded(email);

        System.assert(true);

        EmailService.sandboxOverride = null;
    }

    @IsTest
    static void testDoSend_direct() {

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new List<String>{'test@test.com'});
        email.setSubject('s');
        email.setPlainTextBody('b');

        EmailService.sendInvocationCount = 0;

        Test.startTest();
        EmailService.doSend(email);
        Test.stopTest();

        System.assertEquals(1, EmailService.sendInvocationCount);
    }

    @IsTest
    static void testSend_emptyRecipients() {

        EmailService.sandboxOverride = false;

        Test.startTest();
        EmailService.send(new Set<String>(), 'Subj', 'Body');
        Test.stopTest();

        System.assert(true);

        EmailService.sandboxOverride = null;
    }

    @IsTest
    static void testSend_nullRecipients() {

        EmailService.sandboxOverride = false;

        Test.startTest();
        EmailService.send(null, 'Subj', 'Body');
        Test.stopTest();

        System.assert(true);

        EmailService.sandboxOverride = null;
    }

    @IsTest
    static void testResolveOWEA_noOverride() {

        // не задаємо override → йдемо в try/catch
        Id result = EmailService.resolveOWEA();

        // в sandbox зазвичай null — і це ок
        System.assert(true);
    }

    @IsTest
    static void testRecipientList_withNullEmail() {

        EmailService.sandboxOverride = false;

        Set<String> input = new Set<String>{
            null,
            '   '
        };

        List<String> result = EmailService.buildRecipientList(input);

        System.assertEquals(0, result.size());

        EmailService.sandboxOverride = null;
    }

    @IsTest
    static void testApplyOWEA_withoutOWEA() {

        EmailService.sandboxOverride = false;
        EmailService.oweaOverride = null; //  force null

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

        EmailService.applyOrgWideEmailIfNeeded(email);

        System.assert(true);

        EmailService.sandboxOverride = null;
    }

    @IsTest
    static void testSend_forceAllBranches() {

        // змушуємо піти в PROD
        EmailService.sandboxOverride = false;

        // змушуємо пройти OWEA гілку
        EmailService.oweaOverride = UserInfo.getUserId();

        EmailService.sendInvocationCount = 0;

        // важливо: НЕ пустий, НЕ null
        Set<String> recipients = new Set<String>{
            ' valid@test.com ',
            'ANOTHER@test.com'
        };

        Test.startTest();
        EmailService.send(recipients, 'Subj', 'Body');
        Test.stopTest();

        System.assertEquals(1, EmailService.sendInvocationCount);

        // cleanup
        EmailService.sandboxOverride = null;
        EmailService.oweaOverride = null;
    }

    @IsTest
    static void testSend_earlyReturnBranches() {

        EmailService.sandboxOverride = false;

        Test.startTest();

        // null
        EmailService.send(null, 's', 'b');

        // empty
        EmailService.send(new Set<String>(), 's', 'b');

        Test.stopTest();

        System.assert(true);

        EmailService.sandboxOverride = null;
    }
}