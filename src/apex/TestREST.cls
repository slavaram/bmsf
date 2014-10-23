@RestResource(urlMapping='/restme/*')
global with sharing class TestREST {

	@HttpGet
	global static void doGet() {
		RestRequest req		= RestContext.request;
		RestResponse res	= RestContext.response;
		JSONParser parser	= JSON.createParser(EncodingUtil.base64Decode(req.requestBody.get()));
		
		
	}

	@HttpPost
	global static void doPost() {
		RestRequest req		= RestContext.request;
		RestResponse res	= RestContext.response;
		
	}

}