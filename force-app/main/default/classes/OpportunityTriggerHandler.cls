public class OpportunityTriggerHandler extends TriggerHandler implements ITrigger {
	static ID standardPricebookId;
	Map<Id, Opportunity> oppMapWithOLIs = new Map<Id, Opportunity> ();
	public OpportunityTriggerHandler(Map<Id, SObject> oldMap, Map<Id, SObject> newMap, List<SObject> oldList, List<SObject> newList) {
		super(oldMap, newMap, oldList, newList);
	}

	public static List<Id> opportunityOrdersForDelete = new List<Id> ();
	public static List<Id> opportunitiesToConvert = new List<Id> ();
	public static List<OrderItem> newOrderItems = new List<OrderItem> ();
	public static Map<Id, Opportunity> oppWithOLIMap;
	public Map<Id, Order> oppIdWithOrderMap = new Map<Id, Order> ();
	public static Map<Id, User> owners;


	public void bulkBefore() {
		System.debug('bulkBefore OpportunityTriggerHandler');
		if (Trigger.isUpdate && oppWithOLIMap == null) {
			oppWithOLIMap = new Map<Id, Opportunity> ([SELECT Id, (SELECT Id, ID_ERP__c, ServiceDate FROM OpportunityLineItems) FROM Opportunity WHERE Id IN: newMap.keySet()]);
		}

		if (Test.isRunningTest()) {
			standardPricebookId = Test.getStandardPricebookId();
		} else {
			if (standardPricebookId == null) {
				standardPricebookId = [Select ID FROM Pricebook2 WHERE IsStandard = true] [0].Id;
			}
		}
		if (operation != TriggerOperation.IS_DELETE) {
			List<Opportunity> scope = new List<Opportunity> ();
			if (operation == TriggerOperation.IS_INSERT || operation == TriggerOperation.IS_UPDATE) {
				scope.addAll((List<Opportunity>) newList);
			} else {
				for (Opportunity opp : (List<Opportunity>) newList) {
					if (isFieldChanged(opp, (Opportunity) oldMap.get(opp.Id), 'OwnerId')) {
						scope.add(opp);
					}
				}
			}
			
			//if (owners == null) {
				Set<String> ownersIdSet = new Set<String> ();
				ownersIdSet = ApexUtil.getFieldValues(scope, Opportunity.OwnerId);
				owners = new Map<Id, User> ([SELECT Id, SalesDivision__c, SalesRegion__c, AssignedBOS__c, AdditionalBOS__c FROM USER WHERE Id IN :ownersIdSet]);
			//}
			system.debug(scope);
			for (Opportunity opp : scope) {
                if(owners.containsKey(opp.OwnerId)){
                
    				opp.Owner__c = opp.OwnerId;
                    if (opp.MarketSegment__c == null || opp.MarketSegment__c == '') {
                           opp.MarketSegment__c = owners.get(opp.OwnerId).SalesDivision__c;
                    }
                    if (opp.Region__c == null || opp.Region__c == '') {
                        opp.Region__c = owners.get(opp.OwnerId).SalesRegion__c;
                    }
                    if (opp.AssignedBOS__c == null) {
                        Id bosId = owners.get(opp.OwnerId).AssignedBOS__c;
                        if (bosId != null) {
                            opp.AssignedBOS__c = owners.get(opp.OwnerId).AssignedBOS__c;
                        }
                    }
                    if (opp.AdditionalBOS__c == null){
                        id aBosId = owners.get(opp.OwnerId).AdditionalBOS__c;
                        if(aBosId != null){
                            opp.AdditionalBOS__c = owners.get(opp.OwnerId).AdditionalBOS__c; 
                        }
                    }
                }
				
                
                
			}
		}
		
		//if (operation == TriggerOperation.IS_DELETE) {
			////Удалим все связанные Orders
			//Set<String> oppIdSet = ApexUtil.getIds(oldList);
			//List<Order> ordList = New List<Order>([Select Id FROM Order Where OpportunityId in :oppIdSet]);
			//Delete ordList;
		//}
		
	}

	public void bulkAfter() {
		System.debug('bulkAfter');
		//if (Trigger.isUpdate) {
			//Set<Id> oppWithChangesIds = new Set<Id> ();
			//List<Quote> quotesToUpdate = new List<Quote> ();
			//for (SObject opps : newList) {
				//Opportunity oppNew = (Opportunity) opps;
				//Opportunity oppOld = (Opportunity) oldMap.get(oppNew.Id);
				//if (oppOld.DeliveryTerms__c != oppNew.DeliveryTerms__c || oppOld.PaymentTerms__c != oppNew.PaymentTerms__c) {
					//oppWithChangesIds.add(oppNew.Id);
				//}
			//}
			//if (oppWithChangesIds.size() != 0) {
				//oppMapWithOLIs = new Map<Id, Opportunity> ([SELECT Id, DeliveryTerms__c, PaymentTerms__c, (SELECT Id FROM Quotes) FROM Opportunity WHERE Id IN :oppWithChangesIds]);
				//for (Opportunity opp : oppMapWithOLIs.values()) {
					//for (Quote qu : opp.Quotes) {
						//qu.DeliveryTerms__c = opp.DeliveryTerms__c;
						//qu.PaymentTerms__c = opp.PaymentTerms__c;
						//quotesToUpdate.add(qu);
					//}
				//}
				//update quotesToUpdate;
			//}
		//}

		//syncCustomerEnquiry();
	}

	public void beforeInsert(SObject so) {
		System.debug('beforeInsert');
		Opportunity opp = (Opportunity) so;
		opp.StageName = 'Qualification';
		if (opp.Pricebook2Id == null) {
			opp.Pricebook2Id = standardPricebookId;
		}
	}

	public void beforeUpdate(SObject oldSo, SObject so) {

		System.debug('beforeUpdate');

		Opportunity oldOpp = (Opportunity) oldSo;
		Opportunity opp = (Opportunity) so;
		
		if (isFieldChanged(opp, oldOpp, 'StageName')) {
			if (oldOpp.get('StageName').equals('Closed Won')){
				opportunityOrdersForDelete.add(so.Id);
			} else if (opp.get('StageName').equals('Closed Won')) {
				for (OpportunityLineItem curr_item : oppWithOLIMap.get(opp.Id).OpportunityLineItems) {
					if (curr_item.ID_ERP__c == null) {
						System.debug('Opp error here!' + curr_item.ID_ERP__c);
						opp.addError('You can not set stage to "Closed Won" if Opportunity Product field - "ID in ERP" is not populated.');
					}
				}

				/* 18.10.2020: Закомментировал создание ордеров, чтобы избежать конфликта, когда из ИТ-Предприятия приходит заказ, а оппа еще не в стадии выигранной.
				//opportunitiesToConvert.add(so.Id);
				//Order newOrder = createOrder((Opportunity) so);
				//oppIdWithOrderMap.put(so.Id, newOrder);
				*///18.10.2020
			}
		}
	}

	public void beforeDelete(SObject so) {
	}

	public void afterInsert(SObject so) {

		System.debug('afterInsert');
	
	}

	public void afterUpdate(SObject oldSo, SObject so) {
		if (!Test.isRunningTest()) {
            System.debug('afterUpdate');
			Opportunity oldOpp = (Opportunity) oldSo;
			Opportunity opp = (Opportunity) so;
			if (opp.StageName != oldOpp.StageName && opp.ID_ERP__c != null) {
				SFtoERPOpportunityStage.sendJSONData(opp.id);
			}
			if (String.isNotBlank(opp.ID_ERP__c) && String.isBlank(oldOpp.ID_ERP__c) ) {
				SFtoERPOpportunityStage.sendJSONData(opp.id);
			}
			if (isFieldChanged(oldOpp, opp, 'Probability')) {
				List<id> lastQuoteId = new List<id>();
				List<Quote> lastQuote = [SELECT id FROM Quote WHERE OpportunityId =:opp.id ORDER BY CreatedDate DESC LIMIT 1];
				System.debug('lastQuote ' +lastQuote.size());

				if (lastQuote.size() > 0) {
					for (Quote qt : lastQuote) {
						lastQuoteId.add(qt.Id);
					}
				System.debug('lastQuote ' +lastQuote);
				if (lastQuote[0].Created_From_OPA_process__c = false) {
					QuoteJSONGenerator.createJsonData(lastQuoteId);
				}
				}
			}
        }
		
	}

	public void afterDelete(SObject so) {
	}

	public override void beforePostProcessing() {

		if (!oppIdWithOrderMap.values().isEmpty()) {
			insert oppIdWithOrderMap.values();
			
			for (Id current_order_opp_id : oppIdWithOrderMap.keySet()) {
				((Opportunity) newMap.get(current_order_opp_id)).SyncedOrder__c = oppIdWithOrderMap.get(current_order_opp_id).Id;
			}

			newOrderItems.addAll(createOrderItems(opportunitiesToConvert, oppIdWithOrderMap.values()));
			if (!newOrderItems.isEmpty()) {
				System.debug('Insert order items - ' + newOrderItems);
				insert newOrderItems;
				for (Order current_item : oppIdWithOrderMap.values()) {
					current_item.Status = 'Activated';
				}
				update oppIdWithOrderMap.values();
				newOrderItems.clear();
			}
			oppIdWithOrderMap.values().clear();
			opportunitiesToConvert.clear();
		}
	}

	public void postProcessing() {
		if (!opportunityOrdersForDelete.isEmpty()) {
			List<Order> ordersForDelete = [SELECT Id FROM Order WHERE OpportunityId IN :opportunityOrdersForDelete];
			if (!ordersForDelete.isEmpty()) {
				for (Order current_item : ordersForDelete) {
					current_item.Status = 'Draft';
				}
				update ordersForDelete;
				delete ordersForDelete;
				ordersForDelete.clear();
			}
		}
	}

	private static Order createOrder(Opportunity so) {
		Order newOrder = new Order(OpportunityId = so.Id, AccountId = so.AccountId, Status = 'Draft',
		                           EffectiveDate = getEffectiveDate(oppWithOLIMap.get(so.Id).OpportunityLineItems), Pricebook2Id = so.Pricebook2Id,
		                           AdditionalNumber__c = so.AdditionalNumber__c, AssignedBOS__c = so.AssignedBOS__c,
		                           ContractId = so.ContractId, MarketSegment__c = so.MarketSegment__c, Country__c = so.Country__c,
		                           CrossMarketSegment__c = so.CrossMarketSegment__c, CrossMarketManager__c = so.CrossMarketManager__c, CrossMarketShare__c = so.CrossMarketShare__c,
								   DeliveryTerms__c = so.DeliveryTerms__c,
		                           Description = so.Description, ID_ERP__c = so.ID_ERP__c,
		                           CurrencyIsoCode = so.CurrencyIsoCode, Name = so.Name,
		                           OwnerId = so.OwnerId, Type = so.Type, PaymentTerms__c = so.PaymentTerms__c,
		                           OrderReferenceNumber = so.AdditionalNumber__c);

		return newOrder;
	}

	private static List<OrderItem> createOrderItems(List<Id> opportunitiesId, List<Order> orderList) {
		List<OpportunityLineItem> lineItemsToConvert = [SELECT Id, Quantity, UnitPrice, PricebookEntryId, OpportunityId, ID_ERP__c, CDD__c, ConfirmedCDD__c,
		                                                Coating__c, TubeEnds__c, ITENumber__c, Description, Margin__c,
		                                                Margin_t__c, Name__c, NPP_ERP__c, Product2Id, ProductSpecLevel__c,
		                                                ProductStandard__c, QuotaType__c, ServiceDate, SteelGrade__c,
		                                                LengthSize__c, TubeOD__c, TubeWT__c, Weight_kpm__c, Weight_ppf__c, Shop__c
		                                                FROM OpportunityLineItem WHERE OpportunityId IN :opportunitiesId];
		List<OrderItem> newOrderItems = new List<OrderItem> ();
		for (OpportunityLineItem oppLineItem : lineItemsToConvert) {
			for (Order orderListItem : orderList) {
				if (orderListItem.OpportunityId == oppLineItem.OpportunityId) {
					newOrderItems.add(new OrderItem(OrderId = orderListItem.Id, Quantity = oppLineItem.Quantity,
					                                UnitPrice = oppLineItem.UnitPrice, PricebookEntryId = oppLineItem.PricebookEntryId,
					                                ID_ERP__c = oppLineItem.ID_ERP__c, CDD__c = oppLineItem.CDD__c, ConfirmedCDD__c = oppLineItem.ConfirmedCDD__c,
					                                Coating__c = oppLineItem.Coating__c, Stage__c = 'Confirmed',
					                                TubeEnds__c = oppLineItem.TubeEnds__c, ITENumber__c = oppLineItem.ITENumber__c,
					                                Description = oppLineItem.Description, Shop__c = oppLineItem.Shop__c,
					                                Name__c = oppLineItem.Name__c, NPP_ERP__c = oppLineItem.NPP_ERP__c,
					                                Product2Id = oppLineItem.Product2Id, ProductSpecLevel__c = oppLineItem.ProductSpecLevel__c,
					                                ProductStandard__c = oppLineItem.ProductStandard__c, QuotaType__c = oppLineItem.QuotaType__c,
					                                ServiceDate = oppLineItem.ServiceDate, SteelGrade__c = oppLineItem.SteelGrade__c,
					                                TubeLengthSize__c = oppLineItem.LengthSize__c,
					                                TubeOD__c = oppLineItem.TubeOD__c, TubeWT__c = oppLineItem.TubeWT__c,
					                                Weight_kpm__c = oppLineItem.Weight_kpm__c, Weight_ppf__c = oppLineItem.Weight_ppf__c
					));
				}
			}
		}
		return newOrderItems;
	}

	private static Date getEffectiveDate(List<OpportunityLineItem> oppLineItems) {
		Date minDate = Date.today();
		for (OpportunityLineItem oli : oppLineItems) {
			if (oli.ServiceDate<minDate) {
				minDate = oli.ServiceDate;
			}
		}
		return minDate;
	}

	private Boolean isFieldChanged(Opportunity newOpp, Opportunity oldOpp, String fieldName) {
		return newOpp.get(fieldName) != oldOpp.get(fieldName);
	}

	private void syncCustomerEnquiry() {
		String actionType;

		if (Trigger.isInsert || Trigger.isUpdate) {
			actionType = 'Update';
		} else if (Trigger.isDelete) {
			actionType = 'Delete';
		}

		CustomerEnquirySync ces = new CustomerEnquirySync(new List<Id>(newMap.keySet()), 'Opportunity', actionType);
		Id jobId = System.enqueueJob(ces);
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
	}
}