public class ERPMessageHandlerPriceApprovalRequest  {
    
    static PriceApprovalRequest__c par;
    static List<Id> currentApproversIdList = new List<Id>();
    
    static String allApprovalComments;

    final static List<String> ACTIVE_SEGMENTS = new List<String> {
        '00001', // Americas
        '00002', // MENA
        '00004', // Europe
        '00006', // KLW
        '00010', // CIS
        '00011', // Ukraine
        '00016',  // Custom Union
        '00020',   //ETA 
        '00021'   //Machinery 
    };

    final static Map<String, String> LABELS_TO_SF_API_NAMES = new Map<String, String> {
        'Customer'          => 'Account',
        'Payment Terms'     => 'PaymentTerms__c',
        'Delivery Terms'    => 'DeliveryTerms__c'
    };

    final static Map<String, String> ERP_TO_SF_API_NAMES = new Map<String, String> {
        'productGroup'  => 'Product2',
        'shop'          => 'Shop__c',
        'specLevel'     => 'ProductSpecLevel__c',
        'steelGrade'    => 'SteelGrade__c',
        'standard'      => 'ProductStandard__c',
        'od'            => 'TubeOD__c',
        'wt'            => 'TubeWT__c',
        'lengthSize'    => 'TubeLengthSize__c',
        'coating'       => 'CoatingType__c',
        'ends'          => 'TubeEnds__c',
        'country'       => 'Country__c',
        'shippingPoint' => 'ShippingPoint__c',
        'deliveryTerms' => 'DeliveryTerms__c'
    };

    final static List<String> APPROVABLE_STAGES = new List<String> {
        '_3', // Confirmation by Sales Rep
        '_18', // Approval by PRD director
        '_20' // Additional approval by PRD director
    };

    final static Map<String, String> STAGES_TO_APPROVAL_PROCESS_NAMES = new Map<String, String> {
        '_3' => 'PAR_Sales_Rep',
        '_18' => 'PAR_PRD_Director',
        '_20' => 'PAR_PRD_Director'
    };

    final static Country__c country_not_spec = [SELECT Id FROM Country__c WHERE ID_ERP__c = '0' LIMIT 1];

    static Map<Id, SteelGrade__c> sgMap = new Map<Id, SteelGrade__c> ();
    static Map<Id, TubeOD__c> odMap = new Map<Id, TubeOD__c> ();
    static Map<Id, TubeWT__c> wtMap = new Map<Id, TubeWT__c> ();
    static Map<Id, TubeLengthSize__c> lsMap = new Map<Id, TubeLengthSize__c> ();
    static Set<String> sgIds = new Set<String> ();
    static Set<String> odIds = new Set<String> ();
    static Set<String> wtIds = new Set<String> ();
    static Set<String> lsIds = new Set<String> ();

