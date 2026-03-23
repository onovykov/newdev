@IsTest
global class ERPWebServiceMock implements WebServiceMock {

    global String mode;

    global ERPWebServiceMock(String mode) {
        this.mode = mode;
    }

    global void doInvoke(
        Object stub,
        Object request,
        Map<String, Object> response,
        String endpoint,
        String soapAction,
        String requestName,
        String responseNS,
        String responseName,
        String responseType
    ) {

        if (requestName == 'LoginEx') {

            SFToERP.LoginExResponse_element resp = new SFToERP.LoginExResponse_element();

            if (mode == 'LOGIN_EXCEPTION') {
                throw new CalloutException('Login failed');
            }

            if (mode == 'EMPTY_TICKET') {
                resp.LoginExResult = '{"Success":true,"Ticket":""}';
            } else {
                resp.LoginExResult = '{"Success":true,"Ticket":"abc123"}';
            }

            response.put('response_x', resp);
        }

        else if (requestName == 'ExecuteEx') {

            SFToERP.ExecuteExResponse_element resp = new SFToERP.ExecuteExResponse_element();

            if (mode == 'EXEC_EXCEPTION') {
                throw new CalloutException('Execute failed');
            }

            if (mode == 'EXEC_FAILURE') {
                resp.ExecuteExResult = '{"Success":false,"Comments":"ERP failed"}';
            }
            else if (mode == 'JSON_ERROR') {
                resp.ExecuteExResult = 'INVALID_JSON';
            }
            else {
                resp.ExecuteExResult = '{"Success":true,"Comments":"OK"}';
            }

            response.put('response_x', resp);
        }
    }
}