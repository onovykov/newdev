public with sharing class ERPInboundController {

    public static void handle(
        RestRequest request,
        RestResponse response
    ) {

        String rawJson =
            request.requestBody == null
            ? null
            : request.requestBody.toString();

        if (String.isBlank(rawJson)) {

            response.statusCode = 400;
            response.responseBody =
                Blob.valueOf(
                    '{"status":"EMPTY_PAYLOAD"}'
                );

            return;
        }

        if (!rawJson.trim().startsWith('{')) {

            response.statusCode = 400;
            response.responseBody =
                Blob.valueOf(
                    '{"status":"INVALID_JSON"}'
                );

            return;
        }

        try {

            JSON.deserializeUntyped(rawJson);

        } catch (Exception e) {

            response.statusCode = 400;
            response.responseBody =
                Blob.valueOf(
                    '{"status":"INVALID_JSON_FORMAT"}'
                );

            return;
        }

        InboundBatchCoordinator.Result r =
            InboundBatchCoordinator.acceptPart(rawJson);

        response.statusCode = r.httpStatus;
        response.responseBody =
            Blob.valueOf(r.responseBody);
    }
}