import {LightningElement, track, api, wire} from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getDecadeGridForSupplier from '@salesforce/apex/ScrapSlotModalController.getDecadeGridForSupplier';
import getStep2StaticInfo from '@salesforce/apex/ScrapSlotModalController.getStep2StaticInfo'; // ⬅️ новий
import getStep2Lookups from '@salesforce/apex/ScrapSlotModalController.getStep2Lookups';
import createReserve from '@salesforce/apex/ScrapSlotModalController.createReserve';

import searchDrivers from '@salesforce/apex/ScrapSlotModalController.searchDrivers';
import sendReserveToErp from '@salesforce/apex/ScrapSlotModalController.sendReserveToErp';
import markReserveApproved from '@salesforce/apex/ScrapSlotModalController.markReserveApproved';
import checkSimilarReserve from '@salesforce/apex/ScrapSlotModalController.checkSimilarReserve';

import getDecadeGridForSupplierAtDate from '@salesforce/apex/ScrapSlotModalController.getDecadeGridForSupplierAtDate';
import getNextDecadeAnchor from '@salesforce/apex/ScrapSlotModalController.getNextDecadeAnchor';
import getPrevDecadeAnchor from '@salesforce/apex/ScrapSlotModalController.getPrevDecadeAnchor';


import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import SCRAP_SLOT_RESERVE_OBJECT from '@salesforce/schema/ScrapSlotReserve__c';
import FIXED_WEIGHT_FIELD from '@salesforce/schema/ScrapSlotReserve__c.FixedWeight__c';

import searchTrucks from '@salesforce/apex/ScrapSlotModalController.searchTrucks';

export default class ReserveSlotModal extends LightningElement {
    @api visible = false;
    @track isOutOfLimit = false; // уже є в тебе? лишаємо як state
    MIN_BOOK_TONNAGE = 10;


    @api
    get presetOutOfLimit() { return this.isOutOfLimit; }
    set presetOutOfLimit(v) {
        this.isOutOfLimit = !!v;             // значення приходить одноразово від батька
        this._applyOutOfLimitToGrid();       // перерахувати disabled по клітинках, якщо сітка вже завантажена
        this.recomputeAutoWeightNorm?.();    // опційно: підлаштувати рекомендований норматив
    }

    // Працюємо тільки з першою сторінкою
    @track currentStep = 'selectDate';
    get isStepSelectDate() { return this.currentStep === 'selectDate'; }
// ADD inside class ReserveSlotModal
    @track dupModalOpen = false;
    @track dupCheckInProgress = false;
    @track dupData = { exists:false, count:0, summaries:[], ids:[] };
    _forceCreate = false; // прапорець, щоб дозволити повторне створення після підтвердження

    // supplierId з батька
    _supplierId;
    @api
    get supplierId() { return this._supplierId; }
    set supplierId(v) {
        const changed = v !== this._supplierId;
        this._supplierId = v;
        if (changed && v && this.isConnected) this.loadGrid();
    }
    @track isSending = false;

    // ADD inside class ReserveSlotModal
    runDuplicateCheck = async () => {
        this.dupCheckInProgress = true;
        try {
            const res = await checkSimilarReserve({
                supplierId:  this._supplierId,
                scrapTypeId: this.selectedType,
                reserveDate: this.selectedDate,                // 'YYYY-MM-DD'
                truckId:     this.selectedTruckId,
                trailerId:   this.trailerRequired ? this.selectedTrailerId : null,
                fixedWeight: this.selectedWeightNorm           // рядок, напр. '20'
            });
            this.dupData = res || { exists:false, count:0, summaries:[], ids:[] };
            if (this.dupData.exists) {
                // показуємо модалку попередження і НЕ переходимо на крок водія
                this.dupModalOpen = true;
                return false;
            }
            return true; // ОК, дублів немає
        } catch (e) {
            // на помилку перевірки не валимо процес — просто попереджаємо
            this.toast('Перевірка дублікатів', e?.body?.message || e?.message || 'Не вдалося виконати перевірку', 'warning');
            return true;
        } finally {
            this.dupCheckInProgress = false;
        }
    };


    @track successShown = false;
    @track successInfo = {
        date: '',
        scrapType: '',
        truckModel: '',
        truckPlate: '',
        tonnage: '',
        driver: '',
        address: '',
        passNumber: '',
        passId: '',
        hasTrailer: false,     // ⬅️ нове
        trailer: ''
    };

    // Стан таблиці
    @track isLoadingGrid = false;
    @track dates = [];      // "dd.MM.yyyy" для шапки
    _daysIso = [];          // "YYYY-MM-DD" — порядок колонок
    @track tableRows = [];  // [{ scrapId, scrapName, cells:[{key,date,value,disabled,reason,tooltip}] }]

    // Для кліку/логів
    _typeMeta = {};   // { scrapTypeId: {code,name} }
    _cellByKey = {};  // { `${scrapId}|${iso}`: {limit,incoming,remaining,reason} }
    // Якщо supplierId приходить пізніше
    _didInit = false;
    renderedCallback() {
        if (!this._didInit && this._supplierId) {
            this._didInit = true;
            this.anchorIso = this._getTodayIso(); // ⬅️
            this.loadGrid();
        }
    }

