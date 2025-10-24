import { LightningElement, wire, track } from 'lwc';
import getPrices from '@salesforce/apex/AllPricesDatatableController.getPrices';

const COLUMNS = [
    { label: 'Country', fieldName: 'country', type: 'text'},
    { label: 'Product', fieldName: 'product', type: 'text'},
    { label: 'Shop', fieldName: 'shop', type: 'text'},
    { label: 'Steel Grade', fieldName: 'steelGrade', type: 'text'},
    { label: 'OD, mm', fieldName: 'odmm', type: 'text'},
    { label: 'WT, mm', fieldName: 'wtmm', type: 'text'},
    { label: 'OD, in', fieldName: 'odin', type: 'text'},
    { label: 'WT, in', fieldName: 'wtin', type: 'text'},
    { label: 'PPF', fieldName: 'ppf', type: 'number' },
    { label: 'Incoterms', fieldName: 'incoterms', type: 'text'},
    { label: 'Destination', fieldName: 'shippingPoint', type: 'text'},
    { label: 'Price, $/t', fieldName: 'price', type: 'number'},
    { label: 'Margin, $/t', fieldName: 'margin', type: 'number'},
    { label: 'Budget margin, $/t', fieldName: 'budgetMargin', type: 'number'},
    { label: 'Additional Info', fieldName: 'additionalInformation', type: 'text', initialWidth: 200},
];

export default class AllPricesDatatable extends LightningElement {
    @track columns = COLUMNS;
    @track prices = [];
    
    filters = [
        { label: 'Country', type: 'text', api: 'Country__r.Name', fieldType: 'text' },
        { label: 'Product', type: 'text', api: 'Product__r.Name', fieldType: 'text' },
        { label: 'Shop', type: 'text', api: 'Shop__r.Name', fieldType: 'text' },
        { label: 'Steel Grade', type: 'text', api: 'SteelGradeGroup__r.Name', fieldType: 'text' },
        { label: 'OD, mm', type: 'text', api: 'OD_mm__r.OD_mm__c', fieldType: 'number', apiMax: 'OD_mm_max__r.OD_mm__c'},
        { label: 'WT, mm', type: 'text', api: 'WT_mm__r.WT_mm__c', fieldType: 'number', apiMax: 'WT_mm_max__r.WT_mm__c'},
        { label: 'OD, in', type: 'text', api: 'OD_inch__c', fieldType: 'number', apiMax: 'OD_inch_max__c'},
        { label: 'WT, in', type: 'text', api: 'WT_inch__c', fieldType: 'number', apiMax: 'WT_inch_max__c'},
        { label: 'PPF', type: 'text', api: 'Weight_ppf__c', fieldType: 'text' },
        { label: 'Incoterms', type: 'text', api: 'Incoterms__c', fieldType: 'text' },
        { label: 'Destination', type: 'text', api: 'ShippingPoint__r.Name', fieldType: 'text' },
        { label: 'Price', type: 'text', api: 'Price__c', fieldType: 'number' },
        { label: 'Margin', type: 'text', api: 'Margin__c', fieldType: 'number' },
        { label: 'Budget margin', type: 'text', api: 'MarginBG__c', fieldType: 'number' },
        { label: 'Additional Info', type: 'text', api: 'Additional_Information__c', fieldType: 'text' },
    ];
    
        
    @wire(getPrices)
    wirePrices({data, error}){
        if(data && data.length > 0){
            this.prices = data;     
        }  else if (error) {
            console.log("error =====> " + JSON.stringify(error));
        }
    };

    handleFilter(event){
        this.prices = event.detail.data;
    }
}