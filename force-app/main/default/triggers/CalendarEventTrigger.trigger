trigger CalendarEventTrigger on Calendar_Event__e (after insert) {
    CalendarEventTriggerHandler.afterInsert(Trigger.new);
}