    async loadGrid() {
        this.isLoadingGrid = true;
        this.tableRows = [];
        this._typeMeta = {};
        this._cellByKey = {};
        try {
            this._todayIso = this._getTodayIso(); // ⬅️ ДОДАЙ ОЦЕ

            console.log('this. ID: ' + this._supplierId);
            // const dto = await getDecadeGridForSupplier({ supplierId: this._supplierId });
            const dto = await getDecadeGridForSupplierAtDate({
                supplierId: this._supplierId,
                anchorDate: this.anchorIso          // ⬅️ якір
            });
            console.log('DTO: ' + JSON.stringify(dto,null,2));

            // 1) шапка
            this._daysIso = (dto?.days || []).map(String);
            this.dates = this._daysIso.map(this.formatDate);

            // 2) рядки з клітинками відразу з DTO
            this.tableRows = (dto?.rows || []).map(r => {
                const scrapId = r.scrapTypeId || r.code || r.name; // підстрахуємось
                this._typeMeta[scrapId] = { code: r.code, name: r.name };

                const byIso = new Map((r.cells || []).map(c => [String(c.dateValue), c]));

                const cells = this._daysIso.map(iso => {
                    const c = byIso.get(iso) || {};
                    const key = `${scrapId}|${iso}`;

                    // кеш для кліку/логів
                    this._cellByKey[key] = {
                        limit:     c.limitValue,
                        incoming:  c.incoming,
                        remaining: c.remaining,
                        reason:    c.reason
                    };
// TODO: ПОВЕРНУТИ НАЗАД ПІСЛЯ ТЕСТУВАННЯ
                    const dateLocked  = iso <= this._todayIso; // учора/сьогодні — заборонено
// TODO: відкрити резервування на сьогодні ->
                    // const dateLocked  = iso < this._todayIso; // учора/сьогодні — заборонено
                    const rawDisabled = !!c.disabled;          // бізнес-блок через ліміти

                    const rem         = Number(c.remaining ?? 0);
                    const belowMin    = rem < this.MIN_BOOK_TONNAGE;

                    let reason;
                    if (dateLocked)            reason = 'Недоступно: можна бронювати лише з завтрашнього дня';
                    else if (belowMin)         reason = `Недоступно: доступний залишок < ${this.MIN_BOOK_TONNAGE} т`;
                    else                       reason = c.reason || null;

                    return {
                        key,
                        date: iso,
                        value: this.formatNum(c.remaining),
                        dateLocked,
                        rawDisabled,
                        remainingValue: rem,
                        reason,               // ⬅️ використовуємо нашу reason
                        tooltip: reason,      // ⬅️ і тут теж
                        uiDisabled: dateLocked || (rawDisabled && !this.isOutOfLimit)
                    };
                });

                return {
                    scrapId,
                    // у першій колонці — код, якщо є, інакше назва
                    scrapName: r.code || r.name,
                    cells
                };
            });
            this._applyOutOfLimitToGrid();

            if (!this.tableRows.length) {
                this.toast('Немає даних', 'Для цього постачальника не знайдено доступних типів у поточній декаді.', 'warning');
            }
        } catch (e) {
            this.toast('Помилка', e?.body?.message || e?.message || 'Не вдалося завантажити дані', 'error');
        } finally {
            this.isLoadingGrid = false;
        }
    }

    goPrevDecade = async () => {
        if (!this.anchorIso) return;
        const prev = await getPrevDecadeAnchor({ anyDate: this.anchorIso });
        this.anchorIso = String(prev);
        this.loadGrid();
    };

    goNextDecade = async () => {
        if (!this.anchorIso) return;
        const next = await getNextDecadeAnchor({ anyDate: this.anchorIso });
        this.anchorIso = String(next);
        this.loadGrid();
    };

// (опц.) режим «місяць»
    toggleViewMode = async () => {
        this.viewMode = (this.viewMode === 'decade') ? 'month' : 'decade';
        // для місяця якір достатньо залишити на будь-який день місяця
        this.loadGrid();
    };


    // Клік по комірці — тільки лог
    handleSelectDate(event) {
        console.log('handleSelectDate');
        const scrapTypeId = event.target.dataset.type;
        const dateIso     = event.target.dataset.date;

        const row  = this.tableRows.find(r => r.scrapId === scrapTypeId);
        const cell = row?.cells?.find(x => x.date === dateIso);
        if (!cell || cell.uiDisabled) return;

        this.selectedType = scrapTypeId;              // Id типу
        const meta = this._typeMeta[scrapTypeId] || {};
        this.selectedScrapName = meta.name || '';     // повна назва (на випадок)
        this.selectedDate = dateIso;
        const key = `${scrapTypeId}|${dateIso}`;
        // const cell = this._cellByKey[key] || null;
        // this.dayRemaining = cell && cell.remaining != null ? Number(cell.remaining) : null;
        this.dayRemaining = cell && cell.remainingValue != null ? Number(cell.remainingValue) : null;

        this.recomputeAutoWeightNorm(); // пересчитаємо рекомендоване значення
        this.currentStep = 'vehicle';
        this.loadStaticForStep2();                    // ⬅️ тягнемо постачальника/договір
    }

