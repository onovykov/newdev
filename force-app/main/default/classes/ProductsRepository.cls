public with sharing class ProductsRepository {
    // === Продукти (Product2) =================================================
    public class ProdInfo {
        public Id     prodId;
        public String prodGroup3;   // ID_ERP__c
        public String prodType;
        public String prodFamily;
        public String prodName;
        public String prodMaterial;

        public ProdInfo() {
            this.prodId=null;
            this.prodGroup3='';
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
        if (isLoadedProds) return;
        prodMapById  = new Map<Id, ProdInfo>();
        prodMapByErp = new Map<String, ProdInfo>();

        List<Product2> pList = [
            SELECT Id, ID_ERP__c, Type__c, Family, Name, Material__c
            FROM Product2
            WHERE ID_ERP__c != '0'
            ORDER BY Type__c
        ];
        for (Product2 p : pList) {
            ProdInfo pi = new ProdInfo();
            pi.prodId       = p.Id;
            pi.prodGroup3   = p.ID_ERP__c;
            pi.prodType     = p.Type__c;
            pi.prodFamily   = p.Family;
            pi.prodName     = p.Name;
            pi.prodMaterial = p.Material__c;

            prodMapById.put(p.Id, pi);
            if (p.ID_ERP__c != null) prodMapByErp.put(p.ID_ERP__c, pi);
        }
        isLoadedProds = true;
    }
    public static ProdInfo getProdById(Id id)      { loadAllProds(); return prodMapById.get(id); }
    public static ProdInfo getProdByErp(String erp){ loadAllProds(); return prodMapByErp.get(erp); }
    public static void clearCacheProds() { isLoadedProds = false; prodMapById = null; prodMapByErp = null; }
    public static void refreshProds()    { clearCacheProds(); loadAllProds(); }

    /***************************************************************************
    *                              Трубна продукція                            *
    ****************************************************************************/
    // === Діаметри труб (TubeOD__c) ===========================================
    public class TubeOD {
        public Id      OD_Id;
        public Decimal OD_mm;
        public Decimal OD_inch;
        public String  OD_mm_str;
        public String  NPS;
        public String  Mark1;     // фракція
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
    private static Map<Id, TubeOD> tubeODById;
    private static Map<String, TubeOD> tubeODByErp;
    private static Boolean isLoadedTubeOD = false;

    public static void loadAllTubeOD() {
        if (isLoadedTubeOD) return;
        tubeODById  = new Map<Id, TubeOD>();
        tubeODByErp = new Map<String, TubeOD>();

        List<TubeOD__c> odList = [
            SELECT Id, ID_ERP__c, Name, OD_mm__c, NPS__c, H_mm__c, L_mm__c
            FROM TubeOD__c
        ];
        for (TubeOD__c od : odList) {
            TubeOD rec = new TubeOD();
            rec.OD_Id   = od.Id;
            rec.ID_ERP  = od.ID_ERP__c;
            rec.OD_mm   = od.OD_mm__c;
            rec.OD_inch = (od.OD_mm__c == null) ? null : TubeUtils.mmToInches(od.OD_mm__c, 3);
            rec.OD_mm_str = (od.OD_mm__c == null) ? null : String.valueOf(od.OD_mm__c.setScale(2));
            rec.NPS     = od.NPS__c;
            rec.Mark1   = (od.OD_mm__c == null) ? null : TubeUtils.mmToInchesFraction(od.OD_mm__c);
            rec.H_mm    = od.H_mm__c;
            rec.H_inch  = (od.H_mm__c == null) ? null : TubeUtils.mmToInches(od.H_mm__c, 3);
            rec.L_mm    = od.L_mm__c;
            rec.L_inch  = (od.L_mm__c == null) ? null : TubeUtils.mmToInches(od.L_mm__c, 3);

            // Правило: прямокутний профіль = обидва H і L задані і >0; круглий інакше
            rec.IsRound = !(
                (od.H_mm__c != null && od.H_mm__c > 0) &&
                (od.L_mm__c != null && od.L_mm__c > 0)
            );

            tubeODById.put(od.Id, rec);
            if (od.ID_ERP__c != null) tubeODByErp.put(od.ID_ERP__c, rec);
        }
        isLoadedTubeOD = true;
    }
    public static TubeOD getTubeODById(Id id)        { loadAllTubeOD(); return tubeODById.get(id); }
    public static TubeOD getTubeODByErp(String erp)  { loadAllTubeOD(); return tubeODByErp.get(erp); }
    public static void clearCacheTubeOD() { isLoadedTubeOD = false; tubeODById = null; tubeODByErp = null; }
    public static void refreshTubeOD()    { clearCacheTubeOD(); loadAllTubeOD(); }

    // === Стінки труб (TubeWT__c) =============================================
    public class TubeWT {
        public Id      WT_Id;
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
    private static Map<Id, TubeWT> tubeWTById;
    private static Map<String, TubeWT> tubeWTByErp;
    private static Boolean isLoadedTubeWT = false;

    public static void loadAllTubeWT() {
        if (isLoadedTubeWT) return;
        tubeWTById  = new Map<Id, TubeWT>();
        tubeWTByErp = new Map<String, TubeWT>();

        List<TubeWT__c> wtList = [SELECT Id, ID_ERP__c, WT_mm__c FROM TubeWT__c];
        for (TubeWT__c wt : wtList) {
            TubeWT rec = new TubeWT();
            rec.WT_Id       = wt.Id;
            rec.WT_mm       = wt.WT_mm__c;
            rec.WT_inch     = (wt.WT_mm__c == null) ? null : TubeUtils.mmToInches(wt.WT_mm__c, 3);
            rec.WT_inch_str = (wt.WT_mm__c == null) ? null : TubeUtils.mmToInchesFraction(wt.WT_mm__c);
            rec.ID_ERP      = wt.ID_ERP__c;

            tubeWTById.put(wt.Id, rec);
            if (wt.ID_ERP__c != null) tubeWTByErp.put(wt.ID_ERP__c, rec);
        }
        isLoadedTubeWT = true;
    }
    public static TubeWT getTubeWTById(Id id)        { loadAllTubeWT(); return tubeWTById.get(id); }
    public static TubeWT getTubeWTByErp(String erp)  { loadAllTubeWT(); return tubeWTByErp.get(erp); }
    public static void clearCacheTubeWT() { isLoadedTubeWT = false; tubeWTById = null; tubeWTByErp = null; }
    public static void refreshTubeWT()    { clearCacheTubeWT(); loadAllTubeWT(); }

    // === Кінці труб (TubeEnds__c) ============================================
    public class TubeEnds {
        public Id     EndId;
        public String EndName;
        public String EndShortName;
        public String EndType;        // якщо є
        public String OCTGEnds;
        public String TubingEnds;
        public String CasingEnds;
        public String ID_ERP;
        
        public TubeEnds () {
            this.EndId = null;
            this.EndName = '';
            this.EndShortName = '';
            this.EndType = '';
            this.OCTGEnds = '';
            this.TubingEnds = '';
            this.CasingEnds = '';
            this.ID_ERP='';
        }       
    }
    private static Map<Id, TubeEnds> tubeEndById;
    private static Map<String, TubeEnds> tubeEndByErp;
    private static Boolean isLoadedTubeEnds = false;

    public static void loadAllTubeEnds() {
        if (isLoadedTubeEnds) return;
        tubeEndById  = new Map<Id, TubeEnds>();
        tubeEndByErp = new Map<String, TubeEnds>();

        List<TubeEnds__c> endsList = [
            SELECT Id, ID_ERP__c, Name, ShortName__c, CasingEnds__c, TubingEnds__c, OCTGEnds__c
            FROM TubeEnds__c
        ];
        for (TubeEnds__c e : endsList) {
            TubeEnds rec = new TubeEnds();
            rec.EndId        = e.Id;
            rec.EndName      = e.Name;
            rec.EndShortName = e.ShortName__c;
            rec.CasingEnds   = e.CasingEnds__c;
            rec.TubingEnds   = e.TubingEnds__c;
            rec.OCTGEnds     = e.OCTGEnds__c;
            rec.ID_ERP       = e.ID_ERP__c;

            tubeEndById.put(e.Id, rec);
            if (e.ID_ERP__c != null) tubeEndByErp.put(e.ID_ERP__c, rec);
        }
        isLoadedTubeEnds = true;
    }
    public static TubeEnds getTubeEndsById(Id id)        { loadAllTubeEnds(); return tubeEndById.get(id); }
    public static TubeEnds getTubeEndsByErp(String erp)  { loadAllTubeEnds(); return tubeEndByErp.get(erp); }
    public static void clearCacheTubeEnds() { isLoadedTubeEnds = false; tubeEndById = null; tubeEndByErp = null; }
    public static void refreshTubeEnds()    { clearCacheTubeEnds(); loadAllTubeEnds(); }

    // === Стандарти (ProductStandard__c) ======================================
    public class TubeStd {
        public Id     TubeStdId;
        public String StdName;
        public String StdFullName;
        public Boolean IsActive;
        public String ID_ERP;
        public String FacetValue;

        public TubeStd() {
            this.TubeStdId = null;
            this.StdName='';
            this.StdFullName='';
            this.IsActive=false;
            this.ID_ERP='';
            this.FacetValue = '';
        }       
    }
    private static Map<Id, TubeStd> tubeStdById;
    private static Map<String, TubeStd> tubeStdByErp;
    private static Boolean isLoadedTubeStd = false;

    public static void loadAllTubeStd() {
        if (isLoadedTubeStd) return;
        tubeStdById  = new Map<Id, TubeStd>();
        tubeStdByErp = new Map<String, TubeStd>();

        List<ProductStandard__c> psList = [
            SELECT Id, ID_ERP__c, Name, FacetValue__c, IsActive__c, FullName__c
            FROM ProductStandard__c
            WHERE IsActive__c = true
        ];
        for (ProductStandard__c ps : psList) {
            TubeStd rec = new TubeStd();
            rec.TubeStdId   = ps.Id;
            rec.StdName     = ps.Name;
            rec.StdFullName = ps.FullName__c;
            rec.IsActive    = ps.IsActive__c;
            rec.ID_ERP      = ps.ID_ERP__c;
            rec.FacetValue  = ps.FacetValue__c;

            tubeStdById.put(ps.Id, rec);
            if (ps.ID_ERP__c != null) tubeStdByErp.put(ps.ID_ERP__c, rec);
        }
        isLoadedTubeStd = true;
    }
    public static TubeStd getTubeStdById(Id id)        { loadAllTubeStd(); return tubeStdById == null ? null : tubeStdById.get(id); }
    public static TubeStd getTubeStdByErp(String erp)  { loadAllTubeStd(); return tubeStdByErp == null ? null : tubeStdByErp.get(erp); }
    public static void clearCacheTubeStd() { isLoadedTubeStd = false; tubeStdById = null; tubeStdByErp = null; }
    public static void refreshTubeStd()    { clearCacheTubeStd(); loadAllTubeStd(); }

    //=== Довжини труб (TubeLengthSize__c) ======================================
    public class TubeLen {
        public Id      TubeLenId;
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

    private static Map<Id, TubeLen> tubeLenById;
    private static Map<String, TubeLen> tubeLenByErp;
    private static Boolean isLoadedTubeLen = false;

    public static void loadAllTubeLen() {
        if (isLoadedTubeLen) return;
        // Ініціалізуємо допоміжні структури
        tubeLenById   = new Map<Id, TubeLen>();
        tubeLenByErp  = new Map<String, TubeLen>();
        List<TubeLengthSize__c> tlsList = [SELECT 
                                            Id, ID_ERP__c, MinLength__c, MaxLength__c, 
                                            Name, ShortName__c, Type__c, Obsolete__c
                                           FROM TubeLengthSize__c];
        for(TubeLengthSize__c tls : tlsList) {
            TubeLen tl = new TubeLen();
            tl.TubeLenId = tls.Id;
            tl.MinLen_mm = tls.MinLength__c;
            tl.MaxLen_m  = tls.MaxLength__c;
            tl.MinLen_m  = (tls.MaxLength__c/1000.0).setScale(2);
            tl.MaxLen_m  = (tls.MaxLength__c/1000.0).setScale(2);
            tl.MinLen_ft = ((tls.MinLength__c/1000.0)/0.3048).setScale(2);
            tl.MaxLen_ft = ((tls.MaxLength__c/1000.0)/0.3048).setScale(2);
            tl.LenType   = tls.Type__c;
            tl.LenName   = tls.Name;
            tl.ID_ERP    = tls.ID_ERP__c;
            tl.IsActive  = !tls.Obsolete__c;

            tubeLenById.put(tls.Id, tl);
            if(tls.ID_ERP__c!=null) tubeLenByErp.put(tls.ID_ERP__c, tl);
        }
        isLoadedTubeLen = true;
    }

    public static TubeLen getTubeLenById(Id id) { loadAllTubeLen(); return (tubeLenById == null) ? null : tubeLenById.get(id); }
    public static TubeLen getTubeLenByErp(String erp) { loadAllTubeLen(); return (tubeLenByErp == null) ? null : tubeLenByErp.get(erp); }
    public static void clearCacheTubeLen() { isLoadedTubeLen = false; tubeLenById = null; tubeLenByErp = null; }
    public static void refreshTubeLen() { clearCacheTubeLen(); loadAllTubeLen(); }   

    //=== Марки сталі (SteelGrade__c) ======================================
    public class TubeSG {
        public Id     TubeSGId;
        public String ID_ERP;
        public String TubeSGName;

        public TubeSG() {
            this.TubeSGId = null;
            this.ID_ERP = '';
            this.TubeSGName = '';
        }
    }
    private static Map<Id, TubeSG> tubeSGById;
    private static Map<String, TubeSG> tubeSGByErp;
    private static Boolean isLoadedTubeSG = false;  

    public static void loadAllTubeSG() {
        if(isLoadedTubeSG) return;
        tubeSGById = new Map<Id, TubeSG>();
        tubeSGByErp = new Map<String, TubeSG>();

        List<SteelGrade__c> sgList = [SELECT 
                                        Id, ID_ERP__c, ShortName__c, Name 
                                      FROM SteelGrade__c 
                                      WHERE Obsolete__c = false];
        for(SteelGrade__c sg : sgList) {
            TubeSG recSG = new TubeSG();
            recSG.TubeSGId = sg.Id;
            recSG.ID_ERP   = sg.ID_ERP__c;
            recSG.TubeSGName = sg.ShortName__c;

            tubeSGById.put(sg.Id, recSG);
            if(sg.ID_ERP__c!=null) tubeSGByErp.put(sg.ID_ERP__c, recSG);
        }
        isLoadedTubeSG = true;
    }

    public static TubeSG getTubeSGById(Id id) { loadAllTubeSG(); return (tubeSGById == null) ? null : tubeSGById.get(id); }
    public static TubeSG getTubeSGByErp(String erp) { loadAllTubeSG(); return (tubeSGByErp == null) ? null : tubeSGByErp.get(erp); }
    public static void clearCacheTubeSG() { isLoadedTubeSG = false; tubeSGById = null; tubeSGByErp = null; }
    public static void refreshTubeSG() { clearCacheTubeSG(); loadAllTubeSG(); }    
    
    //=== Тип покриття (CoatingType__c) ======================================
    public class TubeCoat {
        public Id     TubeCoatId;
        public String ID_ERP;
        public String TubeCoatName;

        public TubeCoat() {
            this.TubeCoatId = null;
            this.ID_ERP = '';
            this.TubeCoatName = '';
        }
    }
    private static Map<Id, TubeCoat> tubeCoatById;
    private static Map<String, TubeCoat> tubeCoatByErp;
    private static Boolean isLoadedTubeCoat = false;  

    public static void loadAllTubeCoat() {
        if(isLoadedTubeCoat) return;
        tubeCoatById = new Map<Id, TubeCoat>();
        tubeCoatByErp = new Map<String, TubeCoat>();

        List<CoatingType__c> coatList = [SELECT 
                                        Id, ID_ERP__c, Name 
                                      FROM CoatingType__c];
        for(CoatingType__c coat : coatList) {
            TubeCoat recCoat = new TubeCoat();
            recCoat.TubeCoatId = coat.Id;
            recCoat.ID_ERP   = coat.ID_ERP__c;
            recCoat.TubeCoatName = coat.Name;

            tubeCoatById.put(coat.Id, recCoat);
            if(coat.ID_ERP__c!=null) tubeCoatByErp.put(coat.ID_ERP__c, recCoat);
        }
        isLoadedTubeCoat = true;
    }

    public static TubeCoat getTubeCoatById(Id id) { loadAllTubeCoat(); return (tubeCoatById == null) ? null : tubeCoatById.get(id); }
    public static TubeCoat getTubeCoatByErp(String erp) { loadAllTubeCoat(); return (tubeCoatByErp == null) ? null : tubeCoatByErp.get(erp); }
    public static void clearCacheTubeCoat() { isLoadedTubeCoat = false; tubeCoatById = null; tubeCoatByErp = null; }
    public static void refreshTubeCoat() { clearCacheTubeCoat(); loadAllTubeCoat(); }        

    //=== ProductSpecLevel__c ======================================
    public class TubePSL {
        public Id     TubePSLId;
        public String ID_ERP;
        public String TubePSLName;

        public TubePSL() {
            this.TubePSLId = null;
            this.ID_ERP = '';
            this.TubePSLName = '';
        }
    }
    private static Map<Id, TubePSL> tubePSLById;
    private static Map<String, TubePSL> tubePSLByErp;
    private static Boolean isLoadedTubePSL = false;  

    public static void loadAllTubePSL() {
        if(isLoadedTubePSL) return;
        tubePSLById = new Map<Id, TubePSL>();
        tubePSLByErp = new Map<String, TubePSL>();

        List<ProductSpecLevel__c> pslList = [SELECT 
                                        Id, ID_ERP__c, Name 
                                      FROM ProductSpecLevel__c];
        for(ProductSpecLevel__c psl : pslList) {
            TubePSL recPSL = new TubePSL();
            recPSL.TubePSLId = psl.Id;
            recPSL.ID_ERP   = psl.ID_ERP__c;
            recPSL.TubePSLName = psl.Name;

            tubePSLById.put(psl.Id, recPSL);
            if(psl.ID_ERP__c!=null) tubePSLByErp.put(psl.ID_ERP__c, recPSL);
        }
        isLoadedTubePSL = true;
    }

    public static TubePSL getTubePSLById(Id id) { loadAllTubePSL(); return (tubePSLById == null) ? null : tubePSLById.get(id); }
    public static TubePSL getTubePSLByErp(String erp) { loadAllTubePSL(); return (tubePSLByErp == null) ? null : tubePSLByErp.get(erp); }
    public static void clearCacheTubePSL() { isLoadedTubePSL = false; tubePSLById = null; tubePSLByErp = null; }
    public static void refreshTubePSL() { clearCacheTubePSL(); loadAllTubePSL(); } 

    /***************************************************************************
    *                          Залізнична продукція                            *
    ****************************************************************************/
    //=== Діаметри коліс (WheelDiameter__c) ====================================
    public class WheelDiam {
        public Id      OD_Id;
        public Decimal OD_mm;
        public Decimal H_inch;
        public String  ID_ERP;
        public String  ODName;

        public WheelDiam () {
            this.OD_Id = null;
            this.OD_mm = 0.00;
            this.H_inch = 0.00;
            this.ID_ERP = '';
            this.ODName = '';
        }
    }
    private static Map<Id, WheelDiam> wheelDiamById;
    private static Map<String, WheelDiam> wheelDiamByErp;
    private static Boolean isLoadedWD = false;   
    
    public static void loadAllwheelDiam() {
        if(isLoadedWD) return;
        wheelDiamById = new Map<Id, WheelDiam>();
        wheelDiamByErp = new Map<String, WheelDiam>();
        List<WheelDiameter__c> wdList = [SELECT 
                                            Id, ID_ERP__c, Name, OD_mm__c
                                         FROM WheelDiameter__c];
        if(!wdList.isEmpty()) {
            for (WheelDiameter__c wd : wdList) {
                WheelDiam recWD = new WheelDiam();
                recWD.OD_mm = wd.OD_mm__c;
                recWD.OD_Id = wd.Id;
                recWD.H_inch = TubeUtils.mmToInches(wd.OD_mm__c, 0);
                recWD.ID_ERP = wd.ID_ERP__c;
                recWD.ODName = wd.Name;

                wheelDiamById.put(wd.Id, recWD);
                if(wd.ID_ERP__c!=null) wheelDiamByErp.put(wd.ID_ERP__c, recWD);
            }
        } 
        isLoadedWD = true;
    } 
    public static WheelDiam getWheelDiamById(Id id) { loadAllwheelDiam(); return (wheelDiamById == null) ? null : wheelDiamById.get(id); }
    public static WheelDiam getWheelDiamByErp(String erp) { loadAllwheelDiam(); return (wheelDiamByErp == null) ? null : wheelDiamByErp.get(erp); }
    public static void clearCacheWD() { isLoadedWD = false; wheelDiamById = null; wheelDiamByErp = null; }
    public static void refreshWD() { clearCacheWD(); loadAllwheelDiam(); }    
    
    //=== WheelAssembly ====================================
    private static Map<String, WheelAssembly__c> mapWA;
    private static boolean isLoadedWA = false;

    public static void loadAllWA() {
        if(isLoadedWA) return;
        mapWA = new Map<String, WheelAssembly__c>(); 
        List<WheelAssembly__c> waList = [SELECT Id, ID_ERP__c, NameENG__c, NameUKR__c FROM WheelAssembly__c];
        if(!waList.isEmpty()) {
            for(WheelAssembly__c wa : waList) {
                mapWA.put(wa.ID_ERP__c, wa);
            }
        }
        isLoadedWA=true;
    }
    public static WheelAssembly__c getWAByErp(String erp) {
        loadAllWA();
        return (mapWA.containsKey(erp)) ? mapWA.get(erp) : new WheelAssembly__c();
    }
    public static void clearCacheWA() { isLoadedWA = false; mapWA = null; }
    public static void refreshWA() { clearCacheWA(); loadAllWA(); }
}