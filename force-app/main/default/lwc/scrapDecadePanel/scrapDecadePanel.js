import { LightningElement, track } from 'lwc';
import getHierarchy from '@salesforce/apex/ScrapDecadesController.getHierarchy'
import getByBranchAndGroup from '@salesforce/apex/ScrapTypeService.getByBranchAndGroup';
import getDayLimitsByDate from '@salesforce/apex/ScrapDecadesController.getDayLimitsByDate';

import saveDayLimitsByDate from '@salesforce/apex/ScrapDecadesController.saveDayLimitsByDate';
import saveDayLimitsForDay from '@salesforce/apex/ScrapDecadesController.saveDayLimitsForDay';
import getDecadeTotalsByDecade from '@salesforce/apex/ScrapDecadesController.getDecadeTotalsByDecade';
import getMonthTotalsByMonth from '@salesforce/apex/ScrapDecadesController.getMonthTotalsByMonth';
import getYearTotalsByYear from '@salesforce/apex/ScrapDecadesController.getYearTotalsByYear';

import listSiblingDays from '@salesforce/apex/ScrapDecadesController.listSiblingDays';
import copyDayLimits from '@salesforce/apex/ScrapDecadesController.copyDayLimits';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';


import LightningConfirm from 'lightning/confirm';


export default class ScrapDecadePanel extends LightningElement {
    @track searchQuery = '';
    @track selectedNode = null;

    // те, що рендеримо зліва
    @track yearNode = null;
    @track copying = false;


    @track showCopyModal = false;
    @track copyLoading = false;
    @track siblingDays = []; // [{id, label, hasLimits, checked}]
    get siblingDaysEmpty() { return !this.siblingDays || this.siblingDays.length === 0; }
    get submitCopyDisabled() {
        return this.copyLoading || this.siblingDays.every(d => !d.checked);
    }

