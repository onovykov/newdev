public with sharing class LeadConvertion {
    // --- TEST HOOKS ---
    @TestVisible static Boolean bypassSegmentCheck  = false;
    @TestVisible static Boolean bypassLicenseCheck  = false;
    @TestVisible static List<StringUtilsEx.MatchResult> testDuplicates = null;
    // -------------------

    // Прогрів рт лише потрібних sObject
    static {
        RecordTypeCache.primeFor(new Set<String>{ 'Opportunity', 'Contact', 'Account', 'LeadDuplicateAcc__c' }, false);
    }
    private static Id rtIdOpp  = RecordTypeCache.getId(Opportunity.SObjectType, 'New_Client_Enquiry');
    private static Id rtIdCont = RecordTypeCache.getId(Contact.SObjectType,     'Lead_Contact');
    private static Id rtIdAcc  = RecordTypeCache.getId(Account.SObjectType,     'Customer');

    // ---------- DTO ----------
    public class DataDTO {
        public String  OrderType;
        public String  OrderCurrency;
        public Header  Header;
    }
    public class Header {
        public Integer Undoc;
        public String  IteNumber;
        public String  AltNumber;
        public String  PONumber;
        public String  ID_SF;
        public Datetime CreatedDate;
        public Datetime OrderDate;
        public Acc     Account;

        public String  BusinessSegmentId;
        public Integer RegionId;
        public Integer CountryId;

        public PaymentTerms  PaymentTerms;
        public DeliveryTerms DeliveryTerms;
        public Person        SalesRep;
        public Person        BoSpecialist;

        public String  CrossMarket_BusinessSegment;
        public Person  CrossMarket_SalesRep;
        public Decimal CrossMarket_Percent;
    }
    public class Acc { public String Name; public Integer CountryId; public String Address; public String Id; }
    public class PaymentTerms { public String Name; public String Id; }
    public class DeliveryTerms { public String Name; public String Incoterms; public String Id; }
    public class Person { public String Name; public String UserId; public String Email; public String Id; }
    private class Envelope { public DataDTO Data; }

    public static DataDTO parseData(String jsonPayload) {
        Envelope env = (Envelope) JSON.deserialize(jsonPayload, Envelope.class);
        if (env == null || env.Data == null) {
            throw new AuraHandledException('JSON не містить вузла "Data".');
        }
        return env.Data;
    }
    public static DataDTO parseDataNodeOnly(String jsonPayload) {
        Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(jsonPayload);
        Object dataNode = root.get('Data');
        if (dataNode == null) {
            throw new AuraHandledException('JSON не містить вузла "Data".');
        }
        return (DataDTO) JSON.deserialize(JSON.serialize(dataNode), DataDTO.class);
    }

    // --------- Сегмент → вірт. акаунт ---------
    public static Map<String, Id> getSegmVirtAcc() {
        Map<String, Id> mapSegmAcc = new Map<String, Id>();
        List<SegmentAccount__c> listSA = [SELECT Name, ID_ERP__c FROM SegmentAccount__c];
        for (SegmentAccount__c sa : listSA) {
            Account acc = AccountRepository.getByErp(sa.ID_ERP__c);
            if (acc != null) mapSegmAcc.put(sa.Name, acc.Id);
        }
        return mapSegmAcc;
    }
    public static Id getVirtAccIdBySegm(String segment) {
        Map<String, Id> mapIds = getSegmVirtAcc();
        return mapIds.containsKey(segment) ? mapIds.get(segment) : null;
    }

    // --------- Пошук дублікатів по назві ---------
    public static List<StringUtilsEx.MatchResult> getAccountDuplicates(String sourceName, Decimal threshold) {
         // Тестовий інжектор дублікейтів
        if (Test.isRunningTest() && testDuplicates != null) {
            return testDuplicates;
        }      
        List<StringUtilsEx.MatchResult> matches = new List<StringUtilsEx.MatchResult>();
        if (String.isBlank(sourceName)) {
            System.debug('Source Name is incorrect');
            return matches;
        }
        if (threshold == null || threshold == 0.0 || threshold < 0 || threshold > 1.0) {
            System.debug('Parameter threshold was set to default value 0.8');
            threshold = 0.8;
        }
        IndexWeights idxWeights = IndexWeights.getDefault();
        WeightSet pairWeights   = WeightSet.getDefault();
        return NameSimilarityUtil.finalDuplicateCheck(
            Consts.FIND_BY_NAME,
            sourceName,
            false,
            '',
            null,
            threshold,
            false,
            idxWeights,
            pairWeights
        );
    }

    // --------- Результат конвертації ---------
    public class LeadConvertResult {
        public Boolean accResult;
        public Boolean oppResult;
        public Boolean contResult;
        public Boolean leadConverted;
        public LeadConvertResult() {
            accResult = false; oppResult = false; contResult = false; leadConverted = false;
        }
        public LeadConvertResult(Boolean a, Boolean o, Boolean c, Boolean l) {
            accResult = a; oppResult = o; contResult = c; leadConverted = l;
        }
    }

    // --------- Основний метод ---------
    public static LeadConvertResult convertLead(String payload) {
        LeadConvertResult result = new LeadConvertResult();
        DataDTO dataConv = parseDataNodeOnly(payload);

        if (dataConv == null) {
            System.debug('❌ ERROR: Data structure is invalid!');
            return result;
        }

        // Знаходимо “енквайрі” оппу (head)
        List<Opportunity> headList = [
            SELECT Id, ID_ERP__c, Lead__c, ITENumber__c
            FROM Opportunity
            WHERE Id = :dataConv.Header.ID_SF
            LIMIT 1
        ];
        if (headList.isEmpty()) {
            System.debug('❌ ERROR: Lead Enquiry is invalid!');
            return result;
        }
        Opportunity head = headList[0];

        ClientLead__c lead = LeadRepository.getById(head.Lead__c);
        if (lead == null) {
            System.debug('❌ ERROR: Lead ID is invalid!');
            return result;
        }

        // Дублікати акаунтів
        List<StringUtilsEx.MatchResult> matches = getAccountDuplicates(dataConv.Header.Account.Name, 0.85);
        if (!matches.isEmpty()) {
            List<LeadDuplicateAcc__c> ldaList = new List<LeadDuplicateAcc__c>();
            for (StringUtilsEx.MatchResult mr : matches) {
                ldaList.add(new LeadDuplicateAcc__c(
                    RecordTypeId        = RecordTypeCache.getId(LeadDuplicateAcc__c.SObjectType, 'Convertion'),
                    AccountNameIT__c    = dataConv.Header.Account.Name,
                    DuplicateAcc__c     = mr.account1Id,
                    MainLead__c         = lead.Id,
                    MatchIndex__c       = mr.matchIndex,
                    ID_ERP__c           = dataConv.Header.Account.Id,
                    JSONBody__c         = payload
                ));
            }
            if (!ldaList.isEmpty()) Database.insert(ldaList, false);

            // ── LOG: duplicates found (critical)
            Triton.instance.addEvent(
                TritonTypes.Level.ERROR,
                TritonTypes.Type.AccountDuplicates,
                TritonTypes.Area.LeadConversion,
                'Duplicate Accounts were found during Lead Conversion',
                payload
            );
            return result; // критично — дубль знайдено
        }

        // Перевіряємо сегмент (ERP код vs піктліст)
        Map<String, String> segmentsMap = SysUtils.getPicklistFieldMap('Account', 'MarketSegment__c', true);
        String segmentCandidate = dataConv.Header.BusinessSegmentId;
        // перевірка сегмента
        if (!segmentsMap.containsKey(segmentCandidate) && !bypassSegmentCheck) {
            System.debug('❌ ERROR: Market Segment is invalid (unknown ERP code): ' + segmentCandidate);
            return result;
        }

        // Власник
        User usr = UserRepository.getByLoginERP(dataConv.Header.SalesRep.UserId);
        if (usr == null) {
            // fallback — поточний користувач
            usr = [SELECT Id, Profile.UserLicense.Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        } else {
            // гарантуємо, що завантажили ліцензію профілю
            usr = [SELECT Id, Profile.UserLicense.Name FROM User WHERE Id = :usr.Id LIMIT 1];
        }

        // перевірка ліцензії
        if (usr.Profile.UserLicense.Name != 'Salesforce' && !bypassLicenseCheck) {
            System.debug('❌ ERROR: Wrong User Licence (is not Salesforce)!');
            return result;
        }

        // Країна
        Country__c country = CountryRepository.getByNumCode(String.valueOf(dataConv.Header.CountryId));
        if (country == null) {
            System.debug('❌ ERROR: Country is invalid!');
            return result;
        }

        // Довідники
        Id deliveryTermsId = null, paymentTermsId = null;
        List<DeliveryTerms__c> delivTerms = [
            SELECT Id FROM DeliveryTerms__c WHERE ID_ERP__c = :dataConv.Header.DeliveryTerms.Id LIMIT 1
        ];
        if (!delivTerms.isEmpty()) deliveryTermsId = delivTerms[0].Id;

        List<PaymentTerms__c> paymTerms = [
            SELECT Id FROM PaymentTerms__c WHERE ID_ERP__c = :dataConv.Header.PaymentTerms.Id LIMIT 1
        ];
        if (!paymTerms.isEmpty()) paymentTermsId = paymTerms[0].Id;

        // Створюємо акаунт
        Account acc = new Account(
            Name                = dataConv.Header.Account.Name,
            AccountSource       = 'Customer Event',
            CountryId__c        = country.Id,
            BillingCountry      = country.SysName__c,
            BillingCountryCode  = country.A2Code__c,
            BillingStreet       = dataConv.Header.Account.Address,
            MarketSegment__c    = segmentCandidate,
            OwnerId             = usr.Id,
            DeliveryTerms__c    = deliveryTermsId,
            Payment_Terms_v2__c = paymentTermsId,
            CurrencyIsoCode     = dataConv.OrderCurrency,
            Activity_Type__c    = 'Potential',
            HoldingGroup__c     = lead.Holding__c,
            ParentId            = lead.ParentAccount__c,
            Phone               = lead.Phone__c,
            Mobile__c           = lead.Mobile__c,
            Email__c            = lead.Email__c,
            Website             = lead.Web__c,
            Type                = 'End User',
            RecordTypeId        = rtIdAcc,
            ID_ERP__c           = dataConv.Header.Account.Id
        );

        Database.SaveResult accSr = Database.insert(acc, false);
        if (!accSr.isSuccess()) {
            System.debug('❌ ERROR: Account creation was unsuccessful!');
            // ── LOG: account creation failed
            Triton.instance.addError(
                TritonTypes.Type.DMLResult,
                TritonTypes.Area.LeadConversion,
                'Account creation was unsuccessful',
                'Account Name: ' + dataConv.Header.Account.Name
            );
            return result;
        }
        result.accResult = true;
        Id newAccId = accSr.getId();

        // Мапа RT для опп
        String division = (dataConv.OrderType == null ? '' : dataConv.OrderType.trim().toUpperCase());
        String oppTargetRtDevName = (division == 'TUBES') ? 'Tubes_RFP' : 'Wheels_RFP';

        // Перекодовуємо оппи, створені як Enquiry
        List<Opportunity> oppList = [
            SELECT Id, RecordTypeId, Status__c, AccountId
            FROM Opportunity
            WHERE Lead__c = :lead.Id
              AND RecordTypeId = :rtIdOpp
        ];
        if (!oppList.isEmpty()) {
            Id newOppRtId = RecordTypeCache.getId(Opportunity.SObjectType, oppTargetRtDevName);
            for (Opportunity o : oppList) {
                o.RecordTypeId = (newOppRtId != null ? newOppRtId : o.RecordTypeId);
                o.AccountId    = newAccId;
                o.Status__c    = 'Opportunity';
            }
            Database.SaveResult[] oppSrs = Database.update(oppList, false);
            Boolean ok = true;
            String errStr = '\n❌ ERROR: Opportunity update was unsuccessful!\nBad IDs:\n';
            for (Integer i = 0; i < oppSrs.size(); i++) {
                ok &= oppSrs[i].isSuccess();
                if (!oppSrs[i].isSuccess()) errStr += oppSrs[i].getId() + '\n';
            }
            if (!ok) {
                System.debug(errStr);
                // ── LOG: opportunity update failed
                Triton.instance.addError(
                    TritonTypes.Type.DMLResult,
                    TritonTypes.Area.LeadConversion,
                    'Opportunity update was unsuccessful',
                    errStr
                );
            } else {
                result.oppResult = true;
            }
        } else {
            System.debug('ℹ️ No Enquiry opportunities to update for lead ' + lead.Id);
        }

        // Контакти з ліда → акаунт
        List<Contact> contList = [
            SELECT Id, AccountId, RecordTypeId
            FROM Contact
            WHERE Lead__c = :lead.Id
              AND RecordTypeId = :rtIdCont
        ];
        if (!contList.isEmpty()) {
            Id externalRt = RecordTypeCache.getId(Contact.SObjectType, 'External');
            for (Contact c : contList) {
                c.AccountId    = newAccId;
                if (externalRt != null) c.RecordTypeId = externalRt;
            }
            Database.SaveResult[] contSrs = Database.update(contList, false);
            Boolean ok = true;
            String errStr = '\n❌ ERROR: Contacts update were unsuccessful!\nBad IDs:\n';
            for (Integer i = 0; i < contSrs.size(); i++) {
                ok &= contSrs[i].isSuccess();
                if (!contSrs[i].isSuccess()) errStr += contSrs[i].getId() + '\n';
            }
            if (!ok) {
                System.debug(errStr);
                // ── LOG: contacts update failed
                Triton.instance.addError(
                    TritonTypes.Type.DMLResult,
                    TritonTypes.Area.LeadConversion,
                    'Contacts update were unsuccessful',
                    errStr
                );
            } else {
                result.contResult = true;
            }
        } else {
            System.debug('ℹ️ No Lead_Contact contacts to update for lead ' + lead.Id);
        }

        // Фінал: відмічаємо лід як Converted, якщо все ОК
        if (result.accResult && result.oppResult && result.contResult) {
            lead.LeadStage__c = 'Converted';
            Database.SaveResult lSr = Database.update(lead, false);
            if (!lSr.isSuccess()) {
                System.debug('❌ ERROR: Lead Converted status update failed!');
                // ── LOG: lead status failed
                Triton.instance.addError(
                    TritonTypes.Type.DMLResult,
                    TritonTypes.Area.LeadConversion,
                    'Lead Converted status was unsuccessful',
                    'Lead Conversion was unsuccessful - Stage was not updated to Converted'
                );
            } else {
                result.leadConverted = true;
            }
        }
        return result;
    }
}