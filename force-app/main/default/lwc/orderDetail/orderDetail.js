import {LightningElement, wire, track, api} from 'lwc';
import getOrderItems from '@salesforce/apex/OrderItemDatatableController.getOrderItems';
import getUserMarketSegment from '@salesforce/apex/OrderItemDatatableController.getUserMarketSegment';

import IMAGES from "@salesforce/resourceUrl/SiteImages";

import site_th_Product from '@salesforce/label/c.Site_th_Product';
import site_th_Name from '@salesforce/label/c.Site_th_Name';
import site_th_Quantity from '@salesforce/label/c.Site_th_Quantity';
import site_th_Stage from '@salesforce/label/c.Site_th_Stage';
import site_th_ProducedQuantity from '@salesforce/label/c.Site_th_ProducedQuantity';
import site_th_DispatchedQuantity from '@salesforce/label/c.Site_th_DispatchedQuantity';
import site_th_ShippedQuantity from '@salesforce/label/c.Site_th_ShippedQuantity';
import site_th_UnitPrice from '@salesforce/label/c.Site_th_UnitPrice';

import site_orderDetail_Order from '@salesforce/label/c.Site_orderDetail_Order';
import site_orderDetail_DeliveryStatus from '@salesforce/label/c.Site_orderDetail_DeliveryStatus';
import site_orderDetail_Stage from '@salesforce/label/c.Site_orderDetail_Stage';
import site_orderDetail_ExecutionStatus from '@salesforce/label/c.Site_orderDetail_ExecutionStatus';
import site_orderDetail_Quantity from '@salesforce/label/c.Site_orderDetail_Quantity';
import site_orderDetail_Address from '@salesforce/label/c.Site_orderDetail_Address';
import site_orderDetail_Account from '@salesforce/label/c.Site_orderDetail_Account';
import site_orderDetail_OrderProducts from '@salesforce/label/c.Site_orderDetail_OrderProducts';
import site_orderDetail_Details from '@salesforce/label/c.Site_orderDetail_Details';
import site_orderDetail_OrderNumber from '@salesforce/label/c.Site_orderDetail_OrderNumber';
import site_orderDetail_PONumber from '@salesforce/label/c.Site_orderDetail_PONumber';
import site_orderDetail_Country from '@salesforce/label/c.Site_orderDetail_Country';
import site_orderDetail_PhoneNumber from '@salesforce/label/c.Site_orderDetail_PhoneNumber';
import site_orderDetail_ITENumber from '@salesforce/label/c.Site_orderDetail_ITENumber';
import site_orderDetail_OrderOwner from '@salesforce/label/c.Site_orderDetail_OrderOwner';
import site_orderDetail_Date1 from '@salesforce/label/c.Site_orderDetail_Date1';
import site_orderDetail_Date2 from '@salesforce/label/c.Site_orderDetail_Date2';
import site_orderDetail_Date3 from '@salesforce/label/c.Site_orderDetail_Date3';
import site_orderDetail_Produced from '@salesforce/label/c.Site_orderDetail_Produced';
import site_orderDetail_Dispatched from '@salesforce/label/c.Site_orderDetail_Dispatched';
import site_orderDetail_Shipped from '@salesforce/label/c.Site_orderDetail_Shipped';
import site_orderDetail_Currency from '@salesforce/label/c.Site_orderDetail_Currency';
import site_orderDetail_Amount from '@salesforce/label/c.Site_orderDetail_Amount';
import site_orderDetail_BillingAddress from '@salesforce/label/c.Site_orderDetail_BillingAddress';
import site_orderDetail_ShippingAddress from '@salesforce/label/c.Site_orderDetail_ShippingAddress';
import site_orderDetail_t from '@salesforce/label/c.Site_orderDetail_t';
import site_orderDetail_pcs from '@salesforce/label/c.Site_orderDetail_pcs';
import site_orderDetail_TypeOfProducts from '@salesforce/label/c.Site_orderDetail_TypeOfProducts';


import print from '@salesforce/label/c.Print';

import JSPDF from '@salesforce/resourceUrl/jsPDF';
import autoTable from '@salesforce/resourceUrl/jsPDFAutotable'
import XLSX from '@salesforce/resourceUrl/XLSX';

import GOLOS_FONT from '@salesforce/resourceUrl/Golos';

import {CurrentPageReference, NavigationMixin} from 'lightning/navigation';
import {loadScript} from "lightning/platformResourceLoader";


export default class OrderDetail extends NavigationMixin(LightningElement) {

