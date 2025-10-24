declare module "@salesforce/apex/lookupfieldController.GetRecentRecords" {
  export default function GetRecentRecords(param: {ObjectName: any, ReturnFields: any, MaxResults: any}): Promise<any>;
}
declare module "@salesforce/apex/lookupfieldController.SearchRecords" {
  export default function SearchRecords(param: {ObjectName: any, ReturnFields: any, QueryFields: any, SearchText: any, SortColumn: any, SortOrder: any, MaxResults: any, Filter: any, FromDate: any, ToDate: any}): Promise<any>;
}
declare module "@salesforce/apex/lookupfieldController.GetRecord" {
  export default function GetRecord(param: {ObjectName: any, ReturnFields: any, Id: any}): Promise<any>;
}
declare module "@salesforce/apex/lookupfieldController.findObjectIcon" {
  export default function findObjectIcon(param: {ObjectName: any}): Promise<any>;
}
declare module "@salesforce/apex/lookupfieldController.getObjectDetails" {
  export default function getObjectDetails(param: {ObjectName: any}): Promise<any>;
}