    async loadStaticForStep2() {
        this.isLoadingStatic = true;
        try {
            console.log('supplierId: ' + this._supplierId);
            console.log('scrapTypeId: ' + this.selectedType);
            const dto = await getStep2StaticInfo({
                supplierId: this._supplierId,
                scrapTypeId: this.selectedType
            });
            console.log('DTO: ' + JSON.stringify(dto,null,));

            this.supplierName = dto?.supplierName || '';

            const c = dto?.contract;
            if (c) {
                const df = this.formatDateISO(c.dateFrom);
                const dt = c.dateTo ? this.formatDateISO(c.dateTo) : '—';

                this.contractInfo = {
                    id: c.id,
                    // contractNumber уже містить "Угода № …", не дублюємо префікс
                    label: `${c.contractNumber}${df ? ' від ' + df : ''}`,
                    number: c.contractNumber || '—',
                    dateFrom: c.dateFrom ? new Date(c.dateFrom) : null,
                    dateTo:   c.dateTo   ? new Date(c.dateTo)   : null,
                    dateFromHuman: df || '—',
                    dateToHuman: dt,
                    daysLeft: (c.willBeActiveDays ?? null) // ⬅️ беремо значення з формули, а не рахуємо самі
                };
            } else {
                // немає чинного договору
                this.contractInfo = {
                    id: null, label: '—', number: '—',
                    dateFrom: null, dateTo: null,
                    dateFromHuman: '—', dateToHuman: '—',
                    daysLeft: null
                };
                this.toast('Немає чинного договору', 'Для постачальника не знайдено активну підставу.', 'warning');
            }

            const lookups = await getStep2Lookups({ supplierId: this._supplierId });
            console.log('=======================lookups: ' + JSON.stringify(lookups,null,2));
// === МЕНЕДЖЕРИ ===
            this._allManagers = (lookups?.managers || []).map(m => ({
                id:   m.id,
                name: m.name,
                role: m.role,
                phone: m.phone
            }));
            this.contactSuggestions = [...this._allManagers];

            if (this._allManagers.length === 1) {
                const only = this._allManagers[0];
                this.selectedContactId = only.id;
                this.contactQuery = only.name;
                this.hasMultipleManagers = false;
                this.showContactSug = false;
            } else {
                this.selectedContactId = null;
                this.contactQuery = '';
                this.hasMultipleManagers = this._allManagers.length > 1;
                this.showContactSug = false;
            }

// === АДРЕСИ ===  (ЗАМІНИ твій блок map(...) на цей)
            this._allAddresses = (lookups?.addresses || []).map(a => {
                // display = "Label | Address, City"
                const left  = a.label || a.address || '';
                const right = [a.address, a.city].filter(Boolean).join(', ');
                const display = right ? `${left} | ${right}` : left || '—';
                return {
                    id: a.id,
                    label: a.label || '',     // залишаємо, якщо десь ще треба
                    address: a.address || '',
                    city: a.city || '',
                    country: a.country || '',
                    display
                };
            });
            this.addressSuggestions = [...this._allAddresses];

            if (this._allAddresses.length === 1) {
                const onlyA = this._allAddresses[0];
                this.selectedAddress = onlyA.id;
                this.addressQuery    = onlyA.display;
                this.hasMultipleAddresses = false;
                this.showAddressSug = false;
            } else {
                this.selectedAddress = '';
                this.addressQuery    = '';
                this.hasMultipleAddresses = this._allAddresses.length > 1;
                this.showAddressSug = false;
            }
        } catch (e) {
            this.toast('Помилка', e?.body?.message || e?.message || 'Не вдалося отримати дані постачальника', 'error');
        } finally {
            this.isLoadingStatic = false;
        }
    }

    formatDateISO(iso) {
        const [y,m,d] = String(iso).split('-').map(Number);
        if (!y || !m || !d) return '—';
        return `${String(d).padStart(2,'0')}.${String(m).padStart(2,'0')}.${y}`;
    }

    // Кнопка "Скасувати"
    closeModal = () => {
        this.dispatchEvent(new CustomEvent('close'));
    };

