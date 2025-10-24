public without sharing class QuoteTriggerHandler extends TriggerHandler implements ITrigger {
    
    String header = '';
    String bottom = '';
    String marking = '';
    String markingUkr = '';
    String markingRus = '';
    String tolerance = '';
    String packing = '';
    String packingUkr = '';
    String packingRus = '';
    String plasticCapsUkr = '';
    String plasticCapsRus = '';
    String thirdPartyInspection = '';
    String thirdPartyInspectionUkr = '';
    String thirdPartyInspectionRus = '';
    String specialShippingRequirements = '';
    String productionDeliveryDetails = '';
    String shippingMarks = '';
    String additionalTerms = '';
    String additionalTermsUkr = '';
    String additionalTermsRus = '';
    String additionalTermsWheels = '';
    String additionalTermsWheelsUkr = '';
    String additionalTermsWheelsRus = '';
    String additionalMarkingOnDeliveryUkr = '';
    String additionalMarkingOnDeliveryRus = '';
    String additionalTermsOnDeliveryUkr = '';
    String additionalTermsOnDeliveryRus = '';
    Map<Id, Date> cddForOpp = new Map<Id, Date>();
    Map<Id, Opportunity> oppMapWithOLIs = new Map<Id, Opportunity>();
    Map<Id, List<OpportunityLineItem>> quoteIdToOppli = new Map<Id, List<OpportunityLineItem>>();
    List<QuoteLineItem> QuLItoInsert = new List<QuoteLineItem>();
    
    public QuoteTriggerHandler(Map<Id, SObject> oldMap, Map<Id, SObject> newMap, List<SObject> oldList, List<SObject> newList) {
        super(oldMap, newMap, oldList, newList);
    }
    
    public void bulkBefore() {
        System.debug('bulkBeforeQuote');
        List<Bank_Details__mdt> banks = [SELECT Id, BottomText__c, HeaderText__c, Marking__c, Marking_Ukr__c, Marking_Rus__c, Tolerance__c, Packing__c, Packing_Ukr__c, Packing_Rus__c, 
                                         Plastic_Caps_Ukr__c, Plastic_Caps_Rus__c, Third_party_Inspection__c, Third_party_Inspection_Ukr__c, Third_party_Inspection_Rus__c, 
                                         Special_Shipping_Requirements__c, Shipping_Marks__c, Additional_Terms__c, Additional_Terms_Ukr__c, Additional_Terms_Rus__c, 
                                         Additional_Terms_Wheels__c, Additional_Terms_Wheels_Ukr__c, Additional_Terms_Wheels_Rus__c, Additional_Marking_On_Delivery_Ukr__c, 
                                         Additional_Marking_On_Delivery_Rus__c, Additional_Terms_On_Delivery_Ukr__c, Additional_Terms_On_Delivery_Rus__c, Production_Delivery_Details__c  
                                         FROM Bank_Details__mdt];
        
        if(banks.size()>0){
            header = String.valueOf(banks[0].HeaderText__c);
            marking = String.valueOf(banks[0].Marking__c);
            markingUkr = String.valueOf(banks[0].Marking_Ukr__c);
            markingRus = String.valueOf(banks[0].Marking_Rus__c);
            tolerance = String.valueOf(banks[0].Tolerance__c);
            packing = String.valueOf(banks[0].Packing__c);
            packingUkr = String.valueOf(banks[0].Packing_Ukr__c);
            packingRus = String.valueOf(banks[0].Packing_Rus__c);
            plasticCapsUkr = String.valueOf(banks[0].Plastic_Caps_Ukr__c);
            plasticCapsRus = String.valueOf(banks[0].Plastic_Caps_Rus__c);
            thirdPartyInspection = String.valueOf(banks[0].Third_party_Inspection__c);
            thirdPartyInspectionUkr = String.valueOf(banks[0].Third_party_Inspection_Ukr__c);
            thirdPartyInspectionRus = String.valueOf(banks[0].Third_party_Inspection_Rus__c);
            specialShippingRequirements = String.valueOf(banks[0].Special_Shipping_Requirements__c);
            productionDeliveryDetails = String.valueOf(banks[0].Production_Delivery_Details__c);
            shippingMarks = String.valueOf(banks[0].Shipping_Marks__c);
            additionalTerms = String.valueOf(banks[0].Additional_Terms__c);
            additionalTermsUkr = String.valueOf(banks[0].Additional_Terms_Ukr__c);
            additionalTermsRus = String.valueOf(banks[0].Additional_Terms_Rus__c);
            additionalTermsWheels = String.valueOf(banks[0].Additional_Terms_Wheels__c);
            additionalTermsWheelsUkr = String.valueOf(banks[0].Additional_Terms_Wheels_Ukr__c);
            additionalTermsWheelsRus = String.valueOf(banks[0].Additional_Terms_Wheels_Rus__c);
            additionalMarkingOnDeliveryUkr = String.valueOf(banks[0].Additional_Marking_On_Delivery_Ukr__c);
            additionalMarkingOnDeliveryRus = String.valueOf(banks[0].Additional_Marking_On_Delivery_Rus__c);
            additionalTermsOnDeliveryUkr = String.valueOf(banks[0].Additional_Terms_On_Delivery_Ukr__c);
            additionalTermsOnDeliveryRus = String.valueOf(banks[0].Additional_Terms_On_Delivery_Rus__c);
        }
        
        if (Trigger.isInsert) {
            Set<Id> oppIds = new Set<Id>();
            for (SObject so : newList) {
                Quote qli = (Quote) so;
                oppIds.add(qli.OpportunityId);
            }
            oppMapWithOLIs = new Map<Id, Opportunity>([SELECT Id, CurrencyISOCode, (SELECT CDD__c, FinalCDD__c, ITENumber__c, NPP_ERP__c, InquiryUnit__c FROM OpportunityLineItems) FROM Opportunity WHERE Id IN :oppIds]);
            
            for(Opportunity opp : oppMapWithOLIs.values()){
                List<Date> cdds = new List<Date>();
                for(OpportunityLineItem oli : opp.OpportunityLineItems){
                    cdds.add(oli.FinalCDD__c);
                }
                cdds.sort();
                if(cdds.size()>0){
                    cddForOpp.put(opp.Id, cdds.get(cdds.size()-1));
                }
            }
        }
        System.debug(oppMapWithOLIs);        
    }
    
    public void beforeInsert(SObject so) {
        System.debug('beforeInsert');
        Quote qu = (Quote) so;
        qu.HeaderText__c = header;
        qu.Marking__c = marking;
        qu.Marking_Ukr__c = markingUkr;
        qu.Marking_Rus__c = markingRus;
        qu.Tolerance__c = tolerance;
        qu.Packing__c = packing;
        qu.Packing_Ukr__c = packingUkr;
        qu.Packing_Rus__c = packingRus;
        qu.Plastic_Caps_Ukr__c = plasticCapsUkr;
        qu.Plastic_Caps_Rus__c = plasticCapsRus;
        qu.Third_party_Inspection__c = thirdPartyInspection;
        qu.Third_Party_Inspection_Ukr__c = thirdPartyInspectionUkr;
        qu.Third_Party_Inspection_Rus__c = thirdPartyInspectionRus;
        qu.Special_Shipping_Requirements__c = specialShippingRequirements;
        qu.Production_Delivery_Details__c = productionDeliveryDetails;
        qu.ShippingMarks__c = shippingMarks;
        qu.Additional_Terms__c = additionalTerms;
        qu.Additional_Terms_Ukr__c = additionalTermsUkr;
        qu.Additional_Terms_Rus__c = additionalTermsRus;
        qu.Additional_Terms_Wheels__c = additionalTermsWheels;
        qu.Additional_Terms_Wheels_Ukr__c = additionalTermsWheelsUkr;
        qu.Additional_Terms_Wheels_Rus__c = additionalTermsWheelsRus;
        qu.Additional_Marking_On_Delivery_Ukr__c = additionalMarkingOnDeliveryUkr;
        qu.Additional_Marking_On_Delivery_Rus__c = additionalMarkingOnDeliveryRus;
        qu.Additional_Terms_On_Delivery_Ukr__c = additionalTermsOnDeliveryUkr;
        qu.Additional_Terms_On_Delivery_Rus__c = additionalTermsOnDeliveryRus;
        qu.Production_Delivery__c = cddForOpp.get(qu.OpportunityId)!=null ? cddForOpp.get(qu.OpportunityId).format() : '';
        fillInvoicing(qu);
    }
    
    public void beforeUpdate(SObject oldSo, SObject so) {
        System.debug('beforeUpdate');
    }
    
    public void beforeDelete(SObject so) {
    }
    
    public void bulkAfter() {
        System.debug('bulkAfter');
        if (Trigger.isInsert) {
            Set<Id> oppIds = new Set<Id>();
            for (SObject so : newList) {
                Quote qli = (Quote) so;
                oppIds.add(qli.OpportunityId);
            }
            oppMapWithOLIs = new Map<Id, Opportunity>([SELECT Id, CurrencyISOCode, (SELECT Id,ID_ERP__c, ITENumber__c, NPP_ERP__c, CDD__c, InquiryUnit__c, InquiryQuantity__c, PricebookEntryId, Product2Id, Quantity, Quantity_ft__c, Quantity_m__c, Quantity_pcs__c, Description, Discount, ListPrice, Subtotal, UnitPrice FROM OpportunityLineItems) FROM Opportunity WHERE Id IN :oppIds]);
            for (SObject so : newList) {
                Quote qli = (Quote) so;
                System.debug(oppMapWithOLIs);
                Opportunity opp = oppMapWithOLIs.get(qli.OpportunityId);
                System.debug(opp);
                List<OpportunityLineItem> oppLiList = opp.OpportunityLineItems;
                quoteIdToOppli.put(qli.Id, oppLiList);
            }
        }
    }
    
    public void afterInsert(SObject so) {
        System.debug('afterInsert');
        Quote oneQuote = (Quote) so;
        if (oneQuote.Created_from_Flow__c==true){
            List<OpportunityLineItem> oppLiList = quoteIdToOppli.get(oneQuote.Id);
            System.debug('Quote PB ID = '+oneQuote.Pricebook2Id);
            for (OpportunityLineItem oppLi : oppLiList) {
                System.debug('Quote PB ID = '+oneQuote.Pricebook2Id);
                QuoteLineItem quoteLI = new QuoteLineItem();
                quoteLI.Product2Id = oppLi.Product2Id;
                quoteLI.OpportunityLineItemId = oppLi.Id;
                quoteLI.OpportunityLineItemITENumber__c = oppLi.ITENumber__c;
                quoteLI.NPP__c = oppLi.NPP_ERP__c;
                quoteLI.ID_ERP__c = oppLi.ID_ERP__c;
                System.debug('quoteLI.Product2Id = '+quoteLI.Product2Id);
                quoteLI.Quantity = oppLi.Quantity;
                quoteLI.Quantity_ft__c = oppLi.Quantity_ft__c;
                quoteLI.Quantity_m__c = oppLi.Quantity_m__c;
                quoteLI.Quantity_pcs__c = oppLi.Quantity_pcs__c;
                quoteLI.UnitPrice = oppLi.UnitPrice;quoteLI.Quantity = oppLi.Quantity;
                System.debug('quoteLI.PricebookEntryId = '+quoteLI.PricebookEntryId);
                
                quoteLI.Description = (oppLi.Description==null) ? null : oppLi.Description;
                quoteLI.Discount = (oppLi.Discount==null) ? null : oppLi.Discount;
                
                quoteLI.QuoteId = oneQuote.Id;
                
                QuLItoInsert.add(quoteLI);
            }
        }
    }
    
    public void afterUpdate(SObject oldSo, SObject so) {
        System.debug('afterUpdate');
        Quote newQuote = (Quote) so;
        Quote oldQuote = (Quote) oldSo;
		List<Id> quoteIds = new List<Id>();
        
        if (isFieldChanged(newQuote, oldQuote, 'ExpirationDate') && oldQuote.Created_From_OPA_process__c == false) {
            for(Id id : newMap.keySet()){
                quoteIds.add(id);
                System.debug('---equal');
            }
            system.debug('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
            QuoteJSONGenerator.createJsonData(quoteIds);
        }
    }

    
    public void afterDelete(SObject so) {
    }
    
    public void postProcessing() {
        System.debug('postProcessing');
        if (QuLItoInsert.size()>0) {
            insert QuLItoInsert;
        }
    }
    
    public static Map<String, String> getApinameToLabelMap(){
        Map<String, String> labelToApinameMap = ApexUtil.getPicklistFieldMap('QuoteLineItem', 'InquiryUnit__c');
        Map<String, String> result = new Map<String, String>();
        for (String label : labelToApinameMap.keySet()){
            result.put(labelToApinameMap.get(label), label);
        }
        result.put(null, 'n.s.');
        return result;
    }
    
    public void fillInvoicing(Quote qu){
        String invoicing = '';
        invoicing+=oppMapWithOLIs.get(qu.OpportunityId).CurrencyISOCode;
        Map<String, String> labelsToAPINames = getApinameToLabelMap();
        invoicing+=', ';
        if(oppMapWithOLIs.get(qu.OpportunityId).OpportunityLineItems.size()>0){
            invoicing+=labelsToAPINames.get(oppMapWithOLIs.get(qu.OpportunityId).OpportunityLineItems[0].InquiryUnit__c);
        }
        qu.Invoicing__c = invoicing;
    }

    private Boolean isFieldChanged(Quote newQuote, Quote oldQuote, String fieldName) {
		return newQuote.get(fieldName) != oldQuote.get(fieldName);
	}
}