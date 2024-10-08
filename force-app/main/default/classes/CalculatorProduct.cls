public without sharing class CalculatorProduct{
    @AuraEnabled public Product2 Product {get;set;}
    @AuraEnabled public Boolean selected {get;set;}
    @AuraEnabled public Boolean enabled {get;set;}
    @AuraEnabled public Boolean quantityEnabled {get;set;}
    @AuraEnabled public Boolean frequencyEnabled {get;set;}
    @AuraEnabled public Double adjustedPrice {get;set;}
    @AuraEnabled public Double baseCalculatorPrice {get;set;}
    @AuraEnabled public Integer currentQuantity {get;set;}
    @AuraEnabled public String currentBillingFrequency {get;set;}
    @AuraEnabled public String description {get;set;}
    @AuraEnabled public Double subtotal {get;set;}
    @AuraEnabled public Integer delayDays {get;set;}
    @AuraEnabled public Boolean isInOffer {get;set;}
    @AuraEnabled public Id pbeId {get;set;}
    @AuraEnabled public Integer numOfPayments {get;set;}
    @AuraEnabled public Id Id {get {return this.Product?.Id;} set;}
    @AuraEnabled public String name {get {return this.Product?.Name;} set;}
    @AuraEnabled public Boolean visible {get;set;}
    @AuraEnabled public Boolean isMetered {get;set;}
    @AuraEnabled public Double meteredMaxQuantity {get;set;}
    @AuraEnabled public Boolean advisoryAddon {get;set;}
    @AuraEnabled public Boolean requiredForBundle {get;set;}
    @AuraEnabled public Boolean freeWithBundle {get;set;}
    @AuraEnabled public Boolean defaultForBundle {get;set;}

    public CalculatorProduct(Product2 prod){
        this.Product = prod;
        this.selected = false;
        this.enabled = true;
        this.currentQuantity = 1;
        this.currentBillingFrequency = prod.Billing_Frequency__c;
        this.delayDays = 0;
        this.isInOffer = false;
        this.adjustedPrice = 0;
        this.baseCalculatorPrice = 0;
        this.subtotal = 0;
        this.numOfPayments = 1;
        this.description = prod.HTML_Description__c;
        this.Product.HTML_Description__c = '';
        this.quantityEnabled = true;
        this.frequencyEnabled = prod.AnnualMonthlyOption__c;
        //this.bundlePricing = prod.Bundles__c != null && prod.Bundles__c.contains('Advisory Bundle');
        this.visible = true;
        this.isMetered = (prod.Metered_Product__c && prod.Billing_Frequency__c == 'One-Time');
        this.meteredMaxQuantity = prod.Maximum_Allowable_Quantity_Per_Period__c;
        this.advisoryAddon = prod.Advisory_Addon__c;
        this.requiredForBundle = false;
        this.freeWithBundle = false;
        this.defaultForBundle = false;
    }
}



