import { LightningElement,api,track } from 'lwc';
import getCaseFiles from '@salesforce/apex/SupportDatatableController.getCaseFiles';
import getCase from '@salesforce/apex/SupportDatatableController.getCase';
import viewFile from '@salesforce/apex/ReclamationDatatableController.viewFile';
import {NavigationMixin} from 'lightning/navigation';

import card_details from '@salesforce/label/c.card_details';
import card_files from '@salesforce/label/c.card_files';

import scf_name from '@salesforce/label/c.scf_name';
import scf_owner from '@salesforce/label/c.scf_owner';
import scf_lastChange from '@salesforce/label/c.scf_lastChange';
import scf_size from '@salesforce/label/c.scf_size';

import subject from '@salesforce/label/c.subject';
import Creation_date from '@salesforce/label/c.Creation_date';
import Status from '@salesforce/label/c.Status';
import Status_date from '@salesforce/label/c.Status_date';
import Support_description from '@salesforce/label/c.Support_description';

export default class SiteSupportDetail extends NavigationMixin(LightningElement)  {
    @api getSelectedCase;
    @track caseFiles;
    @track currentCase;
    @track dataLoaded=false;

    labels = {
        scf_name,
        scf_owner,
        scf_lastChange,
        scf_size,

        card_details,
        card_files,
        
        subject,
        Creation_date,
        Status,
        Status_date,
        Support_description
    }

    @track dropdownOpen = false;
    @track optionsToDisplay;
    @track selectedValue = this.labels.card_details;
    @track options = [
        {id: 'tab-defaultItem-1', label: this.labels.card_details, order: 1},
        {id: 'tab-defaultItem-2', label: this.labels.card_files, order: 2},
    ];
    @track selectedOption = this.options[0].label;

    connectedCallback() {        
        this.optionsToDisplay = this.options.filter((option) => option.label !== this.selectedOption);
        console.log('this.optionsToDisplay', this.options)

        getCaseFiles({caseId:this.getSelectedCase}).then(result=>{         
            if(result){
                console.log(result);
                let dataCopy = result.map(item=>{
                    return Object.assign({},item);
                })
                dataCopy.forEach(element => {
                    element.fileSize = this.formatBytes(element.ContentDocument.ContentSize, 2);
                });
                this.caseFiles = dataCopy;
            }           
        });

        getCase({caseId:this.getSelectedCase}).then(result=>{         
            if(result){
                console.log('--------------------------cases'); 
                console.log(result);                
                result.CreatedDate = new Date(result.CreatedDate).toLocaleDateString();
                this.currentCase = result;
                this.dataLoaded = true;
            }           
        });

    }

    formatBytes(bytes, decimals = 2) {
        if (!+bytes) return '0 Bytes'
        const k = 1024
        const dm = decimals < 0 ? 0 : decimals
        const sizes = ['Bytes', 'KB', 'MB', 'GB']
        const i = Math.floor(Math.log(bytes) / Math.log(k))
        return `${parseFloat((bytes / Math.pow(k, i)).toFixed(dm))} ${sizes[i]}`
    }

   
    openFile(event) {
        
        console.log(event.target.dataset.id);
        this.cdl = event.target.dataset.id;
        viewFile({cdl: this.cdl }).then(result => {
            console.log('file url  result ', result);
            
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: result
                }
            });
        
    })
    }

    toggleSubtabs(event) {
        console.log(event.target.id);
        this.switchTabName(event.target.id)                   
    }
    toggleDropdown() {
        this.dropdownOpen = !this.dropdownOpen;
    }

    handleOptionClick(event) {
        const selectedOptionId = event.target.dataset.id;
        console.log('selectedOptionId ', selectedOptionId)
        this.switchTabName(selectedOptionId)
        const selectedOption = this.options.find((option) => option.id === selectedOptionId);
        if (selectedOption) {
            this.selectedOption = selectedOption.label;
            this.optionsToDisplay = this.options.filter((option) => option.label !== selectedOption.label);
            this.optionsToDisplay.sort((a, b) => a.order - b.order);
            console.log()
        }
        this.dropdownOpen = false;
    }


    switchTabName(idAtrribute){
        console.log('in function')
        this.template.querySelectorAll('.slds-tabs_default__item').forEach(function(data){
            if(data.querySelectorAll('a')[0].dataset.id ==idAtrribute ){
                data.classList.add("slds-is-active")
            } else{
                data.classList.remove("slds-is-active");
            }
        })

        let idAttributeContent = idAtrribute;
        console.log(idAttributeContent);
        this.template.querySelectorAll('.slds-tabs_default__content').forEach(function(data){  
            
            let currentId = data.dataset.id
            console.log(currentId) ;
            console.log(currentId == idAttributeContent) ;
            if(idAttributeContent == currentId){
                data.classList.add("slds-show");
                data.classList.remove("slds-hide");
            } else {
                try {
                    data.classList.remove("slds-show");
                    data.classList.add("slds-hide");
                } catch (error) {
                    console.log(error)
                }
                
            }
        })
    }
}