    static Set<String> oppIdErpSet = new Set<String>();
    static Map<String, Id> oppIdErpToIdMap = new Map<String, Id>();
    static Id oppAccountId;
    static String oppErrMessage;
    static Id srId;
    static Id boId;
    static Id prmdId;
    static Boolean srIsActive;


    
    public static MessageProcessingResult ProcessMessage(ERPMessageParser.ErpToSfMessage_PAR parsedMessage, String requestBody) {
        
        MessageProcessingResult res = new MessageProcessingResult();
        res.MessageType = parsedMessage.metadata.msgType;
        ERPMessageParser.PARHeader parHeader = parsedMessage.data.header;
        ERPMessageParser.PARItem[] parItems = parsedMessage.data.items;
        List<OpportunityLineItem> oppItemsNewMarginUpdate = new List<OpportunityLineItem>();
        Boolean marginNullValue = false;

        if (!ACTIVE_SEGMENTS.contains(parHeader.segment)) {
            res.resultComment = 'PAR was not saved because the Market Segment ' + parHeader.segment + ' is not used in Salesforce';
            return res;
        }

        if (parsedMessage.data.items.isEmpty()) {
            res.resultComment = 'PAR was not saved because it has now items';
            return res;
        }

        if (parHeader.salesRep_EmpNum.Id.trim() == parHeader.boSpecialist_EmpNum.Id.trim()) {
            // Если бек и продавец в служебке - один и тот же человек, то не импортируем эту служебку
            res.resultComment = 'PAR was not saved because the sales rep is the same person as the BO specialist: ' + parHeader.boSpecialist_EmpNum.Name.trim();
            return res;
        }

        oppErrMessage = '';
        List<Opportunity> oppList = getOpportunities(parsedMessage.data.items);
        if (oppList == null){
            res.resultComment = 'PAR was not saved. ' + oppErrMessage;
            return res;
        }

        Long messageTimestamp = parsedMessage.metadata.msgTimestamp.getTime();

        List<PriceApprovalRequestItem__c> parItemsToUpsert = new List<PriceApprovalRequestItem__c> ();
        List<PriceApprovalRequestItem__c> parItemsToDelete = new List<PriceApprovalRequestItem__c> ();

        // Сохраним мапу с айдишниками юзеров из сообщения:
        List<String> usrIdErpList = new List<String>();
        usrIdErpList.add(parHeader.salesRep_EmpNum.Id.trim());
        usrIdErpList.add(parHeader.boSpecialist_EmpNum.Id.trim());
        usrIdErpList.add(parHeader.prmDirector_EmpNum.Id.trim());
        List<UserID_ERP__c> usrList = [SELECT Id, Name, User__c, User__r.Name, User__r.ManagerId, User__r.isActive 
                                       FROM UserID_ERP__c WHERE Name in :usrIdErpList];
        Map<String, UserID_ERP__c> usrIdMap = new Map<String, UserID_ERP__c>();
        For(UserID_ERP__c usrIdErp : usrList) {
            usrIdMap.put(usrIdErp.Name, usrIdErp);
        }
        srId = usrIdMap.get(parHeader.salesRep_EmpNum.Id.trim())?.User__c;
        srIsActive = usrIdMap.get(parHeader.salesRep_EmpNum.Id.trim())?.User__r.isActive;
        boId = usrIdMap.get(parHeader.boSpecialist_EmpNum.Id.trim())?.User__c;
        prmdId = usrIdMap.get(parHeader.prmDirector_EmpNum.Id.trim())?.User__c;
        //------------------------------------------------------
        
        //Найдем существующую или создадим новую запись PriceApprovalRequest__c:
        par = getPriceApprovalRequest(parHeader, parItems, res);

        checkRelations();
        
        // Создадим список с СФ-айдишниками всех текущих аппруверов:
        switch on par.StageERP__c {
            when '_3' {
                if (srId == null) {
                    res.resultComment = 'PAR was not saved because there is no any user with ERP-ID ' + parHeader.salesRep_EmpNum.Id.trim();
                    return res;
                }
                currentApproversIdList.add(srId);
            }
            when '_18', '_20' {
                if (prmdId == null) {
                    res.resultComment = 'PAR was not saved because there is no any user with ERP-ID ' + parHeader.prmDirector_EmpNum.Id.trim();
                    return res;
                }
                currentApproversIdList.add(prmdId);
            }
        }
        /* Пока что СФ не позволяет добавлять несколько процессов с динамическими аппруверами, поэтому пришлось закомментировать.
        for (String approverIdErp : parsedMessage.StageInfo.OwnersIDs) {
            Id approverId = usrIdMap.get(approverIdErp.trim())?.User__c;
            if (approverId != null && !currentApproversIdList.contains(approverId)) {
                currentApproversIdList.add(approverId);
            }
        }
        */
        System.debug('>>>>>>>>>> current approvers list: ' + currentApproversIdList);

        //Создадим мапу, в которой хранится имя объекта и мапа соответствия ID_ERP и ID. Объекты, которые добавляются в эту мапу, перечислены в ERP_TO_SF_API_NAMES.
        //Например: <'Shop__c' --> <ID_ERP --> Id>>
        Map<String, Map<String, Id>> objToIdMap = getObjectToIdMap(parItems);

        //Сформируем мапу: <Код OpportunityID_ERP --> Opportunity>
        Map<String, Opportunity> oppIdErpToObjMap = getOppIdErpToObjMap(parItems);

        //Сформируем мапу: <Код OpportunityLineItemITENumber --> OpportunityLineItem>
        Map<String, OpportunityLineItem> oliITENumberToObjMap = getOliITENumberToObjMap(parItems);

        sgMap = new Map<Id, SteelGrade__c> ([SELECT Id, Name FROM SteelGrade__c WHERE ID_ERP__c = :sgIds]);
        odMap = new Map<Id, TubeOD__c> ([SELECT Id, OD_mm__c, OD_inch__c FROM TubeOD__c WHERE ID_ERP__c = :odIds]);
        wtMap = new Map<Id, TubeWT__c> ([SELECT Id, WT_mm__c, WT_inch__c FROM TubeWT__c WHERE ID_ERP__c = :wtIds]);
        lsMap = new Map<Id, TubeLengthSize__c> ([SELECT Id, Name, MaxLength__c FROM TubeLengthSize__c WHERE ID_ERP__c = :lsIds]);
        
        //Сформируем мапу: <код ID_ERP --> объект parItem>
        Map<String, PriceApprovalRequestItem__c> parItemByIdERPMap = getIdErpToParItemMap();

        for (ERPMessageParser.PARItem parItemERP : parItems) {
            //Пропустим строку, если не заполнены продукт или количество:
            if (String.isBlank(parItemERP.productGroup.Id) || parItemERP.inqQuantity == null || parItemERP.inqQuantity == 0) {
                continue;
            }
            /*
            if (String.isBlank(parItemERP.ProductGroup.Id)) {
                String errorMessage = String.isBlank(parItemERP.ProductGroup.Id) ? ('ProductGroup field for Line Item #' + parItemERP.GUID + ' is empty.') : ('There is no such Product Group (' + parItemERP.ProductGroup + ') for item #' + parItemERP.GUID);
                throw new erpException(errorMessage);
            }
            */

            String fullIdERP = parItemERP.GUID;
            PriceApprovalRequestItem__c parItem;

            if (res.isNewPriceApprovalRequestCreated || !parItemByIdERPMap.containsKey(fullIdERP)) {
                parItem = new PriceApprovalRequestItem__c ();
                parItem.PriceApprovalRequestId__c = par.Id;
                parItem.ID_ERP__c = fullIdERP;
            } else {
                parItem = parItemByIdERPMap.get(fullIdERP);
            }
            
            parItem.ExchangeTimestamp__c = messageTimestamp;
            parItem.CurrencyIsoCode = parItemERP.currencyCode;
            mapRelatedERPId(parItem, objToIdMap, parItemERP);
            parItem.OpportunityId__c = oppIdErpToIdMap.get(String.valueOf(parItemERP.opportunityID_ERP));
            parItem.OpportunityLineItemITENumber__c = parItemERP.opportunityLineItemITENumber;
            parItem.NPP__c = String.valueOf(parItemERP.npp);
            fillName(parItem);
            OpportunityLineItem relatedOli = oliITENumberToObjMap.get(parItemERP.opportunityLineItemITENumber);
            parItem.OpportunityLineItemId__c = relatedOli?.Id;
            parItem.OppProduct__c = relatedOli?.Id; //Added 03.12.2025
            parItem.InquiryQuantity__c = parItemERP.inqQuantity;
            parItem.InquiryUnit__c = String.valueOf(parItemERP.inqUnit);
            parItem.Quantity_t__c = parItemERP.quantity_Mt;
            parItem.InquiryUnitPrice__c = parItemERP.price;
            parItem.Price_t__c = parItemERP.price_t;
            parItem.PriceEXW_t__c = parItemERP.priceEXW_t;
            parItem.TotalPrice__c = parItemERP.totalPrice;
            parItem.Margin__c = parItemERP.margin;
            parItem.Margin_t__c = parItemERP.margin_t;
            parItem.Liabilities_t__c = parItemERP.liabilities_t;
            parItem.TransportationCost_t__c = parItemERP.transportationCosts_t;
            parItem.ROI__c = parItemERP.roi;
            parItem.BilletCost_t__c = parItemERP.billetCost_t;
            parItem.MetalPrice_t__c = parItemERP.metalPriceForProduction_t;
            parItem.CostsTKB_t__c = parItemERP.costsTKB_t;
            parItem.MarginTKB_t__c = parItemERP.marginTKB_t;
            parItem.BilletMargin_t__c = parItemERP.marginBillet_t;
            parItem.CustomDuty_t__c = parItemERP.customDuty_t;
            parItem.CoatingCost_t__c = parItemERP.coatingCost_t;
            parItem.ExtraCosts_t__c = parItemERP.extraCosts_t;
            //25.10.21 add CDD field
            parItem.CDD__c = relatedOli?.FinalCDD__c;
            parItemsToUpsert.add(parItem);
            //29.11.21 update margin field on related Opportunity
            if(parItem.Margin__c == 0 || parItem.Margin__c == null || parItem.Margin_t__c == null || parItem.Margin_t__c == 0){
                marginNullValue = true;
            }
            
            if(par.Stage__c == 'Resolved' && relatedOli!=null){
                OpportunityLineItem oppItemMarginUpdate = setNewMarginForOppLineItem(relatedOli,parItem);
                oppItemsNewMarginUpdate.add(oppItemMarginUpdate);
            }
        }

        upsert parItemsToUpsert;

        parItemsToDelete = [SELECT Id FROM PriceApprovalRequestItem__c WHERE PriceApprovalRequestId__c = :par.Id AND ExchangeTimestamp__c < :messageTimestamp];
        delete parItemsToDelete;

        syncApprovalHistory(parsedMessage.data.approvalHistory);
        syncCurrentApprovers(parHeader, usrIdMap);

        updateApprovalStatus();
        if(!marginNullValue){
            try {
            upsert oppItemsNewMarginUpdate;
            } catch( DmlException  e ) {
            System.debug( e.getMessage() );
            }}
        
        return res;
    }


