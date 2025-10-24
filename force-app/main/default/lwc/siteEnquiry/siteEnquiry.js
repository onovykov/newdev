import { LightningElement, track, wire,api} from 'lwc';
import IMAGES from "@salesforce/resourceUrl/SiteImages";
import getEnquiries from '@salesforce/apex/EnquiryDatatableController.getEnquiries';
import generatePdf from '@salesforce/apex/EnquiryDatatableController.generatePdf';
import {NavigationMixin} from 'lightning/navigation';

//Labels
import PRINT from '@salesforce/label/c.Print';
import CHOOSEADATE from '@salesforce/label/c.Choose_a_date';
import FROM from '@salesforce/label/c.From';
import TO from '@salesforce/label/c.To';
import contact_sys_admin from '@salesforce/label/c.contact_sys_admin';


export default class SiteEnquiry extends NavigationMixin(LightningElement) {

    @track data;
    @track filteredEnquiriesList;
    @track enquiriesList;
    @track enquiriesResult;
    @track selectedEnquiryId;

    sortIcon = IMAGES + '/filterIcon.png';
    printImg = IMAGES + '/print.png';
    refresh = IMAGES + '/refresh.png';

    dateSortToggled = false;
    stageSortToggled = false;
    numberSortToggled = false;

    sortByDateAsc = true;
    sortBydStageAsc = true;
    sortByNumberAsc = true;

    amountAllEnquiries
    amountProcessingEnquiries
    amountCancelledEnquiries
    amountClosedEnquiries
    amountDraftEnquiries


    //Tabs
    isAllEnquiries
    isProcessingEnquiries
    isCancelledEnquiries
    isClosedEnquiries
    isDraftEnquiries


    isModalOpen
    @track selectedEnquiryId

    showGenPdfSpinner = false;


    labels ={
        PRINT,
        CHOOSEADATE,
        FROM,
        TO,
        contact_sys_admin
    }

    @wire(getEnquiries,{}) handleEnquiries(result){
        console.log(result)
        this.enquiriesResult = result;
        const {error, data } = result;
        if(data){
            let dataCopy = data.map(item=>{
                return Object.assign({},item);
            })
            
            dataCopy.forEach(item =>{
                if(item.OpportunityId__r.StageName == 'Qualification'){
                    item.Status__c = 'Draft';
                }
                if(item.OpportunityId__r.StageName == 'Preparation' || item.OpportunityId__r.StageName == 'Analysis' ||
                   item.OpportunityId__r.StageName == 'Proposal' || item.OpportunityId__r.StageName == 'Negotiation'){
                    
                    item.Status__c = 'Processing';
                }
                if(item.OpportunityId__r.StageName == 'Cancelled'){
                    item.Status__c = 'Cancelled';
                }
                if(item.OpportunityId__r.StageName == 'Closed Won' || item.OpportunityId__r.StageName == 'Closed Lost'){
                    item.Status__c = 'Closed';
                }
            })

            this.enquiriesList = dataCopy;
            this.filteredEnquiriesList = dataCopy;
            let all = this.filteredEnquiriesList.filter((item=>{
                return item;
            }))
            let draft = this.filteredEnquiriesList.filter((item=>{
                return item.Status__c == 'Draft';
            }))
            let closed = this.filteredEnquiriesList.filter((item=>{
                return item.Status__c == 'Closed';
            }))
            let processing = this.filteredEnquiriesList.filter((item=>{
                return item.Status__c == 'Processing';
            }))
            let cancelled = this.filteredEnquiriesList.filter((item=>{
                return item.Status__c == 'Cancelled';
            }))
            this.amountAllEnquiries = all.length;
            this.amountDraftEnquiries = draft.length;
            this.amountClosedEnquiries = closed.length;
            this.amountProcessingEnquiries = processing.length;
            this.amountCancelledEnquiries = cancelled.length;
        }
        if(error){
            console.error(error);
        }

    }


    //Custom Search And Filters


    handleSearch(event) {
        this.searchKey = event.target.value.toLowerCase();
        this.searchBy();
    }

