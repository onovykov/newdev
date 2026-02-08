@IsTest
private class DataQualityServiceTest {

    // ---- Helpers ---------------------------------------------------------

    private static void assertCmdtExists(String objAlias, String fieldAlias) {
        // CMDT in tests is readable without SeeAllData=true
        // (as long as records exist in the org metadata)
        InvalidPhoneEmail__mdt found;
        for (InvalidPhoneEmail__mdt m : InvalidPhoneEmail__mdt.getAll().values()) {
            if (String.valueOf(m.ObjectNameParam__c).equalsIgnoreCase(objAlias)
                && String.valueOf(m.FieldNameParam__c).equalsIgnoreCase(fieldAlias)
            ) {
                found = m;
                break;
            }
        }

        System.assertNotEquals(
            null,
            found,
            'Missing CMDT mapping in InvalidPhoneEmail__mdt for alias: ' +
            objAlias + '.' + fieldAlias +
            '. Add a record, e.g. ObjectAPI__c=' + objAlias + ', FieldAPI__c=<real field api name>.'
        );
    }

    // ---- Tests: CMDT presence -------------------------------------------

    @IsTest
    static void test_cmdt_required_mappings_exist() {
        // мінімальний набір, який ви вже використовуєте
        assertCmdtExists('Account', 'Email');
        assertCmdtExists('Account', 'Phone');
        assertCmdtExists('Account', 'Mobile');
        assertCmdtExists('Account', 'Website');

        assertCmdtExists('Contact', 'Email');
        assertCmdtExists('Contact', 'Phone');
        assertCmdtExists('Contact', 'Mobile');

        // якщо у вас є ClientLead__c у проді — розкоментуй:
        // assertCmdtExists('Lead', 'Email');
        // assertCmdtExists('Lead', 'Phone');
        // assertCmdtExists('Lead', 'Mobile');
    }

    // ---- Tests: Email ----------------------------------------------------

    @IsTest
    static void test_email_invalid_examples() {
        Account a = new Account();
        a.put('Email__c', '1@1.11'); // ваш кейс
        System.assertEquals(true, DataQualityService.isInvalid('Account', 'Email', a));

        a.put('Email__c', '11@22.33');
        System.assertEquals(true, DataQualityService.isInvalid('Account', 'Email', a));

        a.put('Email__c', 'test@@mail.com');
        System.assertEquals(true, DataQualityService.isInvalid('Account', 'Email', a));

        a.put('Email__c', 'a b@c.com');
        System.assertEquals(true, DataQualityService.isInvalid('Account', 'Email', a));
    }

    @IsTest
    static void test_email_valid_examples() {
        Account a = new Account();
        a.put('Email__c', 'andy.hulburd@ptclpipesource.com');
        System.assertEquals(false, DataQualityService.isInvalid('Account', 'Email', a));

        a.put('Email__c', 'a.byelichenko@gmail.com');
        System.assertEquals(false, DataQualityService.isInvalid('Account', 'Email', a));

        a.put('Email__c', 'A.BRAUNSTEIN@carlico.de'); // upper-case
        System.assertEquals(false, DataQualityService.isInvalid('Account', 'Email', a));
    }

    // ---- Tests: Phone / Mobile ------------------------------------------

    @IsTest
    static void test_phone_invalid_examples() {
        Account a = new Account();

        a.put('Phone', '111');
        System.assertEquals(true, DataQualityService.isInvalid('Account', 'Phone', a));

        a.put('Phone', '000');
        System.assertEquals(true, DataQualityService.isInvalid('Account', 'Phone', a));

        a.put('Phone', '12-34'); // too short
        System.assertEquals(true, DataQualityService.isInvalid('Account', 'Phone', a));

        a.put('Phone', '+48 (xx) 123'); // non-digits after clean
        System.assertEquals(true, DataQualityService.isInvalid('Account', 'Phone', a));
    }

    @IsTest
    static void test_phone_valid_examples() {
        Account a = new Account();

        a.put('Phone', '+48 13 46 36 096');
        System.assertEquals(false, DataQualityService.isInvalid('Account', 'Phone', a));

        a.put('Phone', '44 (0) 2086844036');
        System.assertEquals(false, DataQualityService.isInvalid('Account', 'Phone', a));

        a.put('Phone', '225-773-3340');
        System.assertEquals(false, DataQualityService.isInvalid('Account', 'Phone', a));

        a.put('Phone', '+97172447372');
        System.assertEquals(false, DataQualityService.isInvalid('Account', 'Phone', a));
    }