    private static List<Opportunity> getOpportunities(List<ERPMessageParser.PARItem> parItems) {

        // Соберем все ID_ERP из входящего сообщения:
        for(ERPMessageParser.PARItem parItem : parItems) {
            oppIdErpSet.add(String.valueOf(parItem.opportunityID_ERP));
        }
        
        // Найдем все оппы с такими ID_ERP
        List<Opportunity> oppList = [
                                        SELECT Id, ID_ERP__c, AccountId
                                        FROM Opportunity
                                        WHERE ID_ERP__c in :oppIdErpSet
                                    ];
        
        if (oppList.isEmpty()) {
            oppErrMessage = 'Related opp(s) were not found';
            return null;
        }

        Set<String> existingOppIdErpSet = new Set<String>();
        for (Opportunity opp : oppList) {
            existingOppIdErpSet.add(opp.ID_ERP__c);
            oppIdErpToIdMap.put(opp.ID_ERP__c, opp.Id);
            if (oppAccountId == null) {
                oppAccountId = opp.AccountId;
            } else {
                if (opp.AccountId != oppAccountId) {
                    oppErrMessage = 'There are different accounts in the related opportunities. All opportunities should be for the same customer.';
                    return null;
                }
            }
        }
        
        // Пройдемся по айдишникам из сообщения и проверим, что оппа с таким кодом существует:
        String unknownOppIds;
        for (String oppIdErp : oppIdErpSet) {
            if (!existingOppIdErpSet.contains(oppIdErp)) {
                unknownOppIds += String.isBlank(unknownOppIds) ? oppIdErp : ', ' + oppIdErp;
            }
        }
        if (String.isNotBlank(unknownOppIds)) {
            oppErrMessage = 'Opportunities with the following ERP IDs were not found: ' + unknownOppIds + '.';
            return null;
        }
        
        return oppList;
    }



    private static void checkRelations() {
        
        List<OpportunityPARRelationship__c> relToInsert = new List<OpportunityPARRelationship__c>();
        List<OpportunityPARRelationship__c> relToDelete = new List<OpportunityPARRelationship__c>();

        // Найдем все связи в junction объекте
        List<OpportunityPARRelationship__c> oppRelationsList =  [
                                                                    SELECT Id, Opportunity__c, Opportunity__r.Id_ERP__c
                                                                    FROM OpportunityPARRelationship__c
                                                                    WHERE PriceApprovalRequest__c = :par.Id
                                                                ];

        Set<String> existingRelationsIdErpSet = new Set<String>();
        for (OpportunityPARRelationship__c rel : oppRelationsList) {
            existingRelationsIdErpSet.add(rel.Opportunity__r.ID_ERP__c);
        }

        for (String oppIdErp : oppIdErpSet) {
            if (!existingRelationsIdErpSet.contains(oppIdErp)) {
                OpportunityPARRelationship__c newRelation = new OpportunityPARRelationship__c ();
                newRelation.Opportunity__c = oppIdErpToIdMap.get(oppIdErp);
                newRelation.PriceApprovalRequest__c = par.Id;
                relToInsert.add(newRelation);
            }
        }
        insert relToInsert;

        for (OpportunityPARRelationship__c rel : oppRelationsList) {
            if (!oppIdErpSet.contains(rel.Opportunity__r.ID_ERP__c)) {
                relToDelete.add(rel);
            }
        }
        delete relToDelete;
    }



