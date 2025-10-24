import {api, LightningElement, track} from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getCurrentMonthPanel from '@salesforce/apex/ScrapLimitsPanelController.getCurrentMonthPanel';
import saveApprovedEdits from '@salesforce/apex/ScrapLimitsPanelController.saveApprovedEdits';

export default class ScrapAdminLimitViewPanel extends LightningElement {
    // Демо-дані: заявлений (proposed), узгоджений (approved), фактичний (factual)

    @track requests = [];
    @track isModalOpen = false;
    @track selectedRequest = null;
    @track modalWarnings = [];
    @api uploadRecordId;
    @track uploadedFiles = [];
    @track triedToSubmit = false;

    searchText = '';
    _searchTimer;

    handleSearchInput = (e) => {
        const v = (e.target.value || '').trim();
        window.clearTimeout(this._searchTimer);
        this._searchTimer = setTimeout(() => { this.searchText = v.toLowerCase(); }, 200);
    };

    get filteredAndSorted() {
        const q = this.searchText;
        // 1) фільтр
        let items = this.requests;
        if (q) {
            items = items.filter(r => (r.supplier || '').toLowerCase().includes(q));
        }
        // 2) сортування:
        //    - спершу ті, у кого є і declared, і approved (state === 'ok')
        //    - потім лише declared (state === 'onlyDeclared')
        //    - потім без даних (state === 'noLimits')
        //    - усередині груп — за назвою постачальника
        const rank = (r) => (r.hasDeclared && r.hasApproved) ? 0
            : (r.hasDeclared && !r.hasApproved) ? 1
                : 2;
        return [...items].sort((a, b) => {
            const ra = rank(a), rb = rank(b);
            if (ra !== rb) return ra - rb;
            const na = (a.supplier || '').toLowerCase();
            const nb = (b.supplier || '').toLowerCase();
            return na.localeCompare(nb, 'uk');
        });
    }

    connectedCallback() {
        this.loadData();
    }

