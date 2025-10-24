import {LightningElement, api, wire, track} from 'lwc';
import getOrderById from '@salesforce/apex/orderDeliveryController.getOrderById';
import getCalloutResponseContents from '@salesforce/apex/orderDeliveryController.getCalloutResponseContents';
import ID_ERP_FIELD from '@salesforce/schema/Order.ID_ERP__c';
import ITENUMBER_FIELD from '@salesforce/schema/Order.ITENumber__c';
import sendEmail from '@salesforce/apex/orderDeliveryController.sendEmail';
import nonDeliveryInfo from '@salesforce/label/c.OrderDeliveryNonInfo';
import pickupMessage from '@salesforce/label/c.Self_Pickup_Message';
import print from '@salesforce/label/c.Print';
import selectAll from '@salesforce/label/c.Select_All';
import deselectAll from '@salesforce/label/c.Deselect_All';


import {loadScript} from 'lightning/platformResourceLoader';
import JSPDF from '@salesforce/resourceUrl/jsPDF';
import getUserMarketSegment from '@salesforce/apex/UserUtils.getUserMarketSegment';
import GOLOS_FONT from '@salesforce/resourceUrl/Golos';

import autoTable from '@salesforce/resourceUrl/jsPDFAutotable'
import XLSX from '@salesforce/resourceUrl/XLSX';
import IMAGES from "@salesforce/resourceUrl/SiteImages";
import {NavigationMixin} from "lightning/navigation";
import {ShowToastEvent} from "lightning/platformShowToastEvent";

import LightningConfirm from 'lightning/confirm';


export default class BasicDatatable extends NavigationMixin(LightningElement) {
    data = [];
    showData = false;
    showErrorMessage = false;
    showSpinner = true;
    error;
    idERP;
    itenumber;
    mapOfListValues = {};
    orderItemArray = [];
    latitude;
    longtitude;
    place;
    missingOrderValueMessage;
    showMissingOrderValueMessage = false;
    isAmericanUser = false;
    showPickupMessage = false;
    history = [];


    @api selectedItems = new Map();

    @track
    keys = [];
    printBntsClass = 'print-btn disabled';
    deselectButton = 'deselect-btn disabled';
    selectButton = 'select-btn enabled'


    @track
    selectedRows = [];
    printImg = IMAGES + '/print.png';
    xlsxIcon = IMAGES + '/xslxIcon.png';

    areRowsSelected = false;

    selectedFullRows = [];

    showGenPdfSpinner = false;

    rows = [];
    columns = [];

    label = {
        nonDeliveryInfo,
        pickupMessage,
        print,
        selectAll,
        deselectAll
    }

    @api recordId;
    value = 'val from parent';

    @track
    isMobile = false;

    @wire(getOrderById, {recId: '$recordId'})
    wiredOrder({data, error}) {
        if (data) {
            if (data.length == 0) {
                this.showErrorMessage = true;
                this.showSpinner = false;
            }
            this.idERP = data[0].ID_ERP__c;
            this.itenumber = data[0].ITENumber__c;
            if (this.idERP == undefined && this.itenumber == undefined) {
                this.missingOrderValueMessage = 'Missing Id_ERP and ITE Number Values of current order';
                this.showMissingOrderValueMessage = true;
            } else if (this.idERP == undefined) {
                this.missingOrderValueMessage = 'Missing Id_ERP value of current order';
                this.showMissingOrderValueMessage = true;
            } else if (this.idERP == undefined) {
                this.missingOrderValueMessage = 'Missing ITE Number value of current order';
                this.showMissingOrderValueMessage = true;
            }
        } else if (error) {
            console.error(error);

        }else{
        }
    }

    // @wire(getCalloutResponseContents, {recId: '$recordId'})
    // getResponse({data, error}) {
    //     this.showSpinner = true;
    //     if (data) {
    //         console.log('datra', data);
    //         const autoItems = data.OrderLineItems.filter(item => item.SHIPMENT_TYPE_COD === '2');
    //         const seaItems = data.OrderLineItems.filter(item => item.SHIPMENT_TYPE_COD === 'A');
    //         // console.log('autoItems', autoItems)
    //         // console.log('seaItems', seaItems)
    //         if(autoItems.length > 0) this.showDatatable(autoItems);
    //         if(seaItems.length > 0)  this.showDatatable(seaItems,'A');
    //         // if(data.length === 0){
    //         //     this.showErrorMessage = true;
    //         // }
    //          this.showSpinner = false;
            
