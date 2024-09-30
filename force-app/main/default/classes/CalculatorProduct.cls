public without sharing class CalculatorProduct{
    public Product2 Product {get;set;}
    public Boolean selected {get;set;}
    public Boolean enabled {get;set;}
    public Boolean quantityEnabled {get;set;}
    public Boolean frequencyEnabled {get;set;}
    public Double adjustedPrice {get;set;}
    public Integer currentQuantity {get;set;}
    public String currentBillingFrequency {get;set;}
    public String description {get;set;}
    public Double subtotal {get;set;}
    public Integer delayDays {get;set;}
    public Boolean isInOffer {get;set;}
    public Id pbeId {get;set;}
    public Integer numOfPayments {get;set;}
    public Id Id {get {return this.Product?.Id;} set;}
    public Boolean visible {get;set;}
    public Boolean isMetered {get;set;}
    public Double meteredMaxQuantity {get;set;}
    public Boolean advisoryAddon {get;set;}
    public Boolean requiredForBundle {get;set;}
    public Boolean freeWithBundle {get;set;}
    public Boolean defaultForBundle {get;set;}

    public CalculatorProduct(Product2 prod){
        this.Product = prod;
        this.selected = false;
        this.enabled = true;
        this.currentQuantity = 1;
        this.currentBillingFrequency = prod.Billing_Frequency__c;
        this.delayDays = 0;
        this.isInOffer = false;
        this.adjustedPrice = 0;
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