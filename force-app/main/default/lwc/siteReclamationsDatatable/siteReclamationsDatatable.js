import { LightningElement, track, wire,api } from 'lwc';
import getUserLanguage from '@salesforce/apex/UserUtils.getUserLanguage';
import IMAGES from "@salesforce/resourceUrl/SiteImages";
import getReclamations from '@salesforce/apex/ReclamationDatatableController.getReclamations';
import generatePdf from '@salesforce/apex/ReclamationDatatableController.generatePdf';
import PRINT from '@salesforce/label/c.Print';
import CHOOSEADATE from '@salesforce/label/c.Choose_a_date';
import FROM from '@salesforce/label/c.From';
import TO from '@salesforce/label/c.To';

import Site_th_number from '@salesforce/label/c.Site_th_number';
import Site_th_dateReclamation from '@salesforce/label/c.Site_th_dateReclamation';
import Site_th_Stage from '@salesforce/label/c.Site_th_Stage';
import Site_th_Owner from '@salesforce/label/c.Site_th_Owner';
import Site_th_Refund from '@salesforce/label/c.Site_th_Refund';
import Site_th_erpNumber from '@salesforce/label/c.Site_th_erpNumber';

import All_Reclamations from '@salesforce/label/c.All_Reclamations';
import Stage_Draft from '@salesforce/label/c.Stage_Draft';
import Stage_Sended from '@salesforce/label/c.Stage_Sended';
import Stage_Registered from '@salesforce/label/c.Stage_Registered';
import Stage_Considered from '@salesforce/label/c.Stage_Considered';
import Stage_Rejected from '@salesforce/label/c.Stage_Rejected';
import Stage_Accepted from '@salesforce/label/c.Stage_Accepted';
import Stage_Director_Decision from '@salesforce/label/c.Stage_Director_Decision';
import Stage_OnHold from '@salesforce/label/c.On_Hold';


import {NavigationMixin} from 'lightning/navigation';

export default class SiteOrderDatatable extends NavigationMixin(LightningElement) {
    @track data;
    @track filteredReclamationsList;
    @track reclamationsList;
    @track reclamationsResult;
    @track selectedReclamationid;
    
    @track amountAllClaims;
    @track amountRegisteredClaims;
    @track amountConsideredClaims;
    @track amountRejectedClaims
    @track amountShippedClaims;
    @track amountAcceptedClaims
    @track amountOnHoldClaims;

    @track dropdownOpen = false;
    @track optionsToDisplay;


    print = PRINT;
    chooseADate = CHOOSEADATE;
    from = FROM;
    to = TO;

    allReclamations;
    isDraftReclamations;
    isRegisteredReclamations;
    isConsideredReclamations;
    isRejectedReclamations;
    isAcceptedReclamations;
    isOnHoldReclamations;

    startDate;
    endDate;
    searchKey;
    sortIcon = IMAGES + '/filterIcon.png';
    printImg = IMAGES + '/print.png';
    refresh = IMAGES + '/refresh.png';
    yesImg = IMAGES + '/Yes.png';
    NoImg = IMAGES + '/No.png';
    refundImg;
    dateSortToggled = false;
    stageSortToggled = false;
    numberSortToggled = false;

    isModalOpen = false;
    showGenPdfSpinner = false;

    sortBydateAsc = true;


    labels = {
        Site_th_number,
        Site_th_dateReclamation,
        Site_th_Stage,
        Site_th_Owner,
        Site_th_Refund,
        Site_th_erpNumber,
        All_Reclamations,
        Stage_Draft,
        Stage_Sended,
        Stage_Registered,
        Stage_Considered,
        Stage_Rejected,
        Stage_Accepted,
        Stage_Director_Decision,
        Stage_OnHold
        
    }

