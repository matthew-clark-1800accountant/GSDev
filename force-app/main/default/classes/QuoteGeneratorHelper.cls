global without sharing class QuoteGeneratorHelper {
    public class NoEmailTemplateFoundException extends Exception {}
    public class NoPrimaryContactException extends Exception {}
    public class ConvertedLeadException extends Exception {}
    public class InsertedLeadException extends Exception {}
    public class BusinessCreationException extends Exception {}
    public class WrongRecordIdException extends Exception {}
    public class WebSocketApiKeyException extends Exception {}
    public class WebSocketException extends Exception {}
    public class errorCreatingBusinessException extends Exception {}
    public class errorQuoteExistException extends Exception {}

    // public class NoTSAEventFoundException extends Exception {}
    public static String noEmailTemplateFound = 'No Classic Email Template found with the Name Guided Selling Client Link. Please check and try again';
    public static String wrongRecordId = 'Missing required Id of type Lead, Account, or Opportunity. Please make sure the Event is related to one of those.';
    public static String convertedLead = 'Error Converting Lead:';
    public static String noApiKeyError = 'Could not find metadata type with the label Web Socket API Key. Please check and try again.';
    public static String webSocketError = 'There was a problem generating your live web socket session. Please contact your administrator with these details: ';
    public static String errorCreatingBusiness = 'There was a problem creating a business and business owner for the client. ';
    public static String errorQuoteExist = 'There is a Quote already created for the Opportunity. Please, go to the calculator on Update Quote link. ';

    //returns opp id
    global static Id convertLead(Lead leadToConvert){
        if(leadToConvert.Id == null){
            try{
                System.debug('inserting lead '+leadToConvert);
                insert leadToConvert;
            } catch(Exception ex){
                throw new InsertedLeadException('Error inserting lead: '+ex.getMessage());
            }
        }

        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(leadToConvert.Id);
        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1];
        lc.setConvertedStatus(convertStatus.MasterLabel);
        Database.LeadConvertResult lcr = Database.convertLead(lc, false);
        if(!lcr.isSuccess()){
            List<String> duplicateIds = new List<String>();
            for (Database.Error error : lcr.getErrors()){
                if (error instanceof Database.DuplicateError){
                    Database.DuplicateError duplicateError = (Database.DuplicateError)error;
                    Datacloud.MatchRecord[] matchRecords = duplicateError.getDuplicateResult().getMatchResults()[0].getMatchRecords();

                    // Add matched record to the duplicate records variable
                    for (Datacloud.MatchRecord matchRecord : matchRecords) {
                        System.debug('MatchRecord: ' + matchRecord.getRecord().Id);
                        duplicateIds.add(matchRecord.getRecord().Id);
                    }
                }
            }
            throw new ConvertedLeadException('Duplicate Record IDs: '+String.valueOf(duplicateIds));
        }
        System.debug(lcr);
        Id oppId = lcr.getOpportunityId();
        Id accId = lcr.getAccountId();
        Id conId = lcr.getContactId();

        Account getAccount = ([
            SELECT Id, Name, Expected_1st_year_revenue__c,
            Industry, Entity_Tax_Classification__c, Number_of_Owners__c, Total_Startup_Costs__c, Owned_Business_Before_new__c, Interested_in_obtaining_funding__c, Registration_Date__c,
            BillingCountry, BillingCity, BillingState, BillingStreet, BillingPostalCode
            FROM Account 
            WHERE Id = :accId LIMIT 1
        ]);
        Contact getContact = [SELECT Id, Name, FirstName, LastName, Email, Phone FROM Contact WHERE Id = :conId LIMIT 1];
        System.debug(getAccount);
        System.debug(getContact);
        createOrGetBusinessRecords(oppId);
        

        return oppId;
    }

    global static Id createOrGetBusinessRecords(Id recordId){
        String recordIdType = recordId?.getSObjectType().getDescribe().getName(); 

        switch on recordIdType{
            when 'Lead' {
                return convertLead(new Lead(Id=recordId));
            }
            when 'Account'{
                Opportunity opp;
                List<Opportunity> opps = [SELECT Id FROM Opportunity WHERE AccountId = :recordId ORDER BY CreatedDate DESC LIMIT 1];
                if(opps.isEmpty()){
                    Account acc = [SELECT Name FROM Account WHERE Id = :recordId LIMIT 1];
                    opp = new Opportunity(AccountId = recordId, Name = acc.Name, StageName='New');
                    insert opp;
                } else {
                    opp = opps[0];
                }
                createBusinessRecords(opp.Id);
                return opp.Id;
            }
            when 'Contact'{
                Opportunity opp;
                Contact con = [SELECT AccountId FROM Contact WHERE Id = :recordId LIMIT 1];
                return createOrGetBusinessRecords(con.AccountId);
                // List<Opportunity> opps = [SELECT Id FROM Opportunity WHERE AccountId = :con.AccountId ORDER BY CreatedDate DESC LIMIT 1];
                // if(opps.isEmpty()){
                //     opp = new Opportunity(AccountId = recordId, Name = acc.Name);
                //     insert opp;
                // } else {
                //     opp = opps[0];
                // }
                // createBusinessRecords(opp.Id);
                // return opp.Id;
            }
            when 'Opportunity'{
                createBusinessRecords(recordId);
                return recordId;
            }
            when 'Event'{
                Event e = [SELECT WhatId, WhoId FROM Event WHERE Id = :recordId LIMIT 1];
                if(e.WhatId != null){ return createOrGetBusinessRecords(e.WhatId); }
                else { return createOrGetBusinessRecords(e.WhoId); }
            }
            when else {
                throw new InvalidIdException('Id is invalid or of an unsupported type.');
            }
        }
    }

    //returns business Id
    //@future
    global static Id createBusinessRecords(Id oppId){
        try{
            Opportunity getOpp = [SELECT AccountId FROM Opportunity WHERE Id = :oppId LIMIT 1];
            Account getAccount = ([
                SELECT Id, Name, Expected_1st_year_revenue__c,
                Industry, Entity_Tax_Classification__c, Number_of_Owners__c, Total_Startup_Costs__c, Owned_Business_Before_new__c, Interested_in_obtaining_funding__c, Registration_Date__c,
                BillingCountry, BillingCity, BillingState, BillingStreet, BillingPostalCode, Primary_Contact__c, (SELECT Id FROM Businesses__r)
                FROM Account 
                WHERE Id = :getOpp.AccountId LIMIT 1
            ]);
            List<Contact> getContacts = [SELECT Id, Name, FirstName, LastName, Email, Phone FROM Contact WHERE Id = :getAccount.Primary_Contact__c LIMIT 1];
            
            if(getAccount.Businesses__r.isEmpty()){
                Business__c toInsertBusiness = new Business__c(
                    Name = getAccount.Name,
                    Account__c = getAccount.Id,
                    Anticipated_Revenue__c = getAccount.Expected_1st_year_revenue__c,
                    Industry__c = getAccount.Industry,
                    Business_Type__c = getAccount.Entity_Tax_Classification__c,
                    Number_of_Owners__c = getAccount.Number_of_Owners__c,
                    Startup_Costs__c = getAccount.Total_Startup_Costs__c,
                    First_Business__c = (getAccount.Owned_Business_Before_new__c == 'Yes'),
                    Date_of_incorporation__c = getAccount.Registration_Date__c
                );
                insert toInsertBusiness;
                System.debug(toInsertBusiness);
    
                if(!getContacts.isEmpty()){
                    Contact getContact = getContacts[0];
                    Business_Owner__c toInsertBusinessContact = new Business_Owner__c(
                        Name = getContact.firstName + ' ' + getContact.lastName,
                        First_Name__c = getContact.firstName,
                        Last_Name__c = getContact.lastName,
                        Phone__c = getContact.Phone,
                        Email__c = getContact.Email,
                        Business__c = toInsertBusiness.Id,
                        Primary_Contact__c = true,
                        Partner_Role__c = 'Primary Contact',
                        Contact__c = getContact.Id,
                        Address__c = getAccount.BillingStreet,
                        City__c = getAccount.BillingCity,
                        Zip__c = getAccount.BillingPostalCode,
                        Country__c = getAccount.BillingCountry,
                        State__c = getAccount.BillingState
                    );                
                    insert toInsertBusinessContact;
                    System.debug(toInsertBusinessContact);
                }
                
                return toInsertBusiness.Id;
            } else {
                return getAccount.Businesses__r[0].Id;
            }
        } catch(Exception ex) {
            throw new BusinessCreationException('Error creating business records: '+ex.getMessage());
        } 
    }

    
    global class InvalidIdException extends Exception{}
}