import { LightningElement, api, track } from 'lwc';
import getFilteredPrices from '@salesforce/apex/AllPricesDatatableController.getFilteredPrices';

export default class DynamicFilterForPrices extends LightningElement {
    @api filters;
    @track prices = [];

    connectedCallback() {
        this.filters = JSON.parse(JSON.stringify(this.filters));
    }

    handleChange(event) {
        this.filters.find(filter => filter.api === event.target.name).value = event.target.value;
        this.fetchData();
    }

    fetchData() {
        let filterValues = {};
        let fieldsTypes = {};
        let fieldsMax = {};
        this.filters.forEach(filter => {
            if (filter.value) {
                filterValues[filter.api] = filter.value;
                fieldsTypes[filter.api] = filter.fieldType;
                fieldsMax[filter.api] = filter.apiMax;
            }
        });

        getFilteredPrices({ filters: filterValues, fieldsTypes: fieldsTypes, fieldsMax: fieldsMax })
            .then(data => {
                this.dispatchEvent(new CustomEvent('filter', { detail: { data } }));
            })
            .catch(error => {
                console.error('Error fetching filtered data:', error);
            });
    }

    resetFilters() {
        this.filters.forEach(filter => filter.value = '');
        this.template.querySelectorAll('lightning-input').forEach(input => input.value = '');
        this.fetchData();
    }
}