    @wire(getReclamations,{}) handleReclamations(result){
        this.reclamationsResult = result;
        const {error, data } = result;
        if(data){
            console.log(data);
            let dataCopy = data.map(item=>{
                return Object.assign({},item);
            })
            dataCopy.forEach(item => {
              if(item.Status__c == 'Director decision') {
                item.Status__c = 'Being considered';
              }
              if(item.Status__c == 'Is being considered') {
                item.Status__c = 'Being considered';
              }
              if(item.Status__c == 'Rejected') {
                item.Status__c = 'Declined';
              }
            });
            this.reclamationsList = dataCopy;
            this.filteredReclamationsList = dataCopy;

            let all = this.filteredReclamationsList.filter((item=>{
                return item;
            }))
            let registered = this.filteredReclamationsList.filter((item=>{
                return item.Status__c == 'Registered';
            }))
            let considered = this.filteredReclamationsList.filter((item=>{
                return item.Status__c == 'Being considered';
            }))
            let draft = this.filteredReclamationsList.filter((item=>{
                return item.Status__c == 'Draft';
            }))
            let rejected = this.filteredReclamationsList.filter((item=>{
                return item.Status__c == 'Declined';
            }))
            let accepted = this.filteredReclamationsList.filter((item=>{
                return item.Status__c == 'Accepted' || item.Status__c == 'Accepted partially' || 
                item.Status__c == 'Accepted (pending compensation)' || item.Status__c == 'Accepted partially (pending compensation)';
            }))
            let onHold = this.filteredReclamationsList.filter((item=>{
                return item.Status__c == 'On Hold';
            }))


            // Draft
            // Registered
            // Is being considered
            // Rejected
            // Accepted

            this.amountAllClaims = all.length;
            this.amountRegisteredClaims = registered.length;
            this.amountConsideredClaims = considered.length;
            this.amountRejectedClaims = rejected.length;
            this.amountDraftClaims = draft.length;
            this.amountAcceptedClaims = accepted.length;
            this.amountOnHoldClaims = onHold.length;
        }
        if(error){
            console.error(error);
        }

    }

    handleSearch(event) {
        this.searchKey = event.target.value.toLowerCase();
        this.searchBy();
    }

