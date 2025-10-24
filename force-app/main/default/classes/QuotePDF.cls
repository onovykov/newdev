public without sharing class QuotePDF {


	public final Quote quote;
	public User curUser { get; set; }
    public String curUserSignature {get; set; }
    public String curUserSignatureTitle {get; set; }
	public String userEmail {get; set; }
	public String tolerance {get; set; }
    public String quoteToleranceWeight {get; set; }
	public String quoteMarking {get; set; }
    public String quoteMarkingUkr {get; set; }
    public String quoteMarkingRus {get; set; }
	public String quotePacking {get; set; }
    public String quotePackingUkr {get; set; }
    public String quotePackingRus {get; set; }
    public String plasticCapsUkr {get; set; }
    public String plasticCapsRus {get; set; }
    public String productionDeliveryDetails {get; set; }

	public String quoteThirdPartyInspection {get; set; }
    public String quoteThirdPartyInspectionUkr {get; set; }
    public String quoteThirdPartyInspectionRus {get; set; }
	public String quotePaymentTermsNameFull {get; set; }
    public String quotePaymentTermsNameFullUkr {get; set; }
    public String additionalTermsUkr {get; set; }
    public String additionalTermsRus {get; set; }
    public String additionalTermsWheels {get; set; }
    public String additionalTermsWheelsUkr {get; set; }
    public String additionalTermsWheelsRus {get; set; }
    public String additionalMarkingOnDeliveryUkr {get; set; }
    public String additionalMarkingOnDeliveryRus {get; set; }
    public String additionalTermsOnDeliveryUkr {get; set; }
    public String additionalTermsOnDeliveryRus {get; set; }

	public String shippingMarks {get; set; }
	public Account acc { get; set; }
	public List<AggregateResult> aggResList { get; set; }
	public List<QuoteLineItem> oliList { get; set; }
	public Set<String> manufacturerAndOriginSet { get; set; }
    public Set<String> manufacturerAndOriginSetRus { get; set; }
    public Set<String> manufacturerAndOriginSetUkr { get; set; }
	public String manufacturerAndOrigin { get; set; }
    public String manufacturerAndOriginRus { get; set; }
    public String manufacturerAndOriginUkr { get; set; }
	public Boolean showNotForMT { get; set; }
	public Decimal quantitySum { get; set; }
	public String quantitySumAsString { get; set; }
	public Decimal quantityMTSum { get; set; }
	public String quantityMTSumAsString { get; set; }
	public Decimal totalPriceSum { get; set; }
	public String totalPriceSumAsString { get; set; }
	public Map<String, List<QuoteLineItem>> mapOLI { get; set; }
	public List<Map<String, String>> mapGroupsToMapAggregates { get; set; }
	public Map<String, Map<String, String>> oliIdToFormattedDataMap { get; set; }
	public Map<String, Map<String, Decimal>> mapGroupsToMapAggregatesDecimals { get; set; }
	public String sirName { get; set; }
	public String metricName { get; set; }
	public String metricNameRus { get; set; }
    public List<String> selectedMeasureUnits { get; set; }
    public Decimal quantityM { get; set; }
    public Decimal quantityLb { get; set; }
    public Decimal quantityFt { get; set; }
    public Decimal quantityT { get; set; }
    public Decimal quantityPcs { get; set; }
    public Map<String,Decimal> sumOfQuantityUnitsMap { get; set; }
    public List<QuoteLineItem> oliListAccessories { get; set; }
    public Boolean emptyAccessories { get; set; }
	public Map<String,Decimal> accessoriesSumMap { get; set; }
	public Decimal quantityAccessories { get; set; }
    
	private final Map<String, String> metricNamesMap = new Map<String, String>{'Quantity' => 'T',
																			'Quantity_ft__c' => 'ft',
																			'Quantity_m__c' => 'm', 
																			'Quantity_pcs__c' => 'pcs',
																			'Quantity_lb__c' => 'lb'};
	private final Map<String, String> metricNamesRusMap = new Map<String, String>{'Quantity' => 'т',
																			'Quantity_ft__c' => 'фут',
																			'Quantity_m__c' => 'м', 
																			'Quantity_pcs__c' => 'шт',
        																	'Quantity_lb__c' => 'фунт'};
	private final Map<Integer, String> monthRus = new Map<Integer, String>{ 1 => 'января',
																			2 => 'февраля',
																			3 => 'марта',
																			4 => 'апреля',
																			5 => 'мая',
																			6 => 'июня',
																			7 => 'июля',
																			8 => 'августа',
																			9 => 'сентября',
																			10 => 'октября',
																			11 => 'ноября',
																			12 => 'декабря' };
    private final Map<Integer, String> monthUkr = new Map<Integer, String>{ 1 => 'січня',
                                                                            2 => 'лютого',
                                                                            3 => 'березня',
                                                                            4 => 'квітня',
                                                                            5 => 'травня',
                                                                            6 => 'червня',
                                                                            7 => 'липня',
                                                                            8 => 'серпня',
                                                                            9 => 'вересня',
                                                                            10 => 'жовтня',
                                                                            11 => 'листопада',
                                                                            12 => 'грудня' };
	private final Map<String, String> quantitySumNamesMap = new Map<String, String>{'Quantity' => 'q',
																			'Quantity_ft__c' => 'quantityFt',
																			'Quantity_m__c' => 'quantityM', 
																			'Quantity_pcs__c' => 'quantityPcs',
																			'Quantity_lb__c' => 'quantityLb'};
    private final Map<String, String> selectedSalesPricePerUnitMap = new Map<String, String>{'Quantity' => 'UnitPrice',
																			'Quantity_ft__c' => 'Sales_Price_ft__c',
																			'Quantity_m__c' => 'Sales_Price_m__c', 
																			'Quantity_pcs__c' => 'Sales_Price_pcs__c',
																			'Quantity_lb__c' => 'Sales_Price_lb__c'};                                                                            

	public QuotePDF(ApexPages.StandardController stdController) {
		if(!ApexPages.currentPage().getParameters().containsKey('Quantity')) {
			ApexPages.currentPage().getParameters().put('Quantity','Quantity');
		}
		System.debug('hi ' + ((Quote) stdController.getRecord()).Id);
        
		this.quote = [SELECT Id, Name, Opportunity.Owner.Name, Opportunity.Owner.Title, Opportunity.CurrencyISOCode, AccountId, 
                      OpportunityId, Opportunity.AccountId, QuoteNumber, OwnerId, Phone, Additional_Terms__c, Additional_Terms_Ukr__c, Additional_Terms_Rus__c, 
                      Additional_Terms_Wheels_Ukr__c, Additional_Terms_Wheels_Rus__c, Country_of_Origin__c, Marking__c, Marking_Ukr__c, Marking_Rus__c, 
                      Packing__c, Packing_Ukr__c, Packing_Rus__c, Plastic_Caps_Ukr__c, Plastic_Caps_Rus__c, Special_Shipping_Requirements__c, 
                      PaymentTerms__r.NameFull__c, PaymentTerms__r.Full_Name_Ukr__c, PaymentTerms__r.NameFullRus__c, DeliveryTerms__r.Name, 
                      DeliveryTerms__r.NameUkr__c, DeliveryTerms__r.NameRus__c, ShippingMarks__c, ExpirationDate, Description, Contact.Name, 
                      Protection__c, Additional_Marking_On_Delivery_Ukr__c, Additional_Marking_On_Delivery_Rus__c, Additional_Terms_On_Delivery_Ukr__c, 
                      Additional_Terms_On_Delivery_Rus__c, Third_party_Inspection__c, Third_Party_Inspection_Ukr__c, Third_Party_Inspection_Rus__c, 
                      Tolerance__c, Production_Delivery__c, Interpipe_Bank_Details__c, Invoicing__c, HeaderText__c, Additional_Terms_Wheels__c, Production_Delivery_Details__c 
                      FROM Quote 
                      WHERE Id = :((Quote) stdController.getRecord()).Id];

		acc = [SELECT Id, Name, BillingStreet, BillingCity, BillingCountry, BillingPostalCode, BillingState 
               FROM Account 
               WHERE Id = :quote.Opportunity.AccountId];

		aggResList = [SELECT Product2.Type__c, ProductStandard__c, ProductSpecLevel__c, ShippingPoint__c 
                      /*, SUM(InquiryQuantity__c) inqQ, SUM(Quantity) q, SUM(InquiryUnitPrice__c) inqUnitPrice, 
						SUM(UnitPrice) unitPrice, SUM(TotalPrice) totalPrice */
		              FROM QuoteLineItem
		              WHERE QuoteId = :quote.Id AND showInPDF__c=TRUE AND Product2.Is_Accessory__c=false
		              GROUP BY Product2.Type__c, ProductStandard__c, ProductSpecLevel__c, ShippingPoint__c];

		oliList = [SELECT Product2.Type__c, ProductStandard__c, ProductStandard__r.Name, ProductSpecLevel__c, ProductSpecLevel__r.Name, ShippingPoint__c,
		           ShippingPoint__r.Name, ShippingPoint__r.Country__r.Name, Product2.Name, Product2.Family, TubeOD__r.OD_inch__c, Weight_ppf__c, 
                   Weight_kpm__c, TubeOD__r.OD_mm__c, TubeWT__r.WT_mm__c, TubeWT__r.WT_inch__c, SteelGrade__r.ShortName__c,
		           TubeEnds__r.ShortName__c, TubeLengthSize__r.ShortName__c, Quantity, Quantity_ft__c, Quantity_m__c, Quantity_pcs__c, 
                   InquiryQuantity__c, Shop__c, Shop__r.Plant__r.FullName__c, Shop__r.Plant__r.FullName_Rus__c, Shop__r.Plant__r.FullName_Ukr__c,
                   InquiryUnit__c, Quote.DeliveryTerms__r.Incoterms__c, InquiryUnitPrice__c, UnitPrice, TotalPrice, Quote.DeliveryTerms__r.Name,Quantity_lb__c,
                   Sales_Price_m__c,Sales_Price_pcs__c,Sales_Price_lb__c,Sales_Price_ft__c
		           FROM QuoteLineItem WHERE QuoteId = :quote.Id AND showInPDF__c=TRUE AND Product2.Is_Accessory__c=false];
        
        oliListAccessories = [SELECT Product2.Type__c, ProductStandard__c, ProductStandard__r.Name, ProductSpecLevel__c, ProductSpecLevel__r.Name, ShippingPoint__c,
		           ShippingPoint__r.Name, ShippingPoint__r.Country__r.Name, Product2.Name, Product2.Family, TubeOD__r.OD_inch__c, Weight_ppf__c, 
                   Weight_kpm__c, TubeOD__r.OD_mm__c, TubeWT__r.WT_mm__c, TubeWT__r.WT_inch__c, SteelGrade__r.ShortName__c,
		           TubeEnds__r.ShortName__c, TubeLengthSize__r.ShortName__c, Quantity, Quantity_ft__c, Quantity_m__c, Quantity_pcs__c, 
                   InquiryQuantity__c, Shop__c, Shop__r.Plant__r.FullName__c, Shop__r.Plant__r.FullName_Rus__c, Shop__r.Plant__r.FullName_Ukr__c,
                   InquiryUnit__c, Quote.DeliveryTerms__r.Incoterms__c, InquiryUnitPrice__c, UnitPrice, TotalPrice, Quote.DeliveryTerms__r.Name
		           FROM QuoteLineItem WHERE QuoteId = :quote.Id AND showInPDF__c=TRUE AND Product2.Is_Accessory__c=true];
        
        if(oliListAccessories.size()>1){
            emptyAccessories = true;
        } else {
            emptyAccessories = false;
        }
		
		curUser = [SELECT Name, Phone, Full_Name_Rus__c, Full_Name_Ukr__c FROM User WHERE Id = :UserInfo.getUserId()];
		userEmail = UserInfo.getUserEmail();
        
        List<ContentDocumentLink> quoteOwnerSignatureList = [SELECT ContentDocument.LatestPublishedVersionId, ContentDocument.Title 
                                                   			FROM ContentDocumentLink 
                                                   			WHERE LinkedEntityId = :quote.OwnerId
                                                   			AND ContentDocumentId IN (SELECT ContentDocumentId FROM ContentVersion WHERE isSignature__c = true)
                                                        	ORDER BY ContentDocument.CreatedDate DESC LIMIT 1];
        
        if(!quoteOwnerSignatureList.isEmpty()){
            ContentDocumentLink quoteOwnerSignature = quoteOwnerSignatureList.get(0);
            curUserSignature = quoteOwnerSignature.ContentDocument.LatestPublishedVersionId;
        	curUserSignatureTitle = quoteOwnerSignature.ContentDocument.Title;
		}
        
        System.debug(curUser);
		System.debug(oliList.size());
        System.debug(oliListAccessories.size());
        System.debug(oliListAccessories.isEmpty());
		System.debug(quote.id);
        
        String unitValues = ApexPages.currentPage().getParameters().get('MeasureUnits');
        if(unitValues!=null){
           selectedMeasureUnits = unitValues.split(',');                           
        }
        system.debug(selectedMeasureUnits);
		
        if (!oliList.isEmpty()) {
			groupOLI();
			getManufacturerOriginString();
            getManufacturerOriginStringRus();
            getManufacturerOriginStringUkr();

			showNotForMT = (oliList[0].InquiryUnit__c == '34') ? false : true;

			countSums();
		}

		if (!oliListAccessories.isEmpty()){
			sumOliAccessories();
		}

		Set<String> standardSet = new Set<String>();
		for(QuoteLineItem qli : oliList) {
			String standard = qli.ProductStandard__r.Name;
			if(standard != null) {
				standardSet.add(standard);
			}
		}
		
        for(String standard: standardSet) {
			if(tolerance == null) {
				tolerance = standard;
			} else {
				tolerance += ', ' + standard;
			}
		}

		if(quote.ShippingMarks__c != null) {
			shippingMarks = quote.ShippingMarks__c.stripHtmlTags();
		}
		if(quote.Marking__c != null) {
			quoteMarking = quote.Marking__c.stripHtmlTags();
		}
        if(quote.Marking_Ukr__c != null) {
			quoteMarkingUkr = quote.Marking_Ukr__c.stripHtmlTags();
		}
        if(quote.Marking_Rus__c != null) {
			quoteMarkingRus = quote.Marking_Rus__c.stripHtmlTags();
		}
		if(quote.Packing__c != null) {
			quotePacking = quote.Packing__c.stripHtmlTags();
		}
        if(quote.Packing_Ukr__c != null) {
			quotePackingUkr = quote.Packing_Ukr__c.stripHtmlTags();
		}
        if(quote.Packing_Rus__c != null) {
			quotePackingRus = quote.Packing_Rus__c.stripHtmlTags();
		}
        if(quote.Plastic_Caps_Ukr__c != null) {
			plasticCapsUkr = quote.Plastic_Caps_Ukr__c.stripHtmlTags();
		}
        if(quote.Plastic_Caps_Rus__c != null) {
			plasticCapsRus = quote.Plastic_Caps_Rus__c.stripHtmlTags();
		}
        if(quote.Production_Delivery_Details__c != null) {
			productionDeliveryDetails = quote.Production_Delivery_Details__c.stripHtmlTags();
		}
		if(quote.Third_Party_Inspection__c != null) {
			quoteThirdPartyInspection = quote.Third_Party_Inspection__c.stripHtmlTags();
		}
        if(quote.Third_Party_Inspection_Ukr__c != null) {
			quoteThirdPartyInspectionUkr = quote.Third_Party_Inspection_Ukr__c.stripHtmlTags();
		}
        if(quote.Third_Party_Inspection_Rus__c != null) {
			quoteThirdPartyInspectionRus = quote.Third_Party_Inspection_Rus__c.stripHtmlTags();
		}
        if(quote.Tolerance__c != null) {
			quoteToleranceWeight = quote.Tolerance__c.stripHtmlTags();
		}
        if(quote.Additional_Terms_Wheels__c != null) {
			additionalTermsWheels = quote.Additional_Terms_Wheels__c;
		}
        if(quote.Additional_Terms_Wheels_Ukr__c != null) {
			additionalTermsWheelsUkr = quote.Additional_Terms_Wheels_Ukr__c;
		}
        if(quote.Additional_Terms_Wheels_Rus__c != null) {
			additionalTermsWheelsRus = quote.Additional_Terms_Wheels_Rus__c;
		}
        if(quote.Additional_Terms_Ukr__c != null) {
			additionalTermsUkr = quote.Additional_Terms_Ukr__c;
		}
        if(quote.Additional_Terms_Rus__c != null) {
			additionalTermsRus = quote.Additional_Terms_Rus__c;
		}
		if(quote.PaymentTerms__r.NameFull__c != null) {
			quotePaymentTermsNameFull = quote.PaymentTerms__r.NameFull__c.stripHtmlTags();
		}
        if(quote.PaymentTerms__r.Full_Name_Ukr__c != null) {
			quotePaymentTermsNameFullUkr = quote.PaymentTerms__r.Full_Name_Ukr__c.stripHtmlTags();
		}
        if(quote.Additional_Marking_On_Delivery_Ukr__c != null) {
			additionalMarkingOnDeliveryUkr = quote.Additional_Marking_On_Delivery_Ukr__c.stripHtmlTags();
		}
        if(quote.Additional_Marking_On_Delivery_Rus__c != null) {
			additionalMarkingOnDeliveryRus = quote.Additional_Marking_On_Delivery_Rus__c.stripHtmlTags();
		}
        if(quote.Additional_Terms_On_Delivery_Ukr__c != null) {
			additionalTermsOnDeliveryUkr = quote.Additional_Terms_On_Delivery_Ukr__c.stripHtmlTags();
		}
        if(quote.Additional_Terms_On_Delivery_Rus__c != null) {
			additionalTermsOnDeliveryRus = quote.Additional_Terms_On_Delivery_Rus__c.stripHtmlTags();
		}

		
		metricName = metricNamesMap.get(ApexPages.currentPage().getParameters().get('Quantity'));
		metricNameRus = metricNamesRusMap.get(ApexPages.currentPage().getParameters().get('Quantity'));
		if(this.quote.Contact.Name != null) {
			sirName = this.quote.Contact.Name;
		} else sirName = '';
        
        
	}

	public String getDynamicFormatString(String input) {
		String result = input;
		integer index = result.indexOf('.');
		for (integer i = index - 1; i >= 0; i--) {
			if (Math.mod(index - i, 3) == 0) {
				result = result.substring(0, i) + ' ' + result.substring(i, result.length());
			}
		}
		return result;
	}
	
    
	public List<List<QuoteLineItem>> getListOpps() {
		if(mapOLI.values().isEmpty()){
			return null ;
		}
		return mapOLI.values();

	}

	public List<Boolean> getShowLB_FTForTables() {
		List<Boolean> showLB_FTList = new List<Boolean> ();
		for (List<QuoteLineItem> listQuotes : mapOLI.values()) {
			Boolean showLB_FT = false;
			for (QuoteLineItem qli : listQuotes) {
				if (qli.Product2.Family == 'OCTG') {
					showLB_FT = true;
				}
			}
			showLB_FTList.add(showLB_FT);
		}
		return showLB_FTList;
	}

	public List<Boolean> getShowWTForTables() {
		List<Boolean> showWTList = new List<Boolean> ();
		for (List<QuoteLineItem> listQuotes : mapOLI.values()) {
			Boolean showWT = false;
			for (QuoteLineItem qli : listQuotes) {
				if (qli.Product2.Family != 'OCTG') {
					showWT = true;
				}
			}
			showWTList.add(showWT);
		}
		return showWTList;
	}

	public List<String> getGroupKeys() {
		if(mapOLI == null) { 
			mapOLI =  new Map<String, List<QuoteLineItem>> ();
		}
		return new List<String>(mapOLI.keySet());
	}

	private void getManufacturerOriginString() {
		manufacturerAndOriginSet = new Set<String> ();
		manufacturerAndOrigin = '';
		for (QuoteLineItem oli : oliList) {
			manufacturerAndOriginSet.add(oli.Shop__r.Plant__r.FullName__c);
		}
		manufacturerAndOrigin = composeManufacturer(manufacturerAndOriginSet);
	}
    
    private void getManufacturerOriginStringRus() {
        manufacturerAndOriginSetRus = new Set<String> ();
        manufacturerAndOriginRus = '';
        for (QuoteLineItem oli : oliList) {
			manufacturerAndOriginSetRus.add(oli.Shop__r.Plant__r.FullName_Rus__c);
		}
		manufacturerAndOriginRus = composeManufacturer(manufacturerAndOriginSetRus);
    }
    
    private void getManufacturerOriginStringUkr() {
        manufacturerAndOriginSetUkr = new Set<String> ();
        manufacturerAndOriginUkr = '';
        for (QuoteLineItem oli : oliList) {
			manufacturerAndOriginSetUkr.add(oli.Shop__r.Plant__r.FullName_Ukr__c);
		}
		manufacturerAndOriginUkr = composeManufacturer(manufacturerAndOriginSetUkr);
    }
    
    private String composeManufacturer(Set<String> manufacturerAndOriginSet) {
        String manufacturer = '';
        List<String> manufacturerAndOriginList = new List<String> (manufacturerAndOriginSet);
		for (Integer i = 0; i<manufacturerAndOriginList.size(); i++) {
			if (manufacturerAndOriginList[i] != null) {
				if (i<(manufacturerAndOriginList.size() - 1)) {
					manufacturer += manufacturerAndOriginList[i];
					manufacturer += ', ';
				} else {
					manufacturer += manufacturerAndOriginList[i];
				}
			}
		}
        return manufacturer;
    }

	private void countSums() {
		quantitySum = 0;
		quantityMTSum = 0;
		totalPriceSum = 0;
        quantityM = 0;
        quantityLb = 0;
        quantityFt = 0;
        quantityT = 0;
        quantityPcs = 0;
        quantityAccessories = 0;

        sumOfQuantityUnitsMap = new Map<String,Decimal>();
        
		for (QuoteLineItem oli : oliList) {
			quantitySum += (oli.InquiryQuantity__c != null) ? oli.InquiryQuantity__c : 0;
			if(ApexPages.currentPage().getParameters().containsKey('Quantity')) {
				String quantityField = ApexPages.currentPage().getParameters().get('Quantity');
				quantityMTSum += (oli.get(quantityField) != null) ? (Decimal)oli.get(quantityField) : 0;
			} else quantityMTSum += (oli.Quantity != null) ? oli.Quantity : 0;
			system.debug(selectedMeasureUnits);
            if(selectedMeasureUnits != null){ 
            if(selectedMeasureUnits.contains('Quantity_m__c')){
                quantityM+=(oli.Quantity_m__c!= null) ?oli.Quantity_m__c:0 ;
                sumOfQuantityUnitsMap.put('Quantity_m__c',quantityM);
            }
            if(selectedMeasureUnits.contains('Quantity_ft__c')){
                quantityFt+=(oli.Quantity_ft__c!= null) ?oli.Quantity_ft__c:0 ;
                sumOfQuantityUnitsMap.put('Quantity_ft__c',quantityFt);
            }
            if(selectedMeasureUnits.contains('Quantity')){
                quantityT+=(oli.Quantity!= null) ?oli.Quantity:0 ;
                sumOfQuantityUnitsMap.put('Quantity',quantityT);
            }
            if(selectedMeasureUnits.contains('Quantity_lb__c')){
                quantityLb+=(oli.Quantity_lb__c!= null) ?oli.Quantity_lb__c:0 ;
                sumOfQuantityUnitsMap.put('Quantity_lb__c',quantityLb);
            }
            if(selectedMeasureUnits.contains('Quantity_pcs__c')){
                quantityPcs+=(oli.Quantity_pcs__c!= null) ?oli.Quantity_pcs__c:0 ;
                sumOfQuantityUnitsMap.put('Quantity_pcs__c',quantityPcs);
            }}
			
			totalPriceSum += (oli.TotalPrice != null) ? oli.TotalPrice : 0;
		}
		if(!oliListAccessories.isEmpty()){
			for(QuoteLineItem qli:oliListAccessories){
				totalPriceSum += (qli.TotalPrice != null) ? qli.TotalPrice : 0;
				quantityAccessories += (qli.InquiryQuantity__c != null) ? qli.InquiryQuantity__c : 0;
			}
		}
		quantitySum = Decimal.valueOf(formatedDecimalToOneSign(quantitySum));
		quantityMTSum = Decimal.valueOf(formatedDecimalToOneSign(quantityMTSum));
		totalPriceSum = Decimal.valueOf(formatedDecimalToOneSign(totalPriceSum));
		quantitySumAsString = getDynamicFormatString(formatedDecimalToOneSign(quantitySum));
		quantityMTSumAsString = getDynamicFormatString(formatedDecimalToOneSign(quantityMTSum));
		totalPriceSumAsString = getDynamicFormatString(formatedDecimalToOneSign(totalPriceSum));
        system.debug(quantityM);
	}

	public void groupOLI() {
		mapOLI = new Map<String, List<QuoteLineItem>> ();
		mapGroupsToMapAggregates = new List<Map<String, String>> ();
		mapGroupsToMapAggregatesDecimals = new Map<String, Map<String, Decimal>> ();
		oliIdToFormattedDataMap = new Map<String, Map<String, String>> ();
		for (AggregateResult ar : aggResList) {
			String st = '';
			st += ar.get('Type__c');
			st += ar.get('ProductStandard__c');
			st += ar.get('ProductSpecLevel__c');
			st += ar.get('ShippingPoint__c');
			mapOLI.put(st, new List<QuoteLineItem> ());
			System.debug(st);
			Map<String, Decimal> innerMap = new Map<String, Decimal> ();
			innerMap.put('q', 0.0); innerMap.put('totalPrice', 0.0); innerMap.put('unitPrice', 0.0); innerMap.put('inqUnitPrice', 0.0); innerMap.put('inqQ', 0.0); innerMap.put('quantityM', 0.0);
			innerMap.put('quantityFt', 0.0);innerMap.put('quantityLb', 0.0);innerMap.put('quantityPcs', 0.0);
			//innerMap.put('q',            getDynamicFormatString(formatedDecimal((Decimal)ar.get('q'))));
			//innerMap.put('totalPrice',   getDynamicFormatString(formatedDecimal((Decimal)ar.get('totalPrice'))));
			//innerMap.put('unitPrice',    getDynamicFormatString(formatedDecimal((Decimal)ar.get('unitPrice'))));
			//innerMap.put('inqUnitPrice', getDynamicFormatString(formatedDecimal((Decimal)ar.get('inqUnitPrice'))));
			//innerMap.put('inqQ', formatedDecimal((Decimal)ar.get('inqQ')));
			mapGroupsToMapAggregatesDecimals.put(st, innerMap);
		}
		for (QuoteLineItem oli : oliList) {
			oliIdToFormattedDataMap.put(oli.Id, formatAllNumberFields(oli.getPopulatedFieldsAsMap()));
			String strForOLI = '';
			strForOLI += oli.Product2.Type__c;
			strForOLI += oli.ProductStandard__c;
			strForOLI += oli.ProductSpecLevel__c;
			strForOLI += oli.ShippingPoint__c;

			for (String key : mapOLI.keySet()) {
				if (key == strForOLI) {
					String quantityField = 'Quantity';
                    system.debug(ApexPages.currentPage().getParameters().get('MeasureUnits'));
                    
					if(ApexPages.currentPage().getParameters().containsKey('Quantity')) {
						quantityField = ApexPages.currentPage().getParameters().get('Quantity');
					}					
					System.debug(oli.InquiryQuantity__c + ' ' + oli.TotalPrice + ' ' + oli.UnitPrice + ' ' + oli.InquiryUnitPrice__c + ' ' + oli.get(quantityField));
					mapGroupsToMapAggregatesDecimals.get(key).put('q', mapGroupsToMapAggregatesDecimals.get(key).get('q') + (Decimal)oli.get(quantityField));
					mapGroupsToMapAggregatesDecimals.get(key).put('inqUnitPrice', mapGroupsToMapAggregatesDecimals.get(key).get('inqUnitPrice') + (oli.InquiryUnitPrice__c == null ? 0.0 : oli.InquiryUnitPrice__c));
					mapGroupsToMapAggregatesDecimals.get(key).put('unitPrice', mapGroupsToMapAggregatesDecimals.get(key).get('unitPrice') + (oli.UnitPrice == null ? 0.0 : oli.UnitPrice));
					mapGroupsToMapAggregatesDecimals.get(key).put('totalPrice', mapGroupsToMapAggregatesDecimals.get(key).get('totalPrice') + (oli.TotalPrice == null ? 0.0 : oli.TotalPrice));
					mapGroupsToMapAggregatesDecimals.get(key).put('inqQ', mapGroupsToMapAggregatesDecimals.get(key).get('inqQ') + (oli.InquiryQuantity__c == null ? 0.0 : oli.InquiryQuantity__c));
					mapGroupsToMapAggregatesDecimals.get(key).put('quantityM', mapGroupsToMapAggregatesDecimals.get(key).get('quantityM') + (oli.Quantity_m__c == null ? 0.0 : oli.Quantity_m__c));
					mapGroupsToMapAggregatesDecimals.get(key).put('quantityFt', mapGroupsToMapAggregatesDecimals.get(key).get('quantityFt') + (oli.Quantity_ft__c == null ? 0.0 : oli.Quantity_ft__c));
					mapGroupsToMapAggregatesDecimals.get(key).put('quantityLb', mapGroupsToMapAggregatesDecimals.get(key).get('quantityLb') + (oli.Quantity_lb__c == null ? 0.0 : oli.Quantity_lb__c));
					mapGroupsToMapAggregatesDecimals.get(key).put('quantityPcs', mapGroupsToMapAggregatesDecimals.get(key).get('quantityPcs') + (oli.Quantity_pcs__c == null ? 0.0 : oli.Quantity_pcs__c));
					oli.Quantity = Decimal.valueOf(formatedDecimalToOneSign(oli.Quantity));
					oli.Quantity_ft__c = Decimal.valueOf(formatedDecimalToOneSign(oli.Quantity_ft__c));
					oli.Quantity_m__c = Decimal.valueOf(formatedDecimalToOneSign(oli.Quantity_m__c));
					oli.Quantity_pcs__c = Decimal.valueOf(formatedDecimalToOneSign(oli.Quantity_pcs__c));
					oli.UnitPrice = Decimal.valueOf(formatedDecimalToTwoSigns(oli.UnitPrice));
					oli.InquiryUnitPrice__c = Decimal.valueOf(formatedDecimalToTwoSigns(oli.InquiryUnitPrice__c));
					if (oli.TubeOD__c != null && oli.TubeOD__r.OD_mm__c != null) {
						oli.TubeOD__r.OD_mm__c = oli.TubeOD__r.OD_mm__c.setScale(1);
					}
					if (oli.TubeWT__c != null && oli.TubeWT__r.WT_mm__c != null) {
						oli.TubeWT__r.WT_mm__c = oli.TubeWT__r.WT_mm__c.setScale(2);
					}
					//oliIdToFormattedDataMap.put(oli.Id, getDynamicFormatString(formatedDecimal(oli.TotalPrice)));
					//oli.put('TotalPrice', formatedDecimal(oli.TotalPrice));
					mapOLI.get(key).add(oli);
				}
			}
		}
		for (String key : mapGroupsToMapAggregatesDecimals.keySet()) {
			Map<String, String> innerMap = new Map<String, String> ();
			innerMap.put('q', getDynamicFormatString(formatedDecimalToOneSign((Decimal) mapGroupsToMapAggregatesDecimals.get(key).get('q'))));
			innerMap.put('totalPrice', getDynamicFormatString(formatedDecimalToOneSign((Decimal) mapGroupsToMapAggregatesDecimals.get(key).get('totalPrice'))));
			innerMap.put('unitPrice', getDynamicFormatString(formatedDecimalToTwoSigns((Decimal) mapGroupsToMapAggregatesDecimals.get(key).get('unitPrice'))));
			innerMap.put('inqUnitPrice', getDynamicFormatString(formatedDecimalToTwoSigns((Decimal) mapGroupsToMapAggregatesDecimals.get(key).get('inqUnitPrice'))));
			innerMap.put('inqQ', getDynamicFormatString(formatedDecimalToOneSign((Decimal) mapGroupsToMapAggregatesDecimals.get(key).get('inqQ'))));
			innerMap.put('quantityM', getDynamicFormatString(formatedDecimalToOneSign((Decimal) mapGroupsToMapAggregatesDecimals.get(key).get('quantityM'))));
			innerMap.put('quantityFt', getDynamicFormatString(formatedDecimalToOneSign((Decimal) mapGroupsToMapAggregatesDecimals.get(key).get('quantityFt'))));
			innerMap.put('quantityLb', getDynamicFormatString(formatedDecimalToOneSign((Decimal) mapGroupsToMapAggregatesDecimals.get(key).get('quantityLb'))));
			innerMap.put('quantityPcs', getDynamicFormatString(formatedDecimalToOneSign((Decimal) mapGroupsToMapAggregatesDecimals.get(key).get('quantityPcs'))));
			mapGroupsToMapAggregates.add(innerMap);
		}
	}

	public void sumOliAccessories(){
		Map<String,Decimal> sumAccessoriesValues = new Map<String,Decimal>();
		sumAccessoriesValues.put('quantityPcs',0.0);
		sumAccessoriesValues.put('sumPricePcs',0.0);

		for(QuoteLineItem qli : oliListAccessories){
			sumAccessoriesValues.put('quantityPcs',sumAccessoriesValues.get('quantityPcs') + (qli.InquiryQuantity__c == null ? 0.0 : qli.InquiryQuantity__c));
			sumAccessoriesValues.put('sumPricePcs',sumAccessoriesValues.get('sumPricePcs') + (qli.TotalPrice  == null ? 0.0 : qli.TotalPrice));
		}

		accessoriesSumMap = sumAccessoriesValues;
	}

	public Map<String, String> formatAllNumberFields(Map<String, Object> populatedMap) {
		Map<String, String> result = new Map<String, String> ();
		result.put('InquiryUnitPrice__c', '0.000');
		result.put('InquiryQuantity__c', '0.000');
		for (String key : populatedMap.keySet()) {
			if (key == 'InquiryUnitPrice__c') {
				result.put('InquiryUnitPrice__c', getDynamicFormatString(formatedDecimalToTwoSigns((Decimal) (populatedMap.get('InquiryUnitPrice__c') == null ? 0.0 : populatedMap.get('InquiryUnitPrice__c')))));
			} else if (key == 'InquiryQuantity__c') {
				result.put('InquiryQuantity__c', getDynamicFormatString(formatedDecimalToOneSign((Decimal) (populatedMap.get('InquiryQuantity__c') == null ? 0.0 : populatedMap.get('InquiryQuantity__c')))));
			} else if (populatedMap.get(key) instanceof Decimal) {
				result.put(key, getDynamicFormatString(formatedDecimalToOneSign((Decimal) populatedMap.get(key))));
			}
		}

		return result;
	}

	public Integer getNumPdfs() {
		return[SELECT Id FROM QuoteDocument WHERE QuoteId = : quote.Id].size() + 1;
	}

	public String getAccountAddress() {
		String result = '';
		result += (String.isBlank(acc.BillingStreet) ? '' : acc.BillingStreet + ', ');
		result += (String.isBlank(acc.BillingCity) ? '' : acc.BillingCity + ', ');
		result += (String.isBlank(acc.BillingState) ? '' : acc.BillingState + ', ');
		result += (String.isBlank(acc.BillingPostalCode) ? '' : acc.BillingPostalCode + ', ');
		result += (String.isBlank(acc.BillingCountry) ? '' : acc.BillingCountry);

		return result;
	}

	public Map<String, String> getApinameToLabelMap() {
		Map<String, String> labelToApinameMap = ApexUtil.getPicklistFieldMap('QuoteLineItem', 'InquiryUnit__c');
		Map<String, String> result = new Map<String, String> ();
		for (String label : labelToApinameMap.keySet()) {
			result.put(labelToApinameMap.get(label), label);
		}
		result.put(null, '-');
		return result;
	}

	public String formatedDecimalToOneSign(Decimal num) {
		if (num != null) {
			return String.valueOf(num.setScale(1, System.RoundingMode.HALF_UP));
		} else {
			return '0.000';
		}
	}

	public String formatedDecimalToTwoSigns(Decimal num) {
		if (num != null) {
			return String.valueOf(num.setScale(2, System.RoundingMode.HALF_UP));
		} else {
			return '0.000';
		}
	}

	public String getBankDetails() {
		List<Bank_Details__mdt> banks = [SELECT Id, Details__c FROM Bank_Details__mdt];
		Map<String, String> apiNameToMergeLabel = new Map<String, String> ();
		String quoteId = quote.Id;

		String str = '';
		if (banks[0].Details__c != null) {

			str = String.valueOf(banks[0].Details__c);
		}

		return str;
	}

	public String getMetadataRecordName() {
		List<Bank_Details__mdt> banks = [SELECT Id, Label FROM Bank_Details__mdt];

		String str = '';
		if (banks.size()> 0) {
			str = String.valueOf(banks[0].Label);
		}

		return str;
	}

	public String getOwnerName() {
		String ownerName = quote.Opportunity.Owner.Name;
		return ownerName;
	}

	public String getOwnerPosition() {
		String ownerPosition = quote.Opportunity.Owner.Title;
		return ownerPosition;
	}

	public String getExpirationDate() {
		if (quote.ExpirationDate != null) {
			Date expirationDate = quote.ExpirationDate;
            String expirationDateDay = String.valueOf(expirationDate.day());
            String expirationDateMonth = String.valueOf(expirationDate.month());
            
            expirationDateDay = setLeadingZeros(expirationDate.day(), expirationDateDay);
            expirationDateMonth = setLeadingZeros(expirationDate.month(), expirationDateMonth);
            
            String expirationDateToString = expirationDateMonth + '/' + expirationDateDay + '/' + expirationDate.year();
			return expirationDateToString;
		}
		return '';
	}
    
    public String getExpirationDateCIS() {
		if (quote.ExpirationDate != null) {
            Date expirationDate = quote.ExpirationDate;
            String expirationDateDay = String.valueOf(expirationDate.day());
            String expirationDateMonth = String.valueOf(expirationDate.month());
            
            expirationDateDay = setLeadingZeros(expirationDate.day(), expirationDateDay);
            expirationDateMonth = setLeadingZeros(expirationDate.month(), expirationDateMonth);
            
            String expirationDateToString = expirationDateDay + '.' + expirationDateMonth + '.' + expirationDate.year();
			return expirationDateToString;
		}
		return '';
	}
    
    public String getProductionDeliveryDateCIS() {
        String productionDeliveryDateToString = '';
		if (quote.Production_Delivery__c != null) {
            String userLocale = UserInfo.getLocale();
            
            if(userLocale == 'en_US'){
                Date productionDeliveryDate = Date.parse(quote.Production_Delivery__c);
                String productionDeliveryDateDay = String.valueOf(productionDeliveryDate.day());
            	String productionDeliveryDateMonth = String.valueOf(productionDeliveryDate.month());
                productionDeliveryDateDay = setLeadingZeros(productionDeliveryDate.day(), productionDeliveryDateDay);
            	productionDeliveryDateMonth = setLeadingZeros(productionDeliveryDate.month(), productionDeliveryDateMonth);
            
            	productionDeliveryDateToString = productionDeliveryDateDay + '.' + productionDeliveryDateMonth + '.' + productionDeliveryDate.year();
				return productionDeliveryDateToString;
                
            } 
            return quote.Production_Delivery__c; 
        }
        return productionDeliveryDateToString;
	}
    
    public String setLeadingZeros (Integer expDatesInteger, String expDatesString) {
        String checkedDatesString = '';
        if(expDatesInteger < 10){
                checkedDatesString = '0' + expDatesString;
        } else {
            checkedDatesString = expDatesString;
        }
        return checkedDatesString;
    }
    
	public String getExpirationDateDays() {
		if (quote.ExpirationDate != null) {
			return String.valueOf(Date.today().daysBetween(quote.ExpirationDate));
		}
		else {
			return '';
		}
	}
    
	public String getTodayRus() {
		Date today = Date.today();
		return String.valueOf(today.day()) + ' ' + monthRus.get(today.month()) + ', ' + today.year();
	}

    public String getTodayUkr() {
        Date today = Date.today();
        return String.valueOf(today.day()) + ' ' + monthUkr.get(today.month()) + ', ' + today.year();
    }
    
    public List<String> getTestForRepeat(){
        String unitValues = ApexPages.currentPage().getParameters().get('MeasureUnits');
        if(unitValues!=null){
           List<String> test = unitValues.split(',');
                    
        //List<String> test = new List<String>{'asdf','grg4'};
            return test; 
        }        
            return null;
    }

	public List<String> getQuantitySumNamesMap(){
		List<String> selecteMeasure = getTestForRepeat();
		List<String> selectedMeasureMaped = new List<String>();
		for(String s : selecteMeasure){
			selectedMeasureMaped.add(quantitySumNamesMap.get(s));
		}
		return selectedMeasureMaped;
	}
    
    public List<String> getSelectedSalesPrice(){
        
        List<String> selecteMeasure = getTestForRepeat();
		List<String> selectedSalesPrice = new List<String>();
        for(String s : selecteMeasure){
			selectedSalesPrice.add(selectedSalesPricePerUnitMap.get(s));
		}
        return selectedSalesPrice;
        
    }
    
    public List<String> getNamesOfMeasureUnits(){
        List<String> namesMeasureUnits = new List<String>();
        String unitValues = ApexPages.currentPage().getParameters().get('MeasureUnits');
        if(unitValues!=null){
           List<String> selectedUnits = unitValues.split(',');
            for(String name : selectedUnits){
                namesMeasureUnits.add(metricNamesMap.get(name));
            }         
        } 
        return namesMeasureUnits;
    }
    
    public List<String> getNamesOfMeasureUnitsRus(){
        List<String> namesMeasureUnits = new List<String>();
        String unitValues = ApexPages.currentPage().getParameters().get('MeasureUnits');
        if(unitValues!=null){
           List<String> selectedUnits = unitValues.split(',');
            for(String name : selectedUnits){
                namesMeasureUnits.add(metricNamesRusMap.get(name));
            }         
        } 
        return namesMeasureUnits;
    }
}