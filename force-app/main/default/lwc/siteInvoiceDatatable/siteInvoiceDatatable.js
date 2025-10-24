import { LightningElement, track, wire,api } from 'lwc';
import {NavigationMixin} from 'lightning/navigation';

import getInvoices from '@salesforce/apex/SiteInvoiceController.getInvoices';
import getCurrenciesRate from '@salesforce/apex/SiteInvoiceController.getCurrenciesRate';
import getAccountMarketSegment from '@salesforce/apex/SiteInvoiceController.getAccountMarketSegment';
import requestForInvoicePDF from '@salesforce/apex/SiteInvoiceController.requestForInvoicePDF';
import getAllDivisions from '@salesforce/apex/UserUtils.getAllDivisions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';


import IMAGES from "@salesforce/resourceUrl/SiteImages";

import PRINT from '@salesforce/label/c.Print';
import CHOOSEADATE from '@salesforce/label/c.Choose_a_date';
import FROM from '@salesforce/label/c.From';
import TO from '@salesforce/label/c.To';
import VIEW from '@salesforce/label/c.View';
import Total_Debt_Common from '@salesforce/label/c.Total_Debt_Common';
import Total_Debt_Other_documents from '@salesforce/label/c.Total_Debt_Other_documents';
import Total_Debt_Orders from '@salesforce/label/c.Total_Debt_Orders';
import Overdue_accounts_receivable from '@salesforce/label/c.Overdue_accounts_receivable';
import All_Invoices from '@salesforce/label/c.All_Invoices';
import By_Contracts from '@salesforce/label/c.By_contracts';
import Contract from '@salesforce/label/c.Contract';
import Detail from '@salesforce/label/c.Site_Detail';
import Prod_Type from '@salesforce/label/c.Prod_Type';

import site_th_Product from '@salesforce/label/c.Site_th_Product';
import Currency from '@salesforce/label/c.Currency';
import Outstanding_Debt from '@salesforce/label/c.Outstanding_Debt';
import VAT_Amount from '@salesforce/label/c.VAT_Amount';
import Net_Amount from '@salesforce/label/c.Net_Amount';
import Days_Overdue from '@salesforce/label/c.Days_Overdue';
import Due_Date from '@salesforce/label/c.Due_Date';
import Invoice_Date from '@salesforce/label/c.Invoice_Date';
import Invoice from '@salesforce/label/c.Invoice';
import COC from '@salesforce/label/c.COC';


export default class SiteinvoiceDatatable extends NavigationMixin(LightningElement) {
    allInvoices
    @track displayedInvoices;
    @track selectedCurrency;
    @track groupedInvoices;
    @track isMENAUser;
    @track isUkraineUser;
    @track dropdownOpen = false;
    @track optionsToDisplay;
    @api activeTab;
    @track isLoading = false;
    invoicesWithCalculatedCurrencies;
    invoicesWithCalculatedCurrenciesForOtherDocs;
    allinvoicesCount;
    labels = {
        Total_Debt_Common,
        Total_Debt_Other_documents,
        Total_Debt_Orders,
        Overdue_accounts_receivable,
        site_th_Product,
        Currency,
        Outstanding_Debt,
        VAT_Amount,
        Net_Amount,
        Days_Overdue,
        Due_Date,
        Invoice_Date,
        Invoice,
        COC,
        All_Invoices,
        By_Contracts,
        Contract,
        Detail,
        Prod_Type
    }

    b64 = 'data:application/pdf;base64, ';
    nameFile = 'Certificate.pdf';

    totalOutstandingDebt = null;
    totalOutstandingDebtOverdue = null;

    currenciesRate= {};
    isCurrencySelected = false;
    currencyIsoCode;
    
    startDate;
    endDate;
    searchKey;

    invDateSortToggled = false;
    dueDateSortToggled = false;
    sortByInvDateAsc = true;
    sortByDueDateAsc = true;
    isAllInvoices;
    isUSDInvoices;
    isEURInvoices;
    isAllDivisions;


