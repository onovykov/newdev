@IsTest
public class ClientDeliveryStatusTest  {
    
    // @IsTest
    // public static void queryBookedOrderTableForNotAccountRecordTest() {
    //     Id wrongObjectId = UserInfo.getUserId();

    //     Test.startTest();
    //         ClientDeliveryStatus.ResultWrapper resultData = ClientDeliveryStatus.queryBookedOrderTable(wrongObjectId);
    //     Test.stopTest();

    //     ClientDeliveryStatus.OrderJournalsByQuartersWrapper returnedData = (ClientDeliveryStatus.OrderJournalsByQuartersWrapper)resultData.ReturnedData;

    //     List<Integer> NumberOfJournalsByQuarters2018 = new List<Integer>{0,0,0,0};
    //     List<Integer> NumberOfJournalsByQuarters2017 = new List<Integer>{0,-1,-1,-1};
    //     List<Integer> TotalNumberOfJournalsByQuarters = new List<Integer>{0,0,0,0};

    //     System.assertEquals('There is no Account record with Id: ' + wrongObjectId, resultData.errors);
    //     System.assertEquals(null, resultData.AccountName);
    //     System.assertEquals('Booked Orders', returnedData.TableName);
    //     System.assertEquals('New Orders, [THIS_YEAR] production', returnedData.TileToNumberOfJournalsByQuarters2018);
    //     System.assertEquals('Backlog, carried from [LAST_YEAR]', returnedData.TileToNumberOfJournalsByQuarters2017);
    //     System.assertEquals('Total Booked Orders', returnedData.TileToTotals);
    //     for(Integer i = 0; i < 4; i++) {
    //         System.assertEquals(NumberOfJournalsByQuarters2018.get(i), returnedData.NumberOfJournalsByQuarters2018.get(i));
    //         System.assertEquals(NumberOfJournalsByQuarters2017.get(i), returnedData.NumberOfJournalsByQuarters2017.get(i));
    //         System.assertEquals(TotalNumberOfJournalsByQuarters.get(i), returnedData.TotalNumberOfJournalsByQuarters.get(i));
    //     }
    //     System.assertEquals(0, returnedData.TotalNumberOfJournalsByQuarters2018);
    //     System.assertEquals(0, returnedData.TotalNumberOfJournalsByQuarters2017);
    //     System.assertEquals(0, returnedData.TotalOfTotals);
    // }

    // @IsTest
    // public static void queryBookedOrderTableForAccountRecordWithoutRelatedOrderTest() {
    //     Account testAccount = new Account(Name = 'test');
    //     insert testAccount;

    //     Test.startTest();
    //         ClientDeliveryStatus.ResultWrapper resultData = ClientDeliveryStatus.queryBookedOrderTable(testAccount.id);
    //     Test.stopTest();

    //     ClientDeliveryStatus.OrderJournalsByQuartersWrapper returnedData = (ClientDeliveryStatus.OrderJournalsByQuartersWrapper)resultData.ReturnedData;

    //     List<Integer> NumberOfJournalsByQuarters2018 = new List<Integer>{0,0,0,0};
    //     List<Integer> NumberOfJournalsByQuarters2017 = new List<Integer>{0,-1,-1,-1};
    //     List<Integer> TotalNumberOfJournalsByQuarters = new List<Integer>{0,0,0,0};

    //     System.assertEquals(null, resultData.errors);
    //     System.assertEquals('test', resultData.AccountName);
    //     System.assertEquals('Booked Orders', returnedData.TableName);
    //     System.assertEquals('New Orders, [THIS_YEAR] production', returnedData.TileToNumberOfJournalsByQuarters2018);
    //     System.assertEquals('Backlog, carried from [LAST_YEAR]', returnedData.TileToNumberOfJournalsByQuarters2017);
    //     System.assertEquals('Total Booked Orders', returnedData.TileToTotals);
    //     for(Integer i = 0; i < 4; i++) {
    //         System.assertEquals(NumberOfJournalsByQuarters2018.get(i), returnedData.NumberOfJournalsByQuarters2018.get(i));
    //         System.assertEquals(NumberOfJournalsByQuarters2017.get(i), returnedData.NumberOfJournalsByQuarters2017.get(i));
    //         System.assertEquals(TotalNumberOfJournalsByQuarters.get(i), returnedData.TotalNumberOfJournalsByQuarters.get(i));
    //     }
    //     System.assertEquals(0, returnedData.TotalNumberOfJournalsByQuarters2018);
    //     System.assertEquals(0, returnedData.TotalNumberOfJournalsByQuarters2017);
    //     System.assertEquals(0, returnedData.TotalOfTotals);
    // }

