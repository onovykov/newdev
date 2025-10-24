import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import USER_ID from '@salesforce/user/Id';
import getMyAccountId from '@salesforce/apex/ScrapPassDirectController.getMyAccountId'
import getSupplierPrereqs from '@salesforce/apex/ScrapSupplierPortalController.getSupplierPrereqs';

import listSupplierActiveSlotsThisAndNext from '@salesforce/apex/ScrapSupplierPortalController.listSupplierActiveSlotsThisAndNext';
import listSupplierHistorySlotsBeforeToday from '@salesforce/apex/ScrapSupplierPortalController.listSupplierHistorySlotsBeforeToday';
import listThisAndNextBalances from '@salesforce/apex/ScrapSupplierPortalController.listThisAndNextBalances';

import LightningConfirm from 'lightning/confirm';
import cancelSupplierSlot from '@salesforce/apex/ScrapSupplierPortalController.cancelSupplierSlot';


export default class ScrapSupplierOperations extends LightningElement {
    supplierName = 'ТОВ ТВК ЕРКОНТРЕЙД ';
    MIN_BOOK_TONNAGE = 10;

    _getTodayIso() {
        const d = new Date();
        const yyyy = d.getFullYear();
        const mm = String(d.getMonth()+1).padStart(2,'0');
        const dd = String(d.getDate()).padStart(2,'0');
        return `${yyyy}-${mm}-${dd}`;
    }

    @track hasShippingPoint = false;
    @track hasDriver = false;
    @track hasTruck = false;

    @track noActionsTitle = '';
    @track noActionsText  = '';

    get showPrereqInfo() {
        return !(this.hasShippingPoint && this.hasDriver && this.hasTruck);
    }
    get missingPrereqList() {
        const miss = [];
        if (!this.hasShippingPoint) miss.push('Місце завантаження');
        if (!this.hasDriver)        miss.push('Водій');
        if (!this.hasTruck)         miss.push('Транспортний засіб');
        return miss.join(', ');
    }

    _setNoActions(title, text){
        this.noActionsTitle = title;
        this.noActionsText  = text;
    }
    _clearNoActions(){
        this.noActionsTitle = '';
        this.noActionsText  = '';
    }

    @track showReserveBtn = false;
    @track showOutOfLimitBtn = false;
    @track showReserveModal = false;
    outOfLimitMode = false;

    async refreshActionButtons() {
        if (!this.currentAccountId) return;

        try {
            this._clearNoActions();

            // (A) Перевірка довідників постачальника
            const prereq = await getSupplierPrereqs({ supplierId: this.currentAccountId });
            this.hasShippingPoint = !!prereq?.hasShippingPoint;
            this.hasDriver        = !!prereq?.hasDriver;
            this.hasTruck         = !!prereq?.hasTruck;

            console.log('this.hasShippingPoint: ' + this.hasShippingPoint)
            console.log('this.hasDriver: ' + this.hasDriver)
            console.log('this.hasTruck: ' + this.hasTruck)

            if (this.showPrereqInfo) {
                this.showReserveBtn    = false;
                this.showOutOfLimitBtn = false;

                const miss = [];
                if (!this.hasShippingPoint) miss.push('Місце завантаження');
                if (!this.hasDriver)        miss.push('Водій');
                if (!this.hasTruck)         miss.push('Транспортний засіб');

                this._setNoActions(
                    'Бронювання недоступне',
                    `Заповніть довідники постачальника: ${miss.join(', ')}. Після цього бронювання стане доступним.`
                );
                return;
            }

            // (B) Перевірка лімітів/залишку (як у тебе було)
            const balances = await listThisAndNextBalances({ supplierId: this.currentAccountId });
            const now = new Date();
            const y = now.getFullYear();
            const m = now.getMonth() + 1;

            const thisMonth = (balances || []).find(b => Number(b?.yearNum) === y && Number(b?.monthNum) === m);

            const hasApprovedPlan =
                !!thisMonth &&
                (
                    Number(thisMonth.limitTotal || 0) > 0 ||
                    (thisMonth.decades || []).some(d => Number(d.approvedLimit || 0) > 0)
                );

            if (!hasApprovedPlan) {
                this.showReserveBtn    = false;
                this.showOutOfLimitBtn = false;

                this._setNoActions(
                    'Бронювання недоступне',
                    'Немає погоджених лімітів на поточний місяць. Зверніться до адміністратора або дочекайтесь підтвердження.'
                );
                return;
            }

            this.showOutOfLimitBtn = true;

            const decNum = this._currentDecadeNum();
            const curDec = (thisMonth.decades || []).find(d => Number(d.decadeNum) === decNum);
            const remaining = curDec ? Number(curDec.remaining || 0) : 0;

            this.showReserveBtn = remaining >= this.MIN_BOOK_TONNAGE;

            this._clearNoActions();

        } catch (e) {
            console.warn('refreshActionButtons error', e);
            this.showReserveBtn = false;
            this.showOutOfLimitBtn = false;

            // запасний текст на випадок помилки
            this._setNoActions(
                'Бронювання тимчасово недоступне',
                'Сталася помилка при перевірці умов. Спробуйте ще раз або зверніться до адміністратора.'
            );
        }
    }


