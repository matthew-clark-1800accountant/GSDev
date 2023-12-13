public without sharing class BackfillEventUpdatesBatchable implements Database.batchable<sObject>{

    public BackfillEventUpdatesBatchable() {
        System.debug('BackfillEventUpdatesBatchable()');
    }

    public Database.QueryLocator start(Database.BatchableContext BC){
        System.debug('start()');
        String query = 'SELECT Id, CreatedDate, Event_History__r.Id FROM Event_Field_Update__c WHERE CreatedDate = LAST_90_DAYS';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<Event_Field_Update__c> scope){        
        System.debug('execute');
        System.debug(scope);
        Map<Id, Event_Field_Update__c> historyIdToUpdate = new Map<Id, Event_Field_Update__c>();
        Map<Event, Event_Field_Update__c> eventToUpdate = new Map<Event, Event_Field_Update__c>();
        List<Event_Field_Update__c> updatesToUpdate = new List<Event_Field_Update__c>();
        for(Event_Field_Update__c up : scope){
            historyIdToUpdate.put(up.Event_History__r.Id, up);
        }
        List<Event> eventList = [SELECT Id, StartDateTime, EndDateTime, Event_History__r.Id FROM Event WHERE Event_History__r.Id IN :historyIdToUpdate.keySet()];
        
        System.debug(eventList);
        for(Event ev : eventList){
            Event_Field_Update__c up = historyIdToUpdate.get(ev.Event_History__r.Id);
            if(up.CreatedDate > ev.startDateTime.addMinutes(-15) && up.CreatedDate < ev.EndDateTime){
                up.Update_made_in_change_window__c = true;
                updatesToUpdate.add(up);
            }
        }
        update updatesToUpdate;
    }

    public void finish(Database.BatchableContext BC){
        System.debug('finish');
    }
}