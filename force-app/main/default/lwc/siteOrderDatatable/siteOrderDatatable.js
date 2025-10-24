import {api, LightningElement, track, wire} from 'lwc';
import IMAGES from "@salesforce/resourceUrl/SiteImages";
import getOrders from '@salesforce/apex/OrderDatatableController.getOrders';
import getUserMarketSegment from '@salesforce/apex/UserUtils.getUserMarketSegment';
import getProdPlanVisible from '@salesforce/apex/UserUtils.getProdPlanVisible';
import getBusinessDivision from '@salesforce/apex/UserUtils.getBusinessDivision';
import getAllDivisions from '@salesforce/apex/UserUtils.getAllDivisions';
import getStructuredProdPlan from '@salesforce/apex/OrderDatatableController.getStructuredProdPlan';

//import generatePdf from '@salesforce/apex/OrderDatatableController.generatePdf';
import ACTIVE from '@salesforce/label/c.Active';
import CLOSED from '@salesforce/label/c.Closed';
import ALL_ORDERS from '@salesforce/label/c.All_orders';
import DRAFT from '@salesforce/label/c.Draft';
import SHIPPED from '@salesforce/label/c.Shipped';
import PRINT from '@salesforce/label/c.Print';
import CHOOSEADATE from '@salesforce/label/c.Choose_a_date';
import FROM from '@salesforce/label/c.From';
import TO from '@salesforce/label/c.To';
import PRODUCTION_PLAN from '@salesforce/label/c.Production_Plan';
import PRODUCTION_DATES from '@salesforce/label/c.Production_Dates';
import START_DATE from '@salesforce/label/c.Start_Date';
import END_DATE from '@salesforce/label/c.End_Date';
import Site_orderDetail_OrderNumber from '@salesforce/label/c.Site_orderDetail_OrderNumber';
import Site_orderDetail_Date1 from '@salesforce/label/c.Site_orderDetail_Date1';
import site_th_Quantity from '@salesforce/label/c.Site_th_Quantity';
import site_th_Stage from '@salesforce/label/c.Site_th_Stage';
import site_th_ProducedQuantity from '@salesforce/label/c.Site_th_ProducedQuantity';
import site_th_DispatchedQuantity from '@salesforce/label/c.Site_th_DispatchedQuantity';
import site_th_ShippedQuantity from '@salesforce/label/c.Site_th_ShippedQuantity';
import site_orderDetail_t from '@salesforce/label/c.Site_orderDetail_t';
import site_orderDetail_pcs from '@salesforce/label/c.Site_orderDetail_pcs';
import Site_th_erpNumber from '@salesforce/label/c.Site_th_erpNumber';
import site_orderDetail_DeliveryStatus from '@salesforce/label/c.Site_orderDetail_DeliveryStatus';
import Site_th_Product from '@salesforce/label/c.Site_th_Product';
import PleaseSelectOrder from '@salesforce/label/c.Please_select_at_least_one_order';
import Warning from '@salesforce/label/c.Warning';
import nonDeliveryInfo from '@salesforce/label/c.OrderDeliveryNonInfo';
import NO_PLAN_DATA from '@salesforce/label/c.NoPlanDataMessage';



import Balance_for_Shipment from '@salesforce/label/c.Balance_for_Shipment';
import Stock from '@salesforce/label/c.Stock';
import Balance_for_Production from '@salesforce/label/c.Balance_for_Production';
import Monthly_Prod_Plan from '@salesforce/label/c.Monthly_Prod_Plan';
import Weekly_Prod_Plan from '@salesforce/label/c.Weekly_Prod_Plan';
import Estimated_Prod_Balance from '@salesforce/label/c.Estimated_Prod_Balance';
import Order_Number_for_Prod_Plan from '@salesforce/label/c.Order_Number_for_Prod_Plan';

import VIEW from '@salesforce/label/c.View';
import {loadScript} from 'lightning/platformResourceLoader';
import JSPDF from '@salesforce/resourceUrl/jsPDF';
import autoTable from '@salesforce/resourceUrl/jsPDFAutotable'
import XLSX from '@salesforce/resourceUrl/XLSX';
import GOLOS_FONT from '@salesforce/resourceUrl/Golos';

import {ShowToastEvent} from 'lightning/platformShowToastEvent';


import {NavigationMixin} from 'lightning/navigation';

export default class SiteOrderDatatable extends NavigationMixin(LightningElement) {
    @track data;
    @track filteredOrdersList;
    @track ordersList;
    @track ordersResult;
    @track selectedOrderid;
    @track dropdownOpen = false;
    @track options;
    @track selectedOption;
    @track optionsToDisplay;
    @track prodPlanData = [];

    label = {
        NO_PLAN_DATA
    };



    active = ACTIVE;
    closed = CLOSED;
    allOrdersTxt = ALL_ORDERS;
    draft = DRAFT;
    shipped = SHIPPED;
    print = PRINT;
    chooseADate = CHOOSEADATE;
    from = FROM;
    to = TO;
    productionDates = PRODUCTION_DATES;
    startDateProd = START_DATE;
    endDateProd = END_DATE;
    view = VIEW;
    productionPlan = PRODUCTION_PLAN;

    number = Site_orderDetail_OrderNumber;
    date = Site_orderDetail_Date1;
    status = site_th_Stage;
    quantity = site_th_Quantity;
    prodQuantity = site_th_ProducedQuantity;
    dispQuantity = site_th_DispatchedQuantity;
    shippedQuantity = site_th_ShippedQuantity;
    tons = site_orderDetail_t;
    pcs = site_orderDetail_pcs;
    erp = Site_th_erpNumber;
    deliveryStatus = site_orderDetail_DeliveryStatus;
    BalanceforShipment = Balance_for_Shipment;
    Stock = Stock;
    BalanceforProduction = Balance_for_Production;
    MonthlyProdPlan = Monthly_Prod_Plan;
    WeeklyProdPlan = Weekly_Prod_Plan;
    EstimatedProdBalance = Estimated_Prod_Balance;
    OrderNumberforProdPlan = Order_Number_for_Prod_Plan;
    productName = Site_th_Product;
    PleaseSelectOrder = PleaseSelectOrder;
    Warning = Warning;
    nonDeliveryInfo = nonDeliveryInfo;