    generatePdf() {
        this.showGenPdfSpinner = true;
        let reclamations = this.filteredReclamationsList.map(reclamation => {
            return reclamation.Id;
        })
        //console.log( 'selected reclamations ', JSON.stringify(reclamations));
        generatePdf({selectedReclamations: JSON.stringify(reclamations)}).then(result => {
            //console.log( 'gen pdf result ', result);
            this.showGenPdfSpinner = false;
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: result
                }
            });
        })
        .catch(error => {
            console.log(error);
            this.showGenPdfSpinner = false;
        })
    }

    refreshSearch(){
        this.filteredReclamationsList = this.reclamationsList;
        this.startDate = null;
        this.endDate = null
        this.searchKey = null;
        [...this.template
            .querySelectorAll('lightning-input, lightning-textarea')]
            .forEach((input) => { input.value = ''; });

        this.switchTabName('tab-default-1__item');
    }

    setStartDate(event){
        this.startDate = event.target.value;
        //console.log( this.startDate);
        this.searchBy();
    }
    setEndDate(event){
        this.endDate = event.target.value;
        //console.log( this.endDate);
        this.searchBy();
    }

    searchBy(){
        
        this.filteredReclamationsList = this.reclamationsList;
        //console.log( this.filteredReclamationsList);
        if (this.searchKey) {
            if (this.filteredReclamationsList) {
                let searchRecords = [];
                for (let record of this.filteredReclamationsList) {
                    let valuesArray = Object.values(record);
 
                    for (let val of valuesArray) {
                        // //console.log( 'val is ' + val);
                        let strVal = String(val);
 
                        if (strVal) {
 
                            if (strVal.toLowerCase().includes(this.searchKey)) {
                                searchRecords.push(record);
                                break;
                            }
                        }
                    }
                }
 
                //console.log( 'Matched Reclamations are ' + JSON.stringify(searchRecords));
                this.filteredReclamationsList = searchRecords;
            }
        } else {
            this.filteredReclamationsList = this.reclamationsList;
        }

        if(this.startDate){
            this.filteredReclamationsList = this.filteredReclamationsList.filter(reclamation=>{
                return reclamation.CreatedDate >= this.startDate;
            })
        }

        if(this.endDate){
            this.filteredReclamationsList = this.filteredReclamationsList.filter(reclamation=>{
                return reclamation.CreatedDate <= this.endDate;
            })
        }
        if(this.allReclamations){
            //console.log( this.allReclamations);
            this.filteredReclamationsList = this.filteredReclamationsList.filter(reclamation=>{
                return reclamation
            })
        }
        if(this.isDraftReclamations){
            this.filteredReclamationsList = this.filteredReclamationsList.filter(reclamation=>{
                return reclamation.Status__c == 'Draft';
            })
        }
        if(this.isRegisteredReclamations){
            this.filteredReclamationsList = this.filteredReclamationsList.filter(reclamation=>{
                return reclamation.Status__c == 'Registered';
            })
        }
        if(this.isConsideredReclamations){
            this.filteredReclamationsList = this.filteredReclamationsList.filter(reclamation=>{
                return reclamation.Status__c == 'Being considered';
            })
        }
        if(this.isRejectedReclamations){
            this.filteredReclamationsList = this.filteredReclamationsList.filter(reclamation=>{
                return reclamation.Status__c == 'Declined';
            })
        }
        if(this.isOnHoldReclamations){
            this.filteredReclamationsList = this.filteredReclamationsList.filter(reclamation=>{
                return reclamation.Status__c == 'On Hold';
            })
        }
        if(this.isAcceptedReclamations){
            this.filteredReclamationsList = this.filteredReclamationsList.filter(reclamation=>{
                return reclamation.Status__c == 'Accepted' || reclamation.Status__c == 'Accepted partially' || 
                reclamation.Status__c == 'Accepted (pending compensation)' || reclamation.Status__c == 'Accepted partially (pending compensation)';
            })
        }

    }
    @track options = [
        { id: 'tab-default-1__item', label:  this.labels.All_Reclamations, order: 1},
        { id: 'tab-default-3__item', label:  this.labels.Stage_Registered   , order: 2},
        { id: 'tab-default-4__item', label:  this.labels.Stage_Considered   , order: 3},
        { id: 'tab-default-5__item', label:  this.labels.Stage_Rejected   , order: 4 ,},
        { id: 'tab-default-6__item', label:  this.labels.Stage_Accepted   , order: 5 ,},
        { id: 'tab-default-7__item', label:  this.labels.Stage_OnHold   , order: 6 ,},
        { id: 'tab-default-2__item', label:  this.labels.Stage_Draft   , order: 7 ,},
    ];
    @track selectedOption = this.options[0].label;

    renderedCallback() {
        let styleDropdownBtn = window.getComputedStyle(this.refs.dropdownBtn);
        if(this.refs.dropdownList?.style){
            this.refs.dropdownList.style.width = styleDropdownBtn.width;
        }
    }
    connectedCallback() {
        this.optionsToDisplay = this.options.filter((option) => option.label !== this.selectedOption);
        console.log(this.optionsToDisplay)
        // this.options = this.options.filter((option) => option.label !== this.selectedOption);
    }


    toggleSubtabs(event) {
        this.switchTabName(event.target.dataset.id)                   
    }

    toggleDropdown() {
        this.dropdownOpen = !this.dropdownOpen;
    }
    
    handleOptionClick(event) {
        const selectedOptionId = event.target.dataset.id;
        this.switchTabName(selectedOptionId)    
        const selectedOption = this.options.find((option) => option.id === selectedOptionId);
        // this.optionsToDisplay = this.deepCopy(this.options);
        if (selectedOption) {   
            this.selectedOption = selectedOption.label;
            this.optionsToDisplay = this.options.filter((option) => option.label !== selectedOption.label);
            this.optionsToDisplay.sort((a, b) => a.order - b.order);
            console.log()
        }
        this.dropdownOpen = false;
    }

    

    switchTabName(idAtrribute){
        this.template.querySelectorAll('.slds-tabs_default__item').forEach(function(data){
            //console.log( '123', data.dataset.id)
            if(data.querySelectorAll('a')[0].dataset.id == idAtrribute ){
                data.classList.add("slds-is-active")
            } else{
                data.classList.remove("slds-is-active");
            }
        })
        //console.log( 'idAtrribute' , idAtrribute);
        if(idAtrribute == 'tab-default-1__item'){//allReclamations
            this.allReclamations = true;
            this.isDraftReclamations = false;
            this.isRegisteredReclamations = false;
            this.isConsideredReclamations = false;
            this.isRejectedReclamations = false;
            this.isAcceptedReclamations = false;
            this.isOnHoldReclamations = false;
            
            this.searchBy();
        }
        if(idAtrribute == 'tab-default-2__item'){//isDraftReclamations
            this.allReclamations = false;
            this.isDraftReclamations = true;
            this.isRegisteredReclamations = false;
            this.isConsideredReclamations = false;
            this.isRejectedReclamations = false;
            this.isAcceptedReclamations = false;
            this.isOnHoldReclamations = false;
            
            this.searchBy();
        }
        if(idAtrribute == 'tab-default-3__item'){//isRegisteredReclamations

            this.allReclamations = false;
            this.isDraftReclamations = false;
            this.isRegisteredReclamations = true;
            this.isConsideredReclamations = false;
            this.isRejectedReclamations = false;
            this.isAcceptedReclamations = false;
            this.isOnHoldReclamations = false;

            this.searchBy();
        }
        if(idAtrribute == 'tab-default-4__item'){//isConsideredReclamations

            this.allReclamations = false;
            this.isDraftReclamations = false;
            this.isRegisteredReclamations = false;
            this.isConsideredReclamations = true;
            this.isRejectedReclamations = false;
            this.isAcceptedReclamations = false;
            this.isOnHoldReclamations = false;

            this.searchBy();
        }
        if(idAtrribute == 'tab-default-5__item'){//isRejectedReclamations

            this.allReclamations = false;
            this.isDraftReclamations = false;
            this.isRegisteredReclamations = false;
            this.isConsideredReclamations = false;
            this.isRejectedReclamations = true;
            this.isAcceptedReclamations = false;
            this.isOnHoldReclamations = false;

            this.searchBy();
        }
        if(idAtrribute == 'tab-default-6__item'){//isAcceptedReclamations

            this.allReclamations = false;
            this.isDraftReclamations = false;
            this.isRegisteredReclamations = false;
            this.isConsideredReclamations = false;
            this.isRejectedReclamations = false;
            this.isAcceptedReclamations = true;
            this.isOnHoldReclamations = false;

            this.searchBy();
        }
        if(idAtrribute == 'tab-default-7__item'){//isAcceptedReclamations

            this.allReclamations = false;
            this.isDraftReclamations = false;
            this.isRegisteredReclamations = false;
            this.isConsideredReclamations = false;
            this.isRejectedReclamations = false;
            this.isAcceptedReclamations = false;
            this.isOnHoldReclamations = true;

            this.searchBy();
        }
    }

    filterByDate(){
        if(!this.dateSortToggled ){
            this.dateSortToggled = !this.dateSortToggled;
            this.stageSortToggled = false;
            this.numberSortToggled = false;
            this.template.querySelector('[data-id="dateSortIcon"]').classList.add('sort-icon-rotate');
            this.template.querySelector('[data-id="stageSortIcon"]').classList.remove('sort-icon-rotate')
            this.template.querySelector('[data-id="numberSortIcon"]').classList.remove('sort-icon-rotate')
        }else{
            this.dateSortToggled = !this.dateSortToggled;
            this.template.querySelector('[data-id="dateSortIcon"]').classList.remove('sort-icon-rotate')
            this.template.querySelector('[data-id="stageSortIcon"]').classList.remove('sort-icon-rotate')
            this.template.querySelector('[data-id="numberSortIcon"]').classList.remove('sort-icon-rotate')
        }
        //console.log( this.filteredReclamationsList);
        //console.log( this.sortBydateAsc);
        try {
            var self = this;
            this.filteredReclamationsList.sort(function(a, b) {
                if(self.sortBydateAsc){
                    return new Date(a.CreatedDate)-new Date(b.CreatedDate);
                } else {
                    return new Date(b.CreatedDate)-new Date(a.CreatedDate);
                }
                
            });
            this.sortBydateAsc = !this.sortBydateAsc;
        } catch (error) {
            console.log(error)
        }
        
        //console.log( this.filteredReclamationsList);
    }
    sortByStageAsc = true;
    filterByStage(){
        if(!this.stageSortToggled ){
            this.stageSortToggled = !this.stageSortToggled;
            this.dateSortToggled = false;
            this.numberSortToggled = false;
            this.template.querySelector('[data-id="stageSortIcon"]').classList.add('sort-icon-rotate');
            this.template.querySelector('[data-id="dateSortIcon"]').classList.remove('sort-icon-rotate')
            this.template.querySelector('[data-id="numberSortIcon"]').classList.remove('sort-icon-rotate')
        }else{
            this.stageSortToggled = !this.stageSortToggled;
            this.template.querySelector('[data-id="stageSortIcon"]').classList.remove('sort-icon-rotate')
            this.template.querySelector('[data-id="dateSortIcon"]').classList.remove('sort-icon-rotate')
            this.template.querySelector('[data-id="numberSortIcon"]').classList.remove('sort-icon-rotate')
        }       
        try {
            var self = this;
            this.filteredReclamationsList.sort(function(a, b) {
                if(self.sortByStageAsc){
                    return  new String(a.Status__c).localeCompare(new String(b.Status__c));
                } else {
                    return new String(b.Status__c).localeCompare(new String(a.Status__c));
                }
                
            });
            this.sortByStageAsc = !this.sortByStageAsc;
        } catch (error) {
            console.log(error)
        }
    }
    sortByNumberAsc = true
    filterByNumber(){
        if(!this.numberSortToggled ){
            this.numberSortToggled = !this.numberSortToggled;
            this.dateSortToggled = false;
            this.stageSortToggled = false;
            this.template.querySelector('[data-id="numberSortIcon"]').classList.add('sort-icon-rotate');
            this.template.querySelector('[data-id="dateSortIcon"]').classList.remove('sort-icon-rotate')
            this.template.querySelector('[data-id="stageSortIcon"]').classList.remove('sort-icon-rotate')
        }else{
            this.numberSortToggled = !this.numberSortToggled;
            this.template.querySelector('[data-id="numberSortIcon"]').classList.remove('sort-icon-rotate')
            this.template.querySelector('[data-id="dateSortIcon"]').classList.remove('sort-icon-rotate')
            this.template.querySelector('[data-id="stageSortIcon"]').classList.remove('sort-icon-rotate')
        }       
        try {
            var self = this;
            this.filteredReclamationsList.sort(function(a, b) {
                if(self.sortByNumberAsc){
                    return  new String(a.Name).localeCompare(new String(b.Name));
                } else {
                    return new String(b.Name).localeCompare(new String(a.Name));
                }
                
            });
            this.sortByNumberAsc = !this.sortByNumberAsc;
        } catch (error) {
            console.log(error)
        }
    }

    //Modal setup
    @api
    modalContainer;

    openModal(event) {
        //console.log( event.target.dataset.id);
        this.isModalOpen = true;       
        this.selectedReclamationid = event.target.dataset.id
        setTimeout(() => {
            this.modalContainer = this.template.querySelector('.slds-modal__container');
            //console.log( this.modalContainer);
        }, 2000)
    }

    closeModal() {
        this.isModalOpen = false;
        this.isUserModalActive = false;
    }

    

    handleAddProduct(){
        const addProductEvent = new CustomEvent('addedproduct', { detail: this.selectedReclamationid });
        this.dispatchEvent(addProductEvent);
    }

    @api LWCreloadProducts(){
        //console.log( 'reload items');
        this.template.querySelector('c-site-reclamation-detail').LWCreloadProducts();
        /*
        getReclamationDetail({ReclamationId:this.getSelectedReclamation}).then(response=>{
            console.log(response);  
            this.reclamationItemsList = response.Reclamation_Details__r;  
            this.reclamation = response; 
            this.noRefund = response.No_Refund__c;        
        })
        */
    }
}