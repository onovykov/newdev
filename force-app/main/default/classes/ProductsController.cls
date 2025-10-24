/*** Контролер характеристик продукції ***/
public with sharing class ProductsController {    
    /***************** Типи продукції ***********************
    ********************************************************/  
    public class ProdInfo {
        public Id prodId;
        public String prodType;
        public String prodFamily;
        public String prodName;
        public String prodMaterial;

        public ProdInfo() {
            this.prodId=null;
            this.prodType='';
            this.prodFamily='';
            this.prodName='';
            this.prodMaterial='';
        }
    }

    private static Map<Id, ProdInfo> prodMapById;
    private static Map<String, ProdInfo> prodMapByErp;
    private static Boolean isLoadedProds = false;

    public static void loadAllProds() {
        if(isLoadedProds) return;
        prodMapById = new Map<Id, ProdInfo>();
        prodMapByErp = new Map<String, ProdInfo>();
        List<Product2> pList = [SELECT 
                            Id, ID_ERP__c, Type__c, Family, Name, Material__c
                          FROM Product2
                          WHERE ID_ERP__c !='0'
                          ORDER BY Type__c];
        if(!pList.isEmpty()) {
            for(Product2 p : pList) {
                ProdInfo pt = new ProdInfo();
                pt.prodId = p.Id;
                pt.prodType = p.Type__c;
                pt.prodFamily = p.Family;
                pt.prodName = p.Name;
                pt.prodMaterial = p.Material__c;

                prodMapById.put(p.Id, pt);
                prodMapByErp.put(p.ID_ERP__c, pt);
            }
        }
        isLoadedProds=true;
    }

    public static ProdInfo getProdById(Id id) {
        loadAllProds();
        return prodMapById.get(id);
    }

     public static ProdInfo getProdByErp(String erp) {
        loadAllProds();
        return prodMapByErp.get(erp);
    }   

    //--- Чистимо кеш
    public static void clearCacheProds() {
        isLoadedProds = false;
        prodMapById = null;
        prodMapByErp = null;
    }
    //--- Рефрешимо кеш
    public static void refreshProds() {
        clearCacheProds();
        loadAllProds();
    }    

    /***************** Діаметри труб **********************
    ********************************************************/
    public class TubeOD {
        public Id OD_Id;
        public Decimal OD_mm;
        public Decimal OD_inch;
        public String  OD_mm_str;
        public String  NPS;
        public String  Mark1;
        public Decimal H_mm;
        public Decimal H_inch;
        public Decimal L_mm;
        public Decimal L_inch;
        public String  ID_ERP;
        public Boolean IsRound;

        public TubeOD () {
            this.OD_Id = null;
            this.OD_mm=0.00;
            this.OD_inch=0.00;
            this.OD_mm_str='';
            this.NPS='';
            this.Mark1='';
            this.H_mm=0.00;
            this.H_inch=0.00;
            this.L_mm=0.00;
            this.L_inch=0.00;
            this.ID_ERP='';
            this.IsRound=true;
        }
    }

    private static Map<Id, Map<String, Decimal>> paramsMapOD;
    private static Map<Id, TubeOD> tubeODbyId;
    private static Map<String, TubeOD> tubeODbyErp;
    private static Set<Id> cdIdsOD = new Set<Id>();
    private static Boolean isLoadedTubeOD = false;

    public static void loadAllTubeOD() {
        if (isLoadedTubeOD && tubeODbyId != null && tubeODbyErp != null) return;

        // Використовуємо поля класу, а НЕ локальні змінні
        tubeODbyId   = new Map<Id, TubeOD>();
        tubeODbyErp  = new Map<String, TubeOD>();
        paramsMapOD    = new Map<Id, Map<String, Decimal>>();
        cdIdsOD.clear();

        // Вибираємо детальні параметри з CharactDetailValue__c
        List<CharactDetailValue__c> paramList = [
            SELECT Param__c, ParamValue__c, CharactDetail__c
            FROM CharactDetailValue__c
            WHERE CharactDetail__r.ClassifierMain__r.ExtKey__c='[Tubes][Diameter]'
            ORDER BY CharactDetail__r.Name
        ];
        // System.debug('paramList.size()=' + paramList.size());

        if (!paramList.isEmpty()) {
            for (CharactDetailValue__c r : paramList) {
                if (r.CharactDetail__c == null || String.isBlank(r.Param__c)) continue;

                cdIdsOD.add(r.CharactDetail__c);

                Map<String, Decimal> innerMap = paramsMapOD.get(r.CharactDetail__c);
                if (innerMap == null) {
                    innerMap = new Map<String, Decimal>();
                    paramsMapOD.put(r.CharactDetail__c, innerMap);
                }
                innerMap.put(r.Param__c, r.ParamValue__c);
            }
        }
        // System.debug('paramsMapOD.size()=' + paramsMapOD.size());

        // Вибираємо основні параметри з CharactDetails__c
        if (!cdIdsOD.isEmpty()) {
            List<CharactDetails__c> cdList = [
                SELECT Id, ID_ERP__c, Name, SpecAttribType__c, SpecAttrib__c
                FROM CharactDetails__c
                WHERE Id IN :cdIdsOD AND IsActive__c=true
            ];
            // System.debug('cdList.size()=' + cdList.size());

            for (CharactDetails__c cd : cdList) {
                TubeOD recTubeOD = new TubeOD();
                Map<String, Decimal> mapValues = paramsMapOD.get(cd.Id);
                recTubeOD.OD_Id = cd.Id;
                recTubeOD.ID_ERP = cd.ID_ERP__c;
                if (cd.SpecAttribType__c == 'NPS') recTubeOD.NPS = cd.SpecAttrib__c;

                if (mapValues != null) {
                    for (String param : mapValues.keySet()) {
                        Boolean isH = false;
                        Boolean isL = false;
                        Decimal v = mapValues.get(param);
                        if (param == 'D_mm') {
                            Decimal d_mm = (v == null) ? 0.00 : v.setScale(2);
                            recTubeOD.OD_mm = d_mm;
                            recTubeOD.OD_inch = ProductsHelper.mmToInches(d_mm, 3);
                            recTubeOD.Mark1 = ProductsHelper.mmToInchesFraction(d_mm);
                            //recTubeOD.OD_mm_str = 'ø'+String.valueOf(d_mm.stripTrailingZeros());
                            recTubeOD.OD_mm_str = 'ø'+ApexUtil.formatDecimal(d_mm);
                        } else if (param == 'H_mm') {
                            Decimal h_mm = (v == null) ? 0.00 : v.setScale(2);
                            recTubeOD.H_mm = h_mm;
                            recTubeOD.H_inch = ProductsHelper.mmToInches(h_mm, 3);
                            isH = true;
                        } else if (param == 'L_mm') {
                            Decimal l_mm = (v == null) ? 0.00 : v.setScale(2);
                            recTubeOD.L_mm = l_mm;
                            recTubeOD.L_inch = ProductsHelper.mmToInches(l_mm, 3);
                            isL=true;
                        }
                        if(isH && isL) recTubeOD.IsRound = false;
                    }
                }

                tubeODbyId.put(cd.Id, recTubeOD);
                // Лише якщо є ключ ERP — не кладемо null-ключі
                if (!String.isBlank(cd.ID_ERP__c)) {
                    tubeODbyErp.put(cd.ID_ERP__c, recTubeOD);
                }
            }
        }

        isLoadedTubeOD = true;
        // System.debug('tubeODbyId.size=' + tubeODbyId.size());
        // System.debug('tubeODbyErp.size=' + tubeODbyErp.size());
    }

    public static TubeOD getTubeODById(Id id) {
        loadAllTubeOD();
        return (tubeODbyId == null) ? null : tubeODbyId.get(id);
    }

    public static TubeOD getTubeODByErp(String erp) {
        loadAllTubeOD();
        if (tubeODbyErp == null) {
            // System.debug('tubeODbyErp is null');
            return null;
        }
        return tubeODbyErp.get(erp);
    }

    //--- Чистимо кеш
    public static void clearCacheTubeOD() {
        isLoadedTubeOD = false;
        tubeODbyId = null;
        tubeODbyErp = null;
        paramsMapOD = null;
        cdIdsOD.clear();
    }
    //--- Рефрешимо кеш
    public static void refreshTubeOD() {
        clearCacheTubeOD();
        loadAllTubeOD();
    }

    /***************** Стінки труб *************************
    ********************************************************/    
    public class TubeWT {
        public Id WT_Id;
        public Decimal WT_mm;
        public Decimal WT_inch;
        public String  WT_inch_str;
        public String  ID_ERP;

        public TubeWT () {
            this.WT_id = null;
            this.WT_mm=0.00;
            this.WT_inch=0.00;
            this.WT_inch_str='';
            this.ID_ERP='';
        }
    }    
    private static Map<Id, Map<String, Decimal>> paramsMapWT;
    private static Map<Id, TubeWT> tubeWTbyId;
    private static Map<String, TubeWT> tubeWTbyErp;
    private static Set<Id> cdIdsWT = new Set<Id>();
    private static Boolean isLoadedTubeWT = false;

    public static void loadAllTubeWT() {
        if (isLoadedTubeWT && tubeWTbyId != null && tubeWTbyErp != null) return;

        // Використовуємо поля класу, а НЕ локальні змінні
        tubeWTbyId   = new Map<Id, TubeWT>();
        tubeWTbyErp  = new Map<String, TubeWT>();
        paramsMapWT    = new Map<Id, Map<String, Decimal>>();
        cdIdsWT.clear();

        // Вибираємо детальні параметри з CharactDetailValue__c
        List<CharactDetailValue__c> paramList = [
            SELECT Param__c, ParamValue__c, CharactDetail__c
            FROM CharactDetailValue__c
            WHERE CharactDetail__r.ClassifierMain__r.ExtKey__c='[Tubes][Thickness]'
            ORDER BY CharactDetail__r.Name
        ];
        // System.debug('paramList.size()=' + paramList.size());

        if (!paramList.isEmpty()) {
            for (CharactDetailValue__c r : paramList) {
                if (r.CharactDetail__c == null || String.isBlank(r.Param__c)) continue;

                cdIdsWT.add(r.CharactDetail__c);

                Map<String, Decimal> innerMap = paramsMapWT.get(r.CharactDetail__c);
                if (innerMap == null) {
                    innerMap = new Map<String, Decimal>();
                    paramsMapWT.put(r.CharactDetail__c, innerMap);
                }
                innerMap.put(r.Param__c, r.ParamValue__c);
            }
        }
        // System.debug('paramsMapWT.size()=' + paramsMapWT.size());

        // Вибираємо основні параметри з CharactDetails__c
        if (!cdIdsWT.isEmpty()) {
            List<CharactDetails__c> cdList = [
                SELECT Id, ID_ERP__c, Name, SpecAttribType__c, SpecAttrib__c
                FROM CharactDetails__c
                WHERE Id IN :cdIdsWT AND IsActive__c=true
            ];
            // System.debug('cdList.size()=' + cdList.size());

            for (CharactDetails__c cd : cdList) {
                TubeWT recTubeWT = new TubeWT();
                Map<String, Decimal> mapValues = paramsMapWT.get(cd.Id);

                recTubeWT.ID_ERP = cd.ID_ERP__c;
                recTubeWT.WT_Id = cd.Id;
                if (mapValues != null) {
                    for (String param : mapValues.keySet()) {
                        Decimal v = mapValues.get(param);
                        if (param == 'WT_mm') {
                            Decimal wt_mm = (v == null) ? 0.00 : v.setScale(2);
                            recTubeWT.WT_mm = wt_mm;
                            recTubeWT.WT_inch = ProductsHelper.mmToInches(wt_mm, 3);
                            recTubeWT.WT_inch_str = +ApexUtil.formatDecimal(ProductsHelper.mmToInches(wt_mm, 3))+'W';
                        }
                    }
                }

                tubeWTbyId.put(cd.Id, recTubeWT);
                // Лише якщо є ключ ERP — не кладемо null-ключі
                if (!String.isBlank(cd.ID_ERP__c)) {
                    tubeWTbyErp.put(cd.ID_ERP__c, recTubeWT);
                }
            }
        }

        isLoadedTubeWT = true;
        // System.debug('tubeWTbyId.size=' + tubeWTbyId.size());
        // System.debug('tubeWTbyErp.size=' + tubeWTbyErp.size());
    }

    public static TubeWT getTubeWTById(Id id) {
        loadAllTubeWT();
        return (tubeWTbyId == null) ? null : tubeWTbyId.get(id);
    }

    public static TubeWT getTubeWTByErp(String erp) {
        loadAllTubeWT();
        if (tubeWTbyErp == null) {
            System.debug('tubeWTbyErp is null');
            return null;
        }
        return tubeWTbyErp.get(erp);
    }

    //--- Чистимо кеш
    public static void clearCacheTubeWT() {
        isLoadedTubeWT = false;
        tubeWTbyId = null;
        tubeWTbyErp = null;
        paramsMapWT = null;
        cdIdsWT.clear();
    }
    //--- Рефрешимо кеш
    public static void refreshTubeWT() {
        clearCacheTubeWT();
        loadAllTubeWT();
    }

    /***************** Стандарти труб **********************
    ********************************************************/ 
    public class TubeStd {
        public Id TubeStdId;
        public String StdName;
        public String StdFullName;
        public Boolean IsAcive;
        public String ID_ERP;
        public String FacetValue;

        public TubeStd() {
            this.TubeStdId = null;
            this.StdName='';
            this.StdFullName='';
            this.IsAcive=false;
            this.ID_ERP='';
            this.FacetValue = '';
        }
    }

    private static Map<Id, TubeStd> tubeStdById;
    private static Map<String, TubeStd> tubeStdByErp;
    private static Boolean isLoadedTubeStd = false;

    public static void loadAllTubeStd() {
        if (isLoadedTubeStd && tubeStdById != null && tubeStdByErp != null) return;

        // Ініціалізуємо допоміжні структури
        tubeStdById   = new Map<Id, TubeStd>();
        tubeStdByErp  = new Map<String, TubeStd>();

        // Вибираємо основні параметри з CharactDetails__c
		List<CharactDetails__c> cdList = [
			SELECT Id, ID_ERP__c, Name, SpecAttribType__c, SpecAttrib__c, IsActive__c
			FROM CharactDetails__c
			WHERE ClassifierMain__r.ExtKey__c='[Tubes][Standard]'
		];
		
        Map<Id, String> mapStdFullName = new Map<Id, String>();
        List<CharactAddAttrib__c> caList = [SELECT
                                              CharactDetail__c, AddAttribValue__c
                                            FROM CharactAddAttrib__c
                                            WHERE CharactDetail__r.ClassifierMain__r.ExtKey__c='[Tubes][Standard]' 
                                            AND AddAttribType__c='TubeStdAttrib' AND AddAttribKind__c='FullName'];
        if(!caList.isEmpty()) {
            for(CharactAddAttrib__c ca : caList) {
                mapStdFullName.put(ca.CharactDetail__c, ca.AddAttribValue__c);
            }
        }

		for (CharactDetails__c cd : cdList) {
			TubeStd recTubeStd = new TubeStd();
			recTubeStd.TubeStdId = cd.Id;
			recTubeStd.ID_ERP = cd.ID_ERP__c;
			recTubeStd.StdName = cd.Name;
			if(mapStdFullName!=null && mapStdFullName.size()>0) {
                if(mapStdFullName.containsKey(cd.Id)) recTubeStd.StdFullName = mapStdFullName.get(cd.Id);
            }
            if(cd.SpecAttribType__c=='FacetValue') recTubeStd.FacetValue= cd.SpecAttrib__c;
			recTubeStd.IsAcive = cd.IsActive__c;
			tubeStdById.put(cd.Id, recTubeStd);
			// Лише якщо є ключ ERP — не кладемо null-ключі
			if (!String.isBlank(cd.ID_ERP__c)) {
				tubeStdByErp.put(cd.ID_ERP__c, recTubeStd);
			}
		}
        isLoadedTubeStd = true;
    }

    public static TubeStd getTubeStdById(Id id) {
        loadAllTubeStd();
        return (tubeStdById == null) ? null : tubeStdById.get(id);
    }

    public static TubeStd getTubeStdByErp(String erp) {
        loadAllTubeStd();
        if (tubeStdByErp == null) {
            System.debug('tubeStdByErp is null');
            return null;
        }
        return tubeStdByErp.get(erp);
    }

    //--- Чистимо кеш
    public static void clearCacheTubeStd() {
        isLoadedTubeStd = false;
        tubeStdById = null;
        tubeStdByErp = null;
    }
    //--- Рефрешимо кеш
    public static void refreshTubeStd() {
        clearCacheTubeStd();
        loadAllTubeStd();
    } 

    /***************** Довжини труб **********************
    ********************************************************/ 
    public class TubeLen {
        public Id TubeLenId;
        public Decimal MinLen_mm;
        public Decimal MaxLen_mm;
        public Decimal MinLen_m;
        public Decimal MaxLen_m;
        public Decimal MinLen_ft;
        public Decimal MaxLen_ft;
        public String  LenType;
		public String  LenName;
        public String  ID_ERP;
		public Boolean IsActive;

        public TubeLen () {
            this.TubeLenId = null;
			this.MinLen_mm=0.00;
			this.MaxLen_mm=0.00;
			this.MinLen_m=0.00;
			this.MaxLen_m=0.00;
			this.MinLen_ft=0.00;
			this.MaxLen_ft=0.00;
			this.LenType='';
			this.LenName='';
			this.ID_ERP='';
			this.IsActive=false;
        }
    }

    private static Map<Id, Map<String, Decimal>> paramsMapLen;
    private static Map<Id, TubeLen> tubeLenById;
    private static Map<String, TubeLen> tubeLenByErp;
    private static Set<Id> cdIdsLen = new Set<Id>();
    private static Boolean isLoadedTubeLen = false;

    public static void loadAllTubeLen() {
        if (isLoadedTubeLen && tubeLenById != null && tubeLenByErp != null) return;

        // Ініціалізуємо допоміжні структури
        tubeLenById   = new Map<Id, TubeLen>();
        tubeLenByErp  = new Map<String, TubeLen>();
        paramsMapLen    = new Map<Id, Map<String, Decimal>>();
        cdIdsLen.clear();

        // Вибираємо детальні параметри з CharactDetailValue__c
        List<CharactDetailValue__c> paramList = [
            SELECT Param__c, ParamValue__c, CharactDetail__c
            FROM CharactDetailValue__c
            WHERE CharactDetail__r.ClassifierMain__r.ExtKey__c='[Tubes][LengthSize]'
            ORDER BY CharactDetail__r.Name
        ];
        // System.debug('paramList.size()=' + paramList.size());

        if (!paramList.isEmpty()) {
            for (CharactDetailValue__c r : paramList) {
                if (r.CharactDetail__c == null || String.isBlank(r.Param__c)) continue;

                cdIdsLen.add(r.CharactDetail__c);

                Map<String, Decimal> innerMap = paramsMapLen.get(r.CharactDetail__c);
                if (innerMap == null) {
                    innerMap = new Map<String, Decimal>();
                    paramsMapLen.put(r.CharactDetail__c, innerMap);
                }
                innerMap.put(r.Param__c, r.ParamValue__c);
            }
        }

        // Вибираємо основні параметри з CharactDetails__c
        if (!cdIdsLen.isEmpty()) {
            List<CharactDetails__c> cdList = [
                SELECT Id, ID_ERP__c, Name, SpecAttribType__c, SpecAttrib__c, IsActive__c
                FROM CharactDetails__c
                WHERE Id IN :cdIdsLen //AND IsActive__c=true
            ];

            for (CharactDetails__c cd : cdList) {
                TubeLen recTubeLen = new TubeLen();
                Map<String, Decimal> mapValues = paramsMapLen.get(cd.Id);
                recTubeLen.TubeLenId = cd.Id;
                recTubeLen.ID_ERP = cd.ID_ERP__c;
				recTubeLen.LenName = cd.Name;
				recTubeLen.IsActive = cd.IsActive__c;
                if (cd.SpecAttribType__c == 'LenType') recTubeLen.LenType = cd.SpecAttrib__c;

                if (mapValues != null) {
                    for (String param : mapValues.keySet()) {
                        Decimal v = mapValues.get(param);
                        if (param == 'LenMinSize') {
                            Decimal minsize_mm = (v == null) ? 0.00 : v.setScale(2);
                            recTubeLen.MinLen_mm = minsize_mm;
							recTubeLen.MinLen_m = (minsize_mm/1000.00).setScale(2);
							recTubeLen.MinLen_ft = ((minsize_mm/1000.00)/0.3048).setScale(2);
                        } else if (param == 'LenMaxSize') {
                            Decimal maxsize_mm = (v == null) ? 0.00 : v.setScale(2);
                            recTubeLen.MaxLen_mm = maxsize_mm;
							recTubeLen.MaxLen_m = (maxsize_mm/1000.00).setScale(2);
							recTubeLen.MaxLen_ft = ((maxsize_mm/1000.00)/0.3048).setScale(2);
                        }
                    }
                }
                tubeLenById.put(cd.Id, recTubeLen);
                // Лише якщо є ключ ERP — не кладемо null-ключі
                if (!String.isBlank(cd.ID_ERP__c)) {
                    tubeLenByErp.put(cd.ID_ERP__c, recTubeLen);
                }
            }
        }

        isLoadedTubeLen = true;
    }

    public static TubeLen getTubeLenById(Id id) {
        loadAllTubeLen();
        return (tubeLenById == null) ? null : tubeLenById.get(id);
    }

    public static TubeLen getTubeLenByErp(String erp) {
        loadAllTubeLen();
        if (tubeLenByErp == null) {
            return null;
        }
        return tubeLenByErp.get(erp);
    }

    //--- Чистимо кеш
    public static void clearCacheTubeLen() {
        isLoadedTubeLen = false;
        tubeLenById = null;
        tubeLenByErp = null;
        paramsMapLen = null;
        cdIdsLen.clear();
    }
    //--- Рефрешимо кеш
    public static void refreshTubeLen() {
        clearCacheTubeLen();
        loadAllTubeLen();
    }
}