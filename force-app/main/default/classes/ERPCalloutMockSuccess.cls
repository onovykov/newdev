@IsTest
global class ERPCalloutMockSuccess
implements WebServiceMock {

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

        String mockResponse =
        '{"Status": true, "ErrorMessage": ""}';

        response.put(
            'response_x',
            JSON.deserializeUntyped(mockResponse)
        );
    }
}