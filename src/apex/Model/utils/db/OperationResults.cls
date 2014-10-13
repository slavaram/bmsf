public class OperationResults {

	public Boolean			mIsOperationSuccessful	{get; set;}
	public List<String>		mErrorMessages			{get; private set;}
	public List<Exception>	mExceptions				{get; private set;}
	public List<Object>		mReturnedObjects		{get; private set;}

	public OperationResults(Boolean isOperationSuccessful) {
		mIsOperationSuccessful = isOperationSuccessful;
		mErrorMessages = new List<String>();
		mExceptions = new List<Exception>();
		mReturnedObjects = new List<Object>();
	}

}