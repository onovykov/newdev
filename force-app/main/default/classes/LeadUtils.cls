public class LeadUtils {
    /* Конвертація "лівих" акаунтів у ліди */
    //-- Кешована мапа керівників сегментів
    private static Map<String, User> segmChiefsMap = new Map<String, User>();
    private static Boolean isLoaded = false;

    /* Керівники сегментів */
    public static void loadAllSegmChiefs() {
        if (isLoaded) return;

        // гарантуємо, що є мапа й вона порожня
        if (segmChiefsMap == null) {
            segmChiefsMap = new Map<String, User>();
        } else {
            segmChiefsMap.clear();
        }

        List<User> usrList = [
            SELECT Id, Name, UserRole.Name, Profile.Name, SalesDivision__c, BusinesDivision__c, Title
            FROM User
            WHERE Profile.UserLicense.Name = 'Salesforce'
            AND IsActive = true
            AND SalesDivision__c != null
            AND BusinesDivision__c IN ('Pipes','Railway')
            AND JobTitle__c IN ('Sales Chief Officer')
            ORDER BY SalesDivision__c
        ];

        if (!usrList.isEmpty()) {
            for (User usr : usrList) {
                segmChiefsMap.put(usr.SalesDivision__c, usr);
            }
            isLoaded = true;
        } else {
            isLoaded = false;
        }
    }

    //--- Повермаємо мапу кервіників сегментів
    public static Map<String, User> getSegmChiefsMap() {
        loadAllSegmChiefs();
        return isLoaded ? segmChiefsMap : new Map<String, User>();
    }
    //--- Кервіник конкретного сегменту
     public static User getSegmentChief(String segmentCode) {
        loadAllSegmChiefs();
        return isLoaded ? segmChiefsMap.get(segmentCode) : new User();
    }   

    //--- Чистимо кеш
    public static void clearCache() {
        isLoaded = false;
        if (segmChiefsMap != null) {
            segmChiefsMap.clear();
        } else {
            segmChiefsMap = new Map<String, User>();
        }
    }

    //--- Рефрешимо кеш
    public static void refreshCache() {
        clearCache();
        loadAllSegmChiefs();
    }

    /*  Повертаємо лист "підозрілих" акаунтів ***
        Параматри:
            Boolean isNullIDinERP = true - немає ID_ERP__c;
            Boolean noOpps = true - немає жодної Opportunity;
            Boolean isNoClosedWon = true - немає жодної Opportunity в статусі ClosedWon
            Boolean isNoOrders = true - немає жодного ордеру;
            Boolean noSegment = true - немає сегменту;
            Boolean And_Or = true - WHERE по AND, false - WHERE по OR  
            Boolean isWrongOwner = true - шукати з оунером (alias) ITE або Bahtiyar 
            Integer sqlLimit - число для параметру LIMIT. Якщо =0 - ліміту немає  
    *** */
    public static List<Account> getWrongAccList(Boolean isNullIDinERP, Boolean noOpps, Boolean isNoClosedWon, 
                                                Boolean isNoOrders, Boolean noSegment, Boolean isWrongOwner, 
                                                Boolean And_Or, Integer sqlLimit) {
        List<Account> accList = new List<Account>();
        String sqlStr = 'SELECT ' + 
                'Id, ID_ERP__c, Name, MarketSegment__c, ParentId, HoldingGroup__c,BillingCity,BillingStreet,' + 
                'CountryId__c, Ownerid, Owner.Name, Owner.IsActive, Owner.CountryCode,' + 
                'Owner.SalesDivision__c, Owner.BusinesDivision__c, ' + 
                'Email__c, Phone, Mobile__c, WebSite, CreatedById, CreatedDate ' + 
            'FROM Account ';
        String whereStr = '';
        List<String> whereLst = new List<String>();

        if(isNullIDinERP) whereLst.add('ID_ERP__c=null');
        if(noOpps) whereLst.add('(OppsCount__c=0 OR OppsCount__c=null)');
        if(isNoClosedWon) whereLst.add('(ClosedWonOpps__c=0 OR ClosedWonOpps__c=null)');
        if(isNoOrders) whereLst.add('(OppsCount__c=0 OR OppsCount__c=null)');
        if(noSegment) whereLst.add('MarketSegment__c=null');
        if(isWrongOwner) {
            String aliases = 'Owner.Alias IN (\'ITE\',\'Bahtiyar\')';
            whereLst.add(aliases);
        }

        if(isNullIDinERP || noOpps || isNoClosedWon || isNoOrders || noSegment || isWrongOwner) {
            String whereConn = And_Or ? ' AND ' : ' OR ';
            whereStr = ' WHERE ' + String.join(whereLst, whereConn);
        }

        sqlStr = sqlStr + whereStr + (sqlLimit==0 ? '' : ' LIMIT ' + String.valueOf(sqlLimit));
        //System.debug(sqlStr);

        accList = (List<Account>) Database.query(sqlStr);
        System.debug('Returned ' + accList.size() + ' records'); 
        return accList;      
    }

    //--- Версія пошуку за списком AccountId
     public static List<Account> getWrongAccList(Set<Id> setIdList) {
        List<Account> accList = new List<Account>();
        if(setIdList!=null && !setIdList.isEmpty()) {
            accList = [SELECT 
                        Id, ID_ERP__c, Name, MarketSegment__c, ParentId, HoldingGroup__c,BillingCity,BillingStreet,
                        CountryId__c, Ownerid, Owner.Name, Owner.IsActive, Owner.CountryCode,
                        Owner.SalesDivision__c, Owner.BusinesDivision__c, 
                        Email__c, Phone, Mobile__c, WebSite, CreatedById, CreatedDate
                      FROM Account WHERE Id IN :setIdList];       
        }
        return accList;      
    }
       

    //--- Мапа сегмент/країна по дефолту
    private static Map<String,String> mapSegmAcc = new Map<String,String>{
        '00001'=>'US', '00002'=>'AE', '00004'=>'CH',
        '00010'=>'KZ','00011'=>'UA','00006'=>'UA'
    };

    //--- Формування листа лідів з листа "підозрілих" акаунтів
    public static List<ClientLead__c> getLeadsToInseret(List<Account> fakeAccList) {
        List<ClientLead__c> leadList = new List<ClientLead__c>();
        //  Формуємо сет Id акаунтів, які вже було перенесено в ліди
        Set<Id> setAccLead = new Set<Id>();
        List<ClientLead__c> lstAccLead = [SELECT Account__c FROM ClientLead__c WHERE Account__c!=null];
        if(!lstAccLead.isEmpty()) {
            for(ClientLead__c cl : lstAccLead) {
                setAccLead.add(cl.Account__c);
            }            
        }
        // Формування листа
        if(!fakeAccList.isEmpty()) {
            for(Account acc : fakeAccList) {
                if(setAccLead.isEmpty() || !setAccLead.contains(acc.Id)) { // Якщо такого ще нема - додаємо
                    ClientLead__c lead = new ClientLead__c();
                    lead.Name = acc.Name; // Назва 
                    lead.Account__c = acc.Id; // AccountId - для тесту. Далі тут буде Id акаунта, конвертованого з цього ліда
                    if(acc.CountryId__c!=null) { // Є країна в акаунті
                        lead.Country__c = acc.Country__c;               
                    } else { // Немає країни в акаунті
                        // --> Спробуємо дістати країну з сегменту 
                        if(acc.MarketSegment__c!=null) {
                            if(mapSegmAcc.keySet().contains(acc.MarketSegment__c)) {
                                Country__c c = CountryRepository.getByA2Code(mapSegmAcc.get(acc.MarketSegment__c));
                                lead.Country__c = c.Id;                                
                            }
                        } else {// Шукаємо країну в оунері
                             if(!String.isBlank(acc.Owner.CountryCode)) { 
                                Country__c c = CountryRepository.getByA2Code(acc.Owner.CountryCode);
                                lead.Country__c = c.Id;
                            } else { // Якщо й тут пусто - ставимо по дефолту UA
                                Country__c c = CountryRepository.getByA2Code('UA');
                                lead.Country__c = c.Id;
                            }                           
                        }
                    }
                    // Отримати сегмент і дивізіон
                    if(acc.MarketSegment__c!=null) { // Є сегмент в акаунті
                        lead.MarketSegment__c = acc.MarketSegment__c;
                        if(acc.MarketSegment__c=='00006') {
                            lead.BusinessDivision__c = 'Railway';
                        } else {lead.BusinessDivision__c = 'Pipes';}
                    } else { // Немає сегменту в акаунті
                        if(acc.Owner.BusinesDivision__c!=null) {// Оуенр має дивізіон?
                            // Беремо дивізіон з оунера
                            lead.BusinessDivision__c = acc.Owner.BusinesDivision__c;
                        } else {
                            // Беремо дивізіон по дефолту - Pipes
                            lead.BusinessDivision__c = 'Pipes';
                            // Сегмент - по країні
                            Country__c country = CountryRepository.getById(lead.Country__c);
                            lead.MarketSegment__c = country.Market_Segment__c;
                        }
                        if(acc.Owner.SalesDivision__c!=null) {
                            lead.MarketSegment__c = acc.Owner.SalesDivision__c;
                        }
                    }
                    lead.City__c = acc.BillingCity;
                    lead.Address__c = acc.BillingStreet;
                    if(acc.Owner.IsActive) { // Якщо юзер активний
                        // Записуємо його у власники ліда
                        lead.Manager__c = acc.Ownerid;
                        lead.OwnerId = acc.Ownerid;
                    } else { // Якщо юзер деактивований
                        if(!String.isBlank(acc.MarketSegment__c)) { // Якщо є сегмент
                            // Записуємо власником ліда керівника сегменту 
                            User u = getSegmentChief(acc.MarketSegment__c);
                            lead.Manager__c = u.Id;
                            lead.OwnerId = u.Id;                   
                        } else { // Інакше - IT-Enterpise
                            User u = UserRepository.getByAlias('ITE');
                            lead.Manager__c = u.Id;
                            lead.OwnerId = u.Id;                    
                        }
                    }
                    lead.Email__c = acc.Email__c;
                    lead.Mobile__c = acc.Mobile__c;
                    lead.Phone__c = acc.Phone;
                    lead.Web__c = acc.Website;

                    leadList.add(lead);
                }  
            }
        } 
        return leadList;      
    }

    //--- Інсертимо лист нових лідів, що створюються з хибних акаунтів
    //    Повертаємо мапу <Id хибного акаунта, Id нового ліда>
    public static Map<Id,Id> insertNewLeads(List<ClientLead__c> clList) {
        Map<Id,Id> newIdsMap = new Map<Id,Id>();
        if(clList!=null && !clList.isEmpty()) {
            Database.SaveResult[] results   = Database.insert(clList, false);
            for (Integer i = 0; i < results.size(); i++) {
                if (results[i].isSuccess()) {
                    newIdsMap.put(((ClientLead__c)clList[i]).Account__c, ((ClientLead__c)clList[i]).Id);
                } else {
                    // Обробка помилок для конкретного елемента
                    for (Database.Error e : results[i].getErrors()) {
                        // Для прод версії доповнити - додати запис логу в Pharos Triton
                        System.debug('Row ' + i + ' failed: ' + e.getStatusCode() + ' ' + e.getMessage());
                    }
                }
            }
            //System.debug('Inserted Ids: ' + newIds); 
        }
        return newIdsMap;       
    }    
 
    //--- Прив'язуємо до нових лідів оппи й ордери
    /**
     * @param mapAccLeadIds  key: AccountId, value: Lead__c (custom) Id
     * @param onlyIfBlank    true -> виставляти Lead__c тільки якщо воно порожнє
     */
    public static void linkLeadsOppOrders(Map<Id, Id> mapAccLeadIds, Boolean onlyIfBlank) {
        if (mapAccLeadIds == null || mapAccLeadIds.isEmpty()) return;

        Set<Id> accIds = new Set<Id>(mapAccLeadIds.keySet());

        Boolean canUpdateOpp   = Schema.sObjectType.Opportunity.fields.Lead__c.isUpdateable();
        Boolean canUpdateOrder = Schema.sObjectType.Order.fields.Lead__c.isUpdateable();
        Boolean canUpdateContact = Schema.sObjectType.Contact.fields.Lead__c.isUpdateable();
        
        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        // Отримуємо RecordTypeId 'New_Client_Enquiry' для Opportunity (для сендбоксу =  012S8000003CKzEIAW)
        Id rtOppId = null;
        Map<String, Schema.RecordTypeInfo> oppRtMap =
            Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName();
        if (oppRtMap != null && oppRtMap.containsKey('New_Client_Enquiry')) {
            rtOppId = oppRtMap.get('New_Client_Enquiry').getRecordTypeId();
        }
        // Отримуємо RecordTypeId 'Lead_Contact' для Contact (для сендбоксу =  012S8000004eHr3IAE)
        Id rtContId = null;
        Map<String, Schema.RecordTypeInfo> contRtMap =
            Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName();
        if (contRtMap != null && contRtMap.containsKey('Lead_Contact')) {
            rtContId = contRtMap.get('Lead_Contact').getRecordTypeId();
        }
                                   
        // Opportunity
        if (canUpdateOpp) {
            List<Opportunity> opps = onlyIfBlank
                ? [SELECT Id, AccountId, Lead__c, RecordTypeId, Status__c FROM Opportunity WHERE AccountId IN :accIds AND Lead__c = NULL]
                : [SELECT Id, AccountId, Lead__c, RecordTypeId, Status__c FROM Opportunity WHERE AccountId IN :accIds];

            for (Opportunity opp : opps) {
                Id newLeadId = mapAccLeadIds.get(opp.AccountId);
                if (newLeadId == null) continue;

                if (onlyIfBlank) {
                    if (opp.Lead__c == null) {
                        opp.Lead__c = newLeadId;
                        if (rtOppId != null) opp.RecordTypeId = rtOppId;
                        opp.Status__c = 'Enquiry';
                        oppsToUpdate.add(opp);
                    }
                } else {
                    if (opp.Lead__c != newLeadId) {
                        opp.Lead__c = newLeadId;
                        if (rtOppId != null) opp.RecordTypeId = rtOppId;
                        opp.Status__c = 'Enquiry';
                        oppsToUpdate.add(opp);
                    }
                }
            }
        }
        // Orders
        List<Order> ordersToUpdate = new List<Order>();
        if (canUpdateOrder) {
            List<Order> orders = onlyIfBlank
                ? [SELECT Id, AccountId, Lead__c FROM Order WHERE AccountId IN :accIds AND Lead__c = NULL]
                : [SELECT Id, AccountId, Lead__c FROM Order WHERE AccountId IN :accIds];

            for (Order ord : orders) {
                Id newLeadId = mapAccLeadIds.get(ord.AccountId);
                if (newLeadId == null) continue;

                if (onlyIfBlank) {
                    if (ord.Lead__c == null) {
                        ord.Lead__c = newLeadId;
                        ordersToUpdate.add(ord);
                    }
                } else {
                    if (ord.Lead__c != newLeadId) {
                        ord.Lead__c = newLeadId;
                        ordersToUpdate.add(ord);
                    }
                }
            }
        }
        // Contacts
        List<Contact> contactsToUpdate = new List<Contact>();
        if (canUpdateContact) {
            List<Contact> contacts = onlyIfBlank
                ? [SELECT Id, AccountId, Lead__c FROM Contact WHERE AccountId IN :accIds AND Lead__c = NULL]
                : [SELECT Id, AccountId, Lead__c FROM Contact WHERE AccountId IN :accIds];

            for (Contact c : contacts) {
                Id newLeadId = mapAccLeadIds.get(c.AccountId);
                if (newLeadId == null) continue;

                if (onlyIfBlank) {
                    if (c.Lead__c == null) {
                        c.Lead__c = newLeadId;
                        if (rtContId != null) c.RecordTypeId = rtContId;
                        contactsToUpdate.add(c);
                    }
                } else {
                    if (c.Lead__c != newLeadId) {
                        c.Lead__c = newLeadId;
                        if (rtContId != null) c.RecordTypeId = rtContId;
                        contactsToUpdate.add(c);
                    }
                }
            }
        }
        // Часткові апдейти + місце для логування помилок
        if (!oppsToUpdate.isEmpty()) {
            Database.SaveResult[] r = Database.update(oppsToUpdate, /*allOrNone*/ false);
            // TODO: за потреби — залогувати неуспіхи r[i].getErrors()
        }
        if (!ordersToUpdate.isEmpty()) {
            Database.SaveResult[] r = Database.update(ordersToUpdate, /*allOrNone*/ false);
            // TODO: за потреби — залогувати неуспіхи r[i].getErrors()
        }
        if (!contactsToUpdate.isEmpty()) {
            Database.SaveResult[] r = Database.update(contactsToUpdate, /*allOrNone*/ false);
            // TODO: за потреби — залогувати неуспіхи r[i].getErrors()
        }        
    }

    // За замовчуванням перезаписує, якщо значення інше
    public static void linkLeadsOppOrders(Map<Id, Id> mapAccLeadIds) {
        linkLeadsOppOrders(mapAccLeadIds, false);
    }

    /* ********************************************************* */
    //--- Повертаємо ID_ERP__c віртуального акаунта
    //    Сегмент задається як АРІ відповідного піклиста - '00001', '00002' тощо
    public static String getSegmAccCode(String segment) {
        // Перевіряємо коректність сегменту
        if(String.isBlank(segment)) return '';
        // Отримуємо перелік сегментів з типового піклиста на акаунті
        Map<String, String> segmMap = SysUtils.getPicklistFieldMap('Account', 'MarketSegment__c', true);
        if(!segmMap.keySet().contains(segment)) return '';
        
        Map<String, String> segmAccMap = new Map<String, String>();
        // Дістаємо вірт. акаунти для сегметів з Custom Setting SegmentAccount__c
        for(SegmentAccount__c row : [SELECT Name, ID_ERP__c FROM SegmentAccount__c]) {
            segmAccMap.put(row.Name, row.ID_ERP__c);
        }
        if(!segmAccMap.keySet().contains(segment)) return '';

        return segmAccMap.get(segment);
    }


    //--- Повертаємо нормалізовану назву ліда
    public static String getLeadNormName(String leadName) {
        if(String.isBlank(leadName)) {
            System.debug('❌ ERROR: Lead Name is invalid!');
            return '';
        } else {
            return StringNormalize.getClearName(leadName, Consts.ToUpperCase.YES,
                                                    Consts.QuestionMarkRule.REMOVE_SIGN,
                                                    Consts.ClearCountryName.NO);
        }
    }

    //--- Метод пошуку дублів по наявних фонет. кодах і норм неймах в полях ClientLead__c
    public static List<StringUtilsEx.MatchResult> findDuplicates(String sourceName, Decimal threshold) {

        List<StringUtilsEx.MatchResult> resultList = new List<StringUtilsEx.MatchResult>();

        if(String.isBlank(sourceName)) {
            System.debug('❌ERROR! Source Name is invalid!');
            return resultList;
        }

        if (threshold == null || threshold < 0.0 || threshold > 1.000) {
            System.debug('⚠️WARNING! Parameter threshold was set to default: 0.8');
            threshold = 0.8;
        }
        String s = getLeadNormName(sourceName);
        String sourceSoundexAll = String.join(StringUtilsEx.getSoundexEx(s), ' ');
        String sourceNysiisAll = StringUtilsEx.getNYSIIS(s);
        String sourcePhonetic  = PhoneticTranscoder.toPhoneticCode(s);
        MetaphoneUtils.MetaphoneResult mphResult = MetaphoneUtils.getMetaphoneFull(s);

        String sourceSoundex3 = sourceSoundexAll.left(3);
        List<ClientLead__c> leadList = LeadRepository.getloadAllLeads();
        List<ClientLead__c> matchLeadList = LeadRepository.getByFieldValue('SoundexFirst3Letters__c', sourceSoundex3);
        if(matchLeadList.isEmpty()) {
            System.debug('No match results');
            return resultList;
        }

        Integer lenS = s.length();
        String strLead = '';
        String leadSoundex = '';
        String leadNysiis = '';
        String leadPhonetic = '';
        MetaphoneUtils.MetaphoneResult leadMetaphone = new MetaphoneUtils.MetaphoneResult();
        for(ClientLead__c lead : matchLeadList) {
            if(lead.NormalizedName__c.length()>lenS) {
                strLead = lead.NormalizedName__c.substring(0,lenS);
            } else {
                strLead = lead.NormalizedName__c;
            }
            leadSoundex = String.join(StringUtilsEx.getSoundexEx(strLead), ' ');
            leadNysiis = StringUtilsEx.getNYSIIS(strLead);
            leadPhonetic = PhoneticTranscoder.toPhoneticCode(strLead);
            leadMetaphone = MetaphoneUtils.getMetaphoneFull(strLead);

            Decimal sndIx = StringUtilsEx.compareSoundexAllCodes(sourceSoundexAll, leadSoundex);
            Decimal nysIdx = StringUtilsEx.compareNysiisWords(sourceNysiisAll, leadNysiis,
                                                              StringUtilsEx.getNysiisCache(sourceNysiisAll, leadNysiis));
            Set<String> allCodes = new Set<String>();
            allCodes.add(sourcePhonetic);
            allCodes.add(leadPhonetic);
            Map<String, Set<String>> bigramsMap = PhoneticTranscoder.buildBigramsCache(new List<String>(allCodes));
            Map<String, Set<String>> lettersMap = PhoneticTranscoder.buildLettersCache(new List<String>(allCodes));
            Decimal phnIdx = PhoneticTranscoder.comparePhoneticHybridCached(sourcePhonetic, leadPhonetic, bigramsMap, lettersMap);

            // - сети для кодів Metaphone
            Set<String> mphCodes1 = new Set<String>();
            Set<String> mphCodes2 = new Set<String>();

            // - заповнюємо сети кодами
            mphCodes1.add(mphResult.primary);
            mphCodes1.add(mphResult.alternate);

            mphCodes2.add(leadMetaphone.primary);
            mphCodes2.add(leadMetaphone.alternate);

            Decimal mphIdx = MetaphoneUtils.compareMetaphoneLetterSets(mphCodes1, mphCodes2);

            Decimal resIdx = (sndIx + nysIdx + phnIdx + mphIdx)/4.0;
            if(resIdx >= threshold) {
                StringUtilsEx.MatchResult resRec = new StringUtilsEx.MatchResult(sourceName, lead.Id, null, resIdx.setScale(3));
                resultList.add(resRec);
            }
        }
        return resultList;
    }
}