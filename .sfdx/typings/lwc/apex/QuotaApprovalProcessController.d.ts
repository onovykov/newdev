declare module "@salesforce/apex/QuotaApprovalProcessController.getQuotaDetails" {
  export default function getQuotaDetails(param: {urlString: any}): Promise<any>;
}
declare module "@salesforce/apex/QuotaApprovalProcessController.getQuoteSegmentStruct" {
  export default function getQuoteSegmentStruct(param: {marketSegment: any}): Promise<any>;
}
declare module "@salesforce/apex/QuotaApprovalProcessController.isApprovalRequestPending" {
  export default function isApprovalRequestPending(param: {urlString: any}): Promise<any>;
}
declare module "@salesforce/apex/QuotaApprovalProcessController.approveOrRejectRequest" {
  export default function approveOrRejectRequest(param: {urlString: any, isApproved: any}): Promise<any>;
}
