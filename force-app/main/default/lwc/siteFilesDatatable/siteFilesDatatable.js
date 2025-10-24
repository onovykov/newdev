import { LightningElement, track, wire,api } from 'lwc';
import IMAGES from "@salesforce/resourceUrl/SiteImages";
import getFiles from '@salesforce/apex/FilesDatatableController.getFiles';
import uploadFile from '@salesforce/apex/FilesDatatableController.uploadFile';
import deleteRelatedFile from '@salesforce/apex/FilesDatatableController.deleteRelatedFile';
import viewFile from '@salesforce/apex/FilesDatatableController.viewFile';
import CHOOSEADATE from '@salesforce/label/c.Choose_a_date';
import FROM from '@salesforce/label/c.From';
import TO from '@salesforce/label/c.To';
import { refreshApex } from '@salesforce/apex';

import Upload_file from '@salesforce/label/c.Upload_file';	
import scf_name from '@salesforce/label/c.scf_name';
import scf_owner from '@salesforce/label/c.scf_owner';
import scf_lastChange from '@salesforce/label/c.scf_lastChange';
import Site_th_delete from '@salesforce/label/c.Site_th_delete';
import delete_file_question from '@salesforce/label/c.delete_file_question';
import Yes from '@salesforce/label/c.Yes';
import No from '@salesforce/label/c.No';





import {NavigationMixin} from 'lightning/navigation';

export default class SiteFilesDatatable extends NavigationMixin(LightningElement) {
    @track data;
    @track filteredFilesList;
    @track filesList;
    
    chooseADate = CHOOSEADATE;
    from = FROM;
    to = TO;
    refresh = IMAGES + '/refresh.png';
    plus = IMAGES + '/plus.png';

    @track filesResult
    @track startDate;
    @track endDate;
    @track searchKey;
    @track idFileToDelete;
    @track modalDeleteFile = false;
    @track modalText;
    @track deleteFileBoolean = false;
    @track uploadedFiles = [];
    
    cdl;

    labels = {
        Upload_file,
        scf_name,
        scf_owner,
        scf_lastChange,
        Site_th_delete,
        delete_file_question,
        Yes,
        No
    }
    
    @wire(getFiles,{}) handleFiles(result){
        this.filesResult = result;
        const {error, data } = result;
        if(data){
            console.log(data);
            
            this.filesList = data;
            this.filteredFilesList = data;
        }
        if(error){
            console.error(error);
        }

    }

    handleSearch(event) {
        this.searchKey = event.target.value.toLowerCase();
        this.searchBy();
    }


    refreshSearch(){
        console.log('this.startDate' , this.startDate);
        console.log('this.endDate' , this.endDate);
        console.log('this.searchKey' , this.searchKey);
        this.filteredFilesList = this.filesList;
        this.startDate = null;
        this.endDate = null
        this.searchKey = null;
        [...this.template
            .querySelectorAll('lightning-input, lightning-textarea')]
            .forEach((input) => { input.value = ''; });

        console.log('this.startDate' , this.startDate);
        console.log('this.endDate' , this.endDate);
        console.log('this.searchKey' , this.searchKey);
    }

    setStartDate(event){
        this.startDate = event.target.value;
        console.log( this.startDate);
        this.searchBy();
    }
    setEndDate(event){
        this.endDate = event.target.value;
        console.log( this.endDate);
        this.searchBy();
    }

    searchBy(){
        
        this.filteredFilesList = this.filesList;
        console.log( this.filteredFilesList);
        if (this.searchKey) {
            if (this.filteredFilesList) {
                let searchRecords = [];
                for (let record of this.filteredFilesList) {
                    //console.log('RECORD', JSON.stringify(record.ContentDocument) );
                    let valuesArray = Object.values(record.ContentDocument);
 
                    for (let val of valuesArray) {
                        //console.log( 'val is ' + val);
                        let strVal = String(val);
 
                        if (strVal) {
 
                            if (strVal.toLowerCase().includes(this.searchKey)) {
                                searchRecords.push(record);
                                break;
                            }
                        }
                    }
                }
 
                console.log( 'Matched files are ' + JSON.stringify(searchRecords));
                this.filteredFilesList = searchRecords;
            }
        } else {
            this.filteredFilesList = this.filesList;
        }

        if(this.startDate){
            this.filteredFilesList = this.filteredFilesList.filter(file=>{
                return file.ContentDocument.ContentModifiedDate >= this.startDate;
            })
        }

        if(this.endDate){
            this.filteredFilesList = this.filteredFilesList.filter(file=>{
                return file.ContentDocument.ContentModifiedDate <= this.endDate;
            })
        }
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

    openDeleteFileModal(event){
        try{
            this.modalText = this.labels.delete_file_question;
            this.modalDeleteFile = true;
            this.deleteFileBoolean = true;
            this.idFileToDelete = event.target.dataset.id;
        } catch (e) {
            console.log(e);
        console.log(event.target.dataset.id);
        }
    }
    
    confirmModal(){
        if(this.deleteFileBoolean){
            console.log('YES')
            this.deleteFile();
        }
    }

    deleteFile(){
        deleteRelatedFile({docId:this.idFileToDelete}).then(response=>{
            console.log('123',response);
            this.closeModal(); 
            getFiles().then(result=>{
            
                if(result){
                    console.log(result);
                    let dataCopy = result.map(item=>{
                        return Object.assign({},item);
                    })
                    this.filteredFilesList = dataCopy;
                    this.closeModal(); 
                    this.cleanModalBoolean();
                    refreshApex(this.filesResult);
                }
                
            });
    })
    }

    cleanModalBoolean(){
        this.modalDeleteFile = false;
        this.deleteFileBoolean = false;
    }   

    closeModal(){
        this.modalDeleteFile = false;
    }

    handleFileSelect(event) {      
        console.log(event.target.files)
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
                    console.log(self.uploadedFiles);
                    uploadFile({ files:JSON.stringify(self.uploadedFiles)}).then(result=>{                 
                        console.log(result)
                        self.template.querySelector('c-custom-toast-lwc').showToast('success', 'Files uploaded');
                        getFiles().then(result=>{
                
                            if(result){
                                console.log(result);
                                let dataCopy = result.map(item=>{
                                    return Object.assign({},item);
                                })
                                self.filteredFilesList = dataCopy;
                            }
                            self.uploadedFiles = [];
                            refreshApex(self.filesResult);
                        });
                    }).catch(err=>{
                        console.log(err)
                        self.template.querySelector('c-custom-toast-lwc').showToast('warning', 'Something went wrong. Contact with administrator,please.');
                    }).finally(() => {
                        
                    })               
                });                     
            } catch (error) {
                console.log(error)
            }         
                console.log( this.uploadedFiles);          
            }
      
        
    }

    async fileListToBase64(fileList) {     
        try {                 
            function getBase64(file) {
            const reader = new FileReader()
            return new Promise(resolve => {
                reader.onload = ev => {
                resolve(file.name+','+ev.target.result.split(',')[1])
                console.log(file.name)
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
}