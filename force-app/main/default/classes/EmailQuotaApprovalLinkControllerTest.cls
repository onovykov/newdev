@isTest
public class EmailQuotaApprovalLinkControllerTest {
    private static final String HEADER_ID = 'a3l000000000001aaa';
    private static final String USER_ID = '005000000000001aaa';
    private static final String QUOTA_APPROVAL_PATH = '/s/quota-approval?';

    @isTest
    public static void linkAddress_emptyParams_nullLink() {
        Test.startTest();
        EmailQuotaApprovalLinkController linkController = new EmailQuotaApprovalLinkController();
        String linkAddress = linkController.linkAddress;
        Test.stopTest();

        Assert.isTrue(String.isEmpty(linkAddress), 'There should be an empty link string');
    }

    @isTest
    public static void linkAddress_Private_Success() {
        Test.startTest();
        EmailQuotaApprovalLinkController linkController = new EmailQuotaApprovalLinkController();
        linkController.headerId = HEADER_ID;
        linkController.user = USER_ID;
        String linkAddress = linkController.linkAddress;
        Test.stopTest();

        Assert.isTrue(!String.isEmpty(linkAddress), 'There should be a link string');
        Assert.isTrue(linkAddress.contains(QUOTA_APPROVAL_PATH), 'The link should contain a reference to quota approval page');
        Assert.isTrue(linkAddress.contains(Label.Portal_URL), 'The link should contain the portal url');
    }
}