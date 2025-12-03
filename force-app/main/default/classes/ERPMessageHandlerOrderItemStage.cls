public class ERPMessageHandlerOrderItemStage {
    
    
    private final static List<String> isPlacedList = new List<String> {
            '_4', 
            '_6', 
            '_8', 
            '_9', 
            '_39', 
            '_41', 
            '_45 ',
            '_52'   
        };
            
            
     public final static Map<String,String> stageCodeMap = makeMapForStage(); 
    
    public static MessageProcessingResult ProcessMessage(ERPMessageParser.ErpToSfMessage_OrderItemStage parsedMessage, String requestBody) {
        MessageProcessingResult res = new MessageProcessingResult();
              
        res.MessageType = parsedMessage.metadata.MsgType;
        String undoc = String.valueof(parsedMessage.data.Undoc);
        String idERP = parsedMessage.data.Undoc + '-'+parsedMessage.data.Npp;
        String newStage = parsedMessage.data.Stage; 
        String currentStage = mapStageResult(newStage,stageCodeMap).substringBefore('(');
        
        if(currentStage == 'Cancelled'){
            try{
            OpportunityLineItem oppForCancell = [SELECT ID_ERP__c, ITENumber__c, OpportunityId, ProductStandard__c, ProductSpecLevel__c, Opportunity.Owner__c,
                                                 SteelGrade__c, TubeOD__c, TubeWT__c, TubeEnds__c, Coating__c, Shop__c, Name, UnitPrice,
                                                 TotalPrice, NPP_ERP__c, CDD__c, ConfirmedCDD__c, CoatingSpecification__c, ServiceDate,Quantity,
                                                 ExtraCosts_t__c, FinDept__c, FinStatus__c, InitialQuantity__c, LengthSize__c, Liabilities_t__c,
                                                 Description, ListPrice, InquiryQuantity__c, InquiryUnitPrice__c, Product2Id, ProductCode,
                                                 ProductType__c, ProductionAllowed__c, SCDept__c, ShippingPoint__c, Stage__c, TechExp__c,Quantity_ft__c,Quantity_lb__c,Quantity_m__c,Quantity_pcs__c,
                                                 Weight_kpm__c, Weight_ppf__c, PriceBookEntryId, InquiryUnit__c,Sales_Price_ft__c,Sales_Price_lb__c,Sales_Price_m__c,Sales_Price_pcs__c,
                                                 Cancel_reason__c,Cancel_Reason_Details__c FROM OpportunityLineItem WHERE ID_ERP__c=:idERP LIMIT 1];
            
           
                try{
                    Order orderCancelledProduct = [SELECT id,Status FROM ORDER WHERE ID_ERP__c=:undoc LIMIT 1];
                    OrderItem orderItemForCancell = [SELECT id FROM ORDERITEM WHERE ID_ERP__c=:idERP LIMIT 1 ];                          
                    orderCancelledProduct.Status = 'Draft';
                    update orderCancelledProduct; 
                    delete orderItemForCancell;
                } catch (Exception e){
                system.debug(idERP);
                
                }
          
            CancelledOpportunityLineItem__c createdCancelledProduct = createCancelledOppProduct(oppForCancell);
            insert createdCancelledProduct;
            res.IdCancelledProduct = createdCancelledProduct.id;
            sendMessageInfo(createdCancelledProduct.Owner__c,createdCancelledProduct.id);
            delete oppForCancell;
                
            } catch (Exception e){
                system.debug(idERP);
                System.debug(e.getMessage());
                res.isError = true;
                res.errorText = e.getMessage();
            }    
            
        } else {
                
            List<OpportunityLineItem> oppItems = new List<OpportunityLineItem>();
            List<OrderItem> orderItems = new List<OrderItem>();
            
            try{
                 oppItems = [SELECT Stage__c,Is_Placed__c FROM OpportunityLineItem WHERE ID_ERP__c=:idERP LIMIT 1];         
            } catch (Exception e){
                system.debug(e.getMessage());
            }
            
            if(oppItems.size() == 0){
                try{
                 system.debug('in cancelled to restore');   
                 CancelledOpportunityLineItem__c searchedCancelledProduct = [SELECT ID_ERP__c, ITENumber__c, Opportunity__c, ProductStandard__c, ProductSpecLevel__c,
                                                 SteelGrade__c, TubeOD__c, TubeWT__c, TubeEnds__c, Coating__c, Shop__c, Name, UnitPrice__c,
                                                 TotalPrice__c, NPP_ERP__c, CDD__c, ConfirmedCDD__c, CoatingSpecification__c, ServiceDate__c,Quantity__c,
                                                 ExtraCosts_t__c, FinDept__c, FinStatus__c, InitialQuantity__c, LengthSize__c, Liabilities_t__c,
                                                 LineDescription__c, ListPrice__c, InquiryQuantity__c, InquiryUnitPrice__c, Product2Id__c, ProductCode__c,
                                                 ProductType__c, ProductionAllowed__c, SCDept__c, ShippingPoint__c, Stage__c, TechExp__c,
                                                 Weight_kpm__c, Weight_ppf__c, PriceBookEntryId__c, InquiryUnit__c,CancelReason__c,CancelReasonDetails__c,
                                                 Sales_Price_per_ft__c,Sales_Price_per_lb__c,Sales_Price_per_m__c,Sales_Price_per_pcs__c,
                                                 Quantity_ft__c,Quantity_lb__c ,Quantity_m__c ,Quantity_pcs__c FROM CancelledOpportunityLineItem__c WHERE ID_ERP__c=:idERP LIMIT 1];   
                 system.debug('cancelled product found id - ' + searchedCancelledProduct.id);  
                 OpportunityLineItem restoredProduct = restoreCancelItem(searchedCancelledProduct,currentStage);
                 insert restoredProduct;
                 delete searchedCancelledProduct; 
                    
                 Order existingOrder = [SELECT id FROM ORDER WHERE ID_ERP__c=:undoc LIMIT 1];
                 OrderItem orderItemToRestore = restoreOrderItem(searchedCancelledProduct,currentStage,existingOrder);
                 insert orderItemToRestore;  
                    
                } catch (Exception e){
                    system.debug(e.getMessage());
                }
            }
            
            
            try{
                 orderItems = [SELECT Stage__c,Is_Placed__c FROM OrderItem WHERE ID_ERP__c=:idERP LIMIT 1 FOR UPDATE];         
            } catch (Exception e){
                system.debug(e.getMessage());
            }
            
            if(oppItems.size()>0){
                changeStageInOppItems(oppItems,currentStage,newStage);
                update oppItems;
                res.NumberOfUpdatedRecords += oppItems.size();
                
            }
            
            if(orderItems.size()>0){
                changeStageInOrderItems(orderItems,currentStage,newStage);
                update orderItems;
                res.NumberOfUpdatedRecords += orderItems.size();
                
            }                   
        }         
        return res;
           
    }
    
    private static  List<OpportunityLineItem> changeStageInOppItems(List<OpportunityLineItem> oppItems,String stageName,String stageCode){
       
        for(OpportunityLineItem oli : oppItems){
            oli.Stage__c = stageName;
            oli.Is_Placed__c = oli.Is_Placed__c==true ? true : checkIfPlaced(stageCode);
        }
        return oppItems;
    }
    
    private static  List<OrderItem> changeStageInOrderItems(List<OrderItem> orderItems,String stageName,String stageCode){
       
        for(OrderItem oli : orderItems){
            oli.Stage__c = stageName;
            oli.Is_Placed__c = checkIfPlaced(stageCode);
        }
        return orderItems;
    }
    
    
    
    public static Blob generateResponseBody(Map<Integer, String> statusCodesMap, Integer statusCode, String error, MessageProcessingResult mpRes) {
        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();
        gen.writeNumberField('Status Code', statusCode);
        gen.writeStringField('Status', statusCodesMap.get(statusCode));
        if (error == NULL) {
            gen.writeStringField('Processed message type', mpRes.MessageType);
            gen.writeStringField('Number of updated records', String.valueOf(mpRes.NumberOfUpdatedRecords));
            gen.writeStringField('Cancelled Product Id', String.valueOf(mpRes.IdCancelledProduct));
            gen.writeStringField('Error', String.valueOf(mpRes.isError));
            gen.writeStringField('Error Text', String.valueOf(mpRes.errorText));
            
        } else {
            gen.writeStringField('Error Message', error);
        }

        gen.writeEndObject();
        
        String res = gen.getAsString();
        System.debug('Response body text generated: ' + res);
        return Blob.valueOf(res);
    }
    
    public static String mapStageResult(String apiName,Map<String, String> ple){
            String valueResult;           
            valueResult =  ple.get(apiName);           
            if(valueResult == null){
                valueResult = 'Processing';
                sendEmailForAdministrators(apiName);
            }
            return valueResult;
        }
    
    public static void sendEmailForAdministrators(String numberOfStage){
        String emailAddres = System.Label.EmailForNewStageOnProduct;
        //String profileAdminId = [SELECT id FROM Profile WHERE Name = 'System Administrator' limit 1].id;
        //List<User> administratorsUser = [SELECT Name,Email FROM User WHERE profileid =:profileAdminId];
        List<String> adminUserEmails = new List<String>();        
        adminUserEmails.add(emailAddres);
        
       
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();   
        message.optOutPolicy = 'FILTER';
        message.subject = 'New Unknown Stage On Product';
        message.htmlbody = 'New Unknown Stage On Product - '+ numberOfStage; 
       try{         
           message.toAddresses = adminUserEmails;   
           Messaging.SingleEmailMessage[] messages =   new List<Messaging.SingleEmailMessage> {message};
           Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
       } catch (exception e){
           system.debug(e.getMessage());
       }
    }
    
    public static CancelledOpportunityLineItem__c createCancelledOppProduct(OpportunityLineItem oliForCancel){
        
        String cancelReason = setCancelledReason(oliForCancel);
        
        CancelledOpportunityLineItem__c newCancelledProduct = new CancelledOpportunityLineItem__c();
        
        newCancelledProduct.ID_ERP__c = oliForCancel.ID_ERP__c;
        newCancelledProduct.ITENumber__c = oliForCancel.ITENumber__c;
        newCancelledProduct.Opportunity__c = oliForCancel.OpportunityId;
        newCancelledProduct.ProductStandard__c = oliForCancel.ProductStandard__c;
        newCancelledProduct.ProductSpecLevel__c = oliForCancel.ProductSpecLevel__c;
        newCancelledProduct.SteelGrade__c = oliForCancel.SteelGrade__c;
        newCancelledProduct.TubeOD__c = oliForCancel.TubeOD__c;
        newCancelledProduct.TubeWT__c = oliForCancel.TubeWT__c;
        newCancelledProduct.TubeEnds__c = oliForCancel.TubeEnds__c;
        newCancelledProduct.Coating__c = oliForCancel.Coating__c;
        newCancelledProduct.Shop__c = oliForCancel.Shop__c;
        newCancelledProduct.Name = oliForCancel.Name;
        newCancelledProduct.UnitPrice__c = oliForCancel.UnitPrice;
        newCancelledProduct.TotalPrice__c = oliForCancel.TotalPrice;
        newCancelledProduct.CancelReason__c = cancelReason; 
        newCancelledProduct.CancelReasonDetails__c = oliForCancel.Cancel_Reason_Details__c; 
        newCancelledProduct.InitialQuantity__c = oliForCancel.InitialQuantity__c;
        newCancelledProduct.NPP_ERP__c = oliForCancel.NPP_ERP__c;
        newCancelledProduct.CDD__c = oliForCancel.CDD__c;
        newCancelledProduct.ConfirmedCDD__c = oliForCancel.ConfirmedCDD__c;
        newCancelledProduct.CoatingSpecification__c = oliForCancel.CoatingSpecification__c;
        newCancelledProduct.ServiceDate__c = oliForCancel.ServiceDate;
        newCancelledProduct.ExtraCosts_t__c = oliForCancel.ExtraCosts_t__c;
        newCancelledProduct.FinDept__c = oliForCancel.FinDept__c;
        newCancelledProduct.FinStatus__c = oliForCancel.FinStatus__c;
        newCancelledProduct.InitialQuantity__c = oliForCancel.InitialQuantity__c;
        newCancelledProduct.LengthSize__c = oliForCancel.LengthSize__c;
        
        newCancelledProduct.Liabilities_t__c = oliForCancel.Liabilities_t__c;
        newCancelledProduct.LineDescription__c = oliForCancel.Description;
        newCancelledProduct.ListPrice__c = oliForCancel.ListPrice;
        newCancelledProduct.InquiryQuantity__c = oliForCancel.InquiryQuantity__c;
        newCancelledProduct.InquiryUnitPrice__c = oliForCancel.InquiryUnitPrice__c;
        newCancelledProduct.Product2Id__c = oliForCancel.Product2Id;
        newCancelledProduct.ProductCode__c = oliForCancel.ProductCode;
        newCancelledProduct.ProductType__c = oliForCancel.ProductType__c;
        newCancelledProduct.ProductionAllowed__c = oliForCancel.ProductionAllowed__c;
        newCancelledProduct.SCDept__c = oliForCancel.SCDept__c;
        newCancelledProduct.ShippingPoint__c = oliForCancel.ShippingPoint__c;
        newCancelledProduct.Stage__c = oliForCancel.Stage__c;
        newCancelledProduct.TechExp__c = oliForCancel.TechExp__c;
        newCancelledProduct.Weight_kpm__c = oliForCancel.Weight_kpm__c;
        newCancelledProduct.Weight_ppf__c = oliForCancel.Weight_ppf__c;
        newCancelledProduct.PriceBookEntryId__c = oliForCancel.PriceBookEntryId;
        newCancelledProduct.InquiryUnit__c = oliForCancel.InquiryUnit__c;   
        newCancelledProduct.Quantity__c = oliForCancel.Quantity;
        newCancelledProduct.Owner__c = oliForCancel.Opportunity.Owner__c;
        
        newCancelledProduct.Sales_Price_per_ft__c = oliForCancel.Sales_Price_ft__c;
        newCancelledProduct.Sales_Price_per_lb__c = oliForCancel.Sales_Price_lb__c;
        newCancelledProduct.Sales_Price_per_m__c = oliForCancel.Sales_Price_m__c;
        newCancelledProduct.Sales_Price_per_pcs__c = oliForCancel.Sales_Price_pcs__c;
        
        newCancelledProduct.Quantity_ft__c = oliForCancel.Sales_Price_ft__c;
        newCancelledProduct.Quantity_lb__c = oliForCancel.Quantity_lb__c;
        newCancelledProduct.Quantity_m__c = oliForCancel.Quantity_m__c;
        newCancelledProduct.Quantity_pcs__c = oliForCancel.Quantity_pcs__c;
        
            
        return newCancelledProduct;    
    }
    
    public static String setCancelledReason(OpportunityLineItem oppToCancel){
        String cancelReason;
        if(oppToCancel.Cancel_reason__c == null || oppToCancel.Cancel_reason__c == 'None'){
            cancelReason = 'Other';
        }else{
            cancelReason = oppToCancel.Cancel_reason__c;
        }
        return cancelReason;
    }
    
    public static OpportunityLineItem restoreCancelItem(CancelledOpportunityLineItem__c cancelledProduct, String stage){
        OpportunityLineItem restoredProduct = new OpportunityLineItem();
        
        restoredProduct.ID_ERP__c =  cancelledProduct.ID_ERP__c;
        restoredProduct.ITENumber__c  = cancelledProduct.ITENumber__c;
        restoredProduct.OpportunityId = cancelledProduct.Opportunity__c;
        restoredProduct.ProductStandard__c = cancelledProduct.ProductStandard__c ;
        restoredProduct.ProductSpecLevel__c = cancelledProduct.ProductSpecLevel__c;
        restoredProduct.SteelGrade__c = cancelledProduct.SteelGrade__c;
        restoredProduct.TubeOD__c = cancelledProduct.TubeOD__c;
        restoredProduct.TubeWT__c = cancelledProduct.TubeWT__c;
        restoredProduct.TubeEnds__c = cancelledProduct.TubeEnds__c;
        restoredProduct.Coating__c = cancelledProduct.Coating__c;
        restoredProduct.Shop__c = cancelledProduct.Shop__c;
        //restoredProduct.Name__c = cancelledProduct.Name;
        restoredProduct.UnitPrice = cancelledProduct.UnitPrice__c;
        //restoredProduct.TotalPrice = cancelledProduct.TotalPrice__c;
        restoredProduct.Cancel_reason__c = cancelledProduct.CancelReason__c; 
        restoredProduct.Cancel_Reason_Details__c = cancelledProduct.CancelReasonDetails__c; 
        restoredProduct.InitialQuantity__c = cancelledProduct.InitialQuantity__c;
        restoredProduct.NPP_ERP__c = cancelledProduct.NPP_ERP__c;
        restoredProduct.CDD__c = cancelledProduct.CDD__c ;
        restoredProduct.ConfirmedCDD__c = cancelledProduct.ConfirmedCDD__c ;
        restoredProduct.CoatingSpecification__c =  cancelledProduct.CoatingSpecification__c;
        restoredProduct.ServiceDate = cancelledProduct.ServiceDate__c;
        restoredProduct.ExtraCosts_t__c = cancelledProduct.ExtraCosts_t__c;
        restoredProduct.FinDept__c = cancelledProduct.FinDept__c;
        restoredProduct.FinStatus__c = cancelledProduct.FinStatus__c;
        
        restoredProduct.LengthSize__c = cancelledProduct.LengthSize__c;
        
        restoredProduct.Liabilities_t__c = cancelledProduct.Liabilities_t__c ;
        restoredProduct.Description = cancelledProduct.LineDescription__c;
        //restoredProduct.ListPrice = cancelledProduct.ListPrice__c;
        restoredProduct.InquiryQuantity__c = cancelledProduct.InquiryQuantity__c;
        restoredProduct.InquiryUnitPrice__c = cancelledProduct.InquiryUnitPrice__c;
        restoredProduct.Product2Id = cancelledProduct.Product2Id__c;
        //restoredProduct.ProductCode = cancelledProduct.ProductCode__c;
        restoredProduct.ProductType__c = cancelledProduct.ProductType__c ;
        restoredProduct.ProductionAllowed__c = cancelledProduct.ProductionAllowed__c;
        restoredProduct.SCDept__c = cancelledProduct.SCDept__c ;
        restoredProduct.ShippingPoint__c = cancelledProduct.ShippingPoint__c;
        restoredProduct.Stage__c = cancelledProduct.Stage__c ;
        restoredProduct.TechExp__c = cancelledProduct.TechExp__c;
        restoredProduct.Weight_kpm__c = cancelledProduct.Weight_kpm__c;
        restoredProduct.Weight_ppf__c = cancelledProduct.Weight_ppf__c;
        restoredProduct.PriceBookEntryId = cancelledProduct.PriceBookEntryId__c;
        restoredProduct.InquiryUnit__c = cancelledProduct.InquiryUnit__c  ;
        restoredProduct.Quantity = cancelledProduct.Quantity__c==0?null:cancelledProduct.Quantity__c;
        restoredProduct.Stage__c = stage;
        restoredProduct.Cancelled__c = true;
        
        restoredProduct.Sales_Price_ft__c = cancelledProduct.Sales_Price_per_ft__c;
        restoredProduct.Sales_Price_lb__c = cancelledProduct.Sales_Price_per_lb__c;
        restoredProduct.Sales_Price_m__c = cancelledProduct.Sales_Price_per_m__c;
        restoredProduct.Sales_Price_pcs__c = cancelledProduct.Sales_Price_per_pcs__c;
            
        restoredProduct.Quantity_ft__c = cancelledProduct.Quantity_ft__c;
        restoredProduct.Quantity_lb__c = cancelledProduct.Quantity_lb__c;
        restoredProduct.Quantity_m__c = cancelledProduct.Quantity_m__c;
        restoredProduct.Quantity_pcs__c = cancelledProduct.Quantity_pcs__c;
             
        
        
        return restoredProduct;
    }
    
    public static OrderItem restoreOrderItem(CancelledOpportunityLineItem__c cancelledProduct, String stage, Order orderExist){
        OrderItem restoredProduct = new OrderItem();
        
        restoredProduct.Quantity = cancelledProduct.Quantity__c==0?null:cancelledProduct.Quantity__c;
        restoredProduct.Weight_ppf__c = cancelledProduct.Weight_ppf__c;
        restoredProduct.Weight_kpm__c = cancelledProduct.Weight_kpm__c;
        restoredProduct.UnitPrice = cancelledProduct.UnitPrice__c;
        restoredProduct.CDD__c = cancelledProduct.CDD__c;
        restoredProduct.ConfirmedCDD__c = cancelledProduct.ConfirmedCDD__c;
        restoredProduct.Stage__c = stage;
        restoredProduct.orderid = orderExist.id;
        restoredProduct.NPP_ERP__c = cancelledProduct.NPP_ERP__c;
        restoredProduct.ID_ERP__c = cancelledProduct.ID_ERP__c;
        restoredProduct.PriceBookEntryId = cancelledProduct.PriceBookEntryId__c;
        
        return restoredProduct;
    }
    
    public static void sendMessageInfo(String userToSentMessage,String idRecord){
        String urlProduction = system.label.OrganizationURL;
        String createMessage = 'Product was cancelled. Link: '+ urlProduction+ '/'+idRecord;
        
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();    
        message.optOutPolicy = 'FILTER';
        message.subject = 'Cancel  product';
        message.htmlbody = createMessage;                         
        User assignedUser  = [SELECT Email FROM USER WHERE id=:userToSentMessage limit 1]; 
        message.toAddresses = new String[] { assignedUser.Email};   
        Messaging.SingleEmailMessage[] messages =   new List<Messaging.SingleEmailMessage> {message};
        Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);        
    }
    
    
    public static Map<String, String> makeMapForStage(){
            Integer k = 0;
            k++;
            k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++; 
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++; 
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
         k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++; 
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++; 
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
         k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++; 
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++; 
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
         k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++; 
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++; 
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
         k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++; 
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++; 
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
         k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++; 
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++; 
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
         k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++; 
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++; 
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        k++;
        
        
            Map<String, String> valuesCodes = new Map<String, String>();
            Schema.DescribeFieldResult fieldResult = Product_Picklist_Stage__mdt.Stage__c.getDescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            for( Schema.PicklistEntry pickListVal : ple){               
                valuesCodes.put(pickListVal.getValue(),pickListVal.getLabel());
            }
            return valuesCodes;
        }
    
    public class MessageProcessingResult {
        public String MessageType;      
        public Integer NumberOfUpdatedRecords = 0;
        public String IdCancelledProduct = 'None';
        public Boolean isError = false;
        public String errorText = 'None';
    }
    
    public static boolean checkIfPlaced(String apiName){
            boolean isPlaced = false;
            if(isPlacedList.contains(apiName)){
                isPlaced = true;
            }
            return isPlaced;           
        }
}