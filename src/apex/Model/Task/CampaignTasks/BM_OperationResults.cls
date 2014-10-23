public class BM_OperationResults {

	public Boolean isOperationSuccessful	{get; set;}
	public List<String> errorMessages		{get; private set;}
	public List<Exception> exceptions		{get; private set;}
	public List<Object> returnedObjects		{get; private set;}

	public BM_OperationResults(Boolean operationSuccessful) {
		isOperationSuccessful	= operationSuccessful;
		errorMessages			= new List<String>();
		exceptions				= new List<Exception>();
		returnedObjects			= new List<Object>();
	}

}