    async openCopyModal() {
        // діагностика
        // eslint-disable-next-line no-console
        console.log('[ScrapDecadePanel] openCopyModal click, isDay=', this.isDay, ' node?', !!this.selectedNode);

        if (!this.isDay || !this.selectedNode) return;

        // Показуємо модалку відразу (щоб бачити спінер),
        // і НЕ закриваємо її у catch (лише показуємо тост).
        this.showCopyModal = true;
        this.copying = false;        // ← важливо

        this.copyLoading = true;

        try {
            const rows = await listSiblingDays({ sourceDayDecadeId: this.selectedNode.id });
            this.siblingDays = (rows || []).map(r => ({
                id: r.id,
                // позначимо вихідні, щоб користувачу було видно
                label: r.label + (r.isWeekend ? ' • вихідний' : ''),
                hasLimits: r.hasLimits,
                isWeekend: !!r.isWeekend,
                // вихідні не обираємо за замовчуванням
                checked: !r.hasLimits && !r.isWeekend
            }));
        } catch (e) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Помилка',
                message: (e?.body?.message) || 'Не вдалося завантажити дні декади',
                variant: 'error'
            }));
            // ВАЖЛИВО: не закриваємо модалку, щоб було видно помилку/стан
            // this.showCopyModal = false;  // ← прибрати
        } finally {
            this.copyLoading = false;
        }
    }

    handleTargetCheckbox = (e) => {
        const id = e.currentTarget.dataset.id;
        const checked = e.target.checked;
        this.siblingDays = this.siblingDays.map(d => d.id === id ? { ...d, checked } : d);
    }

    selectAllTargets = () => {
        this.siblingDays = this.siblingDays.map(d => ({ ...d, checked: true }));
    }
    clearAllTargets = () => {
        this.siblingDays = this.siblingDays.map(d => ({ ...d, checked: false }));
    }

    submitCopy = async () => {
        const targetIds = this.siblingDays
            .filter(d => d.checked && !d.isWeekend)
            .map(d => d.id);

        if (!targetIds.length) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Увага',
                message: 'Немає обраних робочих днів для копіювання (вихідні ігноруються).',
                variant: 'warning'
            }));
            return;
        }

        if (!targetIds.length) {
            this.dispatchEvent(new ShowToastEvent({ title:'Увага', message:'Оберіть принаймні один день', variant:'warning' }));
            return;
        }

        // якщо редагуєш — беремо значення з інпутів
        let items = null;
        if (this.isEditingDay) {
            items = (this.dayEditRows || []).map(r => ({
                scrapTypeId: r.id,
                value: (r.inputValue === null || r.inputValue === undefined || r.inputValue === '') ? '' : String(r.inputValue)
            }));
        }

        // === чанки по днях
        const DAY_CHUNK = 1;       // один день за виклик (щоб зменшити навантаження тригерів)
        const TYPE_CHUNK = 12;     // 10–15 типів за виклик зазвичай безпечно
        const dayChunks = [];
        for (let i=0; i<targetIds.length; i+=DAY_CHUNK) {
            dayChunks.push(targetIds.slice(i, i+DAY_CHUNK));
        }

        // список типів (коли items == null, ми копіюємо зі збереженого дня-джерела,
        // але обмежуємо набором активних типів)
        const allTypeIds = (this.isEditingDay)
            ? (items || []).map(i => i.scrapTypeId)
            : (this.activeTypes || []).map(t => t.id);

        // розрізаємо типи
        const typeChunks = [];
        for (let i=0; i<allTypeIds.length; i+=TYPE_CHUNK) {
            typeChunks.push(allTypeIds.slice(i, i+TYPE_CHUNK));
        }

        this.copying = true;         // ← покажемо текст
        this.copyLoading = true;
        let inserted = 0, updated = 0, total = 0;

        try {
            for (const idsOfDays of dayChunks) {
                for (const idsOfTypes of typeChunks) {
                    const res = await copyDayLimits({
                        sourceDayDecadeId: this.selectedNode.id,
                        targetDayDecadeIds: idsOfDays,
                        items,                 // якщо не редагуєш — null
                        skipZeros: false,
                        onlyTypeIds: idsOfTypes   // <— НОВЕ
                    });
                    inserted += res?.inserted || 0;
                    updated  += res?.updated  || 0;
                    total    += res?.totalProcessed || 0;
                }
            }

            this.dispatchEvent(new ShowToastEvent({
                title: 'Готово',
                message: `Скопійовано: ${total} запис(ів) (створено: ${inserted}, оновлено: ${updated}).`,
                variant: 'success'
            }));
            this.showCopyModal = false;
        } catch (e) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Помилка копіювання',
                message: (e?.body?.message) || 'Сталася невідома помилка',
                variant: 'error'
            }));
        } finally {
            this.copying = false;
            this.copyLoading = false;
        }
    }

    get isModalBusy() { return this.copyLoading || this.copying; }

    closeCopyModal = () => { this.showCopyModal = false; }


    // кеш оригіналу (для пошуку/розгортання)
    fullYearNode = null;

    get isDecade() {
        return this.selectedNode && this.selectedNode.level === 3;
    }

    connectedCallback() { this.loadTree(); }

    @track activeTypes = [];   // [{ id, name, code }]
    @track loadingActive = false;

    get isDay() {
        return this.selectedNode && this.selectedNode.level === 4;
    }
    get activeTypesEmpty() {
        return !this.activeTypes || this.activeTypes.length === 0;
    }

    async ensureActiveTypesLoaded() {
        if (this.activeTypes && this.activeTypes.length) return;
        this.loadingActive = true;
        try {
            const data = await getByBranchAndGroup(); // { commercial:[{items:[]}], corporate:[{items:[]}]}
            const pick = (arr) => (arr || []).flatMap(g => g.items || []);
            const all = [...pick(data?.commercial), ...pick(data?.corporate)];
            this.activeTypes = all
                .filter(it => it?.IsActive__c)
                .map(it => ({ id: it.Id, name: it.Name, code: it.ScrapTypeCode__c }))
                .sort((a,b) => a.name.localeCompare(b.name, 'uk'));
        } catch(e) {
            console.error(e);
            this.activeTypes = [];
        } finally {
            this.loadingActive = false;
        }
    }

    async loadTree() {
        try {
            const data = await getHierarchy({ yearFilter: null, limitSize: 50000 });
            const roots = Array.isArray(data) ? data : [];
            const calendar = roots[0]; // level 0
            const nodes = calendar?.children?.length ? calendar.children : roots;

            const currentYear = new Date().getFullYear();
            const year = (nodes || []).find(n => n.level === 1 && n.year === currentYear);
            if (!year) { this.yearNode = null; return; }

            // обгортаємо UI-класами та розкриваємо до рівня місяців
            const decorated = this.decorate(year);
            this.fullYearNode = this.openUntilLevel(decorated, 2);
            this.yearNode = this.fullYearNode;
        } catch (e) {
            // eslint-disable-next-line no-console
            console.error('Помилка завантаження дерева', e);
        }
    }

    // додає rowClass/itemClass/caretClass рекурсивно
    decorate(node, selectedId = null) {
        const clone = { ...node };
        const isLeafDay = clone.level === 4;
        const isSelected = selectedId && clone.id === selectedId;

        clone.open = clone.open || false;
        clone.caretClass = clone.hasChildren ? `caret${clone.open ? ' open' : ''}` : 'caret empty';
        clone.rowClass = `group-row${isSelected ? ' active' : ''}`;
        clone.itemClass = `sp-item${isSelected ? ' active' : ''}`;

        clone.children = (clone.children || []).map(ch => this.decorate(ch, selectedId));
        return clone;
    }

    openUntilLevel(node, maxLvl) {
        const walk = (n) => {
            const open = n.level < maxLvl;
            const updated = {
                ...n,
                open,
                caretClass: n.hasChildren ? `caret${open ? ' open' : ''}` : 'caret empty',
                children: (n.children || []).map(walk)
            };
            return updated;
        };
        return walk(node);
    }

    // ---- події лівої панелі
    toggleNode = (e) => {
        e.stopPropagation();
        const id = e.currentTarget.dataset.id;
        const toggle = (n) => {
            if (n.id === id) {
                const open = !n.open;
                return { ...n, open, caretClass: n.hasChildren ? `caret${open ? ' open' : ''}` : 'caret empty',
                    children: (n.children || []).map(toggle) };
            }
            return { ...n, children: (n.children || []).map(toggle) };
        };
        this.yearNode = toggle(this.yearNode);
        this.fullYearNode = toggle(this.fullYearNode);
    };

    handleSelectNode = (e) => {
        const id = e.currentTarget.dataset.id;
        const find = (n) => {
            if (n.id === id) return n;
            for (const c of (n.children || [])) {
                const f = find(c); if (f) return f;
            }
            return null;
        };
        const node = this.yearNode ? find(this.yearNode) : null;
        this.selectedNode = node;

        if (this.isDay) {
            this.loadDayLimits(this.selectedNode.dateValue);
            this.ensureActiveTypesLoaded();
        } else if (this.isDecade) {
            this.loadDecadeTotals(this.selectedNode.id);
        } else if (this.isMonth) {
            this.loadMonthTotals(this.selectedNode.id);
        } else if (this.isYear) {
            this.loadYearTotals(this.selectedNode.id);
        }




        // оновити підсвітку
        const repaint = (n) => {
            const isSelected = n.id === id;
            const base = n.level === 4 ? 'sp-item' : 'group-row';
            const itemClass = `${base}${isSelected ? ' active' : ''}`;
            const out = { ...n };
            if (n.level === 4) out.itemClass = itemClass; else out.rowClass = itemClass;
            out.children = (n.children || []).map(repaint);
            return out;
        };
        if (this.yearNode) this.yearNode = repaint(this.yearNode);
        if (this.fullYearNode) this.fullYearNode = repaint(this.fullYearNode);
    };

    // ---- пошук по назві
    handleSearchInput = (e) => {
        this.searchQuery = (e.target.value || '').trim().toLowerCase();
        if (!this.searchQuery) { this.yearNode = this.fullYearNode; return; }

        const filter = (n) => {
            const match = (n.name || '').toLowerCase().includes(this.searchQuery);
            const children = (n.children || []).map(filter).filter(Boolean);
            if (match || children.length) {
                const open = children.length > 0;
                return { ...n, open, caretClass: n.hasChildren ? `caret${open ? ' open' : ''}` : 'caret empty', children };
            }
            return null;
        };
        this.yearNode = filter(this.fullYearNode);
    };

    // ---- тулбар
    expandAll = () => {
        const expand = (n) => ({ ...n, open: true, caretClass: n.hasChildren ? 'caret open' : 'caret empty',
            children: (n.children || []).map(expand) });
        if (this.yearNode) this.yearNode = expand(this.yearNode);
        if (this.fullYearNode) this.fullYearNode = expand(this.fullYearNode);
    };

    collapseAll = () => {
        const collapse = (n) => ({ ...n, open: false, caretClass: n.hasChildren ? 'caret' : 'caret empty',
            children: (n.children || []).map(collapse) });
        if (this.yearNode) this.yearNode = collapse(this.yearNode);
        if (this.fullYearNode) this.fullYearNode = collapse(this.fullYearNode);
    };

    // +++ додай у класі
    @track dayValues = {}; // { [scrapTypeId]: number }