    print = PRINT;
    chooseADate = CHOOSEADATE;
    from = FROM;
    to = TO;
    view = VIEW;
    refresh = IMAGES + '/refresh.png';
    sortIcon = IMAGES + '/filterIcon.png';

    currencyOptions = [
        { label: 'USD', value: 'USD' },
        { label: 'EUR', value: 'EUR' },
        { label: 'PLN', value: 'PLN' },
        { label: 'RON', value: 'RON' },
        { label: 'AED', value: 'AED' },
        { label: 'UAH', value: 'UAH' },
    ];
    globalSelectedCurrency;

    @track options = [
        { id: 'tab-default-1__item', label:  "All invoices", order: 1}
    ];
    @track selectedOption = this.options[0].label;
    @track showContractsTab = false;
    connectedCallback(){
        getAccountMarketSegment().then(result => {

            if (result == '00002') {
                this.isMENAUser = true;
            }else if(result == '00011'){
                this.isUkraineUser = true;
            }
            this.showContractsTab = result === '00010' || result === '00011'; // CIS or Ukraine
        })

        getAllDivisions().then(resultAllDivisions => {
            this.isAllDivisions = resultAllDivisions;
        })
    }
    renderedCallback() {
        if(!this.isMENAUser){
            let styleSum = window.getComputedStyle(this.refs.sum);
            let styleCurrency = window.getComputedStyle(this.refs.currency);
            let styleDropdownBtn = window.getComputedStyle(this.refs.dropdownBtn);
            if(this.refs.dropdownList?.style){
                this.refs.dropdownList.style.width = styleDropdownBtn.width;
            }
                this.refs.sumTotal.style.width = styleSum.width;
                this.refs.currencyTotal.style.width = styleCurrency.width;
        }
    }
    
    
    @wire(getInvoices, {}) handleInvoices(result) {
        const {error,data} = result;
        if (data) {
            let dataCopy = this.deepCopy(data)
            dataCopy.forEach(item => {
                if(item.Name.length > 14){
                    item.Name = 'N/A'
                }
                if(item.Account__r.MarketSegment__c == '00004'){
                    item.DaysOverdue__c += 1;
                }
                if(item.DaysOverdue__c  <= 0){
                    item.DaysOverdue__c = 0;
                }
                if (item.Order__r) {
                    if (item.Order__r && item.Order__r.AdditionalNumber__c !== null) {
                        item.AdditionalNumber = item.Order__r.AdditionalNumber__c;
                        item.ProdType = item.Order__r.Prod_Type__c;
                    } else {
                        item.AdditionalNumber = 'N/A';
                        item.ProdType = '';
                    }
                } else {
                    item.AdditionalNumber = 'N/A';
                    item.ProdType = '';
                }
                
                item.NetAmount__c = item.NetAmount__c.toLocaleString('uk', {minimumFractionDigits : 2});
                item.VATAmount__c = parseFloat(item.VATAmount__c).toFixed(2);
                item.VATAmount__c = item.VATAmount__c.toLocaleString('uk', {minimumFractionDigits : 2});
                item.OutstandingDebt__c = item.OutstandingDebt__c.toLocaleString('uk', {minimumFractionDigits : 2});

            });
            this.allInvoices = dataCopy
            this.displayedInvoices = this.allInvoices;
            this.currencyIsoCode;
            // перевіряємо чи всі об'єкти в масиві мають однаковий CurrencyIsoCode
            const hasSameCurrency = this.displayedInvoices.every(obj => obj.CurrencyIsoCode === this.displayedInvoices[0].CurrencyIsoCode);

            this.allinvoicesCount = this.displayedInvoices.length;
    
            getCurrenciesRate().then(result => {
                this.currenciesRate = result;
                if (hasSameCurrency) {
                    if(this.displayedInvoices.length>0){
                        this.currencyIsoCode = this.displayedInvoices[0].CurrencyIsoCode;
                    }else if(this.isUkraineUser){
                        this.currencyIsoCode = 'UAH'
                    }else {
                        this.currencyIsoCode = 'USD'
                    }
                    this.selectedCurrency = this.currencyIsoCode;
                    this.isCurrencySelected = true;
                    this.globalSelectedCurrency = this.selectedCurrency
                    this.changeCurrency(null)
                }
            })
        }
        if (error) {
            console.error(error);
        }
    
    }
    //Groups invoices by their associated contract and calculates aggregate amounts for each group.
    groupInvoices(invoices) {
        let contractMap = new Map();
        invoices.forEach(invoice => {
            const netAmount = parseFloat(invoice.NetAmount__c.replace(/ /g, '').replace(',', '.'));
            const vatAmount = parseFloat(invoice.VATAmount__c.replace(/ /g, '').replace(',', '.'));
            const outstandingDebt = parseFloat(invoice.OutstandingDebt__c.replace(/\s/g, '').replace(',', '.'));
    
            if (contractMap.has(invoice.Contract__c)) {
                let contractInfo = contractMap.get(invoice.Contract__c);
                contractInfo.invoices.push(invoice);
                contractInfo.totalNetAmount += netAmount;
                contractInfo.totalVATAmount += vatAmount;
                contractInfo.totalOutstandingDebt += outstandingDebt;
                if (invoice.DaysOverdue__c > 0) {
                    contractInfo.totalOverdueOutstandingDebt += outstandingDebt;
                }
            } else {
                contractMap.set(invoice.Contract__c, {
                    contract: invoice.Contract__c,
                    invoices: [invoice],
                    totalNetAmount: netAmount,
                    totalVATAmount: vatAmount,
                    totalOutstandingDebt: outstandingDebt,
                    totalOverdueOutstandingDebt: invoice.DaysOverdue__c > 0 ? outstandingDebt : 0
                });
            }
        });
    
        contractMap.forEach((contract) => {
            contract.totalOutstandingDebt = contract.totalOutstandingDebt.toLocaleString('uk', {minimumFractionDigits : 2});
            contract.totalOverdueOutstandingDebt = contract.totalOverdueOutstandingDebt.toLocaleString('uk', {minimumFractionDigits : 2});
        });
    
        console.log(contractMap);
        return Array.from(contractMap.values());
    }
    
/**
 * Changes the currency for invoice amounts and recalculates values accordingly.
 * @param {Event|string} event - The event triggered by currency selection or a string representing the currency code.
 *
 * This method resets the total outstanding debts, updates the selected currency,
 * and recalculates the invoice amounts based on the current exchange rates.
 * It handles both direct string inputs (e.g., 'EUR', 'USD') and events from UI interactions.
 * After recalculating, it updates the displayed invoices with converted amounts in the selected currency.
 */

