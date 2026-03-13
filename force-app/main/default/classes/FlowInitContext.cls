public with sharing class FlowInitContext {

    public class Output {
        @InvocableVariable
        public String recordTypeId;

        @InvocableVariable
        public String recordTypeContactId;        

        @InvocableVariable
        public String ownerId;

        @InvocableVariable
        public Id ParentHierId;
    }

    @InvocableMethod(label='Init Account Flow Context')
    public static List<Output> init(List<String> dummy) {
        Output o = new Output();

        o.recordTypeId = RecordTypeCache.getId('Account', 'Scrap_Supplier');
        o.ownerId = UserRepository.getByErp('66120').Id;
        o.recordTypeContactId = RecordTypeCache.getId('Contact', 'External');
        List<Account> accList = [SELECT Id FROM Account WHERE Name LIKE 'КОМЕРЦ%' LIMIT 1];
        o.ParentHierId = (!accList.isEmpty()) ? accList[0].Id : null;

        return new List<Output>{ o };
    }
}