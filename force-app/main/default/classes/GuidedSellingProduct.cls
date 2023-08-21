public without sharing class GuidedSellingProduct{
    public Product2 Product {get;set;}
    public Boolean selected {get;set;}
    public Boolean enabled {get;set;}
    public Double adjustedPrice {get;set;}
    public Integer currentQuantity {get;set;}

    public GuidedSellingProduct(Product2 prod){
        this.Product = prod;
        this.selected = false;
        this.enabled = true;
        this.currentQuantity = 1;
    }
}