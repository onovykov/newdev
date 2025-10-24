import { LightningElement, wire } from 'lwc';
import XLSX from '@salesforce/resourceUrl/XLSX';
import { loadScript } from 'lightning/platformResourceLoader';
import getImportSettings from '@salesforce/apex/excelImportController.getImportSettings';
import insertRecords from '@salesforce/apex/excelImportController.insertRecords'
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
//import deleteExsistingRecords from '@salesforce/apex/ExcelImportController.deleteExsistingRecords';

// import OBJECT_NAME_FIELD from '@salesforce/schema/Excel_Import_Setting__c.Object_Name__c';
// import SHEET_NAME_FIELD from '@salesforce/schema/Excel_Import_Setting__c.Sheet_Name__c';
// import SHEET_COLUMNS_FIELD from '@salesforce/schema/Excel_Import_Setting__c.Sheet_Columns__c';

var OBJECT_NAME_FIELD = { fieldApiName: "Object_Name__c" };
var SHEET_NAME_FIELD = { fieldApiName: "Sheet_Name__c" };
var SHEET_COLUMNS_FIELD = { fieldApiName: "Sheet_Columns__c" };
var REQUIRED_FIELDS = { fieldApiName: "Required_Fields__c" };

const MAX_NUMBER_OF_ROWS_TO_DISPLAY = 30;
const MAX_NUMBER_ON_INSERT = 100000000;

export default class ExcelImport extends LightningElement {
    settings = [];
    showData = false;
    rowOffset = 0;
    error;
    workbookData = {};
    filteredWorkBookData = {};
    isLoading = false;
    dataFilters = {"TradeData" : [
            {label : "Year", fieldApiName : "Year__c", type : "text"}
        ]
    };

    @wire(getImportSettings)

    setSettings(result) {
        if (result.data) {
            this.settings = result.data;
            this.settings.forEach(setting => {
                this.workbookData[setting[SHEET_NAME_FIELD.fieldApiName]] = [];
            });
            console.log('settings ', JSON.parse(JSON.stringify(this.settings)));
        }
        if (result.error) {
            this.error = result.error;
        }
    }
    renderedCallback() {
        loadScript(this, XLSX);
    }

