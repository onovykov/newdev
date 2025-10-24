import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import listChanges   from '@salesforce/apex/SlotChangeAdminService.listChanges';
import approveChange from '@salesforce/apex/SlotChangeAdminService.approveChange';
import rejectChange  from '@salesforce/apex/SlotChangeAdminService.rejectChange';
import getChangeState  from '@salesforce/apex/SlotChangeAdminService.getChangeState';

const STATUS = {
    OPEN: 'Open',
    APPROVED: 'Approved',
    REJECTED: 'Rejected'
};

export default class ScrapSlotChangeApprovalPanel extends LightningElement {
    @track rows = [];
    @track loading = false;
    @track erpWait = false;

    // фільтри
    @track statusFilter = STATUS.OPEN; // Open | Approved | Rejected | ALL
    statusOptions = [
        { label: 'Очікує', value: STATUS.OPEN },
        { label: 'Підтверджено', value: STATUS.APPROVED },
        { label: 'Відхилено', value: STATUS.REJECTED },
        { label: 'Усі', value: 'ALL' },
    ];
    @track query = '';
    _qTimer;

    // модалка/дії
    @track isModalOpen = false;
    @track selected = null;
    @track actionBusy = false;

    connectedCallback() { this.refresh(); }

    async refresh() {
        this.loading = true;
        try {
            const data = await listChanges({ status: this.statusFilter, query: this.query || '' });
            this.rows = (data || []).map(r => this.decorate(r));
        } catch (e) {
            this.toast('Помилка', e?.body?.message || e?.message || 'Не вдалося завантажити список', 'error');
        } finally { this.loading = false; }
    }

    // ========== helpers ==========
    // нормалізації як раніше
    normalize(v) {
        if (v === undefined || v === null) return null;
        const s = String(v).trim();
        return (s === '' || s === '0') ? null : s;
    }
    phoneNorm(v) {
        if (v === undefined || v === null) return null;
        const s = String(v).replace(/[^\d+]/g, '');
        return s === '' ? null : s;
    }
    view(val, fallback = '—') { return (val === null || val === undefined || val === '') ? fallback : String(val); }

    makeDriverLine(side) {
        const name  = this.view(this.normalize(side?.driverName));
        const phone = this.view(this.phoneNorm(side?.driverPhone));
        return `${name} / ${phone}`;
    }
    makeTruckLine(side) {
        const plate = this.view(this.normalize(side?.tractorPlate));
        const model = this.view(this.normalize(side?.tractorModel));
        return `${plate} / ${model}`;
    }
    makeTrailerLine(side) {
        const plate = this.view(this.normalize(side?.trailerPlate));
        const model = this.view(this.normalize(side?.trailerModel));
        return `${plate} / ${model}`;
    }

