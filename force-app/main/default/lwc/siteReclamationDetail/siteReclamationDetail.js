import { LightningElement,wire,track,api   } from 'lwc';
import getReclamationDetail from '@salesforce/apex/ReclamationItemDatatableController.getReclamationDetail';
import getAccountInfo from '@salesforce/apex/UserUtils.getAccountInfo';
import IMAGES from "@salesforce/resourceUrl/SiteImages";
import confirmReclamationIt from '@salesforce/apex/ReclamationItemDatatableController.confirmReclamationIt';
import deleteReclamationSf from '@salesforce/apex/ReclamationItemDatatableController.deleteReclamation';
import deleteReclamationItem from '@salesforce/apex/ReclamationItemDatatableController.deleteReclamationItem';
import uploadFileReclamation from '@salesforce/apex/FileUploaderTest.uploadFileReclamation';
import deleteRelatedFile from '@salesforce/apex/FileUploaderTest.deleteRelatedFile';
import editReclamationItem from '@salesforce/apex/ReclamationItemDatatableController.editReclamationItem';

import getDependentMap from '@salesforce/apex/CreateReclamationController.getDependentMap';
import reclamationDetail from '@salesforce/schema/Reclamation_Detail__c';

import getReclamationFiles from '@salesforce/apex/ReclamationDatatableController.getReclamationFiles';
import viewFile from '@salesforce/apex/ReclamationDatatableController.viewFile';
import {NavigationMixin} from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';

import site_th_Product from '@salesforce/label/c.Site_th_Product';
import site_th_orderQuantity from '@salesforce/label/c.site_th_orderQuantity';
import site_th_reclamationQuantity from '@salesforce/label/c.site_th_reclamationQuantity';
import site_th_descriptionClaim from '@salesforce/label/c.site_th_descriptionClaim';
import Site_th_currency from '@salesforce/label/c.Site_th_currency';
import site_th_type from '@salesforce/label/c.site_th_type';
import site_th_subtype from '@salesforce/label/c.site_th_subtype';
import site_th_MeasurementUnit from '@salesforce/label/c.Site_th_MeasurementUnit';
import site_th_delete from '@salesforce/label/c.Site_th_delete';
import site_th_edit from '@salesforce/label/c.Site_th_Edit';

import reclamationNumber from '@salesforce/label/c.reclamationNumber';
import dateOfCreation from '@salesforce/label/c.dateOfCreation';
import scd_account from '@salesforce/label/c.scd_account';
import scd_erpNumber from '@salesforce/label/c.scd_erpNumber';
import scd_contractNumber from '@salesforce/label/c.scd_contractNumber';
import scd_contractDate from '@salesforce/label/c.scd_contractDate';
import scd_currency from '@salesforce/label/c.scd_currency';
import scd_stage from '@salesforce/label/c.scd_stage';
import scd_noRefund from '@salesforce/label/c.scd_noRefund';
import scd_Comment from '@salesforce/label/c.scd_Comment';

import scf_name from '@salesforce/label/c.scf_name';
import scf_owner from '@salesforce/label/c.scf_owner';
import scf_lastChange from '@salesforce/label/c.scf_lastChange';
import scf_size from '@salesforce/label/c.scf_size';

import card_related from '@salesforce/label/c.card_related';
import card_details from '@salesforce/label/c.card_details';
import card_files from '@salesforce/label/c.card_files';

import site_reclamation from '@salesforce/label/c.site_reclamation';
import site_DeleteReclamation from '@salesforce/label/c.Site_DeleteReclamation';
import site_ConfirmReclamation from '@salesforce/label/c.Site_ConfirmReclamation';
import site_request from '@salesforce/label/c.site_request';
import site_t from '@salesforce/label/c.Site_orderDetail_t';
import Upload_file from '@salesforce/label/c.Upload_file';


import confirm_claim_answer from '@salesforce/label/c.confirm_claim_answer';
import delete_claim_answer from '@salesforce/label/c.delete_claim_answer';
import Yes from '@salesforce/label/c.Yes';
import No from '@salesforce/label/c.No';
import can_not_edit_reclamation from '@salesforce/label/c.can_not_edit_reclamation';
import delete_item_answer from '@salesforce/label/c.delete_item_answer';
import contact_sys_admin from '@salesforce/label/c.contact_sys_admin';
import Reclamation_confirmed from '@salesforce/label/c.Reclamation_confirmed';
import Reclamation_deleted from '@salesforce/label/c.Reclamation_deleted';




