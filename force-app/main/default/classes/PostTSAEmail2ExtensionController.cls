public class PostTSAEmail2ExtensionController {
    //Display booleans
    public Boolean hasOpportunity {get; set;} 
    public Boolean hasBusinessTax {get; set;} 
    public Boolean has1800access {get; set;} 
    public Boolean hasAdvisory {get; set;} 
    public Boolean hasPersonal {get; set;}     
    public Boolean hasBookkeeping {get; set;} 

    //Tax Savings
    public Decimal totalSavings {get; set;}
    public Decimal sSavings {get; set;}
    public Decimal homeOfficeSavings {get; set;}
    public Decimal businessMileageSavings {get; set;}
    public Decimal qbiSavings {get; set;}
    public Decimal startupSavings {get; set;}
    //Product Ids
    public Id taxAdvisoryId {get; set;}
    public Id businessReturnId {get; set;}
    public Id bookeepingId {get; set;}
    public Id personalReturnId {get; set;}
    public Id accountantAccessId {get; set;}
    public Id loanAgreementId {get; set;}
    public Id auditDefensePersonalId {get; set;}
    public Id auditDefenseBusinessId {get; set;}
    public Id twoYearReviewId {get; set;}
    public Id nonprofitTaxPrepId {get; set;}

    public Id entityFormationId {get; set;}
    public Id payrollFeeId {get; set;}
    public Id llcStateFilingFeeId {get; set;}
    public Id corpStateFilingFeeId {get; set;}
    public Id payrollId {get; set;}
    public Id website3pageId {get; set;}
    public Id maintenanceManagementId {get; set;}
    public Id websiteBuilderId {get; set;}
    public Id website5pageId {get; set;}
    


    public Opportunity opportunity {get; set;}
    public Quote quote {get; set;}
    public Product2 get1800AccessProductId {get; set;}
    public Product2 getBusinessReturnProductId {get; set;}
    public Map<Id, OpportunityLineItem> products {get; set;}
    public Set<String> productNames {get; set;}
    public Set<String> productCalculatorLocation {get; set;}
    public Set<Id> personalizableProductIds {get; set;}
    public Set<Id> currentProductIds {get; set;}
    public Set<Id> allProducts {get; set;}
    public Boolean hasBundle {get; set;} 


    //Financing 
    public Map<String,String> QUOTEFINANCING {
        get {
            return new Map<String, String> {
                null => 'No Financing',
                'yrl' => 'No Financing', 
                'mon' => 'Monthly',
                '2pay' => '2 Payments',
                '3pay' => '3 Payments',
                '4pay' => '4 Payments',
                '6pay' => '6 Payments'
            };
        }
        set;
    }

    public Map<String, Id> calculatorLocationToProduct {get;set;}
    //Prices in a map, serialized for the front end
    public Map<Id, Decimal> productIdToPrice;
    public Map<Id, Decimal> bundleProductIdToPrice;
    public Map<Id, Decimal> overrideProductIdToPrice;


    public Map<Id, String> productIdToBilling;

    public Map<String, Id> productNameToId {get;set;}
    public void setproductIdToPrice(Map<Id, Decimal> setproductIdToPrice) {this.productIdToPrice = setproductIdToPrice;}
    public String getproductIdToPrice() { return JSON.serialize(this.productIdToPrice); }

    public void setbundleProductIdToPrice(Map<Id, Decimal> setbundleProductIdToPrice) {this.bundleProductIdToPrice = setbundleProductIdToPrice;}
    public String getbundleProductIdToPrice() { return JSON.serialize(this.bundleProductIdToPrice); }

    public void setoverrideProductIdToPrice(Map<Id, Decimal> setoverrideProductIdToPrice) {this.overrideProductIdToPrice = setoverrideProductIdToPrice;}
    public String getoverrideProductIdToPrice() { return JSON.serialize(this.bundleProductIdToPrice); }

    public void setproductIdToBilling(Map<Id, String> setproductIdToBilling) {this.productIdToBilling = setproductIdToBilling;}
    public String getproductIdToBilling() { return JSON.serialize(this.productIdToBilling); }

    public String getSerializedProductNameToId() { return JSON.serialize(this.productNameToId); }

    public PostTSAEmail2ExtensionController(ApexPages.StandardController stdController) {
        //Get the Id from the parameters
        Id opportunityId = ApexPages.currentPage().getParameters().get('id');
        //Check not null and is an Opportunity Id
        hasOpportunity = (null != opportunityId && opportunityId.getSObjectType().getDescribe().getName() == 'Opportunity') ? true : false;
        if(hasOpportunity){
            opportunity = [
                SELECT Id, Name, Amount, Pricebook2Id, ChargeOver_Quote_URL__c, Account.Potential_Home_Office_Savings__c, Account.Potential_Total_Savings__c, 
                Account.Potential_SCorp_Savings__c, Account.Potential_QBI_Savings__c, Account.Potential_Business_Mile_Savings__c, 
                Account.Potential_Startup_Savings__c, Account.Name, OwnerId, AccountId
                FROM Opportunity
                WHERE Id = :opportunityId
            ];
            quote = [
                SELECT Id, Name, billingSchedule__c , Calc_Number_of_Transactions__c, Calc_Number_of_Rental_Properties__c, Calc_Personal_Income__c, Calc_Living_Abroad__c, Calc_Number_of_K1s__c, Calc_Entity_Type__c,
                Calc_Number_of_Employees__c, Calc_Industry_Type__c, Calc_Number_of_Contractors__c, Calc_Foreign_Owners__c, Calc_Projected_1st_Year_Revenue__c, Calc_Projected_1st_Year_Profit__c,
                Calc_State_of_Incorporation__c, Calc_Total_Investor_Funding__c, Calc_Total_Startup_Cost__c, Calc_Website_Selling_Goods__c, Calc_Number_of_Owners__c, Bundle__c, Calc_Run_Payroll_Before__c
                FROM Quote 
                WHERE OpportunityId = :opportunityId 
                LIMIT 1
            ];
            hasBundle = (null != quote.Bundle__c && 'None' != quote.Bundle__c && Id.valueOf(quote.Bundle__c).getSObjectType().getDescribe().getName() == 'Calculator_Offer__c') ? true : false;

            //Stripping the currency values of formatting, and setting to 0 if null
            totalSavings = (null != opportunity.Account.Potential_Total_Savings__c) ? opportunity.Account.Potential_Total_Savings__c : 0.00;
            sSavings = (null != opportunity.Account.Potential_SCorp_Savings__c) ? opportunity.Account.Potential_SCorp_Savings__c : 0.00;
            homeOfficeSavings = (null != opportunity.Account.Potential_Home_Office_Savings__c) ? opportunity.Account.Potential_Home_Office_Savings__c : 0.00;
            businessMileageSavings = (null != opportunity.Account.Potential_Business_Mile_Savings__c) ? opportunity.Account.Potential_Business_Mile_Savings__c : 0.00;
            qbiSavings = (null != opportunity.Account.Potential_QBI_Savings__c) ? opportunity.Account.Potential_QBI_Savings__c : 0.00;
            startupSavings = (null != opportunity.Account.Potential_Startup_Savings__c) ? opportunity.Account.Potential_Startup_Savings__c : 0.00;

            //This one is a la carte so I am adding the name to the query to get the right one (there are multiple a la carte products)
            get1800AccessProductId = [ SELECT Id, Name, ChargeOver__c  FROM Product2 WHERE ChargeOver__c = true AND IsActive = true AND Calculator_Location__c = 'A La Carte' AND Name = '1-800Accountant Access' LIMIT 1];
            bookeepingId = [ SELECT Id, Name, ChargeOver__c  FROM Product2 WHERE ChargeOver__c = true AND IsActive = true AND Calculator_Location__c = 'Bookkeeping' LIMIT 1].Id;
            taxAdvisoryId = [ SELECT Id, Name, ChargeOver__c  FROM Product2 WHERE ChargeOver__c = true AND IsActive = true AND Calculator_Location__c = 'Advisory' LIMIT 1].Id;
            personalReturnId = [ SELECT Id, Name, ChargeOver__c  FROM Product2 WHERE ChargeOver__c = true AND IsActive = true AND Calculator_Location__c = 'Personal Return' LIMIT 1].Id;

            entityFormationId = [ SELECT Id, Name, ChargeOver__c  FROM Product2 WHERE ChargeOver__c = true AND IsActive = true AND Calculator_Location__c = 'A La Carte'  AND Name = 'Entity Formation' LIMIT 1].Id;
            payrollFeeId = [ SELECT Id, Name, ChargeOver__c  FROM Product2 WHERE ChargeOver__c = true AND IsActive = true AND Calculator_Location__c = 'A La Carte'  AND Name = 'Payroll Setup Fee' LIMIT 1].Id;
            llcStateFilingFeeId = [ SELECT Id, Name, ChargeOver__c  FROM Product2 WHERE ChargeOver__c = true AND IsActive = true AND Calculator_Location__c = 'LLC State Filing' LIMIT 1].Id;
            corpStateFilingFeeId = [ SELECT Id, Name, ChargeOver__c  FROM Product2 WHERE ChargeOver__c = true AND IsActive = true AND Calculator_Location__c = 'Corp State Filing' LIMIT 1].Id;
            payrollId = [ SELECT Id, Name, ChargeOver__c  FROM Product2 WHERE ChargeOver__c = true AND IsActive = true AND Calculator_Location__c = 'Payroll' LIMIT 1].Id;

            website3pageId = [ SELECT Id, Name, ChargeOver__c  FROM Product2 WHERE ChargeOver__c = true AND IsActive = true AND Calculator_Location__c = 'A La Carte' AND Name = '3-Page Templated Website' LIMIT 1].Id;
            maintenanceManagementId = [ SELECT Id, Name, ChargeOver__c  FROM Product2 WHERE ChargeOver__c = true AND IsActive = true AND Calculator_Location__c = 'A La Carte' AND Name = 'Maintenance & Management' LIMIT 1].Id;
            websiteBuilderId = [ SELECT Id, Name, ChargeOver__c  FROM Product2 WHERE ChargeOver__c = true AND IsActive = true AND Calculator_Location__c = 'A La Carte' AND Name = 'Website Builder' LIMIT 1].Id;
            website5pageId = [ SELECT Id, Name, ChargeOver__c  FROM Product2 WHERE ChargeOver__c = true AND IsActive = true AND Calculator_Location__c = 'A La Carte' AND Name = '5-Page Templated Website' LIMIT 1].Id;






            loanAgreementId = [ SELECT Id, Name, ChargeOver__c  FROM Product2 WHERE ChargeOver__c = true AND IsActive = true AND Calculator_Location__c = 'A La Carte' AND Name = 'Loan Agreement'].Id;

            auditDefensePersonalId = [ SELECT Id, Name, ChargeOver__c  FROM Product2 WHERE ChargeOver__c = true AND IsActive = true AND Calculator_Location__c = 'A La Carte' AND Name = 'Audit Defense - Personal'].Id;
            auditDefenseBusinessId = [ SELECT Id, Name, ChargeOver__c  FROM Product2 WHERE ChargeOver__c = true AND IsActive = true AND Calculator_Location__c = 'A La Carte' AND Name = 'Audit Defense - Business'].Id;
            twoYearReviewId = [ SELECT Id, Name, ChargeOver__c  FROM Product2 WHERE ChargeOver__c = true AND IsActive = true AND Calculator_Location__c = 'A La Carte' AND Name = 'Two-Year Review'].Id;
            nonprofitTaxPrepId = [ SELECT Id, Name, ChargeOver__c  FROM Product2 WHERE ChargeOver__c = true AND IsActive = true AND Calculator_Location__c = 'A La Carte' AND Name = 'Non-Profit Tax Preparation'].Id;



            products = new Map<Id,OpportunityLineItem>([
                SELECT Id, Name, Product2Id, Product2.Name, UnitPrice, PricebookEntryId, Product2.Calculator_Location__c, Product2.Billing_Frequency__c
                FROM OpportunityLineItem
                WHERE OpportunityId = :opportunity.Id
            ]);

            calculatorLocationToProduct = new Map<String,Id>();
            productIdToBilling = new Map<Id, String>();
            productNameToId = new Map<String,Id>();
            productNames = new Set<String>();
            personalizableProductIds = new Set<Id>();
            currentProductIds = new Set<Id>();
            allProducts = new Set<Id>();
            productCalculatorLocation = new Set<String>();
            // List<Id> findPrice = new List<Id>();
            //Going through the products to map some information for the front end and to find the price
            for(OpportunityLineItem p : products.values()){
                productNameToId.put(p.Product2.Name, p.Product2Id);
                personalizableProductIds.add(p.Product2Id);
                productNames.add(p.Product2.Name);
                allProducts.add(p.Product2Id);
                currentProductIds.add(p.Product2Id);
                // findPrice.add(p.Product2Id);
                //Using the calculator location
                if(null != p.Product2.Calculator_Location__c
                && 'A La Carte' != p.Product2.Calculator_Location__c){
                    calculatorLocationToProduct.put(p.Product2.Calculator_Location__c, p.Product2Id);
                    productCalculatorLocation.add(p.Product2.Calculator_Location__c);
                //If they don't have one, using the product name
                } else {
                    calculatorLocationToProduct.put(p.Product2.Name, p.Product2Id);
                    productCalculatorLocation.add(p.Product2.Name);
                }
                //Gathering the billing frequency to calculate price on the front end as they change the financing
                productIdToBilling.put(p.Product2Id, p.Product2.Billing_Frequency__c);
                //Identifying if a product already in their package matches an add on product 
                if(p.Product2.Calculator_Location__c == 'Advisory'){
                    hasAdvisory = true;
                }

                if(p.Product2.Calculator_Location__c == 'Personal Return'){
                    hasPersonal = true;

                }
                if(p.Product2.Calculator_Location__c == 'Bookkeeping'){
                    hasBookkeeping = true;
                }
                //Identifying two products that cannot be removed and removing them from the list of products and maps of prices
                if(p.Product2.Calculator_Location__c == 'Business Return'){
                    hasBusinessTax = true;
                    productNames.remove(p.Product2.Name);
                    personalizableProductIds.remove(p.Product2Id);
                    businessReturnId = p.Product2Id;
                }
                if(get1800AccessProductId.Id == p.Product2Id){
                    has1800access = true;
                    productNames.remove(p.Product2.Name);
                    personalizableProductIds.remove(p.Product2Id);
                    accountantAccessId = p.Product2Id;
                }
            }
            //Loading the had-coded override products and prices
            // overrideProductIdToPrice = new Map<Id,Decimal>();
            // for(OpportunityLineItem p : products.values()){
            //     if(p.Product2.Name == 'Loan Agreement'){
            //         overrideProductIdToPrice.put(p.Product2Id, 0.00);
            //     } else if(p.Product2.Name == '1-800Accountant Access'){
            //         overrideProductIdToPrice.put(p.Product2Id, 29.99);
            //     }
            // }
            //Need to find the price for these add on products as well if they are not in the package
            //Have to add business return to fin
            productCalculatorLocation.addAll(new Set<String>{'Bookkeeping', 'Advisory', 'Personal Return', 'Business Return'});
            calculatorLocationToProduct.putAll(new Map<String, Id>{'Bookkeeping' => bookeepingId, 'Advisory' => taxAdvisoryId, 'Personal Return' => personalReturnId, 'Business Return' => businessReturnId});
            allProducts.addAll(new List<Id>{bookeepingId, taxAdvisoryId, personalReturnId});
            personalizableProductIds.addAll(new List<Id>{bookeepingId, taxAdvisoryId, personalReturnId});
            System.debug(productNameToId);




            User user = [SELECT Id, Name, Skills_Sales__c FROM User WHERE Id = :opportunity.OwnerId ];
            Account account = [SELECT Id, Name, Campaign__c, Lead_Type_New__c FROM Account WHERE Id = :opportunity.AccountId ];



            List<Product_Pricing_Rule__mdt> overrideRules = [
                SELECT Id, MasterLabel, Quote_Field2__c, Product_Name__c, Field_Value__c, Price_Adjustment__c, User_Field__c, Account_Field__c, Flat_Price_Override__c
                FROM Product_Pricing_Rule__mdt
                WHERE Product_Name__c IN :productCalculatorLocation
                AND Flat_Price_Override__c = true
            ];

            productIdToPrice = new Map<Id,Decimal>();
            bundleProductIdToPrice = new Map<Id,Decimal>();



            System.debug(overrideRules);
            for(Product_Pricing_Rule__mdt rule : overrideRules){
                String quoteFieldValue = rule.Quote_Field2__c;
                String accountFieldValue = rule.Account_Field__c;
                String userFieldValue = rule.User_Field__c;
                if(null != quoteFieldValue){
                    Map<String, Object> serializedQuote = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(quote));
                    String quoteValue = String.valueOf(serializedQuote.get(quoteFieldValue));
                    if(quoteValue == rule.Field_Value__c){
                        productIdToPrice.put(calculatorLocationToProduct.get(rule.Product_Name__c), rule.Price_Adjustment__c);
                        productCalculatorLocation.remove(rule.Product_Name__c);
                    }
                }   
                if(null != userFieldValue){
                    Map<String, Object> serializedUser = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(quote));
                    String userValue = String.valueOf(serializedUser.get(userFieldValue));
                    if(userValue == rule.Field_Value__c){
                        productIdToPrice.put(calculatorLocationToProduct.get(rule.Product_Name__c), rule.Price_Adjustment__c);
                        productCalculatorLocation.remove(rule.Product_Name__c);
                    }
                }  
                if(null != accountFieldValue){
                    Map<String, Object> serializedAccount = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(quote));
                    String accountValue = String.valueOf(serializedAccount.get(accountFieldValue));
                    if(accountValue == rule.Field_Value__c){
                        productIdToPrice.put(calculatorLocationToProduct.get(rule.Product_Name__c), rule.Price_Adjustment__c);
                        productCalculatorLocation.remove(rule.Product_Name__c);
                    }
                }
            }
            System.debug(productIdToPrice);
            System.debug(productCalculatorLocation);


            if(hasBundle){
                List<Calculator_Offer_Product__c> bundleProducts = [
                    SELECT Id, Name, Product__c, Calculator_Offer__c, Amount__c
                    FROM Calculator_Offer_Product__c
                    WHERE Calculator_Offer__c = :quote.Bundle__c
                    AND Active__c = true
                ];

                for(Calculator_Offer_Product__c bp : bundleProducts){
                    bundleProductIdToPrice.put(bp.Product__c, bp.Amount__c);
                }
                System.debug(bundleProductIdToPrice);

            }
                
            List<Product_Pricing_Rule__mdt> rules = [
                SELECT Id, MasterLabel, Quote_Field2__c, Product_Name__c, Field_Value__c, Price_Adjustment__c, User_Field__c, Account_Field__c, Flat_Price_Override__c
                FROM Product_Pricing_Rule__mdt
                WHERE Product_Name__c IN :productCalculatorLocation
                AND Flat_Price_Override__c = false
            ];
            //Need map product id to product calculator location
            for(Product_Pricing_Rule__mdt rule : rules){
                String fieldValue1 = rule.Quote_Field2__c;
                Map<String, Object> serializedObject = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(quote));
                String fieldValue = String.valueOf(serializedObject.get(fieldValue1));

                if(fieldValue == rule.Field_Value__c){
                    if(null == productIdToPrice.get(calculatorLocationToProduct.get(rule.Product_Name__c))){
                        productIdToPrice.put(calculatorLocationToProduct.get(rule.Product_Name__c), rule.Price_Adjustment__c);
                    } else {
                        Decimal totalPrice = productIdToPrice.get(calculatorLocationToProduct.get(rule.Product_Name__c)) + rule.Price_Adjustment__c;
                        productIdToPrice.put(calculatorLocationToProduct.get(rule.Product_Name__c), totalPrice);
                    }
                }
            }

            
            List<PricebookEntry> prices = [
                SELECT Id, Name, Pricebook2Id, UnitPrice, IsActive, Product2Id, Product2.Name, Product2.ChargeOver__c, Product2.Calculator_Location__c
                FROM PricebookEntry
                WHERE Pricebook2Id = :opportunity.Pricebook2Id
                AND isActive = true
                AND Product2.ChargeOver__c = true
                AND Product2Id IN :allProducts
                AND Product2Id NOT IN :productIdToPrice.keySet()
            ];
             
            for(PricebookEntry pb : prices){
                productIdToPrice.put(pb.Product2Id, pb.UnitPrice);
            }

            System.debug(productIdToPrice.get(businessReturnId));
            System.debug(productIdToPrice.get(personalReturnId));


            Decimal taxAdvisoryPrice = ((productIdToPrice.get(businessReturnId) + productIdToPrice.get(personalReturnId)) / (815 + 365)) * 1125;
            productIdToPrice.put(taxAdvisoryId, taxAdvisoryPrice);
            if(!allProducts.contains(businessReturnId)){
                productIdToPrice.remove(businessReturnId);
            }



            System.debug(productIdToPrice);
            System.debug(productCalculatorLocation);
            //The savings only includes home office & business mileage if they do not have tax advisory currently in their personalized plan
            if(null == taxAdvisoryId){
                totalSavings = homeOfficeSavings + businessMileageSavings;
            }
        }
    }

    public static final Map<String, String> FINANCING = new Map<String, String>{
        'No Financing' => 'Yearly', 
        'Monthly' => 'Monthly',
        '2 Payments' => '2-Pay',
        '3 Payments' => '3-Pay',
        '4 Payments' => '4-Pay',
        '6 Payments' => '6-Pay'
        };

    public static void deleteToRemake(Id opportunityId, Id quoteId){
        //Delete Opportunity Line Items
        List<OpportunityLineItem> oldOLI = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :opportunityId];
        delete oldOLI;
        //Delete Quote Line Items
        List<QuoteLineItem> oldQLI = [SELECT Id FROM QuoteLineItem WHERE QuoteId = :quoteId];
        delete oldQLI;
        //Delete old Chargeover Quotes & Lines
        List<ChargeOver_Quote__c> oldCOQ = [SELECT Id, (SELECT Id FROM ChargeOver_Quote_Line_Items__r) FROM ChargeOver_Quote__c WHERE Quote__c = :quoteID];
        List<ChargeOver_Quote_Line_Item__c> toDeleteCOQLI = new List<ChargeOver_Quote_Line_Item__c>();
        for(ChargeOver_Quote__c coq : oldCOQ){
            toDeleteCOQLI.addAll(coq.ChargeOver_Quote_Line_Items__r);
        }
        delete toDeleteCOQLI;
        delete oldCOQ;
    }

    public static void sleep(Long milliSeconds) {
        Long timeDiff = 0;
        DateTime firstTime = System.now(); 
        do
        {
            timeDiff = System.now().getTime() - firstTime.getTime();
        }
        while(timeDiff <= milliSeconds);
    }
    @RemoteAction
    public static String updateQuote(List<String> newProducts, String quoteId, String oppId, String mappedPrices, String financing) {
        //Deserializing price information
        System.debug(newProducts);
        System.debug(quoteId);
        System.debug(oppId);
        System.debug(mappedPrices);
        System.debug(financing);
        Map<String, String> prices = (Map<String,String>) JSON.deserialize(mappedPrices, Map<String,String>.class);

        Opportunity opportunity = [
            SELECT Id, Name, OwnerId, Amount, Pricebook2Id, AccountId, Account.Name, Brand__c, Account.Primary_Contact_ID__c, Account.Primary_Contact__c, Account.BillingStreet, Account.BillingCity, Account.BillingState, Account.BillingPostalCode, Account.BillingCountry
            FROM Opportunity
            WHERE Id = :oppId
        ];

        // Get Rules
        PostTSAEmail2ExtensionController.Rules ruleMaster = new PostTSAEmail2ExtensionController.Rules(opportunity.Id);
        List<Id> productsIdsToAdd = new List<Id>();
        for(String dp : newProducts){
            System.debug(dp);
            productsIdsToAdd.add(dp.replace('\'',''));
        }
        List<Product2> toAddProducts = [
            SELECT Id, Name, Description, Sort_Order__c, Calculator_Location__c, HTML_Description__c, Billing_Frequency__c, RevenueInstallmentPeriod
            FROM Product2
            WHERE Id IN :productsIdsToAdd
        ];

        List<PricebookEntry> pbes = [SELECT Id, Product2Id FROM PricebookEntry WHERE Pricebook2Id =: opportunity.PriceBook2Id AND Product2Id IN :productsIdsToAdd];
        Map<Id, Id> productToPricebook = new Map<Id, Id>();
        for(PricebookEntry pe : pbes){
            productToPricebook.put(pe.Product2Id, pe.Id);
        }

        //Delete old information to remake
        PostTSAEmail2ExtensionController.deleteToRemake(oppId, quoteId);
        
        Quote quote = [
            SELECT Id, Calc_Entity_Type__c, Calc_Foreign_Owners__c, QuoteNumber, Calc_Industry_Type__c, Calc_Living_Abroad__c, Calc_Number_of_Contractors__c, Calc_Number_of_Employees__c, Calc_Number_of_K1s__c, Calc_Number_of_Owners__c, Calc_Number_of_Rental_Properties__c, Calc_Number_of_Transactions__c, Calc_Personal_Income__c, Calc_Projected_1st_Year_Profit__c, Calc_Projected_1st_Year_Revenue__c, Calc_State_of_Incorporation__c, Calc_Total_Investor_Funding__c, Calc_Total_Startup_Cost__c, Calc_Website_Selling_Goods__c, Calc_Worked_with_Accountant__c, Calc_Run_Payroll_Before__c, OpportunityId, AccountId, billingSchedule__c, Bundle__c, Calc_Filing_Status__c, Calc_Business_Miles__c, Calc_Office_Square_Footage__c 
            FROM Quote
            WHERE Id = :quoteId
        ];

        Chargeover_URL__c uset = Chargeover_URL__c.getOrgDefaults();
        String sURL = uset.Scheduler_URL__c;

        String apptType;
        for(Product2 p : toAddProducts){
            if(null == apptType || 'ALaCart' == apptType){
                if(opportunity.Brand__c == 'EzBizFile') {
                    apptType = 'Discovery';
                } else {
                    if(p.Calculator_Location__c == 'Advisory') {
                        apptType = 'Discovery';
                    } else {
                        if(p.Calculator_Location__c == 'Bookkeeping') {
                            apptType = 'Bookkeeper';
                        } else if(p.Calculator_Location__c == 'Payroll') {
                            apptType = 'Payroll';
                        } else {
                            apptType = 'ALaCart';
                        }
                    }
                }
            }
        }
        String schedulerURL = sURL+'?TID='+apptType+'&WID='+opportunity.Account.Primary_Contact__c;
        Boolean madeMonth = false;
        Boolean madeYearly = false;
        Boolean madeOneTime = false;
        Boolean madeInstallment = false;
        Map<String, ChargeOver_Quote__c> COQuotes = new Map<String, ChargeOver_Quote__c>();
        Integer installments = 1;
        Integer divisor = 1;
        if('mon' != financing && 'yrl' != financing){
            installments = ('6pay' == financing) ? Integer.valueOf(financing.substring(0, 1))+1 : Integer.valueOf(financing.substring(0, 1))+2;
            divisor = Integer.valueOf(financing.substring(0, 1));
        }

        for(Product2 product : toAddProducts){
            System.debug(product.Name);
            System.debug(product.Id);
            if('Monthly' == product.Billing_Frequency__c) {
                if(false == madeMonth) {
                    ChargeOver_Quote__c monthlyCOQ = PostTSAEmail2ExtensionController.makeMonthlyChargeoverQuote(opportunity, quote, schedulerURL);                    
                    madeMonth = true;
                    COQuotes.put('mon', monthlyCOQ);
                }    
            }
            if('Annual' == product.Billing_Frequency__c) {
                if('mon' == financing) {
                    if(false == madeMonth) {
                        ChargeOver_Quote__c monthlyCOQ = PostTSAEmail2ExtensionController.makeMonthlyChargeoverQuote(opportunity, quote, schedulerURL);                    
                        madeMonth = true;
                        COQuotes.put('mon', monthlyCOQ);
                    }   

                }
                else if('yrl' == financing) {
                    if(false == madeYearly) {
                        ChargeOver_Quote__c yearlyCOQ = PostTSAEmail2ExtensionController.makeYearlyChargeoverQuote(opportunity, quote, schedulerURL);                    
                        madeYearly = true;
                        COQuotes.put('yrl', yearlyCOQ);
                    }    
                }
                else { //financing options
                    if(false == madeInstallment) {
                        ChargeOver_Quote__c yearlyCOQ = PostTSAEmail2ExtensionController.makeYearlywithPaymentsChargeoverQuote(installments, opportunity, quote, schedulerURL);                    
                        madeInstallment = true;
                        COQuotes.put('installmentPlan', yearlyCOQ);    
                    }
                }           
            }
            if('One-Time' == product.Billing_Frequency__c) {
                // if('mon' == financing) {
                //     if(false == madeMonth) {
                //         ChargeOver_Quote__c monthlyCOQ = PostTSAEmail2ExtensionController.makeMonthlyChargeoverQuote(opportunity, quote, schedulerURL);                    
                //         madeMonth = true;
                //         COQuotes.put('mon', monthlyCOQ);
                //     }
                // }
                // else if('yrl' == financing) {
                    if(false == madeOneTime) {
                        ChargeOver_Quote__c theCOQuoteOneTime = PostTSAEmail2ExtensionController.makeOneTimeChargeoverQuote(opportunity, quote, schedulerURL);                    
                        madeOneTime = true;
                        COQuotes.put('one', theCOQuoteOneTime);
                    }  
    
                // }
                // else { //financing options
                //     if(false == madeInstallment) {
                //         ChargeOver_Quote__c yearlyCOQ = PostTSAEmail2ExtensionController.makeYearlywithPaymentsChargeoverQuote(installments, opportunity, quote, schedulerURL);                    
                //         madeInstallment = true;
                //         COQuotes.put('installmentPlan', yearlyCOQ);    
                //     }
    
                // }          
            }
        }
        
        insert COQuotes.values();

        List<Id> COQIds = new List<Id>(new Map<Id, ChargeOver_Quote__c>(COQuotes.values()).keySet());

        List<Chargeover_Quote__c> coQList = [
            SELECT Id, Name, ChargeOver_URL_Token__c, Quote_Created__c
            FROM Chargeover_Quote__c
            WHERE Id IN : COQIds
        ];
        String redirURL = '';
          
        redirURL = uset.Chargeover_URL__c + '/r/salesforce/wait/quote.custom_1/';
        Boolean prevTokenFound = false;
        //update quote with new billing
        quote.billingSchedule__c = financing;
        quote.Payment_URL__c  = redirURL;
        update quote;
        for(ChargeOver_Quote__c coQItem : coQList){
            if(!prevTokenFound) {
                redirURL = redirURL + coQItem.ChargeOver_URL_Token__c;
                prevTokenFound = true;
            } else {
                redirURL = redirURL + ',' + coQItem.ChargeOver_URL_Token__c;
            }
            
        }
        redirURL = redirURL + '?utm_source=KobysThing';


        List<OpportunityLineItem> toInsertOLI = new List<OpportunityLineItem>();
        List<QuoteLineItem> toInsertQLI = new List<QuoteLineItem>();
        List<ChargeOver_Quote_Line_Item__c> toInsertCOQLI = new List<ChargeOver_Quote_Line_Item__c>();
        
        for(Product2 np : toAddProducts){
            //Opp Line Items
            System.debug(np.Id);
            Decimal thisPrice = ruleMaster.calculateTotal(np.Billing_Frequency__c, financing, Decimal.valueOf(prices.get(String.valueOf(np.Id))), divisor);
            
            String mapKey = ruleMaster.getQuoteKey();
            System.debug(mapKey);
            System.debug(COQuotes.get(mapKey));

            OpportunityLineItem oLIA = new OpportunityLineItem(
                Description = ((np.Description.length() > 255)) ? np.Description.substring(0, 255) : np.Description,
                OpportunityId = oppId,
                Product2Id = np.Id,
                Quantity = 1,//lol no other quantities in all of prod
                UnitPrice = Decimal.valueOf(prices.get(String.valueOf(np.Id))),
                Payment_Cycle__c = ('installmentPlan' == mapKey) ? 'yrl' : mapKey,
                First_Charge_Price__c = thisPrice,
                First_Charge_Total__c = thisPrice,
                Installment_Payment_Schedule__c = PostTSAEmail2ExtensionController.FINANCING.get(financing)
            );
            toInsertOLI.add(oLIA);  //come back to this
            //ChargeOver Line Items
            ChargeOver_Quote_Line_Item__c tempCOLineItem = new ChargeOver_Quote_Line_Item__c(
                ChargeOver_Quote__c = COQuotes.get(mapKey).Id,
                Product__c = np.Id,
                //Price per unit == total price. Divided by installment schedule on CO quote
                Price_Per_Unit__c = thisPrice,
                Quantity__c = 1,
                Contract_Amount__c = thisPrice,
                Product_Description__c = np.Description,
                HTML_Description__c = np.HTML_Description__c,
                Account__c = opportunity.AccountId,
                Sales_Source__c = 'Sales',
                Sort_Order__c = (null == np.Sort_Order__c) ? 4 : np.Sort_Order__c
            );
            toInsertCOQLI.add(tempCOLineItem);         
        }
        insert toInsertOLI;
        insert toInsertCOQLI;

        for(OpportunityLineItem oli : toInsertOLI){
            QuoteLineItem qli = new QuoteLineItem(
                QuoteId = quoteId,
                OpportunityLineItemId = oli.Id,
                PricebookEntryId = productToPricebook.get(oli.Product2Id),
                Product2Id = oli.Product2Id,
                Quantity = oli.Quantity,
                UnitPrice = oli.UnitPrice,
                First_Charge_Price__c = oli.First_Charge_Price__c,
                First_Charge_Total__c = oli.First_Charge_Total__c
            );
            toInsertQLI.add(qli);
        }

        insert toInsertQLI;
        for(ChargeOver_Quote__c coQItem : coQList){
            coQItem.Quote_Created__c = true;
        }
        update coQList;
        PostTSAEmail2ExtensionController.sleep(2000);

        return redirURL;
        
    }

    public static ChargeOver_Quote__c makeMonthlyChargeoverQuote(Opportunity opportunity, Quote SFquote, String schedulerURL) {
        ChargeOver_Quote__c monthlyCOQ = new ChargeOver_Quote__c(
            Name = ((opportunity.Account.Name.length() > 70) ? opportunity.Account.Name.substring(0, 70) : opportunity.Account.Name )+' Quote',
            Payment_Cycle__c = 'mon',
            Account__c = opportunity.AccountId,
            Quote_ID__c = SFquote.Id,
            Quote__c = SFquote.Id,
            Quote_Number__c = SFquote.QuoteNumber + '-m',
            Opportunity__c = opportunity.Id,
            Brand_Name__c = opportunity.Brand__c,
            Contact__c = opportunity.Account.Primary_Contact__c,
            Sales_Source__c = 'Sales',
            Billing_Street_Line_1__c = opportunity.Account.BillingStreet,
            Billing_City__c = opportunity.Account.BillingCity,
            Billing_State__c = opportunity.Account.BillingState,
            Billing_Postal_Code__c = opportunity.Account.BillingPostalCode,
            Billing_Country__c = opportunity.Account.BillingCountry,
            Scheduler_URL__c = schedulerURL
        );
        return monthlyCOQ;
    }
    public static ChargeOver_Quote__c makeYearlyChargeoverQuote(Opportunity opportunity, Quote SFquote, String schedulerURL) {
        ChargeOver_Quote__c yearlyCOQ = new ChargeOver_Quote__c(
            Name = ((opportunity.Account.Name.length() > 70) ? opportunity.Account.Name.substring(0, 70) : opportunity.Account.Name )+' Quote',
            Payment_Cycle__c = 'yrl',
            Account__c = opportunity.AccountId,
            Quote_ID__c = SFquote.Id,
            Quote__c = SFquote.Id,
            Quote_Number__c = SFquote.QuoteNumber + '-y',
            Opportunity__c = opportunity.Id,
            Brand_Name__c = opportunity.Brand__c,
            Contact__c = opportunity.Account.Primary_Contact__c,
            Sales_Source__c = 'Sales',
            Billing_Street_Line_1__c = opportunity.Account.BillingStreet,
            Billing_City__c = opportunity.Account.BillingCity,
            Billing_State__c = opportunity.Account.BillingState,
            Billing_Postal_Code__c = opportunity.Account.BillingPostalCode,
            Billing_Country__c = opportunity.Account.BillingCountry,
            Quote_Created__c = true,
            Scheduler_URL__c = schedulerURL
        );
        return yearlyCOQ;
    }
    public static ChargeOver_Quote__c makeOneTimeChargeoverQuote(Opportunity opportunity, Quote SFquote, String schedulerURL) {
        ChargeOver_Quote__c theCOQuoteOneTime = new ChargeOver_Quote__c(
            Name = ((opportunity.Account.Name.length() > 70) ? opportunity.Account.Name.substring(0, 70) : opportunity.Account.Name )+' Quote',
            Payment_Cycle__c = 'one',
            Account__c = opportunity.AccountID,
            Quote_ID__c = SFquote.ID,
            Quote__c = SFquote.ID,
            Quote_Number__c = SFquote.QuoteNumber + '-o',
            Opportunity__c = opportunity.ID,
            Brand_Name__c = opportunity.Brand__c,
            Contact__c = opportunity.Account.Primary_Contact__c,
            Sales_Source__c = 'Sales',
            Billing_Street_Line_1__c = opportunity.Account.BillingStreet,
            Billing_City__c = opportunity.Account.BillingCity,
            Billing_State__c = opportunity.Account.BillingState,
            Billing_Postal_Code__c = opportunity.Account.BillingPostalCode,
            Billing_Country__c = opportunity.Account.BillingCountry,
            Scheduler_URL__c = schedulerURL
        );
        return theCOQuoteOneTime;
    }
    public static ChargeOver_Quote__c makeYearlywithPaymentsChargeoverQuote(Integer installments, Opportunity opportunity, Quote SFquote, String schedulerURL) {
        ChargeOver_Quote__c yearlyCOQ = new ChargeOver_Quote__c(
            Name = ((opportunity.Account.Name.length() > 70) ? opportunity.Account.Name.substring(0, 70) : opportunity.Account.Name )+' Quote',
            Payment_Cycle__c = 'yrl',
            Account__c = opportunity.AccountId,
            Quote_ID__c = SFquote.Id,
            Quote__c = SFquote.Id,
            Quote_Number__c = SFquote.QuoteNumber + '-y',
            Installment_Payment_Schedule__c = installments,
            Opportunity__c = opportunity.Id,
            Brand_Name__c = opportunity.Brand__c,
            Contact__c = opportunity.Account.Primary_Contact__c,
            Sales_Source__c = 'Sales',
            Billing_Street_Line_1__c = opportunity.Account.BillingStreet,
            Billing_City__c = opportunity.Account.BillingCity,
            Billing_State__c = opportunity.Account.BillingState,
            Billing_Postal_Code__c = opportunity.Account.BillingPostalCode,
            Billing_Country__c = opportunity.Account.BillingCountry,
            Scheduler_URL__c = schedulerURL
        );
        return yearlyCOQ;
    }

    public class Rules {
        private Id salesUserId;

        private Boolean SellClientBooks;

        private String UserSalesSkill;
        private String LeadTypeNew;
        private String LeadSource;
        private String Campaign;
        private String UserRole;

        private Map<String, Calculator_Rule__c> overrideList = new Map<String, Calculator_Rule__c>();
        public Map<String, Calculator_Rule__c> getOverRideProductRules(){return this.overrideList;}

        private String environment;
        public String getEnvironment() { return (null == this.environment) ? 'Standard' : this.environment;}
        
        private Opportunity currentOpportunity;

        private List<Calculator_Rule__c> ruleList = [SELECT Action__c, Criteria_Field_1__c, Criteria_Field_2__c, Criteria_Object__c, Field_1_Operator__c, Field_1_Value__c, Field_2_Operator__c, Field_2_Value__c, Message__c, Product__c, Amount__c, Environment__c, Calculator_Offer__c FROM Calculator_Rule__c WHERE (Criteria_Object__c = 'User' OR Criteria_Object__c = 'Account') AND Active__c = true];
        
        public Rules(Id opportunityId) {
            this.currentOpportunity = [
                SELECT Id, Name, OwnerId, Amount, Pricebook2Id, AccountId, Account.Name, Brand__c, Account.Primary_Contact_ID__c, Account.Primary_Contact__c, Account.BillingStreet, Account.BillingCity, Account.BillingState, Account.BillingPostalCode, Account.BillingCountry
                FROM Opportunity
                WHERE Id = :opportunityId
            ];
        }

        private String loopQuoteKey;
        private void setLoopQuoteKey(String currentVal) {this.loopQuoteKey = currentVal;}
        public String getQuoteKey() {return this.loopQuoteKey;}
        public Decimal calculateTotal(String prodBilling, String financeSchedule, Decimal baseTotal, Integer installments)  {
            Decimal magicNumber = 0.00;
            if('Monthly' == prodBilling) {
                this.setLoopQuoteKey('mon');
                magicNumber = baseTotal;
            } 
            else if('One-Time' == prodBilling) {
                this.setLoopQuoteKey('one');
                magicNumber = baseTotal;                    
            }
            else {
                if('mon' == financeSchedule) {
                    magicNumber = (baseTotal/12)*1.2;
                    this.setLoopQuoteKey(financeSchedule);
                }
                else if('yrl' == financeSchedule) {
                    magicNumber = baseTotal;
                    this.setLoopQuoteKey(financeSchedule);
                }
                else {
                    magicNumber = baseTotal/installments;
                    this.setLoopQuoteKey('installmentPlan');
                }
            }
            return magicNumber;

        }
    }   
}