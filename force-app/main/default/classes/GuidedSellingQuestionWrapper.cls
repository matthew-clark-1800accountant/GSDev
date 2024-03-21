public without sharing class GuidedSellingQuestionWrapper{
    public Boolean DisplayByDefault {get;set;}
    public String EngageText {get;set;}
    public Boolean IncludesEngageText {get;set;}
    public String PicklistOptions {get;set;}
    public String QuestionText {get;set;}
    public String QuestionType {get;set;}
    public Boolean Required {get;set;}
    public String DevName {get;set;}
    public Boolean Answered {get;set;}
    public String Value {get;set;}

    public GuidedSellingQuestionWrapper(Guided_Selling_Discovery_Question__mdt questionRecord){
        this.DisplayByDefault = questionRecord.Display_By_Default__c;
        this.EngageText = questionRecord.Engage_Text__c;
        this.IncludesEngageText = questionRecord.Includes_Engage_Text__c;
        this.PicklistOptions = questionRecord.Picklist_Options__c;
        this.QuestionText = questionRecord.Question_Text__c;
        this.QuestionType = questionRecord.Question_Type__c;
        this.Required = questionRecord.Required__c;
        this.DevName = questionRecord.DeveloperName;
        this.Answered = false;
    }
}