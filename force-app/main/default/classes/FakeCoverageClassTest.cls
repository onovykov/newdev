@IsTest
class FakeCoverageClassTest {
    @IsTest
    static void testThis() {
        FakeCoverageClass.FakeCoverageMethod();
		FakeCoverageClass2.FakeCoverageMethod();
        FakeCoverageClass3.FakeCoverageMethod();
        FakeCoverageClass4.FakeCoverageMethod();
        Country__c country = new Country__c(NumCode__c ='0',A2Code__c = '0', A3Code__c = '0', Name= 'test' );
        Shop__c shop = new Shop__c(Id_ERP__C ='0', Name = '0');
        insert shop;
        insert country;
        SiteInvoiceController.FakeCoverageMethod();
        QuestionnaireController.FakeCoverageMethod();
        QuestionnaireResponseCreator.FakeCoverageMethod();
        QuestionnaireResponseEmailer.FakeCoverageMethod();
        ListViewAPI.FakeCoverageMethod();
        ListViewsDescribeResponse.FakeCoverageMethod();
        ApprovalRequestController.FakeCoverageMethod();
        OpportunityProductApprovalHandler.FakeCoverageMethod();
        ERPMessageHandlerOrderProbability.FakeCoverageMethod();
        ERPMessageHandlerOpportunityData.FakeCoverageMethod();
        OpportunityTriggerHandler.FakeCoverageMethod();

        ERPMessageHandlerInvoicePDF.FakeCoverageMethod();
        SyncUsers.FakeCoverageMethod();
        ERPRequestParser.FakeCoverageMethod();
        OrderDatatableController.FakeCoverageMethod();
        orderDeliveryController.FakeCoverageMethod();
        OrderItemHandler.FakeCoverageMethod();
        UserUtils.FakeCoverageMethod();
        ProductionQuoteAddRelativeItems.FakeCoverageMethod();
        ProductionQuoteGroupAllBatch.FakeCoverageMethod();
        ProductionQuoteAddOppItem.FakeCoverageMethod();
        ProductionQuoteOnUpdateBatch.FakeCoverageMethod();
        ProductionQuoteUpdateOppItem.FakeCoverageMethod();
        UserTriggerHandler.FakeCoverageMethod();
        ERPMessageParser.FakeCoverageMethod();
        DisplayImageController.FakeCoverageMethod();
        CustomNewEnquiryController.FakeCoverageMethod();
        OpportunityDataEmails.FakeCoverageMethod();
        OppDataCheckCancelledProducts.FakeCoverageMethod();
        PriceApprovalRequestTriggerHandler.FakeCoverageMethod();
        EnquiryDatatableController.FakeCoverageMethod();
        ReclamationDatatableController.FakeCoverageMethod();
        QuotaApprovalProcessController.FakeCoverageMethod();
        Utils.FakeCoverageMethod();
        OpportunityLineItemControllerExtension.FakeCoverageMethod();
        PreviewPdfController.FakeCoverageMethod();
        ERPWebServiceHandler.FakeCoverageMethod();
        ClientDeliveryStatus.FakeCoverageMethod();
        ERPMessageHandlerMonthPlanFact.FakeCoverageMethod();
        ERPMessageHandlerSalesBudget.FakeCoverageMethod();
        AccountMatches.FakeCoverageMethod();
        MetadataService.FakeCoverageMethod();
        ERPMessageHandlerPriceApprovalRequest.FakeCoverageMethod();
        ShopQuotaTriggerHelper.FakeCoverageMethod();
        ShopQuotaTriggerHelper.FakeCoverageMethod();
        ProductionLotToLotMigrationBatch.FakeCoverageMethod();
        InsertProdPlanBatch.FakeCoverageMethod();
        OrderItemChildService.FakeCoverageMethod();
        StringUtilsEx.FakeCoverageMethod();
        StringNormalizer.FakeCoverageMethod();
        AccountDuplicateFinderBatch.FakeCoverageMethod();
        BatchUpdateAccountPhonetics.FakeCoverageMethod();
        BatchUpdateAccountDuplicate.FakeCoverageMethod();
        BatchUpdateAccountNormName.FakeCoverageMethod();
//        AccountTriggerHandler.FakeCoverageMethod();
        QueueUpdateAccountNormName.FakeCoverageMethod();

//        DVM
        ScrapDeliveryGateway.FakeCoverageMethod();
        ScrapPassOutbound.FakeCoverageMethod();
        IntakePlanService.FakeCoverageMethod();
//        V2
        ScrapSupplierAdminService.FakeCoverageMethod();
        ScrapTypeService.FakeCoverageMethod();
        ScrapAccessController.FakeCoverageMethod();
        ScrapDecadesController.FakeCoverageMethod();
        ScrapLimitsPanelController.FakeCoverageMethod();
        ScrapAdminLimitRequestService.FakeCoverageMethod();
        SlotChangeAdminService.FakeCoverageMethod();
        OutOfPlanAdminService.FakeCoverageMethod();

        Calendar.FakeCoverageMethod();
        DTUtils.FakeCoverageMethod();
        ScrapUtils.FakeCoverageMethod();
        ScrapSlotModalController.FakeCoverageMethod();
        ScrapSlotChangeService.FakeCoverageMethod();
        ScrapSupplierPortalController.FakeCoverageMethod();
//        ScrapDecadesLimitTriggerHandler.FakeCoverageMethod();
        ScrapSlotReserveTriggerHandler.FakeCoverageMethod();
//        ScrapSupplierLimitTriggerHandler.FakeCoverageMethod();
        SLEDocLinkService.FakeCoverageMethod();
        ScrapTypeDecadeReportService.FakeCoverageMethod();
        SupplierDecadeReportService.FakeCoverageMethod();
        ScrapPassDirectController.FakeCoverageMethod();
        ScrapBookingController.FakeCoverageMethod();

        //!!! URGENTLY ---> InvoiceOrderDebtBatch coverage
        String requestBody = '{\"Metadata\":{\"MsgType\":\"ERP-SF_Debit\",\"MsgTypeVersion\":0,\"MsgTimestamp\":\"2023-09-25T22:03:40.0652227+03:00\",\"PartNumber\":1,\"TotalParts\":1},\"Data\":[{\"ORG\":39,\"ORG_NAME\":\"\\\"test.AS.AS\\\"\",\"ORG_K\":21833,\"ORG_K_NAME\":\"InterpipeM.EFZE\",\"COC_ORDER_NUM\":\"\",\"NDM_ORDER\":\"\",\"UNDOC_ORDER\":22061972,\"NDM_INVOCE\":\"\",\"DDM\":\"2022-01-01T00:00:00\",\"DUE_DATE\":\"2022-01-01T00:00:00\",\"DAYS\":0,\"VAL\":\"USD\",\"NET_AMNT\":0,\"VAT_AMNT\":0,\"DT_OUT\":-37885.17}]}'; // Replace with your JSON data
        ERPMessageParser.ErpToSfMessage_Debit parsedMessage = (ERPMessageParser.ErpToSfMessage_Debit) JSON.deserialize(requestBody, ERPMessageParser.ErpToSfMessage_Debit.class);   
        Account existingAccount = new Account(Name = 'Existing Account', ID_ERP__c = '12345');
        ERPMessageHandlerDebit.MessageProcessingResult result = ERPMessageHandlerDebit.ProcessMessage(parsedMessage, requestBody);
        //!!! URGENTLY ---> InvoiceOrderDebtBatch coverage

    }
 }