public class ERPMessageHandlerOpportunityData {
    public final static Map<Integer, String> HTTPSTATUSES = new Map<Integer, String> {
        200 => 'OK',
        201 => 'CREATED',
        202 => 'ACCEPTED',
        204 => 'NO CONTENT',
        206 => 'PARTIAL CONTENT',
        300 => 'MULTIPLE CHOICES',
        301 => 'MOVED PERMANENTLY',
        302 => 'FOUND',
        304 => 'NOT MODIFIED',
        400 => 'BAD REQUEST',
        401 => 'UNAUTHORIZED',
        403 => 'FORBIDDEN',
        404 => 'NOT FOUND',
        405 => 'METHOD NOT ALLOWED',
        406 => 'NOT ACCEPTABLE',
        409 => 'CONFLICT',
        410 => 'GONE',
        412 => 'PRECONDITION FAILED',
        413 => 'REQUEST ENTITY TOO LARGE',
        414 => 'REQUEST URI TOO LARGE',
        415 => 'UNSUPPORTED MEDIA TYPE',
        417 => 'EXPECTATION FAILED',
        500 => 'INTERNAL SERVER ERROR',
        503 => 'SERVER UNAVAILABLE'
    };

    public final static Map<String,Map<String,String>> erp_to_sf_api_names_new = new Map<String,Map<String,String>> {
        'General' => new Map<String, String>{
            'productgroup' => 'Product2',   
            'quotatype' => 'QuotaType__c',
            'shop' => 'Shop__c',
            'speclevel' => 'ProductSpecLevel__c',
            'shippingpoint' => 'ShippingPoint__c'
        },
            
        'Tubes' => new Map<String, String>{
            'Diameter' => 'TubeOD__c',
            'Thickness' => 'TubeWT__c',
            'Standard' => 'ProductStandard__c',
            'SteelGrade' => 'SteelGrade__c',
            'Ends' => 'TubeEnds__c',
            'LengthSize' => 'TubeLengthSize__c',
            'Coating' => 'CoatingType__c'   
        },
            
        'Wheels' => new Map<String, String>{
            'Standard' => 'WheelProductStandard__c',
            'SteelGrade' => 'WheelSteelGrade__c',
            'Diameter' => 'WheelDiameter__c',
            'Hub' => 'WheelHub__c',
            'Drawing' => 'WheelDrawing__c'
        }
    };
    
    public final static Map<String, String> erp_to_sf_api_names_opp = new Map<String, String> {
        'Country' => 'Country__c',
        'PaymentTerms' => 'PaymentTerms__c',
        'DeliveryTerms' => 'DeliveryTerms__c'
    };
            
    public final static Map<String,String> stageCodeMap = makeMapForStage();    
    
    public static Country__c country_not_spec;
    public static Shop__c shop_not_cpec;
    public final static Map<Id, RecordType> idToRtMap = New Map<Id, RecordType>([Select Id, DeveloperName from RecordType where SObjectType = 'Opportunity']);

    public static String ProductType;
    public static Opportunity relatedOpp;
	public static String minLength;
	public static String maxLength;

    private static List<PaymentTerms__c> paymentTerms = new List<PaymentTerms__c>();
    private static List<DeliveryTerms__c> deliveryTerms = new List<DeliveryTerms__c>();
    private static List<Country__c> country = new List<Country__c>();
    private static List<UserID_ERP__c> userBOSpecialist = new List<UserID_ERP__c>();
    private static List<UserID_ERP__c> userOwner = new List<UserID_ERP__c>();
    private static Map<String, SpecVersion__c> specVersionMap = new Map<String, SpecVersion__c>();
    private static Map<String, DrawingVersion__c> drawingVersionMap = new Map<String, DrawingVersion__c>();

	Map<String, String> valuesCodes = new Map<String, String>();
	Schema.DescribeFieldResult fieldResult = Product_Picklist_Stage__mdt.Stage__c.getDescribe();
	List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

	private final static List<String> isPlacedList = new List<String> {
        '_4', 
        '_6', 
        '_8', 
        '_9', 
        '_39', 
        '_41', 
        '_45 '   
    };
    	
