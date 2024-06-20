public with sharing class CalendarEventTriggerHandler {

    public static void afterInsert(List<Calendar_Event__e> updatedEvents){
        System.debug('CalendarEventTriggerHandler.afterInsert');
        syncToApiFuture(updatedEvents);
    }

    //@future(callout=true)
    public static void syncToApiFuture(List<Calendar_Event__e> updatedEvents){
        System.debug('CalendarEventTriggerHandler.syncToApiFuture');
        
        List<ApiCalloutWrapper> eventWrappers = new List<ApiCalloutWrapper>();
        for(Calendar_Event__e e : updatedEvents){
            ApiCalloutWrapper wrapper = new ApiCalloutWrapper();
            wrapper.eventId = e.Event_Record_Id__c;
            wrapper.isUpdate = e.IsUpdate__c;
            wrapper.eventData = new EventWrapper(e);
            eventWrappers.add(wrapper);
        }
        System.debug(eventWrappers);
        syncToApiSynch(eventWrappers);
    }

    public static void syncToApiSynch(List<ApiCalloutWrapper> events){
        System.debug('CalendarEventTriggerHandler.syncToApiSynch');
        while(events.size() > 0){
            List<ApiCalloutWrapper> sublist = new List<ApiCalloutWrapper>();
            Integer eventsSize = events.size();
            for(Integer i=0; i<(Math.min(100, eventsSize)); i++){
                sublist.add(events.remove(0));
            }
            makeApiCallout(JSON.serialize(sublist));
        }
    }

    @future(callout=true)
    public static void makeApiCallout(String body){
        if(!Test.isRunningTest()){
            System.debug('CalendarEventTriggerHandler.makeApiCallout');
            System.debug(body);
            String endPoint = 'callout:X1800Accountant_SFAPI/schedule/alleventcache.php';
            //String escapedQuery = EncodingUtil.urlEncode(query, 'UTF-8');
            HttpRequest req; 
            HttpResponse res; 
            Http h; 
    
    
            req = new HttpRequest(); 
            req.setEndpoint(endPoint); 
            req.setMethod('POST'); 
            req.setBody(body);
            h = new Http(); 
            res = h.send(req); 
            System.debug(res.getBody());
        }
    }


    public class ApiCalloutWrapper{
        public Id eventId;
        public Boolean isUpdate;
        public EventWrapper eventData;
    }

    public class EventWrapper{
        public Id OwnerId;
        public Datetime StartDateTime;
        public Datetime EndDateTime;
        public String ShowAs;
        public String Type_of_Appointment;
        public String Subject;

        public EventWrapper(Calendar_Event__e ev){
                this.OwnerId = ev.OwnerId__c;
                this.StartDateTime = ev.StartDateTime__c;
                this.EndDateTime = ev.EndDateTime__c;
                this.ShowAs = ev.ShowAs__c;
                this.Type_of_Appointment = ev.Type_of_Appointment__c;
                this.Subject = ev.Subject__c;
        }
    }

}