    // Утиліти
    toast(title, message, variant='success') {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant, mode: 'dismissable' }));
    }
    formatDate = (iso) => {
        const [y, m, d] = String(iso).split('-').map(n => parseInt(n, 10));
        if (!y || !m || !d) return iso;
        return `${String(d).padStart(2,'0')}.${String(m).padStart(2,'0')}.${y}`;
    };
    formatNum(n) {
        if (n == null) return '';
        const v = Number(n);
        return Number.isInteger(v) ? String(v) : v.toFixed(1);
    }

    // ==== СТАТИКА КРОКУ 2 ====
    @track isLoadingStatic = false;
    @track supplierName = '';

    get selectedScrapLabel() {
        // код із _typeMeta якщо є; інакше — що зберегли при кліку
        const meta = this._typeMeta?.[this.selectedType] || {};
        // показуємо код, якщо є; інакше повну назву
        return this.selectedScrapName ;
    }

    @track contractInfo = {
        id: null,
        label: '—',
        number: '—',
        dateFromHuman: '—',
        dateToHuman: null,
        daysLeft: null
    };

    @track viewMode = 'decade'; // 'decade' | 'month'
    @track anchorIso = null;    // 'YYYY-MM-DD' – якір поточної сторінки (1/11/21 або 1 число місяця)
    get headerTitle() {
        // для красивого підпису в шапці
        if (!this._daysIso || this._daysIso.length === 0) return 'Резервування слоту';
        const first = this._daysIso[0];
        const [y,m] = first.split('-').map(Number);
        const month = new Date(y, m-1, 1).toLocaleString('uk', { month:'long' });
        const d = Number(first.split('-')[2]);
        const decade = d<=10 ? '1-ша декада' : d<=20 ? '2-га декада' : '3-тя декада';
        return this.viewMode==='month' ? `Місяць: ${month} ${y}` : `${decade} • ${month} ${y}`;
    }

    // було відсутнє
    get isStepVehicle() {
        return this.currentStep === 'vehicle';
    }

    get contractDaysLeftText() {
        const d = this.contractInfo?.daysLeft;
        if (d == null) return 'Без дати завершення';
        if (d <= 0)    return 'Договір прострочено';
        if (d <= 30)   return `Закінчується через ${d} дн.`;
        return `Чинна ще ${d} дн.`;
    }
    get contractBadgeTheme() {
        const d = this.contractInfo?.daysLeft;
        if (d == null) return 'slds-badge slds-theme_info';
        if (d <= 0)    return 'slds-badge slds-theme_error';
        if (d <= 30)   return 'slds-badge slds-theme_warning';
        return 'slds-badge slds-theme_success';
    }

    @track hasMultipleManagers = false;
    @track hasMultipleAddresses = false;

// уже є в тебе:
    @track contactSuggestions = [];
    @track addressSuggestions = [];
    @track selectedContactId = null;
    @track selectedAddress = '';

// красиво показати єдиного:
    get singleManagerLine() {
        const o = (this.contactSuggestions && this.contactSuggestions[0]) || null;
        if (!o) return '—';
        let s = o.name || '';
        if (o.role)  s += `, ${o.role}`;
        if (o.phone) s += ` • ${o.phone}`;
        return s;
    }
    get singleAddressLine() {
        const a = (this.addressSuggestions && this.addressSuggestions[0]) || null;
        return a ? (a.display || a.label || a.address || '—') : '—';
    }


    // ==== СТАТИКА КРОКУ 2 ====
// ... твої існуючі @track isLoadingStatic, @track supplierName, contractInfo, hasMultiple* і т.д.

// ▼ ДОДАТИ ОЦЕ:
    @track showContactSug = false;
    @track showAddressSug = false;

    contactQuery = '';
    addressQuery = '';

    _allManagers = [];   // повний список менеджерів (для фільтрації)
    _allAddresses = [];  // повний список адрес (для фільтрації)

// форматуємо обрану дату з кроку 1 (бо в HTML використовується formattedSelectedDate)
    get formattedSelectedDate() {
        return this.selectedDate ? this.formatDate(this.selectedDate) : '—';
    }

// ===== ЛУКАП: МЕНЕДЖЕР =====
    openContactSug = () => {
        if (!this.hasMultipleManagers) return;
        this.showContactSug = true;
        // показуємо весь список, навіть якщо рядок порожній
        this.contactSuggestions = [...this._allManagers];
    };

    onContactInput = (e) => {
        this.contactQuery = e.target.value || '';
        const q = this.contactQuery.trim().toLowerCase();
        // простий фільтр по name/role/phone
        this.contactSuggestions = this._allManagers.filter(m => {
            const hay = `${m.name} ${m.role || ''} ${m.phone || ''}`.toLowerCase();
            return !q || hay.includes(q);
        });
        this.showContactSug = true;
        // якщо користувач редагує — скидати попередній вибір
        this.selectedContactId = null;
    };

    pickContact = (e) => {
        e.preventDefault();

        const { id, name } = e.currentTarget.dataset;
        this.selectedContactId = id;
        this.contactQuery = name;
        this.showContactSug = false;
        this.contactInvalid = false;
    };

