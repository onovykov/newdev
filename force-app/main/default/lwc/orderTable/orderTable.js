import {LightningElement, api, track} from 'lwc';
import requestForCertificate from '@salesforce/apex/orderDeliveryController.requestForCertificate';
import {loadScript} from 'lightning/platformResourceLoader';
import JSPDF from '@salesforce/resourceUrl/jsPDF';
import autoTable from '@salesforce/resourceUrl/jsPDFAutotable'
import XLSX from '@salesforce/resourceUrl/XLSX';
import getUserMarketSegment from '@salesforce/apex/UserUtils.getUserMarketSegment';
import { loadStyle } from 'lightning/platformResourceLoader';
import OrderTableCustomStyles from '@salesforce/resourceUrl/OrderTableCustomStyles';
import IMAGES from "@salesforce/resourceUrl/SiteImages";
import {NavigationMixin} from "lightning/navigation";
import LOCALE from '@salesforce/i18n/locale';

const columns = [
    {label: 'Car #', fieldName: 'NOM_VM', type: 'text', initialWidth: 120, cellAttributes: { class: { fieldName: 'rowClass' } }},
];

const bookingColumns = [
    { label: 'SeaBooking', fieldName: 'seaBooking', type: 'text' },
    { label: 'Departed From', fieldName: 'departedFrom', type: 'text' },
    { label: 'Departure Date', fieldName: 'departureDate', type: 'text' },
    { label: 'Destination', fieldName: 'destination', type: 'text' },
    { label: 'SeaStatus', fieldName: 'seaStatus', type: 'text' },
    { label: 'Estimated Arrival Date', fieldName: 'estimatedArrivalDate', type: 'text' },
    { label: 'Shipment Tracking', fieldName: 'shipmentTracking', type: 'text' }
];

export default class OrderTable extends NavigationMixin(LightningElement) {
    @api getMyData;
    @api getArrayLength;
    @api getIndex;
    @api getHistory;
    @track dynamicColumns = [];
    getOrderItems = [];
    orderNumber;
    cariageNumber;
    error;
    itemNames;
    columns = columns;
    @track bShowModal = false;
    @track record = {};
    b64 = 'data:application/pdf;base64, ';
    nameFile = 'Certificate.pdf';
    showSpinner = false;
    showCertificate = false;
    showError = false;
    isSeaShipment;
    isAmericanUser = false;
    isUkraineUser = false;
    bookingColumns = bookingColumns;
    bookingData = [];
    @track
    selectedRows = [];
    printImg = IMAGES + '/print.png';
    xlsxIcon = IMAGES + '/xslxIcon.png';
    areRowsSelected = false;
    showGenPdfSpinner = false;
    resolutionLessThan600 = false;
    orderItemsTotals = [];
    existHistory = false;
    history = [];
    arrivalDateLabel = 'Estimated Arrival Date';

    // connectedCallback() {
    //     console.log('----------DATA ----------' , JSON.parse(JSON.stringify(this.getMyData)));
    //
    //     loadStyle(this, OrderTableCustomStyles)
    //     .then(() => {
    //         // console.log('Custom styles loaded.');
    //     })
    //     .catch(error => {
    //         console.error('Error loading custom styles', error);
    //     });
    //
    //     getUserMarketSegment().then(result => {
    //         if(result == '00001'){
    //             this.isAmericanUser = true;
    //         } else if(result == '00011'){
    //             this.isUkraineUser = true;
    //         }
    //
    //         this.getAndSortHistory();
    //         this.updateDynamicColumns();
    //         this.populateBookingData();
    //         this.calculateAndAppendTotals();
    //         this.calculateAndAppendTotalsForOrderItems();
    //         this.formatNumbersInData();
    //         if(this.isUkraineUser) {
    //             this.updateColumnsForUkraine();
    //         }
    //     })
    //
    // }

