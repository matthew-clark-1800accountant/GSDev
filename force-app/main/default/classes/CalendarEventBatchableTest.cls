@IsTest
public with sharing class CalendarEventBatchableTest {
    @TestSetup
    static void makeData(){
        Id currentUserId = UserInfo.getUserId();
        
        String uniqueIdentifier = String.valueOf(Datetime.now().getTime());
        
        Lead testLead = new Lead(
            FirstName='Jon',
            LastName='Doe',
            Company='TestCompany',
            Email='test' + uniqueIdentifier + '@examplecewh.com',
            Phone='555' + uniqueIdentifier,
            LeadSource='1-800Accountant',
            Lead_Type__c='TSA',
            Lead_Type_New__c='TSA'
        );
        
        insert testLead;

        Event tsa = new Event(
            Subject='Tax Consultation', 
            Type_of_Appointment__c='Tax Savings Analysis',
            StartDateTime=Datetime.now().addHours(1),
            EndDateTime=Datetime.now().addHours(2),        
            OwnerId = currentUserId,
            WhoId = testLead.Id
        );

        Event block = new Event(
            Subject='Tax Consultation', 
            Type_of_Appointment__c='Calendar Block',
            StartDateTime=Datetime.now().addHours(1),
            EndDateTime=Datetime.now().addHours(2),        
            OwnerId = currentUserId
        );

        insert new List<Event>{tsa, block};
        
        System.debug('Inserted events: ' + [SELECT Id, Subject FROM Event]);

        }

    @isTest static void syncEvents(){
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        
        CalendarEventBatchable.startBatch(new List<List<Id>>{new List<Id>{UserInfo.getUserId()}});
        Test.stopTest();
        Integer count = [SELECT COUNT() FROM Event];
        System.assertEquals(0, count);
    }
}