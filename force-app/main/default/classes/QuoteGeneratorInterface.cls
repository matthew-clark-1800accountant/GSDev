@RestResource(urlMapping='/QuoteGenerator/*')
global without sharing class QuoteGeneratorInterface {
    global QuoteGeneratorInterface() {

    }

    global enum RequestType {GET_BUNDLE, GET_PRODUCTS, CHECK_BUNDLE, UPDATE_PRODUCTS, CREATE_QUOTES}


    @InvocableMethod(label='Invocable QuoteGenerator Test' description='Invocable method to test QuoteGenerator methods.')
    global static List<BundleResponse> runQuoteGenerator(List<BundleRequest> bundleRequests){
        List<BundleResponse> results = new List<BundleResponse>();
        for(BundleRequest req : bundleRequests){            
            BundleResponse response = new BundleResponse();
            RequestType reqType;
            try{
                reqType = RequestType.valueOf(req.requestType);
            } catch (Exception ex){
                throw new RequestTypeException(reqType + ' is not a valid request type.');
            }
            if(req.config != null && req.config.accountId == null){
                List<Opportunity> opps = [SELECT AccountId FROM Opportunity WHERE Id = :req.config.opportunityId LIMIT 1];
                if(opps.isEmpty()){
                    throw new InvalidIdException('Invalid Opportunity Id: '+req.config.opportunityId);
                }
                req.config.accountId = opps[0].AccountId;
            }

            switch on reqType {
                when GET_BUNDLE {
                    Quote_Bundle__mdt bundle = QuoteGenerator.getQuoteBundle(req.config);
                    if(req.serializeResults == true){ response.serializedResults = JSON.serialize(bundle); }
                    else { response.bundleResult = bundle; }
                }
                when GET_PRODUCTS {
                    List<CalculatorProduct> products = QuoteGenerator.getProductData(req.config, null);
                    if(req.serializeResults == true){ 
                        response.serializedResults = JSON.serialize(products); 
                        response.serializedResults2 = JSON.serialize(QuoteGenerator.getSelectedProducts(products));
                    }
                    else { response.productResults = products; }
                }
                when CHECK_BUNDLE {
                    Boolean bundleIsActive = QuoteGenerator.useBundlePricing(req.config, (List<CalculatorProduct>)JSON.deserialize(req.serializedInput, List<CalculatorProduct>.class));
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
                    products = QuoteGenerator.updatePrices(req.config, products, selectedProducts);
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
                when CREATE_QUOTES {
                    List<CalculatorProduct> products = (List<CalculatorProduct>)JSON.deserialize(req.serializedInput, List<CalculatorProduct>.class);
                    List<CalculatorProduct> selectedProducts;
                    if(req.serializedInput2 != null){
                        selectedProducts = (List<CalculatorProduct>)JSON.deserialize(req.serializedInput2, List<CalculatorProduct>.class);
                    } else {
                        selectedProducts = QuoteGenerator.getSelectedProducts(products);
                    }
                    if(req.serializeResults == true){ 
                        response.serializedResults = QuoteGenerator.doSubmit(req.config, selectedProducts, null); 
                    }
                    else { response.serializedResults = QuoteGenerator.doSubmit(req.config, selectedProducts, null); }
                }
            }
            results.add(response);
        }
        return results;
    }
    
    // //@InvocableMethod(label='Get Eligible Bundle' description='Returns the bundle for which an account would be eligible.')
    // public static List<Quote_Bundle__mdt> testBundleSelection(List<BundleRequest> bundleRequests){
    //     List<Quote_Bundle__mdt> results = new List<Quote_Bundle__mdt>();
    //     for(BundleRequest req : bundleRequests){
    //         results.add(QuoteGenerator.getQuoteBundle(req.accountId, req.entityOverride, req.calculator));
    //     }
    //     return results;
    // }

    // //@InvocableMethod(label='Get Bundle Products' description='Returns the list of products available for a given account.')
    // public static List<List<CalculatorProduct>> testBundleProducts(List<BundleRequest> bundleRequests){
    //     List<List<CalculatorProduct>> results = new List<List<CalculatorProduct>>();
    //     for(BundleRequest req : bundleRequests){
    //         results.add(QuoteGenerator.getProductData(req.accountId, req.entityOverride, req.calculator, null));
    //     }
    //     return results;
    // }

    @HttpPost
    global static BundleResponse generatorEndpoint(BundleRequest req){
        List<BundleResponse> responses = runQuoteGenerator(new List<BundleRequest>{req});
        if(responses.isEmpty()){ return null; }
        return responses[0];
    }

    @HttpPut
    global static Id createBusinessRecords(Lead inputLead){
        return QuoteGeneratorHelper.convertLead(inputLead);
    }

    global class BundleRequest {
        @AuraEnabled @InvocableVariable(label='Calculator Configuration data' description='Calculator Configuration' required=true)
        global CalculatorConfiguration config;
        @AuraEnabled @InvocableVariable(label='Type of the request' description='Request Type' required=true)
        global String requestType;
        @AuraEnabled @InvocableVariable(label='Convert method results to JSON' description='Serialize Results' required=false)
        global Boolean serializeResults;
        @AuraEnabled @InvocableVariable(label='JSON input for calculator products' description='Serialized input' required=false)
        global String serializedInput;
        @AuraEnabled @InvocableVariable(label='JSON input for selected products' description='Serialized input 2' required=false)
        global String serializedInput2;

        global BundleRequest(){}

        global BundleRequest(Id accountId, String entityOverride, String calculator){
            CalculatorConfiguration config = new CalculatorConfiguration();
            config.accountId = accountId;
            config.entityOverride = entityOverride;
            config.calculator = calculator;
            this.config = config;
        }

        global BundleRequest(Id accountId, String entityOverride, String calculator, String requestType, Boolean serializeResults, String serializedInput){
            CalculatorConfiguration config = new CalculatorConfiguration();
            config.accountId = accountId;
            config.entityOverride = entityOverride;
            config.calculator = calculator;
            this.config = config;
            
            this.requestType = requestType;
            this.serializeResults = serializeResults;
            this.serializedInput = serializedInput;
        }
    }

    global class BundleResponse {
        @AuraEnabled @InvocableVariable(label='Quote Bundle response data' description='Quote Bundle' required=false)
        global Quote_Bundle__mdt bundleResult;
        @AuraEnabled @InvocableVariable(label='Quote Bundle Product response data' description='Quote Bundle Products' required=false)
        global List<CalculatorProduct> productResults;
        @AuraEnabled @InvocableVariable(label='Subtotal for selected products' description='Quote Subtotal' required=false)
        global Double subtotal;
        @AuraEnabled @InvocableVariable(label='Serialized response data' description='Serialized Results' required=false)
        global String serializedResults;
        @AuraEnabled @InvocableVariable(label='Serialized secondary response data' description='Serialized Results 2' required=false)
        global String serializedResults2;
    }

    global class RequestTypeException extends Exception{}
    global class InvalidIdException extends Exception{}
}