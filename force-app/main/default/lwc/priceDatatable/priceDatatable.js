import { LightningElement, wire, api, track } from 'lwc';
import getPrices from '@salesforce/apex/PriceDatatableController.getPrices';

const COLUMNS = [
    { label: 'OD, mm', fieldName: 'odmm', type: 'number', typeAttributes: { minimumFractionDigits: '2' }},
    { label: 'WT, mm', fieldName: 'wtmm', type: 'number', typeAttributes: { minimumFractionDigits: '2' }}
];

export default class priceDatatable extends LightningElement {
    @api recordId;
    @track columns = COLUMNS;
    prices;

    filters = [
        { label: 'OD, mm', type: 'text', api: 'odmm'},
        { label: 'WT, mm', type: 'text', api: 'wtmm'}
    ];
    
    @wire(getPrices, {priceListHierarchyId: '$recordId'})
    wirePrices({data, error}){
        if(data && data.length > 0){
            this.prices = data; 
            this.columns = [];
            this.columns.push(...COLUMNS);

            if(data[0].prodType == 'OCTG') {
                this.columns.push({ label: 'OD, in', fieldName: 'odin', type: 'number', typeAttributes: { minimumFractionDigits: '2' }});
                this.columns.push({ label: 'WT, in', fieldName: 'wtin', type: 'number', typeAttributes: { minimumFractionDigits: '3' }});
                this.columns.push({ label: 'PPF', fieldName: 'ppf', type: 'number' });

                this.filters.push({ label: 'OD, in', type: 'text', api: 'odin'});
                this.filters.push({ label: 'WT, in', type: 'text', api: 'wtin'});
                this.filters.push({ label: 'PPF', type: 'text', api: 'ppf'});
            }

            this.columns.push({ label: 'Incoterms', fieldName: 'incoterms', type: 'text'});
            this.columns.push({ label: 'Destination', fieldName: 'shippingPoint', type: 'text'});
            this.columns.push({ label: 'Price, $/t', fieldName: 'price', type: 'number'});
            this.columns.push({ label: 'Margin, $/t', fieldName: 'margin', type: 'number'});
            this.columns.push({ label: 'Budget margin, $/t', fieldName: 'budgetMargin', type: 'number'});
            this.columns.push({ label: 'Additional Info', fieldName: 'additionalInformation', type: 'text', initialWidth: 200});
            
            this.filters.push({ label: 'Incoterms', type: 'text', api: 'incoterms'});
            this.filters.push({ label: 'Destination', type: 'text', api: 'shippingPoint'});
            this.filters.push({ label: 'Price', type: 'text', api: 'price'});
            this.filters.push({ label: 'Margin', type: 'text', api: 'margin'});
            this.filters.push({ label: 'Budget margin', type: 'text', api: 'budgetMargin'});
            this.filters.push({ label: 'Additional Info', type: 'text', api: 'additionalInformation'});
        }
    };

    handleFilter(event){
        this.prices = event.detail.data;
    }
}