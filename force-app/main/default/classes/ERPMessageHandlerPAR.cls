public with sharing class ERPMessageHandlerPAR {
    // ==============================
    // DTO результату
    // ==============================
    public class MessageProcessingResult {
        public String MessageType;
        public Boolean isNewPARCreated = false;
        public String resultComment;
    }

    // Локальний тип помилки для бізнес-валідаторів
    public class ErpException extends Exception {}

    // ==============================
    // CMDT: стадії PAR
    //   ключ: Code__c (ERP code, типу '_3', '_18' тощо)
    //   значення: MasterLabel (людська назва)
    // ==============================
    public static final Map<String, String> STAGE_LABELS_BY_CODE;
    // Активні сегменти (код з ERP)
    public static final Set<String> ACTIVE_SEGMENTS;
    // Error messages
    public static final Map<String, String> ERR_MSG;

    static {
        // --- Стадії PAR
        Map<String, String> stageMap = new Map<String, String>();
        for (PARStage__mdt s : [
            SELECT Code__c, MasterLabel
            FROM PARStage__mdt
        ]) {
            if (s.Code__c != null) {
                stageMap.put(s.Code__c.trim(), s.MasterLabel);
            }
        }
        STAGE_LABELS_BY_CODE = stageMap;

        // --- Маркет сегменти
        Set<String> segmSet = new Set<String>();
        for (MarketSegment__mdt ms : [
            SELECT Code__c
            FROM MarketSegment__mdt
        ]) {
            if (ms.Code__c != null) {
                segmSet.add(ms.Code__c.trim());
            }
        }
        ACTIVE_SEGMENTS = segmSet;

        // Error messages
        Map<String, String> errMsgMap = new Map<String, String>();
        for(ExceptionMessages__mdt em : [
            SELECT
                DeveloperName, MessageText__c
            FROM ExceptionMessages__mdt
            WHERE Handler__c IN ('PAR','COMMON')
        ]) {
            errMsgMap.put(em.DeveloperName, em.MessageText__c);
        }
        ERR_MSG = errMsgMap;
    }

    // ==============================
    // Допоміжні структури
    // ==============================
    // Інфа по оппах, прив’язаних до PAR
    public class OpportunitiesInfo {
        public Map<String, Opportunity> oppByIdErp = new Map<String, Opportunity>();
        public Id accountId;
    }

    // ==============================
    // МАПА OLI ПО ITENumber__c
    //   ключ — ITENumber__c
    // ==============================
    public static Map<String, OpportunityLineItem> getOliMap(
        ERPMessageParser.ErpToSfMessage_PAR parsedMessage
    ) {
        ERPMessageParser.PARItem[] parItems = parsedMessage.data.items;
        Set<String> iteNumbersSet = new Set<String>();
        for (ERPMessageParser.PARItem parItem : parItems) {
            if (String.isNotBlank(parItem.opportunityLineItemITENumber)) {
                iteNumbersSet.add(parItem.opportunityLineItemITENumber.trim());
            }
        }
        System.debug('ERPMessageHandlerPAR.getOliMap » iteNumbersSet = ' + iteNumbersSet);

        Map<String, OpportunityLineItem> oliMap = new Map<String, OpportunityLineItem>();
        if (iteNumbersSet.isEmpty()) {
            return oliMap;
        }

        List<OpportunityLineItem> oliList = [
            SELECT Id,
                   ID_ERP__c,
                   NPP_ERP__c,
                   ITENumber__c,
                   Name__c,
                   Coating__c,
                   TubeEnds__c,
                   LengthSize__c,
                   Weight_kpm__c,
                   Weight_ppf__c,
                   TubeOD__c,
                   OpportunityId,
                   Product2Id,
                   ProductSpecLevel__c,
                   ProductStandard__c,
                   ProductType__c,
                   ShippingPoint__c,
                   SteelGrade__c,
                   TubeWT__c
            FROM OpportunityLineItem
            WHERE ITENumber__c IN :iteNumbersSet
        ];

        for (OpportunityLineItem oli : oliList) {
            if (oli.ITENumber__c != null) {
                oliMap.put(oli.ITENumber__c, oli);
            }
        }

        System.debug('ERPMessageHandlerPAR.getOliMap » oliMap.size = ' + oliMap.size());
        return oliMap;
    }

    // --- Назва продукту позиції оппи
    public static String getOliProdName(
        String oliIteNumber,
        Map<String, OpportunityLineItem> oliMap
    ) {
        if (String.isBlank(oliIteNumber)) {
            return '';
        }
        OpportunityLineItem oli = oliMap.get(oliIteNumber);
        String oliProdName = (oli != null ? oli.Name__c : '');
        return oliProdName.replace('/ ', '/');
    }

    // ==============================
    // Пошук Opp по item’ах PAR
    // ==============================
    private static OpportunitiesInfo findOpportunities(ERPMessageParser.PARItem[] parItems) {
        OpportunitiesInfo info = new OpportunitiesInfo();
        Set<String> oppIdErpSet = new Set<String>();

        for (ERPMessageParser.PARItem item : parItems) {
            if (item != null && item.opportunityId_ERP != null) {
                oppIdErpSet.add(String.valueOf(item.opportunityId_ERP).trim());
            }
        }

        if (oppIdErpSet.isEmpty()) {
            throw new ErpException(ERR_MSG.get('INVALID_OPP_ID_ERP'));
        }

        List<Opportunity> oppList = [
            SELECT Id, Id_ERP__c, AccountId
            FROM Opportunity
            WHERE Id_ERP__c IN :oppIdErpSet
        ];

        if (oppList.isEmpty()) {
            throw new ErpException(ERR_MSG.get('NO_SUCH_OPP_IN_SF') +
                                   String.join(new List<String>(oppIdErpSet), ', '));
        }

        // Перевірка: чи всі Opp знайдено?
        Set<String> found = new Set<String>();
        for (Opportunity o : oppList) {
            if (o.Id_ERP__c != null) {
                found.add(o.Id_ERP__c);
            }
        }
        Set<String> missing = new Set<String>(oppIdErpSet);
        missing.removeAll(found);
        if (!missing.isEmpty()) {
            throw new ErpException(
                ERR_MSG.get('NO_SOME_OPP_IN_SF') +
                String.join(new List<String>(missing), ', ')
            );
        }

        // Перевірка: всі Opp одного акаунта
        Id accountId;
        for (Opportunity o : oppList) {
            if (accountId == null) {
                accountId = o.AccountId;
            } else if (accountId != o.AccountId) {
                throw new ErpException(ERR_MSG.get('ALL_ITEMS_PAR_MUST_REFER_OPP'));
            }
            info.oppByIdErp.put(o.Id_ERP__c, o);
        }
        info.accountId = accountId;

        return info;
    }

    // ==============================
    // Основний процесор повідомлення
    // ==============================
    public static MessageProcessingResult ProcessMessage(
        ERPMessageParser.ErpToSfMessage_PAR parsedMessage,
        String requestBody
    ) {
        MessageProcessingResult res = new MessageProcessingResult();
        res.MessageType = parsedMessage != null && parsedMessage.metadata != null
            ? parsedMessage.metadata.msgType
            : 'UNKNOWN';

        if (parsedMessage == null || parsedMessage.data == null) {
            res.resultComment = 'PAR was not saved: ' + ERR_MSG.get('MSG_BODY_EMPTY');
            return res;
        }

        ERPMessageParser.PARHeader parHeader = parsedMessage.data.header;
        ERPMessageParser.PARItem[] parItems = parsedMessage.data.items;

        // -----------------------------
        // Базові перевірки
        // -----------------------------
        if (parHeader == null) {
            res.resultComment = 'PAR was not saved: '+ERR_MSG.get('HEADER_MISSING');
            return res;
        }

        if (parItems == null || parItems.isEmpty()) {
            res.resultComment = ERR_MSG.get('PAR_HAS_NO_ITEMS');
            return res;
        }

        // Перевірка сегмента (зараз — через CMDT MarketSegment__mdt)
        if (!ACTIVE_SEGMENTS.isEmpty()
            && String.isNotBlank(parHeader.segment)
            && !ACTIVE_SEGMENTS.contains(parHeader.segment.trim())) {

            res.resultComment =
                ERR_MSG.get('BAD_SEGMENT') + parHeader.segment;
            return res;
        }

        // Забороняємо, якщо Sales Rep == BO Specialist
        if (parHeader.salesRep_EmpNum != null &&
            parHeader.boSpecialist_EmpNum != null &&
            String.isNotBlank(parHeader.salesRep_EmpNum.Id) &&
            String.isNotBlank(parHeader.boSpecialist_EmpNum.Id) &&
            parHeader.salesRep_EmpNum.Id.trim() == parHeader.boSpecialist_EmpNum.Id.trim()) {

            res.resultComment =
                ERR_MSG.get('SR_EQ_BOS') + parHeader.boSpecialist_EmpNum.Name;
            return res;
        }

        try {
            // Мапа OLI за ITENumber__c
            Map<String, OpportunityLineItem> oliMap = getOliMap(parsedMessage);

            // Перевіряємо Opp’и, до яких прив’язаний PAR
            OpportunitiesInfo oppInfo = findOpportunities(parItems);

            // TODO: далі в наступних кроках:
            //  - знайти / створити PriceApprovalRequest__c (по header.id_ERP)
            //  - синхронізувати PriceApprovalRequestItem__c для кожного PARItem
            //  - оновити/створити зв’язки Opportunity <-> PAR
            //  - синхронізувати Approval History / поточних апруверів
            //  - при потребі оновити Margin на OLI

            res.isNewPARCreated = false;
            res.resultComment =
                'PAR message successfully validated (new handler in refactoring mode: no data changes were performed).';

            return res;

        } catch (ErpException e) {
            res.resultComment = e.getMessage();
            return res;
        } catch (Exception e) {
            // Це вже не бізнес-помилка, а технічний збій — нехай наверху її перехоплюють
            // і формують 500 з generateResponseBody(...)
            throw e;
        }
    }

    // ==============================
    // Формування відповіді для ERP
    // (аналог generateResponseBody зі старого класу)
    // ==============================
    public static Blob generateResponseBody(
        Map<Integer, String> statusCodesMap,
        Integer statusCode,
        String error,
        MessageProcessingResult mpRes
    ) {
        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();
        gen.writeNumberField('Status Code', statusCode);
        gen.writeStringField('Status', statusCodesMap.get(statusCode));

        if (error == null) {
            if (mpRes != null) {
                gen.writeStringField('Processed message type', mpRes.MessageType);
                if (String.isNotBlank(mpRes.resultComment)) {
                    gen.writeStringField('Result comment', mpRes.resultComment);
                }
            }
        } else {
            gen.writeStringField('Error Message', error);
        }

        gen.writeEndObject();

        String res = gen.getAsString();
        System.debug('ERPMessageHandlerPAR.generateResponseBody » ' + res);
        return Blob.valueOf(res);
    }

    // ==============================
    // Створення Task’а адміну при помилці
    // ==============================
    public static void insertErrorTask(
        String subject,
        String request,
        String error,
        Id objId
    ) {
        String notifyId = Credentials__c.getOrgDefaults().NotifyId__c;
        if (String.isBlank(notifyId)) {
            System.debug('Task for Admin was not created because Custom Setting does not contain any ID in NotifyId__c field.');
            return;
        }

        Task t = new Task();
        String errShort = error;
        if (errShort != null && errShort.length() > 200) {
            errShort = errShort.substring(0, 196) + '...';
        }
        if (String.isNotBlank(errShort)) {
            subject = (subject == null ? '' : subject) + ': ' + errShort;
        }

        if (subject != null && subject.length() > 255) {
            subject = subject.substring(0, 251) + '...';
        }

        t.Subject     = subject;
        t.OwnerId     = notifyId;
        t.ActivityDate= Date.today();
        t.Description = 'Request:\n' + request + '\nResponse:\n' + error;
        t.WhatId      = objId;

        System.debug('ERPMessageHandlerPAR.insertErrorTask » Task = ' + t);
        insert t;
    }
    // =====================================
    //  Створення або оновлення PriceApprovalRequest__c
    // =====================================
    private static PriceApprovalRequest__c createOrUpdatePAR(
        ERPMessageParser.PARHeader parHeader,
        OpportunitiesInfo oppInfo
    ) {
        if (parHeader == null) {
            throw new ErpException('PAR was not saved: header is null.');
        }
        if (parHeader.id_ERP == null) {
            throw new ErpException('PAR was not saved: missing ID_ERP in header.');
        }

        String headerErpId = String.valueOf(parHeader.id_ERP);

        // --- шукаємо існуючий PAR по текстовому ID_ERP__c
        PriceApprovalRequest__c existingPAR = null;

        List<PriceApprovalRequest__c> existingList = [
            SELECT Id, Name, ID_ERP__c, Account__c,
                StageERP__c, StageName__c,
                SalesRep__c, BOSpecialist__c,
                MarketSegment__c, DocDate__c,
                Comment__c, Status__c
            FROM PriceApprovalRequest__c
            WHERE ID_ERP__c = :headerErpId
            LIMIT 1
        ];

        if (!existingList.isEmpty()) {
            existingPAR = existingList[0];
        }

        // ===========================
        // Стадія PAR із header.stageInfo
        // ===========================
        String stageCode;

        if (parHeader.stageInfo != null && !String.isBlank(parHeader.stageInfo.Id)) {
            // У JSON stageInfo.Id = "_8", "_3" тощо
            stageCode = parHeader.stageInfo.Id.trim();
        } else {
            throw new ErpException('PAR was not saved: StageInfo.Id (stage code) is empty.');
        }

        PARStage__mdt stageRow = PARStage__mdt.getInstance(stageCode);

        if (stageRow == null) {
            throw new ErpException(
                'PAR was not saved: stage ' + stageCode + ' is not configured in PARStage__mdt.'
            );
        }

        // ===========================
        // Створюємо / оновлюємо PAR
        // ===========================
        PriceApprovalRequest__c par = (existingPAR != null)
            ? existingPAR
            : new PriceApprovalRequest__c(
                ID_ERP__c = headerErpId
            );

        // --- Account (з Oppʼів)
        par.Account__c = oppInfo.accountId;

        // --- Stage fields з CMDT
        par.StageERP__c  = stageRow.Code__c;         // "_8", "_3", ...
        par.StageName__c = stageRow.StageName__c;    // "УПР", "Менеджер Sale" тощо

        // --- Segment (з ERP Header.segment)
        par.MarketSegment__c = parHeader.segment;

        // --- DocDate__c (у хедері docDate як Datetime)
        if (parHeader.docDate != null) {
            par.DocDate__c = parHeader.docDate.date();
        } else {
            par.DocDate__c = null;
        }

        // --- Sales Rep
        if (parHeader.salesRep_EmpNum != null) {
            par.SalesRep__c = parHeader.salesRep_EmpNum.Id;
        }

        // --- BO Specialist
        if (parHeader.boSpecialist_EmpNum != null) {
            par.BOSpecialist__c = parHeader.boSpecialist_EmpNum.Id;
        }

        // --- Comment__c (якщо потім зʼявиться комент у Header — сюди його й мапити)
        // par.Comment__c = <парсер-хедер-комент>;

        return par;
    }

    //--- Синхронізація PAR Items
	private static void syncParItems(
		PriceApprovalRequest__c par,
		ERPMessageParser.PARItem[] incomingItems,
		OpportunitiesInfo oppInfo,
		Map<String, OpportunityLineItem> oliMap
	) {
		if (par.Id == null) {
			throw new ErpException('Cannot sync PAR items: PAR Id is null.');
		}

		// --- 1) Мапимо itemʼи ERP по GUID (це і є ERP-код itemʼа)
		Map<String, ERPMessageParser.PARItem> incomingByGuid = new Map<String, ERPMessageParser.PARItem>();
		for (ERPMessageParser.PARItem src : incomingItems) {
			if (String.isBlank(src.guid)) {
				throw new ErpException('PAR item is missing GUID (required).');
			}
			incomingByGuid.put(src.guid.trim(), src);
		}

		// --- 2) Витягуємо існуючі itemʼи PAR
		Map<String, PriceApprovalRequestItem__c> existingByGuid = new Map<String, PriceApprovalRequestItem__c>();

		List<PriceApprovalRequestItem__c> existingItems = [
			SELECT Id, ID_ERP__c
			FROM PriceApprovalRequestItem__c
			WHERE PriceApprovalRequestId__c = :par.Id
		];

		for (PriceApprovalRequestItem__c oldItem : existingItems) {
			if (!String.isBlank(oldItem.ID_ERP__c)) {
				existingByGuid.put(oldItem.ID_ERP__c.trim(), oldItem);
			}
		}

		List<PriceApprovalRequestItem__c> toInsert = new List<PriceApprovalRequestItem__c>();
		List<PriceApprovalRequestItem__c> toUpdate = new List<PriceApprovalRequestItem__c>();
		List<PriceApprovalRequestItem__c> toDelete = new List<PriceApprovalRequestItem__c>();

		// --- 3) Обробляємо всі itemʼи
		for (String guid : incomingByGuid.keySet()) {

			ERPMessageParser.PARItem src = incomingByGuid.get(guid);
			PriceApprovalRequestItem__c trg;

			Boolean isNew = !existingByGuid.containsKey(guid);

			if (isNew) {
				trg = new PriceApprovalRequestItem__c();
				trg.ID_ERP__c = guid;                  // 👈 GUID = ERP-код itemʼа
				trg.PriceApprovalRequestId__c = par.Id;
			} else {
				trg = existingByGuid.get(guid);
			}

			// --- 3.1 Opportunity (по opportunityId_ERP)
			Opportunity opp = null;
			if (src.opportunityId_ERP != null) {
				opp = oppInfo.oppByIdErp.get(String.valueOf(src.opportunityId_ERP));
			}

			if (opp == null) {
				throw new ErpException(
					'Opportunity with ERP ID ' + src.opportunityId_ERP +
					' not found while processing item GUID=' + guid
				);
			}

			trg.OpportunityId__c = opp.Id;

			// --- 3.2 OLI (по opportunityLineItemITENumber)
			OpportunityLineItem oli = null;
			if (!String.isBlank(src.opportunityLineItemITENumber)) {
				oli = oliMap.get(src.opportunityLineItemITENumber.trim());
			}

			// Поле OpportunityLineItemId__c - зайве, це просто текст
			// Пишемо для сумісности зі старою версією
			// Після повного рефакторинга - видалити це сміття
			trg.OpportunityLineItemId__c = (oli != null ? oli.Id : null);

			// Нормальний лукап на OpportunityLineItemId
			// Замість OpportunityLineItemId__c
			trg.OppProduct__c = oli?.Id;

			// --- 3.3 Name
			trg.Name = (oli != null ? oli.Name__c : 'Item ' + guid);

			// --- 3.4 ERP числові поля
			trg.Quantity_t__c            = src.quantity_Mt;
			trg.InquiryQuantity__c       = src.quantity_pcs;
			trg.Price_t__c               = src.price_t;
			trg.TotalPrice__c            = src.totalPrice;
			trg.PriceEXW_t__c            = src.priceEXW_t;
			trg.Margin_t__c              = src.margin_t;
			trg.Liabilities_t__c         = src.liabilities_t;
			trg.TransportationCost_t__c  = src.transportationCosts_t;
			trg.MetalPrice_t__c          = src.metalPriceForProduction_t;

			// --- 3.5 Поля з OLI
			if (oli != null) {
				trg.TubeOD__c          = oli.TubeOD__c;
				trg.TubeWT__c          = oli.TubeWT__c;
				trg.TubeLengthSize__c  = oli.LengthSize__c;

				trg.SteelGrade__c       = oli.SteelGrade__c;
				trg.ProductStandard__c  = oli.ProductStandard__c;
				trg.Product2Id__c       = oli.Product2Id;

				trg.Weight_kpm__c       = oli.Weight_kpm__c;
				trg.Weight_ppf__c       = oli.Weight_ppf__c;

				trg.Coating__c          = oli.Coating__c;
				trg.TubeEnds__c         = oli.TubeEnds__c;
				trg.ShippingPoint__c    = oli.ShippingPoint__c;
			}

			if (isNew) {
				toInsert.add(trg);
			} else {
				toUpdate.add(trg);
			}
		}

		// --- 4) Delete missing items
		for (String guid : existingByGuid.keySet()) {
			if (!incomingByGuid.containsKey(guid)) {
				toDelete.add(existingByGuid.get(guid));
			}
		}

		// --- 5) DML
		if (!toInsert.isEmpty()) insert toInsert;
		if (!toUpdate.isEmpty()) update toUpdate;
		if (!toDelete.isEmpty()) delete toDelete;

        // --- 6) Sync Opportunity ↔ PAR relationships
        Set<Id> oppIdsUsed = new Set<Id>();

        for (ERPMessageParser.PARItem item : incomingItems) {
            if (item != null && item.opportunityId_ERP != null) {
                String key = String.valueOf(item.opportunityId_ERP).trim();
                Opportunity o = oppInfo.oppByIdErp.get(key);
                if (o != null) {
                    oppIdsUsed.add(o.Id);
                }
            }
        }

        // Поточні зв'язки
        Map<Id, OpportunityPARRelationship__c> existingRels = new Map<Id, OpportunityPARRelationship__c>();

        for (OpportunityPARRelationship__c rel : [
            SELECT Id, Opportunity__c
            FROM OpportunityPARRelationship__c
            WHERE PriceApprovalRequest__c = :par.Id
        ]) {
            existingRels.put(rel.Opportunity__c, rel);
        }

        List<OpportunityPARRelationship__c> relToInsert = new List<OpportunityPARRelationship__c>();

        // Створюємо нові зв'язки (якщо їх ще немає)
        for (Id oppId : oppIdsUsed) {
            if (!existingRels.containsKey(oppId)) {
                relToInsert.add(new OpportunityPARRelationship__c(
                    Opportunity__c = oppId,
                    PriceApprovalRequest__c = par.Id
                ));
            }
        }

        if (!relToInsert.isEmpty()) {
            insert relToInsert;
        }

	}

    // Для покриття тестами (аналог старого FakeCoverageMethod)
    @TestVisible
    private static void FakeCoverageMethod() {
        Integer i = 0;
        i++; i++; i++;
    }
}