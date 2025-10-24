import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getMyAccountId from '@salesforce/apex/ScrapPassDirectController.getMyAccountId'

import listThisAndNextAllLimits from '@salesforce/apex/ScrapSupplierPortalController.listThisAndNextAllLimits';
import createProposedAutoThisOrNext from '@salesforce/apex/ScrapSupplierPortalController.createProposedAutoThisOrNext';
import listThisAndNextBalances from '@salesforce/apex/ScrapSupplierPortalController.listThisAndNextBalances';

// + додай:
import getStep2StaticInfo from '@salesforce/apex/ScrapSlotModalController.getStep2StaticInfo';
import getStep2Lookups    from '@salesforce/apex/ScrapSlotModalController.getStep2Lookups';
import searchDrivers      from '@salesforce/apex/ScrapSlotModalController.searchDrivers';
import searchTrucks       from '@salesforce/apex/ScrapSlotModalController.searchTrucks';

export default class ScrapSupplierProfile extends LightningElement {
    // Профіль
    @track isLoadingSupplier = false;
    supplierInfo = {
        name: '—',
        contactPerson: '—',
        phone: '—',
        unloadLocations: [],
        availableDrivers: [],
        availableTrucks: [],
        contactId: null,
        managers: []
    };

    get hasManagers() {
        return (this.supplierInfo?.managers || []).length > 0;
    }

    // ⬇️ під supplierInfo додай:
    get hasUnloadLocations() {
        return (this.supplierInfo?.unloadLocations || []).length > 0;
    }
    get hasDrivers() {
        return (this.supplierInfo?.availableDrivers || []).length > 0;
    }
    get hasTrucks() {
        return (this.supplierInfo?.availableTrucks || []).length > 0;
    }



    monthNamesUkr = [
        'Січень','Лютий','Березень','Квітень','Травень','Червень',
        'Липень','Серпень','Вересень','Жовтень','Листопад','Грудень'
    ];
    monthNumberToUkr(n){ return this.monthNamesUkr[(Number(n) || 1) - 1]; }

    currentAccountId;

    get submitBtnLabel() {
        return this.isSubmitting ? 'Надсилаю…' : 'Надіслати';
    }

// заголовок модалки — універсальний
    get modalTitle() {
        return 'Внесення заявлених лімітів';
    }

    @track isSubmitting = false;  // спінер/disable на час запиту

    @track cur = {
        ready: false,
        monthLabel: '',
        hasProposed: false,
        hasApproved: false,
        proposed: null, // {d1,d2,d3,month}
        approved: null,  // {d1,d2,d3,month}
        remaining: null          // ⬅️ тут триматимемо залишок по декадах/місяцю

    };

    packBalance(vm){
        if (!vm || !vm.decades) return null;
        let d1 = 0, d2 = 0, d3 = 0;
        (vm.decades || []).forEach(d => {
            const n = Number(d.decadeNum);
            const rem = Number(d.remaining || 0);
            if (n === 1) d1 = rem;
            else if (n === 2) d2 = rem;
            else if (n === 3) d3 = rem;
        });
        return {
            d1, d2, d3,
            month: Number(vm.remainingTotal || 0)
        };
    }


    @track nxt = {
        monthLabel: '',
        hasProposed: false,
        hasApproved: false,
        proposed: null,
        approved: null
    };

    get showUrgentPanel() {
        return !this.hasAnyCur && !this.hasAnyNxt;
    }

    get showCurrentFillCTA() {
        return !this.hasAnyCur;
    }

    get showCurrentTable(){
        return this.cur?.ready && (this.cur.hasProposed || this.cur.hasApproved);
    }

    get showNextCTA(){
        return !this.hasAnyNxt && !this.showUrgentPanel;
        // (showUrgentPanel = немає взагалі жодних лімітів – ок, лишаємо як є)
    }

    get showNextTable(){
        return this.hasAnyNxt; // є заявлений або узгоджений
    }

    // підпис під таблицею наступного місяця, якщо ще немає узгодженого
    get showNextPendingNote(){
        return this.nxt?.hasProposed && !this.nxt?.hasApproved;
    }

    connectedCallback() {
        this.bootstrapOnce();
    }

