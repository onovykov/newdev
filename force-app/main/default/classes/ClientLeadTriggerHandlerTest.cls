@IsTest
private class ClientLeadTriggerHandlerTest {

    // ---------- Топ-рівень helpers (static тут дозволено) ----------
    private static User makeUser(){
        Profile p = [SELECT Id FROM Profile WHERE UserType = 'Standard' LIMIT 1];
        User u = new User(
            Alias = 'utuser',
            Email = 'utuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Tester',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'Europe/Kiev',
            Username = 'utuser+' + System.now().getTime() + '@example.com',
            ProfileId = p.Id
        );
        insert u;
        return u;
    }

    private static Account makeAccount(String name){
        Account a = new Account(Name = name);
        insert a;
        return a;
    }

    private static ClientLead__c insertLead(String name){
        ClientLead__c cl = new ClientLead__c(Name = name);
        insert cl;
        return cl;
    }

    // ---------- Простий мок, що повертає наперед задані списки ----------
    private class MockDupFinder implements ClientLeadTriggerHandler.IDupFinder {
        List<ClientLeadTriggerHandler.Match> acc;
        List<ClientLeadTriggerHandler.Match> leads;
        MockDupFinder(List<ClientLeadTriggerHandler.Match> acc, List<ClientLeadTriggerHandler.Match> leads){
            this.acc   = (acc   == null) ? new List<ClientLeadTriggerHandler.Match>() : acc;
            this.leads = (leads == null) ? new List<ClientLeadTriggerHandler.Match>() : leads;
        }
        public List<ClientLeadTriggerHandler.Match> findAcc(String name, Decimal threshold){ return acc; }
        public List<ClientLeadTriggerHandler.Match> findLead(String name, Decimal threshold){ return leads; }
    }

    // ---------- Мок з послідовною віддачею результатів для bulk-випадку ----------
    private class SeqFinder implements ClientLeadTriggerHandler.IDupFinder {
        Integer call = 0;
        List<ClientLeadTriggerHandler.Match> first;
        List<ClientLeadTriggerHandler.Match> second;
        SeqFinder(List<ClientLeadTriggerHandler.Match> first, List<ClientLeadTriggerHandler.Match> second){
            this.first = first; this.second = second;
        }
        public List<ClientLeadTriggerHandler.Match> findAcc(String name, Decimal threshold){
            call++;
            return (call == 1) ? first : second;
        }
        public List<ClientLeadTriggerHandler.Match> findLead(String name, Decimal threshold){
            return new List<ClientLeadTriggerHandler.Match>();
        }
    }

    // ---------- Тест 1: створили лід -> зʼявились рядки-дублі в обох таблицях ----------
    @IsTest
    static void test_afterInsert_creates_related_duplicate_rows(){
        User u = makeUser();
        System.runAs(u){
            Account a1 = makeAccount('Acme Steel');
            ClientLead__c otherLead = insertLead('Acme Group');

            List<ClientLeadTriggerHandler.Match> accMatches = new List<ClientLeadTriggerHandler.Match>{
                new ClientLeadTriggerHandler.Match(a1.Id, 0.91, 'Acme Steel')
            };
            List<ClientLeadTriggerHandler.Match> leadMatches = new List<ClientLeadTriggerHandler.Match>{
                new ClientLeadTriggerHandler.Match(otherLead.Id, 0.87, 'Acme Group')
            };

            ClientLeadTriggerHandler.setDupFinder(new MockDupFinder(accMatches, leadMatches));

            Test.startTest();
            ClientLead__c newL = insertLead('Acme STeel LLC');
            Test.stopTest();

            ClientLead__c fetched = [SELECT Id, Duplicates__c FROM ClientLead__c WHERE Id = :newL.Id];
            System.assertNotEquals(null, fetched.Duplicates__c, 'Duplicates__c should be populated');
            System.assert(fetched.Duplicates__c.contains('Potential duplicates in Accounts'));
            System.assert(fetched.Duplicates__c.contains('Potential duplicates in Client Leads'));

            List<LeadDuplicateAcc__c> accRows = [
                SELECT Id, MainLead__c, DuplicateAcc__c, MatchIndex__c, AccountNameIT__c
                FROM LeadDuplicateAcc__c WHERE MainLead__c = :newL.Id
            ];
            System.assertEquals(1, accRows.size(), 'One LeadDuplicateAcc__c expected');
            System.assertEquals(a1.Id, accRows[0].DuplicateAcc__c, 'Account lookup mismatch');
            System.assertEquals(0.91, accRows[0].MatchIndex__c, 'MatchIndex__c mismatch');

            List<LeadDuplicateLead__c> leadRows = [
                SELECT Id, MainLead__c, DuplicateLead__c, MatchIndex__c
                FROM LeadDuplicateLead__c WHERE MainLead__c = :newL.Id
            ];
            System.assertEquals(1, leadRows.size(), 'One LeadDuplicateLead__c expected');
            System.assertEquals(otherLead.Id, leadRows[0].DuplicateLead__c, 'Lead lookup mismatch');
            System.assertEquals(0.87, leadRows[0].MatchIndex__c, 'MatchIndex__c mismatch');

            // Повернемо дефолтну реалізацію (не обов'язково, але охайно)
            ClientLeadTriggerHandler.setDupFinder(null);
        }
    }