// ===== ЛУКАП: АДРЕСА =====
    openAddressSug = () => {
        if (!this.hasMultipleAddresses) return;
        this.showAddressSug = true;
        this.addressSuggestions = [...this._allAddresses];
    };

    onAddressInput = (e) => {
        this.addressQuery = e.target.value || '';
        const q = this.addressQuery.trim().toLowerCase();
        this.addressSuggestions = this._allAddresses.filter(a => {
            const hay = `${a.display}`.toLowerCase();
            return !q || hay.includes(q);
        });
        this.showAddressSug = true;
        this.selectedAddress = '';
    };

    pickAddress = (e) => {
        e.preventDefault();

        const { id, display } = e.currentTarget.dataset;
        this.selectedAddress = id;
        this.addressQuery = display;
        this.showAddressSug = false;
        this.addressInvalid = false;

    };

    closeContactSug = () => {
        setTimeout(() => { this.showContactSug = false; }, 120);
    };
    closeAddressSug = () => {
        setTimeout(() => { this.showAddressSug = false; }, 120);
    };

    handleBackToDateStep = () => { this.currentStep = 'selectDate'; };
    handleNext = () => {
        // скинути старі помилки
        this.contactInvalid = false;
        this.addressInvalid = false;
        this.weightInvalid  = false;
        this.truckInvalid   = false;
        this.trailerInvalid = false;

        const missing = [];

        // Контакт обов'язковий лише якщо менеджерів кілька (тоді треба вибір)
        if (this.hasMultipleManagers && !this.selectedContactId) {
            this.contactInvalid = true;
            missing.push('контактну особу');
        }
        // Адреса — аналогічно
        if (this.hasMultipleAddresses && !this.selectedAddress) {
            this.addressInvalid = true;
            missing.push('адресу відвантаження');
        }
        // Норматив ваги
        if (!this.selectedWeightNorm) {
            this.weightInvalid = true;
            missing.push('норматив ваги');
        }
        // Тягач
        if (!this.selectedTruckId) {
            this.truckInvalid = true;
            missing.push('тягач');
        }
        // Причіп — якщо обов’язковий (тоннаж тягача = 0 або користувач увімкнув чекбокс)
        if (this.trailerRequired && !this.selectedTrailerId) {
            this.trailerInvalid = true;
            missing.push('причіп');
        }

        if (missing.length) {
            this.toast(
                'Заповніть поля',
                'Не заповнено: ' + missing.join(', ') + '.',
                'warning'
            );
            return; // не переходимо далі
        }

        // все ок
        this.runDuplicateCheck().then(ok => {
            if (ok) {
                this.currentStep = 'driver';
            }
        });
    };
    handlePrevious = () => { this.currentStep = 'vehicle'; };

    @track allWeightOptions = [];     // усі значення з пікліста (як {label, value})
    @track selectedWeightNorm = null; // вибране значення (рядок, напр. '20')

// денний залишок для обраної клітинки (з кроку 1)
    @track dayRemaining = null;

    @wire(getObjectInfo, { objectApiName: SCRAP_SLOT_RESERVE_OBJECT })
    objectInfo;

    @wire(getPicklistValues, {
        recordTypeId: '$objectInfo.data.defaultRecordTypeId',
        fieldApiName: FIXED_WEIGHT_FIELD
    })
    weightPicklist({ data, error }) {
        if (data) {
            // data.values: [{label:'10 т.', value:'10'}, ...]
            this.allWeightOptions = (data.values || []).map(v => ({ label: v.label, value: v.value }));
            this.recomputeAutoWeightNorm(); // коли підтягуються значення — одразу авто-вибір
        } else if (error) {
            // не обов’язково: можна показати toast
            // console.error('Picklist error', JSON.stringify(error));
        }
    }

    // максимальний допустимий норматив зараз обмежуємо тільки залишком на дату.
// (коли доробимо блок ТЗ — додамо min(місткість ТЗ, dayRemaining))
    get permissibleMax() {
        return this.dayRemaining != null ? Number(this.dayRemaining) : null;
    }

// опції з пікліста, які не перевищують permissibleMax
    get filteredWeightOptions() {
        if (this.isOutOfLimit) return this.allWeightOptions; // позапланове — без обмеження залишком
        const max = this.permissibleMax;
        if (max == null) return this.allWeightOptions;
        return this.allWeightOptions.filter(o => Number(o.value) <= max);
    }


// підказка під комбобоксом
    get weightHint() {
        if (this.isOutOfLimit) return 'Позапланове бронювання: обмеження добового залишку ігнорується';
        if (this.dayRemaining == null) return '';
        return `Доступний залишок на дату: ${this.dayRemaining} т`;
    }


// коли змінюються дата/залишок або при першому завантаженні пікліста — підставляємо найкраще значення
    recomputeAutoWeightNorm() {
        const opts = this.filteredWeightOptions;
        if (!opts || !opts.length) {
            this.selectedWeightNorm = null;
            return;
        }
        // якщо поточне значення ще валідне — лишаємо
        if (this.selectedWeightNorm && opts.some(o => o.value === this.selectedWeightNorm)) return;
        // інакше ставимо найбільше доступне (останній елемент після фільтру)
        this.selectedWeightNorm = opts[opts.length - 1].value;
    }

// onChange від комбобокса
    handleWeightNormChange = (e) => {
        this.selectedWeightNorm = e.detail.value;
        this.weightInvalid = false;
    };

    get noWeightOptions() {
        return (this.filteredWeightOptions || []).length === 0;
    }

    // ▼ ТЯГАЧ
    @track vehicleQuery = '';
    @track showVehicleList = false;
    @track vehicleOptions = []; // [{Id, Name, Model, Tonnage, Type, display}]
    @track selectedTruckId = null;
    @track selectedTruckName = '';
    @track selectedTruckTonnage = null;

// ▼ ПРИЧІП
    @track trailerQuery = '';
    @track showTrailerList = false;
    @track trailerOptions = [];
    @track selectedTrailerId = null;
    @track selectedTrailerName = '';
    @track selectedTrailerTonnage = null;

// ▼ Правило: якщо тоннаж тягача = 0 -> причіп обов’язковий і чекбокс блокуємо
    @track trailerRequired = false; // у тебе вже було — залишаємо, але тепер керуємо ним тут
    @track trailerLock = false;     // коли true — чекбокс “Потрібен причіп?” disabled