import site_btn_AddProduct from '@salesforce/label/c.Site_btn_AddProduct';
import SVG_PIPES from '@salesforce/resourceUrl/pipeIcons';

// currency additions
import { publish, subscribe, MessageContext, APPLICATION_SCOPE } from 'lightning/messageService';
//import addReclamationProduct from '@salesforce/messageChannel/addReclamationProduct';
import addReclamationProduct from '@salesforce/messageChannel/addReclamationProduct__c';
// end


export default class SiteReclamationDetail extends NavigationMixin(LightningElement) {

    @api getSelectedReclamation;
    
    @track reclamationItemsList;
    @track reclamation;
    @track noRefund;
    UA = IMAGES + '/ukraine-twitter.png';

    @track mistmatchType = [];
    @track mistmatchSubType;
    @track mapDependetValue;
    @track firstDependentValueArr = [];

    @track data;
    @track reclamationFiles;
    
    cdl;
    @track modalReclamation = false;
    @track spinner = false;
    @track idItemToDelete;
    @track idFileToDelete;

    @track confirmBoolean = false;
    @track deleteReclamationBoolean = false;
    @track deleteItemBoolean = false;
    @track deleteFileBoolean = false;
    @track modalText;
    @track uploadedFiles = [];

    labels = {
        site_th_Product,
        site_th_orderQuantity,
        site_th_reclamationQuantity,
        site_th_descriptionClaim,
        Site_th_currency,
        site_th_type,
        site_th_subtype,
        site_th_MeasurementUnit,
        site_th_delete,
        site_th_edit,
        

        reclamationNumber,
        dateOfCreation,
        scd_account,
        scd_erpNumber,
        scd_contractNumber,
        scd_contractDate,
        scd_currency,
        scd_stage,
        scd_noRefund,
        scd_Comment,

        scf_name,
        scf_owner,
        scf_lastChange,
        scf_size,

        card_related,
        card_details,
        card_files,

        site_request,
        site_reclamation,

        site_btn_AddProduct,

        site_t,
        Upload_file,

        site_DeleteReclamation,
        site_ConfirmReclamation,

        confirm_claim_answer,
        delete_claim_answer,
        Yes,
        No,
        can_not_edit_reclamation,
        delete_item_answer,
        contact_sys_admin,
        Reclamation_confirmed,
        Reclamation_deleted
        
     
    }
    attach = `${SVG_PIPES}#attach`;
    @track dropdownOpen = false;
    @track optionsToDisplay;
    @track accData = {};
    @track options = [
        { id: 'tab-defaultItem-1', label:  this.labels.card_related, order: 1},
        { id: 'tab-defaultItem-2', label:  this.labels.card_details, order: 2 },
        { id: 'tab-defaultItem-3', label:  this.labels.card_files, order: 3 },

    ];
    @track selectedOption = this.options[0].label;

    connectedCallback() {
        // console.log('connectedcallback');
        // console.log(this.getSelectedReclamation);
        this.optionsToDisplay = this.options.filter((option) => option.label !== this.selectedOption);
        getAccountInfo({}).then(response=>{
            let accValues = {
                id : response.id,
                Name : response.Name
            }
            this.accData = accValues;
        })
        getReclamationDetail({ReclamationId:this.getSelectedReclamation}).then(response=>{
            // console.log('reclamationItemsList---> ' ,response.Reclamation_Details__r)
            // console.log('reclamationItemsList---> ' ,response.Reclamation_Details__r[0].OrderItemID__r)        
            if(response.Status__c == 'Director decision') {
                response.Status__c = 'Being considered';
              }
              if(response.Status__c == 'Is being considered') {
                response.Status__c = 'Being considered';
              }
              if(response.Status__c == 'Rejected') {
                response.Status__c = 'Declined';
              }
              if(response.Account__c == '' || response.Account__c == '') {
                response.Account__c = this.accData.id;
              }
            this.reclamationItemsList = response.Reclamation_Details__r;  
            this.reclamation = response; 
            this.noRefund = response.No_Refund__c;
             
        })

        getReclamationFiles({reclamationId:this.getSelectedReclamation}).then(result=>{
            
            if(result){
                // console.log(result);
                let dataCopy = result.map(item=>{
                    return Object.assign({},item);
                })
                dataCopy.forEach(element => {
                    element.fileSize = this.formatBytes(element.ContentDocument.ContentSize, 2);
                });
                this.reclamationFiles = dataCopy;
            }
            
        });

        const record = {
            sobjectType: "Reclamation_Detail__c",
            Name: "Demo",
          };

        getDependentMap({objDetail:record,contrfieldApiName:'Mistmatch_Type__c',depfieldApiName:'Mistmatch_SubType__c'}).then(response=>{           
            // console.log('getDependentMap');                
            // console.log(response);  
            this.mapDependetValue = response; 
            this.firstDependentValueArr = response[0];
            for (var singlekey in response) {
                this.mistmatchType.push(singlekey);
            }  
            this.firstDependentValueArr = response[this.mistmatchType[0]];
            // console.log(this.firstDependentValueArr);    
            // console.log(this.mistmatchType);       
        }).catch((error) => {
            // console.log('getDependentMap');
            console.log(error);       
        });

        this.subscribeToMessageChannel();
    }