    //     } else if (error) {
    //         this.showData = true;
    //         this.showSpinner = false;
    //         this.showErrorMessage = true;

    //         console.error(error);
    //     }else{
    //         // this.showErrorMessage = true;
    //         // this.showSpinner = false;
    //     }
    // }

    @wire(getCalloutResponseContents, {recId: '$recordId'})
    getResponse({data, error}) {
        this.showSpinner = true;
        if (data) {

            console.log('datra', data);
            console.log('data.OrderLineItems.length', data.OrderLineItems.length);

            if(data.OrderLineItems.length == 0){
                this.showErrorMessage = true;
            } 
            // else if(data.OrderLineItems[0].SHIPMENT_TYPE_COD === 'C') {
            //     this.showPickupMessage = true;
            // }
            let autoItems = data.OrderLineItems.filter(item => item.SHIPMENT_TYPE_COD === '2' || item.SHIPMENT_TYPE_COD === '3' || item.SHIPMENT_TYPE_COD === 'C');
            let seaItems = data.OrderLineItems.filter(item => item.SHIPMENT_TYPE_COD === 'A');
            autoItems = aggregateAutoItems(autoItems);

            seaItems = aggregateItems(seaItems);
            this.history = data.HistoryChains;

            // console.log('autoItems', autoItems)
            console.log('seaItems', seaItems)

            if(autoItems.length > 0) this.showDatatable(autoItems);
            if(seaItems.length > 0)  this.showDatatable(seaItems,'A');
            this.showSpinner = false;

            
            
        } else if (error) {
            this.showData = true;
            this.showSpinner = false;
            this.showErrorMessage = true;

            console.error(error);
        }else{
            // this.showErrorMessage = true;
            // this.showSpinner = false;
        }
    }
    connectedCallback() {
        window.addEventListener('resize', this.pageLayoutChanged.bind(this));

        getUserMarketSegment().then(result => {
            this.userMarketSegment = result;
            if(result == '00001'){
                this.isAmericanUser = true;
            } 
        })
    }

    renderedCallback() {
        Promise.all([

            loadScript(this, JSPDF),
            loadScript(this, autoTable),
            loadScript(this, XLSX)
        ]).then(() => {

        }).then(() => {
        }).catch(error => {
            console.error('Error loading jsPDF:', error);
        });
        this.refreshButtonState()
        this.pageLayoutChanged();
    }
    showDatatable(orderLineItems, shipmentType) {
        if (this.isAmericanUser) {
            this.data = adjustUnitsForAmericanUser(orderLineItems);
        } else {
            this.data = this.deepCopy(orderLineItems);
        }
        if (this.data.length === 0) {
            this.showData = false;
            this.showErrorMessage = true;
            this.showSpinner = false;
            return;
        }
        let mappedItems;
        this.showData = true;
        
        if (shipmentType =='A') {
            mappedItems = createMapWithSeaBooking(this.data);
        } else {
            mappedItems = createMapWithOrderItemOnIteNumber(this.data);
        }
        this.mapOfListValues = mappedItems;
        for (let key in mappedItems) {
            let groupArr = groupRecordsInArray(mappedItems[key]);
            this.orderItemArray.push(groupArr);
        }
        this.data.forEach(dataItem => {
            this.latitude = dataItem.LATITUDE;
            this.longtitude = dataItem.LONGTITUDE;
            // let dateOtgr = dataItem.DATE_OTGR.match(/\d/g).join("");
            // dataItem.DATE_OTGR = new Date(Number(dateOtgr));
    
            if (this.latitude && this.longtitude) {
                this.place = "https://www.google.com/maps/search/?api=1&query=" + this.latitude + "," + this.longtitude;
            } else {
                this.place = ' ';
                //dataItem.PLACE = ' ';
            }
            dataItem.GPS_LOCATION = this.place;
            dataItem.watched = false;
            // dataItem.STATUS_NAME = parseStatus(dataItem.STATUS_NAME, dataItem.SHIPMENT_TYPE_COD);

            const statusParts = dataItem.STATUS_NAME?.match(/^Поточна станція\s+(.+)$/i);
            if (statusParts) {
                dataItem.PLACE = statusParts[1];
                dataItem.STATUS_NAME = 'Поточна станція';
            } else {
                dataItem.STATUS_NAME = parseStatus(dataItem.STATUS_NAME, dataItem.SHIPMENT_TYPE_COD);
            }

            if (dataItem.SHIPMENT_TYPE_COD === '2' && dataItem.COUNTRY === 'Україна') {
                dataItem.DATE_OTGR = parseUnixDate(dataItem.DEPARTURE_TIME, false);
            } else {
                const raw = dataItem.DATE_OTGR?.match(/\d/g)?.join("");
                if (raw) {
                    dataItem.DATE_OTGR = new Date(Number(raw));
                }
            }

        });
    }
    
