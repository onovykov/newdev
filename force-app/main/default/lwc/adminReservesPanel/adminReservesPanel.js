import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getCurrentDecadePlan from '@salesforce/apex/IntakePlanService.getCurrentDecadePlan';


export default class AdminReservesPanel extends LightningElement {
    @track groupedData = [];
    @track isLoading = false;

    connectedCallback() {
        this.load();
    }

    async load() {
        this.isLoading = true;
        try {
            const data = await getCurrentDecadePlan();
            this.groupedData = (data || []).map(g => ({
                ...g,
                date: g.dateStr,      // для {group.date}
                open: g.open === true // беремо дефолт з Apex (минулі згорнуті, сьогодні відкритий)
            }));
        } catch (e) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Помилка завантаження',
                message: e?.body?.message || e?.message || 'Не вдалося отримати план приймання.',
                variant: 'error'
            }));
        } finally {
            this.isLoading = false;
        }
    }


    toggleSection = (evt) => {
        const idx = Number(evt.currentTarget.dataset.index);
        this.groupedData = this.groupedData.map((g, i) =>
            i === idx ? { ...g, open: !g.open } : g
        );
    };

    handleClick(event) {
        const row = event.currentTarget.dataset;
        // твоя логіка по кліку (перехід/модалка тощо)
    }
}