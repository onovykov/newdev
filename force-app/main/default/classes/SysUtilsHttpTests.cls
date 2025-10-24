@IsTest
private class SysUtilsHttpTests {

    // ---------------------------
    // Моки HTTP для різних сценаріїв
    // ---------------------------

    // 1) Пагінація: сторінка 1 -> nextRecordsUrl -> сторінка 2
    private class QueryPagedMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            String url = req.getEndpoint();

            // перша сторінка: query?q=...
            if (url.contains('/services/data/v62.0/query?q=')) {
                res.setStatusCode(200);
                res.setHeader('Content-Type','application/json');
                res.setBody(
                    '{"totalSize":2,' +
                    ' "done": false,' +
                    ' "records":[{"attributes":{"type":"Account"},"Id":"001000000000001"}],' +
                    ' "nextRecordsUrl":"/services/data/v62.0/query/01gNEXT"}'
                );
                return res;
            }

            // друга (фінальна) сторінка: /query/01gNEXT
            if (url.contains('/services/data/v62.0/query/01gNEXT')) {
                res.setStatusCode(200);
                res.setHeader('Content-Type','application/json');
                res.setBody(
                    '{"totalSize":2,' +
                    ' "done": true,' +
                    ' "records":[{"attributes":{"type":"Account"},"Id":"001000000000002"}]}'
                );
                return res;
            }

            res.setStatusCode(500);
            res.setBody('{"error":"unexpected url for QueryPagedMock"}');
            return res;
        }
    }

    // 2) Порожня відповідь (done:true, records:[])
    private class QueryEmptyMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type','application/json');
            res.setBody('{"totalSize":0, "done": true, "records": []}');
            return res;
        }
    }

    // 3) Помилка 500
    private class QueryErrorMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setHeader('Content-Type','application/json');
            res.setBody('{"message":"boom"}');
            return res;
        }
    }

    // 4) Для deleteOldRecords: повертаємо записи з конкретними Id,
    //    які ми щойно вставили в тесті (щоб видалення справді відбулося)
    private class DeleteOldRecordsMock implements HttpCalloutMock {
        private List<Id> idsToReturn;
        DeleteOldRecordsMock(List<Id> ids) {
            // deepClone() недоступний для List<Id>; зробимо копію явним конструктором
            this.idsToReturn = new List<Id>(ids);
        }

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();

            // Збираємо JSON через Map → JSON.serialize
            Map<String, Object> root = new Map<String, Object>();
            root.put('totalSize', idsToReturn.size());
            root.put('done', true);

            List<Object> records = new List<Object>();
            for (Id theId : idsToReturn) {
                Map<String, Object> rec = new Map<String, Object>();
                rec.put('Id', String.valueOf(theId));
                Map<String, Object> attrs = new Map<String, Object>();
                attrs.put('type', 'Account');
                rec.put('attributes', attrs);
                records.add(rec);
            }
            root.put('records', records);

            res.setStatusCode(200);
            res.setHeader('Content-Type','application/json');
            res.setBody(JSON.serialize(root));
            return res;
        }
    }

    // ---------------------------
    // ТЕСТИ
    // ---------------------------
    @IsTest
    static void test_fetchAllRecords_pagination() {
        Test.setMock(HttpCalloutMock.class, new QueryPagedMock());

        Test.startTest();
        List<SObject> got = SysUtils.fetchAllRecords(
            'Account',
            new List<String>{'Id'},
            ' WHERE Name LIKE \'A%\' ORDER BY CreatedDate ASC'
        );
        Test.stopTest();

        System.assertEquals(2, got.size(), 'Must collect both pages');
        System.assertEquals('Account', got[0].getSObjectType().getDescribe().getName());

        Id id1 = (Id) got[0].get('Id');
        Id id2 = (Id) got[1].get('Id');
        System.assertEquals('001000000000001', String.valueOf(id1).left(15));
        System.assertEquals('001000000000002', String.valueOf(id2).left(15));
    }

    @IsTest
    static void test_fetchAllRecords_error_throws() {
        Test.setMock(HttpCalloutMock.class, new QueryErrorMock());

        Boolean thrown = false;
        try {
            Test.startTest();
            SysUtils.fetchAllRecords('Account', new List<String>{'Id'}, ' WHERE Name LIKE \'A%\'');
            Test.stopTest();
        } catch (Exception e) {
            thrown = true;
            System.assert(e.getMessage().contains('Error:'), 'Should throw CalloutException with error text');
        }
        System.assertEquals(true, thrown, 'Expected an exception on non-200 response');
    }

    @IsTest
    static void test_deleteOldRecords_success_deletes() {
        // Готуємо реальні записи, які потім "поверне" мок і метод видалить
        Account a1 = new Account(Name='A1');
        Account a2 = new Account(Name='A2');
        insert new List<Account>{a1, a2};
        List<Id> ids = new List<Id>{a1.Id, a2.Id};

        // Мок поверне саме ці Id
        Test.setMock(HttpCalloutMock.class, new DeleteOldRecordsMock(ids));

        Test.startTest();
        // nYears будь-яке додатне; метод сам порахує dateTo
        SysUtils.deleteOldRecords('Account', 1);
        Test.stopTest();

        // Перевіряємо, що записи справді видалені
        List<Account> stillThere = [SELECT Id FROM Account WHERE Id IN :ids];
        System.assertEquals(0, stillThere.size(), 'Records must be deleted by deleteOldRecords');
    }

    @IsTest
    static void test_deleteOldRecords_emptyResponse_keepsRecords() {
        Account a = new Account(Name='KeepMe');
        insert a;

        Test.setMock(HttpCalloutMock.class, new QueryEmptyMock());

        Test.startTest();
        SysUtils.deleteOldRecords('Account', 1);
        Test.stopTest();

        // Нічого не видалилось — бо fetchAllRecords повернув 0 записів
        Account again = [SELECT Id, Name FROM Account WHERE Id = :a.Id];
        System.assertEquals('KeepMe', again.Name);
    }
}