    deepCopy(inObject) {
        let outObject, value, key
        if (typeof inObject !== "object" || inObject === null) {
            return inObject // Return the value if inObject is not an object
        }
        // Create an array or object to hold the values
        outObject = Array.isArray(inObject) ? [] : {}
        for (key in inObject) {
            value = inObject[key]
            // Recursively (deep) copy for nested objects, including arrays
            outObject[key] = this.deepCopy(value)
        }
        return outObject
    }
    hanldeSpinnerValueChange(event) {
        this.showSpinner = false;
    }

    handlerItemSelect(event) {
        //console.log('get value before', this.selectedItems.get(event.detail.orderNumber));
        if (this.selectedItems.has(event.detail.orderNumber)) {
            //console.log('key', event.detail.orderNumber);
            !event.detail.items?.length
                ? this.selectedItems.delete(event.detail.orderNumber)
                : this.selectedItems.set(event.detail.orderNumber, JSON.parse(JSON.stringify(event.detail.items)))
        } else {
            this.selectedItems.set(event.detail.orderNumber, JSON.parse(JSON.stringify(event.detail.items)))
            //this.selectedItems.get(event.detail.orderNumber).push(JSON.parse(JSON.stringify(event.detail.items)))
        }
        //console.log('get value after', this.selectedItems.get(event.detail.orderNumber));
        this.refreshButtonState()
    }


    deselectAll() {
        this.selectedItems.clear();
        let tables = this.template.querySelectorAll('c-order-table');
        for (let i = 0; i < tables.length; i++) {
            tables[i]?.deselectAll();
        }
        this.refreshButtonState()

    }

    selectAll() {

        let tables = this.template.querySelectorAll('c-order-table');
        for (let i = 0; i < tables.length; i++) {
            tables[i]?.selectAll();
        }
        this.refreshButtonState()
    }

