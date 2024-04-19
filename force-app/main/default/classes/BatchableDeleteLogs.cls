public with sharing class BatchableDeleteLogs implements Database.Batchable<sObject>, Database.AllowsCallouts {
    String query = 'select Id, Application, DurationMilliseconds, LogLength, StartTime, Status from ApexLog where StartTime < TODAY AND Status = \'Success\'';
    
    public BatchableDeleteLogs() {

    }

    public Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(query);
     }
  
    public void execute(Database.BatchableContext BC, List<sObject> scope){
        //String userToTrace = System.UserInfo.getUserId();
        String endPoint = URL.getSalesforceBaseUrl().toExternalForm()+'/services/data/v43.0/tooling/sobjects/ApexLog/';
        HttpRequest req; 
        HttpResponse res; 
        Http h; 

        for(Sobject s : scope){
            try {
                ApexLog log = (ApexLog) s;
                req = new HttpRequest(); 
                req.setHeader('Authorization', 'Bearer ' + ToolingAPIController.getToolingToken()); 
                req.setEndpoint(endPoint + log.id + '/'); 
                req.setMethod('DELETE'); 
                h = new Http(); 
                res = h.send(req); 
                System.debug(res.getBody());
            } catch (Exception ex){
                System.debug(ex.getMessage());
            }
        }
    }
  
    public void finish(Database.BatchableContext BC){
  
    }
}