// проста “затримка” для debounce
    _debounce;
    async loadTrucks(kind, query = '') {
        // kind: 'Truck' або 'Trailer'
        const res = await searchTrucks({
            supplierId: this._supplierId,
            query,
            type: kind,
            limitSize: 20
        });
        // Переформатуємо у вигляд для списку
        return (res || []).map(t => ({
            Id: t.id,
            Name: t.name,
            Model: t.model,
            Tonnage: t.tonnage,
            Type: t.type,
            display: `${t.model || ''} | ${t.name} • ${t.tonnage ?? 0} т`.trim()
        }));
    }

    onVehicleFocus = async () => {
        this.showVehicleList = true;
        this.vehicleOptions = await this.loadTrucks('Truck', '');
    };

    onVehicleInput = (e) => {
        this.vehicleQuery = e.target.value || '';
        clearTimeout(this._debounce);
        this._debounce = setTimeout(async () => {
            this.vehicleOptions = await this.loadTrucks('Truck', this.vehicleQuery);
            this.showVehicleList = true;
        }, 250);
    };

    onVehiclePick = (e) => {
        e.preventDefault(); // не даємо інпуту втратити фокус до вибору

        const id = e.currentTarget.dataset.id;
        const picked = this.vehicleOptions.find(v => v.Id === id);
        if (!picked) return;

        this.selectedTruckId = picked.Id;
        this.selectedTruckName = picked.Name;
        this.selectedTruckTonnage = Number(picked.Tonnage) || 0;

        this.vehicleQuery = picked.display;
        this.showVehicleList = false;
        this.truckInvalid = false;


        // правило: якщо тоннаж тягача = 0 — причіп обов’язковий і чекбокс блокуємо
        this.trailerLock = (this.selectedTruckTonnage === 0);
        if (this.trailerLock) this.trailerRequired = true;
        // якщо тягач має >0 — залишаємо ручний контроль користувачу
    };

    contactFocusOut = (e) => { const r=e.currentTarget,n=e.relatedTarget; if(n&&r.contains(n)) return; setTimeout(()=>{ this.showContactSug=false; },80); };
    addressFocusOut = (e) => { const r=e.currentTarget,n=e.relatedTarget; if(n&&r.contains(n)) return; setTimeout(()=>{ this.showAddressSug=false; },80); };
    trailerFocusOut = (e) => { const r=e.currentTarget,n=e.relatedTarget; if(n&&r.contains(n)) return; setTimeout(()=>{ this.showTrailerList=false; },80); };
    driverFocusOut  = (e) => { const r=e.currentTarget,n=e.relatedTarget; if(n&&r.contains(n)) return; setTimeout(()=>{ this.showDriverList=false; },80); };


    onTrailerFocus = async () => {
        if (!this.selectedTruckId) {
            this.toast('Спочатку оберіть тягач', 'Причіп не може існувати без тягача.', 'warning');
            return;
        }
        this.showTrailerList = true;
        this.trailerOptions = await this.loadTrucks('Trailer', '');
    };

    onTrailerInput = (e) => {
        if (!this.selectedTruckId) return;
        this.trailerQuery = e.target.value || '';
        clearTimeout(this._debounce);
        this._debounce = setTimeout(async () => {
            this.trailerOptions = await this.loadTrucks('Trailer', this.trailerQuery);
            this.showTrailerList = true;
        }, 250);
    };

    onTrailerPick = (e) => {
        e.preventDefault();

        const id = e.currentTarget.dataset.id;
        const picked = this.trailerOptions.find(v => v.Id === id);
        if (!picked) return;

        this.selectedTrailerId = picked.Id;
        this.selectedTrailerName = picked.Name;
        this.selectedTrailerTonnage = Number(picked.Tonnage) || 0;

        this.trailerQuery = picked.display;
        this.showTrailerList = false;
        this.trailerInvalid = false;

    };

    handleTrailerToggle = (e) => {
        if (this.trailerLock) {
            this.trailerRequired = true;
            return;
        }
        this.trailerRequired = e.target.checked;
        if (!this.trailerRequired) this.trailerInvalid = false;

        if (!this.trailerRequired) {
            this.selectedTrailerId = null;
            this.selectedTrailerName = '';
            this.selectedTrailerTonnage = null;
            this.trailerQuery = '';
            this.showTrailerList = false;
        }
    };

    closeVehicleList = () => { setTimeout(() => { this.showVehicleList = false; }, 120); };
    closeTrailerList = () => { setTimeout(() => { this.showTrailerList = false; }, 120); };


    get disableNextFromStatic() {
        const contactOk  = !!this.selectedContactId || !this.hasMultipleManagers;
        const addressOk  = !!this.selectedAddress  || !this.hasMultipleAddresses;
        const contractOk = !!this.contractInfo?.id || true;
        const normOk     = !!this.selectedWeightNorm;

        // нове: без тягача не рухаємось далі
        const truckOk    = !!this.selectedTruckId;

        // причіп обов'язковий лише якщо у lock або користувач увімкнув чекбокс
        const trailerOk  = !this.trailerRequired || !!this.selectedTrailerId;

        return !(contactOk && addressOk && contractOk && normOk && truckOk && trailerOk);
    }


    get isStepDriver() {
        return this.currentStep === 'driver';
    }

    get noTruckSelected() {
        // немає вибраного тягача
        return !this.selectedTruckId;
    }

    get needTrailerButMissing() {
        // обраний тягач із тоннажем 0 і ще не обраний причіп
        return !!this.selectedTruckId
            && Number(this.selectedTruckTonnage) === 0
            && !this.selectedTrailerId;
    }

    @track contactInvalid = false;
    @track addressInvalid = false;
    @track weightInvalid  = false;
    @track truckInvalid   = false;
    @track trailerInvalid = false;

