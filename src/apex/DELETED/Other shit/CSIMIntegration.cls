global class CSIMIntegration {
    webService static String getCredentials(String objectId, String objectType) {
        Schema.SObjectType targetType = Schema.getGlobalDescribe().get(objectType);
        if(Contact.sObjectType == targetType) {
            return getContact(objectId);
        } else if(Account.sObjectType == targetType) {
            return getAccount(objectId);
        } else if(targetType != null) {
            String eObjectType = escapeString(objectType);
            String eObjectId = escapeString(objectId);
            Schema.DescribeSObjectResult describe = targetType.getDescribe();
            if(describe.fields.getMap().containsKey('ContactId')) {
                List<SObject> result = Database.query('SELECT ContactId FROM ' + eObjectType + ' WHERE Id = \'' + eObjectId + '\'');
                if(!result.isEmpty()) {
                    return getContact(String.valueOf(result.get(0).get('ContactId')));
                }
            } else if(describe.fields.getMap().containsKey('AccountId')) {
                List<SObject> result = Database.query('SELECT AccountId FROM ' + eObjectType + ' WHERE Id = \'' + eObjectId + '\'');
                if(!result.isEmpty()) {
                    return getAccount(String.valueOf(result.get(0).get('AccountId')));
                }
            }
        }
        return '{}';
    }

    webService static String saveActivityObject(String objectId, String objectType, String description, 
                                                Integer duration, String disposition, String direction, 
                                                String serviceName, String adapterUrl, String recordingUrl) {
        Schema.SObjectType targetType = Schema.getGlobalDescribe().get(objectType);

        String contactId = null;
        String whatId = null;
        if(targetType != null) {
            if(targetType == Contact.sObjectType) {
                Contact result = [SELECT Id FROM Contact WHERE Id = :objectId];
                if(result != null) {
                    contactId = objectId;
                }
            } else {
                whatId = objectId;
                Schema.DescribeSObjectResult describe = targetType.getDescribe();
                if(describe.fields.getMap().containsKey('ContactId')) {
                    List<SObject> result = Database.query('Select ContactId from ' + escapeString(objectType) + ' where Id = \'' + escapeString(objectId) + '\'');
                    if(!result.isEmpty()) {
                        contactId = String.valueOf(result.get(0).get('ContactId'));
                    }
                }
            }
        }
        
        List<CallCenter> cc = [Select c.Name From CallCenter c WHERE c.AdapterUrl like:('%' + adapterUrl + '%')];
        Task task = new Task();
        task.ActivityDate = date.today();
        if(!cc.isEmpty()) {
            task.CallObject = cc.get(0).Name;
        }
        task.CallType = direction;
        task.CallDisposition = disposition;
        task.CallDurationInSeconds = duration;
        task.Description = description;
        task.WhatId = whatId;
        task.WhoId = contactId;
        task.Subject = 'Call: ' + serviceName;
        task.Status = 'Completed';
        if(Schema.SObjectType.Task.fields.getMap().containsKey('SPRecordingOrTranscriptURL__c')){
            task.put('SPRecordingOrTranscriptURL__c', recordingUrl);
        }

        Database.SaveResult sr = Database.insert(task);
        return JSON.serialize(sr);
    }
    
    webService static String saveActivityAttribute(String objectId, String key, String value) {
        if(Schema.SObjectType.Task.fields.getMap().containsKey(key)) {
            SObject result = Database.query('SELECT '+ escapeString(key) +' FROM Task where Id = \'' + escapeString(objectId) + '\'');
            result.put(key, value);
            try {
                update result;
                return '{\'result\' : \'success\'}';
            } catch (DmlException e) {
                String message = '';
                for (Integer i = 0; i < e.getNumDml(); i++) {
                    message += e.getDmlMessage(i) + ';'; 
                }
                return '{\'result\' : \'Unable to update task ' + message + '\'}';
            }
        }

        return '{\'result\' : \'undefined field: ' + key + '\'}';
    }  
    
    private static String escapeString(String value) {
        return String.escapeSingleQuotes(value);
    }
    
    public static String getCustomSettings(String adapterUrl) {
        List<CallCenter> result = [Select c.CustomSettings From CallCenter c WHERE c.AdapterUrl like:('%' + adapterUrl + '%')];
        if(result.isEmpty()) {
            return '';
        }
        return result.get(0).CustomSettings;
    }      
    
    private static String getAccount(String accountId) {
        List<Account> result = [SELECT Name FROM Account WHERE Id = :accountId];
        if(result.isEmpty()) {
            return '{}';
        }
        return JSON.serialize(result.get(0));
    }

    private static String getContact(String contactId) {
        List<Contact> result = [SELECT FirstName, LastName FROM Contact where Id = :contactId];
        if(result.isEmpty()) {
            return '{}';
        }
        return JSON.serialize(result.get(0));
    }  
}