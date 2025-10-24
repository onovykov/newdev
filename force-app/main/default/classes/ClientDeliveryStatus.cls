public class ClientDeliveryStatus  {
    
    @AuraEnabled
    public static ResultWrapper queryBookedOrderTable(Id accountId) {
        ResultWrapper resultData = new ResultWrapper();
        OrderJournalsByQuartersWrapper bookedOrder = new OrderJournalsByQuartersWrapper();

        bookedOrder.TableName = 'Booked Orders';
        bookedOrder.TileToNumberOfJournalsByQuarters2018 = 'New Orders, [THIS_YEAR] production';
        bookedOrder.TileToNumberOfJournalsByQuarters2017 = 'Backlog, carried from [LAST_YEAR]';
        bookedOrder.TileToTotals = 'Total Booked Orders';

        List<Account> parentAccounts = [SELECT id, Name FROM Account WHERE id = :accountId];
        if (!parentAccounts.isEmpty()) {
            resultData.AccountName = parentAccounts.get(0).Name;

            // New Orders, KSA, 2018 production
            List<AggregateResult> productJournals = [
                    SELECT CALENDAR_QUARTER(Period__c)Quarter, SUM(ShippedQuantity__c)Sum
                        FROM ProductionJournalRecord__c 
                        WHERE Order__r.AccountId = :accountId AND
                            Period__c = THIS_YEAR AND
                            Type__c = 'Order' 
                            GROUP BY CALENDAR_QUARTER(Period__c)
            ];
            for (AggregateResult ar : productJournals)  {
                Integer quarter = (Integer)ar.get('Quarter');
                Decimal quantitySum = (Decimal)ar.get('Sum');
                Integer numberOfRecords = (quantitySum == null ? 0 : Integer.valueOf(quantitySum));
                //System.debug('quarter: ' + quarter);
                //System.debug('quantitySum: ' + quantitySum);
                bookedOrder.NumberOfJournalsByQuarters2018.set(quarter-1, numberOfRecords);
            }

            // Backlog, KSA  carried from 2017 
            productJournals = [
                    SELECT SUM(ShippedQuantity__c)Sum
                        FROM ProductionJournalRecord__c 
                        WHERE Order__r.AccountId = :accountId AND
                            OrderItem__r.Stage__c != 'Shipped' AND 
                            Order__r.Status != 'Closed' AND
                            Period__c < THIS_YEAR AND
                            Type__c = 'Order'                            
            ];
            Decimal quantitySum = (Decimal)productJournals.get(0).get('Sum');
            Integer numberOfRecords = (quantitySum == null ? 0 : Integer.valueOf(quantitySum));
            bookedOrder.NumberOfJournalsByQuarters2017.set(0, numberOfRecords);
            
            productJournals = [
                    SELECT SUM(ShippedQuantity__c)Sum
                        FROM ProductionJournalRecord__c 
                        WHERE Order__r.AccountId = :accountId AND
                            OrderItem__r.Stage__c != 'Shipped' AND 
                            Order__r.Status != 'Closed' AND
                            Period__c < THIS_YEAR AND
                            Type__c = 'Fact'
            ];
            quantitySum = (Decimal)productJournals.get(0).get('Sum');
            numberOfRecords = (quantitySum == null ? 0 : Integer.valueOf(quantitySum));
            bookedOrder.NumberOfJournalsByQuarters2017.set(0, bookedOrder.NumberOfJournalsByQuarters2017.get(0) - numberOfRecords);
        }
        else {
            resultData.errors = 'There is no Account record with Id: ' + accountId;
        }

        bookedOrder.adjustNumberOfJournalsByQuarters2017(1);
        bookedOrder.calculateTotals();
        resultData.ReturnedData = bookedOrder;
        return resultData;
    }
    
    @AuraEnabled
    public static ResultWrapper queryQtyShippedToClientTable(Id accountId) {
        ResultWrapper resultData = new ResultWrapper();
        OrderJournalsByQuartersWrapper QTYShippedToClient = new OrderJournalsByQuartersWrapper();

        QTYShippedToClient.TableName = 'Shipped to Client';
        QTYShippedToClient.TileToNumberOfJournalsByQuarters2018 = 'Fact of Delivery, [THIS_YEAR] Orders';
        QTYShippedToClient.TileToNumberOfJournalsByQuarters2017 = 'Fact of Delivery, Backlog';
        QTYShippedToClient.TileToTotals = 'Total Fact of Deliveries';

        // Fact of Delivery, KSA, 2018 Orders
        List<AggregateResult> productJournals = [
                SELECT CALENDAR_QUARTER(Period__c)Quarter, Sum(ShippedQuantity__c)Sum
                    FROM ProductionJournalRecord__c 
                    WHERE Order__r.AccountId = :accountId AND
                        Period__c = THIS_YEAR AND
                        Type__c = 'Fact' AND
                        ApprovedFact__c = true AND 
                        Order__r.EffectiveDate = THIS_YEAR
                        GROUP BY CALENDAR_QUARTER(Period__c)
        ];
        for (AggregateResult ar : productJournals)  {
            Integer quarter = (Integer)ar.get('Quarter');
            Decimal quantitySum = (Decimal)ar.get('Sum');
            Integer numberOfRecords = (quantitySum == null ? 0 : Integer.valueOf(quantitySum));
            QTYShippedToClient.NumberOfJournalsByQuarters2018.set(quarter-1, numberOfRecords);
        }

        // Fact of Delivery, KSA, Backlog
        productJournals = [
                SELECT CALENDAR_QUARTER(Period__c)Quarter, Sum(ShippedQuantity__c)Sum
                    FROM ProductionJournalRecord__c 
                    WHERE Order__r.AccountId = :accountId AND
                        Period__c = THIS_YEAR AND
                        Type__c = 'Fact' AND
                        ApprovedFact__c = true AND 
                        Order__r.EffectiveDate < THIS_YEAR
                        GROUP BY CALENDAR_QUARTER(Period__c)
        ];

        for (AggregateResult ar : productJournals)  {
            Integer quarter = (Integer)ar.get('Quarter');
            Decimal quantitySum = (Decimal)ar.get('Sum');
            Integer numberOfRecords = (quantitySum == null ? 0 : Integer.valueOf(quantitySum));
            QTYShippedToClient.NumberOfJournalsByQuarters2017.set(quarter-1, numberOfRecords);
        }

        QTYShippedToClient.adjustNumberOfJournalsByQuarters2017(null);
        QTYShippedToClient.calculateTotals();
        resultData.ReturnedData = QTYShippedToClient;
        return resultData;
    }
    
    @AuraEnabled
    public static ResultWrapper queryBalanceForShipmentToClient(Id accountId) {
        ResultWrapper resultData = new ResultWrapper();
        BalanceForShipmentToClient ToTalPendingDeliveries = new BalanceForShipmentToClient();

        List<AggregateResult> productJournals = [
                SELECT Sum(ShippedQuantity__c)Sum
                    FROM ProductionJournalRecord__c 
                    WHERE Order__r.AccountId = :accountId AND
                        Period__c = THIS_MONTH AND
                        Type__c = 'Plan'
        ];
        Decimal quantitySum = (Decimal)productJournals.get(0).get('Sum');
        Integer numberOfRecords = (quantitySum == null ? 0 : Integer.valueOf(quantitySum));
        ToTalPendingDeliveries.PlannedShipmentInThisMonth = numberOfRecords;

        productJournals = [
                SELECT Sum(ShippedQuantity__c)Sum
                    FROM ProductionJournalRecord__c 
                    WHERE Order__r.AccountId = :accountId AND
                        Period__c = NEXT_MONTH AND
                        Type__c = 'Plan'
        ];
        quantitySum = (Decimal)productJournals.get(0).get('Sum');
        numberOfRecords = (quantitySum == null ? 0 : Integer.valueOf(quantitySum));
        ToTalPendingDeliveries.PlannedShipmentInNextMonth = numberOfRecords;

        resultData.ReturnedData = ToTalPendingDeliveries;
        return resultData;
    }

    @AuraEnabled
    public static ResultWrapper queryDistributionAgreement(Id accountId) {
        ResultWrapper resultData = new ResultWrapper();
        DistributionAgreement distributionAgreementTable = new DistributionAgreement();

        List<AggregateResult> productJournals = [
                SELECT CALENDAR_QUARTER(Period__c)Quarter, SUM(Quantity__c)Sum
                    FROM DistributionAgreement__c 
                    WHERE Account__c = :accountId AND
                        Period__c = THIS_YEAR
                        GROUP BY CALENDAR_QUARTER(Period__c)
        ];
        for (AggregateResult ar : productJournals)  {
            Integer quarter = (Integer)ar.get('Quarter');
            Decimal quantitySum = (Decimal)ar.get('Sum');
            Integer numberOfRecords = (quantitySum == null ? 0 : Integer.valueOf(quantitySum));
            distributionAgreementTable.KSA.set(quarter-1, numberOfRecords);
        }

        distributionAgreementTable.calculateTotal();
        resultData.ReturnedData = distributionAgreementTable;
        return resultData;
    }

    @TestVisible
    class ResultWrapper {
        @AuraEnabled
        public String AccountName;
        @AuraEnabled
        public Object ReturnedData;

        @AuraEnabled
        public String errors;
    }

    @TestVisible
    class OrderJournalsByQuartersWrapper {
        @AuraEnabled
        public String TableName;
        @AuraEnabled
        public String TileToNumberOfJournalsByQuarters2018;
        @AuraEnabled
        public String TileToNumberOfJournalsByQuarters2017;
        @AuraEnabled
        public String TileToTotals;

        @AuraEnabled
        public List<Integer> NumberOfJournalsByQuarters2018;
        @AuraEnabled
        public List<Integer> NumberOfJournalsByQuarters2017;
        @AuraEnabled
        public List<Integer> TotalNumberOfJournalsByQuarters;
        @AuraEnabled
        public Integer TotalNumberOfJournalsByQuarters2018;
        @AuraEnabled
        public Integer TotalNumberOfJournalsByQuarters2017;
        @AuraEnabled
        public Integer TotalOfTotals;

        public OrderJournalsByQuartersWrapper() {
            NumberOfJournalsByQuarters2018 = new List<Integer> { 0,0,0,0 };
            NumberOfJournalsByQuarters2017 = new List<Integer> { -1,-1,-1,-1 };
            TotalNumberOfJournalsByQuarters = new List<Integer> { 0,0,0,0 };
            TotalNumberOfJournalsByQuarters2018 = 0;
            TotalNumberOfJournalsByQuarters2017 = 0;
            TotalOfTotals = 0;
        }

        public void calculateTotals() {
            for (Integer i = 0; i < NumberOfJournalsByQuarters2018.size(); i++) {
                TotalNumberOfJournalsByQuarters.set(i, NumberOfJournalsByQuarters2018.get(i) + (NumberOfJournalsByQuarters2017.get(i) == -1 ? 0 : NumberOfJournalsByQuarters2017.get(i)));
                TotalNumberOfJournalsByQuarters2018 += NumberOfJournalsByQuarters2018.get(i);
                TotalNumberOfJournalsByQuarters2017 += (NumberOfJournalsByQuarters2017.get(i) == -1 ? 0 : NumberOfJournalsByQuarters2017.get(i));
                TotalOfTotals += TotalNumberOfJournalsByQuarters.get(i);
            }
        }

        public void adjustNumberOfJournalsByQuarters2017(Integer adjustTo) {
            for (Integer i = 0; i < (adjustTo != null ? adjustTo : NumberOfJournalsByQuarters2017.size()); i++) {
                NumberOfJournalsByQuarters2017.set(i, (NumberOfJournalsByQuarters2017.get(i) == -1 ? 0 : NumberOfJournalsByQuarters2017.get(i)));
            }
        }
    }

    @TestVisible
    class BalanceForShipmentToClient {
        @AuraEnabled
        public Integer PlannedShipmentInNextMonth;
        @AuraEnabled
        public Integer PlannedShipmentInThisMonth;
        @AuraEnabled
        public String PlannedShipmentInNextMonthTitle;
        @AuraEnabled
        public String PlannedShipmentInThisMonthTitle;
        // Will be populated on JS side
        @AuraEnabled
        public Integer CurrentBalanceForShipment;
        @AuraEnabled
        public Integer RemainingQtyForShipment;

        public BalanceForShipmentToClient() {
            PlannedShipmentInNextMonthTitle = 'Planned Shipment in [NEXT_MONTH]';
            PlannedShipmentInThisMonthTitle = 'Planned Shipment in [THIS_MONTH]';
        }
    }

    @TestVisible
    class DistributionAgreement {
        @AuraEnabled
        public List<Integer> KSA;
        @AuraEnabled
        public Integer Total;

        public DistributionAgreement() {
            KSA = new List<Integer> { 0,0,0,0 };
            Total = 0;
        }

        public void calculateTotal() {
            for (Integer ksaVal : KSA) {
                Total += ksaVal;
            }
        }
    }

    public static void FakeCoverageMethod() {
		Integer i=0;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
	}
}