    async bootstrapOnce() {
        try {
            const accId = await getMyAccountId();
            this.currentAccountId = accId;

            // ⬇️ Тягнемо одночасно
            const [data, balances] = await Promise.all([
                listThisAndNextAllLimits({ supplierId: accId }),
                listThisAndNextBalances({ supplierId: accId })
            ]);

            // Логи (як і було)
            this.logApex(data);

            // 1) Спочатку будуємо стан таблиць (воно перезаписує this.cur)
            this.buildStateFromData(data);

            // 2) Тільки потім доклеюємо "залишок" у this.cur
            const curBalVm = (balances || [])[0]; // 0 — поточний місяць
            this.cur = { ...this.cur, remaining: this.packBalance(curBalVm) };

            await this.hydrateSupplierProfile(accId);
            this.checkEntryNotifications();

        } catch (e) {
            console.error('[Profile] bootstrap error:', e?.body?.message || e?.message, e);
            this.dispatchEvent(new ShowToastEvent({
                title: 'Помилка',
                message: e.body?.message || e.message,
                variant: 'error'
            }));
        }
    }


    get showCurrentRemaining(){
        // залишок показуємо лише для поточного і коли є узгоджений
        return !!(this.cur?.hasApproved && this.cur?.remaining);
    }
    get curRemD1(){ return this.cur?.remaining ? this.cur.remaining.d1 : '—'; }
    get curRemD2(){ return this.cur?.remaining ? this.cur.remaining.d2 : '—'; }
    get curRemD3(){ return this.cur?.remaining ? this.cur.remaining.d3 : '—'; }
    get curRemMonth(){ return this.cur?.remaining ? this.cur.remaining.month : '—'; }


// виносимо існуючу логіку логування сюди
    logApex(data) {
        console.log('[Profile] RAW result from Apex (object):', data);
        console.log('[Profile] RAW JSON:\n', JSON.stringify(data, null, 2));
        const count = Array.isArray(data) ? data.length : 0;
        console.log(`[Profile] Months returned: ${count}`);
        (data || []).forEach((m, i) => {
            console.group(`[${i}] Year=${m.yearNum}, Month=${m.monthNum}`);
            console.log('proposed count:', (m.proposed || []).length);
            console.log('approved count:', (m.approved || []).length);
            if ((m.proposed || []).length) {
                console.log('proposed[0]:', m.proposed[0]);
                if (m.proposed[0]?.details?.length) {
                    console.table(m.proposed[0].details.map(d => ({
                        detailId: d.id,
                        decadeId: d.decadeId,
                        decadeNumber: d.decadeNumber,
                        limitValue: d.limitValue
                    })));
                }
            }
            if ((m.approved || []).length) {
                console.log('approved[0]:', m.approved[0]);
                if (m.approved[0]?.details?.length) {
                    console.table(m.approved[0].details.map(d => ({
                        detailId: d.id,
                        decadeId: d.decadeId,
                        decadeNumber: d.decadeNumber,
                        limitValue: d.limitValue
                    })));
                }
            }
            console.groupEnd();
        });
    }

// сюди переносимо твою initCurrentTable (без додаткових Apex-викликів і без сету геттера)
    buildStateFromData(data) {
        const now = new Date();
        const y = now.getFullYear();
        const m = now.getMonth() + 1;
        const nextY = (m === 12) ? y + 1 : y;
        const nextM = (m === 12) ? 1 : (m + 1);

        const findBlock = (yy, mm) => (data || []).find(x => x.yearNum === yy && x.monthNum === mm) || null;

        const curBlock = findBlock(y, m);
        const nxtBlock = findBlock(nextY, nextM);

        const outCur = {
            ready: true,
            monthLabel: `${this.monthNumberToUkr(m)} ${y}`,
            hasProposed: false,
            hasApproved: false,
            proposed: null,
            approved: null
        };
        if (curBlock) {
            if (curBlock.proposed && curBlock.proposed.length) {
                outCur.hasProposed = true;
                outCur.proposed = this.packRow(curBlock.proposed[0]);
            }
            if (curBlock.approved && curBlock.approved.length) {
                outCur.hasApproved = true;
                outCur.approved = this.packRow(curBlock.approved[0]);
            }
        }
        this.cur = outCur;

        const outNxt = {
            monthLabel: `${this.monthNumberToUkr(nextM)} ${nextY}`,
            hasProposed: false,
            hasApproved: false,
            proposed: null,
            approved: null
        };
        if (nxtBlock) {
            if (nxtBlock.proposed && nxtBlock.proposed.length) {
                outNxt.hasProposed = true;
                outNxt.proposed = this.packRow(nxtBlock.proposed[0]);
            }
            if (nxtBlock.approved && nxtBlock.approved.length) {
                outNxt.hasApproved = true;
                outNxt.approved = this.packRow(nxtBlock.approved[0]);
            }
        }
        this.nxt = outNxt;

        // дебаг
        console.log('[CUR]', JSON.stringify(this.cur, null, 2));
        console.log('[NXT]', JSON.stringify(this.nxt, null, 2));
        console.log('[showUrgentPanel]', this.showUrgentPanel);
    }