    decorate(r) {
        // повні рядки для old/new
        const driverOld = this.makeDriverLine(r.oldData);
        const truckOld  = this.makeTruckLine(r.oldData);
        const trlrOld   = this.makeTrailerLine(r.oldData);

        const driverNewRaw = this.makeDriverLine(r.newData);
        const truckNewRaw  = this.makeTruckLine(r.newData);
        const trlrNewRaw   = this.makeTrailerLine(r.newData);

        // є чи ні пропозиція (хоча б одна частина заповнена)
        const hasNewDriver  = !!(r.newData?.driverName   || r.newData?.driverPhone);
        const hasNewTruck   = !!(r.newData?.tractorPlate || r.newData?.tractorModel);
        const hasNewTrailer = !!(r.newData?.trailerPlate || r.newData?.trailerModel);

        // порівнюємо лише якщо була пропозиція
        const driverChanged =
            hasNewDriver &&
            (this.normalize(r.oldData?.driverName) !== this.normalize(r.newData?.driverName) ||
                this.phoneNorm(r.oldData?.driverPhone) !== this.phoneNorm(r.newData?.driverPhone));

        const truckChanged =
            hasNewTruck &&
            (this.normalize(r.oldData?.tractorPlate) !== this.normalize(r.newData?.tractorPlate) ||
                this.normalize(r.oldData?.tractorModel) !== this.normalize(r.newData?.tractorModel));

        const trailerChanged =
            hasNewTrailer &&
            (this.normalize(r.oldData?.trailerPlate) !== this.normalize(r.newData?.trailerPlate) ||
                this.normalize(r.oldData?.trailerModel) !== this.normalize(r.newData?.trailerModel));

        // що показувати як "нове": якщо пропозиції нема — залишаємо старе (і стрілку не показуємо)
        const driverNew = hasNewDriver  ? driverNewRaw : driverOld;
        const truckNew  = hasNewTruck   ? truckNewRaw  : truckOld;
        const trlrNew   = hasNewTrailer ? trlrNewRaw   : trlrOld;

        let rowClass = '';
        if (r.status === 'Approved') rowClass = 'row-approved';
        else if (r.status === 'Rejected') rowClass = 'row-rejected';
        else if (driverChanged || truckChanged || trailerChanged) rowClass = 'row-changed';

        return {
            ...r,
            date: r.dateValue,
            scrapType: r.scrapType, // Name

            driverOld, driverNew, driverChanged,
            truckOld,  truckNew,  truckChanged,
            trlrOld,   trlrNew,   trailerChanged,

            driverCellClass:  driverChanged  ? 'cell-changed' : '',
            truckCellClass:   truckChanged   ? 'cell-changed' : '',
            trailerCellClass: trailerChanged ? 'cell-changed' : '',

            // класи для модалки
            driverOldClass:   driverChanged  ? 'changed-old' : '',
            driverNewClass:   driverChanged  ? 'changed-new' : '',
            truckOldClass:    truckChanged   ? 'changed-old' : '',
            truckNewClass:    truckChanged   ? 'changed-new' : '',
            trailerOldClass:  trailerChanged ? 'changed-old' : '',
            trailerNewClass:  trailerChanged ? 'changed-new' : '',

            // для сумісності з наявними біндінгами
            driverChangedClass:  driverChanged  ? 'changed-new' : '',
            tractorChangedClass: truckChanged   ? 'changed-new' : '',
            trailerChangedClass: trailerChanged ? 'changed-new' : '',

            isOpen: r.isOpen ?? (r.status === STATUS.OPEN),
            rowClass
        };
    }




    // віддаємо як є
    get visibleRows() { return this.rows || []; }

    // ——— Події фільтрів/пошуку
    handleStatusFilterChange(e) { this.statusFilter = e.detail.value; this.refresh(); }
    handleQueryChange(e) {
        this.query = e.target.value;
        clearTimeout(this._qTimer);
        this._qTimer = setTimeout(() => this.refresh(), 300);
    }
    refreshClick(){ this.refresh(); }

    // ——— Модалка (залишаю як у тебе)
    openModal(e) {
        const id = e.currentTarget.dataset.id;
        const r = (this.rows || []).find(x => x.id === id);
        if (!r) return;
        if (!r.isOpen) { this.toast('Інформація', 'Заявка вже закрита.', 'info'); return; }
        this.selected = JSON.parse(JSON.stringify(r));
        this.isModalOpen = true;
    }
    closeModal(){ if (this.actionBusy) return; this.isModalOpen = false; this.selected = null; }

    async pollErp(changeId, { intervalMs = 1500, maxMs = 90000 } = {}) {
        const started = Date.now();
        // eslint-disable-next-line no-constant-condition
        while (true) {
            // 1) читаємо стан
            //    очікуємо, що getChangeState повертає { success, message, passNumber, passId, ... }
            //    success === true -> Approved
            //    success === false і є message з описом помилки ERP -> викидаємо помилку
            const st = await getChangeState({ changeId });

            if (st?.success) return st; // Approved: маємо passNumber/passId

            // Якщо бекенд поклав причину (наприклад, "ERP повернув помилку" або "Callout error")
            if (st?.message && st.message.trim()) {
                const m = st.message.toLowerCase();
                if (m.includes('erp') || m.includes('callout')) {
                    throw new Error(st.message);
                }
            }

            if (Date.now() - started > maxMs) {
                throw new Error('Час очікування відповіді ERP вичерпано.');
            }
            // eslint-disable-next-line no-await-in-loop
            await new Promise(r => setTimeout(r, intervalMs));
        }
    }

