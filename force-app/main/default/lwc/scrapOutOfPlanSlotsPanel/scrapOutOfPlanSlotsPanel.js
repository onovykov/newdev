import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// APEX
import listRequestedOutOfPlanVM
    from '@salesforce/apex/OutOfPlanAdminService.listRequestedOutOfPlanVM';
import approveOutOfPlan
    from '@salesforce/apex/OutOfPlanAdminService.approveOutOfPlan';

import getSlotStatus
    from '@salesforce/apex/OutOfPlanAdminService.getSlotStatus';

import getFixedWeightOptions
    from '@salesforce/apex/OutOfPlanAdminService.getFixedWeightOptions';

const STATUS = {
    PENDING: 'PENDING',
    APPROVED: 'APPROVED',
    REJECTED: 'REJECTED'
};

export default class ScrapOutOfPlanSlotsPanel extends LightningElement {
    // ===== ДАНІ =====
    @track rows = [];          // нормалізовані рядки для таблиці
    @track isLoading = false;  // спінер завантаження
    @track isSending = false;

    @track fixedWeightOptions = [];

    // ===== Фільтри UI =====
    @track statusFilter = 'ALL';
    statusOptions = [
        { label: 'Усі', value: 'ALL' },
        { label: 'Очікує', value: STATUS.PENDING },
        { label: 'Підтверджено', value: STATUS.APPROVED },
        { label: 'Відхилено', value: STATUS.REJECTED }
    ];
    @track query = '';

    // ===== Модалка =====
    @track isModalOpen = false;
    @track selected = null;

    // ===== Ініціалізація =====
    connectedCallback() {
        // this.loadRows();
        Promise.all([ this.loadRows(), this.loadFixedWeightOptions() ]).catch(()=>{});
    }

    async loadFixedWeightOptions() {
        try {
            const opts = await getFixedWeightOptions(); // очікуємо ['10','20','25'] або [{label,value}]
            // Нормалізуємо до combobox-формату
            this.fixedWeightOptions = (opts || []).map(o => {
                if (typeof o === 'object' && o.value) return o;         // уже {label,value}
                const v = String(o);
                return { label: `${v} т.`, value: v };
            });
            // fallback (на всяк випадок)
            if (!this.fixedWeightOptions.length) {
                this.fixedWeightOptions = [{label:'10 т.',value:'10'},{label:'20 т.',value:'20'},{label:'25 т.',value:'25'}];
            }
        } catch(e) {
            // запасні значення, якщо Apex впав
            this.fixedWeightOptions = [{label:'10 т.',value:'10'},{label:'20 т.',value:'20'},{label:'25 т.',value:'25'}];
            // можна тихо, або тостом — як зручно
            // this.dispatchEvent(new ShowToastEvent({ title:'Увага', message:'Не вдалося отримати опції тоннажу', variant:'warning'}));
        }
    }


    async loadRows() {
        this.isLoading = true;
        try {
            // простий виклик без серверних фільтрів — усе фільтруємо на клієнті
            const data = await listRequestedOutOfPlanVM({
                supplierIdFilter: null,
                scrapTypeFilter: null,
                dateFrom: null,
                dateTo: null
            });

            // Нормалізуємо під шаблон (назви полів з Apex → під твої колонки)
            this.rows = (data || []).map(r => this.mapApexRow(r));
        } catch (e) {
            // Покажемо помилку
            this.dispatchEvent(new ShowToastEvent({
                title: 'Помилка завантаження',
                message: e?.body?.message || e?.message || 'Невідома помилка',
                variant: 'error'
            }));
        } finally {
            this.isLoading = false;
        }
    }

