declare module "@salesforce/apex/ScrapSupplierPortalController.getMyAccountId" {
  export default function getMyAccountId(): Promise<any>;
}
declare module "@salesforce/apex/ScrapSupplierPortalController.checkExistingProposedThisOrNext" {
  export default function checkExistingProposedThisOrNext(param: {supplierId: any}): Promise<any>;
}
declare module "@salesforce/apex/ScrapSupplierPortalController.listThisAndNextAllLimits" {
  export default function listThisAndNextAllLimits(param: {supplierId: any}): Promise<any>;
}
declare module "@salesforce/apex/ScrapSupplierPortalController.createProposedAutoThisOrNext" {
  export default function createProposedAutoThisOrNext(param: {supplierId: any, dec1Limit: any, dec2Limit: any, dec3Limit: any}): Promise<any>;
}
declare module "@salesforce/apex/ScrapSupplierPortalController.getSupplierMonthBalance" {
  export default function getSupplierMonthBalance(param: {supplierId: any, yearNum: any, monthNum: any}): Promise<any>;
}
declare module "@salesforce/apex/ScrapSupplierPortalController.listThisAndNextBalances" {
  export default function listThisAndNextBalances(param: {supplierId: any}): Promise<any>;
}
declare module "@salesforce/apex/ScrapSupplierPortalController.listSupplierActiveSlotsThisAndNext" {
  export default function listSupplierActiveSlotsThisAndNext(param: {supplierId: any}): Promise<any>;
}
declare module "@salesforce/apex/ScrapSupplierPortalController.listSupplierHistorySlotsBeforeToday" {
  export default function listSupplierHistorySlotsBeforeToday(param: {supplierId: any, monthsBack: any}): Promise<any>;
}
declare module "@salesforce/apex/ScrapSupplierPortalController.cancelSupplierSlot" {
  export default function cancelSupplierSlot(param: {slotId: any}): Promise<any>;
}
declare module "@salesforce/apex/ScrapSupplierPortalController.getSupplierPrereqs" {
  export default function getSupplierPrereqs(param: {supplierId: any}): Promise<any>;
}
