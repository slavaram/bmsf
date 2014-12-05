public class EmailManager implements Messaging.InboundEmailHandler {

	public Messaging.InboundEmailResult handleInboundEmail(Messaging.inboundEmail email, Messaging.InboundEnvelope envelope) {
		Messaging.InboundEmailResult result	= new Messaging.InboundEmailResult();
		result.success						= true;
		List<Account> accounts				= [SELECT Id FROM Account WHERE PersonEmail = :email.fromAddress];
		if (accounts.isEmpty()) {
			System.debug('Unknown email!');
		} else {
			Case cas = new Case(AccountId	= accounts.get(0).Id,
								Origin		= 'Email');
			insert cas;
			System.debug('Email Id -> ' + email.messageId);
			/*EmailMessage ema = new EmailMessage(HasAttachment	= (envelope == null ? false : true),
												CcAddress		= email.ccAddresses,
												FromAddress		= email.fromAddress,
												FromName		= email.fromName,
												Headers			= email.headers,
												HtmlBody		= email.htmlBody,
												Incoming		= true,
												IsDeleted		= false,
												MessageDate		= System.now(),
												ParentId		= cas.Id,
												Status			= 'New',
												Subject			= );*/
			
		}
		System.debug('Email Id -> ' + email.messageId);
		return result;
	}

}