// рядки для таблиці дня
    get dayRows() {
        return (this.activeTypes || []).map(t => ({
            id: t.id,
            name: t.name,
            code: t.code,
            value: this.dayValues[t.id] ?? ''
        }));
    }
    get dayRowsEmpty() {
        return !this.dayRows.length;
    }

// обробник зміни значення
    handleDayValueChange = (e) => {
        const id = e.currentTarget.dataset.id;
        let val = e.target.value;
        // пусте -> приберемо з мапи
        if (val === '' || val === null || val === undefined) {
            const copy = { ...this.dayValues };
            delete copy[id];
            this.dayValues = copy;
            return;
        }
        const num = Number(val);
        this.dayValues = { ...this.dayValues, [id]: isNaN(num) ? '' : num };
    };

// (необов'язково) cкинути введене за день
    reloadDay = () => { this.dayValues = {}; };

    @track dayLimits = [];
    @track loadingDayLimits = false;

    async loadDayLimits(dateValue) {
        this.loadingDayLimits = true;
        try {
            const data = await getDayLimitsByDate({ targetDate: dateValue });

            // ЗАМІНИ мапінг dayLimits:
            this.dayLimits = (data || []).map(d => {
                const raw = d.limitValue;                          // "1100.6" або null
                const num = raw == null ? null : Number(raw);      // 1100.6 або null
                const isPos = num != null && !isNaN(num) && num > 0;

                const lim = d.limitValue || "0.0";
                const inc = d.incoming   || "0.0";
                const rem = d.remaining  || "0.0";

                return {
                    id: d.scrapTypeId,
                    name: d.name,
                    // ► для підрахунків
                    limitValue: isPos ? num : 0,                     // число (0 якщо пусто)
                    // ► для відображення
                    limitText: isPos ? String(raw) : '—',
                    incoming: inc,
                    remaining: rem,
                    rowClass: isPos ? 'row-filled' : 'row-empty'
                };
            });


            // підготовка редагування: нульові та порожні робимо пустим інпутом
            this.dayEditRows = (this.dayLimits || []).map(r => ({
                id: r.id,
                name: r.name,
                inputValue: (r.limitValue && r.limitValue > 0) ? String(r.limitValue) : '' // '' якщо пусто
            }));


            this._originalDayEditSnapshot = JSON.stringify(this.dayEditRows || []);
            this.isEditingDay = false;
            this.dayLoadedAt = new Date();
        } catch (e) {
            console.error('Помилка завантаження лімітів', e);
            this.dayLimits = [];
            this.dayEditRows = [];
            this._originalDayEditSnapshot = '[]';
            this.isEditingDay = false;
            this.dayLoadedAt = null;
        } finally {
            this.loadingDayLimits = false;
        }
    }


    get dayLimitsEmpty() {
        return !this.dayLimits || this.dayLimits.length === 0;
    }

    @track dayLoadedAt; // Date

    get dayCount()  { return (this.dayLimits || []).length; }
    // get dayFilled() { return (this.dayLimits || []).filter(r => r._filled).length; }
    // get dayEmpty()  { return Math.max(this.dayCount - this.dayFilled, 0); }
    get hasAnyLimits() { return this.dayFilled > 0; }


    // get dayCount()  { return (this.dayLimits || []).length; }
    // get dayFilled() { return (this.dayLimits || []).filter(r => r.limitValue !== null && r.limitValue !== undefined && r.limitValue !== '' && r.limitValue !== '—').length; }
    // get dayEmpty()  { return Math.max(this.dayCount - this.dayFilled, 0); }
    // get hasAnyLimits() { return this.dayFilled > 0; }


    get dayLoadedAtStr() {
        return this.dayLoadedAt
            ? new Intl.DateTimeFormat('uk-UA', { hour: '2-digit', minute: '2-digit', day: '2-digit', month: '2-digit' }).format(this.dayLoadedAt)
            : '';
    }

