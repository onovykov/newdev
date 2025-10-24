@isTest
public class PipeWeightCalculationsTest  {
	
	@TestSetup
	public static void testSetup() {
		List<Product2> prodList = new List<Product2>();
		prodList.add(new Product2(Name = 'Product 1', ID_ERP__c = 'p01', Family = 'OCTG', LinearWeightCalculationGroup__c = 'Tubing'));
		prodList.add(new Product2(Name = 'Product 2', ID_ERP__c = 'p02', Family = 'OCTG', LinearWeightCalculationGroup__c = 'Casing'));
		prodList.add(new Product2(Name = 'Product 3', ID_ERP__c = 'p03', Family = 'LP/GU', LinearWeightCalculationGroup__c = ''));
		insert prodList;

		GeneralProductStandard__c gps = new GeneralProductStandard__c(Name = 'API 5CT', ID_ERP__c = 'gps01');
		insert gps;

		ProductStandard__c ps = new ProductStandard__c(Name = '2019 API 5CT PSL1', GeneralProductStandard__c = gps.Id);
		insert ps;

		TubeOD__c od = new TubeOD__c(Name = '48.26 mm', OD_mm__c = 48.26, OD_inch__c = 1.9, ID_ERP__c = '03');
		insert od;

		TubeWT__c wt = new TubeWT__c(Name = '3.18 mm', WT_mm__c = 3.18, WT_inch__c = 0.125, ID_ERP__c = '0Ц');
		insert wt;

		TubeEnds__c ends = new TubeEnds__c(Name = 'Plain ends', Type__c = 'PE');
		insert ends;

		PipeLinearWeight__c plw = new PipeLinearWeight__c(	GeneralProductStandard__c = gps.Id,
															CalculationGroup__c = 'Tubing',
															TubeOD__c = od.Id,
															TubeWT__c = wt.Id,
															TubeEndsType__c = 'PE',
															Weight_kpm__c = 3.54);
		insert plw;
	}

	@IsTest
	public static void check_OCTG_Tubing() {
		Product2 prod = [Select Id, Family, LinearWeightCalculationGroup__c From Product2 WHERE Family = 'OCTG' AND LinearWeightCalculationGroup__c = 'Tubing' LIMIT 1];
		GeneralProductStandard__c gps = [Select Id, ID_ERP__c from GeneralProductStandard__c limit 1];
		TubeOD__c od =  [Select Id, ID_ERP__c, OD_mm__c, OD_inch__c From TubeOD__c Limit 1];
		TubeWT__c wt =  [Select Id, ID_ERP__c, WT_mm__c, WT_inch__c From TubeWT__c Limit 1];
		TubeEnds__c ends = [Select Id, Type__c From TubeEnds__c LIMIT 1];
		Map<String, Decimal> plw = PipeWeightCalculations.getPipeLinearWeight(prod, gps, od, wt, ends);
		System.assertEquals(3.54, plw.get('kpm'));
		//System.assertEquals(null, plw.get('ppf'));
	}

	@IsTest
	public static void check_NonOCTG() {
		Product2 prod = [Select Id, Family, LinearWeightCalculationGroup__c From Product2 WHERE Family != 'OCTG' LIMIT 1];
		GeneralProductStandard__c gps = [Select Id, ID_ERP__c from GeneralProductStandard__c limit 1];
		TubeOD__c od =  [Select Id, ID_ERP__c, OD_mm__c, OD_inch__c From TubeOD__c Limit 1];
		TubeWT__c wt =  [Select Id, ID_ERP__c, WT_mm__c, WT_inch__c From TubeWT__c Limit 1];
		TubeEnds__c ends = [Select Id, Type__c From TubeEnds__c LIMIT 1];
		Map<String, Decimal> plw = PipeWeightCalculations.getPipeLinearWeight(prod, gps, od, wt, ends);
		System.assertEquals(3.535, plw.get('kpm').setScale(3));
		//System.assertEquals(null, plw.get('ppf'));
	}

}