    mapApexRow(r) {
        // формат дати
        const dateFmt = new Intl.DateTimeFormat('uk-UA', { day: '2-digit', month: '2-digit', year: 'numeric' });
        const uiDate = r.reserveDate ? dateFmt.format(new Date(r.reserveDate)) : '—';

        const monthLimit = toNum(r.approvedMonth);
        const used       = toNum(r.factMonth);
        const leftMonth  = isNum(r.remainMonth) ? Number(r.remainMonth) : (monthLimit - used);

            // 🔹 значення по декаді (бек уже віддає approvedDec/factDec/remainDec)
          const decLimit = toNum(r.approvedDec);
          const decUsed  = toNum(r.factDec);
          const decLeft  = isNum(r.remainDec) ? Number(r.remainDec) : (decLimit - decUsed);

        const fixedStr = (r.fixedWeight || '').trim();
        const fixedNum = Number(fixedStr || 0);
        // статуси поки локальні (сервер повертає Requested)
        const uiStatus = STATUS.PENDING;

        return {
            // базове
            id: r.slotId,
            date: uiDate,
            supplier: r.supplierName || '—',
            scrapType: r.scrapTypeName || '—',
            weight: toNum(r.tonnage),

            // місячні агрегати
            monthLimit,
            used,
            leftMonth,      // зберігаємо як допоміжне

            // декада
            decLimit, decUsed, decLeft,

            // транспорт
            driverName: r.driverName || '—',
            driverPhone: r.driverPhone || '—',
            truckModel: r.truckModel || '—',
            truckNumber: r.truckNumber || r.truckName || '—',

            fixedWeightValue: fixedStr || null,         // '10' | '20' | '25' | null
            fixedWeightNumber: isNum(fixedNum) ? fixedNum : 0, // 10 | 20 | 25 | 0

            fixedWeightDisplay: isNum(fixedNum) ? String(fixedNum) : '—',

            // технічне
            approvedDetailDecId: r.approvedDetailDecId,
            yearNum: r.yearNum,
            monthNum: r.monthNum,
            decadeNum: r.decadeNum,
            monthId: r.monthId,

            status: uiStatus
        };
    }

    computeLeftMonth = (r) => (isNum(r.leftMonth) ? Number(r.leftMonth) : (r.monthLimit ?? 0) - (r.used ?? 0));
    computeLeftDec   = (r) => (isNum(r.decLeft)   ? Number(r.decLeft)   : (r.decLimit   ?? 0) - (r.decUsed ?? 0));

    computeOverMonthIfAccepted = (r) => {
        const left = this.computeLeftMonth(r);
        const accept = Number(r.fixedWeightNumber ?? 0); // було r.weight
        return accept - Math.max(left, 0);
    };
    computeOverDecIfAccepted = (r) => {
        const left = this.computeLeftDec(r);
        const accept = Number(r.fixedWeightNumber ?? 0); // було r.weight
        return accept - Math.max(left, 0);
    };
    computeOverIfAccepted = (r) => { // для rowClass
        const left = this.computeLeft(r);
        const accept = Number(r.fixedWeightNumber ?? 0);
        return accept - Math.max(left, 0);
    };



    // ===== Helpers =====
    computeLeft = (r) => {
        // віддаємо те, що прийшло з бекенда, або рахуємо
        if (isNum(r.leftMonth)) return Number(r.leftMonth);
        return (r.monthLimit ?? 0) - (r.used ?? 0);
    };
    // computeOverIfAccepted = (r) => {
    //     const left = this.computeLeft(r);
    //     const accept = r.weight ?? 0; // у таблиці — "якщо дозволити весь запитаний тоннаж"
    //     return accept - Math.max(left, 0);
    // };

    formatSigned(n) {
        if (!isNum(n)) return '—';
        return Number(n).toString();
    }
    leftClass(n) {
        if (n < 0) return 'num neg';
        if (n === 0) return 'num zero';
        return 'num';
    }
    overClass(n) {
        if (n > 0) return 'num danger';
        if (n === 0) return 'num zero';
        return 'num';
    }
    statusLabel(st) {
        switch (st) {
            case STATUS.PENDING:  return 'Очікує';
            case STATUS.APPROVED: return 'Підтверджено';
            case STATUS.REJECTED: return 'Відхилено';
            default: return st || '—';
        }
    }
    statusBadgeClass(st) {
        switch (st) {
            case STATUS.PENDING:  return 'badge badge-pending';
            case STATUS.APPROVED: return 'badge badge-approved';
            case STATUS.REJECTED: return 'badge badge-rejected';
            default: return 'badge';
        }
    }
    rowClass = (r) => {
        if (r.status === STATUS.APPROVED) return 'row-approved';
        if (r.status === STATUS.REJECTED) return 'row-rejected';
        const over = this.computeOverIfAccepted(r);
        return over > 0 ? 'row-changed' : '';
    };