    @track selectedAutoItems = [];
    @track selectedSeaItems = [];
    genPDF(event) {
        this.showGenPdfSpinner = true;
        const { jsPDF } = window.jspdf;
        const doc = new jsPDF();
    
        const logoImgData = IMAGES + '/interpipeLogoEN.png';
        const headerText = this.getHeaderText(this.userMarketSegment);
    
        this.selectedAutoItems = [];
        this.selectedSeaItems = [];
        console.log('as', this.selectedItems)
        this.selectedItems.forEach((value, key) => {
            value.forEach(item => {
                item.QTY_T_NETTO = Number(item.QTY_T_NETTO) || 0;
                item.QTY_T_BRUTTO = Number(item.QTY_T_BRUTTO) || 0;
                item.QTY_PCS = Number(item.QTY_PCS) || 0;
                item.LENGTH_M = Number(item.LENGTH_M) || 0;


                if (item.SHIPMENT_TYPE_COD == "2" || item.SHIPMENT_TYPE_COD === '3') {
                    this.selectedAutoItems.push(item);
                } else if (item.SHIPMENT_TYPE_COD == "A") {
                    this.selectedSeaItems.push(item);
                }
            });
        });
    
        console.log('autoItems ', this.selectedAutoItems);
        console.log('seaItems ', this.selectedSeaItems);
    
        this.preparePDFDocument(doc, logoImgData, headerText);
        this.addTableData(doc, 'Auto', this.selectedAutoItems);  // Pass the auto items
        this.addTableData(doc, 'Sea', this.selectedSeaItems);    // Pass the sea items
        this.addPageNumbers(doc);
    
        // navigate to the PDF URL in a new window
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: URL.createObjectURL(doc.output('blob'))
            }
        });
    }
    
    generateXLSX() {
        // Import the XLSX library
        const XLSX = window.XLSX;
    
        // Create a new workbook object
        const workbook = XLSX.utils.book_new();
    
        // Initialize arrays to store worksheet data for "Auto" and "Sea" shipments
        const autoItemsData = [];
        const seaItemsData = [];
    
        // Define column headers for "Auto" shipments
        const autoColumns = [
            'Car #',
            'Item #',
            'Certificate',
            'Qty (pcs)',
            'Qty (t), brutto',
            'Qty (t), netto',
            'Length, m',
            'Date/Time GPS',
            'Place',
            'Country',
            'Status'
        ];
    
        // Define column headers for "Sea" shipments 
        const seaColumns = [
            // 'Cariage #',
            'Booking',
            'Item #',
            'Qty (pcs)',
            'Qty (t), netto',
            'Length',
            'Estimated Arrival Date',
            'Sea Status'
        ];
    
        // Iterate through selected items
        for (const key of this.selectedItems.keys()) {
            for (const order of this.selectedItems.get(key)) {
                // Determine the correct length unit based on user locale
                let lengthValue;
                if (this.isAmericanUser) {
                    lengthValue = order.LENGTH_FT ? Number(order.LENGTH_FT).toFixed(2) + ' ft' : 'N/A';
                } else {
                    lengthValue = order.LENGTH_M ? Number(order.LENGTH_M).toFixed(2) + ' m' : 'N/A';
                }
        
                // Define the columns and values for each order
                const orderDataAuto = {
                    'Car #': order.NOM_VM,
                    'Item #': order.ITENumber__c,
                    'Certificate': order.NOMSERT,
                    'Qty (pcs)': order.QTY_PCS,
                    'Qty (t), brutto': Number(order.QTY_T_BRUTTO).toFixed(2),
                    'Qty (t), netto': Number(order.QTY_T_NETTO).toFixed(2),
                    'Length': lengthValue,
                    'Date/Time GPS': this.convertDateTimeToLocal(order.COORD_DT),
                    'Place': order.PLACE,
                    'Country': order.COUNTRY,
                    'Status': order.STATUS_NAME
                };
                const orderDataShip = {
                    // 'Cariage #': order.NOM_VM,
                    'Booking' : order.SEA_BOOKING,
                    'Item #': order.ITENumber__c,
                    'Qty (pcs)': order.QTY_PCS,
                    'Qty (t), netto': Number(order.QTY_T_NETTO).toFixed(2),
                    'Length': lengthValue,
                    'Estimated Arrival Date': formatDateWithouTime(order.SEA_DATE_ARRIVAL_ESTIMATE),
                    'Sea Status': order.SEA_STATUS_EU
                };
        
                // Determine the shipment type and add data to the appropriate array
                if (order.SHIPMENT_TYPE_COD === '2' || order.SHIPMENT_TYPE_COD === '3') {
                    autoItemsData.push(orderDataAuto);
                } else if (order.SHIPMENT_TYPE_COD === 'A') {
                    seaItemsData.push(orderDataShip);
                }
            }
        }
        
        // Define the column widths for each worksheet (adjust as needed)
        const wscolsAuto = [
            { wch: 15 }, // 15 characters
            { wch: 20 },
            { wch: 10 },
            { wch: 10 },
            { wch: 10 },
            { wch: 15 },
            { wch: 15 },
            { wch: 15 },
            { wch: 40 },
            { wch: 10 },
            { wch: 20 },
        ];

        const wscolsSea = [
            { wch: 15 },
            { wch: 20 },
            { wch: 10 },
            { wch: 10 },
            { wch: 10 },
            { wch: 15 },
            { wch: 15 },
            { wch: 15 },
            { wch: 40 },
            { wch: 10 },
            { wch: 20 },
        ];
        // Convert the data arrays to worksheets
        // Set the column widths for each worksheet
        // Add the worksheets to the workbook with appropriate names
        let autoItemsSheet, seaItemsSheet;

        if (autoItemsData.length > 0) {
            autoItemsSheet = XLSX.utils.json_to_sheet(autoItemsData, { header: autoColumns });
            autoItemsSheet['!cols'] = wscolsAuto;
            XLSX.utils.book_append_sheet(workbook, autoItemsSheet, 'Auto Shipments');
        } else if(seaItemsData.length > 0){
            seaItemsSheet = XLSX.utils.json_to_sheet(seaItemsData, { header: seaColumns });
            seaItemsSheet['!cols'] = wscolsSea;
            XLSX.utils.book_append_sheet(workbook, seaItemsSheet, 'Sea Shipments');
        }
        // Save the workbook as an XLSX file
        XLSX.writeFile(workbook, 'InterpipeOrdersData.xlsx');
    }
    

    refreshButtonState() {
        this.deselectButton = 'deselect-btn ' + (this.selectedItems.size > 0 ? ' enabled ' : ' disabled ');

        let totalRecordAmount = this.orderItemArray.reduce(
            (accumulator, currentValue) => accumulator + currentValue.length,
            0
        );

        let selectedRecordAmount = [...this.selectedItems.values()].reduce(
            (accumulator, currentValue) => accumulator + currentValue.length,
            0
        );

        this.selectButton = 'select-btn ' + (totalRecordAmount !== selectedRecordAmount ? ' enabled ' : ' disabled ');

        this.printBntsClass = 'print-btn ' + ((this.selectedItems.size > 0 || this.isMobile) ? ' enabled ' : ' disabled ');
    }
    preparePDFDocument(doc, logoImgData, headerText) {
        doc.addFont(GOLOS_FONT, "Golos", "normal");
        doc.setFont("Golos");
        doc.setFontSize(9);
        doc.addImage(logoImgData, 'JPEG', 10, 10, 80, 16);
        doc.text(headerText, 155, 10);
        doc.setLineWidth(0.5);
        doc.line(10, 32, 200, 32);
        doc.setFontSize(15);
        // doc.text('Order products:', 10, 43);
    }

    addTableData(doc, type, items) {
        if(type == 'Auto'){
            this.columns = ['Car #','Item #','Certificate', 'Qty (pcs)', 'Qty (t), brutto', 'Qty (t), netto', 'Length, m', 'Date/Time GPS', 'Place', 'Country', 'Status'];
        }else if(type == 'Sea'){
            this.columns = ['Booking','Name','Qty (t), netto', 'Qty (pcs)', 'Length, m','Status', 'Estimated Arrival Date'];

        }
        console.log(items);
        // Check if items is an array before proceeding
        if (Array.isArray(items)) {
            let datatableRows = this.buildDatatable(items);
    
            let finalY = doc.lastAutoTable.finalY || 40;
            doc.setFontSize(8);
            doc.text(`${type} Shipments`, 14, finalY + 6);  // Add a title for the table
    
            doc.autoTable({
                startY: finalY + 8,
                head: [this.columns],
                body: datatableRows,
                styles: { font: 'Golos', fontSize: 8 },
                theme: 'grid',
                headStyles: { fillColor: [255, 255, 255], textColor: [0, 0, 0], lineWidth: 0.5, lineColor: [225, 225, 225] }
            });
        } else {
            console.error('Provided items are not in an array format:', items);
        }
    }
    

    addPageNumbers(doc) {
        for (let i = 1; i <= doc.internal.getNumberOfPages(); i++) {
            doc.setPage(i);
            doc.setFontSize(8);
            doc.text('Page ' + i + ' of ' + doc.internal.getNumberOfPages(), doc.internal.pageSize.width - 20, doc.internal.pageSize.height - 10, {align: 'right'});
        }
    }
    buildDatatable(selectedItems) {
        if (!Array.isArray(selectedItems)) {
            console.error('Selected items are not an array:', selectedItems);
            return [];
        }
        let rows = [];
        selectedItems.forEach((item) => {       
            if(item.SHIPMENT_TYPE_COD ==='A'){
                rows.push([
                    item.SEA_BOOKING,
                    item.NameProduct,
                    item.QTY_T_NETTO.toFixed(2),
                    item.QTY_PCS,
                    item.LENGTH_M.toFixed(2),
                    item.SEA_STATUS_EU,
                    formatDateWithouTime(item.SEA_DATE_ARRIVAL_ESTIMATE)
                    //item.SEA_STATUS_EU == 'Arrived' ? formatDateWithouTime(item.SEA_DATE_ARRIVAL) : formatDateWithouTime(item.SEA_DATE_ARRIVAL_ESTIMATE)
                    
                ]);
            }else{
                rows.push([
                    item.NOM_VM,
                    item.ITENumber__c,
                    item.NOMSERT,
                    item.QTY_PCS,
                    item.QTY_T_BRUTTO.toFixed(2),
                    item.QTY_T_NETTO.toFixed(2),
                    item.LENGTH_M.toFixed(2),
                    this.convertDateTimeToLocal(item.COORD_DT),
                    item.PLACE,
                    item.COUNTRY,
                    item.STATUS_NAME
                ]);
            }
            // Optionally, add an empty row for spacing before the next order number
            // rows.push([]);
        });
    
        return rows;
    }

    convertDateTimeToLocal(dateTime) {
        try {
            return new Intl.DateTimeFormat(window.navigator.language).format(new Date(dateTime));
        } catch (e) {
            return dateTime
        }

    }

    pageLayoutChanged() {
        this.isMobile = window.innerWidth < 600
        this.refreshButtonState();
    }

    handlePrint(event) {
        if (!this.selectedItems.size && !this.isMobile) {
            return;
        }
        this.printByType(event.currentTarget.dataset.id);
    }


    async printByType(type) {
        if (this.isMobile) {
            this.selectAll()
        }
        switch (type) {
            case 'PDF':
                await this.genPDF();
                break;
            case 'XLSX':
                await this.generateXLSX();
                break;

        }

        if (this.isMobile) {
            await this.deselectAll()
        }

    }


    getHeaderText() {
        if (this.userMarketSegment == '00001') {//Americas
            return '1800 West Loop South\nHouston, Texas 77027\nUnited States\nWebsite: www.na.interpipe.biz\nEmail: info@us.interpipe.biz\nPhone: +1 713-333-0333';
        } else if (this.userMarketSegment == '00002') {//MENA
            return 'LOB 19 (JAFZA VIEW 19),\nOFFICE 1008,\nJEBEL ALI,P.O. BOX 262810\nDUBAI, U.A.E.\nWebsite: www.me.interpipe.biz\nEmail: info@ae.interpipe.biz\nPhone: +971 4 812 5500'

        } else if (this.userMarketSegment == '00004') {//Europe
            return 'Via San Salvatore 13\nP.O.Box 745, CH-6902\nLugano-Paradiso, Switzerland\nWebsite: www.eu.interpipe.biz\nEmail: info@eu.interpipe.biz\nPhone: +41 91 261 39 00';

        } else if (this.userMarketSegment == '00006') {//KLW
            return 'Via San Salvatore 13\nP.O.Box 745, CH-6902\nLugano-Paradiso, Switzerland\nWebsite: www.klw.biz\nEmail: info@eu.interpipe.biz\nPhone: +41 91 261 39 00';

        }

        return '1A Pisarzhevs`koho str.\nDnipro,49000\nUkraine\nWebsite: www.interpipe.biz\nEmail: info@ua.interpipe.biz\nPhone: +38 (056) 736-60-06';

    }


}


