@RestResource(urlMapping='/RESTAccount/*')
global with sharing class TestREST {

	@HttpGet
	global static void createAccount() {
		RestRequest request = RestContext.request;
		String accountName = request.params.get('code');
		String accountEmail = request.params.get('state');
		Case cas = new Case(Subject = accountName, Description = accountEmail);
		insert cas;
	}

	@HttpPost
	global static void createAccount2(String code, String state) {
		RestRequest request = RestContext.request;
		String accountName = request.params.get('code');
		String accountEmail = request.params.get('state');
		Case cas = new Case(Subject = accountName, Description = accountEmail);
		insert cas;
	}

}