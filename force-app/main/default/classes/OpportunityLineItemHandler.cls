public class OpportunityLineItemHandler extends TriggerHandler implements ITrigger {

	Set<Opportunity> oppsToUpdate = new Set<Opportunity> ();
	List<OpportunityStage> oppStages = new List<OpportunityStage> ();
	public static final String OLI_STAGENAME_SHIPPED = 'Shipped';

	Map<ID, Opportunity> oppMap;
	Map<Id, Opportunity> oppMap2;

	Map<Id, Id> oppIds = new Map<Id, Id>();
	public static Map<Id, Product2> prodMap;
	public static Map<Id, ProductStandard__c> psMap;
	public static Map<Id, GeneralProductStandard__c> gpsMap;
	
	public static Map<Id, SteelGrade__c> sgMap;
	public static Map<Id, TubeOD__c> odMap;
	public static Map<Id, TubeWT__c> wtMap;
	public static Map<Id, TubeEnds__c> endsMap;
	public static Map<Id, TubeLengthSize__c> lsMap;
	
	public static Map<Id, WheelSteelGrade__c> wsgMap;
	public static Map<Id, WheelDiameter__c> wodMap;
	public static Map<Id, WheelHub__c> whMap;
	public static Map<Id, WheelDrawing__c> wdMap;

	//Bahtiyar 2018-07-25: добавил переменные, используемые при создании записей в объекте SalesPlanFact__c ------------------
	
	public static Map<Id, Opportunity> oppMapForSPF;
	public static List<SalesPlanFact__c> spfToInsert = new List<SalesPlanFact__c>();
	public static final Id RT_OPPORTUNITY = [SELECT Id, Name FROM RecordType WHERE SobjectType = 'SalesPlanFact__c' And Name = 'Opportunity'].Id;
	//---------------------------------------------------------------------
	public static Set<Id> oliSet = new Set<Id>();

	Boolean tonnQuantityChanged;
	Boolean tonnPriceChanged;
	Boolean inquiryUnitChanged;
	Boolean inquiryUnitQuantityChanged;
	Boolean inquiryUnitPriceChanged;



	public OpportunityLineItemHandler(Map<Id, SObject> oldMap, Map<Id, SObject> newMap, List<SObject> oldList, List<SObject> newList) {
		super(oldMap, newMap, oldList, newList);
	}

	public void bulkBefore() {
		
		System.debug('bulkBeforeOLI');
		
		List<OpportunityLineItem> oppliList = (List<OpportunityLineItem>) newList;
		Set<Id> oppIdSet = new Set<Id>();
		//Set<Id> prodIds = new Set<Id>();
		//Set<Id> psIds = new Set<Id>();
		//Set<Id> sgIds = new Set<Id>();
		//Set<Id> odIds = new Set<Id>();
		//Set<Id> wtIds = new Set<Id>();
		//Set<Id> endsIds = new Set<Id>();
		//Set<Id> lsIds = new Set<Id>();

		//Set<Id> wsgIds = new Set<Id>();
		//Set<Id> wodIds = new Set<Id>();
		//Set<Id> whIds = new Set<Id>();
		//Set<Id> wdIds = new Set<Id>();       

        if(Trigger.isInsert){
           //updateQuotaTypeField(oppliList);
        }
        
		if ((Trigger.isInsert || Trigger.isUpdate) && prodMap == null) {
			updateQuotaTypeField(oppliList);
            for (SObject so : newList) {
				OpportunityLineItem oli = (OpportunityLineItem) so;
				oppIdSet.add(oli.OpportunityId);
				//prodIds.add(oli.Product2Id);
				//psIds.add(oli.ProductStandard__c);
				//sgIds.add(oli.SteelGrade__c);
				//odIds.add(oli.TubeOD__c);
				//wtIds.add(oli.TubeWT__c);
				//endsIds.add(oli.TubeEnds__c);
				//lsIds.add(oli.LengthSize__c);
				//wsgIds.add(oli.WheelSteelGrade__c);
				//wodIds.add(oli.WheelDiameter__c);
				//whIds.add(oli.WheelHub__c);
				//wdIds.add(oli.WheelDrawing__c);
			}			
		} else if (Trigger.isDelete) {
			for (SObject so : oldList) {
				OpportunityLineItem oli = (OpportunityLineItem) so;
				oppIdSet.add(oli.OpportunityId);
			}
		}

		if((Trigger.isInsert || Trigger.isUpdate) && prodMap == null) {
			
			//prodMap = new Map<Id, Product2> ([SELECT Id, Family, Type__c, LinearWeightCalculationGroup__c FROM Product2 WHERE Id = :prodIds]);
			prodMap = new Map<Id, Product2> ([SELECT Id, Family, Type__c, LinearWeightCalculationGroup__c FROM Product2]);
			//List<ProductStandard__c> psList = [SELECT Id, GeneralProductStandard__c FROM ProductStandard__c WHERE Id = :psIds];
			List<ProductStandard__c> psList = [SELECT Id, GeneralProductStandard__c, IsSecondChoice__c FROM ProductStandard__c];
			psMap = new Map<Id, ProductStandard__c> (psList);
			//Set<String> gpsIds = ApexUtil.getIds(psList);
			/*
			gpsMap = new Map<Id, GeneralProductStandard__c> ([SELECT Id, ID_ERP__c FROM GeneralProductStandard__c WHERE Id = :gpsIds]);
			sgMap = new Map<Id, SteelGrade__c> ([SELECT Id, Name FROM SteelGrade__c WHERE Id = :sgIds]);
			odMap = new Map<Id, TubeOD__c> ([SELECT Id, OD_mm__c, OD_inch__c FROM TubeOD__c WHERE Id = :odIds]);
			wtMap = new Map<Id, TubeWT__c> ([SELECT Id, WT_mm__c, WT_inch__c FROM TubeWT__c WHERE Id = :wtIds]);
			endsMap = new Map<Id, TubeEnds__c> ([SELECT Id, Type__c FROM TubeEnds__c WHERE Id = :endsIds]);
			lsMap = new Map<Id, TubeLengthSize__c> ([SELECT Id, Name, MaxLength__c FROM TubeLengthSize__c WHERE Id = :lsIds]);
			wsgMap = new Map<Id, WheelSteelGrade__c> ([SELECT Id, Name FROM WheelSteelGrade__c WHERE Id = :wsgIds]);
			wodMap = new Map<Id, WheelDiameter__c> ([SELECT Id, OD_mm__c, Name FROM WheelDiameter__c WHERE Id = :wodIds]);
			whMap = new Map<Id, WheelHub__c> ([SELECT Id, Name FROM WheelHub__c WHERE Id = :whIds]);
			wdMap = new Map<Id, WheelDrawing__c> ([SELECT Id, Name FROM WheelDrawing__c WHERE Id = :wdIds]);
			*/
			gpsMap = new Map<Id, GeneralProductStandard__c> ([SELECT Id, ID_ERP__c FROM GeneralProductStandard__c]);
			sgMap = new Map<Id, SteelGrade__c> ([SELECT Id, Name FROM SteelGrade__c]);
			odMap = new Map<Id, TubeOD__c> ([SELECT Id, OD_mm__c, OD_inch__c FROM TubeOD__c]);
			wtMap = new Map<Id, TubeWT__c> ([SELECT Id, WT_mm__c, WT_inch__c FROM TubeWT__c]);
			endsMap = new Map<Id, TubeEnds__c> ([SELECT Id, Type__c FROM TubeEnds__c]);
			lsMap = new Map<Id, TubeLengthSize__c> ([SELECT Id, Name, MaxLength__c FROM TubeLengthSize__c]);
			wsgMap = new Map<Id, WheelSteelGrade__c> ([SELECT Id, Name FROM WheelSteelGrade__c]);
			wodMap = new Map<Id, WheelDiameter__c> ([SELECT Id, OD_mm__c, Name FROM WheelDiameter__c]);
			whMap = new Map<Id, WheelHub__c> ([SELECT Id, Name FROM WheelHub__c]);
			wdMap = new Map<Id, WheelDrawing__c> ([SELECT Id, Name FROM WheelDrawing__c]);
		}

		if (Trigger.isInsert || Trigger.isUpdate || Trigger.isDelete) {
			oppMap2 = new Map<Id, Opportunity> ([SELECT Id, ID_ERP__c, OwnerId, CloseDate, Probability FROM Opportunity WHERE Id IN :oppIdSet]);
		}
		

		// Удалим все связанные записи из таблицы SalesPlanFact__c
		if (oldList != null) {
			deleteRelatedSPF();
		}
        
        if(Trigger.isUpdate || Trigger.isInsert){
            //checkCancelledProduct(oppliList);
        }
	}

	public void bulkAfter() {
		System.debug('bulkAfterOLI');

		if (Trigger.isUpdate) {
			Boolean rightStatus = false;
			for (SObject oliS : newList) {
				OpportunityLineItem oli = (OpportunityLineItem) oliS;
				OpportunityLineItem oliOld = (OpportunityLineItem) oldMap.get(oli.Id);
				if (oliOld.Stage__c != OLI_STAGENAME_SHIPPED && oli.Stage__c == OLI_STAGENAME_SHIPPED) {
					rightStatus = true;
					oppIds.put(oli.Id, oli.OpportunityId);
				}
			}
			if (rightStatus) {
				oppStages = [SELECT Id, ApiName FROM OpportunityStage WHERE IsWon = true AND IsClosed = true];
					oppMap = new Map<ID, Opportunity> ([SELECT Id, StageName, IsClosed, (SELECT Id, Stage__c FROM OpportunityLineItems) FROM Opportunity WHERE Id IN :oppIds.values() AND IsClosed = false]);
				closeRightOpps(newList);
				List<Opportunity> oppsToUpdateList = new List<Opportunity> (oppsToUpdate);
				update oppsToUpdateList;
			}

			Set<Id> oppWithChangesIds = new Set<Id>();
			List<Quote> quotesToUpdate = new List<Quote>();
			for (SObject oliS : newList) {
				OpportunityLineItem oli = (OpportunityLineItem) oliS;
				OpportunityLineItem oliOld = (OpportunityLineItem) oldMap.get(oli.Id);
				if (oliOld.FinalCDD__c != oli.FinalCDD__c || oliOld.InquiryUnit__c != oli.InquiryUnit__c) {
					oppWithChangesIds.add(oli.OpportunityId);
				}
			}
			if(oppWithChangesIds.size()!=0){
				List<Opportunity> oppListWithOLIs = [SELECT Id, CurrencyIsoCode, (SELECT Id, FinalCDD__c, InquiryUnit__c FROM OpportunityLineItems), (SELECT Id, IsSyncing, Production_Delivery__c FROM Quotes) FROM Opportunity WHERE Id IN :oppWithChangesIds];
				for(Opportunity opp : oppListWithOLIs){
					List<Date> cdds = new List<Date>();
					for(OpportunityLineItem oli : opp.OpportunityLineItems){
						cdds.add(oli.FinalCDD__c);
					}
					cdds.sort();
					if(cdds.size()>0){
						for(Quote qu : opp.Quotes){
							qu.Production_Delivery__c = cdds.get(cdds.size()-1)!=null ? cdds.get(cdds.size()-1).format() : '';
							qu.Invoicing__c = opp.CurrencyIsoCode + ', ' + QuoteTriggerHandler.getApinameToLabelMap().get(opp.OpportunityLineItems[0].InquiryUnit__c);
							quotesToUpdate.add(qu);
						}	
					}				
				}
				update quotesToUpdate;
			}

            List<OpportunityLineItem> oliWithChangedQuantityOrQt = new List<OpportunityLineItem>();
            Map<Id,OpportunityLineItem> oldOliMap = (Map<Id,OpportunityLineItem>)oldMap;
            for(OpportunityLineItem oli : (List<OpportunityLineItem>) newList) {
                system.debug('new '+oli.Quantity+' old '+oldOliMap.get(oli.Id).Quantity);
                if (oli.Quantity != oldOliMap.get(oli.Id).Quantity
                    	|| oli.QuotaType__c != oldOLiMap.get(oli.Id).QuotaType__c) {
                    oliWithChangedQuantityOrQt.add(oli);
                }
            }
            if(!oliWithChangedQuantityOrQt.isEmpty()) { system.debug('oliWithChangedQuantityOrQt not empty');
                updateActualQuantityOnShopQuota((List<OpportunityLineItem>) newList,(Map<Id,OpportunityLineItem>)oldMap,null);
            } else if (oliWithChangedQuantityOrQt.isEmpty() && Trigger.isUpdate){
                system.debug('in update for add shop quota');
                updateActualQuantityOnShopQuota((List<OpportunityLineItem>) newList,(Map<Id,OpportunityLineItem>)oldMap,null);
                
            }
            
            //23 12 new fragment
            if(!Test.isRunningTest()){
            //ProductionQuoteUpdateOppItem updateToProdQuotaBatch = new ProductionQuoteUpdateOppItem(newList);
            //Id updateToProdQuotaBatchID = Database.executeBatch(updateToProdQuotaBatch,30);
            }
		}

		//Bahtiyar 2018-07-25: добавил новый фрагмент кода: --------------------
		if (Trigger.isInsert || Trigger.isUpdate || Trigger.isUndelete) {
			//Сформируем список соответствий, для мастер-объектов Opportunity, чтоб потом считывать значения их полей при создании записей в объекте SalesPlanFact__c.
			Set<Id> oppIdSet = new Set<Id>();
			for (sObject oli : newList) {
				oppIdSet.add(((OpportunityLineItem) oli).OpportunityId);
			}
			oppMapForSPF = New Map<Id,Opportunity>(
					[	SELECT Id, MarketSegment__c, Region__c, AdditionalNumber__c, Country__c, OwnerId, CurrencyIsoCode, CloseDate, AccountId, Probability, StageName, IsSecondChoice__c
						FROM Opportunity
						WHERE Id In :oppIdSet
					]);
		}
		//----------------------------------------------------------------------
		if(Trigger.isInsert){
            system.debug('AFTER INSERT BULk HERE');
            Set<id> opportunitySetIds = new Set<id>();
            Set<id> productSetIds = new Set<id>();
            List<OpportunityLineItem> oppliList = (List<OpportunityLineItem>) newList;
            
            AutomatedFamilyField updateJob = new AutomatedFamilyField(oppliList);
            ID jobID = System.enqueueJob(updateJob);
                                    
            updateActualQuantityOnShopQuota(oppliList,null,null);
            
            //23.12 
            if(!Test.isRunningTest()){
            //ProductionQuoteAddOppItem addToProdQuotaBatch = new ProductionQuoteAddOppItem(newList);
            //Id addToProdQuotaBatchID = Database.executeBatch(addToProdQuotaBatch,30);
            }
        }
        
        if(Trigger.isDelete){
            system.debug('delete event');
            Set<Id> oppIds = new Set<Id>();
            Set<id> products2idDeletedItems = new Set<id>();
            List<OpportunityLineItem> oppliList = (List<OpportunityLineItem>) oldList;
           AutomatedFamilyFieldOnDelete updateJob = new AutomatedFamilyFieldOnDelete(oppliList);
		   ID jobID = System.enqueueJob(updateJob);	            
            
            List<OpportunityLineItem> deletedOliWithQuotaType = new List<OpportunityLineItem>();
            for(OpportunityLineItem deletedOli : (List<OpportunityLineItem>) oldList) {
                if(deletedOli.QuotaType__c != null) {
                    deletedOliWithQuotaType.add(deletedOli);
                }
            }
            
            if(!deletedOliWithQuotaType.isEmpty()) {
                system.debug('oli not empty');
          		updateActualQuantityOnShopQuota(null,null,deletedOliWithQuotaType);
            }
            
           
        }

		//syncCustomerEnquiryProducts();
	}

	public void beforeInsert(SObject so) {
		System.debug('beforeInsertOLI');
		OpportunityLineItem oli = (OpportunityLineItem) so;
			
		fillName(oli);
		
		ERPProfile__c erpProf = ERPProfile__c.getInstance();
		if(!erpProf.SkipRecount__c){
			inquiryUnitQuantityChanged = oli.InquiryQuantity__c != null;
			inquiryUnitPriceChanged = oli.InquiryUnitPrice__c != null;
			Boolean inquiryRelatedFieldChanged = inquiryUnitQuantityChanged || inquiryUnitPriceChanged;

			tonnQuantityChanged = oli.Quantity != null;
			tonnPriceChanged = oli.UnitPrice != null;
			Boolean tonnRelatedFieldChanged = tonnQuantityChanged || tonnPriceChanged;

			if (inquiryRelatedFieldChanged && tonnRelatedFieldChanged && oli.Quantity != null && oli.UnitPrice != Null) {
				//recountTonnGroupValues(oli);
				//oli.addError('You cannot change inquiry measurement unit values and metric tonn values at once. Please, cancel one of these changes.');
				// Не делаем ничего вообще, т.к. в этом случае возможно нам пришли готовые данные из ИТ при обмене.
			} else if (inquiryRelatedFieldChanged) {
				recountTonnGroupValues(oli);
			} else if (tonnRelatedFieldChanged) {
				recountInquiryUnitGroupValues(oli);
			}
		}

		fillNPP_ERP(oli);
		calculateMargin(oli);
		setSecondChoice(oli);
	}

	public void beforeUpdate(SObject oldSo, SObject so) {
		System.debug('beforeUpdateOLI');
		
		OpportunityLineItem oli = (OpportunityLineItem) so;	
		OpportunityLineItem oldOLI = (OpportunityLineItem) oldMap.get(oli.Id);
		
		if(Math.abs(oli.TotalPrice - oldOLI.TotalPrice) < 0.001) {
			oli.TotalPrice = oldOLI.TotalPrice;
		}

		Boolean odChanged = (oli.TubeOD__c != oldOLI.TubeOD__c);
		Boolean wtChanged = (oli.TubeWT__c != oldOLI.TubeWT__c);
		Boolean lsChanged = (oli.LengthSize__c != oldOLI.LengthSize__c);
		Boolean sgChanged = (oli.SteelGrade__c != oldOLI.SteelGrade__c);
		
		//if (odChanged || wtChanged || lsChanged || sgChanged) {
			fillName(oli);			
		//}
		
		ERPProfile__c erpProf = ERPProfile__c.getInstance();
		if (!erpProf.SkipRecount__c) {
			inquiryUnitChanged = oli.InquiryUnit__c != oldOLI.InquiryUnit__c;
			if (oli.InquiryQuantity__c != null && oldOLI.InquiryQuantity__c != null) {
				inquiryUnitQuantityChanged = oli.InquiryQuantity__c.setScale(3) != oldOLI.InquiryQuantity__c.setScale(3);
			} else {
				inquiryUnitQuantityChanged = oli.InquiryQuantity__c != oldOLI.InquiryQuantity__c;
			}
			if (oli.InquiryUnitPrice__c != null && oldOLI.InquiryUnitPrice__c != null) {
				inquiryUnitPriceChanged = oli.InquiryUnitPrice__c.setScale(2) != oldOLI.InquiryUnitPrice__c.setScale(2);
			} else {
				inquiryUnitPriceChanged = oli.InquiryUnitPrice__c != oldOLI.InquiryUnitPrice__c;
			}
			Boolean inquiryRelatedFieldChanged = inquiryUnitChanged || inquiryUnitQuantityChanged || inquiryUnitPriceChanged;

			if (oli.Quantity != null && oldOLI.Quantity != null) {
				tonnQuantityChanged = oli.Quantity.setScale(3) != oldOLI.Quantity.setScale(3);
			} else {
				tonnQuantityChanged = oli.Quantity != oldOLI.Quantity;
			}
			if (oli.UnitPrice != null && oldOLI.UnitPrice != null) {
				tonnPriceChanged = oli.UnitPrice.setScale(2) != oldOLI.UnitPrice.setScale(2);
			} else {
				tonnPriceChanged = oli.UnitPrice != oldOLI.UnitPrice;
			}
			Boolean tonnRelatedFieldChanged = tonnQuantityChanged || tonnPriceChanged;
			
			if (inquiryRelatedFieldChanged && tonnRelatedFieldChanged) {
				//recountTonnGroupValues(oli);
				//oli.addError('You cannot change inquiry measurement unit values and metric tonn values at once. Please, cancel one of these changes.');
				// Не делаем ничего вообще, т.к. в этом случае возможно нам пришли готовые данные из ИТ при обмене.
			} else if (inquiryRelatedFieldChanged || odChanged || wtChanged || lsChanged || sgChanged || oli.Quantity == 0) {
				recountTonnGroupValues(oli);
			} else if (tonnRelatedFieldChanged) {
				recountInquiryUnitGroupValues(oli);
			}
		}

		fillNPP_ERP(oli);
		calculateMargin(oli);
		setSecondChoice(oli);
	}

	public void beforeDelete(SObject so) {
		System.debug('beforeDeleteOLI');
		OpportunityLineItem oli = (OpportunityLineItem) so;
	}

	public void afterInsert(SObject so) {
		System.debug('afterInsertOLI');

		// Bahtiyar 2018-07-25: создадим записи в объекте SalesPlanFact__c
			OpportunityLineItem oppLineItem = (OpportunityLineItem) so;
			createRelatedSPF((OpportunityLineItem) so);
	}

	public void afterUpdate(SObject oldSo, SObject so) {
		System.debug('afterUpdateOLI');

		// Bahtiyar 2018-07-25: создадим записи в объекте SalesPlanFact__c
			OpportunityLineItem oppLineItem = (OpportunityLineItem) so;
			createRelatedSPF((OpportunityLineItem) so);
	}



	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Helpers

	private void setSecondChoice(OpportunityLineItem oli) {
		Boolean isSecondChoice = psMap.get(oli.ProductStandard__c)?.IsSecondChoice__c;
		oli.IsSecondChoiceProduct__c = isSecondChoice == null ? false : isSecondChoice;
	}

	public void closeRightOpps(List<SObject> newList) {
		for (SObject so : newList) {
			OpportunityLineItem oppLineItem = (OpportunityLineItem) so;
			OpportunityLineItem oliOld = (OpportunityLineItem) oldMap.get(oppLineItem.Id);

			Opportunity opp = oppMap.get(oppIds.get(oppLineItem.Id));
			if (oliOld.Stage__c != OLI_STAGENAME_SHIPPED && oppLineItem.Stage__c == OLI_STAGENAME_SHIPPED && opp != null && !oppsToUpdate.contains(opp)) {
				Integer shippedOppProdcuts = 0;
				for (OpportunityLineItem oppProduct : opp.OpportunityLineItems) {
					if (oppProduct.Stage__c == OLI_STAGENAME_SHIPPED) {
						shippedOppProdcuts++;
					}
				}
				if (shippedOppProdcuts == opp.OpportunityLineItems.size()) {
					opp.StageName = oppStages[0].ApiName;
					oppsToUpdate.add(opp);
				}
				System.debug(opp);
			}
		}
	}

	
	
	public void fillName(OpportunityLineItem oli) {
		system.debug('oli  ' + oli);
		System.debug('prodMap ' +prodMap.get(oli.Product2Id));
		if (prodMap.get(oli.Product2Id).Type__c == 'Tube') {
			String sg = (sgMap.get(oli.SteelGrade__c) != null ? sgMap.get(oli.SteelGrade__c).Name : '');
			String od = (odMap.get(oli.TubeOD__c) != null ? String.valueOf(odMap.get(oli.TubeOD__c).OD_mm__c) : '');
			String wt = (wtMap.get(oli.TubeWT__c) != null ? String.valueOf(wtMap.get(oli.TubeWT__c).WT_mm__c) : '');
			String ls = (lsMap.get(oli.LengthSize__c) != null ? lsMap.get(oli.LengthSize__c).Name : '');
			oli.Name__c = sg + ' ' + od + 'x' + wt + ' ' + ls;
		} else {
			String wsg = (wsgMap.get(oli.WheelSteelGrade__c) != null ? wsgMap.get(oli.WheelSteelGrade__c).Name : '');
			String wod = (wodMap.get(oli.WheelDiameter__c) != null ? String.valueOf(wodMap.get(oli.WheelDiameter__c).OD_mm__c) : '');
			String wh = (whMap.get(oli.WheelHub__c) != null ? whMap.get(oli.WheelHub__c).Name : '');
			String wd = (wdMap.get(oli.WheelDrawing__c) != null ? wdMap.get(oli.WheelDrawing__c).Name : '');
			oli.Name__c = wsg + '|' + wod + '|' + ((String.isNotBlank(wh) || wh.toLowerCase() == '<not specified>') ? wh + '|' : '') + wd;
		}
	}

	
	
	public void recountTonnGroupValues(OpportunityLineItem oli){
		if (inquiryUnitQuantityChanged || inquiryUnitChanged) {
			if(odMap.get(oli.TubeOD__c) != null && wtMap.get(oli.TubeWT__c) != null) {
				if(odMap.get(oli.TubeOD__c).OD_mm__c!=null && wtMap.get(oli.TubeWT__c).WT_mm__c!=null) {
					//Map<String, Decimal> plw = PipeWeightCalculations.getPipeLinearWeight(prodMap.get(oli.Product2Id), gpsMap.get(oli.ProductStandard__r.GeneralProductStandard__c), odMap.get(oli.TubeOD__c), wtMap.get(oli.TubeWT__c), endsMap.get(oli.TubeEnds__c));
					//Decimal oneMeterWeight = plw.get('kpm');
					//Decimal oneFootWeigth = plw.get('ppf');
					Decimal oneMeterWeight = oli.Weight_kpm__c;
					Decimal oneFootWeigth = oli.Weight_ppf__c;

					System.debug('One meter weight: ' + oneMeterWeight);
					System.debug('One foot weight: ' + oneFootWeigth);

					if (oli.InquiryUnit__c=='34') {
						// Tons (t)
	        			oli.Quantity = oli.InquiryQuantity__c;
						oli.Quantity_m__c = (1000 * oli.Quantity)/oneMeterWeight;
						oli.Quantity_ft__c = oli.Quantity_m__c/0.3048;
						if (oli.LengthSize__c!=null) {
							Decimal maxL = lsMap.get(oli.LengthSize__c).MaxLength__c;
							if (maxL != null && maxL != 0) {
								oli.Quantity_pcs__c = (oli.Quantity_m__c * 1000 / maxL).round(System.RoundingMode.UP);
							} else {
								oli.Quantity_pcs__c = null;
							}
						} else {
							oli.Quantity_pcs__c = null;
						}			          
					} else if (oli.InquiryUnit__c=='20') {
						// Meters (m)
						oli.Quantity_m__c = oli.InquiryQuantity__c;
						oli.Quantity_ft__c = oli.Quantity_m__c/0.3048;
						oli.Quantity = oneMeterWeight != null ? (oli.Quantity_m__c * oneMeterWeight)/1000 : 0.01;
						if(oli.LengthSize__c!=null){
							Decimal maxL = lsMap.get(oli.LengthSize__c).MaxLength__c;
							if(maxL != null && maxL != 0){
								oli.Quantity_pcs__c = (oli.Quantity_m__c * 1000 / maxL).round(System.RoundingMode.UP);
							} else {
								oli.Quantity_pcs__c = null;
							}
						} else {
							oli.Quantity_pcs__c = null;
						}			
					} else if (oli.InquiryUnit__c=='74') {
						// Feet (ft)
	        			oli.Quantity_ft__c = oli.InquiryQuantity__c;
						oli.Quantity_m__c = 0.3048 * oli.Quantity_ft__c;
						oli.Quantity = (oli.Quantity_m__c * oneMeterWeight)/1000;
						if (oli.LengthSize__c!=null) {
							Decimal maxL = lsMap.get(oli.LengthSize__c).MaxLength__c;
							if (maxL != null && maxL != 0) {
								oli.Quantity_pcs__c = (oli.Quantity_m__c * 1000 / maxL).round(System.RoundingMode.UP);
							} else {
								oli.Quantity_pcs__c = null;
							}
						} else {
							oli.Quantity_pcs__c = null;
						}
					} else if(oli.InquiryUnit__c=='43') {
						// Pieces (pcs)
	        			oli.Quantity_pcs__c = oli.InquiryQuantity__c;
						if (oli.LengthSize__c!=null) {
							if (lsMap.get(oli.LengthSize__c).MaxLength__c!=null && lsMap.get(oli.LengthSize__c).MaxLength__c!=0) {
								oli.Quantity_m__c = lsMap.get(oli.LengthSize__c).MaxLength__c/1000 * oli.Quantity_pcs__c;
								System.debug(oli.Quantity_m__c);
								oli.Quantity_ft__c = oli.Quantity_m__c/0.3048;
								oli.Quantity = (oli.Quantity_m__c * oneMeterWeight)/1000;
							} else {
								oli.addError('Max Length in Length Size is empty.');
							}
						} else {
							oli.addError('Length Size is empty.');
						}
					}
				}
			} else if (oli.InquiryUnit__c == '34') {
				oli.Quantity = oli.InquiryQuantity__c;
				oli.Quantity_m__c = null;
				oli.Quantity_ft__c = null;
				oli.Quantity_pcs__c = null;
			}
		}


		//if (inquiryUnitPriceChanged) {
			//if(oli.InquiryUnitPrice__c!=null && oli.InquiryQuantity__c!=null && oli.Quantity!=null && oli.Quantity != 0) {
				//if (oli.InquiryUnitPrice__c != null) {
					//oli.UnitPrice = (oli.InquiryUnitPrice__c * oli.InquiryQuantity__c) / oli.Quantity;
				//} else if (oli.UnitPrice != null) {
					//oli.InquiryUnitPrice__c = (oli.UnitPrice * oli.Quantity) / oli.InquiryQuantity__c;
				//}
			//}
		//}
		if (inquiryUnitPriceChanged) {
			if (oli.InquiryUnit__c == '34') {
				oli.UnitPrice = oli.InquiryUnitPrice__c;
			} else if (oli.Quantity != null && oli.Quantity != 0) {
				oli.UnitPrice = (oli.InquiryUnitPrice__c * oli.InquiryQuantity__c) / oli.Quantity;
			} else {
				oli.UnitPrice = 0;
			}
		}

		System.debug(oli.Quantity);
    }



	public void recountInquiryUnitGroupValues(OpportunityLineItem oli){
		if (tonnQuantityChanged) {
			if(odMap.get(oli.TubeOD__c)!=null && wtMap.get(oli.TubeWT__c)!=null){
				System.debug('GPS map: ' + gpsMap);
				System.debug('Product Standard: ' + oli.ProductStandard__c);
				System.debug('General Product Standard: ' + oli.ProductStandard__r.GeneralProductStandard__c);
				//Map<String, Decimal> plw = PipeWeightCalculations.getPipeLinearWeight(prodMap.get(oli.Product2Id), gpsMap.get(oli.ProductStandard__r.GeneralProductStandard__c), odMap.get(oli.TubeOD__c), wtMap.get(oli.TubeWT__c), endsMap.get(oli.TubeEnds__c));
				//Decimal oneMeterWeight = plw.get('kpm');
				//Decimal oneFootWeigth = plw.get('ppf');
				Decimal oneMeterWeight = oli.Weight_kpm__c;
				Decimal oneFootWeigth = oli.Weight_ppf__c;

				System.debug('One meter weight: ' + oneMeterWeight);
				System.debug('One foot weight: ' + oneFootWeigth);

				Decimal quantityMC = oneMeterWeight == 0 || oneMeterWeight == null ? 0 : (oli.Quantity*1000)/oneMeterWeight;
				System.debug(quantityMC);
				oli.Quantity_m__c = quantityMC;
				Decimal quantityFT = quantityMC/0.3048;
				oli.Quantity_ft__c = quantityFT;
				Decimal quantityPCS = null;
				if(oli.LengthSize__c!=null){
					Decimal maxL = lsMap.get(oli.LengthSize__c).MaxLength__c;
					System.debug(maxL);
					if(maxL != null && maxL != 0) {
						quantityPCS = (quantityMC * 1000 / maxL).round(System.RoundingMode.UP);
					}		
				}
				
				oli.Quantity_pcs__c = quantityPCS;

				System.debug(oli.Id);
				System.debug(oli.InquiryUnit__c);

				if(oli.InquiryUnit__c=='34'){
	        		oli.InquiryQuantity__c = oli.Quantity;
				}
				else if(oli.InquiryUnit__c=='20'){				
					oli.InquiryQuantity__c = quantityMC;
					System.debug(oli.InquiryQuantity__c);
				}
				else if(oli.InquiryUnit__c=='74'){
					oli.InquiryQuantity__c = quantityFT;
				}
				else if(oli.InquiryUnit__c=='43'){
					oli.InquiryQuantity__c = quantityPCS;
				}
			}
		}

		
		//if (tonnPriceChanged) {
			//if(oli.InquiryQuantity__c != null && oli.InquiryQuantity__c != 0) {
				//System.debug('change sales prcie');
				//if (oli.UnitPrice != null) {
					//oli.InquiryUnitPrice__c = (oli.UnitPrice*oli.Quantity)/oli.InquiryQuantity__c;
				//} else if (oli.InquiryUnitPrice__c != null) {
					//oli.UnitPrice = (oli.InquiryUnitPrice__c*oli.InquiryQuantity__c)/oli.Quantity;
				//}
			//}
		//}
		if (tonnPriceChanged){
			if (oli.InquiryUnit__c == '34') {
				oli.InquiryUnitPrice__c = oli.UnitPrice;
			} else if (oli.InquiryQuantity__c != null && oli.InquiryQuantity__c != 0) {
				oli.InquiryUnitPrice__c = (oli.UnitPrice * oli.Quantity) / oli.InquiryQuantity__c;
			} else {
				oli.InquiryUnitPrice__c = 0;
			}
		}
    }

	public void fillNPP_ERP(OpportunityLineItem oli) {		
		if (oppMap2.size() > 0 && String.isNotBlank(oppMap2.get(oli.OpportunityId).ID_ERP__c) && String.isNotBlank(oli.NPP_ERP__c)) {
			oli.ID_ERP__c = oppMap2.get(oli.OpportunityId).ID_ERP__c + '-' + oli.NPP_ERP__c;
		}
	}
		
	public void calculateMargin(OpportunityLineItem oli) {
		if (oli.Quantity != null && oli.Quantity > 0 && oli.Margin_t__c != null && oli.Margin_t__c > 0) {
			oli.Margin__c = oli.Quantity * oli.Margin_t__c;
		}
	}

	public void afterDelete(SObject so) {
		System.debug('After Delete');
	}

	public void postProcessing() {
		System.debug('Post Processing');

		// Запишем созданные записи в объекте SalesPlanFact__c
		if (Trigger.isInsert || Trigger.isUpdate || Trigger.isUndelete) {
			System.debug(spfToInsert);
			insert spfToInsert;
			spfToInsert.clear();
		}
	}

	
	//{Bahtiyar 2018-07-25: добавил блок процедур для создания записей в объекте SalesPlanFact__c -------------------------------------------------
	public void deleteRelatedSPF() {
		
		// Соберем список текстовых Id, который будем использовать для фильтрации запроса
		Set<String> textIdSet = New Set<String>();
		For (Integer i = 0; i < oldList.size(); i++) {
			textIdSet.add(oldList[i].Id);
		}
		
		// Удалим старые связанные записи из таблицы SalesPlanFact__c
		delete [Select Id from SalesPlanFact__c where InitialRecordId__c in :textIdSet];
	}

	public void createRelatedSPF(OpportunityLineItem oli) {
	System.debug('createRelatedSPF');
		
		Opportunity opp = oppMapForSPF.get(oli.OpportunityId);

		if (opp.StageName != 'Closed Lost' && opp.StageName != 'Closed Won' && (opp.Probability >= 70 || oli.Stage__c == 'Confirmed') && !oliSet.contains(oli.Id)) {
			SalesPlanFact__c spf = new SalesPlanFact__c();

			spf.InitialRecordId__c = String.valueOf(oli.Id);
			spf.InitialRecordURL__c = URL.getSalesforceBaseUrl().toExternalForm() + '/' + oli.Id;
			spf.OrderAdditionalNumber__c = opp.AdditionalNumber__c;
			// Оппу записываем на месяц вперед, т.к. если контракт будет в этом месяце, то производство в следующем
			Date prodDate = opp.CloseDate.addMonths(1);
			prodDate = Date.newInstance(prodDate.year(), prodDate.month(), 1);
			spf.Period__c = prodDate;
			//----------------------------------------------------------------
			spf.RecordTypeId = RT_OPPORTUNITY;
			spf.Shop__c = oli.Shop__c;
			spf.MarketSegment__c = opp.MarketSegment__c;
			spf.Region__c = opp.Region__c;
			spf.Country__c = opp.Country__c;
			spf.Account__c = opp.AccountId;
			spf.OwnerId = opp.OwnerId;
			spf.CurrencyIsoCode = opp.CurrencyIsoCode;
			spf.ProductionAmount__c = oli.Quantity;
			spf.SalesAmount__c = 0;
			spf.Revenue__c = 0;
			spf.Margin__c = 0;
			spf.Margin_t__c = 0;
			spf.Probability__c = opp.Probability;
			spf.SecondChoice__c = opp.IsSecondChoice__c;

			spfToInsert.add(spf);
			oliSet.add(oli.Id);
			System.debug(oliSet);
		}
        
        
	}
	//} Блок процедур для создания записей в объекте SalesPlanFact__c ---------------------------------------------------------------------------
	
	
    
    public void updateActualQuantityOnShopQuota(List<OpportunityLineItem> oliList, Map<Id,OpportunityLineItem> oldMap, List<OpportunityLineItem> deletedOliList) {
		Map<Id,Map<Id,List<Shop_Quota__c>>> sqByOppAndQt = new Map<Id,Map<Id,List<Shop_Quota__c>>>();
        Map<Id,Map<String,List<Shop_Quota__c>>> sqByGroupQtAndCdd = new Map<Id,Map<String,List<Shop_Quota__c>>>();
		List<Shop_Quota__c> newShopQuotas = new List<Shop_Quota__c>();
        Set<Id> oppIds = new Set<Id>();
        Set<Id> quotaTypesIds = new Set<Id>();
     	Set<Id> oldQuoteTypesIds = new Set<Id>();
        Set<Id> existingQuoteTypesIds = new Set<id>(); 
        Set<id> deleteOliIds = new Set<Id>();
        Set<id> deleteOliIdsPOpp = new Set<Id>();
        //system.debug('in shop quota');       
        //system.debug(oliList.size());
        try{
                   		
            if(oliList == null) {
                oliList = new List<OpportunityLineItem>();
            }
            
            for (OpportunityLineItem oli : oliList) {
                    oppIds.add(oli.OpportunityId);
                    quotaTypesIds.add(oli.QuotaType__c);
              
                if(Trigger.isUpdate){
                    existingQuoteTypesIds.add(oli.QuotaType__c);
                }
                /*
                if(Trigger.isDelete){
                    
                    existingQuoteTypesIds.add(oli.QuotaType__c);
                }
             */   	
            }
            
            if (oldMap != null) {
                for(OpportunityLineItem oldOli : oldMap.values()) {
                    quotaTypesIds.add(oldOli.QuotaType__c);
                }
            }
            
            if (deletedOliList != null) {
                for(OpportunityLineItem deletedOli : deletedOliList) {
                    oppIds.add(deletedOli.OpportunityId);
                    quotaTypesIds.add(deletedOli.QuotaType__c);
                    deleteOliIds.add(deletedOli.id);
                    deleteOliIdsPOpp.add(deletedOli.OpportunityId);
                }
            }
            
            List<Shop_Quota__c> shopQuotasList = [
                    SELECT Id,
                    Actual_Quantity__c,
                    Opportunity__c,
                    Quota_Type__c,
                	CDD__c
                    FROM Shop_Quota__c
                    WHERE Opportunity__c in :oppIds
                    AND Quota_Type__c in :quotaTypesIds
            ];
            system.debug(shopQuotasList);
            for (Shop_Quota__c shopQuota : shopQuotasList) {
                if(shopQuota.Actual_Quantity__c == null) {
                    shopQuota.Actual_Quantity__c = 0;
                }
                if(sqByGroupQtAndCdd.containsKey(shopQuota.Opportunity__c)) {
                    if(sqByGroupQtAndCdd.get(shopQuota.Opportunity__c).containsKey(String.valueof(shopQuota.Quota_Type__c)+String.valueof(shopQuota.CDD__c))) {
                        sqByGroupQtAndCdd.get(shopQuota.Opportunity__c).get(String.valueof(shopQuota.Quota_Type__c)+String.valueof(shopQuota.CDD__c)).add(shopQuota);
                    } else {
                        sqByGroupQtAndCdd.get(shopQuota.Opportunity__c).put(String.valueof(shopQuota.Quota_Type__c)+String.valueof(shopQuota.CDD__c), new List<Shop_Quota__c>{shopQuota});
                    }
                } else {
                    sqByGroupQtAndCdd.put(shopQuota.Opportunity__c,new Map<String,List<Shop_Quota__c>>());
                    sqByGroupQtAndCdd.get(shopQuota.Opportunity__c).put(String.valueof(shopQuota.Quota_Type__c)+String.valueof(shopQuota.CDD__c), new List<Shop_Quota__c>{shopQuota});
                }
            }
                               
            shopQuotasList.clear();
            
            for(OpportunityLineItem oli : oliList) {
                if(oli.QuotaType__c == null) {
                    continue;
                }
                
                if(sqByGroupQtAndCdd.containsKey(oli.OpportunityId)) {
                    Boolean isQuoteTypeChanged = false;
                    Boolean isQuantityChanged = false;
                    Decimal quantityDifference = oli.Quantity;
                    if(oldMap != null) {
                        isQuantityChanged = oli.Quantity != oldMap.get(oli.Id).Quantity;
                        isQuoteTypeChanged = oli.QuotaType__c != oldMap.get(oli.Id).QuotaType__c;
                        
                        //system.debug('bag 3');
                        if((isQuoteTypeChanged && isQuantityChanged) || isQuoteTypeChanged) {                           
                            sqByGroupQtAndCdd.get(oli.OpportunityId).get(String.valueof(oldMap.get(oli.Id).QuotaType__c)+String.valueOf(oldMap.get(oli.Id).FinalCDD__c))[0].Actual_Quantity__c -= oldMap.get(oli.Id).Quantity;
                        } else if (!isQuoteTypeChanged && isQuantityChanged) {                          
                            //system.debug('check quantity difference');                          
                            quantityDifference = oli.Quantity - oldMap.get(oli.Id).Quantity;
                        }
                    }
    				//system.debug('bag 4');
                    if(sqByGroupQtAndCdd.get(oli.OpportunityId).containsKey(String.valueof(oli.QuotaType__c)+String.valueOf(oli.FinalCDD__c))) { system.debug('bag 4.1');                                                                                          
                            if(sqByGroupQtAndCdd.get(oli.opportunityId).get(String.valueof(oli.QuotaType__c)+String.valueOf(oli.FinalCDD__c))[0].Actual_Quantity__c == null){
                                        sqByGroupQtAndCdd.get(oli.opportunityId).get(String.valueof(oli.QuotaType__c)+String.valueOf(oli.FinalCDD__c))[0].Actual_Quantity__c = 0;
                             } 
                                if(!isQuantityChanged && Trigger.isUpdate){ system.debug('in if for continue');continue;}
                           
                           // system.debug('change value');
                                                                                                        
                            sqByGroupQtAndCdd.get(oli.opportunityId).get(String.valueof(oli.QuotaType__c)+String.valueOf(oli.FinalCDD__c))[0].Actual_Quantity__c += quantityDifference;                                                               
                                                                                         
                    } else {system.debug('bag 4.2');
                        Shop_Quota__c newSq = new Shop_Quota__c();
                        newSq.Opportunity__c = oli.OpportunityId;
                        newSq.Quota_Type__c = oli.QuotaType__c;
                        newSq.CDD__c = oli.FinalCDD__c; 
                         // newSq.Actual_Quantity__c = 0;
                        //sqByOppAndQt.get(oli.OpportunityId).put(oli.QuotaType__c,new List<Shop_Quota__c>{newSq}); system.debug('bag 5');
                        sqByGroupQtAndCdd.get(oli.opportunityId).put(String.valueof(oli.QuotaType__c)+String.valueOf(oli.FinalCDD__c),new List<Shop_Quota__c>{newSq});    
                    }
                } else { system.debug('bag 6');
                    Shop_Quota__c newSq = new Shop_Quota__c();
                    newSq.Opportunity__c = oli.OpportunityId;
                    newSq.Quota_Type__c = oli.QuotaType__c;
                    newSq.CDD__c = oli.FinalCDD__c; 
                    sqByGroupQtAndCdd.put(oli.opportunityId,new Map<String,List<Shop_Quota__c>>());
                    sqByGroupQtAndCdd.get(oli.opportunityId).put(String.valueof(oli.QuotaType__c)+String.valueOf(oli.FinalCDD__c),new List<Shop_Quota__c>{newSq});
                }
            }
            //system.debug('bag 5');
            if (deletedOliList != null) {
                //system.debug('on delete oli');
                for(OpportunityLineItem deletedOli : deletedOliList) {
                    if(sqByGroupQtAndCdd?.get(deletedOli.OpportunityId)?.get(String.valueof(deletedOli.QuotaType__c)+String.valueOf(deletedOli.FinalCDD__c)) != null) {
                        sqByGroupQtAndCdd.get(deletedOli.OpportunityId).get(String.valueof(deletedOli.QuotaType__c)+String.valueOf(deletedOli.FinalCDD__c))[0].Actual_Quantity__c -= deletedOli.Quantity;
                    }
                }
            }
            
            for(Map<String,List<Shop_Quota__c>> innerMap : sqByGroupQtAndCdd.values()) {
                List<List<Shop_Quota__c>> innerListOfLists = innerMap.values();
                for(List<Shop_Quota__c> innerList : innerListOfLists) {
                //  shopQuotasList.addAll(innerList);
					for(Shop_Quota__c inList : innerList){
						if (inList?.id != null) {
							shopQuotasList.add(inList);
						}else{
							newShopQuotas.add(inList);
						}
					}
                }
            }
            // НЕ міняти на upsert
			update shopQuotasList;
            insert newShopQuotas;

            
            //23.12 
            if(!Test.isRunningTest()){
              //ProductionQuoteAddShopQuota addProductionQuoteAddShopQuota = new ProductionQuoteAddShopQuota(shopQuotasList);
              //Id addProductionQuoteAddShopQuotaId = Database.executeBatch(addProductionQuoteAddShopQuota,1);  
            }
            
            
            if(Trigger.isUpdate){
                  DeleteExtraShopQuotaOpportunity deleteExtraShopQuotas = new DeleteExtraShopQuotaOpportunity(existingQuoteTypesIds,oppIds);
				  ID jobID = System.enqueueJob(deleteExtraShopQuotas); 
            }
        
            if(trigger.isDelete){
                DeleteExtraShopQuotaOpportunity deleteExtraShopQuotas = new DeleteExtraShopQuotaOpportunity(existingQuoteTypesIds,deleteOliIdsPOpp);
				  ID jobID3 = System.enqueueJob(deleteExtraShopQuotas); 
     //       DeleteExtraShopQuotaOpportunityOnDelete deleteExtraShopQuotas = new DeleteExtraShopQuotaOpportunityOnDelete(deleteOliIds,deleteOliIdsPOpp);
    //      ID jobID1 = System.enqueueJob(deleteExtraShopQuotas);
            }
            
        	}catch(Exception e){
             System.debug('An exception occurred: ' + e.getMessage());
        }
    }
    
    public void updateQuotaTypeField(List<OpportunityLineItem> oppliList){
        
        system.debug('================updateQuotaTypeField==================');
        system.debug(oppliList);
        string idDefaultQuoteType = 'empty';
        try{
        	idDefaultQuoteType = [SELECT ID FROM QuotaType__c WHERE NAME='Not Added' LIMIT 1].id;         
        } catch ( QueryException e ){
            system.debug(e.getMessage());
        }
        if(idDefaultQuoteType!='empty'){
        for(OpportunityLineItem oli : oppliList) {           
            oli.QuotaType__c = oli.QuotaType__c==null? idDefaultQuoteType:oli.QuotaType__c;            
        }
            }
    }
    
    
	
}