    // @IsTest
    // public static void queryBookedOrderTableForAccountRecordWithRelatedOrdersAndProductionJournalRecordsTest() {
    //     Account testAccount = new Account(Name = 'test');
    //     insert testAccount;

    //     Id standardBookId = Test.getStandardPricebookId();

    //     Order lastYearOrder = new Order(EffectiveDate = Date.newInstance(Date.today().year()-1, 01, 15), AccountId = testAccount.id, Status = 'Draft', pricebook2id = standardBookId);
    //     Order thisYearOrder = new Order(EffectiveDate = Date.newInstance(Date.today().year(), 01, 15), AccountId = testAccount.id, Status = 'Draft', pricebook2id = standardBookId);
    //     List<Order> orders = new List<Order>{
    //         lastYearOrder,
    //         thisYearOrder
    //     };
    //     insert orders;

    //     Product2 test_product = new product2(name='test product');
	// 	test_product.ID_ERP__c = 't1';
	// 	test_product.Type__c = 'Tube';
    //     insert test_product;

    //     Pricebookentry entry = new PricebookEntry(pricebook2id = standardBookId, product2id = test_product.id, unitprice=1.0, isActive = true);
    //     insert entry; 

    //     OrderItem notValidOrderItemRecord = new OrderItem(Stage__c = 'Shipped', ID_ERP__c = '111', OrderId = lastYearOrder.Id, UnitPrice = 3, Quantity = 1, PricebookEntryId = entry.id);
    //     OrderItem validOrderItemRecord = new OrderItem(Stage__c = 'Produced', ID_ERP__c = '222', OrderId = lastYearOrder.Id, UnitPrice = 3, Quantity = 1, PricebookEntryId = entry.id);
    //     List<OrderItem> orderItems = new List<OrderItem>{
    //         notValidOrderItemRecord,
    //         validOrderItemRecord
    //     };
    //     insert orderItems;

    //     Date startDate = Date.newInstance(Date.today().year(), 01, 15);
    //     List<ProductionJournalRecord__c> journals = new List<ProductionJournalRecord__c>();
    //     for(Integer j = 0; j < 2; j++) {
    //         for(Integer i = 0; i < 4; i++) {
    //             journals.add(new ProductionJournalRecord__c(Order__c = orders.get(j).id, OrderItem__c = (j == 0 ? validOrderItemRecord.id : notValidOrderItemRecord.id), ShippedQuantity__c = j * 4 + i, Type__c = 'Order', Period__c = (j == 0 ? startDate.addMonths(i * 3) : startDate.addYears(-1).addMonths(i * 3))));
    //             journals.add(new ProductionJournalRecord__c(Order__c = orders.get(j).id, OrderItem__c = (j == 0 ? validOrderItemRecord.id : notValidOrderItemRecord.id), ShippedQuantity__c = j * 4 + i, Type__c = 'Fact', Period__c = (j == 0 ? startDate.addMonths(i * 3) : startDate.addYears(-1).addMonths(i * 3))));
    //         }
    //     }
    //     insert journals;

    //     /*System.debug('All ProductionJournalRecord__c:');
    //     for(ProductionJournalRecord__c j : journals) {
    //         System.debug(j.Period__c + ' ' + j.ShippedQuantity__c);
    //     }*/
        
    //     Test.startTest();
    //         ClientDeliveryStatus.ResultWrapper resultData = ClientDeliveryStatus.queryBookedOrderTable(testAccount.id);
    //     Test.stopTest();

    //     ClientDeliveryStatus.OrderJournalsByQuartersWrapper returnedData = (ClientDeliveryStatus.OrderJournalsByQuartersWrapper)resultData.ReturnedData;

    //     List<Integer> NumberOfJournalsByQuarters2018 = new List<Integer>{0, 1, 2, 3};
    //     List<Integer> NumberOfJournalsByQuarters2017 = new List<Integer>{1, -1, -1, -1};
    //     List<Integer> TotalNumberOfJournalsByQuarters = new List<Integer>{1, 1, 2, 3};

    //     System.assertEquals(null, resultData.errors);
    //     System.assertEquals('test', resultData.AccountName);
    //     System.assertEquals('Booked Orders', returnedData.TableName);
    //     // System.assertEquals('New Orders, [THIS_YEAR] production', returnedData.TileToNumberOfJournalsByQuarters2018);
    //     // System.assertEquals('Backlog, carried from [LAST_YEAR]', returnedData.TileToNumberOfJournalsByQuarters2017);
    //     System.assertEquals('Total Booked Orders', returnedData.TileToTotals);
    //     for(Integer i = 0; i < 4; i++) {
    //         // System.assertEquals(NumberOfJournalsByQuarters2018.get(i), returnedData.NumberOfJournalsByQuarters2018.get(i));
    //         // System.assertEquals(NumberOfJournalsByQuarters2017.get(i), returnedData.NumberOfJournalsByQuarters2017.get(i));
    //         // System.assertEquals(TotalNumberOfJournalsByQuarters.get(i), returnedData.TotalNumberOfJournalsByQuarters.get(i));
    //     }
    //     // System.assertEquals(6, returnedData.TotalNumberOfJournalsByQuarters2018);
    //     // System.assertEquals(1, returnedData.TotalNumberOfJournalsByQuarters2017);
    //     // System.assertEquals(7, returnedData.TotalOfTotals);
    // }
    