    get hasAnyCur() {
        const c = this.cur;
        return !!(c && (c.hasProposed || c.hasApproved));
    }

    get hasAnyNxt() {
        const n = this.nxt;
        return !!(n && (n.hasProposed || n.hasApproved));
    }

    packRow(parentVm){
        let d1 = 0, d2 = 0, d3 = 0;
        (parentVm?.details || []).forEach(d => {
            const n = Number(d.decadeNumber);
            const v = Number(d.limitValue || 0);
            if (n === 1) d1 = v;
            else if (n === 2) d2 = v;
            else if (n === 3) d3 = v;
        });
        return { d1, d2, d3, month: d1 + d2 + d3 };
    }

    // handleAddCurrentLimit(){
    //     console.log('[CTA] Заповнити ліміти на поточний місяць');
    //     // TODO: відкрити модал/навігувати/викликати Apex (коли будемо готові)
    // }
    // openApproveModal(){  // у тебе вже є така функція — залишаю тут, щоб кнопка працювала
    //     // TODO: підлаштуй під модал для внесення заявки на наступний місяць
    //     console.log('[CTA] Внести заявку на наступний місяць');
    //     // ... твоя існуюча логіка відкриття модалки
    // }

    handleAccordionToggle(event) {
        const target = event.currentTarget.dataset.target;
        const body = this.template.querySelector('.accordion-body[data-body="' + target + '"]');
        const icon = this.template.querySelector('.accordion-toggle[data-icon="' + target + '"]');
        if (body && icon) {
            body.classList.toggle('show');
            icon.classList.toggle('rotate');
        }
    }

    // Контракти — попередження перемістили сюди (статичні у прикладі)

    // Ліміти — повний функціонал
    supplierName = 'ТОВ ТВК ЕРКОНТРЕЙД ';
    declaredLimitDec1 = 350;
    declaredLimitDec2 = 350;
    declaredLimitDec3 = 300;
    declaredLimitMonth = 1000;

    approvedLimitDec1 = 350;
    approvedLimitDec2 = 300;
    approvedLimitDec3 = 400;
    approvedLimitMonth = 980;

    remainingLimitDec1 = 0;
    remainingLimitDec2 = 280;
    remainingLimitDec3 = 300;
    remainingLimitMonth = 690;

    limit1 = 0;
    limit2 = 0;
    limit3 = 0;
    savedLimits = [0, 0, 0];
    showApproveModal = false;
    totalLimit = 0;
    disableConfirm = true;
    disableSave = true;

