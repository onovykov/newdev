declare module "@salesforce/apex/OutOfPlanAdminService.approveOutOfPlan" {
  export default function approveOutOfPlan(param: {slotId: any, fixedWeightValue: any}): Promise<any>;
}
declare module "@salesforce/apex/OutOfPlanAdminService.getSlotStatus" {
  export default function getSlotStatus(param: {slotId: any}): Promise<any>;
}
declare module "@salesforce/apex/OutOfPlanAdminService.listRequestedOutOfPlan" {
  export default function listRequestedOutOfPlan(): Promise<any>;
}
declare module "@salesforce/apex/OutOfPlanAdminService.getApprovedLimitsForCurrentMonth" {
  export default function getApprovedLimitsForCurrentMonth(param: {supplierId: any}): Promise<any>;
}
declare module "@salesforce/apex/OutOfPlanAdminService.getApprovedLimitsForMonth" {
  export default function getApprovedLimitsForMonth(param: {supplierId: any, year: any, month: any}): Promise<any>;
}
declare module "@salesforce/apex/OutOfPlanAdminService.listRequestedOutOfPlanVM" {
  export default function listRequestedOutOfPlanVM(param: {supplierIdFilter: any, scrapTypeFilter: any, dateFrom: any, dateTo: any}): Promise<any>;
}
declare module "@salesforce/apex/OutOfPlanAdminService.previewApprove" {
  export default function previewApprove(param: {slotId: any}): Promise<any>;
}
declare module "@salesforce/apex/OutOfPlanAdminService.getFixedWeightOptions" {
  export default function getFixedWeightOptions(): Promise<any>;
}
