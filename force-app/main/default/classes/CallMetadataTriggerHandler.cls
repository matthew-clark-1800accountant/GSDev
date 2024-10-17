public with sharing class CallMetadataTriggerHandler {
    public static void afterInsert(List<Call_Metadata__c> calls){
        ProcessCallMetadataBatchable bat = new ProcessCallMetadataBatchable(new List<Id>(new Map<Id, Call_Metadata__c>(calls).keySet()));
        Database.executeBatch(bat, 20);
    }
}