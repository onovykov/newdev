@RestResource(urlMapping = '/ERPtoSF/v1/*')
global with sharing class ERPtoSF {

	@HttpPost
	global static void postCST() {
		RestRequest request = RestContext.request;
		RestResponse response = RestContext.response;
		ERPMessageHandler.postCSTfromHelper(request, response);
	}
}