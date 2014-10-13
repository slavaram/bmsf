@isTest
public class AttachmentProcessTest {

	public testmethod static void test() {
		Account acc = new Account(Name = 'Test acc');
		insert acc;
		Attachment attach = new Attachment(ParentId = acc.Id, Name = 'Tets attach', Body = Blob.valueOf('test'));
		insert attach;
	}

}