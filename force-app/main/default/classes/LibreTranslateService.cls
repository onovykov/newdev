public with sharing class LibreTranslateService {

    private static final String ENDPOINT = 'callout:LibreTranslate_NC/translate';

    public static String translate(
        String text,
        String sourceLang,
        String targetLang
    ) {
        if (String.isBlank(text)) {
            return text;
        }

        HttpRequest req = new HttpRequest();
        req.setEndpoint(ENDPOINT);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');

        Map<String, Object> payload = new Map<String, Object>{
            'q'      => text,
            'source' => String.isBlank(sourceLang) ? 'auto' : sourceLang,
            'target' => targetLang,
            'format' => 'text'
        };

        req.setBody(JSON.serialize(payload));

        HttpResponse res = new Http().send(req);

        if (res.getStatusCode() != 200) {
            throw new CalloutException(
                'LibreTranslate error: ' + res.getStatus() + ' ' + res.getBody()
            );
        }

        LibreTranslateResponse response =
            (LibreTranslateResponse) JSON.deserialize(
                res.getBody(),
                LibreTranslateResponse.class
            );

        return response.translatedText;
    }

    /* === HELPERS === */
    //--- Визначаємо мову юзера
    public static String getUserLng(Id userId) {
        String result = '';
        if(userId==null) return result;
        User u = UserRepository.getById(userId);
        if(u!=null) {
            result = u.LanguageLocaleKey.left(2);
        }
        return result;
    }

    //--- Мова поточного юзера
    public static String getCurUserLng() {
        return UserUtils.getUserLanguage().left(2);
    }
}