    // @IsTest
    // public static void queryQtyShippedToClientTableForAccountRecordWithoutRelatedOrderTest() {
    //     Id wrongObjectId = UserInfo.getUserId();

    //     Test.startTest();
    //         ClientDeliveryStatus.ResultWrapper resultData = ClientDeliveryStatus.queryQtyShippedToClientTable(wrongObjectId);
    //     Test.stopTest();

    //     ClientDeliveryStatus.OrderJournalsByQuartersWrapper returnedData = (ClientDeliveryStatus.OrderJournalsByQuartersWrapper)resultData.ReturnedData;

    //     System.assertEquals(null, resultData.errors);
    //     System.assertEquals(null, resultData.AccountName);
    //     System.assertEquals('Shipped to Client', returnedData.TableName);
    //     System.assertEquals('Fact of Delivery, [THIS_YEAR] Orders', returnedData.TileToNumberOfJournalsByQuarters2018);
    //     System.assertEquals('Fact of Delivery, Backlog', returnedData.TileToNumberOfJournalsByQuarters2017);
    //     System.assertEquals('Total Fact of Deliveries', returnedData.TileToTotals);
    //     for(Integer i = 0; i < 4; i++) {
    //         System.assertEquals(0, returnedData.NumberOfJournalsByQuarters2018.get(i));
    //         System.assertEquals(0, returnedData.NumberOfJournalsByQuarters2017.get(i));
    //         System.assertEquals(0, returnedData.TotalNumberOfJournalsByQuarters.get(i));
    //     }
    //     System.assertEquals(0, returnedData.TotalNumberOfJournalsByQuarters2018);
    //     System.assertEquals(0, returnedData.TotalNumberOfJournalsByQuarters2017);
    //     System.assertEquals(0, returnedData.TotalOfTotals);
    // }
    
    // @IsTest
    // public static void queryQtyShippedToClientTableForAccountRecordWithRelatedOrdersAndProductionJournalRecordsTest() {
    //     Account testAccount = new Account(Name = 'test');
    //     insert testAccount;

    //     Order lastYearOrder = new Order(EffectiveDate = Date.newInstance(Date.today().year()-1, 01, 15), AccountId = testAccount.id, Status = 'Draft');
    //     Order thisYearOrder = new Order(EffectiveDate = Date.newInstance(Date.today().year(), 01, 15), AccountId = testAccount.id, Status = 'Draft');
    //     List<Order> orders = new List<Order>{
    //         lastYearOrder,
    //         thisYearOrder
    //     };
    //     insert orders;

    //     Date startDate = Date.newInstance(Date.today().year(), 01, 15);
    //     List<ProductionJournalRecord__c> journals = new List<ProductionJournalRecord__c>();
    //     for(Integer j = 0; j < 2; j++) {
    //         for(Integer i = 0; i < 4; i++) {
    //             journals.add(new ProductionJournalRecord__c(Order__c = (j == 0 ? thisYearOrder.id : lastYearOrder.id), ShippedQuantity__c = j * 4 + i, ApprovedFact__c = true, Type__c = 'Fact', Period__c = startDate.addMonths(i * 3) ));
    //         }
    //     }
    //     insert journals;

    //     Test.startTest();
    //         ClientDeliveryStatus.ResultWrapper resultData = ClientDeliveryStatus.queryQtyShippedToClientTable(testAccount.id);
    //     Test.stopTest();

    //     ClientDeliveryStatus.OrderJournalsByQuartersWrapper returnedData = (ClientDeliveryStatus.OrderJournalsByQuartersWrapper)resultData.ReturnedData;

    //     List<Integer> NumberOfJournalsByQuarters2018 = new List<Integer>{0,1,2,3};
    //     List<Integer> NumberOfJournalsByQuarters2017 = new List<Integer>{4,5,6,7};
    //     List<Integer> TotalNumberOfJournalsByQuarters = new List<Integer>{4,6,8,10};