    // ================== АПРУВ ==================
    async handleApprove() {
        if (!this.selected?.id) return;
        this.actionBusy = true;   // блокуємо кнопки
        this.erpWait = true;      // ховаємо контент модалки, показуємо спінер

        try {
            // 1) Запускаємо серверний апрув (оновлює слот, ставить Queueable)
            const res = await approveChange({ changeId: this.selected.id });
            // 2) Чекаємо фіналу від ERP
            const final = await this.pollErp(res.changeId);

            // 3) Успіх — показуємо номер перепустки, закриваємо модалку, оновлюємо список
            this.dispatchEvent(new ShowToastEvent({
                title: 'Підтверджено',
                message: `Перепустка: ${final?.passNumber || '—'}`,
                variant: 'success'
            }));

            this.isModalOpen = false;
            this.selected = null;
            await this.refresh();   // підтягнути оновлений статус/перепустку
        } catch (e) {
            // Помилка ERP / таймаут — модалка лишається відкритою
            this.dispatchEvent(new ShowToastEvent({
                title: 'Помилка',
                message: e?.body?.message || e?.message || 'ERP не підтвердив зміни',
                variant: 'error'
            }));
        } finally {
            this.erpWait = false;
            this.actionBusy = false;
        }
    }


    async handleReject() {
        if (!this.selected?.id) return;
        this.actionBusy = true;
        try {
            const res = await rejectChange({ changeId: this.selected.id });
            this.rows = this.rows.map(r =>
                r.id === res.changeId ? this.decorate({ ...r, status: STATUS.REJECTED, isOpen: false }) : r
            );
            this.isModalOpen = false;
            this.toast('Відхилено', 'Слот скасовано, заявку відхилено.', 'warning');
        } catch (e) {
            this.toast('Помилка', e?.body?.message || e?.message || 'Не вдалося відхилити', 'error');
        } finally { this.actionBusy = false; }
    }

    toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    // --- токенізація зі збереженням розділювачів
    tokenize(str) {
        const s = (str ?? '').toString();
        // розбиваємо на слова/цифри і розділювачі, щоб зберегти пробіли, слеші та дужки
        const parts = s.split(/(\s+|\/|\(|\)|,|\.|-|_)/g).filter(x => x !== '');
        return parts;
    }

// LCS для маркування same/add/rem
    diffTokens(oldStr, newStr) {
        const A = this.tokenize(oldStr);
        const B = this.tokenize(newStr);
        const n = A.length, m = B.length;

        // DP матриця
        const dp = Array(n+1).fill(0).map(()=>Array(m+1).fill(0));
        for (let i= n-1; i>=0; i--) {
            for (let j= m-1; j>=0; j--) {
                dp[i][j] = (A[i] === B[j]) ? dp[i+1][j+1] + 1 : Math.max(dp[i+1][j], dp[i][j+1]);
            }
        }
        // відновлюємо LCS
        const same = [];
        let i=0, j=0;
        while (i<n && j<m) {
            if (A[i] === B[j]) { same.push(A[i]); i++; j++; }
            else if (dp[i+1][j] >= dp[i][j+1]) i++;
            else j++;
        }

        // проходимо ще раз, збираємо сегменти
        const segOld = [];
        const segNew = [];
        i=0; j=0;
        let k=0;

        while (i<n || j<m) {
            if (i<n && j<m && A[i] === B[j]) {
                const t = A[i]; i++; j++;
                segOld.push({ key:`o${k}`, text:t, kind:'same' });
                segNew.push({ key:`n${k}`, text:t, kind:'same' });
                k++;
            } else {
                // видалене з A
                if (i<n && (j>=m || dp[i+1][j] >= dp[i][j+1])) {
                    segOld.push({ key:`o${k}`, text:A[i], kind:'rem' }); i++; k++;
                    continue;
                }
                // додане у B
                if (j<m) {
                    segNew.push({ key:`n${k}`, text:B[j], kind:'add' }); j++; k++;
                }
            }
        }
        return { segOld, segNew };
    }

// конструктори рядків
    buildDriverLines(side) {
        const name  = this.view(this.normalize(side?.driverName));
        const phone = this.view(this.phoneNorm(side?.driverPhone));
        return `${name} / ${phone}`;
    }
    buildTruckLines(side) {
        const plate = this.view(this.normalize(side?.tractorPlate));
        const model = this.view(this.normalize(side?.tractorModel));
        return `${plate} / ${model}`;
    }
    buildTrailerLines(side) {
        const plate = this.view(this.normalize(side?.trailerPlate));
        const model = this.view(this.normalize(side?.trailerModel));
        return `${plate} / ${model}`;
    }

}