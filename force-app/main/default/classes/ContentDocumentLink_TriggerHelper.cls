public class ContentDocumentLink_TriggerHelper {
    public static Boolean flag = true;
    public static void shareFile(List<ContentDocumentLink> cdlLink){
        try{
            insert cdlLink;
        }
        catch(Exception e){
            system.debug('Exception has occured ! ' +e.getMessage());
        }
    }
}