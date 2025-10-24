declare module "@salesforce/apex/ScrapSlotChangeService.requestChange" {
  export default function requestChange(param: {slotId: any, newDriverId: any, newTractorId: any, newTrailerId: any, comment: any}): Promise<any>;
}
declare module "@salesforce/apex/ScrapSlotChangeService.listDrivers" {
  export default function listDrivers(param: {supplierId: any}): Promise<any>;
}
declare module "@salesforce/apex/ScrapSlotChangeService.listTrucks" {
  export default function listTrucks(param: {supplierId: any, truckType: any}): Promise<any>;
}
declare module "@salesforce/apex/ScrapSlotChangeService.getSlotDetails" {
  export default function getSlotDetails(param: {slotId: any}): Promise<any>;
}
