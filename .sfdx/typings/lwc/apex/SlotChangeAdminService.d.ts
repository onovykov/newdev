declare module "@salesforce/apex/SlotChangeAdminService.listChanges" {
  export default function listChanges(param: {status: any, query: any}): Promise<any>;
}
declare module "@salesforce/apex/SlotChangeAdminService.rejectChange" {
  export default function rejectChange(param: {changeId: any}): Promise<any>;
}
declare module "@salesforce/apex/SlotChangeAdminService.approveChange" {
  export default function approveChange(param: {changeId: any}): Promise<any>;
}
declare module "@salesforce/apex/SlotChangeAdminService.getChangeState" {
  export default function getChangeState(param: {changeId: any}): Promise<any>;
}
