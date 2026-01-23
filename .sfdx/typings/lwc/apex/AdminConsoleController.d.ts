declare module "@salesforce/apex/AdminConsoleController.previewSoql" {
  export default function previewSoql(param: {soql: any, maxRows: any}): Promise<any>;
}
declare module "@salesforce/apex/AdminConsoleController.executeUpdateByQuery" {
  export default function executeUpdateByQuery(param: {sObjectApi: any, fieldsToSelect: any, whereClause: any, setValues: any, asyncConfigName: any, dryRun: any, snapshotLimit: any}): Promise<any>;
}
declare module "@salesforce/apex/AdminConsoleController.executeDeleteByQuery" {
  export default function executeDeleteByQuery(param: {sObjectApi: any, snapshotFields: any, whereClause: any, asyncConfigName: any, dryRun: any, snapshotLimit: any}): Promise<any>;
}
