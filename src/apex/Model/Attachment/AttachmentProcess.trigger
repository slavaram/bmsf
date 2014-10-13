trigger AttachmentProcess on Attachment (before insert) {

	for (Attachment attach : trigger.new) {
		if ((attach.Name.contains('.rar') || attach.Name.contains('.zip') || attach.Name.contains('.exe'))
				&& attach.ParentId.getSObjectType().getDescribe().getName() == 'EmailMessage') {
			attach.Body = Blob.valueOf('original file body was deleted by salesforce email firewall system');
		}
	}

}