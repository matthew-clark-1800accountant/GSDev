@RestResource(urlMapping='/BusinessRecords/*')
global without sharing class CreateBusinessRecordsAPI {
    
    @HttpPost
    global static Id newLead(Lead leadInfo){
        return QuoteGeneratorHelper.convertLead(leadInfo);
    }

    @HttpPut
    global static Id createOrGetBusinessRecords(Id recordId){
        return QuoteGeneratorHelper.createOrGetBusinessRecords(recordId);
    }
}