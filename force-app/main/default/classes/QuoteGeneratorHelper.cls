public without sharing class QuoteGeneratorHelper {
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

    public static Id convertLead(Lead leadToConvert){
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
        try{
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

        } catch(Exception ex) {
            throw new BusinessCreationException('Error creating business records: '+ex.getMessage());
        } 

        return oppId;
    }
}