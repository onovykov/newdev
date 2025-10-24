declare module "@salesforce/apex/OpportunityInfoController.getJSONData" {
  export default function getJSONData(param: {opp: any, acc: any, opportunityProducts: any}): Promise<any>;
}
declare module "@salesforce/apex/OpportunityInfoController.sendJSONData" {
  export default function sendJSONData(param: {jsonedWrapper: any}): Promise<any>;
}
declare module "@salesforce/apex/OpportunityInfoController.getOpportunity" {
  export default function getOpportunity(param: {oppId: any}): Promise<any>;
}
