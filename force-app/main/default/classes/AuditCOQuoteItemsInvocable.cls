public without sharing class AuditCOQuoteItemsInvocable {
    @InvocableMethod(label='Aggregate the line items of each CO Quote' description='Aggregate the line items of each CO Quote')
    public static List<List<String>> AggregateItems(List<Id> quoteIds){
        Id quoteId = quoteIds[0];
        Map<Double, Integer> scheduleNumToPayNum = new Map<Double,Integer>{
            null => 1,
            4 => 2,
            5 => 3,
            6 => 4,
            7 => 6
        };
        Map<Integer, String> payNumToInstallString = new Map<Integer,String>{
            1 => 'no',
            2 => '2-Pay',
            3 => '3-Pay',
            4 => '4-Pay',
            6 => '6-Pay',
            12 => 'Monthly Installments' //this one shouldn't ever be used
        };
        Map<String,String> payCycleToPayString = new Map<String, String>{
            'mon' => 'Monthly',
            'one' => 'One-Time',
            'yrl' => 'Yearly'
        };

        List<String> resultStrings = new List<String>();
        String templateString = 'The {0} CO Quote with {1} installments has payment amount(s) of ${2} and includes the following items: {3}';
        
        List<Chargeover_Quote__c> coQuotes = [SELECT Id, Payment_Cycle__c, Installment_Payment_Schedule__c, (SELECT Id, Price_Per_Unit__c, Quantity__c, Contract_Amount__c, Product__r.Name FROM ChargeOver_Quote_Line_Items__r) FROM Chargeover_Quote__c WHERE Quote__c = :quoteId order by Payment_Cycle__c,Installment_Payment_Schedule__c];
        for(Chargeover_Quote__c coQuote : coQuotes){
            String resultString = templateString.replace('{0}', payCycleToPayString.get(coQuote.Payment_Cycle__c)).replace('{1}', payNumToInstallString.get(scheduleNumToPayNum.get(coQuote.Installment_Payment_Schedule__c)));
            Decimal installAmount = 0;
            String itemListString = '';
            Integer payNum = scheduleNumToPayNum.get(coQuote.Installment_Payment_Schedule__c);
            //if(coQuote.Payment_Cycle__c == 'mon'){ payNum = 12; }
            for(ChargeOver_Quote_Line_Item__c item : coQuote.ChargeOver_Quote_Line_Items__r){
                Decimal itemAmount = ((item.Price_Per_Unit__c*item.Quantity__c)/payNum).setScale(2);
                installAmount += itemAmount;
                itemListString += item.Product__r.Name+' ($'+itemAmount+'), ';
            }
            //installAmount = (installAmount / payNum).setScale(2);
            itemListString = itemListString.substring(0, itemListString.length()-2);
            resultString = resultString.replace('{2}', String.valueOf(installAmount)).replace('{3}', itemListString);
            resultStrings.add(resultString);
        }

        return new List<List<String>>{resultStrings};
    }
}