function createMapWithOrderItemOnIteNumber(arrayOrderItem) {
    let mappedValues = {};
    arrayOrderItem.forEach(function (data) {
        if (mappedValues[data.ITENumber__c] != null) {
            mappedValues[data.ITENumber__c].push(data);
        } else {
            mappedValues[data.ITENumber__c] = new Array();
            mappedValues[data.ITENumber__c].push(data);
        }
    })

    return mappedValues;
}
function createMapWithSeaBooking(arrayOrderItem) {
    let mappedValues = {};
    arrayOrderItem.forEach(function (data) {
        if (data.SHIPMENT_TYPE_COD === 'A') { // Перевірка, що це морський транспорт
            let bookingKey = data.SEA_BOOKING;// Використання Sea Booking як ключа для групування
            if (!mappedValues[bookingKey]) {
                mappedValues[bookingKey] = [];
            }
            mappedValues[bookingKey].push(data);
        }
    });
    // console.log('mappedValues', mappedValues);
    return mappedValues;
}



function groupRecordsInArray(itemArray) {
    let newArray = [];
    for (let i = 0; i < itemArray.length; i++) {
        let record = itemArray[i];
        record.DEPARTURE_TIME = parseUnixDate(record.DEPARTURE_TIME, false);
        record.SEA_DATE_ARRIVAL_ESTIMATE = parseUnixDate(record.SEA_DATE_ARRIVAL_ESTIMATE, true);
        record.SEA_DATE_ARRIVAL = parseUnixDate(record.SEA_DATE_ARRIVAL, true);
        record.SEA_DEPARTURE_DATE = parseUnixDate(record.SEA_DEPARTURE_DATE, true); 
        record.QTY_T_NETTO = record.QTY_T_NETTO?.toFixed(2);
        record.LENGTH_M = record.LENGTH_M?.toFixed(2);
        record.COORD_DT = record.COORD_DT == '01.01.0001 0:00:00' ? '' : record.COORD_DT;
        if (record.watched == true || record.SHIPMENT_TYPE_COD === 'A') {
            newArray.push(record);
            continue;
        }

        for (let k = i + 1; k < itemArray.length; k++) {
            let nextRecord = itemArray[k];
            if (record.NOM_VM == nextRecord.NOM_VM &&
                record.TRDOC_NUM == nextRecord.TRDOC_NUM &&
                record.NOMSERT == nextRecord.NOMSERT &&
                record.COORD_DT == nextRecord.COORD_DT &&
                record.COUNTRY == nextRecord.COUNTRY &&
                record.ISO == nextRecord.ISO &&
                record.PLACE == nextRecord.PLACE &&
                record.STATUS_NAME == nextRecord.STATUS_NAME) {
                record.QTY_PCS = (Number(record.QTY_PCS) + Number(nextRecord.QTY_PCS)).toFixed(2);
                record.QTY_T_BRUTTO = (Number(record.QTY_T_BRUTTO) + Number(nextRecord.QTY_T_BRUTTO)).toFixed(2);
                record.QTY_T_NETTO = (Number(record.QTY_T_NETTO) + Number(nextRecord.QTY_T_NETTO)).toFixed(2);
                record.LENGTH_M = (Number(record.LENGTH_M) + Number(nextRecord.LENGTH_M)).toFixed(2);

                nextRecord.watched = true;
            }
        }
        if (!record.watched) {
            newArray.push(record);
        }
    }
    return newArray;
}