    refreshSearch(){
        //console.log( '11111', JSON.stringify(this.filteredEnquiriesList));
        //console.log( '22222', JSON.stringify(this.enquiriesList));
        this.filteredEnquiriesList = this.enquiriesList;
        this.startDate = null;
        this.endDate = null
        this.searchKey = null;
        [...this.template
            .querySelectorAll('lightning-input, lightning-textarea')]
            .forEach((input) => { input.value = ''; });

        this.switchTabName('tab-default-3__item');
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
        
        this.filteredEnquiriesList = this.enquiriesList;
        //console.log( this.filteredEnquiriesList);
        if (this.searchKey) {
            if (this.filteredEnquiriesList) {
                let searchRecords = [];
                for (let record of this.filteredEnquiriesList) {
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
 
                //console.log( 'Matched Orders are ' + JSON.stringify(searchRecords));
                this.filteredEnquiriesList = searchRecords;
            }
        } else {
            this.filteredEnquiriesList = this.enquiriesList;
        }

        if(this.startDate){
            this.filteredEnquiriesList = this.filteredEnquiriesList.filter(enquiry=>{
                return enquiry.CreatedDate >= this.startDate;
            })
        }

        if(this.endDate){
            this.filteredEnquiriesList = this.filteredEnquiriesList.filter(enquiry=>{
                return enquiry.CreatedDate <= this.endDate;
            })
        }

        if(this.isAllEnquiries){
            this.filteredEnquiriesList = this.filteredEnquiriesList.filter(enquiry=>{
                return enquiry;
            })
        }
        if(this.isDraftEnquiries){
            this.filteredEnquiriesList = this.filteredEnquiriesList.filter(enquiry=>{
                return enquiry.Status__c == 'Draft';
            })
        }
        if(this.isClosedEnquiries){
            this.filteredEnquiriesList = this.filteredEnquiriesList.filter(enquiry=>{
                return enquiry.Status__c == 'Closed';
            })
        }
        if(this.isCancelledEnquiries){
            this.filteredEnquiriesList = this.filteredEnquiriesList.filter(enquiry=>{
                return enquiry.Status__c == 'Cancelled';
            })
        }
        if(this.isProcessingEnquiries){
            this.filteredEnquiriesList = this.filteredEnquiriesList.filter(enquiry=>{
                return enquiry.Status__c == 'Processing';
            })
        }
       
    }

    toggleSubtabs(event) {
        this.switchTabName(event.target.dataset.id)                   
    }

    switchTabName(idAtrribute){
        this.template.querySelectorAll('.slds-tabs_default__item').forEach(function(data){
            //console.log( '123', data.dataset.id)
            //console.log( '!!!!!!', idAtrribute)
            if(data.querySelectorAll('a')[0].dataset.id == idAtrribute ){
                data.classList.add("slds-is-active")
            } else{
                data.classList.remove("slds-is-active");
            }
        })
        
        //console.log( idAtrribute);
        if(idAtrribute == 'tab-default-1__item'){
            this.allEnquiries = false
            this.isClosedEnquiries = false;
            this.isAllEnquiries = false;
            this.isCancelledEnquiries = false;
            this.isProcessingEnquiries = true;
            this.searchBy();
        }
        if(idAtrribute == 'tab-default-2__item'){
            this.isClosedEnquiries = true
            this.isDraftEnquiries = false;
            this.isAllEnquiries = false;
            this.isCancelledEnquiries = false;
            this.isProcessingEnquiries = false;
            this.searchBy();
        }
        if(idAtrribute == 'tab-default-3__item'){
            this.isAllEnquiries = true
            this.isDraftEnquiries = false;
            this.isClosedEnquiries = false;
            this.isCancelledEnquiries = false;
            this.isProcessingEnquiries = false;
            this.searchBy();
        }
        if(idAtrribute == 'tab-default-4__item'){
            this.isCancelledEnquiries = false;
            this.isAllEnquiries = false;
            this.isDraftEnquiries = true;
            this.isClosedEnquiries = false;
            this.isProcessingEnquiries = false;
            this.searchBy();
        }
        if(idAtrribute == 'tab-default-5__item'){
            this.isProcessingEnquiries = false
            this.isAllEnquiries = false;
            this.isDraftEnquiries = false;
            this.isClosedEnquiries = false;
            this.isCancelledEnquiries = true;
            this.searchBy();
        }
        
    }

    //sort icons 

    filterByDate(){
        //var sortIcon = this.template.querySelector('[data-id="dateSortIcon"]');
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
        try {
            var self = this;
            let arrayForSort = [...this.filteredEnquiriesList];
            arrayForSort.sort(function(a, b) {
                if(self.sortByDateAsc){
                    return new Date(a.CreatedDate)-new Date(b.CreatedDate);
                } else {
                    return new Date(b.CreatedDate)-new Date(a.CreatedDate);
                }
                
            });
            this.filteredEnquiriesList = arrayForSort;
            this.sortByDateAsc = !this.sortByDateAsc;
        } catch (error) {
            console.log(error);
        }
        
        //console.log( this.filteredEnquiriesList);
    }

    filterByStage(){
        //var sortIcon = this.template.querySelector('[data-id="stageSortIcon"]');
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
            let arrayForSort = [...this.filteredEnquiriesList];
            arrayForSort.sort(function(a, b) {
                if(self.sortByStageAsc){
                    return  new String(a.Status__c).localeCompare(new String(b.Status__c));
                } else {
                    return new String(b.Status__c).localeCompare(new String(a.Status__c));
                }
                
            });
            this.filteredEnquiriesList = arrayForSort;
            this.sortByStageAsc = !this.sortByStageAsc;
        } catch (error) {
            console.log(error);
        }
        
        //console.log( this.filteredEnquiriesList);
    }
    filterByNumber(){
        //var sortIcon = this.template.querySelector('[data-id="numberSortIcon"]');
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
            let arrayForSort = [...this.filteredEnquiriesList];
            arrayForSort.sort(function(a, b) {
                if(self.sortByNumberAsc){
                    return  new String(a.Name).localeCompare(new String(b.Name));
                } else {
                    return new String(b.Name).localeCompare(new String(a.Name));
                }
            });
            this.filteredEnquiriesList = arrayForSort;
            //console.log( '123123',this.filteredEnquiriesList);
            this.sortByNumberAsc = !this.sortByNumberAsc;
        } catch (error) {
            console.log(error);
        }
        
        //console.log( this.filteredEnquiriesList);
    }


    generatePdf() {
        this.showGenPdfSpinner = true;
        let enquiries = this.filteredEnquiriesList.map(enquiry => {
            return enquiry.Id;
        })
        //console.log( 'selected orders ', JSON.stringify(orders));
        generatePdf({selectedEnquiries: JSON.stringify(enquiries)}).then(result => {
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
            console.error(error);
            this.template.querySelector('c-custom-toast-lwc').showToast('error', this.labels.contact_sys_admin)
            this.showGenPdfSpinner = false;
        })
    }




    @api modalContainer;
    openModal(event) {
        console.log( event.target.dataset.id);
        this.isModalOpen = true;       
        this.selectedEnquiryId = event.target.dataset.id
        setTimeout(() => {
            this.modalContainer = this.template.querySelector('.slds-modal__container');
            //console.log( this.modalContainer);
        }, 2000)
    }

    closeModal(){
        this.isModalOpen = false;
    }


}