    // ---------- Тест 2: bulk (2 однакові назви) — черга в кеші вирівнює відповіді ----------
    @IsTest
    static void test_bulk_two_leads_same_name_queue_alignment(){
        User u = makeUser();
        System.runAs(u){
            Account aA = makeAccount('Globex A');
            Account aB = makeAccount('Globex B');

            List<ClientLeadTriggerHandler.Match> accMatches1 = new List<ClientLeadTriggerHandler.Match>{
                new ClientLeadTriggerHandler.Match(aA.Id, 0.9, 'Globex A')
            };
            List<ClientLeadTriggerHandler.Match> accMatches2 = new List<ClientLeadTriggerHandler.Match>{
                new ClientLeadTriggerHandler.Match(aB.Id, 0.92, 'Globex B')
            };

            ClientLeadTriggerHandler.setDupFinder(new SeqFinder(accMatches1, accMatches2));

            Test.startTest();
            insert new List<ClientLead__c>{
                new ClientLead__c(Name = 'Globex LLC'),
                new ClientLead__c(Name = 'Globex LLC')
            };
            Test.stopTest();

            List<LeadDuplicateAcc__c> rows = [
                SELECT Id, MainLead__c, DuplicateAcc__c, MatchIndex__c, AccountNameIT__c
                FROM LeadDuplicateAcc__c
                ORDER BY CreatedDate ASC
            ];
            System.assertEquals(2, rows.size(), 'Two LeadDuplicateAcc__c expected');

            // Перевіряємо, що кожний MainLead__c отримав свій відповідний Account
            Set<Id> accIds = new Set<Id>{ rows[0].DuplicateAcc__c, rows[1].DuplicateAcc__c };
            System.assert(accIds.contains(aA.Id) && accIds.contains(aB.Id), 'Each account should appear exactly once');

            ClientLeadTriggerHandler.setDupFinder(null);
        }
    }

    // ---------- Тест 3: поріг — нижче 0.8 рядки не створюються ----------
    @IsTest
    static void test_threshold_filters_out_low_scores(){
        User u = makeUser();
        System.runAs(u){
            Account a = makeAccount('LowScore Inc');

            List<ClientLeadTriggerHandler.Match> accMatches = new List<ClientLeadTriggerHandler.Match>{
                new ClientLeadTriggerHandler.Match(a.Id, 0.51, 'LowScore Inc')
            };
            ClientLeadTriggerHandler.setDupFinder(new MockDupFinder(accMatches, new List<ClientLeadTriggerHandler.Match>()));

            Test.startTest();
            ClientLead__c l = insertLead('LowScore');
            Test.stopTest();

            List<LeadDuplicateAcc__c> rows = [
                SELECT Id FROM LeadDuplicateAcc__c WHERE MainLead__c = :l.Id
            ];
            System.assertEquals(0, rows.size(), 'No LeadDuplicateAcc__c should be created under threshold');

            ClientLeadTriggerHandler.setDupFinder(null);
        }
    }
}