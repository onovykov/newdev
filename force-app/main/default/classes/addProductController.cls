public with sharing class addProductController {
	@TestVisible static Boolean isInSalesforce1 = UserInfo.getUIThemeDisplayed() == 'Theme4t';
	public static TubeOD__c od = new TubeOD__c();
	public static TubeWT__c wt = new TubeWT__c();
	public static TubeLengthSize__c ls = new TubeLengthSize__c();
	public static SteelGrade__c sg = new SteelGrade__c();

	@AuraEnabled
	public static Boolean getIsAllowedToAddProducts(Id oppId) {
		Opportunity opp = [SELECT Id, ID_ERP__c FROM Opportunity WHERE Id = :oppId];
		return String.isBlank(opp.ID_ERP__c);
	}

	@AuraEnabled
	public static Map<String, String> getProductNames(Id oppId) {
		Map<String, String> values = new Map<String, String> ();
		Opportunity opp = [SELECT Id, Pricebook2Id, CurrencyIsoCode FROM Opportunity WHERE Id = :oppId];
		List<PriceBookEntry> pb2 = [select Id, UnitPrice, Product2Id, Product2.Name, Product2.IsActive from PriceBookEntry where Pricebook2Id = :opp.Pricebook2Id and CurrencyISOcode = :opp.CurrencyISOcode AND Product2.IsActive = true];
		for (PriceBookEntry pbe : pb2) {
			values.put(pbe.Product2Id, pbe.Product2.Name);
		}
		System.debug(values);
		return values;

	}

	@AuraEnabled
	public static String getCurrencyIsoCode(Id oppId) {
		Opportunity opp = [SELECT CurrencyIsoCode FROM Opportunity WHERE Id = :oppId];
		return opp.CurrencyIsoCode;
	}

	@AuraEnabled
	public static OpportunityLineItem getNewOppProduct() {
		return new OpportunityLineItem();
	}

	@AuraEnabled
	public static Map<String, String> getFieldPicklistValues(String picklistField) {
		Schema.SObjectType sobjectType = Schema.getGlobalDescribe().get('OpportunityLineItem');
		List<Schema.PicklistEntry> picklistValues = sobjectType.getDescribe().fields.getMap().get(picklistField).getDescribe().getPickListValues();
		Map<String, String> values = new Map<String, String> ();
		for (Schema.PicklistEntry pklVal : picklistValues) {
			values.put(pklVal.getLabel(), pklVal.getValue());
		}
		return values;
	}

	@AuraEnabled
	public static Map<String, String> getNames(String objectApiName) {
		Map<String, String> values = new Map<String, String> ();
		List<SObject> objList = Database.query('SELECT Id, Name FROM ' + objectApiName);
		for (SObject obj : objList) {
			values.put(obj.Id, (String) obj.get('Name'));
		}
		return values;
	}

	@AuraEnabled
	public static Boolean isMobile() {
		return(isInSalesforce1);
	}

	@AuraEnabled
	public static Map<String, String> getShippingPointForCountry(Id oppId) {
		Map<String, String> values = new Map<String, String> ();
		Opportunity opp = [SELECT Country__c FROM Opportunity WHERE Id = :oppId];

		List<ShippingPoint__c> spList = [SELECT Id, Name FROM ShippingPoint__c WHERE Country__c = :opp.Country__c];
		for (ShippingPoint__c sp : spList) {
			values.put(sp.Id, sp.Name);
		}
		return values;
	}

	@AuraEnabled
	public static String addOppProductQ(OpportunityLineItem oppProduct, Id oppId) {
		String errorMessage = '';
		try {
			Opportunity opp = [SELECT Id, CurrencyISOcode FROM Opportunity WHERE Id = :oppId];
			PriceBookEntry pb2;
			if (Test.isRunningTest()) {
				Id pricebookId = Test.getStandardPricebookId();
				pb2 = [select Id, UnitPrice from PriceBookEntry where Pricebook2Id = :pricebookId LIMIT 1];
			} else {
				Pricebook2 pb1 = [select Id, Name, IsActive from PriceBook2 where IsStandard = True LIMIT 1];
				pb2 = [select Id, UnitPrice from PriceBookEntry where Pricebook2Id = :pb1.Id and Product2Id = :oppProduct.Product2Id and CurrencyISOcode = :opp.CurrencyISOcode LIMIT 1];
			}
			OpportunityLineItem oppProductToInsert = new OpportunityLineItem();
			oppProductToInsert = oppProduct;
			if (oppProduct.InquiryUnit__c == '34') {
				oppProductToInsert.Quantity = oppProductToInsert.InquiryQuantity__c;
			}
			else if (oppProduct.InquiryUnit__c == '20') {
				oppProductToInsert.Quantity_m__c = oppProductToInsert.InquiryQuantity__c;
			} else if (oppProduct.InquiryUnit__c == '74') {
				oppProductToInsert.Quantity_ft__c = oppProductToInsert.InquiryQuantity__c;
			} else if (oppProduct.InquiryUnit__c == '43') {
				oppProductToInsert.Quantity_pcs__c = oppProductToInsert.InquiryQuantity__c;
			}

			oppProductToInsert.PricebookEntryId = pb2.Id;
			//oppProductToInsert.UnitPrice = oppProduct.UnitPrice != null ? oppProduct.UnitPrice : 0;

			oppProductToInsert.OpportunityId = oppId;
			System.debug(oppProductToInsert.InquiryUnit__c);
			if (oppProduct.InquiryUnitPrice__c != null) {
				oppProductToInsert.UnitPrice = oppProductToInsert.InquiryUnitPrice__c;
			}
			else {
				oppProductToInsert.UnitPrice = 0;
			}
			oppProductToInsert.TotalPrice = null;
			oppProductToInsert.Name__c = (sg.Name != null ? sg.Name : '') + ' ' + od.OD_mm__c + 'x' + wt.WT_mm__c + ' ' + (ls.Name != null ? ls.Name : '');
			System.debug(oppProductToInsert);
			Database.SaveResult result = Database.insert(oppProductToInsert);

			/*Database.Error[] errors = result.getErrors();
			  for(Database.Error error : errors){
			  errorMessage+=error + '. ';
			  }*/
		}
		catch(Exception e) {
			errorMessage = e.getMessage();
			errorMessage += e.getStackTraceString();
		}
		return errorMessage;
	}

	public class ResponseData {
		public Boolean isSuccess;
		public Map<String, Object> results;
		public String errMsg;

		public ResponseData() {
			this.isSuccess = true;
			this.results = new Map<String, Object> ();
		}

		public void addError(String errMsg) {
			this.errMsg = errMsg;
			this.isSuccess = false;
		}

		public String getJsonString() {
			return JSON.serialize(this);
		}
	}
}