    @IsTest
    static void test_mobile_invalid_examples() {
        Account a = new Account();

        a.put('Mobile__c', '000');
        System.assertEquals(true, DataQualityService.isInvalid('Account', 'Mobile', a));

        a.put('Mobile__c', '111');
        System.assertEquals(true, DataQualityService.isInvalid('Account', 'Mobile', a));
    }

    // ---- Tests: Website --------------------------------------------------

    @IsTest
    static void test_website_invalid_examples() {
        Account a = new Account();

        a.put('Website', 'example'); // no dot
        System.assertEquals(true, DataQualityService.isInvalid('Account', 'Website', a));

        a.put('Website', 'http://bad host.com'); // space
        System.assertEquals(true, DataQualityService.isInvalid('Account', 'Website', a));

        a.put('Website', 'https://example..com'); // double dot
        System.assertEquals(true, DataQualityService.isInvalid('Account', 'Website', a));
    }

    @IsTest
    static void test_website_valid_examples() {
        Account a = new Account();

        a.put('Website', 'https://example.com');
        System.assertEquals(false, DataQualityService.isInvalid('Account', 'Website', a));

        a.put('Website', 'example.com'); // should be accepted (service may auto-prefix)
        System.assertEquals(false, DataQualityService.isInvalid('Account', 'Website', a));

        a.put('Website', 'https://sub.domain.co.uk/path');
        System.assertEquals(false, DataQualityService.isInvalid('Account', 'Website', a));
    }

    // ------------------------------------------------------------
    // Tests: Email Suspicious (business-trash but syntactically valid)
    // ------------------------------------------------------------

    @IsTest
    static void test_email_suspicious_examples() {

        // invalid → NOT suspicious
        System.assertEquals(
            false,
            DataQualityService.isSuspiciousEmail('1@1.11'),
            'Invalid email must not be marked as suspicious'
        );

        // suspicious (classic placeholders)
        System.assertEquals(
            true,
            DataQualityService.isSuspiciousEmail('1@1.com'),
            'Numeric local + short domain should be suspicious'
        );

        System.assertEquals(
            true,
            DataQualityService.isSuspiciousEmail('a@b.com'),
            'Very short local/domain should be suspicious'
        );

        System.assertEquals(
            true,
            DataQualityService.isSuspiciousEmail('info@info.com'),
            'Placeholder local/domain should be suspicious'
        );

        System.assertEquals(
            true,
            DataQualityService.isSuspiciousEmail('test@test.de'),
            'Test/test pattern should be suspicious'
        );

        // normal corporate / personal emails
        System.assertEquals(
            false,
            DataQualityService.isSuspiciousEmail('andy.hulburd@ptclpipesource.com'),
            'Normal corporate email must not be suspicious'
        );

        System.assertEquals(
            false,
            DataQualityService.isSuspiciousEmail('a.byelichenko@gmail.com'),
            'Normal personal email must not be suspicious'
        );
    }

    @IsTest
    static void test_phone_suspicious() {

        // invalid → not suspicious
        System.assertEquals(false, DataQualityService.isSuspiciousPhone('111'));

        // suspicious
        System.assertEquals(true, DataQualityService.isSuspiciousPhone('+994111111111'));
        System.assertEquals(true, DataQualityService.isSuspiciousPhone('+998111111111'));
        System.assertEquals(true, DataQualityService.isSuspiciousPhone('1234567'));
        System.assertEquals(true, DataQualityService.isSuspiciousPhone('987654321'));

        // valid
        System.assertEquals(false, DataQualityService.isSuspiciousPhone('+48 576 662 229'));
        System.assertEquals(false, DataQualityService.isSuspiciousPhone('+995 591 22 46 17'));
    }

    @IsTest
    static void test_phone_suspicious_zero_tail() {
        System.assertEquals(
            true,
            DataQualityService.isSuspiciousPhone('+993110000000')
        );

        System.assertEquals(
            true,
            DataQualityService.isSuspiciousPhone('+994550000000')
        );
    }

}