    // openApproveModal() {
    //     [this.limit1, this.limit2, this.limit3] = this.savedLimits || [0, 0, 0];
    //     this.recalculateLimit();
    //     this.showApproveModal = true;
    // }
    closeApproveModal() {
        this.totalLimit = 0;
        this.showApproveModal = false;
    }
    handleLimitInput(event) {
        const index = parseInt(event.target.dataset.index, 10);
        const value = parseFloat(event.target.value);
        if (index === 0) this.limit1 = value;
        if (index === 1) this.limit2 = value;
        if (index === 2) this.limit3 = value;
        this.recalculateLimit();
    }
    handleSaveLimits() {
        this.savedLimits = [this.limit1, this.limit2, this.limit3];
        this.showToast('Збережено', 'Значення збережено');
        this.showApproveModal = false;
    }
    handleSubmitLimits() {
        const d1 = Number(this.limit1) || 0;
        const d2 = Number(this.limit2) || 0;
        const d3 = Number(this.limit3) || 0;
        const m  = d1 + d2 + d3;

        this.nextPlan = { dec1: d1, dec2: d2, dec3: d3, month: m };
        this.nextPlanSubmitted = true;

        this.showToast('Відправлено', 'Ліміти надіслано на узгодження до адміністратора');
        this.closeApproveModal();
    }
    recalculateLimit() {
        const nums = [this.limit1, this.limit2, this.limit3];
        this.totalLimit = nums.reduce((s, v) => (typeof v === 'number' && !isNaN(v) ? s + v : s), 0);
        this.disableConfirm = nums.some(v => typeof v !== 'number' || isNaN(v) || v <= 0);
        this.disableSave = nums.every(v => typeof v !== 'number' || isNaN(v) || v <= 0);
    }
    showToast(title, message) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant: 'success', mode: 'dismissable' }));
    }

    // Історія — переміщено сюди
    orderHistory = [
        { id: 'h1', date: '2025-07-15', scrapType: '5/301', truck: 'MAN TGX 18.500', tonnage: 19, driver: 'Іваненко Петро', contract: '№120/К', address: 'вул. Промислова, 12, Київ' },
        { id: 'h2', date: '2025-07-21', scrapType: '4/201', truck: 'Scania R450', tonnage: 21, driver: 'Сидорчук Віктор', contract: '№121/К', address: 'вул. Заводська, 34, Дніпро' },
        { id: 'h3', date: '2025-07-25', scrapType: '3/101', truck: 'Volvo FH16', tonnage: 20, driver: 'Коваленко Андрій', contract: '№122/К', address: 'просп. Перемоги, 98, Харків' },
        { id: 'h4', date: '2025-07-28', scrapType: '2/401', truck: 'DAF XF 105', tonnage: 18, driver: 'Мельник Сергій', contract: '№123/К', address: 'вул. Металургів, 7, Запоріжжя' },
        { id: 'h5', date: '2025-08-01', scrapType: '6/301', truck: 'Renault T Range', tonnage: 22, driver: 'Гаврилюк Олександр', contract: '№124/К', address: 'вул. Центральна, 44, Львів' },
        { id: 'h6', date: '2025-08-03', scrapType: '5/205', truck: 'Mercedes-Benz Actros', tonnage: 20, driver: 'Ткаченко Максим', contract: '№125/К', address: 'вул. Індустріальна, 23, Одеса' }
    ];

    handleHistoryClick(event) {
        const id = event.currentTarget.dataset.orderId;
        // Деталі замовлення — за потреби додай модал
    }
    handleAccordionHistoryToggle(event) {
        const target = event.currentTarget.dataset.target;
        const body = this.template.querySelector('.accordion-body[data-body="' + target + '"]');
        const icon = this.template.querySelector('.order-history-accordion-toggle[data-icon="' + target + '"]');
        if (body && icon) {
            body.classList.toggle('show');
            icon.classList.toggle('rotate');
        }
    }

    // Редагування профілю
// ScrapSupplierProfile.js

    @track showEditSupplierModal = false;

    async openEditSupplierModal() {
        // 1) гарантуємо, що маємо accountId постачальника
        if (!this.currentAccountId) {
            try {
                this.currentAccountId = await getMyAccountId();
            } catch (e) {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Помилка',
                    message: 'Не вдалося визначити постачальника.',
                    variant: 'error'
                }));
                return;
            }
        }

        // 2) показуємо дочірній компонент у розмітці
        this.showEditSupplierModal = true;

        // 3) дочекайся рендера і відкрий модалку всередині дитини
        await Promise.resolve();
        const editor = this.template.querySelector('c-supplier-editor-panel');
        if (editor && this.currentAccountId) {
            editor.openForSupplier(this.currentAccountId); // ← викликає внутрішню модалку
        }
    }

    async handleCloseEditSupplierModal(event) {
        this.showEditSupplierModal = false;
        await this.hydrateSupplierProfile(this.currentAccountId);
        this.checkEntryNotifications();
    }

    get limit1Display() { return Number.isFinite(this.limit1) ? this.limit1 : ''; }
    get limit2Display() { return Number.isFinite(this.limit2) ? this.limit2 : ''; }
    get limit3Display() { return Number.isFinite(this.limit3) ? this.limit3 : ''; }



    @track showContractBlock = false;
    @track showContractWarning = false;
    @track showReserveReminder = false;
    @track showApproveReminder = false;

    handleCloseContractBlock() {
        this.showContractBlock = false;
        this._dismissEntryOnce('contractBlock');
    }
    handleCloseContractWarning() {
        this.showContractWarning = false;
        this._dismissEntryOnce('contractWarn');
    }
    handleCloseReserveReminder() {
        this.showReserveReminder = false;
        this._dismissEntryOnce('reserveReminder');
    }
    handleCloseApproveReminder() {
        this.showApproveReminder = false;
        this._dismissEntryOnce('approveReminder');
    }


    // показувати кнопку тільки поки НЕ надіслано
    get showApproveNextMonthButton() {
        return !this.nextPlanSubmitted;
    }

