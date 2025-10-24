declare module "@salesforce/apex/ScrapAdminLimitRequestService.createProposedForCurrentMonth" {
  export default function createProposedForCurrentMonth(param: {supplierId: any, dec1Limit: any, dec2Limit: any, dec3Limit: any}): Promise<any>;
}
declare module "@salesforce/apex/ScrapAdminLimitRequestService.listUnapprovedForCurrentMonth" {
  export default function listUnapprovedForCurrentMonth(): Promise<any>;
}
declare module "@salesforce/apex/ScrapAdminLimitRequestService.listUnapprovedForPeriod" {
  export default function listUnapprovedForPeriod(param: {yearNum: any, monthNum: any}): Promise<any>;
}
declare module "@salesforce/apex/ScrapAdminLimitRequestService.approve" {
  export default function approve(param: {input: any}): Promise<any>;
}
declare module "@salesforce/apex/ScrapAdminLimitRequestService.listUnapprovedForCurrentAndNext" {
  export default function listUnapprovedForCurrentAndNext(): Promise<any>;
}