    allOrders = true;
    isActiveOrders;
    isPortal;
    isClosedOrders;
    isDraftOrders
    isShippedOrders;
    isStockOrders;
    isProductionPlan;
    isStockOrProdPlan;
    isProdPlanVisible;
    isStockVisible;
    isProdPlanOnMobile;
    isProdPlanOnDesktop;
    isProdPlanNotOnDesktop;
    isKLWSegment;
    isAllDivisions;
    startDate;
    endDate;
    prodPlanStartDate;
    prodPlanEndDate;
    searchKey;
    sortIcon = IMAGES + '/filterIcon.png';
    printImg = IMAGES + '/print.png';
    refresh = IMAGES + '/refresh.png';
    plusIcon = IMAGES + '/plusIcon.png';
    minusIcon = IMAGES + '/minusIcon.png';
    xlsxIcon = IMAGES + '/xslxIcon.png';


    selectedItemsToGenerateXSLX = [];

    isModalOpen = false;
    showGenPdfSpinner = false;

    dateSortToggled = false;
    stageSortToggled = false;
    numberSortToggled = false;

    sortByDateAsc = true;
    sortBydStageAsc = true;
    sortByNumberAsc = true;
    classAdded = false;


    @track amountAllOrders;
    @track amountActiveOrders;
    @track amountClosedOrders;
    @track amountDraftOrders
    @track amountShippedOrders;

    userMarketSegment;
    isModalDeliveryOpen = false;
    orderDeliveryId;
    isOrderDispatched;

    @api recordId;

    get containerClass() {
        return this.isPortal ? 'portal-container production-plan_container full-height-content' : 'internal-container production-plan_container full-height-content';
    }

    @wire(getOrders, {}) handleOrders(result) {

        this.ordersResult = result;
        const {error, data} = result;
        if (data) {
            let dataCopy = this.deepCopy(data);

            getUserMarketSegment().then(result => {
                this.userMarketSegment = result;
                this.isKLWSegment = this.userMarketSegment === '00006';

                dataCopy.forEach(item => {
                    if (item.Status == 'Activated') {
                        item.Status = 'Active';
                    }
                    if (!item.PO_Number__c) {
                        item.PO_Number__c = item.AdditionalNumber__c;
                    }
                    item.TotalOrderQuantity__c = item.TotalOrderQuantity__c.toFixed(3);
                    item.Quantity_pcs__c = item.Quantity_pcs__c ? item.Quantity_pcs__c.toFixed(0) : 0;
                    item.ProducedQuantity_pcs__c = item.ProducedQuantity_pcs__c ? item.ProducedQuantity_pcs__c.toFixed(0) : 0;
                    item.DispatchedQuantity_pcs__c = item.DispatchedQuantity_pcs__c ? item.DispatchedQuantity_pcs__c.toFixed(0) : 0;
                    item.DeliveredQuantity_pcs__c = item.DeliveredQuantity_pcs__c ? item.DeliveredQuantity_pcs__c.toFixed(0) : 0;
                    // сюди додати
                    item.ProducedQuantity__c = item.ProducedQuantity__c.toFixed(3);
                    item.ShippedQuantity__c = item.ShippedQuantity__c.toFixed(3);
                    item.DispatchedQuantity__c = item.DispatchedQuantity__c < 0 ? 0 : item.DispatchedQuantity__c.toFixed(3);

                    item.Stock = (item.ProducedQuantity__c - item.ShippedQuantity__c).toFixed(3);
                    // item.BalanceForShipment = (item.TotalOrderQuantity__c - item.DispatchedQuantity__c).toFixed(3);
                    item.BalanceForShipment = 0;
                    if (item.BalanceForShipment < 0) {
                        item.BalanceForShipment = 0;
                    }
                    item.BalanceForProduction = 0;
                    item.MonthlyProdPlan = 0;
                    item.WeeklyProdPlan = 0;
                    item.EstimatedProdBalance = 0;
                    item.expandDocuments = false;
                    if (item.OrderItems) {
                        item.OrderItems = item.OrderItems.map(ordItem => {
                            ordItem.Quantity = ordItem.Quantity.toFixed(3);
                            ordItem.Stock = (ordItem.ProducedQuantity__c - ordItem.DispatchedQuantity__c).toFixed(3);
                            ordItem.BalanceForShipment = (ordItem.Quantity - ordItem.ShippedQuantity__c).toFixed(3);
                            if (ordItem.BalanceForShipment < 0) {
                                ordItem.BalanceForShipment = 0;
                            }
                            if(ordItem.Stock != 0) {
                                item.BalanceForShipment += parseFloat(ordItem.BalanceForShipment);
                            }
                            if(ordItem.WeekStartDate__c != null && (ordItem.WeeklyProdPlan__c != 0 || ordItem.MonthlyProdPlan__c != 0 || ordItem.BalanceForProduction__c != 0 || ordItem.Estimated_Prod_Balance__c != 0)) {
                                item.BalanceForProduction += ordItem.BalanceForProduction__c;
                                item.MonthlyProdPlan += ordItem.MonthlyProdPlan__c;
                                item.WeeklyProdPlan += ordItem.WeeklyProdPlan__c;
                                item.EstimatedProdBalance += ordItem.Estimated_Prod_Balance__c;
                                this.prodPlanStartDate = ordItem.WeekStartDate__c;
                                this.prodPlanEndDate = ordItem.WeekEndDate__c;
                            }
                            return ordItem;

                        })
                        item.BalanceForShipment = item.BalanceForShipment.toFixed(3);
                        item.BalanceForProduction = item.BalanceForProduction.toFixed(3);
                        item.MonthlyProdPlan = item.MonthlyProdPlan.toFixed(3);
                        item.WeeklyProdPlan = item.WeeklyProdPlan.toFixed(3);
                        item.EstimatedProdBalance = item.EstimatedProdBalance.toFixed(3);
                        item.OrderNumberProdPlan = item.AdditionalNumber__c + ' | ' + item.PO_Number__c;
                        item.OrderItemsForProdPlan = item.OrderItems.filter(ordItem => {
                            return ordItem.WeekStartDate__c != null && (ordItem.WeeklyProdPlan__c != 0 || ordItem.MonthlyProdPlan__c != 0 || ordItem.BalanceForProduction__c != 0 || ordItem.Estimated_Prod_Balance__c != 0);
                        })
                        item.OrderItems = item.OrderItems.filter(ordItem => {
                            return ordItem.Stock != 0;
                        })

                        if (this.userMarketSegment =='00011') { // Перевірка ProducedQuantity__c на 0
                            const hasNMPP = item.OrderItems.some(item => item.Shop__r.Plant__r.Name === 'NMPP');

                            if (hasNMPP) { // Якщо хоча б один OrderItem відповідає критерію
                                item.ProducedQuantity__c = item.ShippedQuantity__c; // Оновлення ProducedQuantity__c
                            }
                        }
                    }
                });
            })

            this.ordersList = dataCopy;
            this.filteredOrdersList = dataCopy;
            let all = this.filteredOrdersList.filter((item => {
                return item && item.EffectiveDate >= this.startDate && item.EffectiveDate <= this.endDate;
            }))
            let active = this.filteredOrdersList.filter((item => {
                return item.Status == 'Active' && item.EffectiveDate >= this.startDate && item.EffectiveDate <= this.endDate;
            }))
            let closed = this.filteredOrdersList.filter((item => {
                return item.Status == 'Closed' && item.EffectiveDate >= this.startDate && item.EffectiveDate <= this.endDate;
            }))
            let draft = this.filteredOrdersList.filter((item => {
                return item.Status == 'Draft' && item.EffectiveDate >= this.startDate && item.EffectiveDate <= this.endDate;
            }))
            let shipped = this.filteredOrdersList.filter((item => {
                return item.ShippedQuantity__c != 0 && item.EffectiveDate >= this.startDate && item.EffectiveDate <= this.endDate && item.Status != 'Closed';
            }))

            this.amountAllOrders = all.length;
            this.amountActiveOrders = active.length;
            this.amountClosedOrders = closed.length;
            this.amountDraftOrders = (draft.length == 0) ? 0 : draft.length;
            this.amountShippedOrders = shipped.length;

            this.setInitialDates();
            this.searchBy();
        }
        if (error) {
            console.error(error);
        }

    }

