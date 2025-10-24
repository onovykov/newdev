@isTest
global class SendPostFromFlowTest {
	@IsTest
    static void sendPostTest() {        
        List<String> test = new List<String>{'test'};
        SendPostFromFlow.sendPost(test);
    }
}