    // ===== Вирахувані ряди для таблиці =====
    // get visibleRows() {
    //     const q = (this.query || '').trim().toLowerCase();
    //     return (this.rows || [])
    //         .filter(r => this.statusFilter === 'ALL' || r.status === this.statusFilter)
    //         .filter(r => {
    //             if (!q) return true;
    //             const hay = [
    //                 r.supplier, r.scrapType, r.driverName, r.driverPhone, r.truckNumber, r.truckModel
    //             ].join(' ').toLowerCase();
    //             return hay.includes(q);
    //         })
    //         .map(r => {
    //             const left = this.computeLeft(r);
    //             const over = this.computeOverIfAccepted(r);
    //             return {
    //                 ...r,
    //                 statusLabel: this.statusLabel(r.status),
    //                 statusBadgeClass: this.statusBadgeClass(r.status),
    //                 rowClass: this.rowClass(r),
    //                 leftDisplay: this.formatSigned(left),
    //                 leftClass: this.leftClass(left),
    //                 overDisplay: over > 0 ? `+${over}` : `${over}`,
    //                 overClass: this.overClass(over)
    //             };
    //         });
    // }

    get visibleRows() {
        const q = (this.query || '').trim().toLowerCase();
        return (this.rows || [])
            .filter(r => this.statusFilter === 'ALL' || r.status === this.statusFilter)
            .filter(r => {
                if (!q) return true;
                const hay = [r.supplier, r.scrapType, r.driverName, r.driverPhone, r.truckNumber, r.truckModel]
                    .join(' ').toLowerCase();
                return hay.includes(q);
            })
            .map(r => {
                // МІСЯЦЬ
                const leftM = this.computeLeftMonth(r);
                const overM = this.computeOverMonthIfAccepted(r);
                // ДЕКАДА
                const leftD = this.computeLeftDec(r);
                const overD = this.computeOverDecIfAccepted(r);

                return {
                    ...r,
                    statusLabel: this.statusLabel(r.status),
                    statusBadgeClass: this.statusBadgeClass(r.status),

                    // місяць
                    leftDisplay: this.formatSigned(leftM),
                    leftClass: this.leftClass(leftM),
                    overDisplay: overM > 0 ? `+${overM}` : `${overM}`,
                    overClass: this.overClass(overM),

                    // декада
                    decLeftDisplay: this.formatSigned(leftD),
                    decLeftClass: this.leftClass(leftD),
                    decOverDisplay: overD > 0 ? `+${overD}` : `${overD}`,
                    decOverClass: this.overClass(overD),

                    // підсвічування рядка — якщо є “перевищення” хоча б по одному з вимірів
                    rowClass: (r.status === STATUS.APPROVED) ? 'row-approved'
                        : (r.status === STATUS.REJECTED) ? 'row-rejected'
                            : ((overM > 0 || overD > 0) ? 'row-changed' : '')
                };
            });
    }

    get selDecLeft(){
        return this.selected ? this.computeLeftDec(this.selected) : 0;
    }
    get selDecLeftDisplay(){
        return this.formatSigned(this.selDecLeft);
    }
    get selDecLeftClass(){
        return this.leftClass(this.selDecLeft);
    }
    get selDecOverApproved(){
        if (!this.selected) return 0;
        const left = this.computeLeftDec(this.selected);
        return this.selApprovedWeight - Math.max(left, 0);
    }
    get selDecOverDisplay(){
        const n = this.selDecOverApproved; return n > 0 ? `+${n}` : `${n}`;
    }
    get selDecOverClass(){
        return this.overClass(this.selDecOverApproved);
    }

// якщо перевищення є або по місяцю, або по декаді — показуємо алерт
    get hasOverLimit(){
        return this.selOverApproved > 0 || this.selDecOverApproved > 0;
    }