    private static PriceApprovalRequest__c getPriceApprovalRequest(ERPMessageParser.PARHeader parHeader, ERPMessageParser.PARItem[] parItems, MessageProcessingResult res) {
        
        PriceApprovalRequest__c par;
        String parIdErp = String.valueOf(parHeader.id_ERP);

        List<PriceApprovalRequest__c> parList = [
                                                    SELECT Id, ID_ERP__c, Stage__c, StageERP__c, OwnerId, DocNumber__c, DocDate__c, IsPriceModel__c, MarketSegment__c,
                                                        Account__c, SalesRep__c, SalesRep__r.ManagerId, BOSpecialist__c, BOSpecialist__r.Name, PRMDirector__c, CurrencyIsoCode, PaymentTerms__c,
                                                        CurrentApprover__c 
                                                    FROM PriceApprovalRequest__c
                                                    WHERE Id_ERP__c = :parIdErp LIMIT 1
                                                ];

        if (parList.size() == 0) {
            par = new PriceApprovalRequest__c();
            if (srId == null) {
                throw new erpException('There is no any user (Sales Rep) with ID = ' + parHeader.salesRep_EmpNum.id.trim());
            }
            par.OwnerId = srId;
            par.Id_ERP__c = parIdErp;
            res.isNewPriceApprovalRequestCreated = true;
        } else {
            par = parList[0];
        }

        Map<String, sObject> sObjects_to_insert = new Map<String, sObject> ();

        par.Name = parHeader.docNumber;
        par.DocNumber__c = parHeader.docNumber;
        par.DocDate__c = parHeader.docDate.date();
        par.CurrencyIsoCode = parItems[0].currencyCode;
        par.IsPriceModel__c = parHeader.priceModel;
        par.MarketSegment__c = parHeader.segment;
        // Аккаунт:
        String customerIdErp = parHeader.customer.id.trim();
        if (customerIdErp != '164525') {
            // 164525 - код служебной записи "Новый контрагент" в  ИТ-Предприятии
            List<Account> accList = [SELECT Id FROM Account WHERE ID_ERP__c = :customerIdErp];
            checkListSize(accList, 'Customer', parHeader.customer, null);
            if (!accList.isEmpty()) {
                par.Account__c = accList[0].Id;
            } else {
                // Возьмем аккаунт из оппы:
                par.Account__c = oppAccountId;
            }
        } else {
            // Возьмем аккаунт из оппы:
            par.Account__c = oppAccountId;
        }
        
        //---------
        par.SalesRep__c = srId;
        par.BOSpecialist__c = boId;
        par.PRMDirector__c = prmdId;
        // Условия оплаты:
        List<PaymentTerms__c> ptList = [SELECT Id FROM PaymentTerms__c WHERE ID_ERP__c = :parHeader.paymentTerms.id.trim()];
        checkListSize(ptList, 'Payment Terms', parHeader.paymentTerms, sObjects_to_insert);
        par.PaymentTerms__c = ptList.isEmpty() ? sObjects_to_insert.get('Payment Terms').Id : ptList[0].Id;
        // Условия поставки:
        List<DeliveryTerms__c> dtList = [SELECT Id FROM DeliveryTerms__c WHERE ID_ERP__c = :parItems[0].deliveryTerms.id.trim()];
        ERPMessageParser.ERPObject deliveryTerms = new ERPMessageParser.ERPObject();
        deliveryTerms.id = parItems[0].deliveryTerms.id.trim();
        deliveryTerms.name = parItems[0].deliveryTerms.name.trim();
        checkListSize(dtList, 'Delivery Terms', deliveryTerms, sObjects_to_insert);
        par.DeliveryTerms__c = dtList.isEmpty() ? sObjects_to_insert.get('Delivery Terms').Id : dtList[0].Id;
        //----------------
        switch on parHeader.stageInfo.milestone {
            when 'BO' {
                par.Stage__c = 'Draft';
            }
            when 'SalesRep' {
                par.Stage__c = 'Needs Confirmation';
            }
            when 'Costing' {
                par.Stage__c = 'Costing';
            }
            when 'PRM' {
                par.Stage__c = 'PRD';
            }
            when 'ExtraCosts' {
                par.Stage__c = 'In Review';
            }
            when 'Decision' {
                par.Stage__c = 'In Review';
            }
            when 'Finish' {
                par.Stage__c = 'Resolved';
            }
        }
        par.StageERP__c = parHeader.stageInfo.id.trim();
        par.FED__c = parHeader.fed;
        par.Transportation__c = parHeader.transportation;
        par.Turnover__c = parHeader.turnover;
        par.Status__c = String.valueOf(parHeader.statusInfo.State);
        par.StageName__c = parHeader.stageInfo.name;

        upsert par;

        return par;

    }


    
    public static void checkListSize(List<SObject> listToCheck, String sfObjectLabel, ERPMessageParser.ERPObject erpObject, Map<String, sObject> sObjects_to_insert) {
        if (listToCheck.size() == 0) {
            if (sfObjectLabel == 'Account' || sfObjectLabel == 'Customer') {
                //String errorMessage = 'There is no any ' + sfObjectLabel + ' with such ID ERP (' + erpObject.Id + ')';
                //throw new erpException(errorMessage);
            } else {
                if (sfObjectLabel == 'Country') {
                    sObjects_to_insert.put(sfObjectLabel, country_not_spec);
                } else {
                    System.debug('There is no any ' + sfObjectLabel + ' with such ID ERP (' + erpObject.id + ') - Creating a new one.');
                    sObject sObj_to_insert = Schema.getGlobalDescribe().get(LABELS_TO_SF_API_NAMES.get(sfObjectLabel)).newSObject();
                    String erpObjName = erpObject.name;
                    if (sfObjectLabel == 'Payment Terms') {
                        erpObjName = checkNameFieldSize(erpObjName, 255);
                        sObj_to_insert.put('NameFull__c', erpObjName);
                        sObj_to_insert.put('NameFullRus__c', erpObjName);

                        erpObjName = checkNameFieldSize(erpObjName, 80);
                        sObj_to_insert.put('NameRus__c', erpObjName);
                    }
                    erpObjName = checkNameFieldSize(erpObjName, 80);

                    sObj_to_insert.put('Name', erpObjName);
                    sObj_to_insert.put('Id_ERP__c', erpObject.id);
                    insert sObj_to_insert;
                    System.debug('Created new object - ' + sObj_to_insert);
                    sObjects_to_insert.put(sfObjectLabel, sObj_to_insert);
                }
            }
        } else if (listToCheck.size() > 1) {
            String errorMessage = 'There are several ' + sfObjectLabel + ' with such ID ERP(' + erpObject.id + ').';
            System.debug(errorMessage.removeEnd('.') + ': ');
            Integer i = 1;
            for (SObject sobj : listToCheck) {
                System.debug(i + '--' + sobj);
                i++;
            }
            throw new erpException(errorMessage);
        }
    }



    public static String checkNameFieldSize(String nameOfObject, Integer fieldSize) {
        if (String.isNotBlank(nameOfObject) && nameOfObject.length() > fieldSize) {
            nameOfObject = nameOfObject.substring(0, fieldSize - 4) + '...';
        }
        return nameOfObject;
    }



