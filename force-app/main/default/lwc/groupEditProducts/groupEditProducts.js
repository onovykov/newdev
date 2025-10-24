import { LightningElement, track, api, wire } from 'lwc';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import getQuoteLineItems from '@salesforce/apex/QuoteLineItemGroupEditController.getQuoteLineItems';
import updateQuoteLineItems from '@salesforce/apex/QuoteLineItemGroupEditController.updateQuoteLineItems';


export default class GroupEditProducts extends LightningElement {
    @api recordId;
    @api isLoaded = false;
    @track wiredRecords = [];
    @track records = [];
    error;
    @track columns = [];
    @track draftValues;
    changedValues = [];
    showCustomButtons = false;
    disableSaveButton = true;
    disableAcceptButton = true;
    notifyChangeIds = [];
    selectedRowsToUpdate = [];
    previousRecords = [];
    initialRecords = [];
    arrayForSave = [];
    updatedRecords = [];
    

    //Boolean tracked variable to indicate if modal is open or not default value is false as modal is closed when page is loaded 
    @track isSaveModalOpen = false;
    @track isReturnInitialModalOpen = false;
    @track isCancelModalOpen = false;
    openSaveModal() {
        // to open modal set isModalOpen tarck value as true
        this.isSaveModalOpen = true;
    }
    closeSaveModal() {
        // to close modal set isModalOpen tarck value as false
        this.isSaveModalOpen = false;
    }
    submitSaveDetails() {
        // to close modal set isModalOpen tarck value as false
        //Add your code to call apex method or do some processing
        this.isSaveModalOpen = false;
    }
    openReturnInitialModal() {
        // to open modal set isModalOpen tarck value as true
        this.isReturnInitialModalOpen = true;
    }
    closeReturnInitialModal() {
        // to close modal set isModalOpen tarck value as false
        this.isReturnInitialModalOpen = false;
    }
    submitReturnInitialDetails() {
        // to close modal set isModalOpen tarck value as false
        //Add your code to call apex method or do some processing
        this.isReturnInitialModalOpen = false;
    }
    openModalForClose(){
        this.isCancelModalOpen = true;
    }
    closeModalForClose(){
        this.isCancelModalOpen = false;
    }

    

    @wire(getQuoteLineItems, { recordId: '$recordId' })
    wiredQLI(value) {
        this.wiredRecords = value;
        const { data, error } = value;
        if (data) {
            let tempRecords = JSON.parse( JSON.stringify( data ) );
            
            tempRecords = tempRecords.map( row => {  
                            
                return { ...row, Name: row.Product2.Name,
                    CurrencyOpp: row.Quote.Opportunity.CurrencyIsoCode,               
                    ProductStandart: JSON.stringify(row).includes("ProductStandard__r") ? row.ProductStandard__r.Name : '', 
                    ProductSpecLvl: JSON.stringify(row).includes("ProductSpecLevel__r") ? row.ProductSpecLevel__r.Name : '', 
                    SteelGrade:  JSON.stringify(row).includes("SteelGrade__r") ? row.SteelGrade__r.Name : '', 
                    WT: JSON.stringify(row).includes("TubeWT__r") ? row.TubeWT__r.Name : '', 
                    OD: JSON.stringify(row).includes("TubeOD__r") ? row.TubeOD__r.Name : '', 
                    Ends: JSON.stringify(row).includes("TubeEnds__r") ? row.TubeEnds__r.Name : '', 
                    LengSize: JSON.stringify(row).includes("TubeLengthSize__r") ? row.TubeLengthSize__r.Name : '',
                    isAccessory: row.Product2.Is_Accessory__c,
                    LengthMin_mm__c: JSON.stringify(row).includes("TubeLengthSize__r") ? row.TubeLengthSize__r.MinLength__c:0,
                    LengthMax_mm__c: JSON.stringify(row).includes("TubeLengthSize__r") ? row.TubeLengthSize__r.MaxLength__c:0  };
            })
            this.records = tempRecords;
            this.previousRecords = tempRecords;
            this.error = undefined;
            this.isLoaded = true;
            this.initialRecords = tempRecords.map(a => ({...a}));
        } else if (error) {
            this.error = error;
            this.records = undefined;
        }
    }

    closeQuickAction() {
        //console.log('close modal test');
        this.dispatchEvent(new CustomEvent('close'));;
    }