    // ===== Обробники фільтрів =====
    handleStatusFilterChange(e) { this.statusFilter = e.detail.value; }
    handleQueryChange(e)       { this.query = e.target.value; }

    // ===== Модалка =====
    openModal(e) {
        const index = Number(e.currentTarget.dataset.index);
        const row = this.visibleRows[index];
        const realIndex = this.rows.findIndex(x => x.id === row.id);

        const base = JSON.parse(JSON.stringify(this.rows[realIndex]));

        // якщо у слота вже є FixedWeight__c — беремо його,
        // інакше — перше значення з пікліста (або weight, якщо співпадає)
        let initial = base.fixedWeightValue || null;
        if (!initial && this.fixedWeightOptions.length) {
            const w = String(base.weight ?? '');
            initial = this.fixedWeightOptions.some(o => o.value === w) ? w : this.fixedWeightOptions[0].value;
            // initial = this.fixedWeightOptions[0].value;

        }

        this.selected = { ...base, index: realIndex, fixedWeightValue: initial, requestedFixedWeight: base.fixedWeightValue || initial };
        this.isModalOpen = true;
    }

    // Скільки дозволяємо — це вибір з пікліста (числом)
    get selFixedWeight() {
        return this.selected ? (this.selected.fixedWeightValue ?? null) : null; // '10'|'20'|'25'|null
    }
    get selApprovedWeight() {
        return Number(this.selFixedWeight || 0); // число для математики
    }
    get selRequestedWeight() {
        if (!this.selected) return 0;
        return Number(this.selected.requestedFixedWeight || 0);
    }

    closeModal() {
        this.isModalOpen = false;
        this.selected = null;
    }

    get approvedPillClass(){
        if(!this.selected) return 'pill pill-neutral';
        return (this.selApprovedWeight < this.selRequestedWeight)
            ? 'pill pill-warning'
            : 'pill pill-ok';
    }

    get selFixedOptions() {
        // показуємо 10/20/25 як є, без обмежень за “вагою автомобіля”
        return this.fixedWeightOptions;
    }


    get selLeft(){
        return this.selected ? this.computeLeft(this.selected) : 0;
    }
    get selLeftDisplay(){
        const n = this.selLeft; return this.formatSigned(n);
    }
    get selLeftClass(){
        const n = this.selLeft; return this.leftClass(n);
    }
    get selOverApproved(){
        if(!this.selected) return 0;
        const left = this.computeLeft(this.selected);
        return this.selApprovedWeight - Math.max(left, 0);
    }
    get selOverDisplay(){
        const n = this.selOverApproved; return n > 0 ? `+${n}` : `${n}`;
    }
    get selOverClass(){
        const n = this.selOverApproved; return this.overClass(n);
    }
    // get hasOverLimit(){ return this.selOverApproved > 0; }

    handleApprovedWeightChange = (e) => {
        if (!this.selected) return;

        const val = String(e.detail?.value ?? e.target?.value ?? '');
        const isValid = this.fixedWeightOptions.some(o => o.value === val);

        // якщо значення не з переліку — не приймаємо
        this.selected = {
            ...this.selected,
            fixedWeightValue: isValid ? val : null
        };
    };

    pollTimer = null;
    POLL_INTERVAL = 2500;  // 2.5s
    POLL_TIMEOUT  = 120000; // 2 хв
    pollStartedAt = 0;

    disconnectedCallback(){
        if (this.pollTimer){ clearInterval(this.pollTimer); this.pollTimer = null; }
    }