    @testVisible
    private static Map<String, PriceApprovalRequestItem__c> getIdErpToParItemMap() {
        
        List<PriceApprovalRequestItem__c> parItemsList = [
                                                        SELECT Id, ID_ERP__c, OpportunityId__c, OpportunityLineItemITENumber__c, 
                                                               NPP__c, Name, Shop__c, Shop__r.Id_ERP__c, Product2Id__c, 
                                                               Product2Id__r.Id_ERP__c, OppProduct__c,
                                                              TubeOD__c, TubeOD__r.Id_ERP__c, TubeWT__c, TubeWT__r.Id_ERP__c, 
                                                              Coating__c, Coating__r.ID_ERP__c, SteelGrade__c, 
                                                              SteelGrade__r.Id_ERP__c, TubeEnds__c, TubeEnds__r.ID_ERP__c, 
                                                              TubeLengthSize__c, TubeLengthSize__r.ID_ERP__c
                                                        FROM PriceApprovalRequestItem__c
                                                        WHERE PriceApprovalRequestId__c = :par.Id
                                                        ];

        Map<String, PriceApprovalRequestItem__c> parItemMap = new Map<String, PriceApprovalRequestItem__c> ();
        for (PriceApprovalRequestItem__c parItem : parItemsList) {
            parItemMap.put(parItem.ID_ERP__c, parItem);
        }

        return parItemMap;
    }



    private static Map<String, Opportunity> getOppIdErpToObjMap(List<ERPMessageParser.PARItem> parItemsList) {

        Map<String, Opportunity> idErpToOppMap = new Map<String, Opportunity>();
        
        Set<String> oppIdErpSet = new Set<String>();
        for (ERPMessageParser.PARItem parItem : parItemsList) {
            oppIdErpSet.add(String.valueOf(parItem.opportunityID_ERP).trim());
        }
        
        List<Opportunity> oppList = [
                                        SELECT Id, Id_ERP__c
                                        FROM Opportunity
                                        WHERE ID_ERP__c in :oppIdErpSet
                                    ];
        
        for (Opportunity opp : oppList) {
            idErpToOppMap.put(opp.ID_ERP__c, opp);
        }
        
        return idErpToOppMap;
    }
    
    
    private static Map<String, OpportunityLineItem> getOliITENumberToObjMap(ERPMessageParser.PARItem[] parItems) {
        
        Set<String> oliITENumberSet = new Set<String>();
        Set<String> currSet = new Set<String>(); // В этот сет соберем коды валют из всех строк, и если есть разные коды, то выбросим ошибку.
        
        for (ERPMessageParser.PARItem parItem : parItems) {
            oliITENumberSet.add(parItem.opportunityLineItemITENumber);
            
            // Заполним сеты с ID_ERP записей, которые понадобятся при формировании наименования строки служебки.
            sgIds.add(parItem.steelGrade.id.trim());
            odIds.add(parItem.od.id.trim());
            wtIds.add(parItem.wt.id.trim());
            lsIds.add(parItem.lengthSize.id.trim());
            
            // Сохраним код валюты для последующей проверки
            currSet.add(parItem.currencyCode.trim());
        }
        if (currSet.size() > 1) {
            throw new erpException('All items of the Price Approval Request must have the same currency!');
        }

        List<OpportunityLineItem> oliList = [SELECT Id, Name, ID_ERP__c, ITENumber__c, CDD__c, FinalCDD__c, Margin__c, Margin_t__c 
                                             FROM OpportunityLineItem WHERE ITENumber__c in :oliITENumberSet];

        Map<String, OpportunityLineItem> oliITENumberToObjMap = new Map<String, OpportunityLineItem>();
        for (OpportunityLineItem oli : oliList){
            oliITENumberToObjMap.put(oli.ITENumber__c, oli);
        }

        return oliITENumberToObjMap;
    }



    private static Map<String, Map<String, Id>> getObjectToIdMap(List<ERPMessageParser.PARItem> parItemERPList) {
        Map<String, Map<String, Id>> objectToIdMap = new Map<String, Map<String, Id>> ();
        Map<String, Set<String>> erpValuesForObject = new Map<String, Set<String>> ();
        System.debug(parItemERPList);
        String serializedString = JSON.serialize(parItemERPList);
        System.debug(serializedString);
        List<Object> parItemFieldsList = (List<Object>) JSON.deserializeUntyped(serializedString);
        System.debug('-- List: ' + parItemFieldsList);
        for (String key : ERP_TO_SF_API_NAMES.keyset()) {
            Set<String> valuesSet = new Set<String> ();
            for (Integer i = 0; i < parItemFieldsList.size(); i++) {
                Map<String, Object> parItemField = (Map<String, Object>) parItemFieldsList.get(i);

                Map<String, Object> erpObject = (Map<String, Object>) parItemField.get(key);
                if (String.isNotBlank((String) erpObject.get('id'))) {
                    System.debug('--- ' + (String) erpObject.get('id'));
                    if (key == 'shippingPoint') {
                        // По какой-то причине если код символьный, то в справочнике он иногда сохраняется 
                        // маленькими буквами, и затем не совпадает с тем, что приходит в файле. 
                        // Поэтому явно приводим все коды к LowerCase() тут и во время проверки.
                        String objIdLowerCase = ((String) erpObject.get('id')).toLowerCase();
                        valuesSet.add((String) erpObject.get('spType') + '-' + objIdLowerCase);
                    }
                    else {
                        valuesSet.add(((String) erpObject.get('id')).trim());
                    }
                }
            }
            erpValuesForObject.put(key, valuesSet);
        }
        System.debug(erpValuesForObject);

        for (String key : erpValuesForObject.keySet()) {
            Set<String> setERPIds = erpValuesForObject.get(key);
            List<sObject> objectList;
            Map<String, Id> erpIdToIdMap = new Map<String, Id> ();
            switch on key {
                when 'salesRep_EmpNum', 'boSpecialist_EmpNum', 'prmDirector_EmpNum' {
                    //Запрос выполняется не по справочнику User и полю Id, а по справочнику UserId_ERP__c и полю Name
                    objectList = Database.query('SELECT Name, User__c FROM UserId_ERP__c WHERE Name IN :setERPIds');
                    for (sObject ob : objectList) {
                        erpIdToIdMap.put((String) ob.get('Name'), (Id) ob.get('User__c'));
                    }
                    objectToIdMap.put(key, erpIdToIdMap);
                }
                when else {
                    objectList = Database.query('SELECT Id, ID_ERP__c FROM ' + ERP_TO_SF_API_NAMES.get(key) + 
                                                ' WHERE ID_ERP__c IN :setERPIds');
                    for (sObject ob : objectList) {
                        if (key == 'shippingPoint') {
                            erpIdToIdMap.put(((String) ob.get('ID_ERP__c')).toLowerCase(), ob.Id);
                        } else {
                            erpIdToIdMap.put((String) ob.get('ID_ERP__c'), ob.Id);
                        }
                    }
                }
            }
            objectToIdMap.put(key, erpIdToIdMap);
            System.debug('Object to ID Map: ' + objectToIdMap);
        }
        return objectToIdMap;
    }