// ▼ ВОДІЙ
    @track driverQuery = '';
    @track showDriverList = false;
    @track driverOptions = []; // [{Id, Name, Phone, display}]
    @track selectedDriverId = null;
    @track driverInvalid = false;

    // DRIVERS
    async loadDrivers(query = '') {
        const res = await searchDrivers({
            supplierId: this._supplierId,
            query,
            limitSize: 20
        });
        return (res || []).map(d => ({
            Id: d.id,
            Name: d.name,
            Phone: d.phone,
            display: `${d.name}${d.phone ? ' | ' + d.phone : ''}`
        }));
    }

    onDriverFocus = async () => {
        const list = await this.loadDrivers('');   // повний список для постачальника
        this.driverOptions = list;
        this.showDriverList = list.length > 0;
        this.noDriversForSupplier = list.length === 0; // якщо порожньо — показуємо інфоблок
    };


    onDriverInput = (e) => {
        this.driverQuery = e.target.value || '';
        clearTimeout(this._debounce);
        this._debounce = setTimeout(async () => {
            const list = await this.loadDrivers(this.driverQuery);
            this.driverOptions = list;
            this.showDriverList = list.length > 0;
            // noDriversForSupplier тут не змінюємо — він про “взагалі немає водіїв у постачальника”
        }, 250);
    };


    onDriverPick = (e) => {
        e.preventDefault();

        const id = e.currentTarget.dataset.id;
        const picked = this.driverOptions.find(d => d.Id === id);
        if (!picked) return;
        this.selectedDriverId = picked.Id;
        this.driverQuery = picked.display;
        this.showDriverList = false;
        this.driverInvalid = false;
    };


    handleSubmit = async () => {
        // 0) Мінімальна перевірка водія (решта валідована раніше)
        if (!this.selectedDriverId) {
            this.driverInvalid = true;
            this.toast('Заповніть поля', 'Не заповнено: водій.', 'warning');
            return;
        }
        if (this.isSending) return;

        this.isSending = true;
        try {
            const input = {
                supplierId:       this._supplierId,
                scrapTypeId:      this.selectedType,
                reserveDate:      this.selectedDate,            // 'YYYY-MM-DD'
                fixedWeight:      this.selectedWeightNorm,      // '10'|'20'|'25'
                shippingPointId:  this.selectedAddress || null,
                supplierPersonId: this.selectedContactId || null,
                truckId:          this.selectedTruckId,
                trailerId:        this.trailerRequired ? this.selectedTrailerId : null,
                driverId:         this.selectedDriverId,
                contractId:       this.contractInfo?.id || null,
                isOutOfLimit:     this.isOutOfLimit,
                forceCreate:      this._forceCreate
            };
            console.log('INPUT: ' + JSON.stringify(input, null, 2));

            const createRes = await createReserve({ input });
            const reserveId = createRes?.id;
            console.log('reserveId: ' + reserveId);

            if (!reserveId) {
                throw new Error('Не отримали Id створеного резерву (reserveId).');
            }

            if (this.isOutOfLimit) {
                this.toast(
                    'Заявку створено',
                    'Позаплановий слот створено. Статус: Requested. Заявка відправлена на розгляд адміністратору.',
                    'success'
                );

                this.requestedInfo = {
                    date: this.formattedSelectedDate,
                    scrapType: this.selectedScrapName || '',
                    tonnage: this.selectedWeightNorm || '',
                    truck: this.vehicleQuery || '',
                    trailer: this.selectedTrailerId
                        ? (this.trailerQuery || `${this.selectedTrailerName}${this.selectedTrailerTonnage ? ' • ' + this.selectedTrailerTonnage + ' т' : ''}`)
                        : '—',
                    driver: this.driverQuery || '',
                    address: this.singleAddressLine || ''
                };
                this.showRequestedInfo = true;  // 🔔 показуємо новий інфо-блок
                this.successShown = false;      // (на випадок, якщо десь лишилось true)

                // оновити списки у батьківському
                this.dispatchEvent(new CustomEvent('slotcreated', {
                    detail: reserveId, bubbles: true, composed: true
                }));

                this.isSending = false;
                return; // ⛔️ жодних викликів ERP
            }


            this.toast('Заявку створено', 'Резерв збережено. Формуємо перепустку...', 'success');

            // 2) ЧЕКАЄМО відповідь ERP (await)
            console.log('Викликаємо sendReserveToErp для:', reserveId);
            const erp = await sendReserveToErp({ reserveId });

            // 3) Логуємо ВСЮ відповідь ERP у консоль
            console.log('ERP RESULT JSON:', JSON.stringify(erp, null, 2));
            console.log('ERP success:', erp?.success);
            console.log('ERP passNumber:', erp?.passNumber, 'passId:', erp?.passId);
            if (erp?.itemErrors && erp.itemErrors.length) {
                console.warn('ERP itemErrors:', erp.itemErrors);
            }

            if (erp?.success) {
                try {
                    await markReserveApproved({
                        reserveId,
                        passNumber: erp?.passNumber || null,
                        passId: erp?.passId || null
                    });
                    console.log('Статус слота оновлено на Approved.');

                    // (опційно) ще раз підкажемо батькові оновитись
                    this.dispatchEvent(new CustomEvent('slotupdated', {
                        detail: { id: reserveId, status: 'Approved', passNumber: erp?.passNumber },
                        bubbles: true, composed: true
                    }));

                    this.toast('ERP', 'Перепустку створено в ERP. Статус: Approved', 'success');
                } catch (updErr) {
                    console.warn('Не вдалося оновити статус на Approved:', updErr);
                    this.toast('Попередження', 'ERP успішний, але не вдалося оновити статус у Salesforce', 'warning');
                }
            } else {
                this.toast('ERP', 'ERP повернув помилку. Перевірте консоль.', 'warning');
            }

            // Сповістимо батьківський компонент (якщо слухає)
            this.dispatchEvent(new CustomEvent('slotcreated', {
                detail: reserveId,
                bubbles: true,
                composed: true
            }));
            // (за бажанням) можна ще:
            // console.log('ERP requestBody:', erp?.requestBody);
            // console.log('ERP rawResponse:', erp?.rawResponse);

            // 4) Показати “успіх” у панелі (вже є розмітка)
            this.successInfo = {
                date: this.formattedSelectedDate,
                scrapType: this.selectedScrapName || '',
                truckModel: this.vehicleQuery || '',
                truckPlate: '',
                tonnage: this.selectedWeightNorm || '',
                driver: this.driverQuery || '',
                address: this.singleAddressLine || '',
                passNumber: erp?.passNumber || '—',
                passId: erp?.passId || '—',
                hasTrailer: !!this.selectedTrailerId,
                trailer: this.selectedTrailerId
                    ? (this.trailerQuery || `${this.selectedTrailerName}${this.selectedTrailerTonnage ? ' • ' + this.selectedTrailerTonnage + ' т' : ''}`)
                    : ''
            };
            this.successShown = true;

        } catch (e) {
            const msg = e?.body?.message || e?.message || 'Помилка під час створення/відправки';
            this.toast('Помилка', msg, 'error');
            console.error('handleSubmit error:', e);
            this.closeModal();
        } finally {
            this.isSending = false;
        }
    };

