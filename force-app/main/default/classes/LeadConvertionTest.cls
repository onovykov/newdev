@IsTest
private class LeadConvertionTest {

    // Хелпер: зібрати валідний 18-символьний Id для Account (префікс "001")
    private static Id fakeAccountId(Integer n) {
        String kp = Account.SObjectType.getDescribe().getKeyPrefix(); // "001"
        String num = String.valueOf(n);
        while (num.length() < 12) num = '0' + num;
        return (Id)(kp + num + 'AAA');
    }

    @IsTest
    static void test_convert_success_contacts_and_maybe_opps() {
        // вмикаємо гачки
        LeadConvertion.bypassSegmentCheck = true;
        LeadConvertion.bypassLicenseCheck = true;

        try {
            insert new Country__c(Name='UA test', SysName__c='Ukraine', A2Code__c='UA', A3Code__c='UKR', NumCode__c='804');
            insert new DeliveryTerms__c(Name='DT', ID_ERP__c='008');
            insert new PaymentTerms__c(Name='PT', ID_ERP__c='C33');

            ClientLead__c lead = new ClientLead__c(
                Name='Lead X',
                BusinessDivision__c = 'Pipes',  // Валідне значення з picklist
                MarketSegment__c = '00001'       // Ukraine
            );
            insert lead;

            // Очищаємо кеш, щоб LeadRepository знайшов щойно створений Lead
            LeadRepository.clearCache();

            Id rtOppEnquiry  = RecordTypeCache.getId(Opportunity.SObjectType, 'New_Client_Enquiry');
            Id rtContactLead = RecordTypeCache.getId(Contact.SObjectType,     'Lead_Contact');

            Opportunity o = new Opportunity(
                Name='Enquiry',
                StageName='Prospecting',
                CloseDate=Date.today().addDays(30),
                Lead__c=lead.Id,
                RecordTypeId=rtOppEnquiry
            );
            insert o;

            List<Contact> contacts = new List<Contact>{
                new Contact(LastName='C1', Lead__c=lead.Id, RecordTypeId=rtContactLead),
                new Contact(LastName='C2', Lead__c=lead.Id, RecordTypeId=rtContactLead)
            };
            insert contacts;

            String payload = JSON.serialize(new Map<String, Object>{
                'Data' => new Map<String, Object>{
                    'OrderType'     => 'Tubes',
                    'OrderCurrency' => 'USD',
                    'Header' => new Map<String, Object>{
                        'ID_SF'            => o.Id,
                        'Account'          => new Map<String,Object>{ 'Name'=>'Test Acc', 'Id'=>'ERP-1', 'CountryId'=>804, 'Address'=>'Addr' },
                        'BusinessSegmentId'=> '00011',
                        'CountryId'        => 804,
                        'PaymentTerms'     => new Map<String,Object>{ 'Id'=>'C33', 'Name'=>'PT' },
                        'DeliveryTerms'    => new Map<String,Object>{ 'Id'=>'008', 'Name'=>'DT' },
                        'SalesRep'         => new Map<String,Object>{ 'UserId'=>'ANY' }
                    }
                }
            });

            Test.startTest();
            LeadConvertion.LeadConvertResult res = LeadConvertion.convertLead(payload);
            Test.stopTest();

            System.assertNotEquals(null, res);
            System.assert(res.accResult, 'Account should be created');

            List<Contact> updated = [SELECT Id, AccountId, RecordTypeId FROM Contact WHERE Id IN :contacts];
            System.assertEquals(2, updated.size());
            System.assertNotEquals(null, updated[0].AccountId);

            if (rtOppEnquiry != null) {
                System.assert(res.oppResult, 'Opps should be updated when Enquiry RT exists');
                Opportunity o2 = [SELECT Id, AccountId, Status__c, RecordTypeId FROM Opportunity WHERE Id=:o.Id];
                System.assertEquals('Opportunity', o2.Status__c);
                System.assertNotEquals(null, o2.AccountId);
            } else {
                System.assertEquals(false, res.oppResult);
            }

            if (res.accResult && res.oppResult && res.contResult) {
                ClientLead__c leadAfter = [SELECT Id, LeadStage__c FROM ClientLead__c WHERE Id=:lead.Id];
                System.assertEquals('Converted', leadAfter.LeadStage__c);
                System.assert(res.leadConverted);
            }
        } finally {
            // скидаємо гачки
            LeadConvertion.bypassSegmentCheck = false;
            LeadConvertion.bypassLicenseCheck = false;
            LeadConvertion.testDuplicates = null;
        }
    }