    // Метадані статусів
    STATUS_META = {
        issued:     { short: 'Видано',     cls: 'status-pill status-issued',  placeholder: 'Видано перепустку' },
        pending:    { short: 'Очікує',     cls: 'status-pill status-pending', placeholder: 'Очікує підтвердження змін адміністратором' },
        canceled:   { short: 'Скасовано',  cls: 'status-pill status-canceled', placeholder: '' },
        completed:  { short: 'Завершено',  cls: 'status-pill status-issued',  placeholder: 'Візит завершено' } // опційно
    };

    @track historyGroups = [];
    get hasHistory(){ return (this.historyGroups?.length || 0) > 0; }
    monthNamesUkr = ['Січень','Лютий','Березень','Квітень','Травень','Червень','Липень','Серпень','Вересень','Жовтень','Листопад','Грудень'];
    _monthLabel(y, m){ return `${this.monthNamesUkr[m-1]} ${y}`; }
    _groupHistory(rows){
        const buckets = {};
        (rows || []).forEach(r => {
            const iso = r?.visitDate;            // очікуємо 'YYYY-MM-DD' з Apex
            if (!iso) return;
            const [yS, mS] = String(iso).split('-');
            const y = Number(yS), m = Number(mS);
            const key = `${y}-${String(m).padStart(2,'0')}`;
            if (!buckets[key]) buckets[key] = { key, y, m, label: this._monthLabel(y, m), items: [] };
            buckets[key].items.push( this._decorate(this._mapSlotToOrder(r)) );
        });
        // новіші місяці зверху
        return Object.values(buckets).sort((a,b) => (b.y - a.y) || (b.m - a.m));
    }

    // this._mapSlotToOrder is not a function

    @track orders = [];
    currentAccountId;

    @track ordersLoaded = false;

    get hasOrders() {
        return (this.orders || []).length > 0;
    }
    get showEmptyOrdersPanel() {
        return this.ordersLoaded && !this.hasOrders;
    }