    async loadData() {
        try {
            const data = await getCurrentMonthPanel();
            console.log('DATA: ' + JSON.stringify(data, null, 2));
            const toNum = (v) => (v == null ? 0 : Number(v));
            const sum = (o) => toNum(o.dec1) + toNum(o.dec2) + toNum(o.dec3);

            this.requests = (data || []).map((r, idx) => {
                const toNum = (v) => (v == null ? 0 : Number(v));
                const proposed = { dec1: toNum(r.propDec1), dec2: toNum(r.propDec2), dec3: toNum(r.propDec3) };
                const approved = { dec1: toNum(r.apprDec1), dec2: toNum(r.apprDec2), dec3: toNum(r.apprDec3) };
                const factual  = { dec1: toNum(r.factDec1), dec2: toNum(r.factDec2), dec3: toNum(r.factDec3) };
                const hasSupplierLimitEdit = !!r.hasSupplierLimitEdit;

                const sum = (o) => toNum(o.dec1) + toNum(o.dec2) + toNum(o.dec3);
                const remain = {
                    dec1: approved.dec1 - factual.dec1,
                    dec2: approved.dec2 - factual.dec2,
                    dec3: approved.dec3 - factual.dec3
                };

                const proposedSum = sum(proposed);
                const approvedSum = sum(approved);

                // прапорці з Apex (або обчисли з сум, якщо не приїдуть)
                const hasDeclared = (r.hasDeclared !== undefined) ? r.hasDeclared : proposedSum > 0;
                const hasApproved = (r.hasApproved !== undefined) ? r.hasApproved : approvedSum > 0;
                const state = (!hasDeclared && !hasApproved) ? 'noLimits'
                    : (hasDeclared && !hasApproved) ? 'onlyDeclared'
                        : 'ok';

                // модифікатори класів
                const proposedRowClass = `proposed-row ${state==='noLimits' ? 'row--nodata' : ''}`;
                const approvedRowClass = `approved-row ${approvedSum ? 'approved-row--filled' : ''} ${state==='onlyDeclared' ? 'row--onlydecl' : ''} ${state==='noLimits' ? 'row--nodata' : ''}`;
                const factualRowClass  = `factual-row ${state==='noLimits' ? 'row--nodata' : ''}`;
                const remainRowClass   = `remain-row ${state==='noLimits' ? 'row--nodata' : ''}`;
                const supplierCellClass= `supplier-cell ${state==='noLimits' ? 'supplier--nodata' : ''}`;

                return {
                    id: r.supplierId,
                    supplier: r.supplierName,

                    proposed,
                    approved,
                    factual,

                    propKey:   `${idx}_prop`,
                    apprKey:   `${idx}_appr`,
                    factKey:   `${idx}_fact`,
                    remainKey: `${idx}_remain`,

                    hasSupplierLimitEdit,
                    _kind: r.supplierKind,
                    proposedDisplay: { ...proposed, total: proposedSum },
                    approvedDisplay: { ...approved, total: approvedSum },
                    factualDisplay:  { ...factual,  total: sum(factual) },
                    remainDisplay:   { ...remain,   total: remain.dec1 + remain.dec2 + remain.dec3 },

                    // нове:
                    hasDeclared,
                    hasApproved,
                    state,
                    proposedRowClass,
                    approvedRowClass,
                    factualRowClass,
                    remainRowClass,
                    supplierCellClass,

                    // для модалки — повідомлення
                    showNoDeclared: !hasDeclared,
                    showNoApproved: !hasApproved,

                    // як було
                    preview: { dec1: null, dec2: null, dec3: null },
                    // monthAlertClass: approvedSum > proposedSum ? 'month-danger' : ''
                    monthAlertClass: (approvedSum > proposedSum && hasSupplierLimitEdit) ? 'month-danger' : '',
                    apprDetailDec1Id: r.apprDetailDec1Id || null,
                    apprDetailDec2Id: r.apprDetailDec2Id || null,
                    apprDetailDec3Id: r.apprDetailDec3Id || null,


                };
            });

        } catch (e) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Помилка завантаження',
                message: e?.body?.message || e?.message || 'Не вдалося отримати дані.',
                variant: 'error'
            }));
        }
    }

    get hasRequests() { return this.requests?.length > 0; }
    get overLimitWarnings() { return this.modalWarnings; }
    get hasOverLimitWarnings() { return this.modalWarnings.length > 0; }

    // Відкрити модалку редагування УЗГОДЖЕНОГО
    handleApprove(event) {
        const supplierId = event.currentTarget.dataset.id;
        const baseIndex = this.requests.findIndex(r => r.id === supplierId);
        if (baseIndex < 0) return;

        const row = this.requests[baseIndex];

        this.selectedRequest = {
            id: row.id,
            index: baseIndex,                // індекс у this.requests
            supplier: row.supplier,
            dec1: row.proposed.dec1,
            dec2: row.proposed.dec2,
            dec3: row.proposed.dec3,
            dec1Approved: row.preview.dec1 ?? row.approved.dec1,
            dec2Approved: row.preview.dec2 ?? row.approved.dec2,
            dec3Approved: row.preview.dec3 ?? row.approved.dec3,
            apprDetailDec1Id: row.apprDetailDec1Id || null,
            apprDetailDec2Id: row.apprDetailDec2Id || null,
            apprDetailDec3Id: row.apprDetailDec3Id || null,
            showNoDeclared: !row.hasDeclared,
            showNoApproved: !row.hasApproved,
            hasSupplierLimitEdit: row.hasSupplierLimitEdit
        };

        this.uploadedFiles = [];
        this.isModalOpen = true;

        this.refreshDisplays(baseIndex);
        this.updateModalWarnings();
        this.triedToSubmit = false;
    }



    // live-update інпутів узгодженого
    handleInputChange(event) {
        const fieldName = event.target.dataset.name; // 'dec1' | 'dec2' | 'dec3'
        const value = event.target.value === '' ? null : Number(event.target.value);

        // оновлюємо selectedRequest
        this.selectedRequest = { ...this.selectedRequest, [`${fieldName}Approved`]: value };

        // актуальний індекс у базовому масиві
        const baseIndex = this.requests.findIndex(r => r.id === this.selectedRequest.id);
        if (baseIndex < 0) return;

        const list = [...this.requests];
        list[baseIndex] = {
            ...list[baseIndex],
            preview: { ...list[baseIndex].preview, [fieldName]: value }
        };
        this.requests = list;

        this.refreshDisplays(baseIndex);
        this.updateModalWarnings();
    }

    handleModalCancel() {
        this.isModalOpen = false;
    }

    @track isSaving = false; // <— нове


    // Зберегти узгоджені значення
    handleModalSave = async () => {
        if (this.isSaving) return; // захист від дубль-кліків

        if (!this.approvedAllFilledAndValid) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Перевірте значення',
                message: 'Усі три значення узгоджених лімітів мають бути заповнені числами ≥ 0.',
                variant: 'error'
            }));
            return;
        }
        if (this.limitsChanged && !this.hasContractFile) {
            this.triedToSubmit = true;
            this.dispatchEvent(new ShowToastEvent({
                title: 'Немає підтверджувального документа',
                message: 'Додайте PDF договору/додаткової угоди для підтвердження змін.',
                variant: 'error'
            }));
            return;
        }

        this.isSaving = true; // <— показуємо спінер

        const r = this.selectedRequest;
        const today = new Date();

        // збираємо зміни по декадах
        const changes = [];
        changes.push({ detailId: r.apprDetailDec1Id || null, decade: 1, newLimit: r.dec1Approved });
        changes.push({ detailId: r.apprDetailDec2Id || null, decade: 2, newLimit: r.dec2Approved });
        changes.push({ detailId: r.apprDetailDec3Id || null, decade: 3, newLimit: r.dec3Approved });

        try {
            console.log('r.id: ' + r.id);
            console.log('year: ' + today.getFullYear());
            console.log('month: ' + today.getMonth() + 1);
            console.log('changes: ' + JSON.stringify(changes,null,2));
            console.log('contentDocIds: ' + this.uploadedFiles.map(f => f.documentId));
            await saveApprovedEdits({
                supplierId: r.id,
                year: today.getFullYear(),
                month: today.getMonth() + 1, // 1..12
                changes,
                contentDocIds: this.uploadedFiles.map(f => f.documentId)
            });

            const idx = r.index;
            const list = [...this.requests];
            list[idx] = {
                ...list[idx],
                approved: {
                    dec1: r.dec1Approved,
                    dec2: r.dec2Approved,
                    dec3: r.dec3Approved
                },
                preview: { dec1: null, dec2: null, dec3: null },
                hasSupplierLimitEdit: true // тепер точно є правка у цьому місяці
            };
            this.requests = list;
            this.refreshDisplays(idx);

            this.isModalOpen = false;
            this.dispatchEvent(new ShowToastEvent({
                title: 'Збережено',
                message: `Узгоджені ліміти для ${r.supplier} оновлено.`,
                variant: 'success'
            }));
        } catch (e) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Помилка збереження',
                message: e?.body?.message || e?.message || 'Не вдалося зберегти зміни.',
                variant: 'error'
            }));
        } finally {
            this.isSaving = false; // <— ховаємо спінер у будь-якому разі
        }
    };

    // Перерахунок approved/factual/remain + підсвітка
    refreshDisplays(index) {
        const list = [...this.requests];
        const row = { ...list[index] };

        const approvedDec1 = row.preview.dec1 ?? row.approved.dec1;
        const approvedDec2 = row.preview.dec2 ?? row.approved.dec2;
        const approvedDec3 = row.preview.dec3 ?? row.approved.dec3;

        const toNum = v => (v == null ? 0 : v);
        const toStr = v => (v == null ? '—' : v);

        const approvedTotal = toNum(approvedDec1) + toNum(approvedDec2) + toNum(approvedDec3);
        const proposedTotal = row.proposed.dec1 + row.proposed.dec2 + row.proposed.dec3;

        row.approvedDisplay = {
            dec1: toStr(approvedDec1),
            dec2: toStr(approvedDec2),
            dec3: toStr(approvedDec3),
            total: (approvedDec1!=null && approvedDec2!=null && approvedDec3!=null) ? approvedTotal : '—'
        };

        const factualDec1 = toNum(row.factual.dec1);
        const factualDec2 = toNum(row.factual.dec2);
        const factualDec3 = toNum(row.factual.dec3);
        const factualTotal = factualDec1 + factualDec2 + factualDec3;

        row.factualDisplay = {
            dec1: toStr(factualDec1),
            dec2: toStr(factualDec2),
            dec3: toStr(factualDec3),
            total: factualTotal
        };

        // залишок = approved - factual (показуємо total тільки якщо всі approved задані)
        const remainDec1 = toNum(approvedDec1) - factualDec1;
        const remainDec2 = toNum(approvedDec2) - factualDec2;
        const remainDec3 = toNum(approvedDec3) - factualDec3;
        const remainTotal = remainDec1 + remainDec2 + remainDec3;

        const allApprovedFilled = (approvedDec1!=null && approvedDec2!=null && approvedDec3!=null);
        row.remainDisplay = {
            dec1: allApprovedFilled ? remainDec1 : '—',
            dec2: allApprovedFilled ? remainDec2 : '—',
            dec3: allApprovedFilled ? remainDec3 : '—',
            total: allApprovedFilled ? remainTotal : '—'
        };

        const changed1 = (approvedDec1 ?? null) !== (row.approved.dec1 ?? null);
        const changed2 = (approvedDec2 ?? null) !== (row.approved.dec2 ?? null);
        const changed3 = (approvedDec3 ?? null) !== (row.approved.dec3 ?? null);

// невеличкі бейджі-дельти
        const delta = (a, b) => (a == null || b == null) ? '' : ((a - b) === 0 ? '' : ((a - b) > 0 ? `+${a-b}` : `${a-b}`));

        row.changedFlags = { d1: changed1, d2: changed2, d3: changed3 };
        row.deltas = {
            d1: delta(approvedDec1, row.approved.dec1),
            d2: delta(approvedDec2, row.approved.dec2),
            d3: delta(approvedDec3, row.approved.dec3),
        };


        row.proposedDisplay = {
            ...row.proposed,
            total: proposedTotal
        };

        // row.monthAlertClass = (allApprovedFilled && approvedTotal > proposedTotal) ? 'month-danger' : '';
        row.monthAlertClass = (allApprovedFilled && approvedTotal > proposedTotal && row.hasSupplierLimitEdit)
            ? 'month-danger'
            : '';
        row.approvedRowClass = allApprovedFilled ? 'approved-row approved-row--filled' : 'approved-row';

        list[index] = row;
        this.requests = list;
    }

    updateModalWarnings() {
        const r = this.selectedRequest;
        if (!r) { this.modalWarnings = []; return; }

        if (!r.hasSupplierLimitEdit) { this.modalWarnings = []; return; }

        const msgs = [];
        const push = (key, text, className) => msgs.push({ key, text, className });

        const check = (label, appr, prop, key) => {
            if (appr == null || prop == null) return;
            if (appr > prop) {
                const diff = appr - prop;
                push(key, `${label} — узгоджений більший на ${diff} за заявлений (${prop}).`, 'warn-decade');
            }
        };

        check('1 декада', r.dec1Approved, r.dec1, 'd1');
        check('2 декада', r.dec2Approved, r.dec2, 'd2');
        check('3 декада', r.dec3Approved, r.dec3, 'd3');

        const allFilled = r.dec1Approved!=null && r.dec2Approved!=null && r.dec3Approved!=null;
        if (allFilled) {
            const apprSum = r.dec1Approved + r.dec2Approved + r.dec3Approved;
            const propSum  = r.dec1 + r.dec2 + r.dec3;
            if (apprSum > propSum) {
                push('m', `Місяць — узгоджений сумарний більший на ${apprSum - propSum} за заявлений (${propSum}).`, 'warn-month');
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
        if (this.isSaving) return true; // <— нове

        const r = this.selectedRequest;
        if (!r) return true;

        const validNumbers =
            this.isNumberValid(r.dec1Approved) &&
            this.isNumberValid(r.dec2Approved) &&
            this.isNumberValid(r.dec3Approved);

        if (!validNumbers) return true;

        // Якщо є зміни і немає файлу — блокуємо
        if (this.limitsChanged && this.uploadedFiles.length === 0) {
            return true;
        }

        return false;
    }

    get mustUploadFile() {
        // Показуємо inline-попередження
        return this.limitsChanged && this.uploadedFiles.length === 0;
    }

    get canUseFileUpload() {
        // можемо виводити lightning-file-upload, якщо є recordId
        return !!this.effectiveUploadRecordId;
    }
    get effectiveUploadRecordId() {
        // джерела для recordId у такому порядку пріоритету:
        // 1) явно переданий @api uploadRecordId
        // 2) relatedRecordId від вибраного рядка (якщо додаси в демо)
        return this.uploadRecordId || null;
    }

    handleUploadFinished(event) {
        const files = event.detail?.files || [];
        this.uploadedFiles = files.map(f => ({ documentId: f.documentId, name: f.name }));
        this.dispatchEvent(new ShowToastEvent({
            title: 'Файл завантажено',
            message: files.length ? files[0].name : 'Документ додано.',
            variant: 'success'
        }));
    }

    removeUploadedFile = (e) => {
        const id = e.currentTarget.dataset.id;
        this.uploadedFiles = this.uploadedFiles.filter(f => f.documentId !== id);
    };

    // ===== Валідація числових полів =====
    isNumberValid(n) {
        // дозволяємо 0 і додатні, без NaN/Infinity
        return n !== null && n !== '' && !isNaN(n) && isFinite(n) && Number(n) >= 0;
    }

    get approvedAllFilledAndValid() {
        const r = this.selectedRequest;
        if (!r) return false;
        return this.isNumberValid(r.dec1Approved) &&
            this.isNumberValid(r.dec2Approved) &&
            this.isNumberValid(r.dec3Approved);
    }

    get hasContractFile() {
        // потребуємо мінімум 1 файл
        return this.uploadedFiles.length > 0;
    }

    get limitsChanged() {
        if (!this.selectedRequest) return false;

        const baseIndex = this.requests.findIndex(r => r.id === this.selectedRequest.id);
        if (baseIndex < 0) return false;

        const row = this.requests[baseIndex];
        const d1 = this.selectedRequest.dec1Approved;
        const d2 = this.selectedRequest.dec2Approved;
        const d3 = this.selectedRequest.dec3Approved;

        return (d1 !== row.approved.dec1) || (d2 !== row.approved.dec2) || (d3 !== row.approved.dec3);
    }


    // ==== інші твої методи лишай без змін (refreshDisplays, updateModalWarnings, handleInputChange тощо) ====

    get showContractError() {
        return this.triedToSubmit && !this.hasContractFile && this.limitsChanged;
    }

    // ▼ СТАН акордеона
    @track summaryOpen = false;

// ▼ Місячний лейбл
    get currentMonthLabel() {
        try {
            const d = new Date();
            const s = new Intl.DateTimeFormat('uk-UA', { month: 'long', year: 'numeric' }).format(d);
            return s.charAt(0).toUpperCase() + s.slice(1);
        } catch (e) { return 'цей місяць'; }
    }

    toggleSummary = () => { this.summaryOpen = !this.summaryOpen; };

// ▼ Допоміжне: нормалізуємо тип (COMMERCIAL|CORPORATE|OTHER)
    _normalizeKind(k) {
        const v = (k || '').toString().toUpperCase();
        if (v.includes('COMMERCIAL') || v.includes('КОМЕР')) return 'COMMERCIAL';
        if (v.includes('CORPORATE')  || v.includes('КОРП'))  return 'CORPORATE';
        return 'OTHER';
    }

// ▼ Звідки брати рядки для підсумку: беремо вже відфільтровані (пошуком) дані
    get _rowsForTotals() { return this.filteredAndSorted || []; }

// ▼ Сума approved по типу постачальника
    _sumApprovedByKind(kind) {
        let d1=0, d2=0, d3=0;
        const K = this._normalizeKind(kind);
        for (const r of this._rowsForTotals) {
            // r._kind ставимо при завантаженні (див. loadData нижче)
            const rowKind = this._normalizeKind(r._kind);
            if (rowKind !== K) continue;

            const a1 = Number(r.approved?.dec1 || 0);
            const a2 = Number(r.approved?.dec2 || 0);
            const a3 = Number(r.approved?.dec3 || 0);
            d1 += a1; d2 += a2; d3 += a3;
        }
        return { dec1: d1, dec2: d2, dec3: d3, total: d1 + d2 + d3 };
    }

    get summaryCommercial() { return this._sumApprovedByKind('COMMERCIAL'); }
    get summaryCorporate()  { return this._sumApprovedByKind('CORPORATE'); }

}