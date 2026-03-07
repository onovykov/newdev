declare module "@salesforce/apex/ScrapSupplierAdminService.listSuppliers" {
  export default function listSuppliers(param: {query: any}): Promise<any>;
}
declare module "@salesforce/apex/ScrapSupplierAdminService.getSupplierDetails" {
  export default function getSupplierDetails(param: {accountId: any}): Promise<any>;
}
declare module "@salesforce/apex/ScrapSupplierAdminService.createShippingPoint" {
  export default function createShippingPoint(param: {supplierId: any, name: any, city: any, address: any}): Promise<any>;
}
declare module "@salesforce/apex/ScrapSupplierAdminService.createDriver" {
  export default function createDriver(param: {supplierAccountId: any, lastName: any, firstName: any, middleName: any, email: any, phone: any, title: any, department: any}): Promise<any>;
}
declare module "@salesforce/apex/ScrapSupplierAdminService.createManager" {
  export default function createManager(param: {accountId: any, firstName: any, middleName: any, lastName: any, phone: any, email: any, title: any, department: any}): Promise<any>;
}
declare module "@salesforce/apex/ScrapSupplierAdminService.searchAvailableTrucks" {
  export default function searchAvailableTrucks(param: {supplierAccountId: any, searchText: any, rowLimit: any}): Promise<any>;
}
declare module "@salesforce/apex/ScrapSupplierAdminService.linkExistingTruck" {
  export default function linkExistingTruck(param: {supplierAccountId: any, truckId: any}): Promise<any>;
}
declare module "@salesforce/apex/ScrapSupplierAdminService.updateSupplierBasics" {
  export default function updateSupplierBasics(param: {accountId: any, name: any, phone: any, email: any, address: any, description: any}): Promise<any>;
}
declare module "@salesforce/apex/ScrapSupplierAdminService.updateShippingPoint" {
  export default function updateShippingPoint(param: {id: any, name: any, city: any, address: any}): Promise<any>;
}
declare module "@salesforce/apex/ScrapSupplierAdminService.deleteShippingPoint" {
  export default function deleteShippingPoint(param: {id: any}): Promise<any>;
}
declare module "@salesforce/apex/ScrapSupplierAdminService.updateContact" {
  export default function updateContact(param: {contactId: any, firstName: any, middleName: any, lastName: any, title: any, department: any, phone: any, mobile: any, email: any}): Promise<any>;
}
declare module "@salesforce/apex/ScrapSupplierAdminService.deleteContact" {
  export default function deleteContact(param: {contactId: any}): Promise<any>;
}
declare module "@salesforce/apex/ScrapSupplierAdminService.updateTruckBasic" {
  export default function updateTruckBasic(param: {truckId: any, plateNumber: any, model: any, type: any, tonnage: any}): Promise<any>;
}
declare module "@salesforce/apex/ScrapSupplierAdminService.unlinkTruckFromSupplier" {
  export default function unlinkTruckFromSupplier(param: {supplierAccountId: any, truckId: any}): Promise<any>;
}
declare module "@salesforce/apex/ScrapSupplierAdminService.updateSupplierMainInfo" {
  export default function updateSupplierMainInfo(param: {accountId: any, name: any, phone: any, email: any, description: any, billingStreet: any, billingCity: any, billingState: any, billingPostalCode: any, billingCountry: any}): Promise<any>;
}
declare module "@salesforce/apex/ScrapSupplierAdminService.getSupplierMonth" {
  export default function getSupplierMonth(param: {supplierId: any, year: any, month: any}): Promise<any>;
}
declare module "@salesforce/apex/ScrapSupplierAdminService.getSupplierScrapAccessMatrix" {
  export default function getSupplierScrapAccessMatrix(param: {accountId: any}): Promise<any>;
}
declare module "@salesforce/apex/ScrapSupplierAdminService.setSupplierActivity" {
  export default function setSupplierActivity(param: {accountId: any, newActivityType: any}): Promise<any>;
}
declare module "@salesforce/apex/ScrapSupplierAdminService.createTruck" {
  export default function createTruck(param: {supplierAccountId: any, plateNumber: any, model: any, type: any, tonnage: any, isScrapHauler: any}): Promise<any>;
}
declare module "@salesforce/apex/ScrapSupplierAdminService.detachContact" {
  export default function detachContact(param: {contactId: any}): Promise<any>;
}
declare module "@salesforce/apex/ScrapSupplierAdminService.detachShippingPoint" {
  export default function detachShippingPoint(param: {id: any}): Promise<any>;
}