    connectedCallback() {
        getMyAccountId()
            .then(accId => {
                this.currentAccountId = accId;
                return Promise.all([
                    listSupplierActiveSlotsThisAndNext({ supplierId: accId }),
                    listSupplierHistorySlotsBeforeToday({ supplierId: accId, monthsBack: 6 })
                ]);
            })
            .then(([activeRows, historyRows]) => {
                console.log('activeRows[0] =', JSON.stringify(activeRows?.[0]));

                // АКТУАЛЬНІ = тільки Approved/Requested
                const active = (activeRows || [])
                    .map(r => this._mapSlotToOrder(r))
                    .filter(o => o.status === 'issued' || o.status === 'pending')
                    .map(o => this._decorate(o));
                this.orders = active;

                // ІСТОРІЯ = Completed / Canceled, з групуванням по місяцях
                this.historyGroups = this._groupHistory(historyRows || []);

                console.log(`[Orders] active: ${active.length}, history: ${(historyRows || []).length}`);
                return this.refreshActionButtons();   // ⬅️ додали
            })
            .catch(error => {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Помилка',
                    message: error?.body?.message || error?.message,
                    variant: 'error'
                }));
            })
            .finally(() => {
                this.ordersLoaded = true;
            });
    }

    _mapSlotToOrder(r) {
        const date = r?.visitDate ? this._formatDateDMY(r.visitDate) : '';

        const normalizedStatus =
            r?.status === 'Approved'                                  ? 'issued'    :
                r?.status === 'Requested'                                 ? 'pending'   :
                    r?.status === 'Completed'                                 ? 'completed' :
                        (r?.status === 'Canceled' || r?.status === 'Cancelled')   ? 'canceled'  :
                            'pending';

        const trailerPlate = (r?.trailerPlate || '').trim();

        return {
            id:         r?.id,
            date,
            scrapType:  r?.scrapTypeCode || '—',
            truckModel: r?.truckModel    || '—',
            truckPlate: r?.truckPlate    || '',
            tonnage:    r?.tonnage,
            driver:     r?.driverName    || '—',
            driverPhone:r?.driverPhone   || '',
            address:    r?.address       || '—',
            passNumber: r?.passNumber    || null,
            hasTrailer: r?.hasTrailer ?? (trailerPlate.length > 0),
            trailerPlate,
            status:     normalizedStatus
        };

    }


    async handleAskDelete(e) {
        const id = e.currentTarget?.dataset?.id;
        if (!id) return;

        const ok = await LightningConfirm.open({
            message: 'Скасувати це замовлення? Дію не можна буде скасувати.',
            label: 'Підтвердження',
            theme: 'warning'
        });
        if (!ok) return;

        this.isSaving = true;
        try {
            console.log('SLOT: ID ' + id)
            await cancelSupplierSlot({ slotId: id });

            // Прибираємо зі списку “Актуальні”
            this.orders = (this.orders || []).filter(o => o.id !== id);

            this.dispatchEvent(new ShowToastEvent({
                title: 'Скасовано',
                message: 'Замовлення позначено як скасоване.',
                variant: 'success'
            }));
        } catch (e) {
            console.log('ПОМИЛКА: ' + JSON.stringify(e));
            this.dispatchEvent(new ShowToastEvent({
                title: 'Помилка',
                message: e?.body?.message || e?.message || 'Не вдалося скасувати замовлення',
                variant: 'error',
                mode: 'sticky'
            }));
        } finally {
            this.isSaving = false;
        }
    }


    _formatDateDMY(iso) {
        // 'yyyy-MM-dd' -> 'dd.MM.yyyy'
        try {
            const [y, m, d] = iso.split('-').map(v => Number(v));
            const dd = String(d).padStart(2, '0');
            const mm = String(m).padStart(2, '0');
            return `${dd}.${mm}.${y}`;
        } catch (e) {
            return iso || '';
        }
    }

    _fmtDate(d) {
        if (!d) return '';
        const dt = new Date(d); // Apex Date -> JS Date
        const dd = String(dt.getDate()).padStart(2,'0');
        const mm = String(dt.getMonth()+1).padStart(2,'0');
        const yyyy = dt.getFullYear();
        return `${dd}.${mm}.${yyyy}`;
    }


    _decorate(o) {
        let st = o.status;
        if (!st) {
            if (o.canceled) st = 'canceled';
            else if (o.passNumber) st = 'issued';
            else st = 'pending';
        }

        const meta = this.STATUS_META[st] || this.STATUS_META.pending;

        return {
            ...o,
            status: st,
            statusShort: meta.short,
            statusClass: meta.cls,
            statusPlaceholder: meta.placeholder,
            rowClass: st === 'canceled' ? 'is-canceled' : '',
            canEdit: !(st === 'canceled' || st === 'pending'), // ❌ сховали для "Очікує"є
            canCancel: st !== 'canceled'   // ⬅️ додано

        };
    }

    // Резерв слоту
    openReserveModal() {
        this.outOfLimitMode = false;      // звичайний режим
        this.showReserveModal = true;
    }

    openOutOfLimitModal() {
        this.outOfLimitMode = true;       // позаплановий
        this.showReserveModal = true;
    }

    closeReserveModal() { this.showReserveModal = false; }

    // Модал редагування пропуска
    @track showEditPass = false;
    @track selectedOrder = null;
    @track isSaving = false;

    availableDrivers = [
        { id:'d1', name:'Іванов Іван Олександрович', phone:'+380 67 111 22 33' },
        { id:'d2', name:'Петренко Сергій Миколайович', phone:'+380 67 222 33 44' },
        { id:'d3', name:'Коваль Василь Ігорович',      phone:'+380 67 333 44 55' },
        { id:'d4', name:'Мельник Дмитро Анатолійович',  phone:'+380 67 444 55 66' },
        { id:'d5', name:'Соколенко Артем Вікторович',  phone:'+380 12 34 45 67' }
    ];
    availableTrucks = [
        { id:'t1', model:'DAF XF 105',  capacity:25 },
        { id:'t2', model:'Volvo FH 460', capacity:20 },
        { id:'t3', model:'MAN TGX',      capacity:10 },
        { id:'t4', model:'Scania R450',  capacity:20 }
    ];

    handleEditPass(event) {
        const id = event.currentTarget.dataset.id;
        const ord = this.orders.find(o => o.id === id);
        if (!ord || !ord.canEdit) return;
        this.selectedOrder = ord;
        this.showEditPass  = true;
    }
    handleEditPassClose() {
        if (this.isSaving) return;
        this.showEditPass = false;
        this.selectedOrder = null;
    }

    async handleEditPassSave(event) {
        const d = event.detail; // з модалки
        this.isSaving = true;
        try {
            // TODO: Apex-збереження
            await new Promise(r => setTimeout(r, 800));

            this.orders = this.orders.map(o => {
                if (o.id !== d.orderId) return o;

                const cap = (typeof d.truckCapacity === 'number' && Number.isFinite(d.truckCapacity)) ? d.truckCapacity : null;

                const updated = {
                    ...o,
                    driver:       d.driverName    ?? o.driver,
                    driverPhone:  d.driverPhone   ?? o.driverPhone,
                    truck:        d.truckModel    ?? o.truck,          // ← тепер точно підміниться
                    tonnage:      cap ?? o.tonnage,                    // 10/20/25 або лишаємо як було
                    truckPlate:   d.truckPlate    ?? o.truckPlate,
                    hasTrailer:   (typeof d.hasTrailer === 'boolean') ? d.hasTrailer : o.hasTrailer,
                    trailerPlate: (typeof d.hasTrailer === 'boolean' && !d.hasTrailer) ? '' : (d.trailerPlate ?? o.trailerPlate),
                    truckModel: d.truckModel ?? o.truckModel,
                    status: 'pending',
                    passNumber: null
                };

                return this._decorate(updated);
            });

            this.dispatchEvent(new ShowToastEvent({
                title: 'Надіслано на погодження',
                message: 'Зміни передано адміністратору. Статус: «Очікує», перепустку скинуто.',
                variant: 'success',
                mode: 'dismissable'
            }));

            this.showEditPass  = false;
            this.selectedOrder = null;
        } catch (e) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Помилка',
                message: 'Не вдалося надіслати зміни на погодження',
                variant: 'error',
                mode: 'sticky'
            }));
        } finally {
            this.isSaving = false;
        }
    }



    handleNewDriver(event) {
        const rec = event.detail; // {id,name,phone}
        this.availableDrivers = [...this.availableDrivers, rec];
    }
    handleNewTruck(event) {
        const rec = event.detail; // {id,model,capacity}
        this.availableTrucks = [...this.availableTrucks, rec];
    }

    // Скасування з модалки
    async handleCancelFromModal(event) {
        const id  = event.detail?.orderId;
        const ord = this.orders.find(o => o.id === id);
        if (!id || !ord) return;

        this.isSaving = true;
        try {
            // TODO: Apex-скасування
            await new Promise(r => setTimeout(r, 800));

            this.orders = this.orders.map(o => (
                o.id === id ? this._decorate({ ...o, status: 'canceled', passNumber: null }) : o
            ));

            this.dispatchEvent(new ShowToastEvent({
                title: 'Замовлення скасовано',
                message: `Замовлення ${ord.date} скасовано.`,
                variant: 'success'
            }));

            this.showEditPass  = false;
            this.selectedOrder = null;
        } catch (e) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Помилка',
                message: 'Не вдалося скасувати замовлення: ' + JSON.stringify(e),
                variant: 'error',
                mode: 'sticky'
            }));
        } finally {
            this.isSaving = false;
        }
    }

    // ScrapSupplierOperations.js — додай методи:

    _mapStatus(s, passNumber) {
        const map = { Approved:'issued', Requested:'pending', Completed:'completed' }; // опційно
        if (map[s]) return map[s];
        if (['issued','pending','canceled','completed'].includes(s)) return s;
        const m = { 'Видано':'issued', 'Очікує':'pending', 'Скасовано':'canceled', 'Завершено':'completed' };
        return m[s] || (passNumber ? 'issued' : 'pending');
    }

    _parseDate(d) { // 'dd.MM.yyyy' -> Date
        if (!d) return null;
        const [dd, mm, yyyy] = d.split('.');
        return new Date(Number(yyyy), Number(mm)-1, Number(dd));
    }

    _upsertOrder(newOrdRaw) {
        // нормалізуємо поля під твою схему
        const o = {
            id:         newOrdRaw.id,
            date:       newOrdRaw.date,
            scrapType:  newOrdRaw.scrapType,
            truckModel: newOrdRaw.truckModel || newOrdRaw.truck || '—',
            truckPlate: newOrdRaw.truckPlate || newOrdRaw.plate || '',
            tonnage:    newOrdRaw.tonnage,
            driver:     newOrdRaw.driver,
            address:    newOrdRaw.address,
            passNumber: newOrdRaw.passNumber || null,
            status:     this._mapStatus(newOrdRaw.status, newOrdRaw.passNumber)
        };

        // upsert у this.orders
        const idx = this.orders.findIndex(x => x.id === o.id);
        const decorated = this._decorate(o);

        const HIDE = new Set(['canceled','in_progress']);
        if (HIDE.has(decorated.status)) return; // не показуємо приховані

        if (idx >= 0) {
            this.orders = [
                ...this.orders.slice(0, idx),
                decorated,
                ...this.orders.slice(idx+1)
            ];
        } else {
            this.orders = [decorated, ...this.orders];
        }

        // необов'язково: посортувати за датою (нові зверху)
        this.orders = [...this.orders].sort((a,b) => (this._parseDate(b.date) - this._parseDate(a.date)));
    }