    @IsTest
    static void test_convert_duplicates_early_exit() {
        ClientLead__c lead = new ClientLead__c(
            Name='Lead D',
            BusinessDivision__c = 'Pipes',  // Валідне значення з picklist
            MarketSegment__c = '00011'       // Ukraine
        );
        insert lead;

        // Очищаємо кеш, щоб LeadRepository знайшов щойно створений Lead
        LeadRepository.clearCache();

        Opportunity o = new Opportunity(
            Name='Head D',
            StageName='Prospecting',
            CloseDate=Date.today().addDays(10),
            Lead__c=lead.Id
        );
        insert o;

        // підставляємо “знайдені” дублікати
        String mrJson = JSON.serialize(new Map<String,Object>{
            'account1Id' => (String)fakeAccountId(1),
            'account2Id' => (String)fakeAccountId(2),
            'matchIndex' => 0.92
        });
        StringUtilsEx.MatchResult mr =
            (StringUtilsEx.MatchResult) JSON.deserialize(mrJson, StringUtilsEx.MatchResult.class);
        LeadConvertion.testDuplicates = new List<StringUtilsEx.MatchResult>{ mr };

        try {
            String payload = JSON.serialize(new Map<String, Object>{
                'Data' => new Map<String, Object>{
                    'OrderType'     => 'Wheels',
                    'OrderCurrency' => 'EUR',
                    'Header' => new Map<String, Object>{
                        'ID_SF'            => o.Id,
                        'Account'          => new Map<String,Object>{ 'Name'=>'Dup Acc', 'Id'=>'ERP-X', 'CountryId'=>804, 'Address'=>'Addr' },
                        'BusinessSegmentId'=> '00099',
                        'CountryId'        => 804,
                        'PaymentTerms'     => new Map<String,Object>{ 'Id'=>'C99', 'Name'=>'PT' },
                        'DeliveryTerms'    => new Map<String,Object>{ 'Id'=>'009', 'Name'=>'DT' },
                        'SalesRep'         => new Map<String,Object>{ 'UserId'=>'ANY' }
                    }
                }
            });

            Test.startTest();
            LeadConvertion.LeadConvertResult res = LeadConvertion.convertLead(payload);
            Test.stopTest();

            System.assertNotEquals(null, res);
            System.assertEquals(false, res.accResult);
            System.assertEquals(false, res.oppResult);
            System.assertEquals(false, res.contResult);
            System.assertEquals(false, res.leadConverted);
        } finally {
            LeadConvertion.testDuplicates = null; // скидаємо
        }
    }

    @IsTest
    static void test_getSegmVirtAcc_found() {
        // Створюємо віртуальний акаунт
        Account virtualAcc = new Account(
            Name = 'Virtual Account Europe',
            ID_ERP__c = 'VIRT_EU_001',
            Type = 'Virtual'
        );
        insert virtualAcc;

        // Створюємо SegmentAccount, що посилається на цей акаунт через ID_ERP__c
        SegmentAccount__c segAcc = new SegmentAccount__c(
            Name = 'EUROPE',
            ID_ERP__c = 'VIRT_EU_001'
        );
        insert segAcc;

        // Очищаємо кеш AccountRepository, щоб він завантажив наш тестовий акаунт
        AccountRepository.clearCache();

        Test.startTest();
        Map<String, Id> result = LeadConvertion.getSegmVirtAcc();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Map не має бути null');
        System.assert(result.containsKey('EUROPE'), 'Map має містити ключ EUROPE');
        System.assertEquals(virtualAcc.Id, result.get('EUROPE'), 'Id акаунта має співпадати');
    }

    @IsTest
    static void test_getSegmVirtAcc_notFound() {
        // Створюємо SegmentAccount БЕЗ відповідного Account
        SegmentAccount__c segAcc = new SegmentAccount__c(
            Name = 'AMERICA',
            ID_ERP__c = 'VIRT_AM_999'
        );
        insert segAcc;

        // Очищаємо кеш
        AccountRepository.clearCache();

        Test.startTest();
        Map<String, Id> result = LeadConvertion.getSegmVirtAcc();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Map не має бути null');
        System.assertEquals(false, result.containsKey('AMERICA'), 'Map не має містити AMERICA, бо акаунт не знайдено');
    }

    @IsTest
    static void test_getVirtAccIdBySegm_found() {
        // Створюємо віртуальний акаунт
        Account virtualAcc = new Account(
            Name = 'Virtual Account CIS',
            ID_ERP__c = 'VIRT_CIS_001',
            Type = 'Virtual'
        );
        insert virtualAcc;

        // Створюємо SegmentAccount
        SegmentAccount__c segAcc = new SegmentAccount__c(
            Name = 'CIS',
            ID_ERP__c = 'VIRT_CIS_001'
        );
        insert segAcc;

        // Очищаємо кеш
        AccountRepository.clearCache();

        Test.startTest();
        Id result = LeadConvertion.getVirtAccIdBySegm('CIS');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Id не має бути null');
        System.assertEquals(virtualAcc.Id, result, 'Id має співпадати з віртуальним акаунтом');
    }

    @IsTest
    static void test_getVirtAccIdBySegm_notFound() {
        Test.startTest();
        Id result = LeadConvertion.getVirtAccIdBySegm('UNKNOWN_SEGMENT');
        Test.stopTest();

        System.assertEquals(null, result, 'Для невідомого сегменту має повертатися null');
    }
}