// після успішного завантаження лімітів у loadDayLimits(...)

// кнопка "Внести ліміти" (поки заглушка)
    handleEnterEdit = () => {
        // TODO: тут ввімкнемо режим редагування в наступному кроці
        // наприклад: this.isEditTab = true;
        // Зараз — простий toast/console:
        // eslint-disable-next-line no-console
        console.log('Enter edit mode (todo)');
    };

    get selectedDateFormatted() {
        if (!this.selectedNode || !this.selectedNode.dateValue) return '';
        // полудень, щоб уникнути часових зсувів
        const d = new Date(this.selectedNode.dateValue + 'T12:00:00');
        if (isNaN(d)) return this.selectedNode.dateValue;
        const date = d.toLocaleDateString('uk-UA', { day:'2-digit', month:'2-digit', year:'numeric' });
        const dow  = d.toLocaleDateString('uk-UA', { weekday:'short' }).toLowerCase(); // 'пн','вт',...
        return `${date} (${dow})`;
    }

    // NEW: чи ввімкнено режим редагування дня
// NEW: рядки для редагування (мають inputValue)
    @track dayEditRows = [];

// Заміни/додай цей геттер, щоб таблиця брала правильні рядки
    get dayTableRows() {
        return this.isEditingDay ? this.dayEditRows : this.dayLimits;
    }

