public without sharing class QuoteGeneratorInterface {
    public QuoteGeneratorInterface() {

    }

    public enum RequestType {GET_BUNDLE, GET_PRODUCTS, CHECK_BUNDLE, UPDATE_PRODUCTS}


    @InvocableMethod(label='Invocable QuoteGenerator Test' description='Invocable method to test QuoteGenerator methods.')
    public static List<BundleResponse> testQuoteGenerator(List<BundleRequest> bundleRequests){
        List<BundleResponse> results = new List<BundleResponse>();
        for(BundleRequest req : bundleRequests){            
            BundleResponse response = new BundleResponse();
            RequestType reqType;
            try{
                reqType = RequestType.valueOf(req.requestType);
            } catch (Exception ex){
                throw new RequestTypeException(reqType + ' is not a valid request type.');
            }

            switch on reqType {
                when GET_BUNDLE {
                    Quote_Bundle__mdt bundle = QuoteGenerator.getQuoteBundle(req.accountId, req.entityOverride, req.calculator);
                    if(req.serializeResults == true){ response.serializedResults = JSON.serialize(bundle); }
                    else { response.bundleResult = bundle; }
                }
                when GET_PRODUCTS {
                    List<CalculatorProduct> products = QuoteGenerator.getProductData(req.accountId, req.entityOverride, req.calculator, null);
                    if(req.serializeResults == true){ 
                        response.serializedResults = JSON.serialize(products); 
                        response.serializedResults2 = JSON.serialize(QuoteGenerator.getSelectedProducts(products));
                    }
                    else { response.productResults = products; }
                }
                when CHECK_BUNDLE {
                    Boolean bundleIsActive = QuoteGenerator.useBundlePricing(req.accountId, req.entityOverride, req.calculator, (List<CalculatorProduct>)JSON.deserialize(req.serializedInput, List<CalculatorProduct>.class));
                    if(req.serializeResults == true){
                        response.serializedResults = bundleIsActive.toString();
                    }
                    else {response.serializedResults = bundleIsActive.toString();}
                }
                when UPDATE_PRODUCTS {
                    List<CalculatorProduct> products = (List<CalculatorProduct>)JSON.deserialize(req.serializedInput, List<CalculatorProduct>.class);
                    List<CalculatorProduct> selectedProducts;
                    if(req.serializedInput2 != null){
                        selectedProducts = (List<CalculatorProduct>)JSON.deserialize(req.serializedInput2, List<CalculatorProduct>.class);
                    }
                    products = QuoteGenerator.updatePrices(req.accountId, req.entityOverride, req.calculator, products, selectedProducts);
                    selectedProducts = QuoteGenerator.getSelectedProducts(products);
                    Double subtotal = 0;
                    for(CalculatorProduct prod : selectedProducts){ subtotal += prod.subtotal; }
                    if(req.serializeResults == true){ 
                        response.serializedResults = JSON.serialize(products); 
                        response.serializedResults2 = JSON.serialize(selectedProducts);
                    } else {
                        response.productResults = products;
                    }
                    response.subtotal = subtotal;
                }
            }
            results.add(response);
        }
        return results;
    }
    
    //@InvocableMethod(label='Get Eligible Bundle' description='Returns the bundle for which an account would be eligible.')
    public static List<Quote_Bundle__mdt> testBundleSelection(List<BundleRequest> bundleRequests){
        List<Quote_Bundle__mdt> results = new List<Quote_Bundle__mdt>();
        for(BundleRequest req : bundleRequests){
            results.add(QuoteGenerator.getQuoteBundle(req.accountId, req.entityOverride, req.calculator));
        }
        return results;
    }

    //@InvocableMethod(label='Get Bundle Products' description='Returns the list of products available for a given account.')
    public static List<List<CalculatorProduct>> testBundleProducts(List<BundleRequest> bundleRequests){
        List<List<CalculatorProduct>> results = new List<List<CalculatorProduct>>();
        for(BundleRequest req : bundleRequests){
            results.add(QuoteGenerator.getProductData(req.accountId, req.entityOverride, req.calculator, null));
        }
        return results;
    }



    public class BundleRequest {
        @AuraEnabled @InvocableVariable(label='Id for test account' description='Account Id' required=false)
        public Id accountId;
        @AuraEnabled @InvocableVariable(label='Id for test opportunity' description='Opportunity Id' required=false)
        public Id opportunityId;
        @AuraEnabled @InvocableVariable(label='Entity value to override account field' description='Entity Override' required=false)
        public String entityOverride;
        @AuraEnabled @InvocableVariable(label='Calculator to check against' description='Calculator' required=false)
        public String calculator;        
        @AuraEnabled @InvocableVariable(label='Type of the request' description='Request Type' required=true)
        public String requestType;
        @AuraEnabled @InvocableVariable(label='Convert method results to JSON' description='Serialize Results' required=false)
        public Boolean serializeResults;
        @AuraEnabled @InvocableVariable(label='JSON input for calculator products' description='Serialized input' required=false)
        public String serializedInput;
        @AuraEnabled @InvocableVariable(label='JSON input for selected products' description='Serialized input 2' required=false)
        public String serializedInput2;

        public BundleRequest(){}

        public BundleRequest(Id accountId, String entityOverride, String calculator){
            this.accountId = accountId;
            this.entityOverride = entityOverride;
            this.calculator = calculator;
        }

        public BundleRequest(Id accountId, String entityOverride, String calculator, String requestType, Boolean serializeResults, String serializedInput){
            this.accountId = accountId;
            this.entityOverride = entityOverride;
            this.calculator = calculator;
            this.requestType = requestType;
            this.serializeResults = serializeResults;
            this.serializedInput = serializedInput;
        }
    }

    public class BundleResponse {
        @AuraEnabled @InvocableVariable(label='Quote Bundle response data' description='Quote Bundle' required=false)
        public Quote_Bundle__mdt bundleResult;
        @AuraEnabled @InvocableVariable(label='Quote Bundle Product response data' description='Quote Bundle Products' required=false)
        public List<CalculatorProduct> productResults;
        @AuraEnabled @InvocableVariable(label='Subtotal for selected products' description='Quote Subtotal' required=false)
        public Double subtotal;
        @AuraEnabled @InvocableVariable(label='Serialized response data' description='Serialized Results' required=false)
        public String serializedResults;
        @AuraEnabled @InvocableVariable(label='Serialized secondary response data' description='Serialized Results 2' required=false)
        public String serializedResults2;
    }

    public class RequestTypeException extends Exception{}
}