/**
 * Created by shing on 9/28/2020.
 */

trigger ContentDocumentLinkTrigger on ContentDocumentLink (before insert, before update )
{
    for(ContentDocumentLink cdl : Trigger.new)
    {
        if(!'AllUsers'.equalsIgnoreCase(cdl.Visibility)){cdl.Visibility='AllUsers';}
        if('SNOTE'.equalsIgnoreCase(cdl.ContentDocument?.FileType)){cdl.ShareType='I';}
    }
}