    changeCurrency(event) {
        this.totalOutstandingDebtOverdue = null;
        this.totalOutstandingDebt = null;

        if (event == 'EUR') {
            this.selectedCurrency = 'EUR';
            
        } else if(event == 'USD'){
            this.selectedCurrency = 'USD';

        }
         else if(event){
            this.selectedCurrency = event.detail.value;
            // this.globalSelectedCurrency = event.detail.value;
        }
        else{
            this.selectedCurrency = this.globalSelectedCurrency;
        }
        this.isCurrencySelected = this.selectedCurrency || this.globalSelectedCurrency;
        let invoicesListCopy = this.deepCopy(this.displayedInvoices);
        if(invoicesListCopy.length > 0){
            try {
                let rateFrom = null;
                let rateTo = null;
                // Map invoices list to convert amounts to selected currency
                this.invoicesWithCalculatedCurrencies = invoicesListCopy.map(item => {
                    // Get exchange rate for source and destination currency
                    Object.keys(this.currenciesRate).forEach(key => {
                        if (key.endsWith('Rate__c') && key.replace('Rate__c', '') === item.CurrencyIsoCode) {
                            rateFrom = this.currenciesRate[key];
                        }
                        if (key.endsWith('Rate__c') && key.replace('Rate__c', '') === this.selectedCurrency) {
                            rateTo = this.currenciesRate[key];
                        }
                    });
                    // Convert amounts to selected currency
                    if (rateFrom && rateTo) { 
                        item.NetAmount__c =  parseFloat(item.NetAmount__c.replace(/[^\d.,-]/g, '').replace(',', '.'));
                        item.VATAmount__c = parseFloat(item.VATAmount__c.replace(/[^\d.,-]/g, '').replace(',', '.'));
                        item.OutstandingDebt__c = parseFloat(item.OutstandingDebt__c.replace(/[^\d.,-]/g, '').replace(',', '.'));
                        const convertedNetAmount = ((item.NetAmount__c * rateFrom) / rateTo).toFixed(2);
                        const convertedVatAmount = ((item.VATAmount__c * rateFrom) / rateTo).toFixed(2);
                        const convertedDebtAmount = ((item.OutstandingDebt__c * rateFrom) / rateTo).toFixed(2);
                        item.NetAmount__c = parseFloat(convertedNetAmount);
                        item.VATAmount__c = parseFloat(convertedVatAmount);
                        item.OutstandingDebt__c = parseFloat(convertedDebtAmount);
                        this.totalOutstandingDebt += item.OutstandingDebt__c;
                        if (item.DaysOverdue__c > 0) {
                            this.totalOutstandingDebtOverdue += item.OutstandingDebt__c;
                        }
                        item.NetAmount__c = item.NetAmount__c.toLocaleString('uk', {minimumFractionDigits : 2});
                        item.VATAmount__c = item.VATAmount__c.toLocaleString('uk', {minimumFractionDigits : 2});
                        item.OutstandingDebt__c = item.OutstandingDebt__c.toLocaleString('uk', {minimumFractionDigits : 2});
                        item.CurrencyIsoCode = this.selectedCurrency;
                    }
                    return item;
                })
                this.displayedInvoices = this.deepCopy(this.invoicesWithCalculatedCurrencies);
                this.groupedInvoices = this.groupInvoices(this.displayedInvoices);
                if(this.totalOutstandingDebtOverdue){
                    this.totalOutstandingDebtOverdue = this.totalOutstandingDebtOverdue.toLocaleString('uk', {minimumFractionDigits : 2});
                }
                this.totalOutstandingDebt = this.totalOutstandingDebt.toLocaleString('uk', {minimumFractionDigits : 2});
        
            } catch (error) {
                console.error(error);
            }
        }

    }    
/**
 * Tab and Dropdown Interaction Functions
 * ---------------------------------------
 * 
 * This set of functions manages user interactions with tabs and dropdowns in the UI
 *
 * Methods:
 *  - toggleSubtabs(event): Toggles subtabs based on user interaction, ensuring the corresponding 
 *    tab content is displayed.
 *  - toggleDropdown(): Toggles the visibility state of the dropdown menu, allowing for dynamic 
 *    display of options.(mobile)
 *  - selectDropdownOption(event): Handles the selection of an option from the dropdown menu, 
 *    updating the UI to reflect the chosen option and triggering corresponding data display.(mobile)
 *  - switchTabName(idAttribute): Switches the active state of tabs based on the selected 
 *    option or user interaction.
 *  - updateTabState(idAttribute): Updates the component's state to reflect the current active 
 *    tab, triggering data filters and currency changes as needed.
 */

