import { LightningElement, api,wire,track } from 'lwc';
import getReclamationFiles from '@salesforce/apex/ReclamationDatatableController.getReclamationFiles';
import viewFile from '@salesforce/apex/ReclamationDatatableController.viewFile';
import {NavigationMixin} from 'lightning/navigation';
export default class SiteOrderDatatable extends NavigationMixin(LightningElement) {
    @track data;
    @track reclamationFiles;
    cdl;

    @wire(getReclamationFiles,{}) handleReclamations(result){
        const {error, data } = result;
        if(data){
            console.log(data);
            let dataCopy = data.map(item=>{
                return Object.assign({},item);
            })
            dataCopy.forEach(element => {
                element.fileSize = this.formatBytes(element.ContentDocument.ContentSize, 2);
            });
            this.reclamationFiles = dataCopy;
        }
        if(error){
            console.error(error);
        }

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
}