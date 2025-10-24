public class SendAdjustmentQuotaRequest {

    @InvocableMethod
    public static void SendQuotaRequest(List<Id> quotaRequestHeaderIdList) {
        List<QuoteRequestDetail__c> quotaRequestDetailList = [SELECT Id, MarketSegment__c, Family__r.ID_ERP__c, Region__r.ID_ERP__c, Quote_t__c,
                                                                     Manager__r.ID_ERP__c, Group3__r.ID_ERP__c, DateBegin__c, Percent__c, 
                                                                     AddQty_t__c, Add_Qty_pcs__c, RoutesQuotesH__c, QuoteStructureDetail__c,
                                                                     QuoteStructureDetail__r.ID_ERP__c
                                                              FROM QuoteRequestDetail__c 
                                                              WHERE QuoteRequestHeader__c = :quotaRequestHeaderIdList.get(0)];

        String data = getJSONData(quotaRequestDetailList);
        System.enqueueJob(new SendAdjustmentQuotaCalloutJob(data, quotaRequestDetailList));
    }

    public static String getJSONData(List<QuoteRequestDetail__c> quotaRequestDetailList) {
        JSONGenerator jsonToSend = JSON.createGenerator(true);

		jsonToSend.writeStartArray();
		
		for (QuoteRequestDetail__c quotaRequestDetail : quotaRequestDetailList) {
			jsonToSend.writeStartObject();
			jsonToSend.writeObjectField('SegmentCode', quotaRequestDetail.MarketSegment__c);
			jsonToSend.writeObjectField('FamilyId', quotaRequestDetail.Family__r?.ID_ERP__c);
			jsonToSend.writeObjectField('DateFrom', quotaRequestDetail.DateBegin__c);
			jsonToSend.writeObjectField('Quota_percent', quotaRequestDetail.Percent__c);
			jsonToSend.writeObjectField('Quota_add_t', quotaRequestDetail.AddQty_t__c);
			jsonToSend.writeObjectField('Quota_add_pcs', quotaRequestDetail.Add_Qty_pcs__c);

            if(quotaRequestDetail.Region__r?.ID_ERP__c != null) {
                jsonToSend.writeObjectField('RegionId', quotaRequestDetail.Region__r.ID_ERP__c);
            } else {
                jsonToSend.writeNullField('RegionId');
            }

            if(quotaRequestDetail.Manager__r?.ID_ERP__c != null) {
                jsonToSend.writeObjectField('SaleKdk', quotaRequestDetail.Manager__r.ID_ERP__c);
            } else {
                jsonToSend.writeNullField('SaleKdk');
            }

            if(quotaRequestDetail.Group3__r?.ID_ERP__c != null) {
                jsonToSend.writeObjectField('Grp3Id', quotaRequestDetail.Group3__r.ID_ERP__c);
            } else {
                jsonToSend.writeNullField('Grp3Id');
            }

			jsonToSend.writeEndObject();
		}

		jsonToSend.writeEndArray();

		System.debug('JSON to send - ' + jsonToSend.getAsString());

		return jsonToSend.getAsString();
	}
}