    // ===== Дії (поки локальні; бекенд-ендпойнти можна підв’язати пізніше) =====
    async handleApprove() {
        if (!this.selected) return;

        const chosen = this.selFixedWeight;
        if (!chosen) {
            this.dispatchEvent(new ShowToastEvent({
                title:'Не обрано тоннаж',
                message:'Виберіть «Дозволити до приймання, т».',
                variant:'warning'
            }));
            return;
        }

        this.isSending = true;        // показуємо оверлей-спінер у модалці
        try {
            // 1) тригеримо Apex, який ОНОВИТЬ слот і ЗАПУСТИТЬ чергу
            await approveOutOfPlan({ slotId: this.selected.id, fixedWeightValue: chosen });

            // 2) починаємо пулити стан слота до готовності
            this.pollStartedAt = Date.now();
            const slotId = this.selected.id;

            this.pollTimer = setInterval(async () => {
                try{
                    const s = await getSlotStatus({ slotId });
                    const approved = s && s.Status__c === 'Approved' && s.PassNumber__c;

                    const expired  = (Date.now() - this.pollStartedAt) > this.POLL_TIMEOUT;
                    // const errored  = s && s.Status__c === 'Error';

                    if (approved) {
                        clearInterval(this.pollTimer); this.pollTimer = null;
                        this.isSending = false;

                        // оновимо рядок у таблиці
                        const allow = this.selApprovedWeight; // 10/20/25 як число
                        const list = [...this.rows];
                        const idx  = this.selected.index;
                        const row  = { ...list[idx] };

                        row.status           = 'APPROVED';
                        row.fixedWeightValue   = chosen;                       // '10' | '20' | '25'
                        row.fixedWeightNumber  = this.selApprovedWeight;       // 10 | 20 | 25
                        row.fixedWeightDisplay = String(this.selApprovedWeight);

                        row.used    = (row.used    ?? 0) + allow;
                        row.decUsed = (row.decUsed ?? 0) + allow;
                        row.decLeft = (row.decLeft ?? 0) - allow;
                        if (isNum(row.leftMonth)) row.leftMonth = Number(row.leftMonth) - allow;

                        list[idx] = row;
                        this.rows = list;

                        this.isModalOpen = false;

                        this.dispatchEvent(new ShowToastEvent({
                            title:'Підтверджено',
                            message:`Слот ${row.id} підтверджено. Перепустка: ${s.PassNumber__c || '—'}.`,
                            variant:'success'
                        }));

                        await this.loadRows();   // ← ОНОВИТИ СПИСОК

                    } else if (expired) {
                        clearInterval(this.pollTimer); this.pollTimer = null;
                        this.isSending = false;
                        this.dispatchEvent(new ShowToastEvent({
                            title:'Довго немає відповіді',
                            message:'ERP ще не повернув перепустку. Перевірте пізніше або оновіть сторінку.',
                            variant:'warning'
                        }));
                    }
                } catch(e){
                    // одноразово зупиняємось при помилці пулінгу
                    clearInterval(this.pollTimer); this.pollTimer = null;
                    this.isSending = false;
                    this.dispatchEvent(new ShowToastEvent({
                        title:'Помилка перевірки статусу',
                        message: e?.body?.message || e?.message || 'Невідома помилка',
                        variant:'error'
                    }));
                }
            }, this.POLL_INTERVAL);

        } catch (e) {
            this.isSending = false;
            this.dispatchEvent(new ShowToastEvent({
                title:'Помилка',
                message:e?.body?.message || e?.message || 'Не вдалося надіслати в ERP.',
                variant:'error'
            }));
        }
    }


    // get selFixedOptions() {
    //     if (!this.selected) return this.fixedWeightOptions;
    //     const max = Number(this.selected.weight) || Infinity;
    //     return (this.fixedWeightOptions || []).filter(o => Number(o.value) <= max);
    // }



    handleReject(){
        if(!this.selected) return;

        const list = [...this.rows];
        list[this.selected.index] = {
            ...this.selected,
            status: STATUS.REJECTED
        };
        this.rows = list;
        this.isModalOpen = false;

        this.dispatchEvent(new ShowToastEvent({
            title: 'Відхилено',
            message: `Слот ${this.selected.id} відхилено.`,
            variant: 'warning'
        }));
    }
}

// ==== локальні утиліти ====
function isNum(v){ return v !== null && v !== undefined && !Number.isNaN(Number(v)); }
function toNum(v){ return isNum(v) ? Number(v) : 0; }