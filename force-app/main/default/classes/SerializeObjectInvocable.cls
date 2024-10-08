public with sharing class SerializeObjectInvocable {
    public SerializeObjectInvocable() {

    }

    //@InvocableMethod(label='Get Eligible Bundle' description='Returns the bundle for which an account would be eligible.')
    public static List<String> serializeObject(List<Object> objects){
        List<String> results = new List<String>();
        for(Object ob : objects){
            results.add(JSON.serialize(ob));
        }
        return results;
    }

    @InvocableMethod(label='Deserialize Products' description='Returns deserialized calculator products')
    public static List<ProductList> deserializeObject(List<String> objects){
        List<ProductList> results = new List<ProductList>();
        for(String ob : objects){
            results.add(
                new ProductList(
                    (List<CalculatorProduct>)JSON.deserialize(ob, List<CalculatorProduct>.class)
                )
            );
        }
        return results;
    }

    public class ProductList {
        @AuraEnabled @InvocableVariable(label='Id for test account' description='Account Id' required=true)
        public List<CalculatorProduct> products;

        public ProductList(List<CalculatorProduct> products){
            this.products = products;
        }
    }
}