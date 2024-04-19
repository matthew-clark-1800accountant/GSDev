public with sharing class TraceFlagScheduler implements Schedulable {
    public TraceFlagScheduler() {

    }
    
    public void execute(SchedulableContext sc){
        new TraceCalloutController().manageFlags();
    }

}