// NEW: клік по "Внести ліміти" – вмикає/вимикає режим і готує inputValue
    handleEnterLimitsClick = () => {
        if (!this.isDay) return;
        if (!this.dayEditMode) {
            this.dayEditRows = (this.dayLimits || []).map(r => ({
                ...r,
                // якщо прочерк — залишаємо порожнім
                inputValue: (r.limitValue === '—' || r.limitValue === null || r.limitValue === undefined)
                    ? null
                    : Number(r.limitValue)
            }));
            this.dayEditMode = true;
        } else {
            this.dayEditMode = false;
        }
    };

// NEW: зміна значення в полі
//     handleEditInputChange = (e) => {
//         const id = e.currentTarget.dataset.id;
//         let val = e.target.value;
//
//         // Якщо пусто — прибираємо
//         if (!val) {
//             this.dayEditRows = this.dayEditRows.map(r =>
//                 r.id === id ? { ...r, inputValue: null } : r
//             );
//             return;
//         }
//
//         // Валідація по regex
//         const regex = /^\d+(\.\d)?$/;
//         if (!regex.test(val)) {
//             e.target.setCustomValidity('Введіть число або число з одним десятковим знаком');
//             e.target.reportValidity();
//             return;
//         } else {
//             e.target.setCustomValidity('');
//             e.target.reportValidity();
//         }
//
//         this.dayEditRows = this.dayEditRows.map(r =>
//             r.id === id ? { ...r, inputValue: val } : r
//         );
//     };

    handleEditInputChange = (e) => {
        const id = e.currentTarget.dataset.id;
        let val = (e.target.value || '').trim();

        if (!val) {
            this.dayEditRows = this.dayEditRows.map(r => r.id === id ? { ...r, inputValue: '' } : r);
            e.target.setCustomValidity('');
            e.target.reportValidity();
            return;
        }

        const regex = /^\d+(\.\d)?$/; // ціле або з одним десятком
        if (!regex.test(val)) {
            e.target.setCustomValidity('Введіть число або число з одним десятковим знаком (наприклад 10 або 10.1)');
            e.target.reportValidity();
            return;
        }
        e.target.setCustomValidity('');
        e.target.reportValidity();

        this.dayEditRows = this.dayEditRows.map(r => r.id === id ? { ...r, inputValue: val } : r);
    };

    @track isEditingDay = false;
    _originalDayEditSnapshot = '[]';   // для порівняння змін

    startEditDay = () => {
        if (!this.dayEditRows || !this.dayEditRows.length) {
            this.dayEditRows = (this.dayLimits || []).map(r => ({
                id: r.id,
                name: r.name,
                inputValue: r.limitValue === '—' ? '' : (r.limitValue || '')
            }));
            this._originalDayEditSnapshot = JSON.stringify(this.dayEditRows);
        }
        this.isEditingDay = true;
    };

