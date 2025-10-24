declare module "@salesforce/apex/ApprovalRequestController.getApprovalRequests" {
  export default function getApprovalRequests(): Promise<any>;
}
declare module "@salesforce/apex/ApprovalRequestController.approveRequests" {
  export default function approveRequests(param: {workItems: any}): Promise<any>;
}
declare module "@salesforce/apex/ApprovalRequestController.rejectRequests" {
  export default function rejectRequests(param: {workItems: any}): Promise<any>;
}
