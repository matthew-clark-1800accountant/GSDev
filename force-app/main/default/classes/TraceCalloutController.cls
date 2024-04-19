public with sharing class TraceCalloutController {
    public List<String> userIds = new List<String>();
    public List<String> classIds = new List<String>();
    public String userDebugLevel;
    public String classDebugLevel;

    public TraceCalloutController(List<String> users, List<String> classes) {
        this.userIds = users;
        this.classIds = classes;
    }

    public TraceCalloutController(){
        List<Enhanced_Logging_Settings__mdt> settings = [SELECT Label, Setting_Type__c, Value__c FROM Enhanced_Logging_Settings__mdt];
        for(Enhanced_Logging_Settings__mdt setting : settings){
            if(setting.Setting_Type__c == 'User to Trace'){
                this.userIds.add(setting.Value__c);
            } else if (setting.Setting_Type__c == 'Class to Trace'){
                this.classIds.add(setting.Value__c);
            } else if (setting.Setting_Type__c == 'User Log Level'){
                this.userDebugLevel = setting.Value__c;
            } else if (setting.Setting_Type__c == 'Class Log Level'){
                this.classDebugLevel = setting.Value__c;
            }
        }
        System.debug(this.userIds);
        System.debug(this.classIds);
        System.debug(this.userDebugLevel);
        System.debug(this.classDebugLevel);

        // String guestUser = '00502000001iR5k';
        // String integrationUser = '0055f0000057vXuAAI';
        // String processUser = '0055f0000057vXrAAI';
        // String spotterUser = '00502000001iasW';
        // String horizonUser = '0055f000006ghJz';
        // String dbUser = '00502000001lT4Y';
        
        // String spotterApiController = '01p02000000FMEP';
        // String syncUserToSpotter = '01p02000000FZ5u'; 

        // this.userIds = new List<String>{
        //     guestUser,
        //     integrationUser,
        //     processUser,
        //     spotterUser,
        //     horizonUser,
        //     dbUser
        // };

        // this.classIds = new List<String>{
        //     spotterApiController,
        //     syncUserToSpotter
        // };
    }
    public void manageFlags(){
        TraceCalloutController.addFlags(this.userIds, this.classIds, this.userDebugLevel, this.classDebugLevel);
    }

    @future(callout=true)
    public static void addFlags(List<String> userIds, List<String> classIds, String userDebugLevel, String classDebugLevel){
        System.debug('TraceCalloutController.addFlags()');
        System.debug(userIds);
        System.debug(classIds);
        if(userIds.size()>0 && classIds.size()>0){
            ToolingAPIController.addUserTraceFlags(userIds, userDebugLevel);
            ToolingAPIController.addClassTraceFlags(classIds, classDebugLevel);
        }
        ToolingAPIController.deleteOldFlags();
        System.enqueueJob(new QueueableDeleteLogs());
    }
    
}