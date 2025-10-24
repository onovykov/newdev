trigger ContentDocumentLink_Trigger on ContentDocumentLink (after insert) {
    
    ContentDocumentLink_TriggerHandler handler = new ContentDocumentLink_TriggerHandler();
    
    if(Trigger.isAfter && Trigger.isInsert){
        handler.OnAfterInsert();
    }
}