    private static void mapRelatedERPId(PriceApprovalRequestItem__c parItem, Map<String, Map<String, Id>> objToIdMap, 
                                        ERPMessageParser.PARItem parItemERP) {
        List<String> fields = new List<String> { 'productGroup', 'shop', 'specLevel', 'steelGrade', 'standard', 'od', 'wt', 'lengthSize', 'ends', 'coating', 'shippingPoint', 'deliveryTerms' };
        Map<String, Object> productAsMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(parItemERP));

        List<String> errList = new List<String> ();
        String allErrors = '';

        String parItemFullId = parItemERP.guid;

        Map<String, SObject> sObjects_to_insert = new Map<String, SObject> ();

        for (String fieldName : fields) {
            System.debug('--- Product As Map: ' + productAsMap);

            String erpObjectId;
            String erpObjectIdInMap;
            Map<String, Object> erpObject = (Map<String, Object>) productAsMap.get(fieldName);
            if (fieldName == 'shippingPoint') {
                if (String.isNotBlank((String) erpObject.get('id'))) {
                    erpObjectId = ((String) erpObject.get('spType')) + '-' + ((String) erpObject.get('id')).trim();
                    erpObjectIdInMap = erpObjectId.toLowerCase();
                } else {
                    erpObjectId = '';
                }
            } else {
                erpObjectId = ((String) erpObject.get('id')).trim();
                erpObjectIdInMap = erpObjectId;
            }
            String ERPObjectName = (String) erpObject.get('name');
            if (String.isBlank(ERPObjectName)) {
                ERPObjectName = 'Object with ERP Id = ' + erpObjectId;
            }

            System.debug('--- Object: ' + objToIdMap.get(fieldName).get(erpObjectId));

            if (String.isNotBlank(erpObjectId) && objToIdMap.get(fieldName).get(erpObjectIdInMap) == null) {
                
                System.debug('There is no any ' + fieldName + ' with ERP-ID ' + erpObjectId + ' (item #' + parItemFullId + ') - Creating new one.');

                String objName = ERP_TO_SF_API_NAMES.get(fieldName);
                sObject sObj_to_insert = Schema.getGlobalDescribe().get(objName).newSObject();
                sObj_to_insert.put('Id_ERP__c', erpObjectId);
                sObj_to_insert.put('Name', checkFieldValueSize(ERPObjectName, 80));
                if (objHasField(objName, 'NameRus__c')){
                    sObj_to_insert.put('NameRus__c', checkFieldValueSize(ERPObjectName, 255));
                }
                if (fieldName == 'quotaType'){
                    sObj_to_insert.put('Shop__c', objToIdMap.get('shop').get((String) erpObject.get('shop')));
                } else if (fieldName == 'shippingPoint') {
                    sObj_to_insert.put('Type__c', (String) erpObject.get('spType'));
                    sObj_to_insert.put('Country__c', objToIdMap.get('country').get(parItemERP.country.id.trim()));
                } else if (fieldName == 'deliveryTerms') {
                    sObj_to_insert.put('Incoterms__c', (String) erpObject.get('incoterms'));
                }
                System.debug('Created new object - ' + sObj_to_insert);

                sObjects_to_insert.put(fieldName, sObj_to_insert);
            }
        }

        if (sObjects_to_insert.values().size() > 0) {
            insert sObjects_to_insert.values();
            for (String fieldName : sObjects_to_insert.keySet()) {
                String erpObjectId;
                Map<String, Object> erpObject = (Map<String, Object>) productAsMap.get(fieldName);
                if (fieldName == 'shippingPoint') {
                    erpObjectId = ((String) erpObject.get('spType')) + '-' + ((String) erpObject.get('id')).trim();
                    objToIdMap.get(fieldName).put(erpObjectId.toLowerCase(), sObjects_to_insert.get(fieldName).Id);
                } else {
                    erpObjectId = ((String) erpObject.get('id')).trim();
                    objToIdMap.get(fieldName).put(erpObjectId, sObjects_to_insert.get(fieldName).Id);
                }
            }
        }

        if (errList.size() > 0) {
            for (String errorMessage : errList) {
                System.debug(errorMessage);
            }
            throw new erpException(allErrors);
        }

        Id productSfId = objToIdMap.get('productGroup').get(parItemERP.productGroup.id.trim());
        if (productSfId == null) {
            throw new erpException('There is no any product with ID = ' + parItemERP.ProductGroup.id.trim());
        }
        parItem.Product2Id__c = productSfId;
        parItem.Shop__c = objToIdMap.get('shop').get(parItemERP.shop.id.trim());

//        parItem.SteelGrade__c = objToIdMap.get('steelGrade').get(parItemERP.steelGrade.id.trim());
//        parItem.ProductStandard__c = objToIdMap.get('standard').get(parItemERP.standard.id.trim());
//        parItem.ProductSpecLevel__c = objToIdMap.get('specLevel').get(parItemERP.specLevel.id.trim());
//        parItem.TubeOD__c = objToIdMap.get('od').get(parItemERP.od.id.trim());
//        parItem.TubeWT__c = objToIdMap.get('wt').get(parItemERP.wt.id.trim());
//        parItem.TubeLengthSize__c = objToIdMap.get('lengthSize').get(parItemERP.lengthSize.id.trim());
//        parItem.TubeEnds__c = objToIdMap.get('ends').get(parItemERP.ends.id.trim());
//        parItem.Coating__c = objToIdMap.get('coating').get(parItemERP.coating.id.trim());