// стан і дані інфопанелі
    @track nextPlanSubmitted = false;
    @track nextPlan = { dec1: 0, dec2: 0, dec3: 0, month: 0 };

// ярлик місяця для панелі (тримай узгодженим із модалкою)
    nextMonthLabelCap = 'Вересень 2025';

// onSubmit: зберігаємо, показуємо панель, ховаємо модал і кнопку
    async submitModal() {
        const d1 = Number(this.limit1) || 0;
        const d2 = Number(this.limit2) || 0;
        const d3 = Number(this.limit3) || 0;
        if (d1 <= 0 || d2 <= 0 || d3 <= 0) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Перевірте дані',
                message: 'Усі три декади мають бути > 0.',
                variant: 'warning'
            }));
            return;
        }

        if (!this.currentAccountId) {
            try {
                this.currentAccountId = await getMyAccountId();
            } catch (e) {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Помилка',
                    message: 'Не вдалося визначити постачальника.',
                    variant: 'error'
                }));
                return;
            }
        }

        this.isSubmitting = true;
        try {
            await createProposedAutoThisOrNext({
                supplierId: this.currentAccountId,
                dec1Limit: d1,
                dec2Limit: d2,
                dec3Limit: d3
            });

            this.dispatchEvent(new ShowToastEvent({
                title: 'Надіслано',
                message: 'Заявлені ліміти збережено і надіслано на розгляд.',
                variant: 'success'
            }));

            this.showApproveModal = false;
            this.limit1 = this.limit2 = this.limit3 = 0;
            this.savedLimits = [0, 0, 0];
            this.totalLimit = 0;

            // ⬇️ Перечитуємо і ліміти, і баланси паралельно
            const [fresh, freshBalances] = await Promise.all([
                listThisAndNextAllLimits({ supplierId: this.currentAccountId }),
                listThisAndNextBalances({ supplierId: this.currentAccountId })
            ]);

            // Оновлюємо таблиці
            this.buildStateFromData(fresh);

            // Оновлюємо залишок для поточного місяця
            const curBalVm = (freshBalances || [])[0];
            this.cur = { ...this.cur, remaining: this.packBalance(curBalVm) };

        } catch (e) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Помилка',
                message: e?.body?.message || e?.message || 'Не вдалося надіслати ліміти.',
                variant: 'error'
            }));
        } finally {
            this.isSubmitting = false;
        }
    }


    get isSubmitDisabled() {
        return this.disableConfirm || this.isSubmitting;
    }

    openApproveModal() {
        // Підставимо останні збережені/введені значення або нулі
        const seed = this.savedLimits || [0, 0, 0];
        [this.limit1, this.limit2, this.limit3] = seed;
        this.recalculateLimit();    // оновить total/disableConfirm/disableSave
        this.showApproveModal = true;
    }