function aggregateItems(items) {
    const aggregatedData = items.reduce((acc, item) => {
        // Create a unique key by concatenating ITENumber__c and NOMSERT
        const key = `${item.ITENumber__c}-${item.NOMSERT}`;

        // Check if an object with the same key already exists in the accumulator
        if (!acc[key]) {
            // If not, create a new object with the current item's data and include the key
            acc[key] = { ...item, key };

            // Initialize LENGTH_M if it's supposed to be aggregated but not provided
            acc[key].LENGTH_M = acc[key].LENGTH_M || 0;

            // Ensure initial values are rounded to three decimal places for consistency
            acc[key].QTY_T_NETTO = parseFloat(item.QTY_T_NETTO.toFixed(3));
        } else {
            // If yes, sum the necessary fields
            acc[key].QTY_PCS += item.QTY_PCS;
            acc[key].LENGTH_M += item.LENGTH_M;

            // Sum and round the QTY_T_NETTO field to three decimal places
            acc[key].QTY_T_NETTO = parseFloat((acc[key].QTY_T_NETTO + item.QTY_T_NETTO).toFixed(3));
        }
        return acc;
    }, {});

    // Convert the aggregated data object into an array of its values
    return Object.values(aggregatedData);
}

function aggregateAutoItems(items) {
    const aggregatedData = items.reduce((acc, item) => {
        // Create a unique key by concatenating NOM_VM and NOMSERT
        const key = `${item.NOM_VM}-${item.NOMSERT}`;

        // Check if an object with the same key already exists in the accumulator
        if (!acc[key]) {
            // If not, create a new object with the current item's data
            acc[key] = { ...item, key };  // Include the key in the aggregated object

            // Initialize LENGTH_M if not existent
            acc[key].LENGTH_M = acc[key].LENGTH_M || 0;

            // Ensure initial values are rounded to three decimal places for consistency
            acc[key].QTY_T_NETTO = parseFloat(item.QTY_T_NETTO.toFixed(3));
        } else {
            // If yes, sum the necessary fields
            acc[key].QTY_PCS += item.QTY_PCS;
            //acc[key].LENGTH_M += item.LENGTH_M;
            acc[key].LENGTH_M = parseFloat((acc[key].LENGTH_M + item.LENGTH_M).toFixed(3));
            // Sum and round the QTY_T_NETTO field to three decimal places
            acc[key].QTY_T_NETTO = parseFloat((acc[key].QTY_T_NETTO + item.QTY_T_NETTO).toFixed(3));
        }
        return acc;
    }, {});

    // Convert the aggregated data object into an array of its values
    return Object.values(aggregatedData);
}

