import { LightningElement, wire, api } from 'lwc';
import getAvailableReportsForUser from '@salesforce/apex/PowerBIReportService.getAvailableReportsForUser';
import noHeader from '@salesforce/resourceUrl/NoLightningAppHeader';
import { loadStyle } from 'lightning/platformResourceLoader';

export default class PowerBiEmbed extends LightningElement {
    reports = [];

    @api reportUrl = 'asdfghjkl';

    connectedCallback() {
        loadStyle(this, noHeader);
    }

    @wire(getAvailableReportsForUser)
    wiredReports({ data, error }) {
        console.log('[PowerBI] Вхід у wiredReports');
        if (data) {
            console.log('[PowerBI] Отримано звіти з Apex:', data);
            this.reports = data;
        } else {
            this.reports = [];
        }
    }

    validateUrl(url) {
        try {
            const parsed = new URL(url);
            return (
                parsed.hostname === 'app.powerbi.com' &&
                parsed.pathname.startsWith('/reportEmbed') &&
                parsed.searchParams.has('reportId')
            );
        } catch (e) {
            return false;
        }
    }

    get visibleReports() {
        return this.reports.map(report => ({
            ...report,
            isValidUrl: this.validateUrl(report.url),
            isValidUrl2: this.validateUrl(report.url2),
            isValidUrl3: this.validateUrl(report.url3)
        }));
    }

    get hasReports() {
        return this.visibleReports.length > 0;
    }
}