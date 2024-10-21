@IsTest
public without sharing class QuoteGeneratorTest {
    
    @IsTest 
    public static void convertLeadTest(){
        Lead l = new Lead(FirstName = 'Rico', LastName='Chavez', Company='Bobby\'s Tables');
        Id oppId = QuoteGeneratorHelper.convertLead(l);
        Assert.isNotNull(oppId);
    }
}