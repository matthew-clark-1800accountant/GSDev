trigger CallMetadataTrigger on Call_Metadata__c (after insert) {
    CallMetadataTriggerHandler.afterInsert(Trigger.new);
}