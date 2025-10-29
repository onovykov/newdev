@IsTest
private class GenericHardDeleteBatchTest {

    // ---------- Helpers ----------
    private static List<SObject> newRecords(String objectApiName, Integer n, String namePrefix) {
        Schema.DescribeSObjectResult d = Schema.getGlobalDescribe().get(objectApiName).getDescribe();
        Schema.SObjectType t = d.getSObjectType();

        Boolean shouldSetName = false;
        if (d.fields.getMap().containsKey('Name')) {
            Schema.DescribeFieldResult fr = d.fields.getMap().get('Name').getDescribe();
            shouldSetName = fr.isCreateable() && !fr.isNillable();
        }

        List<SObject> out = new List<SObject>();
        for (Integer i = 0; i < n; i++) {
            SObject s = t.newSObject();
            if (shouldSetName) s.put('Name', namePrefix + '_' + i);
            // TODO: якщо у Lot__c є інші required-поля — заповни тут
            out.add(s);
        }
        return out;
    }

    private static Integer countActive(String obj) {
        return (Integer)Database.countQuery('SELECT COUNT() FROM ' + obj);
    }

    private static Integer countActiveByIds(String obj, Set<Id> ids) {
        if (ids.isEmpty()) return 0;
        String soql = 'SELECT COUNT() FROM ' + obj + ' WHERE Id IN :ids';
        return (Integer)Database.countQuery(soql);
    }

    private static Integer countAllRowsByIds(String obj, Set<Id> ids) {
        if (ids.isEmpty()) return 0;
        String soql = 'SELECT COUNT() FROM ' + obj + ' WHERE Id IN :ids ALL ROWS';
        return (Integer)Database.countQuery(soql);
    }

    // ---------- Tests ----------

    @IsTest
    static void testHardDelete_AllRecords_softInTests() {
        String obj = 'Lot__c';
        insert newRecords(obj, 5, 'TALL');

        System.assertEquals(5, countActive(obj), 'Expected 5 active before delete');

        Test.startTest();
        // У тестах вимикаємо hard delete для стабільності
        Database.executeBatch(new GenericHardDeleteBatch(obj, null, false), 2000);
        Test.stopTest();

        // Активних не лишилось
        System.assertEquals(0, countActive(obj), 'All active should be soft-deleted');

        // У Recycle Bin записи присутні (бо performHardDelete=false)
        Integer withBin = (Integer)Database.countQuery('SELECT COUNT() FROM ' + obj + ' ALL ROWS');
        System.assertEquals(5, withBin, 'Soft-deleted remain in Recycle Bin in tests');
    }

    @IsTest
    static void testHardDelete_WithWhere_Subset_softInTests() {
        String obj = 'Lot__c';

        List<SObject> recs = newRecords(obj, 5, 'TSUB');
        insert recs;

        Set<Id> toDelete = new Set<Id>{ (Id)recs[0].get('Id'), (Id)recs[1].get('Id') };
        Set<Id> toStay   = new Set<Id>{ (Id)recs[2].get('Id'), (Id)recs[3].get('Id'), (Id)recs[4].get('Id') };

        // WHERE Id IN (...)
        List<String> idLits = new List<String>();
        for (Id i : toDelete) idLits.add('\'' + String.valueOf(i) + '\'');
        String whereClause = 'Id IN (' + String.join(idLits, ',') + ')';

        Test.startTest();
        Database.executeBatch(new GenericHardDeleteBatch(obj, whereClause, false), 2000);
        Test.stopTest();

        // Обрані — soft-deleted: активних 0, у ALL ROWS = 2
        System.assertEquals(0, countActiveByIds(obj, toDelete), 'Selected should not be active after delete');
        System.assertEquals(2, countAllRowsByIds(obj, toDelete), 'Selected remain in Recycle Bin (tests)');

        // Необрані — залишаються активними
        System.assertEquals(3, countActiveByIds(obj, toStay), 'Other IDs should remain active');
    }