// 👂 головний обробник
    // 👇 ЗАМІНИ ЦЕЙ МЕТОД У ScrapSupplierOperations.js
    async handlePassCreated(e) {
        const reserveId = e?.detail; // id щойно створеного слота з дочірнього
        console.log('--------------handlePassCreated------------------', reserveId);

        try {
            const [activeRows, historyRows] = await Promise.all([
                listSupplierActiveSlotsThisAndNext({ supplierId: this.currentAccountId }),
                listSupplierHistorySlotsBeforeToday({ supplierId: this.currentAccountId, monthsBack: 6 })
            ]);

            // АКТУАЛЬНІ = тільки Approved/Requested
            const active = (activeRows || [])
                .map(r => this._mapSlotToOrder(r))
                .filter(o => o.status === 'issued' || o.status === 'pending')
                .map(o => this._decorate(o));
            this.orders = active;

            this.historyGroups = this._groupHistory(historyRows || []);
            await this.refreshActionButtons();       // ⬅️ ДОДАЙ ЦЕ

            console.log(`[Orders refresh] active: ${active.length}, history: ${(historyRows || []).length}`);
        } catch (error) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Помилка оновлення',
                message: error?.body?.message || error?.message || 'Не вдалося оновити списки слотів',
                variant: 'error'
            }));
        }
    }


    async handleCancelFromModal(event){
        const id  = event.detail?.orderId;
        if (!id) return;
        this.isSaving = true;

        try {
            // TODO: виклик Apex для відміни в бекенді (за потреби)
            // await cancelOrder({ orderId: id });

            // 🔥 прибираємо зі списку постачальника
            this.orders = this.orders.filter(o => o.id !== id);

            this.dispatchEvent(new ShowToastEvent({
                title: 'Замовлення скасовано',
                message: `Замовлення видалено зі списку.`,
                variant: 'success'
            }));

            this.showEditPass  = false;
            this.selectedOrder = null;
        } catch(e){
            this.dispatchEvent(new ShowToastEvent({
                title: 'Помилка',
                message: 'Не вдалося скасувати замовлення',
                variant: 'error',
                mode: 'sticky'
            }));
        } finally {
            this.isSaving = false;
        }
    }


    get showNoActionsInfo() {
        return !this.showReserveBtn && !this.showOutOfLimitBtn;
    }

    _currentDecadeNum(d = new Date()){
        const day = d.getDate();
        return (day <= 10) ? 1 : (day <= 20 ? 2 : 3);
    }

    handleSlotChanged(e){
        const dto = e.detail; // { id,status,reserveDate,truckModel,truckPlate,driverName,passNumber,hasTrailer,trailerPlate }
        // Можеш просто рефрешнути списки як у тебе вже зроблено,
        // або локально помітити слот як pending і скинути passNumber:
        this.orders = this.orders.map(o => o.id === dto.id
            ? this._decorate({ ...o, status: 'pending', passNumber: null,
                truckModel: dto.truckModel || o.truckModel,
                truckPlate: dto.truckPlate || o.truckPlate,
                driver: dto.driverName || o.driver })
            : o
        );
        this.showEditPass = false;
        this.selectedOrder = null;
    }

}