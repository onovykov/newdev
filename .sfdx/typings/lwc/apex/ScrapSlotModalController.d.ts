declare module "@salesforce/apex/ScrapSlotModalController.checkSimilarReserve" {
  export default function checkSimilarReserve(param: {supplierId: any, scrapTypeId: any, reserveDate: any, truckId: any, trailerId: any, fixedWeight: any}): Promise<any>;
}
declare module "@salesforce/apex/ScrapSlotModalController.getCurrentDecadeAndDays" {
  export default function getCurrentDecadeAndDays(): Promise<any>;
}
declare module "@salesforce/apex/ScrapSlotModalController.listPermittedScrapTypes" {
  export default function listPermittedScrapTypes(param: {supplierId: any}): Promise<any>;
}
declare module "@salesforce/apex/ScrapSlotModalController.getDecadeGridForSupplier" {
  export default function getDecadeGridForSupplier(param: {supplierId: any}): Promise<any>;
}
declare module "@salesforce/apex/ScrapSlotModalController.getStep2StaticInfo" {
  export default function getStep2StaticInfo(param: {supplierId: any, scrapTypeId: any}): Promise<any>;
}
declare module "@salesforce/apex/ScrapSlotModalController.getStep2Lookups" {
  export default function getStep2Lookups(param: {supplierId: any}): Promise<any>;
}
declare module "@salesforce/apex/ScrapSlotModalController.searchTrucks" {
  export default function searchTrucks(param: {supplierId: any, query: any, type: any, limitSize: any}): Promise<any>;
}
declare module "@salesforce/apex/ScrapSlotModalController.searchDrivers" {
  export default function searchDrivers(param: {supplierId: any, query: any, limitSize: any}): Promise<any>;
}
declare module "@salesforce/apex/ScrapSlotModalController.createReserve" {
  export default function createReserve(param: {input: any}): Promise<any>;
}
declare module "@salesforce/apex/ScrapSlotModalController.sendReserveToErp" {
  export default function sendReserveToErp(param: {reserveId: any}): Promise<any>;
}
declare module "@salesforce/apex/ScrapSlotModalController.markReserveApproved" {
  export default function markReserveApproved(param: {reserveId: any, passNumber: any, passId: any}): Promise<any>;
}
declare module "@salesforce/apex/ScrapSlotModalController.getDecadeAnchor" {
  export default function getDecadeAnchor(param: {anyDate: any}): Promise<any>;
}
declare module "@salesforce/apex/ScrapSlotModalController.getNextDecadeAnchor" {
  export default function getNextDecadeAnchor(param: {anyDate: any}): Promise<any>;
}
declare module "@salesforce/apex/ScrapSlotModalController.getPrevDecadeAnchor" {
  export default function getPrevDecadeAnchor(param: {anyDate: any}): Promise<any>;
}
declare module "@salesforce/apex/ScrapSlotModalController.getDecadeGridForSupplierAtDate" {
  export default function getDecadeGridForSupplierAtDate(param: {supplierId: any, anchorDate: any}): Promise<any>;
}