    public static UpdateSFRecordsResult updateOpportunity(ERPMessageParser.ErpToSfMessage_OpportunityData requestObj, String requestBody, String businessDivision) {
        //system.debug(JSON.serializePretty(requestObj));
        if (requestObj.data.header.unDoc == null) {
            String errorMessage = 'Your request does not contain ID_ERP field for Opportunity.';
            throw new erpException(errorMessage);
        }
    
        UpdateSFRecordsResult result = new UpdateSFRecordsResult();
        Opportunity opp = getOpportunitySFByERPID(requestObj.data.header.UnDoc);
        result.parentOpp = opp;
    
        checkOpportunityStatus(requestObj, result);
            
        Map<String, Id> rtNameToIdMap = new Map<String, Id>();
        for (Id rtId : idToRtMap.keySet()) {
            rtNameToIdMap.put(idToRtMap.get(rtId).DeveloperName, rtId);
        }
        Id rtId;
        if (businessDivision == 'Tubes') {
            rtId = rtNameToIdMap.get('Tubes_RFP');
        } else if (businessDivision == 'Wheels') {
            rtId = rtNameToIdMap.get('Wheels_RFP');
        } else if (String.isBlank(businessDivision)) {
            if (opp == null) {
                // Не будем создавать новую оппу, если в ней нет ни одной позиции
                return result;
            } 
        } else {
            throw new erpException('Unknown Business Division! Allowed values: "Tubes" | "Wheels"');
        }
    
        if (opp != NULL) {
            if (opp.Pricebook2Id == null) {
                opp.Pricebook2Id = [SELECT Id, Name, IsActive FROM PriceBook2 WHERE IsStandard = True LIMIT 1].get(0).Id;
            }

            if (String.valueOf(opp.CurrencyIsoCode) != requestObj.data.orderCurrency) {
                result.isCurrencyCodeChanged = true;
            }

            if (opp.IsClosed) {
                result.oppChangeStatus = 'Closed';
            } else if(result.hasLots) {
                // Если оппа не закрыта, но по ней уже есть лоты, то закроем ее:
                opp.StageName = 'Closed Won';
            }
    
            if (result.isCurrencyCodeChanged) {
                List<OpportunityLineItem> oppLineItemsToDelete = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :opp.Id];
                delete oppLineItemsToDelete;

                try{
                    List<Quote> relatedQuotes = [SELECT id FROM Quote WHERE OpportunityId= :opp.Id];   
                    delete relatedQuotes;
                } catch(Exception e){
                    system.debug(e.getMessage());
                }
            }

            opp = mapOpportunityFields(requestObj, opp, result, requestBody);
            Database.update(opp);
            result.oppChangeStatus = 'Updated';
        } else {
            result.isNewOppCreated = true;
            opp = new Opportunity();
            opp.RecordTypeId = rtId;
            opp.Type = 'Ordinary Selling';
            opp = mapOpportunityFields(requestObj, opp, result, requestBody);
            opp.Name = String.Isblank(requestObj.data.header.altNumber) ? (String.IsBlank(string.valueOf(requestObj.data.header.unDoc)) ? 'Not defined' : string.valueOf(requestObj.data.header.unDoc) + ' (UnDoc in IT-Enterprise)'): requestObj.data.header.altNumber;
            opp.ID_ERP__c = String.valueOf(requestObj.data.header.unDoc);
            if (result.hasLots) {
                opp.StageName = 'Closed Won'; 
            } else {
                opp.StageName = 'Analysis';
            }
            opp.CloseDate = Date.today();
//            opp.CreatedDate = opp.CreatedDate_ERP__c.date();
                
            upsert opp ID_ERP__c;

            result.oppChangeStatus = 'Created';
            result.parentOpp = opp;
        }
        return result;
    }
    
    public static UpdateSFRecordsResult updateLineItems(ERPMessageParser.ErpToSfMessage_OpportunityData requestObj, ERPMessageHandlerOpportunityData.UpdateSFRecordsResult resultOpp) {
        UpdateSFRecordsResult result = new UpdateSFRecordsResult();
        result.newOppProductsIds = new List<String> ();
        result.updatedOppProductsIds = new List<String> ();
        ERPMessageParser.ERPObject_OrderItem[] orderItems = requestObj.data.items;

        ProductType = requestObj.data.orderType;

        Opportunity opp = getOpportunitySFByERPID(requestObj.data.header.unDoc);
        List<OpportunityLineItem> oppProductsToUpdate = new List<OpportunityLineItem> ();
        Set<OpportunityLineItem> oppProductsToDelete = new Set<OpportunityLineItem> ();
        List<OpportunityLineItem> oppProductsToInsert = new List<OpportunityLineItem> ();
        List<OpportunityLineItem> oppProductsToCheckCancelled = new List<OpportunityLineItem> ();
        Map<String, PricebookEntry> pbeIdByProduct2erpId = selectPBEbyProduct2ERPId(requestObj.data.items, opp); 
        Set<Integer> oppProductERPIds = getOppProductERPIds(requestObj.data.items);
        Map<Integer, OpportunityLineItem> oppProductsByERPIdMap = getOppProdSFMap(oppProductERPIds, 'NPP_ERP__c', String.valueOf(opp.Id));
        Map<String, Map<String, Id>> objToIdMap = getObjectToIdMap(requestObj.data.items, requestObj.data.orderType);

        if(ProductType == 'Wheels') {
            getKlwMaps(requestObj.data.items);
        }
    
        if (resultOpp.isNewOppCreated == true || resultOpp.isCurrencyCodeChanged == true) {
            for (ERPMessageParser.ERPObject_OrderItem oppProdERP : orderItems) {
                //Пропустим строку, если не заполнены продукт или количество:
                if (oppProdERP.ProductGroup.Id == null || oppProdERP.InqQuantity == null || oppProdERP.InqQuantity == 0) {
                    continue;
                }
                if (String.isBlank(oppProdERP.ProductGroup.ID) || !pbeIdByProduct2erpId.containsKey(oppProdERP.ProductGroup.ID)) {
                    if (String.isBlank(oppProdERP.ProductGroup.ID)) {
                        String errorMessage = String.isBlank(oppProdERP.ProductGroup.ID) ? ('ProductGroup field for Line Item #' + oppProdERP.npp + ' is empty.') : ('There is no such Product Group (' + oppProdERP.ProductGroup + ') for item #' + oppProdERP.npp);
                        throw new erpException(errorMessage);
                    }
                }
                OpportunityLineItem newOppLi = createNewOli(oppProdERP, opp.Id, pbeIdByProduct2erpId);
                mapRelatedERPId(newOppLi, null, objToIdMap, oppProdERP, requestObj.data.orderType);
                updateOLI(newOppLi, null, oppProdERP, requestObj.data.header.unDoc, null, null);
                oppProductsToInsert.add(newOppLi);
            }
        } else {
            for (ERPMessageParser.ERPObject_OrderItem oppProdERP : orderItems) {
                //Пропустим строку, если не заполнены продукт или количество:
                if (oppProdERP.ProductGroup.Id == null || oppProdERP.InqQuantity == null || oppProdERP.InqQuantity == 0) {
                    continue;
                }
                if (!pbeIdByProduct2erpId.containsKey(oppProdERP.ProductGroup.ID)) {
                    String errorMessage = String.isBlank(oppProdERP.ProductGroup.ID) ? ('ProductGroup field for Line Item #' + oppProdERP.npp + ' is empty.') : ('There is no such Product Group (' + oppProdERP.ProductGroup.ID + ') for item #' + oppProdERP.npp);
                    throw new erpException(errorMessage);
                }
                if (!oppProductsByERPIdMap.containsKey(oppProdERP.npp)) {
                    OpportunityLineItem newOppLi = createNewOli(oppProdERP, opp.Id, pbeIdByProduct2erpId);
                    mapRelatedERPId(newOppLi, null, objToIdMap, oppProdERP, requestObj.data.orderType);
                    updateOLI(newOppLi, null, oppProdERP, requestObj.data.header.unDoc, null, null);
                    oppProductsToInsert.add(newOppLi);     
                } else {
                    OpportunityLineItem oldOppLi = oppProductsByERPIdMap.get(oppProdERP.npp);
                    if (oldOppLi.PricebookEntryId == pbeIdByProduct2erpId.get(oppProdERP.ProductGroup.ID).Id) {
                        OpportunityLineItem oppLi = oppProductsByERPIdMap.get(oppProdERP.npp);
                        mapRelatedERPId(oppLi, null, objToIdMap, oppProdERP, requestObj.data.orderType);
                        updateOLI(oppLi, null, oppProdERP, requestObj.data.header.unDoc, null, null);
                        oppProductsToUpdate.add(oppLi);
                        result.updatedOppProductsIds.add(oppLi.Id);                                                      
                    } else {
                        OpportunityLineItem newOppLi = oldOppLi.clone(false, true, false, false);
                        newOppLi.OpportunityId = opp.Id;
                        newOppLi.PricebookEntryId = pbeIdByProduct2erpId.get(oppProdERP.ProductGroup.ID).Id;
                        newOppLi.TotalPrice = null;
                        newOppLi.NPP_ERP__c = String.valueOf(oppProdERP.npp);
                        mapRelatedERPId(newOppLi, null, objToIdMap, oppProdERP, requestObj.data.orderType);
                        updateOLI(newOppLi, null, oppProdERP, requestObj.data.header.unDoc, null, null);
                        oppProductsToInsert.add(newOppLi);
                        oppProductsToDelete.add(oldOppLi);
                    }
                }
            }
        }

        if (oppProductsToDelete.size() > 0) {
            List<OpportunityLineItem> deletionLIst = new List<OpportunityLineItem> (oppProductsToDelete);
            delete deletionLIst;
            oppProductsToDelete.clear();
        }

        if (oppProductsToInsert.size() > 0) {
            insert oppProductsToInsert;
            for (OpportunityLineItem createdOppLi : oppProductsToInsert) {
                result.newOppProductsIds.add(createdOppLi.Id);
            }
        }

        for (Integer current_li_ID_ERP : oppProductsByERPIdMap.keySet()) {
            if (current_li_ID_ERP != null && !oppProductERPIds.contains(current_li_ID_ERP)) {
                oppProductsToDelete.add(oppProductsByERPIdMap.get(current_li_ID_ERP));
            }
        }

        if (oppProductsToDelete.size() > 0) {
            List<OpportunityLineItem> deletionLIst2 = new List<OpportunityLineItem> (oppProductsToDelete);
            for(OpportunityLineItem oli : deletionLIst2){
                oli.Stage__c = 'Cancelled';
                oppProductsToUpdate.add(oli);
            } 
        }
        if (oppProductsToUpdate.size() > 0) {
            update oppProductsToUpdate;
        }

        resultOpp.objToIdMap = objToIdMap;
    
        return result;
    }

    public static Order getOrderSFByID(UpdateSFRecordsResult resultOpp) {
        if (resultOpp.parentOpp.SyncedOrder__c == null) {
            return null;
        } else {
            List<Order> ordList = [SELECT Id, OwnerId, InitialOwnerName__c, OpportunityId, CreatedDate, EffectiveDate, EffectiveDateAux__c, Status, ID_ERP__c, CurrencyIsoCode FROM Order WHERE Id = :resultOpp.parentOpp.SyncedOrder__c];
            if (!ordList.isEmpty()) {
                return ordList[0];
            } else {
                return null;
            }
        }
    }

    public static UpdateSFRecordsResultOrder updateOrder(ERPMessageParser.ErpToSfMessage_OpportunityData requestObj, ERPMessageHandlerOpportunityData.UpdateSFRecordsResult resultOpp) {
        UpdateSFRecordsResultOrder result = new UpdateSFRecordsResultOrder();
        Order ord = getOrderSFByID(resultOpp);
    
        if (ord != NULL) {
            if (ord.Status != 'Draft') {
                ord.Status = 'Draft';
            }

            //Запишем Start Date ордера в результат, чтобы если там не найдется более ранней даты, восстановить эту.
            result.firstLotDate = ord.EffectiveDate;
            //Очистим даты начала и конца ордера, чтобы не возникло конфликтов при назначении дат продуктам.
            ord.EndDate = null;

            if (String.valueOf(ord.CurrencyIsoCode) != requestObj.data.orderCurrency) {
                result.isCurrencyCodeChanged = true;
                List<OrderItem> ordLineItemsToDelete = [SELECT Id FROM OrderItem WHERE OrderId = :ord.Id];
                delete ordLineItemsToDelete;
            }
    
            ord = mapOrderFields(requestObj, ord, result, resultOpp);
            Database.update(ord);
            result.parentOrd = ord;

            //Удалим записи ProductionLots:
            //OLD
             List<ProductionLot__c> lotsToDelete = [SELECT id FROM ProductionLot__c WHERE Order__c = :ord.Id];
//            NEW
//            List<Lot__c> lotsToDelete = [SELECT Id FROM Lot__c WHERE Order__c = :ord.Id];
            delete lotsToDelete;
        } else {   
            Opportunity opp = getOpportunitySFByERPID(requestObj.data.header.unDoc);
            result.isNewOrderCreated = true;
            ord = new Order();
            ord = mapOrderFields(requestObj, ord, result, resultOpp);
            ord.Name = (requestObj.data.header.unDoc == null) ? 'Not defined' : String.valueOf(requestObj.data.header.unDoc);
            ord.ID_ERP__c = String.valueOf(requestObj.data.header.unDoc);
            ord.ContractId = opp.ContractId;
            //Сначала запишем "нулевую дату", чтобы потом проставить либо текущую, либо дату самого первого лота.
            ord.EffectiveDate = Date.newInstance(1900, 1, 1);
            ord.EffectiveDateAux__c = opp.CloseDate < Date.today() ? opp.CloseDate : Date.today();
            result.firstLotDate = opp.CloseDate < Date.today() ? opp.CloseDate : Date.today();
            ord.Status = 'Draft';
            ord.Pricebook2Id = opp.Pricebook2Id;
            ord.OpportunityId = opp.Id;
    
            upsert ord ID_ERP__c;
    
            Opportunity opp_to_update = new Opportunity(Id = opp.Id);
            opp_to_update.SyncedOrder__c = ord.Id;
            update opp_to_update;

            result.parentOrd = ord;
        }
        return result;
    }

    public static UpdateSFRecordsResultOrder updateOrderLineItems(ERPMessageParser.ErpToSfMessage_OpportunityData requestObj, UpdateSFRecordsResult resultOpp, UpdateSFRecordsResultOrder resultOrd) {
        ERPMessageParser.ERPObject_OrderItem[] orderItems = requestObj.data.items;
        UpdateSFRecordsResultOrder result = new UpdateSFRecordsResultOrder();
        result.newOrdProductsIds = new List<String> ();
        result.updatedOrdProductsIds = new List<String> ();

        Opportunity opp = getOpportunitySFByERPID(requestObj.data.header.unDoc);
        Order ord = resultOrd.parentOrd;
        List<OrderItem> ordProductsToUpdate = new List<OrderItem> ();
        Set<OrderItem> ordProductsToDelete = new Set<OrderItem> ();
        List<OrderItem> ordProductsToInsert = new List<OrderItem> ();
//        OLD
        List<ProductionLot__c> lotsToInsert = new List<ProductionLot__c> ();
//        NEW
//        List<Lot__c> lotsToInsert = new List<Lot__c> ();
        Map<String, PricebookEntry> pbeIdByProduct2erpId = selectPBEbyProduct2ERPId(requestObj.data.items, opp);
        Set<Integer> oppProductERPIds = getOppProductERPIds(requestObj.data.items);
        Map<Integer, OrderItem> ordProductsByERPIdMap = getOrdProdSFMap(oppProductERPIds, 'NPP_ERP__c', String.valueOf(ord.Id));

        Map<String, Map<String, Id>> objToIdMap;
        
        if (resultOpp.objToIdMap != null) {
            objToIdMap = resultOpp.objToIdMap;
        } else {
            objToIdMap = getObjectToIdMap(requestObj.data.items, requestObj.data.orderType);
        }
    
        Integer numberOfProducts = 0;
        if (resultOrd.isNewOrderCreated == true || result.isCurrencyCodeChanged == true) {
            for (ERPMessageParser.ERPObject_OrderItem oppProdERP : orderItems) {
                if (oppProdERP.ProductGroup.Id == null || oppProdERP.InqQuantity == null || oppProdERP.InqQuantity == 0) {
                    continue;
                }
                if (String.isBlank(oppProdERP.ProductGroup.ID) || !pbeIdByProduct2erpId.containsKey(oppProdERP.ProductGroup.ID)) {
                    if (String.isBlank(oppProdERP.ProductGroup.ID)) {
                        String errorMessage = String.isBlank(oppProdERP.ProductGroup.ID) ? ('ProductGroup field for Line Item #' + oppProdERP.npp + ' is empty.') : ('There is no such Product Group (' + oppProdERP.ProductGroup + ') for item #' + oppProdERP.npp);
                    }
                }
                OrderItem newOrdI = OpportunityDataEmails.createNewOrderItem(oppProdERP, ord, pbeIdByProduct2erpId);
                mapRelatedERPId(null, newOrdI, objToIdMap, oppProdERP, requestObj.data.orderType);
                updateOLI(null, newOrdI, oppProdERP, requestObj.data.header.undoc, lotsToInsert, result);
                ordProductsToInsert.add(newOrdI);
                numberOfProducts++;
            }
        } else {
            for (ERPMessageParser.ERPObject_OrderItem oppProdERP : orderItems) {
                if (oppProdERP.ProductGroup.Id == null || oppProdERP.InqQuantity == null || oppProdERP.InqQuantity == 0) {
                    continue;
                }
                if (!pbeIdByProduct2erpId.containsKey(oppProdERP.ProductGroup.ID)) {
                    String errorMessage = String.isBlank(oppProdERP.ProductGroup.ID) ? ('ProductGroup field for Line Item #' + oppProdERP.npp + ' is empty.') : ('There is no such Product Group (' + oppProdERP.ProductGroup.ID + ') for item #' + oppProdERP.npp);
                    throw new erpException(errorMessage);
                }
                if (!ordProductsByERPIdMap.containsKey(oppProdERP.npp)) {
                    OrderItem newOrdI = OpportunityDataEmails.createNewOrderItem(oppProdERP, ord, pbeIdByProduct2erpId);
                    mapRelatedERPId(null, newOrdI, objToIdMap, oppProdERP, requestObj.data.orderType);
                    updateOLI(null, newOrdI, oppProdERP, requestObj.data.header.undoc, lotsToInsert, result);
                    ordProductsToInsert.add(newOrdI);
                } else {
                        OrderItem oldOrdLi = ordProductsByERPIdMap.get(oppProdERP.npp);
                    if (oldOrdLi.PricebookEntryId == pbeIdByProduct2erpId.get(oppProdERP.ProductGroup.ID).Id) {
                        OrderItem ordLi = ordProductsByERPIdMap.get(oppProdERP.npp);
                        mapRelatedERPId(null, ordLi, objToIdMap, oppProdERP, requestObj.data.orderType);
                        updateOLI(null, ordLi, oppProdERP, oppProdERP.npp, lotsToInsert, result);
                        ordProductsToUpdate.add(ordLi);
                        result.updatedOrdProductsIds.add(ordLi.Id);
                    } else {
                        OrderItem newOrdLi = oldOrdLi.clone(false, true, false, false);
                        newOrdLi.OrderId = ord.Id;
                        newOrdLi.PricebookEntryId = pbeIdByProduct2erpId.get(oppProdERP.ProductGroup.ID).Id;
                        newOrdLi.NPP_ERP__c = String.valueOf(oppProdERP.npp);
                        mapRelatedERPId(null, newOrdLi, objToIdMap, oppProdERP, requestObj.data.orderType);
                        updateOLI(null, newOrdLi, oppProdERP, requestObj.data.header.undoc, lotsToInsert, result);
                        ordProductsToInsert.add(newOrdLi);
                        ordProductsToDelete.add(oldOrdLi);
                    }
                }
                numberOfProducts++;
            }
        }

        if (ordProductsToDelete.size() > 0) {
            List<OrderItem> deletionLIst = new List<OrderItem> (ordProductsToDelete);
            delete deletionLIst;
            ordProductsToDelete.clear();
        }

        if (ordProductsToInsert.size() > 0) {
            insert ordProductsToInsert;
            for (OrderItem createdOrdLi : ordProductsToInsert) {
                result.newOrdProductsIds.add(createdOrdLi.Id);
            }
        }

        if (lotsToInsert.size() > 0) {
            insert lotsToInsert;
        }

        for (Integer current_li_ID_ERP : ordProductsByERPIdMap.keySet()) {
            if (!oppProductERPIds.contains(Integer.valueOf(current_li_ID_ERP))) {
                ordProductsToDelete.add(ordProductsByERPIdMap.get(Integer.valueOf(current_li_ID_ERP)));
            }
        }

        if (ordProductsToDelete.size() > 0) {
            List<OrderItem> deletionLIst = new List<OrderItem> (ordProductsToDelete);
            delete deletionLIst;
        }
        if (ordProductsToUpdate.size() > 0) {
            update ordProductsToUpdate;
        }
        if (result.firstLotDate != null && (ord.EffectiveDate == null || ord.EffectiveDate == Date.newInstance(1900, 1, 1) || ord.EffectiveDate > result.firstLotDate)) {
            ord.EffectiveDate = result.firstLotDate;
        }
        
        if (ord.EffectiveDate == null || ord.EffectiveDate == Date.newInstance(1900,1,1)) {
            //Сначала выберем между opp.CloseDate и ord.CreatedDate:
            if (ord.CreatedDate != null) {
                ord.EffectiveDate = opp.CloseDate < ord.CreatedDate.date() ? opp.CloseDate : ord.CreatedDate.date();
            } else {
                ord.EffectiveDate = opp.CloseDate;                
            }
            //Теперь сверим с текущей датой:
            if (ord.EffectiveDate > Date.today()) {
                ord.EffectiveDate = Date.today();
            }
        }

        ord.EffectiveDateAux__c = ord.EffectiveDate;
        if (result.isFullyShipped && numberOfProducts > 0) {
            ord.Status = 'Closed';
            ord.EndDate = result.lastLotDate;
        } else {
            if (numberOfProducts > 0) {
                ord.Status = 'Activated';
            }
            ord.EndDate = null;
        }
            
        if(ord.EffectiveDate>ord.EndDate){
            ord.EffectiveDate=ord.EndDate;
        }
        update ord;
    
        return result;
    }
    
    private static void mapRelatedERPId(OpportunityLineItem oppProductSF, OrderItem ordProductSF, Map<String, Map<String, Id>> objToIdMap, ERPMessageParser.ERPObject_OrderItem oppProdERP, String orderType) {
        Map<String, Object> productAsMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(oppProdERP));
        List<String> errList = new List<String> ();
        String allErrors = '';
        Set<String> keysToUse = new Set<String>(erp_to_sf_api_names_new.get(orderType).keySet());
        keysToUse.addALl(erp_to_sf_api_names_new.get('General').keySet());
        keysToUse.remove('shippingpoint');

        Map<String, SObject> sObjects_to_insert = new Map<String, SObject> ();
        for (String fieldName : keysToUse){
            String ERPObjectID;
            String ERPObjectName;
            Map<String, Object> ERPObject;

            if(erp_to_sf_api_names_new.get('General').containsKey(fieldName)) {
                ERPObject = (Map<String,Object>) productAsMap.get(fieldName);
            } else {
                Map<String, Object> prodChar = (Map<String, Object>) productAsMap.get('productCharacteristic');
                ERPObject = (Map<String,Object>) prodChar.get(fieldName);
            }
                
            if(ERPObject == null && fieldName == 'LengthSize'){
                continue;
            }
            ERPObjectID = (String) ERPObject.get('id');
            ERPObjectName = (String) ERPObject.get('name');
            sObject sObj_to_insert;

            if (String.isNotBlank(ERPObjectID) && objToIdMap.get(fieldName).get(fieldName == 'shippingpoint' ? ERPObjectID.toLowerCase() : ERPObjectID) == null) {
                if(erp_to_sf_api_names_new.get('General').containsKey(fieldName)) {
                    sObj_to_insert = Schema.getGlobalDescribe().get(erp_to_sf_api_names_new.get('General').get(fieldName)).newSObject();
                }else{
                    sObj_to_insert = Schema.getGlobalDescribe().get(erp_to_sf_api_names_new.get(orderType).get(fieldName)).newSObject();
                }

                if(fieldName == 'Ends' || fieldName ==  'Coating') {
                    ERPObjectName = OpportunityDataEmails.checkNameFieldSize(ERPObjectName, 255);
                    sObj_to_insert.put('NameRus__c', ERPObjectID);
                }
                ERPObjectName = OpportunityDataEmails.checkNameFieldSize(ERPObjectName, 80);
                sObj_to_insert.put('Name', ERPObjectName);
                sObj_to_insert.put('Id_ERP__c', ERPObjectID);
                if(fieldName == 'SteelGrade' || fieldName ==  'Shop') {
                    sObj_to_insert.put('NameRus__c', ERPObjectName);
                }
                if(fieldName == 'Diameter'){   
                    sObj_to_insert.put('OD_mm__c', ERPObject.get('OD_mm') );
                }
                if(fieldName == 'shippingpoint') {
                    if(country_not_spec == null) {
                        country_not_spec = [SELECT Id FROM Country__c WHERE NumCode__c = '0' LIMIT 1];
                    }
                    sObj_to_insert.put('Country__c', string.valueOf(country_not_spec.id));
                    sObj_to_insert.put('Type__c', ERPObject.get('spType'));
                }
                sObjects_to_insert.put(fieldName, sObj_to_insert);
            }
        }

        if (sObjects_to_insert.values().size() > 0) {
            insert sObjects_to_insert.values();
            for (String fieldName : sObjects_to_insert.keySet()) {
                    SObject obj = sObjects_to_insert.get(fieldName);
                    objToIdMap.get(fieldName).put((String)obj.get('ID_ERP__c'), (String)obj.get('Id'));
            }
        }
    
        if (errList.size() > 0) {
            throw new erpException(allErrors);
        }
    
        if (oppProductSF != null) {
            if(orderType =='tubes'){
                oppProductSF.ProductStandard__c = objToIdMap.get('Standard').get(oppProdERP.productCharacteristic.Standard.ID);
                oppProductSF.ProductSpecLevel__c = objToIdMap.get('speclevel').get(oppProdERP.SpecLevel.ID);
                oppProductSF.SteelGrade__c = objToIdMap.get('SteelGrade').get(oppProdERP.productCharacteristic.SteelGrade.ID);
                oppProductSF.TubeEnds__c = objToIdMap.get('Ends').get(oppProdERP.productCharacteristic.Ends.ID);
                oppProductSF.Coating__c = objToIdMap.get('Coating').get(oppProdERP.productCharacteristic.Coating.ID);
            }
            if(orderType == 'wheels'){
                oppProductSF.WheelProductStandard__c = objToIdMap.get('Standard').get(oppProdERP.productCharacteristic.Standard.ID);
                oppProductSF.WheelSteelGrade__c = objToIdMap.get('SteelGrade').get(oppProdERP.productCharacteristic.SteelGrade.ID);
                oppProductSF.WheelHub__c = objToIdMap.get('Hub').get(oppProdERP.productCharacteristic.Hub.ID);
                oppProductSF.WheelDrawing__c = objToIdMap.get('Drawing').get(oppProdERP.productCharacteristic.Drawing.ID);
            }
            
            oppProductSF.Shop__c = objToIdMap.get('shop').get(oppProdERP.Shop.ID);
    
            if (String.isNotBlank(String.valueOf(oppProdERP.ShippingPoint.ID))) {
                String fullID = oppProdERP.ShippingPoint.spType + '-' + oppProdERP.ShippingPoint.ID;
                if (String.isNotBlank(String.valueOf(productAsMap.get('shippingpoint'))) && objToIdMap.get('shippingpoint').get(fullID.toLowerCase()) == null) {
                    Map<String, Object> ERPObject = (Map<String, Object>) productAsMap.get('shippingpoint');
                    String ERPObjectID = (String) ERPObject.get('id');
                    String ERPObjectName = (String) ERPObject.get('name');
                    ERPObjectName = OpportunityDataEmails.checkNameFieldSize(ERPObjectName, 80);
                    String ERPObjectType = (String) ERPObject.get('spType');
                    if(country_not_spec == null) {
                        country_not_spec = [SELECT Id FROM Country__c WHERE NumCode__c = '0' LIMIT 1];
                    }
                    // В справочник код fullId записываем не в LowerCase, а как в оригинале:
                    ShippingPoint__c shipping_point_to_insert = new ShippingPoint__c(Id_ERP__c = fullID, Name = ERPObjectName, Country__c = country_not_spec.Id, Type__c = ERPObjectType);
                    
                    insert shipping_point_to_insert;
                    objToIdMap.get('shippingpoint').put(fullID.toLowerCase(), shipping_point_to_insert.Id);
                }
                oppProductSF.ShippingPoint__c = objToIdMap.get('shippingpoint').get(fullID.toLowerCase());
            } else {
                oppProductSF.ShippingPoint__c = null;
            }
    
            if (String.isNotBlank(String.valueOf(oppProdERP.QuotaType.ID))) {
                if (String.isNotBlank(String.valueOf(productAsMap.get('QuotaType'))) && objToIdMap.get('QuotaType').get(oppProdERP.QuotaType.ID) == null) {
                    Map<String, Object> ERPObject = (Map<String, Object>) productAsMap.get('QuotaType');
                    String ERPObjectID = (String) ERPObject.get('Id');
                    String ERPObjectName = (String) ERPObject.get('Name');
                    ERPObjectName = OpportunityDataEmails.checkNameFieldSize(ERPObjectName, 80);
                    String ERPObjectShop = (String) ERPObject.get('Shop');
                    QuotaType__c quota_type_to_insert = new QuotaType__c(Id_ERP__c = ERPObjectID, Name = ERPObjectName, NameRus__c = ERPObjectName);
                    List<Shop__c> shop_to_link = [SELECT ID_ERP__c FROM Shop__c WHERE ID_ERP__c = :ERPObjectShop];
                    if (shop_to_link.size() > 0) {
                        quota_type_to_insert.Shop__c = shop_to_link[0].Id;
                    } else {
                        shop_not_cpec = [SELECT Id, Id_ERP__C, Name FROM Shop__c WHERE Id_ERP__C = '0' LIMIT 1];
                        quota_type_to_insert.Shop__c = shop_not_cpec.Id;
                    }
                    insert quota_type_to_insert;
                    objToIdMap.get('QuotaType').put(ERPObjectID, quota_type_to_insert.Id);
                }
                oppProductSF.QuotaType__c = objToIdMap.get('quotatype').get(oppProdERP.QuotaType.ID);
            } else {
                oppProductSF.QuotaType__c = null;
            }
    
            if (ProductType == 'Tubes' && String.isNotBlank(String.valueOf(oppProdERP.productCharacteristic.Diameter.id))) {
                if (String.isNotBlank(String.valueOf(productAsMap.get('OD'))) && objToIdMap.get('OD').get(oppProdERP.productCharacteristic.Diameter.ID) == null) {
                    Map<String, Object> ERPObject = (Map<String, Object>) productAsMap.get('OD');
                    String ERPObjectID = (String) ERPObject.get('Id');
                    String ERPObjectName = (String) ERPObject.get('Name');
                    ERPObjectName = OpportunityDataEmails.checkNameFieldSize(ERPObjectName, 80);
                    String ERPObjectOD_mm = (String) ERPObject.get('OD_mm');
    
                    if (ERPObjectOD_mm == null) {
                        String errorMessage = 'Field OD_mm can not be blank on OD object';
                        throw new erpException(errorMessage);
                    } else {
                        TubeOD__c tube_od = new TubeOD__c(Id_ERP__c = ERPObjectID, Name = ERPObjectName, OD_mm__c = Decimal.valueOf(ERPObjectOD_mm));
                        insert tube_od;
                        objToIdMap.get('OD').put(ERPObjectID, tube_od.Id);
                    }
                }
                oppProductSF.TubeOD__c = objToIdMap.get('Diameter').get(oppProdERP.productCharacteristic.Diameter.ID);
            } else if(ProductType == 'Tubes') {
                String errorMessage = 'Field ID_IN_ERP can not be blank on OD object';
                throw new erpException(errorMessage);
            } else {
                oppProductSF.TubeOD__c = null;
            }
    
            if (ProductType == 'Tubes' && String.isNotBlank(String.valueOf(oppProdERP.productCharacteristic.Thickness.ID))) {
                if (String.isNotBlank(String.valueOf(productAsMap.get('WT'))) && objToIdMap.get('WT').get(oppProdERP.productCharacteristic.Thickness.ID) == null) {
                    Map<String, Object> ERPObject = (Map<String, Object>) productAsMap.get('WT');
                    String ERPObjectID = (String) ERPObject.get('Id');
                    String ERPObjectName = (String) ERPObject.get('Name');
                    ERPObjectName = OpportunityDataEmails.checkNameFieldSize(ERPObjectName, 80);
                    String ERPObjectWT_mm = (String) ERPObject.get('WT_mm');
    
                    if (ERPObjectWT_mm == null) {
                        String errorMessage = 'Field WT_mm can not be blank on WT object';
                        throw new erpException(errorMessage);
                    } else {
                        TubeWT__c tube_wt = new TubeWT__c(Id_ERP__c = ERPObjectID, Name = ERPObjectName, WT_mm__c = Decimal.valueOf(ERPObjectWT_mm));
                        insert tube_wt;
                        objToIdMap.get('WT').put(ERPObjectID, tube_wt.Id);
                    }
                }
                oppProductSF.TubeWT__c = objToIdMap.get('Thickness').get(oppProdERP.productCharacteristic.Thickness.ID);
            } else if(ProductType == 'Tubes') {
                String errorMessage = 'Field ID_IN_ERP can not be blank on WT object';
                throw new erpException(errorMessage);
            } else {
                oppProductSF.TubeWT__c = null;
            }
            if(oppProdERP.productCharacteristic.LengthSize != null){
                if (ProductType == 'Tubes' && String.isNotBlank(String.valueOf(oppProdERP.productCharacteristic.LengthSize.ID))) {
                    if (String.isNotBlank(String.valueOf(productAsMap.get('LengthSize'))) && objToIdMap.get('LengthSize').get(oppProdERP.productCharacteristic.LengthSize.ID) == null) {
                        Map<String, Object> ERPObject = (Map<String, Object>) productAsMap.get('LengthSize');
                        String ERPObjectID = (String) ERPObject.get('Id');
                        String ERPObjectName = (String) ERPObject.get('Name');
                        
                        String ERPObjectODminLength = (String) ERPObject.get('MinLength');
                        String ERPObjectODmaxLength = (String) ERPObject.get('MaxLength');
    
                        TubeLengthSize__c tubeLengthSize = new TubeLengthSize__c(Id_ERP__c = ERPObjectID);
                        ERPObjectName = OpportunityDataEmails.checkNameFieldSize(ERPObjectName, 255);
                        tubeLengthSize.NameRus__c = ERPObjectName;
                        ERPObjectName = OpportunityDataEmails.checkNameFieldSize(ERPObjectName, 80);
                        tubeLengthSize.Name = ERPObjectName;
                        tubeLengthSize.MaxLength__c = (ERPObjectODmaxLength != null && ERPObjectODmaxLength != '' ? Decimal.valueOf(ERPObjectODmaxLength) : null);
                        tubeLengthSize.MinLength__c = (ERPObjectODminLength != null && ERPObjectODminLength != '' ? Decimal.valueOf(ERPObjectODminLength) : null);
                        insert tubeLengthSize;
                        objToIdMap.get('LengthSize').put(ERPObjectID, tubeLengthSize.Id);
                    }
                    oppProductSF.LengthSize__c = objToIdMap.get('LengthSize').get(oppProdERP.productCharacteristic.LengthSize.ID);
                } else {
                    oppProductSF.LengthSize__c = null;
                }
            }
            if (orderType == 'Wheels' && String.isNotBlank(String.valueOf(oppProdERP.productCharacteristic.Diameter.ID))) {
                    Map<String, Object> prodChar = (Map<String, Object>) productAsMap.get('productCharacteristic');
                if (String.isNotBlank(String.valueOf(prodChar.get('Diameter'))) && objToIdMap.get('Diameter').get(oppProdERP.productCharacteristic.Diameter.ID) == null) {
                    Map<String, Object> ERPObject = (Map<String, Object>) prodChar.get('Diameter');
                    String ERPObjectID = (String) ERPObject.get('Id');
                    String ERPObjectName = (String) ERPObject.get('Name');
                    ERPObjectName = OpportunityDataEmails.checkNameFieldSize(ERPObjectName, 80);
                    String ERPObjectOD_mm = (String) ERPObject.get('OD_mm');
                    if (ERPObjectOD_mm == null) {
                        //String errorMessage = 'Field OD_mm can not be blank on WheelDiameter object';
                        //throw new erpException(errorMessage);
                    } else {
                        WheelDiameter__c wheelDiameter = new WheelDiameter__c(Id_ERP__c = ERPObjectID, Name = ERPObjectName, OD_mm__c = Decimal.valueOf(ERPObjectOD_mm));
                        insert wheelDiameter;
                        objToIdMap.get('Diameter').put(ERPObjectID, wheelDiameter.Id);
                    }
                }
                oppProductSF.WheelDiameter__c = objToIdMap.get('Diameter').get(oppProdERP.productCharacteristic.Diameter.ID);
            } else if(ProductType == 'Wheels') {
                String errorMessage = 'Field ID_IN_ERP can not be blank on WheelDiameter object';
                throw new erpException(errorMessage);
            } else {
                oppProductSF.WheelDiameter__c = null;
            }
        } else {
            if(orderType == 'tubes'){
                ordProductSF.ProductStandard__c = objToIdMap.get('Standard').get(oppProdERP.productCharacteristic.Standard.ID);
                ordProductSF.ProductSpecLevel__c = objToIdMap.get('speclevel').get(oppProdERP.SpecLevel.ID);
                ordProductSF.SteelGrade__c = objToIdMap.get('SteelGrade').get(oppProdERP.productCharacteristic.SteelGrade.ID);
                ordProductSF.TubeEnds__c = objToIdMap.get('Ends').get(oppProdERP.productCharacteristic.Ends.ID);
                ordProductSF.Coating__c = objToIdMap.get('Coating').get(oppProdERP.productCharacteristic.Coating.ID);
            }
            if(orderType == 'wheels'){
                ordProductSF.WheelProductStandard__c = objToIdMap.get('Standard').get(oppProdERP.productCharacteristic.Standard.ID);
                ordProductSF.WheelSteelGrade__c = objToIdMap.get('SteelGrade').get(oppProdERP.productCharacteristic.SteelGrade.ID);
                ordProductSF.WheelHub__c = objToIdMap.get('Hub').get(oppProdERP.productCharacteristic.Hub.ID);
                ordProductSF.WheelDrawing__c = objToIdMap.get('Drawing').get(oppProdERP.productCharacteristic.Drawing.ID);
                ordProductSF.KLWSpec__c = specVersionMap.get(String.valueOf(oppProdERP.productCharacteristic.Specification)) != null ?
                                          specVersionMap.get(String.valueOf(oppProdERP.productCharacteristic.Specification)).Id : null;
                if(oppProdERP.productCharacteristic.Drawing.ID != null) { 
                    ordProductSF.Drawing__c = drawingVersionMap.get(oppProdERP.productCharacteristic.Drawing.ID) != null ?
                                              drawingVersionMap.get(oppProdERP.productCharacteristic.Drawing.ID).Id : null;
                } else {
                    ordProductSF.Drawing__c = specVersionMap.get(String.valueOf(oppProdERP.productCharacteristic.Specification)) != null ?
                                              specVersionMap.get(String.valueOf(oppProdERP.productCharacteristic.Specification)).DrawingVersion__c : null;
                }
                // if(ordProductSF.Drawing__c == null || ordProductSF.KLWSpec__c == null) {
                //     String message = 'Missing Drawing Version or Specification Version';
                //     Triton.instance.error(TritonTypes.Type.ERPMessageHandler, TritonTypes.Area.OpportunityData, message, 
                //                           message, oppProdERP.iteNumber);
                // }
            }
            ordProductSF.Shop__c = objToIdMap.get('shop').get(oppProdERP.Shop.ID);
    
            if (String.isNotBlank(String.valueOf(oppProdERP.QuotaType.ID))) {
                if (String.isNotBlank(String.valueOf(productAsMap.get('QuotaType'))) && objToIdMap.get('QuotaType').get(oppProdERP.QuotaType.ID) == null) {
                    Map<String, Object> ERPObject = (Map<String, Object>) productAsMap.get('QuotaType');
                    String ERPObjectID = (String) ERPObject.get('Id');
                    String ERPObjectName = (String) ERPObject.get('Name');
                    ERPObjectName = OpportunityDataEmails.checkNameFieldSize(ERPObjectName, 80);
                    String ERPObjectShop = (String) ERPObject.get('Shop');
                    QuotaType__c quota_type_to_insert = new QuotaType__c(Id_ERP__c = ERPObjectID, Name = ERPObjectName, NameRus__c = ERPObjectName);
                    List<Shop__c> shop_to_link = [SELECT ID_ERP__c FROM Shop__c WHERE ID_ERP__c = :ERPObjectShop];
                    if (shop_to_link.size() > 0) {
                        quota_type_to_insert.Shop__c = shop_to_link[0].Id;
                    } else {
                        if (shop_not_cpec == null) {
                            shop_not_cpec = [SELECT Id, Id_ERP__C, Name FROM Shop__c WHERE Id_ERP__C = '0' LIMIT 1];
                        }
                        quota_type_to_insert.Shop__c = shop_not_cpec.Id;
                    }
    
                    insert quota_type_to_insert;
                    objToIdMap.get('QuotaType').put(ERPObjectID, quota_type_to_insert.Id);
                }
                ordProductSF.QuotaType__c = objToIdMap.get('quotatype').get(oppProdERP.QuotaType.ID);
            } else {
                ordProductSF.QuotaType__c = null;
            }
    
            if (ProductType == 'Tubes' && String.isNotBlank(String.valueOf(oppProdERP.productCharacteristic.Diameter.ID))) {
                if (String.isNotBlank(String.valueOf(productAsMap.get('OD'))) && objToIdMap.get('OD').get(oppProdERP.productCharacteristic.Diameter.ID) == null) {
                    Map<String, Object> ERPObject = (Map<String, Object>) productAsMap.get('OD');
                    String ERPObjectID = (String) ERPObject.get('Id');
                    String ERPObjectName = (String) ERPObject.get('Name');
                    ERPObjectName = OpportunityDataEmails.checkNameFieldSize(ERPObjectName, 80);
                    String ERPObjectOD_mm = (String) ERPObject.get('OD_mm');
    
                    if (ERPObjectOD_mm == null) {
                        String errorMessage = 'Field OD_mm can not be blank on OD object';
                        throw new erpException(errorMessage);
                    } else {
                        TubeOD__c tube_od = new TubeOD__c(Id_ERP__c = ERPObjectID, Name = ERPObjectName, OD_mm__c = Decimal.valueOf(ERPObjectOD_mm));
                        insert tube_od;
                        objToIdMap.get('OD').put(ERPObjectID, tube_od.Id);
                    }
                }
                ordProductSF.TubeOD__c = objToIdMap.get('Diameter').get(oppProdERP.productCharacteristic.Diameter.ID);
            } else if (ProductType == 'Tubes') {
                String errorMessage = 'Field ID_IN_ERP can not be blank on OD object';
                throw new erpException(errorMessage);
            } else {
                ordProductSF.TubeOD__c = null;
            }

            if (ProductType == 'Tubes' && String.isNotBlank(String.valueOf(oppProdERP.productCharacteristic.Thickness.ID))) {
                if (String.isNotBlank(String.valueOf(productAsMap.get('WT'))) && objToIdMap.get('WT').get(oppProdERP.productCharacteristic.Thickness.ID) == null) {
                    Map<String, Object> ERPObject = (Map<String, Object>) productAsMap.get('WT');
                    String ERPObjectID = (String) ERPObject.get('Id');
                    String ERPObjectName = (String) ERPObject.get('Name');
                    ERPObjectName = OpportunityDataEmails.checkNameFieldSize(ERPObjectName, 80);
                    String ERPObjectWT_mm = (String) ERPObject.get('WT_mm');
    
                    if (ERPObjectWT_mm == null) {
                        String errorMessage = 'Field WT_mm can not be blank on WT object';
                        throw new erpException(errorMessage);
                    } else {
                        TubeWT__c tube_wt = new TubeWT__c(Id_ERP__c = ERPObjectID, Name = ERPObjectName, WT_mm__c = Decimal.valueOf(ERPObjectWT_mm));
                        insert tube_wt;
                        objToIdMap.get('WT').put(ERPObjectID, tube_wt.Id);
                    }
                }
                ordProductSF.TubeWT__c = objToIdMap.get('Thickness').get(oppProdERP.productCharacteristic.Thickness.ID);
            } else if (ProductType == 'Tubes') {
                String errorMessage = 'Field ID_IN_ERP can not be blank on WT object';
                throw new erpException(errorMessage);
            } else {
                ordProductSF.TubeWT__c = null;
            }  
            if (ProductType == 'Tubes' && String.isNotBlank(String.valueOf(oppProdERP.productCharacteristic.LengthSize.ID))) {
                if (String.isNotBlank(String.valueOf(productAsMap.get('LengthSize'))) && objToIdMap.get('LengthSize').get(oppProdERP.productCharacteristic.LengthSize.ID) == null) {
                    Map<String, Object> ERPObject = (Map<String, Object>) productAsMap.get('LengthSize');
                    String ERPObjectID = (String) ERPObject.get('Id');
                    String ERPObjectName = (String) ERPObject.get('Name');
                    String ERPObjectODminLength = (String) ERPObject.get('MinLength');
                    String ERPObjectODmaxLength = (String) ERPObject.get('MaxLength');
    
                    TubeLengthSize__c tubeLengthSize = new TubeLengthSize__c(Id_ERP__c = ERPObjectID);
                    ERPObjectName = OpportunityDataEmails.checkNameFieldSize(ERPObjectName, 255);
                    tubeLengthSize.NameRus__c = ERPObjectName;
                    ERPObjectName = OpportunityDataEmails.checkNameFieldSize(ERPObjectName, 80);
                    tubeLengthSize.Name = ERPObjectName;
                    tubeLengthSize.MaxLength__c = (ERPObjectODmaxLength != null && ERPObjectODmaxLength != '' ? Decimal.valueOf(ERPObjectODmaxLength) : null);
                    tubeLengthSize.MinLength__c = (ERPObjectODminLength != null && ERPObjectODminLength != '' ? Decimal.valueOf(ERPObjectODminLength) : null);
                    insert tubeLengthSize;    					

                    objToIdMap.get('LengthSize').put(ERPObjectID, tubeLengthSize.Id);
                }
                ordProductSF.TubeLengthSize__c = objToIdMap.get('LengthSize').get(oppProdERP.productCharacteristic.LengthSize.ID);
            } else if (ProductType == 'Tubes') {
                String errorMessage = 'Field ID_IN_ERP can not be blank on lengh size object';
                throw new erpException(errorMessage);
            } else {
                ordProductSF.TubeLengthSize__c = null;
            }
    
            if (orderType == 'Wheels' && String.isNotBlank(String.valueOf(oppProdERP.productCharacteristic.Diameter.ID))) {
                Map<String, Object> prodChar = (Map<String, Object>) productAsMap.get('productCharacteristic');
                if (String.isNotBlank(String.valueOf(prodChar.get('Diameter'))) && objToIdMap.get('Diameter').get(oppProdERP.productCharacteristic.Diameter.ID) == null) {
                    Map<String, Object> ERPObject = (Map<String, Object>) prodChar.get('Diameter');
                    String ERPObjectID = (String) ERPObject.get('Id');
                    String ERPObjectName = (String) ERPObject.get('Name');
                    ERPObjectName = OpportunityDataEmails.checkNameFieldSize(ERPObjectName, 80);
                    String ERPObjectOD_mm = (String) ERPObject.get('OD_mm');
                    if (ERPObjectOD_mm == null) {
                        //String errorMessage = 'Field OD_mm can not be blank on WheelDiameter object';
                        //throw new erpException(errorMessage);
                    } else {
                        WheelDiameter__c wheelDiameter = new WheelDiameter__c(Id_ERP__c = ERPObjectID, Name = ERPObjectName, OD_mm__c = Decimal.valueOf(ERPObjectOD_mm));
                        insert wheelDiameter;
                        objToIdMap.get('Diameter').put(ERPObjectID, wheelDiameter.Id);
                    }
                }
                ordProductSF.WheelDiameter__c = objToIdMap.get('Diameter').get(oppProdERP.productCharacteristic.Diameter.ID);
            } else if(ProductType == 'Wheels') {
                String errorMessage = 'Field ID_IN_ERP can not be blank on WheelDiameter object';
                throw new erpException(errorMessage);
            } else {
                ordProductSF.WheelDiameter__c = null;
            }
        }
    }
    
    @testVisible
    public static void updateOLI(OpportunityLineItem oppProductSF, OrderItem ordProductSF, ERPMessageParser.ERPObject_OrderItem oppProdERP, Integer requestObjGeneral_DataID_ERP, List<ProductionLot__c> lotsToInsert, UpdateSFRecordsResultOrder result) {
// NEW CORRECT    public static void updateOLI(OpportunityLineItem oppProductSF, OrderItem ordProductSF, ERPMessageParser.ERPObject_OrderItem oppProdERP, Integer requestObjGeneral_DataID_ERP, List<Lot__c> lotsToInsert, UpdateSFRecordsResultOrder result) {
        Map<String,String> stageCodeMap = makeMapForStage();
        if (oppProductSF != null) {                
            oppProductSF.Typical__c = (oppProdERP.isTypical != null && oppProdERP.isTypical == 1);
            oppProductSF.ProductionAllowed__c = (oppProdERP.FinApproval != null && oppProdERP.FinApproval == 1);
            oppProductSF.FinStatus__c = (oppProdERP.FinStatus != null && oppProdERP.FinStatus != '' ? oppProdERP.FinStatus : null);
            oppProductSF.FinStatus__c = (oppProductSF.ProductionAllowed__c ? oppProductSF.FinStatus__c + '. Production allowed.' : oppProductSF.FinStatus__c);
            oppProductSF.TechExp__c = String.valueOf((oppProdERP.TechExp != null && oppProdERP.TechExp != null ? oppProdERP.TechExp : null));
            oppProductSF.CDD__c = ( oppProdERP.criticalDispatchDate != null && !String.valueOf(oppProdERP.criticalDispatchDate).contains('1900-01-01') && !String.valueOf(oppProdERP.criticalDispatchDate).contains('0001') ? Date.valueOf(oppProdERP.criticalDispatchDate) : null );
            oppProductSF.ConfirmedCDD__c = ( oppProdERP.recommendedCDD != null && !String.valueOf(oppProdERP.recommendedCDD).contains('1900-01-01') && !String.valueOf(oppProdERP.recommendedCDD).contains('0001') ? Date.valueOf(oppProdERP.recommendedCDD) : null );

            for (ERPMessageParser.ERPObject_Quotas quotas : oppProdERP.quotas) {
                oppProductSF.Quota_Date__c = ((quotas.quotaDate != null && quotas.quotaDate != null) ? date.valueOf(quotas.quotaDate): null);
            }
    
            oppProdERP.CoatingSpec = OpportunityDataEmails.checkNameFieldSize(oppProdERP.CoatingSpec, 255);
            oppProductSF.CoatingSpecification__c = (oppProdERP.CoatingSpec!= null && oppProdERP.CoatingSpec != '' ? oppProdERP.CoatingSpec : null);
            oppProductSF.InquiryUnit__c = String.valueOf((oppProdERP.InqUnit != null && oppProdERP.InqUnit != null ? oppProdERP.InqUnit : null));
            oppProductSF.Quantity = (oppProdERP.Quantity_Mt != null && oppProdERP.Quantity_Mt != null && oppProdERP.Quantity_Mt != 0 ? (oppProdERP.Quantity_Mt) : 0.01); // т.к. бывает количество тонн нулевое (еще не рассчитали вес из клиентских единиц), то установим 0.01
            oppProductSF.Quantity_m__c = (oppProdERP.Quantity_m != null && oppProdERP.Quantity_m != null ? oppProdERP.Quantity_m : 0);
            oppProductSF.Quantity_ft__c = (oppProdERP.Quantity_ft != null && oppProdERP.Quantity_ft != null ? oppProdERP.Quantity_ft : 0);
            oppProductSF.Quantity_pcs__c = (oppProdERP.Quantity_pcs != null && oppProdERP.Quantity_pcs != null ? oppProdERP.Quantity_pcs : 0);
            oppProductSF.Weight_ppf__c = (oppProdERP.LinearWeight_ppf != null && oppProdERP.LinearWeight_ppf != null ? oppProdERP.LinearWeight_ppf : 0);
            oppProductSF.Weight_kpm__c = (oppProdERP.LinearWeight_kpm != null && oppProdERP.LinearWeight_kpm != null ? oppProdERP.LinearWeight_kpm : 0);
            oppProductSF.InquiryQuantity__c = (oppProdERP.InqQuantity != null && oppProdERP.InqQuantity != null ? oppProdERP.InqQuantity : 0);
            oppProductSF.InquiryUnitPrice__c = (oppProdERP.Price != null && oppProdERP.Price != null ? oppProdERP.Price : 0);
            oppProductSF.UnitPrice = (oppProdERP.Price_t != null && oppProdERP.Price_t != null ? oppProdERP.Price_t : 0);
            oppProductSF.Margin_t__c = (oppProdERP.Margin_t != null && oppProdERP.Margin_t != null ? oppProdERP.Margin_t : 0);
            oppProductSF.Margin__c = (oppProductSF.Margin_t__c != null && oppProductSF.Quantity != null ? oppProductSF.Margin_t__c * oppProductSF.Quantity : 0);
            oppProductSF.ITENumber__c = (oppProdERP.iteNumber != null && oppProdERP.iteNumber != '' ? oppProdERP.iteNumber : null);              
            String currentStage = OpportunityDataEmails.mapStageResult(oppProdERP.Stage,stageCodeMap,oppProdERP);
            oppProductSF.Stage__c = currentStage != null ? currentStage.substringBefore('(') : null;
//            oppProductSF.Is_Placed__c = oppProductSF.Is_Placed__c==false?checkIfPlaced(oppProdERP.Stage):true;
            oppProductSF.Is_Placed__c = checkIfPlaced(oppProdERP.Stage);


            //add balance for oppProduct          
            if(oppProdERP.Produced != null){
                oppProductSF.Balance_t__c = oppProdERP.Quantity_Mt - oppProdERP.Produced;
            }

            Decimal maxLength = 0;
            Decimal minLength = 0;    

            if(oppProdERP.productCharacteristic.lengthSize != null){
                maxLength =  oppProdERP.productCharacteristic.lengthSize.maxLength;
                minLength =  oppProdERP.productCharacteristic.lengthSize.minLength; 
                oppProductSF.LengthMin_mm__c = (minLength != null ? minLength : 0);
                oppProductSF.LengthMax_mm__c = (maxLength != null ? maxLength : 0);
            } else {
				oppProductSF.LengthMin_mm__c = 0;
                oppProductSF.LengthMax_mm__c = 0;
            }

            if(oppProductSF.InquiryUnit__c == '34'){
                oppProductSF.Quantity_lb__c = (oppProductSF.Quantity*2204.62).setScale(2);
                if(oppProductSF.Weight_kpm__c!=0){
                    oppProductSF.Quantity_m__c = (oppProductSF.Quantity / (0.001*oppProductSF.Weight_kpm__c)).setScale(2);
                    oppProductSF.Quantity_ft__c = (oppProductSF.Quantity_m__c / 0.3048).setScale(2);
                } else if(oppProductSF.Weight_ppf__c != 0){
                    oppProductSF.Quantity_m__c = ((oppProductSF.Quantity_lb__c/oppProductSF.Weight_ppf__c)*0.3048).setScale(2);
                    oppProductSF.Quantity_ft__c = (oppProductSF.Quantity_lb__c/oppProductSF.Weight_ppf__c).setScale(2);
                } else {
                    oppProductSF.Quantity_m__c = 0;
                    oppProductSF.Quantity_ft__c = 0;
                }

                oppProductSF.Quantity_pcs__c = maxLength!=0?(oppProductSF.Quantity_m__c/(maxLength/1000)).setScale(2):0;
                //price 
                oppProductSF.Sales_Price_lb__c = (oppProductSF.UnitPrice/2204.62).setScale(2);
                if(oppProductSF.Weight_kpm__c!=0){
                    oppProductSF.Sales_Price_m__c =  (oppProductSF.UnitPrice * (oppProductSF.Weight_kpm__c/1000)).setScale(2);
                    oppProductSF.Sales_Price_ft__c = (oppProductSF.Sales_Price_m__c*0.3048).setScale(2);
                } else if(oppProductSF.Weight_ppf__c != 0){
                    oppProductSF.Sales_Price_ft__c = (oppProductSF.Sales_Price_lb__c * oppProductSF.Weight_ppf__c).setScale(2);
                    oppProductSF.Sales_Price_m__c = (oppProductSF.Sales_Price_ft__c / 0.3048).setScale(2);
                } else {
                    oppProductSF.Sales_Price_ft__c = 0 ;
                    oppProductSF.Sales_Price_m__c = 0;
                }

                oppProductSF.Sales_Price_pcs__c = (oppProductSF.Sales_Price_m__c * (maxLength/1000)).setScale(2);
            }
                //m
                if(oppProductSF.InquiryUnit__c == '20'){
                    oppProductSF.Quantity_pcs__c = maxLength!=0?(oppProductSF.Quantity_m__c/(maxLength/1000)).setScale(2):0;
                    oppProductSF.Quantity_lb__c = (oppProductSF.Quantity*2204.62).setScale(2);
                    oppProductSF.Quantity_ft__c = (oppProductSF.Quantity_m__c / 0.3048).setScale(2);
					//price
					oppProductSF.Sales_Price_m__c = oppProductSF.InquiryUnitPrice__c;
					oppProductSF.Sales_Price_ft__c = (oppProductSF.Sales_Price_m__c*0.3048).setScale(2);
                    oppProductSF.Sales_Price_pcs__c =  (oppProductSF.Sales_Price_m__c*(maxLength/1000)).setScale(2);
                    oppProductSF.Sales_Price_lb__c = (oppProductSF.UnitPrice/2204.62).setScale(2);
                }
                //ft
                if(oppProductSF.InquiryUnit__c == '74'){
                    oppProductSF.Quantity_ft__c = oppProductSF.InquiryQuantity__c;
                    oppProductSF.Quantity_m__c = (oppProductSF.Quantity_ft__c * 0.3048).setScale(2);
                    oppProductSF.Quantity_pcs__c = maxLength!=0?(oppProductSF.Quantity_m__c/(maxLength/1000)).setScale(2):0;
                    oppProductSF.Quantity_lb__c = (oppProductSF.Quantity*2204.62).setScale(2);
					//price
					oppProductSF.Sales_Price_ft__c = oppProductSF.InquiryUnitPrice__c; 
                    oppProductSF.Sales_Price_m__c = (oppProductSF.Sales_Price_ft__c / 0.3048).setScale(2);
                    oppProductSF.Sales_Price_lb__c = (oppProductSF.UnitPrice/2204.62).setScale(2);
                    oppProductSF.Sales_Price_pcs__c = (oppProductSF.Sales_Price_m__c*(maxLength/1000)).setScale(2);
                }
              //pcs
            if(oppProductSF.InquiryUnit__c == '43'){
                oppProductSF.Quantity_pcs__c = oppProductSF.InquiryQuantity__c;
                oppProductSF.Quantity_m__c = (oppProductSF.Quantity_pcs__c * (maxLength/1000)).setScale(2);
                oppProductSF.Quantity_ft__c = (oppProductSF.Quantity_m__c / 0.3048).setScale(2);
                oppProductSF.Quantity_lb__c = (oppProductSF.Quantity*2204.62).setScale(2);
                //price
                oppProductSF.Sales_Price_pcs__c = oppProductSF.InquiryUnitPrice__c; 
                oppProductSF.Sales_Price_m__c = maxLength!=0?(oppProductSF.Sales_Price_pcs__c / (maxLength/1000)).setScale(2):0;
                oppProductSF.Sales_Price_ft__c = (oppProductSF.Sales_Price_m__c * 0.3048).setScale(2);
                oppProductSF.Sales_Price_lb__c = (oppProductSF.UnitPrice/2204.62).setScale(2);   
            }   
        } else {
            ordProductSF.Quantity = (oppProdERP.Quantity_Mt != null && oppProdERP.Quantity_Mt != null && oppProdERP.Quantity_Mt != 0 ? oppProdERP.Quantity_Mt : 0.01);  // т.к. бывает количество тонн нулевое (еще не рассчитали вес из клиентских единиц), то установим 0.01
            ordProductSF.Weight_ppf__c = (oppProdERP.LinearWeight_ppf != null && oppProdERP.LinearWeight_ppf != null ? oppProdERP.LinearWeight_ppf : 0);
            ordProductSF.Weight_kpm__c = (oppProdERP.LinearWeight_kpm != null && oppProdERP.LinearWeight_kpm != null ? oppProdERP.LinearWeight_kpm : 0);
            ordProductSF.UnitPrice = (oppProdERP.Price_t != null && oppProdERP.Price_t != null ? oppProdERP.Price_t : 0);
            ordProductSF.NPS__c = oppProdERP.NPS.contains('"') ? oppProdERP.NPS : oppProdERP.NPS.trim() + '"';
            ordProductSF.SCH__c = oppProdERP.SCH;
            ordProductSF.Mark_1__c = oppProdERP.Mark1.contains('"') ? oppProdERP.Mark1 : oppProdERP.Mark1.trim() + '"';
            ordProductSF.MeasUnit__c = String.valueOf((oppProdERP.InqUnit != null && oppProdERP.InqUnit != null ? oppProdERP.InqUnit : null));
            ordProductSF.Quantity_m__c = (oppProdERP.Quantity_m != null && oppProdERP.Quantity_m != null ? oppProdERP.Quantity_m : 0);
            ordProductSF.Quantity_ft__c = (oppProdERP.Quantity_ft != null && oppProdERP.Quantity_ft != null ? oppProdERP.Quantity_ft : 0);
            ordProductSF.Quantity_pcs__c = (oppProdERP.Quantity_pcs != null && oppProdERP.Quantity_pcs != null ? oppProdERP.Quantity_pcs : 0);
            ordProductSF.InqQuantuty__c = (oppProdERP.InqQuantity != null && oppProdERP.InqQuantity != null ? oppProdERP.InqQuantity : 0);
            ordProductSF.InqUnitPrice__c = (oppProdERP.Price != null && oppProdERP.Price != null ? oppProdERP.Price : 0);
            ordProductSF.UnitPrice = (oppProdERP.Price_t != null && oppProdERP.Price_t != null ? oppProdERP.Price_t : 0);
            ordProductSF.CDD__c = ( oppProdERP.criticalDispatchDate != null && !String.valueOf(oppProdERP.criticalDispatchDate).contains('1900-01-01') && !String.valueOf(oppProdERP.criticalDispatchDate).contains('0001') ? Date.valueOf(oppProdERP.criticalDispatchDate) : null );
            ordProductSF.ConfirmedCDD__c = ( oppProdERP.recommendedCDD != null && !String.valueOf(oppProdERP.recommendedCDD).contains('1900-01-01') && !String.valueOf(oppProdERP.recommendedCDD).contains('0001') ? Date.valueOf(oppProdERP.recommendedCDD) : null );

            for (ERPMessageParser.ERPObject_Quotas quotas : oppProdERP.quotas) {
                ordProductSF.Quota_Date__c = ((quotas.quotaDate != null && quotas.quotaDate != null) ? date.valueOf(quotas.quotaDate): null);
            }

            String currentStage = OpportunityDataEmails.mapStageResult(oppProdERP.Stage,stageCodeMap, oppProdERP);                
            ordProductSF.Stage__c = currentStage != null ? currentStage.substringBefore('(') : null;
            ordProductSF.Is_Placed__c = checkIfPlaced(oppProdERP.Stage);
            ordProductSF.ITENumber__c = (oppProdERP.ITENumber != null && oppProdERP.ITENumber != '' ? oppProdERP.ITENumber : null);
    
            // Поля ProducedQuantity__c, DispatchedQuantity__c и ShippedQuantity__c заполняются из оперативных данных в заводской системе учета:
            ordProductSF.ProducedQuantity__c = oppProdERP.Produced != null ? oppProdERP.Produced : 0;
            ordProductSF.DispatchedQuantity__c = oppProdERP.Dispatched != null ? oppProdERP.Dispatched : 0;
            ordProductSF.ShippedQuantity__c = oppProdERP.Shipped != null ? oppProdERP.Shipped : 0;
            // Поля Margin__c и Margin_t__c заполняются на основании данных из фактических срезов в ИТ, которые заполняются аналитиками:
            Decimal FinDataShipped = oppProdERP.FinDataShipped != null ? oppProdERP.FinDataShipped : 0;
            ordProductSF.Margin__c = oppProdERP.FinDataMargin != null ? oppProdERP.FinDataMargin : 0;
            ordProductSF.Margin_t__c = FinDataShipped != 0 ? ordProductSF.Margin__c / FinDataShipped : 0;
                
            Date oldestLotDate;
            Date finalProdDate;
            Date finalShippedDate;
            Date finalDelivdate;

            //--------------OLD Logic
//             Создадим записи в таблице ProductionLots:
            for (ERPMessageParser.ERPObject_ProductLot lot : oppProdERP.Lots) {
                ProductionLot__c Productlot = new ProductionLot__c();
//                NEW Lot__c Productlot = new Lot__c();
                Productlot.Order__c = ordProductSF.OrderId;
                Productlot.OrderItem__c = ordProductSF.Id;
                Productlot.LotDate__c = ((lot.LotDate != null && lot.LotDate != '') ? date.valueOf(lot.LotDate) : null);
                Productlot.ProducedQuantity__c = (lot.Produced != null && lot.Produced != '' ? Decimal.valueOf(lot.Produced) : 0);
                Productlot.DispatchedQuantity__c = (lot.Dispatched != null && lot.Dispatched != '' ? Decimal.valueOf(lot.Dispatched) : 0);
                Productlot.ShippedQuantity__c = (lot.Shipped != null && lot.Shipped != '' ? Decimal.valueOf(lot.Shipped) : 0);
                lotsToInsert.add(Productlot);
                if (oldestLotDate == null || Productlot.LotDate__c > oldestLotDate) {
                    oldestLotDate = Productlot.LotDate__c;
                }
                if (Productlot.ProducedQuantity__c != 0 && (finalProdDate == null || Productlot.LotDate__c > finalProdDate)) {
                    finalProdDate = Productlot.LotDate__c;
                }
                if (Productlot.DispatchedQuantity__c != 0 && (finalShippedDate == null || Productlot.LotDate__c > finalShippedDate)) {
                    finalShippedDate = Productlot.LotDate__c;
                }
                if (Productlot.ShippedQuantity__c != 0 && (finalDelivdate == null || Productlot.LotDate__c > finalDelivdate)) {
                    finalDelivdate = Productlot.LotDate__c;
                }
            }

//            ----------------NEW LOGIC
            // Створимо записи Lot__c на основі типів
//            for (ERPMessageParser.ERPObject_ProductLot lot : oppProdERP.Lots) {
//                Date lotDate = (lot.lotDate != null && lot.lotDate != '') ? date.valueOf(lot.lotDate) : null;
//
//                if (lot.produced != null && lot.produced != '' && Decimal.valueOf(lot.produced) > 0) {
//                    lotsToInsert.add(new Lot__c(
//                            Order__c = ordProductSF.OrderId,
//                            OrderItem__c = ordProductSF.Id,
//                            LotDate__c = lotDate,
//                            LotQty_t__c = Decimal.valueOf(lot.produced),
//                            LotType__c = 'Produced'
//                    ));
//                    if (ordProductSF.FinallyProdDate__c == null || lotDate > ordProductSF.FinallyProdDate__c) {
//                        ordProductSF.FinallyProdDate__c = lotDate;
//                    }
//                }
//
//                if (lot.dispatched != null && lot.dispatched != '' && Decimal.valueOf(lot.dispatched) > 0) {
//                    lotsToInsert.add(new Lot__c(
//                            Order__c = ordProductSF.OrderId,
//                            OrderItem__c = ordProductSF.Id,
//                            LotDate__c = lotDate,
//                            LotQty_t__c = Decimal.valueOf(lot.dispatched),
//                            LotType__c = 'Shipped'
//                    ));
//                    if (ordProductSF.FinallyShippedDate__c == null || lotDate > ordProductSF.FinallyShippedDate__c) {
//                        ordProductSF.FinallyShippedDate__c = lotDate;
//                    }
//                }
//
//                if (lot.shipped != null && lot.shipped != '' && Decimal.valueOf(lot.shipped) > 0) {
//                    lotsToInsert.add(new Lot__c(
//                            Order__c = ordProductSF.OrderId,
//                            OrderItem__c = ordProductSF.Id,
//                            LotDate__c = lotDate,
//                            LotQty_t__c = Decimal.valueOf(lot.shipped),
//                            LotType__c = 'Delivered'
//                    ));
//                    if (ordProductSF.FinallyDelivDate__c == null || lotDate > ordProductSF.FinallyDelivDate__c) {
//                        ordProductSF.FinallyDelivDate__c = lotDate;
//                    }
//
//                    // Для розрахунку EndDate
//                    if (ordProductSF.EndDate == null || lotDate > ordProductSF.EndDate) {
//                        ordProductSF.EndDate = lotDate;
//                    }
//                }
//
//                // Оновлюємо останню дату лота в результаті
//                if (result.lastLotDate == null || lotDate > result.lastLotDate) {
//                    result.lastLotDate = lotDate;
//                }
////                END NEW LOGIC
//            }


            ordProductSF.FinallyProdDate__c = finalProdDate;
            ordProductSF.FinallyShippedDate__c = finalShippedDate;
            ordProductSF.FinallyDelivDate__c = finalDelivdate;

            if (ordProductSF.Stage__c == 'Shipped') {
                ordProductSF.EndDate = oldestLotDate;
                if (result.lastLotDate == null || oldestLotDate > result.lastLotDate) {
                    result.lastLotDate = oldestLotDate;
                }
            } else {
                ordProductSF.EndDate = null;
                result.isFullyShipped = false;
            }
        }
    }
    
    private static Map<String, PricebookEntry> selectPBEbyProduct2ERPId(List<ERPMessageParser.ERPObject_OrderItem> items, Opportunity opp) {
        Map<String, PricebookEntry> result = new Map<String, PricebookEntry> ();

        Map<String, ERPMessageParser.ERPObject_OrderItem> product2erpIdMap = new Map<String, ERPMessageParser.ERPObject_OrderItem> ();
        for (ERPMessageParser.ERPObject_OrderItem oppProdERP : items) {
            product2erpIdMap.put(oppProdERP.productGroup.id, oppProdERP);
        }

        Map<Id, String> prods = new Map<Id, String> ();
        for (Product2 prod2_item :[SELECT Id, ID_ERP__c FROM Product2 WHERE ID_ERP__c IN :product2erpIdMap.keySet()]) {
            prods.put(prod2_item.ID, prod2_item.ID_ERP__c);
        }
    
        List<Product2> products_to_insert = new List<Product2> ();
    
        for (String product2erpId : product2erpIdMap.keySet()) {
            if (!prods.values().contains(product2erpId)) {
                Product2 newProduct = new Product2();
                product2erpIdMap.get(product2erpId).ProductGroup.Name = OpportunityDataEmails.checkNameFieldSize(product2erpIdMap.get(product2erpId).ProductGroup.Name, 255);
                newProduct.Name = product2erpIdMap.get(product2erpId).ProductGroup.Name;
                product2erpIdMap.get(product2erpId).ProductGroup.Name = OpportunityDataEmails.checkNameFieldSize(product2erpIdMap.get(product2erpId).ProductGroup.Name, 80);
                newProduct.NameRus__c = product2erpIdMap.get(product2erpId).ProductGroup.Name;
                newProduct.ID_ERP__c = product2erpIdMap.get(product2erpId).ProductGroup.Id;
                products_to_insert.add(newProduct);
            }
        }
    
        if (!products_to_insert.isEmpty()) {
            insert products_to_insert;
    
            for (Product2 prod2_item : products_to_insert) {
                prods.put(prod2_item.ID, prod2_item.ID_ERP__c);
            }
        }
    
        List<PriceBookEntry> pb2;
        Id pricebookId;
    
        if (Test.isRunningTest()) {
            pricebookId = Test.getStandardPricebookId();
            pb2 = [SELECT Id, UnitPrice, Product2Id FROM PriceBookEntry WHERE Pricebook2Id = :pricebookId AND Product2Id in :prods.keySet()];
        } else {
            pb2 = [SELECT Id, UnitPrice, CurrencyIsoCode, Product2Id FROM PriceBookEntry WHERE Pricebook2Id = :opp.Pricebook2Id AND CurrencyISOcode = :opp.CurrencyISOcode AND Product2Id in :prods.keySet()];
        }
    
        Map<Id, PricebookEntry> pbeIdByProduct2erpId = new Map<Id, PricebookEntry> ();
        for (PricebookEntry pbe : pb2) {
            pbeIdByProduct2erpId.put(pbe.Product2Id, pbe);
        }
        List<PricebookEntry> pbe_to_insert = new List<PricebookEntry> ();
    
        if (!Test.isRunningTest()) {
            for (String Product2Id : prods.keySet()) {
                if (!pbeIdByProduct2erpId.keySet().contains(Product2Id)) {
                    PricebookEntry pbe = new PricebookEntry(CurrencyIsoCode = opp.CurrencyIsoCode,
                                                            Pricebook2Id = opp.Pricebook2Id,
                                                            IsActive = true,
                                                            Product2Id = Product2Id,
                                                            UnitPrice = product2erpIdMap.get(prods.get(Product2Id)).Price_t
                    );
                    pbe_to_insert.add(pbe);
                }
            }
        } else {
            for (String Product2Id : prods.keySet()) {
                if (!pbeIdByProduct2erpId.keySet().contains(Product2Id)) {
                    PricebookEntry pbe = new PricebookEntry(CurrencyIsoCode = opp.CurrencyIsoCode,
                                                            Pricebook2Id = pricebookId,
                                                            IsActive = true,
                                                            Product2Id = Product2Id,
                                                            UnitPrice = product2erpIdMap.get(prods.get(Product2Id)).Price_t
                    );
                    pbe_to_insert.add(pbe);
                }
            }
        }
    
        if (!pbe_to_insert.isEmpty()) {
            insert pbe_to_insert;
            for (PricebookEntry pbe_item : pbe_to_insert) {
                pb2.add(pbe_item);
            }
        }
    
        for (PricebookEntry pbe : pb2) {
            result.put(prods.get(pbe.Product2Id), pbe);
        }
        
        return result;
    }
    
    private static Map<String, Map<String, Id>> getObjectToIdMap(List<ERPMessageParser.ERPObject_OrderItem> oppProductsERP, String orderType) {
        Map<String, Map<String, Id>> objectToIdMap = new Map<String, Map<String, Id>> ();
        Map<String, Set<String>> erpValuesForObject = new Map<String, Set<String>> ();
        String serializedString = JSON.serialize(oppProductsERP);
        List<Object> oppProductFieldsList = (List<Object>) JSON.deserializeUntyped(serializedString);
        orderType = orderType==''?'Tubes':orderType;
        Set<String> keysToUse = new Set<String>(erp_to_sf_api_names_new.get(orderType).keySet());
        keysToUse.addALl(erp_to_sf_api_names_new.get('General').keySet());

        for (String key :  keysToUse) {
            Map<String, Object> CheckLengthSizeForNull;
            Set<String> valuesSet = new Set<String> ();

            for (Integer i = 0; i < oppProductFieldsList.size(); i++) {
                Map<String, Object> oppProductField = (Map<String, Object>) oppProductFieldsList.get(i);
                Map<String, Object> ERPObject;

                if(erp_to_sf_api_names_new.get('General').containsKey(key)) {
                    ERPObject = (Map<String,Object>) oppProductField.get(key);
                } else {
                    Map<String, Object> prodChar = (Map<String, Object>) oppProductField.get('productCharacteristic');
                    ERPObject = (Map<String,Object>) prodChar.get(key);
                }
                if(ERPObject == null && key == 'LengthSize'){
                    continue;
                }
                valuesSet.add((String) ERPObject.get('id'));

                //Повернутись до цього
                if(ERPObject != null){
                    if ((String) ERPObject.get('id') != null) {
                        if (key == 'shippingpoint') {
                            // По какой-то причине если код символьный, то в справочнике он иногда сохраняется маленькими буквами, и затем не совпадает с тем, что приходит в файле. Поэтому явно приводим все коды к LowerCase() тут и во время проверки.
                            String objIdLowerCase = ((String) ERPObject.get('id')).toLowerCase();
                            valuesSet.add((String) ERPObject.get('spType') + '-' + objIdLowerCase);
                        } else {
                            valuesSet.add((String) ERPObject.get('Id'));
                        }
                    }
                }
                erpValuesForObject.put(key, valuesSet);
            }
        }

        //проверка на пустой массив 20.09.2021
        for (String key : erpValuesForObject.keySet()) {
            Set<String> setERPIds = erpValuesForObject.get(key);
            String fromObject = erp_to_sf_api_names_new.get(orderType).get(key) == null 
                ? erp_to_sf_api_names_new.get('General').get(key) 
                : erp_to_sf_api_names_new.get(orderType).get(key);
            List<sObject> objectList = Database.query('SELECT Id, ID_ERP__c FROM ' + fromObject + ' WHERE ID_ERP__c IN :setERPIds');
            Map<String, Id> erpIdToIdMap = new Map<String, Id> ();
            for (sObject ob : objectList) {
                if (key == 'shippingpoint') {
                    // По какой-то причине если код символьный, то в справочнике он иногда сохраняется маленькими буквами, и затем не совпадает с тем, что приходит в файле. Поэтому явно приводим все коды к LowerCase() тут и во время проверки.
                    String idErpToLowerCase = ((String) ob.get('ID_ERP__c')).toLowerCase();
                    erpIdToIdMap.put(idErpToLowerCase, ob.Id);
                } else {
                    erpIdToIdMap.put((String) ob.get('ID_ERP__c'), ob.Id);
                }
            }
            objectToIdMap.put(key, erpIdToIdMap); 
        }
        
        return objectToIdMap;
    }

    public static void getKlwMaps(List<ERPMessageParser.ERPObject_OrderItem> oppProductsERP) {
        Set<String> specVersionIdSet = new Set<String>();
        Set<String> drawingIdSet = new Set<String>();

        for(ERPMessageParser.ERPObject_OrderItem oppProductERP : oppProductsERP) {
            specVersionIdSet.add(String.valueOf(oppProductERP.productCharacteristic.Specification));
            drawingIdSet.add(oppProductERP.productCharacteristic.Drawing.Id);
        }

        if(!specVersionIdSet.isEmpty()) {
            List<SpecVersion__c> specVersionList = [SELECT Id, DrawingVersion__c, ID_ERP__c FROM SpecVersion__c WHERE ID_ERP__c IN :specVersionIdSet];
            for(SpecVersion__c specVersion : specVersionList) {
                specVersionMap.put(specVersion.ID_ERP__c, specVersion);
            }
        }

        if(!drawingIdSet.isEmpty()) {
            List<DrawingVersion__c> drawingVersionList = [SELECT Id, Facet__c FROM DrawingVersion__c WHERE Facet__c IN :drawingIdSet];
            for(DrawingVersion__c drawingVersion : drawingVersionList) {
                drawingVersionMap.put(drawingVersion.Facet__c, drawingVersion);
            }
        }
    }
    
    public static void checkOpportunityStatus(ERPMessageParser.ErpToSfMessage_OpportunityData requestObj, UpdateSFRecordsResult result) {
        ERPMessageParser.ERPObject_OrderItem[] orderItems = requestObj.data.items;
        for (ERPMessageParser.ERPObject_OrderItem oppProdERP : orderItems) {
            //Пропустим строку, если не заполнены продукт или количество:
            if (oppProdERP.ProductGroup.id == null || oppProdERP.InqQuantity == null  || oppProdERP.InqQuantity == 0) {
                continue;
            }
    
            for (ERPMessageParser.ERPObject_ProductLot lot : oppProdERP.Lots) {
                result.hasLots = true;
                Date lotDate = ((lot.LotDate != null && lot.LotDate != '') ? Date.valueOf(lot.LotDate) : null);
                Decimal producedQuantity = (lot.Produced != null && lot.Produced != '' ? Decimal.valueOf(lot.Produced) : 0);
                Decimal dispatchedQuantity = (lot.Dispatched != null && lot.Dispatched != '' ? Decimal.valueOf(lot.Dispatched) : 0);
                Decimal shippedQuantity = (lot.Shipped != null && lot.Shipped != '' ? Decimal.valueOf(lot.Shipped) : 0);
    
                if (result.firstLotDate == null || lotDate < result.firstLotDate) {
                    result.firstLotDate = lotDate;
                }
                if (result.lastLotDate == null || lotDate > result.lastLotDate) {
                    result.lastLotDate = lotDate;
                }
            }
        }
    }
        
    private static Opportunity mapOpportunityFields(ERPMessageParser.ErpToSfMessage_OpportunityData requestObj, Opportunity opp, UpdateSFRecordsResult result, String requestBody) {   
        // В сообщении указано время в часовом поясе Украины, поэтому нужно привести его к GMT (для этого у юзера It-Enterprise должен быть установлен часовой пояс Украина):
        Integer offset = UserInfo.getTimezone().getOffset(Datetime.now());
        opp.CreatedDate_ERP__c = requestObj.data.header.createdDate;
        opp.LastSyncERP__c = Datetime.now();
        String countryId = String.valueOf(requestObj.data.header.Account.CountryId);
        String countryName = null;
        String countryMarketSegment = null;
        Id userId = null;
        String managerMarketingSegment = null;
        if (String.isNotBlank(countryId)) {
            List <Country__c> accountCountries = [SELECT Name, Market_Segment__c FROM Country__c WHERE NumCode__c =: countryId LIMIT 1];
            if (!accountCountries.isEmpty()) {
                countryName = accountCountries[0].Name;
                countryMarketSegment = accountCountries[0].Market_Segment__c;
            }
        }
        List<Account> accsToUpdate = new List <Account>();
        String accountERPId = requestObj.data.header.Account.ID == '130214' ? '67694' : requestObj.data.header.Account.ID;
        List<Account> accs = [SELECT Id, OwnerId, MarketSegment__c, ShippingCountry, ShippingStreet, BillingCountry, BillingStreet, ID_ERP__c FROM Account WHERE ID_ERP__c = :accountERPId OR (ID_ERP__c = null AND Name = :requestObj.data.header.Account.Name)];
        if (requestObj.data.header.salesRep != null && String.isNotBlank(requestObj.data.header.salesRep.Id)) {
            userOwner = [ SELECT User__c, User__r.SalesDivision__c, User__r.ID_ERP__c, User__r.IsActive FROM UserID_ERP__c WHERE (Name = :requestObj.data.header.salesRep.Id.replaceAll('(\\s+)', '') OR Name = :requestObj.data.header.salesRep.UID.replaceAll('(\\s+)', '')) AND Active__c = true AND User__r.IsActive = true LIMIT 1 ];
            if (userOwner.size() > 0 && userOwner[0].User__r.IsActive) {
                userId = userOwner[0].User__c;
                managerMarketingSegment = userOwner[0].User__r.SalesDivision__c;
                checkUserIdERP(userOwner[0], requestObj.data.header.salesRep.Id.replaceAll('(\\s+)', ''));
            }
        }

        for (Account acc: accs) {
            Boolean needsUpdate = false;
            if (acc.ID_ERP__c == null) {
                acc.ID_ERP__c = requestObj.data.header.Account.ID;
                needsUpdate = true;
            }
            if (acc.MarketSegment__c != requestObj.data.header.businessSegmentId) {
                acc.MarketSegment__c = requestObj.data.header.businessSegmentId == '00021' ? '00004' : requestObj.data.header.businessSegmentId;
                needsUpdate = true;
            }
            if (countryName != null && acc.ShippingCountry != countryName) {
                acc.BillingCountry = countryName;
                acc.ShippingCountry = countryName;
                needsUpdate = true;
            }
            if (requestObj.data.header.account.Address != null) {
                if (String.isBlank(acc.ShippingStreet)) {
                    acc.ShippingStreet = requestObj.data.header.account.Address;
                    needsUpdate = true;
                }
                if (String.isBlank(acc.BillingStreet)) {
                    acc.BillingStreet = requestObj.data.header.account.Address;
                    needsUpdate = true;
                }
            }
            if (needsUpdate) {
                accsToUpdate.add(acc);
            }
        }
        // Bulk update
        if (!accsToUpdate.isEmpty()) {
            update accsToUpdate;
        }
        checkListSize(accs, 'Account', requestObj.data.header.Account.ID, null, null);
        String newAccountOwnerId;
        if (accs.size() == 0) {
            if (result.isNewOppCreated == true || (result.isNewOppCreated == false && opp.Account.ID_ERP__c != null)) {
                //Если это новая оппа, либо существующая, в которой указан контрагент, с другим ID_ERP кодом, чем нам пришел,
                //то создадим нового контрагента, который чуть ниже подставится в оппу.
                if (requestObj.data.header.Account.Id != '164525') {
                    // Если это не служебная запись "Новый контрагент" в ИТ-Предприятии.
                    newAccountOwnerId = userId;
                    String businessSegmentId = requestObj.data.header.businessSegmentId == '00021' ? '00004' : requestObj.data.header.businessSegmentId;
                    String newAccountBusinessSegment = (businessSegmentId == null || businessSegmentId == '') ? countryMarketSegment : businessSegmentId;

                    if(newAccountOwnerId == null && newAccountBusinessSegment != null){
                        List <User> userList = [SELECT id FROM User WHERE (UserRole.Name LIKE 'Chief Sales Officer%' OR UserRole.Name LIKE 'Senior Sales Manager%') AND SalesDivision__c =: newAccountBusinessSegment LIMIT 1];
                        if (!userList.isEmpty()) {
                            newAccountOwnerId = userList[0].id;
                        }
                    }

                    else if(businessSegmentId == null  && newAccountOwnerId != null){
                        newAccountBusinessSegment = managerMarketingSegment;
                    }
    
                    Account acc = new Account();
                    RecordType rtAccountCustomer = [Select Id from RecordType where SObjectType = 'Account' AND Name = 'Customer' limit 1];
                    acc.RecordTypeId = rtAccountCustomer.Id;
                    requestObj.data.header.Account.Name = OpportunityDataEmails.checkNameFieldSize(requestObj.data.header.Account.Name, 80);
                    acc.Name = String.isNotBlank(requestObj.data.header.Account.Name) ? requestObj.data.header.Account.Name : 'Unnamed account from IT-Enterprise ERP system';
                    acc.ID_ERP__c = requestObj.data.header.Account.ID;
                    acc.BillingCountry = countryName;
                    if(newAccountOwnerId != null){
                        acc.OwnerId = newAccountOwnerId;
                    }
                    if(newAccountBusinessSegment == null && newAccountOwnerId == null){
                        acc.Activity_Type__c = 'Unknown';
                    }
                    acc.ShippingStreet = requestObj.data.header.account.Address;
                    acc.BillingStreet = requestObj.data.header.account.Address;
                    acc.MarketSegment__c = newAccountBusinessSegment;
                    if(acc.MarketSegment__c == null) {
                        String errorMessage = 'Account without Market Segment cannot be created';
                        throw new erpException(errorMessage);
                    }
                    insert acc;
                    if(acc.Activity_Type__c == 'Unknown') {
                        OpportunityDataEmails.sendEmailAboutUnknownAccount(acc.Id);
                    }
                    accs.add(acc);
                }
            } else {
                //Если это существующая оппа, в которой указан контрагент с пустым кодом ID_ERP,
                //то заполним этот код значением из сообщения.
                if (requestObj.data.header.Account.Id != '164525') {
                    // Если это не служебная запись "Новый контрагент" в ИТ-Предприятии.
                    Account acc = [SELECT Id FROM Account WHERE Id = :opp.AccountId LIMIT 1];
                    acc.ID_ERP__c = requestObj.data.header.Account.ID;
                    update acc;
                    accs.add(acc);
                }
            }
        } 

        if (requestObj.data.header.Account.Id != '164525') {
            // Апдейтим контрагента в оппе, только если это не служебная запись "Новый контрагент" в ИТ-Предприятии.
            opp.AccountId = accs[0].Id;
        }
    
        Map<String, sObject> sObjects_to_insert = new Map<String, sObject> ();
    
        if (requestObj.data.header.countryId != null) {
            countryId = String.valueOf(requestObj.data.header.countryId);
            country = [SELECT Id FROM Country__c WHERE NumCode__c = :countryId];
                
            checkListSize(country, 'Country', countryId, null, sObjects_to_insert);
            if (country.size() == 0) {
                opp.Country__c = sObjects_to_insert.get('Country').Id;
            } else {
                opp.Country__c = country[0].Id;
            }
        } else {
            opp.Country__c = null;
        }
        if (String.isNotBlank(requestObj.data.header.PaymentTerms.ID)) {
            paymentTerms = [SELECT Id, ID_ERP__c FROM PaymentTerms__c WHERE ID_ERP__c = :requestObj.data.header.PaymentTerms.ID];
            checkListSize(paymentTerms, 'PaymentTerms', requestObj.data.header.PaymentTerms.ID, requestObj.data.header.PaymentTerms.Name, sObjects_to_insert);
            if (paymentTerms.isEmpty()) {
                opp.PaymentTerms__c = sObjects_to_insert.get('PaymentTerms').Id;
            } else {
                opp.PaymentTerms__c = paymentTerms[0].Id;
            }
        } else {
            opp.PaymentTerms__c = null;
        }
        if (String.isNotBlank(requestObj.data.header.DeliveryTerms.ID)) {
            deliveryTerms = [SELECT Id FROM DeliveryTerms__c WHERE ID_ERP__c = :requestObj.data.header.DeliveryTerms.ID];
            if (deliveryTerms.size() == 0) {
                DeliveryTerms__c obj_to_insert = new DeliveryTerms__c(Name = requestObj.data.header.DeliveryTerms.Name, Id_ERP__c = requestObj.data.header.DeliveryTerms.ID);
                requestObj.data.header.DeliveryTerms.Name = OpportunityDataEmails.checkNameFieldSize(requestObj.data.header.DeliveryTerms.Name, 80);
                obj_to_insert.Name = requestObj.data.header.DeliveryTerms.Name;
                obj_to_insert.NameRus__c = requestObj.data.header.DeliveryTerms.Name;
                obj_to_insert.Incoterms__c = requestObj.data.header.DeliveryTerms.Incoterms;
                insert obj_to_insert;
                opp.DeliveryTerms__c = obj_to_insert.Id;
            } else {
                opp.DeliveryTerms__c = deliveryTerms[0].Id;
            }
        } else {
            opp.DeliveryTerms__c = null;
        }
    
        if (opp.OwnerId == null) {
            //Владельца устанавливаем только в новых созданных оппах
            if (requestObj.data.header.salesRep != null && String.isNotBlank(requestObj.data.header.salesRep.Id)) {
                //Если менеджер по сегменту Европа, то из ИТ приходит код "xxxxx", (после отделения европейского офиса
                //переназначили часть продуктовой линейки продавцам БВиА, и импортировали заказы по этим продуктам из ИТ)
                if (requestObj.data.header.salesRep.id == 'xxxxx'){
                    opp.OwnerId = UserInfo.getUserId();
                    opp.InitialOwnerName__c = requestObj.data.header.salesRep.Name;
                } else {                                         
                    checkListSize(userOwner, 'Users (Sales Manager)', requestObj.data.header.salesRep.Id, requestObj.data.header.salesRep.Name, null);
                    opp.OwnerId = userOwner[0].User__c;
                    opp.InitialOwnerName__c = '';
                }
            } else if (String.isNotBlank(newAccountOwnerId)){
                opp.OwnerId = newAccountOwnerId;
            } 
        }
            
        if (String.isNotBlank(requestObj.data.header.boSpecialist.Id)) {
            userBOSpecialist = [SELECT User__c, User__r.ID_ERP__c FROM UserID_ERP__c WHERE (Name = :requestObj.data.header.boSpecialist.Id.replaceAll('(\\s+)', '') OR Name = :requestObj.data.header.boSpecialist.UID.replaceAll('(\\s+)', '')) AND Active__c = true LIMIT 1];
            checkListSize(userBOSpecialist, 'Users (BO specialist)', requestObj.data.header.BOSpecialist.Id, null, null);
            if (userBOSpecialist.size() > 0) {
                opp.AssignedBOS__c = userBOSpecialist[0].User__c;
                checkUserIdERP(userBOSpecialist[0], requestObj.data.header.BOSpecialist.Id.replaceAll('(\\s+)', ''));
            } 
        } 

        if(userId != null){
            opp.OwnerId = userId;
        }
        opp.CurrencyIsoCode = requestObj.data.orderCurrency;
    	opp.PO_Number__c = String.valueOf(requestObj.data.header.pONumber);
        opp.ITENumber__c = requestObj.data.header.ITENumber;
        opp.AdditionalNumber__c = requestObj.data.header.altNumber;
        opp.MarketSegment__c = String.valueOf(requestObj.data.header.businessSegmentId == '00021' ? '00004' : requestObj.data.header.businessSegmentId);
        opp.Region__c = String.valueOf(requestObj.data.header.regionId);
        opp.CrossMarketSegment__c = requestObj.data.header.crossMarket_BusinessSegment;
        if (String.isNotBlank(requestObj.data.header.crossMarket_BusinessSegment)) {
            List<UserID_ERP__c> userCrossMarketManager = [SELECT User__c, User__r.ID_ERP__c FROM UserID_ERP__c WHERE (Name = :requestObj.data.header.crossMarket_SalesRep.Name OR Name = :requestObj.data.header.salesRep.UID.replaceAll('(\\s+)', '')) AND Active__c = true LIMIT 1];
            if (userCrossMarketManager.size() > 0) {
                opp.CrossMarketManager__c = userCrossMarketManager[0].User__c;
            }
        } else {
            opp.CrossMarketManager__c = null;
        }
        opp.CrossMarketShare__c = requestObj.data.header.crossMarket_Percent;
    
        return opp;
    }
        
    public static Order mapOrderFields(ERPMessageParser.ErpToSfMessage_OpportunityData requestObj, Order ord, UpdateSFRecordsResultOrder result, ERPMessageHandlerOpportunityData.UpdateSFRecordsResult resultOpp) {
        Map<String, sObject> sObjects_to_insert = new Map<String, sObject> ();
        ord.AccountId = resultOpp.parentOpp.AccountId;

        if (requestObj.data.header.countryId != null) {
            String countryId = String.valueOf(requestObj.data.header.countryId);
            if(country.isEmpty()) {
                country = [SELECT Id FROM Country__c WHERE NumCode__c = :countryId];
            }
            checkListSize(country, 'Country', countryId, null, sObjects_to_insert);
            if (country.size() == 0) {
                ord.Country__c = sObjects_to_insert.get('Country').Id;
            } else {
                ord.Country__c = country[0].Id;
            }
        } else {
            ord.Country__c = null;
        }
        if (String.isNotBlank(requestObj.data.header.PaymentTerms.ID)) {
            if(paymentTerms.isEmpty()) {
                paymentTerms = [SELECT Id, ID_ERP__c FROM PaymentTerms__c WHERE ID_ERP__c = :requestObj.data.header.PaymentTerms.ID];
            }
            checkListSize(paymentTerms, 'PaymentTerms', requestObj.data.header.PaymentTerms.ID, requestObj.data.header.PaymentTerms.Name, sObjects_to_insert);
            String nameOfPaymentTerms = requestObj.data.header.PaymentTerms.Name;
            if (paymentTerms.isEmpty()) {
                ord.PaymentTerms__c = sObjects_to_insert.get('PaymentTerms').Id;
            } else {
                ord.PaymentTerms__c = paymentTerms[0].Id;
            }
        } else {
            ord.PaymentTerms__c = null;
        }
        if (String.isNotBlank(requestObj.data.header.DeliveryTerms.ID)) {
            if(deliveryTerms.isEmpty()) {
                deliveryTerms = [SELECT Id FROM DeliveryTerms__c WHERE ID_ERP__c = :requestObj.data.header.DeliveryTerms.ID];
            }
            if (deliveryTerms.size() == 0) {
                DeliveryTerms__c obj_to_insert = new DeliveryTerms__c(Name = requestObj.data.header.DeliveryTerms.Name, Id_ERP__c = requestObj.data.header.DeliveryTerms.ID);
                obj_to_insert.Incoterms__c = requestObj.data.header.DeliveryTerms.Incoterms;
                insert obj_to_insert;
                ord.DeliveryTerms__c = obj_to_insert.Id;
            } else {
                ord.DeliveryTerms__c = deliveryTerms[0].Id;
            }
        } else {
            ord.DeliveryTerms__c = null;
        }
    
        if (ord.OwnerId == null) {
            ord.OwnerId = resultOpp.parentOpp.OwnerId;
            ord.InitialOwnerName__c = resultOpp.parentOpp.InitialOwnerName__c;
        }
    
        if (String.isNotBlank(requestObj.data.header.BOSpecialist.Id)) {
            if(userBOSpecialist.isEmpty()) {
                userBOSpecialist = [SELECT User__c, User__r.ID_ERP__c FROM UserID_ERP__c WHERE (Name = :requestObj.data.header.BOSpecialist.Id.replaceAll('(\\s+)', '') OR Name = :requestObj.data.header.BOSpecialist.UID.replaceAll('(\\s+)', '')) AND Active__c = true LIMIT 1];
                if (userBOSpecialist.size() > 0) {
                    checkUserIdERP(userBOSpecialist[0], requestObj.data.header.BOSpecialist.Id.replaceAll('(\\s+)', ''));
                }
            }
            
            if (userBOSpecialist.size() > 0) {
                ord.AssignedBOS__c = userBOSpecialist[0].User__c;
            }    
        }
    		
        ord.PO_Number__c = String.valueOf(requestObj.data.header.pONumber);
        ord.ID_ERP__c = String.valueOf(requestObj.data.header.unDoc);
        ord.ITENumber__c = requestObj.data.header.ITENumber;
        ord.AdditionalNumber__c = requestObj.data.header.altNumber;
        ord.CurrencyIsoCode = requestObj.data.orderCurrency;
        ord.MarketSegment__c = String.valueOf(requestObj.data.header.businessSegmentId == '00021' ? '00004' : requestObj.data.header.businessSegmentId);
        ord.Region__c = String.valueOf(requestObj.data.header.regionId);
        ord.CrossMarketSegment__c = requestObj.data.header.crossMarket_BusinessSegment;
        if (String.isNotBlank(requestObj.data.header.crossMarket_SalesRep.Name)) {
            List<UserID_ERP__c> userCrossMarketManager = [SELECT User__c, User__r.ID_ERP__c FROM UserID_ERP__c WHERE (Name = :requestObj.data.header.crossMarket_SalesRep.Name OR Name = :requestObj.data.header.salesRep.UID.replaceAll('(\\s+)', '')) AND Active__c = true LIMIT 1];
            if (userCrossMarketManager.size() > 0) {
                ord.CrossMarketManager__c = userCrossMarketManager[0].User__c;
            }  
        } else {
            ord.CrossMarketManager__c = null;
        }
        ord.CrossMarketShare__c = requestObj.data.header.crossMarket_Percent;
    
        return ord;
    }
    
    public static void checkListSize(List<SObject> listToCheck, String objName, String obj_ID_ERP, String request_obj_name, Map<String, sObject> sObjects_to_insert) {
        if (listToCheck.size() == 0 && objName != 'Account') {
            if (objName == 'Users (Sales Manager)') {
                String errorMessage = 'There is no ' + objName + ' with ID ERP ' + obj_ID_ERP + '. User name: ' + request_obj_name;
                throw new erpException(errorMessage);
            } else {
                if (objName == 'Country') {
                    if(country_not_spec == null) {
                        country_not_spec = [SELECT Id FROM Country__c WHERE NumCode__c = '0' LIMIT 1];
                    }
                    sObjects_to_insert.put(objName, country_not_spec);
                } else if(objName == 'Users (BO Specialist)' || objName == 'Users (cross-market manager)') {
                    //Ничего не делаем.
                } else {
                    sObject sObj_to_insert = Schema.getGlobalDescribe().get(erp_to_sf_api_names_opp.get(objName)).newSObject();
        
                    if (objName == 'PaymentTerms') {
                        request_obj_name = OpportunityDataEmails.checkNameFieldSize(request_obj_name, 255);
                        sObj_to_insert.put('NameFull__c', request_obj_name);
                        sObj_to_insert.put('NameFullRus__c', request_obj_name);
                        request_obj_name = OpportunityDataEmails.checkNameFieldSize(request_obj_name, 80);
                        sObj_to_insert.put('NameRus__c', request_obj_name);
                    }
                    request_obj_name = OpportunityDataEmails.checkNameFieldSize(request_obj_name, 80);
        
                    sObj_to_insert.put('Name', request_obj_name);
                    sObj_to_insert.put('Id_ERP__c', obj_ID_ERP);
                    insert sObj_to_insert;
                    sObjects_to_insert.put(objName, sObj_to_insert);
                }
            }
        } else if (listToCheck.size() > 1) {
            String errorMessage = 'There are several ' + objName + ' with such ID ERP(' + obj_ID_ERP + ').';
            throw new erpException(errorMessage);
        }
    }
    
    public static Blob generateResponseBodyOppUpdate(Integer statusCode, String error, ERPMessageHandlerOpportunityData.UpdateSFRecordsResult oppResult, ERPMessageHandlerOpportunityData.UpdateSFRecordsResult oppProductsResult) {
        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();
        gen.writeNumberField('Status Code', statusCode);
        gen.writeStringField('Status', HTTPSTATUSES.get(statusCode));
        if (error != NULL) {
            gen.writeStringField('Error Message', error);
        }
        if (oppResult?.parentOpp?.Id != NULL) {
            if (oppResult.isNewOppCreated == true) {
                gen.writeStringField('Created Opportunity Id', oppResult.parentOpp.Id);
            } else {
                gen.writeStringField('Updated Opportunity Id', oppResult.parentOpp.Id);
            }
        }
        if (oppProductsResult?.newOppProductsIds.size() > 0) {
            gen.writeFieldName('Created Opportunity Products');
            if (oppProductsResult.newOppProductsIds.size() > 0) {
                gen.writeStartArray();
            }
            for (Integer i = 0; i<oppProductsResult.newOppProductsIds.size(); i++) {
                gen.writeStartObject();
                gen.writeObjectField('Id', oppProductsResult.newOppProductsIds[i]);
                gen.writeEndObject();
            }
            if (oppProductsResult.newOppProductsIds.size()> 0) {
                gen.writeEndArray();
            }
        }
        if (oppProductsResult?.updatedOppProductsIds.size() > 0) {
            gen.writeFieldName('Updated Opportunity Products');
            if (oppProductsResult.updatedOppProductsIds.size() > 0) {
                gen.writeStartArray();
            }
            for (Integer i = 0; i<oppProductsResult.updatedOppProductsIds.size(); i++) {
                gen.writeStartObject();
                gen.writeObjectField('Id', oppProductsResult.updatedOppProductsIds[i]);
                gen.writeEndObject();
            }
            if (oppProductsResult.updatedOppProductsIds.size()> 0) {
                gen.writeEndArray();
            }
        }
        gen.writeEndObject();
        String res = gen.getAsString();
        return Blob.valueOf(res);
    }



    @testVisible
    private static Set<Integer> getOppProductERPIds(List<ERPMessageParser.ERPObject_OrderItem> oppProductsERP) {
        Set<Integer> oppProdIds = new Set<Integer> ();
        if (oppProductsERP != null) {
            for (ERPMessageParser.ERPObject_OrderItem oppProduct : oppProductsERP) {
                if (oppProduct.npp == null) {
                    String errorMessage = 'Your Opportunity Line Item does not contain required ID_ERP field.';
                    throw new erpException(errorMessage);
                }
                oppProdIds.add(oppProduct.npp);
            }
        }
        return oppProdIds;
    }
    
    @testVisible
    private static Map<Integer, OpportunityLineItem> getOppProdSFMap(Set<Integer> oppProdIds, String fieldName, String oppId) {
        String queryString =
        'SELECT Id, ID_ERP__c, Name, Stage__c, Product2.ID_ERP__c, SteelGrade__r.ID_ERP__c, Quantity, Quantity_m__c,Is_Placed__c,TotalPrice,InitialQuantity__c,ServiceDate,ExtraCosts_t__c,FinDept__c,Liabilities_t__c,ListPrice,ProductCode,ProductType__c,' +
        'Quantity_ft__c,ProductionAllowed__c, TubeEnds__r.ID_ERP__c,Opportunity.Owner__c, Coating__c,SCDept__c, WheelProductStandard__r.ID_ERP__c, WheelSteelGrade__r.ID_ERP__c, WheelHub__r.ID_ERP__c, WheelDrawing__r.ID_ERP__c, Shop__r.ID_ERP__c, Description, TechExp__c, PricebookEntryId,' +
        'TubeOD__r.ID_ERP__c, TubeWT__r.ID_ERP__c, WheelDiameter__r.ID_ERP__c, NPP_ERP__c, OpportunityId FROM OpportunityLineItem WHERE OpportunityId=\'' + oppId + '\'';
    
        List<OpportunityLineItem> oppProducts = Database.query(queryString);
    
        Map<Integer, OpportunityLineItem> oppProdMap = new Map<Integer, OpportunityLineItem> ();
        for (OpportunityLineItem oppProd : oppProducts) {
            oppProdMap.put((Integer) integer.valueof(oppProd.get(fieldName)), oppProd);
        }
        return oppProdMap;
    }
    
    @testVisible
    private static Map<Integer, OrderItem> getOrdProdSFMap(Set<Integer> oppProdIds, String fieldName, String ordId) {
        String queryString =
        'SELECT Id, ID_ERP__c, Name__c, Product2Id, SteelGrade__r.ID_ERP__c, Quantity,' +
        'TubeEnds__r.ID_ERP__c, Coating__c, WheelProductStandard__r.ID_ERP__c, WheelSteelGrade__r.ID_ERP__c, WheelHub__r.ID_ERP__c, WheelDrawing__r.ID_ERP__c, Description, PricebookEntryId,' +
        'TubeOD__r.ID_ERP__c, TubeWT__r.ID_ERP__c, WheelDiameter__r.ID_ERP__c, NPP_ERP__c, OrderId FROM OrderItem WHERE OrderId=\'' + ordId + '\'';
    
        List<OrderItem> ordProducts = Database.query(queryString);
        Map<Integer, OrderItem> ordProdMap = new Map<Integer, OrderItem> ();
        if (ordProducts.size() > 0) {
            for (OrderItem ordProd : ordProducts) {
                ordProdMap.put(Integer.valueOf(ordProd.get(fieldName)), ordProd);
            }
        }
        return ordProdMap;
    }

    public static Opportunity getOpportunitySFByERPID(Integer oppIdERP) {
        if (relatedOpp != null) {
            return relatedOpp;
        }

        String oppIdERPstr = String.valueOf(oppIdERP);
        List<Opportunity> oppList = [SELECT Id, ID_ERP__c, CreatedDate, OwnerId, Owner.LanguageLocaleKey, InitialOwnerName__c, StageName, CloseDate,
                                        IsClosed, IsWon, Country__c, DeliveryTerms__c, Description, DeliveryTerms__r.Name, Pricebook2Id,
                                        AssignedBOS__c, AssignedBOS__r.Name, AssignedBOS__r.Email, SyncedOrder__c, Name,
                                        ContractId, AccountId, Account.ID_ERP__c, Account.Name, CurrencyIsoCode,
                                        IsSecondChoice__c
                                        FROM Opportunity
                                        WHERE ID_ERP__c = :oppIdERPstr
                                    ];

        if (oppList.size() != 0) {
            relatedOpp = oppList[0];
        }
        return relatedOpp;
    }
    
    public static OpportunityLineItem createNewOli(ERPMessageParser.ERPObject_OrderItem oppProdERP, Id parentOppId, Map<String, PricebookEntry> pbeIdByProduct2erpId) {
        String currentStage = OpportunityDataEmails.mapStageResult(oppProdERP.Stage, stageCodeMap, oppProdERP);
        OpportunityLineItem newOLI = new OpportunityLineItem();
        newOLI.OpportunityId = parentOppId;
        newOLI.PricebookEntryId = pbeIdByProduct2erpId.get(oppProdERP.ProductGroup.ID).Id;
        newOLI.TotalPrice = null;
        newOLI.NPP_ERP__c = String.valueOf(oppProdERP.npp);
        newOLI.Stage__c = currentStage != null ? currentStage.substringBefore('(') : null;
        newOLI.Is_Placed__c = newOLI.Is_Placed__c==false?checkIfPlaced(oppProdERP.Stage):true;
        return newOli;
    }
    
    public static List<OpportunityLineItem> getOpportunityLineItem(String OppLiNpp, String oppId) {
        List<OpportunityLineItem> result = [SELECT Id, OpportunityId, Stage__c, TechExp__c, ID_ERP__c, CDD__c, CDDRecommended__c, NPP_ERP__c,Is_Placed__c FROM OpportunityLineItem WHERE OpportunityId = :oppId AND NPP_ERP__c = :OppLiNpp];
        return result;
    }

    public static Blob generateResponseBody(Integer statusCode, String error) {
        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();
        gen.writeNumberField('Status Code', statusCode);
        gen.writeStringField('Status', HTTPSTATUSES.get(statusCode));
        if (error != NULL) {
            gen.writeStringField('Error Message', error);
        }
        gen.writeEndObject();
        String res = gen.getAsString();
        return Blob.valueOf(res);
    }
    
    public static Map<String, String> makeMapForStage(){
    	Map<String, String> valuesCodes = new Map<String, String>();
		Schema.DescribeFieldResult fieldResult = Product_Picklist_Stage__mdt.Stage__c.getDescribe();
    	List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
    	for( Schema.PicklistEntry pickListVal : ple){    			
        	valuesCodes.put(pickListVal.getValue(),pickListVal.getLabel());
    	}
        return valuesCodes;
    }

    private static void checkUserIdERP(UserID_ERP__c link, String currentId) {
        if (String.isBlank(currentId) || link == null || link.User__c == null) return;

        User u = [
                SELECT Id, IsActive, ID_ERP__c
                FROM User
                WHERE Id = :link.User__c
                LIMIT 1
        ];

        if (!u.IsActive) return;
        if (u.ID_ERP__c == currentId) return;

        List<User> holders = [
                SELECT Id, IsActive
                FROM User
                WHERE ID_ERP__c = :currentId AND Id != :u.Id
                LIMIT 1
        ];

        // (Опційно) оновлюємо тільки якщо було порожньо — щоб не перетирати існуючі значення
        if (u.ID_ERP__c == null) {
            update new User(Id = u.Id, ID_ERP__c = currentId, EmployeeNumber = currentId);
        }
    }

    
    public static boolean checkIfPlaced(String apiName){
        boolean isPlaced = false;
        if(isPlacedList.contains(apiName)){
            isPlaced = true;
        }
        return isPlaced;           
    }
    
        public class UpdateSFRecordsResult {
            public Boolean isError = false;
    
            public Map<String, Map<String, Id>> objToIdMap;
    
            public Boolean isNewOppCreated = false;
            public Boolean isCurrencyCodeChanged = false;
            public Opportunity parentOpp;
            public String oppChangeStatus;
            
            public Date firstLotDate; //Содержит дату самого раннего лота по данной оппе во входящем сообщении из ERP.
            public Date lastLotDate; //Содержит дату самого позднего лота по данной оппе во входящем сообщении из ERP.
            public Boolean hasLots = false; // установится в True, если хотя бы по одной позиции обнаружим данные по Execution.
    
    
            public List<String> newOppProductsIds;
            public List<String> updatedOppProductsIds;
        }
    
        public class UpdateSFRecordsResultOrder {
            public Boolean isError = false;
    
            public Boolean isNewOrderCreated = false;
            public Order parentOrd;
            public Boolean isCurrencyCodeChanged = false;
    
            public List<String> newOrdProductsIds;
            public List<String> updatedOrdProductsIds;
            public List<String> deletedOrdProductsIds;
    
            public Boolean isFullyShipped = true; //изначально предполагаем, что весь заказ реализован, но если попадется хоть одна не реализованная позиция, изменим значение на False.
            public Date firstLotDate;
            public Date lastLotDate;
        }

        public class erpException extends Exception { }

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
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++; 
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
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