    async connectedCallback() {
        console.log('----------DATA ----------', JSON.parse(JSON.stringify(this.getMyData)));

        loadStyle(this, OrderTableCustomStyles)
            .catch(error => {
                console.error('Error loading custom styles', error);
            });

        const result = await getUserMarketSegment();

        if (result === '00001') {
            this.isAmericanUser = true;
            console.log('AMERICAN USER!!!!!')
        } else if (result === '00011') {
            this.isUkraineUser = true;
            console.log('UKRAINE USER!!!!!')
        }



        await this.getAndSortHistory();
        this.updateDynamicColumns();
        this.populateBookingData();
        this.calculateAndAppendTotals();
        this.calculateAndAppendTotalsForOrderItems();
        this.formatNumbersInData();

        if (this.isUkraineUser) {
            this.updateColumnsForUkraine();
        }
    }


    async getAndSortHistory() {
        if (this.getHistory.length > 0) {
            this.getHistory.forEach(item => {
                if (item.Number === this.getMyData[0].HISTORY_CHAIN) {
                    this.history = [...item.Units];
                }
            });
        }

        if (this.history.length > 0) {
            this.existHistory = true;

            // Очікуємо форматування дат
            this.history = await Promise.all(this.history.map(async item => ({
                ...item,
                Dt: await this.formatDateForOrg(item.Dt, false)
            })));

            // Сортування після форматування
            this.history.sort((a, b) => new Date(b.Dt) - new Date(a.Dt));
        }
    }


    // async formatDateForOrg(inputDate, withTime) {
    //     console.log('⏳ Calling Apex parseDotNetDate with:', inputDate, 'withTime:', withTime);
    //
    //     let result = null;
    //     try {
    //         result = await parseDotNetDate(inputDate);
    //         console.log('✅ Apex returned formatted date:', result);
    //     } catch (error) {
    //         console.error('❌ Apex parseDotNetDate error:', error?.body?.message || error);
    //     }
    //
    //     return result;
    // }

    // formatDateForOrg(rawDate, withTime = false) {
    //     if (!rawDate || typeof rawDate !== 'string') return '-';
    //
    //     const match = rawDate.match(/\/Date\((\d+)\)\//);
    //     if (!match) return '-';
    //
    //     const millis = parseInt(match[1], 10);
    //     if (isNaN(millis)) return '-';
    //
    //     const dtUtc = new Date(millis);
    //     const localDate = new Date(dtUtc.getTime() + dtUtc.getTimezoneOffset() * -60000); // local offset
    //
    //     if (localDate.getFullYear() < 2015) {
    //         return '----';
    //     }
    //
    //     const day = String(localDate.getDate()).padStart(2, '0');
    //     const month = String(localDate.getMonth() + 1).padStart(2, '0');
    //     const year = localDate.getFullYear();
    //
    //     return `${day}.${month}.${year}`;
    // }


