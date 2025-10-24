import { LightningElement, api, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { CloseActionScreenEvent } from "lightning/actions";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getQuoteStructureDetails from '@salesforce/apex/QuotaAdjustmentFormController.getQuoteStructureDetails';
import getQuoteSegmentStruct from '@salesforce/apex/QuotaAdjustmentFormController.getQuoteSegmentStruct';
import createQuoteRequestRecords from '@salesforce/apex/QuotaAdjustmentFormController.createQuoteRequestRecords';
import cancelChanges from '@salesforce/label/c.QuotaCancelChanges';
import calculateChanges from '@salesforce/label/c.QuotaCalculateChanges';
import applyChanges from '@salesforce/label/c.QuotaApplyChanges';

export default class QuotaAdjustmentForm extends LightningElement {
    @api recordId;
    @track quotaData = [];
    @track filteredQuotaData = [];
    @track originalQuotaData = [];
    @track headerTotals = {};
    @track initialHeaderTotals = {};
    @track overallTotals = {
        quoteT: 0,
        newQuoteT: 0,
        deltaQuoteT: 0,
        addQtyT: 0
    };
    @track initialOverallTotals = {};
    @track showBaseOnly = false;
    isLoaded = false;
    isManagerVisible = false;
    isRegionVisible = false;
    isGroup3Visible = false;
    isApplyDisabled = true;
    isWrongPercent = false;

    label = {
        cancelChanges,
        calculateChanges,
        applyChanges
    };

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.state.recordId;
        }
    }
    
    connectedCallback() {
        this.fetchQuoteStructureDetails();
    }

    fetchQuoteStructureDetails() {
        console.log('this.recordId: ', this.recordId);
        getQuoteStructureDetails({ routeQuotaHierarchyId: this.recordId })
            .then((data) => {
                console.log('data: ', data);
                if (data && data.length > 0) {
                    this.quotaData = data;
                    this.filteredQuotaData = [...this.quotaData];
                    this.originalQuotaData = JSON.parse(JSON.stringify(data));
                    this.calculateInitialHeaderTotals();
                    this.calculateOverallTotals();
                }
            })
            .catch((error) => {
                console.error('Error fetching data: ', error);
            });
    }

    @wire(getQuoteSegmentStruct, { routeQuotaHierarchyId: '$recordId' })
    wireQuoteSegmentStruct({ data, error }) {
        if (data && data.length > 0) {
            this.isManagerVisible = data[0].ManagerStruct__c;
            this.isRegionVisible = data[0].RegionStruct__c;
            this.isGroup3Visible = data[0].Group3Struct__c;
        } else if (error) {
            console.log("error =====> " + JSON.stringify(error));
        }
    }

    @api closeModal() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    renderedCallback() {
        if (this.isLoaded) {
            return;
        }

        const STYLE = document.createElement('style');

        STYLE.innerText = `.uiModal--medium .modal-container {
            width: 100% !important;
            height: 108% !important;
            max-width: 100%;
            min-width: 100%;
            max-height: 110%
            min-height: 100%;
        }`;

        this.template.querySelector('lightning-card').appendChild(STYLE);

        this.isLoaded = true;
    }

    calculateInitialHeaderTotals() {
        this.headerTotals = this.quotaData.reduce((acc, row) => {
            const familyType = row.familyType;
            if (!acc[familyType]) {
                acc[familyType] = {
                    quoteT: 0,
                    addQtyT: 0,
                    percent: 0,
                    newPercent: 0,
                };
            }
            acc[familyType].quoteT += parseFloat(row.quoteT || 0);
            acc[familyType].addQtyT += parseFloat(row.addQty || 0);
            acc[familyType].percent += parseFloat(row.percent || 0);
            return acc;
        }, {});

        for (let type in this.headerTotals) {
            this.headerTotals[type].newPercent = this.headerTotals[type].percent;
        }

        this.initialHeaderTotals = JSON.parse(JSON.stringify(this.headerTotals));

        this.overallTotals.quoteT = Object.values(this.headerTotals).reduce(
            (sum, family) => sum + family.quoteT,
            0
        );
        this.overallTotals.addQtyT = Object.values(this.headerTotals).reduce(
            (sum, family) => sum + family.addQtyT,
            0
        );

        this.initialOverallTotals = JSON.parse(JSON.stringify(this.overallTotals));
    }

    calculateOverallTotals() {
        this.overallTotals = {
            quoteT: 0,
            addQtyT: 0,
        };

        for (let type in this.headerTotals) {
            this.overallTotals.quoteT += this.headerTotals[type].quoteT || 0;
            this.overallTotals.addQtyT += this.headerTotals[type].addQtyT || 0;
        }
    }

    get familyTypeTotals() {
        return Object.keys(this.headerTotals).map(familyType => ({
            familyType,
            quoteT: this.headerTotals[familyType].quoteT || 0,
            addQtyT: this.headerTotals[familyType].addQtyT || 0,
            percent: this.headerTotals[familyType].percent || 0,
            newPercent: this.headerTotals[familyType].newPercent || 0,
        }));
    }

    handleInputChange(event) {
        const { id, field } = event.target.dataset;
        const fieldValue = event.target.value;

        this.quotaData = this.quotaData.map(row => {
            if (row.quoteStructDetailId === id) {
                return { ...row, [field]: fieldValue };
            }
            return row;
        });
    }

    handleFamilyTypeCheckboxChange(event) {
        this.showBaseOnly = event.target.checked;
        this.filterData();
    }

    handleCalculateChanges() {
        const updatedHeaderTotals = JSON.parse(JSON.stringify(this.headerTotals));
        let applyDisabled = false;
    
        for (let type in updatedHeaderTotals) {
            updatedHeaderTotals[type].newPercent = 0;
            updatedHeaderTotals[type].addQtyT = 0;
        }
    
        this.quotaData = this.quotaData.map(row => {
            if (row.percent) {
                const familyType = row.familyType;
                const addQty = parseFloat(row.addQty || 0);
    
                updatedHeaderTotals[familyType].quoteT = this.headerTotals[familyType].quoteT;
                updatedHeaderTotals[familyType].newPercent += parseFloat(row.percent || 0);
                updatedHeaderTotals[familyType].addQtyT += addQty;
            }
            return row;
        });

        this.quotaData = this.quotaData.map(row => {
            if (row.percent) {
                const familyType = row.familyType;
                const initialQuoteT = updatedHeaderTotals[familyType].quoteT;
                const addQty = updatedHeaderTotals[familyType].addQtyT;
                const percent = updatedHeaderTotals[familyType].newPercent;
                const updatedQuoteT = (row.percent / percent) * (initialQuoteT - addQty) + parseFloat(row.addQty || 0);
    
                return {...row, newQuota: updatedQuoteT};
            }
            return row;
        });
    
        this.headerTotals = updatedHeaderTotals;
        
        this.calculateOverallTotals();
        this.filterData();
    
        this.familyTypeTotals.forEach(row => {
            if ((row.newPercent > 0 && row.newPercent < 99.98) || row.newPercent > 100.02) {
                applyDisabled = true;
            }
        });
    
        this.isApplyDisabled = applyDisabled;
        this.isWrongPercent = applyDisabled;
    }

    handleCancelChanges() {
        setTimeout(() => {
            this.filteredQuotaData = JSON.parse(JSON.stringify(this.originalQuotaData));
            this.quotaData = JSON.parse(JSON.stringify(this.originalQuotaData));
        }, 0);
    
        this.headerTotals = JSON.parse(JSON.stringify(this.initialHeaderTotals));
        this.overallTotals = JSON.parse(JSON.stringify(this.initialOverallTotals));
        this.isApplyDisabled = true;
        this.isWrongPercent = false;
        this.filterData();
    }    

    calculateSumQuoteT(familyType) {
        return this.quotaData
            .filter(row => row.familyType === familyType)
            .reduce((sum, row) => sum + parseFloat(row.quoteT || 0), 0);
    }

    filterData() {
        if (this.showBaseOnly) {
            this.filteredQuotaData = this.quotaData.filter(row => row.familyType === 'Базовый');
        } else {
            this.filteredQuotaData = [...this.quotaData];
        }
    }

    handleApplyChanges() {
        const updatedHeaderTotals = JSON.parse(JSON.stringify(this.headerTotals));
        for (let type in updatedHeaderTotals) {
            updatedHeaderTotals[type].newPercent = 0;
        }
    
        this.quotaData = this.quotaData.map(row => {
            if (row.percent) {
                const familyType = row.familyType;
                const initialQuoteT = this.headerTotals[familyType].quoteT;
                const addQty = parseFloat(row.addQty || 0);
                const updatedQuoteT = (row.percent / 100) * (initialQuoteT - addQty);
    
                updatedHeaderTotals[familyType].newPercent += parseFloat(row.percent || 0);
    
                return {...row, quoteT: updatedQuoteT};
            }
            return row;
        });
    
        this.headerTotals = updatedHeaderTotals;
        this.calculateOverallTotals();
        this.filterData();

        const familyRecords = Object.keys(this.headerTotals).map(familyType => {
            const familyRow = this.quotaData.find(row => row.familyType === familyType);
            return {
                familyType,
                familyId: familyRow.familyId,
                familyTypeId: familyRow.familyTypeId,
                totalQuote: this.headerTotals[familyType].quoteT,
                totalAddQty: this.headerTotals[familyType].addQtyT,
                percent: this.headerTotals[familyType].percent,
                newPercent: this.headerTotals[familyType].newPercent
            };
        });
    
        const detailRecords = this.filteredQuotaData.map(row => ({
            familyId: row.familyId,
            quoteStructDetailId: row.quoteStructDetailId,
            quoteT: parseFloat(row.newQuota),
            addQty: parseFloat(row.addQty),
            percent: parseFloat(row.percent)
        }));

        try {
            createQuoteRequestRecords({
                routeQuotaHierarchyId: this.recordId,
                families: familyRecords,
                details: detailRecords
            });
    
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Quote Request created successfully!',
                    variant: 'success'
                })
            );
        } catch (error) {
            console.error('Error creating records: ', error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Failed to create Quote Request',
                    variant: 'error'
                })
            );
        }

        this.dispatchEvent(new CloseActionScreenEvent());
    }
    
}