    @IsTest
    static void testThrows_OnUnknownObject() {
        Boolean thrown = false; String msg = '';
        Test.startTest();
        try {
            Database.executeBatch(new GenericHardDeleteBatch('Nope__c', null, false), 200);
            Test.stopTest();
        } catch (Exception e) {
            thrown = true; msg = e.getMessage();
        }
        System.assert(thrown, 'Expected exception for unknown sObject');
        System.assert(msg != null && msg.contains('Unknown sObject'),
            'Should mention Unknown sObject, got: ' + msg);
    }

    @IsTest
    static void testThrows_OnNotDeletableObject() {
        // RecordType існує, але не deletable → має впасти з "sObject is not deletable"
        Boolean thrown = false; String msg = '';
        Test.startTest();
        try {
            Database.executeBatch(new GenericHardDeleteBatch('RecordType', null, false), 200);
            Test.stopTest();
        } catch (Exception e) {
            thrown = true; msg = e.getMessage();
        }
        System.assert(thrown, 'Expected exception for not deletable sObject');
        System.assert(msg != null && msg.contains('sObject is not deletable'),
            'Should mention "sObject is not deletable", got: ' + msg);
    }

    @IsTest
    static void testNoRecords_NoOp_ExecuteEarlyReturn() {
        String obj = 'Lot__c';
        // Створюємо 1 запис
        List<SObject> recs = newRecords(obj, 1, 'TNOOP');
        insert recs;
        Id createdId = (Id)recs[0].get('Id');

        // WHERE гарантовано поверне 0 рядків
        String whereClause = 'Id = null';

        Test.startTest();
        Database.executeBatch(new GenericHardDeleteBatch(obj, whereClause, false), 2000);
        Test.stopTest();

        // Перевіряємо існування САМЕ цього запису за Id (а не за Name)
        System.assertEquals(
            1,
            countActiveByIds(obj, new Set<Id>{ createdId }),
            'Record should remain since WHERE matched no rows'
        );
    }

    @IsTest
    static void testForceHardDelete_BlockCovered() {
        String obj = 'Lot__c';
        // створимо 2 записи
        List<SObject> recs = newRecords(obj, 2, 'THARD');
        insert recs;
        Set<Id> ids = new Map<Id, SObject>(recs).keySet();

        // форсимо проходження гілки hard delete у батчі (в тестах ми лише симулюємо emptyRecycleBin)
        GenericHardDeleteBatch.FORCE_HARD_DELETE_IN_TESTS = true;

        Test.startTest();
        Database.executeBatch(new GenericHardDeleteBatch(obj, null, true), 200000);
        Test.stopTest();

        // Активних записів не має бути (soft delete відбувся)
        System.assertEquals(0, countActiveByIds(obj, ids), 'Active rows must be 0 after delete');

        // У тестах hard delete симулюється, тож записи лишаються в Recycle Bin (ALL ROWS == 2)
        System.assertEquals(2, countAllRowsByIds(obj, ids),
            'In tests we simulate hard delete, so ALL ROWS equals number of soft-deleted');

        // приберемо прапорець
        GenericHardDeleteBatch.FORCE_HARD_DELETE_IN_TESTS = false;
    }
    
    @IsTest
    static void testSimulateDeleteException_CatchCovered() {
        String obj = 'Lot__c';
        // один запис
        List<SObject> rec = newRecords(obj, 1, 'TEXC');
        insert rec;
        Id theId = (Id)rec[0].get('Id');

        // імітуємо виняток під час delete, щоб покрити catch і ранній return
        GenericHardDeleteBatch.SIMULATE_DELETE_EXCEPTION = true;

        Test.startTest();
        Database.executeBatch(new GenericHardDeleteBatch(obj, null, false), 1);
        Test.stopTest();

        // запис має лишитися активним (бо delete «завалився» і ми вийшли з execute)
        System.assertEquals(1, countActiveByIds(obj, new Set<Id>{ theId }),
            'Record should remain because delete threw and was caught');

        // приберемо прапорець
        GenericHardDeleteBatch.SIMULATE_DELETE_EXCEPTION = false;
    }
}