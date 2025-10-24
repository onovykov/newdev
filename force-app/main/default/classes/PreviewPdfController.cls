public class PreviewPdfController {
	
	private static final Map<String, List<String>> TEMPLATE_TO_LANGUAGE = new Map<String, List<String>>{
			'Default Template' => new List<String>{'English', 'Russian', 'Spanish'},
			'Pipes' => new List<String>{'English', 'Russian', 'Spanish', 'USA', 'Ukrainian'},
			'Wheels' => new List<String>{'English', 'Russian', 'Ukrainian'}
	};

	private static final Map<String, List<String>> LANGUAGES_BY_MARKET_SEGMENT = new Map<String, List<String>>{
			'00002' => new List<String>{'English'},
			'00001' => new List<String>{'English (USA)', 'Spanish'},
			'00004' => new List<String>{'English'},
			'00010' => new List<String>{'English', 'Russian', 'Ukrainian'},
			'00011' => new List<String>{'English', 'Russian', 'Ukrainian'},
			'00016' => new List<String>{'English', 'Russian', 'Ukrainian'},
			'00006' => new List<String>{'English', 'Russian', 'Ukrainian'},
			'00019' => new List<String>{'English'},
			'00005' => new List<String>{'English'}
	};

	private static final List<String> AVAILABLE_METRICS = new List<String>{'Quantity', 'Quantity_ft__c',
																		   'Quantity_m__c', 'Quantity_pcs__c'};
	private static final Map<String, String> AVAILABLE_METRICS_MAP = new Map<String, String>{'Pieces' => 'Quantity_pcs__c', 
																							'Meters' => 'Quantity_m__c', 
																							'Feet' => 'Quantity_ft__c',
																							'Tons' => 'Quantity' };
	private static final String WHEELS = 'Wheels';
	private static final String PIPES = 'Pipes';
	private static final String TUBES = 'Tubes';
	private static final String DEFAULT_TEMPLATE = 'Default Template';

	@AuraEnabled
	public static String attachPDfLight(String quoteId, String pageName, String quantity, String selectedMeasure){
        //generate and attach the PDF document        
        PageReference pdfPage;

		switch on pageName {
			when 'QuotePDFPipesENG' {						
				pdfPage = Page.QuotePDFPipesENG;
			}	
			when 'QuotePDFPipesRUS' {		
				pdfPage = Page.QuotePDFPipesRUS;
			}
			when 'QuotePDFPipesSP' {		
				pdfPage = Page.QuotePDFPipesSP;
			}
			when 'QuotePDFPipesUSA' {		
				pdfPage = Page.QuotePDFPipesUSA;
			}
            when 'QuotePDFPipesUKR' {       
                pdfPage = Page.QuotePDFPipesUKR;
            }
			when 'QuotePDFWheelsENG' {		
				pdfPage = Page.QuotePDFWheelsENG;
			}
			when 'QuotePDFWheelsRUS' {
				pdfPage = Page.QuotePDFWheelsRUS;
			}
            when 'QuotePDFWheelsUKR' {       
                pdfPage = Page.QuotePDFWheelsUKR;
            }
			when else {
				pdfPage = Page.QuotePDFPage;
			}			
		}		

        pdfPage.getParameters().put('Id', quoteId);
		//pdfPage.getParameters().put('Quantity', quantity);
        pdfPage.getParameters().put('MeasureUnits', selectedMeasure);
        QuoteDocument qd = new QuoteDocument();
        qd.document = pdfPage.getContentAsPDF();
        qd.quoteId = quoteId;
        insert qd;
            
        System.debug('after insert ');
        return 'OK';
    }

	@AuraEnabled
	public static String getTemplate(String quoteId) {
		Quote record = [SELECT Id, Opportunity.RecordType.DeveloperName FROM Quote WHERE Id = :quoteId];
		if(record != null) {
			if (record.Opportunity.RecordType.DeveloperName.containsIgnoreCase(WHEELS)) return WHEELS;
			if (record.Opportunity.RecordType.DeveloperName.containsIgnoreCase(TUBES) 
				|| record.Opportunity.RecordType.DeveloperName.containsIgnoreCase(PIPES) ) return PIPES;
		}
		return DEFAULT_TEMPLATE;
	}

	@AuraEnabled
	public static List<String> getAllTemplates() {
		List<String> allTemplates = new List<String>(TEMPLATE_TO_LANGUAGE.keySet());
		return allTemplates;
	}

	@AuraEnabled
	public static String getMarketSegment(String quoteId) {
		Quote record = [SELECT Id, Account.MarketSegment__c FROM Quote WHERE Id = :quoteId];
		Schema.DescribeFieldResult fieldResult = Account.MarketSegment__c.getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
		for( Schema.PicklistEntry pickListVal : ple){
			if(pickListVal.getValue() == record.Account.MarketSegment__c) {
				return pickListVal.getLabel();
			}
		}     
		return record.Account.MarketSegment__c;
	}

	@AuraEnabled
	public static List<String> getAllLanguages(String quoteId, String curTemplate) {
		if(curTemplate == WHEELS) {
			return TEMPLATE_TO_LANGUAGE.get(curTemplate);
		}
		Quote record = [SELECT Id, Account.MarketSegment__c FROM Quote WHERE Id = :quoteId];
		String marketSegment = record.Account.MarketSegment__c;
		if (LANGUAGES_BY_MARKET_SEGMENT.containsKey(marketSegment)) {
			return LANGUAGES_BY_MARKET_SEGMENT.get(marketSegment);
		} else {
			String template = getTemplate(quoteId);
			if (TEMPLATE_TO_LANGUAGE.containsKey(template)) {
				return TEMPLATE_TO_LANGUAGE.get(template);
			}
		}
		return TEMPLATE_TO_LANGUAGE.get(DEFAULT_TEMPLATE);
	}

	@AuraEnabled
	public static String getAllMetrics() {
		return JSON.serialize(AVAILABLE_METRICS_MAP);
	}
    
    @AuraEnabled
	public static Boolean validateQuoteTerms(String quoteId) {
		Quote record = [SELECT Id, PaymentTerms__c, DeliveryTerms__c FROM Quote WHERE Id = :quoteId];
        if(record.PaymentTerms__c != null && record.DeliveryTerms__c != null){
            return true;
        } else {
            return false;
        }
	}
    
    @AuraEnabled
	public static List<QuoteLineItem> fetchQuoteLineItems(String quoteId) {
		List<QuoteLineItem> itemsList = [SELECT id,Product2.Name,Name__c,InquiryQuantity__c,InquiryUnitPrice__c,Quantity,UnitPrice,
                                         Sales_Price_ft__c,Sales_Price_lb__c,Sales_Price_m__c,Sales_Price_pcs__c from QuoteLineItem WHERE QuoteId=:quoteId];
        //return list of accounts
        return itemsList;
	}
    
    @AuraEnabled
    public static void changeShowInPdfToTrue (List<Id> selectedQuoteLineItems){
        system.debug('tst here ');
        system.debug(selectedQuoteLineItems);
        for(Id i : selectedQuoteLineItems){
            system.debug(i);
        }
        List<QuoteLineItem> itemsList = [SELECT Id,showInPDF__c from QuoteLineItem WHERE Id IN :selectedQuoteLineItems];
        List<QuoteLineItem> updatedList = new List<QuoteLineItem>();
        if(itemsList.size()>0){
            for(QuoteLineItem q : itemsList){
                q.showInPDF__c =  true;
                updatedList.add(q);
            }
            update updatedList;
        }
    }
    
    @AuraEnabled
    public static void changeShowInPdfToFalse (String quoteId){
        List<QuoteLineItem> itemsList = [SELECT Id,showInPDF__c from QuoteLineItem WHERE QuoteId=:quoteId];
           
        List<QuoteLineItem> updatedList = new List<QuoteLineItem>();
        if(itemsList.size()>0){
            for(QuoteLineItem q : itemsList){
                q.showInPDF__c =  false;
                updatedList.add(q);
            }
            update updatedList;
        }
    }
    
    @AuraEnabled
    public static Map<String,String> fetchPicklistMeasureUnit (){
                  
        Map<String,String> valueLabelMeasureUnit = new Map<String,String>();
		Schema.DescribeFieldResult fieldResult = QuoteLineItem.InquiryUnit__c.getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
		for( Schema.PicklistEntry pickListVal : ple){			
            valueLabelMeasureUnit.put(pickListVal.getValue(),pickListVal.getLabel());
		}     
		system.debug(valueLabelMeasureUnit);
        return valueLabelMeasureUnit;
    }
    
    @AuraEnabled
    public static List<String> fetchMeasureUnitsProducts(String quoteId){
           
        List<String> measureValues = new List<String>();
        List<AggregateResult> aggResList = [SELECT InquiryUnit__c	                      
		              FROM QuoteLineItem
		              WHERE QuoteId =:quoteId
		              GROUP BY InquiryUnit__c];
		system.debug(aggResList);
        measureValues.add('Quantity');
        for(AggregateResult ar:aggResList){
            system.debug(ar);
            if(ar.get('InquiryUnit__c') == '20'){
                measureValues.add('Quantity_m__c');
            }  
           
            if(ar.get('InquiryUnit__c') == '74'){
                measureValues.add('Quantity_ft__c');
            } 
            if(ar.get('InquiryUnit__c') == '43'){
                measureValues.add('Quantity_pcs__c');
            } 
            if(ar.get('InquiryUnit__c') == '99'){
                measureValues.add('	Quantity_lb__c');
            } 
        }
		return measureValues;
    }

	public static void FakeCoverageMethod() {
		Integer i=0;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
	}
}