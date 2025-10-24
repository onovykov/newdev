public class SendAdjustmentQuotaCalloutJob implements Queueable, Database.AllowsCallouts {
    private String requestData;
    private List<QuoteRequestDetail__c> quotaRequestDetailList;

    public SendAdjustmentQuotaCalloutJob(String requestData, List<QuoteRequestDetail__c> quotaRequestDetailList) {
        this.requestData = requestData;
        this.quotaRequestDetailList = quotaRequestDetailList;
    }

    public void execute(QueueableContext context) {
        SFToERP.WebServiceSoap ERPhandler = new SFToERP.WebServiceSoap();
        String login = Credentials__c.getOrgDefaults().User_Login__c;
        String password = Credentials__c.getOrgDefaults().User_Password__c;

        Triton.instance.debug(TritonTypes.Type.RequestDebug, 
							  TritonTypes.Area.AdjustmentQuotaRequest,   
							  'Send Adjustment Quota Request',
							  requestData);

        try {
            String response = ERPhandler.LoginEx(login, password);
            ERPRequestParser.LoginResponse requestObject = (ERPRequestParser.LoginResponse) JSON.deserialize(response, ERPRequestParser.LoginResponse.class);
            String calc = '_SF_STRUCTQUOTAUPDATES';
            String ticket = requestObject.Ticket;

            String erpResult = ERPhandler.ExecuteEx(calc, requestData, ticket);
            String processed = erpResult.remove('\\').substring(1, erpResult.length() - 2);
            Triton.instance.debug(TritonTypes.Type.RequestDebug, TritonTypes.Area.AdjustmentQuotaRequest, 
                              'Send Adjustment Quota Response body', processed);
            ERPRequestParser.ExecuteResponceQuotaRequest idResponse = (ERPRequestParser.ExecuteResponceQuotaRequest) JSON.deserialize(processed, ERPRequestParser.ExecuteResponceQuotaRequest.class);

            if (!idResponse.Success) {
                Triton.instance.error(TritonTypes.Type.Backend, TritonTypes.Area.AdjustmentQuotaRequest,   
                                      'Send Adjustment Quota Request failed', idResponse.Comments);
            } else {
                Triton.instance.debug(TritonTypes.Type.RequestDebug, TritonTypes.Area.AdjustmentQuotaRequest, 
                                  'Send Adjustment Quota Response body', String.valueOf(idResponse));
            }
        } catch(CalloutException callfail) {
			Triton.instance.error(TritonTypes.Area.SendToBackoffice, callfail);
		} catch(System.JSONException jsfailed) {
			Triton.instance.error(TritonTypes.Area.SendToBackoffice, jsfailed);
		}

        updateQuoteStructureDetails(quotaRequestDetailList);
    }

    private static void updateQuoteStructureDetails(List<QuoteRequestDetail__c> quotaRequestDetailList) {
        List<QuoteStructureDetail__c> quotaStructDetailToInsertList = new List<QuoteStructureDetail__c>();
        List<QuoteStructureDetail__c> quotaStructDetailList = getQuotaStructDetailList(quotaRequestDetailList);
        Map<String, List<QuoteStructureDetail__c>> quotaStructDetailMap = new Map<String, List<QuoteStructureDetail__c>>();

        for(QuoteStructureDetail__c quotaStructDetail : quotaStructDetailList) {
            if(quotaStructDetailMap.get(quotaStructDetail.ID_ERP__c) == null) {
                quotaStructDetailMap.put(quotaStructDetail.ID_ERP__c, new List<QuoteStructureDetail__c>());
            }
            quotaStructDetailMap.get(quotaStructDetail.ID_ERP__c).add(quotaStructDetail);
        }

        for(QuoteRequestDetail__c quotaRequestDetail : quotaRequestDetailList) {
            List<QuoteStructureDetail__c> quotaStructDetails = quotaStructDetailMap.get(quotaRequestDetail.QuoteStructureDetail__r.ID_ERP__c);

            for(QuoteStructureDetail__c quotaStructDetail : quotaStructDetails) {
                QuoteStructureDetail__c quotaStructDetailToInsert = quotaStructDetail.clone(false, true, false, false);
                quotaStructDetailToInsert.AddQty_t__c = quotaRequestDetail.AddQty_t__c;
                quotaStructDetailToInsert.Quote_t__c = quotaRequestDetail.Quote_t__c;
                quotaStructDetailToInsert.Percent__c = quotaRequestDetail.Percent__c;
                quotaStructDetailToInsertList.add(quotaStructDetailToInsert);
    
                quotaStructDetail.Archived__c = true;
            }
        }

        insert quotaStructDetailToInsertList;
        update quotaStructDetailList;
    }

    private static List<QuoteStructureDetail__c> getQuotaStructDetailList(List<QuoteRequestDetail__c> quotaRequestDetailList) {
        Set<String> quoteStructDetailIdErpSet = new Set<String>();

        for(QuoteRequestDetail__c quotaRequestDetail : quotaRequestDetailList) {
            quoteStructDetailIdErpSet.add(quotaRequestDetail.QuoteStructureDetail__r.ID_ERP__c);
        }

        List<QuoteStructureDetail__c> quotaStructDetailList = [
            SELECT Add_Qty_pcs__c, AddQty_t__c, Budget_pcs__c, Budget_t__c, DateBegin__c, DateEnd__c, Family__c, FamilyType__c, Group3__c,
                   ID_ERP__c, Manager__c, Margin__c, MarketSegment__c, Percent__c, Quote_pcs__c, Quote_t__c, RouteQuote__c, QuoteStruct__c,
                   Region__c, Route__c, Name, RoutesQuotesH__c, RouteQuoteRelated__c
		    FROM QuoteStructureDetail__c 
            WHERE ID_ERP__c IN :quoteStructDetailIdErpSet AND Archived__c = false
        ];

        return quotaStructDetailList;
    }
}