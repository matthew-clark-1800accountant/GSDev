@isTest
public with sharing class AuditCOQuoteItemsInvocableTest {
    @TestSetup
    static void makeData(){
        Pricebook2 pb = new Pricebook2 (
            Id = Test.getStandardPricebookId(),
            IsActive = true,
            Environment__c = 'Standard'
        );
        try{
            update pb;
        } catch(Exception ex){
            System.debug(ex.getMessage());
        }        
        
        Account acc = new Account(Name='new account', Lead_Type_New__c = 'Bark');
        insert acc;
        Opportunity opp = new Opportunity(CloseDate=Date.today(), AccountId = acc.Id, Name='name', StageName='New');
        insert opp;
        Product2 p = new Product2(Name = 'Loan Agreement', IsActive=true, Guided_Selling_Identifier__c='Personal Return',
        ChargeOver__c = true, Environment__c='Standard',Billing_Frequency__c = 'Annual',HTML_Description__c = 'test', Description = 'test', No_Split_Allowed__c = true, sort_Order__c = 2);
        //insert p;
        //insert pbe;
        Contact c = new Contact(
            FirstName = 'test',
            LastName = 'Contact', 
            Email = 'test@1800accountant.com', 
            AccountId = acc.Id
        );
        insert c;


        Product2 p2 = new Product2(Name = '1-800AccountantAccess', IsActive=true, Guided_Selling_Identifier__c='Business Return',
        ChargeOver__c = true, Environment__c='Standard', Billing_Frequency__c = 'Annual',HTML_Description__c = 'test', Description = 'test', No_Split_Allowed__c = true, sort_Order__c = 2);
        //insert p2;
        system.debug(p);
        system.debug(p2);
        //insert pbe2;
        Product2 p3 = new Product2 (
            Name = 'Test prod 3',
            Calculator_Location__c = 'A La Carte', 
            AnnualMonthlyOption__c = true, 
            Billing_Frequency__c = 'One-Time', 
            HTML_Description__c = 'test', 
            Description = 'test', 
            No_Split_Allowed__c = true, 
            Guided_Selling_Identifier__c = 'Test prod 3', 
            sort_Order__c = 3
            );
        //insert p3;

        Product2 p4 = new Product2 (
            Name = 'Test prod 4',
            Calculator_Location__c = 'A La Carte', 
            AnnualMonthlyOption__c = true, 
            Billing_Frequency__c = 'Annual', 
            HTML_Description__c = 'test', 
            Description = 'test', 
            No_Split_Allowed__c = true, 
            Guided_Selling_Identifier__c = 'Test prod 4', 
            sort_Order__c = 4
            );
        //insert p4;

        Product2 p5 = new Product2 (
            Name = 'Test prod 5',
            Calculator_Location__c = 'Advisory', 
            AnnualMonthlyOption__c = true, 
            Billing_Frequency__c = 'Annual', 
            HTML_Description__c = 'test', 
            Description = 'test', 
            No_Split_Allowed__c = true, 
            Guided_Selling_Identifier__c = 'Test prod 5', 
            sort_Order__c = 5
            );
        //insert p5;
        insert new List<Product2>{p,p2,p3,p4,p5};



        Quote testQuote = new Quote(
            Name = 'test quote',
            OpportunityId = opp.Id,
            billingSchedule__c = 'yrl',
            Calc_Bookkeeping_Start_Date__c = '2023-10-09',
            Calc_Bookkeeping_End_Date__c = '2023-11-09'
        );
        insert testQuote;

        Chargeover_Quote__c coQuote = new Chargeover_Quote__c(
            Payment_Cycle__c = 'mon',
            Installment_Payment_Schedule__c = 5,
            Quote__c = testQuote.Id,
            Account__c = acc.Id,
            Opportunity__c = opp.Id,
            Contact__c = c.Id
        );
        insert coQuote;

        ChargeOver_Quote_Line_Item__c item = new ChargeOver_Quote_Line_Item__c(
            Price_Per_Unit__c = 10,
            Quantity__c = 1,
            Contract_Amount__c = 10,
            ChargeOver_Quote__c = coQuote.Id,
            Account__c = acc.Id,
            Product__c = p.Id
        );
        insert item;
    }
    
    @isTest
    public static void testAudit() {
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];
        Test.startTest();
        List<String> results = AuditCOQuoteItemsInvocable.AggregateItems(new List<Id>{testQuote.Id})?.get(0);
        Test.stopTest();
        System.assertNotEquals(null, results);
    }
}