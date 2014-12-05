@isTest
private class Test_CSIMIntegration {

  static testMethod void unitTest() {
  
        //test Account
    
        Account newAccount = new Account(Name = 'Test Account name');
        try {
            insert newAccount;
        } catch( Exception ex ){}        
        CSIMIntegration.getCredentials(newAccount.Id, 'Account');
        CSIMIntegration.getCredentials('undefined', 'Account'); 
        
         //test Contact  
        Contact newContact = new Contact(FirstName = 'Test First Name', LastName = 'Test Last Name');
        try {
            insert newContact;
        } catch( Exception ex ){}
        
        CSIMIntegration.getCredentials(newContact.Id, 'Contact');
        CSIMIntegration.getCredentials('undefined', 'Contact'); 
        CSIMIntegration.getCredentials('undefined', 'undefined');
        CSIMIntegration.getCustomSettings('sdf');
        CSIMIntegration.saveActivityObject(newContact.id, 'Contact', 'description', 32, 'disposition', 'Inbound', 'service name', 'adapter url', 'rec url');
        CSIMIntegration.saveActivityObject(newAccount.id, 'Account', 'description', 32, 'disposition', 'Inbound', 'service name', 'adapter url', 'rec url');
        
    
        //test Case
        Task newTask = new Task();
        try {
            insert newTask;
        } catch( Exception ex ){}        
        CSIMIntegration.getCredentials(newTask.Id, 'Task');
        CSIMIntegration.saveActivityAttribute(newTask.id, 'CallDisposition', 'new name');
  }
}