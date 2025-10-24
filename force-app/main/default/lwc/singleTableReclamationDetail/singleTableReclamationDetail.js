import { LightningElement,api,track } from 'lwc';

const columns = [
    { label: 'Item #', fieldName: 'urlTorecord',type:'url',
        typeAttributes: {
            label: { fieldName: 'ITENumber__c' },
            target: '_blank'}},
    { label: 'Product Name', fieldName: 'productName',type:'text'},
    //{ label: 'Meas Unit', fieldName: 'OrderQty__c',type:'text'},
    //{ label: 'COC Number', fieldName: 'Order_Additional_Number__c',type:'text'},
    //{ label: 'PO Number', fieldName: 'PO_Number__c',type:'text'},
   
    { label: 'Order Qty', fieldName: 'OrderQty__c',type:'text'},
    { label: 'Claim Qty', fieldName: 'ClaimQty__c',type:'text'},
    { label: 'Claim Summary', fieldName: 'ClaimSum__c',type:'text'},
    { label: 'Currency', fieldName: 'CurrencyIsoCode',type:'text',fixedWidth: 110},
    { label: 'Mistmatch Type', fieldName: 'Mistmatch_Type__c',type:'text'},
    { label: 'Mistmatch SubType', fieldName: 'Mistmatch_SubType__c',type:'text'},
    
    
];

export default class SingleTableReclamationDetail extends LightningElement {
    @api getMyData;
    @track test;  
    columns=columns;
    orderNumber;
    poNumber;

    renderedCallback() {
        this.orderNumber = this.getMyData[0].OrderID__r.AdditionalNumber__c;
        this.poNumber = this.getMyData[0].PO_Number__c;             
    }
}