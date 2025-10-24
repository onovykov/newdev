public class CreateReclamationController {
	
    
    @AuraEnabled
    public static string takeInitialInfo(){
        
        List<Currencies> currs = new List<Currencies>(); 
        Map<String,Object> info = new Map<String,String>();
        String userId = UserInfo.getUserId();
        //Contact client = [SELECT name,Account.id,Account.CurrencyIsoCode,Account.MarketSegment__c FROM contact WHERE OwnerId='0051n000005mO52AAE' LIMIT 1];
        //Contact client = [SELECT name,Account.id,Account.CurrencyIsoCode,Account.MarketSegment__c FROM contact WHERE OwnerId=:userId LIMIT 1];
        User userInfo = [SELECT Contact.Account.Name,contact.Name,Contact.Account.Id,Contact.Account.CurrencyIsoCode, Account.MarketSegment__c,Contact.Id,ContactId FROM USER WHERE Id=:userId  LIMIT 1];
       	String userContactId = userInfo.ContactId;
        Contact client2 = [SELECT name,Account.id,Account.CurrencyIsoCode,toLabel(Account.MarketSegment__c) FROM contact WHERE Id=:userContactId LIMIT 1];
        system.debug(userId);
        	system.debug(userInfo.Contact.Account.Name);
        info.put('AccountId',client2.Account.id);
        info.put('date',String.valueOf(Date.today()));
        info.put('Currency',client2.Account.CurrencyIsoCode);
        info.put('CurrencyArr',createCurrencyArray(client2.Account.CurrencyIsoCode));
        info.put('Segment',client2.Account.MarketSegment__c);
        info.put('UserInfo',userId);
        info.put('AccountName',userInfo.Contact.Account.Name);
        string jsonstring = JSON.serialize(info);
        return jsonstring;
    }
    
    @AuraEnabled
    public static Map<String, List<String>> getDependentMap(sObject objDetail, string contrfieldApiName,string depfieldApiName) {
        String controllingField = contrfieldApiName.toLowerCase();
        String dependentField = depfieldApiName.toLowerCase();
        system.debug(objDetail);
        Map<String,List<String>> objResults = new Map<String,List<String>>();
        
        Schema.sObjectType objType = objDetail.getSObjectType();
        if (objType==null){
            return objResults;
        }
        
        Map<String, Schema.SObjectField> objFieldMap = objType.getDescribe().fields.getMap();
        
        if (!objFieldMap.containsKey(controllingField) || !objFieldMap.containsKey(dependentField)){
            return objResults;     
        }
        
        Schema.SObjectField theField = objFieldMap.get(dependentField);
        Schema.SObjectField ctrlField = objFieldMap.get(controllingField);
        
        List<Schema.PicklistEntry> contrEntries = ctrlField.getDescribe().getPicklistValues();
        List<PicklistEntryWrapper> depEntries = wrapPicklistEntries(theField.getDescribe().getPicklistValues());
        List<String> controllingValues = new List<String>();
        
        for (Schema.PicklistEntry ple : contrEntries) {
            String label = ple.getLabel();
            objResults.put(label, new List<String>());
            controllingValues.add(label);
        }
        
        for (PicklistEntryWrapper plew : depEntries) {
            String label = plew.label;
            String validForBits = base64ToBits(plew.validFor);
            for (Integer i = 0; i < validForBits.length(); i++) {
                String bit = validForBits.mid(i, 1);
                if (bit == '1') {
                    objResults.get(controllingValues.get(i)).add(label);
                }
            }
        }
        return objResults;
    }
    
    @AuraEnabled(cacheable=true) 
    public static Map<String, List<String>> getDependentMapLwc() {
        //Map<String, List<String>> valueMap = new Map<String, List<String>>();
        //valueMap.put('test',new List<STRING>{'tset'});
//        return valueMap;
        
        Reclamation_Detail__c objDetail = new Reclamation_Detail__c();
        //Schema.sObjectType objType = objDetail.getSObjectType();
        //system.debug(objType);
        
        String controllingField =  'Mistmatch_Type__c'.toLowerCase();
        String dependentField =  'Mistmatch_SubType__c'.toLowerCase();
        system.debug(objDetail);
        system.debug(controllingField);
        system.debug(dependentField);
        Map<String,List<String>> objResults = new Map<String,List<String>>();
        
        Schema.sObjectType objType = objDetail.getSObjectType();
        system.debug(objType);
        if (objType==null){
            return objResults;
        }
        
        Map<String, Schema.SObjectField> objFieldMap = objType.getDescribe().fields.getMap();
        system.debug(objFieldMap);
        if (!objFieldMap.containsKey(controllingField) || !objFieldMap.containsKey(dependentField)){
            return objResults;     
        }
        
        Schema.SObjectField theField = objFieldMap.get(dependentField);
        Schema.SObjectField ctrlField = objFieldMap.get(controllingField);
        system.debug(theField);
        system.debug(ctrlField);
        List<Schema.PicklistEntry> contrEntries = ctrlField.getDescribe().getPicklistValues();
        List<PicklistEntryWrapper> depEntries = wrapPicklistEntries(theField.getDescribe().getPicklistValues());
        List<String> controllingValues = new List<String>();
        
        for (Schema.PicklistEntry ple : contrEntries) {
            String label = ple.getLabel();
            objResults.put(label, new List<String>());
            controllingValues.add(label);
        }
        
        for (PicklistEntryWrapper plew : depEntries) {
            String label = plew.label;
            String validForBits = base64ToBits(plew.validFor);
            for (Integer i = 0; i < validForBits.length(); i++) {
                String bit = validForBits.mid(i, 1);
                if (bit == '1') {
                    objResults.get(controllingValues.get(i)).add(label);
                }
            }
        }
        system.debug(objResults);
        return objResults;
    }
    
    @AuraEnabled
    public static Map<String,List<OrderItem>> getOrderItems(String orderId){
        List<OrderItem> orderItems = [SELECT Id, Product2.Name,Product2.Id_ERP__c,UnitPrice,Quantity,OrderId,ITENumber__c,ID_ERP__c,Order.OrderNumber,Name__c,Order.AdditionalNumber__c,Order.PO_Number__c FROM OrderItem WHERE OrderId=:orderId ];
        Map<String,List<OrderItem>> mapOrderItem = new Map<String,List<OrderItem>>();
        mapOrderItem.put(orderId,orderItems);
        
        system.debug(orderItems);
        return mapOrderItem;
        
    }
    
    @AuraEnabled
    public static String getOrderData(String orderId){
        List<String> orderItemErpIds = new List<String>();
        Map<String,OpportunityLineItem> idErpOli = new Map<String,OpportunityLineItem>();
        List<OrderItem> orderItems = [SELECT Id, Product2.Name,Product2.Id_ERP__c,UnitPrice,Quantity,OrderId,ITENumber__c,
                                      ID_ERP__c,Order.OrderNumber,Name__c,Order.AdditionalNumber__c,Order.PO_Number__c FROM OrderItem WHERE OrderId=:orderId ];
        for(OrderItem oi : orderItems){
            orderItemErpIds.add(oi.ID_ERP__c);
        }
        
        for(OpportunityLineItem oli : [SELECT InquiryQuantity__c,tolabel(InquiryUnit__c),ID_ERP__c FROM OpportunityLineItem WHERE ID_ERP__c IN:orderItemErpIds]){
            idErpOli.put(oli.ID_ERP__c,oli);
        }           
        
        List<orderItemWithOliValue> dataItemList = new List<orderItemWithOliValue>();
        for(OrderItem oi : orderItems){
            orderItemWithOliValue dataItem = new orderItemWithOliValue();
            dataItem.Name = oi.Name__c;
            dataItem.Id = oi.Id;
            dataItem.OrderPONumber = oi.order.PO_Number__c;
            dataItem.InquiryQuantity = String.valueof(idErpOli.get(oi.ID_ERP__c).InquiryQuantity__c);
            dataItem.InquiryUnit = idErpOli.get(oi.ID_ERP__c).InquiryUnit__c;
            dataItem.UnitPrice = String.valueof(oi.UnitPrice);
            dataItem.OrderId = oi.OrderId;
            dataItem.IdinERP = oi.ID_ERP__c;
            dataItem.ITENumber = oi.ITENumber__c;
            dataItem.AdditionalNumber = oi.Order.AdditionalNumber__c;
            
            
            dataItemList.add(dataItem);
        }
       
        Map<String,List<orderItemWithOliValue>> mapOrderItem = new Map<String,List<orderItemWithOliValue>>();
        mapOrderItem.put(orderId,dataItemList);
		system.debug(mapOrderItem);
        String responseVal = JSON.serialize(mapOrderItem);
        return responseVal;
        
    }
    
    public class orderItemWithOliValue{
        public String Name {get;set;}        
        public String Id {get;set;}
        public String InquiryQuantity {get;set;}
        public String InquiryUnit {get;set;}
        public String UnitPrice {get;set;}
        public String OrderPONumber {get;set;}   
		public String OrderId {get;set;}     
        public String OrderProductId {get;set;}
        public String IdinERP {get;set;}
        public String ITENumber {get;set;}
        public String AdditionalNumber {get;set;}
        public String Product2Id {get;set;}
       
        }
    
    @AuraEnabled 
    public static String createReclamation(String reclamation,String data){
        Map<String, Object> reclamationInfo = (Map<String, Object>) JSON.deserializeUntyped(reclamation);
        Map<String,String> segmentsMap = getMarketSegmentMap();    
        Map<String, String> MistmatchType = new Map<String, String>();
    	MistmatchType.put('test', 'First item');
        Map<String, Integer> mistmatchTypeMap = getMapTypes();
        Set<Id> orderIdsFromReclamation = new Set<id>();
        List<Reclamation_Detail__c> reclamationDetailToInsert = new List<Reclamation_Detail__c>();
        String userId = UserInfo.getUserId();
        
        if(Test.isRunningTest()){
            userId = [SELECT Id FROM USER WHERE CompanyName = 'Vertamedia' LIMIT 1].id;
        }
        
        User userInfo = [SELECT Contact.Account.Id,AssignedBOS__c,ContactId FROM USER WHERE Id=:userId  LIMIT 1];
        //String userContactId = userInfo.ContactId;
        //Contact client2 = [SELECT name,Account.id,Account.CurrencyIsoCode,Account.MarketSegment__c FROM contact WHERE Id=:userContactId LIMIT 1];
        
        Reclamation__c createdRecl = new Reclamation__c();
        createdRecl.ContractNum__c = String.valueOf(reclamationInfo.get('orderNumber'));
        createdRecl.ReclSum__c = Double.valueOf(reclamationInfo.get('reclSum'));
        createdRecl.ContractDate__c = String.valueOf(reclamationInfo.get('contractDate')) != 'none' ? Date.valueOf(String.valueOf(reclamationInfo.get('contractDate'))) : null;
        createdRecl.CurrencyIsoCode = String.valueOf(reclamationInfo.get('reclCurrency'));
        createdRecl.Account__c	 = userInfo.Contact.Account.Id;
        createdRecl.AssignedBO_ID__c = userInfo.AssignedBOS__c;
        createdRecl.MarketSegment__c = segmentsMap.get(String.valueOf(reclamationInfo.get('marketSegment')));
        createdRecl.No_Refund__c = Boolean.valueOf(reclamationInfo.get('noRefund'));
        insert createdRecl;
        
        if(!Test.isRunningTest()){
            //create attached files
            List<Object> filesIds = (List<Object>) JSON.deserializeUntyped(JSON.serialize(reclamationInfo.get('files')));
            system.debug(filesIds);
            For(Object c : filesIds){
                System.debug(String.valueOf(c));
            }
            
            List<ContentDocumentLink> linksFile = new List<ContentDocumentLink>();
            For(Object c : filesIds){
                ContentDocumentLink cdl = new ContentDocumentLink(); // Content Document Link to share the file with Opportunity(Parent) record
                    cdl.LinkedEntityId = createdRecl.id; // Opportunity ID
                    cdl.ContentDocumentId = String.valueOf(c); //Content Dcoument ID
                    cdl.ShareType = 'V';
                    cdl.Visibility = 'AllUsers';
                    linksFile.add(cdl);
               // System.debug();
            }
            insert linksFile;
        }
        
        
        //Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(data);
        List<Object> m = ( List<Object>) JSON.deserializeUntyped(data);
        system.debug(m);   
        system.debug(m.size());
        for(Object o : m ){
            Reclamation_Detail__c newRecDet = new Reclamation_Detail__c();
            system.debug(o);
            Map<String, Object> ma =   (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(o));
            system.debug(ma.get('Product2'));
           // Map<String, Object> relatedOrder =   (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(ma.get('Order')));
           // system.debug(relatedOrder.get('AdditionalNumber__c'));
            system.debug(String.valueOf(ma.get('mismatchType')));
            newRecDet.ReclID__c=createdRecl.id;
            newRecDet.OrderID__c =String.valueOf(ma.get('OrderId'));
			newRecDet.OrderItemID__c =String.valueOf(ma.get('Id'));
            newRecDet.ID_in_ERP__c =String.valueOf(ma.get('ID_in_ERP__c'));
            newRecDet.Product2Id__c =String.valueOf(ma.get('Product2Id'));
            newRecDet.OrderQty__c =Double.valueOf(ma.get('InquiryQuantity'));
            newRecDet.OrderPrice__c =Double.valueOf(ma.get('UnitPrice'));
            newRecDet.ClaimQty__c =Double.valueOf(ma.get('claimQuaintity'));
            newRecDet.ClaimSum__c =Double.valueOf(ma.get('claimPrice'));
            newRecDet.Mistmatch_Type__c =String.valueOf(mistmatchTypeMap.get(String.valueOf(ma.get('mismatchType'))));
            newRecDet.Mistmatch_SubType__c =String.valueOf(mistmatchTypeMap.get(String.valueOf(ma.get('mismatchSubType'))));
            newRecDet.MismatchDate__c = Date.valueOf(String.valueOf(ma.get('mismatchSubDate')));
            newRecDet.CurrencyIsoCode = createdRecl.CurrencyIsoCode;
            newRecDet.ID_in_ERP__c = String.valueOf(ma.get('idErp'));
            newRecDet.ITENumber__c = String.valueOf(ma.get('ITENumber'));
            newRecDet.ClaimReason__c = String.valueOf(ma.get('commentItem')) == null? ' ' : String.valueOf(ma.get('commentItem'));
            newRecDet.Order_Additional_Number__c = String.valueOf(ma.get('AdditionalNumber')) == null? ' ' : String.valueOf(ma.get('AdditionalNumber'));
            newRecDet.PO_Number__c = String.valueOf(ma.get('OrderPONumber')) == null? ' ' : String.valueOf(ma.get('OrderPONumber'));
            newRecDet.MeasurementUnit__c = String.valueOf(ma.get('InquiryUnit'));
            system.debug(newRecDet);
            system.debug(MistmatchType.get('test'));
            system.debug(mistmatchTypeMap.get('Logistic'));
            reclamationDetailToInsert.add(newRecDet);
			orderIdsFromReclamation.add(newRecDet.OrderID__c);            
        }
        searchAndSendNotificationForOrderOwners(orderIdsFromReclamation,createdRecl.id);
        insert reclamationDetailToInsert;
        return createdRecl.id;
    }
    
    public static void searchAndSendNotificationForOrderOwners(Set<id> orderIds, Id reclamationId){
        List<String> orderOwnerEmails = new List<String>();
        String mailBody = 'New Reclamation was created. Link: '+ URL.getSalesforceBaseUrl().toExternalForm()+ '/'+reclamationId;
        
        for(Order orderSearch:[SELECT Owner.Email FROM ORDER WHERE Id in:orderIds] ){
            orderOwnerEmails.add(orderSearch.Owner.Email);
        }
        system.debug(orderOwnerEmails);
        system.debug(mailBody);
        
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.toAddresses = orderOwnerEmails;
        message.optOutPolicy = 'FILTER';
        message.subject = 'New Reclamation';
        message.htmlbody = mailBody;
        /*
        Messaging.SingleEmailMessage[] messages =   new List<Messaging.SingleEmailMessage> {message};
        Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
        
        if (results[0].success) {
            System.debug('The email was sent successfully.');
        } else {
            System.debug('The email failed to send: ' + results[0].errors[0].message);
        }*/
        
    }
    
    public static Map<String,Integer> getMapTypes(){
        //Map<String, Integer> MistmatchType = new Map<String, Integer>();
    	
        Map<String,Integer> valueSubTypeMap= new Map<String,Integer>();
		
		Schema.DescribeFieldResult fieldResult = Reclamation_Detail__c.Mistmatch_SubType__c.getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
		for( Schema.PicklistEntry pickListVal : ple){			
            valueSubTypeMap.put(pickListVal.getLabel(),Integer.valueOf(pickListVal.getValue()));
		} 
        
        Schema.DescribeFieldResult fieldResult2 = Reclamation_Detail__c.Mistmatch_Type__c.getDescribe();
		List<Schema.PicklistEntry> ple2 = fieldResult2.getPicklistValues();
		for( Schema.PicklistEntry pickListVal : ple2){			
            valueSubTypeMap.put(pickListVal.getLabel(),Integer.valueOf(pickListVal.getValue()));
		}
                                                       
        return valueSubTypeMap;
    }
    
    public static String createCurrencyArray(String value){
                       
        List<String> arrayOfCurr = new List<String>();
        arrayOfCurr.add(value);
        Set<String> validCurrency = new Set<String>();
		Schema.DescribeFieldResult f = Pricebook2.CurrencyIsoCode.getDescribe();
		for (Schema.PicklistEntry pick:f.getPicklistValues()){
          validCurrency.add(pick.getValue());
 			}
        String customArray ='' ;
        validCurrency.remove(value);
        arrayOfCurr.addAll(validCurrency);
        for(String cur : arrayOfCurr){
            customArray += cur + ',';
        }
        
       
  //      string arr = String.valueOf(arrayOfCurr);
        return customArray;

    }
    
    public static String decimalToBinary(Integer val) {
        String bits = '';
        while (val > 0) {
            Integer remainder = Math.mod(val, 2);
            val = Integer.valueOf(Math.floor(val / 2));
            bits = String.valueOf(remainder) + bits;
        }
        return bits;
    }
    
    public static String base64ToBits(String validFor) {
        if (String.isEmpty(validFor)) return '';
        
        String validForBits = '';
        
        for (Integer i = 0; i < validFor.length(); i++) {
            String thisChar = validFor.mid(i, 1);
            Integer val = base64Chars.indexOf(thisChar);
            String bits = decimalToBinary(val).leftPad(6, '0');
            validForBits += bits;
        }
        
        return validForBits;
    }
    
    private static final String base64Chars = '' +
        'ABCDEFGHIJKLMNOPQRSTUVWXYZ' +
        'abcdefghijklmnopqrstuvwxyz' +
        '0123456789+/';
    
    
    private static List<PicklistEntryWrapper> wrapPicklistEntries(List<Schema.PicklistEntry> PLEs) {
        return (List<PicklistEntryWrapper>)
            JSON.deserialize(JSON.serialize(PLEs), List<PicklistEntryWrapper>.class);
    }
    
    public class PicklistEntryWrapper{
        public String active {get;set;}
        public String defaultValue {get;set;}
        public String label {get;set;}
        public String value {get;set;}
        public String validFor {get;set;}
        public PicklistEntryWrapper(){            
        }
        
    }
    
    public class Currencies{
        String value;
    }
    
    public static void sendEmailForOrderOwners(Set<id> orderIds, Id reclamationId){
        Set<id> usersIds = new Set<id>();
        Set<String> userEmail = new Set<String>();
        List<Order> choosenOrders = [ SELECT OwnerId FROM ORDER WHERE id in :orderIds];
        for(Order o:choosenOrders){
            usersIds.add(o.OwnerId);
        }
        List<User> userOwnersOrder = [SELECT Email FROM USER WHERE Id IN :usersIds];
        for(User u : userOwnersOrder){
            userEmail.add(u.Email);
        }
        
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.toAddresses = new List<String>(userEmail);
        message.optOutPolicy = 'FILTER';
        message.subject = 'Reclamation';
        message.HtmlBody = 'Reclamation was created. Id - ' + reclamationId;
        Messaging.SingleEmailMessage[] messages =   new List<Messaging.SingleEmailMessage> {message};
        Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
        
        if (results[0].success) {
            System.debug('The email was sent successfully.');
        } else {
            System.debug('The email failed to send: ' + results[0].errors[0].message);
		}
        
    }
    
    @AuraEnabled 
    public static String addReclamationItems(String reclamationId,String data){
          
        Reclamation__c createdRecl = [SELECT Id,CurrencyIsoCode FROM Reclamation__c WHERE id=:reclamationId LIMIT 1];
        Map<String, Integer> mistmatchTypeMap = getMapTypes();
        Set<Id> orderIdsFromReclamation = new Set<id>();
        List<Reclamation_Detail__c> reclamationDetailToInsert = new List<Reclamation_Detail__c>();
                                               
        
        //Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(data);
        List<Object> m = ( List<Object>) JSON.deserializeUntyped(data);
        system.debug(m);   
        system.debug(m.size());
        for(Object o : m ){
            Reclamation_Detail__c newRecDet = new Reclamation_Detail__c();
            system.debug(o);
            Map<String, Object> ma =   (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(o));
            system.debug(ma.get('Product2'));
            system.debug(String.valueOf(ma.get('mismatchType')));
            newRecDet.ReclID__c=createdRecl.id;
            newRecDet.OrderID__c =String.valueOf(ma.get('OrderId'));
			newRecDet.OrderItemID__c =String.valueOf(ma.get('Id'));
            newRecDet.ID_in_ERP__c =String.valueOf(ma.get('ID_in_ERP__c'));
            newRecDet.Product2Id__c =String.valueOf(ma.get('Product2Id'));
            newRecDet.OrderQty__c =Double.valueOf(ma.get('InquiryQuantity'));
            newRecDet.OrderPrice__c =Double.valueOf(ma.get('UnitPrice'));
            newRecDet.ClaimQty__c =Integer.valueOf(ma.get('claimQuaintity'));
            newRecDet.ClaimSum__c =Double.valueOf(ma.get('claimPrice'));
            newRecDet.Mistmatch_Type__c =String.valueOf(mistmatchTypeMap.get(String.valueOf(ma.get('mismatchType'))));
            newRecDet.Mistmatch_SubType__c =String.valueOf(mistmatchTypeMap.get(String.valueOf(ma.get('mismatchSubType'))));
            newRecDet.MismatchDate__c = Date.valueOf(String.valueOf(ma.get('mismatchSubDate')));
            newRecDet.CurrencyIsoCode = createdRecl.CurrencyIsoCode;
            newRecDet.ID_in_ERP__c = String.valueOf(ma.get('idErp'));
            newRecDet.ITENumber__c = String.valueOf(ma.get('ITENumber__c'));
            newRecDet.ClaimReason__c = String.valueOf(ma.get('commentItem')) == null? ' ' : String.valueOf(ma.get('commentItem'));
            newRecDet.Order_Additional_Number__c = String.valueOf(ma.get('AdditionalNumber')) == null? ' ' : String.valueOf(ma.get('AdditionalNumber'));
            newRecDet.PO_Number__c = String.valueOf(ma.get('OrderPONumber')) == null? ' ' : String.valueOf(ma.get('OrderPONumber'));
            newRecDet.MeasurementUnit__c = String.valueOf(ma.get('InquiryUnit'));
            system.debug(newRecDet);
            
            system.debug(mistmatchTypeMap.get('Logistic'));
            reclamationDetailToInsert.add(newRecDet);
			orderIdsFromReclamation.add(newRecDet.OrderID__c);            
        }
        searchAndSendNotificationForOrderOwners(orderIdsFromReclamation,createdRecl.id);
        insert reclamationDetailToInsert;
        return createdRecl.id;
    }
    @AuraEnabled 
    public static String getReclamationStatus(String reclamationId){
        String statusReclamation;
        system.debug(reclamationId);
        Reclamation__c searchedReclamation = [SELECT Id,Status__c FROM Reclamation__c WHERE id=:reclamationId LIMIT 1];
        statusReclamation = searchedReclamation.Status__c;
        system.debug(statusReclamation);
        return statusReclamation;
    }

    public static Map<String,String> getMarketSegmentMap(){
        Map<String,String> marketSegmentMap = new Map<String,String>();
        Schema.DescribeFieldResult fieldResult = Order.MarketSegment__c.getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
		for( Schema.PicklistEntry pickListVal : ple){
			marketSegmentMap.put(pickListVal.getLabel(),pickListVal.getValue());
		}     
		return marketSegmentMap;

    }
        
}