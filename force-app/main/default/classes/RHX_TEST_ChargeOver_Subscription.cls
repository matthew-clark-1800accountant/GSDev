@isTest(SeeAllData=true)
public class RHX_TEST_ChargeOver_Subscription {
	static testMethod void RHX_Testmethod() {
        List<sObject> sourceList = [SELECT Id 
			FROM ChargeOver_Subscription__c ORDER BY LastModifiedDate DESC LIMIT 1];
            Account acc = new Account(Name='test acc');
            insert acc;
            if(sourceList.size() == 0) {
            sourceList.add(
                    new ChargeOver_Subscription__c(Account__c = acc.Id)
            );
        }
    	

       rh2.ParentUtil.UpsertRollupTestRecords( sourceList );
    }
}