// чи є незбережені зміни
    get hasDayChanges() {
        return JSON.stringify(this.dayEditRows || []) !== this._originalDayEditSnapshot;
    }

    cancelEditDay = async () => {
        if (this.hasDayChanges) {
            const ok = await LightningConfirm.open({
                message: 'Скасувати зміни? Їх не буде збережено.',
                label: 'Підтвердження',
                theme: 'warning'
            });
            if (!ok) return;
        }
        // повертаємо редаговані рядки до оригіналу
        this.dayEditRows = JSON.parse(this._originalDayEditSnapshot);
        this.isEditingDay = false;
    };

// збереження (поки без бекенда — просто закриємо режим)
    saveDayLimits = async () => {
        // підготуємо payload з інпутів
        // const items = (this.dayEditRows || [])
        //     .filter(r => r && r.id) // тільки валідні
        //     .map(r => ({ scrapTypeId: r.id, value: (r.inputValue ?? '').toString().trim() }));

        const items = (this.dayEditRows || []).map(r => ({
            scrapTypeId: r.id,
            // можна передавати '' або null — бекенд все одно зробить 0
            value: (r.inputValue === null || r.inputValue === undefined) ? '' : String(r.inputValue)
        }));




        try {
            this.loadingDayLimits = true;

            console.log('this.selectedNote.id: ' + this.selectedNode.id);
            console.log('THIS ITEMS: ' + JSON.stringify(items,null,2));

            const result = await saveDayLimitsForDay({
                dayDecadeId: this.selectedNode.id,
                items
            });

            console.log('result: ' + result);

            // тост успіху
            this.dispatchEvent(new ShowToastEvent({
                title: 'Готово',
                message: 'Ліміти успішно збережено',
                variant: 'success'
            }));

            // перезавантажимо перегляд
            await this.loadDayLimits(this.selectedNode.dateValue);
            this.isEditingDay = false;
        } catch (e) {
            // тост помилки
            this.dispatchEvent(new ShowToastEvent({
                title: 'Помилка збереження',
                message: (e && e.body && e.body.message) ? e.body.message : 'Сталася невідома помилка',
                variant: 'error'
            }));
        } finally {
            this.loadingDayLimits = false;
        }
    };

    normalizeLimit(raw) {
        // повертає: { text: '—' або '10.1', filled: true/false, num: number|null }
        if (raw === null || raw === undefined || raw === '') {
            return { text: '—', filled: false, num: null };
        }
        const n = Number(raw);
        if (!isFinite(n)) {
            return { text: '—', filled: false, num: null };
        }
        // округлюємо до одного знаку після крапки, як і на бекенді
        const rounded = Math.round(n * 10) / 10;
        if (rounded === 0) {
            return { text: '—', filled: false, num: 0 };
        }
        // показуємо з одним десятковим знаком, щоб було послідовно (10.0 → 10.0)
        return { text: rounded.toFixed(1), filled: true, num: rounded };
    }

    @track decadeTotals = [];
    @track loadingDecadeTotals = false;
    @track decadeLoadedAt; // Date

    async loadDecadeTotals(decadeId) {
        console.log('loadDecadeTotals')
        this.loadingDecadeTotals = true;
        try {
            const data = await getDecadeTotalsByDecade({ decadeId });
            // нормалізуємо '0'/'0.0' -> '—' (про всяк випадок)
            this.decadeTotals = (data || []).map(d => {
                const isZero = d.totalValue === '0' || d.totalValue === '0.0' || Number(d.totalValue) === 0;
                return {
                    id: d.scrapTypeId,
                    name: d.name,
                    totalValue: (d.totalValue == null || isZero) ? '—' : d.totalValue,
                    incoming: d.incoming ?? '—',
                    remaining: d.remaining ?? '—'
                };
            });
            this.decadeLoadedAt = new Date();
        } catch(e) {
            console.error('Помилка завантаження сум по декаді', e);
            this.decadeTotals = [];
            this.decadeLoadedAt = null;
        } finally {
            this.loadingDecadeTotals = false;
        }
    }