    toggleSubtabs(event) {
        this.switchTabName(event.target.dataset.id)  
        this.switchTabName(event.target.dataset.id) 
        this.activeTab = event.target.dataset.id;                  
    }
    get isTab4Active() {
        return this.activeTab === 'tab-default-4__item'; // or whatever the identifier for your fourth tab is
    }
    
    toggleDropdown() {
        this.dropdownOpen = !this.dropdownOpen;
    }
    selectDropdownOption(event) {
        const selectedOptionId = event.target.dataset.id;
        this.switchTabName(selectedOptionId)    
        const selectedOption = this.options.find((option) => option.id === selectedOptionId);
        if (selectedOption) {   
            this.selectedOption = selectedOption.label;
            this.optionsToDisplay = this.options.filter((option) => option.label !== selectedOption.label);
            this.optionsToDisplay.sort((a, b) => a.order - b.order);
        }
        this.dropdownOpen = false;
    }
    switchTabName(idAttribute) {
        this.template.querySelectorAll('.slds-tabs_default__item').forEach((data) => {
            const tabLink = data.querySelector('a');
            const isActive = tabLink.dataset.id === idAttribute;
            data.classList.toggle("slds-is-active", isActive);
        });

        this.updateTabState(idAttribute);
    }

    updateTabState(idAttribute) {
        const tabStates = {
            'tab-default-1__item': { all: true, usd: false, eur: false, contract: false},
            'tab-default-2__item': { all: false, usd: true, eur: false, contract: false },
            'tab-default-3__item': { all: false, usd: false, eur: true, contract: false },
            'tab-default-4__item': { all: false, usd: false, eur: false, contract: true }

        };

        const state = tabStates[idAttribute];
        if (state) {
            this.isAllInvoices = state.all;
            this.isUSDInvoices = state.usd;
            this.isEURInvoices = state.eur;
        
            if (state.all) {
                // this.resetSearch();
            }else if(state.contract){
                
            } else {
                const currency = state.usd ? 'USD' : 'EUR';
                this.changeCurrency(currency);
            }
        
            this.filterInvoices();
        }
    }

/**
 * Invoice Display Management Functions
 * -------------------------------------
 * Methods:
 *  - setStartDate(event): Sets the start date for invoice filtering, enhancing date-based data exploration.
 *  - setEndDate(event): Sets the end date for invoice filtering, allowing users to narrow down the data view.
 *  - searchInvoices(event): Enables keyword-based search functionality, allowing users to quickly find relevant invoices.
 *  - cancelCurrencyInput(): Cancels the currently selected currency and resets the state of the component
 *  - resetSearch(switchTab): Resets all search and filter criteria, providing a clean slate for data viewing.
 *  - filterInvoices(): Applies the set filter criteria (such as dates and search terms) to the invoice data, updating the view accordingly.
 *  - sortInvoicesByDate(): Sorts the invoices based on their date, offering an ordered view for better data comprehension.
 *  - sortInvoicesByDueDate(): Sorts the invoices based on their due date, helping prioritize overdue or upcoming invoices.
 *  - requestForInvoicePDFHandle: fetches an invoice PDF, manages loading state, handles success or error outcomes, and controls UI feedback
 */
    setStartDate(event) {
        this.startDate = new Date(event.target.value + 'T23:59:59');
        this.filterInvoices();
        this.changeCurrency(null)
    }
    setEndDate(event) {
        this.endDate = new Date(event.target.value + 'T23:59:59');
        this.filterInvoices();
        this.changeCurrency(null)

    }
    searchInvoices(event) {
        this.searchKey = event.target.value.toLowerCase();
        this.filterInvoices();
        this.changeCurrency(null)
    }
    cancelCurrencyInput() {
        if(this.currencyIsoCode){
            this.selectedCurrency = this.currencyIsoCode;
            this.changeCurrency(null)
        }else {
            // this.selectedCurrency = '';
            this.totalOutstandingDebt = null;
            this.isCurrencySelected = false;
            this.displayedInvoices = this.deepCopy(this.allInvoices)
        }
        // this.resetSearch('true');

    }
    resetSearch(switchTab) {
        // Clear any selected currency, start date, end date, and search key.
        this.startDate = null;
        this.endDate = null;
        if(this.currencyIsoCode){
            this.selectedCurrency = this.currencyIsoCode;
            this.changeCurrency(null)
        }else {
            this.selectedCurrency = '';
            this.totalOutstandingDebt = null;
            this.isCurrencySelected = false;
            this.displayedInvoices = this.deepCopy(this.allInvoices)
        }
        // Clear the values of all input fields in the template.
        [...this.template
            .querySelectorAll('lightning-input, lightning-textarea')
        ]
        .forEach((input) => {
            input.value = '';
        });
        this.displayedInvoices = this.deepCopy(this.allInvoices)
        this.switchTabName('tab-default-1__item');
    }

