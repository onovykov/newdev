import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// ⬇️ замість listUnapproved використовуємо спрощений метод
import listUnapprovedForPeriod from '@salesforce/apex/ScrapAdminLimitRequestService.listUnapprovedForPeriod';
import approve from '@salesforce/apex/ScrapAdminLimitRequestService.approve';

export default class ScrapAdminLimitRequestPanel extends LightningElement {
    @track requests = [];

    @track isLoading = false;

    monthNamesUkr = [
        'Січень','Лютий','Березень','Квітень','Травень','Червень',
        'Липень','Серпень','Вересень','Жовтень','Листопад','Грудень'
    ];
    monthNumberToUkr(n){ return this.monthNamesUkr[(Number(n) || 1) - 1]; }

    connectedCallback(){ this.loadDataBothMonths(); }

    get hasRequests(){ return this.requests?.length > 0; }

    get currentMonthLabel() {
        const now = new Date();
        return `${this.monthNamesUkr[now.getMonth()]}`;
    }
    // get nextMonthLabel() {
    //     const now = new Date();
    //     const m = now.getMonth(), y = now.getFullYear();
    //     const nextMonth = (m + 1) % 12;
    //     const nextYear = m === 11 ? y + 1 : y;
    //     return `${this.monthNamesUkr[nextMonth]} ${nextYear}`;
    // }

    // async loadData(opts = {}) {
    //     try {
    //         // якщо хочеш специфічний період — виклич інший метод:
    //         // const data = await listUnapprovedForPeriod({ yearNum, monthNum });
    //         console.log('===========loadData===========')
    //         const data = await listUnapprovedForPeriod(); // поточний місяць
    //
    //         this.requests = (data || []).map((r, i) => {
    //             // формат дати
    //             const created = new Date(r.createdDate);
    //             const createdLabel =
    //                 `${String(created.getDate()).padStart(2,'0')}.${String(created.getMonth()+1).padStart(2,'0')}.${created.getFullYear()} ` +
    //                 `${String(created.getHours()).padStart(2,'0')}:${String(created.getMinutes()).padStart(2,'0')}`;
    //
    //             const d1 = Number(r.dec1 ?? 0);
    //             const d2 = Number(r.dec2 ?? 0);
    //             const d3 = Number(r.dec3 ?? 0);
    //
    //             return {
    //                 id: String(i + 1),
    //                 supplierLimitId: r.parentId,     // ← з Apex
    //                 createdDateLabel: createdLabel,
    //                 supplier: r.supplierName,
    //
    //                 dec1: d1,
    //                 dec2: d2,
    //                 dec3: d3,
    //                 monthTotal: d1 + d2 + d3,      // ← СУМА ДЕКАД
    //
    //                 // ids деталей — потрібні для approve
    //                 detailDec1Id: r.detailDec1Id || null,
    //                 detailDec2Id: r.detailDec2Id || null,
    //                 detailDec3Id: r.detailDec3Id || null,
    //
    //                 // місяць як текст з номера або з monthTxt
    //                 monthLabel: this.monthNumberToUkr(r.monthNum ?? Number(r.monthTxt)),
    //
    //                 // для модалки залишаємо структуру як є
    //                 approved: { dec1: null, dec2: null, dec3: null },
    //                 preview:  { dec1: null, dec2: null, dec3: null },
    //             };
    //         });
    //
    //         if (!this.requests.length) {
    //             this.dispatchEvent(new ShowToastEvent({
    //                 title: 'Дані',
    //                 message: 'Наразі немає неузгоджених заявок за поточний місяць.',
    //                 variant: 'info'
    //             }));
    //         }
    //     } catch (e) {
    //         this.dispatchEvent(new ShowToastEvent({
    //             title: 'Помилка завантаження',
    //             message: e.body?.message || e.message,
    //             variant: 'error'
    //         }));
    //     }
    // }

