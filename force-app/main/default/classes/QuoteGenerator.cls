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
        'Core Accounting Package (Partner BTPNS/BOI)' => new List<String>{'Personal Tax Preparation', 'Tax Advisory', '1-800Accountant Access', 'Personal Financial Planning', 'Loan Agreement', 'Audit Defense - Business','Audit Defense - Personal','Two-Year Review', 'Business Tax Preparation - State Only'},
        'Core Accounting Package (Non-Profit)' => new List<String>{'Non-Profit Tax Preparation', 'Tax Advisory', '1-800Accountant Access', 'Personal Financial Planning', 'Loan Agreement', 'Beneficial Owner Information Report'},
        'Core Personal Package' => new List<String>{'Personal Financial Planning', 'Personal Tax Preparation', 'Audit Defense - Personal', 'Tax Hotline'}
    };
    public static List<String> bundleProducts {get{
        Set<String> bundleProductNames = new Set<String>();
        for(String bundleName : bundleToDefaultProductNames.keySet()){
            bundleProductNames.add(bundleName);
            for(String name : bundleToDefaultProductNames.get(bundleName)){
                bundleProductNames.add(name);
            }
        }        
        return new List<String>(bundleProductNames);
    }}
    public static List<String> entityFormationProductNames = new List<String>{'LLC State Filing Fee', 'Corp State Filing Fee', 'Complete Compliance', 'EIN - Priority Processing', 'EIN - Standard Processing', 'Entity Formation', 'Operating Agreement', 'Registered Agent', 'Rush Processing'};
    
    public static Quote_Bundle__mdt getQuoteBundle(CalculatorConfiguration config){
        Account acc = [SELECT Id, Entity_Tax_Classification__c, Lead_Type_New__c, Lead_Source__c, (SELECT Id, Name, Subscription_Status__c FROM Active_Subscriptions__r) FROM Account WHERE Id = :config.accountId LIMIT 1];
        Map<String, Boolean> subToActiveStatus = new Map<String, Boolean>();
        for(Active_Subscriptions__c sub : acc.Active_Subscriptions__r){
            subToActiveStatus.put(sub.Name, sub.Subscription_Status__c == 'Active');
        }
        String entityType = config.entityOverride == null ? acc.Entity_Tax_Classification__c : config.entityOverride;
        Quote_Bundle__mdt eligibleBundle;

        for(Quote_Bundle__mdt bundle : [SELECT Id, MasterLabel, DeveloperName, Required_Entity_Type__c, Description__c,
        Required_LTN__c, Required_Source__c, Required_Subscriptions__c, Bundle_Priority__c FROM Quote_Bundle__mdt WHERE Active__c = true
        AND (Calculator_Availability__c = 'Any' OR Calculator_Availability__c = :config.calculator) ORDER BY Bundle_Priority__c desc]){
            System.debug(bundle);
            if(bundle.Required_Entity_Type__c != null && entityType != bundle.Required_Entity_Type__c){
                continue;
            }
            if(bundle.Required_Source__c != null && acc.Lead_Source__c != bundle.Required_Source__c){
                continue;
            }
            if(bundle.Required_Subscriptions__c != null){
                Boolean disqualified = false;
                for(String subName : bundle.Required_Subscriptions__c.split('&')){
                    if(subName == 'Business Tax Preparation' && !subToActiveStatus.containsKey('Business Tax Preparation')){
                        disqualified = !acc.Lead_Type_New__c.contains('BTP');
                    } else if(subName == 'Personal Tax Preparation' && !subToActiveStatus.containsKey('Personal Tax Preparation')){
                        disqualified = !acc.Lead_Type_New__c.contains('PTP');
                    } else if(subToActiveStatus.get(subName) != true){
                        disqualified = true;
                    }
                }
                if(disqualified){ continue; }
            }
            if(bundle.Required_LTN__c != null){
                Boolean disqualified = false;
                if(bundle.Required_LTN__c == 'BTP' && subToActiveStatus.containsKey('Business Tax Preparation')){
                    disqualified = !subToActiveStatus.get('Business Tax Preparation');
                } else if(bundle.Required_LTN__c == 'PTP' && subToActiveStatus.containsKey('Personal Tax Preparation')){
                    disqualified = !subToActiveStatus.get('Personal Tax Preparation');
                } else {
                    disqualified = !acc.Lead_Type_New__c.contains(bundle.Required_LTN__c);
                }
                if(disqualified){ continue; }
            }

            //return the first bundle that does not fail a requirement
            eligibleBundle = bundle;
            break;
        }
        return eligibleBundle;
    }

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

    public static Boolean containsAny(List<Object> list1, List<Object> list2){
        for(Object ob : list1){
            if(list2.contains(ob)){
                return true;
            }
        }
        return false;
    }

    public static List<CalculatorProduct> getProductData(CalculatorConfiguration config, String eligibleBundle) {
        //System.debug('bookkeepingStartString: '+bookkeepingStartString);
        String environment = 'Standard';
        if(config.calculator == null){ config.calculator = 'Any'; }
        //to-do: implement the tbd generic identifier
        Map<Id, Product2> products = new Map<Id, Product2>([
            SELECT Id, Name, Guided_Selling_Identifier__c, Calculator_Location__c, AnnualMonthlyOption__c, Bundles__c,
            Billing_Frequency__c, Disable_QTY_on_Calc__c, sort_Order__c, No_Split_Allowed__c, HTML_Description__c, Setup_Fee__c,
            Metered_Product__c, Maximum_Allowable_Quantity_Per_Period__c, Advisory_Addon__c
            FROM Product2 
            //WHERE Guided_Selling_Identifier__c != null 
            WHERE Calculator_Product__c = true
            AND Environment__c INCLUDES (:environment)
            AND Product2.ChargeOver__c = true
            ORDER BY Name
        ]);

        Account acc = [
            SELECT Primary_Contact_Email__c, Primary_Contact__c, Owner.Name, Owner.Email, Owner.Skills_Sales__c,
            Name, Lead_Source__c, Primary_Contact__r.FirstName, Primary_Contact__r.LastName, Primary_Contact__r.Phone, 
            Primary_Contact__r.Email, Owner.FirstName, Lead_Type_New__c, Campaign__c, Owner.Id, Entity_Tax_Classification__c,
            Website_Selling_Goods__c, Years_in_Business__c, Industry, State_of_Formation__c, Personal_Return_Filing_Status__c, 
            Total_Startup_Costs__c, Expected_1st_year_revenue__c, Trans_Per_Month__c, 
            How_much_funding__c, Current_Year_Profit_Projection__c, Number_of_owners__c, NumberOfEmployees, 
            Personal_Income__c, Rental_Properties__c, Home_Office_Square_Feet__c, Estimated_Business_Mileage__c, 
            Lead_Source_Date__c
            FROM Account 
            WHERE Id = :config.accountId
            LIMIT 1
        ];
        User accountOwner = [SELECT Id, Name, Skills_Sales__c, Sell_Client_Books__c FROM User WHERE Id = :acc.Owner.Id LIMIT 1];
        //Account account = [SELECT Id, Lead_Type_New__c, Lead_Source__c, State_of_Formation__c, Entity_Tax_Classification__c, (SELECT Id, Name FROM Active_Subscriptions__r WHERE Subscription_Status__c = 'Active') FROM Account WHERE Id = :config.accountId LIMIT 1];
        

        List<CalculatorProduct> defaultProducts = new List<CalculatorProduct>(); //filter all products based on GSID and account fields
        List<CalculatorProduct> finalProducts = new List<CalculatorProduct>(); //the same list as allProducts

        
        Set<String> allProducts = new Set<String>(); //add each product, then remove some based on Product_Configuration__mdt 
        Map<String, String> disabledMessage = new Map<String, String>();
        List<Id> allProductIds = new List<Id>();
        //Map<String, CalculatorProduct> calculatorProductsIdMap = new Map<String, CalculatorProduct>();

        for(Product2 p : products.values()) {
            p.HTML_Description__c = p.HTML_Description__c?.substring(0,Math.min(1000,p.HTML_Description__c.length())).escapeHtml4().escapeJava();
            allProducts.add(p.Name);
            allProductIds.add(p.Id);
        }

        //to-do: add support for product rules that distinguish between calculators
        //to-do: add support for quantity disable rules
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
                Map<String, Object> serializedUser = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(accountOwner));
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
                Map<String, Object> serializedAccount = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(acc));
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
        Map<String, CalculatorProduct> nameToProduct = new Map<String, CalculatorProduct>();
        //Map<Id, CalculatorProduct> idToProduct = new Map<Id, CalculatorProduct>();


        for(Product2 p : products.values()) {
            if(allProducts.contains(p.Name)) {
                CalculatorProduct prod = new CalculatorProduct(p);
                nameToProduct.put(p.Name, prod);
                //idToProduct.put(p.Id, prod);                
            }  else {
                System.debug('allProducts does not contain '+p.Guided_Selling_Identifier__c);
            }
        }
        System.debug('nameToProduct: '+nameToProduct);

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
                WHERE Account__r.Id = :config.accountId
                LIMIT 1
            ];
            if(bList.isEmpty()){
                b = new Business__c();
            } else {
                b = bList[0];
            }

        //User u = [SELECT Id, Name, Skills_Sales__c, Sell_Client_Books__c FROM User WHERE Id = :acc.Owner.Id LIMIT 1];
        //Account a = [SELECT Id, Lead_Type_New__c, Lead_Source__c FROM Account WHERE Id = :config.accountId LIMIT 1];

        Map<Id, Decimal> productIdToPrice = new Map<Id, Decimal>();
        Map<Id, Decimal> defaultPrices = new Map<Id, Decimal>();
            
        for(Product_Pricing_Rule__mdt rule : overrideRules) {
            String businessFieldValue = rule.Quote_Field2__c;
            String accountFieldValue = rule.Account_Field__c;
            String userFieldValue = rule.User_Field__c;
            
            // Calling it "quote" but we are using the business data and fields
            if(null != businessFieldValue) {
                Map<String, Object> serializedQuote = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(b));
                String businessValue = String.valueOf(serializedQuote.get(businessFieldValue));
                if(businessValue == rule.Field_Value__c) {
                    System.debug('using pricing rule: '+rule);
                    productIdToPrice.put(nameToProduct.get(rule.Product_Name__c).Id, rule.Price_Adjustment__c);
                    defaultPrices.put(nameToProduct.get(rule.Product_Name__c).Id, rule.Price_Adjustment__c);
                }
            } 

            if(null != userFieldValue) {
                Map<String, Object> serializedUser = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(accountOwner));
                String userValue = String.valueOf(serializedUser.get(userFieldValue));
                if(userValue == rule.Field_Value__c) {
                    System.debug('using pricing rule: '+rule);
                    productIdToPrice.put(nameToProduct.get(rule.Product_Name__c).Id, rule.Price_Adjustment__c);
                    defaultPrices.put(nameToProduct.get(rule.Product_Name__c).Id, rule.Price_Adjustment__c);
                }
            }

            if(null != accountFieldValue) {
                Map<String, Object> serializedAccount = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(acc));
                String accountValue = String.valueOf(serializedAccount.get(accountFieldValue));
                if(accountValue == rule.Field_Value__c) {
                    System.debug('using pricing rule: '+rule);
                    productIdToPrice.put(nameToProduct.get(rule.Product_Name__c).Id, rule.Price_Adjustment__c);
                    defaultPrices.put(nameToProduct.get(rule.Product_Name__c).Id, rule.Price_Adjustment__c);
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
            String businessFieldValue = rule.Quote_Field2__c;
            Map<String, Object> serializedObject = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(b));
            String businessValue = String.valueOf(serializedObject.get(businessFieldValue));

            if(businessValue == rule.Field_Value__c) {
                System.debug('applying rule: '+rule);
                if(null == productIdToPrice.get(nameToProduct.get(rule.Product_Name__c).Id)) {
                    productIdToPrice.put(nameToProduct.get(rule.Product_Name__c).Id, rule.Price_Adjustment__c);
                    defaultPrices.put(nameToProduct.get(rule.Product_Name__c).Id, rule.Price_Adjustment__c);
                } else {
                    Decimal totalPrice = productIdToPrice.get(nameToProduct.get(rule.Product_Name__c).Id) + rule.Price_Adjustment__c;
                    productIdToPrice.put(nameToProduct.get(rule.Product_Name__c).Id, totalPrice);
                    defaultPrices.put(nameToProduct.get(rule.Product_Name__c).Id, totalPrice);
                }
                System.debug(productIdToPrice);
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
            CalculatorProduct curProd = nameToProduct.get(offerProductItem.Product__c);
            if(curProd != null) {
                System.debug('applying offer: '+offerProductItem);
                productIdToPrice.put(curProd.Id, offerProductItem.Amount__c);
                defaultPrices.put(curProd.Id, offerProductItem.Amount__c);
                curProd.isInOffer = true;
                curProd.delayDays = offerProductItem.Delay_Days__c.intValue();
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
            AND Product2.Id NOT IN :productIdToPrice.keySet()
        ];
             
        for(PricebookEntry pb : prices) {
            if(null != nameToProduct.get(pb.Product2.Name)) {
                Decimal price = pb.UnitPrice;
                CalculatorProduct prod = nameToProduct.get(pb.Product2.Name);
                System.debug('applying pbe: '+pb);
                prod.pbeId = pb.Id;
                productIdToPrice.put(prod.Id, price);
                defaultPrices.put(prod.Id, price);
            }
        }
        for(CalculatorProduct prod : nameToProduct.values()){
            Double adjustedPrice = productIdToPrice.get(prod.Id);//+0.03;
            prod.adjustedPrice = adjustedPrice;
            prod.subtotal = adjustedPrice;//qty=1 and freq=default
        }

        List<String> existingQuoteProductNames = new List<String>();
       

        List<String> bundleNames = new List<String>();
        for(Quote_Bundle__mdt bundle : [SELECT Description__c FROM Quote_Bundle__mdt]){
            bundleNames.add(bundle.Description__c);
        }
        List<CalculatorProduct> calculatorProducts = nameToProduct.values();
        if(eligibleBundle == null){ eligibleBundle = getQuoteBundle(config)?.Description__c; }
        CalculatorProduct coreProduct;
        Map<Id, Quote_Bundle_Product__mdt> productIdToBundleProduct = new Map<Id, Quote_Bundle_Product__mdt>();
        for(Quote_Bundle_Product__mdt bundleProduct : [SELECT Id, MasterLabel, Default__c, Free__c, Required__c, Product_Id__c 
        FROM Quote_Bundle_Product__mdt WHERE Quote_Bundle__r.Description__c = :eligibleBundle]){
            productIdToBundleProduct.put(bundleProduct.Product_Id__c, bundleProduct);
        }
        System.debug('calculatorProducts: ');
        System.debug(productIdToBundleProduct);
        List<CalculatorProduct> tempProds = new List<CalculatorProduct>();
        for(CalculatorProduct p : calculatorProducts){
            Quote_Bundle_Product__mdt bundleProduct = productIdToBundleProduct.get(p.Product.Id);
            System.debug('CalculatorProduct '+p);
            // if(disabledProductNames.contains(p.Product.Name)){
            //     p.enabled = false;
            // }
            p.baseCalculatorPrice = p.adjustedPrice;
            if(bundleNames.contains(p.Product.Name) || p.advisoryAddon){
                p.enabled = false;
                p.visible = false;
            }
            if(disabledQuantityProductNames.contains(p.Product.Name)){
                p.quantityEnabled = false;
            }
            //if(advisoryAddonProductNames.contains(p.Product.Name) || bundleToDefaultProductNames.keySet().contains(p.Product.Name)){
            // if(p.advisoryAddon || p.Product.Name == eligibleBundle){
            //     p.visible = false;
            // }
            if(bundleProduct != null){
                if(bundleProduct.Default__c){ p.selected = true; }
                p.defaultForBundle = bundleProduct.Default__c;
                p.freeWithBundle = bundleProduct.Free__c;
                p.requiredForBundle = bundleProduct.Required__c;
            }
            // if(p.Product.Name == eligibleBundle){
            //     coreProduct = p;
            // }
            if(!bundleNames.contains(p.Product.Name) || p.Product.Name == eligibleBundle){
                tempProds.add(p);
            }            
        }
        //System.debug(finalProductsJson);
        //System.debug(JSON.deserialize(selectedProductsJson, List<CalculatorProduct>.class));

        return tempProds;
    }

    public static Boolean useBundlePricing(CalculatorConfiguration config, List<CalculatorProduct> products){
        Boolean hasActiveBTP = false;
        Boolean hasActivePTP = false;
        Boolean hasActiveNPTP = false;
        Boolean hasActiveAdvisory = false;
        Boolean hasActiveBundle = false;
        Boolean hasActiveHotline = false;
        Boolean hasActivePAD = false;

        Account acc = [SELECT Lead_Type_New__c, Lead_Source__c, Campaign__c, State_of_Formation__c, (SELECT Id, Product__c, Subscription_Status__c, Name FROM Active_Subscriptions__r) FROM Account WHERE Id = :config.accountId];
        if(acc.Lead_Type_New__c.contains('BTP')){
            hasActiveBTP = true;
        }
        if(acc.Lead_Type_New__c.contains('PTP')){
            hasActivePTP = true;
        }
        if(acc.Lead_Type_New__c.contains('Advisory')){
            hasActiveAdvisory = true;
        }
        if(acc.Lead_Type_New__c.contains('Non-Profit')){
            hasActiveNPTP = true;
        }

        for (Active_Subscriptions__c aSubItem : acc.Active_Subscriptions__r) {        
            if(aSubItem.Name == 'Tax Advisory'){
                hasActiveAdvisory = (aSubItem.Subscription_Status__c == 'Active');
            } else if (aSubItem.Name == 'Personal Tax Preparation'){
                hasActivePTP = (aSubItem.Subscription_Status__c == 'Active');
            } else if (aSubItem.Name == 'Business Tax Preparation'){
                hasActiveBTP = (aSubItem.Subscription_Status__c == 'Active');
            } else if (aSubItem.Name.contains('Core Accounting Package') || aSubItem.Name.contains('Custom Accounting Package') || aSubItem.Name.contains('Custom Personal Package')){
                hasActiveBundle = (aSubItem.Subscription_Status__c == 'Active');
            } else if (aSubItem.Name == 'Non-Profit Tax Preparation'){
                hasActiveNPTP = (aSubItem.Subscription_Status__c == 'Active');
            } else if (aSubItem.Name == 'Audit Defense - Personal'){
                hasActivePAD = (aSubItem.Subscription_Status__c == 'Active');
            } else if (aSubItem.Name == 'Tax Hotline'){
                hasActiveHotline = (aSubItem.Subscription_Status__c == 'Active');
            } 
        }

        for(CalculatorProduct prod : products){
            if(prod.selected){
                if(prod.Name == 'Tax Advisory'){
                    hasActiveAdvisory = true;
                } else if (prod.Name == 'Personal Tax Preparation'){
                    hasActivePTP = true;
                } else if (prod.Name == 'Business Tax Preparation'){
                    hasActiveBTP = true;
                } else if (prod.Name.contains('Core Accounting Package') || prod.Name.contains('Custom Accounting Package') || prod.Name.contains('Custom Personal Package')){
                    hasActiveBundle = true;
                } else if (prod.Name == 'Non-Profit Tax Preparation'){
                    hasActiveNPTP = true;
                } else if (prod.Name == 'Audit Defense - Personal'){
                    hasActivePAD = true;
                } else if (prod.Name == 'Tax Hotline'){
                    hasActiveHotline = true;
                }
            }
        }

        String eligibleBundle = getQuoteBundle(config)?.Description__c;
        if(eligibleBundle == 'Core Accounting Package (Non-Profit)'){
            return hasActiveNPTP && hasActiveAdvisory;
        } else if(eligibleBundle == 'Core Personal Package'){
            return hasActiveHotline && hasActivePAD && hasActivePTP;
        } else {
            return hasActiveBTP && hasActivePTP && hasActiveAdvisory;
        }      
    }

    public static List<CalculatorProduct> updatePrices(CalculatorConfiguration config, List<CalculatorProduct> products, List<CalculatorProduct> selectedProducts){
        Double bundleDiscount = Dynamic_Pricing_Values__c.getValues('Bundle discount')?.Percent_value__c;
        if(bundleDiscount == null){ bundleDiscount = 0.191; }
        else { bundleDiscount = bundleDiscount / 100.0; }
        if(selectedProducts == null){selectedProducts = getSelectedProducts(products, null);}

        Boolean useBundlePrice = useBundlePricing(config, selectedProducts);
        String bundleName = getQuoteBundle(config)?.Description__c;
        Map<String, CalculatorProduct> nameToProduct = new Map<String, CalculatorProduct>();
        List<CalculatorProduct> advisoryAddons = new List<CalculatorProduct>();

        for(CalculatorProduct prod : products){
            prod.selected = false;
            
            nameToProduct.put(prod.name, prod);
            if(useBundlePrice){
                prod.adjustedPrice = prod.freeWithBundle ? 0 : Math.ceil(prod.baseCalculatorPrice * (1-bundleDiscount));
            } else {
                prod.adjustedPrice = prod.baseCalculatorPrice;
            }
            prod.subtotal = prod.adjustedPrice * prod.currentQuantity;
            if(prod.advisoryAddon){advisoryAddons.add(prod);}
        }
        for(CalculatorProduct prod : selectedProducts){
            nameToProduct.get(prod.name).selected = true;
        }
        
        
        
        if(nameToProduct.containsKey(bundleName)){ nameToProduct.get(bundleName).selected = useBundlePrice; }
        if(nameToProduct.containsKey('Tax Advisory')){ 
            Boolean advisorySelected = nameToProduct.get('Tax Advisory').selected;
            for(CalculatorProduct addon : advisoryAddons){ addon.selected = advisorySelected; }
        }
        if(nameToProduct.containsKey('Payroll') && nameToProduct.containsKey('Payroll Setup Fee')){ nameToProduct.get('Payroll Setup Fee').selected = nameToProduct.get('Payroll').selected; }
        return products;
    }

    public static List<CalculatorProduct> getSelectedProducts(List<CalculatorProduct> products, List<CalculatorProduct> selectedProducts){
        List<CalculatorProduct> results = new List<CalculatorProduct>();
        if(selectedProducts == null){
            for(CalculatorProduct prod : products){
                if(prod.selected){ results.add(prod); }
            }
        } else {
            for(CalculatorProduct prod : products){
                if(selectedProducts.contains(prod)){ prod.selected=true; results.add(prod); }
            }
        }
        
        return results;
    }
    public static Id updateAndDeployMetadata() {
        Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
        Map<String, String> descToBundleLabel = new Map<String, String>();
        for(Quote_Bundle__mdt bundle : [SELECT Description__c, DeveloperName FROM Quote_Bundle__mdt]){
            descToBundleLabel.put(bundle.Description__c, bundle.DeveloperName);
        }

        Map<String, String> productNameToId = new Map<String, String>();
        for(Product2 prod : [SELECT Name, Id FROM Product2 WHERE Calculator_Location__c != null AND Name IN :bundleProducts]){
            productNameToId.put(prod.Name, prod.Id);
        }

        System.debug(descToBundleLabel);


        Metadata.CustomMetadata customMetadata;
        Metadata.CustomMetadataValue customField;
        String formattedBundleName;
        String formattedProductName;
        String uniqueProductName;
        for(String bundleName : bundleToDefaultProductNames.keySet()){
            formattedBundleName = bundleName.replace(')', '').replace('(', '').replace('/', '').replace('-', '').replace('  ', '_').replace(' ', '_').replace('__', '_');
            uniqueProductName = (formattedBundleName).left(40);
            if(uniqueProductName.substring(0,1) == '_'){uniqueProductName = uniqueProductName.substring(1);}
            if(uniqueProductName.substring(uniqueProductName.length()-1, uniqueProductName.length()) == '_'){uniqueProductName = uniqueProductName.substring(0, uniqueProductName.length()-1);}
            
            customMetadata =  new Metadata.CustomMetadata();
            customMetadata.fullName = 'Quote_Bundle_Product.'+uniqueProductName;
            customMetadata.label = bundleName.left(40);

            // customField = new Metadata.CustomMetadataValue();
            // customField.field = 'MasterLabel';
            // customField.value = uniqueProductName;
            // customMetadata.values.add(customField);

            customField = new Metadata.CustomMetadataValue();
            customField.field = 'Product_Id__c';
            customField.value = productNameToId.containsKey(bundleName) ? productNameToId.get(bundleName) : '';
            customMetadata.values.add(customField);

            customField = new Metadata.CustomMetadataValue();
            customField.field = 'Quote_Bundle__c';
            customField.value = descToBundleLabel.get(bundleName);
            customMetadata.values.add(customField);

            customField = new Metadata.CustomMetadataValue();
            customField.field = 'Default__c';
            customField.value = true;
            customMetadata.values.add(customField);
            System.debug(customMetadata);
            mdContainer.addMetadata(customMetadata);
            
            for(String prodName : bundleToDefaultProductNames.get(bundleName)){
                formattedProductName = prodName.replace(')', '').replace('(', '').replace('/', '').replace('-', '').replace('  ', '_').replace(' ', '_').replace('__', '_');
                uniqueProductName = (formattedBundleName.right(15)+formattedProductName).right(40);
                if(uniqueProductName.substring(0,1) == '_'){uniqueProductName = uniqueProductName.substring(1);}
                if(uniqueProductName.substring(uniqueProductName.length()-1, uniqueProductName.length()) == '_'){uniqueProductName = uniqueProductName.substring(0, uniqueProductName.length()-1);}
                
                customMetadata =  new Metadata.CustomMetadata();
                customMetadata.fullName = 'Quote_Bundle_Product.'+uniqueProductName;
                customMetadata.label = prodName.left(40);


                // customField = new Metadata.CustomMetadataValue();
                // customField.field = 'MasterLabel';
                // customField.value = uniqueProductName;
                // customMetadata.values.add(customField);
                
                customField = new Metadata.CustomMetadataValue();
                customField.field = 'Product_Id__c';
                customField.value = productNameToId.containsKey(prodName) ? productNameToId.get(prodName) : '';
                customMetadata.values.add(customField);

                customField = new Metadata.CustomMetadataValue();
                customField.field = 'Quote_Bundle__c';
                //customField.value = 'Quote_Bundle.'+descToBundleLabel.get(bundleName);
                customField.value = descToBundleLabel.get(bundleName);
                customMetadata.values.add(customField);

                customField = new Metadata.CustomMetadataValue();
                customField.field = 'Default__c';
                customField.value = true;
                customMetadata.values.add(customField);
                
            System.debug(customMetadata);
                mdContainer.addMetadata(customMetadata);
            }
        }
               
        // Enqueue custom metadata deployment
        Id jobId = Metadata.Operations.enqueueDeployment(mdContainer, null);
        return jobId;
    }

    public static ChargeOver_Quote__c getChargeOverQuote(List<String> data) {
        
        Integer instPay = 0;
        if(data[16] != '' && data[16] != null) {
            instPay = integer.valueof(data[16]);
        } else {
            instPay = null;
        }
        ChargeOver_Quote__c chargeOverQuote = new ChargeOver_Quote__c(
                Name = data[0] + ' Quote',
                Payment_Cycle__c = data[1],
                Account__c = data[2],
                Quote_ID__c = data[3],
                Quote__c = data[3],
                Quote_Number__c = data[4] + data[5],
                Opportunity__c = data[6],
                Brand_Name__c = data[7],
                Contact__c = data[8],
                Sales_Source__c = 'Sales',
                Billing_Street_Line_1__c = data[9],
                Billing_City__c = data[10],
                Billing_State__c = data[11],
                Billing_Postal_Code__c = data[12],
                Billing_Country__c = data[13],
                //Scheduler_URL__c = data[14],
                Guided_Selling_Scheduler_URL__c = data[14],
                Name_of_Offer_Package__c = data[15],
                Installment_Payment_Schedule__c = instPay,
                Scheduler_URL_VIP_hide__c = data[17],
                isFromGuidedSelling__c = true
            );
        return chargeOverQuote;
    }
    
    public static String getChargeOverURL(Id opportunityId) {

        Boolean prevTokenFound = false;
        Chargeover_URL__c uset = Chargeover_URL__c.getOrgDefaults();
        String theURL = uset.Chargeover_URL__c;
        String redirURL = theURL + '/r/salesforce/wait/quote.custom_1/';
        String cOQuoteId = '';
        String cOQuoteIdOneTime = '';
        String cOQuoteIdMonth = '';
        
        list<ChargeOver_Quote__c> coQuoteList = [
                SELECT Id, Quote_Created__c, ChargeOver_View_URL__c, Payment_Cycle__c, ChargeOver_URL_Token__c
                FROM ChargeOver_Quote__c 
                WHERE Opportunity__r.Id = :opportunityId];

        for(ChargeOver_Quote__c coQ : coQuoteList) {
            if(coQ.Payment_Cycle__c == 'yrl') {
                cOQuoteId = coQ.Id;
            } else if(coQ.Payment_Cycle__c == 'one') {
                cOQuoteIdOneTime = coQ.Id;
            } else if(coQ.Payment_Cycle__c == 'mon') {
                cOQuoteIdMonth = coQ.Id;
            }
        }

        if (cOQuoteId != '') {
            if (prevTokenFound == true) {
                redirURL = redirURL + ',';
            }
            
            for(ChargeOver_Quote__c coQ : coQuoteList) {
                if(coQ.Id == cOQuoteId) {
                    redirURL = redirURL + coQ.ChargeOver_URL_Token__c;
                    prevTokenFound = true;
                }
            }
        }
        
        if (cOQuoteIdOneTime != '') {
            if (prevTokenFound == true) {
                redirURL = redirURL + ',';
            }
            
            for(ChargeOver_Quote__c coQ : coQuoteList) {
                if(coQ.Id == cOQuoteIdOneTime) {
                    redirURL = redirURL + coQ.ChargeOver_URL_Token__c;
                    prevTokenFound = true;
                }
            }
        }
        
        if (cOQuoteIdMonth != '') {
            if (prevTokenFound == true) {
                redirURL = redirURL + ',';
            }
            
            for(ChargeOver_Quote__c coQ : coQuoteList) {
                if(coQ.Id == cOQuoteIdMonth) {
                    redirURL = redirURL + coQ.ChargeOver_URL_Token__c;
                    prevTokenFound = true;
                }
            }
        }

        String updURL = redirURL;
        redirURL = redirURL + '?utm_source=Sales&utm_term=Sales&utm_medium=Guided+Selling';
        
        //sleep(4000);
        
        List<Quote> quoteList = [SELECT Id, Payment_URL__c FROM Quote WHERE OpportunityId = :opportunityId];
        if(quoteList.size() > 0) {
            for(Quote q : quoteList) {
                q.Payment_URL__c = redirURL;
            }
        }

        update quoteList;
        
        update new Opportunity(
            Id = opportunityId,
            StageName = 'Quote Generated'
        );

        return updURL;
    }

    //input review:
    //environment: only used to determine pricing mdt to use
    //listProdSelected: primary product data
    //oppId/accOd: used to update the opportunity and create the quotes and line items
    //billingTime: used to determine branding (?) as well as opp/quote data
    //delProds: used to filter out input products
    //@RemoteAction
    public static String doSubmit(CalculatorConfiguration config, List<CalculatorProduct> selectedProds, String bundleName) {
        //quoteButtonText = 'Next Section';
        // Initialize class variables
        System.debug('doSubmit');
        String environment = 'Standard';
        //List<CalculatorProduct> selectedProds = (List<CalculatorProduct>) JSON.deserialize(listProdSelected, List<CalculatorProduct>.class);
        Opportunity opp = [SELECT Id, AccountId, StageName, OwnerId, Email_Campaign_ID__c FROM Opportunity WHERE Id = :config.opportunityId LIMIT 1];
        String emailCampId = opp.Email_Campaign_ID__c;
        Id accountId = opp.AccountId;

        if(bundleName == null){
            bundleName = getQuoteBundle(config).Description__c;
        }
        String packageName = bundleName;
        String quoteID = '';
        String quoteNum = '';
        String brand = '1-800Accountant';
        String leadTypeNew = '';
        String leadSource = '';
        Boolean entityFormation = false;
        Boolean clientBooks = false;
        Boolean advisory = false;
        Boolean bookkAdv = false;
        Boolean bookk = false;
        Boolean payroll = false;
        Boolean backBookk = false;
        Boolean persTaxAdv = false;
        Boolean persTaxPrep = false;
        Boolean busiRet = false;
        Boolean persRet = false;
        Boolean doSomeSchedule = false;
        String apptType = '';
        String contactId = '';
        String coQuoteMonthId = '';
        //String coQuoteOneTimeId = '';
        String coQuoteAnnualId = '';
        List<Id> coQuoteOneTimeIds = new List<String>();
        Double quoteTotal = 0;

        // Initialize package name

        List<Product_Offer__mdt> offerList = [
            SELECT Id, DeveloperName, MasterLabel, Active__c, Amount__c, Environment__c, Product__c, calcId__c, Default_Parent__c, Default_Child_isMaster__c, Delay_Days__c
            FROM Product_Offer__mdt 
            WHERE Active__c = true 
            AND Environment__c = :environment];
            
        Set<String> prodsIds = new Set<String>();
        

        // // Get products ids from the selected ones
        Decimal vipAmount = quoteTotal;
        if(vipAmount == null){
            System.debug('quoteTotal not found');
            vipAmount = 0.00;
            for(CalculatorProduct prod : selectedProds) {
                vipAmount += prod.subtotal;
                prodsIds.add(prod.Product.Id);
            }
        } else {
            for(CalculatorProduct prod : selectedProds) {
                prodsIds.add(prod.Product.Id);
            }
        }
        

        // // Get standard Pricebook id

        String standardPriceBookID = '';
        List<Pricebook2> pbList = [
            SELECT Id, Name, IsActive, IsStandard 
            FROM Pricebook2 
            WHERE IsActive = true 
            AND Environment__c includes (:environment)];
        for(Pricebook2 pbItem : pbList) {
            standardPriceBookID = pbItem.Id;
        }


        // Get Product information from the selected ones

        Map<Id,Product2> productList = new Map<Id, Product2>([
            SELECT Id, Calculator_Location__c, Name, AnnualMonthlyOption__c, Billing_Frequency__c, HTML_Description__c, Description, No_Split_Allowed__c, Guided_Selling_Identifier__c, sort_Order__c, Maximum_Allowable_Quantity_Per_Period__c, Metered_Product__c
            FROM Product2 
            WHERE Id IN :prodsIds]);
        
        Decimal businessTax = 0.00;
        Decimal personalTax = 0.00;

        
        Boolean doMonthlyQuote = false;
        Boolean doOneTimeQuote = false;
        Boolean doAnnualQuote = false;

        Map<Integer, String> payNumToScheduleString = new Map<Integer,String>{
            1 => '',
            2 => '4',
            3 => '5',
            4 => '6',
            6 => '7',
            12 => '7' //this one shouldn't ever be used
        };
        Set<String> oneTimeSchedules = new Set<String>();
        
        Map<String, CalculatorProduct> nameToProduct = new Map<String, CalculatorProduct>();
        //Map<String, CalculatorProduct> nameToProductMap = new Map<String, CalculatorProduct>();
        CalculatorProduct advisoryProduct;
        Double advisoryAddonTotal = 0;
        //List<String> advisoryAddonProductNames = new List<String>{'1-800Accountant Access', 'Personal Financial Planning', 'Loan Agreement', 'Beneficial Owner Information Report'};
        for(CalculatorProduct prodData : selectedProds) {
            System.debug('setting flags for '+prodData.Product.Name);

            System.debug('prodData '+prodData);
            System.debug('productList '+productList.get(prodData.Id));
            prodData.Product.Description = productList.get(prodData.Product.Id).Description;
            prodData.Product.HTML_Description__c = productList.get(prodData.Product.Id).HTML_Description__c;

            if(prodData.advisoryAddon){
                advisoryAddonTotal += prodData.adjustedPrice;
            }

            if(prodData.Product.Calculator_Location__c == 'Advisory') {
                advisoryProduct = prodData;
                System.debug('advisoryProduct: '+advisoryProduct);
            }
            if (prodData.Product.Calculator_Location__c == 'Business Return') {
                businessTax = Decimal.valueOf(prodData.subtotal);
            }
            if (prodData.Product.Calculator_Location__c == 'Personal Return') {
                personalTax = Decimal.valueOf(prodData.subtotal);
            }
            nameToProduct.put(prodData.name, prodData);

            if((prodData.currentBillingFrequency == 'Monthly' || config.billingFinance == 'mon') && coQuoteMonthId == '') {
                doMonthlyQuote = true;
            }
            if(prodData.currentBillingFrequency == 'One-Time' && prodData.numOfPayments != 12) {
                doOneTimeQuote = true;
                oneTimeSchedules.add(payNumToScheduleString.get(prodData.numOfPayments));
            }
            if(prodData.currentBillingFrequency == 'Annual' && config.billingFinance != 'mon') {
                doAnnualQuote = true;
            }
        }

        System.debug('advisoryAddonTotal: '+advisoryAddonTotal);
        //separate the revenue again
        if(advisoryProduct != null && config.combinedAdvisory == true){
            advisoryProduct.adjustedPrice -= advisoryAddonTotal;
            advisoryProduct.subtotal = advisoryProduct.adjustedPrice * advisoryProduct.currentQuantity;
            if(config.billingFinance == 'mon'){
                advisoryProduct.subtotal = advisoryProduct.subtotal / 10;
            }
        }
        System.debug('separated advisoryProduct: '+advisoryProduct);


        // Extra for: some special calculations on prods

        // Decimal vipAmount = 0.00;

        // for(SelectedProduct prodSelec : prodSelecDataList) {
        //     if(prodSelec.location == 'Advisory') {
        //         prodSelec.price = String.valueOf(((businessTax + personalTax) / (869 + 390)) * 1199);
        //     }

        //     if(advisory == true && persTaxPrep == true) {
        //         if(prodSelec.name == 'Loan Agreement') {
        //             prodSelec.price = '0.00';
        //             prodSelec.freqPrice = '0.00';
        //             prodSelec.subtotal = '0.00';
        //         }
        //     }

        //     vipAmount = vipAmount + Decimal.valueOf(prodSelec.subtotal);
        // }

        // Get data for the quote creation

        Account acc = [
            SELECT Id, Name, Potential_Total_Savings__c, Lead_Type_New__c, Lead_Source__c, Primary_Contact_ID__c, BillingState, BillingCountry, BillingStreet, BillingCity, BillingPostalCode 
            FROM Account 
            WHERE Id = :accountId
            LIMIT 1];
        leadTypeNew = acc.Lead_Type_New__c;
        leadSource = acc.Lead_Source__c;
        contactId = acc.Primary_Contact_ID__c;
        if(leadTypeNew == null){leadTypeNew='';}

        

        // Missing fields from original query: Name, Account__c, Has_Employees_Contractors__c, File_Return_Yourself__c, Has_Rental_Properties__c, Is_Working_From_Home__c, 
        // Commutes_With_Own_Vehicle__c, First_Business__c, 
        Business__c business;
        
        List<Business__c> businesses = [
                SELECT Id, Business_Type__c, Industry__c, Number_of_Employees__c, 
                Number_of_Owners__c, Monthly_Bookkeeping_Transactions__c, Number_of_Rental_Properties__c, W2_Income__c, Profit_Projection__c, 
                Anticipated_Revenue__c, State_of_incorporation__c, Startup_Costs__c, Run_Payroll_Before__c, Tax_Filing_Status__c, 
                Yearly_Business_Miles__c, Home_Office_Square_Feet__c, Years_In_Business__c, Foreign_State_of_Incorporation__c,
                Date_of_incorporation__c 
                FROM Business__c 
                WHERE Account__r.Id = :accountId
                LIMIT 1];
        if(businesses.isEmpty()){
            business = new Business__c();
        } else {
            business = businesses[0];
        }

        String livingAbroad = 'No';
        // if (business.Foreign_Income__c == true) {
        //     livingAbroad = 'Yes';
        // }

        String E_Commerce = 'No';
        // if (business.E_Commerce__c == true) {
        //     E_Commerce = 'Yes';
        // }

        String runPayrollBefore = 'No';
        if (business.Run_Payroll_Before__c == true) {
            runPayrollBefore = 'Yes';
        }
        
        // Set pricebook id, brand and scheduler links for the opportunity

        if (config.billingFinance == 'mon') {
            brand = 'Subscription Management Services';
        }
        
        if (leadTypeNew.contains('Sprout') && entityFormation == true) {
            brand = 'EzBizFile';    
        }
        
        if (leadTypeNew.contains('EIN') && leadSource == 'EIN Tax Filing') {
            brand = 'EIN-Tax-Filing';
        }
        
        if (clientBooks == true) {
            brand = 'ClientBooks';
        }
        
        Chargeover_URL__c uset = Chargeover_URL__c.getOrgDefaults();
        String sURL = uset.Scheduler_URL__c;
        apptType = 'Discovery';
        
        if (nameToProduct.containsKey('Tax Advisory')) {
            apptType = 'Discovery';
        } else {
            apptType = 'ALaCart';
            if (nameToProduct.containsKey('Bookkeeping Advisory')) {
                apptType = 'BKAdvOnboard';
            }
            if (nameToProduct.containsKey('Dedicated Bookkeeping')) {
                apptType = 'BKOnboard';
            } else if (nameToProduct.containsKey('Payroll')) {
                apptType = 'PayOnboard';
            }
            if (nameToProduct.containsKey('Back Bookkeeping')) {
                apptType = 'BKOnboard';
            }
            if (nameToProduct.containsKey('Personal Tax Advisory')) {
                apptType = 'Discovery';
            }
        }
        
        if (brand == 'EzBizFile') {
            apptType = 'EForm';
        }
        
        String schedulerURL = sURL + '?TID=' + apptType + '	&WID=' + contactId + '&EmailCampaignID=' + emailCampId+'&OtherTrackingID=Guided%20Selling';
        String schedulerVIPURL = '';
        String schedulerCSAURL = '';

        String schedulerURLReturn = sURL + ',' + apptType + ',' + contactId + ',' + emailCampId;
        String schedulerVIPURLReturn = ''; 
        String schedulerCSAURLReturn = '';
        
        if (apptType == 'Discovery') {
            schedulerVIPURL = sURL + '?TID=DiscoveryVIP' + '&WID=' + contactId + '&EmailCampaignID=' + emailCampId+'&OtherTrackingID=Guided%20Selling';
            schedulerVIPURLReturn = sURL + ',VIP,' + contactId + ',' + emailCampId;
            schedulerCSAURL = sURL + '?TID=CSAO&WID='+contactID+ '&EmailCampaignID=' + emailCampId+'&OtherTrackingID=Guided%20Selling';
            schedulerCSAURLReturn = sURL + ',CSAO,' + contactId + ',' + emailCampId;
        }
        List<String> productsToSchedule = new List<String>{'Tax Advisory','Personal Tax Preparation','Business Tax Preparation', 'Payroll', 'Dedicated Bookkeeping'};
        if (containsAny(productsToSchedule, new List<String>(nameToProduct.keySet())) || brand == 'EzBizFile') {
            doSomeSchedule = true;
        }
 
        if (doSomeSchedule == false) {
            schedulerURL = '';
            schedulerVIPURL = '';
        }

        Boolean isCSA = ((leadSource == '1-800Accountant' && advisory) || vipAmount >= 7500);
        Boolean isVIP = (!isCSA && vipAmount >= 5000);
        // update opportunity
        System.debug('updating Opportunity');
        update new Opportunity(
            Id = config.opportunityId,
            Pricebook2Id = standardPriceBookID,
            Customized_Bundle__c = false,
            Name_of_Offer_Package__c = packageName,
            Brand__c = brand,
            Email_Campaign_ID__c = emailCampId,
            Sales_Platform__c = 'Guided Selling'
        );

        // Creation of the quote
        Quote theQuote = new Quote(
            Name = acc.Name + ' Quote',
            OpportunityId = config.opportunityId,
            Pricebook2Id = standardPriceBookID,
            Calc_Entity_Type__c = business.Business_Type__c,
            //Calc_Foreign_Owners__c = business.Number_of_Foreign_Owners__c,
            Calc_Industry_Type__c = business.Industry__c,
            Calc_Living_Abroad__c = livingAbroad,
            //Calc_Number_of_Contractors__c = business.Number_of_Contractors__c,
            Calc_Number_of_Employees__c = business.Number_of_Employees__c,
            //Calc_Number_of_K1s__c = business.Number_of_K1_Investments__c,
            Calc_Number_of_Owners__c = business.Number_of_Owners__c,
            Calc_Number_of_Transactions__c = business.Monthly_Bookkeeping_Transactions__c,
            Calc_Number_of_Rental_Properties__c = business.Number_of_Rental_Properties__c,
            Calc_Personal_Income__c = business.W2_Income__c,
            Calc_Projected_1st_Year_Profit__c = business.Profit_Projection__c,
            Calc_Projected_1st_Year_Revenue__c = business.Anticipated_Revenue__c,
            Calc_State_of_Incorporation__c = business.State_of_incorporation__c,
            //Calc_Total_Investor_Funding__c = business.Investor_Funding__c,
            Calc_Total_Startup_Cost__c = business.Startup_Costs__c,
            //Calc_Website_Selling_Goods__c = E_Commerce,
            //Calc_Worked_with_Accountant__c = business.workedWithAccountantInPastInput,
            Calc_Run_Payroll_Before__c = runPayrollBefore,
            Calc_Filing_Status__c = business.Tax_Filing_Status__c,
            Calc_Business_Miles__c = business.Yearly_Business_Miles__c,
            Calc_Office_Square_Footage__c = String.valueOf(business.Home_Office_Square_Feet__c),
            Calc_Foreign_State__c = business.Foreign_State_of_Incorporation__c,
            Calc_Years_in_Business__c = (business.Date_of_incorporation__c == null ? '' : String.valueOf((Date.today().year() - business.Date_of_incorporation__c?.year()))),
            //Calc_State_of_Residence__c = business.State_of_Residence__c,
            billingSchedule__c = config.billingFinance,
            Bundle__c = 'None',
            Calc_Savings_Amount__c = String.valueOf(acc.Potential_Total_Savings__c)
        );
        if(config.bookStartDate != null){
            System.debug('bookkepingStartDate: '+config.bookStartDate);
            //theQuote.Calc_Bookkeeping_Start_Date__c  = Datetime.newInstance(bookkeepingStartDate, Time.newInstance(0,0,0,0)).format('yyyy-MM-dd');//mc
            theQuote.Calc_Bookkeeping_Start_Date__c = config.bookStartDate.toString();
            theQuote.Calc_Bookkeeping_End_Date__c = config.bookEndDate.toString();
        } else {
            System.debug('bookkepingStartDate null');
        }
        System.debug('theQuote '+theQuote);
        List<Quote> quoteList = [SELECT Id FROM Quote WHERE OpportunityId = :config.opportunityId LIMIT 1];
        if(!quoteList.isEmpty()) {
            quoteId = quoteList[0].Id;
            theQuote.Id = quoteId;
            update theQuote;
            // delete quote line items

            List<QuoteLineItem> oldQLI = [SELECT Id FROM QuoteLineItem WHERE QuoteId = :quoteID];
            delete oldQLI;
            
            // delete opportunity line items
            List<OpportunityLineItem> oldOLI = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :config.opportunityId];
            delete oldOLI;
            
            // delete chargeover quotes
            List<ChargeOver_Quote__c> oldCOQ = [SELECT Id FROM ChargeOver_Quote__c WHERE Quote__c = :quoteID];
            for(ChargeOver_Quote__c cOQItem : oldCOQ){
                
                // delete chargeover quote line items
                List<ChargeOver_Quote_Line_Item__c> oldCOQLI = [SELECT Id FROM ChargeOver_Quote_Line_Item__c WHERE ChargeOver_Quote__c = :cOQItem.Id];
                delete oldCOQLI;
                
            }
            
            delete oldCOQ;
            
            //sleep(3000);
            
            // get quote number from quote
            List <Quote> currentQuote = [SELECT Id, QuoteNumber FROM Quote WHERE Id = :quoteID];
            for(Quote cqItem : currentQuote){
                quoteNum = cqItem.QuoteNumber;
            }
        } else {
            
            insert theQuote;
            quoteID = theQuote.Id;

            Quote currentQuote = [SELECT Id, QuoteNumber FROM Quote WHERE Id = :quoteID LIMIT 1];
            quoteNum = currentQuote.QuoteNumber;
        }

        

        // Check for existing event related to opportunity and assign email campaign id if it exists

        if (emailCampId != '' && emailCampId != null) {
            List<Event> eventList = [
                SELECT Id, WhoId, WhatId, Type_of_Appointment__c, ActivityDate 
                FROM Event 
                WHERE WhoId = :contactId 
                AND (Type_of_Appointment__c = 'Tax Savings Analysis' OR Type_of_Appointment__c = 'BNA' OR Type_of_Appointment__c = 'Formation Consultation') 
                AND ActivityDate = LAST_N_DAYS:365
                ORDER BY ActivityDate DESC];
            
            for (Event eve : eventList){
                eve.Email_Campaign_ID__c = emailCampId;
            }
            System.debug('eventList '+eventList);
            update eventList;
        }
        
        // shorten account name if necessary
        String shortAccName = acc.Name;
        Integer maxSize = 70;
        if(shortAccName.length() > maxSize) {
            shortAccName = shortAccName.substring(0, maxSize);
        }
        
        // Initialize data structure for Chargeover quotes and creation if necessary

        ChargeOver_Quote__c theCOQuote;
        ChargeOver_Quote__c theCOQuoteMonth;
        List<ChargeOver_Quote__c> theCOQuotesOneTime = new List<Chargeover_Quote__c>();

        System.debug('creating CO Quotes');
        List<String> dataForQuoteMon = new list<String>{shortAccName, 'mon', accountId, quoteID, quoteNum, '-m', config.opportunityId, brand, contactId, acc.BillingStreet, acc.BillingCity, acc.BillingState, acc.BillingPostalCode, acc.BillingCountry, schedulerURL, packageName, '', schedulerVIPURL};
        theCOQuoteMonth = getChargeOverQuote(dataForQuoteMon);

        for(String schedule : oneTimeSchedules){
            List<String> dataForQuoteOneTime = new list<String>{shortAccName, 'one', accountId, quoteID, quoteNum, '-o', config.opportunityId, brand, contactId, acc.BillingStreet, acc.BillingCity, acc.BillingState, acc.BillingPostalCode, acc.BillingCountry, schedulerURL, packageName, schedule, schedulerVIPURL};
            theCOQuotesOneTime.add(getChargeOverQuote(dataForQuoteOneTime));
        }
        // List<String> dataForQuoteOneTime = new list<String>{shortAccName, 'one', accountId, quoteID, quoteNum, '-o', config.opportunityId, brand, contactId, acc.BillingStreet, acc.BillingCity, acc.BillingState, acc.BillingPostalCode, acc.BillingCountry, schedulerURL, packageName, '', schedulerVIPURL};
        // theCOQuoteOneTime = getChargeOverQuote(dataForQuoteOneTime);

        if (doMonthlyQuote == true) {
            insert theCOQuoteMonth;
            coQuoteMonthId = theCOQuoteMonth.Id;
        } 
        
        if (doOneTimeQuote == true) {
            //insert theCOQuoteOneTime;
            //coQuoteOneTimeId = theCOQuoteOneTime.Id;
            insert theCOQuotesOneTime;
            coQuoteOneTimeIds = new List<Id>(new Map<Id, Chargeover_Quote__c>(theCOQuotesOneTime).keySet());
        }
        theCOQuote = new Chargeover_Quote__c();
        if (doAnnualQuote == true) {
            if (config.billingFinance == '2pay') {
                List<String> dataForQuote = new list<String>{shortAccName, 'yrl', accountId, quoteID, quoteNum, '-y', config.opportunityId, brand, contactId, acc.BillingStreet, acc.BillingCity, acc.BillingState, acc.BillingPostalCode, acc.BillingCountry, schedulerURL, packageName, '4', schedulerVIPURL};
                theCOQuote = getChargeOverQuote(dataForQuote);
            } else if (config.billingFinance == '3pay') {
                List<String> dataForQuote = new list<String>{shortAccName, 'yrl', accountId, quoteID, quoteNum, '-y', config.opportunityId, brand, contactId, acc.BillingStreet, acc.BillingCity, acc.BillingState, acc.BillingPostalCode, acc.BillingCountry, schedulerURL, packageName, '5', schedulerVIPURL};
                theCOQuote = getChargeOverQuote(dataForQuote);
            } else if (config.billingFinance == '4pay') {
                List<String> dataForQuote = new list<String>{shortAccName, 'yrl', accountId, quoteID, quoteNum, '-y', config.opportunityId, brand, contactId, acc.BillingStreet, acc.BillingCity, acc.BillingState, acc.BillingPostalCode, acc.BillingCountry, schedulerURL, packageName, '6', schedulerVIPURL};
                theCOQuote = getChargeOverQuote(dataForQuote);
            } else if (config.billingFinance == '6pay') {
                List<String> dataForQuote = new list<String>{shortAccName, 'yrl', accountId, quoteID, quoteNum, '-y', config.opportunityId, brand, contactId, acc.BillingStreet, acc.BillingCity, acc.BillingState, acc.BillingPostalCode, acc.BillingCountry, schedulerURL, packageName, '7', schedulerVIPURL};
                theCOQuote = getChargeOverQuote(dataForQuote);
            } else {
                List<String> dataForQuote = new list<String>{shortAccName, 'yrl', accountId, quoteID, quoteNum, '-y', config.opportunityId, brand, contactId, acc.BillingStreet, acc.BillingCity, acc.BillingState, acc.BillingPostalCode, acc.BillingCountry, schedulerURL, packageName, '', schedulerVIPURL};
                theCOQuote = getChargeOverQuote(dataForQuote);
            }

            insert theCOQuote;
            coQuoteAnnualId = theCOQuote.Id;
        } 

        createLineItems(config, selectedProds, quoteID, coQuoteMonthId, coQuoteOneTimeIds, coQuoteAnnualId, bundleName);
        
        //sleep(3000);
        
        if (isCSA && schedulerCSAURL != '') {
            theCOQuoteMonth.Scheduler_URL__c = schedulerCSAURL;
            for(Chargeover_Quote__c theCOQuoteOneTime : theCOQuotesOneTime) {theCOQuoteOneTime.Scheduler_URL__c = schedulerCSAURL;}
            theCOQuote.Scheduler_URL__c = schedulerCSAURL;
        } else if(schedulerVIPURL != '' && isVIP) {
            theCOQuoteMonth.Scheduler_URL__c = schedulerVIPURL;
            //theCOQuoteOneTime.Scheduler_URL__c = schedulerVIPURL;
            for(Chargeover_Quote__c theCOQuoteOneTime : theCOQuotesOneTime) {theCOQuoteOneTime.Scheduler_URL__c = schedulerVIPURL;}
            theCOQuote.Scheduler_URL__c = schedulerVIPURL;
        }

        if(coQuoteMonthId != '' && !Test.isRunningTest()) {
            theCOQuoteMonth.Quote_Created__c = true;     
            update theCOQuoteMonth;
        }


        if(!Test.isRunningTest()) {
            for(Chargeover_Quote__c theCOQuoteOneTime : theCOQuotesOneTime){
            theCOQuoteOneTime.Quote_Created__c = true;
            }            
            update theCOQuotesOneTime;       
        }

        if(coQuoteAnnualId != '' && !Test.isRunningTest()) {
            theCOQuote.Quote_Created__c = true;
            update theCOQuote;
        }

        
        if (isCSA && schedulerCSAURL != '') {
            System.debug('schedulerCSAURLReturn: '+schedulerCSAURLReturn);
            return schedulerCSAURLReturn;
        } else if(schedulerVIPURL != '' && isVip) {
            System.debug('schedulerVIPURLReturn: '+schedulerVIPURLReturn);
            return schedulerVIPURLReturn;
        } else {
            System.debug('schedulerURLReturn: '+schedulerURLReturn);
            return schedulerURLReturn;
        }
    }

    //Decimal productPassAdjustment, List<SelectedProduct> prodSelectedList, String calcIdPass, String bundlePass, String productDescription, String opportunityIdPass, String pricebookEntryIdPass, String productIdPass, Integer quantityPass, String timePass, String timeDefPass, String billingTimePass, String quoteIdPass, String coQuoteIdPass, String coQuoteIdMonthPass, String coQuoteIdOneTimePass, String sowDescPass, String sowDescPassHTML, String accountIdPass, Decimal sortOrderPass, Boolean doFeePass, Decimal feeAmountPass, String feeDesc, Boolean oneTimePass, Boolean noSplitPass)
    public static void createLineItems(CalculatorConfiguration config, List<CalculatorProduct> prodSelectedList, String qId, String coMonthQuoteId, List<Id> coOneTimeQuoteIds, String coAnnualQuoteId, String bundleName) {
        System.debug('createLineItems');
        System.debug(prodSelectedList);
        Map<Double, Integer> scheduleNumToPayNum = new Map<Double,Integer>{
            null => 1,
            4 => 2,
            5 => 3,
            6 => 4,
            7 => 6
        };
        Map<Integer, String> payNumToInstallString = new Map<Integer,String>{
            1 => 'One-Time',
            2 => '2-Pay',
            3 => '3-Pay',
            4 => '4-Pay',
            6 => '6-Pay',
            12 => '6-Pay' //this one shouldn't ever be used
        };
        Map<Integer, Chargeover_Quote__c> payNumToOneTimeQuote = new Map<Integer, Chargeover_Quote__c>();
        for(Chargeover_Quote__c coQuote : [SELECT Id, Installment_Payment_Schedule__c FROM Chargeover_Quote__c WHERE Id IN :coOneTimeQuoteIds]){
            payNumToOneTimeQuote.put(scheduleNumToPayNum.get(coQuote.Installment_Payment_Schedule__c), coQuote);
        }
        System.debug(payNumToOneTimeQuote);

        List<String> defaultProductNames = new List<String>();
        if(bundleToDefaultProductNames.containsKey(bundleName)){ defaultProductNames = bundleToDefaultProductNames.get(bundleName); }

        
        
        Set<Id> bookkeepingIds = new Map<Id, Product2>([SELECT Id FROM Product2 WHERE Name LIKE '%Dedicated Bookkeeping%']).keySet();
        Set<Id> backBookkeepingIds = new Map<Id, Product2>([SELECT Id FROM Product2 WHERE Name LIKE '%Back Bookkeeping%']).keySet();

        Datetime holdDate;
        String holdDateString = '';

        Decimal subAmount = 0.00;
        Decimal monthlyPrice = 0.00;
        Decimal tmpACPrice = 0.00;
        Decimal subTotalAmount = 0.00;
        Decimal financeAmount = 0.00;
        String OLIPayInstall = '';
        Double quoteSalesPrice = 0;
        Double quoteSubtotal = 0;
        Double quoteFirstChargeTotal = 0;
        Double quoteFirstChargePrice = 0;

        List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();
        List<QuoteLineItem> qliList = new List<QuoteLineItem>();
        List<ChargeOver_Quote_Line_Item__c> coliList = new List<ChargeOver_Quote_Line_Item__c>();

        for(CalculatorProduct p : prodSelectedList) {
            System.debug(p);
            //System.debug('processing '+p.Product.Name+', '+p.currentBillingFrequency+', '+p.Product.Billing_Frequency__c);
            //System.debug('No Split Allowed: '+p.Product.No_Split_Allowed__c);
            if (Integer.valueOf(p.delayDays) > 0) {
                holdDate = System.today() + Integer.valueOf(p.delayDays);
                holdDateString = String.valueOf(holdDate);
            }
            Boolean customMonthly = p.currentBillingFrequency == 'Monthly' && p.Product.Billing_Frequency__c != 'Monthly';
            Integer qty = p.currentQuantity;
            Integer numPayments = p.numOfPayments;
            Id pbeId = Id.valueOf(p.pbeId);
            Id prodId = Id.valueOf(p.Product.Id);
            //String OLIPayInstall = '';
            String OLIPayCycle = '';
            String COQuoteId;
            quoteSalesPrice = p.subtotal/qty;
            if(customMonthly){
                quoteSalesPrice *= numPayments;
            }                  
            // if(config.billingFinance == 'mon'){
            //     quoteSalesPrice *= 1.2;
            // }              
            quoteSubtotal = quoteSalesPrice*qty;
            quoteFirstChargeTotal = quoteSubtotal / numPayments;
            quoteFirstChargePrice = quoteFirstChargeTotal / qty;

            if (p.currentBillingFrequency == 'One-Time' 
            //&& (p.Product.No_Split_Allowed__c == true || config.billingFinance == 'yrl')){ //if config.billingFinance != 'yrl', product must not be splittable
            && p.numOfPayments != 12){
                //COQuoteId = coOneTimeQuoteId;
                COQuoteId = payNumToOneTimeQuote.get(p.numOfPayments).Id;
                OLIPayCycle = 'one';
                //OLIPayInstall = 'One-Time';
                OLIPayInstall = String.valueOf(payNumToInstallString.get(p.numOfPayments));
            } else if(p.currentBillingFrequency == 'Monthly' || config.billingFinance == 'mon'){
                COQuoteId = coMonthQuoteId;
                OLIPayCycle = 'mon';
                OLIPayInstall = 'Monthly';
            } else if (p.currentBillingFrequency == 'Annual' || (p.currentBillingFrequency == 'One-Time' && p.Product.No_Split_Allowed__c == false)){
                COQuoteId = coAnnualQuoteId;
                OLIPayCycle = 'yrl';
                if (config.billingFinance == '2pay') {
                    OLIPayInstall = '2-Pay';
                } else if (config.billingFinance == '3pay') {
                    OLIPayInstall = '3-Pay';
                } else if (config.billingFinance == '4pay') {
                    OLIPayInstall = '4-Pay';
                } else if (config.billingFinance == '6pay') {
                    OLIPayInstall = '6-Pay';
                } else {
                    if (p.currentBillingFrequency == 'Annual') {
                        OLIPayInstall = 'Yearly';
                    } else if(p.currentBillingFrequency == 'One-Time') {
                        OLIPayInstall = 'One-Time';
                    }
                }
            }
            System.debug('COQuoteId result: '+COQuoteId);

            OpportunityLineItem oli;
            if(config.opportunityId != null && String.valueOf(config.opportunityId) != '') {
                oli = new OpportunityLineItem(
                   Description = p.Product.Name,
                   OpportunityId = Id.valueOf(config.opportunityId),
                   PricebookEntryId = pbeId,
                   Product2Id = prodId,
                   Quantity = qty,
                   UnitPrice = quoteSalesPrice,
                   Payment_Cycle__c = OLIPayCycle,
                   First_Charge_Price__c = quoteFirstChargePrice,
                   First_Charge_Total__c = quoteFirstChargeTotal,
                   Installment_Payment_Schedule__c = OLIPayInstall
               );
               if(oli != null) {
                   //oliList.add(oli);
                   System.debug(oli);
                   insert oli;
               }
           }

            if(qId != null && qId != '') {
                QuoteLineItem qli = new QuoteLineItem(
                    QuoteId = Id.valueOf(qId),
                    OpportunityLineItemId = oli.Id,
                    PricebookEntryId =pbeId,
                    Product2Id = prodId,
                    Quantity = qty,
                    UnitPrice = quoteSalesPrice,
                    First_Charge_Price__c = quoteFirstChargePrice,
                    First_Charge_Total__c = quoteFirstChargeTotal
                );
                if(qli != null) {
                    System.debug(qli);
                    qliList.add(qli);
                }
            }

            if(COQuoteId != null && COQuoteId != '') {
                String descrip = p.Product.Description;
                String HTMLDesc = p.Product.HTML_Description__c;
                System.debug(COQuoteId);
                if(backBookkeepingIds.contains(prodId) || bookkeepingIds.contains(prodId)){
                    descrip += ' For ' + config.monthlyTransactions + ' transactions per month.';
                    HTMLDesc += ' For ' + config.monthlyTransactions + ' transactions per month.';
                }
                if(backBookkeepingIds.contains(prodId)){
                    descrip += ' Back Bookkeeping services will cover the period beginning ' + config.bookStartDate;
                    HTMLDesc += ' Back Bookkeeping services will cover the period beginning ' + config.bookStartDate;
                    if(config.bookEndDate != null){
                        descrip += ' and ending ' + config.bookEndDate.toString();
                        HTMLDesc += ' and ending ' + config.bookEndDate.toString();
                    }
                }
                ChargeOver_Quote_Line_Item__c coli = new ChargeOver_Quote_Line_Item__c(
                    ChargeOver_Quote__c = Id.valueOf(COQuoteId),
                    Product__c = prodId,
                    Price_Per_Unit__c = ((config.billingFinance == 'mon' && p.numOfPayments == 12) ? quoteFirstChargePrice : p.subtotal/qty),
                    Quantity__c = qty,
                    Contract_Amount__c = quoteSubtotal,
                    Product_Description__c =  descrip,
                    HTML_Description__c = HTMLdesc,
                    Account__c = config.accountId,
                    Sales_Source__c = 'Sales',
                    sort_Order__c = p.Product.sort_Order__c,
                    Sold_in_Offer__c = p.isInOffer,
                    Date_Time_Invoice_Being_Held_Until__c = holdDateString
                );
                if(defaultProductNames.contains(p.Product.Name) || p.Product.Name == bundleName){ coli.Bundle_Name__c = bundleName; }
                if(coli != null) {
                    System.debug(coli);
                    coliList.add(coli);
                }
            }



            
        }
        insert qliList;
        insert coliList;
    }

}