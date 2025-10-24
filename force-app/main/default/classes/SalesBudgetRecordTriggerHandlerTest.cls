@isTest 
private class SalesBudgetRecordTriggerHandlerTest {

	@isTest
	private static void testMonth() {
		SalesBudget__c sb = new SalesBudget__c();
		Integer year = Date.today().year();
		sb.Type__c = 'Y';
		sb.Year__c = year;
		sb.Name = year + ' - Initial';
		sb.Approved__c = true;
		insert sb;

		ID rtPlanMonthId = [SELECT Id, Name FROM RecordType WHERE SobjectType = 'SalesBudgetRecord__c' And Name = 'Plan Month'].Id;
		SalesBudgetRecord__c sbr = new SalesBudgetRecord__c();
		sbr.RecordTypeId = rtPlanMonthId;
		sbr.SalesBudget__c = sb.Id;
		sbr.PeriodMonth__c = '05';
		sbr.PeriodYear__c = year;
		sbr.SalesManager__c = UserInfo.getUserId();
		sbr.ProductionAmount__c = 90;
		sbr.SalesAmount__c = 90;
		sbr.Revenue__c = 90000;
		sbr.Margin__c = 18000;
		insert sbr;
		
		Id sbrId = sbr.Id;

		sbr = [Select Id, Period__c from SalesBudgetRecord__c where Id = :sbrId];
		System.assertEquals(Date.valueOf(year + '-05-01'), sbr.Period__c);

		sbr.PeriodMonth__c = '02';
		update sbr;
		
		sbr = [Select Id, Period__c from SalesBudgetRecord__c where Id = :sbrId];
		System.assertEquals(Date.valueOf(year + '-02-01'), sbr.Period__c);
	}

	@isTest
	private static void testQuarter() {
		SalesBudget__c sb = new SalesBudget__c();
		Integer year = Date.today().year();
		sb.Type__c = 'Y';
		sb.Year__c = year;
		sb.Name = year + ' - Initial';
		sb.Approved__c = true;
		insert sb;

		ID rtPlanQuarterId = [SELECT Id, Name FROM RecordType WHERE SobjectType = 'SalesBudgetRecord__c' And Name = 'Plan Quarter'].Id;
		System.debug('--- Record Type ID: ' + rtPlanQuarterId);
		SalesBudgetRecord__c sbr = new SalesBudgetRecord__c();
		sbr.RecordTypeId = rtPlanQuarterId;
		sbr.SalesBudget__c = sb.Id;
		sbr.PeriodQuarter__c = '1';
		sbr.PeriodYear__c = year;
		sbr.SalesManager__c = UserInfo.getUserId();
		sbr.ProductionAmount__c = 90;
		sbr.SalesAmount__c = 90;
		sbr.Revenue__c = 90000;
		sbr.Margin__c = 18000;
		insert sbr;

		SalesPlanFact__c spfOpp = new SalesPlanFact__c();
		spfOpp.Type__c = 'Opportunity';
		SalesPlanFact__c spfOrder = new SalesPlanFact__c();
		spfOrder.Type__c = 'Order';
		SalesPlanFact__c spfPlan = new SalesPlanFact__c();
		spfPlan.Type__c = 'Plan';
		SalesPlanFact__c spfFact = new SalesPlanFact__c();
		spfFact.Type__c = 'Fact';

		insert new List<SalesPlanFact__c>{spfOpp, spfOrder, spfPlan, spfFact};

		Id sbrId = sbr.Id;

		sbr = [Select Id, Period__c from SalesBudgetRecord__c where Id = :sbrId];
		System.assertEquals(Date.valueOf(year + '-01-01'), sbr.Period__c);

		sbr.PeriodQuarter__c = '2';
		update sbr;

		sbr = [Select Id, Period__c from SalesBudgetRecord__c where Id = :sbrId];
		System.assertEquals(Date.valueOf(year + '-04-01'), sbr.Period__c);

		sbr.PeriodQuarter__c = '3';
		update sbr;

		sbr = [Select Id, Period__c from SalesBudgetRecord__c where Id = :sbrId];
		System.assertEquals(Date.valueOf(year + '-07-01'), sbr.Period__c);

		sbr.PeriodQuarter__c = '4';
		update sbr;

		sbr = [Select Id, Period__c from SalesBudgetRecord__c where Id = :sbrId];
		System.assertEquals(Date.valueOf(year + '-10-01'), sbr.Period__c);
	}
}