    //     System.assertEquals(null, resultData.errors);
    //     System.assertEquals(null, resultData.AccountName);
    //     System.assertEquals('Shipped to Client', returnedData.TableName);
    //     System.assertEquals('Fact of Delivery, [THIS_YEAR] Orders', returnedData.TileToNumberOfJournalsByQuarters2018);
    //     System.assertEquals('Fact of Delivery, Backlog', returnedData.TileToNumberOfJournalsByQuarters2017);
    //     System.assertEquals('Total Fact of Deliveries', returnedData.TileToTotals);
    //     for(Integer i = 0; i < 4; i++) {
    //         System.assertEquals(NumberOfJournalsByQuarters2018.get(i), returnedData.NumberOfJournalsByQuarters2018.get(i));
    //         System.assertEquals(NumberOfJournalsByQuarters2017.get(i), returnedData.NumberOfJournalsByQuarters2017.get(i));
    //         System.assertEquals(TotalNumberOfJournalsByQuarters.get(i), returnedData.TotalNumberOfJournalsByQuarters.get(i));
    //     }
    //     System.assertEquals(6, returnedData.TotalNumberOfJournalsByQuarters2018);
    //     System.assertEquals(22, returnedData.TotalNumberOfJournalsByQuarters2017);
    //     System.assertEquals(28, returnedData.TotalOfTotals);
    // }
    
    // @IsTest
    // public static void queryBalanceForShipmentToClientTest() {
    //     Account testAccount = new Account(Name = 'test');
    //     insert testAccount;

    //     Order lastYearOrder = new Order(EffectiveDate = Date.newInstance(Date.today().year()-1, 01, 15), AccountId = testAccount.id, Status = 'Draft');
    //     Order thisYearOrder = new Order(EffectiveDate = Date.newInstance(Date.today().year(), 01, 15), AccountId = testAccount.id, Status = 'Draft');
    //     List<Order> orders = new List<Order>{
    //         lastYearOrder,
    //         thisYearOrder
    //     };
    //     insert orders;

    //     Date startDate = Date.newInstance(Date.today().year(), 01, 15);
    //     List<ProductionJournalRecord__c> journals = new List<ProductionJournalRecord__c>();
    //     for(Integer j = 0; j < 2; j++) {
    //         for(Integer i = 0; i < 4; i++) {
    //             journals.add(new ProductionJournalRecord__c(Order__c = orders.get(j).id, Type__c = 'Plan', Period__c = startDate.addMonths((-1) * i + 1)));
    //             journals.add(new ProductionJournalRecord__c(Order__c = orders.get(j).id, Type__c = 'Plan', Period__c = startDate.addMonths((-1) * i + 1)));
    //         }
    //     }
    //     insert journals;

    //     Test.startTest();
    //         ClientDeliveryStatus.ResultWrapper resultData = ClientDeliveryStatus.queryBalanceForShipmentToClient(testAccount.id);
    //     Test.stopTest();

    //     ClientDeliveryStatus.BalanceForShipmentToClient returnedData = (ClientDeliveryStatus.BalanceForShipmentToClient)resultData.ReturnedData;

    //     System.assertEquals(null, resultData.errors);
    //     System.assertEquals(null, resultData.AccountName);
    //     System.assertEquals('Planned Shipment in [NEXT_MONTH]', returnedData.PlannedShipmentInNextMonthTitle);
    //     System.assertEquals('Planned Shipment in [THIS_MONTH]', returnedData.PlannedShipmentInThisMonthTitle);
    //     System.assertEquals(0, returnedData.PlannedShipmentInNextMonth);
    //     System.assertEquals(0, returnedData.PlannedShipmentInThisMonth);
    // }

    // @IsTest
    // public static void queryDistributionAgreementTest() {
    //     Account testAccount = new Account(Name = 'test');
    //     insert testAccount;

    //     Date startDate = Date.newInstance(Date.today().year(), 01, 15);
    //     List<DistributionAgreement__c> agreements = new List<DistributionAgreement__c>();
    //     for(Integer i = 0; i < 4; i++) {
    //         agreements.add(new DistributionAgreement__c(Account__c = testAccount.id,  Period__c = startDate.addMonths(i * 3), Quantity__c = i));
    //     }
    //     insert agreements;

    //     Test.startTest();
    //         ClientDeliveryStatus.ResultWrapper resultData = ClientDeliveryStatus.queryDistributionAgreement(testAccount.id);
    //     Test.stopTest();

    //     ClientDeliveryStatus.DistributionAgreement returnedData = (ClientDeliveryStatus.DistributionAgreement)resultData.ReturnedData;

    //     List<Integer> KSA = new List<Integer>{0,1,2,3};

    //     System.assertEquals(null, resultData.errors);
    //     System.assertEquals(null, resultData.AccountName);
    //     for(Integer i = 0; i < 4; i++) {
    //         System.assertEquals(KSA.get(i), returnedData.KSA.get(i));
    //     }
    //     System.assertEquals(6, returnedData.Total);
    // }
}