public without sharing class CalendarEventBatchable implements Database.batchable<sObject>{

    List<Id> userIds;

    public CalendarEventBatchable(List<Id> inputIds){
        System.debug(inputIds);
        userIds = inputIds;
        System.debug('CalendarEventBatchable.CalendarEventBatchable()');
    }

    public Database.QueryLocator start(Database.BatchableContext BC){
        Datetime startTime = Datetime.now();
        List<Id> userIdList = userIds;
        String query = 'SELECT Id FROM Event WHERE StartDateTime >= :startTime '
        +'AND OwnerId IN :userIdList';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<Event> scope){        
        System.debug(scope.size());
        delete scope;
    }

    public void finish(Database.BatchableContext BC){}

    @InvocableMethod(label='Sync Future Calendar Events')
    public static void startBatch(List<List<Id>> userIds){
        if(!userIds.isEmpty()){
            CalendarEventBatchable bat = new CalendarEventBatchable(userIds[0]);
            Database.executeBatch(bat);
        }
    }
}