// ADD inside class ReserveSlotModal
    confirmDuplicateCreate = () => {
        this._forceCreate = true;     // дозволяємо створення попри дубль
        this.dupModalOpen = false;
        this.toast('Підтверджено', 'Створення слоту буде дозволено попри існуючу заявку.', 'success');
        // далі користувач переходить на крок водія і завершить створення як звично
        this.currentStep = 'driver';
    };

    cancelDuplicateCreate = () => {
        this._forceCreate = false;
        this.dupModalOpen = false;
        // лишаємось на кроці транспорту, щоби користувач міг змінити дані
    };


    get disableSubmit() {
        return !this.selectedDriverId;
    }

    get isSubmitDisabled() {
        return this.isSending || this.disableSubmit;
    }

    hideDriverListDelayed = () => { setTimeout(() => { this.showDriverList = false; }, 120); };
    @track noDriversForSupplier = false;

    // ▼ додай десь на початку класу
    _todayIso = null;
    _getTodayIso() {
        const d = new Date();
        const yyyy = d.getFullYear();
        const mm = String(d.getMonth()+1).padStart(2,'0');
        const dd = String(d.getDate()).padStart(2,'0');
        return `${yyyy}-${mm}-${dd}`; // 'YYYY-MM-DD'
    }

// застосувати поточне isOutOfLimit до вже побудованої таблиці
    _applyOutOfLimitToGrid() {
        if (!this.tableRows || !this.tableRows.length) return;
        this.tableRows = this.tableRows.map(row => ({
            ...row,
            cells: row.cells.map(c => ({
                ...c,
                uiDisabled: c.dateLocked || (!this.isOutOfLimit && (c.rawDisabled || (c.remainingValue ?? 0) < this.MIN_BOOK_TONNAGE))
            }))
        }));
    }

    @track showRequestedInfo = false;
    @track requestedInfo = {
        date: '',
        scrapType: '',
        tonnage: '',
        truck: '',
        trailer: '',
        driver: '',
        address: ''
    };

    vehicleFocusOut = (e) => {
        // якщо фокус лишився в межах .lookup — не закриваємо
        const root = e.currentTarget;
        const next = e.relatedTarget;
        if (next && root.contains(next)) return;

        // невелика затримка — про всяк випадок для мобільних
        setTimeout(() => { this.showVehicleList = false; }, 100);
    };

// (опційно зроби аналогічно для трейлера/водія,
// якщо теж інколи зривається вибір)
//     trailerFocusOut = (e) => {
//         const root = e.currentTarget;
//         const next = e.relatedTarget;
//         if (next && root.contains(next)) return;
//         setTimeout(() => { this.showTrailerList = false; }, 100);
//     };
//     driverFocusOut = (e) => {
//         const root = e.currentTarget;
//         const next = e.relatedTarget;
//         if (next && root.contains(next)) return;
//         setTimeout(() => { this.showDriverList = false; }, 100);
//     };


}