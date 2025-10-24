public with Sharing class lookupfieldController {    
    @AuraEnabled
    public static List<sObject> GetRecentRecords(String ObjectName, List<String> ReturnFields, Integer MaxResults) {
        
        List<Id> recentIds = new List<Id>();
        for(RecentlyViewed recent : [SELECT Id FROM RecentlyViewed WHERE Type = :ObjectName ORDER BY LastViewedDate DESC LIMIT :MaxResults]) {
            recentIds.add(recent.Id);
        }
        
        String sQUERY = 'SELECT Id, ';

        if (ReturnFields != null && ReturnFields.Size() > 0) {
            sQuery += String.join(ReturnFields, ',');
        } else {
            sQuery += 'Name';   
        }
        
        sQuery += ' FROM ' + ObjectName + ' WHERE Id IN :recentIds';

        List<sObject> searchResult = Database.query(sQuery);
        //dont show recent records
        return new List<sObject>();
    }
    
    @AuraEnabled
    public static List<sObject> SearchRecords(String ObjectName, List<String> ReturnFields, List<String> QueryFields, String SearchText, String SortColumn, String SortOrder, Integer MaxResults, String Filter,Date FromDate,Date ToDate) {
        
        system.debug(ReturnFields);
        system.debug(QueryFields);
        
        List<String> searchFields = new List<String>{'AdditionalNumber__c','PO_Number__c'};
        //always put a limit on the results
        if (MaxResults == null || MaxResults == 0) {
            MaxResults = 5;
        }
        
        SearchText = '%' + SearchText + '%';
        
        List <sObject > returnList = new List < sObject > ();
        
        String sQuery =  'SELECT Id, ';
        
        if (searchFields != null && searchFields.Size() > 0) {
            sQuery += String.join(searchFields, ',');
        } else {
            sQuery += 'Name';   
        }
        //add status!=draft
        sQuery += ' FROM ' + ObjectName + ' WHERE Status !=\'Draft\'  AND';
        
        //add date filter
        if(FromDate != null){
            sQuery += ' EffectiveDate >' +  String.valueof(FromDate).substringBefore(' ') + ' AND';        
        }
        
        if(ToDate != null){
            sQuery += ' EffectiveDate <' +  String.valueof(ToDate).substringBefore(' ')+ ' AND';
        }
        
        if (searchFields == null || searchFields.isEmpty()) {
            sQuery += ' Name LIKE :SearchText ';
        } else {
            string likeField = '';
            for(string field : searchFields) {
                likeField += ' OR ' + field + ' LIKE :SearchText ';    
            }
            sQuery += ' (' + likeField.removeStart(' OR ') + ') ';
        }
        
      //  if (Filter != null) {
       //     sQuery += ' AND (' + Filter + ')';
        //}
        
        if(string.isNotBlank(SortColumn) && string.isNotBlank(SortOrder)) {
            sQuery += ' ORDER BY ' + SortColumn + ' ' + SortOrder;
        }
        
        sQuery += ' LIMIT ' + MaxResults;
        
        System.debug(sQuery);
        
        List <sObject> searchResult = Database.query(sQuery);
        System.debug(searchResult);
        return searchResult;
    }
    
    @AuraEnabled
    public static List<sObject> GetRecord(String ObjectName, List<String> ReturnFields, String Id) {
        String sQUERY = 'SELECT Id, ';

        if (ReturnFields != null && ReturnFields.Size() > 0) {
            sQuery += String.join(ReturnFields, ',');
        } else {
            sQuery += 'Name';   
        }
        
        sQuery += ' FROM ' + ObjectName + ' WHERE Id = :Id';

        List<sObject> searchResult = Database.query(sQuery);
        
        return searchResult;
    }
    
    @AuraEnabled
    public static string findObjectIcon(String ObjectName) {    
        String u;
        List<Schema.DescribeTabResult> tabDesc = new List<Schema.DescribeTabResult>();
        List<Schema.DescribeIconResult> iconDesc = new List<Schema.DescribeIconResult>();
        
        for(Schema.DescribeTabSetResult describeTabSetResult : Schema.describeTabs()) {
            for(Schema.DescribeTabResult describeTabResult : describeTabSetResult.getTabs()) {
                if(describeTabResult.getSobjectName() == ObjectName) { 
                    if( describeTabResult.isCustom() == true ) {
                        for (Schema.DescribeIconResult describeIcon : describeTabResult.getIcons()) {
                            if (describeIcon.getContentType() == 'image/svg+xml'){
                                return 'custom:' + describeIcon.getUrl().substringBetween('custom/','.svg').substringBefore('_');
                            }
                        }
                    } else {
                        return 'standard:' + ObjectName.toLowerCase();
                    }
                }
            }
        }

        return 'standard:default';
    }
    
    @AuraEnabled
    public static objectDetails getObjectDetails(String ObjectName) {    

        objectDetails details = new objectDetails();
        
        Schema.DescribeSObjectResult describeSobjectsResult = Schema.describeSObjects(new List<String>{ObjectName})[0];

        details.label = describeSobjectsResult.getLabel();
        details.pluralLabel = describeSobjectsResult.getLabelPlural();

        details.iconName = findObjectIcon(ObjectName);
        
        return details;
    }
    
    public class objectDetails {
        @AuraEnabled
        public string iconName;
        @AuraEnabled
        public string label;
        @AuraEnabled
        public string pluralLabel;
    }
}