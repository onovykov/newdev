public without sharing class OrderItemDatatableController {
    @AuraEnabled(cacheable=true)
    public static Order getOrderItems(String orderId){
        return [SELECT id, OrderNumber, Type, Account.Name, AdditionalNumber__c, Country__r.Name, EffectiveDate, 
                Status, ProducedQuantity__c, DispatchedQuantity__c, ShippedQuantity__c, Owner.Name, 
                EndDate, ActivatedDate, SecondChoice__c, TotalAmount,
                ProducedPercentage__c, DispatchedPercentage__c, ShippedPercentage__c,
                TotalOrderQuantity__c, CurrencyIsoCode,
                BillingAddress, ShippingAddress, ITENumber__c,
                Owner.Phone, Owner.LastName, Owner.FirstName,
                MarketSegment__c, PO_Number__c,
                    (SELECT Product2.Name, Name__c, Quantity, ProductStandard__r.Name, Stage__c, ProducedQuantity__c, DispatchedQuantity__c, ProdDetails__c,
                        ShippedQuantity__c, Quantity_pcs__c, ProducedQuantity_pcs__c, ShippedQuantity_pcs__c, DispatchedQuantity_pcs__c, UnitPrice, TubeOD__r.OD_inch__c, TubeWT__r.WT_inch__c, TubeLengthSize__r.MinLength__c, TubeLengthSize__r.MaxLength__c,
                        KLWSpec__c, Drawing__c
                    FROM OrderItems)
                FROM Order
				WHERE id = :orderId
            ];
    }

    @AuraEnabled(cacheable=true)
    public static OrderItem getOrderItemSpecification(String orderItemId){
        return [SELECT Product2.Name, Name__c, Quantity, ProductStandard__r.Name, Stage__c, ProducedQuantity__c, DispatchedQuantity__c, ProdDetails__c,
                        ShippedQuantity__c, UnitPrice, TubeOD__r.OD_inch__c, TubeWT__r.WT_inch__c, TubeLengthSize__r.MinLength__c, TubeLengthSize__r.MaxLength__c, 
                        Drawing__r.WheelProduct__c, Drawing__r.Name, KLWSpec__r.Name, KLWSpec__r.ExecCategory__c, KLWSpec__r.Standard__r.Name, KLWSpec__r.Marking__r.Name,
                        KLWSpec__r.Packing__r.Name, KLWSpec__r.Imbalance__r.Name, KLWSpec__r.OilHole__c, KLWSpec__r.PlugType__r.Name, KLWSpec__r.Coating__r.Name,
                        KLWSpec__r.CoatingType__r.Name, KLWSpec__r.Inspection__r.Name, KLWSpec__r.Purpose__r.Name, KLWSpec__r.HasSpecReq__c, KLWSpec__r.WeightKG__c,
                        KLWSpec__r.Shape__r.Name, KLWSpec__r.AxleBox__r.Name, KLWSpec__r.Bearer__r.Name, KLWSpec__r.SpecAxle__r.Name, KLWSpec__r.SpecWheel__r.Name, 
                        KLWSpec__r.SteelGrade__r.Name, KLWSpec__c, NameForDoc_Formula__c, Drawing__c, KLWSpec__r.Packing__r.NameENG__c, KLWSpec__r.Packing__r.NameUKR__c,
                        KLWSpec__r.CoatingType__r.NameENG__c, KLWSpec__r.CoatingType__r.NameUKR__c, KLWSpec__r.Inspection__r.NameENG__c, KLWSpec__r.Inspection__r.NameUKR__c,
                        KLWSpec__r.Purpose__r.NameUKR__c, KLWSpec__r.Purpose__r.NameRUS__c
                FROM OrderItem
				WHERE id = :orderItemId
        ];
    }

    @AuraEnabled(cacheable=true)
    public static String getUserMarketSegment() {
        try {
            String userId = UserInfo.getUserId();
            String idContactUser = [SELECT Contactid FROM User WHERE Id =: userId LIMIT 1].contactid;
            system.debug(idContactUser);
            String accId = [SELECT id, AccountId FROM Contact WHERE id =: idContactUser LIMIT 1].AccountId;
            String segment = [SELECT id, MarketSegment__c FROM Account WHERE id =:accId].MarketSegment__c;
            return  segment;

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}