    @api getSelectedOrder;
    recordId;
    @track order;
    UA = IMAGES + '/ukraine-twitter.png';
    @track ordersItemsList;
    @track filteredOrdersItemsList;
    @track secondChoice;
    @track dropdownOpen = false;
    @track optionsToDisplay;
    @track selectedOrderItemId;

    isModalOpen = false;
    isModalDeliveryOpen = false;

    labels = {
        site_th_Product,
        site_th_Name,
        site_th_Quantity,
        site_th_Stage,
        site_th_ProducedQuantity,
        site_th_DispatchedQuantity,
        site_th_ShippedQuantity,
        site_th_UnitPrice,

        site_orderDetail_Order,
        site_orderDetail_DeliveryStatus,
        site_orderDetail_Stage,
        site_orderDetail_ExecutionStatus,
        site_orderDetail_Quantity,
        site_orderDetail_Address,
        site_orderDetail_Account,
        site_orderDetail_OrderProducts,
        site_orderDetail_Details,
        site_orderDetail_OrderNumber,
        site_orderDetail_PONumber,
        site_orderDetail_Country,
        site_orderDetail_PhoneNumber,
        site_orderDetail_ITENumber,
        site_orderDetail_OrderOwner,
        site_orderDetail_Date2,
        site_orderDetail_Date1,
        site_orderDetail_Date3,
        site_orderDetail_Produced,
        site_orderDetail_Dispatched,
        site_orderDetail_Shipped,
        site_orderDetail_Currency,
        site_orderDetail_Amount,
        site_orderDetail_BillingAddress,
        site_orderDetail_ShippingAddress,
        site_orderDetail_t,
        site_orderDetail_pcs,
        site_orderDetail_TypeOfProducts,
        print
    }

    @track selectedValue = this.labels.site_orderDetail_OrderProducts;
    @track options = [
        {id: 'tab-defaultItem-1', label: this.labels.site_orderDetail_OrderProducts, order: 1},
        {id: 'tab-defaultItem-2', label: this.labels.site_orderDetail_Details, order: 2},
    ];
    @track selectedOption = this.options[0].label;

    isAmericanUser = false;
    isKLWUser = false;


    printImg = IMAGES + '/print.png';
    xlsxIcon = IMAGES + '/xslxIcon.png';


    connectedCallback() {
        this.optionsToDisplay = this.options.filter((option) => option.label !== this.selectedOption);
        console.log('this.optionsToDisplay', this.options)
        getUserMarketSegment().then(response => {
            console.log('response ---->', response);
            this.isAmericanUser = response === '00001';
            this.isKLWUser = response === '00006';
        });

        getOrderItems({orderId: this.getSelectedOrder}).then(response => {
            this.ordersItemsList = response.OrderItems;
            let respCopy = {...response}
            if (respCopy.Status == 'Activated') {
                respCopy.Status = 'Active';
            }
            this.order = respCopy;
            this.secondChoice = response.SecondChoice__c;
            let dataCopy = this.deepCopy(response.OrderItems)
            console.log('dataCopy : ', dataCopy);
            dataCopy.forEach(element => {
                element.Quantity = element.Quantity.toFixed(3);
                element.unitPrice = this.numberWithSpaces(element.UnitPrice);
                if (element.TubeLengthSize__r) {
                    element.TubeLengthSize__r.MaxLength__c = (element.TubeLengthSize__r.MaxLength__c / 304.8).toFixed(2);
                    element.TubeLengthSize__r.MinLength__c = (element.TubeLengthSize__r.MinLength__c / 304.8).toFixed(2);
                } else {
                    element.TubeLengthSize__r = {MaxLength__c: 'N/A', MinLength__c: 'N/A'}
                }
                if (!element.TubeOD__r) {
                    element.TubeOD__r = {OD_inch__c: 'N/A'}
                }

                if (!element.TubeWT__r) {
                    element.TubeWT__r = {WT_inch__c: 'N/A'}

                }
                element.Name__c = element.Name__c.replace(/\(delete duplicate\)/g, '');
                element.HasSpecification = element.KLWSpec__c != null && element.Drawing__c != null;
            });

            this.filteredOrdersItemsList = dataCopy;
            
            console.log('filteredOrdersItemsList : ', this.filteredOrdersItemsList);


        })
    }

    renderedCallback() {
        let styleDropdownBtn = window.getComputedStyle(this.refs.dropdownBtn);
        if (this.refs.dropdownList?.style) {
            this.refs.dropdownList.style.width = styleDropdownBtn.width;
        }

        Promise.all([
            loadScript(this, JSPDF),
            loadScript(this, autoTable),
            loadScript(this, XLSX),

        ]).then(() => {
            // console.log('jsPDF loaded successfully');
        }).catch(error => {
            console.error('Error loading jsPDF:', error);
        });
    }


