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

    get isPortalForWire() {
        // true/false для порталу; якщо не можемо визначити — undefined (тоді wire не виконається)
        try { return window.location.href.includes('/s/'); } catch(e){ return undefined; }
    }
    get recordIdForWire() {
        // Для порталу recordId не потрібен -> явно повертаємо null.
        // Для внутрішнього випадку — чекаємо, поки з’явиться this.recordId (інакше undefined, wire не викличеться).
        const onPortal = this.isPortalForWire === true;
        if (onPortal) return null;
        return this.recordId || undefined;
    }


    @wire(getOrders, { isPortal: '$isPortalForWire', recordId: '$recordIdForWire' })
    handleOrders(result) {
        this.ordersResult = result;
        const {error, data} = result;
        if (data) {
            let dataCopy = this.deepCopy(data);

            getUserMarketSegment().then(result => {
                this.userMarketSegment = result;
                this.isKLWSegment = this.userMarketSegment === '00006';

                dataCopy.forEach(item => {
                    if (item.Status === 'Activated') {
                        item.Status = 'Active';
                    }
                    if (!item.PO_Number__c) {
                        item.PO_Number__c = item.AdditionalNumber__c;
                    }

                    // форматуємо тони через хелпер
                    item.TotalOrderQuantity__c = this.formatTons(item.TotalOrderQuantity__c);
                    item.ProducedQuantity__c   = this.formatTons(item.ProducedQuantity__c);
                    item.ShippedQuantity__c    = this.formatTons(item.ShippedQuantity__c);

                    const disp = Number(item.DispatchedQuantity__c);
                    item.DispatchedQuantity__c = this.formatTons(disp < 0 ? 0 : disp);

                    // pcs як і було — цілі
                    item.Quantity_pcs__c          = item.Quantity_pcs__c ? item.Quantity_pcs__c.toFixed(0) : 0;
                    item.ProducedQuantity_pcs__c  = item.ProducedQuantity_pcs__c ? item.ProducedQuantity_pcs__c.toFixed(0) : 0;
                    item.DispatchedQuantity_pcs__c= item.DispatchedQuantity_pcs__c ? item.DispatchedQuantity_pcs__c.toFixed(0) : 0;
                    item.DeliveredQuantity_pcs__c = item.DeliveredQuantity_pcs__c ? item.DeliveredQuantity_pcs__c.toFixed(0) : 0;

                    // stock на рівні ордера (числом → потім формат)
                    const orderStock = Number(item.ProducedQuantity__c) - Number(item.ShippedQuantity__c);
                    item.Stock = this.formatTons(orderStock);

                    // ініціалізація сум — числові!
                    item.BalanceForShipment   = 0;
                    item.BalanceForProduction = 0;
                    item.MonthlyProdPlan      = 0;
                    item.WeeklyProdPlan       = 0;
                    item.EstimatedProdBalance = 0;

                    item.expandDocuments = false;

                    if (!item.OrderItems) return;

                    if (item.OrderItems) {
                        item.OrderItems = item.OrderItems.map(ordItem => {
                            // кількість
                            ordItem.Quantity = this.formatTons(ordItem.Quantity);

                            // stock по айтему
                            const oiStock = Number(ordItem.ProducedQuantity__c) - Number(ordItem.DispatchedQuantity__c);
                            ordItem.Stock = this.formatTons(oiStock);

                            // баланс до відвантаження по айтему
                            const bfs = Number(ordItem.Quantity) - Number(ordItem.ShippedQuantity__c);
                            ordItem.BalanceForShipment = this.formatTons(bfs < 0 ? 0 : bfs);

                            // сумуємо в ордер: тільки числовими значеннями
                            if (Number(oiStock) !== 0) {
                                item.BalanceForShipment += Number(ordItem.BalanceForShipment);
                            }

                            if (
                                ordItem.WeekStartDate__c != null &&
                                (Number(ordItem.WeeklyProdPlan__c)       !== 0 ||
                                    Number(ordItem.MonthlyProdPlan__c)      !== 0 ||
                                    Number(ordItem.BalanceForProduction__c) !== 0 ||
                                    Number(ordItem.Estimated_Prod_Balance__c) !== 0)
                            ) {
                                item.BalanceForProduction += Number(ordItem.BalanceForProduction__c || 0);
                                item.MonthlyProdPlan      += Number(ordItem.MonthlyProdPlan__c      || 0);
                                item.WeeklyProdPlan       += Number(ordItem.WeeklyProdPlan__c       || 0);
                                item.EstimatedProdBalance += Number(ordItem.Estimated_Prod_Balance__c || 0);
                                this.prodPlanStartDate = ordItem.WeekStartDate__c;
                                this.prodPlanEndDate   = ordItem.WeekEndDate__c;
                            }

                            return ordItem;
                        });

                        item.BalanceForShipment   = this.formatTons(item.BalanceForShipment);
                        item.BalanceForProduction = this.formatTons(item.BalanceForProduction);
                        item.MonthlyProdPlan      = this.formatTons(item.MonthlyProdPlan);
                        item.WeeklyProdPlan       = this.formatTons(item.WeeklyProdPlan);
                        item.EstimatedProdBalance = this.formatTons(item.EstimatedProdBalance);

                        item.OrderNumberProdPlan = item.AdditionalNumber__c + ' | ' + item.PO_Number__c;

                        item.OrderItemsForProdPlan = item.OrderItems.filter(oi => {
                            return oi.WeekStartDate__c != null && (
                                Number(oi.WeeklyProdPlan__c)       !== 0 ||
                                Number(oi.MonthlyProdPlan__c)      !== 0 ||
                                Number(oi.BalanceForProduction__c) !== 0 ||
                                Number(oi.Estimated_Prod_Balance__c) !== 0
                            );
                        });

                        item.OrderItems = item.OrderItems.filter(oi => Number(oi.Stock) !== 0);

                        if (this.userMarketSegment == '00011') {
                            const hasNMPP = item.OrderItems.some(oi => oi.Shop__r?.Plant__r?.Name === 'NMPP');
                            if (hasNMPP) {
                                item.ProducedQuantity__c = item.ShippedQuantity__c;
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
            console.error('getOrders ERROR =', JSON.parse(JSON.stringify(error)));

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
            console.log('jsPDF loaded successfully');
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
            this.isProdPlanVisible = true;
            this.isStockVisible = false;
            this.isProductionPlan = true;

            this.options = [
                { id: 'tab-default-7__item', label: this.productionPlan, order: 1 }
            ];
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
        const base = Array.isArray(this.ordersList) ? this.ordersList : [];
        this.filteredOrdersList = [...base];

        if (this.searchKey) {
            const needle = this.searchKey.toLowerCase();
            this.filteredOrdersList = this.filteredOrdersList.filter(rec =>
                Object.values(rec || {}).some(v => String(v ?? '').toLowerCase().includes(needle))
            );
        }

        if (this.startDate) {
            this.filteredOrdersList = this.filteredOrdersList.filter(o => o.EffectiveDate >= this.startDate);
        }
        if (this.endDate) {
            this.filteredOrdersList = this.filteredOrdersList.filter(o => o.EffectiveDate <= this.endDate);
        }

        if (this.allOrders) {
            this.amountAllOrders = this.filteredOrdersList.length;
        }
        if (this.isActiveOrders) {
            this.filteredOrdersList = this.filteredOrdersList.filter(o => o.Status === 'Active');
            this.amountActiveOrders = this.filteredOrdersList.length;
        }
        if (this.isClosedOrders) {
            this.filteredOrdersList = this.filteredOrdersList.filter(o => o.Status === 'Closed');
            this.amountClosedOrders = this.filteredOrdersList.length;
        }
        if (this.isDraftOrders) {
            this.filteredOrdersList = this.filteredOrdersList.filter(o => o.Status === 'Draft');
            this.amountDraftOrders = this.filteredOrdersList.length;
        }
        if (this.isShippedOrders) {
            this.filteredOrdersList = this.filteredOrdersList.filter(o => o.ShippedQuantity__c != 0 && o.Status !== 'Closed');
            this.amountShippedOrders = this.filteredOrdersList.length;
        }
        if (this.isStockOrders) {
            this.filteredOrdersList = this.filteredOrdersList.filter(o => Number(o.Stock) > 0);
        }
        if (this.isProductionPlan) {
            const visibleIds = new Set((this.structuredPlans || []).map(o => o.orderId));
            this.filteredOrdersList = this.filteredOrdersList.filter(o => visibleIds.has(o.Id));
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
        getStructuredProdPlan({ isPortal: this.isPortal, recordId: this.recordId })
            .then(result => {
                const cloned = JSON.parse(JSON.stringify(result || []));
                this.structuredPlans = this.filterForView(cloned);
                this.normalizePlansForDisplay();

                // ↓↓↓ ДОДАТИ ОДРАЗУ ПІСЛЯ normalizePlansForDisplay()
                this.structuredPlans = (this.structuredPlans || []).map(order => {
                    order.items = (order.items || []).map(oi => {
                        const m = (oi.months || [])[0]; // перший видимий місяць (після filterForView)
                        if (m) {
                            // дублюємо показники місяця в рядок item
                            oi.balance  = m.balance;       // Balance for Production (t)
                            oi.planQty  = m.monthlyPlan;   // Monthly Plan Qty (t)
                            oi.factQty  = m.factQty;       // Fact Qty (t)
                            oi.planDate = m.planDate;      // Plan Date
                            oi.factDate = m.factDate;      // Fact Date
                        } else {
                            // якщо немає місяців — ставимо прочерки/нулями як у тебе прийнято
                            oi.balance  = '---';
                            oi.planQty  = '---';
                            oi.factQty  = '---';
                            oi.planDate = '---';
                            oi.factDate = '---';
                        }
                        return oi;
                    });
                    return order;
                });


                // Після normalize:
                // Після this.normalizePlansForDisplay();
                const totalsByOrderId = new Map(
                    (this.structuredPlans || []).map(o => [
                        o.orderId,
                        {
                            balanceForProduction: o.balanceForProduction, // т
                            monthlyPlanQty:       o.monthlyPlanQty,       // т
                            factQty:              o.factQty,              // т
                            planDate:             o.planDate,
                            factDate:             o.factDate
                        }
                    ])
                );

                if (Array.isArray(this.ordersList)) {
                    this.ordersList = this.ordersList.map(ord => {
                        const t = totalsByOrderId.get(ord.Id);
                        if (t) {
                            ord.BalanceForProduction      = Number.isFinite(+t.balanceForProduction) ? (+t.balanceForProduction).toFixed(3) : '---';
                            ord.MonthlyProdPlan           = Number.isFinite(+t.monthlyPlanQty)       ? (+t.monthlyPlanQty).toFixed(3)       : '---';
                            // якщо хочеш показувати факт у верхній таблиці — вибери куди його класти:
                            ord.WeeklyProdPlan            = Number.isFinite(+t.factQty)              ? (+t.factQty).toFixed(3)              : '---';
                            // або ord.EstimatedProdBalance = ...

                            // дати — додай колонки в шаблон, якщо треба показувати:
                            ord.ProdPlan_LatestPlanDate   = t.planDate || '---';
                            ord.ProdPlan_LatestFactDate   = t.factDate || '---';
                        }
                        return ord;
                    });
                }


                if (Array.isArray(this.ordersList)) {
                    this.ordersList = this.ordersList.map(ord => {
                        const t = totalsByOrderId.get(ord.Id);
                        if (t) {
                            // ці поля вже є у вашій розмітці під Production Plan
                            ord.BalanceForProduction = t.balance;      // т
                            ord.MonthlyProdPlan      = t.monthPlan;    // т
                            // якщо хочете показувати ФАКТ у верхній таблиці — використайте одну з колонок:
                            // наприклад, замінити WeeklyProdPlan або EstimatedProdBalance на factQty/дати
                            ord.WeeklyProdPlan       = t.fact;         // т (за бажанням)
                            ord.EstimatedProdBalance = t.fact;         // або сюди, якщо Weekly лишаєте як є

                            // якщо в шапці треба ще дати — додайте нові поля і в шаблон:
                            ord.ProdPlan_LatestPlanDate = t.planDate;  // 'dd.MM.yyyy' або '---'
                            ord.ProdPlan_LatestFactDate = t.factDate;  // 'dd.MM.yyyy' або '---'
                        }
                        return ord;
                    });
                }


                if (Array.isArray(this.ordersList) && this.ordersList.length) {
                    this.searchBy();
                }
            })
            .catch(() => {
                this.structuredPlans = [];
                if (Array.isArray(this.ordersList) && this.ordersList.length) {
                    this.searchBy();
                }
            });
    }

    formatTons(v) {
        if (v === null || v === undefined || v === '' || Number.isNaN(Number(v))) return '---';
        const n = Number(v);
        const isInt = Math.abs(n - Math.trunc(n)) < 1e-9;
        return isInt ? String(Math.trunc(n)) : n.toFixed(3);
    }


    filterForView(orders) {
        const today = new Date();

        // межі поточного місяця (UTC)
        const startOfMonth = new Date(Date.UTC(today.getUTCFullYear(), today.getUTCMonth(), 1));
        const endOfMonth   = new Date(Date.UTC(today.getUTCFullYear(), today.getUTCMonth()+1, 0));
        const ymNow = `${today.getUTCFullYear()}-${String(today.getUTCMonth()+1).padStart(2,'0')}`;

        // тижневе вікно для порталу: цей + наступний тиждень
        const monday = d => { const x=new Date(Date.UTC(d.getUTCFullYear(),d.getUTCMonth(),d.getUTCDate())); const wd=(x.getUTCDay()+6)%7; x.setUTCDate(x.getUTCDate()-wd); return x; };
        const addDays = (d,n)=>{ const x=new Date(d); x.setUTCDate(x.getUTCDate()+n); return x; };
        const thisWeekStart = monday(today);
        const thisWeekEnd   = addDays(thisWeekStart,6);
        const nextWeekStart = addDays(thisWeekStart,7);
        const nextWeekEnd   = addDays(nextWeekStart,6);

        const inMonth = d => d>=startOfMonth && d<=endOfMonth;
        const inPortalWindow = d => (d>=thisWeekStart && d<=thisWeekEnd) || (d>=nextWeekStart && d<=nextWeekEnd);

        const parseDDMMYYYY = s => {
            if (!s || s === '---') return null;
            const [dd,mm,yyyy] = s.split('.');
            const dt = new Date(`${yyyy}-${mm}-${dd}T00:00:00Z`);
            return isNaN(dt.getTime()) ? null : dt;
        };

        (orders || []).forEach(o => {
            (o.items || []).forEach(it => {
                // 1) фільтруємо тижні
                (it.months || []).forEach(m => {
                    m.weeks = (m.weeks || []).filter(w => {
                        const d = parseDDMMYYYY(w.planDate) || parseDDMMYYYY(w.factDate);
                        if (!d) return false;
                        return this.isPortal ? inPortalWindow(d) : inMonth(d);
                    });
                });

                // 2) фільтруємо місяці
                it.months = (it.months || []).filter(m => {
                    if (this.isPortal) {
                        // на порталі показуємо тільки місяці, де є видимі тижні у вікні
                        return m.weeks && m.weeks.length > 0;
                    } else {
                        // внутрішній користувач: тільки поточний місяць (навіть без тижнів)
                        return m.key === ymNow;
                    }
                });
            });
        });

        return orders;
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
        const row = event.target.closest('.order-row');
        if (!row) {
            console.warn('No .order-row found for event target');
            return;
        }

        const orderId = row.dataset.id;

        const itemRows = this.template.querySelectorAll(`.order-item-row[data-order-id="${orderId}"]`);

        const shouldHide = Array.from(itemRows).some(el => !el.classList.contains('hidden'));

        itemRows.forEach(itemRow => {
            const itemId = itemRow.dataset.id;

            itemRow.classList.toggle('hidden', shouldHide);

            const monthRows = this.template.querySelectorAll(`.month-row[data-item-id="${itemId}"]`);
            monthRows.forEach(month => {
                month.classList.add('hidden');
            });

            const weekRows = this.template.querySelectorAll(`.week-row[data-item-id="${itemId}"]`);
            weekRows.forEach(week => {
                week.classList.add('hidden');
            });

            const monthIcons = this.template.querySelectorAll(`.month-icon[data-item-id="${itemId}"]`);
            monthIcons.forEach(icon => icon.classList.remove('rotate'));

            const itemIcon = this.template.querySelector(`.item-icon[data-id="${itemId}"]`);
            if (itemIcon) {
                if (shouldHide) {
                    itemIcon.classList.remove('rotate');
                }
            } else {
                console.warn('No itemIcon found for itemId:', itemId);
            }
        });

        const icon = this.template.querySelector(`.order-icon[data-id="${orderId}"]`);
        if (icon) {
            icon.classList.toggle('rotate', !shouldHide);
        } else {
            console.warn('No order icon found for orderId:', orderId);
        }
    }


    normalizePlansForDisplay() {
        const fmtNum  = (v) => this.formatTons(v);
        const fmtDate = v => (v && v !== '' ? v : '---');

        (this.structuredPlans || []).forEach(order => {
            order.totalBalance      = fmtNum(order.totalBalance);
            order.totalMonthPlanQty = fmtNum(order.totalMonthPlanQty);
            order.totalFactQty      = fmtNum(order.totalFactQty);
            order.latestPlanDate    = fmtDate(order.latestPlanDate);
            order.latestFactDate    = fmtDate(order.latestFactDate);

            (order.items || []).forEach(oi => {
                oi.balance  = fmtNum(oi.balance);
                oi.planQty  = fmtNum(oi.planQty);
                oi.factQty  = fmtNum(oi.factQty);
                oi.planDate = fmtDate(oi.planDate);
                oi.factDate = fmtDate(oi.factDate);

                (oi.months || []).forEach(m => {
                    m.balance     = fmtNum(m.balance);
                    m.monthlyPlan = fmtNum(m.monthlyPlan);
                    m.factQty     = fmtNum(m.factQty);
                    m.planDate    = fmtDate(m.planDate);
                    m.factDate    = fmtDate(m.factDate);

                    (m.weeks || []).forEach(w => {
                        w.balance  = w.balance ?? '-';
                        w.planQty  = fmtNum(w.planQty);
                        w.factQty  = fmtNum(w.factQty);
                        w.planDate = fmtDate(w.planDate);
                        w.factDate = fmtDate(w.factDate);
                    });
                });
            });
        });
    }

}