    handleFileSelect(event) {
        var files = event.target.files;
        event.target.disabled = true;
        var file = files[0];
        this.ExcelToJSON(file);
    }
    ExcelToJSON(file) {
        this.isLoading = true;
        const PRIMARY_KEY_FIELD_NAME = 'Primary_Key__c';
        var reader = new FileReader();
        reader.onload = event => {
            var data = event.target.result;
            var workbook = window.XLSX.read(data, {
                type: 'binary'
            });

            this.settings = this.settings.map(item => ({
                ...item,
                data: [],
                columns: [],
                requiredFields: []
            }));
            this.settings.map(item => {
                let data = window.XLSX.utils.sheet_to_row_object_array(workbook.Sheets[item[SHEET_NAME_FIELD.fieldApiName]]);
                console.log('data from excel ', data.length, data);
                let columns = JSON.parse(item[SHEET_COLUMNS_FIELD.fieldApiName]);
                let sheetName = item[SHEET_NAME_FIELD.fieldApiName];
                console.log(sheetName);
                let requiredFields = JSON.parse(item[REQUIRED_FIELDS.fieldApiName]);
                console.log('requiredFields ', requiredFields);

                data.forEach(dataItem => {

                    let PrimaryKey = '';

                    columns.forEach(columnItem => {

                        if (columnItem.label.toLowerCase().includes('date')) {
                            // console.log('++++++++++++', dataItem[columnItem.label]);
                            let dateData = dataItem[columnItem.label];
                            if (typeof dataItem[columnItem.label] == 'string') {

                                let dateData = dataItem[columnItem.label] + '';
                                let dateDataArr = dateData.split('.');
                                [dateDataArr[0], dateDataArr[1]] = [dateDataArr[1], dateDataArr[0]];
                                dateData = dateDataArr.join('.');
                                dataItem[columnItem.fieldName] = this.ExcelDateToJSDate(dateData);
                            } else {
                                dataItem[columnItem.fieldName] = this.ExcelDateToJSDate(dateData);
                            }

                            //console.log('------------', dataItem[columnItem.fieldName]);
                        } else {
                            dataItem[columnItem.fieldName] = dataItem[columnItem.label];
                        }

                        if (dataItem[columnItem.fieldName] === 'N/A') {
                            dataItem[columnItem.fieldName] = '';
                        }

                        if (columnItem.fieldName == 'OD_mm__c') {
                            dataItem[columnItem.fieldName] += '';
                        }

                        if (columnItem.fieldName == 'Steel_grade__c') {
                            dataItem[columnItem.fieldName] += '';
                        }
                        
                        // if (true) {
                        //     dataItem[columnItem.fieldName] += '';
                        // }

                        if (requiredFields.includes(columnItem.fieldName)) {
                            PrimaryKey += dataItem[columnItem.fieldName];
                        }

                        delete dataItem[columnItem.label];
                    });

                    dataItem[PRIMARY_KEY_FIELD_NAME] = PrimaryKey;
                });
                this.workbookData[sheetName] = data;
                //filter
                this.filteredWorkBookData[sheetName] = data;
                //filter end
                item.data = data.slice(0, MAX_NUMBER_OF_ROWS_TO_DISPLAY);
                item.columns = columns;
                item.objectApiName = item[OBJECT_NAME_FIELD.fieldApiName];
                item.sheetName = sheetName;
                //filter
                item.filters = this.dataFilters[sheetName];
                //filter end

                delete item[SHEET_COLUMNS_FIELD.fieldApiName];
                delete item[OBJECT_NAME_FIELD.fieldApiName];
                delete item[SHEET_NAME_FIELD.fieldApiName];

                console.log('data new', item.sheetName, item.data);
                return item;

            });
            this.isLoading = false;
            this.showData = true;
        };
        reader.onerror = function (ex) {
            this.error = ex;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error while reading the file',
                    message: ex.message,
                    variant: 'error',
                }),
            );
        };
        reader.readAsBinaryString(file);

    }

    //filter method, accepts filterValue, target sheet name, field api name from event (onchange event on input field)
    handleFilterFieldsChange(event) {
        let filterValue = event.target.value;
        let targetSheet = event.target.dataset.sheetname;
        let fieldApiName = event.target.dataset.fieldApiName;

        console.log('filterValue' , filterValue);

        this.filteredWorkBookData[targetSheet] = this.workbookData[targetSheet].filter(item => {
            return item[fieldApiName].toString().toLowerCase().includes(filterValue.toLowerCase());
        });
        
        this.settings = this.settings.map(setting => {
            if(setting.sheetName == targetSheet) {
                setting.data = this.filteredWorkBookData[targetSheet].slice(0,MAX_NUMBER_OF_ROWS_TO_DISPLAY);
            }
            return setting;
        });
    }

    handleSaveClick(event) {
        event.target.disabled = true;
        console.log(typeof (event.target.dataset.objectname), event.target.dataset.objectname);
        let objectApiName = event.target.dataset.objectname;
        console.log(event.target.dataset.sheetname);
        let sheetName = event.target.dataset.sheetname;
        //filter old -> this.workBookData[shetName].slice();
        let records = this.filteredWorkBookData[sheetName].slice();
        //filter end
        records.forEach(item => {
            item.sobjectType = objectApiName;
        });
        let recordsToInsert = records;
        console.log('records    ', records);
        if (recordsToInsert.length < MAX_NUMBER_ON_INSERT) {
            const event = new ShowToastEvent({
                "title": "Warning! Data transfer has started",
                "variant": "warning",
                "message": "Do not reload the page or close the tab",
                "mode": "dismissible"
            });
            this.dispatchEvent(event);

            let size = 5000;
            let recordsChunk = records.slice();

            function processChunks(i) {
                if (i < Math.ceil(recordsToInsert.length / size)) {

                    recordsChunk[i] = recordsToInsert.slice((i * size), (i * size) + size);
                    console.log('recordsChunk   ', recordsChunk[i]);
                    console.log("Count recordsChunk -1  ", Math.ceil(recordsToInsert.length / size) - 1);
                    console.log("Iterator   ", i);

                    insertRecords({ records: recordsChunk[i] })
                        .then(result => {
                            if (i === Math.ceil(records.length / size - 1)) {
                                console.log('result:  ', result);
                            }
                        })
                        .catch(e => {
                            this.error = e;
                            console.error(e);
                            console.error('e.name => ' + e.name);
                            console.error('e.message => ' + e.message);
                            console.error('e.stack => ' + e.stack);
                        });

                    setTimeout(processChunks.bind(this), 3000, ++i)
                    

                }
                else {
                    console.log('FINISH');

                    const event = new ShowToastEvent({
                        "title": "Success!",
                        "variant": "success",
                        "message": objectApiName + "  records have been sent for batch processing!",
                        "mode": "dismissible"
                    });

                    this.dispatchEvent(event);
                     
                    let buttons =this.template.querySelectorAll('[data-id="saveButton"]');

                    buttons.forEach(button =>{
                        button.disabled = false; 
                        console.log('button.disabled' , button.disabled );
                    });

                }
            }

            setTimeout(processChunks.bind(this), 3000, 0);


        }
        else {
            const event = new ShowToastEvent({
                "title": "You can not insert more than  " + MAX_NUMBER_ON_INSERT + "  rows!",
                "variant": "error",
                "message": "You are trying to insert " + records.length + " rows. " + "  Check your .xlsx file and try again.",
                "mode": "sticky"
            });
            this.dispatchEvent(event);
        }

    }

    ExcelDateToJSDate(serial) {
        let date_info;
        if (typeof serial == "string") {
            date_info = new Date(serial);

        } else {
            let utc_days = Math.floor(serial - 25569);
            let utc_value = utc_days * 86400;
            date_info = new Date(utc_value * 1000);
        }
        let month = (date_info.getMonth() + 1);
        let day = date_info.getDate();
        let finalDate = '' + date_info.getFullYear() + '-' + (month >= 10 ? month : ('0' + month)) + '-' + (day >= 10 ? day : ('0' + day));
        return finalDate;
        // return new Date(date_info.getFullYear(), date_info.getMonth(), date_info.getDate()).toISOString();
    }

}