    renderedCallback() {
        let styleDropdownBtn = window.getComputedStyle(this.refs.dropdownBtn);
        if (this.refs.dropdownList?.style) {
            this.refs.dropdownList.style.width = styleDropdownBtn.width;
        }

        Promise.all([
            loadScript(this, JSPDF),
            loadScript(this, autoTable),
            loadScript(this, XLSX)
        ]).then(() => {
            // console.log('jsPDF loaded successfully');
        }).catch(error => {
            console.error('Error loading jsPDF:', error);
        });


    }

    handleSearch(event) {
        this.searchKey = event.target.value.toLowerCase();
        this.searchBy();
    }

    genPDF() {
        this.showGenPdfSpinner = true;

        // import jsPDF from the global window object
        const {jsPDF} = window.jspdf;

        // create a new instance of jsPDF
        const doc = new jsPDF();


        doc.addFont(GOLOS_FONT, "Golos", "normal");
        doc.setFont("Golos");

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
        // add the logo image and header text to the first page of the PDF document
        doc.setFontSize(9);
        doc.addImage(logoImgData, 'JPEG', 10, 10, 80, 16);
        doc.text(headerText, 155, 10);

        // Add a line below the header
        doc.setLineWidth(0.5);
        if (this.userMarketSegment == '00002') {
            doc.line(10, 35, 200, 35);
        } else {
            doc.line(10, 32, 200, 32);
        }

        // get the list of selected orders
        let orders = this.filteredOrdersList;

        // add a heading for the selected orders section
        doc.setFontSize(18);
        doc.text('Selected Orders:', 10, 43);
        let columns = [];
        let rows = []
        // create a table and add it to the PDF document
        if (this.isStockOrders) {
            columns = ['Order Number', 'Quantity(t)', 'Balance For Shipment', 'Stock'];

            rows = orders.map(order => [
                order.AdditionalNumber__c,
                order.TotalOrderQuantity__c,
                order.BalanceForShipment,
                order.Stock
            ]);
        } else if (this.isProductionPlan) {
            columns = ['Order COC # | PO #', 'Quantity(t)', 'Balance For Production', 'Monthly Prod. Plan', 'Weekly Prod. Plan', 'Estimated Prod. Balance'];

            rows = orders.map(order => [
                order.OrderNumberProdPlan,
                order.TotalOrderQuantity__c,
                order.BalanceForProduction,
                order.MonthlyProdPlan,
                order.WeeklyProdPlan,
                order.EstimatedProdBalance
            ]);
        } else {

            columns = ['Order Number', 'Date', 'Stage', 'Quantity(t)', 'Produced(t)', 'Dispatched(t)', 'Delivered acc to Incoterms(t)'];

            rows = orders.map(order => [
                order.AdditionalNumber__c,
                order.EffectiveDate,
                order.Status,
                order.TotalOrderQuantity__c,
                order.ProducedQuantity__c,
                order.DispatchedQuantity__c,
                order.ShippedQuantity__c,
            ]);
        }


        doc.autoTable({
            head: [columns],
            body: rows,
            startY: 50,
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

        // save the PDF document as a blob
        const pdfBlob = doc.output('blob');

        // create a URL for the PDF blob
        const pdfUrl = URL.createObjectURL(pdfBlob);

        // hide the spinner
        this.showGenPdfSpinner = false;

        // navigate to the PDF URL in a new window
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: pdfUrl
            }
        });
    }

    generateAllOrdersXLSX() {
        // Import the XLSX library
        const XLSX = window.XLSX;
        // Create a new workbook object
        const workbook = XLSX.utils.book_new();
        let orderItemsData = [];
        if (this.filteredOrdersList.length > 0) {
            this.filteredOrdersList.forEach(item => {

                orderItemsData.push({
                    'Order Number': item.AdditionalNumber__c,
                    'Date': item.EffectiveDate,
                    'Stage': item.Status,
                    'Quantity AN(pcs)': 424,
                    'Quantity(t)': item.TotalOrderQuantity__c,
                    'Produced(t)': item.ProducedQuantity__c,
                    'Dispatched(t)': item.DispatchedQuantity__c,
                    'Delivered acc to Incoterms(t)': item.ShippedQuantity__c,
                });

            });
            // Convert the orderItemsData array to a worksheet
            const sheet1 = XLSX.utils.json_to_sheet(orderItemsData);
            // Define the column widths
            var wscols = [
                {wch: 15},//15 characters
                {wch: 40},
                {wch: 10},
                {wch: 20},
                {wch: 10},
            ];
            // Set the column widths for the worksheet
            sheet1['!cols'] = wscols;

            // Add the worksheet to the workbook
            XLSX.utils.book_append_sheet(workbook, sheet1, 'All Orders');
            // Save the workbook as an XLSX file
            XLSX.writeFile(workbook, 'InterpipeAllOrders.xlsx');
        }
    }

    generateXLSX() {
        // Import the XLSX library
        const XLSX = window.XLSX;
        // Create a new workbook object
        const workbook = XLSX.utils.book_new();
        let orderItemsData = [];
        if (this.selectedItemsToGenerateXSLX.length > 0) {
            this.selectedItemsToGenerateXSLX.forEach(item => {
                if (item.OrderItems) {
                    item.OrderItems.forEach(orderItem => {
                        orderItemsData.push({
                            'Order Number': item.AdditionalNumber__c,
                            'Product Name': orderItem.Name__c,
                            'Quantity (t)': orderItem.Quantity,
                            'Balance For Shipment': orderItem.BalanceForShipment,
                            'Stock': orderItem.Stock,

                        });
                    });
                }
            });
            // додати сюди


            // Convert the orderItemsData array to a worksheet
            const sheet1 = XLSX.utils.json_to_sheet(orderItemsData);
            // Define the column widths
            var wscols = [
                {wch: 15},//15 characters
                {wch: 40},
                {wch: 10},
                {wch: 20},
                {wch: 10},
            ];
            // Set the column widths for the worksheet
            sheet1['!cols'] = wscols;

            // Add the worksheet to the workbook
            XLSX.utils.book_append_sheet(workbook, sheet1, 'Orders Stock');
            // Save the workbook as an XLSX file
            XLSX.writeFile(workbook, 'InterpipeOrdersStock.xlsx');
        } else {
            const evt = new ShowToastEvent({
                title: this.Warning,
                message: this.PleaseSelectOrder,
                variant: 'Warning'
            });
            this.dispatchEvent(evt);
        }

    }

    generateXLSXforProdPlan() {
        // Import the XLSX library
        const XLSX = window.XLSX;
        // Create a new workbook object
        const workbook = XLSX.utils.book_new();
        let orderItemsData = [];
        if (this.selectedItemsToGenerateXSLX.length > 0) {
            this.selectedItemsToGenerateXSLX.forEach(item => {
                if (item.OrderItemsForProdPlan) {
                    item.OrderItemsForProdPlan.forEach(orderItem => {
                        orderItemsData.push({
                            'Order COC # | PO #': item.OrderNumberProdPlan,
                            'Product Name': orderItem.Name__c,
                            'Quantity (t)': orderItem.Quantity,
                            'Balance For Production': orderItem.BalanceForProduction__c,
                            'Monthly Prod. Plan': orderItem.MonthlyProdPlan__c,
                            'Weekly Prod. Plan': orderItem.WeeklyProdPlan__c,
                            'Estimated Prod. Balance': orderItem.Estimated_Prod_Balance__c,
                            'Week Start Date': orderItem.WeekStartDate__c,
                            'Week End Date': orderItem.WeekEndDate__c,
                        });
                    });
                }
            });
            // Convert the orderItemsData array to a worksheet
            const sheet1 = XLSX.utils.json_to_sheet(orderItemsData);
            // Define the column widths
            var wscols = [
                {wch: 20},//20 characters
                {wch: 40},
                {wch: 10},
                {wch: 20},
                {wch: 16},
                {wch: 15},
                {wch: 20},
                {wch: 15},
                {wch: 15},
            ];
            // Set the column widths for the worksheet
            sheet1['!cols'] = wscols;

            // Add the worksheet to the workbook
            XLSX.utils.book_append_sheet(workbook, sheet1, 'Production Plan');
            // Save the workbook as an XLSX file
            XLSX.writeFile(workbook, 'InterpipeProductionPlan.xlsx');
        } else {
            const evt = new ShowToastEvent({
                title: this.Warning,
                message: this.PleaseSelectOrder,
                variant: 'Warning'
            });
            this.dispatchEvent(evt);
        }

    }

    connectedCallback() {


        const href = window.location.href;
        this.isPortal = !!href.includes('/s/');

        if (!this.isPortal) {
            // Логіка для сторінки рекорда: лише один таб
            this.isProdPlanVisible = true;
            this.isStockVisible = false;
            this.isProductionPlan = true;

            this.options = [
                { id: 'tab-default-7__item', label: this.productionPlan, order: 1 }
            ];
            // this.selectedOption = this.productionPlan;
            this.selectedOption = this.options[0].label;

            this.optionsToDisplay = [];

            this.setInitialDates();
            this.loadProductionPlanData();

            // Достроково виходимо з connectedCallback
            return;
        }

        // Для порталу далі виконується стандартна логіка
        getProdPlanVisible().then(resultVisible => {

            getBusinessDivision().then(businessDivision => {
                this.isProdPlanVisible = businessDivision === 'Railway' ? false : resultVisible;
                this.isStockVisible = businessDivision !== 'Railway';

                this.options = [
                    {id: 'tab-default-3__item', label: this.allOrdersTxt, order: 1, amount: this.all},
                    {id: 'tab-default-1__item', label: this.active, order: 2, amount: this.amountActiveOrders},
                    {id: 'tab-default-5__item', label: this.shipped, order: 3, amount: this.amountShippedOrders},
                    {id: 'tab-default-2__item', label: this.closed, order: 4, amount: this.amountClosedOrders},
                    {id: 'tab-default-4__item', label: this.draft, order: 5, amount: this.amountDraftOrders},
                ];
                if (this.isStockVisible) {
                    this.options.push({id: 'tab-default-6__item', label: this.Stock, order: 6});
                }
                if (this.isProdPlanVisible) {
                    this.options.push({id: 'tab-default-7__item', label: this.productionPlan, order: 7});
                }

                this.selectedOption = this.options[0].label;
                this.optionsToDisplay = this.options.filter((option) => option.label !== this.selectedOption);
            });
        });

        getAllDivisions().then(resultAllDivisions => {
            this.isAllDivisions = resultAllDivisions;
        });

        this.setInitialDates();
    }


    setInitialDates() {
        const today = new Date();
        const firstDayLastYear = new Date(Date.UTC(today.getUTCFullYear() - 1, 0, 1));

        this.startDate = firstDayLastYear.toISOString().split('T')[0];
        this.endDate = today.toISOString().split('T')[0];
        // this.searchBy();
    }


    setStartDate(event) {
        this.startDate = event.target.value;
        this.searchBy();
    }

    setEndDate(event) {
        this.endDate = event.target.value;
        this.searchBy();
    }

    searchBy() {
        this.filteredOrdersList = this.ordersList;
        if (this.searchKey) {
            if (this.filteredOrdersList) {
                let searchRecords = [];
                for (let record of this.filteredOrdersList) {
                    let valuesArray = Object.values(record);

                    for (let val of valuesArray) {
                        let strVal = String(val);

                        if (strVal) {

                            if (strVal.toLowerCase().includes(this.searchKey)) {
                                searchRecords.push(record);
                                break;
                            }
                        }
                    }
                }

                this.filteredOrdersList = searchRecords;
            }
        } else {
            this.filteredOrdersList = this.ordersList;
        }

        if (this.startDate) {
            this.filteredOrdersList = this.filteredOrdersList.filter(order => {
                return order.EffectiveDate >= this.startDate;
            })
        }

        if (this.endDate) {
            this.filteredOrdersList = this.filteredOrdersList.filter(order => {
                return order.EffectiveDate <= this.endDate;
            })
        }

        if (this.allOrders) {
            this.filteredOrdersList = this.filteredOrdersList.filter(order => {
                return order;
            })
            this.amountAllOrders = this.filteredOrdersList.length;
        }
        if (this.isActiveOrders) {
            this.filteredOrdersList = this.filteredOrdersList.filter(order => {
                return order.Status == 'Active';
            })
            this.amountActiveOrders = this.filteredOrdersList.length;
        }
        if (this.isClosedOrders) {
            this.filteredOrdersList = this.filteredOrdersList.filter(order => {
                return order.Status == 'Closed';
            })
            this.amountClosedOrders = this.filteredOrdersList.length;
        }
        if (this.isDraftOrders) {
            this.filteredOrdersList = this.filteredOrdersList.filter(order => {
                return order.Status == 'Draft';
            })
            this.amountDraftOrders = this.filteredOrdersList.length;
        }
        if (this.isShippedOrders) {
            this.filteredOrdersList = this.filteredOrdersList.filter(order => {
                return order.ShippedQuantity__c != 0 && order.Status != 'Closed';
            })
            this.amountShippedOrders = this.filteredOrdersList.length;
        }
        if (this.isStockOrders) {
            this.filteredOrdersList = this.filteredOrdersList.filter(order => {
                return order.Stock > 0;
            })
        }
        if (this.isProductionPlan) {
            this.filteredOrdersList = this.filteredOrdersList.filter(order => {
                return this.prodPlanStartDate != null && (order.WeeklyProdPlan != 0 || order.MonthlyProdPlan != 0 || order.BalanceForProduction != 0 || order.EstimatedProdBalance != 0);
            })
        }

    }
    refreshSearch() {
        this.filteredOrdersList = this.ordersList;
        this.searchKey = null;
        this.setInitialDates();
        this.template.querySelector('.search-input').value = '';
        this.switchTabName('tab-default-3__item');
    }

    toggleSubtabs(event) {
        this.switchTabName(event.target.dataset.id)

    }

    // @track options = [
    //     {id: 'tab-default-3__item', label: this.allOrdersTxt, order: 1, amount: this.all},
    //     {id: 'tab-default-1__item', label: this.active, order: 2, amount: this.amountActiveOrders},
    //     {id: 'tab-default-5__item', label: this.shipped, order: 3, amount: this.amountShippedOrders},
    //     {id: 'tab-default-2__item', label: this.closed, order: 4, amount: this.amountClosedOrders},
    //     {id: 'tab-default-4__item', label: this.draft, order: 5, amount: this.amountDraftOrders},
    //     {id: 'tab-default-6__item', label: this.Stock, order: 6},
    //     {id: 'tab-default-7__item', label: this.productionPlan, order: 7},
    // ];

    //@track selectedOption = this.options[0].label;
    toggleDropdown() {
        this.dropdownOpen = !this.dropdownOpen;
    }

    handleOptionClick(event) {
        const selectedOptionId = event.target.dataset.id;
        this.switchTabName(selectedOptionId)
        const selectedOption = this.options.find((option) => option.id === selectedOptionId);
        // this.optionsToDisplay = this.deepCopy(this.options);
        if (selectedOption) {
            this.selectedOption = selectedOption.label;
            this.optionsToDisplay = this.options.filter((option) => option.label !== selectedOption.label);
            this.optionsToDisplay.sort((a, b) => a.order - b.order);



            if (this.selectedOption === 'Stock' || this.selectedOption === 'Production Plan') {
                this.template.querySelector('.datatable').classList.remove('not-stock-selected');
                this.template.querySelector('.datatable').classList.add('stock-selected');

                this.template.querySelector('table thead').classList.add('stock-selected');
                this.template.querySelector('table thead').classList.remove('not-stock-selected');


                this.template.querySelector('.datatable-header').classList.add('stock-selected');
                this.template.querySelector('.datatable-header').classList.remove('not-stock-selected');


            } else {
                this.template.querySelector('.datatable').classList.add('not-stock-selected');
                this.template.querySelector('.datatable').classList.remove('stock-selected');

                this.template.querySelector('table thead').classList.remove('stock-selected');
                this.template.querySelector('table thead').classList.add('not-stock-selected');


                this.template.querySelector('.datatable-header').classList.add('not-stock-selected');
                this.template.querySelector('.datatable-header').classList.remove('stock-selected');


                // this.template.querySelector('th').classList.remove('stock-selected');
                // this.template.querySelector('table').classList.remove('stock-selected');
            }
        }
        this.dropdownOpen = false;
    }

    switchTabName(idAtrribute) {
        this.template.querySelectorAll('.slds-tabs_default__item').forEach(function (data) {
            if (data.querySelectorAll('a')[0].dataset.id == idAtrribute) {
                data.classList.add("slds-is-active")
            } else {
                data.classList.remove("slds-is-active");
            }
        })

        // if (idAtrribute != 'tab-default-6__item') {
        //     this.template.querySelector('.datatable').classList.add('not-stock-selected');
        // }
        //
        // if (FORM_FACTOR != 'Large' && idAtrribute === 'tab-default-7__item') {
        //     this.isProdPlanNotOnDesktop = true;
        // }
        // if (FORM_FACTOR == 'Large' && idAtrribute === 'tab-default-7__item') {
        //     this.isProdPlanOnDesktop = true;
        // }
        // if (FORM_FACTOR == 'Small' && idAtrribute === 'tab-default-7__item') {
        //     this.isProdPlanOnMobile = true;
        // }

        if (idAtrribute == 'tab-default-1__item') {
            this.isActiveOrders = true
            this.isClosedOrders = false;
            this.allOrders = false;
            this.isDraftOrders = false;
            this.isShippedOrders = false;
            this.isStockOrders = false;
            this.isProductionPlan = false;
            this.isStockOrProdPlan = false;
            this.isProdPlanOnMobile = false;
            this.isProdPlanOnDesktop = false;
            this.isProdPlanNotOnDesktop = false;
            this.closeAllOrderItems();

            this.searchBy();
        }
        if (idAtrribute == 'tab-default-2__item') {
            this.isClosedOrders = true
            this.isActiveOrders = false;
            this.allOrders = false;
            this.isDraftOrders = false;
            this.isShippedOrders = false;
            this.isStockOrders = false;
            this.isProductionPlan = false;
            this.isStockOrProdPlan = false;
            this.isProdPlanOnMobile = false;
            this.isProdPlanOnDesktop = false;
            this.isProdPlanNotOnDesktop = false;
            this.closeAllOrderItems();

            this.searchBy();
        }
        if (idAtrribute == 'tab-default-3__item') {
            this.allOrders = true
            this.isActiveOrders = false;
            this.isClosedOrders = false;
            this.isDraftOrders = false;
            this.isShippedOrders = false;
            this.isStockOrders = false;
            this.isProductionPlan = false;
            this.isStockOrProdPlan = false;
            this.isProdPlanOnMobile = false;
            this.isProdPlanOnDesktop = false;
            this.isProdPlanNotOnDesktop = false;
            this.closeAllOrderItems();

            this.searchBy();
        }
        if (idAtrribute == 'tab-default-4__item') {
            this.isDraftOrders = true;
            this.allOrders = false;
            this.isActiveOrders = false;
            this.isClosedOrders = false;
            this.isShippedOrders = false;
            this.isStockOrders = false;
            this.isProductionPlan = false;
            this.isStockOrProdPlan = false;
            this.isProdPlanOnMobile = false;
            this.isProdPlanOnDesktop = false;
            this.isProdPlanNotOnDesktop = false;
            this.closeAllOrderItems();

            this.searchBy();
        }
        if (idAtrribute == 'tab-default-5__item') {
            this.isShippedOrders = true
            this.allOrders = false;
            this.isActiveOrders = false;
            this.isClosedOrders = false;
            this.isDraftOrders = false;
            this.isStockOrders = false;
            this.isProductionPlan = false;
            this.isStockOrProdPlan = false;
            this.isProdPlanOnMobile = false;
            this.isProdPlanOnDesktop = false;
            this.isProdPlanNotOnDesktop = false;
            this.closeAllOrderItems();
            this.searchBy();
        }
        if (idAtrribute === 'tab-default-6__item') {
            this.isShippedOrders = false;
            this.allOrders = false;
            this.isActiveOrders = false;
            this.isClosedOrders = false;
            this.isDraftOrders = false;
            this.isStockOrders = true;
            this.isProductionPlan = false;
            this.isStockOrProdPlan = true;
            this.isProdPlanOnMobile = false;
            this.isProdPlanOnDesktop = false;
            this.isProdPlanNotOnDesktop = false;
            this.closeAllOrderItems();
            this.searchBy();
            this.template.querySelector('.datatable').classList.remove('not-stock-selected');
        }
        if (idAtrribute === 'tab-default-7__item') {
            this.isShippedOrders = false;
            this.allOrders = false;
            this.isActiveOrders = false;
            this.isClosedOrders = false;
            this.isDraftOrders = false;
            this.isStockOrders = false;
            this.isProductionPlan = true;
            this.isStockOrProdPlan = true;
            this.loadProductionPlanData();
            this.closeAllOrderItems();

            this.template.querySelector('.datatable').classList.remove('not-stock-selected');
            this.searchBy();
        }
    }

    filterByDate() {
        //var sortIcon = this.template.querySelector('[data-id="dateSortIcon"]');
        if (!this.dateSortToggled) {
            this.dateSortToggled = !this.dateSortToggled;
            this.stageSortToggled = false;
            this.numberSortToggled = false;
            this.template.querySelector('[data-id="dateSortIcon"]').classList.add('sort-icon-rotate');
            this.template.querySelector('[data-id="stageSortIcon"]').classList.remove('sort-icon-rotate')
            this.template.querySelector('[data-id="numberSortIcon"]').classList.remove('sort-icon-rotate')


        } else {
            this.dateSortToggled = !this.dateSortToggled;
            this.template.querySelector('[data-id="dateSortIcon"]').classList.remove('sort-icon-rotate')
            this.template.querySelector('[data-id="stageSortIcon"]').classList.remove('sort-icon-rotate')
            this.template.querySelector('[data-id="numberSortIcon"]').classList.remove('sort-icon-rotate')
        }
        try {
            var self = this;
            let arrayForSort = [...this.filteredOrdersList];
            arrayForSort.sort(function (a, b) {
                if (self.sortByDateAsc) {
                    return new Date(a.EffectiveDate) - new Date(b.EffectiveDate);
                } else {
                    return new Date(b.EffectiveDate) - new Date(a.EffectiveDate);
                }

            });
            this.filteredOrdersList = arrayForSort;
            this.sortByDateAsc = !this.sortByDateAsc;
        } catch (error) {
            console.log(error);
        }

    }

    filterByStage() {
        //var sortIcon = this.template.querySelector('[data-id="stageSortIcon"]');
        if (!this.stageSortToggled) {
            this.stageSortToggled = !this.stageSortToggled;
            this.dateSortToggled = false;
            this.numberSortToggled = false;
            this.template.querySelector('[data-id="stageSortIcon"]').classList.add('sort-icon-rotate');
            this.template.querySelector('[data-id="dateSortIcon"]').classList.remove('sort-icon-rotate')
            this.template.querySelector('[data-id="numberSortIcon"]').classList.remove('sort-icon-rotate')

        } else {
            this.stageSortToggled = !this.stageSortToggled;
            this.template.querySelector('[data-id="stageSortIcon"]').classList.remove('sort-icon-rotate')
            this.template.querySelector('[data-id="dateSortIcon"]').classList.remove('sort-icon-rotate')
            this.template.querySelector('[data-id="numberSortIcon"]').classList.remove('sort-icon-rotate')
        }
        try {
            var self = this;
            let arrayForSort = [...this.filteredOrdersList];
            arrayForSort.sort(function (a, b) {
                if (self.sortByStageAsc) {
                    return new String(a.Status).localeCompare(new String(b.Status));
                } else {
                    return new String(b.Status).localeCompare(new String(a.Status));
                }

            });
            this.filteredOrdersList = arrayForSort;
            this.sortByStageAsc = !this.sortByStageAsc;
        } catch (error) {
            console.log(error);
        }

        //console.log( this.filteredOrdersList);
    }

    filterByNumber() {
        //var sortIcon = this.template.querySelector('[data-id="numberSortIcon"]');
        if (!this.numberSortToggled) {
            this.numberSortToggled = !this.numberSortToggled;
            this.dateSortToggled = false;
            this.stageSortToggled = false;
            this.template.querySelector('[data-id="numberSortIcon"]').classList.add('sort-icon-rotate');
            this.template.querySelector('[data-id="dateSortIcon"]').classList.remove('sort-icon-rotate')
            this.template.querySelector('[data-id="stageSortIcon"]').classList.remove('sort-icon-rotate')
        } else {
            this.numberSortToggled = !this.numberSortToggled;
            this.template.querySelector('[data-id="numberSortIcon"]').classList.remove('sort-icon-rotate')
            this.template.querySelector('[data-id="dateSortIcon"]').classList.remove('sort-icon-rotate')
            this.template.querySelector('[data-id="stageSortIcon"]').classList.remove('sort-icon-rotate')
        }
        try {
            var self = this;
            let arrayForSort = [...this.filteredOrdersList];
            arrayForSort.sort(function (a, b) {
                if (self.sortByNumberAsc) {
                    return new String(a.AdditionalNumber__c).localeCompare(new String(b.AdditionalNumber__c));
                } else {
                    return new String(b.AdditionalNumber__c).localeCompare(new String(a.AdditionalNumber__c));
                }
            });
            this.filteredOrdersList = arrayForSort;
            this.sortByNumberAsc = !this.sortByNumberAsc;
        } catch (error) {
            console.log(error);
        }
    }

    //Modal setup
    @api
    modalContainer;

    openModal(event) {
        this.isModalOpen = true;
        this.selectedOrderid = event.target.dataset.id
        setTimeout(() => {
            this.modalContainer = this.template.querySelector('.slds-modal__container');
        }, 2000)
    }

    openModalDelivery(event) {
        this.isModalDeliveryOpen = true;
        this.orderDeliveryId = event.currentTarget.dataset.id;

        this.filteredOrdersList.forEach(item => {
            if(this.orderDeliveryId == item.Id) {
                this.isOrderDispatched = item.DispatchedQuantity__c != 0;
            }
        });

        setTimeout(() => {
            this.modalContainer = this.template.querySelector('.slds-modal__container');
        }, 2000)
    }

    closeModalDelivery() {
        this.isModalDeliveryOpen = false;
        this.isUserModalActive = false;
    }

    closeModal() {
        this.isModalOpen = false;
        this.isUserModalActive = false;
    }

    orderItemTableOppened = false;

    openOrderItem(event) {
        let docId = event.target.dataset.id;
        let icon = event.target;

        this.filteredOrdersList = this.filteredOrdersList.map(doc => {
            if (doc.Id == docId) {
                doc.expandDocuments = !doc.expandDocuments;
                if (doc.expandDocuments) {
                    icon.src = this.minusIcon;
                } else {
                    icon.src = this.plusIcon;
                }
            }
            return doc;
        })
        let parentIcon = this.template.querySelector('[data-id="headerIconPlusMinus"]');
        let numberOfOpened = this.filteredOrdersList.filter(docItem => docItem.expandDocuments).length
        if (numberOfOpened == this.filteredOrdersList.length) {
            parentIcon.src = this.minusIcon;
        } else {
            parentIcon.src = this.plusIcon;
        }
    }

    closeAllOrderItems() {
        this.filteredOrdersList = this.filteredOrdersList.map(doc => {
            doc.expandDocuments = false;
            return doc;
        })

        this.template.querySelectorAll('[data-state="extended"]').forEach(item => {
            item.src = this.plusIcon;
        })
    }

    openAllOrderItems(event) {
        let icon = event.target;

        this.filteredOrdersList = this.filteredOrdersList.map(doc => {
            if (icon.src.includes(this.minusIcon)) {
                doc.expandDocuments = false;
            } else {
                doc.expandDocuments = true;
            }
            return doc;
        });

        this.template.querySelectorAll('[data-icontype="subicon"]').forEach(item => {
            if (icon.src.includes(this.minusIcon)) {
                item.src = this.plusIcon;
            } else {
                item.src = this.minusIcon;
            }
        })

        if (icon.src.includes(this.minusIcon)) {
            icon.src = this.plusIcon;
        } else {
            icon.src = this.minusIcon;
        }
    }

    selectRowForXSLX(event) {
        let selectedItem;
        const isSelected = event.target.checked;
        if (isSelected) {
            selectedItem = this.filteredOrdersList.filter(item => item.Id === event.target.dataset.id)[0];
            this.selectedItemsToGenerateXSLX.push(selectedItem);
        } else {
            this.selectedItemsToGenerateXSLX = this.selectedItemsToGenerateXSLX.filter(item => item.Id != event.target.dataset.id);

        }
        if (this.filteredOrdersList.length == this.selectedItemsToGenerateXSLX.length) {
            this.template.querySelector('.selectAllRows').checked = true;
        } else {
            this.template.querySelector('.selectAllRows').checked = false;

        }

    }

    selectAllRowsForXSLX() {
        if (this.template.querySelector('.selectAllRows').checked == true) {
            this.template.querySelectorAll('.selectRow').forEach(item => {
                item.checked = true;
                this.selectedItemsToGenerateXSLX = this.filteredOrdersList;
            })
        } else {
            this.template.querySelectorAll('.selectRow').forEach(item => {
                this.selectedItemsToGenerateXSLX = [];
                item.checked = false;
            })

        }

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

    @track structuredPlans = [];

    loadProductionPlanData() {
        console.log('--- loadProductionPlanData START ---');
        console.log('isPortal:', this.isPortal);
        console.log('recordId:', this.recordId);

        getStructuredProdPlan({ isPortal: this.isPortal, recordId: this.recordId })
            .then(result => {
                console.log('Result from Apex:', JSON.parse(JSON.stringify(result, null, 2)));

                const cloned = JSON.parse(JSON.stringify(result));

                cloned.forEach(order => {
                    console.log('Processing order:', order.orderId, order.orderName);

                    let sumPlan = 0, sumFact = 0, sumBalance = 0;
                    let latestPlanDate = null, latestFactDate = null;

                    if (!order.items || order.items.length === 0) {
                        console.log('Order has no items:', order.orderId);
                    }

                    order.items.forEach(item => {
                        console.log('Processing item:', item.orderItemId, item.itemName);

                        console.log('Raw values - planQty:', item.planQty, 'factQty:', item.factQty, 'balance:', item.balance);
                        sumPlan += item.planQty || 0;
                        sumFact += item.factQty || 0;
                        sumBalance += item.balance || 0;

                        const plan = item.planDate ? this.parseDDMMYYYY(item.planDate) : null;
                        const fact = item.factDate ? this.parseDDMMYYYY(item.factDate) : null;

                        console.log('Parsed dates - plan:', plan, 'fact:', fact);

                        if (plan && (!latestPlanDate || plan > latestPlanDate)) latestPlanDate = plan;
                        if (fact && (!latestFactDate || fact > latestFactDate)) latestFactDate = fact;
                    });

                    order.totalPlanQty = Number(sumPlan.toFixed(3));
                    order.totalFactQty = Number(sumFact.toFixed(3));
                    order.totalBalance = Number(sumBalance.toFixed(3));
                    order.latestPlanDate = latestPlanDate
                        ? latestPlanDate.toISOString().split('T')[0].split('-').reverse().join('.')
                        : '---';
                    order.latestFactDate = latestFactDate
                        ? latestFactDate.toISOString().split('T')[0].split('-').reverse().join('.')
                        : '---';

                    console.log(`Order [${order.orderId}] totals - Plan: ${order.totalPlanQty}, Fact: ${order.totalFactQty}, Balance: ${order.totalBalance}`);
                    console.log(`Order [${order.orderId}] dates - Plan: ${order.latestPlanDate}, Fact: ${order.latestFactDate}`);
                });

                this.structuredPlans = cloned;
                console.log('Final structuredPlans:', JSON.stringify(this.structuredPlans, null, 2));
            })
            .catch(error => {
                console.error('Error loading production plan data', error);
            });
    }

    parseDDMMYYYY(dateStr) {
        const [dd, mm, yyyy] = dateStr.split('.');
        const iso = `${yyyy}-${mm}-${dd}`;
        const date = new Date(iso);
        return isNaN(date.getTime()) ? null : date;
    }

    toggleItem(event) {
        const itemId = event.currentTarget.dataset.id;

        const months = this.template.querySelectorAll(`.month-row[data-item-id="${itemId}"]`);
        const weeks = this.template.querySelectorAll(`.week-row[data-item-id="${itemId}"]`);

        const isAnyMonthVisible = Array.from(months).some(el => !el.classList.contains('hidden'));
        const isAnyWeekVisible = Array.from(weeks).some(el => !el.classList.contains('hidden'));

        const shouldHideAll = isAnyMonthVisible || isAnyWeekVisible;

        if (shouldHideAll) {
            months.forEach(el => el.classList.add('hidden'));
            weeks.forEach(el => el.classList.add('hidden'));

            // скинути всі іконки місяців
            const monthIcons = this.template.querySelectorAll(`.month-icon[data-item-id="${itemId}"]`);
            monthIcons.forEach(icon => icon.classList.remove('rotate'));
        } else {
            months.forEach(el => el.classList.remove('hidden'));
        }

        // оновити іконку item
        const itemIcon = this.template.querySelector(`.item-icon[data-id="${itemId}"]`);
        if (itemIcon) {
            itemIcon.classList.toggle('rotate', !shouldHideAll);
        }
    }




    toggleMonth(event) {
        const itemId = event.currentTarget.dataset.itemId;
        const monthKey = event.currentTarget.dataset.monthKey;

        const weeks = this.template.querySelectorAll(`.week-row[data-item-id="${itemId}"][data-month-key="${monthKey}"]`);
        const isAnyWeekVisible = Array.from(weeks).some(el => !el.classList.contains('hidden'));

        weeks.forEach(el => el.classList.toggle('hidden'));

        // оновлення іконки
        const icon = this.template.querySelector(`.month-icon[data-item-id="${itemId}"][data-month-key="${monthKey}"]`);
        if (icon) {
            icon.classList.toggle('rotate', !isAnyWeekVisible);
        }

        event.stopPropagation(); // блокує toggleItem
    }

    toggleOrder(event) {
        console.log('--- toggleOrder triggered ---');

        const row = event.target.closest('.order-row');
        if (!row) {
            console.warn('No .order-row found for event target');
            return;
        }

        const orderId = row.dataset.id;
        console.log('Toggled orderId:', orderId);

        const itemRows = this.template.querySelectorAll(`.order-item-row[data-order-id="${orderId}"]`);
        console.log('Found itemRows count:', itemRows.length);

        const shouldHide = Array.from(itemRows).some(el => !el.classList.contains('hidden'));
        console.log('Should hide itemRows:', shouldHide);

        itemRows.forEach(itemRow => {
            const itemId = itemRow.dataset.id;
            console.log('Toggling itemId:', itemId);

            itemRow.classList.toggle('hidden', shouldHide);

            const monthRows = this.template.querySelectorAll(`.month-row[data-item-id="${itemId}"]`);
            console.log('Found monthRows count:', monthRows.length);
            monthRows.forEach(month => {
                month.classList.add('hidden');
            });

            const weekRows = this.template.querySelectorAll(`.week-row[data-item-id="${itemId}"]`);
            console.log('Found weekRows count:', weekRows.length);
            weekRows.forEach(week => {
                week.classList.add('hidden');
            });

            const monthIcons = this.template.querySelectorAll(`.month-icon[data-item-id="${itemId}"]`);
            console.log('Found monthIcons count:', monthIcons.length);
            monthIcons.forEach(icon => icon.classList.remove('rotate'));

            const itemIcon = this.template.querySelector(`.item-icon[data-id="${itemId}"]`);
            if (itemIcon) {
                console.log('Found itemIcon for itemId:', itemId);
                if (shouldHide) {
                    itemIcon.classList.remove('rotate');
                    console.log('Removed rotate from itemIcon');
                }
            } else {
                console.warn('No itemIcon found for itemId:', itemId);
            }
        });

        const icon = this.template.querySelector(`.order-icon[data-id="${orderId}"]`);
        if (icon) {
            icon.classList.toggle('rotate', !shouldHide);
            console.log('Toggled rotate on order icon:', !shouldHide);
        } else {
            console.warn('No order icon found for orderId:', orderId);
        }
    }



}