// щоб CTA «Заповнити ліміти на поточний місяць» теж відкривав ту саму модалку:
    handleAddCurrentLimit() {
        this.openApproveModal();
    }

    async hydrateSupplierProfile(supplierId) {
        this.isLoadingSupplier = true;
        try {
            const [stat, lookups, drivers, trucks, trailers] = await Promise.all([
                // scrapTypeId тут нам не критичний — беремо ім'я постачальника
                getStep2StaticInfo({ supplierId, scrapTypeId: null }),
                getStep2Lookups({ supplierId }),
                searchDrivers({ supplierId, query: '', limitSize: 50 }),
                searchTrucks({ supplierId, query: '', type: 'Truck',   limitSize: 50 }),
                searchTrucks({ supplierId, query: '', type: 'Trailer', limitSize: 50 })
            ]);

            // Менеджер (конт. особа) — беремо першого зі списку
            // const managers = Array.isArray(lookups?.managers) ? lookups.managers : [];

            const managersRaw = Array.isArray(lookups?.managers) ? lookups.managers : [];
            const managers = managersRaw.map(m => ({
                id: m.id,
                name: m.name,
                phone: m.phone || '',
                role: m.role || '',
                portalUser: !!m.portalUser
            }));

            const primaryManager = managers.find(x => x.portalUser) || managers[0] || null;
            const managersMarked = managers.map(x => ({ ...x, isPrimary: primaryManager && x.id === primaryManager.id }));


            // Адреси у вигляді "Майданчик | Адреса, Місто"
            const unloadLocations = (lookups?.addresses || []).map(a => {
                const left  = a.label || a.address || '';
                const right = [a.address, a.city].filter(Boolean).join(', ');
                return right ? `${left} | ${right}` : left || '—';
            });

            // Водії
            const availableDrivers = (drivers || []).map(d => ({
                id: d.id, name: d.name, phone: d.phone || ''
            }));

            // Тягачі + причепи (як один список “машин”)
            const availableTrucks = [...(trucks || []), ...(trailers || [])].map(t => ({
                id: t.id,
                model: t.model || t.name || '—',
                capacity: Number(t.tonnage || 0)
            }));

            // якщо Apex повертає контракти у lookups або stat — підсунь
            // const contractsRaw = (lookups && lookups.contracts) || (stat && stat.contracts) || [];

            // const contractsRaw =
            //     (lookups && lookups.contracts) ||
            //     (stat && stat.contracts) || []; // зроби, щоб Apex повертав масив контрактів
            // this.contractStatus = this.computeContractStatus(contractsRaw);
            // this.contractBanners = this.buildContractBanners(contractsRaw);

            const contractsRaw = this.normalizeContracts(stat, lookups);
            this.contractStatus   = this.computeContractStatus(contractsRaw);
            this.contractBanners  = this.buildContractBanners(contractsRaw);
            console.log('[contractsRaw]', contractsRaw);

            this.supplierInfo = {
                name: stat?.supplierName || '—',
                contactPerson: primaryManager?.name  || '—',
                phone:         primaryManager?.phone || '—',
                unloadLocations,
                availableDrivers,
                availableTrucks,
                managers: managersMarked,
                contactId: primaryManager?.id || null
            };
        } catch (e) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Помилка',
                message: e?.body?.message || e?.message || 'Не вдалося завантажити дані постачальника.',
                variant: 'error'
            }));
        } finally {
            this.isLoadingSupplier = false;
        }
    }

    // дедлайни/пороги
    RESERVE_DEADLINE_DAY = 25;   // до якого числа треба зарезервувати ліміти на наступний місяць
    CONTRACT_SOON_DAYS   = 14;   // “скоро завершується”, днів

    @track contractStatus = {
        exists: false,     // є хоч один контракт
        isActive: true,    // активний стан (якщо знаємо)
        endDate: null,     // найближча/актуальна дата завершення (Date або null)
        daysLeft: null     // скільки днів лишилось (число або null)
    };

    computeContractStatus(contracts) {
        const list = Array.isArray(contracts) ? contracts : [];
        if (!list.length) return { exists: false, isActive: true, endDate: null, daysLeft: null };

        // намагаємось витягти потрібні поля з різних можливих імен
        const pickEnd = (c) =>
            c.endDate || c.validTo || c.valid_to || c.contractEndDate || c.end || null;
        const pickActive = (c) =>
            (c.isActive ?? c.active ?? c.is_active ?? (c.status === 'Active'));

        // беремо контракт з найбільш “пізньою” датою завершення (як актуальний)
        let winner = null;
        for (const c of list) {
            const endStr = pickEnd(c);
            const end = endStr ? new Date(endStr) : null;
            if (!winner || (end && (!winner.end || end > winner.end))) {
                winner = { end, isActive: !!pickActive(c) };
            }
        }

        const today = new Date();
        const endDate = winner?.end || null;
        const daysLeft = endDate ? Math.ceil((endDate - today) / 86400000) : null;

        return {
            exists: true,
            isActive: winner?.isActive ?? true,
            endDate,
            daysLeft
        };
    }

    NEXT_LIMITS_TRIGGER_DAY = 20; // поруч з іншими константами

    checkEntryNotifications() {
        this.showContractBlock   = false;
        this.showContractWarning = false;
        this.showReserveReminder = false;
        this.showApproveReminder = false;
        this.showNoLimitsBlock   = false;

        const st  = this.contractStatus || {};
        const now = new Date();
        const day = now.getDate();

        // 1) Контракт завершився/неактивний → блок
        const expired = st?.endDate ? (new Date(st.endDate) < now) : (st?.daysLeft != null && st.daysLeft < 0);
        if (!st?.exists || !st?.isActive || expired) {
            if (!this._wasDismissed('contractBlock')) this.showContractBlock = true;
            return;
        }

        // 1.1) Скоро завершується → попередження
        if (st.daysLeft != null && st.daysLeft <= this.CONTRACT_SOON_DAYS) {
            if (!this._wasDismissed('contractWarn')) this.showContractWarning = true;
        }

        // 2) Наступний місяць: внесено, але не узгоджено → нагадування
        if (this.nxt?.hasProposed && !this.nxt?.hasApproved) {
            if (!this._wasDismissed('approveReminder')) this.showApproveReminder = true;
            return;
        }

        // ✅ 3) Поточний місяць: немає жодних лімітів → банер відразу
        if (!this.hasAnyCur) {
            if (!this._wasDismissed('noLimits')) this.showNoLimitsBlock = true;
            return;
        }

        // ✅ 4) Наступний місяць: після 20 числа → нагадування
        // if (day >= 20 && !(this.nxt?.hasProposed || this.nxt?.hasApproved)) {
        //     if (!this._wasDismissed('reserveReminder')) this.showReserveReminder = true;
        // }

        if (day >= this.NEXT_LIMITS_TRIGGER_DAY && !(this.nxt?.hasProposed || this.nxt?.hasApproved)) {
            if (!this._wasDismissed('reserveReminder')) this.showReserveReminder = true;
        }
    }



    // Пороги
    CONTRACT_WARN_DAYS   = 30; // жовтий: ≤ 30 днів
    CONTRACT_URGENT_DAYS = 14; // червоний: ≤ 14 днів або прострочений

    @track contractBanners = []; // що будемо рендерити над профілем

    toDate(v) {
        if (!v) return null;
        if (v instanceof Date) return isNaN(v.getTime()) ? null : v;

        if (typeof v === 'string') {
            const s = v.trim();

            // ISO: 2025-09-01
            if (/^\d{4}-\d{2}-\d{2}$/.test(s)) {
                const [Y, M, D] = s.split('-').map(Number);
                return new Date(Y, M - 1, D);
            }

            // uk: 01.09.2025
            const m = s.match(/^(\d{1,2})\.(\d{1,2})\.(\d{4})$/);
            if (m) {
                const D = +m[1], M = +m[2], Y = +m[3];
                return new Date(Y, M - 1, D);
            }
        }

        const d = new Date(v);
        return isNaN(d.getTime()) ? null : d;
    }

    fmtDate(d) {
        return d ? new Intl.DateTimeFormat('uk-UA').format(d) : '∞';
    }

