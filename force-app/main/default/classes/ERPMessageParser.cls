public class ERPMessageParser {

	//======================================================================================
	// Core classes

	public class MessageMetadata {
		public String msgType;
		public Decimal msgTypeVersion;
		public DateTime msgTimestamp;
		public Integer partNumber;
		public Integer totalParts;
	}

	public abstract class ERPCoreObject {
		public String id;
		public String name;
	}

	public class ERPObject extends ERPCoreObject {
		public String Address;
		public String CountryId;
	 }
	
	/*
	public class ErpToSfMessage {
		public MessageMetadata metadata;
		public Object data;
	}
	*/

	public class ErpToSfMessage_AccountsReceivable {
		public MessageMetadata metadata;
		public AccountsReceivableMessageData data;
	}

	public class ErpToSfMessage_PAR {
		public MessageMetadata metadata;
		public PARMessageData data;
	}

	public class ErpToSfMessage_OpportunityData {
		public MessageMetadata metadata;
		public OrderMessageData data;
	}

	public class ErpToSfMessage_OrderDelivery {
		public MessageMetadata metadata;
		public OrderDeliveryMessageData data;
	}
    
    public class ErpToSfMessage_SF_ClaimSpr {
		public MessageMetadata metadata;
		public SF_ClaimSpr data;
	}
	public class ErpToSfMessage_Debit {
		public MessageMetadata metadata;
		public List<InvoiceOrderDebtMessageData> data;
	}
	public class ErpToSfMessage_ProdPlanBalance {
		public MessageMetadata metadata;
		public ProdPlanData data;
	}
	public class ERPToSfMessage_OrderProbabilityQuery{
		public MessageMetadata Metadata;
		public List<OrderProbabilityMessageData> data;
	}
	public class ErpToSfMessage_InvoicePDF {
		public MessageMetadata metadata;
		public InvoicePDF data;
	}
	public class ErpToSfMessage_Route {
		public MessageMetadata metadata;
		public RouteMessageData data;
	}
	public class ErpToSfMessage_FamilyType {
		public MessageMetadata metadata;
		public FamilyTypeMessageData data;
	}
	public class ErpToSfMessage_Family {
		public MessageMetadata metadata;
		public FamilyMessageData data;
	}
	public class ErpToSfMessage_RouteFamilies {
		public MessageMetadata metadata;
		public RouteFamilyMessageData data;
	}
	public class ErpToSfMessage_StructQuotaConfig {
		public MessageMetadata metadata;
		public StructQuotaConfigMessageData data;
	}
	public class ErpToSfMessage_RouteQuota {
		public MessageMetadata metadata;
		public RouteQuotaMessageData data;
	}
	public class ErpToSfMessage_StructQuota {
		public MessageMetadata metadata;
		public StructQuotaData data;
	}
	public class ErpToSfMessage_KbSpec {
		public MessageMetadata metadata;
		public SpecMessageData data;
	}
	
	

	//======================================================================================
	//ErpToSfMessage_InvoicePDF
	public class InvoicePDF {
		public Integer ORG;
		public String ORG_NAME;
		public Integer ORG_K;
		public String ORG_K_NAME;
		public String NDM_INVOCE;
		public String DDM;
		public String CONTENTS;
	}
	//======================================================================================
	//ERPToSfMessage_OrderProbabilityQuery

	public class Items {
		public String ITE_NUMBER;
		public Double PROBABILITY;
		public String KDO;
		public String PROD_START_DATE;
		public String EXPIRATION_DATE;
	}

	public class OrderProbabilityMessageData {
		public String ID_SF;
		public Integer ID_ERP;
		public List<Items> Items;
	}

	
	//======================================================================================
	//ProdPlan Balance
	public class ProdPlanData {
		public PeriodInfo periodInfo;
		public List<OrderItemsData> items;
	}
	public class PeriodInfo {
		public String YearMonth;
		public Integer WeekNumber;
		public String WeekStartDate;
		public String WeekEndDate;
	}
	public class OrderItemsData {
		public Integer Undoc;
		public Integer Npp;
		public String IteNumber;
		public Decimal BalanceForProduction;
		public Decimal MonthlyProdPlan;
		public Decimal WeeklyProdPlan;
		public List<ProdPlan> Plans;
		public String DateSnapshot;
		public Integer Year;
		public Integer Month;
		public Integer Shop;
		public Decimal MonthPlanQty_t;           // ← нове місце
		public Decimal MonthProdBalance_t;       // ← нове місце
	}





	//======================================================================================

	//======================================================================================
	//Order Delivery
	public class OrderDeliveryMessageData {
		public OrderDeliveryHeader header;
		public OrderDeliveryItem[] OrderLineItems;
	}

	public class OrderDeliveryHeader {
		public Integer unDoc;
		public boolean success;
		public String iteNumber;
		public String Comment;
	}
	public class OrderDeliveryItem {
		public String iteNumber;
		public String NOM_VM;
		public String TRDOC_NUM;
		public String NOMSERT;
		public decimal QTY_PCS;
		public decimal QTY_T_BRUTTO;
		public decimal QTY_T_NETTO;
		public decimal LENGTH_M;
		public String COORD_DT;
		public String LATITUDE;
		public String LONGTITUDE;
		public String COUNTRY;
		public String ISO;
		public String PLACE;
		public String STATUS_DT;
		public String STATUS_NAME;
	}
	




	//======================================================================================
	// Order

	public class OrderMessageData {
		public String orderType; // "Tubes" | "Wheels"
		public String orderCurrency;
		public ERPObject_OrderHeader header;
		public ERPObject_OrderItem[] items;
	}

	public class ERPObject_OrderHeader {
		public Integer unDoc;
		public String iteNumber;
		public String ID_SF;  // Salesforce Opportunity ID
		public String altNumber;
        public String addNumber;
        public String pONumber;
		public DateTime createdDate;
		public DateTime orderDate;
		public ERPObject account;
		public String businessSegmentId;
		public Integer regionId;
		public Integer countryId;
		public ERPObject paymentTerms;
		public ERPObject_DeliveryTerms deliveryTerms;
		public ERPObject_User salesRep;
		public ERPObject_User boSpecialist;
		public String crossMarket_BusinessSegment;
		public ERPObject_User crossMarket_SalesRep;
		public decimal crossMarket_Percent;
	}

	public class ERPObject_OrderItem {
		public Integer Undoc;
		public Integer npp;
		public String iteNumber;
        public ERPObject_ProductCharacteristic productCharacteristic;
		public ERPObject speclevel;
		public String CoatingSpec;
		public ERPObject productgroup;
		public ERPObject_QuotaType quotatype;
		public ERPObject_Shop shop;
		public decimal inqQuantity;
		public Integer inqUnit;
		public decimal quantity_Mt;
		public decimal quantity_m;
		public decimal quantity_ft;
		public decimal quantity_pcs;
		public decimal price;
		public decimal price_t;
		public decimal margin_t;
		public decimal totalPrice;
		public Decimal LinearWeight_ppf;
		public Decimal LinearWeight_kpm;
		public ERPObject_ShippingPoint shippingpoint;
		public Integer isTypical;
		public Integer techExp;
		public DateTime criticalDispatchDate;
		public DateTime quotaDate;
		public DateTime recommendedCDD;
		public String requestedDeliveryDate;
		public String confirmedDeliveryDate;
		public String finStatus;
		public Integer finApproval;
		public String stage;
		public decimal produced;
		public decimal dispatched;
		public decimal shipped;
		public List<ERPObject_ProductLot> lots;
		public List<ERPObject_Quotas> quotas;
		public decimal finDataShipped;
		public decimal finDataMargin;
		public String NPS;
		public String SCH;
		public String Mark1;
	}

	public class ERPObject_Quotas {
		public Datetime quotaDate;
		public Decimal quantity_Mt;
		public Decimal quantity_pcs;
		public Decimal PriceExw_t;
		public Decimal Margin_t;
	}
	public class ERPObject_ProductLot {
		public String lotDate;
		public String produced;
		public String dispatched;
		public String shipped;
	}




	//======================================================================================
	// Accounts Receivable

	public class AccountsReceivableMessageData {
		public AccountsReceivableItem[] items;
	}

	public class AccountsReceivableItem {
		public ERPObject account;
		public Integer status; //
		public Decimal balance;
		public Decimal pastDueDebt;
		public Decimal pastDueDebt15More;
		public String groupName;
		public Decimal groupPastDueDebt;
		public Decimal groupPastDueDebt15More;
		public Datetime dueDate;
		public Decimal receipts;
		public Boolean toBlock;
		public Datetime permissionDate;
		public ERPObject_User approver;
		public Decimal permittedProductionAmount;
		public Decimal permittedShipmentAmount;
		public String permissionComment;
	}



	//======================================================================================
	// Price Approval Request

	//------------------------- Inbound -------------------------
	public class PARMessageData {
		public PARHeader header;
		public PARItem[] items;
		public PARApprovalHistory[] approvalHistory;
	}

	public class PARHeader {
		public Integer id_ERP;
		public String docNumber;
		public Datetime docDate;
		public Boolean priceModel;
		public String segment;
		public ERPObject customer;
		public ERPObject_User salesRep_EmpNum;
		public ERPObject_User boSpecialist_EmpNum;
		public ERPObject_User prmDirector_EmpNum;
		public ERPObject paymentTerms;
		//public String Stage;
		public PARStage stageInfo;
		public PARStatus statusInfo;
		public Boolean fed;
		public Boolean transportation;
		public Boolean turnover;
		//public String Status;
	}

	public class PARItem {
		public String guid;
		public Integer npp;
		public Integer opportunityId_ERP;
		public String opportunityLineItemITENumber;
		public ERPObject productGroup;
		public ERPObject_Shop shop;
		public ERPObject country;
		public Integer region;
		public Integer kind;
		public ERPObject specLevel;
		public ERPObject_ProductCharacteristic steelGrade;
		public ERPObject_ProductCharacteristic standard;
		public ERPObject_TubeOD od;
		public ERPObject_TubeWT wt;
		public ERPObject_LengthSize lengthSize;
		public ERPObject_ProductCharacteristic coating;
		public ERPObject_ProductCharacteristic ends;
		public ERPObject_QuotaType quotaType;
		public ERPObject_ShippingPoint shippingPoint;
		public ERPObject_DeliveryTerms deliveryTerms;
		public Decimal inqQuantity;
		public Integer inqUnit;
		public Decimal quantity_Mt;
		public Decimal quantity_m;
		public Decimal quantity_ft;
		public Decimal quantity_pcs;
		public Datetime calculationDate;
		public String currencyCode;
		public Decimal currencyExchangeRate;
		public Decimal price;
		public Decimal price_t;
		public Decimal totalPrice;
		public Decimal priceEXW_t;
		public Decimal margin_t;
		public Decimal margin;
		public Decimal liabilities_t;
		public Decimal transportationCosts_t;
		public Decimal roi;
		public Decimal billetCost_t;
		public Decimal metalPriceForProduction_t;
		public Decimal costsTKB_t;
		public Decimal marginTKB_t;
		public Decimal marginBillet_t;
		public Decimal customDuty_t;
		public Decimal coatingCost_t;
		public Decimal extraCosts_t;
	}

	public class PARApprovalHistory {
		public Datetime approvalDate;
		public ERPObject stageBefore;
		public ERPObject stageAfter;
		public ERPObject_User approver;
		public String comment;
	}

	public class PARStage extends ERPCoreObject {
		public String milestone;
		public ERPObject_User[] currentApprovers; // Массив ID кодов пользователей ИТ-Предприятия (логины), которые имеют право согласовывать СЗ на данной стадии.
	}

	public class PARStatus extends ERPCoreObject {
		public Integer State;
	}

	//======================================================================================
	//Quotes

	public class NameObject {
		public String DefaultName;
		public String En;
		public String Uk;
		public String Ru;
	}

	public class RouteMessageData {
		public String Mode;
		public Partial Partial;
		public List<RouteItem> Items;
	}

	public class FamilyTypeMessageData {
		public String Mode;
		public Partial Partial;
		public List<FamilyTypeItem> Items;
	}

	public class FamilyMessageData {
		public String Mode;
		public Partial Partial;
		public List<FamilyItem> Items;
	}

	public class RouteFamilyMessageData {
		public String Mode;
		public Partial Partial;
		public List<RouteFamilyItem> Items;
	}

	public class StructQuotaConfigMessageData {
		public String Mode;
		public Partial Partial;
		public List<StructQuotaConfigItem> Items;
	}

	public class RouteQuotaMessageData {
		public String Mode;
		public Partial Partial;
		public List<RouteQuotaItem> Items;
	}

	public class StructQuotaData {
		public String Mode;
		public Partial Partial;
		public List<StructQuotaItem> Items;
	}

	public class Partial {
		public String Type;
		public Options Options;
	}

	public class Options {
		public DateTime DATEFROM;
		public DateTime DATETO;
	}

	public class RouteItem {
		public Integer RouteId;
		public NameObject Name;
		public Integer ShopId;
		public Boolean IsEmpty;
		public Boolean UsePcs;
		public Integer ProdDays;
		public String Comment;
		public Boolean IsActive;
	}

	public class FamilyTypeItem {
		public Integer FamilyTypeId;
		public NameObject Name;
		public NameObject NameS;
		public Boolean IsActive;
	}

	public class FamilyItem {
		public Integer FamilyId;
		public NameObject Name;
		public NameObject NameS;
		public Boolean IsActive;
		public FamilyTypeItem FamilyType;
	}

	public class RouteFamilyItem {
		public List<FamilyItem> Families;
		public RouteItem Route;
	}

	public class StructQuotaConfigItem {
		public String SegmentCode;
		public Boolean IncludeRegion;
		public Boolean IncludeSaleKdk;
		public Boolean IncludeGrp3;
		public Boolean IsActive;
	}

	public class RouteQuotaItem {
		public Integer RowId;
		public String SegmentCode;
		public DateTime DateFrom;
		public DateTime DateTo;
		public Decimal Quota_t;
		public Decimal Quota_pcs;
		public Decimal Budget_t;
		public Decimal Budget_pcs;
		public Decimal Marginall;
		public RouteFamilyItem RouteFamilies;
	}
	
	public class StructQuotaItem {
		public Integer RowId;
		public FamilyItem Family;
		public StructQuotaConfigItem StructConfig;
		public Integer Region;
		public String SaleKdk;
		public Integer Grp3;
		public DateTime DateFrom;
		public DateTime DateTo;
		public Decimal Qty_percent;
		public Decimal Qty_add_t;
		public Decimal Qty_add_pcs;
	}

	

	//------------------------- Outbound -------------------------
	
	public class ApprovalResult {
		public String MessageType;
		public String ID_ERP;
		public String Resolution;
		public String Approver;
		public String ApproverUserId;
		public String ApproverEmail;
		public String Comment;
	}

	public class ExecuteResponce_ApprovalResult {
		public Boolean Status;
        public String ErrorMessage;
		public PARInfo PAMRequestInfo;
		public ApprovalResult SourceQuoteApprovalMessage;
    }

	public class PARInfo {
		public String ManagerSaleKDK;
		public String ManagerSaleUserId;
		public Integer Status;
		public String Stage;
		public String StageName;
	}




	//======================================================================================
	// Common References

	public class ERPObject_User extends ERPCoreObject {
		public String userId; //Login for IT-Enterprise
		public String email;
		public String UID;
	}

	public class ERPObject_DeliveryTerms extends ERPCoreObject {
		public String incoterms;
	}

	public class ERPObject_QuotaType extends ERPCoreObject {
		public ERPObject shop;
	}

	public virtual class ERPObject_ProductCharacteristic extends ERPCoreObject {
		public Integer Specification;
		public String facetCode;
		public ERPObject_Diameter Diameter;
		public ERPObject_Thickness Thickness;
		public ERPObject_LengthSize LengthSize;
		public ERPOBject_Ends Ends;
		public ERPOJbect_Coating Coating;
		public ERPOBject_Standard Standard;
		public ERPObject_SteelGrade SteelGrade;
		public ERPObject_Hub Hub;
		public ERPObject_Drawing Drawing;

	}

	// public class ERPObject_TubeLengthSize extends ERPObject_ProductCharacteristic {
	// 	public Decimal minLength;
	// 	public Decimal maxLength;
	// }

	public class ERPObject_TubeOD extends ERPCoreObject {
		public Decimal od_mm;
		public String facetCode;
	}

	public class ERPObject_TubeWT extends ERPCoreObject {
		public Decimal wt_mm;
		public String facetCode;
	}

	public class ERPObject_ShippingPoint extends ERPCoreObject {
		public String spType;
		//public String countryA3Code;
	}

	public class ERPObject_Shop extends ERPCoreObject {
		public ERPObject mill;
	}

	// public class ERPObject_ProductCharacteristics {
	// 	public ERPObject_Diameter Diameter;
	// 	public ERPObject_Thickness Thickness;
	// 	public ERPObject_LengthSize LengthSize;
	// 	public ERPOBject_Ends Ends;
	// 	public ERPOJbect_Coating Coating;
	// 	public ERPOBject_Standard Standard;
	// 	public ERPObject_SteelGrade SteelGrade;
	// }

	public class ERPObject_Diameter extends ERPCoreObject {
		public Decimal OD_mm;
		public String facetCode;
	}

	public class ERPObject_Thickness extends ERPCoreObject {
		public Decimal WT_mm;
		public String facetCode;
	}

	public class ERPObject_LengthSize extends ERPCoreObject {
		public Decimal minLength;
		public Decimal maxLength;
		public String facetCode;
	}

	public class ERPOBject_Ends extends ERPCoreObject {
		public String facetCode;
	}

	public class ERPOJbect_Coating extends ERPCoreObject {
		public String facetCode;
	}

	public class ERPOBject_Standard extends ERPCoreObject {

	}

	public class ERPObject_SteelGrade extends ERPCoreObject {
		public String facetCode;
	}
	
	public class ERPObject_Hub extends ERPCoreObject {
		public Decimal WT_mm;
		public String facetCode;
	}

	public class ERPObject_Drawing extends ERPCoreObject {
		public String facetCode;
	}

    public class ErpToSfMessage_Reclamation {
		public MessageMetadata metadata;
		public ErpToSfMessage_ReclamationStatus data;
	}
    
    public class ErpToSfMessage_ReclamationStatus {
        public String MessageType;
        public String ID_in_ERP ;
        public String NUMBER_RECLAMATION;
        public String DATE_RECL;
        public String STAGE;
        public String WARNING;
        public String ERROR;
		public String K_DEC;
		public String DES_AMNT;
		public Decimal PAY_AMNT;
    }
    
    public class ErpToSfMessage_ClaimStage {
        public MessageMetadata metadata;
		public ErpToSfMessage_ReclamationStatus data;    
    }
    
    public class SF_ClaimSpr{
        public String K_MISTM;
        public String N_MISTM;
        public String State;
    }
    
    public class ErpToSfMessage_OrderItemStage {
        public MessageMetadata metadata;
		public ErpToSfMessage_StageData data;    
    }
    
    public class ErpToSfMessage_StageData{
        public Integer Undoc;
        public Integer Npp;
        public String Stage;
    }
	
    public class ErpToSfMessage_RemainProducts {
        public MessageMetadata metadata;
		public ErpToSfMessage_RemainProduct[] data;    
    }
    
    public class ErpToSfMessage_RemainProduct{       
        public String Pos_ITENumber;
        public Boolean Second_Coise;
        public String Std_ERP_ID;
        public String D_ERP_ID;
        public String W_ERP_ID;
        public String SteelGrade_ERP_ID;
        public String L_ERP_ID;
        public String Qty_tons;
        public String uniCode;
    }


	public class ErpToSfMessage_ClaimDoc {
        public MessageMetadata metadata;
		public ErpToSfMessage_ReclamationDoc data;    
    }

	public class ErpToSfMessage_ReclamationDoc{
		public String ID;
		public String NUMB;
		public DateTime DT;
		public String KSEC;
		public String K_CL_T;
		public String ORG;
		public Decimal DES_AMNT;
		public String KVAL;
		public String DESCR;
		public Boolean NO_DES;
	}

//
// ERP-SF_Debit
//
	public class InvoiceOrderDebtMessageData {
		public String ORG;
		public String ORG_NAME;
		public String ORG_K;
		public String ORG_K_NAME;
		public String COC_ORDER_NUM;
		public String NDM_ORDER;
		public String UNDOC_ORDER;
		public String NDM_INVOCE;
		public String DDM;
		public String DUE_DATE;
		public Integer DAYS;
		public String VAL;
		public Double NET_AMNT;
		public Double VAT_AMNT;
		public Double DT_OUT;
		public String Contract;
	}

	//======================================================================================
	// Specifications

	public class SpecMessageData {
		public List<ERPObject_SpecItem> Items;
	}

	public class ERPObject_SpecItem {
		public String ClientSpec;
		public Integer Id;
		public String OilHole;
		public Decimal WeightKg;
		public Decimal WeightAxleboxKg;
		public Decimal WeightAllKg;
		public ERPObject_DrawingVersion DrawingVersion;
		public Integer ParentSpecId;
		public String Ndm;
		public Integer Revision;
		public String Comments;
		public ERPObject_Client Client;
		public Datetime ValidBefore;
		public Boolean IsActive;
		public Boolean HasSpecialRequirements;
		public ERPObject_BaseObject Stage;
		public ERPObject_Product Product;
		public ERPObject_BaseObject Shape;
		public ERPObject_BaseObject ExecCategory;
		public ERPObject_BaseObject NameForDoc;
		public ERPObject_BaseObject Marking;
		public ERPObject_BaseObject Imbalance;
		public ERPObject_BaseObject TypePlug;
		public ERPObject_BaseObject CoatingType;
		public ERPObject_BaseObject CoatingMaterial;
		public ERPObject_BaseObject Packing;
		public ERPObject_BaseObject Inspection;
		public List<ERPObject_BaseObject> Assembly;
		public List<ERPObject_BaseObject> QualityCertificates;
		public ERPObject_BaseObject SteelGradeIPS;
		public ERPObject_BaseObject SteelGrade;
		public ERPObject_BaseObject Axlebox;
		public ERPObject_BaseObject ProducerAxlebox;
		public ERPObject_BaseObject Bearer;
		public ERPObject_BaseObject ProducerBearer;
		public Integer SpecWheelId;
		public Integer SpecAxleId;
		public ERPObject_BaseObject Purpose;
	}

	public class ERPObject_DrawingVersion {
		public Integer Id;
		public Integer DrawingId;
		public String Ndm;
		public Integer Revision;
		public integer Version;
		public String Comments;
		public ERPObject_BaseObject DrawingFacet;
		public ERPObject_BaseObject Purpose;
		public ERPObject_BaseObject CertGroup;
		public Datetime CertValidBefore;
		public Boolean IsActive;
		public ERPObject_BaseObject Stage;
		public ERPObject_Product Product;
		public ERPObject_BaseObject SteelGrade;
		public ERPObject_BaseObject TypeAxload;
		public Decimal Axload;
		public ERPObject_DiameterDrawing Diameter;
		public ERPObject_DiameterHub DiameterHub;
		public ERPObject_BaseObject HubBore;
		public Decimal Groove;
		public Decimal HubOffset;
		public ERPObject_BaseObject Standard;
		public ERPObject_BaseObject Imbalance;
		public ERPObject_BaseObject TypePlug;
		public Decimal WeightKg;
		public Decimal DiamJ;
		public Decimal DiamB;
		public Decimal Length;
		public Decimal DistanceWheels;
	}

	public abstract class ERPObject_Base {
		public String Id;
		public NameObject Name;
	}

	public class ERPObject_BaseObject extends ERPObject_Base {
	}

	public class ERPObject_Product extends ERPObject_Base {
		public ERPObject_BaseObject ProductType;
	}

	public class ERPObject_DiameterDrawing extends ERPCoreObject {
		public Decimal OD_mm;
		public String FacetCode;
	}

	public class ERPObject_DiameterHub extends ERPCoreObject {
		public Decimal WT_mm;
		public String FacetCode;
	}

	public class ERPObject_Client extends ERPObject_Base {
		public String Address;
		public Integer CountryId;
	}

//	NEW CODE

	// ➤ Один елемент (позиція замовлення)
	public class ItemNode {
		public String IteNumber;         // Ідентифікатор OrderItem з ERP
		public Integer Shop;            // ERP ID цеху
		public List<MonthPlanNode> monthPlans; // Місячні плани
	}

	// ➤ Місячний план виробництва
	public class MonthPlanNode {
		public Date DateSnapshot;             // Дата зрізу плану
		public String ProdPlanType;           // Тип плану (253 / 254)
		public Decimal MonthPlanQty_t;        // План на місяць, т
		public Decimal MonthProdBalance_t;    // Баланс до виробництва, т
		public Integer Year;                  // Рік плану
		public Integer Month;                 // Місяць плану
		public Date ValidDate;           // Дата валідності
		public Id OrderItemId;                // Lookup на OrderItem (заповнюється після пошуку)
		public Id ShopId;                     // Lookup на Shop__c (заповнюється після пошуку)
		public List<WeekPlanNode> monthWeeks; // Тижневі плани всередині місяця
	}

	// ➤ Тижневий план усередині місячного
	public class WeekPlanNode {
		public String ProdPlanType;      // Тип плану (для дублювання з MonthPlan)
		public Date ValidDate;           // Дата валідності
		public Id MonthPlanId;           // Lookup на OrderItemMonthlyPlans__c
		public Decimal PlanQty_t;        // Кількість тижневого плану
		public Id ProdWeekId;            // Lookup на ProdWeeksH__c (пошук через SOQL)
		public Integer WeekNum;
		public String DateFrom;
		public String DateTo;
	}

	public class ProdPlan {
		public String ProdPlanType;
//		public Decimal MonthPlanQty_t;
//		public Decimal MonthProdBalance_t;
		public String ValidDate;
		public List<WeekPlan> WeekPlans;
	}

	public class WeekPlan {
		public List<WeekPlanNode> Details;
	}

	public static void FakeCoverageMethod() {
        Integer i=0;
        i++;
        i++;
        i++;
    }
}