    filterInvoices() {    
        if(this.isCurrencySelected){
            this.displayedInvoices = this.displayedInvoices;

        }else {
            this.displayedInvoices = this.deepCopy(this.allInvoices)
        }
        if (this.searchKey) {
            if (this.displayedInvoices) {
                let searchRecords = [];
                for (let record of this.displayedInvoices) {
                    let valuesArray = Object.values(record);

                    for (let val of valuesArray) {
                        let strVal = String(val);

                        if (strVal) {

                            if (strVal.toLowerCase().includes(this.searchKey)) {
                                searchRecords.push(record);
                                break;
                            }
                        }
                    }
                }
                this.displayedInvoices = searchRecords;
            }
        } else {
            this.displayedInvoices = this.deepCopy(this.allInvoices)
        }
        if (this.startDate) {
            this.displayedInvoices = this.displayedInvoices.filter(invoice => {
                return new Date(invoice.InvoiceDate__c) >= this.startDate;
            })
        }

        if (this.endDate) {
            this.displayedInvoices = this.displayedInvoices.filter(invoice => {
                return new Date(invoice.InvoiceDate__c) <= this.endDate;
            })
        }

        if (this.isAllInvoices) {
            this.displayedInvoices = this.displayedInvoices.filter(invoice => {
                return invoice;
            })
        }
        if (this.isUSDInvoices) {
            this.displayedInvoices = this.displayedInvoices.filter(invoice => {
                return invoice.CurrencyIsoCode == 'USD' && invoice.Order__c !== null;
            })
        }
        if (this.isEURInvoices) {
            this.displayedInvoices = this.displayedInvoices.filter(invoice => {
                return invoice.CurrencyIsoCode == 'EUR' && invoice.Order__c !== null;
            })
        }
    }
    sortInvoicesByDate(){
        if(!this.invDateSortToggled ){
            this.invDateSortToggled = !this.invDateSortToggled;
            this.dueDateSortToggled = false;
            this.template.querySelector('[data-id="invDateSortIcon"]').classList.add('sort-icon-rotate');
            this.template.querySelector('[data-id="dueDateSortIcon"]').classList.remove('sort-icon-rotate')
            
            
        }else{
            this.invDateSortToggled = !this.invDateSortToggled;
            this.template.querySelector('[data-id="invDateSortIcon"]').classList.remove('sort-icon-rotate')
            this.template.querySelector('[data-id="dueDateSortIcon"]').classList.remove('sort-icon-rotate')
        }
        try {
            var self = this;
            let arrayForSort = [...this.displayedInvoices];
            arrayForSort.sort(function(a, b) {
                if(self.sortByInvDateAsc){
                    return new Date(b.InvoiceDate__c)-new Date(a.InvoiceDate__c);
                } else {
                    return new Date(a.InvoiceDate__c)-new Date(b.InvoiceDate__c);
                }
                
            });
            this.displayedInvoices = arrayForSort;
            this.sortByInvDateAsc = !this.sortByInvDateAsc;
        } catch (error) {
            console.error(error);
        }
        
    }
    sortInvoicesByDueDate(){
        if(!this.dueDateSortToggled ){
            this.dueDateSortToggled = !this.dueDateSortToggled;
            this.invDateSortToggled = false;
            this.template.querySelector('[data-id="dueDateSortIcon"]').classList.add('sort-icon-rotate');
            this.template.querySelector('[data-id="invDateSortIcon"]').classList.remove('sort-icon-rotate')
            
            
        }else{
            this.dueDateSortToggled = !this.dueDateSortToggled;
            this.template.querySelector('[data-id="invDateSortIcon"]').classList.remove('sort-icon-rotate')
            this.template.querySelector('[data-id="dueDateSortIcon"]').classList.remove('sort-icon-rotate')
        }
        try {
            var self = this;
            let arrayForSort = [...this.displayedInvoices];
            arrayForSort.sort(function(a, b) {
                if(self.sortByDueDateAsc){
                    return (a.DaysOverdue__c)-(b.DaysOverdue__c);
                } else {
                    return (b.DaysOverdue__c)-(a.DaysOverdue__c);
                }
                
            });
            this.displayedInvoices = arrayForSort;
            this.sortByDueDateAsc = !this.sortByDueDateAsc;
        } catch (error) {
            console.error(error);
        }
    }
    handleViewDetailPDF(event) {
        const selectedRowId = event.target.dataset.id;
        console.log(selectedRowId);
        console.log(this.allInvoices);

        const selectedRow = this.allInvoices.find(row => row.Id === selectedRowId);
        console.log(selectedRow);

        if (selectedRow) {
            const org = selectedRow.Account__r.ID_ERP__c;
            const orgK = selectedRow.InternalAccount__r.ID_ERP__c;
            const ndmInvoice = selectedRow.Name;

            this.requestForInvoicePDFHandle(org, orgK, ndmInvoice);
            this.showSpinner = true;
            this.bShowModal = true; // Display modal window
        }
        
    }
    requestForInvoicePDFHandle(org1, orgK1, ndmInvoice1) {
        this.isLoading = true; // Show spinner
        requestForInvoicePDF({org: org1, orgK: orgK1, ndmInvoice: ndmInvoice1})
            .then((result) => {
                // Check if result is null
                console.log('RESULT CONTENTS  ', result.CONTENTS);

                if (result.CONTENTS == undefined) {
                    this.showToast('File is not available', 'The selected invoice is not available in PDF yet', 'warning');
                } else {
                    console.log('RESULT 123  ', result);
                    this.b64 += result.CONTENTS;
                    let downloadLink = document.createElement("a");
                    downloadLink.href = this.b64;
                    downloadLink.download = '' + ndmInvoice1;
                    this.showToast('Success!', 'Your invoice has been downloaded. Please check your Downloads folder.', 'success');
                    downloadLink.click();
                }
            })
            .catch((error) => {
                console.error(error);
                this.showToast('File is not available*', 'The selected invoice is not available in PDF yet', 'warning');
            })
            .finally(() => {
                this.isLoading = false; // Hide spinner
            });
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: 'sticky'
        });
        this.dispatchEvent(evt);
    }
    
    /**
 * Deep Copy Function
 * ------------------
 * Creates a deep copy of a given object or array. This method is essential for avoiding direct
 * mutations to state data, ensuring that the original data structure is not altered when modifications
 * are made to the copy.
 */
    deepCopy(inObject) {
        let outObject, value, key
        // If the input is not an object or is null, return the value
        if (typeof inObject !== "object" || inObject === null) {
            return inObject
        }
        // Create an empty array or object to hold the copied values
        outObject = Array.isArray(inObject) ? [] : {}
        // Loop through all keys in the input object
        for (key in inObject) {
            value = inObject[key]
            // Recursively call the deepCopy function to copy nested objects or arrays
            outObject[key] = this.deepCopy(value)
        }
        return outObject
    }
}