    async loadDataBothMonths(){
        try{
            this.isLoading = true;

            const now = new Date();
            const y1 = now.getFullYear(), m1 = now.getMonth() + 1;
            const next = new Date(y1, m1, 1);
            const y2 = next.getFullYear(), m2 = next.getMonth() + 1;

            // тягнемо одразу обидва місяці
            const [cur, nxt] = await Promise.all([
                listUnapprovedForPeriod({ yearNum: y1, monthNum: m1 }),
                listUnapprovedForPeriod({ yearNum: y2, monthNum: m2 }),
            ]);

            // мерджимо й сортуємо за датою створення (нові згори)
            const data = [...(cur || []), ...(nxt || [])]
                .sort((a, b) => new Date(b.createdDate) - new Date(a.createdDate));

            this.requests = data.map((r) => {
                const dt = new Date(r.createdDate);
                const createdLabel = dt.toLocaleString('uk-UA', {
                    year: 'numeric', month: '2-digit', day: '2-digit',
                    hour: '2-digit', minute: '2-digit'
                });

                const d1 = Number(r.dec1 ?? 0);
                const d2 = Number(r.dec2 ?? 0);
                const d3 = Number(r.dec3 ?? 0);

                const mNum = (r.monthNum ?? Number(r.monthTxt));
                const yTxt = r.yearTxt ?? String(now.getFullYear()); // запасний варіант
                const periodLabel = `${this.monthNumberToUkr(mNum)} ${yTxt}`;

                const isNext = (Number(yTxt) === y2 && Number(mNum) === m2);
                const periodClass = isNext ? 'badge-next' : 'badge-current';


                return {
                    parentId: r.parentId,                 // стабільний ключ
                    supplierLimitId: r.parentId,
                    createdDateLabel: createdLabel,
                    supplier: r.supplierName,
                    periodLabel,                          // НОВЕ
                    periodClass,
                    dec1: d1, dec2: d2, dec3: d3,
                    monthTotal: d1 + d2 + d3,
                    detailDec1Id: r.detailDec1Id || null,
                    detailDec2Id: r.detailDec2Id || null,
                    detailDec3Id: r.detailDec3Id || null,
                    approved: { dec1: null, dec2: null, dec3: null },
                    preview:  { dec1: null, dec2: null, dec3: null },
                };
            });

            if(!this.requests.length){
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Дані',
                    message: 'Немає неузгоджених заявок за поточний і наступний місяці.',
                    variant: 'info'
                }));
            }
        } catch(e){
            this.dispatchEvent(new ShowToastEvent({
                title: 'Помилка завантаження',
                message: e.body?.message || e.message,
                variant: 'error'
            }));
        } finally {
            this.isLoading = false;
        }
    }

    @track isModalOpen = false;
    @track selectedRequest = null;

    handleApprove(event) {
        const idx = Number(event.currentTarget.dataset.index);
        const r = this.requests[idx];

        this.selectedRequest = {
            index: idx,
            supplier: r.supplier,
            // запропоновані
            dec1: r.dec1, dec2: r.dec2, dec3: r.dec3,
            // інпут-значення в модалці
            dec1Approved: r.preview.dec1 ?? r.approved.dec1,
            dec2Approved: r.preview.dec2 ?? r.approved.dec2,
            dec3Approved: r.preview.dec3 ?? r.approved.dec3,
            // ідентифікатори
            supplierLimitId: r.supplierLimitId,
            detailDec1Id: r.detailDec1Id,
            detailDec2Id: r.detailDec2Id,
            detailDec3Id: r.detailDec3Id
        };
        this.isModalOpen = true;

        this.updateModalWarnings();
    }

    handleInputChange(event){
        const field = event.target.dataset.name; // 'dec1'|'dec2'|'dec3'
        let v = event.target.value === '' ? null : Number(event.target.value);
        if(v != null){
            if(Number.isNaN(v)) v = null;
            if(v < 0) v = 0;
        }
        this.selectedRequest = { ...this.selectedRequest, [`${field}Approved`]: v };

        const idx = this.selectedRequest.index;
        const list = [...this.requests];
        list[idx] = { ...list[idx], preview: { ...list[idx].preview, [field]: v } };
        this.requests = list;

        this.updateModalWarnings();
    }

    fillAsProposed() {
        const r = this.selectedRequest;
        const idx = r.index;
        const next = { dec1Approved: r.dec1, dec2Approved: r.dec2, dec3Approved: r.dec3 };
        this.selectedRequest = { ...r, ...next };

        const list = [...this.requests];
        list[idx] = { ...list[idx], preview: { dec1: r.dec1, dec2: r.dec2, dec3: r.dec3 } };
        this.requests = list;

        this.updateModalWarnings();
    }

    async handleModalSave(){
        const r = this.selectedRequest;
        const row = this.requests[r.index];

        if(!row.detailDec1Id || !row.detailDec2Id || !row.detailDec3Id){
            this.dispatchEvent(new ShowToastEvent({
                title: 'Помилка',
                message: 'Відсутні ідентифікатори деталей. Оновіть сторінку.',
                variant: 'error'
            }));
            return;
        }

        const payload = {
            supplierLimitId: row.supplierLimitId,
            detailDec1Id: row.detailDec1Id,
            detailDec2Id: row.detailDec2Id,
            detailDec3Id: row.detailDec3Id,
            dec1: r.dec1Approved, dec2: r.dec2Approved, dec3: r.dec3Approved,
            baseDoc: null, docLinkId: null
        };

        try{
            this.isLoading = true;
            const res = await approve({ input: payload });
            if(!res || !res.success) throw new Error(res?.message || 'Не вдалося узгодити ліміти');

            this.isModalOpen = false;

            this.requests = this.requests.filter((_, i) => i !== r.index);
            await this.loadDataBothMonths();

            this.dispatchEvent(new ShowToastEvent({
                title: 'Підтверджено',
                message: `Узгоджені ліміти для ${r.supplier} збережено.`,
                variant: 'success'
            }));
        } catch(e){
            this.dispatchEvent(new ShowToastEvent({
                title: 'Помилка',
                message: e.body?.message || e.message,
                variant: 'error'
            }));
        } finally{
            this.isLoading = false;
        }
    }



    handleModalCancel() { this.isModalOpen = false; }

    @track modalWarnings = [];
    get overLimitWarnings() { return this.modalWarnings; }
    get hasOverLimitWarnings() { return this.modalWarnings.length > 0; }
    updateModalWarnings() {
        const r = this.selectedRequest;
        if (!r) { this.modalWarnings = []; return; }

        const msgs = [];
        const push = (key, text, className) => msgs.push({ key, text, className });

        const check = (label, appr, prop, key) => {
            if (appr == null || prop == null) return;
            if (appr > prop) {
                const diff = appr - prop;
                push(key, `${label} - узгоджений ліміт більший на ${diff} від запропонованого (${prop}).`, 'warn-decade');
            }
        };

        check('1 декада', r.dec1Approved, r.dec1, 'd1');
        check('2 декада', r.dec2Approved, r.dec2, 'd2');
        check('3 декада', r.dec3Approved, r.dec3, 'd3');

        const allFilled = r.dec1Approved != null && r.dec2Approved != null && r.dec3Approved != null;
        if (allFilled) {
            const apprSum = r.dec1Approved + r.dec2Approved + r.dec3Approved;
            const propSum = r.dec1 + r.dec2 + r.dec3;
            if (apprSum > propSum) {
                const diff = apprSum - propSum;
                push('m', `Місяць — сумарний узгоджений ліміт більший на ${diff} від пропонованого (${propSum}).`, 'warn-month');
            }
        }
        this.modalWarnings = msgs;
    }

    // Гетери для модалки
    get proposedTotal() {
        const r = this.selectedRequest;
        return r ? (r.dec1 + r.dec2 + r.dec3) : 0;
    }
    get approvedDec1() { return this.selectedRequest?.dec1Approved ?? ''; }
    get approvedDec2() { return this.selectedRequest?.dec2Approved ?? ''; }
    get approvedDec3() { return this.selectedRequest?.dec3Approved ?? ''; }
    get approvedTotal() {
        const r = this.selectedRequest;
        return (r?.dec1Approved ?? 0) + (r?.dec2Approved ?? 0) + (r?.dec3Approved ?? 0);
    }
    get isApproveDisabled() {
        const r = this.selectedRequest;
        return !(r && r.dec1Approved != null && r.dec2Approved != null && r.dec3Approved != null);
    }
}