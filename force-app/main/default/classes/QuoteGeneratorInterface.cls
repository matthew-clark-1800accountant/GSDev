public without sharing class QuoteGeneratorInterface {
    public QuoteGeneratorInterface() {

    }

    @InvocableMethod(label='Get Eligible Bundle' description='Returns the bundle for which an account would be eligible.')
    public static List<Quote_Bundle__mdt> testBundleSelection(List<BundleRequest> bundleRequests){
        List<Quote_Bundle__mdt> results = new List<Quote_Bundle__mdt>();
        for(BundleRequest req : bundleRequests){
            results.add(QuoteGenerator.getQuoteBundle(req.accountId, req.entityOverride, req.calculator));
        }
        return results;
    }

    public class BundleRequest {
        @InvocableVariable(label='Id for test account' description='Account Id' required=true)
        public Id accountId;
        @InvocableVariable(label='Entity value to override account field' description='Entity Override' required=false)
        public String entityOverride;
        @InvocableVariable(label='Calculator to check against' description='Calculator' required=false)
        public String calculator;
    }
}