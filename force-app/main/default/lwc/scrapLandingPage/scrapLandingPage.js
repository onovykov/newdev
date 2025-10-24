import { LightningElement } from 'lwc';
import SCRAP from '@salesforce/resourceUrl/scrap_assets';

export default class ScrapLandingPage extends LightningElement {
    _imgsDone = false;

    openPopup = () => {
        const pop = this.template.querySelector('.popup');
        if (pop) pop.style.display = 'block';
    };
    closePopup = () => {
        const pop = this.template.querySelector('.popup');
        if (pop) pop.style.display = 'none';
    };

    _onScroll = () => {
        const btn = this.template.querySelector('.back-to-top');
        if (!btn) return;
        btn.style.display = window.scrollY > 300 ? 'block' : 'none';
    };

    connectedCallback() {
        window.addEventListener('scroll', this._onScroll, { passive: true });
    }
    disconnectedCallback() {
        window.removeEventListener('scroll', this._onScroll);
    }

    renderedCallback() {
        if (this._imgsDone) return;
        this._imgsDone = true;
        this.template.querySelectorAll('img[data-rsrc]').forEach(img => {
            const primary = `${SCRAP}/${img.dataset.rsrc}`;
            const fallback = `${SCRAP}/scrap_assets/${img.dataset.rsrc}`;
            img.onerror = () => { if (img.src !== fallback) img.src = fallback; };
            img.src = primary;
        });
    }
}