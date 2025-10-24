public class EmailQuotaApprovalLinkController {
    public Id headerId {get; set;}
    public String user {get; set;}

    private static final String QUOTA_APPROVAL_PATH = '/s/quota-approval?';
    private static final String PARAMS_URL_SEPARATOR = '&';

    public EmailQuotaApprovalLinkController() {}

    public String linkAddress { 
        get {
            if (headerId != null && user != null) {
                String baseURL = Label.Portal_URL + QUOTA_APPROVAL_PATH;
                String id = 'Id=' + headerId;
                String userId = 'user=' + user;

                return baseURL + CryptoUtils.getCryptoEncodedURLString(id + PARAMS_URL_SEPARATOR + userId);
            } else {
                return '';
            }
        }
        set;
    }
}