public with sharing class ManagerReassignmentsReport {
    public ManagerReassignmentsReport() {

    }

    public static void getData(){
        Map<Id, Event_Field_Update__c> historyIdToUpdate = new Map<Id, Event_Field_Update__c>();
        Map<Event, Event_Field_Update__c> eventToUpdate = new Map<Event, Event_Field_Update__c>();
        List<Event_Field_Update__c> updatesToUpdate = new List<Event_Field_Update__c>();
        for(Event_Field_Update__c up : [SELECT Id, CreatedDate, Event_History__r.Id FROM Event_Field_Update__c WHERE CreatedDate = LAST_90_DAYS]){
            historyIdToUpdate.put(up.Event_History__r.Id, up);
        }
    }
}