@IsTest
private class RecordTypeCacheTest {

    @IsTest
    static void getId_active_and_clone_safety() {
        // Arrange
        RecordTypeCache.flush();
        Map<String, Map<String, Id>> active = new Map<String, Map<String, Id>>{
            'Opportunity' => new Map<String, Id>{
                'New_Client_Enquiry' => (Id) '012000000000001AAA',
                'Existing'           => (Id) '012000000000002AAA'
            },
            'ClientLead__c' => new Map<String, Id>{
                'Default' => (Id) '012000000000003AAA'
            }
        };
        RecordTypeCache.test_inject(active, null);

        // Act
        Id rt1 = RecordTypeCache.getId('Opportunity', 'New_Client_Enquiry');
        Id rt2 = RecordTypeCache.getId(Opportunity.SObjectType, 'Existing');
        Map<String, Id> oppMapCopy = RecordTypeCache.getMapFor('Opportunity'); // має бути копія
        Map<String, Map<String, Id>> fullCopy = RecordTypeCache.getAllAsMap(); // копія всієї активної мапи

        // Assert
        System.assertEquals((Id) '012000000000001AAA', rt1);
        System.assertEquals((Id) '012000000000002AAA', rt2);
        System.assertEquals(2, oppMapCopy.size());
        System.assertEquals(true, fullCopy.containsKey('ClientLead__c'));

        // Змінимо копію і переконаємось, що кеш не постраждав
        oppMapCopy.put('Injected', (Id) '012000000000009AAA');
        System.assertEquals(2, RecordTypeCache.getMapFor('Opportunity').size(),
            'Повертаємо копії, а не посилання на кеш');
    }

    @IsTest
    static void getId_includeInactive_and_getOrThrow() {
        // Arrange
        RecordTypeCache.flush();
        Map<String, Map<String, Id>> active = new Map<String, Map<String, Id>>{
            'Opportunity' => new Map<String, Id>{ 'ActiveOne' => (Id) '012000000000010AAA' }
        };
        Map<String, Map<String, Id>> all = new Map<String, Map<String, Id>>{
            'Opportunity' => new Map<String, Id>{
                'ActiveOne'   => (Id) '012000000000010AAA',
                'InactiveOne' => (Id) '012000000000011AAA'
            }
        };
        RecordTypeCache.test_inject(active, all);

        // Act + Assert
        System.assertEquals((Id) '012000000000010AAA',
            RecordTypeCache.getId('Opportunity', 'ActiveOne', false));

        System.assertEquals((Id) '012000000000011AAA',
            RecordTypeCache.getId('Opportunity', 'InactiveOne', true));

        Boolean thrown = false;
        try {
            RecordTypeCache.getOrThrow('Opportunity', 'Missing', false);
        } catch (RecordTypeCache.NotFoundException ex) {
            thrown = true;
        }
        System.assert(thrown, 'getOrThrow має кидати NotFoundException для відсутніх значень');
    }

    @IsTest
    static void flush_and_empty_paths() {
        RecordTypeCache.flush();

        // getMapFor для невідомого об’єкта -> порожня, але не null
        Map<String, Id> none = RecordTypeCache.getMapFor('NoSuch__c');
        System.assertNotEquals(null, none);
        System.assertEquals(0, none.size());

        // ensureBuilt(true/false) викликається лінивою гілкою
        // нічого не впаде навіть якщо SOQL нічого не поверне
        Id shouldBeNull1 = RecordTypeCache.getId('Account', 'Nope', false);
        Id shouldBeNull2 = RecordTypeCache.getId('Account', 'Nope', true);
        System.assertEquals(null, shouldBeNull1);
        System.assertEquals(null, shouldBeNull2);

        // primeAll викликає build(). Навіть з порожнім результатом — покриття є.
        RecordTypeCache.flush();
        RecordTypeCache.primeAll(false);
        RecordTypeCache.primeAll(true);

        // primeFor із null/empty сетом — no-op гілка
        RecordTypeCache.primeFor(null, false);
        RecordTypeCache.primeFor(new Set<String>(), true);
    }

    @IsTest
    static void test_injectObject_and_merge_cover() {
        // Покриємо шлях test_injectObject (і для ACTIVE, і для ALL)
        RecordTypeCache.flush();
        RecordTypeCache.test_injectObject('Case', new Map<String, Id>{
            'Support' => (Id) '012000000000101AAA'
        }, /*intoAll*/ false);

        RecordTypeCache.test_injectObject('Case', new Map<String, Id>{
            'SupportAll' => (Id) '012000000000102AAA'
        }, /*intoAll*/ true);

        System.assertEquals((Id) '012000000000101AAA',
            RecordTypeCache.getId('Case', 'Support', false));
        System.assertEquals((Id) '012000000000102AAA',
            RecordTypeCache.getId('Case', 'SupportAll', true));

        // Покриємо mergeInto через test_mergeExpose (patch-hook)
        Map<String, Map<String, Id>> base = new Map<String, Map<String, Id>>{
            'Account' => new Map<String, Id>{ 'B2B' => (Id) '012000000000201AAA' }
        };
        Map<String, Map<String, Id>> inc = new Map<String, Map<String, Id>>{
            'Account' => new Map<String, Id>{ 'B2C' => (Id) '012000000000202AAA' },
            'Lead'    => new Map<String, Id>{ 'Retail' => (Id) '012000000000203AAA' }
        };

        // merge в ACTIVE
        RecordTypeCache.test_mergeExpose(base, inc, false);
        Map<String, Id> accActive = RecordTypeCache.getMapFor('Account');
        System.assertEquals(true, accActive.containsKey('B2B'));
        System.assertEquals(true, accActive.containsKey('B2C'));
        System.assertEquals((Id) '012000000000202AAA', accActive.get('B2C'));

        // merge в ALL
        RecordTypeCache.flush();
        RecordTypeCache.test_mergeExpose(base, inc, true);
        System.assertEquals((Id) '012000000000203AAA',
            RecordTypeCache.getId('Lead', 'Retail', true));
    }

    @IsTest
    static void getAllAsMap_is_deep_clone() {
        RecordTypeCache.flush();
        RecordTypeCache.test_inject(new Map<String, Map<String, Id>>{
            'Order' => new Map<String, Id>{ 'B2B' => (Id) '012000000000301AAA' }
        }, null);

        Map<String, Map<String, Id>> copy = RecordTypeCache.getAllAsMap();
        copy.get('Order').put('Injected', (Id) '012000000000302AAA');

        // Оригінал не змінений
        System.assertEquals(false, RecordTypeCache.getAllAsMap().get('Order').containsKey('Injected'));
    }
}