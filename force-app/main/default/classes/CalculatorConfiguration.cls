public without sharing class CalculatorConfiguration {
    @AuraEnabled @InvocableVariable(label='Id for test account' description='Account Id' required=false)
    public Id accountId;
    @AuraEnabled @InvocableVariable(label='Id for test opportunity' description='Opportunity Id' required=true)
    public Id opportunityId;
    @AuraEnabled @InvocableVariable(label='Entity value to override account field' description='Entity Override' required=false)
    public String entityOverride;
    @AuraEnabled @InvocableVariable(label='Calculator to check against' description='Calculator' required=false)
    public String calculator;

    @AuraEnabled @InvocableVariable(label='Bookkeeping Start Date' description='Bookkeeping Start Date' required=false)
    public Date bookStartDate;
    @AuraEnabled @InvocableVariable(label='Bookkeeping End Date' description='Bookkeeping End Date' required=false)
    public Date bookEndDate;
    @AuraEnabled @InvocableVariable(label='Desired quote finanincing' description='Financing' required=false)
    public String billingFinance;
    @AuraEnabled @InvocableVariable(label='Range of transactions per month' description='Combined Advisory' required=false)
    public String monthlyTransactions;
    @AuraEnabled @InvocableVariable(label='Controls whether Advisory and Add-ons display as a single item' description='Combined Advisory' required=false)
    public Boolean combinedAdvisory;
}