// будуємо банери зі списку контрактів
    buildContractBanners(contractsRaw) {
        const today = new Date();
        const pick = (c, keys) => keys.map(k => c[k]).find(v => v != null && v !== '') ?? null;

        const mapped = (contractsRaw || []).map(c => {
            const number = pick(c, ['DogN__c','contractNumber','number','name','code']) || '—';

            // старт: стандарт/кастом/формула
            const start = this.toDate(pick(c, [
                'StartDate', 'startDate', 'DateFrom__c', 'dateFrom', 'validFrom', 'valid_from', 'beginDate', 'start'
            ]));

            // фініш: стандарт/кастом/формула/нормалізоване поле
            const end = this.toDate(pick(c, [
                'EndDate', 'endDate', 'EndDate__c', 'DateTo__c', 'dateTo', 'validTo', 'valid_to', 'contractEndDate', 'end'
            ]));

            // активність: беремо як є, дефолт — true
            const activeRaw = pick(c, ['IsActive__c','isActive','active','is_active','Status']);
            const isActive = (activeRaw == null)
                ? true
                : (typeof activeRaw === 'string' ? (activeRaw === 'Activated' || activeRaw === 'Active') : !!activeRaw);

            // ✅ дні до завершення з поля, без обчислень; якщо нема — тоді вже рахуємо від end
            const willLeftRaw = pick(c, ['WillBeActive__c','willBeActiveDays','will_be_active_days']);
            const daysLeft = Number.isFinite(Number(willLeftRaw))
                ? Number(willLeftRaw)
                : (end ? Math.ceil((end - today) / 86400000) : null);

            // рівень
            let level = 'green';
            if (!isActive) level = 'red';
            else if (daysLeft != null && daysLeft <= this.CONTRACT_URGENT_DAYS) level = 'red';
            else if (daysLeft != null && daysLeft <= this.CONTRACT_WARN_DAYS)   level = 'yellow';

            // текст
            const expired  = daysLeft != null && daysLeft < 0;
            const startTxt = this.fmtDate(start);
            const endTxt   = this.fmtDate(end);
            const line = expired
                ? `Контракт ${number} від ${startTxt} — строк дії закінчився ${endTxt}`
                : `Контракт ${number} від ${startTxt} — термін дії завершується ${endTxt}`;

            return {
                id: c.id || `${number}-${end?.toISOString?.() || Math.random()}`,
                className: `contract-warning ${level}`,
                text: line,
                daysLeft: daysLeft == null ? 999999 : daysLeft,
                level
            };
        });

        mapped.sort((a, b) => a.daysLeft - b.daysLeft);
        return mapped;
    }


    get hasContractBanners() {
        return (this.contractBanners || []).length > 0;
    }

    // Нормалізуємо джерела в єдиний масив контрактів для банерів/статусу
    normalizeContracts(stat, lookups) {
        const list = [];

        // 1) одиночний контракт зі Step2StaticInfo
        const sc = stat?.contract;
        if (sc) {
            list.push({
                id: sc.id,
                contractNumber: sc.contractNumber,
                startDate: sc.dateFrom, // 'YYYY-MM-DD'
                endDate:   sc.dateTo,   // 'YYYY-MM-DD'
                // якщо Apex не повертає isActive — виводимо з willBeActiveDays або з дат
                isActive: (sc.willBeActiveDays == null)
                    ? (sc.dateFrom && sc.dateTo
                        ? (new Date(sc.dateFrom) <= new Date() && new Date(sc.dateTo) >= new Date())
                        : true)
                    : Number(sc.willBeActiveDays) >= 0
            });
        }

        // 2) якщо колись додаси масив у lookups/contracts — теж врахуємо
        if (Array.isArray(lookups?.contracts)) {
            for (const c of lookups.contracts) {
                list.push({
                    id: c.id,
                    contractNumber: c.contractNumber ?? c.number ?? c.name ?? c.code,
                    startDate: c.startDate ?? c.validFrom ?? c.valid_from ?? c.beginDate ?? c.start,
                    endDate:   c.endDate   ?? c.validTo   ?? c.valid_to   ?? c.contractEndDate ?? c.end,
                    isActive:  (c.isActive ?? c.active ?? c.is_active ?? null)
                });
            }
        }
        return list;
    }

    @track showNoLimitsBlock = false;
    handleCloseNoLimitsBlock() { this.showNoLimitsBlock = false; this._dismissEntryOnce('noLimits'); }

    _dismissEntryOnce(key) {
        try { window.sessionStorage.setItem(`ssp:dismiss:${key}`, '1'); } catch(e) {}
    }
    _wasDismissed(key) {
        try { return window.sessionStorage.getItem(`ssp:dismiss:${key}`) === '1'; } catch(e) { return false; }
    }

}