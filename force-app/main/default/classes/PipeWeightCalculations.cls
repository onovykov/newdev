public class PipeWeightCalculations  {

	public static List<PipeLinearWeight__c> plwList;
	public static Map<String, Id> plwIdMap = new Map<String, Id>();
	public static Map<Id, PipeLinearWeight__c> idPlwMap = new Map<Id, PipeLinearWeight__c>();

	static {
		plwList = [SELECT Id, KeyField__c, Weight_kpm__c, Weight_ppf__c FROM PipeLinearWeight__c];
		idPlwMap.putAll(plwList);
		for (PipeLinearWeight__c plw : plwList) {
			System.debug('Key field of the record: ' + plw.KeyField__c);
			plwIdMap.put(plw.KeyField__c, plw.Id);
		}
	}
	
	public static Map<String, Decimal> getPipeLinearWeight(Product2 product, GeneralProductStandard__c gps, TubeOD__c od, TubeWT__c wt, TubeEnds__c ends) {
		Map<String, Decimal> lwMap = new Map<String, Decimal>();

		if (product.Family == 'OCTG'){
			//Вес погонного метра OCTG труб определяем по справочнику:
			if (gps == null) {
				return lwMap;
			}
			String keyField = gps.ID_ERP__c + '|' + product.LinearWeightCalculationGroup__c + '|' + od.ID_ERP__c + '|' + wt.ID_ERP__c + '|' + ends.Type__c;

			System.debug('Key field for Pipe Linear Weight table: ' + keyField);
			System.debug('Key field (with hyphens): ' + gps.ID_ERP__c + '-' + product.LinearWeightCalculationGroup__c + '-' + od.ID_ERP__c + '-' + wt.ID_ERP__c + '-' + ends.Type__c);
			System.debug('PLW map: ' + plwIdMap);

			Id plwId = plwIdMap.get(keyField);
			if (plwId != null){
				lwMap.put('kpm', idPlwMap.get(plwId).Weight_kpm__c);
				lwMap.put('ppf', idPlwMap.get(plwId).Weight_ppf__c);
			}
		} else {
			//Вес погонного метра гладких труб вычисляем по формуле:
			lwMap.put('kpm', (od.OD_mm__c - wt.WT_mm__c) * wt.WT_mm__c * 0.02466);
			lwMap.put('ppf', (od.OD_inch__c - wt.WT_inch__c) * wt.WT_inch__c * 10.69);
		}

		return lwMap;
	}

}