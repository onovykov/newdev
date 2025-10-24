// file: lwc/currencyRatesDashboard/currencyRatesDashboard.js
import { LightningElement, api, wire, track } from 'lwc';
import getRates from '@salesforce/apex/CurrencyRatesDashboardCtrl.getRates';
import refreshFromNbu from '@salesforce/apex/CurrencyRatesDashboardCtrl.refreshFromNbu';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class CurrencyRatesDashboard extends LightningElement {
  @api excludeCurrencies; // "BYN,RUB"
  @api updateDcr = false; // expose toggle if needed
  @track data = [];
  corporateIso = 'USD';
  generatedAt;
  wiredResult;
  updating = false;

  get title() { return `Курси валют (за 1 ${this.corporateIso})`; }
  get hasData() { return this.data && this.data.length > 0; }

  get excludeList() {
    if (!this.excludeCurrencies) return [];
    return this.excludeCurrencies.split(',').map(s => s.trim()).filter(Boolean);
  }

  @wire(getRates, { excludeIsos: '$excludeList' })
  wired(resp) {
    this.wiredResult = resp;
    const { data, error } = resp;
    if (data) {
      this.applyResp(data);
    } else if (error) {
      this.showError(error);
    }
  }

  applyResp(data) {
    this.corporateIso = data.corporateIso || 'USD';
    this.generatedAt = data.generatedAt;
    this.data = (data.rows || []).map((r, idx) => ({
      id: `${r.iso}-${idx}`,
      iso: r.iso,
      rate: (r.rate != null ? Number(r.rate).toFixed(2) : ''),
      lastModified: r.lastModified
    }));
  }

  async handleRefresh() {
    try {
      await refreshApex(this.wiredResult);
    } catch (e) {
      this.showError(e);
    }
  }

  async handleUpdateOnline() {
    this.updating = true;
    try {
      const resp = await refreshFromNbu({ updateCT: true, updateDCR: this.updateDcr, excludeIsos: this.excludeList });
      if (resp) this.applyResp(resp);
      this.dispatchEvent(new ShowToastEvent({ title: 'Готово', message: 'Курси оновлено з НБУ', variant: 'success' }));
    } catch (e) {
      this.showError(e);
    } finally {
      this.updating = false;
    }
  }

  showError(e) {
    let msg = 'Невідома помилка';
    if (e && e.body && e.body.message) msg = e.body.message;
    else if (typeof e === 'string') msg = e;
    this.dispatchEvent(new ShowToastEvent({ title: 'Помилка', message: msg, variant: 'error' }));
    // eslint-disable-next-line no-console
    console.error(e);
  }
}