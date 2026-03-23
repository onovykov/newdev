@IsTest
global class TestHttpMock implements HttpCalloutMock {

    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(200);
        res.setBody('{"Success":true,"Comments":"OK"}');
        return res;
    }
}