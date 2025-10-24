public class CustomerEnquirySync implements Queueable {
	private List<Id> changedObjectsIdList;
	private String objType;
	private String actionType;

	public CustomerEnquirySync (List<Id> changedObjectsIdList, String objType, String actionType) {
		this.changedObjectsIdList = changedObjectsIdList;
		this.objType = objType;
		this.actionType = actionType;
	}

	public void Execute(QueueableContext context) {
		if (objType == 'Opportunity') {
			System.debug('>>>>> Opportunity processing...');
			if (actionType == 'Update') {
				updateEnquiries(changedObjectsIdList);
			} else if (actionType == 'Delete') {
				deleteEnquiries(changedObjectsIdList);
			} else {
				throw new EnqSyncException ('>>> Enquiries syncronization: Unknown action type for opportunity processing!');
			}
		} else if (objType == 'OpportunityProducts') {
			System.debug('>>>>> Opportunity products processing...');
			if (actionType == 'Update') {
				updateEnquiryProducts(changedObjectsIdList);
			} else if (actionType == 'Delete') {
				deleteEnquiryProducts(changedObjectsIdList);
			} else {
				throw new EnqSyncException ('>>> Enquiries syncronization: Unknown action type for opportunity products processing!');
			}
		} else {
			throw new EnqSyncException ('>>> Enquiries syncronization: Unknown object type!');
		}
	}

	
	
	Map<Id, Opportunity> oppByIdMap;
	Map<Id, Order> orderByOppIdMap;
	Map<Id, CustomerEnquiry__c> enqByOppIdMap;

	Map<Id, OpportunityLineItem> oppProductByIdMap;
	Map<Id, CustomerEnquiryProduct__c> enqProductByOppProductIdMap;
	
	
	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Enquiries processing

	private void updateEnquiries(List<Id> updatedOppsIdList) {
		List<CustomerEnquiry__c> enqToInsert = new List<CustomerEnquiry__c>();
		List<CustomerEnquiry__c> enqToUpdate = new List<CustomerEnquiry__c>();
		
		System.debug('>>>>> Updating unquiries. ' + updatedOppsIdList);

		oppByIdMap = getOppByIdMap();
		System.debug('>>> oppByIdMap: ' + oppByIdMap);
		orderByOppIdMap = getOrderByOppIdMap();
		System.debug('>>> orderByOppIdMap: ' + orderByOppIdMap);
		enqByOppIdMap =	getEnquiryByOppIdMap(updatedOppsIdList);
		System.debug('>>> enqByOppIdMap: ' + enqByOppIdMap);
		
		for (Id oppId : updatedOppsIdList) {
			Opportunity opp = oppByIdMap.get(oppId);
			if (!opp.Account.CustomerPortalEnabled__c) {
				continue;
			}

			CustomerEnquiry__c enq = enqByOppIdMap.get(oppId);

			if (enq == null) {
				enq = new CustomerEnquiry__c();
				enq.OpportunityId__c = oppId;
				enqToInsert.add(enq);
			} else {
				enqToUpdate.add(enq);
			}

			mapEnquiryFields(enq, oppByIdMap.get(oppId));
		}

		if (!enqToInsert.isEmpty()) {
			insert enqToInsert;
		}
		if (!enqToUpdate.isEmpty()) {
			update enqToUpdate;
		}
	}

	private Map<Id, Opportunity> getOppByIdMap() {
		Map<Id, Opportunity> oppByIdMap = new Map<Id,Opportunity>	([
																		SELECT Id, RecordType.DeveloperName, AccountId, Account.CustomerPortalEnabled__c, OwnerId, CurrencyIsoCode
																		FROM Opportunity
																		WHERE Id IN :changedObjectsIdList
																	]);
		return oppByIdMap;
	}

	private Map<Id, Order> getOrderByOppIdMap() {
		List<Order> orderList =	[
									SELECT Id, OpportunityId, Status
									FROM Order
									WHERE OpportunityId IN :changedObjectsIdList
								];

		Map<Id, Order> orderByOppIdMap = new Map<Id, Order>();
		for(Order ord : orderList) {
			orderByOppIdMap.put(ord.OpportunityId, ord);
		}

		return orderByOppIdMap;
	}

	private Map<Id, CustomerEnquiry__c> getEnquiryByOppIdMap(List<Id> oppIdList) {
		List<CustomerEnquiry__c> enqList =	[
												SELECT Id, OpportunityId__c
												FROM CustomerEnquiry__c
												WHERE OpportunityId__c IN :oppIdList
											];

		Map<Id, CustomerEnquiry__c> enqByOppIdMap = new Map<Id, CustomerEnquiry__c>();
		for(CustomerEnquiry__c enq : enqList) {
			enqByOppIdMap.put(enq.OpportunityId__c, enq);
		}

		return enqByOppIdMap;
	}

	private void mapEnquiryFields(CustomerEnquiry__c enq, Opportunity opp) {
		Order ord = orderByOppIdMap.get(opp.Id);
		enq.AccountId__c = opp.AccountId;
		enq.SalesRepId__c = opp.OwnerId;
		enq.OrderId__c = ord?.Id;
		enq.CurrencyIsoCode = opp.CurrencyIsoCode;
		enq.RecordTypeId = getEnquiryRecordTypeId(opp.RecordType.DeveloperName);
		enq.Status__c = getEnquiryStatus(ord);
	}

	private Id getEnquiryRecordTypeId(String oppRecordTypeName) {
		Id enquiryRecordTypeId;

		switch on oppRecordTypeName {
			when 'Tubes_RFP', 'Tubes_Tender' {
				enquiryRecordTypeId = Schema.SObjectType.CustomerEnquiry__c.getRecordTypeInfosByDeveloperName().get('Tubes').getRecordTypeId();
			}
			when 'Wheels_RFP', 'Wheels_Tender' {
				enquiryRecordTypeId = Schema.SObjectType.CustomerEnquiry__c.getRecordTypeInfosByDeveloperName().get('Wheels').getRecordTypeId();
			}
		}
		
		return enquiryRecordTypeId;
	}

	private String getEnquiryStatus(Order ord) {
		String enqStatus;

		if (ord == null) {
			enqStatus = 'Processing';
		} else {
			if(ord.Status == 'Closed') {
				enqStatus = 'Closed';
			} else {
				enqStatus = 'Order Created';
			}
		}

		return enqStatus;
	}

	private void deleteEnquiries(List<Id> deletedOppsList) {
		delete [SELECT Id FROM CustomerEnquiry__c WHERE OpportunityId__c IN :deletedOppsList];
	}



	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Enquiry Products processing

	private void updateEnquiryProducts(List<Id> updatedOppProductsIdList) {
		List<CustomerEnquiryProduct__c> enqProductsToInsert = new List<CustomerEnquiryProduct__c>();
		List<CustomerEnquiryProduct__c> enqProductsToUpdate = new List<CustomerEnquiryProduct__c>();
		
		oppProductByIdMap = getOppProductByIdMap();
		enqProductByOppProductIdMap = getEnquiryProductByOppProductIdMap();
		List<Id> oppIdList = getOppIdsFromProducts(oppProductByIdMap.values());
		enqByOppIdMap = getEnquiryByOppIdMap(oppIdList);
		
		for (Id oppProductId : updatedOppProductsIdList) {
			OpportunityLineItem oppProduct = oppProductByIdMap.get(oppProductId);
			if (!oppProduct.Opportunity.Account.CustomerPortalEnabled__c) {
				continue;
			}

			CustomerEnquiryProduct__c enqProduct = enqProductByOppProductIdMap.get(oppProductId);

			if (enqProduct == null) {
				enqProduct = new CustomerEnquiryProduct__c();
				Id oppId = oppProduct.OpportunityId;
				enqProduct.CustomerEnquiryId__c = enqByOppIdMap.get(oppId).Id;
				enqProduct.OpportunityProductId__c = oppProductId;
				enqProductsToInsert.add(enqProduct);
			} else {
				enqProductsToUpdate.add(enqProduct);
			}

			mapEnquiryProductFields(enqProduct, oppProduct);
		}

		if (!enqProductsToInsert.isEmpty()) {
			insert enqProductsToInsert;
		}
		if (!enqProductsToUpdate.isEmpty()) {
			update enqProductsToUpdate;
		}
	}

	private Map<Id, OpportunityLineItem> getOppProductByIdMap() {
		Map<Id, OpportunityLineItem> oppProductByIdMap = new Map<Id, OpportunityLineItem>	([
																								SELECT Id, OpportunityId, Opportunity.Account.CustomerPortalEnabled__c
																								FROM OpportunityLineItem
																								WHERE Id IN :changedObjectsIdList
																							]);
		return oppProductByIdMap;
	}

	private List<Id> getOppIdsFromProducts(List<OpportunityLineItem> oppProductsList) {
		Set<Id> oppIdSet = new Set<Id>();
		for (OpportunityLineItem oppProduct : oppProductsList) {
			oppIdSet.add(oppProduct.OpportunityId);
		}
		
		return new List<Id>(oppIdSet);
	}

	private Map<Id, CustomerEnquiryProduct__c> getEnquiryProductByOppProductIdMap() {
		List<CustomerEnquiryProduct__c> enqProductList =	[
																SELECT Id, OpportunityProductId__c, CustomerEnquiryId__r.RecordType.DeveloperName
																FROM CustomerEnquiryProduct__c
																WHERE OpportunityProductId__c IN :changedObjectsIdList
															];

		Map<Id, CustomerEnquiryProduct__c> enqProductByOppProductIdMap = new Map<Id, CustomerEnquiryProduct__c>();
		for(CustomerEnquiryProduct__c enqProduct : enqProductList) {
			enqProductByOppProductIdMap.put(enqProduct.OpportunityProductId__c, enqProduct);
		}

		return enqProductByOppProductIdMap;
	}

	private void mapEnquiryProductFields(CustomerEnquiryProduct__c enqProduct, OpportunityLineItem oppProduct) {
		enqProduct.RecordTypeId = getEnquiryProductRecordTypeId(enqProduct.CustomerEnquiryId__r.RecordType.DeveloperName);
		enqProduct.CurrencyIsoCode = oppProduct.CurrencyIsoCode;
		enqProduct.Name = oppProduct.Name;
		enqProduct.Price__c = oppProduct.UnitPrice;
		enqProduct.TotalPrice__c = oppProduct.TotalPrice;
		enqProduct.Product2Id__c = oppProduct.Product2Id;
		enqProduct.MeasurementUnit__c = oppProduct.InquiryUnit__c;
		enqProduct.Quantity__c = oppProduct.InquiryQuantity__c;
		enqProduct.Quantity_t__c = oppProduct.Quantity;
	}

	private Id getEnquiryProductRecordTypeId(String enquiryRecordTypeName) {
		Id enquiryProductRecordTypeId;

		switch on enquiryRecordTypeName {
			when 'Tubes' {
				enquiryProductRecordTypeId = Schema.SObjectType.CustomerEnquiry__c.getRecordTypeInfosByDeveloperName().get('Tube').getRecordTypeId();
			}
			when 'Wheels' {
				enquiryProductRecordTypeId = Schema.SObjectType.CustomerEnquiry__c.getRecordTypeInfosByDeveloperName().get('Wheel').getRecordTypeId();
			}
		}
		
		return enquiryProductRecordTypeId;
	}

	private void deleteEnquiryProducts(List<Id> deletedOppProductsList) {
		delete [SELECT Id FROM CustomerEnquiryProduct__c WHERE OpportunityProductId__c IN :deletedOppProductsList];
	}

	public class EnqSyncException extends Exception {}
}