public without sharing class PricingCalcHelperClass {
    public class MeteredProductWrapper{
        public String id {get;set;}
        public String name {get;set;}
        public Decimal maxPerPeriod {get; set;}
        public String billingTimeDef {get; set;}
        public Decimal adjustedPrice {get; set;}
        public Decimal quantity {get;set;}
        public Boolean selected {get;set;}

        public MeteredProductWrapper(Product2 prod){
            this.id = prod.Id;
            this.name = prod.Name;
            this.maxPerPeriod = prod.Maximum_Allowable_Quantity_Per_Period__c;
            this.billingTimeDef = prod.RevenueInstallmentPeriod;
            this.adjustedPrice = 0.0;
            this.quantity = 0.0;
            this.selected = false;
        }
    }
    //Your wrapper 
    public class AcItemWrapper{ 
        public String id {get;set;}
        public String name {get;set;}
        public Decimal price {get; set;} 
        public Decimal altPrice {get; set;} 
        public String pbeid {get; set;}
        public Boolean doIt {get; set;}
        public Integer quantity {get; set;}
        public Boolean disableQTY {get; set;}
        public String billingTime {get; set;}
        public String billingTimeDef {get; set;}
        public String billingFreq {get; set;}
        public Boolean annualMonthlyOption {get; set;}
        public String htmlDescription {get; set;}
        public String productDescription {get; set;}
        public Boolean disableProduct {get; set;}
        public String disableMessage {get; set;}
        public Decimal quoteSort {get; set;}
        public String setupFee {get; set;}
        public Boolean masterOffer {get;set;}
        public Boolean noSplit {get;set;}
        // add billing schedule property
        
    }
    
    // dynamic wrapper class
    public class dynamicRuleClass{
    
        public String productId {get;set;}
        public String fieldName {get;set;}
        public String fieldValue {get;set;}
        public String fieldOperator {get;set;}
        public String fieldName2 {get;set;}
        public String fieldValue2 {get;set;}
        public String fieldOperator2 {get;set;}
        public String action {get;set;}
        public String productLabel {get;set;}
    
    }
    
    public class bundleWrapperClass{
        
        public String id {get;set;}
        public String calcid {get;set;}
        public String bundlelist {get;set;}
        
    }
    
    public class offerMasterWrapperClass{
    
        public String id {get;set;}
        public String name {get;set;}
        public Boolean doIt {get;set;}
        public Integer sortOrder {get;set;}
        public Boolean defaultSel {get;set;}
    
    }
    
    public class offerProductWrapperClass{
        
        public String id {get;set;}
        public String offerId {get;set;}
        public String productName {get;set;}
        public String productId {get;set;}
        public Decimal amount {get;set;}
        public Decimal delayDays {get;set;}
        public Boolean master {get;set;}
        public Boolean upsell {get;set;}
        public String calcId {get;set;}
        public Boolean usePricebook {get;set;}
        
    }
    
    public class priceWrapper{
    
        public String field {get;set;}
        public String value {get;set;}
        public String product {get;set;}
        public Decimal amount {get;set;}
        public Boolean setupFee {get; set;} 
        // add billing schedule property
     
    }
    
    public class priceOverrideWrapper{
        
        public String productId {get;set;}
        public Decimal amount {get;set;}
        public String productPostion {get;set;}
        
    }
    
    public class priceAdjustmentWrapper{
        
        public String productId {get;set;}
        public Decimal amount {get;set;}
        public Decimal percent {get;set;}
        public String productPostion {get;set;}
        
    }
    
    public class productWrapper{
        
        public String Id {get;set;}
        public String Name {get;set;}
        public String Bundles {get;set;}
        public Boolean Disable_QTY_on_Calc {get;set;}
        public String RevenueInstallmentPeriod {get;set;}
        public String Billing_Frequency {get;set;}
        public String AnnualMonthlyOption {get;set;}
        public String Description {get;set;}
        public String HTML_Description {get;set;}
        public String Sort_Order {get;set;}
        public String Setup_Fee {get;set;}
        public String Calculator_Location {get;set;}
        public String EnvironmentList {get;set;}
        public Boolean MasterOffer {get;set;}
        
    }
    
    public class discountWrapper{
        
        public String DiscountType {get;set;}
        public Boolean DisplayDiscount {get;set;}
        public Decimal Amount {get;set;}
        
    }

    public class MisconfiguredMetadataException extends Exception {} 

    public static List<String> disqualifiers = new List<String>{'C Corporation', 'Non-Profit', 'Cryptocurrency', 'Investments', 'Not For Profit', 'Real Estate'};

    public static Boolean displaySavings(String entityType, String industryType){
        Boolean display = true;
        if(disqualifiers.contains(entityType)
        || disqualifiers.contains(industryType)){
            display = false;
        }
        return display;
    } 
    public static Boolean displayBusinessMileageSavings(String entityType, String industryType){
        Boolean display = true;
        List<String> businessMileageDisqualifiers = new List<String>();
        businessMileageDisqualifiers.addAll(disqualifiers);
        businessMileageDisqualifiers.add('Transportation');
        if(businessMileageDisqualifiers.contains(entityType)
        || businessMileageDisqualifiers.contains(industryType)){
            display = false;
        }
        return display;
    } 
    public static Boolean displaySCorporationSavings(Integer formProjectedFirstYearProfit, String formEntityType, String formIndustryType){
        Boolean display = true;
        if(0 == formProjectedFirstYearProfit){
            display = false;
        }
        List<String> SDisqualifiers = new List<String>();
        SDisqualifiers.addAll(disqualifiers);
        SDisqualifiers.add('S Corporation');
        if(SDisqualifiers.contains(formEntityType)
        || SDisqualifiers.contains(formIndustryType)){
            display = false;
        } 
        return display;
    } 

    public static Decimal calculateSCorporationSavings(Integer formProjectedFirstYearProfit){
        Decimal calculatedSCorporationSavings;
        switch on formProjectedFirstYearProfit{
            when 0 { 
                calculatedSCorporationSavings = 0.00;
            }
            when 5000 {
                calculatedSCorporationSavings = 459.00;
            }
            when 10000 {
                calculatedSCorporationSavings = 918.00;
            }
            when 25000 {
                calculatedSCorporationSavings = 2295.00;
            }
            when 50000 {
                calculatedSCorporationSavings = 4590.00;
            }
            when 75000 {
                calculatedSCorporationSavings = 6885.00;
            }
            when 100000 {
                calculatedSCorporationSavings = 9180.00;
            }
            when 150000 {
                calculatedSCorporationSavings = 12877.20;
            }
            when 250000 {
                calculatedSCorporationSavings = 17307.20;
            }
            when 500000 {
                calculatedSCorporationSavings = 24577.20;
            }
            when 1000000 {
                calculatedSCorporationSavings = 31407.20;
            }
        }
        return calculatedSCorporationSavings;
    } 
    public static Decimal calculateSavings(String savingsType, String filingStatus, Decimal totalPersonalIncome, Decimal totalBusinessIncome, Decimal homeOfficeSqFt, Decimal businessMileage, Decimal totalStartupCosts){
        Decimal calculatedSavings = 0;
        Decimal businessIncome = ('Startup Cost' == savingsType) ? (totalBusinessIncome - (totalStartupCosts / 15)) : totalBusinessIncome;
        Decimal totalIncome = totalPersonalIncome + businessIncome;
        Decimal selfEmploymentTax = (businessIncome * .9235 * .153);
        Decimal deductibleOfSelfEmploymentTax = selfEmploymentTax / 2;
        Decimal agi = totalIncome - deductibleOfSelfEmploymentTax;
        Decimal standardDeduction = getDeduction(filingStatus, 'Standard Deduction');
        Decimal businessIncomeDeduction = getDeduction(filingStatus, 'Business Income Deduction');
        Decimal totalQBIDeduction = ('QBI' == savingsType) ? 0 : ((totalIncome > businessIncomeDeduction) ? 0 : (businessIncome * .2));
        //Putting this in a try catch so null errrors can be handled on the front end
        try{
            Decimal federalTaxableIncome = ((agi - standardDeduction - totalQBIDeduction) <= 0) ? 0 : (agi - standardDeduction - totalQBIDeduction);
            Decimal federalIncomeTax = calculateFederalIncomeTax(filingStatus, federalTaxableIncome);
            Decimal totalFederalTax = selfEmploymentTax + federalIncomeTax;
            //After
            Decimal adjustedBusinessIncome;
            if('Home Office' == savingsType){
                adjustedBusinessIncome = (totalBusinessIncome - (homeOfficeSqFt * 5) < 0) ? 0 : (totalBusinessIncome - (homeOfficeSqFt * 5));
            }
            if('Business Mileage' == savingsType){
                adjustedBusinessIncome = (totalBusinessIncome - (businessMileage * .56));
            }
            if(('Startup Cost' == savingsType)){
                adjustedBusinessIncome = totalBusinessIncome - ((totalStartupCosts > 50001) ? (totalStartupCosts / 15) : 5000 + ((totalStartupCosts - 5000) / 15));
            }
            if('QBI' == savingsType){
                adjustedBusinessIncome = totalBusinessIncome;
            }
            Decimal adjustedTotalIncome = totalPersonalIncome + adjustedBusinessIncome;
            Decimal adjustedSelfEmploymentTax = (adjustedBusinessIncome * .9235 * .153);
            Decimal adjustedDeductibleOfSelfEmploymentTax = adjustedSelfEmploymentTax / 2;
            Decimal adjustedAgi = adjustedTotalIncome - adjustedDeductibleOfSelfEmploymentTax;
            Decimal adjustedTotalQBIDeduction =  (adjustedTotalIncome > businessIncomeDeduction) ? 0 : (adjustedBusinessIncome * .2);
            Decimal adjustedFederalTaxableIncome = ((adjustedAgi - standardDeduction - adjustedTotalQBIDeduction) <= 0) ? 0 : (adjustedAgi - standardDeduction - adjustedTotalQBIDeduction);
            Decimal adjustedFederalIncomeTax = calculateFederalIncomeTax(filingStatus, adjustedFederalTaxableIncome);
            Decimal adjustedTotalFederalTax= adjustedSelfEmploymentTax + adjustedFederalIncomeTax;
    
            calculatedSavings = totalFederalTax - adjustedTotalFederalTax;
        } catch (Exception e){}
        
        return calculatedSavings.setScale(2);
        
    } 
    public static Decimal getDeduction(String filingStatus, String deductionType){
        List<Tax_Deduction__mdt> getDeduction = [
            SELECT MasterLabel, Married_Filing_Jointly__c, Single__c, Head_of_Household__c, Married_Filing_Separate__c
            FROM Tax_Deduction__mdt
            WHERE MasterLabel = :deductionType
        ]; 
        if(null == getDeduction || getDeduction.size() > 1){
            throw new MisconfiguredMetadataException('Please check that Custom Metadata Type Found within the Parameters: { Filing Status: '+filingStatus+', Tax Deduction Type: '+deductionType+'} is configured correctly.');
        } 
        Tax_Deduction__mdt taxDeduction = getDeduction[0];
        Decimal deduction;
        switch on filingStatus {
            when 'Single' {
                deduction = taxDeduction.Single__c;
            }
            when 'Head of Household' {
                deduction = taxDeduction.Head_of_Household__c;
            }
            when 'Married Filing Jointly' {
                deduction = taxDeduction.Married_Filing_Jointly__c;
            }
            when 'Married Filing Separate' {
                deduction = taxDeduction.Married_Filing_Separate__c;
            }
        }
        return deduction;
    } 
    public static Decimal calculateFederalIncomeTax(String filingStatus, Decimal federalTaxableIncome){
        List<Tax_Bracket__mdt> getTaxBracket = [
            SELECT MasterLabel, Filing_Status__c, Tax_Bracket_Percentage__c, Minimum_Taxable_Income__c, Maximum_Taxable_Income__c
            FROM Tax_Bracket__mdt 
            WHERE Filing_Status__c = :filingStatus
            AND Minimum_Taxable_Income__c <= :federalTaxableIncome 
            AND Maximum_Taxable_Income__c >  :federalTaxableIncome
        ];
        if(getTaxBracket.size() == 0 || getTaxBracket.size() > 1){
            throw new MisconfiguredMetadataException('Please check that the Custom Metadata Type Found within the Parameters: { Filing Status: '+filingStatus+', Federal Taxable Income: '+math.round(federalTaxableIncome)+'} is configured correctly.');
        } 
        Tax_Bracket__mdt taxBracket = getTaxBracket[0];
        Decimal floor = calculateFloor(taxBracket, filingStatus);
        Decimal calculatedFederalIncomeTax = floor + (federalTaxableIncome - taxBracket.Minimum_Taxable_Income__c) * (taxBracket.Tax_Bracket_Percentage__c * .01);
        
        return calculatedFederalIncomeTax;
    } 
    public static Decimal calculateFloor(Tax_Bracket__mdt taxBracket, String filingStatus){
        List<Tax_Bracket__mdt> getLowerTaxBrackets = [
            SELECT MasterLabel, Filing_Status__c, Tax_Bracket_Percentage__c, Minimum_Taxable_Income__c, Maximum_Taxable_Income__c
            FROM Tax_Bracket__mdt 
            WHERE Filing_Status__c = :filingStatus
            AND Maximum_Taxable_Income__c < :taxBracket.Minimum_Taxable_Income__c
            ORDER BY Minimum_Taxable_Income__c ASC
        ];
        getLowerTaxBrackets.add(taxBracket); 
        if((null == getLowerTaxBrackets && taxBracket.Minimum_Taxable_Income__c > 0)){
            throw new MisconfiguredMetadataException('Missing Custom Metadata Types Found within the Parameters: { Filing Status: '+filingStatus+', Income Limits Less Than: '+taxBracket.Minimum_Taxable_Income__c+'}');
        } 
        Map<Decimal, Tax_Bracket__mdt> mappedMaxToBracket = new Map<Decimal, Tax_Bracket__mdt>();
        for(Tax_Bracket__mdt tb : getLowerTaxBrackets){
            mappedMaxToBracket.put(tb.Maximum_Taxable_Income__c, tb);
        }
 
        Decimal floor;
        Boolean firstIteration = true;
        Map<Tax_Bracket__mdt, Decimal> mappedBracketToFloor = new Map<Tax_Bracket__mdt, Decimal>();
        for(Tax_Bracket__mdt tb : getLowerTaxBrackets){
            if(firstIteration){
                firstIteration = false;
                mappedBracketToFloor.put(tb, 0);
            } else {
                Tax_Bracket__mdt lowerTaxBracket = mappedMaxToBracket.get((tb.Minimum_Taxable_Income__c - 1));
                if(null == lowerTaxBracket){
                    throw new MisconfiguredMetadataException('Missing Custom Metadata Type Found within the Parameters: { Filing Status: '+filingStatus+', Income Limit Maximum of '+(tb.Minimum_Taxable_Income__c - 1)+'}');
                }
                floor = math.ceil((lowerTaxBracket.Maximum_Taxable_Income__c - lowerTaxBracket.Minimum_Taxable_Income__c) * (lowerTaxBracket.Tax_Bracket_Percentage__c * .01) + (mappedBracketToFloor.get(lowerTaxBracket)));
                mappedBracketToFloor.put(tb, floor);
            }
        } 
        return mappedBracketToFloor.get(taxBracket); 
    }

    public static Decimal getVIPAmount(Decimal productPassAdjustment, List<PricingCalcHelperClass.offerProductWrapperClass> offerProductListPass, String calcIdPass, String bundlePass, String productDescription, String opportunityIdPass, String pricebookEntryIdPass, String productIdPass, Integer quantityPass, String timePass, String timeDefPass, String billingTimePass, String quoteIdPass, String coQuoteIdPass, String coQuoteIdMonthPass, String coQuoteIdOneTimePass, String sowDescPass, String sowDescPassHTML, String accountIdPass, Decimal sortPass, Boolean doFeePass, Decimal feeAmountPass, String feeDesc, Boolean oneTimePass, Boolean noSplitPass, String numberOfTransactionsInputPass, String numberOfEmployeesInputPass)
    {
        
        // default variables declared here
        Decimal subTotalAmount = 0.00;
        Decimal tmpACPrice = 0.00;
 
        // check for bundle price
        for(PricingCalcHelperClass.offerProductWrapperClass opwItem : offerProductListPass){
            
            if (opwItem.calcId == calcIdPass && bundlePass == opwItem.offerId && opwItem.usePricebook == false) {
                
                productPassAdjustment = opwItem.amount;
                
            } 
            
        }
        
        productPassAdjustment = productPassAdjustment.setScale(0, RoundingMode.CEILING);
        // now we do something different depending on the timeframe for billing selected
        if (timePass == 'Monthly') {
            
            subTotalAmount = productPassAdjustment.setScale(2) * quantityPass;
        
        } else {
        
            if (noSplitPass == true) {
                billingTimePass = 'yrl';
            }
            
            if (billingTimePass == 'mon') { 
                if (timeDefPass == 'Monthly') {
                
                    subTotalAmount = productPassAdjustment.setScale(2) * quantityPass;
                    
                } else {
                
                    subTotalAmount = (productPassAdjustment * 1.2).setScale(2) * quantityPass;
    
                } 
            } else {
                
                if (timeDefPass == 'Monthly') {
                    
                    tmpACPrice = productPassAdjustment * 11;
                    
                } else {
                
                    tmpACPrice = productPassAdjustment;
                
                } 
                tmpACPrice = tmpACPrice.setScale(2);
                
                subTotalAmount = tmpACPrice * quantityPass; 
            }
            
        }
        
        // return vip amount
        //subTotalAmount = subTotalAmount.setScale(2);
        return subTotalAmount; 
    }
    
    public static Decimal getDynamicAmount(String productNamePass, String entityTypeInputPass, String industryTypeInputPass, String numberOfEmployeesInputPass, String numberOfOwnersInputPass, String numberOfRentalPropertiesInputPass, String personalIncomeInputPass, String projectedFirstYearProfitInputPass, String projectedFirstYearRevenueInputPass, String stateOfIncorporationInputPass, String totalStartupCostInputPass, String numberOfTransactionsInputPass, String filingStatusInputPass, String businessMilesInputPass, String officeSqFtInputPass, String foreignStateInputPass) 
    {
        Decimal adjustAmount = 0.00;
        String tempValue = '';
        
        // start with business return calculation
        List<Calculator_Dropdown__c> dropListB = [SELECT Id, Dropdown_Value__c, Form_Field__c, Price_Adjustment__c, Product__c FROM Calculator_Dropdown__c WHERE Product__c = :productNamePass];
        
        for(Calculator_Dropdown__c dropItem : dropListB){
            
            tempValue = '';
            
            if (dropItem.Form_Field__c == 'Entity Type') {
                tempValue = entityTypeInputPass;
            }
            
            if (dropItem.Form_Field__c == 'Industry Type') {
                tempValue = industryTypeInputPass;
            }
            
            if (dropItem.Form_Field__c == 'Number of Employees') {
                tempValue = numberOfEmployeesInputPass;
            }
            
            if (dropItem.Form_Field__c == 'Number of Owners') {
                tempValue = numberOfOwnersInputPass;
            }
            
            if (dropItem.Form_Field__c == 'Number of Rental Properties') {
                tempValue = numberOfRentalPropertiesInputPass;
            }
            
            if (dropItem.Form_Field__c == 'Personal Income') {
                tempValue = personalIncomeInputPass;
            }
            
            if (dropItem.Form_Field__c == 'Projected 1st Year Profit') {
                tempValue = projectedFirstYearProfitInputPass;
            }
            
            if (dropItem.Form_Field__c == 'Projected 1st Year Revenue') {
                tempValue = projectedFirstYearRevenueInputPass;
            }
            
             if (dropItem.Form_Field__c == 'State of Incorporation') {
                tempValue = stateOfIncorporationInputPass;
            }
            
            if (dropItem.Form_Field__c == 'Total Startup Cost') {
                tempValue = totalStartupCostInputPass;
            }
            
            if (dropItem.Form_Field__c == 'Number of Transactions') {
                tempValue = numberOfTransactionsInputPass;
            }
            
            if (dropItem.Form_Field__c == 'Filing Status') {
                tempValue = filingStatusInputPass;
            }
            
            if (dropItem.Form_Field__c == 'Business Miles') {
                tempValue = businessMilesInputPass;
            }
            
            if (dropItem.Form_Field__c == 'Office Square Footage') {
                tempValue = officeSqFtInputPass;
            }
            
            if (dropItem.Form_Field__c == 'Foreign State') {
                tempValue = foreignStateInputPass;
            } 
            if (tempValue == dropItem.Dropdown_Value__c) {
                adjustAmount = adjustAmount + dropItem.Price_Adjustment__c;
            }
        
        }
        
        return adjustAmount;
        
    }
}