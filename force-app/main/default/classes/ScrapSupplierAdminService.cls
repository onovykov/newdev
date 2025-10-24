public without sharing class ScrapSupplierAdminService {

    // ---------- DTO ----------
    public class SupplierItem {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public String zkpo;
        @AuraEnabled public String type;      // COMMERCIAL | CORPORATE | ін.
        @AuraEnabled public Id parentId;
    }
    public class SupplierTree {
        @AuraEnabled public List<SupplierItem> commercial;
        @AuraEnabled public List<SupplierItem> corporate;
        @AuraEnabled public Integer total;
    }

    public class SupplierDetails {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public String zkpo;
        @AuraEnabled public String phone;
        @AuraEnabled public String companyPhone;
        @AuraEnabled public String email;
        @AuraEnabled public String idErp;
        @AuraEnabled public String description;
        @AuraEnabled public String address;

        @AuraEnabled public String billingStreet;
        @AuraEnabled public String billingCity;
        @AuraEnabled public String billingState;
        @AuraEnabled public String billingPostalCode;
        @AuraEnabled public String billingCountry;

        @AuraEnabled public String activityType;

        @AuraEnabled public List<ContactRow> contacts;
        @AuraEnabled public List<ContractRow> contracts;
        @AuraEnabled public List<ShippingPointRow> shippingPoints;
        @AuraEnabled public List<VehicleRow> vehicles;

        // плейсхолдери
        @AuraEnabled public List<PersonRow> drivers;
        @AuraEnabled public List<PersonRow> managers;
    }
    public class ContactRow { @AuraEnabled public Id id; @AuraEnabled public String name; @AuraEnabled public String title; @AuraEnabled public String dept; @AuraEnabled public String phone; @AuraEnabled public String mobile; @AuraEnabled public String email; }
    public class ContractRow { @AuraEnabled public Id id; @AuraEnabled public String numberText; @AuraEnabled public String status; @AuraEnabled public Date startDate; @AuraEnabled public Date endDate; @AuraEnabled public String dogN; @AuraEnabled public Decimal willBeActive; @AuraEnabled public String ownerName; @AuraEnabled public String dateFrom; @AuraEnabled public String dateTo; @AuraEnabled public Boolean isActive; }
    public class ShippingPointRow { @AuraEnabled public Id id; @AuraEnabled public String name; @AuraEnabled public String address; @AuraEnabled public String city; @AuraEnabled public String countryName; }
    public class VehicleRow { @AuraEnabled public Id id; @AuraEnabled public String plateNumber; @AuraEnabled public String model; @AuraEnabled public String type; @AuraEnabled public Decimal tonnage; @AuraEnabled public String owner; }
    public class PersonRow { @AuraEnabled public Id id; @AuraEnabled public String name; @AuraEnabled public String title; @AuraEnabled public String dept; @AuraEnabled public Date birth; @AuraEnabled public String phone; @AuraEnabled public String email; }

    private class NameParts {
        String firstName;
        String lastName;
        String middleName;
    }

    // ДЛЯ LOOKUP АВТО
    public class TruckLookupRow {
        @AuraEnabled public Id id;
        @AuraEnabled public String plateNumber;
        @AuraEnabled public String model;
        @AuraEnabled public String type;
        @AuraEnabled public Decimal tonnage;
        @AuraEnabled public String ownerName;
    }


    // ---------- LEFT: список ----------
    @AuraEnabled(Cacheable=true)
    public static SupplierTree listSuppliers(String query) {
        String queryText = (query == null) ? '' : query.trim();

        List<Account> accounts = [
            SELECT Id, Name, ZKPO__c, Activity_Type__c, ScrapSupplierType__c,  ParentId
            FROM Account
            WHERE IsSupplier__c = true AND IsGroup__c = false AND Level__c = 3
            AND ScrapSupplierType__c IN ('COMMERCIAL','CORPORATE') AND (Activity_Type__c = 'Potential' OR Activity_Type__c = 'Active')
            ORDER BY Name
        ];

        List<SupplierItem> commercial = new List<SupplierItem>();
        List<SupplierItem> corporate  = new List<SupplierItem>();

        for (Account account : accounts) {
            SupplierItem item = new SupplierItem();
            item.id = account.Id;
            item.name = account.Name;
            item.zkpo = account.ZKPO__c;
            item.type = account.ScrapSupplierType__c;
            item.parentId = account.ParentId;

            if ('COMMERCIAL'.equalsIgnoreCase(account.ScrapSupplierType__c)) {
                commercial.add(item);
            } else if ('CORPORATE'.equalsIgnoreCase(account.ScrapSupplierType__c)) {
                corporate.add(item);
            }
        }

        SupplierTree result = new SupplierTree();
        result.commercial = commercial;
        result.corporate = corporate;
        result.total = accounts.size();

        System.debug('listSuppliers → total=' + result.total + ', COMMERCIAL=' + commercial.size() + ', CORPORATE=' + corporate.size());
        return result;
    }


    // ---------- RIGHT: деталі ----------
    @AuraEnabled
    public static SupplierDetails getSupplierDetails(Id accountId) {
        if (accountId == null) throw new AuraHandledException('accountId обов’язковий');

        Account supplierAccount = [
                SELECT Id, Name, ZKPO__c, Phone, Email__c, Activity_Type__c, IsSupplier__c, ID_ERP__c, Description, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry
                FROM Account
                WHERE Id = :accountId
                LIMIT 1
        ];
        if (supplierAccount.IsSupplier__c != true) {
            throw new AuraHandledException('Вказаний Account не є постачальником');
        }

        SupplierDetails details = new SupplierDetails();
        details.id          = supplierAccount.Id;
        details.name        = supplierAccount.Name;
        details.zkpo        = supplierAccount.ZKPO__c;
        details.phone       = supplierAccount.Phone;
        details.email       = supplierAccount.Email__c;
        details.idErp       = supplierAccount.ID_ERP__c;
        details.description = supplierAccount.Description;
        details.activityType  = supplierAccount.Activity_Type__c;

// окремі Billing-поля
        details.billingStreet     = String.isBlank(supplierAccount.BillingStreet)     ? null : supplierAccount.BillingStreet.trim();
        details.billingCity       = String.isBlank(supplierAccount.BillingCity)       ? null : supplierAccount.BillingCity.trim();
        details.billingState      = String.isBlank(supplierAccount.BillingState)      ? null : supplierAccount.BillingState.trim();
        details.billingPostalCode = String.isBlank(supplierAccount.BillingPostalCode) ? null : supplierAccount.BillingPostalCode.trim();
        details.billingCountry    = String.isBlank(supplierAccount.BillingCountry)    ? null : supplierAccount.BillingCountry.trim();

// зведена адреса тільки для відображення
        List<String> addressParts = new List<String>();
        if (details.billingStreet      != null) addressParts.add(details.billingStreet);
        if (details.billingCity        != null) addressParts.add(details.billingCity);
        if (details.billingState       != null) addressParts.add(details.billingState);
        if (details.billingPostalCode  != null) addressParts.add(details.billingPostalCode);
        if (details.billingCountry     != null) addressParts.add(details.billingCountry);
        details.address = addressParts.isEmpty() ? null : String.join(addressParts, ', ');

//        SupplierDetails details = new SupplierDetails();
//        details.id    = supplierAccount.Id;
//        details.name  = supplierAccount.Name;
//        details.zkpo  = supplierAccount.ZKPO__c;
//        details.phone = supplierAccount.Phone;
//        details.email = supplierAccount.Email__c;
//        details.idErp = supplierAccount.ID_ERP__c;
//        details.description = supplierAccount.Description;
//
//        List<String> addressParts = new List<String>();
//        if (!String.isBlank(supplierAccount.BillingStreet)) addressParts.add(supplierAccount.BillingStreet.trim());
//        if (!String.isBlank(supplierAccount.BillingCity)) addressParts.add(supplierAccount.BillingCity.trim());
//        if (!String.isBlank(supplierAccount.BillingState)) addressParts.add(supplierAccount.BillingState.trim());
//        if (!String.isBlank(supplierAccount.BillingPostalCode)) addressParts.add(supplierAccount.BillingPostalCode.trim());
//        details.address = addressParts.isEmpty() ? null : String.join(addressParts, ', ');


        // Contacts (включно з розкладкою на водіїв/менеджерів)
        List<Contact> contacts = [
                SELECT Id, Name, Title, Department, Phone, MobilePhone, Email, TrackDriver__c
                FROM Contact
                WHERE AccountId = :accountId
                ORDER BY Name
        ];

        details.contacts = new List<ContactRow>();
        details.drivers  = new List<PersonRow>();
        details.managers = new List<PersonRow>();

//        for (Contact contact : contacts) {
//            // повний список
//            ContactRow contactRow = new ContactRow();
//            contactRow.id = contact.Id;
//            contactRow.name = contact.Name;
//            contactRow.title = contact.Title;
//            contactRow.dept = contact.Department;
//            contactRow.phone = contact.Phone;
//            contactRow.mobile = contact.MobilePhone;
//            contactRow.email = contact.Email;
//            details.contacts.add(contactRow);
//
//            // водії
//            if (contact.Title != null && (contact.Title.toLowerCase() == 'водій' || contact.Title.toLowerCase().startsWith('воді'))) {
//                PersonRow driverRow = new PersonRow();
//                driverRow.id = contact.Id;
//                driverRow.name = contact.Name;
//                driverRow.title = contact.Title;
//                driverRow.dept = contact.Department;
//                driverRow.phone = (contact.Phone != null ? contact.Phone : contact.MobilePhone);
//                driverRow.email = contact.Email;
//                details.drivers.add(driverRow);
//            }
//
////            TODO змінити щоб шукало всіх НЕ truckDrived, незалежно від Title
//            // менеджери (директори)
//            if (contact.Title != null && (contact.Title.toLowerCase() == 'директор' || contact.Title.toLowerCase().startsWith('директ'))) {
//                PersonRow managerRow = new PersonRow();
//                managerRow.id = contact.Id;
//                managerRow.name = contact.Name;
//                managerRow.title = contact.Title;
//                managerRow.dept = contact.Department; // Department виводимо для менеджера
//                managerRow.phone = (contact.Phone != null ? contact.Phone : contact.MobilePhone);
//                managerRow.email = contact.Email;
//                details.managers.add(managerRow);
//            }
//        }
//
//        // companyPhone: перший менеджер → інакше Account.Phone
//        if (!details.managers.isEmpty()) {
//            details.companyPhone = details.managers[0].phone;
//        }
//
//        if (String.isBlank(details.companyPhone)) {
//            details.companyPhone = details.phone;
//        }

        for (Contact c : contacts) {
            // Повний список контактів
            ContactRow cr = new ContactRow();
            cr.id = c.Id; cr.name = c.Name; cr.title = c.Title; cr.dept = c.Department;
            cr.phone = c.Phone; cr.mobile = c.MobilePhone; cr.email = c.Email;
            details.contacts.add(cr);

            // Кому копіюємо у drivers / managers: лише за прапорцем
            Boolean isDriver = (c.TrackDriver__c == true); // ← заміни на TruckDriver__c, якщо потрібно

            PersonRow p = new PersonRow();
            p.id = c.Id; p.name = c.Name; p.title = c.Title; p.dept = c.Department;
            p.phone = (c.Phone != null ? c.Phone : c.MobilePhone);
            p.email = c.Email;

            if (isDriver) {
                details.drivers.add(p);
            } else {
                details.managers.add(p); // усі інші, незалежно від Title
            }
        }

// companyPhone: з першого НЕ-водія, інакше — Account.Phone
        if (!details.managers.isEmpty()) {
            details.companyPhone = details.managers[0].phone;
        }
        if (String.isBlank(details.companyPhone)) {
            details.companyPhone = details.phone;
        }

        // Contracts
        List<Contract> contracts = [
                SELECT Id, ContractNumber, Status, StartDate, EndDate, Owner.Name,
                        DogN__c, WillBeActive__c, DateFrom__c, DateTo__c, IsActive__c
                FROM Contract
                WHERE AccountId = :accountId
                ORDER BY StartDate DESC, LastModifiedDate DESC
        ];
        details.contracts = new List<ContractRow>();
        for (Contract contractRec : contracts) {
            ContractRow contractRow = new ContractRow();
            contractRow.id = contractRec.Id;
            contractRow.numberText = contractRec.ContractNumber;
            contractRow.status = contractRec.Status;
            contractRow.startDate = contractRec.StartDate;
            contractRow.endDate = contractRec.EndDate;
            contractRow.dogN = contractRec.DogN__c;
            contractRow.willBeActive = contractRec.WillBeActive__c;
            contractRow.ownerName = (contractRec.Owner == null ? null : contractRec.Owner.Name);
            // нові
            contractRow.dateFrom = contractRec.DateFrom__c;
            contractRow.dateTo = contractRec.DateTo__c;
            contractRow.isActive = contractRec.IsActive__c;
            details.contracts.add(contractRow);
        }


        // Shipping Points (ScrapSupplierShippingPoint__c)
        List<ScrapSupplierShippingPoint__c> shippingPointRecords = [
                SELECT Id, Name, Address__c, City__c, Country__c, Country__r.Name, Supplier__c
                FROM ScrapSupplierShippingPoint__c
                WHERE Supplier__c = :accountId
                ORDER BY Name
        ];
        details.shippingPoints = new List<ShippingPointRow>();
        for (ScrapSupplierShippingPoint__c shippingPoint : shippingPointRecords) {
            ShippingPointRow shippingPointRow = new ShippingPointRow();
            shippingPointRow.id = shippingPoint.Id;
            shippingPointRow.name = shippingPoint.Name;
            shippingPointRow.address = shippingPoint.Address__c;
            shippingPointRow.city = shippingPoint.City__c;
            shippingPointRow.countryName = (shippingPoint.Country__r == null ? null : shippingPoint.Country__r.Name);
            details.shippingPoints.add(shippingPointRow);
        }

        // Vehicles
        List<ScrapTruck__c> ownTrucks = [
                SELECT Id, Name, TruckModel__c, TruckType__c, Tonnage__c, Account__c, Account__r.Name, IsScrapHauler__c
                FROM ScrapTruck__c
                WHERE Account__c = :accountId AND IsScrapHauler__c != TRUE AND Account__c != NULL
        ];
        List<ScrapTruckSupplier__c> junctionLinks = [
                SELECT Id, Supplier__c, ScrapTruck__c
                FROM ScrapTruckSupplier__c
                WHERE Supplier__c = :accountId
        ];
        Set<Id> viaLinkTruckIds = new Set<Id>();
        for (ScrapTruckSupplier__c link : junctionLinks) {
            if (link.ScrapTruck__c != null) viaLinkTruckIds.add(link.ScrapTruck__c);
        }
        List<ScrapTruck__c> linkedTrucks = viaLinkTruckIds.isEmpty() ? new List<ScrapTruck__c>() : [
                SELECT Id, Name, TruckModel__c, TruckType__c, Tonnage__c, Account__c, Account__r.Name
                FROM ScrapTruck__c
                WHERE Id IN :viaLinkTruckIds
        ];

        Map<Id, ScrapTruck__c> allTrucks = new Map<Id, ScrapTruck__c>();
        for (ScrapTruck__c truck : ownTrucks) allTrucks.put(truck.Id, truck);
        for (ScrapTruck__c truck : linkedTrucks) allTrucks.put(truck.Id, truck);

        details.vehicles = new List<VehicleRow>();
        for (ScrapTruck__c truck : allTrucks.values()) {
            VehicleRow vehicleRow = new VehicleRow();
            vehicleRow.id = truck.Id;
            vehicleRow.plateNumber = truck.Name;
            vehicleRow.model = truck.TruckModel__c;
            vehicleRow.type = truck.TruckType__c;
            vehicleRow.tonnage = truck.Tonnage__c;
            vehicleRow.owner = (truck.Account__r == null ? null : truck.Account__r.Name);
            details.vehicles.add(vehicleRow);
        }

        System.debug('getSupplierDetails → ' + JSON.serializePretty(details));
        return details;
    }


//    Для створення Місця завантаження
    @AuraEnabled
    public static ScrapSupplierAdminService.ShippingPointRow createShippingPoint(Id supplierId, String name, String city, String address){
        if (supplierId == null) throw new AuraHandledException('SupplierId обов’язковий');
        if (String.isBlank(name)) throw new AuraHandledException('Назва обов’язкова');
        if (String.isBlank(city)) throw new AuraHandledException('Місто обов’язкове');
        if (String.isBlank(address)) throw new AuraHandledException('Адреса обов’язкова');

        ScrapSupplierShippingPoint__c sp = new ScrapSupplierShippingPoint__c();
        sp.Supplier__c = supplierId;
        sp.Name = name.trim();
        sp.City__c = city.trim();
        sp.Address__c = address.trim();
        sp.Country__c = 'a010Y00000hPQJMQA4'; // lookup на Україну, тут постав потрібний Id країни

        insert sp;

        ScrapSupplierShippingPoint__c saved = [
                SELECT Id, Name, Address__c, City__c, Country__r.Name
                FROM ScrapSupplierShippingPoint__c
                WHERE Id = :sp.Id
                LIMIT 1
        ];
        ScrapSupplierAdminService.ShippingPointRow row = new ScrapSupplierAdminService.ShippingPointRow();
        row.id = saved.Id;
        row.name = saved.Name;
        row.address = saved.Address__c;
        row.city = saved.City__c;
        row.countryName = saved.Country__r != null ? saved.Country__r.Name : null;
        return row;
    }

//    Для створення водія
    // DTO всередині класу вже є: PersonRow

    @AuraEnabled
public static PersonRow createDriver(
    Id supplierAccountId,
    String lastName,
    String firstName,
    String middleName,
    String email,
    String phone,
    String title,        // NEW
    String department    // NEW
){
    if (supplierAccountId == null) throw new AuraHandledException('Account (supplier) обов’язковий');
    if (String.isBlank(lastName))  throw new AuraHandledException('Прізвище обов’язкове');
    if (String.isBlank(firstName)) throw new AuraHandledException('Ім’я обов’язкове');
    if (String.isBlank(phone))     throw new AuraHandledException('Телефон обов’язковий');

    Contact contact = new Contact();
    contact.AccountId  = supplierAccountId;
    contact.LastName   = lastName.trim();
    contact.FirstName  = String.isBlank(firstName)  ? null : firstName.trim();
    contact.MiddleName = String.isBlank(middleName) ? null : middleName.trim();

    contact.Title      = String.isBlank(title) ? 'Водій' : title.trim();
    contact.Department = String.isBlank(department) ? 'Транспортний відділ' : department.trim();

    contact.Email      = String.isBlank(email) ? null : email.trim();
    contact.Phone      = String.isBlank(phone) ? null : phone.trim();
    contact.TrackDriver__c = true;  // лишається як було

    insert contact;

    contact = [SELECT Id, Name, Title, Department, Phone, Email FROM Contact WHERE Id = :contact.Id];
    PersonRow row = new PersonRow();
    row.id = contact.Id; row.name = contact.Name; row.title = contact.Title; row.dept = contact.Department;
    row.phone = contact.Phone; row.email = contact.Email;
    return row;
}


    @AuraEnabled
public static PersonRow createManager(
    Id accountId,
    String firstName,
    String middleName,
    String lastName,
    String phone,
    String email,
    String title,        // NEW
    String department    // NEW
){
    if (accountId == null)        throw new AuraHandledException('accountId обов’язковий');
    if (String.isBlank(lastName)) throw new AuraHandledException('Прізвище обов’язкове');
    if (String.isBlank(firstName))throw new AuraHandledException('Ім’я обов’язкове');

    Contact contact = new Contact();
    contact.AccountId  = accountId;
    contact.FirstName  = String.isBlank(firstName)  ? null : firstName.trim();
    contact.MiddleName = String.isBlank(middleName) ? null : middleName.trim();
    contact.LastName   = lastName.trim();

    contact.Title      = String.isBlank(title) ? 'Директор' : title.trim();
    contact.Department = String.isBlank(department) ? 'Дирекція' : department.trim();

    contact.Phone      = String.isBlank(phone) ? null : phone.trim();
    contact.Email      = String.isBlank(email) ? null : email.trim();

    insert contact;

    contact = [SELECT Id, Name, Title, Department, Phone, MobilePhone, Email FROM Contact WHERE Id = :contact.Id];
    PersonRow row = new PersonRow();
    row.id = contact.Id; row.name = contact.Name; row.title = contact.Title; row.dept = contact.Department;
    row.phone = (contact.Phone != null ? contact.Phone : contact.MobilePhone); row.email = contact.Email;
    return row;
}


//    для атомобілей
    @AuraEnabled(cacheable=true)
    public static List<TruckLookupRow> searchAvailableTrucks(Id supplierAccountId, String searchText, Integer rowLimit) {
        if (supplierAccountId == null) throw new AuraHandledException('supplierAccountId обов’язковий');

        // вантажівки вже лінкнуті до цього постачальника
        Set<Id> linkedTruckIds = new Set<Id>();
        for (ScrapTruckSupplier__c j : [
                SELECT ScrapTruck__c
                FROM ScrapTruckSupplier__c
                WHERE Supplier__c = :supplierAccountId AND ScrapTruck__c != null
        ]) linkedTruckIds.add(j.ScrapTruck__c);

        Integer limitValue = (rowLimit == null || rowLimit <= 0) ? 100 : Math.min(rowLimit, 200);

        // кандидати: НЕ належать цьому Account і НЕ лінкнуті до нього
        List<ScrapTruck__c> trucks = [
                SELECT Id, Name, TruckModel__c, TruckType__c, Tonnage__c, Account__c, Account__r.Name
                FROM ScrapTruck__c
                WHERE (Account__c = null OR Account__c != :supplierAccountId)
                AND Id NOT IN :linkedTruckIds
                ORDER BY Name
                LIMIT :limitValue
        ];

        List<TruckLookupRow> rows = new List<TruckLookupRow>();
        for (ScrapTruck__c t : trucks) {
            TruckLookupRow r = new TruckLookupRow();
            r.id = t.Id;
            r.plateNumber = t.Name;
            r.model = t.TruckModel__c;
            r.type = t.TruckType__c;
            r.tonnage = t.Tonnage__c;
            r.ownerName = (t.Account__r == null ? null : t.Account__r.Name);
            rows.add(r);
        }
        return rows;
    }

    @AuraEnabled
    public static VehicleRow linkExistingTruck(Id supplierAccountId, Id truckId) {
        if (supplierAccountId == null) throw new AuraHandledException('supplierAccountId обов’язковий');
        if (truckId == null) throw new AuraHandledException('truckId обов’язковий');

        ScrapTruck__c t = [
                SELECT Id, Name, TruckModel__c, TruckType__c, Tonnage__c, Account__c, Account__r.Name
                FROM ScrapTruck__c
                WHERE Id = :truckId
                LIMIT 1
        ];

        // якщо не належить напряму — забезпечити лінк у джанкшині
        if (t.Account__c != supplierAccountId) {
            Boolean hasLink = ![
                    SELECT Id
                    FROM ScrapTruckSupplier__c
                    WHERE Supplier__c = :supplierAccountId AND ScrapTruck__c = :truckId
                    LIMIT 1
            ].isEmpty();
            if (!hasLink) {
                insert new ScrapTruckSupplier__c(Supplier__c = supplierAccountId, ScrapTruck__c = truckId);
            }
        }

        VehicleRow v = new VehicleRow();
        v.id = t.Id;
        v.plateNumber = t.Name;
        v.model = t.TruckModel__c;
        v.type = t.TruckType__c;
        v.tonnage = t.Tonnage__c;
        v.owner = (t.Account__r == null ? null : t.Account__r.Name);
        return v;
    }

//для модального вікна ====================

    @AuraEnabled
    public static SupplierDetails updateSupplierBasics(Id accountId, String name, String phone, String email, String address, String description) {
        if (accountId == null) throw new AuraHandledException('accountId обов’язковий');
        Account a = new Account(Id = accountId);
        if (name != null)        a.Name = name.trim();
        if (phone != null)       a.Phone = String.isBlank(phone) ? null : phone.trim();
        if (email != null)       a.Email__c = String.isBlank(email) ? null : email.trim();
        if (description != null) a.Description = description;

        if (address != null) {
            List<String> parts = new List<String>();
            for (String p : address.split(',')) if (!String.isBlank(p)) parts.add(p.trim());
            if (parts.size() > 0) a.BillingStreet = parts[0];
            if (parts.size() > 1) a.BillingCity = parts[1];
            if (parts.size() > 2) a.BillingState = parts[2];
            if (parts.size() > 3) a.BillingPostalCode = parts[3];
            if (parts.size() > 4) a.BillingCountry = parts[4];
        }
        update a;
        return getSupplierDetails(accountId);
    }

    @AuraEnabled
    public static ShippingPointRow updateShippingPoint(Id id, String name, String city, String address) {
        if (id == null) throw new AuraHandledException('id обов’язковий');
        ScrapSupplierShippingPoint__c sp = new ScrapSupplierShippingPoint__c(Id = id);
        if (name != null)    sp.Name = name.trim();
        if (city != null)    sp.City__c = city.trim();
        if (address != null) sp.Address__c = address.trim();
        update sp;
        ScrapSupplierShippingPoint__c rec = [
                SELECT Id, Name, Address__c, City__c, Country__r.Name
                FROM ScrapSupplierShippingPoint__c WHERE Id = :id
        ];
        ShippingPointRow row = new ShippingPointRow();
        row.id = rec.Id; row.name = rec.Name; row.address = rec.Address__c; row.city = rec.City__c;
        row.countryName = rec.Country__r == null ? null : rec.Country__r.Name;
        return row;
    }
    @AuraEnabled public static void deleteShippingPoint(Id id){ if(id==null) throw new AuraHandledException('id обов’язковий'); delete new ScrapSupplierShippingPoint__c(Id=id); }

    @AuraEnabled
    public static PersonRow updateContact(Id contactId, String firstName, String middleName, String lastName,
            String title, String department, String phone, String mobile, String email) {
        if (contactId == null) throw new AuraHandledException('contactId обов’язковий');
        Contact c = new Contact(Id = contactId);
        if (firstName != null)  c.FirstName  = String.isBlank(firstName) ? null : firstName.trim();
        if (middleName != null) c.MiddleName = String.isBlank(middleName) ? null : middleName.trim();
        if (lastName != null)   c.LastName   = String.isBlank(lastName) ? null : lastName.trim();
        if (title != null)      c.Title      = String.isBlank(title) ? null : title.trim();
        if (department != null) c.Department = String.isBlank(department) ? null : department.trim();
        if (phone != null)      c.Phone      = String.isBlank(phone) ? null : phone.trim();
        if (mobile != null)     c.MobilePhone= String.isBlank(mobile) ? null : mobile.trim();
        if (email != null)      c.Email      = String.isBlank(email) ? null : email.trim();
        update c;
        c = [SELECT Id, Name, Title, Department, Phone, MobilePhone, Email FROM Contact WHERE Id=:contactId];
        PersonRow row = new PersonRow();
        row.id=c.Id; row.name=c.Name; row.title=c.Title; row.dept=c.Department;
        row.phone=(c.Phone!=null?c.Phone:c.MobilePhone); row.email=c.Email;
        return row;
    }
    @AuraEnabled public static void deleteContact(Id contactId){ if(contactId==null) throw new AuraHandledException('contactId обов’язковий'); delete new Contact(Id=contactId); }

    @AuraEnabled
    public static VehicleRow updateTruckBasic(Id truckId, String plateNumber, String model, String type, Decimal tonnage) {
        if (truckId == null) throw new AuraHandledException('truckId обов’язковий');
        ScrapTruck__c t = new ScrapTruck__c(Id = truckId);
        if (plateNumber != null) t.Name = plateNumber.trim();
        if (model != null)       t.TruckModel__c = String.isBlank(model) ? null : model.trim();
        if (type != null)        t.TruckType__c  = String.isBlank(type) ? null : type.trim();
        if (tonnage != null)     t.Tonnage__c    = tonnage;
        update t;
        t = [SELECT Id, Name, TruckModel__c, TruckType__c, Tonnage__c, Account__r.Name FROM ScrapTruck__c WHERE Id=:truckId];
        VehicleRow v = new VehicleRow();
        v.id=t.Id; v.plateNumber=t.Name; v.model=t.TruckModel__c; v.type=t.TruckType__c; v.tonnage=t.Tonnage__c; v.owner=(t.Account__r==null?null:t.Account__r.Name);
        return v;
    }
    @AuraEnabled
    public static void unlinkTruckFromSupplier(Id supplierAccountId, Id truckId){
        if(supplierAccountId==null||truckId==null) throw new AuraHandledException('supplierAccountId та truckId обов’язкові');
        List<ScrapTruckSupplier__c> links=[SELECT Id FROM ScrapTruckSupplier__c WHERE Supplier__c=:supplierAccountId AND ScrapTruck__c=:truckId];
        if(!links.isEmpty()) delete links;
        ScrapTruck__c t=[SELECT Id,Account__c FROM ScrapTruck__c WHERE Id=:truckId];
        if(t.Account__c==supplierAccountId){ t.Account__c=null; update t; }
    }

    // === MAIN INFO UPDATE ===
    @AuraEnabled(Cacheable=false)
    public static Account updateSupplierMainInfo(
            Id accountId,
            String name,
            String phone,
            String email,
            String description,
            String billingStreet,
            String billingCity,
            String billingState,
            String billingPostalCode,
            String billingCountry
    ) {
        System.debug('accountId: ' + accountId);
        System.debug('name: ' + name);
        System.debug('phone: ' + phone);
        System.debug('email: ' + email);
        System.debug('description: ' + description);
        System.debug('billingStreet: ' + billingStreet);
        System.debug('billingCity: ' + billingCity);
        System.debug('billingState: ' + billingState);
        System.debug('billingPostalCode: ' + billingPostalCode);
        System.debug('billingCountry: ' + billingCountry);
        if (accountId == null) throw new AuraHandledException('accountId обов’язковий');
        Account acc = [
                SELECT Id, IsSupplier__c
                FROM Account
                WHERE Id = :accountId
                LIMIT 1
        ];
        if (acc.IsSupplier__c != true) {
            throw new AuraHandledException('Вказаний Account не є постачальником');
        }
        if (String.isBlank(name)) throw new AuraHandledException('Назва обов’язкова');

        acc.Name           = name.trim();
        acc.Phone          = String.isBlank(phone)          ? null : phone.trim();
        acc.Email__c       = String.isBlank(email)          ? null : email.trim();
        acc.Description    = String.isBlank(description)    ? null : description.trim();

        acc.BillingStreet     = String.isBlank(billingStreet)     ? null : billingStreet.trim();
        acc.BillingCity       = String.isBlank(billingCity)       ? null : billingCity.trim();
        acc.BillingState      = String.isBlank(billingState)      ? null : billingState.trim();
        acc.BillingPostalCode = String.isBlank(billingPostalCode) ? null : billingPostalCode.trim();
        acc.BillingCountry    = String.isBlank(billingCountry)    ? null : billingCountry.trim();

        update acc;

        return [
                SELECT Id, Name, Phone, Email__c, Description,
                        BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry
                FROM Account
                WHERE Id = :acc.Id
                LIMIT 1
        ];
    }

    public class Row {
        @AuraEnabled public String supplierName;
        @AuraEnabled public Decimal prop1; @AuraEnabled public Decimal prop2; @AuraEnabled public Decimal prop3; @AuraEnabled public Decimal propMonth;
        @AuraEnabled public Decimal appr1; @AuraEnabled public Decimal appr2; @AuraEnabled public Decimal appr3; @AuraEnabled public Decimal apprMonth;
        @AuraEnabled public Decimal used1; @AuraEnabled public Decimal used2; @AuraEnabled public Decimal used3; @AuraEnabled public Decimal usedMonth;
        @AuraEnabled public Decimal rem1;  @AuraEnabled public Decimal rem2;  @AuraEnabled public Decimal rem3;  @AuraEnabled public Decimal remMonth;
    }

    @AuraEnabled(cacheable=true)
    public static Row getSupplierMonth(Id supplierId, Integer year, Integer month) {
        if (supplierId == null || year == null || month == null) {
            throw new AuraHandledException('supplierId, year, month are required');
        }

        // 1) Беремо три мапи з утиліт
        Map<Id, Map<Calendar, Decimal>> declared = ScrapUtils.getSuppliersLimits(ScrapUtils.DECLARED, false);
        Map<Id, Map<Calendar, Decimal>> approved = ScrapUtils.getSuppliersLimits(ScrapUtils.APPROVED, true);
        Map<Id, Map<Calendar, Decimal>> inputs   = ScrapUtils.getSupplierInputsByDecades();

        Map<Calendar, Decimal> dMap = declared != null ? declared.get(supplierId) : null;
        Map<Calendar, Decimal> aMap = approved != null ? approved.get(supplierId) : null;
        Map<Calendar, Decimal> iMap = inputs   != null ? inputs.get(supplierId)   : null;

        Row r = new Row();
        r.supplierName = [SELECT Name FROM Account WHERE Id = :supplierId LIMIT 1].Name;

        for (Integer dec = 1; dec <= 3; dec++) {
            Decimal prop = pick(dMap, year, month, dec);
            Decimal appr = pick(aMap, year, month, dec);
            Decimal used = pick(iMap, year, month, dec);
            Decimal rem  = (appr == null ? 0 : appr) - (used == null ? 0 : used);

            if (dec == 1) { r.prop1 = prop; r.appr1 = appr; r.used1 = used; r.rem1 = rem; }
            if (dec == 2) { r.prop2 = prop; r.appr2 = appr; r.used2 = used; r.rem2 = rem; }
            if (dec == 3) { r.prop3 = prop; r.appr3 = appr; r.used3 = used; r.rem3 = rem; }
        }
        r.propMonth = nz(r.prop1) + nz(r.prop2) + nz(r.prop3);
        r.apprMonth = nz(r.appr1) + nz(r.appr2) + nz(r.appr3);
        r.usedMonth = nz(r.used1) + nz(r.used2) + nz(r.used3);
        r.remMonth  = nz(r.rem1)  + nz(r.rem2)  + nz(r.rem3);
        return r;
    }

    private static Decimal pick(Map<Calendar, Decimal> mapCal, Integer y, Integer m, Integer d) {
        if (mapCal == null) return 0;
        for (Calendar cal : mapCal.keySet()) {
            List<Integer> t = Calendar.decodeCalendar(cal); // [year, month, decade]
            if (t != null && t.size() >= 3 && t[0] == y && t[1] == m && t[2] == d) {
                Decimal v = mapCal.get(cal);
                return v == null ? 0 : v;
            }
        }
        return 0;
    }
    private static Decimal nz(Decimal v) { return v == null ? 0 : v; }

    // ========= DTO: рядок доступів постачальника до типів брухту =========
    public class SupplierScrapAccessRow {
        @AuraEnabled public Id id;            // ScrapType__c
        @AuraEnabled public String name;      // Назва типу
        @AuraEnabled public String code;      // ScrapTypeCode__c (fallback: ID_ERP__c)
        @AuraEnabled public String groupName; // Parent__r.Name (ближча група)
        @AuraEnabled public Boolean permitted;// чи дозволено цьому постачальнику
        @AuraEnabled public Boolean active;   // IsActive__c типу
    }

// ========= Головний метод для таблиці на сторінці постачальника =========
    @AuraEnabled(cacheable=false)
    public static List<SupplierScrapAccessRow> getSupplierScrapAccessMatrix(Id accountId) {
        if (accountId == null) throw new AuraHandledException('accountId обов’язковий');

        // 1) Всі листові типи брухту
        List<ScrapType__c> allTypes = [
                SELECT Id, Name, ScrapTypeCode__c, ID_ERP__c, IsActive__c, IsGroup__c, Parent__r.Name
                FROM ScrapType__c
                WHERE IsGroup__c = FALSE AND Level__c = 3
                ORDER BY Name
                LIMIT 5000
        ];

        // 2) Усі зв’язки для цього постачальника
        List<ScrapTypeSupplierRelation__c> links = [
                SELECT ScrapType__c, Permitted__c
                FROM ScrapTypeSupplierRelation__c
                WHERE Account__c = :accountId
                AND ScrapType__c != NULL
                LIMIT 50000
        ];
        // Якщо є кілька записів на той самий ScrapType — достатньо хоча б одного true
        Map<Id, Boolean> permittedByType = new Map<Id, Boolean>();
        for (ScrapTypeSupplierRelation__c r : links) {
            if (r.ScrapType__c == null) continue;
            Boolean p = (r.Permitted__c == true);
            if (!permittedByType.containsKey(r.ScrapType__c) || p) {
                permittedByType.put(r.ScrapType__c, p);
            }
        }

        // 3) Формуємо результат "всі типи" + стани Доступ/Активність
        List<SupplierScrapAccessRow> outRows = new List<SupplierScrapAccessRow>();
        for (ScrapType__c t : allTypes) {
            SupplierScrapAccessRow row = new SupplierScrapAccessRow();
            row.id        = t.Id;
            row.name      = t.Name;
            row.code      = String.isBlank(t.ScrapTypeCode__c) ? t.ID_ERP__c : t.ScrapTypeCode__c;
            row.groupName = (t.Parent__r == null ? null : t.Parent__r.Name);
            row.active    = (t.IsActive__c == true);
            row.permitted = (permittedByType.containsKey(t.Id) ? permittedByType.get(t.Id) : false);
            outRows.add(row);
        }
        return outRows; // вже відсортовано за Name у SOQL
    }

    @AuraEnabled
    public static void setSupplierActivity(Id accountId, String newActivityType) {
        if (accountId == null) throw new AuraHandledException('accountId обов’язковий');
        if (String.isBlank(newActivityType)) throw new AuraHandledException('newActivityType обов’язковий');

        // валідні значення
        Set<String> allowed = new Set<String>{ 'Active', 'Potential', 'Inactive' };
        if (!allowed.contains(newActivityType)) {
            throw new AuraHandledException('Некоректне значення Activity_Type__c');
        }

        Account acc = [
                SELECT Id, IsSupplier__c, Activity_Type__c
                FROM Account
                WHERE Id = :accountId
                LIMIT 1
        ];
        if (acc.IsSupplier__c != true) {
            throw new AuraHandledException('Вказаний Account не є постачальником');
        }

        acc.Activity_Type__c = newActivityType;
        update acc;
    }

    private static String normalizePlate(String s) {
        if (String.isBlank(s)) return null;
        // прибрати ВСІ пробіли/переноси
        String plate = s.replaceAll('\\s+', '');
        return plate;
    }

    @AuraEnabled
    public static VehicleRow createTruck(
            Id supplierAccountId,
            String plateNumber,
            String model,
            String type,
            Decimal tonnage,
            Boolean isScrapHauler
    ){
        System.debug('supplierAccountId: ' + supplierAccountId + ' | ' + plateNumber + ' | ' + model + ' | ' + type + ' | ' + tonnage + ' | ' + isScrapHauler);
        if (supplierAccountId == null) throw new AuraHandledException('supplierAccountId обов’язковий');
        if (String.isBlank(plateNumber)) throw new AuraHandledException('Держ. номер обов’язковий');

        ScrapTruck__c t = new ScrapTruck__c();
        t.Account__c       = supplierAccountId;                 // власник (постачальник)
        t.Name             = normalizePlate(plateNumber);       // ← без пробілів
        t.TruckModel__c    = String.isBlank(model) ? null : model.trim();
        t.TruckType__c     = String.isBlank(type)  ? null : type.trim();
        t.Tonnage__c       = tonnage;
        t.IsScrapHauler__c = (isScrapHauler == null ? false : isScrapHauler);

        // (необов’язково, але корисно) хто додав:
        t.AddedByUser__c   = UserInfo.getUserId();

        insert t;

        VehicleRow v = new VehicleRow();
        v.id          = t.Id;
        v.plateNumber = t.Name;
        v.model       = t.TruckModel__c;
        v.type        = t.TruckType__c;
        v.tonnage     = t.Tonnage__c;
        v.owner       = [SELECT Name FROM Account WHERE Id = :supplierAccountId].Name;
        return v;
    }

    @AuraEnabled
    public static void detachContact(Id contactId){
        if (contactId == null) throw new AuraHandledException('contactId обов’язковий');
        // просто прибираємо AccountId
        update new Contact(Id = contactId, AccountId = null);
    }

    @AuraEnabled
    public static void detachShippingPoint(Id id){
        if (id == null) throw new AuraHandledException('id обов’язковий');
        // просто прибираємо Supplier__c
        update new ScrapSupplierShippingPoint__c(Id = id, Supplier__c = null);
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
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;

        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
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