// підрахунки для пігулок (аналогічно дням)
    get decadeCount()  { return (this.decadeTotals || []).length; }
    get decadeFilled() {
        const rows = this.decadeTotals || [];
        const isFilled = (v) => {
            if (v == null || v === '' || v === '—') return false;
            const num = Number(v);
            return !isNaN(num) && num > 0;
        };
        return rows.filter(r => isFilled(r.totalValue)).length;
    }
    get decadeEmpty()  { return Math.max(this.decadeCount - this.decadeFilled, 0); }
    get hasAnyDecadeTotals() { return this.decadeFilled > 0; }
    get decadeLoadedAtStr() {
        return this.decadeLoadedAt
            ? new Intl.DateTimeFormat('uk-UA', { hour: '2-digit', minute: '2-digit', day: '2-digit', month: '2-digit' }).format(this.decadeLoadedAt)
            : '';
    }

    // +++ додай у клас
    isPositive(v) {
        if (v == null || v === '' || v === '—') return false;
        const n = Number(v);
        return !isNaN(n) && n > 0;
    }

// рядковий клас для ДНЯ (view/edit)
    rowClassDay(r) {
        const val = this.isEditingDay ? r.inputValue : r.limitValue;
        return this.isPositive(val) ? 'row-filled' : 'row-empty';
    }

// індикатори стану ДНЯ

    get dayFilled() {
        const rows = this.isEditingDay ? (this.dayEditRows || []) : (this.dayLimits || []);
        return rows.filter(r => {
            const v = this.isEditingDay ? r.inputValue : r.limitValue;
            const num = (v === '' || v == null) ? null : Number(v);
            return num != null && !isNaN(num) && num > 0;
        }).length;
    }

    get dayEmpty()  { return Math.max(this.dayCount - this.dayFilled, 0); }
    get dayAllFilled() { return this.dayCount > 0 && this.dayEmpty === 0; }
    get dayCompletionPct() {
        if (!this.dayCount) return 0;
        return Math.round((this.dayFilled / this.dayCount) * 100);
    }