    numberWithSpaces(x) {
        var parts = x.toString().split(".");
        parts[0] = parts[0].replace(/\B(?=(\d{3})+(?!\d))/g, " ");
        return parts.join(".");
    }

    toggleSubtabs(event) {
        // console.log(event.target.dataset.id);
        this.switchTabName(event.target.dataset.id)
    }

    @wire(CurrentPageReference) handlePageReference(result) {
        this.recordId = result.state.id;
        console.log('record ID', result.state.id);
    }


    handleChange(event) {
        this.value = event.detail.value;
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

    switchTabName(idAtrribute) {
        // console.log('idAtrribute',idAtrribute)
        this.template.querySelectorAll('.slds-tabs_default__item').forEach(function (data) {
            if (data.querySelectorAll('a')[0].dataset.id == idAtrribute) {
                data.classList.add("slds-is-active")
            } else {
                data.classList.remove("slds-is-active");
            }
        })
        this.template.querySelectorAll('.slds-tabs_default__content').forEach(function (data) {
            let currentId = data.dataset.id;
            console.log('currentId', currentId, 'idAtrribute ', idAtrribute);

            console.log(currentId == idAtrribute);
            if (idAtrribute == currentId) {
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

    @api
    modalContainer;

    openModalDelivery(event) {
        //console.log(event.target.id);
        this.isModalDeliveryOpen = true;
        this.orderDeliveryId = this.getSelectedOrder;
        setTimeout(() => {
            this.modalContainer = this.template.querySelector('.slds-modal__container');
            console.log(this.modalContainer);
        }, 2000)
    }

    closeModalDelivery() {
        this.isModalDeliveryOpen = false;
        this.isUserModalActive = false;
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

    openModal(event) {
        this.isModalOpen = true;
        this.selectedOrderItemId = event.target.dataset.id
        setTimeout(() => {
            this.modalContainer = this.template.querySelector('.slds-modal__container');
        }, 2000)
    }

    closeModal() {
        this.isModalOpen = false;
        this.isUserModalActive = false;
    }

    genPDF() {


        this.showGenPdfSpinner = true;

        // import jsPDF from the global window object
        const {jsPDF} = window.jspdf;

        // create a new instance of jsPDF
        const doc = new jsPDF();


        // define the path to the logo image
        const logoImgData = IMAGES + '/interpipeLogoEN.png';

        // define the text for the header
        let headerText;
        if (this.userMarketSegment == '00001') {//Americas
            headerText = '1800 West Loop South\nHouston, Texas 77027\nUnited States\nWebsite: www.na.interpipe.biz\nEmail: info@us.interpipe.biz\nPhone: +1 713-333-0333';
        } else if (this.userMarketSegment == '00002') {//MENA
            headerText = 'LOB 19 (JAFZA VIEW 19),\nOFFICE 1008,\nJEBEL ALI,P.O. BOX 262810\nDUBAI, U.A.E.\nWebsite: www.me.interpipe.biz\nEmail: info@ae.interpipe.biz\nPhone: +971 4 812 5500'

        } else if (this.userMarketSegment == '00004') {//Europe
            headerText = 'Via San Salvatore 13\nP.O.Box 745, CH-6902\nLugano-Paradiso, Switzerland\nWebsite: www.eu.interpipe.biz\nEmail: info@eu.interpipe.biz\nPhone: +41 91 261 39 00';

        } else if (this.userMarketSegment == '00006') {//KLW
            headerText = 'Via San Salvatore 13\nP.O.Box 745, CH-6902\nLugano-Paradiso, Switzerland\nWebsite: www.klw.biz\nEmail: info@eu.interpipe.biz\nPhone: +41 91 261 39 00';

        } else {
            headerText = '1A Pisarzhevs`koho str.\nDnipro,49000\nUkraine\nWebsite: www.interpipe.biz\nEmail: info@ua.interpipe.biz\nPhone: +38 (056) 736-60-06';
        }


        doc.addFont(GOLOS_FONT, "Golos", "normal");
        doc.setFont("Golos");


        // add the logo image and header text to the first page of the PDF document
        doc.setFontSize(9);
        doc.addImage(logoImgData, 'JPEG', 10, 10, 80, 16);
        doc.text(headerText, 155, 10);

        // Add a line below the header
        doc.setLineWidth(0.5);
        doc.line(10, 32, 200, 32);

        // add a heading for the selected orders section
        doc.setFontSize(15);
        doc.text(`Order ${this.order.AdditionalNumber__c} `, 10, 43);

        doc.setFontSize(10);

        let columns = [];
        let rows = [];

        let orders = this.ordersItemsList;

        columns = ['Product', 'Name', 'Quantity(t)', 'Stage', 'Produced (t)', 'Dispatched (t)', 'Delivered acc to Incoterms(t)', 'Unit Price'];

        rows = orders.map(item => [
            item.Name__c,
            item.Product2.Name,
            item.Quantity,
            item.Stage__c,
            item.ProducedQuantity__c,
            item.DispatchedQuantity__c,
            item.ShippedQuantity__c,
            `${item.UnitPrice || '0'} ${this.order.CurrencyIsoCode}`
        ]);


        let finalY = doc.lastAutoTable.finalY || 40
        doc.setFontSize(8);
        doc.autoTable({
            startY: finalY + 8,
            head: [columns],
            body: rows,
            styles: {
                font: 'Golos',
                fontSize: 8
            },
            theme: 'grid',//striped, plain
            headStyles: {
                fillColor: [255, 255, 255],
                textColor: [0, 0, 0],
                lineWidth: 0.5,
                lineColor: [225, 225, 225]
            }
        });


        // add page numbering to each page of the PDF document
        for (let i = 1; i <= doc.internal.getNumberOfPages(); i++) {
            doc.setPage(i);
            doc.setFontSize(8);
            doc.text('Page ' + i + ' of ' + doc.internal.getNumberOfPages(), doc.internal.pageSize.width - 20, doc.internal.pageSize.height - 10, {align: 'right'});
        }


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
        let orderItemsData = [];
        if (this.ordersItemsList.length > 0) {
            this.ordersItemsList.forEach(item => {

                orderItemsData.push({
                    'Product': item.Name__c,
                    'Name': item.Product2.Name,
                    'Quantity (t)': item.Quantity,
                    'Stage': item.Stage__c,
                    'Produced (t)': item.ProducedQuantity__c,
                    'Dispatched (t)': item.DispatchedQuantity__c,
                    'Delivered acc to Incoterms(t)': item.ShippedQuantity__c,
                    'Unit Price': `${item.UnitPrice || '0'} ${this.order.CurrencyIsoCode}`
                });

            });
            // Convert the orderItemsData array to a worksheet
            const sheet1 = XLSX.utils.json_to_sheet(orderItemsData);
            // Define the column widths
            var wscols = [
                {wch: 40},//15 characters
                {wch: 10},
                {wch: 10},
                {wch: 10},
                {wch: 10},
            ];
            console.log(wscols);
            // Set the column widths for the worksheet
            sheet1['!cols'] = wscols;

            // Add the worksheet to the workbook
            XLSX.utils.book_append_sheet(workbook, sheet1, 'All Orders items');
            // Save the workbook as an XLSX file
            XLSX.writeFile(workbook, `Order ${this.order.AdditionalNumber__c}.xlsx`);
        }
    }


    // get options() {
    //     return [
    //             {id: 'tab-default-1__item', label: this.labels.site_orderDetail_OrderProducts, value: 'tab-defaultItem-1' },
    //             {id: 'tab-default-2__item', label: this.labels.site_orderDetail_Details, value: 'tab-defaultItem-2' },
    //         ];
    // }
    get orderEndDate() {
        return this.order.EndDate ? this.order.EndDate : 'n/a';
    }

    get ownerFullName() {
        return this.order.Owner.FirstName + ' ' + this.order.Owner.LastName;
    }

    get typeProducts() {
        return this.order.MarketSegment__c == '00006' ? 'Wheels type' : 'Tubes type';
    }

    get POnumber() {
        return this.order.PO_Number__c ? this.order.PO_Number__c : 'n/a';
    }

    get activatedData() {
        return this.order.ActivatedDate ? this.order.ActivatedDate.slice(0, 10) : 'n/a';
    }

    get billingAddress() {
        return this.order.BillingAddress ? this.order.BillingAddress.country + ' ' + this.order.BillingAddress.city + ' ' + this.order.BillingAddress.street : 'n/a'
    }

    get shippingAddress() {
        return this.order.ShippingAddress ? this.order.ShippingAddress.country + ' ' + this.order.ShippingAddress.city + ' ' + this.order.ShippingAddress.street : 'n/a'
    }

    get ownerPhone() {
        return this.order.Owner.Phone ? this.order.Owner.Phone : 'n/a';
    }

}