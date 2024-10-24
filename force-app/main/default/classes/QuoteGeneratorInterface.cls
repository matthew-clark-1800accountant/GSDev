@RestResource(urlMapping='/QuoteGenerator/*')
global without sharing class QuoteGeneratorInterface {
    global QuoteGeneratorInterface() {

    }

    global enum RequestType {GET_BUNDLE, GET_PRODUCTS, CHECK_BUNDLE, UPDATE_PRODUCTS, CREATE_QUOTES}

    global static BundleRequest validateRequest(BundleRequest req){
        RequestType reqType;
        try{
            reqType = RequestType.valueOf(req.requestType);
        } catch (Exception ex){
            throw new RequestTypeException(reqType + ' is not a valid request type.');
        }
        if(req.config == null){
            if(req.deserializeInputs == true){
                try{
                    req.config = (CalculatorConfiguration)JSON.deserialize(req.serializedInput, CalculatorConfiguration.class);
                } catch (Exception ex){
                    throw new InvalidParameterException('No valid CalculatorConfiguration value found. '+ex.getMessage());
                }
            } else {
                throw new InvalidParameterException('No valid CalculatorConfiguration value found.');
            }                
        }
        
        if(req.config.accountId == null){
            List<Opportunity> opps = [SELECT AccountId FROM Opportunity WHERE Id = :req.config.opportunityId LIMIT 1];
            if(opps.isEmpty()){
                throw new InvalidIdException('Invalid Opportunity Id: '+req.config.opportunityId);
            }
            req.config.accountId = opps[0].AccountId;
        }
        if(req.config.calculator == null){
            req.config.calculator = 'Any';
        }
        return req;
    }


    @InvocableMethod(label='Invocable QuoteGenerator Test' description='Invocable method to test QuoteGenerator methods.')
    global static List<BundleResponse> runQuoteGenerator(List<BundleRequest> bundleRequests){
        List<BundleResponse> results = new List<BundleResponse>();
        for(BundleRequest req : bundleRequests){            
            req = validateRequest(req);
            BundleResponse response = new BundleResponse();
            RequestType reqType = RequestType.valueOf(req.requestType);

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
                    else {response.isBundleActive = bundleIsActive;}
                }
                when UPDATE_PRODUCTS {
                    List<CalculatorProduct> products;
                    if(req.deserializeInputs == true && req.serializedInput != null){ products = (List<CalculatorProduct>)JSON.deserialize(req.serializedInput, List<CalculatorProduct>.class);}
                    else{ products = req.calculatorProducts; }
                    List<CalculatorProduct> selectedProducts = QuoteGenerator.getSelectedProducts(products);

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
                    List<CalculatorProduct> products;
                    if(req.deserializeInputs == true && req.serializedInput != null){ products = (List<CalculatorProduct>)JSON.deserialize(req.serializedInput, List<CalculatorProduct>.class);}
                    else{ products = req.calculatorProducts; }
                    List<CalculatorProduct> selectedProducts = QuoteGenerator.getSelectedProducts(products);

                    if(req.serializeResults == true){ 
                        response.serializedResults = QuoteGenerator.doSubmit(req.config, selectedProducts, null); 
                    } else { 
                        response.serializedResults = QuoteGenerator.doSubmit(req.config, selectedProducts, null); 
                    }
                }
            }
            results.add(response);
        }
        return results;
    }
    

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

    @HttpGet
    global static String getTest(){
        return 'you\'ve been got';
    }

    global class BundleRequest {
        @AuraEnabled @InvocableVariable(label='Calculator Configuration data' description='Calculator Configuration' required=true)
        global CalculatorConfiguration config;
        @AuraEnabled @InvocableVariable(label='Type of the request' description='Request Type' required=true)
        global String requestType;
        @AuraEnabled @InvocableVariable(label='List of Calculator Products' description='CalculatorProducts' required=false)
        global List<CalculatorProduct> calculatorProducts;
        @AuraEnabled @InvocableVariable(label='Convert method results to JSON' description='Serialize Results' required=false)
        global Boolean serializeResults;
        @AuraEnabled @InvocableVariable(label='Convert method parameters from JSON' description='Deserialize Inputs' required=false)
        global Boolean deserializeInputs;
        @AuraEnabled @InvocableVariable(label='JSON input for calculator products' description='Serialized input' required=false)
        global String serializedInput;

        //to be deprecated
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
        @AuraEnabled @InvocableVariable(label='Boolean representing if the eligible bundle is active' description='Bundle is Active' required=false)
        global Boolean isBundleActive;
        @AuraEnabled @InvocableVariable(label='Serialized response data' description='Serialized Results' required=false)
        global String serializedResults;

        //to be deprecated
        @AuraEnabled @InvocableVariable(label='Serialized secondary response data' description='Serialized Results 2' required=false)
        global String serializedResults2;
    }

    global class RequestTypeException extends Exception{}
    global class InvalidIdException extends Exception{}
    global class InvalidParameterException extends Exception{}
}