    connectedCallback(){
        this.columns = [
            {
                label: 'Product',
                fieldName: 'Name',
                type: 'text'
            },/*{
                label: 'Product', fieldName: 'Product2Id', type: 'customLookup', 
                    typeAttributes: {mainObjectApiName: 'QuoteLineItem', targetFieldApiName: 'Product2Id', 
                        value: { fieldName: 'Product2Id' }, required: "true", disabled: "true", recordId: { fieldName: 'Id' } }
            },*/

            { 
                label: 'Sales Price (per t)', fieldName: 'UnitPrice', type: 'customLookup',  
                    typeAttributes: {mainObjectApiName: 'QuoteLineItem', targetFieldApiName: 'For_Temporary_Update__c', 
                        value: { fieldName: 'UnitPrice' }, recordId: { fieldName: 'Id' }, disabled:{ fieldName: 'isAccessory' } }
            },
            {
                label:'Currency', fieldName: 'CurrencyOpp', type: 'text', fixedWidth: 110
            },
            
            { 
                label: 'Sales Price (per unit)', fieldName: 'InquiryUnitPrice__c', type: 'customLookup', 
                    typeAttributes: {mainObjectApiName: 'QuoteLineItem', targetFieldApiName: 'For_Temporary_Update_Sales_Unit__c', 
                        value: { fieldName: 'InquiryUnitPrice__c' }, recordId: { fieldName: 'Id' } } 
            },

            { 
                label: 'Quantity (t)', fieldName: 'Quantity', type: 'customLookup', 
                    typeAttributes: {mainObjectApiName: 'QuoteLineItem', targetFieldApiName: 'Quantity', 
                        value: { fieldName: 'Quantity' }, recordId: { fieldName: 'Id' }, disabled:{ fieldName: 'isAccessory' }  } 
            },

            { 
                label: 'Quantity (units)', fieldName: 'InquiryQuantity__c', type: 'customLookup', 
                    typeAttributes: {mainObjectApiName: 'QuoteLineItem', targetFieldApiName: 'InquiryQuantity__c', 
                        value: { fieldName: 'InquiryQuantity__c' }, recordId: { fieldName: 'Id' } } 
            },
            
            { 
                label: 'Measurement Unit', fieldName: 'InquiryUnit__c', type: 'customLookup', 
                    typeAttributes: {mainObjectApiName: 'QuoteLineItem', targetFieldApiName: 'InquiryUnit__c', 
                        value: { fieldName: 'InquiryUnit__c' }, recordId: { fieldName: 'Id' }, disabled:{ fieldName: 'isAccessory' }  }
            },

            { 
                label: 'Line Item Description', fieldName: 'Description', type: 'customLookup', 
                    typeAttributes: {mainObjectApiName: 'QuoteLineItem', targetFieldApiName: 'Description', 
                        value: { fieldName: 'Description' }, recordId: { fieldName: 'Id' } } 
            },
        
            {
                label: 'Shop', fieldName: 'Shop__c', type: 'customLookup', 
                    typeAttributes: { mainObjectApiName: 'QuoteLineItem', targetFieldApiName: 'Shop__c', 
                        value: { fieldName: 'Shop__c' }, recordId: { fieldName: 'Id' } }
            },
        
            {
                label: 'Shipping Point', fieldName: 'ShippingPoint__c', type: 'customLookup', 
                    typeAttributes: { mainObjectApiName: 'QuoteLineItem', targetFieldApiName: 'ShippingPoint__c', 
                        value: { fieldName: 'ShippingPoint__c' }, recordId: { fieldName: 'Id' } }
            },

            { 
                label: 'Discount', fieldName: 'Discount', type: 'customLookup', 
                    typeAttributes: { mainObjectApiName: 'QuoteLineItem', targetFieldApiName: 'Discount', 
                        value: { fieldName: 'Discount' }, recordId: { fieldName: 'Id' } } 
            },
            {
                label: 'Product Standard',
                fieldName: 'ProductStandart',
                type: 'text'
            },
            {
                label: 'Product Spec Level',
                fieldName: 'ProductSpecLvl',
                type: 'text'
            },
            {
                label: 'Steel Grade',
                fieldName: 'SteelGrade',
                type: 'text'
            },
            {
                label: 'OD',
                fieldName: 'OD',
                type: 'text'
            },
            {
                label: 'WT',
                fieldName: 'WT',
                type: 'text'
            },
            {
                label: 'Ends',
                fieldName: 'Ends',
                type: 'text'
            },
            {
                label: 'Length Size',
                fieldName: 'LengSize',
                type: 'text'
            },
            /*{
                label: 'Product Standard', fieldName: 'ProductStandard__c', type: 'customLookup', 
                    typeAttributes: { mainObjectApiName: 'QuoteLineItem', targetFieldApiName: 'ProductStandard__c', 
                        value: { fieldName: 'ProductStandard__c' }, recordId: { fieldName: 'Id' }, disabled: "true" }
            },
        ProductSpecLvl
            {
                label: 'Product Spec Level', fieldName: 'ProductSpecLevel__c', type: 'customLookup', 
                    typeAttributes: { mainObjectApiName: 'QuoteLineItem', targetFieldApiName: 'ProductSpecLevel__c', 
                        value: { fieldName: 'ProductSpecLevel__c' }, recordId: { fieldName: 'Id' }, disabled: "true" }
            },
        
            {
                label: 'Steel Grade', fieldName: 'SteelGrade__c', type: 'customLookup', 
                    typeAttributes: { mainObjectApiName: 'QuoteLineItem', targetFieldApiName: 'SteelGrade__c', 
                        value: { fieldName: 'SteelGrade__c' }, recordId: { fieldName: 'Id' }, disabled: "true" }
            },
        
            {
                label: 'OD', fieldName: 'TubeOD__c', type: 'customLookup', 
                    typeAttributes: { mainObjectApiName: 'QuoteLineItem', targetFieldApiName: 'TubeOD__c', 
                        value: { fieldName: 'TubeOD__c' }, recordId: { fieldName: 'Id' }, disabled: "true" }
            },
        
            {
                label: 'WT', fieldName: 'TubeWT__c', type: 'customLookup', 
                    typeAttributes: { mainObjectApiName: 'QuoteLineItem', targetFieldApiName: 'TubeWT__c', 
                        value: { fieldName: 'TubeWT__c' }, recordId: { fieldName: 'Id' }, disabled: "true" }
            },
        
            {
                label: 'Ends', fieldName: 'TubeEnds__c', type: 'customLookup', 
                    typeAttributes: { mainObjectApiName: 'QuoteLineItem', targetFieldApiName: 'TubeEnds__c', 
                        value: { fieldName: 'TubeEnds__c' }, recordId: { fieldName: 'Id' }, disabled: "true" }
            },
        
            {
                label: 'Length Size', fieldName: 'TubeLengthSize__c', type: 'customLookup', 
                    typeAttributes: { mainObjectApiName: 'QuoteLineItem', targetFieldApiName: 'TubeLengthSize__c', 
                        value: { fieldName: 'TubeLengthSize__c' }, recordId: { fieldName: 'Id' }, disabled: "true" }
            },*/
        
            { label: 'Weight (kpm)', fieldName: 'Weight_kpm__c', type: 'number' },
            { label: 'Weight (ppf)', fieldName: 'Weight_ppf__c', type: 'number' },

            { label: 'Quantity (ft)', fieldName: 'Quantity_ft__c', type: 'customLookup', 
            typeAttributes: { mainObjectApiName: 'QuoteLineItem', targetFieldApiName: 'Quantity_ft__c', 
                value: { fieldName: 'Quantity_ft__c' }, recordId: { fieldName: 'Id' }, disabled:{ fieldName: 'isAccessory' }  } },

            { label: 'Quantity (lb)', fieldName: 'Quantity_lb__c',type: 'customLookup', 
            typeAttributes: { mainObjectApiName: 'QuoteLineItem', targetFieldApiName: 'Quantity_lb__c', 
                value: { fieldName: 'Quantity_lb__c' }, recordId: { fieldName: 'Id' }, disabled:{ fieldName: 'isAccessory' }  } },

            { label: 'Quantity (m)', fieldName: 'Quantity_m__c', type: 'customLookup', 
            typeAttributes: { mainObjectApiName: 'QuoteLineItem', targetFieldApiName: 'Quantity_m__c', 
                value: { fieldName: 'Quantity_m__c' }, recordId: { fieldName: 'Id' }, disabled:{ fieldName: 'isAccessory' }  }  },

            { label: 'Quantity (pcs)', fieldName: 'Quantity_pcs__c', type: 'customLookup', 
            typeAttributes: { mainObjectApiName: 'QuoteLineItem', targetFieldApiName: 'Quantity_pcs__c', 
                value: { fieldName: 'Quantity_pcs__c' }, recordId: { fieldName: 'Id' } }  },

            { label: 'Sales Price (per ft)', fieldName: 'Sales_Price_ft__c', type: 'customLookup', 
            typeAttributes: { mainObjectApiName: 'QuoteLineItem', targetFieldApiName: 'For_Temporary_Update_Sales_ft__c', 
                value: { fieldName: 'Sales_Price_ft__c' }, recordId: { fieldName: 'Id' }, disabled:{ fieldName: 'isAccessory' }  }},

            { label: 'Sales Price (per lb)', fieldName: 'Sales_Price_lb__c', type: 'customLookup', 
            typeAttributes: { mainObjectApiName: 'QuoteLineItem', targetFieldApiName: 'For_Temporary_Update_Sales_lb__c', 
                value: { fieldName: 'Sales_Price_lb__c' }, recordId: { fieldName: 'Id' }, disabled:{ fieldName: 'isAccessory' }  } },

            { label: 'Sales Price (per m)', fieldName: 'Sales_Price_m__c',type: 'customLookup', 
            typeAttributes: { mainObjectApiName: 'QuoteLineItem', targetFieldApiName: 'For_Temporary_Update_Sales_m__c', 
                value: { fieldName: 'Sales_Price_m__c' }, recordId: { fieldName: 'Id' }, disabled:{ fieldName: 'isAccessory' }  } },

            { label: 'Sales Price (per pcs)', fieldName: 'Sales_Price_pcs__c', type: 'customLookup', 
            typeAttributes: { mainObjectApiName: 'QuoteLineItem', targetFieldApiName: 'For_Temporary_Update_Sales_pcs__c', 
                value: { fieldName: 'Sales_Price_pcs__c' }, recordId: { fieldName: 'Id' } } },
        ];
    }

    handleRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;
        //console.log('rowaction');
        //console.log(row);
 }

    handleCustomChange(event) {
        
        let changedLookupValue = event.detail.value;
        let recordId = event.detail.recordId;
        let fieldApiName = event.detail.fieldApiName;
       
       if(fieldApiName == 'For_Temporary_Update__c'){
        fieldApiName = 'UnitPrice' 
       }
        else if(fieldApiName =='For_Temporary_Update_Sales_Unit__c'){
        fieldApiName = 'InquiryUnitPrice__c'    
       }

       if(fieldApiName == 'For_Temporary_Update_Sales_lb__c'){
        fieldApiName = 'Sales_Price_lb__c'
       }
       
       if(fieldApiName == 'For_Temporary_Update_Sales_pcs__c'){
        fieldApiName = 'Sales_Price_pcs__c'
       }

       if(fieldApiName == 'For_Temporary_Update_Sales_m__c'){
        fieldApiName = 'Sales_Price_m__c'
       }

       if(fieldApiName == 'For_Temporary_Update_Sales_ft__c'){
        fieldApiName = 'Sales_Price_ft__c'
       }

        let changedObj = { recId: recordId, field: fieldApiName, value: changedLookupValue };
        

        this.changedValues.push(changedObj);
        
          
        this.showCustomButtons = true;
        this.disableSaveButton = true;
        this.disableAcceptButton = false;                        
    }

    handleCustomSave(){
        //clear refresh and update arrays
        this.notifyChangeIds = [];
        this.selectedRowsToUpdate = [];
        this.isSaveModalOpen = false;
        this.disableAcceptButton = true;
        //get selected rows before save
        let selectedRows = this.template.querySelector('c-group-edit-products-custom-data-table').getSelectedRows();
       

        //prepare data for refresh and update
        if(Array.isArray(selectedRows) && selectedRows.length){
            
            for(let selectedRow of selectedRows){
                let rowToUpdate = Object.assign({}, selectedRow);
                for (let changedValue of this.changedValues){
                    rowToUpdate[changedValue.field] = changedValue.value;
                }
                this.selectedRowsToUpdate.push(rowToUpdate);
            }

            this.notifyChangeIds = this.selectedRowsToUpdate.map(row => { return { recordId: row.Id } });
            
        } else {
            //get all changed records ids from this.changedValues - this.arrayForSave 19.11
            let changedRecordsIds = new Set();
            for (let changedValue of this.arrayForSave){
                changedRecordsIds.add(changedValue.recId);
                
            }
            
            
            //get all changed records
            let recordsToUpdate = [];
            for (let changedRecId of changedRecordsIds){
                let changedRecord = this.records.find(x => x.Id === changedRecId);
                let recordToUpdate = Object.assign({}, changedRecord);
                recordsToUpdate.push(recordToUpdate);
            }
            

            for(let rowToUpdate of recordsToUpdate){
                for (let changedValue of this.changedValues){
                    if(rowToUpdate.Id === changedValue.recId){
                        rowToUpdate[changedValue.field] = changedValue.value;
                    }
                }
                this.selectedRowsToUpdate.push(rowToUpdate);
            }
            
            this.notifyChangeIds = this.selectedRowsToUpdate.map(row => { return { recordId: row.Id } });
            
        }

        this.updateRecords(this.notifyChangeIds, this.selectedRowsToUpdate);
        //this.disableSaveButton = true;
        this.showCustomButtons = false;
        this.changedValues = [];
        
        

    }

    handleCustomCancel(){
        this.disableSaveButton = true;
        this.showCustomButtons = false;
        
       this.records = [];
              
        getQuoteLineItems({recordId: this.recordId }).then(result =>            
            {
                this.records =  this.previousRecords;
                this.changedValues = [];
                
            }
            )
            .catch(error=>
                {
                }
            )
    }

    async updateRecords(notifyChangeIds, updatedRecords){
        try {            
            const result = await updateQuoteLineItems({data: updatedRecords});
            //console.log(result);
            if(result == 'Success: QuoteLineItem(s) updated successfully'){
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Product(s) updated',
                        variant: 'success'
                    })
                );
            } else {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: result,
                        variant: 'error',
                        mode: 'sticky'
                    })
                );
            }
            
            
            getRecordNotifyChange(notifyChangeIds);
            
            return refreshApex(this.wiredRecords).then(() => {
                this.draftValues = [];
            });

        } catch(error) {
               this.dispatchEvent(
                   new ShowToastEvent({
                       title: 'Error updating or refreshing records',
                       message: error.body.message,
                       variant: 'error'
                   })
             );
        };
    }
   
    returnInitialDataValues(){
        this.disableSaveButton = true;
        //console.log('work');
       // console.log(this.records);
       // console.log(this.initialRecords);
        this.records = [];
        this.updatedRecords = [];
        this.arrayForSave = [];
        setTimeout(() =>
             {   //console.log('testtimeout');
                //console.log(this.initialRecords);
                this.records = this.initialRecords},100);
        this.isReturnInitialModalOpen = false;
    }
        
    accept(){

        let alertQuantityShow = false;
        let alertSaleShow = false;
        let lastQuantityUpdate = ' ';
        let lastSaleUpdate = ' ';
        
        var makeChangesInRecord = function(record){
            updatedRecArra.forEach(function(data,ind){
                //console.log(data.Id == record.Id);
                    if(data.Id == record.Id){
                        //console.log(data);
                       // console.log(record);
                        data.Quantity_m__c = isNaN(record.Quantity_m__c) ? 0.0 : Number( record.Quantity_m__c).toFixed(2);
                        data.InquiryQuantity__c = isNaN(record.InquiryQuantity__c) ? 0.0 :  Number(record.InquiryQuantity__c).toFixed(3);
                        data.Quantity_lb__c = isNaN(record.Quantity_lb__c) ? 0.0 :  Number(record.Quantity_lb__c).toFixed(2);
                        data.Quantity_ft__c = isNaN(record.Quantity_ft__c) ? 0.0 :  Number(record.Quantity_ft__c).toFixed(2);
                        data.Quantity_pcs__c = isNaN(record.Quantity_pcs__c) || !isFinite((record.Quantity_pcs__c)) ? 0.0 :  Number(record.Quantity_pcs__c).toFixed(2);
                        data.Quantity = isNaN(record.Quantity) ? 0.0 :  Number(record.Quantity).toFixed(2);
                        
                        data.InquiryUnit__c =  isNaN(record.InquiryUnit__c) ? 0.0 :  record.InquiryUnit__c;

                        data.Sales_Price_m__c =  isNaN(record.Sales_Price_m__c)? 0.0 :  Number(record.Sales_Price_m__c).toFixed(2);
                        data.Sales_Price_pcs__c =  isNaN(record.Sales_Price_pcs__c)? 0.0 :  Number(record.Sales_Price_pcs__c).toFixed(2);
                        data.Sales_Price_lb__c =  isNaN(record.Sales_Price_lb__c)? 0.0 :  Number(record.Sales_Price_lb__c).toFixed(2);
                        data.Sales_Price_ft__c =  isNaN(record.Sales_Price_ft__c)? 0.0 :  Number(record.Sales_Price_ft__c).toFixed(2);
                        data.UnitPrice =  isNaN(record.UnitPrice)? 0.0 :  Number(record.UnitPrice).toFixed(2);
                        data.InquiryUnitPrice__c =  isNaN(record.InquiryUnitPrice__c)? 0.0 :  Number(record.InquiryUnitPrice__c).toFixed(2);

                        //console.log('in if 463');                                                        
                        //console.log(data);
                        /*
                        if(data.isAccessory){

                        data.Sales_Price_m__c = '0.00';                  
                        data.Sales_Price_lb__c = '0.00';
                        data.Sales_Price_ft__c = '0.00';
                        data.UnitPrice = '0.00';

                        data.Quantity_m__c = '0.00';                   
                        data.Quantity_lb__c = '0.00';
                        data.Quantity_ft__c = '0.00';                     
                        data.Quantity = '0.00';
                        }
                        */
                }})
        };

        let selectedRowsToUpdate = [];
        let updateSelectedRows = this.changedValues.map(a => ({...a}));
        //get selected rows before save
        let selectedRows = this.template.querySelector('c-group-edit-products-custom-data-table').getSelectedRows();      
        //prepare data for refresh and update
        if(Array.isArray(selectedRows) && selectedRows.length){
            
            for(let selectedRow of selectedRows){
                let rowToUpdate = Object.assign({}, selectedRow);
                for (let changedValue of updateSelectedRows){
                    rowToUpdate[changedValue.field] = changedValue.value;
                    let changedObj = { recId: rowToUpdate.Id, field: changedValue.field, value: changedValue.value };
                    this.changedValues.push(changedObj);
                }
                selectedRowsToUpdate.push(rowToUpdate);
            }
        }
        //console.log(selectedRowsToUpdate);

        //console.log(this.changedValues);
        var objduplicatecheck = {};
        var changedOriginal = [];
        var duplicate = this.changedValues.reverse();
        duplicate.map(function(data){
            if(!(data.recId.toString()+data.field.toString() in objduplicatecheck)){
                objduplicatecheck[data.recId.toString()+data.field.toString()] = 'exist';
                
                //console.log(objduplicatecheck);
                changedOriginal.push(data);
            }
        });
        
        objduplicatecheck = {};
        
        //console.log(changedOriginal);
        
        this.changedValues.reverse();
        var prevData;

        if(this.updatedRecords.length == 0){
            
            prevData = this.initialRecords.map(a => ({...a}));
        }else{
          //  console.log('424 line');
            //console.log(this.updatedRecords);
            prevData = this.updatedRecords.map(a => ({...a}));
        }
        
        //prevData.map((data)=>data.Quantity = 77);
       // console.log(prevData);
       // console.log(this.initialRecords);

        //this.records = prevData;
        
        let changedRecordsIds = new Set();
            for (let changedValue of changedOriginal){
                changedRecordsIds.add(changedValue.recId);
                //console.log(changedValue);
            }
        
           // console.log(this.records);    
        let recordsToUpdate = [];
        for (let changedRecId of changedRecordsIds){
            let changedRecord = prevData.find(x => x.Id === changedRecId);
            let recordToUpdate = Object.assign({}, changedRecord);
            recordsToUpdate.push(recordToUpdate);
        }
        
        //console.log(recordsToUpdate);
        //console.log('initialize recs for update 404');
        let updatedRecArra = prevData.map(a => ({...a}));

        for(let record of recordsToUpdate){
            var updates = changedOriginal.filter(c => c.recId == record.Id);
            let quantityChange = false;
            let unitChange = false;
            let unitPricePerTchanged = false;
            let priceInquiryChanged = false;
            let pricePerLbChanged = false;
            let pricePerMChanged = false;
            let pricePerFtChanged = false;
            let pricePerPcshanged = false;

            let quantityPerMChanged = false;
            let quantityPerFtChanged = false;
            let quantityPerPcsChanged = false;
            let quantityPerLbChanged = false;
            let quantityPerTChanged = false;
           
            let newQuantityValue = 0;
            let newUnitMeasuteValue = 0;
            let newSalesPricePerUnit = 0;
            let newSalesPricePerLb = 0;
            let newSalesPricePerFt = 0;
            let newSalesPricePerM = 0;
            let newSalesPricePerPcs = 0 ;
            let newSalesPricePerT = 0;

            let newQuantityPerM = 0;
            let newQuantityPerFt = 0;
            let newQuantityPerPcs = 0;
            let newQuantityPerLb = 0;
            let newQuantityPerT = 0;

            let changeQuantityTimes = 0;
            let changeSalesTimes = 0;

            for(let update in updates){
                //console.log('update');
                //console.log(updates[update].field);
                
                if(updates[update].field.toString() == 'InquiryQuantity__c'){
                    //console.log('quantity changed');
                    quantityChange = true;
                    newQuantityValue = updates[update].value;
                    //console.log(newQuantityValue);
                    changeQuantityTimes++;
                }
                if(updates[update].field.toString() == 'InquiryUnit__c'){
                    unitChange = true;
                    newUnitMeasuteValue = updates[update].value;
                } 
                if(updates[update].field.toString() == 'UnitPrice'){
                    unitPricePerTchanged = true;
                    newSalesPricePerT = updates[update].value;
                    changeSalesTimes++;
                } 
                if(updates[update].field.toString() == 'InquiryUnitPrice__c'){
                    priceInquiryChanged = true;
                    newSalesPricePerUnit = updates[update].value;
                    changeSalesTimes++;
                } 
                if(updates[update].field.toString() == 'Sales_Price_lb__c'){
                    pricePerLbChanged = true;
                    newSalesPricePerLb = updates[update].value;
                    changeSalesTimes++;
                }  
                if(updates[update].field.toString() == 'Sales_Price_ft__c'){
                    pricePerFtChanged = true;
                    newSalesPricePerFt = updates[update].value;
                    changeSalesTimes++;
                }  
                if(updates[update].field.toString() == 'Sales_Price_m__c'){
                    pricePerMChanged = true;
                    newSalesPricePerM = updates[update].value;
                    changeSalesTimes++;
                } 
                if(updates[update].field.toString() == 'Sales_Price_pcs__c'){
                    pricePerPcshanged = true;
                    newSalesPricePerPcs = updates[update].value;
                    changeSalesTimes++;
                } 
                
                if(updates[update].field.toString() == 'Quantity_m__c'){
                    quantityPerMChanged = true;
                    newQuantityPerM = updates[update].value;
                    changeQuantityTimes++;
                } 
                if(updates[update].field.toString() == 'Quantity_ft__c'){
                    quantityPerFtChanged = true;
                    newQuantityPerFt = updates[update].value;
                    changeQuantityTimes++
                } 
                if(updates[update].field.toString() == 'Quantity_lb__c'){
                    //console.log('here');
                    quantityPerLbChanged = true;
                    newQuantityPerLb = updates[update].value;
                    changeQuantityTimes++
                }                  
                if(updates[update].field.toString() == 'Quantity_pcs__c'){
                    quantityPerPcsChanged = true;
                    newQuantityPerPcs = updates[update].value;
                    changeQuantityTimes++
                }  
                if(updates[update].field.toString() == 'Quantity'){
                    quantityPerTChanged = true;
                    newQuantityPerT = updates[update].value;
                    changeQuantityTimes++
                }                 
            }
            //console.log('next update');
            //console.log(quantityChange);

            let Weight_kpm = record.Weight_kpm__c;
            let Weight_ppf = record.Weight_ppf__c;
            let LengthMax_mm = record.LengthMax_mm__c;
            if((Weight_kpm==0 || Weight_kpm == undefined)&&(Weight_ppf==0 ||Weight_ppf ==undefined)){
                alert('Parameters DENSITY KG/M and DENSITY LB/FT are not filled. Some calculations can not be done properly. For product ' + record.Product2.Name);
            }

            if(LengthMax_mm==0 || LengthMax_mm == undefined){
                alert('Parameter Length Max is not filled. Some calculations might not be done properly. For product ' + record.Product2.Name);
            }
            
            if (unitChange) {
                                
                record.InquiryUnit__c = newUnitMeasuteValue;
                let QuantityValue = record.InquiryQuantity__c;
                let Weight_kpm = record.Weight_kpm__c;
                let Weight_ppf = record.Weight_ppf__c;
                let LengthMin_mm = record.LengthMin_mm__c;
                let LengthMax_mm = record.LengthMax_mm__c;
                let DENSITY_KG_M = Weight_kpm;
                let DENSITY_LB_FT = Weight_ppf;
                //t
                if(record.InquiryUnit__c == 34){
                    record.InquiryQuantity__c = record.Quantity;
                    record.InquiryUnitPrice__c = record.UnitPrice;
                    /*
                    record.Quantity = QuantityValue;
                    record.Quantity_lb__c = (record.Quantity*2204.62).toFixed(2) ;
                    record.Quantity_m__c = (record.Quantity / (0.001*Weight_kpm)).toFixed(2);
                    record.Quantity_ft__c = ((record.Quantity / (0.001*Weight_kpm)) / 0.3048).toFixed(2);
                    record.Quantity_pcs__c = (record.Quantity_m__c/ (LengthMax_mm/1000)).toFixed(0);
                    
                    
                    record.Sales_Price_m__c =( record.UnitPrice * (Weight_kpm*0.001)).toFixed(2);
                    record.Sales_Price_ft__c = (record.Sales_Price_m__c * 0.3048).toFixed(2);
                    record.Sales_Price_lb__c = (record.UnitPrice / 2204.62).toFixed(2);
                    record.Sales_Price_pcs__c = (record.Sales_Price_m__c * LengthMax_mm/1000).toFixed(2);
                   */ 
                }
                //lb
                if(record.InquiryUnit__c == 99){
                    record.Quantity_lb__c = QuantityValue;
                    record.Quantity = (record.Quantity_lb__c/2204.62).toFixed(3);
                    record.Quantity_m__c = ((record.Quantity_lb__c/Weight_ppf)/0.3048).toFixed(2);
                    record.Quantity_ft__c =  (record.Quantity_lb__c / Weight_ppf).toFixed(2);
                    record.Quantity_pcs__c = ((record.Quantity_lb__c * Weight_ppf * (LengthMax_mm/1000))/0.3048).toFixed(0);

                    record.InquiryUnitPrice__c = record.Sales_Price_lb__c;
                    record.UnitPrice = (record.Sales_Price_lb__c * 2204.62).toFixed(2);
                    record.Sales_Price_ft__c = (record.Sales_Price_lb__c *  Weight_ppf).toFixed(2);
                    record.Sales_Price_m__c = (record.Sales_Price_ft__c / 0.3048).toFixed(2);
                    record.Sales_Price_pcs__c = (record.Sales_Price_m__c * LengthMax_mm/1000).toFixed(2);
                                                                                      
                }
                //m
                
                if(record.InquiryUnit__c == 20){
                    record.InquiryQuantity__c = record.Quantity_m__c;
                    record.InquiryUnitPrice__c = record.Sales_Price_m__c;
                    /*
                    record.Quantity_m__c = QuantityValue;
                    record.Quantity_pcs__c = (record.Quantity_m__c / (LengthMax_mm/1000)).toFixed(0);
                    record.Quantity_lb__c = (record.Quantity_m__c * (0.001*Weight_kpm) * 2204.62).toFixed(2);
                    record.Quantity_ft__c = (record.Quantity_m__c / 0.3048).toFixed(2);
                    record.Quantity = (record.Quantity_m__c * (0.001 * Weight_kpm)).toFixed(2);

                    
                    record.Sales_Price_ft__c = (record.Sales_Price_m__c * 0.3048).toFixed(2);
                    record.Sales_Price_pcs__c = (record.Sales_Price_m__c * (LengthMax_mm/1000)).toFixed(2);
                    record.Sales_Price_lb__c = (record.Sales_Price_ft__c/Weight_ppf).toFixed(2);
                    record.UnitPrice = (record.Sales_Price_lb__c * 2204.62).toFixed(2);*/
                }
                //ft
                if(record.InquiryUnit__c == 74){
                    record.InquiryQuantity__c = record.Quantity_ft__c;
                    record.InquiryUnitPrice__c = record.Sales_Price_ft__c;
                    /*
                    record.Quantity_ft__c = QuantityValue;
                    record.Quantity_m__c =  (record.Quantity_ft__c*0.3048).toFixed(2);
                    record.Quantity_pcs__c = (record.Quantity_m__c / (LengthMax_mm/1000)).toFixed(0);
                    record.Quantity_lb__c = (record.Quantity_m__c * (0.001*Weight_kpm) * 2204.62).toFixed(2);                    
                    record.Quantity = (record.Quantity_m__c * (0.001 * Weight_kpm)).toFixed(2);
                    */
                    
                    
                }
                //pcs
                if(record.InquiryUnit__c == 43){

                    record.InquiryQuantity__c = record.Quantity_pcs__c;
                    record.InquiryUnitPrice__c = record.Sales_Price_pcs__c;
                    /*
                    record.Quantity_pcs__c = QuantityValue;
                    record.Quantity = ((record.Quantity_pcs__c/ (LengthMin_mm/1000)) * (0.001 * Weight_kpm)).toFixed(2);
                    record.Quantity_m__c = (record.Quantity_pcs__c/ (LengthMin_mm/1000)).toFixed(2);
                    record.Quantity_lb__c = ((record.Quantity_pcs__c/ (LengthMin_mm/1000))*Weight_kpm*2.20462).toFixed(2);
                    record.Quantity_ft__c = ((record.Quantity_pcs__c/ (LengthMin_mm/1000))/0.3048).toFixed(2);
                    */
                    
                }
                
                makeChangesInRecord(record);
              
            }

            if (quantityChange) {
                
                //console.log('quant chagne 785');
                let Weight_kpm = record.Weight_kpm__c;
                let Weight_ppf = record.Weight_ppf__c;
                let LengthMin_mm = record.LengthMin_mm__c;
                let LengthMax_mm = record.LengthMax_mm__c;
                let DENSITY_KG_M = Weight_kpm;
                let DENSITY_LB_FT = Weight_ppf;
                //console.log(Weight_kpm);
                //console.log(Weight_ppf);
                if(record.InquiryUnit__c == 34){
                    record.InquiryQuantity__c = newQuantityValue;
                    record.Quantity = newQuantityValue;
                    record.Quantity_lb__c = (record.Quantity*2204.62).toFixed(2) ;
                    
                    if(Weight_kpm!=0 && Weight_kpm != undefined){
                        //console.log('Weight_kpm');
                        record.Quantity_m__c = (record.Quantity / (0.001*Weight_kpm)).toFixed(2);
                        record.Quantity_ft__c = (record.Quantity_m__c / 0.3048).toFixed(2);
                    } else if(Weight_ppf != 0 && Weight_ppf != undefined){
                        //console.log('Weight_ppf');
                        record.Quantity_m__c = ((record.Quantity_lb__c/Weight_ppf)*0.3048).toFixed(2);
                        record.Quantity_ft__c = (record.Quantity_lb__c/Weight_ppf).toFixed(2);
                    } else {
                        //console.log('null');
                        record.Quantity_m__c = 0;
                        record.Quantity_ft__c = 0;
                    }
                                                                             
                    record.Quantity_pcs__c = (record.Quantity_m__c/ (LengthMax_mm/1000)).toFixed(0);
                }

                if(record.InquiryUnit__c == 99){
                    record.InquiryQuantity__c = newQuantityValue;
                    record.Quantity_lb__c = newQuantityValue;
                    record.Quantity = (record.Quantity_lb__c / 2204.62).toFixed(3);
                    record.Quantity_m__c = (record.Quantity / (0.001*Weight_kpm)).toFixed(2);
                    record.Quantity_ft__c = (record.Quantity_lb__c/Weight_ppf).toFixed(2);
                    record.Quantity_pcs__c = (record.Quantity_m__c / (LengthMax_mm/1000)).toFixed(0);
                                                                                      
                }

                if(record.InquiryUnit__c == 20){
                    record.InquiryQuantity__c = newQuantityValue;
                    record.Quantity_m__c = newQuantityValue;
                    record.Quantity_pcs__c = (newQuantityValue / (LengthMax_mm/1000)).toFixed(0);                  
                    record.Quantity_ft__c = (newQuantityValue / 0.3048).toFixed(2);

                    if(Weight_kpm!=0 && Weight_kpm != undefined){
                    record.Quantity = (newQuantityValue * (0.001 * Weight_kpm)).toFixed(3);
                    record.Quantity_lb__c = (record.Quantity * 2204.62).toFixed(2);
                    } else if(Weight_ppf != 0 && Weight_ppf != undefined){
                    record.Quantity_lb__c = (record.Quantity_ft__c*Weight_ppf).toFixed(2);
                    record.Quantity = (record.Quantity_lb__c/2204.62).toFixed(2);
                    } else {
                        record.Quantity_lb__c = 0;
                        record.Quantity = 0.01;
                    }
                }

                if(record.InquiryUnit__c == 74){
                    record.InquiryQuantity__c = newQuantityValue;
                    record.Quantity_ft__c = newQuantityValue;
                    record.Quantity_pcs__c = ((record.Quantity_ft__c * 0.3048) / (LengthMax_mm/1000)).toFixed(0);
                   
                    record.Quantity_m__c =  (record.Quantity_ft__c * 0.3048).toFixed(2);
                    

                    if(Weight_kpm!=0 && Weight_kpm != undefined){
                        record.Quantity = ((record.Quantity_ft__c * 0.3048) * (0.001 * Weight_kpm)).toFixed(3);
                        record.Quantity_lb__c = ((record.Quantity_ft__c*0.3048) * (0.001*Weight_kpm) * 2204.62).toFixed(2);
                        } else if(Weight_ppf != 0 && Weight_ppf != undefined){
                        record.Quantity_lb__c = (newQuantityValue*Weight_ppf).toFixed(2);
                        record.Quantity = (record.Quantity_lb__c/2204.62).toFixed(2);
                        } else {
                            record.Quantity_lb__c = 0;
                            record.Quantity = 0.01;
                        }                                      
                }

                if(record.InquiryUnit__c == 43){
                    record.InquiryQuantity__c = newQuantityValue;
                    record.Quantity_pcs__c = newQuantityValue;                   
                    record.Quantity_m__c =  (record.Quantity_pcs__c * (LengthMax_mm/1000)).toFixed(2);                    
                    record.Quantity_ft__c = (record.Quantity_m__c/ 0.3048).toFixed(2);                   
                    //record.Quantity = (record.Quantity_m__c * (Weight_kpm*0.001)).toFixed(3);
                    //record.Quantity_lb__c = (record.Quantity * 2204.62).toFixed(2); 
                    
                    if(Weight_kpm!=0 && Weight_kpm != undefined){
                        record.Quantity = (record.Quantity_m__c * (0.001 * Weight_kpm)).toFixed(3);
                        record.Quantity_lb__c = (record.Quantity * 2204.62).toFixed(2);
                        } else if(Weight_ppf != 0 && Weight_ppf != undefined){
                        record.Quantity_lb__c = (record.Quantity_ft__c*Weight_ppf).toFixed(2);
                        record.Quantity = (record.Quantity_lb__c/2204.62).toFixed(2);
                        } else {
                            record.Quantity_lb__c = 0;
                            record.Quantity = 0.01;
                        }  
                }
                
                makeChangesInRecord(record);

            } 
               if( quantityPerMChanged){
                lastQuantityUpdate = 'per M';
                let Weight_kpm = record.Weight_kpm__c;
                let Weight_ppf = record.Weight_ppf__c;
                let LengthMin_mm = record.LengthMin_mm__c;
                let LengthMax_mm = record.LengthMax_mm__c;
                let DENSITY_KG_M = Weight_kpm;
                let DENSITY_LB_FT = Weight_ppf;
                
                record.Quantity_m__c = newQuantityPerM;
                record.Quantity_pcs__c = (record.Quantity_m__c / (LengthMax_mm/1000)).toFixed(0);
                //record.Quantity = (record.Quantity_m__c * (0.001*Weight_kpm)).toFixed(3);
                //record.Quantity_lb__c = (record.Quantity * 2204.62).toFixed(2);
                record.Quantity_ft__c = (record.Quantity_m__c / 0.3048).toFixed(2);

                if(Weight_kpm!=0 && Weight_kpm != undefined){
                    record.Quantity = (record.Quantity_m__c * (0.001 * Weight_kpm)).toFixed(3);
                    record.Quantity_lb__c = (record.Quantity * 2204.62).toFixed(2);
                    } else if(Weight_ppf != 0 && Weight_ppf != undefined){
                    record.Quantity_lb__c = (record.Quantity_ft__c*Weight_ppf).toFixed(2);
                    record.Quantity = (record.Quantity_lb__c/2204.62).toFixed(2);
                    } else {
                        record.Quantity_lb__c = 0;
                        record.Quantity = 0.01;
                    }
                //ft
                if(record.InquiryUnit__c == 74){                    
                    record.InquiryQuantity__c =  record.Quantity_ft__c;                                                                                       
                }
                //t
                if(record.InquiryUnit__c == 34){                    
                    record.InquiryQuantity__c =  record.Quantity;                                                                                       
                }
                //lb
                if(record.InquiryUnit__c == 99){                   
                    record.InquiryQuantity__c =  record.Quantity_lb__c;                                                                                       
                }
                //m
                if(record.InquiryUnit__c == 20){                    
                    record.InquiryQuantity__c =  record.Quantity_m__c;                                                                                       
                }
                //pcs
                if(record.InquiryUnit__c == 43){                    
                    record.InquiryQuantity__c =  record.Quantity_pcs__c;                                                                                       
                }
                makeChangesInRecord(record);
            }
            if(quantityPerFtChanged){
                lastQuantityUpdate = 'per Ft';
                let Weight_kpm = record.Weight_kpm__c;
                let Weight_ppf = record.Weight_ppf__c;
                let LengthMin_mm = record.LengthMin_mm__c;
                let LengthMax_mm = record.LengthMax_mm__c;
                let DENSITY_KG_M = Weight_kpm;
                let DENSITY_LB_FT = Weight_ppf;

                record.Quantity_ft__c = newQuantityPerFt;
                record.Quantity_m__c = (record.Quantity_ft__c * 0.3048).toFixed(2);
                record.Quantity_pcs__c = (record.Quantity_m__c / (LengthMax_mm/1000)).toFixed(0);
               // record.Quantity = (record.Quantity_m__c * (0.001*Weight_kpm)).toFixed(3);
               // record.Quantity_lb__c = (record.Quantity * 2204.62).toFixed(2);

                if(Weight_kpm!=0 && Weight_kpm != undefined){
                    record.Quantity = ((record.Quantity_ft__c * 0.3048) * (0.001 * Weight_kpm)).toFixed(3);
                    record.Quantity_lb__c = (record.Quantity * 2204.62).toFixed(2);
                    } else if(Weight_ppf != 0 && Weight_ppf != undefined){
                    record.Quantity_lb__c = (record.Quantity_ft__c*Weight_ppf).toFixed(2);
                    record.Quantity = (record.Quantity_lb__c/2204.62).toFixed(2);
                    } else {
                        record.Quantity_lb__c = 0;
                        record.Quantity = 0.01;
                    }

                //ft
                if(record.InquiryUnit__c == 74){                    
                    record.InquiryQuantity__c =  record.Quantity_ft__c;                                                                                       
                }
                //t
                if(record.InquiryUnit__c == 34){                    
                    record.InquiryQuantity__c =  record.Quantity;                                                                                       
                }
                //lb
                if(record.InquiryUnit__c == 99){                   
                    record.InquiryQuantity__c =  record.Quantity_lb__c;                                                                                       
                }
                //m
                if(record.InquiryUnit__c == 20){                    
                    record.InquiryQuantity__c =  record.Quantity_m__c;                                                                                       
                }
                //pcs
                if(record.InquiryUnit__c == 43){                    
                    record.InquiryQuantity__c =  record.Quantity_pcs__c;                                                                                       
                }
                makeChangesInRecord(record);
            } 
            if(quantityPerLbChanged){
                lastQuantityUpdate = 'per Lb';
                
                let Weight_kpm = record.Weight_kpm__c;
                let Weight_ppf = record.Weight_ppf__c;
                let LengthMin_mm = record.LengthMin_mm__c;
                let LengthMax_mm = record.LengthMax_mm__c;
                let DENSITY_KG_M = Weight_kpm;
                let DENSITY_LB_FT = Weight_ppf;

                record.Quantity_lb__c = newQuantityPerLb;
                record.Quantity = (record.Quantity_lb__c / 2204.62).toFixed(3);
                record.Quantity_m__c = (record.Quantity / (0.001*Weight_kpm)).toFixed(2);
                record.Quantity_ft__c = (record.Quantity_lb__c/Weight_ppf).toFixed(2);
                record.Quantity_pcs__c = (record.Quantity_m__c / (LengthMax_mm/1000)).toFixed(0);

                //ft
                if(record.InquiryUnit__c == 74){                    
                    record.InquiryQuantity__c =  record.Quantity_ft__c;                                                                                       
                }
                //t
                if(record.InquiryUnit__c == 34){                    
                    record.InquiryQuantity__c =  record.Quantity;                                                                                       
                }
                //lb
                if(record.InquiryUnit__c == 99){                   
                    record.InquiryQuantity__c =  record.Quantity_lb__c;                                                                                       
                }
                //m
                if(record.InquiryUnit__c == 20){                    
                    record.InquiryQuantity__c =  record.Quantity_m__c;                                                                                       
                }
                //pcs
                if(record.InquiryUnit__c == 43){                    
                    record.InquiryQuantity__c =  record.Quantity_pcs__c;                                                                                       
                }

                makeChangesInRecord(record);
                
            } if (quantityPerPcsChanged){
                lastQuantityUpdate = 'per Pcs';
                let Weight_kpm = record.Weight_kpm__c;
                let Weight_ppf = record.Weight_ppf__c;
                let LengthMin_mm = record.LengthMin_mm__c;
                let LengthMax_mm = record.LengthMax_mm__c;
                let DENSITY_KG_M = Weight_kpm;
                let DENSITY_LB_FT = Weight_ppf;
                
                record.Quantity_pcs__c = newQuantityPerPcs;          
                record.Quantity_m__c =  record.Quantity_pcs__c * (LengthMax_mm/1000);            
                record.Quantity_ft__c = record.Quantity_m__c/ 0.3048;               
                //record.Quantity = record.Quantity_m__c * (Weight_kpm*0.001);
                //record.Quantity_lb__c = record.Quantity * 2204.62; 
                
                if(Weight_kpm!=0 && Weight_kpm != undefined){
                    record.Quantity = (record.Quantity_m__c * (0.001 * Weight_kpm)).toFixed(3);
                    record.Quantity_lb__c = (record.Quantity * 2204.62).toFixed(2);
                    } else if(Weight_ppf != 0 && Weight_ppf != undefined){
                    record.Quantity_lb__c = (record.Quantity_ft__c*Weight_ppf).toFixed(2);
                    record.Quantity = (record.Quantity_lb__c/2204.62).toFixed(2);
                    } else {
                        record.Quantity_lb__c = 0;
                        record.Quantity = 0.01;
                    }  

                //ft
                if(record.InquiryUnit__c == 74){                    
                    record.InquiryQuantity__c =  record.Quantity_ft__c;                                                                                       
                }
                //t
                if(record.InquiryUnit__c == 34){                    
                    record.InquiryQuantity__c =  record.Quantity;                                                                                       
                }
                //lb
                if(record.InquiryUnit__c == 99){                   
                    record.InquiryQuantity__c =  record.Quantity_lb__c;                                                                                       
                }
                //m
                if(record.InquiryUnit__c == 20){                    
                    record.InquiryQuantity__c =  record.Quantity_m__c;                                                                                       
                }
                //pcs
                if(record.InquiryUnit__c == 43){                    
                    record.InquiryQuantity__c =  record.Quantity_pcs__c;                                                                                       
                }

                makeChangesInRecord(record);

            } if(quantityPerTChanged){
                lastQuantityUpdate = 'per T';
                
                let Weight_kpm = record.Weight_kpm__c;
                let Weight_ppf = record.Weight_ppf__c;
                let LengthMin_mm = record.LengthMin_mm__c;
                let LengthMax_mm = record.LengthMax_mm__c;
                let DENSITY_KG_M = Weight_kpm;
                let DENSITY_LB_FT = Weight_ppf;

                record.Quantity = newQuantityPerT;
                record.Quantity_lb__c = (record.Quantity * 2204.62).toFixed(2); 

                if(Weight_kpm!=0 && Weight_kpm != undefined){
                record.Quantity_m__c = (record.Quantity / (0.001*Weight_kpm)).toFixed(2);
                record.Quantity_ft__c = (record.Quantity_m__c/0.3048).toFixed(2);
                record.Quantity_pcs__c = (record.Quantity_m__c/(LengthMax_mm/1000)).toFixed(0);
                } else if(Weight_ppf != 0 && Weight_ppf != undefined){    
                record.Quantity_ft__c = (record.Quantity_lb__c / Weight_ppf).toFixed(2);
                record.Quantity_m__c = (record.Quantity_ft__c/0.3048).toFixed(2);
                record.Quantity_pcs__c = (record.Quantity_m__c/(LengthMax_mm/1000)).toFixed(0);
                }else {
                    record.Quantity_ft__c =0;
                    record.Quantity_m__c = 0;
                    record.Quantity_pcs__c = 0;
                }  

                //ft
                if(record.InquiryUnit__c == 74){                    
                    record.InquiryQuantity__c =  record.Quantity_ft__c;                                                                                       
                }
                //t
                if(record.InquiryUnit__c == 34){                    
                    record.InquiryQuantity__c =  record.Quantity;                                                                                       
                }
                //lb
                if(record.InquiryUnit__c == 99){                   
                    record.InquiryQuantity__c =  record.Quantity_lb__c;                                                                                       
                }
                //m
                if(record.InquiryUnit__c == 20){                    
                    record.InquiryQuantity__c =  record.Quantity_m__c;                                                                                       
                }
                //pcs
                if(record.InquiryUnit__c == 43){                    
                    record.InquiryQuantity__c =  record.Quantity_pcs__c;                                                                                       
                }   

                makeChangesInRecord(record);
              
                //console.log(updatedRecArra)  ;  
            } if(priceInquiryChanged){
                
                record.InquiryUnitPrice__c	 = newSalesPricePerUnit;
                let QuantityValue = record.InquiryQuantity__c;
                let Weight_kpm = record.Weight_kpm__c;
                let Weight_ppf = record.Weight_ppf__c;
                let LengthMin_mm = record.LengthMin_mm__c;
                let LengthMax_mm = record.LengthMax_mm__c;
                let DENSITY_KG_M = Weight_kpm;
                let DENSITY_LB_FT = Weight_ppf;

                if(record.InquiryUnit__c == 20){
                    
                                        
                    record.Sales_Price_m__c = record.InquiryUnitPrice__c;
                    record.Sales_Price_ft__c = (record.Sales_Price_m__c * 0.3048).toFixed(2);
                    record.Sales_Price_pcs__c = (record.Sales_Price_m__c * (LengthMax_mm/1000)).toFixed(2);
                    //record.Sales_Price_lb__c = (record.Sales_Price_ft__c/Weight_ppf).toFixed(2);
                   // record.UnitPrice = (record.Sales_Price_lb__c * 2204.62).toFixed(2);  
                   // record.UnitPrice = ((record.Quantity_m__c * record.Sales_Price_m__c)/record.Quantity ).toFixed(2); 
                   if(Weight_kpm!=0 && Weight_kpm != undefined){
                     record.UnitPrice = (record.Sales_Price_m__c/(0.001*Weight_kpm)).toFixed(2);
                     record.Sales_Price_lb__c = (record.UnitPrice / 2204.62).toFixed(2);
                   } else if (Weight_ppf != 0 && Weight_ppf != undefined){
                       record.Sales_Price_lb__c = (record.Sales_Price_ft__c/Weight_ppf).toFixed(2);
                       record.UnitPrice = (record.Sales_Price_lb__c * 2204.62).toFixed(2);
                   } else {
                    record.UnitPrice = 0.01;
                    record.Sales_Price_lb__c = 0.01;
                   }
                }

                if(record.InquiryUnit__c == 43){
                    record.Sales_Price_pcs__c = record.InquiryUnitPrice__c;
                    //record.UnitPrice = ((record.Sales_Price_pcs__c*record.Quantity_pcs__c)/record.Quantity).toFixed(2);
                    console.log(LengthMax_mm +  ' ' +record.Sales_Price_pcs__c + ' '+ Weight_kpm )
                    record.UnitPrice = (record.Sales_Price_pcs__c/((LengthMax_mm/1000)*(0.001*Weight_kpm))).toFixed(2);
                    record.Sales_Price_m__c = (record.Sales_Price_pcs__c / (LengthMax_mm/1000)).toFixed(2);
                    record.Sales_Price_ft__c = (record.Sales_Price_m__c * 0.3048).toFixed(2);
                    record.Sales_Price_lb__c = (record.UnitPrice / 2204.62).toFixed(2);
                    
                }

                if(record.InquiryUnit__c == 34) {
                    record.UnitPrice = record.InquiryUnitPrice__c ;
                    
                    record.Sales_Price_lb__c = (record.UnitPrice / 2204.62).toFixed(2);

                    if(Weight_kpm!=0 && Weight_kpm != undefined){
                        record.Sales_Price_m__c = (record.UnitPrice * (DENSITY_KG_M/1000)).toFixed(2);
                        record.Sales_Price_ft__c = (record.Sales_Price_m__c * 0.3048).toFixed(2);
                    } else if(Weight_ppf != 0 && Weight_ppf != undefined){
                        record.Sales_Price_ft__c = (record.Sales_Price_lb__c*DENSITY_LB_FT).toFixed(2);
                        record.Sales_Price_m__c = (record.Sales_Price_ft__c / 0.3048).toFixed(2);
                    } else {
                        record.Sales_Price_ft__c = 0;
                        record.Sales_Price_m__c = 0;
                    }  
                    record.Sales_Price_pcs__c = (record.Sales_Price_m__c * (LengthMax_mm/1000)).toFixed(2);                   
                }

                if(record.InquiryUnit__c == 99) {
                    record.Sales_Price_lb__c = record.InquiryUnitPrice__c;
                    record.UnitPrice = (record.Sales_Price_lb__c * 2204.62).toFixed(2);
                    //record.Sales_Price_ft__c = (record.Sales_Price_lb__c *  Weight_ppf).toFixed(2);
                    //record.Sales_Price_m__c = (record.Sales_Price_ft__c / 0.3048).toFixed(2);
                    //record.Sales_Price_pcs__c = (record.Sales_Price_m__c * LengthMax_mm/1000).toFixed(2);
                    if(Weight_kpm!=0 && Weight_kpm != undefined){
                        record.Sales_Price_m__c = (record.UnitPrice * (DENSITY_KG_M/1000)).toFixed(2);
                        record.Sales_Price_ft__c = (record.Sales_Price_m__c * 0.3048).toFixed(2);
                    } else if(Weight_ppf != 0 && Weight_ppf != undefined){
                        record.Sales_Price_ft__c = (record.Sales_Price_lb__c*DENSITY_LB_FT).toFixed(2);
                        record.Sales_Price_m__c = (record.Sales_Price_ft__c / 0.3048).toFixed(2);
                    } else {
                        record.Sales_Price_ft__c = 0;
                        record.Sales_Price_m__c = 0;
                    }  
                    record.Sales_Price_pcs__c = (record.Sales_Price_m__c * (LengthMax_mm/1000)).toFixed(2);    
                }

                if(record.InquiryUnit__c == 74) {
                    
                    record.Sales_Price_ft__c = record.InquiryUnitPrice__c;
                   // record.UnitPrice = (record.Sales_Price_ft__c*record.Quantity_ft__c/record.Quantity).toFixed(2) ;
                    record.Sales_Price_m__c = (record.Sales_Price_ft__c / 0.3048).toFixed(2);
                    //record.Sales_Price_lb__c = (record.UnitPrice / 2204.62).toFixed(2);
                    //record.Sales_Price_pcs__c = ((record.Sales_Price_ft__c / 0.3048) * (LengthMax_mm/1000)).toFixed(2);
                    //record.Sales_Price_pcs__c = ((record.Sales_Price_m__c*record.Quantity_m__c)/Quantity_pcs__c).toFixed(2);  
                    record.Sales_Price_pcs__c = (record.Sales_Price_m__c * (LengthMax_mm/1000)).toFixed(2); 
                    if(Weight_kpm!=0 && Weight_kpm != undefined){
                        record.UnitPrice = (record.Sales_Price_m__c/(0.001*Weight_kpm)).toFixed(2);
                        record.Sales_Price_lb__c = (record.UnitPrice / 2204.62).toFixed(2);
                      } else if (Weight_ppf != 0 && Weight_ppf != undefined){
                        record.Sales_Price_lb__c = (record.Sales_Price_ft__c/Weight_ppf).toFixed(2);
                        record.UnitPrice = (record.Sales_Price_lb__c * 2204.62).toFixed(2);
                      } else {
                       record.UnitPrice = 0.01;
                       record.Sales_Price_lb__c = 0.01;
                    }  
                }

                makeChangesInRecord(record);
            } if (pricePerLbChanged){
                lastSaleUpdate = 'per Lb';
                
                //console.log(newSalesPricePerLb);
                let Weight_kpm = record.Weight_kpm__c;
                let Weight_ppf = record.Weight_ppf__c;
                let LengthMin_mm = record.LengthMin_mm__c;
                let LengthMax_mm = record.LengthMax_mm__c;
                let DENSITY_KG_M = Weight_kpm;
                let DENSITY_LB_FT = Weight_ppf;

                    record.Sales_Price_lb__c = newSalesPricePerLb;
                    //record.UnitPrice = (record.Sales_Price_lb__c * 2204.62).toFixed(2);
                    //record.Sales_Price_ft__c = (record.Sales_Price_lb__c *  Weight_ppf).toFixed(2);
                    //record.Sales_Price_m__c = (record.Sales_Price_ft__c / 0.3048).toFixed(2);
                    //record.Sales_Price_pcs__c = (record.Sales_Price_m__c * (LengthMax_mm/1000)).toFixed(2);
                    record.UnitPrice = (record.Sales_Price_lb__c * 2204.62).toFixed(2);                   
                    if(Weight_kpm!=0 && Weight_kpm != undefined){
                        record.Sales_Price_m__c = (record.UnitPrice * (DENSITY_KG_M/1000)).toFixed(2);
                        record.Sales_Price_ft__c = (record.Sales_Price_m__c * 0.3048).toFixed(2);
                    } else if(Weight_ppf != 0 && Weight_ppf != undefined){
                        record.Sales_Price_ft__c = (record.Sales_Price_lb__c*DENSITY_LB_FT).toFixed(2);
                        record.Sales_Price_m__c = (record.Sales_Price_ft__c / 0.3048).toFixed(2);
                    } else {
                        record.Sales_Price_ft__c = 0;
                        record.Sales_Price_m__c = 0;
                    }  
                    record.Sales_Price_pcs__c = (record.Sales_Price_m__c * (LengthMax_mm/1000)).toFixed(2);
                //m
                if(record.InquiryUnit__c == 20){                                     
                    record.InquiryUnitPrice__c = record.Sales_Price_m__c;
                }
                //ft
                if(record.InquiryUnit__c == 74){              
                    record.InquiryUnitPrice__c = record.Sales_Price_ft__c;                
                }

                //t
                if(record.InquiryUnit__c == 34){          
                    record.InquiryUnitPrice__c = record.UnitPrice;
                }

                //pcs
                if(record.InquiryUnit__c == 43){             
                    record.InquiryUnitPrice__c = record.Sales_Price_pcs__c;
                }

                //lb
                if(record.InquiryUnit__c == 99){           
                    record.InquiryUnitPrice__c =  record.Sales_Price_lb__c;  
                }
                
                makeChangesInRecord(record);

            } if(pricePerFtChanged){
                lastSaleUpdate = 'per Ft';
                let Weight_kpm = record.Weight_kpm__c;
                let Weight_ppf = record.Weight_ppf__c;
                let LengthMin_mm = record.LengthMin_mm__c;
                let LengthMax_mm = record.LengthMax_mm__c;
                let DENSITY_KG_M = Weight_kpm;
                let DENSITY_LB_FT = Weight_ppf;


                //console.log('newSalesPricePerFt');            
                record.Sales_Price_ft__c = newSalesPricePerFt;           
                //record.Sales_Price_m__c = (record.Sales_Price_ft__c/0.3048).toFixed(2);
                //record.Sales_Price_lb__c = (record.Sales_Price_ft__c/Weight_ppf).toFixed(2);
                //record.UnitPrice = (record.Sales_Price_lb__c * 2204.62).toFixed(2);
                //record.Sales_Price_pcs__c = (record.Sales_Price_m__c*(LengthMax_mm/1000)).toFixed(2);
                record.Sales_Price_m__c = (record.Sales_Price_ft__c / 0.3048).toFixed(2);                 
                record.Sales_Price_pcs__c = (record.Sales_Price_m__c * (LengthMax_mm/1000)).toFixed(2); 
                if(Weight_kpm!=0 && Weight_kpm != undefined){
                    record.UnitPrice = (record.Sales_Price_m__c/(0.001*Weight_kpm)).toFixed(2);
                    record.Sales_Price_lb__c = (record.UnitPrice / 2204.62).toFixed(2);
                  } else if (Weight_ppf != 0 && Weight_ppf != undefined){
                    record.Sales_Price_lb__c = (record.Sales_Price_ft__c/Weight_ppf).toFixed(2);
                    record.UnitPrice = (record.Sales_Price_lb__c * 2204.62).toFixed(2);
                  } else {
                    
                   record.UnitPrice = 0.01;
                   record.Sales_Price_lb__c = 0.01;
                }  
                
                if(record.InquiryUnit__c == 20){               
                    record.InquiryUnitPrice__c =  record.Sales_Price_m__c;               
                }

                if(record.InquiryUnit__c == 34){
                   
                    record.InquiryUnitPrice__c =  record.UnitPrice;
                }

                if(record.InquiryUnit__c == 43){
                    
                    record.InquiryUnitPrice__c =   record.Sales_Price_pcs__c;
                }

                if(record.InquiryUnit__c == 99){
                   
                    record.InquiryUnitPrice__c =   record.Sales_Price_lb__c;
                }

                if(record.InquiryUnit__c == 74){
                   
                    record.InquiryUnitPrice__c = record.Sales_Price_ft__c;
                }

                makeChangesInRecord(record);
            } 
            if(pricePerMChanged){
                lastSaleUpdate = 'per M';
                let Weight_kpm = record.Weight_kpm__c;
                let Weight_ppf = record.Weight_ppf__c;
                let LengthMin_mm = record.LengthMin_mm__c;
                let LengthMax_mm = record.LengthMax_mm__c;
                let DENSITY_KG_M = Weight_kpm;
                let DENSITY_LB_FT = Weight_ppf;

                //console.log('Sales_Price_m__c changed');
                    record.Sales_Price_m__c = newSalesPricePerM;
                    //record.Sales_Price_ft__c = (record.Sales_Price_m__c * 0.3048).toFixed(2);
                    //record.Sales_Price_pcs__c = (record.Sales_Price_m__c * (LengthMax_mm/1000)).toFixed(2);
                    //record.Sales_Price_lb__c = (record.Sales_Price_ft__c/Weight_ppf).toFixed(2);
                   // record.UnitPrice = (record.Sales_Price_lb__c * 2204.62).toFixed(2);
                   record.Sales_Price_ft__c = (record.Sales_Price_m__c * 0.3048).toFixed(2);
                   record.Sales_Price_pcs__c = (record.Sales_Price_m__c * (LengthMax_mm/1000)).toFixed(2);                 
                  if(Weight_kpm!=0 && Weight_kpm != undefined){
                    record.UnitPrice = (record.Sales_Price_m__c/(0.001*Weight_kpm)).toFixed(2);
                    record.Sales_Price_lb__c = (record.UnitPrice / 2204.62).toFixed(2);
                  } else if (Weight_ppf != 0 && Weight_ppf != undefined){
                      record.Sales_Price_lb__c = (record.Sales_Price_ft__c/Weight_ppf).toFixed(2);
                      record.UnitPrice = (record.Sales_Price_lb__c * 2204.62).toFixed(2);
                  } else {
                   record.UnitPrice = 0.01;
                   record.Sales_Price_lb__c = 0.01;
                  }
                //ft
                if(record.InquiryUnit__c == 74){
                    record.InquiryUnitPrice__c = record.Sales_Price_ft__c;                             
                }

                //t
                if(record.InquiryUnit__c == 34){        
                    record.InquiryUnitPrice__c = record.UnitPrice;
                }

                //pcs
                if(record.InquiryUnit__c == 43){           
                    record.InquiryUnitPrice__c = record.Sales_Price_pcs__c;
                }

                //lb
                if(record.InquiryUnit__c == 99){      
                    record.InquiryUnitPrice__c = record.Sales_Price_lb__c; 
                }

                //m
                if(record.InquiryUnit__c == 20){           
                    record.InquiryUnitPrice__c = record.Sales_Price_m__c;                 
                }

                makeChangesInRecord(record);

            }
            if(pricePerPcshanged){
                lastSaleUpdate = 'per Pcs';
                let Weight_kpm = record.Weight_kpm__c;
                let Weight_ppf = record.Weight_ppf__c;
                let LengthMin_mm = record.LengthMin_mm__c;
                let LengthMax_mm = record.LengthMax_mm__c;
                let DENSITY_KG_M = Weight_kpm;
                let DENSITY_LB_FT = Weight_ppf;

                    record.Sales_Price_pcs__c = newSalesPricePerPcs;
                    //record.Sales_Price_m__c = (record.Sales_Price_pcs__c / (LengthMax_mm/1000)).toFixed(2);
                    //record.Sales_Price_ft__c = (record.Sales_Price_m__c * 0.3048).toFixed(2);
                   // record.Sales_Price_lb__c = (record.Sales_Price_ft__c/Weight_ppf).toFixed(2);
                   // record.UnitPrice = (record.Sales_Price_lb__c * 2204.62).toFixed(2);
                    record.UnitPrice = ((record.Sales_Price_pcs__c*record.Quantity_pcs__c)/record.Quantity).toFixed(2);
                    record.Sales_Price_m__c = (record.Sales_Price_pcs__c / (LengthMax_mm/1000)).toFixed(2);
                    record.Sales_Price_ft__c = (record.Sales_Price_m__c * 0.3048).toFixed(2);
                    record.Sales_Price_lb__c = (record.UnitPrice / 2204.62).toFixed(2);
                //ft
                if(record.InquiryUnit__c == 74){                
                record.InquiryUnitPrice__c = record.Sales_Price_ft__c;                                                       
                }

                //t
                if(record.InquiryUnit__c == 34){                   
                    record.InquiryUnitPrice__c = record.UnitPrice;                   
                }

                //lb
                if(record.InquiryUnit__c == 99){            
                    record.InquiryUnitPrice__c =record.Sales_Price_lb__c; 
                }

                //m
                if(record.InquiryUnit__c == 20){              
                    record.InquiryUnitPrice__c = record.Sales_Price_m__c;                 
                }

                 //pcs
                 if(record.InquiryUnit__c == 43){           
                    record.InquiryUnitPrice__c = record.Sales_Price_pcs__c;
                }

                makeChangesInRecord(record);
            } if( unitPricePerTchanged){
                lastSaleUpdate = 'per T';
                
                let Weight_kpm = record.Weight_kpm__c;
                let Weight_ppf = record.Weight_ppf__c;
                let LengthMin_mm = record.LengthMin_mm__c;
                let LengthMax_mm = record.LengthMax_mm__c;
                let DENSITY_KG_M = Weight_kpm;
                let DENSITY_LB_FT = Weight_ppf;

                    record.UnitPrice = newSalesPricePerT;
                    //record.Sales_Price_m__c =( record.UnitPrice * (Weight_kpm*0.001)).toFixed(2);
                    //record.Sales_Price_ft__c = (record.Sales_Price_m__c * 0.3048).toFixed(2);
                   // record.Sales_Price_lb__c = (record.UnitPrice / 2204.62).toFixed(2);
                   // record.Sales_Price_pcs__c = (record.Sales_Price_m__c * (LengthMax_mm/1000)).toFixed(2);                                    
                   record.Sales_Price_lb__c = (record.UnitPrice / 2204.62).toFixed(2);
                    if(Weight_kpm!=0 && Weight_kpm != undefined){
                        record.Sales_Price_m__c = (record.UnitPrice * (DENSITY_KG_M/1000)).toFixed(2);
                        record.Sales_Price_ft__c = (record.Sales_Price_m__c * 0.3048).toFixed(2);
                    } else if(Weight_ppf != 0 && Weight_ppf != undefined){
                        record.Sales_Price_ft__c = (record.Sales_Price_lb__c*DENSITY_LB_FT).toFixed(2);
                        record.Sales_Price_m__c = (record.Sales_Price_ft__c / 0.3048).toFixed(2);
                    } else {
                        record.Sales_Price_ft__c = 0;
                        record.Sales_Price_m__c = 0;
                    }  
                    record.Sales_Price_pcs__c = (record.Sales_Price_m__c * (LengthMax_mm/1000)).toFixed(2);  
                 //ft
                 if(record.InquiryUnit__c == 74){
                    record.InquiryUnitPrice__c  = record.Sales_Price_ft__c;                                                     
                }

                //t
                if(record.InquiryUnit__c == 34){   
                    record.InquiryUnitPrice__c = record.UnitPrice;     
                }

                //lb
                if(record.InquiryUnit__c == 99){          
                    record.InquiryUnitPrice__c =record.Sales_Price_lb__c; 
                }

                //m
                if(record.InquiryUnit__c == 20){              
                    record.InquiryUnitPrice__c = record.Sales_Price_m__c;                 
                }

                //pcs
                if(record.InquiryUnit__c == 43){  
                    record.InquiryUnitPrice__c = record.Sales_Price_pcs__c;
                }

                makeChangesInRecord(record);
            }
        
        
        if(changeQuantityTimes>1 && !alertQuantityShow){
                alertQuantityShow = true;
                alert('You changed quantity for two and more units. Quantity was calculated by ' + lastQuantityUpdate);
            }
            if(changeSalesTimes>1 && !alertSaleShow){
                alertSaleShow = true;  
                alert('You changed sale price for two and more units. Sale price was calculated by ' + lastSaleUpdate);
            }

        }
        
        this.records = updatedRecArra;
        this.updatedRecords = updatedRecArra.map(a => ({...a}));;
        //console.log('updatedRecArra');
        //console.log(updatedRecArra);    
        this.disableSaveButton = false;
        if(this.arrayForSave.length == 0){           
            this.arrayForSave = [...changedOriginal];
            this.changedValues = []
        } else {
            
            this.arrayForSave = this.arrayForSave.concat(changedOriginal);
            this.changedValues = [];
            
        }
        changedOriginal = [];
               
    }
}