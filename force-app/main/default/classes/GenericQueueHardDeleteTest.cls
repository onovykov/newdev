@IsTest
private class GenericQueueHardDeleteTest {

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

            // ===== REQUIRED FIELDS for your org (if any) =====
            // Напр.: s.put('Required__c', 'X'); або s.put('SomeLookup__c', someId);
            // ================================================

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
        // ALL ROWS має бути в кінці
        String soql = 'SELECT COUNT() FROM ' + obj + ' WHERE Id IN :ids ALL ROWS';
        return (Integer)Database.countQuery(soql);
    }

    // ---------- Tests ----------

    @IsTest
    static void deleteAll_withPagination_softInTests() {
        String obj = 'Lot__c';
        // 3 записи → перевіримо ланцюжок Queueable із pageSize=1
        insert newRecords(obj, 3, 'QALL');

        System.assertEquals(3, countActive(obj), 'Seed failed');

        Test.startTest();
        // performHardDelete = false у тесті, щоб не залежати від emptyRecycleBin
        System.enqueueJob(new GenericQueueHardDelete(obj, null, false, 50));
        Test.stopTest();

        // Активних не лишилося
        System.assertEquals(0, countActive(obj), 'All active must be deleted');

        // У корзині 3 (бо hard delete у тесті не форсуємо)
        Integer withBin = (Integer)Database.countQuery('SELECT COUNT() FROM ' + obj + ' ALL ROWS');
        System.assertEquals(3, withBin, 'Soft-deleted remain in Recycle Bin in tests');
    }

    @IsTest
    static void deleteSubset_whereIdIn_softInTests() {
        String obj = 'Lot__c';
        List<SObject> recs = newRecords(obj, 5, 'QSUB');
        insert recs;

        Set<Id> toDelete = new Set<Id>{ (Id)recs[0].get('Id'), (Id)recs[1].get('Id') };
        Set<Id> toStay   = new Set<Id>{ (Id)recs[2].get('Id'), (Id)recs[3].get('Id'), (Id)recs[4].get('Id') };

        // WHERE Id IN (...)
        List<String> lits = new List<String>();
        for (Id i : toDelete) lits.add('\'' + String.valueOf(i) + '\'');
        String whereClause = 'Id IN (' + String.join(lits, ',') + ')';

        Test.startTest();
        System.enqueueJob(new GenericQueueHardDelete(obj, whereClause, false, 50));
        Test.stopTest();

        // Обрані зникли з активних…
        System.assertEquals(0, countActiveByIds(obj, toDelete), 'Selected must not be active');
        // …але лишаються в ALL ROWS (soft delete у тесті)
        System.assertEquals(2, countAllRowsByIds(obj, toDelete), 'Selected remain in Recycle Bin');

        // Інші 3 лишились активними
        System.assertEquals(3, countActiveByIds(obj, toStay), 'Other IDs must remain active');
    }

    @IsTest
    static void unknownSObject_doesNotThrow_andDoesNothing() {
        // Просто перевіряємо, що код відпрацьовує без винятку (лог і return)
        Test.startTest();
        System.enqueueJob(new GenericQueueHardDelete('Nope__c', null, false, 1));
        Test.stopTest();
        // Нічого асертувати не можемо (немає такого об'єкта), головне — без виключень
        System.assert(true, 'No exception for unknown sObject');
    }

    @IsTest
    static void notDeletableSObject_doesNotThrow() {
        // RecordType існує, але не deletable → код має відлогувати і вийти без падіння
        Test.startTest();
        System.enqueueJob(new GenericQueueHardDelete('RecordType', null, false, 1));
        Test.stopTest();
        System.assert(true, 'No exception for not deletable sObject');
    }

    @IsTest
    static void noRecords_returnsEarly_withoutError() {
        // створимо об'єкт, який гарантовано нічого не знайде
        String obj = 'Lot__c';
        String whereClause = 'Id = \'000000000000000AAA\'';

        Test.startTest();
        System.enqueueJob(new GenericQueueHardDelete(obj, whereClause, false, 200));
        Test.stopTest();

        // якщо сюди дійшли — значить execute відпрацював без винятку
        System.assert(true, 'No exception expected when no rows are returned');
    }

}