    toggleSubtabs(event) {
        // console.log(event.target.dataset.id);
        this.switchTabName(event.target.dataset.id)                   
    }
    renderedCallback(){
        let styleDropdownBtn = window.getComputedStyle(this.refs.dropdownBtn);
        if(this.refs.dropdownList?.style){
            this.refs.dropdownList.style.width = styleDropdownBtn.width;
        }
    }
    toggleDropdown() {

        this.dropdownOpen = !this.dropdownOpen;
    }
    handleOptionClick(event) {
        const selectedOptionId = event.target.dataset.id;
        console.log('selectedOptionId ',selectedOptionId)
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
        // console.log('idAtrribute',idAtrribute)
        this.template.querySelectorAll('.slds-tabs_default__item').forEach(function(data){
            if(data.querySelectorAll('a')[0].dataset.id ==idAtrribute ){
                data.classList.add("slds-is-active")
            } else{
                data.classList.remove("slds-is-active");
            }
        })
        this.template.querySelectorAll('.slds-tabs_default__content').forEach(function(data){  
            let currentId = data.dataset.id;
            // console.log('currentId',currentId , 'idAtrribute ', idAtrribute ) ;

            // console.log(currentId == idAtrribute) ;
            if(idAtrribute == currentId){
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

    get ownerFullName(){
        return this.reclamation.Owner.FirstName + ' '+ this.reclamation.Owner.LastName;
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
        
        // console.log(event.target.dataset.id);
        this.cdl = event.target.dataset.id;
        viewFile({cdl: this.cdl }).then(result => {
            // console.log('file url  result ', result);
            
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: result
                }
            });
        
    })
    }

    confirmReclamation(){
        if(this.reclamation.Status__c == 'Draft'){
            this.spinner = true;
            confirmReclamationIt({reclamationId:this.getSelectedReclamation}).then(result=>{          
                if(result){
                    this.spinner = false;
                    // console.log(result);  
                    this.template.querySelector('c-custom-toast-lwc').showToast('success', this.labels.Reclamation_confirmed);    
                    location.reload(); 
                    this.closeModal();
                    this.cleanModalBoolean();             
                }
                this.spinner = false;        
            }).catch(error=>{
                this.spinner = false
                console.log(error);
                this.template.querySelector('c-custom-toast-lwc').showToast('warning', this.labels.contact_sys_admin);
                this.closeModal();
                this.cleanModalBoolean();
            })
        } else {
            this.template.querySelector('c-custom-toast-lwc').showToast('warning', 'Sorry, this reclamation already confirmed');
        }    
    }

    deleteReclamation(){
        // console.log(this.getSelectedReclamation)
        // console.log('delete:');
        if(this.reclamation.Status__c == 'Draft'){
            deleteReclamationSf({ReclamationId:this.getSelectedReclamation}).then(result=>{                    
                this.template.querySelector('c-custom-toast-lwc').showToast('success', this.labels.Reclamation_deleted);    
                location.reload();         
                this.closeModal();
                this.cleanModalBoolean();           
            }).catch(error=>{
                console.log(error);
                this.template.querySelector('c-custom-toast-lwc').showToast('warning', this.labels.contact_sys_admin);
                this.closeModal();
                this.cleanModalBoolean();
            })
        } else {
            this.template.querySelector('c-custom-toast-lwc').showToast('warning', 'Sorry, you can not delete confirmed reclamation.');
        }
        
    }

    @wire(MessageContext)
    messageContext;
    
    subscribeToMessageChannel() {
        this.subscription = subscribe(
            this.messageContext,
            addReclamationProduct,
            (message) => this.handleMessage(message),
            { scope: APPLICATION_SCOPE }
        );
    }

    handleMessage(message) {

    }

    addProduct(){
        
        if(this.reclamation.Status__c == 'Draft'){
            try{
                const payload = {
                    reclamationId: this.getSelectedReclamation
                };
                // console.log('contactTemplate publish ' );
                publish(this.messageContext, addReclamationProduct, payload);
            } catch (e) {
                console.log(e);
            }
        } else {
            this.template.querySelector('c-custom-toast-lwc').showToast('warning', this.labels.can_not_edit_reclamation);
        }
            
        
    }

    

    openDeleteItemModal(event){
        if(this.reclamation.Status__c == 'Draft'){
            try{
                this.idItemToDelete = event.target.dataset.id;
                this.modalText = this.labels.delete_item_answer;
                this.deleteItemBoolean = true;
                this.modalReclamation = true;
            } catch (e) {
                console.log(e);
            }
        } else {
            this.template.querySelector('c-custom-toast-lwc').showToast('warning', this.labels.can_not_edit_reclamation);
        }     
    }

    deleteItem(){
        // console.log('this.idItemToDelete2');
        // console.log(this.idItemToDelete);
        this.spinner=true;
        deleteReclamationItem({idRecord:this.idItemToDelete}).then(result=>{       
                     
            this.template.querySelector('c-custom-toast-lwc').showToast('success', 'Reclamation item deleted');  
            let filteredArr = this.reclamationItemsList.filter( el => el.Id !==this.idItemToDelete ); 
            // console.log(filteredArr);
            this.reclamationItemsList = filteredArr; 
            this.spinner=false;    
            this.closeModal(); 
            this.cleanModalBoolean();
            //location.reload();                    
        }).catch(error=>{
            this.spinner=false;
            console.log(error);
            this.template.querySelector('c-custom-toast-lwc').showToast('warning', this.labels.contact_sys_admin);
            this.closeModal();
            this.cleanModalBoolean();
        })
    }

    openDeleteReclamationModal(){
        if(this.reclamation.Status__c == 'Draft'){
            try{
                this.modalText = this.labels.delete_claim_answer;
                this.deleteReclamationBoolean = true;
                this.modalReclamation = true;
            } catch (e) {
                console.log(e);
            }        
        } else {
            this.template.querySelector('c-custom-toast-lwc').showToast('warning', this.labels.can_not_edit_reclamation);
        }      
    }

    openConfirmReclamationModal(){       
        if(this.reclamation.Status__c == 'Draft'){
            try{
                this.modalText = this.labels.confirm_claim_answer;
                this.confirmBoolean = true;
                this.modalReclamation = true;
            } catch (e) {
                console.log(e);
            }       
        } else {
            this.template.querySelector('c-custom-toast-lwc').showToast('warning', this.labels.can_not_edit_reclamation);
        } 
    }

    closeModal(){
        this.modalReclamation = false;
    }

    confirmReclamationModal(){
        if(this.confirmBoolean){
            this.confirmReclamation();
        } else if (this.deleteReclamationBoolean){
            this.deleteReclamation();
        } else if(this.deleteItemBoolean){
            this.deleteItem();
        } else if(this.deleteFileBoolean){
            this.deleteFile();
        }
    }

    cleanModalBoolean(){
        this.confirmBoolean = false;
        this.deleteReclamationBoolean = false;
        this.deleteItemBoolean = false;
        this.deleteFileBoolean = false;
    }   
     
    openDeleteFileModal(event){
        if(this.reclamation.Status__c == 'Draft'){
            try{
                this.modalText = 'Are you sure to delete this file?';
                this.deleteFileBoolean = true;
                this.modalReclamation = true;
                this.idFileToDelete = event.target.dataset.id;
            } catch (e) {
                console.log(e);
            }       
        } else {
            this.template.querySelector('c-custom-toast-lwc').showToast('warning', this.labels.can_not_edit_reclamation);
        } 
        // console.log(event.target.dataset.id);
        
            
    }

    deleteFile(){
        deleteRelatedFile({docId:this.idFileToDelete}).then(response=>{
            // console.log(response);
            
            getReclamationFiles({reclamationId:this.getSelectedReclamation}).then(result=>{
            
                if(result){
                    // console.log(result);
                    let dataCopy = result.map(item=>{
                        return Object.assign({},item);
                    })
                    dataCopy.forEach(element => {
                        element.fileSize = this.formatBytes(element.ContentDocument.ContentSize, 2);
                    });
                    this.reclamationFiles = dataCopy;
                    this.closeModal(); 
                    this.cleanModalBoolean();
                }
                
            });
            }).catch(err=>{
                console.log(err)
                this.template.querySelector('c-custom-toast-lwc').showToast('warning', this.labels.contact_sys_admin);
            }).finally(() => {
                
            })
    }


    //file loader for reclamation
    handleFileSelect(event) {      
        // console.log(event.target.files)
        if(this.reclamation.Status__c == 'Draft'){
            if(event.target.files.length > 0) {
                try {      
                var base64changed =this.fileListToBase64(event.target.files);             
                let self = this;   
                base64changed.then(function(result) {                 
                    for(let i = 0;i<result.length;i++){
                        let file = {};                      
                        file.name = result[i].split(',')[0];
                        file.base64 = result[i].split(',')[1];               
                        self.uploadedFiles.push(file);               
                    }
                    // console.log(self.uploadedFiles);
                    uploadFileReclamation({ files:JSON.stringify(self.uploadedFiles), recordId:self.getSelectedReclamation}).then(result=>{                 
                        // console.log(result);
                        self.template.querySelector('c-custom-toast-lwc').showToast('success', 'Files uploaded');
                        getReclamationFiles({reclamationId:self.getSelectedReclamation}).then(result=>{
                
                            if(result){
                                console.log(result);
                                let dataCopy = result.map(item=>{
                                    return Object.assign({},item);
                                })
                                dataCopy.forEach(element => {
                                    element.fileSize = self.formatBytes(element.ContentDocument.ContentSize, 2);
                                });
                                self.reclamationFiles = dataCopy;
                            }
                            self.uploadedFiles = [];
                        });
                    }).catch(err=>{
                        console.log(err)
                        self.template.querySelector('c-custom-toast-lwc').showToast('warning', this.labels.contact_sys_admin);
                    }).finally(() => {
                        
                    })               
                });                     
            } catch (error) {
                console.log(error)
            }         
                // console.log( this.uploadedFiles);          
            }
                   
        } else {
            this.template.querySelector('c-custom-toast-lwc').showToast('warning', this.labels.can_not_edit_reclamation);
        }
        
    }

    async fileListToBase64(fileList) {     
        try {                 
            function getBase64(file) {
            const reader = new FileReader()
            return new Promise(resolve => {
                reader.onload = ev => {
                resolve(file.name+','+ev.target.result.split(',')[1])
                // console.log(file.name)
                }
                reader.readAsDataURL(file)
            })
            }    
            const promises = []         
            for (let i = 0; i < fileList.length; i++) {
            promises.push(getBase64(fileList[i]))
            }
            return await Promise.all(promises)
        } catch (error) {
            console.log(error)   
        }
    }
    controlFieldChanged(event){
        let divId = event.target.dataset.id; 
        // console.log('event type changed');
        // console.log(this.template.querySelectorAll('select[data-id="' + divId + '"]')[0]);

        var stateSelected = event.target.value;       
    	var citySelElem = this.template.querySelectorAll('select[data-id="' + divId + '"]')[1];
    	//var stateCityMap = component.get('v.depnedentFieldMap');
    	let cityArray = this.mapDependetValue[stateSelected];
    	let innerHTMLVar = '';
    	for (var i = 0; i < cityArray.length; i++) {
    		//innerHTMLVar = innerHTMLVar + '<option value="' + cityArray[i]+ '">' +cityArray[i] +'</option>';  
            // console.log(cityArray[i]);
            innerHTMLVar = innerHTMLVar + '<option text="'+cityArray[i]+'">' +cityArray[i] +'</option>';  
    	}
    	citySelElem.innerHTML = innerHTMLVar;
    }

    checkSelected(event){
        let divId = event.target.dataset.id; 
        // console.log(this.template.querySelectorAll('select[data-id="' + divId + '"]')[0].value);
        // console.log(this.template.querySelectorAll('select[data-id="' + divId + '"]')[1].value);
    }

    edit(event){
        if(this.reclamation.Status__c == 'Draft'){
        let divId = event.target.dataset.id;      
        this.template.querySelectorAll('input[data-id="' + divId + '"]')[0].disabled = false;
        let claimQty = this.template.querySelectorAll('input[data-id="' + divId + '"]')[0];
        claimQty.style.borderBottom = '1px solid grey';
        this.template.querySelectorAll('div[data-id="' + divId + '"]')[0].classList.remove('displayNone');
        this.template.querySelectorAll('select[data-id="' + divId + '"]')[0].classList.remove('displayNone');
        this.template.querySelectorAll('select[data-id="' + divId + '"]')[1].classList.remove('displayNone');
        this.template.querySelectorAll('span[data-id="' + divId + '"]')[0].classList.add('displayNone');
        this.template.querySelectorAll('span[data-id="' + divId + '"]')[1].classList.add('displayNone');
    }else {
        this.template.querySelector('c-custom-toast-lwc').showToast('warning', this.labels.can_not_edit_reclamation);
    }
    }

    noEdit(event){
        let divId = event.target.dataset.id;
        this.template.querySelectorAll('div[data-id="' + divId + '"]')[0].classList.add('displayNone');
        this.template.querySelectorAll('input[data-id="' + divId + '"]')[0].disabled = true;
        this.template.querySelectorAll('select[data-id="' + divId + '"]')[0].classList.add('displayNone');
        this.template.querySelectorAll('select[data-id="' + divId + '"]')[1].classList.add('displayNone');
        this.template.querySelectorAll('span[data-id="' + divId + '"]')[0].classList.remove('displayNone');
        this.template.querySelectorAll('span[data-id="' + divId + '"]')[1].classList.remove('displayNone');
        this.reclamationItemsList = this.reclamationItemsList;
        let saveDataTable = this.reclamationItemsList;
        this.reclamationItemsList = [];
        this.reclamationItemsList = saveDataTable;
    }

    yesEdit(event){     
        try {
            
        
        let selectedId = event.target.dataset.id;
        this.reclamationItemsList.forEach(element => {
            if(element.Id==selectedId){       
                element.ClaimQty__c = this.template.querySelectorAll('input[data-id="' + selectedId + '"]')[0].value;
                element.Mistmatch_Type__c =  this.template.querySelectorAll('select[data-id="' + selectedId + '"]')[0].value;                
                element.Mistmatch_SubType__c = this.template.querySelectorAll('select[data-id="' + selectedId + '"]')[1].value;
                editReclamationItem({reclamationItem:element}).then(result=>{
                    // console.log(result);
                    this.template.querySelectorAll('div[data-id="' + selectedId + '"]')[0].classList.add('displayNone');
                    this.template.querySelectorAll('input[data-id="' + selectedId + '"]')[0].disabled = true;
                    this.template.querySelectorAll('select[data-id="' + selectedId + '"]')[0].classList.add('displayNone');
                    this.template.querySelectorAll('select[data-id="' + selectedId + '"]')[1].classList.add('displayNone');
                    this.template.querySelectorAll('span[data-id="' + selectedId + '"]')[0].classList.remove('displayNone');
                    this.template.querySelectorAll('span[data-id="' + selectedId + '"]')[1].classList.remove('displayNone');
                }).catch(error=>{
                    console.log(error);
                })
            }
        }         
        )
        } catch (error) {
            console.log(error)
        }
    }

    @api LWCreloadProducts(){
        // console.log('reload items');
        getReclamationDetail({ReclamationId:this.getSelectedReclamation}).then(response=>{
            // console.log(response);  
            this.reclamationItemsList = response.Reclamation_Details__r;  
            this.reclamation = response; 
            this.noRefund = response.No_Refund__c;        
        })
    }


    get ContractNumber(){
        return this.reclamation.ContractNum__c?this.reclamation.ContractNum__c:'n/a';
    }

    get ContractDate(){
        return this.reclamation.ContractDate__c?this.reclamation.ContractDate__c:'n/a';
    }

    get Comment(){
        return this.reclamation.Comment__c?this.reclamation.Comment__c:'n/a';
    }
}