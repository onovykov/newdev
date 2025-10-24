// file: lwc/currencyRatesLite/currencyRatesLite.js
import { LightningElement, api, wire, track } from 'lwc';
import getRates from '@salesforce/apex/CurrencyRatesDashboardCtrl.getRates';
import { refreshApex } from '@salesforce/apex';

export default class CurrencyRatesLite extends LightningElement {
  @api excludeCurrencies; // e.g. "BYN,RUB"
  @track data = [];
  corporateIso = 'USD';
  generatedAt;
  wiredResult;
  refreshing = false;

  get title() { return 'Currency Rates (per 1 USD)'; }
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
      this.corporateIso = data.corporateIso || 'USD';
      this.generatedAt = data.generatedAt;
      this.data = (data.rows || []).map((r, idx) => ({
        id: `${r.iso}-${idx}`,
        iso: r.iso,
        rate: (r.rate != null ? Number(r.rate).toFixed(2) : ''),
        lastModified: r.lastModified
      }));
    } else if (error) {
      // eslint-disable-next-line no-console
      console.error(error);
      this.data = [];
    }
  }

  async handleRefresh() {
    this.refreshing = true;
    try {
      await refreshApex(this.wiredResult);
    } catch (e) {
      // eslint-disable-next-line no-console
      console.error(e);
    } finally {
      this.refreshing = false;
    }
  }
}