function adjustUnitsForAmericanUser(orderItems) {
    return orderItems.map(item => {
        const updatedItem = { ...item };
        // Перерахунок значень з метрів у фути і з тон в фунти
        if (updatedItem.LENGTH_M) {
            console.log()
            updatedItem.LENGTH_FT = (parseFloat(updatedItem.LENGTH_M) * 3.28084).toFixed(2);
            delete updatedItem.LENGTH_M;
        }
        // if (updatedItem.QTY_T_NETTO) {
        //     updatedItem.QTY_LBS_NETTO = (parseFloat(updatedItem.QTY_T_NETTO) * 2204.62).toFixed(3);
        //     delete updatedItem.QTY_T_NETTO; 
        // }
        return updatedItem;
    });
}


function parseUnixDate(departureTime, isDateWithoutTime) {

    // Extract the numeric part of the timestamp from the string
    var matches = departureTime.match(/\/Date\((\d+)\)\//);
    if (matches) {
        var timestamp = parseInt(matches[1], 10);
        // Create a new Date object using the extracted timestamp (which is in milliseconds)
        var date = new Date(timestamp);
        // Return the formatted date string
        if(isDateWithoutTime) {
            return date;
        } else {
            return formatDate(date);
        }
    }
    departureTime = 'N/A';
    return departureTime;
}

function formatDate(date) {
    var year = date.getFullYear();
    var month = pad(date.getMonth() + 1);
    var day = pad(date.getDate());
    var hour = pad(date.getHours());
    var minute = pad(date.getMinutes());
    var second = pad(date.getSeconds());
    
    return year + '-' + month + '-' + day + ' ' + hour + ':' + minute + ':' + second;
}

function formatDateWithouTime(dateString) {
    if (dateString != 'N/A' && dateString != 'undefined') {
        var date = new Date(dateString);
        var year = date.getFullYear();
        var month = pad(date.getMonth() + 1);
        var day = pad(date.getDate());
        return year + '-' + month + '-' + day;
    } else {
        return '';
    }
}

// Helper function to pad single digit numbers with a leading zero
function pad(number) {
    return (number < 10 ? '0' : '') + number;
}


let parseStatusOnEng = {
    'Доставлено': 'Delivered',
    'Достиг зоны разгрузки': 'In the unloading zone',
    'Прибыл в страну назначения': 'Arrived in the destination country',
    'Пересёк погран': 'Border crossed',
    'Пересек погран': 'Border crossed',
    'В пути': 'In transit',
    'Осталось проехать': 'In transit',
    'Достиг погран': 'On the border checkpoint',
    'Завершено': 'The cargo is delivered to the final destination',
}

function parseStatus(oldStatus, shipmentType) {
    console.log('old status: ' + JSON.stringify(oldStatus,null,2));
    console.log('shipmentType : ' + JSON.stringify(shipmentType,null,2));
    let startValue = oldStatus;

    for (let key in parseStatusOnEng) {
        if (oldStatus.includes(key)) {
            oldStatus = parseStatusOnEng[key];
            return oldStatus;
        }
    }
    if (shipmentType == 'C') {
        oldStatus = 'Customer\'s self-pickup';
    } else if (oldStatus == startValue) {
        oldStatus = 'Ready for delivery';
    }
    return oldStatus;
}