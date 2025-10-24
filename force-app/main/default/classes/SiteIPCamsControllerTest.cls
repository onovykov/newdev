@isTest
private class SiteIPCamsControllerTest {
    @isTest
    static void testGetCameraSettings() {
        Test.startTest();
        List<Site_IPCams_Setting__mdt> results = SiteIPCamsController.getCameraSettings();
        Test.stopTest();
    }

    @isTest static void testGetCameraCredentials() {
        // Set up test data
        IPCams_Credentials__c testCreds = new IPCams_Credentials__c(
            Login__c = 'testuser',
            Password__c = 'testpassword'
        );
        insert testCreds;

        // Call the method
        Test.startTest();
        String result = SiteIPCamsController.getCameraCredentials();
        Test.stopTest();
    }
}