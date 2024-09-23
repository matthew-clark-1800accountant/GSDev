public with sharing class QuoteGenerator {
    public QuoteGenerator() {

    }

    //to-do: replace these lists with dynamic metadata values
    public static List<String> disabledProductNames = new List<String>{'Dedicated Bookkeeping', 'Personal Financial Planning', 'Core Accounting Package', '1-800Accountant Access', 'Loan Agreement', 'Core Accounting Package (Partner BTP)', 
    'Core Accounting Package (Partner BTP/BOI)', 'Tailor Brands Business and Personal Tax Preparation Package', 'Core Accounting Package (Partner BTPNS/BOI)', 'Beneficial Owner Information Report'};
    public static List<String> disabledQuantityProductNames = new List<String>{'Dedicated Bookkeeping', 'Back Bookkeeping', 'Personal Financial Planning', 'Core Accounting Package', '1-800Accountant Access', 'Loan Agreement', 'Core Accounting Package (Partner BTP)', 
    'Core Accounting Package (Partner BTP/BOI)', 'Tailor Brands Business and Personal Tax Preparation Package', 'Core Accounting Package (Partner BTPNS/BOI)', 'Beneficial Owner Information Report'};
    public static List<String> advisoryAddonProductNames = new List<String>{'1-800Accountant Access', 'Personal Financial Planning', 'Loan Agreement', 'Beneficial Owner Information Report'};
    public static Map<String, List<String>> bundleToDefaultProductNames = new Map<String, List<String>>{
        'Core Accounting Package' => new List<String>{'Business Tax Preparation', 'Personal Tax Preparation', 'Tax Advisory', '1-800Accountant Access', 'Personal Financial Planning', 'Loan Agreement', 'Beneficial Owner Information Report'},
        'Core Accounting Package (Partner BTP)' => new List<String>{'Personal Tax Preparation', 'Tax Advisory', '1-800Accountant Access', 'Personal Financial Planning', 'Loan Agreement', 'Audit Defense - Business','Audit Defense - Personal','Two-Year Review', 'Beneficial Owner Information Report'},
        'Core Accounting Package (Partner BTP/BOI)' => new List<String>{'Personal Tax Preparation', 'Tax Advisory', '1-800Accountant Access', 'Personal Financial Planning', 'Loan Agreement', 'Audit Defense - Business','Audit Defense - Personal','Two-Year Review'},
        'Core Accounting Package (Partner BTP/PTP/BOI)' => new List<String>{'Tax Advisory', '1-800Accountant Access', 'Personal Financial Planning', 'Loan Agreement', 'Audit Defense - Business','Audit Defense - Personal','Two-Year Review'},
        'Core Accounting Package (Partner BTPNS/BOI)' => new List<String>{'Personal Tax Preparation', 'Tax Advisory', '1-800Accountant Access', 'Personal Financial Planning', 'Loan Agreement', 'Audit Defense - Business','Audit Defense - Personal','Two-Year Review', 'Business Tax Preparation - State Only'}
    };
    public static List<String> entityFormationProductNames = new List<String>{'LLC State Filing Fee', 'Corp State Filing Fee', 'Complete Compliance', 'EIN - Priority Processing', 'EIN - Standard Processing', 'Entity Formation', 'Operating Agreement', 'Registered Agent', 'Rush Processing'};
    // var bundleNameToFreeItems = new Map([
    //     ['Core Accounting Package', ['Personal Financial Planning', 'Loan Agreement', 'Beneficial Owner Information Report']],
    //     ['Core Accounting Package (Partner BTP)', ['Two-Year Review', 'Beneficial Owner Information Report']],
    //     ['Core Accounting Package (Partner BTP/BOI)', ['Two-Year Review']],
    //     ['Core Accounting Package (Partner BTP/PTP/BOI)', []],
    //     ['Core Accounting Package (Partner BTPNS/BOI)', ['Two-Year Review', 'Loan Agreement']]
    // ]);

    public static Boolean isValidQuoteId(Id quoteId){
        return (quoteId != null && quoteId != 'null' && Id.valueOf(quoteId).getSObjectType().getDescribe().getName() == 'Quote');
    }

    public static Boolean compareValueWithList(String comparator, String value, List<String> valueList){
        System.debug(value+', '+comparator+', '+valueList);
        if('Not Equal' == comparator){
            return !compareValueWithList('Equals', value, valueList);
        }
        if('Does Not Contain String' == comparator){
            return !compareValueWithList('Contains String', value, valueList);
        }
        
        for(String valueFromList : valueList){
            if('Equals' == comparator && value == valueFromList){
                return true;
            }
            if('Contains String' == comparator && value != null && value.containsIgnoreCase(valueFromList)){
                return true;
            }
        }
        return false;
    }

    public static List<CalculatorProduct> getProductData(Id oppId, Id quoteId) {
        //System.debug('bookkeepingStartString: '+bookkeepingStartString);
        String environment = 'Standard';
        //to-do: implement the tbd generic identifier
        Map<Id, Product2> products = new Map<Id, Product2>([
            SELECT Id, Name, Guided_Selling_Identifier__c, Calculator_Location__c, AnnualMonthlyOption__c, Bundles__c,
            Billing_Frequency__c, Disable_QTY_on_Calc__c, sort_Order__c, No_Split_Allowed__c, HTML_Description__c, Setup_Fee__c,
            Metered_Product__c, Maximum_Allowable_Quantity_Per_Period__c
            FROM Product2 
            WHERE Guided_Selling_Identifier__c != null 
            AND Environment__c INCLUDES (:environment)
            AND Product2.ChargeOver__c = true
            ORDER BY Name
        ]);

        //to-do: query the opp with parameter id
        Opportunity opportunity = [
            SELECT Id, Name, Account.Primary_Contact_Email__c, Account.Primary_Contact__c, Account.Owner.Name, Account.Owner.Email, AccountId, Account.Owner.Skills_Sales__c,
            Account.Name, Account.Lead_Source__c, Account.Primary_Contact__r.FirstName, Account.Primary_Contact__r.LastName, Account.Primary_Contact__r.Phone, 
            Account.Primary_Contact__r.Email, Account.Owner.FirstName, Account.Lead_Type_New__c, Account.Campaign__c, Account.Owner.Id, Account.Entity_Tax_Classification__c,
            Account.Website_Selling_Goods__c, Account.Years_in_Business__c, Account.Industry, Account.State_of_Formation__c, Account.Personal_Return_Filing_Status__c, 
            Account.Total_Startup_Costs__c, Account.Expected_1st_year_revenue__c, Account.Trans_Per_Month__c, 
            Account.How_much_funding__c, Account.Current_Year_Profit_Projection__c, Account.Number_of_owners__c, Account.NumberOfEmployees, 
            Account.Personal_Income__c, Account.Rental_Properties__c, Account.Home_Office_Square_Feet__c, Account.Estimated_Business_Mileage__c, 
            Account.Lead_Source_Date__c
            FROM Opportunity 
            WHERE Id = :oppId
            LIMIT 1
        ];
        User user = [SELECT Id, Name, Skills_Sales__c, Sell_Client_Books__c FROM User WHERE Id = :opportunity.Account.Owner.Id LIMIT 1];
        Account account = [SELECT Id, Lead_Type_New__c, Lead_Source__c, State_of_Formation__c, Entity_Tax_Classification__c, (SELECT Id, Name FROM Active_Subscriptions__r WHERE Subscription_Status__c = 'Active') FROM Account WHERE Id = :opportunity.AccountId LIMIT 1];
        

        List<CalculatorProduct> defaultProducts = new List<CalculatorProduct>(); //filter all products based on GSID and account fields
        List<CalculatorProduct> finalProducts = new List<CalculatorProduct>(); //the same list as allProducts

        
        Set<String> allProducts = new Set<String>(); //add each product, then remove some based on Product_Configuration__mdt 
        Map<String, String> disabledMessage = new Map<String, String>();
        List<Id> allProductIds = new List<Id>();
        Map<String, CalculatorProduct> calculatorProductsIdMap = new Map<String, CalculatorProduct>();

        for(Product2 p : products.values()) {
            p.HTML_Description__c = p.HTML_Description__c?.substring(0,Math.min(1000,p.HTML_Description__c.length())).escapeHtml4().escapeJava();
            allProducts.add(p.Guided_Selling_Identifier__c);
            allProductIds.add(p.Id);
        }

        List<Product_Configuration__mdt> removeOrDisable = [
            SELECT Id, Label, Account_Field__c, Action__c, Active__c, Message__c, Operator__c, Product_Name__c, User_Field__c, Value__c
            FROM Product_Configuration__mdt
            WHERE Product_Name__c IN :allProducts
            AND Active__c = true
        ];

        for(Product_Configuration__mdt rule : removeOrDisable) {
            String accountFieldValue = rule.Account_Field__c;
            String userFieldValue = rule.User_Field__c;
                
            if(null != userFieldValue) {
                Map<String, Object> serializedUser = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(user));
                String userValue = String.valueOf(serializedUser.get(userFieldValue));
                if(compareValueWithList(rule.Operator__c, userValue, rule.Value__c.split(','))){
                    if('Remove Product' == rule.Action__c) {
                        allProducts.remove(rule.Product_Name__c);
                    } else {
                        if(!disabledProductNames.contains(rule.Product_Name__c)){
                            disabledProductNames.add(rule.Product_Name__c);
                            disabledMessage.put(rule.Product_Name__c, rule.Message__c);
                        }                        
                    }
                }                
            }

            if(null != accountFieldValue) {
                System.debug('rule '+rule);
                Map<String, Object> serializedAccount = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(account));
                System.debug('serializedAccount '+serializedAccount);
                System.debug('accountFieldValue: '+accountFieldValue);
                String accountValue = String.valueOf(serializedAccount.get(accountFieldValue));
                if(compareValueWithList(rule.Operator__c, accountValue, rule.Value__c.split(','))){
                    if('Remove Product' == rule.Action__c) {
                        allProducts.remove(rule.Product_Name__c);
                    } else {
                        if(!disabledProductNames.contains(rule.Product_Name__c)){
                            disabledProductNames.add(rule.Product_Name__c);
                            disabledMessage.put(rule.Product_Name__c, rule.Message__c);
                        }  
                    }
                }    
            }
        }

        Map<Id, String> productToIdentifier = new Map<Id, String>();

        Map<String, Id> productIdToIdentifier = new Map<String, Id>();
        for(Product2 p : products.values()) {
            if(allProducts.contains(p.Guided_Selling_Identifier__c)) {
                calculatorProductsIdMap.put(p.Guided_Selling_Identifier__c, new CalculatorProduct(p));
                productIdToIdentifier.put(p.Guided_Selling_Identifier__c, p.Id);
                productToIdentifier.put(p.Id, p.Guided_Selling_Identifier__c);
                
            }  else {
                System.debug('allProducts does not contain '+p.Guided_Selling_Identifier__c);
            }
        }
        System.debug('productToIdentifier: '+productToIdentifier);

        List<Product_Pricing_Rule__mdt> overrideRules = [
            SELECT Id, MasterLabel, Quote_Field2__c, Product_Name__c, Field_Value__c, Price_Adjustment__c, User_Field__c, Account_Field__c, Flat_Price_Override__c
            FROM Product_Pricing_Rule__mdt
            WHERE Product_Name__c IN :allProducts
            AND Flat_Price_Override__c = true
            AND Active__c = true
        ];

        Business__c b;
        List<Business__c> bList = [
                SELECT Id, Name, Account__c, Anticipated_Revenue__c, Industry__c, Business_Type__c, Number_of_Owners__c, Startup_Costs__c, Years_In_Business__c, 
                Profit_Projection__c, Home_Office_Square_Feet__c,
                State_of_incorporation__c, Monthly_Bookkeeping_Transactions__c, Number_of_Employees__c, Tax_Filing_Status__c,
                W2_Income__c, Number_of_Rental_Properties__c, Yearly_Business_Miles__c, 
                Run_Payroll_Before__c, Has_Employees_Contractors__c, File_Return_Yourself__c, Has_Rental_Properties__c, Is_Working_From_Home__c, Commutes_With_Own_Vehicle__c, 
                First_Business__c, Foreign_State_of_Incorporation__c
                FROM Business__c 
                WHERE Account__r.Id = :opportunity.AccountId
                LIMIT 1
            ];
            if(bList.isEmpty()){
                b = new Business__c();
            } else {
                b = bList[0];
            }

        User u = [SELECT Id, Name, Skills_Sales__c, Sell_Client_Books__c FROM User WHERE Id = :opportunity.Account.Owner.Id LIMIT 1];
        Account a = [SELECT Id, Lead_Type_New__c, Lead_Source__c FROM Account WHERE Id = :opportunity.AccountId LIMIT 1];

        Map<Id, Decimal> productToPrice = new Map<Id, Decimal>();
        Map<Id, Decimal> defaultPrices = new Map<Id, Decimal>();
            
        for(Product_Pricing_Rule__mdt rule : overrideRules) {
            String quoteFieldValue = rule.Quote_Field2__c;
            String accountFieldValue = rule.Account_Field__c;
            String userFieldValue = rule.User_Field__c;
            
            // Calling it "quote" but we are using the business data and fields
            if(null != quoteFieldValue) {
                Map<String, Object> serializedQuote = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(b));
                String quoteValue = String.valueOf(serializedQuote.get(quoteFieldValue));
                if(quoteValue == rule.Field_Value__c) {
                    productToPrice.put(productIdToIdentifier.get(rule.Product_Name__c), rule.Price_Adjustment__c);
                    defaultPrices.put(productIdToIdentifier.get(rule.Product_Name__c), rule.Price_Adjustment__c);
                }
            } 

            if(null != userFieldValue) {
                Map<String, Object> serializedUser = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(u));
                String userValue = String.valueOf(serializedUser.get(userFieldValue));
                if(userValue == rule.Field_Value__c) {
                    productToPrice.put(productIdToIdentifier.get(rule.Product_Name__c), rule.Price_Adjustment__c);
                    defaultPrices.put(productIdToIdentifier.get(rule.Product_Name__c), rule.Price_Adjustment__c);
                }
            }

            if(null != accountFieldValue) {
                Map<String, Object> serializedAccount = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(a));
                String accountValue = String.valueOf(serializedAccount.get(accountFieldValue));
                if(accountValue == rule.Field_Value__c) {
                    productToPrice.put(productIdToIdentifier.get(rule.Product_Name__c), rule.Price_Adjustment__c);
                    defaultPrices.put(productIdToIdentifier.get(rule.Product_Name__c), rule.Price_Adjustment__c);
                }
            }
        }

        List<Product_Pricing_Rule__mdt> rules = [
            SELECT Id, MasterLabel, Quote_Field2__c, Product_Name__c, Field_Value__c, Price_Adjustment__c, User_Field__c, Account_Field__c, Flat_Price_Override__c
            FROM Product_Pricing_Rule__mdt
            WHERE Product_Name__c IN :allProducts
            AND Flat_Price_Override__c = false
            AND Active__c = true
        ];
        
        for(Product_Pricing_Rule__mdt rule : rules) {
            String quoteFieldValue = rule.Quote_Field2__c;
            Map<String, Object> serializedObject = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(b));
            String quoteValue = String.valueOf(serializedObject.get(quoteFieldValue));

            if(quoteValue == rule.Field_Value__c) {
                System.debug('applying rule: '+rule);
                if(null == productToPrice.get(productIdToIdentifier.get(rule.Product_Name__c))) {
                    productToPrice.put(productIdToIdentifier.get(rule.Product_Name__c), rule.Price_Adjustment__c);
                    defaultPrices.put(productIdToIdentifier.get(rule.Product_Name__c), rule.Price_Adjustment__c);
                } else {
                    Decimal totalPrice = productToPrice.get(productIdToIdentifier.get(rule.Product_Name__c)) + rule.Price_Adjustment__c;
                    productToPrice.put(productIdToIdentifier.get(rule.Product_Name__c), totalPrice);
                    defaultPrices.put(productIdToIdentifier.get(rule.Product_Name__c), totalPrice);
                }
                System.debug(productToPrice);
            }
            
        }

        // Bundles logic 

        List<Product_Offer__mdt> offerList = [
            SELECT Id, DeveloperName, MasterLabel, Active__c, Amount__c, Environment__c, Product__c, calcId__c
            FROM Product_Offer__mdt 
            WHERE Active__c = true 
            AND Environment__c = :environment
        ];
    
        for(Product_Offer__mdt offerProductItem : offerList) {
            for(Product2 p : products.values()) {
                if(productIdToIdentifier.get(offerProductItem.Product__c) != null) {
                    if(offerProductItem.Product__c == p.Guided_Selling_Identifier__c) {
                        System.debug('applying offer: '+offerProductItem);
                        productToPrice.put(productIdToIdentifier.get(offerProductItem.Product__c), offerProductItem.Amount__c);
                        defaultPrices.put(productIdToIdentifier.get(offerProductItem.Product__c), offerProductItem.Amount__c);
                        System.debug(productToPrice);
                    }
                }
            }
        } 

        Id pricebookId = [SELECT Id, Name, IsActive from PriceBook2 where IsStandard = true LIMIT 1].Id;
        List<Pricebook2> pbList = [SELECT Id, Name, IsActive, IsStandard FROM Pricebook2 WHERE IsActive = true AND Environment__c INCLUDES (:environment)];
        
        for(Pricebook2 pbItem : pbList) {
            pricebookId = pbItem.Id;
        } 
            
        List<PricebookEntry> prices = [
            SELECT Id, Name, Pricebook2Id, UnitPrice, IsActive, Product2Id, Product2.Name, Product2.ChargeOver__c, Product2.Calculator_Location__c, Product2.Guided_Selling_Identifier__c
            FROM PricebookEntry
            WHERE Pricebook2Id = :pricebookId
            AND isActive = true
            AND Product2.ChargeOver__c = true
            AND Product2Id IN :allProductIds
            AND Product2.Id NOT IN :productToPrice.keySet()
        ];
             
        for(PricebookEntry pb : prices) {
            if(null != productIdToIdentifier.get(pb.Product2.Guided_Selling_Identifier__c)) {
                Decimal price = pb.UnitPrice;
                // if(pb.Product2.Guided_Selling_Identifier__c == '1-800Accountant Access'){
                //     price = price * (11.0/12.0);
                // }
                System.debug('applying pbe: '+pb);
                System.debug(pb.Product2.Guided_Selling_Identifier__c);
                productToPrice.put(productIdToIdentifier.get(pb.Product2.Guided_Selling_Identifier__c), price);
                defaultPrices.put(productIdToIdentifier.get(pb.Product2.Guided_Selling_Identifier__c), price);
                System.debug(productToPrice);
            }
        }
        for(String gsid : productIdToIdentifier.keySet()){
            Double adjustedPrice = productToPrice.get(productIdToIdentifier.get(gsid));//+0.03;
            calculatorProductsIdMap.get(gsid).adjustedPrice = adjustedPrice;
            calculatorProductsIdMap.get(gsid).subtotal = adjustedPrice;//qty=1 and freq=default
        }

        // List<PricebookEntry> returnEntries = [SELECT Id, Name, Pricebook2Id, UnitPrice, IsActive, Product2.Name  FROM PricebookEntry WHERE Pricebook2Id = :pricebookId AND isActive = true AND Product2.ChargeOver__c = true
        // AND Product2.Name IN ('Business Return', 'Business Tax Preparation', 'Personal Return', 'Personal Tax Preparation')];
        // for(PricebookEntry pbe : returnEntries){
        //     if(pbe.Product2.Name == 'Business Tax Preparation' || pbe.Product2.Name == 'Business Return'){
        //         btpPricebookEntryPrice = pbe.UnitPrice;
        //     } else if(pbe.Product2.Name == 'Personal Tax Preparation' || pbe.Product2.Name == 'Personal Return'){
        //         ptpPricebookEntryPrice = pbe.UnitPrice;
        //     }
        // }
        List<String> existingQuoteProductNames = new List<String>();
        if(isValidQuoteId(quoteId)){
            System.debug('quoteId: '+quoteId);
            List<OpportunityLineItem> oppItems = [SELECT Payment_Cycle__c, Installment_Payment_Schedule__c, Quantity, UnitPrice, Description FROM OpportunityLineItem WHERE OpportunityId = :opportunity.Id];
            Map<String,String> prodNameToGsid = new Map<String, String>();
            for(Product2 prod : [SELECT Name, Guided_Selling_Identifier__c FROM Product2 WHERE Guided_Selling_Identifier__c != null]){
                prodNameToGsid.put(prod.Name, prod.Guided_Selling_Identifier__c);
            }
            for(OpportunityLineItem oli : oppItems){
                System.debug('oli '+oli);
                String curGsid = prodNameToGsid.get(oli.Description);
                CalculatorProduct curProd = calculatorProductsIdMap.get(curGsid);
                curProd.currentQuantity =  oli.Quantity.intValue();
                //curProd.adjustedPrice = oli.UnitPrice;
                curProd.subtotal = oli.UnitPrice*oli.Quantity;
                if(new List<String>{'Monthly', 'Annual', 'One-Time'}.contains(oli.Installment_Payment_Schedule__c)){
                    curProd.currentBillingFrequency = oli.Installment_Payment_Schedule__c;
                } else {
                    curProd.currentBillingFrequency = new Map<String,String>{'mon'=>'Monthly', 'one'=>'One-Time', 'yrl'=>'Annual'}.get(oli.Payment_Cycle__c);
                }
                curProd.selected = true;
                existingQuoteProductNames.add(curProd.Product.Name);
            }
            // Quote curQuote = [SELECT billingSchedule__c, Calc_Bookkeeping_Start_Date__c FROM Quote WHERE Id = :quoteId LIMIT 1];
            // billingFreq = curQuote.billingSchedule__c;
            // existingBookkeepingStart = curQuote.Calc_Bookkeeping_Start_Date__c;
        } else {
            System.debug('no quoteId found');
        }
        List<CalculatorProduct> calculatorProducts = calculatorProductsIdMap.values();
        // Double monthlyTotal = 0;
        // Double annualTotal = 0;
        // for(CalculatorProduct p : tempSelectedProducts){//defaultProducts){
        //     p.selected = true;
        //     if(p.currentBillingFrequency == 'Monthly'){
        //         monthlyTotal += p.subtotal;
        //     } else {
        //         annualTotal += p.subtotal;
        //     }
        //     System.debug('CalculatorProduct '+p);
        // }
        // quoteTotalAnnual = annualTotal;
        // quoteTotalMonthly = monthlyTotal;

        System.debug('calculatorProducts: ');
        for(CalculatorProduct p : calculatorProducts){
            if(disabledProductNames.contains(p.Product.Name)){
                p.enabled = false;
            }
            if(disabledQuantityProductNames.contains(p.Product.Name)){
                p.quantityEnabled = false;
            }
            if(advisoryAddonProductNames.contains(p.Product.Name) || bundleToDefaultProductNames.keySet().contains(p.Product.Name)){
                p.visible = false;
            }
            System.debug('CalculatorProduct '+p);
        }
        //System.debug(finalProductsJson);
        //System.debug(JSON.deserialize(selectedProductsJson, List<CalculatorProduct>.class));

        return calculatorProducts;
    }
}