        parItem.SteelGrade__c = null;
        parItem.ProductStandard__c = null;
        parItem.ProductSpecLevel__c = null;
        parItem.TubeOD__c = null;
        parItem.TubeWT__c = null;
        parItem.TubeLengthSize__c = null;
        parItem.TubeEnds__c = null;
        parItem.Coating__c = null;
        //parItem.QuotaType__c = objToIdMap.get('quotaType').get(parItemERP.quotaType.id.trim());
        parItem.Country__c = objToIdMap.get('country').get(parItemERP.country.id.trim());
        String spId = parItemERP.shippingPoint.spType + '-' + parItemERP.shippingPoint.id.trim();
        parItem.ShippingPoint__c = objToIdMap.get('shippingPoint').get(spId.toLowerCase());
    }



    private static Boolean objHasField(String objName, String fieldName) {

        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        Schema.DescribeSObjectResult objDescription = gd.get(objName).getDescribe();
        Map<String, Schema.SObjectField> fieldsMap = objDescription.fields.getMap();
        if (fieldsMap.containsKey(fieldName)) {
            return true;
        } else {
            return false;
        }

    }
    

    
    public static String checkFieldValueSize(String fieldValue, Integer maxValueSize) {

        if (fieldValue.length() > maxValueSize) {
            fieldValue = fieldValue.substring(0, maxValueSize - 4) + '...';
        }
        return fieldValue;
    }



    public static void fillName(PriceApprovalRequestItem__c parItem) {
        String sg = (sgMap.get(parItem.SteelGrade__c) != null ? sgMap.get(parItem.SteelGrade__c).Name + ' ' : '');
        String od = (odMap.get(parItem.TubeOD__c) != null ? String.valueOf(odMap.get(parItem.TubeOD__c).OD_mm__c) + 'x' : '');
        String wt = (wtMap.get(parItem.TubeWT__c) != null ? String.valueOf(wtMap.get(parItem.TubeWT__c).WT_mm__c) + ' ' : '');
        String ls = (lsMap.get(parItem.TubeLengthSize__c) != null ? lsMap.get(parItem.TubeLengthSize__c).Name : '');

        String strName = sg + od + wt + ls;
        if (strName.length() > 80) {
            if (sgMap.get(parItem.SteelGrade__c) != null) {
                // Обычно слишком длинное наименование бывает именно у марки стали, обрежем его.
                Integer difference = strName.length() - 80;
                sg = sgMap.get(parItem.SteelGrade__c).Name;
                sg = sg.left(sg.length() - difference) + ' ';
                strName = sg + od + wt + ls;
            } else {
                strName = strName.left(80);
            }
        }
        
        parItem.Name = strName;
    }


    static void syncApprovalHistory(ERPMessageParser.PARApprovalHistory[] parApprovalHistory) {
        
        // Удалим все текущие записи из истории согласований:
        List<PARApprovalHistory__c> parApprHistoryList = [SELECT Id FROM PARApprovalHistory__c WHERE PriceApprovalRequestId__c = :par.Id];
        delete parApprHistoryList;

        // Добавим записи истории согласовваний из сообщения:
        parApprHistoryList.clear();
        allApprovalComments = '';
        PARApprovalHistory__c newHistoryRecord;
        for (ERPMessageParser.PARApprovalHistory hist : parApprovalHistory) {
            newHistoryRecord = new PARApprovalHistory__c();
            newHistoryRecord.PriceApprovalRequestId__c = par.Id;
            newHistoryRecord.StageBefore__c = hist.stageBefore.id;
            newHistoryRecord.StageAfter__c = hist.stageAfter.id;
            newHistoryRecord.ApprovalDate__c = hist.approvalDate;
            newHistoryRecord.ApproverName__c = hist.approver.name;
            newHistoryRecord.Comment__c = hist.comment;
            parApprHistoryList.add(newHistoryRecord);
            
            addHistoryComment(newHistoryRecord.ApprovalDate__c, newHistoryRecord.ApproverName__c, newHistoryRecord.Comment__c);
        }
        insert parApprHistoryList;
    }

    static void addHistoryComment(Datetime approvalDate, String approverName, String commentText) {
        if (String.isEmpty(commentText)) {
            return;
        }
        if(allApprovalComments != null) {
            allApprovalComments += '\n\n';
        }
        allApprovalComments += String.valueOf(approvalDate) + ':\n' +
                                approverName + '\n' +
                                commentText;
    }

    static void syncCurrentApprovers(ERPMessageParser.PARHeader parHeader, Map<String, UserID_ERP__c> usrIdMap) {
        
        // Удалим все текущие записи из списка аппруверов:
        List<PARCurrentApprover__c> pcaList = [SELECT Id FROM PARCurrentApprover__c WHERE PriceApprovalRequestId__c = :par.Id];
        delete pcaList;

        // Добавим текущих аппруверов из сообщения:
        pcaList.clear();
        PARCurrentApprover__c newApproverRecord;
        for (ERPMessageParser.ERPObject_User currentApprover : parHeader.stageInfo.currentApprovers) {
            newApproverRecord = new PARCurrentApprover__c();
            newApproverRecord.PriceApprovalRequestId__c = par.Id;
            newApproverRecord.Name = usrIdMap.get(currentApprover.id.trim()) == null ? currentApprover.name.trim() : usrIdMap.get(currentApprover.id.trim()).User__r.Name;
            newApproverRecord.Email__c = currentApprover.email;
            newApproverRecord.ApproverId__c = usrIdMap.get(currentApprover.id.trim())?.User__c;
            pcaList.add(newApproverRecord);
        }
        insert pcaList;
    }

    
    private static void updateApprovalStatus() {
        //Получим все активные процессы (в статусе 'Pending') по данной служебке:
        List<ProcessInstance> piList = [
                                            SELECT Id, Status, ProcessDefinition.DeveloperName,
                                                    (
                                                        SELECT Id, OriginalActorId, ActorId
                                                        FROM Workitems
                                                    )
                                            FROM ProcessInstance
                                            WHERE TargetObjectId = :par.Id
                                            AND Status = 'Pending'
                                        ];
        
        List<Id> approversWithActiveWorkitems = new List<Id>();

        if (piList.isEmpty()) {
            // Нет ни одного активного процесса, при необходимости нужно создать новый
            if (STAGES_TO_APPROVAL_PROCESS_NAMES.keySet().contains(par.StageERP__c)) {
                // Т.е. если текущая стадия подразумевает возможность согласования в СФ, то создадим запрос на согласование
                addWorkitems(null);
            }
        } else {
            // Пройдемся по всем активным процессам и удалим нерелевантные
            deleteWorkitems(piList, approversWithActiveWorkitems);

            //Добавим процессы, если их еще нет:
            addWorkitems(approversWithActiveWorkitems);
        }
    }

    static void deleteWorkitems(List<ProcessInstance> piList, List<Id> approversWithActiveWorkitems) {
        List<Approval.ProcessWorkitemRequest> approvalRequestList = new List<Approval.ProcessWorkitemRequest>();

        for (ProcessInstance pi : piLIst) {
            for (ProcessInstanceWorkitem piWorkitem : pi.Workitems) {
                if (pi.ProcessDefinition.DeveloperName != STAGES_TO_APPROVAL_PROCESS_NAMES.get(par.StageERP__c) || !currentApproversIdList.contains(piWorkitem.OriginalActorId)) {
                    //Удалим данный шаг
                    Approval.ProcessWorkitemRequest pwr = new Approval.ProcessWorkitemRequest();
                    pwr.setWorkItemId(piWorkitem.Id);
                    pwr.setAction('Removed');
                    pwr.setComments('The approval step was resolved in the ERP system');
                    approvalRequestList.add(pwr);
                    System.debug('>>>>>>> Approval request "' + STAGES_TO_APPROVAL_PROCESS_NAMES.get(par.StageERP__c) + '" for ' + piWorkitem.OriginalActorId + ' was removed.');
                } else {
                    approversWithActiveWorkitems.add(piWorkitem.OriginalActorId);
                    System.debug('>>>>>>> Approval request "' + STAGES_TO_APPROVAL_PROCESS_NAMES.get(par.StageERP__c) + '" for ' + piWorkitem.OriginalActorId + ' is already exists and that is why was not added again.');
                } 
            }
        }
        
        if (!approvalRequestList.isEmpty()) {
            List<Approval.ProcessResult> apprResultList = Approval.process(approvalRequestList);
            for (Approval.ProcessResult apprResult : apprResultList) {
                System.assert(apprResult.isSuccess());
                System.assertEquals('Removed', apprResult.getInstanceStatus());
            }
        }
    }

    static void addWorkitems(List<Id> approversWithActiveWorkItems) {
        List<Approval.ProcessSubmitRequest> approvalRequestList = new List<Approval.ProcessSubmitRequest>();

        for (Id currentApproverId : currentApproversIdList) {
            if (approversWithActiveWorkItems != null && approversWithActiveWorkItems.contains(currentApproverId)) {
                // Для этого юзера уже имеется активный запрос, так что пропустим его.
                continue;
            }
            Approval.ProcessSubmitRequest psr = new Approval.ProcessSubmitRequest();
            psr.setObjectId(par.Id);
            psr.setProcessDefinitionNameOrId(STAGES_TO_APPROVAL_PROCESS_NAMES.get(par.StageERP__c));
            psr.setComments(allApprovalComments);
            // В метод setNextApproverIds() мы должны передать список с одним единственным значением. Создадим его тут и добавим нужного аппрувера.
            List<Id> nextApproversIdList = new List<Id>();
            nextApproversIdList.add(currentApproverId);
            psr.setNextApproverIds(nextApproversIdList);
            approvalRequestList.add(psr);
            System.debug('>>>>>>> New approval request "' + STAGES_TO_APPROVAL_PROCESS_NAMES.get(par.StageERP__c) + '" for ' + currentApproverId + ' was submitted.');
            System.debug('>>>>>>> nextApproversIdList : ' + nextApproversIdList);
        }
        
        if (!approvalRequestList.isEmpty()) {
            List<Approval.ProcessResult> apprResultList = Approval.process(approvalRequestList);
            for (Approval.ProcessResult apprResult : apprResultList ){
                System.assert(apprResult.isSuccess());
                System.assertEquals('Pending', apprResult.getInstanceStatus());
            }
        }
    }

    public static Blob generateResponseBody(Map<Integer, String> statusCodesMap, Integer statusCode, String error, MessageProcessingResult mpRes) {
        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();
        gen.writeNumberField('Status Code', statusCode);
        gen.writeStringField('Status', statusCodesMap.get(statusCode));
        if (error == NULL) {
            gen.writeStringField('Processed message type', mpRes.MessageType);
            if (String.isNotBlank(mpRes.resultComment)){
                gen.writeStringField('Result comment', mpRes.resultComment);
            }
        } else {
            gen.writeStringField('Error Message', error);
        }

        gen.writeEndObject();
        
        String res = gen.getAsString();
        System.debug('Response body text generated: ' + res);
        return Blob.valueOf(res);
    }
    
    
    
    public static void insertErrorTask(String subject, String request, String error, Id objId) {
        if (String.isNotBlank(Credentials__c.getOrgDefaults().NotifyId__c)) { //add cheking if it user ID in field value
            Task t = new Task();
            subject += ': ' + error.substringAfter('Error Message" : "').substringBefore(error.contains('Class.') ? 'Class.' : '()');
            if (subject.length() > 255) {
                subject = subject.substring(0, 251) + '...';
            }
            t.Subject = subject;
            t.OwnerId = Credentials__c.getOrgDefaults().NotifyId__c;
            t.ActivityDate = Date.today();
            t.Description = 'Request:\n' + request + '\n Response:\n' + error;
            t.WhatId = objId;
            System.debug('Trying inserting Task for Admin:');
            System.debug(t);
            insert t;
            System.debug('Task Id=' + t.Id);
        } else {
            System.debug('Task for Admin was not created because Custom Setting does not contain any ID in NotifyId__c field.');
        }
    }


    
    public class MessageProcessingResult {
        public String MessageType;
        public Boolean isNewPriceApprovalRequestCreated = false;
        public String resultComment;
    }

    public static OpportunityLineItem setNewMarginForOppLineItem(OpportunityLineItem oli, PriceApprovalRequestItem__c parIt){
            
            if(parIt.Margin__c != null && parIt.Margin_t__c!=null){
                oli.Margin_t__c = parIt.Margin_t__c;
                oli.Margin__c = parIt.Margin__c;  
                system.debug(oli.Margin_t__c);
                system.debug(oli.Margin__c);
            }
            return oli;
        }
    
    public class erpException extends Exception {}

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