    formatDateForOrg(inputDate, withTime) {
        console.log('--- formatDateForOrg called ---');
        console.log('Raw inputDate:', inputDate);
        console.log('withTime flag:', withTime);

        if (!inputDate) {
            console.warn('⚠️ inputDate is falsy → return null');
            return null;
        }

        let timestamp;

        if (typeof inputDate === 'string') {
            console.log('Detected string input');

            const match = inputDate.match(/\/Date\((\-?\d+)\)\//); // ← підтримка від’ємних
            if (match && match[1]) {
                console.log('Matched .NET format:', match[0]);
                timestamp = Number(match[1]);
            } else {
                console.log('No .NET match, trying fallback number extract...');
                const fallback = inputDate.match(/\-?\d+/);
                timestamp = fallback ? Number(fallback[0]) : NaN;
            }
        } else if (inputDate instanceof Date) {
            console.log('Detected Date object');
            timestamp = inputDate.getTime();
        } else {
            console.log('Attempting to cast inputDate to number');
            timestamp = Number(inputDate);
        }

        console.log('Parsed timestamp:', timestamp);

        if (isNaN(timestamp)) {
            console.error('❌ Invalid timestamp (NaN) → return null');
            return null;
        }

        const date = new Date(timestamp);
        console.log('Constructed Date object:', date.toString());

        if (date.getFullYear() < 2015) {
            console.warn(`⚠️ Year ${date.getFullYear()} < 2015 → return '----'`);
            return '----';
        }

        const options = withTime
            ? {
                year: 'numeric',
                month: '2-digit',
                day: '2-digit',
                hour: '2-digit',
                minute: '2-digit',
                second: '2-digit',
            }
            : {
                year: 'numeric',
                month: '2-digit',
                day: '2-digit',
            };

        console.log('Intl formatting options:', options);

        const formatter = new Intl.DateTimeFormat(LOCALE, options);
        const formatted = formatter.format(date);

        console.log('✅ Formatted date string:', formatted);
        console.log('--- formatDateForOrg end ---');

        return formatted;
    }



    updateDynamicColumns() {
        this.isSeaShipment = this.getMyData.some(item => item.SHIPMENT_TYPE_COD === 'A');
        if (this.isSeaShipment) {
            this.dynamicColumns = this.getSeaShipmentColumns();
        } else {
            this.dynamicColumns = [...columns];
            this.addColumns();
        }
    }

    addColumns() {
        if (this.getMyData && this.getMyData.length > 0) {
            const shipmentLabel = this.isUkraineUser ? 'Date of shipment' : 'Date/time of shipment';

            let shipmentColumn;
            if (this.isUkraineUser) {
                shipmentColumn = [
                    { label: shipmentLabel, fieldName: 'DATE_OTGR', type: 'text', initialWidth: 200, cellAttributes: { class: { fieldName: 'rowClass' } } },
                ];
            } else {
                shipmentColumn = [
                    { label: shipmentLabel, fieldName: 'DEPARTURE_TIME', type: 'text', initialWidth: 200, cellAttributes: { class: { fieldName: 'rowClass' } } },
                ];
            }
            this.dynamicColumns.push(...shipmentColumn);
            
            let otherColumns = [
                {
                    initialWidth: 120,
                    type: 'button',
                    label: 'Get Certificate',
                    // type: 'button-icon',
                    //initialWidth: 75,
                    typeAttributes: {
                        label: {fieldName: 'NOMSERT'},
                        //iconName: 'action:preview',
                        title: 'Preview',
                        variant: 'border-filled',
                        alternativeText: 'View',
                        value: 'test value'
                    }, 
                    cellAttributes: { class: { fieldName: 'rowClass' } }
                },
                {label: 'Qty (pcs)', fieldName: 'QTY_PCS', type: 'text', cellAttributes: { class: { fieldName: 'rowClass' } }},
                {label: 'Qty (t), netto', fieldName: 'QTY_T_NETTO', type: 'text', cellAttributes: { class: { fieldName: 'rowClass' } }},
                {label: 'Length, m', fieldName: 'LENGTH_M', type: 'text', cellAttributes: { class: { fieldName: 'rowClass' } }},
            ];
            this.dynamicColumns.push(...otherColumns);

            let gpsColumns;
            if(this.isUkraineUser)  {
                gpsColumns = [
                    {label: 'Date GPS', fieldName: 'STATUSDT', type: 'text', cellAttributes: { class: { fieldName: 'rowClass' } }},
                    {label: 'Country ', fieldName: 'COUNTRY', type: 'text', cellAttributes: { class: { fieldName: 'rowClass' } }},
                ];
            } else {
                gpsColumns = [
                    {label: 'Date/Time GPS', fieldName: 'COORD_DT', type: 'text', cellAttributes: { class: { fieldName: 'rowClass' } }},
                    {label: 'Country ', fieldName: 'COUNTRY', type: 'text', cellAttributes: { class: { fieldName: 'rowClass' } }},
                ];
            }
            this.dynamicColumns.push(...gpsColumns);

            if (this.getMyData[0].GPS_LOCATION && this.getMyData[0].GPS_LOCATION != ' ') {
                let placeColumn = [
                    {
                        label: 'Place', fieldName: 'GPS_LOCATION', type: 'url', typeAttributes: {
                            label: {fieldName: 'PLACE'},
                            target: '_blank'
                        },
                        sortable: true, 
                        cellAttributes: { class: { fieldName: 'rowClass' }}
                    },
                    {label: 'Status', fieldName: 'STATUS_NAME', type: 'text', wrapText: true, cellAttributes: { class: { fieldName: 'rowClass' }}},
                ];
                this.dynamicColumns.push(...placeColumn);            
            } else {
                let placeColumn = [
                    {label: 'Place ', fieldName: 'PLACE', type: 'text', cellAttributes: { class: { fieldName: 'rowClass' }}},
                    {label: 'Status', fieldName: 'STATUS_NAME', type: 'text', wrapText: true, cellAttributes: { class: { fieldName: 'rowClass' }}},
                ];
                this.dynamicColumns.push(...placeColumn);         
            }
        }
    }

    getSeaShipmentColumns() {
        let columns = [
            { label: 'Name', fieldName: 'NameProduct', type: 'text', cellAttributes: { class: { fieldName: 'rowClass' }}},
            {
                initialWidth: 160,
                type: 'button',
                label: 'Get Certificate',
                typeAttributes: {
                    label: {fieldName: 'NOMSERT'},
                    title: 'Preview',
                    variant: 'border-filled',
                    alternativeText: 'View',
                    value: 'test value'
                }, 
                cellAttributes: { class: { fieldName: 'rowClass' }}
            },
            { label: 'Qty (t), netto', fieldName: 'QTY_T_NETTO', type: 'text', initialWidth: 160, cellAttributes: { alignment: 'right' }, cellAttributes: { class: { fieldName: 'rowClass' }}},
            this.isAmericanUser
                ? { label: 'Qty, ft', fieldName: 'LENGTH_FT', type: 'text', initialWidth: 160, cellAttributes: { alignment: 'right' }, cellAttributes: { class: { fieldName: 'rowClass' }}}
                : { label: 'Qty, m', fieldName: 'LENGTH_M', type: 'text', initialWidth: 160, cellAttributes: { alignment: 'right' }, cellAttributes: { class: { fieldName: 'rowClass' }}},
            { label: 'Qty (pcs)', fieldName: 'QTY_PCS', type: 'text', initialWidth: 160, cellAttributes: { alignment: 'right' }, cellAttributes: { class: { fieldName: 'rowClass' }}},
        ];    
        return columns;
    }

    populateBookingData() {
        if (this.getMyData && this.getMyData.length > 0) {
            if (this.isSeaShipment) {
                this.bookingData = [{
                    seaBooking: this.getMyData[0].SEA_BOOKING,
                    departedFrom: this.getMyData[0].SEA_TERMINAL,
                    departureDate: this.getMyData[0].SEA_DEPARTURE_DATE,
                    destination: this.getMyData[0].SEA_DESTINATION,
                    seaStatus: this.getMyData[0].SEA_STATUS_EU,
                    estimatedArrivalDate: this.getMyData[0].SEA_STATUS_EU == 'Arrived' ? this.getMyData[0].SEA_DATE_ARRIVAL : this.getMyData[0].SEA_DATE_ARRIVAL_ESTIMATE,
                    shipmentTracking: this.getMyData[0].SEA_HTTP
                }];
                
                if(this.getMyData[0].SEA_STATUS_EU == 'Arrived') {
                    this.arrivalDateLabel = 'Arrival Date';
                }
            }else{
                this.bookingData = [{
                    iteNumber: this.getMyData[0].ITENumber__c,
                    NameProduct: this.getMyData[0].NameProduct
                }];            
            }
           

        } else {
            console.error('getMyData is empty or not defined');
        }
    }

    calculateAndAppendTotals() {
        if (this.getMyData && Array.isArray(this.getMyData)) {
            let totalQtyPcs = 0;
            let totalQtyTBrutto = 0;
            let totalQtyTNetto = 0;
            let totalLengthM = 0;
            let totalLengthFt = 0;
            
            // Calculate totals
            this.getMyData.forEach(row => {
                totalQtyPcs += Number(row.QTY_PCS) || 0;
                totalQtyTBrutto += Number(row.QTY_T_BRUTTO) || 0;
                totalQtyTNetto += Number(row.QTY_T_NETTO) || 0;
                totalLengthM += Number(row.LENGTH_M) || 0;
                totalLengthFt += Number(row.LENGTH_FT) || 0;
            });
            

            // Create a new object for the total row
            const totalRow = {
                NameProduct: 'Total:', 
                NOM_VM: 'Total:', 
                QTY_PCS: totalQtyPcs,
                QTY_T_BRUTTO: totalQtyTBrutto.toFixed(2),
                QTY_T_NETTO: totalQtyTNetto.toFixed(2),
                LENGTH_M: totalLengthM.toFixed(2) ,
                LENGTH_FT: totalLengthFt.toFixed(2),
                isTotalRow: true
            };
            
            this.getMyData = [...this.getMyData, totalRow];
            
            this.getMyData = this.getMyData.map(row => ({
                ...row,
                rowClass: row.isTotalRow ? 'slds-text-title_bold' : ''
            }));
            
        }
    }

    calculateAndAppendTotalsForOrderItems() {
        if (this.getMyData && Array.isArray(this.getMyData)) {
            let orderItemsTotalsMap = new Map();
            this.getMyData.forEach(row => {
                let orderItem = this.deepCopy(row);
                if (orderItemsTotalsMap.get(row.NameProduct) == null) {
                    orderItem.QTY_PCS = 0;
                    orderItem.QTY_T_NETTO = 0;
                    orderItem.LENGTH_M = 0;
                    orderItem.LENGTH_FT = 0;
                    orderItem.NOMSERT = null;
                    orderItem.SEA_DATE_ARRIVAL_ESTIMATE = row.SEA_DATE_ARRIVAL_ESTIMATE;
                    orderItem.key = this.createRandomString(20);
                    orderItem._children = [];
                    orderItemsTotalsMap.set(row.NameProduct, orderItem);
                } else {
                    orderItem = orderItemsTotalsMap.get(row.NameProduct);
                }

                orderItem.QTY_PCS += Number(row.QTY_PCS) || 0;
                orderItem.QTY_T_NETTO += Number(row.QTY_T_NETTO) || 0;
                orderItem.LENGTH_M += Number(row.LENGTH_M) || 0;
                orderItem.LENGTH_FT += Number(row.LENGTH_FT) || 0;
                orderItem._children.push(row);
            })

            const formatter = new Intl.NumberFormat('fr-FR', {
                minimumFractionDigits: 2,
                maximumFractionDigits: 2,
                useGrouping: true
            });

            this.orderItemsTotals = Array.from(orderItemsTotalsMap.values());
            this.orderItemsTotals.forEach(orderItem =>{
                orderItem.QTY_T_NETTO = orderItem.QTY_T_NETTO.toFixed(2);
                orderItem.LENGTH_M = orderItem.LENGTH_M.toFixed(2);
                orderItem.LENGTH_FT = orderItem.LENGTH_FT.toFixed(2);
                orderItem.QTY_PCS = formatter.format(Number(orderItem.QTY_PCS) || 0);
                orderItem.QTY_T_NETTO = formatter.format(Number(orderItem.QTY_T_NETTO) || 0);
                orderItem.LENGTH_M = formatter.format(Number(orderItem.LENGTH_M) || 0);
                orderItem.LENGTH_FT = formatter.format(Number(orderItem.LENGTH_FT) || 0);

            })
        }
    }

    formatNumbersInData() {
        if (this.getMyData && Array.isArray(this.getMyData)) {
            const formatter = new Intl.NumberFormat('fr-FR', {
                minimumFractionDigits: 2,
                maximumFractionDigits: 2,
                useGrouping: true
            });
    
            this.getMyData = this.getMyData.map(row => ({
                ...row,
                QTY_PCS: formatter.format(Number(row.QTY_PCS) || 0),
                QTY_T_BRUTTO: formatter.format(Number(row.QTY_T_BRUTTO) || 0),
                QTY_T_NETTO: formatter.format(Number(row.QTY_T_NETTO) || 0),
                LENGTH_M: formatter.format(Number(row.LENGTH_M) || 0),
                LENGTH_FT: formatter.format(Number(row.LENGTH_FT) || 0),
            }));
        }
    }

    updateColumnsForUkraine() {
        if (this.getMyData && Array.isArray(this.getMyData)) {
    
            this.getMyData = this.getMyData.map(row => ({
                ...row,
                DATE_OTGR: this.formatDateForOrg(row.DATE_OTGR, true),
                STATUSDT: this.formatDateForOrg(row.STATUSDT, false),
                COUNTRY: 'Ukraine',
            }));
        }
    }

    renderedCallback() {
        this.orderNumber = this.getMyData[0].ITENumber__c;
        let lastElelementNumber = this.getIndex + 1;
        if (this.getArrayLength == lastElelementNumber) {
            const selectedEvent = new CustomEvent("spinnervaluechange", {});
            this.dispatchEvent(selectedEvent);
        }
        Promise.all([
            loadScript(this, JSPDF),
            loadScript(this, autoTable),
            loadScript(this, XLSX)
        ]).then(() => {
        }).catch(error => {
            console.error('Error loading jsPDF:', error);
        });


    }


    handleViewCertificate(event) {
        const selectedRowId = event.target.dataset.id;
        // Find the selected row in the data array
        const selectedRow = this.getMyData.find(row => row.ITENumber__c === selectedRowId);

        if (selectedRow) {
            const kobj1 = selectedRow.KOBJ;
            const undoc1 = selectedRow.UNDOC_PA;
            const iteNumber1 = selectedRow.ITENumber__c;
            const packNum1 = selectedRow.PACK_NUM;

            this.requestForCertificateHandle(kobj1, undoc1, iteNumber1, packNum1);
            this.showSpinner = true;
            this.bShowModal = true; // Display modal window
        }
    }


    @api
    selectAll() {
        if(this.isSeaShipment) {
            this.selectedRows = this.orderItemsTotals.map(item => item.key)
            const selectedEvent = new CustomEvent('itemselect', {
                detail: {orderNumber: this.orderNumber, items: JSON.parse(JSON.stringify(this.orderItemsTotals))}
            });

            this.dispatchEvent(selectedEvent);
        } else {
            this.selectedRows = this.getMyData.map(item => item.key)
            const selectedEvent = new CustomEvent('itemselect', {
                detail: {orderNumber: this.orderNumber, items: JSON.parse(JSON.stringify(this.getMyData))}
            });
            
            this.dispatchEvent(selectedEvent);
        }
    }

    @api
    deselectAll() {
        this.selectedRows = [];
    }

    // Row Action event to show the details of the record
    handleRowAction(event) {
        const row = event.detail.row;
        this.record = row;
        this.requestForCertificateHandle(row.KOBJ, row.UNDOC_PA, row.ITENumber__c, row.PACK_NUM);
        this.showSpinner = true;
        this.bShowModal = true; // display modal window
    }

    requestForCertificateHandle(kobj1, undoc1, iteNumber1, packNum1) {
        requestForCertificate({kobj: kobj1, undoc: undoc1, iteNumber: iteNumber1, packNum: packNum1})
            .then((result) => {
                if (result.Success == true) {
                    this.b64 += result.Content;
                    this.nameFile = result.FileName;
                    this.showSpinner = false;
                    this.showCertificate = true;
                } else {
                    this.showSpinner = false;
                    this.showError = true;
                }
            })
            .catch((error) => {
                console.error(error);
                this.showSpinner = false;
                this.showError = true;
            });
    }

    // to close modal window set 'bShowModal' tarck value as false
    closeModal() {
        this.bShowModal = false;
    }


    handleSelected(event) {
        const selectedEvent = new CustomEvent('itemselect', {
            detail: {orderNumber: this.orderNumber, items: event.detail.selectedRows}
        });

        this.dispatchEvent(selectedEvent);
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

    createRandomString(length) {
        const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
        let result = "";
        for (let i = 0; i < length; i++) {
          result += chars.charAt(Math.floor(Math.random() * chars.length));
        }
        return result;
      }
      
}