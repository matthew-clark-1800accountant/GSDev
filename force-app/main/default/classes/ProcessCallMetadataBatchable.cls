public without sharing class ProcessCallMetadataBatchable  implements Database.Batchable<sObject> {
    List<Id> metadataIds;
    public ProcessCallMetadataBatchable(List<Id> ids){
        metadataIds = ids;
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC){
        String query = 'SELECT Id, Agent_Call_Summary__c, Action_Items__c, Account__c, Opportunity__c, Contact__c FROM Call_Metadata__c WHERE Id IN :metadataIds';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<Call_Metadata__c> scope){
        System.debug('ProcessCallMetadataBatchable start');
        List<ContentVersion> notes = new List<ContentVersion>();
        for(Call_Metadata__c call : scope){
            String templateCallText = call.Agent_Call_Summary__c + call.Action_Items__c;
            String title = 'TSA Consultation Summary and Action Items';
            ContentVersion cv = new ContentVersion();
            cv.title = title;      
            cv.VersionData =Blob.valueOf(templateCallText);
            cv.PathOnClient= call.Id+' Call Notes'+'.snote'; //<your file title>.snote 
            notes.add(cv);
        }
        System.debug('ProcessCallMetadataBatchable inserting contentversions');
        insert notes;
        Map<Id, Id> versionIdToDocumentId = new Map<Id, Id>();
        for (ContentVersion version : [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN :(new Map<Id, ContentVersion>(notes).keySet())]){
            versionIdToDocumentId.put(version.Id, version.ContentDocumentId);
        }
        
        Map<Id, List<Id>> noteIdToRelatedIds = new Map<Id, List<Id>>();
        for(Integer i=0; i<notes.size(); i++){
            Call_Metadata__c call = scope[i];
            ContentVersion note = notes[i];
            noteIdToRelatedIds.put(note.Id, new List<Id>{call.Id});
            System.debug(call);
            if(call.Account__c != null){
                noteIdToRelatedIds.get(note.Id).add(call.Account__c);
            }
            if(call.Opportunity__c != null){
                noteIdToRelatedIds.get(note.Id).add(call.Opportunity__c);
            }
            if(call.Contact__c != null){
                noteIdToRelatedIds.get(note.Id).add(call.Contact__c);
            } 
            System.debug(noteIdToRelatedIds.get(note.Id));
        }

        
        List<ContentDocumentLink> links = new List<ContentDocumentLink>();
        for(Id versionId : noteIdToRelatedIds.keySet()){
            for(Id relatedId : noteIdToRelatedIds.get(versionId)){
                ContentDocumentLink cdl = new ContentDocumentLink();
                cdl.ContentDocumentId = versionIdToDocumentId.get(versionId);
                cdl.LinkedEntityId = relatedId;
                cdl.ShareType = 'V';//'I'; //Changed from C
                cdl.Visibility = 'SharedUsers';//'InternalUsers';    //changed from AllUsers
                links.add(cdl); 
            }
        }
        System.debug('ProcessCallMetadataBatchable inserting contentdocumentlinks');
        insert links;
    }

    public void finish(Database.BatchableContext BC){
  
    }
}