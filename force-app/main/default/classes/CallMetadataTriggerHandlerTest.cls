@IsTest
public with sharing class CallMetadataTriggerHandlerTest {
    @TestSetup
    static void makeData(){
        Account acc = new Account(Name='Test Account');
        insert acc;
        Opportunity opp = new Opportunity(name='Test Opp', AccountId = acc.Id, StageName='New');
        insert opp;
        Contact con = new Contact(FirstName='Test', LastName='Contact', AccountId=acc.Id);
        insert con;
    }


    @IsTest
    public static void insertMetadata() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        //Integer cdlCount = [SELECT COUNT() FROM ContentDocumentLink];
        Integer noteCount = [SELECT COUNT() FROM ContentVersion];
        Integer callCount = 20;
        Test.startTest();
        List<NVMStatsSF__NVM_Call_Summary__c> summaries = new List<NVMStatsSF__NVM_Call_Summary__c>();
        List<Call_Metadata__c> calls = new List<Call_Metadata__c>();
        for(Integer i=0; i<callCount; i++){
            summaries.add(new NVMStatsSF__NVM_Call_Summary__c(NVMStatsSF__CallGuid__c = String.valueOf(i), NVMStatsSF__Related_Opportunity__c=opp.Id, NVMStatsSF__Related_Contact__c = con.Id));
            calls.add(new Call_Metadata__c(Account__c =acc.Id, Contact__c=con.Id, Opportunity__c=opp.Id, Action_Items__c='abc', VCC_ID__c= String.valueOf(i)));
            System.debug(calls[i]);
        }
        insert summaries;
        insert calls;
        Test.stopTest();
        List<Id> linkedIds = new List<Id>{acc.Id, opp.Id, con.Id, UserInfo.getUserId()};
        for(Call_Metadata__c call : calls){ linkedIds.add(call.Id); }
        //Each call's note should be linked to 5 records (Account, Opportunity, Contact, Call Metadata, and User (owner))
        Assert.areEqual(callCount * 5, [SELECT COUNT() FROM ContentDocumentLink WHERE LinkedEntityId IN :linkedIds]);// - cdlCount);
        Assert.areEqual(callCount, [SELECT COUNT() FROM ContentVersion] - noteCount);
    }
}