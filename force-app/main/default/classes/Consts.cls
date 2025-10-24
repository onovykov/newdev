public class Consts {
    public enum Alphabet {CYR, LAT, MIXED, UNKNOWN}
    public enum FindType {BY_NAME, BY_CODE}
    public enum FindCodeType {BY_ID_ERP, BY_SF_ID}
    public enum SaveToObject {YES, NO}
    public enum NeedTranslit {YES, NO}
    public enum FirstWordsMatch {YES, NO}
    public enum NeedSort {YES, NO} //sortResult
    public enum RemoveBlanks {YES, NO} //removeBlanks
    public enum GetClear {YES, NO} //getClear
    public enum ToUpperCase {YES, NO}
    public enum AccountsSearchType {BY_SOQL, BY_APEX}
    public enum TranslitDir {CYR_TO_LAT, LAT_TO_CYR}
    public enum QuestionMarkRule {REMOVE_SIGN, REMOVE_WORD}    
    public enum ClearCountryName {YES, NO}
    
    //--- Константи
    public static final String ACCOUNT_OBJ = 'Account';
    public static final String LEAD_OBJ = 'ClientLead__c';
    
    public static final Boolean TO_UPPER = true;
    public static final Boolean NOT_TO_UPPER = false;
    
    public static final Boolean FIND_BY_NAME = true;
    public static final Boolean FIND_BY_CODE = false;
    public static final Boolean FIND_BY_ID_ERP = true;
    public static final Boolean FIND_BY_SF_ID = false; 
    
    public static final Boolean BY_SOQL = true;
    public static final Boolean BY_APEX = false;  
    
    public static final Boolean INSERT_YES = true;
    public static final Boolean INSERT_NO = false;
    
    public static final String LIKE_START_SIGN = '\'%';
    public static final String LIKE_END_SIGN = '%\'';
    public static final String LIKE_WORD = ' LIKE \'';
    
    public static final String CYR = 'Cyrillic';
    public static final String LAT = 'Latin';
    public static final Boolean CYR_TO_LAT = true;
    public static final Boolean LAT_TO_CYR = true;  
    
    public static final Boolean FIRST_WORDS = true;
    public static final Boolean ALL_WORDS = false;
    
    public static final Boolean NEED_TRANSLIT = true;
    public static final Boolean NOT_TRANSLIT = false;
    
    public static final Boolean NEED_SORT = true; //sortResult
    public static final Boolean NOT_SORT = false;   
    
    public static final Boolean REMOVE_BLANKS = true; //removeBlanks
    public static final Boolean NOT_REMOVE_BLANKS = false;
    
    public static final Boolean GET_CLEAR = true; //getClear
    public static final Boolean NOT_CLEAR = false;      

    public static final Integer LIKE_WEAK = 0;
    public static final Integer LIKE_LEFT = 1;
    public static final Integer LIKE_RIGHT = 2;
    public static final String  LIKE_OR = ' OR ';
    public static final String  LIKE_AND = ' AND ';
    
    public static final Boolean NEED = true;
    public static final Boolean NOT_NEED = false;
            
    public static final String SQL_DEFAULT_FIELDS;

    static {
        SQL_DEFAULT_FIELDS = getAllAccountFieldsAsString();
    }   
                                                                 
    private static String getAllAccountFieldsAsString() {
        // Отримуємо дескриптор для об'єкта Account
        Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.Account.fields.getMap();

        // Отримуємо імена полів
        List<String> fieldNames = new List<String>(fieldMap.keySet());

        Set<String> fieldSet = new Set<String>(fieldNames);
        
        // Видаляємо з переліку непотрібні поля
        fieldSet.removeAll(new Set<String>{'accgrp__c','activesince__c','bisdev__c',
            'bisdevsegm__c','ce_hierarchy__fifth_parentid__c','ce_hierarchy__first_parentid__c','ce_hierarchy__fourth_parentid__c',
            'ce_hierarchy__second_parentid__c','ce_hierarchy__third_parentid__c','staticresource__c','test_image_formula__c',
            'ddpcity__c','ddpcountry__c','deliverytermsincoterms__c','holding_group__c','holdinggroup__c',
            'accountnumber','accountsource','accountsreceivableexchangetimestamp__c','accountsreceivablelastsync__c',
            'accounttype__c','active__c','all_market_segments__c','annualrevenue','balance__c','billinggeocodeaccuracy','billinglatitude',
            'billinglongitude','billingpostalcode','billingstate','billingstatecode','billingstreet','blockdate__c','conforming__c',
            'currencyisocode','currentmonthreceipts__c','customerportalenabled__c','ddpaddress__c','ddpaddress__city__s','ddpaddress__countrycode__s',
            'ddpaddress__geocodeaccuracy__s','ddpaddress__latitude__s','ddpaddress__longitude__s','ddpaddress__postalcode__s','ddpaddress__statecode__s',
            'ddpaddress__street__s','dealingstatus__c','deliveryterms__c','description','geolocation__c','geolocation__latitude__s',
            'geolocation__longitude__s','geolocationlatitude__c','geolocationlongitude__c','grouppastduedebt__c','grouppastduedebt15more__c',
            'industry','industrysubcategory__c','iscustomerportal','isdeleted','ispriorityrecord','isvirtual__c','jigsaw','jigsawcompanyid',
            'lastactivitydate','lastmodifiedbyid','lastmodifieddate','lastreferenceddate','lastvieweddate','location__c','masterrecordid',
            'nps__c','numberofemployees','od_max__c','od_min__c','ourshare__c','ownerid','ownership','parent_account_specified__c',
            'pastduedebt__c','pastduedebt15more__c','payment_terms_v2__c','paymentterms__c','permissioncomment__c','permissiondate__c',
            'permittedbyid__c','permittedproductionamount__c','permittedshipmentamount__c','photourl','prod_plan_visible__c',
            'productioncapacity__c','products__c','rating','shippinggeocodeaccuracy','shippinglatitude','shippinglongitude',
            'shippingpostalcode','shippingstate','shippingstatecode','shippingstreet','shortened_name__c','sic','sicdesc','site',
            'stoplistrisk__c','systemmodstamp','tickersymbol','wt_max__c','wt_min__c'
        });
        
        List<String> filteredFieldNames = new List<String>(fieldSet);
        filteredFieldNames.sort();
        String result = String.join(filteredFieldNames, ',');
        return result;
    }
    
    //--- Словник назв-синонімів
    public static final Map<String, String> NAMES_DICT = new Map<String, String>{
        'ДНЕПРОПЕТРОВСКИЙ' => 'ДНІПРОВСЬКИЙ', 'ДНІПРОПЕТРОВСЬКИЙ' => 'ДНІПРОВСЬКИЙ','ДНЕПРОВСКИЙ' => 'ДНІПРОВСЬКИЙ',
        'JAZERA' => 'JAZEERA','JAZIRA' => 'JAZEERA','IRAQUE'=>'IRAQ','IRAK'=>'IRAQ','LEUVEN'=>'LEEUWEN',
        'КИЕВ' => 'КИЇВ','KIEV' => 'KYIV','РЫБИНСКИЙ'=>'РЫБНИЦКИЙ','CHECH'=>'CZECH','OIL & GAS'=>'',
        'МЕХАНИК'=>'МЕХАНІК', 'МЕАХАНІК'=>'МЕХАНІК','GROUPE'=>'GROUP','GRUPPE'=>'GROUP','GRUPPO'=>'GROUP',
        'GRUPA'=>'GROUP','GRUPO'=>'GROUP','GRUP'=>'GROUP','ROER'=>'ROR','SERVICES'=>'SERVICE','ГРУП'=>'GROUP',
        'ЮНАЙТЕД'=>'UNITED','СТІЛ'=>'STEEL','ГЛОБАЛ'=>'GLOBAL','ЛОДЖИСТІК'=>'LOGISTIC','КОРПОРЕЙШН'=>'CORPORATION',
        'INTERNATION'=>'INTERNATIONAL','TUBES'=>'TUBE', 'PIPES'=>'PIPE', 'SUPPLIES'=>'SUPPLY',
        'MATERIAL'=>'MATERIALS','КОМПАНИ'=>'COMPANY','КОМПАНІ'=>'COMPANY','ПЕТРОЛЕУМ'=>'PETROLEUM',
        'ЛИМИТЕД'=>'LIMITED','ЛІМІТЕД'=>'LIMITED','ТРАНССЄРВІС'=>'ТРАНССЕРВИС','HUNGARIA'=>'HUNGARY',
        'ЭНЕРДЖИ'=>'ENERGY','ЕНЕРДЖИ'=>'ENERGY','ЕНЕРДЖІ'=>'ENERGY','УКРАИНСКИЙ'=>'УКРАЇНСЬКИЙ',
        'ФЄМАТЕК'=>'ФЕМАТЕК','ФЕМАТЭК'=>'ФЕМАТЕК','GORGIA'=>'GEORGIA','ТИРОТЕКС-ЭНЕРГО'=>'ТИРОТЕКС',
        'KOENG'=>'KONIG','KOENGFRANKSTAHL'=>'KONIGFRANKSTAHL','EUROMETALS'=>'EUROMETAL',
        'ТРЕЙДІНГ'=>'TRADING','ТРЕЙД'=>'TRADE','ЛОГІСТІК'=>'LOGISTIC','ЛОГИСТИК'=>'LOGISTIC',
        'ЮЭЙ'=>'UA','ЮЕЙ'=>'UA','ЮА'=>'UA','DEUTSCHLAND'=>'GERMANY','P.VAN'=>'VAN','ГРУПП'=>'GROUP','ГРУППЕ'=>'GROUP'      
    };
    
    // Сет "сміттєвих" слів, які треба ігнорувати під час пошуку збігів
    public static final Set<String> TRASH_WORDS_SET = new Set<String>{
        'DES','DE','FER','ТОРГОВО-ПРОИЗВОДСТВЕННЫЙ','KOMMANDITGESELLSCHAFT','ODPOWIEDZIALNOŚCIĄ','ODPOWIEDZIALNOSCIA','USŁUGOWO-HANDLOWA','DIENSTLEISTUNGEN',
        'MUS.TIC.LTD.STI.','PRZEDSIĘBIORSTWA','PRZEDSIĘBIORSTWO','ВІДПОВІДАЛЬНІСТЮ','ОТВЕТСТВЕННОСТЬЮ','INTERNAȚIONALĂ','INTERNATIONALE',
        'MIĘDZYNARODOWA','MIĘDZYNARODOWE','SZOLGÁLTATÁSOK','DISTRIBUZIONE','INTERNACIONAL','INTERNATIONAL','SPOLKA.Z.O.O.','DISTRIBUCION',
        'DISTRIBUCIÓN','DISTRIBUTION','INDUSTRIELLE','KERESKEDELMI','TECHNOLOGIES','TRADE.S.R.O.','TRANSPORTOWA','ІНВЕСТИЦІЯМИ','ОГРАНИЧЕННОЙ',
        'ПІДПРИЄМСТВО','ТОВАРИЩЕСТВО','ТОРГІВЕЛЬНИЙ','ТОРГОВЕЛЬНИЙ','OGRANICZONĄ','KOMANDYTOWA','ALMOTTAHIDA',/*'COMMERCIALE',*/'CONSTRUCȚII',
        'CONTRACTING','CORPORATION','DISTRIBUȚIE','DYSTRYBUCJA','ENTERPRISES','EXPORTACION','EXPORTACIÓN','IMPORTACION','IMPORTACIÓN',
        'INDUSTRIALĂ','INDUSTRIALE','OGRANICZONA','PRODUKCYJNA','ROZWIĄZANIA','SZOLGÁLTATÓ','TECHNOLÓGIA','TECHNOLOGIE','UNTERNEHMEN',
        'АКЦИОНЕРНОЕ','ПАРТНЕРСТВО','ПРЕДПРИЯТИЕ','ТОРГІВЕЛЬНА','ТОРГОВЕЛЬНА','ХОЛДИНГОВАЯ','ХОЛДИНГОВИЙ','ХОЛДИНГОВЫЙ','ХОЛДІНГОВИЙ',
        'COMERCIALĂ','ENTREPRISE','ÉPÍTŐIPARI','GES.M.B.H.','HIZMETLERI','INDUSTRIAL','INDUSTRIES','MEGOLDÁSOK','NEMZETKÖZI','S.A.S.Z.I.',
        'SOLUCIONES','TECNOLOGIA','TECNOLOGÍA','TECNOLOGIE','TEHNOLOGII','АКЦІОНЕРНЕ','ІНОЗЕМНИМИ','КОРПОРАЦИЯ','ОПЕРЕЙТИНГ','ТОВАРИСТВО',
        'ХОЛДИНГОВА','ХОЛДІНГОВА','BUDOWLANA','CO.S.R.L.','COMERCIAL','FACTORIES','GMBH&CO.K','GMBH&Co.K','INDUSTRIE','MARKETING','MATERIALS',
        'MOTTAHIDA','OPERATING','PAZARLAMA','PRODUKCJI','S.A.-N.V.','SERVICIOS','SOCIETATE','SOLUTIONS','SOLUZIONI','SP.Z.O.O.','TRANSPORT',
        'ВИРОБНИЧА','ВИРОБНИЧЕ','ГУСЕЙНОВА','ОБМЕЖЕНОЮ','ПАРТНЕРОВ','УНИТАРНОЕ','PRESTĂRI','SERVICII','(GEMLIK)','(W.L.L.)','ALQABIDA',
        'COMPANIE','DEPOLAMA','DOWALIYA','ELEKTRIK','GMBH+Co.','HANDLOWA','HOLDINGS','INDUSTRY','KHADAMAT','KOLEKTIF','KOMANDIT','LLC-OCTG',
        'LOJISTIK','OTOMOTIV','S.A.O.G.','S.A.R.L.','S.P.R.L.','SERVICES','TIJARIYA','TRAIDING','USŁUGOWA','VERTRIEB','ЗАКРЫТОЕ','КОМБИНАТ',
        'КОМБІНАТ','КОМПАНИЯ','КОМПАНІЯ','ОБЩЕСТВО','ПРИВАТНЕ','ПУБЛІЧНЕ','САВАЛАНА','ТЕСТОВИЙ','ТОРГОВАЯ','ТОРГОВИЙ','ТОРГОВОЕ','ТОРГОВЫЙ',
        'AKCYJNA','CYWILNA','(ATCCO)','.M.B.H.','ALAMIYA','CO.,LTD','CO.LTD.','COMPANY','CSOPORT','DAGITIM','ENGINEE','FACTORY','GMBHCO.',
        'HOLDING','ISTIRAD','KOMPANI','LIMITED','LTD.CO.','LTD.STI','MAKAROV','PRIVATE','PVT.LTD','SAVUNMA','SERVIZI','SIKRETI','ŞIKRETI',
        'SINAIYA','SIRKETI','SOLUȚII','SUPPLY,','SYSTEME','SYSTEMS','SYSTEMY','TECHNIK','TEKSTIL','TICARET','TRADING','Z.O.O.,','КОМПАНИ',
        'ЛИМИТЕД','ТОРГОВА','ЧАСТНОЕ','SPÓŁKA','&#124;','(IMCO)','(LTDA)','ANONIM','BILLET','CO.KG.','CO.LLC','CO.LTD','D.O.O.','ENERJI',
        'EXPORT','F.Z.E.','GEMLIK','GLOBAL','GYÁRTÓ','HANDEL','IMALAT','IMPORT','INSAAT','INT.SA','J.S.C.','K.F.T.',
        'L.D.A.','L.L.C,','L.L.C.','LTD.CO','M.B.H.','O.O.D.','Office','P.P.L.','S.A.S.','S.A.U.','S.K.A.','S.L.A.','S.L.U.','S.O.P.','S.P.A.',
        'S.R.L.','S.R.O.','SAN.VE','SANAYI','SPOLKA','SPOŁKA','SUPPLY','TASDIR','TAWZEE','U.S.A.','USŁUGI','W.L.L.','Z.O.O.','ZAKŁAD','ZAVODU',
        'ZO.O.,','-GMBH','JAWNA','(IMS)','(PPL)','?ELIK','CO.KG','CORP.','D.O.O','Dubai','FIRMA','GMBH+','IPARI',
        'J.S.C','L.L.C','LTD.)','LTDA.','NV/SA','Nv/Sa','O.O.,','P.P.L','PLANT','S.A.S','S.A.U','S.L.U','S.O.P','S.P.A','S.R.O','SAGA,','SPOL.',
        'TAAH.','W.L.L','ВСМПО','ЗАВОД','ЙОЛЧУ','ПЕВКП','УЧНПП','ФИРМА','ФІРМА','ФОРМІ','O.O.','(UK)','?TI.','A.B.','A.D.','A.S.','A.Ş.','B.V.',
        'BHD.','BORU','BROS','C.V.','CJSC','CO.,','CO.K','COKG','CORP','CVBA','D.D.','DMCC','ENG.','EOOD','EURL','FZCO','FZEO','G.P.','GIDA',
        'GMBH','INC.','IND.','INT.','Jr’s','JR’S','Jr\'s','JR\'S','JSCO','KFT.','L.P.','LTD)','LTD,','LTD.','LTDA','N.A.','N.V.','NYRT',
        'P.W.','PJSC','PVT.','Rep.','S.A.','S.C.','S.J.','S.K.','S.L.','SAN.','SARL','SASU','SDN,','SDN.','SP.J','SP.K','SP.Z','STI.','TECH',
        'TEST','TIC.','V.V.','ЗПТУ','КПТМ','ЛНОЕ','НВПП','НГВУ','НЗСТ','ОГЛЫ','ОСОО','ПППФ','ПРАТ','СПБО','ТЕСТ','ЧТУП','SP.','CO.',
        '(M)','(S)','A.S','A/C','A/S','AND','B.V','B-D','BHD','BSC','CÉG','CFL','DIS','DOO','EST','FOR','FZE','INC','INS','INT','SRL.',
        'JPL','JSC','KFT','KG.','KKT','KSC','L.P','LDA','LLC','LLP','LTD','M/S','MBH','MTZ','OHG','OOD','OOO','PLC','PPL','PT.','PTE','PTY',
        'PVT','RBC','S.L','SAN','SAS','SCA','SCI','SCS','SDN','SLA','SLU','SNC','SPA','SRL','SRO','STE','STI','ŞTI','UAB','UND','WLL','ZRT',
        'ВАТ','ВКГ','ВКФ','ВНЦ','ВСФ','ГПУ','ДІМ','ДОМ','ДПЗ','ДПН','ЕГО','ЗАО','ЗАТ','МЖК','МУП','НВК ','НВО','НВП','НВФ','НПО','НПП','НПЦ',
        'ОАО','ООО','ПАО','ПАТ','ТДВ','ТММ','ТОВ','ТОО','ТПК','ТПО','УПП','Ф-Л','ФЛП','ФОП','ЧАО',/*'ЮЕЙ',*/'AB','AD','AG','AS','BT',' S.A',
        'BV','C.','CA','CO','Co','CZ','DE','ET','FZ','H.','IC','J.','JV','K.','KG','LP','ME','NV','O.','OG','OU','OY','P.','RT','S.','SA',
        'SB','SC','SL','SP','SV','TU','UA','UG','UK','UY','V1','VE','АО','АТ','БУ','ВК','ВО','ВП','ВФ','ГК','ГП','ДП','ИИ','ИП','КО','КП',
        'НВ','НС','ОА','ПО','ПП','СА','СП','ТБ','ТД','ТК','УП','ХО','ЧП','OF','CO.(SUMED)','OSTR','IN','END.','WLL.','BRANCH','NEW',
        'ZN','DER','DAS','M/S.','AB,C/O','К...','ТЦ','ТОРГОВО-ПРОМИСЛОВА','№112','СУ','ИНТЕРНЕЙШНЛ','РАЗВ.ДОБЫЧА','ПФЭМГ','ПРЕДСТАВНИЦТВО',
        'С.П.А.','ФИЛИАЛ','АКЦИОНЕРНОГО','ОБЩЕСТВА','С','ЕДИНСТВЕННЫМ','АКЦИОНЕРОМ','НВАТ','НП','ÇELİK','DIŞ','TİCARET','LTD.ŞTİ.',
        'ОТВЕТСТВННОСТЬЮ','ВОЗМОЖНОСТЬЮ','ЛТД','ЛТД.'};

    // Мапа "сміттєвих" слів, які треба ігнорувати під час пошуку збігів
    public static final Map<String, String> TRASH_WORDS = new Map<String, String>{
    'ТОРГОВО-ПРОИЗВОДСТВЕННЫЙ'=>'', 'ODPOWIEDZIALNOSCIA'=>'', 'ВІДПОВІДАЛЬНІСТЮ'=>'', 'ОТВЕТСТВЕННОСТЬЮ'=>'', 'ПІДПРИЄМСТВО'=>'', 'ТОРГОВЕЛЬНИЙ'=>'',
    'ТОРГІВЕЛЬНИЙ'=>'', 'ІНВЕСТИЦІЯМИ'=>'', 'ОГРАНИЧЕННОЙ'=>'', 'OGRANICZONA'=>'', 'KOMANDYTOWA'=>'', 'ПРЕДПРИЯТИЕ'=>'', 'АКЦИОНЕРНОЕ'=>'', 'ТОРГОВЕЛЬНА'=>'',
    'ТОРГІВЕЛЬНА'=>'', 'ТОВАРИСТВО'=>'', 'ІНОЗЕМНИМИ'=>'', 'АКЦІОНЕРНЕ'=>'', 'ОБМЕЖЕНОЮ'=>'', 'ВИРОБНИЧЕ'=>'', 'ВИРОБНИЧА'=>'', 'УНИТАРНОЕ'=>'',
    'SP.Z.O.O.'=>'', 'CO.S.R.L.'=>'', 'S.A.-N.V.'=>'', 'КОМПАНІЯ'=>'', 'ТОРГОВИЙ'=>'', 'ОБЩЕСТВО'=>'', 'ТОРГОВОЕ'=>'', 'ПУБЛІЧНЕ'=>'', 'ЗАКРЫТОЕ'=>'',
    'ТОРГОВЫЙ'=>'', 'ТОРГОВЫЙ'=>'', 'ТОРГОВАЯ'=>'', 'S.P.R.L.'=>'', 'ТЕСТОВИЙ'=>'', /*'OILFIELD'=>'', 'SUPPLIES'=>'',*/ '(GEMLIK)'=>'','КОМПАНИЯ'=>'',
    /*'SERVICES'=>'',*/ 'ЧАСТНОЕ'=>'', 'AKCYJNA'=>'', 'ТОРГОВА'=>'', 'TICARET'=>'', 'LIMITED'=>'', 'PRIVATE'=>'', /*'SERVICE'=>'', */ '.M.B.H.'=>'',
    'SPOLKA'=>'', 'SAN.VE'=>'', 'SPOŁKA'=>'', 'SPÓŁKA'=>'', 'SPOLKA.Z.O.O.'=>'', 'S.A.S.Z.I.'=>'','S.R.O'=>'','COMPANY'=>'','SUPPLY,'=>'',
    'W.L.L.'=>'', 'L.D.A.'=>'', 'CO.KG.'=>'', 'J.S.C.'=>'', 'M.B.H.'=>'', 'S.A.S.'=>'', 'S.P.A.'=>'', 'S.A.U.'=>'', 'SUPPLY'=>'','Z.O.O.'=>'','O.O.'=>'',
    'L.L.C,'=>'', 'GEMLIK'=>'', 'D.O.O.'=>'', 'S.R.O.'=>'', 'SRO'=>'','O.O.D.'=>'', 'OOD'=>'','S.L.A.'=>'', 'L.L.C.'=>'', 'ФІРМА'=>'', 'ФОРМІ'=>'', /*'ЦЕНТР'=>'',*/
    'ФИРМА'=>'', 'УЧНПП'=>'', 'CO.KG'=>'', 'L.L.C'=>'', /*'PIPES'=>'',*/ 'SPOL.'=>'', 'O.O.'=>'', 'SAN.'=>'', 'TIC.'=>'', 'A.Ş.'=>'', 'A.S.'=>'',
    'SP.Z'=>'', 'ПРАТ'=>'', 'LTD.'=>'', 'JSCO'=>'', 'ОСОО'=>'', /*'PIPE'=>'',*/ 'S.L.'=>'', 'ЗПТУ'=>'', 'S.A.'=>'', 'ТЕСТ'=>'', 'LTD,'=>'', 
    'GMBH'=>'', 'KFT.'=>'','S.A.U'=>'',/*'INTERNATIONAL'=>'',*/'SA'=>'','S.A.O.G.'=>'','KOMMANDITGESELLSCHAFT'=>'',
    'A.B.'=>'', 'НГВУ'=>'', 'B.V.'=>'', 'TEST'=>'', 'CO.K'=>'', 'СПБО'=>'', 'COKG'=>'', 'ЧТУП'=>'', 'A.D.'=>'', 'КПТМ'=>'', 'SP.J'=>'', 'НВПП'=>'', 'EOOD'=>'',
    'ПППФ'=>'', 'ДОМ'=>'', 'ДІМ'=>'', 'ТОВ'=>'', 'ТОО'=>'', 'SP.'=>'', 'ООО'=>'', 'ДПН'=>'', 'ВКГ'=>'', 'НВК'=>'', 'НВО'=>'', 'НПП'=>'', 'НВФ'=>'',
    'ВКФ'=>'', 'ВСФ'=>'', 'ВНЦ'=>'', 'Ф-Л'=>'', 'LTD'=>'', 'UAB'=>'', 'KFT'=>'', 'SRL'=>'', 'SLA'=>'', 'SAS'=>'', 'OOD'=>'', 'S.P.A.'=>'', 'LDA'=>'',
    'ЗАО'=>'', 'A/S'=>'', 'JSC'=>'', 'ТПО'=>'', 'ФЛП'=>'', 'НВП'=>'', 'LLC'=>'', 'НПО'=>'', 'НПЦ'=>'', 'ПАО'=>'', 'ГПУ'=>'', 'ЗАТ'=>'', 'PT.'=>'',
    'ЧАО'=>'', 'ФОП'=>'', 'УПП'=>'', 'ТПК'=>'', 'ТДВ'=>'', 'ВАТ'=>'', 'ПАТ'=>'', 'WLL'=>'', 'CO.'=>'', 'ОАО'=>'', 'МЖК'=>'', 'ДПЗ'=>'', 'ТД'=>'',
    'K.'=>'', 'VE'=>'', 'CO'=>'', 'ИИ'=>'', 'СП'=>'', 'ВП'=>'', 'ТБ'=>'', 'ВО'=>'', 'АО'=>'', 'ПП'=>'', 'ИП'=>'', 'ВФ'=>'', 'КП'=>'',
    'НВ'=>'', 'KG'=>'', 'ХО'=>'', 'ГК'=>'', 'ДП'=>'', 'ПО'=>'', 'BV'=>'', 'АТ'=>'', 'OU'=>'', 'БУ'=>'', 'ВК'=>'', 'ТК'=>'', 'AG'=>'',/*'P.VAN'=>'',*/
    'ГП'=>'', 'ОА'=>'', 'ЧП'=>'', 'AS'=>'', 'OG'=>'', 'H.'=>'', 'P.'=>'', 'УП'=>'', 'AB'=>'', 'SL'=>'', 'З'=>'', 'Z'=>'', 'У'=>'', 'С'=>'',
    'ТОВАРИЩЕСТВО'=>'', 'ПРИВАТНЕ'=>'', 'S.P.A.'=>'', 'S.P.A'=>'', 'GMBHCO.'=>'', 'SLU'=>'','S.L.U.'=>'','S.L.U'=>'','C.'=>'','PTY'=>'',
    'S.R.L.'=>'', 'P.W.'=>'', 'SAS'=>'', 'S.A.S.'=>'', 'S.A.S'=>'', 'DOO'=>'', 'NV'=>'', 'N.V.'=>'', 'CVBA'=>'','ПЕВКП'=>'',
    'SPA'=>'', 'S.P.A.'=>'', '(M)'=>'', 'SDN'=>'', 'BHD'=>'', 'UK'=>'', 'FZE'=>'','FZEO'=>'','Z'=>'','O.'=>'','НС'=>'',
    '(S)'=>'','PTE'=>'','FZCO'=>'','FZE'=>'','(IMS)'=>'','CO.LLC'=>'','CO. '=>'','INC.'=>'','INC'=>'','SYSTEMS'=>'',
    '(IMCO)'=>'','EST'=>'','W.L.L'=>'','CORP.'=>'','LTD.CO.'=>'','LTD.CO'=>'','CO.LTD.'=>'', 'KG.'=>'','|'=>'','\\'=>'','/'=>'',
    '(ATCCO)'=>'','S.P.A.'=>'','ME'=>'','DMCC'=>'','BSC'=>'','A.'=>'','S.'=>'','LTDA.'=>'','LTDA'=>'','НЗСТ'=>'','CO'=>'','J.'=>'',
    'C'=>'','PVT'=>'','CO.,'=>'','UY'=>'','ООО'=>'','S.L.'=>'', 'V1'=>'','B.V'=>'', 'C'=>'', 'LTD'=>'','LTD.)'=>'','LTD)'=>'',
    /*'MIDDLE'=>'','EAST'=>'',*/ 'INT.SA'=>'', 'INT'=>'', 'INT.'=>'', 'PVT.LTD'=>'', 'PVT.'=>'', 'GMBH+Co.'=>'', 'A.S.'=>'',
    'SANAYI'=>'', 'SIKRETI'=>'', 'ŞIKRETI'=>'','JR\'S'=>'','Jr\'s'=>'','JR’S'=>'','Jr’s'=>'', 'E'=>'','НПЦ'=>'','Co'=>'',
    'FACTORY'=>'', 'BILLET'=>'', 'DE'=>'', 'trade.s.r.o.'=>'', 'TRADE.S.R.O.'=>'', /*'+'=>'',*/ 'GMBH+'=>'','GMBH&Co.K'=>'',
    'GMBH+'=>'','GMBH&CO.K'=>'','NV/SA'=>'','Nv/Sa'=>'', 'S.O.P'=>'','S.A.R.L.'=>'','S.L'=>'',/*'ЮЕЙ'=>'',*/'ТММ'=>'',
    'LP'=>'','L.P.'=>'','L.P'=>'','(LTDA)'=>'','OOO'=>'','–'=>'','ZRT'=>'','UA'=>'','SC'=>'','SB'=>'','O.O.,'=>'','Z.O.O.,'=>'','ZO.O.,'=>'',
    'SP.Z.O.O.'=>'','SP'=>'','GES.M.B.H.'=>'','.'=>'',','=>'','SP.K'=>'','('=>'',')'=>'','FOR'=>'','TRAIDING'=>'','(PPL)'=>'','PPL'=>'','P.P.L.'=>'',
    'P.P.L'=>'','S.O.P.'=>'','F.Z.E.'=>'','(W.L.L.)'=>'','FZ'=>'','SDN'=>'','SDN,'=>'','BHD'=>'','S.L.U.'=>'','S.L.U'=>'','SLU'=>'','CO.,LTD'=>'',
    'CO.LTD'=>'','-GMBH'=>'','(UK)'=>'','S.C.'=>'','B-D'=>'','Dubai'=>'','Rep.'=>'','Office'=>'','LLP'=>'','ТММ'=>'','CORPORATION'=>'',
    'SAGA,'=>'SAGA', 'C.V.'=>'','SP.'=>'','K.'=>'','SP.K'=>'','КОРПОРАЦИЯ'=>'','КОМПАНИ'=>'', 'ЛИМИТЕД'=>'','КОМБИНАТ'=>'','КОМБІНАТ'=>'','ЗАВОД'=>'',
    'ХОЛДІНГОВА'=>'','ХОЛДИНГОВА'=>'','ХОЛДИНГОВАЯ'=>'','ХОЛДІНГОВИЙ'=>'','ХОЛДИНГОВИЙ'=>'','ХОЛДИНГОВЫЙ'=>'','ЧАО'=>'','D.D.'=>'',
    /*'GENERAL'=>'', 'TRADING'=>'',*/'CONTRACTING'=>'','STE'=>'','?ELIK'=>'','?TI.'=>'','JPL'=>'','ENG.'=>'','TU'=>'','AD'=>'',
    'RBC'=>'','J.S.C'=>'','CJSC'=>'','V.V.'=>'','MAKAROV'=>'','N.A.'=>'','CORP'=>'','PLANT'=>'','L'=>'','C'=>'','LLC-OCTG'=>'','CO.,'=>'',
    'FOR'=>'', 'A/C'=>'','MATERIALS'=>'','ENGINEE'=>'','BROS'=>'','ZAVODU'=>'','IND.'=>'', 'OY'=>'', 'MUS.TIC.LTD.STI.'=>'',
    'HOLDING'=>'', 'D.O.O'=>'', 'M'=>'', 'LP'=>'','SARL'=>'','KSC'=>'','U.S.A.'=>'','BORU'=>'','CA'=>'', 'СА'=>'',
    'AND'=>'', 'UND'=>'', 'ET'=>'','JV'=>'','M/S'=>'','MTZ'=>'','CZ'=>'','ВСМПО'=>'','J.'=>'', 'TAAH.'=>'', 'SAN'=>'',
    'OTOMOTIV' => '', 'SAVUNMA' => '', 'PJSC'=>'', 'SV'=>'', 'KOMPANI'=>'', 'ХО'=>'', 'МУП'=>'', 'І'=>'', 'КО'=>'',
    'ЛНОЕ'=>'', 'ПАРТНЕРСТВО'=>'', 'ГУСЕЙНОВА'=>'', 'САВАЛАНА'=>'', 'ЙОЛЧУ'=>'', 'ОГЛЫ'=>'', 'И'=>'', 'ЕГО'=>'', 'ПАРТНЕРОВ'=>'',
    'OPERATING'=>'', 'ОПЕРЕЙТИНГ'=>'', 'S.A.S'=>'', 'S.A.O.G.'=>'','FACTORIES'=>'','G.P.'=>'', 'CFL'=>'',
    'SDN.'=>'','BHD.'=>'','SDN'=>'','BHD'=>'','STI.'=>''
    /*'San. ve Tic. A.Ş.'=>'', 'SAN. VE TIC. A.Ş.'=>'',*/
    };  

    //--- Мапа самотніх символів, які треба видалити
    public static final Map<String, String> TRASH_LETTERS = new Map<String, String>{
        'A'=>'', 'N'=>'', 'А'=>'', 'Н'=>'', 'Ъ'=>'',
        'B'=>'', 'O'=>'', 'Б'=>'', 'О'=>'', 'Ы'=>'',
        'C'=>'', 'P'=>'', 'В'=>'', 'П'=>'', 'Ь'=>'',
        'D'=>'', 'Q'=>'', 'Г'=>'', 'Р'=>'', 'Э'=>'',
        'E'=>'', 'R'=>'', 'Д'=>'', 'С'=>'', 'Ю'=>'',
        'F'=>'', 'S'=>'', 'Е'=>'', 'Т'=>'', 'Я'=>'',
        'G'=>'', 'T'=>'', 'Ж'=>'', 'У'=>'', 'Ґ'=>'',
        'H'=>'', 'U'=>'', 'З'=>'', 'Ф'=>'', 'Є'=>'',
        'I'=>'', 'V'=>'', 'И'=>'', 'Х'=>'', 'Ї'=>'',
        'J'=>'', 'W'=>'', 'Й'=>'', 'Ц'=>'', 
        'K'=>'', 'X'=>'', 'К'=>'', 'Ч'=>'', 
        'L'=>'', 'Y'=>'', 'Л'=>'', 'Ш'=>'', 
        'M'=>'', 'Z'=>'', 'М'=>'', 'Щ'=>''
    };

    // Мапа варіантів написання специфічних символів або діакритики
    public static final Map<String, List<String>> REPLACEMENTS = new Map<String, List<String>>{
        // German umlauts and variants
        'ö' => new List<String>{'ö', 'oe', 'o', 'ø'}, 'Ö' => new List<String>{'Ö', 'OE', 'O', 'Ø'},
        'ü' => new List<String>{'ü', 'ue', 'u'},      'Ü' => new List<String>{'Ü', 'UE', 'U'},
        'ä' => new List<String>{'ä', 'ae', 'a'},      'Ä' => new List<String>{'Ä', 'AE', 'A'},

        // Scandinavian
        'ø' => new List<String>{'ø', 'ö', 'oe', 'o'}, 'Ø' => new List<String>{'Ø', 'Ö', 'OE', 'O'},
        'å' => new List<String>{'å', 'a'},            'Å' => new List<String>{'Å', 'A'},
        'æ' => new List<String>{'æ', 'ae', 'e'},      'Æ' => new List<String>{'Æ', 'AE', 'E'},

        // French
        'é' => new List<String>{'é', 'e'},            'É' => new List<String>{'É', 'E'},
        'è' => new List<String>{'è', 'e'},            'È' => new List<String>{'È', 'E'},
        'ê' => new List<String>{'ê', 'e'},            'Ê' => new List<String>{'Ê', 'E'},
        'ë' => new List<String>{'ë', 'e'},            'Ë' => new List<String>{'Ë', 'E'},
        'ç' => new List<String>{'ç', 'c'},            'Ç' => new List<String>{'Ç', 'C'},

        // Dutch/Flemish
        'ij' => new List<String>{'ij', 'y', 'i'},
        'IJ' => new List<String>{'IJ', 'Y', 'I'},
        'oe' => new List<String>{'oe','ö', 'ø'},
        'OE' => new List<String>{'OE','Ö', 'Ø'},

        // Polish/Czech/Slovak/Slovenian
        'ś' => new List<String>{'ś', 's'},            'Ś' => new List<String>{'Ś', 'S'},
        'ł' => new List<String>{'ł', 'l'},            'Ł' => new List<String>{'Ł', 'L'},
        'ć' => new List<String>{'ć', 'c'},            'Ć' => new List<String>{'Ć', 'C'},
        'ń' => new List<String>{'ń', 'n'},            'Ń' => new List<String>{'Ń', 'N'},
        'ź' => new List<String>{'ź', 'z'},            'Ź' => new List<String>{'Ź', 'Z'},
        'ż' => new List<String>{'ż', 'z'},            'Ż' => new List<String>{'Ż', 'Z'},
        'č' => new List<String>{'č', 'c'},            'Č' => new List<String>{'Č', 'C'},
        'š' => new List<String>{'š', 's'},            'Š' => new List<String>{'Š', 'S'},
        'ž' => new List<String>{'ž', 'z'},            'Ž' => new List<String>{'Ž', 'Z'},

        // Romanian
        'ă' => new List<String>{'ă', 'a'},            'Ă' => new List<String>{'Ă', 'A'},
        'ș' => new List<String>{'ș', 's'},            'Ș' => new List<String>{'Ș', 'S'},
        'ţ' => new List<String>{'ţ', 't'},            'Ţ' => new List<String>{'Ţ', 'T'}
    };

    // Мапа відповідників діакритики й стандартної латинки
    public static final Map<String, String> DIACR_LATIN = new Map<String, String>{
        'Ö' => 'O', 'Ü' => 'U', 'Ä' => 'A', 'Ø' => 'O', 'Å' => 'A', 'Æ' => 'E',
        'É' => 'E', 'È' => 'E', 'Ê' => 'E', 'Ë' => 'E', 'Ç' => 'C', 'Ś' => 'S',
        'Ł' => 'L', 'Ć' => 'C', 'Ń' => 'N', 'Ź' => 'Z', 'Ż' => 'Z', 'Č' => 'C',
        'Š' => 'S', 'Ž' => 'Z', 'Ă' => 'A', 'Ș' => 'S', 'Ţ' => 'T'        
    };

    // Мапа дифтонгів
    public static final Map<String, String> DIPHTHONGS = new Map<String, String>{
        'AE' => 'E', 'OE' => 'O', 'UE' => 'U'
    };

    // Синоніми
    public static final Map<String, List<String>> SAME_WORDS = new Map<String, List<String>>{
        'INTERNATIONAL' => new List<String>{'INTERNATION', 'INTERNATIONAL'},
        'INTERNATION' => new List<String>{'INTERNATION', 'INTERNATIONAL'},
        'TUBE' => new List<String>{'TUBE', 'TUBES'},
        'TUBES' => new List<String>{'TUBE', 'TUBES'},
        'PIPE' => new List<String>{'PIPE', 'PIPES'},
        'PIPES' => new List<String>{'PIPE', 'PIPES'},
        'SERVICES' => new List<String>{'SERVICES', 'SERVICE'},
        'SERVICE' => new List<String>{'SERVICES', 'SERVICE'},
        'SUPPLIES' => new List<String>{'SUPPLIES', 'SUPPLY'},
        'SUPPLY' => new List<String>{'SUPPLIES', 'SUPPLY'},
        'MATERIAL' => new List<String>{'MATERIAL', 'MATERIALS'},
        'MATERIALS' => new List<String>{'MATERIAL', 'MATERIALS'},
        'BAHAR' => new List<String>{'BAHAR', 'БАХАР'},
        'БАХАР' => new List<String>{'БАХАР', 'BAHAR'},
        'КОМПАНИ'=>new List<String>{'КОМПАНИ','COMPANY','КОМПАНІ'},
        'COMPANY'=>new List<String>{'COMPANY','КОМПАНИ','КОМПАНІ'},
        'КОМПАНІ'=>new List<String>{'КОМПАНІ','КОМПАНИ','COMPANY'},
        'ЛИМИТЕД'=>new List<String>{'ЛИМИТЕД','LIMITED','ЛІМІТЕД'},
        'LIMITED'=>new List<String>{'LIMITED','ЛИМИТЕД','ЛІМІТЕД'},
        'ЛІМІТЕД'=>new List<String>{'ЛІМІТЕД','ЛИМИТЕД','LIMITED'},
        'ПЕТРОЛЕУМ' => new List<String>{'ПЕТРОЛЕУМ', 'PETROLEUM'},
        'PETROLEUM' => new List<String>{'PETROLEUM', 'ПЕТРОЛЕУМ'},
        'КОРПОРЕЙШН' => new List<String>{'КОРПОРЕЙШН', 'CORPORATION'},
        'CORPORATION' => new List<String>{'CORPORATION', 'КОРПОРЕЙШН'},
        'РЫБИНСКИЙ' => new List<String>{'РЫБИНСКИЙ', 'РЫБНИЦКИЙ'},
        'РЫБНИЦКИЙ' => new List<String>{'РЫБНИЦКИЙ', 'РЫБИНСКИЙ'},
        'rør' => new List<String>{'rør', 'ror', 'roer', 'rör'},
        'RØR' => new List<String>{'RØR', 'ROR', 'ROER', 'RÖR'},
        'roer' => new List<String>{'roer', 'rør', 'ror', 'rör'},
        'ROER' => new List<String>{'ROER', 'RØR', 'ROR', 'RÖR'},
        'rör' => new List<String>{'rör', 'ror', 'roer', 'rør'},
        'RÖR' => new List<String>{'RÖR', 'ROR', 'ROER', 'RØR'},
        'ror' => new List<String>{'ror', 'roer', 'rør', 'rör'},
        'ROR' => new List<String>{'ROR', 'ROER', 'RØR', 'RÖR'},
        'rur' => new List<String>{'rur','ror', 'roer', 'rør', 'rör'},
        'RUR' => new List<String>{'RUR','ROR', 'ROER', 'RØR', 'RÖR'},        
        'HELENS' => new List<String>{'HELENS', 'HELÉNS', 'HÉLENS', 'HÉLÉNS'},
        'münchen' => new List<String>{'münchen', 'muenchen', 'munchen'},
        'MÜNCHEN' => new List<String>{'MÜNCHEN', 'MUENCHEN', 'MUNCHEN'},
        'ENERGY'=>new List<String>{'ENERGY', 'ЭНЕРДЖИ'},
        'ЭНЕРДЖИ'=>new List<String>{'ЭНЕРДЖИ', 'ENERGY'},
        'ОПЕРЕЙТИНГ'=>new List<String>{'OPERATING','ОПЕРЕЙТИНГ'},
        'OPERATING'=>new List<String>{'OPERATING','ОПЕРЕЙТИНГ'},
        'ЗАВОД' =>new List<String>{'ЗАВОД','КОМБИНАТ'},
        'КОМБИНАТ'=>new List<String>{'КОМБИНАТ','ЗАВОД'},
        'IRAQUE'=> new List<String>{'IRAQUE','IRAQ'},
        'IRAQ'=> new List<String>{'IRAQ','IRAQUE'},
        '&'=> new List<String>{'&','AND'},
        'AND'=> new List<String>{'AND','&'},
        'J.S.C.'=> new List<String>{'J.S.C.','JSC'},
        'JSC'=> new List<String>{'J.S.C.','JSC'},
        'ФЄМАТЕК'=> new List<String>{'ФЄМАТЕК','ФЕМАТЭК'},
        'ФЕМАТЭК'=> new List<String>{'ФЄМАТЕК','ФЕМАТЭК'},        
        'УКРАЇНСЬКИЙ'=> new List<String>{'УКРАЇНСЬКИЙ','УКРАИНСКИЙ'},
        'УКРАИНСКИЙ'=> new List<String>{'УКРАИНСКИЙ','УКРАЇНСЬКИЙ'},        
        'ТРАНССЄРВІС'=> new List<String>{'ТРАНССЄРВІС','ТРАНССЕРВИС'},
        'ТРАНССЕРВИС'=> new List<String>{'ТРАНССЕРВИС','ТРАНССЄРВІС'},        
        'СЄРВІС'=> new List<String>{'СЄРВІС','СЕРВИС','СЕРВИС'},
        'СЕРВИС'=> new List<String>{'СЕРВИС','СЄРВІС','СЕРВИС'},
        'СЕРВІС'=> new List<String>{'СЕРВИС','СЄРВІС','СЕРВИС'},        
        'ТЕХНОЛОДЖІС'=> new List<String>{'ТЕХНОЛОДЖІС','ТЕХНОЛОДЖИС'},
        'ТЕХНОЛОДЖИС'=> new List<String>{'ТЕХНОЛОДЖИС','ТЕХНОЛОДЖІС'},        
        'ЭНЕРГО'=> new List<String>{'ЭНЕРГО','ЕНЕРГО'},
        'ЕНЕРГО'=> new List<String>{'ЕНЕРГО','ЭНЕРГО'},        
        'СТАЛЬІНВЕСТ'=> new List<String>{'СТАЛЬІНВЕСТ','СТІЛІНВЕСТ'},
        'СТІЛІНВЕСТ'=> new List<String>{'СТІЛІНВЕСТ','СТАЛЬІНВЕСТ'},        
        'ПРОФИЛЬ'=> new List<String>{'ПРОФИЛЬ','ПРОФАЙЛ'},
        'ПРОФАЙЛ'=> new List<String>{'ПРОФАЙЛ','ПРОФИЛЬ'},        
        'ПРЕМЬЕР'=> new List<String>{'ПРЕМЬЕР','ПРЕМЄР','СЕРВИС'},
        'ПРЕМ\'ЄР'=> new List<String>{'ПРЕМ\'ЄР','ПРЕМЄР', 'ПРЕМЬЕР'},
        'ПРЕМЄР'=> new List<String>{'ПРЕМЄР','ПРЕМ\'ЄР', 'ПРЕМЬЕР'},       
        'УКРАИНА'=> new List<String>{'УКРАИНА','УКРАЇНА'},
        'УКРАЇНА'=> new List<String>{'Профайл','УКРАИНА'},
        'KONIGFRANKSTAHL'=> new List<String>{'KONIGFRANKSTAHL','KOENIGFRANKSTAHL','KOENGFRANKSTAHL','KÖNIGFRANKSTAHL'},
        'KOENIGFRANKSTAHL'=> new List<String>{'KONIGFRANKSTAHL','KOENIGFRANKSTAHL','KOENGFRANKSTAHL','KÖNIGFRANKSTAHL'},
        'KOENGFRANKSTAHL'=> new List<String>{'KONIGFRANKSTAHL','KOENIGFRANKSTAHL','KOENGFRANKSTAHL','KÖNIGFRANKSTAHL'},
        'KÖNIGFRANKSTAHL'=> new List<String>{'KONIGFRANKSTAHL','KOENIGFRANKSTAHL','KOENGFRANKSTAHL','KÖNIGFRANKSTAHL'},        
        'KONIG'=> new List<String>{'KONIG','KOENIG','KÖNIG','KOENG'},
        'KOENIG'=> new List<String>{'KONIG','KOENIG','KÖNIG','KOENG'},
        'KÖNIG'=> new List<String>{'KONIG','KOENIG','KÖNIG','KOENG'},
        'KOENG'=> new List<String>{'KONIG','KOENIG','KÖNIG','KOENG'},
        'МЕХАНИК'=> new List<String>{'МЕХАНИК','МЕХАНІК'},  
        'МЕХАНІК'=> new List<String>{'МЕХАНІК','МЕХАНИК'},        
        'GORGIA'=> new List<String>{'GORGIA','GEORGIA'},  
        'GEORGIA'=> new List<String>{'GORGIA','GEORGIA'},
        'ТИРОТЕКС'=> new List<String>{'ТИРОТЕКС','ТИРОТЕКС-ЭНЕРГО'},  
        'ТИРОТЕКС-ЭНЕРГО'=> new List<String>{'ТИРОТЕКС-ЭНЕРГО','ТИРОТЕКС'}                     
    };

    // Додаткове сміття типу "AND"
    public static final Map<String, String> TRASH_AND;
    static {
        TRASH_AND = new Map<String, String>();
        //TRASH_AND.put(' & ', ' ');
        TRASH_AND.put(' \\+', ' ');
        TRASH_AND.put(' \\+ ', ' ');
        //TRASH_AND.put('&', ' ');
        TRASH_AND.put('\\+', ' ');
        TRASH_AND.put(' and ', ' ');
        TRASH_AND.put(' und ', ' ');
        TRASH_AND.put(' et ', ' ');
        TRASH_AND.put(' AND ', ' ');
        TRASH_AND.put(' UND ', ' ');
        TRASH_AND.put(' ET ', ' ');
    }
    
    // Сет інших символів
    public static final Set<String> TRASH_SIGNS= new Set<String>{
        '&', '?', '!', '.', ',', '”', '\'', '»', '$', '#', '*', '§', '+', '@'
    };    

    // Мапа для діакритики
    public static final Map<String, String> DIACRITICS_MAP = new Map<String, String>{
        'A' => 'ÀÁÂÃÄÅĀĄĂ',
        'C' => 'ÇĆČĈĊ',
        'D' => 'ĎĐ',
        'E' => 'ÈÉÊËĒĘĚĔĖ',
        'G' => 'ĞĠĢĜ',
        'H' => 'ĤĦ',
        'I' => 'ÌÍÎÏĪĨĬĮİ',
        'J' => 'Ĵ',
        'K' => 'Ķ',
        'L' => 'ŁĽĹĻĿ',
        'N' => 'ŃÑŇŅŊ',
        'O' => 'ÒÓÔÕÖØŌŐŎ',
        'R' => 'ŘŔŖ',
        'S' => 'ŠŚŞŜȘ',
        'T' => 'ŤŢŦȚ',
        'U' => 'ÙÚÛÜŪŮŰŬŨŲ',
        'W' => 'Ŵ',
        'Y' => 'ÝŶŸ',
        'Z' => 'ŹŽŻ'
    };  
    
    public static final Set<String> DOMAIN_SUFFIXES = new Set<String>{
        'com', 'ua', 'ae', 'fr', 'pl', 'de', 'it', 'net', 'org', 'biz',
        'ru', 'by', 'cz', 'co', 'us', 'in', 'es', 'nl', 'be', 'dk', 'se',
        'fi', 'no', 'ch', 'uk', 'me', 'tv', 'xyz', 'io', 'info', 'gov'
    };    

    // Ключ — патерн у нижньому регістрі, значення — що вставити замість
    public static final Map<String, String> brandFixes = new Map<String, String>{
        'batifer tubes, profiles and tools' => 'batifer',       
        'petro gas'       => 'petrogas',
        'perma pipe'      => 'permapipe',
        'perma-pipe'      => 'permapipe',
        'marubeni itochu' => 'marubeniitochu',
        'marubeni-itochu' => 'marubeniitochu',
        'ets elias'       => 'etselias',
        'ets.elias'       => 'etselias',
        'steel force'     => 'steelforce',
        'pm piping'       => 'pmpiping',
        'az-servis'       => 'azservis',
        'pipe-rolling'    => 'piperolling',
        'b&l pipeco'      => 'pipeco',
        'b2 build'        => 'b2build',
        'armapol-stal'    => 'armapolstal',
        'basatl? pipe'    => 'basatlipipe',
        'basatli pipe'    => 'basatlipipe',
        'be group'        => 'begroup',
        'bg steel'        => 'bgsteel',
        'bk garant'       => 'bkgarant',
        'boly pipe'       => 'bolypipe',
        'bpm-trade'       => 'bpmtrade',
        'bps supply'      => 'bpssupply',
        'bri-steel'       => 'bristeel',
        'bta pipe'        => 'btapipe',
        'c & f international' => 'cfiinternational',
        'c&f international'   => 'cfiinternational',
        'c & r industries' => 'crindustries',
        'c&r industries'   => 'crindustries',
        'c+r hydraulics'   => 'crhydraulics',
        'cal-sierra'       => 'calsierra',
        'cp international' => 'cpinternational',
        'ct&i' => 'cti',
        'cu.ma.' => 'cuma',
        'cuu long' => 'cuulong',
        'd\'amore' => 'damore',
        'd\'aparecida' => 'daparecida',
        'd\''=>'d', '\'s'=>'s', 'l\''=>'l',
        'de-rail' => 'derail',
        'dh-nst' => 'dhnst',
        'di natale' => 'dinatale',
        'e. f. c. acciai' => 'efcacciai',
        'eco-tech' => 'ecotech',
        's-market' => 'smarket',
        'м-арматура' => 'марматура',
        'ас інвестмент' => 'асінвестмент',
        'мотор-сич'  => 'моторсіч', 
        'мотор сич'  => 'моторсіч', 
        'мотор-січ'  => 'моторсіч', 
        'мотор січ'  => 'моторсіч',  
        'механик'  => 'механік',  
        'а групп'  => 'агрупп',
        'a grupp' => 'agrupp', 
        'а-сталь'  => 'асталь',   
        'м-сталь'  => 'мсталь',    
        'steel-м'  => 'steelм', 
        'pesquisa produo' => 'p&p',
        'a+r profilstahl' => 'arprofilstahl',
        'r & w machine' => 'rwmachine',
        'r3 steel' => 'r3steel',
        'raven,a.s.' => 'raven',
        'a-tech' => 'atech',
        'a&r '=>'ar',
        'a.d.r.' => 'adr',
        'a.l.t.a.' => 'alta',
        'a+r' => 'ar',
        'atir-rail' => 'atirrail',
        'avliga-d' => 'avligad',
        'b&l pipeco' => 'blpipeco',
        'be group' => 'begroup',
        'bg steel' => 'bgsteel',
        'bhd tubular' => 'bhdtubular',
        'supply,' => 'supply',
        'f.h mirra' => 'fhmirra',
        'k-energy' => 'kenergy',
        'konig frankstahl' => 'konigfrankstahl',
        'könig stahl' => 'konigstahl',
        'koenigfrankstahl' => 'konigfrankstahl',
        'koeng frankstahl' => 'konigfrankstahl',
        'ld steel' => 'ldsteel',
        'x steel' => 'xsteel',
        'met-invest' => 'metinvest',
        'met invest' => 'metinvest',
        'металика-зуев' => 'мetalikazuev',
        'мetalika-zuev' => 'мetalikazuev',
        'bri-steel' => 'bristeel',        
        'pesquisa e produ??o' => 'p&p',
        'p.van' => 'van',
        'vanleeuwen.fr' => 'van leeuwen',
        'palfinger.com' => 'palfinger',
        'turboatom.com.ua' => 'turboatom',
        'strojopromet-zagreb' => 'strojopromet',
        't machinery' => 'tmachinery',
        'tejas tubular products' => 'tejastubular',
        'tejas tubular' => 'tejastubular',
        'trouvey & cauvin.' => 'trouveycauvin',
        'trouvay & cauvin' => 'trouveycauvin',
        'tubos mecanicos norte s.a.' => 'tubosmecanicos',
        'tubos mecanicos s.a.' => 'tubosmecanicos',
        'unipipe.ae' => 'unipipe',
        'vam drilling france' => 'vamdrilling',
        'vam drilling' => 'vamdrilling',
        'vista pipe & supply, llc' => 'vistapipe',
        'vista pipe' => 'vistapipe',
        'voestalpine rotec gmbh' => 'voestalpine',
        'voestalpine ag' => 'voestalpine',
        'євразтрейд груп тов' => 'євразтрейд',
        'євразтрейд тов' => 'євразтрейд',
        //'титан україна/трубний всмпо-авісма філія всмпо-титан україна' => 'титанукраїна',
        //'титан україна' => 'титанукраїна',
        'group.'=>'', 'b & w pipe'=>'bwpipe', 'r & d pipe'=>'rdpipe',
        'днепровский трубный завод ооо' => 'dnipropipefactory',
        'дніпропетровський трубний завод тов тд' => 'dnipropipefactory',
        'дніпропетровська трубна компанія тов' => 'dnipropipefactory',
        'лукойл узбекистан оперейтинг компани тов' => 'лукойл узбекистан',
        'лукойл-узбекистан' => 'лукойл узбекистан',
        'operey?n' => '', 'opereyn'=>'', 'государств.'=>'',
        'государств.'=>'', 'азербайдж.'=>'азербайджан', 'ай бі сі дженерал'=>'ibc general',
        'государственная'=>'', 'интербурсервис'=>'interburservis', 'ав метал' => 'avmetal',
        'интерпайп'=>'interpipe', 'інтерпайп'=>'interpipe', 'мет-ак'=>'metak', 'аб енерго'=>'abenergo',
        'юа'=>'ua', 'юей'=>'ua', 'юэй'=>'ua','дюна-с'=>'dunas','сг-'=>'',
        //'филиал компании каймановых островов karasu operating company' => 'KARASU KAYMAN',
        //'филиал компании каймановых островов karasu' => 'KARASU KAYMAN',
        //'филиал компании каймановых островов karasu company филиал karasu'=> 'KARASU KAYMAN',
        //'филиал karasu operating company' => '', 
        'pesquisa e produo' => 'p&p',
        'рыбинский'=>'RYBNITSKIY', 'рыбницкий'=>'RYBNITSKIY'
    };    
    //--- Сет назв країн
    public static Set<String> COUNTRY_SET = new Set<String>{
        'AFGHANISTAN', 'АФГАНІСТАН', 'АФГАНИСТАН',
        'ALBANIA', 'АЛБАНІЯ', 'АЛБАНИЯ',
        'ALGERIA', 'АЛЖИР',
        'ANGUILLA', 'АНГІЛЬЯ', 'АНГИЛЬЯ',
        'ARGENTINA', 'АРГЕНТИНА',
        'AUSTRALIA', 'АВСТРАЛІЯ', 'АВСТРАЛИЯ',
        'AUSTRIA', 'АВСТРІЯ', 'АВСТРИЯ',
        'AZERBAIJAN', 'АЗЕРБАЙДЖАН',
        'BAHRAIN', 'БАХРЕЙН',
        'BANGLADESH', 'БАНГЛАДЕШ',
        'BELARUS', 'БІЛОРУСЬ', 'БЕЛОРУСЬ',
        'BELGIUM', 'БЕЛЬГІЯ', 'БЕЛЬГИЯ',
        'BELIZE', 'БЕЛІЗ', 'БЕЛИЗ',
        'BOLIVIA', 'БОЛІВІЯ', 'БОЛИВИЯ',
        'BOSNIA', 'БОСНІЯ', 'БОСНИЯ',
        'BRAZIL', 'БРАЗИЛІЯ', 'БРАЗИЛИЯ',
        'BULGARIA', 'БОЛГАРІЯ', 'БОЛГАРИЯ',
        'CANADA', 'КАНАДА',
        'CAPE VERDE', 'КАБО-ВЕРДЕ',
        'CHILE', 'ЧИЛІ', 'ЧИЛИ',
        'CHINA', 'КИТАЙ',
        'CHINESE TAIPEI', 'ТАЙВАНЬ','TAIWAN',
        'COLOMBIA', 'КОЛУМБІЯ', 'КОЛУМБИЯ',
        'CROATIA', 'ХОРВАТІЯ', 'ХОРВАТИЯ',
        'CYPRUS', 'КІПР', 'КИПР',
        'CZECH', 'ЧЕХІЯ', 'ЧЕХИЯ',
        'DENMARK', 'ДАНІЯ', 'ДАНИЯ',
        'ECUADOR', 'ЕКВАДОР',
        'EGYPT', 'ЄГИПЕТ', 'ЕГИПЕТ',
        'ESTONIA', 'ЕСТОНІЯ', 'ЭСТОНИЯ',
        'FINLAND', 'ФІНЛЯНДІЯ', 'ФИНЛЯНДИЯ',
        'FRANCE', 'ФРАНЦІЯ', 'ФРАНЦИЯ',
        'GABON', 'ГАБОН',
        'GEORGIA', 'ГРУЗІЯ', 'ГРУЗИЯ',
        'GERMANY', 'DEUTSCHLAND','НІМЕЧЧИНА', 'ГЕРМАНИЯ',
        'GIBRALTAR', 'ГІБРАЛТАР', 'ГИБРАЛТАР',
        'GREECE', 'ГРЕЦІЯ', 'ГРЕЦИЯ',
        'GUINEA', 'ГВІНЕЯ', 'ГВИНЕЯ',
        'HUNGARY', 'УГОРЩИНА', 'ВЕНГРИЯ',
        'INDIA', 'ІНДІЯ', 'ИНДИЯ',
        'INDONESIA', 'ІНДОНЕЗІЯ', 'ИНДОНЕЗИЯ',
        'IRAN', 'ІРАН', 'ИРАН',
        'IRAQ', 'IRAQUE','ІРАК', 'ИРАК',
        'IRELAND', 'ІРЛАНДІЯ', 'ИРЛАНДИЯ',
        'ISRAEL', 'ІЗРАЇЛЬ', 'ИЗРАИЛЬ',
        'ITALY', 'ІТАЛІЯ', 'ИТАЛИЯ',
        'JAPAN', 'ЯПОНІЯ', 'ЯПОНИЯ',
        'JORDAN', 'ЙОРДАНІЯ', 'ИОРДАНИЯ',
        'KAZAKHSTAN', 'КАЗАХСТАН',
        'KENYA', 'КЕНІЯ', 'КЕНИЯ',
        'KOREA', 'КОРЕЯ',
        'KUWAIT', 'КУВЕЙТ',
        'KYRGYZSTAN', 'КИРГИЗСТАН',
        'LATVIA', 'ЛАТВІЯ', 'ЛАТВИЯ',
        'LEBANON', 'ЛІВАН', 'ЛИВАН',
        'LIBYA', 'ЛІВІЯ', 'ЛИВИЯ',
        'LITHUANIA', 'ЛИТВА',
        'LUXEMBOURG', 'ЛЮКСЕМБУРГ',
        'MALAYSIA', 'МАЛАЙЗІЯ', 'МАЛАЙЗИЯ',
        'MAURITANIA', 'МАВРИТАНІЯ', 'МАВРИТАНИЯ',
        'MEXICO', 'МЕКСИКА',
        'MOLDOVA', 'МОЛДОВА',
        'MONGOLIA', 'МОНГОЛІЯ', 'МОНГОЛИЯ',
        'MONTENEGRO', 'ЧОРНОГОРІЯ', 'ЧЕРНОГОРИЯ',
        'MOROCCO', 'МАРОККО',
        'MYANMAR', 'М\'ЯНМА', 'МЬЯНМА',
        'NETHERLANDS', 'НІДЕРЛАНДИ', 'НИДЕРЛАНДЫ',
        'NEW ZEALAND', 'НОВА ЗЕЛАНДІЯ', 'НОВАЯ ЗЕЛАНДИЯ',
        'NIGERIA', 'НІГЕРІЯ', 'НИГЕРИЯ',
        'NORWAY', 'НОРВЕГІЯ', 'НОРВЕГИЯ',
        'OMAN', 'ОМАН',
        'PAKISTAN', 'ПАКИСТАН',
        'PANAMA', 'ПАНАМА',
        'POLAND', 'POLSKA','ПОЛЬЩА', 'ПОЛЬША',
        'PORTUGAL', 'ПОРТУГАЛІЯ', 'ПОРТУГАЛИЯ',
        'QATAR', 'КАТАР',
        'ROMANIA', 'РУМУНІЯ', 'РУМЫНИЯ',
        'RUSSIA', 'РОСІЯ', 'РОСИЯ',
        'SAN MARINO', 'САН-МАРІНО', 'САН-МАРИНО',
        'SAUDI ARABIA', 'САУДІВСЬКА АРАВІЯ', 'САУДОВСКАЯ АРАВИЯ',
        'SERBIA', 'СЕРБІЯ', 'СЕРБИЯ',
        'SINGAPORE', 'СІНГАПУР', 'СИНГАПУР',
        'SLOVAKIA', 'СЛОВАЧЧИНА', 'СЛОВАКИЯ',
        'SLOVENIA', 'СЛОВЕНІЯ', 'СЛОВЕНИЯ',
        'SOUTH AFRICA', 'ПІВДЕННА АФРИКА', 'ЮАР',
        'SPAIN', 'ІСПАНІЯ', 'ИСПАНИЯ',
        'SRI LANKA', 'ШРІ-ЛАНКА', 'ШРИ-ЛАНКА',
        'SWEDEN', 'ШВЕЦІЯ', 'ШВЕЦИЯ',
        'SWITZERLAND', 'ШВЕЙЦАРІЯ', 'ШВЕЙЦАРИЯ',
        'SYRIA', 'СИРІЯ', 'СИРИЯ',
        'TAJIKISTAN', 'ТАДЖИКИСТАН',
        'THAILAND', 'ТАЇЛАНД', 'ТАИЛАНД',
        'TUNISIA', 'ТУНІС', 'ТУНИС',
        'TURKEY', 'ТУРЕЧЧИНА', 'ТУРЦИЯ',
        'TURKMENISTAN', 'ТУРКМЕНІСТАН', 'ТУРКМЕНИСТАН',
        'UGANDA', 'УГАНДА',
        'UKRAINE', 'УКРАЇНА','УКРАИНА',
        'UAE', 'ОАЕ', 'ОАЭ',
        'UNITED KINGDOM', 'БРИТАНІЯ', 'БРИТАНИЯ','UK',
        'UNITED STATES', 'США',    'USA',
        'UZBEKISTAN', 'УЗБЕКИСТАН',
        'VIET NAM', 'В\'ЄТНАМ', 'ВЬЕТНАМ',
        'ISLANDS', 'ОСТРОВИ', 'ОСТРОВА'
    };                             
}