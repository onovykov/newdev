declare module "@salesforce/apex/ScrapLimitsPanelController.getCurrentMonthPanel" {
  export default function getCurrentMonthPanel(): Promise<any>;
}
declare module "@salesforce/apex/ScrapLimitsPanelController.getMonthPanel" {
  export default function getMonthPanel(param: {year: any, month: any}): Promise<any>;
}
declare module "@salesforce/apex/ScrapLimitsPanelController.saveApprovedEdits" {
  export default function saveApprovedEdits(param: {supplierId: any, year: any, month: any, changes: any, contentDocIds: any}): Promise<any>;
}
declare module "@salesforce/apex/ScrapLimitsPanelController.getEditsHistory" {
  export default function getEditsHistory(param: {supplierId: any, year: any, month: any, maxItems: any}): Promise<any>;
}
