declare module "@salesforce/apex/ScrapAccessController.init" {
  export default function init(): Promise<any>;
}
declare module "@salesforce/apex/ScrapAccessController.togglePermission" {
  export default function togglePermission(param: {accountId: any, scrapTypeId: any, permitted: any}): Promise<any>;
}
declare module "@salesforce/apex/ScrapAccessController.setPermissionsForSupplier" {
  export default function setPermissionsForSupplier(param: {accountId: any, scrapTypeIds: any, permitted: any}): Promise<any>;
}
declare module "@salesforce/apex/ScrapAccessController.setPermissionsForScrap" {
  export default function setPermissionsForScrap(param: {scrapTypeId: any, accountIds: any, permitted: any}): Promise<any>;
}
