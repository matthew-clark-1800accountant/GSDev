@IsTest
public with sharing class QuoteGeneratorHelperTest {
    @TestSetup
    static void makeData(){
        Account acc = new Account(Name='test account');
        Account acc2 = new Account(Name='account without opp');
        insert new List<Account>{acc, acc2};
        Contact con = new Contact(FirstName='test', LastName='Contact', AccountId=acc.Id);
        insert con;
        Opportunity opp = new Opportunity(Name='test opp', AccountId=acc.Id, StageName='New');
        insert opp;
        Event ev = new Event(Subject='test event', WhatId=opp.Id, StartDateTime=DateTime.now(), EndDateTime=DateTime.now());
        insert ev;
        Lead l = new Lead(FirstName='test2', LastName='lead2', Company='company2');
        insert l;
    }

    @IsTest 
    static void testNewLead(){
        Test.startTest();
        Id oppId = CreateBusinessRecordsAPI.newLead(new Lead(FirstName='test', LastName='lead', Company='company'));
        Test.stopTest();
        Assert.isNotNull(oppId);
        Assert.areEqual('Opportunity', oppId.getSObjectType().getDescribe().getName());
        Assert.areEqual(1, [SELECT COUNT() FROM Business__c]);
        Assert.areEqual(1, [SELECT COUNT() FROM Business_Owner__c]);
    }

    @IsTest 
    static void testExistingLead(){
        Id leadId = [SELECT Id FROM Lead LIMIT 1].Id;
        Test.startTest();
        Id oppId = CreateBusinessRecordsAPI.createOrGetBusinessRecords(leadId);
        Test.stopTest();
        Assert.isNotNull(oppId);
        Assert.areEqual('Opportunity', oppId.getSObjectType().getDescribe().getName());
        Assert.areEqual(1, [SELECT COUNT() FROM Business__c]);
        Assert.areEqual(1, [SELECT COUNT() FROM Business_Owner__c]);
    }

    @IsTest 
    static void testAccount(){
        Test.startTest();
        Id oppId = CreateBusinessRecordsAPI.createOrGetBusinessRecords([SELECT Id FROM Account WHERE Name = 'test account' LIMIT 1].Id);
        Test.stopTest();
        Assert.isNotNull(oppId);
        Assert.areEqual('Opportunity', oppId.getSObjectType().getDescribe().getName());
        Assert.areEqual(1, [SELECT COUNT() FROM Business__c]);
        Assert.areEqual(1, [SELECT COUNT() FROM Business_Owner__c]);
    }
    @IsTest 
    static void testAccountWithoutOpp(){
        Test.startTest();
        Id oppId = CreateBusinessRecordsAPI.createOrGetBusinessRecords([SELECT Id FROM Account WHERE Name = 'account without opp' LIMIT 1].Id);
        Test.stopTest();
        Assert.isNotNull(oppId);
        Assert.areEqual('Opportunity', oppId.getSObjectType().getDescribe().getName());
        Assert.areEqual(1, [SELECT COUNT() FROM Business__c]);
        Assert.areEqual(0, [SELECT COUNT() FROM Business_Owner__c]);
    }
    @IsTest 
    static void testContact(){
        Test.startTest();
        Id oppId = CreateBusinessRecordsAPI.createOrGetBusinessRecords([SELECT Id FROM Contact LIMIT 1].Id);
        Test.stopTest();
        Assert.isNotNull(oppId);
        Assert.areEqual('Opportunity', oppId.getSObjectType().getDescribe().getName());
        Assert.areEqual(1, [SELECT COUNT() FROM Business__c]);
        Assert.areEqual(1, [SELECT COUNT() FROM Business_Owner__c]);
    }
    @IsTest 
    static void testOpportunity(){
        Test.startTest();
        Id oppId = CreateBusinessRecordsAPI.createOrGetBusinessRecords([SELECT Id FROM Opportunity LIMIT 1].Id);
        Test.stopTest();
        Assert.isNotNull(oppId);
        Assert.areEqual('Opportunity', oppId.getSObjectType().getDescribe().getName());
        Assert.areEqual(1, [SELECT COUNT() FROM Business__c]);
        Assert.areEqual(1, [SELECT COUNT() FROM Business_Owner__c]);
    }

    @isTest 
    static void testMultiples(){
        Test.startTest();
        CreateBusinessRecordsAPI.createOrGetBusinessRecords([SELECT Id FROM Contact LIMIT 1].Id);
        Id oppId = CreateBusinessRecordsAPI.createOrGetBusinessRecords([SELECT Id FROM Opportunity LIMIT 1].Id);
        Test.stopTest();
        Assert.isNotNull(oppId);
        Assert.areEqual('Opportunity', oppId.getSObjectType().getDescribe().getName());
        Assert.areEqual(1, [SELECT COUNT() FROM Business__c]);
        Assert.areEqual(1, [SELECT COUNT() FROM Business_Owner__c]);
    }
}