// --- для ДЕКАДИ (read-only)
    rowClassDecade(r) {
        return this.isPositive(r.totalValue) ? 'row-filled' : 'row-empty';
    }
    get decadeAllFilled() { return this.decadeCount > 0 && this.decadeEmpty === 0; }
    get decadeCompletionPct() {
        if (!this.decadeCount) return 0;
        return Math.round((this.decadeFilled / this.decadeCount) * 100);
    }

    get isMonth() {
        return this.selectedNode && this.selectedNode.level === 2;
    }

    @track monthTotals = [];
    @track loadingMonthTotals = false;
    @track monthLoadedAt;

    async loadMonthTotals(monthId) {
        this.loadingMonthTotals = true;
        try {
            const data = await getMonthTotalsByMonth({ monthId });
            this.monthTotals = (data || []).map(d => ({
                id: d.scrapTypeId,
                name: d.name,
                totalValue: d.totalValue || "0.0",
                incoming:   d.incoming   || "0.0",
                remaining:  d.remaining  || "0.0"
            }));


            this.monthLoadedAt = new Date();
        } catch (e) {
            console.error('Помилка завантаження сум по місяцю', e);
            this.monthTotals = [];
            this.monthLoadedAt = null;
        } finally {
            this.loadingMonthTotals = false;
        }
    }

    get monthCount()  { return (this.monthTotals || []).length; }
    get monthFilled() { return (this.monthTotals || []).filter(r => this.isPositive(r.totalValue)).length; }
    get monthEmpty()  { return Math.max(this.monthCount - this.monthFilled, 0); }
    get monthAllFilled() { return this.monthCount > 0 && this.monthEmpty === 0; }
    get monthCompletionPct() {
        if (!this.monthCount) return 0;
        return Math.round((this.monthFilled / this.monthCount) * 100);
    }
    get monthLoadedAtStr() {
        return this.monthLoadedAt
            ? new Intl.DateTimeFormat('uk-UA', { hour: '2-digit', minute: '2-digit', day: '2-digit', month: '2-digit' }).format(this.monthLoadedAt)
            : '';
    }
    get monthTotalsEmpty() {
        return !this.monthTotals || this.monthTotals.length === 0;
    }

    get isYear() {
        return this.selectedNode && this.selectedNode.level === 1;
    }

    @track yearTotals = [];
    @track loadingYearTotals = false;
    @track yearLoadedAt;

    async loadYearTotals(yearId) {
        this.loadingYearTotals = true;
        try {
            const data = await getYearTotalsByYear({ yearId });
            console.log('DATA: ' + JSON.stringify(data,null,2));
            this.yearTotals = (data || []).map(d => ({
                id: d.scrapTypeId,
                name: d.name,
                totalValue: d.totalValue || "0.0",
                incoming:   d.incoming   || "0.0",
                remaining:  d.remaining  || "0.0"
            }));

            this.yearLoadedAt = new Date();
        } catch (e) {
            console.error('Помилка завантаження сум по року', e);
            this.yearTotals = [];
            this.yearLoadedAt = null;
        } finally {
            this.loadingYearTotals = false;
        }
    }

    isNegative(v) {
        if (v == null || v === '' || v === '—') return false;
        const n = Number(v);
        return !isNaN(n) && n < 0;
    }

// онови rowClassDecade:
    rowClassDecade(r) {
        if (this.isNegative(r.remaining)) return 'row-over';   // наприклад, червоний фон
        return this.isPositive(r.totalValue) ? 'row-filled' : 'row-empty';
    }


    get yearCount()  { return (this.yearTotals || []).length; }
    get yearTotalsEmpty() {
        return !this.yearTotals || this.yearTotals.length === 0;
    }

    // get yearLoadedAtStr() {
    //     return this.yearLoadedAt ? new Intl.DateTimeFormat('uk-UA', { hour: '2-digit', minute: '2-digit', day: '2-digit', month: '2-digit' }).format(this.yearLoadedAt) : '';
    // }

    get yearLoadedAtStr() {
        return this.yearLoadedAt
            ? new Intl.DateTimeFormat('uk-UA', {
                day: '2-digit',
                month: '2-digit',
                year: 'numeric',     // додав рік
                hour: '2-digit',
                minute: '2-digit',
                timeZone: 'Europe/Kyiv' // розкоментуй, якщо треба фіксована зона
                // weekday: 'short'        // розкоментуй, якщо хочеш пн/вт/ср
            }).format(this.yearLoadedAt)
            : '';
    }

    @track onlyFilled = false;
    @track onlyEmpty  = false;

    toggleOnlyFilled = (e) => {
        this.onlyFilled = e.target.checked;
        if (this.onlyFilled) this.onlyEmpty = false; // взаємовиключно
    };
    toggleOnlyEmpty = (e) => {
        this.onlyEmpty = e.target.checked;
        if (this.onlyEmpty) this.onlyFilled = false; // взаємовиключно
    };

// чи "рядок заповнений"
    isRowFilled(row) {
        if (this.isEditingDay) {
            const v = row.inputValue;
            if (v === '' || v == null) return false;
            const n = Number(v);
            return !isNaN(n) && n > 0;
        } else {
            const n = row.limitValue;  // у тебе numeric або 0
            return n != null && !isNaN(n) && n > 0;
        }
    }

// застосовуємо фільтр до dayTableRows (який вже враховує режим view/edit)
    get filteredDayTableRows() {
        const rows = this.dayTableRows || [];
        if (this.onlyFilled && !this.onlyEmpty) return rows.filter(r => this.isRowFilled(r));
        if (!this.onlyFilled && this.onlyEmpty) return rows.filter(r => !this.isRowFilled(r));
        return rows; // обидва вимкнені (або обидва увімкнені) => показуємо всі
    }



}