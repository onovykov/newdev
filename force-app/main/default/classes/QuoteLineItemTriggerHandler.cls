public class QuoteLineItemTriggerHandler extends TriggerHandler implements ITrigger {
	public static Map<Id, OpportunityLineItem> oliMap = new Map<Id, OpportunityLineItem>();
	public static Map<Id, Product2> prodMap = new Map<Id, Product2> ();
	public static Map<Id, ProductStandard__c> psMap = new Map<Id, ProductStandard__c> ();
	public static Map<Id, GeneralProductStandard__c> gpsMap = new Map<Id, GeneralProductStandard__c> ();
	public static Map<Id, TubeOD__c> odMap = new Map<Id, TubeOD__c> ();
	public static Map<Id, TubeWT__c> wtMap = new Map<Id, TubeWT__c> ();
	public static Map<Id, TubeEnds__c> endsMap = new Map<Id, TubeEnds__c> ();
	public static Map<Id, TubeLengthSize__c> lsMap = new Map<Id, TubeLengthSize__c> ();
	public static Map<Id, SteelGrade__c> sgMap = new Map<Id, SteelGrade__c> ();
	public static Set<Id> prodIds = new Set<Id> ();
	public static Set<Id> psIds = new Set<Id> ();
	public static Set<Id> odIds = new Set<Id> ();
	public static Set<Id> wtIds = new Set<Id> ();
	public static Set<Id> endsIds = new Set<Id> ();
	public static Set<Id> lsIds = new Set<Id> ();
	public static Set<Id> sgIds = new Set<Id> ();

	Boolean tonnQuantityChanged;
	Boolean tonnPriceChanged;
	Boolean inquiryUnitChanged;
	Boolean inquiryUnitQuantityChanged;
	Boolean inquiryUnitPriceChanged;

	public QuoteLineItemTriggerHandler(Map<Id, SObject> oldMap, Map<Id, SObject> newMap, List<SObject> oldList, List<SObject> newList) {
		super(oldMap, newMap, oldList, newList);
	}

	public void bulkBefore() {
		System.debug('bulkBeforeQLI');
		if (Trigger.isInsert) {
			Set<Id> oliIds = new Set<Id>();
			for (SObject so : newList) {
				QuoteLineItem qli = (QuoteLineItem) so;
				oliIds.add(qli.OpportunityLineItemId);
			}
			oliMap = new Map<Id, OpportunityLineItem>([SELECT Id, TubeEnds__c, LengthSize__c, InquiryUnit__c, TubeOD__c, Name__c, 
														ProductSpecLevel__c, ProductStandard__c, InquiryQuantity__c, InquiryUnitPrice__c, 
														ShippingPoint__c, Shop__c, SteelGrade__c, Weight_kpm__c, Weight_ppf__c, TubeWT__c,
														PricebookEntryId,LengthMax_mm__c,LengthMin_mm__c,Quantity_ft__c,Quantity_lb__c,Quantity_m__c,Quantity_pcs__c,
                                                        Sales_Price_ft__c,Sales_Price_lb__c,Sales_Price_m__c,Sales_Price_pcs__c
														FROM OpportunityLineItem WHERE Id IN :oliIds]);
		}
		if(Trigger.isInsert || Trigger.isUpdate){
			for (SObject so : newList) {
				QuoteLineItem oli = (QuoteLineItem) so;
				prodIds.add(oli.Product2Id);
				psIds.add(oli.ProductStandard__c);
				odIds.add(oli.TubeOD__c);
				wtIds.add(oli.TubeWT__c);
				endsIds.add(oli.TubeEnds__c);
				lsIds.add(oli.TubeLengthSize__c);
				sgIds.add(oli.SteelGrade__c);
			}

			if (prodMap.isEmpty()){
				prodMap = new Map<Id, Product2> ([SELECT Id, Family, LinearWeightCalculationGroup__c FROM Product2 WHERE Id = :prodIds]);
			}
			if (psMap.isEmpty()){
				List<ProductStandard__c> psList = [SELECT Id, GeneralProductStandard__c FROM ProductStandard__c WHERE Id = :psIds];
				psMap = new Map<Id, ProductStandard__c> (psList);
				Set<String> gpsIds = ApexUtil.getIds(psList);
				gpsMap = new Map<Id, GeneralProductStandard__c> ([SELECT Id, ID_ERP__c FROM GeneralProductStandard__c WHERE Id = :gpsIds]);
			}
			
			if (odMap.isEmpty()) {
				odMap = new Map<Id, TubeOD__c> ([SELECT Id, OD_mm__c, OD_inch__c FROM TubeOD__c WHERE Id = :odIds]);
			}
			if (wtMap.isEmpty()) {
				wtMap = new Map<Id, TubeWT__c> ([SELECT Id, WT_mm__c, WT_inch__c FROM TubeWT__c WHERE Id = :wtIds]);
			}
			if (endsMap.isEmpty()){
				endsMap = new Map<Id, TubeEnds__c> ([SELECT Id, Type__c FROM TubeEnds__c WHERE Id = :endsIds]);
			}
			if (lsMap.isEmpty()) {
				lsMap = new Map<Id, TubeLengthSize__c> ([SELECT Id, Name, MaxLength__c FROM TubeLengthSize__c WHERE Id = :lsIds]);
			}
			if (sgMap.isEmpty()) {
				sgMap = new Map<Id, SteelGrade__c> ([SELECT Id, Name FROM SteelGrade__c WHERE Id = :sgIds]);
			}

		}

	}

	public void bulkAfter() {
		System.debug('bulkAfter');
		System.debug('QuoteLineItemTriggerHandler1');
		
		if(Trigger.isUpdate){
			System.debug('afterUpdate');
		List<Id> qliIds = new List<Id>();
		for(Id id : newMap.keySet()){
			System.debug('map ' + id);
			QuoteLineItem oldQLI = (QuoteLineItem) oldMap.get(id);
			QuoteLineItem newQLI = (QuoteLineItem) newMap.get(id);
			if(oldQli.InquiryUnit__c != newQLI.InquiryUnit__c ||
			   oldQli.Quantity != newQLI.Quantity ||
			   oldQli.InquiryQuantity__c != newQLI.InquiryQuantity__c ||
			   oldQli.UnitPrice != newQLI.UnitPrice ||
			   oldQli.InquiryUnitPrice__c != newQLI.InquiryUnitPrice__c 
			){
				qliIds.add(id);
				System.debug('---equal');
			}
			
		}
		if(!qliIds.isEmpty()){
			System.debug('QuoteLineItemTriggerHandler2');
			QuoteJSONGenerator.updatedQuoteItemJSON(qliIds);
		}
		}
	}

	public void beforeInsert(SObject so) {
		System.debug('beforeInsert');
		QuoteLineItem qli = (QuoteLineItem) so;
		ERPProfile__c erpProf = ERPProfile__c.getInstance();
		if(!erpProf.SkipRecount__c){
			inquiryUnitQuantityChanged = qli.InquiryQuantity__c != null;
			inquiryUnitPriceChanged = qli.InquiryUnitPrice__c != null;
			Boolean inquiryRelatedFieldChanged = inquiryUnitQuantityChanged || inquiryUnitPriceChanged;

			tonnQuantityChanged = qli.Quantity != null;
			tonnPriceChanged = qli.UnitPrice != null;
			Boolean tonnRelatedFieldChanged = tonnQuantityChanged || tonnPriceChanged;

			if (inquiryRelatedFieldChanged && tonnRelatedFieldChanged && qli.Quantity != null && qli.UnitPrice != Null) {
				//recountTonnGroupValues(qli);
				//qli.addError('You cannot change inquiry measurement unit values and metric tonn values at once. Please, cancel one of these changes.');
				// Не делаем ничего вообще, т.к. в этом случае возможно нам пришли готовые данные из ИТ при обмене.
			} else if (inquiryRelatedFieldChanged) {
				recountTonnGroupValues(qli);
			} else if (tonnRelatedFieldChanged) {
				recountInquiryUnitGroupValues(qli);
			}
		}
		fillQLIasOLI(qli);
							
	}

	public void beforeUpdate(SObject oldSo, SObject so) {
		if(!checkRecursive.SetOfIDs.contains(so.Id)){
			System.debug('beforeUpdateQLI');
			
			ERPProfile__c erpProf = ERPProfile__c.getInstance();
			if (!erpProf.SkipRecount__c) {
				QuoteLineItem qli = (QuoteLineItem) so;
				QuoteLineItem oldQLI = (QuoteLineItem) oldMap.get(qli.Id);
				
				Boolean odChanged = (qli.TubeOD__c != oldQLI.TubeOD__c);
				Boolean wtChanged = (qli.TubeWT__c != oldQLI.TubeWT__c);
				Boolean lsChanged = (qli.TubeLengthSize__c != oldQLI.TubeLengthSize__c);
				Boolean sgChanged = (qli.SteelGrade__c != oldQLI.SteelGrade__c);

				inquiryUnitChanged = qli.InquiryUnit__c != oldQLI.InquiryUnit__c;
				if (qli.InquiryQuantity__c != null && oldQLI.InquiryQuantity__c != null) {
					inquiryUnitQuantityChanged = qli.InquiryQuantity__c.setScale(3) != oldQLI.InquiryQuantity__c.setScale(3);
				} else {
					inquiryUnitQuantityChanged = qli.InquiryQuantity__c != oldQLI.InquiryQuantity__c;
				}
				if (qli.InquiryUnitPrice__c != null && oldQLI.InquiryUnitPrice__c != null) {
					inquiryUnitPriceChanged = qli.InquiryUnitPrice__c.setScale(2) != oldQLI.InquiryUnitPrice__c.setScale(2);
				} else {
					inquiryUnitPriceChanged = qli.InquiryUnitPrice__c != oldQLI.InquiryUnitPrice__c;
				}
				Boolean inquiryRelatedFieldChanged = inquiryUnitChanged || inquiryUnitQuantityChanged || inquiryUnitPriceChanged;

				if (qli.Quantity != null && oldQLI.Quantity != null) {
					tonnQuantityChanged = qli.Quantity.setScale(3) != oldQLI.Quantity.setScale(3);
				} else {
					tonnQuantityChanged = qli.Quantity != oldQLI.Quantity;
				}
				if (qli.UnitPrice != null && oldQLI.UnitPrice != null) {
					tonnPriceChanged = qli.UnitPrice.setScale(2) != oldQLI.UnitPrice.setScale(2);
				} else {
					tonnPriceChanged = qli.UnitPrice != oldQLI.UnitPrice;
				}
				Boolean tonnRelatedFieldChanged = tonnQuantityChanged || tonnPriceChanged;

				if (inquiryRelatedFieldChanged && tonnRelatedFieldChanged) {
					//recountTonnGroupValues(qli);
					//qli.addError('You cannot change inquiry measurement unit values and metric tonn values at once. Please, cancel one of these changes.');
					// Не делаем ничего вообще, т.к. в этом случае возможно нам пришли готовые данные из ИТ при обмене.
				} else if (inquiryRelatedFieldChanged || odChanged || wtChanged || lsChanged || sgChanged) {
					recountTonnGroupValues(qli);
				} else if (tonnRelatedFieldChanged) {
					recountInquiryUnitGroupValues(qli);
				}
			}
			checkRecursive.SetOfIDs.add(so.Id);
		}
					
	}

	public void beforeDelete(SObject so) {
		//System.debug('beforeDelete');
	}

	public void afterInsert(SObject so) {
		System.debug('afterInsert');
	}

	public void afterUpdate(SObject oldSo, SObject so) {
		
	}

	public void afterDelete(SObject so) {
		//System.debug('afterDelete');
	}

	public void postProcessing() {
		//System.debug('postProcessing');
	}

	private void fillQLIasOLI(QuoteLineItem qli){
		OpportunityLineItem oli = oliMap.get(qli.OpportunityLineItemId);
		if(oli!=null){
			qli.TubeEnds__c = oli.TubeEnds__c;
			qli.TubeLengthSize__c = oli.LengthSize__c;
			qli.InquiryUnit__c = oli.InquiryUnit__c;
			qli.PricebookEntryId = oli.PricebookEntryId;
			qli.TubeOD__c = oli.TubeOD__c;
			qli.Name__c = oli.Name__c;
			qli.ProductSpecLevel__c = oli.ProductSpecLevel__c;
			qli.ProductStandard__c = oli.ProductStandard__c;
			qli.InquiryQuantity__c = oli.InquiryQuantity__c;
			qli.InquiryUnitPrice__c = oli.InquiryUnitPrice__c;
			qli.ShippingPoint__c = oli.ShippingPoint__c;
			qli.Shop__c = oli.Shop__c;
			qli.SteelGrade__c = oli.SteelGrade__c;
			qli.Weight_kpm__c = oli.Weight_kpm__c;
			qli.Weight_ppf__c = oli.Weight_ppf__c;
			qli.TubeWT__c = oli.TubeWT__c;
            
            qli.Quantity_ft__c = oli.Quantity_ft__c;
            qli.Quantity_lb__c = oli.Quantity_lb__c;
            qli.Quantity_m__c = oli.Quantity_m__c;
            qli.Quantity_pcs__c = oli.Quantity_pcs__c;
                
            qli.Sales_Price_ft__c = oli.Sales_Price_ft__c;
            qli.Sales_Price_lb__c = oli.Sales_Price_lb__c;
            qli.Sales_Price_m__c = oli.Sales_Price_m__c;
            qli.Sales_Price_pcs__c = oli.Sales_Price_pcs__c;
            
            qli.LengthMax_mm__c = oli.LengthMax_mm__c!=null?oli.LengthMax_mm__c:0;
            qli.LengthMin_mm__c = oli.LengthMin_mm__c!=null?oli.LengthMin_mm__c:0;                        
		}
	}

	public void recountTonnGroupValues(QuoteLineItem qli){
		System.debug('recount logic');
		System.debug(inquiryUnitQuantityChanged );
		System.debug(inquiryUnitChanged);
		if (inquiryUnitQuantityChanged || inquiryUnitChanged) {
			if(odMap.get(qli.TubeOD__c) != null && wtMap.get(qli.TubeWT__c) != null){
				System.debug('--->> Unit: ' + qli.InquiryUnit__c);
				Decimal oneMeterWeight = (odMap.get(qli.TubeOD__c).OD_mm__c - wtMap.get(qli.TubeWT__c).WT_mm__c) * wtMap.get(qli.TubeWT__c).WT_mm__c * 0.02466;
				if (qli.InquiryUnit__c=='34') {
						// Tons (t)
	        			qli.Quantity = qli.InquiryQuantity__c;
						qli.Quantity_m__c = (1000 * qli.Quantity)/oneMeterWeight;
						qli.Quantity_ft__c = qli.Quantity_m__c/0.3048;
						if (qli.TubeLengthSize__c!=null) {
							Decimal maxL = lsMap.get(qli.TubeLengthSize__c).MaxLength__c;
							if (maxL != null && maxL != 0) {
								qli.Quantity_pcs__c = (qli.Quantity_m__c * 1000 / maxL).round(System.RoundingMode.UP);
							} else {
								qli.Quantity_pcs__c = null;
							}
						} else {
							qli.Quantity_pcs__c = null;
						}			          
					} else if (qli.InquiryUnit__c=='20') {
						// Meters (m)
						qli.Quantity_m__c = qli.InquiryQuantity__c;
						qli.Quantity_ft__c = qli.Quantity_m__c/0.3048;
						qli.Quantity = oneMeterWeight != null ? (qli.Quantity_m__c * oneMeterWeight)/1000 : 0.01;
						if(qli.TubeLengthSize__c!=null){
							Decimal maxL = lsMap.get(qli.TubeLengthSize__c).MaxLength__c;
							if(maxL != null && maxL != 0){
								qli.Quantity_pcs__c = (qli.Quantity_m__c * 1000 / maxL).round(System.RoundingMode.UP);
							} else {
								qli.Quantity_pcs__c = null;
							}
						} else {
							qli.Quantity_pcs__c = null;
						}			
					} else if (qli.InquiryUnit__c=='74') {
						// Feet (ft)
	        			qli.Quantity_ft__c = qli.InquiryQuantity__c;
						qli.Quantity_m__c = 0.3048 * qli.Quantity_ft__c;
						qli.Quantity = (qli.Quantity_m__c * oneMeterWeight)/1000;
						if (qli.TubeLengthSize__c!=null) {
							Decimal maxL = lsMap.get(qli.TubeLengthSize__c).MaxLength__c;
							if (maxL != null && maxL != 0) {
								qli.Quantity_pcs__c = (qli.Quantity_m__c * 1000 / maxL).round(System.RoundingMode.UP);
							} else {
								qli.Quantity_pcs__c = null;
							}
						} else {
							qli.Quantity_pcs__c = null;
						}
					} else if(qli.InquiryUnit__c=='43') {
						// Pieces (pcs)
	        			qli.Quantity_pcs__c = qli.InquiryQuantity__c;
						if (qli.TubeLengthSize__c!=null) {
							if (lsMap.get(qli.TubeLengthSize__c).MaxLength__c!=null && lsMap.get(qli.TubeLengthSize__c).MaxLength__c!=0) {
								qli.Quantity_m__c = lsMap.get(qli.TubeLengthSize__c).MaxLength__c/1000 * qli.Quantity_pcs__c;
								System.debug(qli.Quantity_m__c);
								qli.Quantity_ft__c = qli.Quantity_m__c/0.3048;
								qli.Quantity = (qli.Quantity_m__c * oneMeterWeight)/1000;
							} else {
								qli.addError('Max Length in Length Size is empty.');
							}
						} else {
							qli.addError('Length Size is empty.');
						}
					}
			} else if(qli.InquiryUnit__c=='34'){
				qli.Quantity = qli.InquiryQuantity__c;	
			}
		}
		
		
		if (inquiryUnitPriceChanged) {
			if (qli.InquiryUnit__c == '34') {
				qli.UnitPrice = qli.InquiryUnitPrice__c;
			} else if (qli.Quantity != null && qli.Quantity != 0) {
				qli.UnitPrice = (qli.InquiryUnitPrice__c * qli.InquiryQuantity__c) / qli.Quantity;
			} else {
				qli.UnitPrice = 0;
			}
		}
		
		
    }

	public void recountInquiryUnitGroupValues(QuoteLineItem qli){
		if (tonnQuantityChanged){
			if(odMap.get(qli.TubeOD__c)!=null && wtMap.get(qli.TubeWT__c)!=null){
				Decimal oneMeterWeight = (odMap.get(qli.TubeOD__c).OD_mm__c - wtMap.get(qli.TubeWT__c).WT_mm__c) * wtMap.get(qli.TubeWT__c).WT_mm__c * 0.02466;
				Decimal quantityMC = (qli.Quantity*1000)/oneMeterWeight;
				Decimal quantityFT = quantityMC/0.3048;
				Decimal quantityPCS = null;
				if(qli.TubeLengthSize__c!=null){
					if( lsMap.get(qli.TubeLengthSize__c).MaxLength__c!=null && lsMap.get(qli.TubeLengthSize__c).MaxLength__c!=0){
						quantityPCS = (quantityMC*1000/lsMap.get(qli.TubeLengthSize__c).MaxLength__c).round(System.RoundingMode.UP);	
					} else {
						System.debug('------- Error point 3');
						//qli.addError('Max Length in Length Size is empty.');
					}		
				} else {
					System.debug('------- Error point 4');
					//qli.addError('Length Size is empty.');
				}

				if(qli.InquiryUnit__c=='34'){
					// 34 - тонны
	        		qli.InquiryQuantity__c = qli.Quantity;
				}
				else if(qli.InquiryUnit__c=='20') {
					// 20 - метры
					qli.InquiryQuantity__c = quantityMC;
				}
				else if(qli.InquiryUnit__c=='74') {
					// 74 - футы
					qli.InquiryQuantity__c = quantityFT;
				}
				else if(qli.InquiryUnit__c=='43') {
					// 43 - штуки
					qli.InquiryQuantity__c = quantityPCS;
				}
			}  
		}
		
		if (tonnPriceChanged){
			if (qli.InquiryUnit__c == '34') {
				qli.InquiryUnitPrice__c = qli.UnitPrice;
			} else if (qli.InquiryQuantity__c != null && qli.InquiryQuantity__c != 0) {
				qli.InquiryUnitPrice__c = (qli.UnitPrice * qli.Quantity) / qli.InquiryQuantity__c;
			} else {
				qli.InquiryUnitPrice__c = 0;
			}
		}
    }
}