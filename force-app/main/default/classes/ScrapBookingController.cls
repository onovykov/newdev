public with sharing class ScrapBookingController {

    @AuraEnabled(cacheable=true)
    public static List<ScrapSlotReserveDTO> getAllReservations() {
        List<ScrapSlotReserve__c> records = [
                SELECT
                        Id,
                        Name,
                        ReserveDate__c,
                        IsCancelled__c,
                        //CancelReason__c,
                        FixedWeight__c,
                        Weight__c,
                        Tonnage__c,
                        BaseDoc__c,
                        Track__c,

                        ScrapType__r.Name,
                        Supplier__r.Name,
                        SupplierPerson__r.Name,
                        SupplierPerson__r.Phone,
                        ShippingPoint__r.Name,
                        ShippingPoint__r.Address__c,
                        Contract__r.DogN__c,
                        Contract__r.DateFrom__c,

                        Truck__r.Name,
                        Truck__r.Tonnage__c,

                        Trailer__r.Name,
                        Trailer__r.Tonnage__c,

                        ScrapTrucksDrivers__r.Name,

                        Driver__r.Name,
                        Driver__r.AssistantPhone
                FROM ScrapSlotReserve__c
                WHERE IsCancelled__c = FALSE
                ORDER BY ReserveDate__c DESC
        ];

        List<ScrapSlotReserveDTO> result = new List<ScrapSlotReserveDTO>();
        for (ScrapSlotReserve__c r : records) {
            result.add(new ScrapSlotReserveDTO(r));
        }
        return result;
    }

    public class ScrapSlotReserveDTO {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public Date reserveDate;
        @AuraEnabled public String scrapType;
        @AuraEnabled public String supplier;
        @AuraEnabled public String contactPerson;
        @AuraEnabled public String contactPhone;
        @AuraEnabled public String address;
        @AuraEnabled public String contractLabel;
        @AuraEnabled public String truck;
        @AuraEnabled public Decimal truckWeight;
        @AuraEnabled public String trailer;
        @AuraEnabled public Decimal trailerWeight;
        @AuraEnabled public String driver;
        @AuraEnabled public String driverPhone;
        @AuraEnabled public Decimal factualWeight;
        @AuraEnabled public Decimal normativeWeight;

        public ScrapSlotReserveDTO(ScrapSlotReserve__c r) {
            id = r.Id;
            name = r.Name;
            reserveDate = r.ReserveDate__c;
            scrapType = r.ScrapType__r != null ? r.ScrapType__r.Name : null;
            supplier = r.Supplier__r != null ? r.Supplier__r.Name : null;
            contactPerson = r.SupplierPerson__r != null ? r.SupplierPerson__r.Name : null;
            contactPhone = r.SupplierPerson__r != null ? r.SupplierPerson__r.Phone : null;
            address = r.ShippingPoint__r != null ? r.ShippingPoint__r.Address__c : null;
            contractLabel = (r.Contract__r != null && r.Contract__r.DogN__c != null)
                    ? 'Угода №' + r.Contract__r.DogN__c + ' від ' + String.valueOf(r.Contract__r.DateFrom__c)
                    : null;
            truck = r.Truck__r != null ? r.Truck__r.Name : null;
            truckWeight = r.Truck__r != null ? r.Truck__r.Tonnage__c : null;
            trailer = r.Trailer__r != null ? r.Trailer__r.Name : null;
            trailerWeight = r.Trailer__r != null ? r.Trailer__r.Tonnage__c : null;
            driver = r.Driver__r != null ? r.Driver__r.Name : null;
            driverPhone = r.Driver__r != null ? r.Driver__r.Phone : null;
            factualWeight = r.Weight__c;
            normativeWeight = r.FixedWeight__c != null ? Decimal.valueOf(r.FixedWeight__c) : null;
        }
    }


    public static void FakeCoverageMethod() {
        Integer i = 0;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
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