import { LightningElement, track, wire, api } from 'lwc';

import getSupplierDetails from '@salesforce/apex/ScrapSupplierAdminService.getSupplierDetails';
import createShippingPoint from '@salesforce/apex/ScrapSupplierAdminService.createShippingPoint';
import createDriver from '@salesforce/apex/ScrapSupplierAdminService.createDriver';
import createManager from '@salesforce/apex/ScrapSupplierAdminService.createManager';
import sanitizePhoneNum from '@salesforce/apex/ScrapUtils.sanitizePhoneNum';

import deleteShippingPoint from '@salesforce/apex/ScrapSupplierAdminService.deleteShippingPoint';
import deleteContact from '@salesforce/apex/ScrapSupplierAdminService.deleteContact';
import updateSupplierMainInfo from '@salesforce/apex/ScrapSupplierAdminService.updateSupplierMainInfo';
import updateShippingPoint from '@salesforce/apex/ScrapSupplierAdminService.updateShippingPoint';
import updateContact from '@salesforce/apex/ScrapSupplierAdminService.updateContact';

import createTruck from '@salesforce/apex/ScrapSupplierAdminService.createTruck';
import updateTruckBasic from '@salesforce/apex/ScrapSupplierAdminService.updateTruckBasic';

import detachShippingPoint from '@salesforce/apex/ScrapSupplierAdminService.detachShippingPoint';
import detachContact from '@salesforce/apex/ScrapSupplierAdminService.detachContact';
import unlinkTruckFromSupplier from '@salesforce/apex/ScrapSupplierAdminService.unlinkTruckFromSupplier'; // лишається


import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class SupplierEditorPanel extends LightningElement {
    // --------- ДАНІ ПОСТАЧАЛЬНИКА (джерело істини для модалки) ---------
    @track selected = null; // очікується об’єкт getSupplierDetails

    // --------- СТАН МОДАЛКИ ---------
    showEditModal = false;
    @track saving = false;

    // Робочі копії (тільки в межах модалки)
    @track editedMain = {
        name: '',
        phone: '',
        email: '',
        description: '',
        billingStreet: '',
        billingCity: '',
        billingState: '',
        billingPostalCode: '',
        billingCountry: ''
    };

    editZones = [];
    editDrivers = [];
    editManagers = [];
    editVehicles = [];

    zonesMarkedForDelete = new Set();
    contactsMarkedForDelete = new Set();
    vehiclesMarkedForDelete = new Set();

    // Повертає '+380XXXXXXXXX' або null
    async _normalizePhone(raw) {
        try {
            // Приберемо можливі "ext/доб/дод." разом із усім хвостом після них
            const cleaned = (raw || '').replace(/\s*(ext|доб\.?|дод\.?).*$/i, '').trim();
            const r = await sanitizePhoneNum({ raw: cleaned });
            return r || null;
        } catch (e) {
            return null;
        }
    }

     async _normalizeOrRaw(raw) {
       const val = (raw || '').trim();
       if (!val) return null;
       const norm = await this._normalizePhone(val);
       return norm || val;
     }

    // --------- ПІДТРИМКА ТИПІВ ТЗ (для combobox) ---------
    get typeOptions() {
        return [
            { label: 'Тягач', value: 'Truck' },
            { label: 'Причіп', value: 'Trailer' }
        ];
    }

    _getPhone(row) {
        return ((row && row._draft && row._draft.phone) ?? row?.phone ?? '').toString().trim();
    }

    _validateDriverHasPhone(row) {
        const phone = this._getPhone(row);
        if (!phone) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Неможливо зберегти водія',
                    message: 'Поле "Телефон" є обовʼязковим для водія.',
                    variant: 'error'
                })
            );
            return false;
        }
        return true;
    }

    // --------- ГЕТТЕРИ ДЛЯ ШАБЛОНУ ---------
    get contractsEmpty() {
        return !this.selected || !(this.selected.contracts && this.selected.contracts.length);
    }

    get editZonesRendered()    { return (this.editZones    || []).filter(r => !r._markedForDelete); }
    get editDriversRendered()  { return (this.editDrivers  || []).filter(r => !r._markedForDelete); }
    get editManagersRendered() { return (this.editManagers || []).filter(r => !r._markedForDelete); }
    get editVehiclesRendered() { return (this.editVehicles || []).filter(r => !r._markedForDelete); }

    get editZonesEmpty()    { return (this.editZones    || []).length === 0; }
    get editDriversEmpty()  { return (this.editDrivers  || []).length === 0; }
    get editManagersEmpty() { return (this.editManagers || []).length === 0; }
    get editVehiclesEmpty() { return (this.editVehicles || []).length === 0; }

    get modalContentClass() {
        return `modal-content${this.saving ? ' is-saving' : ''}`;
    }

    // --------- API (опціонально зручно викликати зверху) ---------
    @api async openForSupplier(accountId) {
        if (!accountId) return;
        this.selected = { id: accountId };     // ← встановлюємо id тут
        await this.refreshSelectedDetails(accountId); // ← передаємо явно
        this.openEditModal();
    }

    // --------- ВІДКРИТТЯ/ЗАКРИТТЯ МОДАЛКИ ---------
    openEditModal = () => {
        if (!this.selected) return;

        // Головний блок
        this.editedMain = {
            name: this.selected.name || '',
            phone: this.selected.phone || '',
            email: this.selected.email || '',
            description: this.selected.description || '',
            billingStreet: this.selected.billingStreet || '',
            billingCity: this.selected.billingCity || '',
            billingState: this.selected.billingState || '',
            billingPostalCode: this.selected.billingPostalCode || '',
            billingCountry: this.selected.billingCountry || ''
        };

        // Машини
        this.editVehicles = (this.selected.vehicles || []).map(v =>
            this._decorate({
                ...v,
                _isNew: false,
                _isEditing: false,
                _dirty: false,
                _markedForDelete: false,
                _draft: {
                    plateNumber: v.plateNumber || '',
                    model: v.model || '',
                    type: v.type || '',
                    tonnage: v.tonnage ?? null
                },
                showDeleteIcon: true,
                showReturnIcon: false
            })
        );
        this.vehiclesMarkedForDelete = new Set();

        // Загальний toRow для зон/контактів
        const toRow = (rec) => {
            const n = this._splitName(rec.name);
            const draft = {
                ...rec,
                firstName:  rec.firstName  || n.firstName  || '',
                middleName: rec.middleName || n.middleName || '',
                lastName:   rec.lastName   || n.lastName   || '',
                phone:      rec.phone      || '',
                email:      rec.email      || ''
            };
            return this._decorate({
                ...rec,
                _markedForDelete: false,
                _isEditing: false,
                _dirty: false,
                _isNew: false,
                _draft: draft,
                showDeleteIcon: true,
                showReturnIcon: false
            });
        };

        // Зони / Водії / Менеджери
        this.editZones    = (this.selected.shippingPoints || []).map(toRow);
        this.editDrivers  = (this.selected.drivers || []).map(toRow);
        this.editManagers = (this.selected.managers || []).map(toRow);

        this.zonesMarkedForDelete = new Set();
        this.contactsMarkedForDelete = new Set();

        this.showEditModal = true;
        requestAnimationFrame(() => {
            this.template.querySelector('lightning-input[data-name="name"]')?.focus();
        });
    };

    closeEditModal = () => {
        this.showEditModal = false;
        this.dispatchEvent(
            new CustomEvent('close', {
                detail: { refresh: false, cause: 'cancel' },
                bubbles: true,
                composed: true
            })
        );
    };

    // --------- ОБРОБКА ПОЛІВ "ГОЛОВНОГО БЛОКУ" ---------
    handleMainInputChange = (event) => {
        const fieldName = event.target.dataset.name;
        const fieldValue = event.detail.value;
        this.editedMain = { ...this.editedMain, [fieldName]: fieldValue };
    };

    // --------- РОБОТА ЗІ СТРОКАМИ В ТАБЛИЦЯХ МОДАЛКИ ---------
    startRowEdit = (event) => {
        const type = event.currentTarget.dataset.type; // zone | driver | manager | vehicle
        const id   = event.currentTarget.dataset.id;

        const arm = (arr, toDraft) =>
            arr.map(r => (r.id !== id ? r : this._decorate({ ...r, _isEditing: true, _draft: toDraft(r) })));

        if (type === 'zone') {
            this.editZones = arm(this.editZones, r => ({
                name: r.name || '',
                city: r.city || '',
                address: r.address || ''
            }));
            return;
        }

        if (type === 'driver') {
            this.editDrivers = arm(this.editDrivers, (r) => {
                const n = this._splitName(r.name);
                return {
                    ...r._draft,
                    firstName:  r._draft?.firstName  ?? r.firstName  ?? n.firstName  ?? '',
                    middleName: r._draft?.middleName ?? r.middleName ?? n.middleName ?? '',
                    lastName:   r._draft?.lastName   ?? r.lastName   ?? n.lastName   ?? '',
                    title:      r._draft?.title      ?? r.title      ?? '',
                    dept:       r._draft?.dept       ?? r.dept       ?? '',
                    phone:      r._draft?.phone      ?? r.phone      ?? '',
                    email:      r._draft?.email      ?? r.email      ?? ''
                };
            });
            return;
        }

        if (type === 'manager') {
            this.editManagers = arm(this.editManagers, (r) => {
                const n = this._splitName(r.name);
                return {
                    ...r._draft,
                    firstName:  r._draft?.firstName  ?? r.firstName  ?? n.firstName  ?? '',
                    middleName: r._draft?.middleName ?? r.middleName ?? n.middleName ?? '',
                    lastName:   r._draft?.lastName   ?? r.lastName   ?? n.lastName   ?? '',
                    title:      r._draft?.title      ?? r.title      ?? '',
                    dept:       r._draft?.dept       ?? r.dept       ?? '',
                    phone:      r._draft?.phone      ?? r.phone      ?? '',
                    email:      r._draft?.email      ?? r.email      ?? ''
                };
            });
            return;
        }

        if (type === 'vehicle') {
            this.editVehicles = arm(this.editVehicles, r => ({
                plateNumber: r.plateNumber || '',
                model: r.model || '',
                type: r.type || '',
                tonnage: r.tonnage ?? null
            }));
        }
    };

    cancelRowEdit = (event) => {
        const type = event.currentTarget.dataset.type;
        const id   = event.currentTarget.dataset.id;

        const disarm = (arr) =>
            arr
                .map(r => (r.id === id ? this._decorate({ ...r, _isEditing: false, _draft: undefined }) : r))
                // якщо новий і ще не підтверджений (не натиснули "Зберегти" в рядку) — прибираємо
                .filter(r => !(r.id === id && r._isNew && !r._newCommitted));

        if (type === 'zone')    this.editZones    = disarm(this.editZones);
        if (type === 'driver')  this.editDrivers  = disarm(this.editDrivers);
        if (type === 'manager') this.editManagers = disarm(this.editManagers);
        if (type === 'vehicle') this.editVehicles = disarm(this.editVehicles);
    };

    handleRowDraftInput = (event) => {
        const rowType   = event.currentTarget.dataset.type; // 'zone' | 'driver' | 'manager' | 'vehicle'
        const rowId     = event.currentTarget.dataset.id;
        const fieldName = event.target.dataset.name;
        const incoming  = event.detail.value;

        if (rowType === 'vehicle') {
            let v = incoming;
            if (fieldName === 'plateNumber' && typeof v === 'string') v = v.replace(/\s+/g, '');
            if (fieldName === 'tonnage') v = (v === '' || v === null) ? null : Number(v);

            this.editVehicles = (this.editVehicles || []).map(r => {
                if (r.id !== rowId) return r;
                const nextDraft = { ...(r._draft || {}), [fieldName]: v };
                return this._decorate({ ...r, _draft: nextDraft, _dirty: true });
            });
            return;
        }

        const patch = (arr) =>
            arr.map(r => {
                if (r.id !== rowId) return r;
                const nextDraft = { ...(r._draft || {}), [fieldName]: incoming };
                return this._decorate({ ...r, _draft: nextDraft });
            });

        if (rowType === 'zone')    this.editZones    = patch(this.editZones);
        if (rowType === 'driver')  this.editDrivers  = patch(this.editDrivers);
        if (rowType === 'manager') this.editManagers = patch(this.editManagers);
    };

    handlePersonNameDraft = (event) => {
        const type    = event.currentTarget.dataset.type; // 'driver' | 'manager'
        const id      = event.currentTarget.dataset.id;
        const nameKey = event.target.dataset.name; // firstName | lastName | middleName
        const val     = event.detail.value;

        const patch = (arr) =>
            arr.map(r => {
                if (r.id !== id) return r;
                const person = { ...(r._person || {}), [nameKey]: val };
                return this._decorate({ ...r, _person: person, _dirty: true });
            });

        if (type === 'driver')  this.editDrivers  = patch(this.editDrivers);
        if (type === 'manager') this.editManagers = patch(this.editManagers);
    };

    toggleMarkRemove = (event) => {
        const type = event.currentTarget.dataset.type; // 'zone'|'driver'|'manager'|'vehicle'
        const id   = event.currentTarget.dataset.id;

        const handle = (arr, set) => {
            const row = (arr || []).find(r => r.id === id);
            if (!row) return arr;

            // Нові непідтверджені — просто прибираємо з таблиці
            if (row._isNew || this._isTempId(id)) {
                return (arr || []).filter(r => r.id !== id);
            }

            const mark = !set.has(id);
            if (mark) set.add(id); else set.delete(id);

            return (arr || []).map(r =>
                r.id === id
                    ? this._decorate({
                        ...r,
                        _markedForDelete: mark,
                        showDeleteIcon: !mark,
                        showReturnIcon: mark
                    })
                    : r
            );
        };

        if (type === 'zone')    this.editZones    = handle(this.editZones,    this.zonesMarkedForDelete);
        if (type === 'driver')  this.editDrivers  = handle(this.editDrivers,  this.contactsMarkedForDelete);
        if (type === 'manager') this.editManagers = handle(this.editManagers, this.contactsMarkedForDelete);
        if (type === 'vehicle') this.editVehicles = handle(this.editVehicles, this.vehiclesMarkedForDelete);
    };

    handleRowSave = (event) => {
        const type = event.currentTarget.dataset.type; // 'zone'|'driver'|'manager'|'vehicle'
        const id   = event.currentTarget.dataset.id;

        // Валідація для нових водіїв/менеджерів
        if (type === 'driver' || type === 'manager') {
            const arr = type === 'driver' ? this.editDrivers : this.editManagers;
            const row = (arr || []).find(r => r.id === id);
            if (row && row._isNew && !this._validateNewContactRow(row)) return;
        }

        if (type === 'driver') {
            const row = (this.editDrivers || []).find(r => r.id === id);
            if (!this._validateDriverHasPhone(row)) return; // блокуємо збереження рядка
        }

        if (type === 'vehicle') {
            const commit = (arr) =>
                arr.map(r => {
                    if (r.id !== id) return r;
                    const merged = { ...r, ...r._draft, _isEditing: false, _dirty: true };
                    merged.plateNumber = (merged.plateNumber || '').replace(/\s+/g, '');
                    if (r._isNew) merged._newCommitted = true;
                    merged._draft = { ...merged };
                    return this._decorate(merged);
                });
            this.editVehicles = commit(this.editVehicles);
            return;
        }

        const commit = (arr, rowType) =>
            arr.map(r => {
                if (r.id !== id) return r;
                const merged = { ...r, ...r._draft, _isEditing: false, _dirty: true };

                if (!r._isNew && (rowType === 'driver' || rowType === 'manager')) {
                    const parts = [merged.lastName, merged.firstName, merged.middleName].filter(Boolean);
                    merged.name = parts.join(' ').trim();
                }

                if (r._isNew) {
                    merged._newCommitted = true;
                }
                if (r._isNew && (rowType === 'driver' || rowType === 'manager')) {
                    const p = r._person || {};
                    const parts = [p.lastName, p.firstName, p.middleName].filter(Boolean);
                    merged.name = parts.join(' ').trim();
                }

                merged._draft = { ...merged };
                return this._decorate(merged);
            });

        if (type === 'zone')    this.editZones    = commit(this.editZones, 'zone');
        if (type === 'driver')  this.editDrivers  = commit(this.editDrivers, 'driver');
        if (type === 'manager') this.editManagers = commit(this.editManagers, 'manager');
    };

    // --------- ДОДАВАННЯ НОВИХ РЯДКІВ У МОДАЛЦІ ---------
    addZoneInModal = () => {
        const id = this._makeTempId('Z');
        const row = this._decorate({
            id,
            name: '',
            countryName: 'Україна',
            city: '',
            address: '',
            _isNew: true,
            _newCommitted: false,
            _isEditing: true,
            _dirty: true,
            _markedForDelete: false,
            _draft: { name: '', city: '', address: '' },
            showDeleteIcon: true,
            showReturnIcon: false
        });
        this.editZones = [row, ...(this.editZones || [])];
    };

    addDriverInModal = () => {
        const id = this._makeTempId('D');
        const row = this._decorate({
            id,
            name: '',
            title: 'Водій',
            dept: 'Транспортний відділ',
            phone: '',
            email: '',
            _person: { lastName: '', firstName: '', middleName: '' },
            _isNew: true,
            _isEditing: true,
            _dirty: true,
            _markedForDelete: false,
            _draft: { title: 'Водій', dept: 'Транспортний відділ', phone: '', email: '' },
            showDeleteIcon: true,
            showReturnIcon: false
        });
        this.editDrivers = [row, ...(this.editDrivers || [])];
    };

    addManagerInModal = () => {
        const id = this._makeTempId('M');
        const row = this._decorate({
            id,
            name: '',
            title: 'Директор',
            dept: 'Дирекція',
            phone: '',
            email: '',
            _person: { lastName: '', firstName: '', middleName: '' },
            _isNew: true,
            _isEditing: true,
            _dirty: true,
            _markedForDelete: false,
            _draft: { title: 'Директор', dept: 'Дирекція', phone: '', email: '' },
            showDeleteIcon: true,
            showReturnIcon: false
        });
        this.editManagers = [row, ...(this.editManagers || [])];
    };

    addVehicleInModal = () => {
        const id = this._makeTempId('V');
        const row = this._decorate({
            id,
            plateNumber: '',
            model: '',
            type: '',
            tonnage: null,
            _isNew: true,
            _newCommitted: false,
            _isEditing: true,
            _dirty: true,
            _markedForDelete: false,
            _draft: { plateNumber: '', model: '', type: '', tonnage: null },
            showDeleteIcon: true,
            showReturnIcon: false
        });
        this.editVehicles = [row, ...(this.editVehicles || [])];
    };

    // --------- ЗБЕРЕЖЕННЯ ВСІЄЇ МОДАЛКИ ---------
    saveEditModal = async () => {
        console.log('========saveEditModal========');
        if (this.saving || !this.selected?.id) return;
        this.saving = true;

        try {
            const accountId = this.selected.id;

            // ---- 1) Оновити головні поля акаунта
            let updated;
            try {
                console.log('========CHECK 1========');
                console.log('updated')
                console.log('accountId: ' + accountId)
                console.log('name: ' + this.editedMain.name)
                console.log('phone: ' + this.editedMain.phone)
                console.log('email: ' + this.editedMain.email)
                console.log('description: ' + this.editedMain.description)
                console.log('billingStreet: ' + this.editedMain.billingStreet)

                updated = await updateSupplierMainInfo({
                    accountId,
                    name: this.editedMain.name,
                    phone: this.editedMain.phone,
                    email: this.editedMain.email,
                    description: this.editedMain.description,
                    billingStreet: this.editedMain.billingStreet,
                    billingCity: this.editedMain.billingCity,
                    billingState: this.editedMain.billingState,
                    billingPostalCode: this.editedMain.billingPostalCode,
                    billingCountry: this.editedMain.billingCountry
                });
            } catch (e) {
                const msg = this._errToMessage(e);
                this._logError('updateSupplierMainInfo', e, { payload: this.editedMain, accountId });
                throw new Error(`Оновлення профілю: ${msg}`);
            }
            console.log('========CHECK 2========');
            // ⚠️ Не всі Apex-методи повертають SObject.
            // Якщо прийшло SObject — локально мержимо.
            // Якщо прийшов лише Id/void — пропускаємо мерж і просто рефрешнемо наприкінці.
            if (updated && typeof updated === 'object') {
                this.selected = {
                    ...this.selected,
                    name: updated.Name ?? this.editedMain.name,
                    phone: updated.Phone ?? this.editedMain.phone,
                    email: updated.Email__c ?? this.editedMain.email,
                    description: updated.Description ?? this.editedMain.description,
                    billingStreet: updated.BillingStreet ?? this.editedMain.billingStreet,
                    billingCity: updated.BillingCity ?? this.editedMain.billingCity,
                    billingState: updated.BillingState ?? this.editedMain.billingState,
                    billingPostalCode: updated.BillingPostalCode ?? this.editedMain.billingPostalCode,
                    billingCountry: updated.BillingCountry ?? this.editedMain.billingCountry
                };
            } else {
                console.warn('[updateSupplierMainInfo] unexpected return payload:', updated);
            }
            console.log('========CHECK 3========');

            // ---- 2) Розкласти зміни
            const newZones = (this.editZones || []).filter(z => z._isNew && z._newCommitted && !this.zonesMarkedForDelete.has(z.id));
            const newDrivers = (this.editDrivers || []).filter(d => d._isNew && d._newCommitted && !this.contactsMarkedForDelete.has(d.id));
            const newManagers = (this.editManagers || []).filter(m => m._isNew && m._newCommitted && !this.contactsMarkedForDelete.has(m.id));
            const newVehicles = (this.editVehicles || []).filter(v => v._isNew && v._newCommitted && !this.vehiclesMarkedForDelete.has(v.id));

            const vehiclesToUpdate = (this.editVehicles || []).filter(v => v._dirty && !v._isNew && !this.vehiclesMarkedForDelete.has(v.id));
            const zonesToUpdate    = (this.editZones   || []).filter(z => z._dirty && !z._isNew && !this.zonesMarkedForDelete.has(z.id));
            const driversToUpdate  = (this.editDrivers || []).filter(c => c._dirty && !c._isNew && !this.contactsMarkedForDelete.has(c.id));
            const managersToUpdate = (this.editManagers|| []).filter(c => c._dirty && !c._isNew && !this.contactsMarkedForDelete.has(c.id));

            // 🔒 ДОДАНО: жорстка перевірка, що жоден водій (новий або оновлюваний) не без телефону
            const invalidNewDrivers = newDrivers.filter(d => !this._getPhone(d));
            const invalidUpdDrivers = driversToUpdate.filter(d => !this._getPhone(d));

            if (invalidNewDrivers.length || invalidUpdDrivers.length) {
                const names = [...invalidNewDrivers, ...invalidUpdDrivers]
                    .map(d => (d.name || [d?.lastName, d?.firstName, d?.middleName].filter(Boolean).join(' ')).trim() || '(без імені)')
                    .slice(0, 5) // щоб тост не був надто довгий
                    .join(', ');
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Неможливо зберегти зміни',
                        message: `Для водія(їв) відсутній телефон: ${names}. Заповніть поле "Телефон".`,
                        variant: 'error'
                    })
                );
                throw new Error('Валідація: телефон водія обовʼязковий');
            }

            console.log('========CHECK 4========');

            // ---- 2.1) Нормалізація та валідація телефонів (водії/менеджери)
            // ---- 2.1) Тиха нормалізація телефонів (без валідації формату)
            {
                const setDraftPhone = async (row) => {
                    const raw = this._getPhone(row);                    // бере row._draft?.phone || row.phone
                    const phone = await this._normalizeOrRaw(raw);      // '+380XXXXXXXXX' | raw | null
                    if (!row._draft) row._draft = {};
                    row._draft.phone = phone;                           // для create*
                };

                const setUpdatePhone = async (row) => {
                    const raw = this._getPhone(row);
                    const phone = await this._normalizeOrRaw(raw);
                    row.phone = phone;                                  // для update*
                    if (row._draft) row._draft.phone = phone;           // щоб UI був синхронний
                };

                await Promise.all([
                    // нові контакти — пишемо в _draft
                    ...newDrivers.map(setDraftPhone),
                    ...newManagers.map(setDraftPhone),

                    // існуючі контакти — пишемо і в поле, і в _draft
                    ...driversToUpdate.map(setUpdatePhone),
                    ...managersToUpdate.map(setUpdatePhone),
                ]);
            }


            // ---- 3) Створити нові
            try {
                const createdVehicles = [];
                for (const v of newVehicles) {
                    const plate = (v.plateNumber || v._draft?.plateNumber || '').replace(/\s+/g, '').toUpperCase();
                    if (!plate) continue;
                    const row = await createTruck({
                        supplierAccountId: accountId,
                        plateNumber: plate,
                        model: (v.model || '').trim(),
                        type: (v.type || '').trim(),
                        tonnage: v.tonnage,
                        isScrapHauler: !!v.isScrapHauler
                    });
                    createdVehicles.push(row);
                }
                if (createdVehicles.length) {
                    this.selected.vehicles = [...(this.selected.vehicles || []), ...createdVehicles];
                }
            } catch (e) {
                const msg = this._errToMessage(e);
                this._logError('createTruck', e, { newVehicles });
                throw new Error(`Створення ТЗ: ${msg}`);
            }

            console.log('========CHECK 5========');
            try {
                for (const z of newZones) {
                    const row = await createShippingPoint({
                        supplierId: accountId,
                        name: (z._draft?.name || z.name || '').trim(),
                        city: (z._draft?.city || z.city || '').trim(),
                        address: (z._draft?.address || z.address || '').trim()
                    });
                    this.selected.shippingPoints = [...(this.selected.shippingPoints || []), row];
                }
            } catch (e) {
                const msg = this._errToMessage(e);
                this._logError('createShippingPoint', e, { newZones });
                throw new Error(`Створення адрес: ${msg}`);
            }
            console.log('========CHECK 6========');

            try {
                for (const d of newDrivers) {
                    const p = d._person || {};
                    const row = await createDriver({
                        supplierAccountId: accountId,
                        lastName: p.lastName,
                        firstName: p.firstName,
                        middleName: p.middleName,
                        email: (d._draft?.email || d.email || '').trim(),
                        phone: (d._draft?.phone || null),
                        title: (d._draft?.title || 'Водій'),
                        department: (d._draft?.dept || 'Транспортний відділ')
                    });

                    this.selected.drivers = [...(this.selected.drivers || []), row];
                }
            } catch (e) {
                const msg = this._errToMessage(e);
                this._logError('createDriver', e, { newDrivers });
                throw new Error(`Створення водіїв: ${msg}`);
            }

            console.log('========CHECK 7========');
            try {
                for (const m of newManagers) {
                    const p = m._person || {};
                    const row = await createManager({
                        accountId: accountId,
                        firstName: (p.firstName || '').trim(),
                        middleName: (p.middleName || '').trim(),
                        lastName: (p.lastName || '').trim(),
                        phone: (m._draft?.phone || null),
                        email: (m._draft?.email || m.email || '').trim(),
                        title: (m._draft?.title || 'Директор'),
                        department: (m._draft?.dept || 'Дирекція')
                    });

                    this.selected.managers = [...(this.selected.managers || []), row];
                }
            } catch (e) {
                const msg = this._errToMessage(e);
                this._logError('createManager', e, { newManagers });
                throw new Error(`Створення менеджерів: ${msg}`);
            }

            console.log('========CHECK 8========');
            // ---- 4) Оновити наявні
            try {
                for (const v of vehiclesToUpdate) {
                    await updateTruckBasic({
                        truckId: v.id,
                        plateNumber: (v.plateNumber || '').replace(/\s+/g, '').toUpperCase(),
                        model: v.model || '',
                        type: v.type || '',
                        tonnage: v.tonnage
                    });
                }
            } catch (e) {
                const msg = this._errToMessage(e);
                this._logError('updateTruckBasic', e, { vehiclesToUpdate });
                throw new Error(`Оновлення ТЗ: ${msg}`);
            }
            console.log('========CHECK 9========');
            try {
                for (const z of zonesToUpdate) {
                    await updateShippingPoint({
                        id: z.id,
                        name: z.name ?? null,
                        city: z.city ?? null,
                        address: z.address ?? null
                    });
                }
            } catch (e) {
                const msg = this._errToMessage(e);
                this._logError('updateShippingPoint', e, { zonesToUpdate });
                throw new Error(`Оновлення адрес: ${msg}`);
            }
            console.log('========CHECK 10========');
            try {
                const contactsToUpdate = [...driversToUpdate, ...managersToUpdate];
                for (const c of contactsToUpdate) {
                    await updateContact({
                        contactId:  c.id,
                        firstName:  c.firstName  ?? null,
                        middleName: c.middleName ?? null,
                        lastName:   c.lastName   ?? null,
                        title:      c.title      ?? null,
                        department: c.dept       ?? null,
                        phone:      (c._draft?.phone ?? c.phone ?? null),
                        mobile:     c.mobile     ?? null,
                        email:      c.email      ?? null
                    });
                }
            } catch (e) {
                const msg = this._errToMessage(e);
                this._logError('updateContact', e, { driversToUpdate, managersToUpdate });
                throw new Error(`Оновлення контактів: ${msg}`);
            }
            console.log('========CHECK 11========');
            // ---- 5) Видалення
            try {
                const trucks = Array.from(this.vehiclesMarkedForDelete).filter(id => !this._isTempId(id));
                for (const truckId of trucks) {
                    await unlinkTruckFromSupplier({ truckId, supplierAccountId: accountId });
                }
                if (trucks.length) {
                    this.selected.vehicles = (this.selected.vehicles || []).filter(v => !this.vehiclesMarkedForDelete.has(v.id));
                }

                const zones = Array.from(this.zonesMarkedForDelete).filter(id => !this._isTempId(id));
                for (const zoneId of zones) {
                    await detachShippingPoint({ id: zoneId });
                }
                if (zones.length) {
                    this.selected.shippingPoints = (this.selected.shippingPoints || []).filter(z => !this.zonesMarkedForDelete.has(z.id));
                }

                const contacts = Array.from(this.contactsMarkedForDelete).filter(id => !this._isTempId(id));
                for (const contactId of contacts) {
                    await detachContact({ contactId });
                }
                if (contacts.length) {
                    this.selected.drivers  = (this.selected.drivers  || []).filter(c => !this.contactsMarkedForDelete.has(c.id));
                    this.selected.managers = (this.selected.managers || []).filter(c => !this.contactsMarkedForDelete.has(c.id));
                    this.selected.contacts = (this.selected.contacts || []).filter(c => !this.contactsMarkedForDelete.has(c.id));
                }


                // Локально прибрати видалені
                if (zones.length) {
                    this.selected.shippingPoints = (this.selected.shippingPoints || []).filter(z => !this.zonesMarkedForDelete.has(z.id));
                }
                if (contacts.length) {
                    this.selected.drivers  = (this.selected.drivers  || []).filter(c => !this.contactsMarkedForDelete.has(c.id));
                    this.selected.managers = (this.selected.managers || []).filter(c => !this.contactsMarkedForDelete.has(c.id));
                }
                this.selected = { ...this.selected };
            } catch (e) {
                const msg = this._errToMessage(e);
                this._logError('delete/unlink', e, {
                    vehiclesMarkedForDelete: Array.from(this.vehiclesMarkedForDelete),
                    zonesMarkedForDelete: Array.from(this.zonesMarkedForDelete),
                    contactsMarkedForDelete: Array.from(this.contactsMarkedForDelete)
                });
                throw new Error(`Видалення/відв’язування: ${msg}`);
            }
            console.log('========CHECK 12========');

            // ---- 6) Рефреш з сервера (підтягнути обчислення/контракти)
            try {
                await this.refreshSelectedDetails(accountId);
            } catch (e) {
                const msg = this._errToMessage(e);
                this._logError('refreshSelectedDetails', e, { accountId });
                // не фейлимо весь процес — просто попередимо
                console.warn('Помилка при refreshSelectedDetails:', msg);
            }
            console.log('========CHECK 13========');


            // ---- 7) Done
            this.showEditModal = false;
            this.dispatchEvent(
                new CustomEvent('close', {
                    detail: { refresh: true, cause: 'save' },
                    bubbles: true,
                    composed: true
                })
            );
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Зміни збережено ✅',
                    message: 'Ваші зміни було збережено успішно.',
                    variant: 'success'
                })
            );
        } catch (e) {
            const msg = this._errToMessage(e);
            this._logError('saveEditModal', e);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Помилка збереження',
                    message: msg || 'Сталася помилка під час збереження',
                    variant: 'error'
                })
            );
        } finally {
            this.saving = false;
        }
    };


    // --------- ДОПОМІЖНІ ---------
    async refreshSelectedDetails(accountId) {
        const id = accountId || this.selected?.id;
        if (!id) return;

        const res = await getSupplierDetails({ accountId: id });
        const primaryManager = (res.managers && res.managers.length) ? res.managers[0] : null;
        const contractsView = (res.contracts || []).map(c => ({
            ...c,
            activeClass: c.isActive ? 'status-pill status-green' : 'status-pill status-gray',
            activeLabel: c.isActive ? 'Активний' : 'Не активний'
        }));

        this.selected = {
            ...res,
            contracts: contractsView,
            manager: primaryManager ? primaryManager.name : 'Немає даних',
            address: this._composeAddress(res),
            description: res.description || null,
            activityType: res.activityType || 'Active'
        };
    }


    async _loadSupplier(accountId) {
        if (!accountId) return;
        const res = await getSupplierDetails({ accountId });
        const primaryManager = (res.managers && res.managers.length) ? res.managers[0] : null;
        const contractsView = (res.contracts || []).map(c => ({
            ...c,
            activeClass: c.isActive ? 'status-pill status-green' : 'status-pill status-gray',
            activeLabel: c.isActive ? 'Активний' : 'Не активний'
        }));
        this.selected = {
            ...res,
            contracts: contractsView,
            manager: primaryManager ? primaryManager.name : 'Немає даних',
            address: this._composeAddress(res),
            description: res.description || null,
            activityType: res.activityType || 'Active'
        };
    }

    _composeAddress(src) {
        const parts = [];
        if (src?.billingStreet)     parts.push(src.billingStreet.trim());
        if (src?.billingCity)       parts.push(src.billingCity.trim());
        if (src?.billingState)      parts.push(src.billingState.trim());
        if (src?.billingPostalCode) parts.push(src.billingPostalCode.trim());
        if (src?.billingCountry)    parts.push(src.billingCountry.trim());
        return parts.length ? parts.join(', ') : 'Немає даних';
        // (в selected.address використовується тільки оновлене значення)
    }

    _splitName(full) {
        const parts = (full || '').trim().split(/\s+/).filter(Boolean);
        const lastName   = parts[0] || '';
        const firstName  = parts[1] || '';
        const middleName = parts.slice(2).join(' ') || '';
        return { firstName, middleName, lastName };
    }

    _validateNewContactRow(row) {
        const p = row._person || {};
        const first = (p.firstName || '').trim();
        const last  = (p.lastName  || '').trim();
        const phone = ((row._draft && row._draft.phone) || row.phone || '').trim();

        if (!last || !first || !phone) {
            const missing = [
                !last  ? 'Прізвище' : null,
                !first ? 'Ім’я'     : null,
                !phone ? 'Телефон'  : null
            ].filter(Boolean).join(', ');

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Неможливо зберегти',
                    message: `Заповніть обов’язкові поля: ${missing}.`,
                    variant: 'error'
                })
            );
            return false;
        }
        return true;
    }

    _makeTempId(prefix = 'TMP') {
        return `${prefix}-${Math.random().toString(36).slice(2, 9)}`;
    }

    _isTempId(id) {
        return !!id && (/^(TMP-|Z-|D-|M-|V-)/).test(id);
    }

    _computeRowClass(r) {
        let cls = '';
        if (r._markedForDelete) cls = 'row-marked';
        if (r._isEditing) cls = (cls ? cls + ' ' : '') + 'row-editing';
        if (r._isNew) cls = (cls ? cls + ' ' : '') + 'row-pending';
        return cls;
    }

    _decorate(r) {
        return { ...r, rowClass: this._computeRowClass(r) };
    }

    // ДОДАТИ всередині класу
    _errToMessage(err) {
        try {
            const b = err?.body;

            // 1) Page errors (DmlException, Validation Rules, Duplicate rules)
            if (Array.isArray(b?.pageErrors) && b.pageErrors.length) {
                return b.pageErrors
                    .map(pe => [pe?.statusCode, pe?.message].filter(Boolean).join(': '))
                    .join('; ');
            }

            // 2) Field errors: { fieldApiName: [{message, statusCode}, ...], ... }
            if (b?.fieldErrors && typeof b.fieldErrors === 'object') {
                const msgs = [];
                for (const [field, arr] of Object.entries(b.fieldErrors)) {
                    (arr || []).forEach(e => msgs.push(`${field}: ${e?.message || e}`));
                }
                if (msgs.length) return msgs.join('; ');
            }

            // 3) Масив помилок
            if (Array.isArray(b)) {
                const msgs = b.map(x => x?.message || x).filter(Boolean);
                if (msgs.length) return msgs.join('; ');
            }

            // 4) Рядок або звичайне поле message
            if (typeof b === 'string') return b;
            if (b?.message) return b.message;

            // 5) Заголовок по статусу
            if (err?.status || err?.statusText) {
                return [err.status, err.statusText].filter(Boolean).join(' ');
            }

            // 6) Fallback
            return err?.message || 'Невідома помилка';
        } catch {
            return 'Невідома помилка';
        }
    }

    _logError(tag, err, extra = {}) {
        // максимально докладний лог у консолі, але без падінь
        try {
            // Locker в LWC любить JSON-safe
            // eslint-disable-next-line no-console
            console.error(`[${tag}]`, JSON.parse(JSON.stringify({ err, extra })));
        } catch {
            // eslint-disable-next-line no-console
            console.error(`[${tag}]`, err, extra);
        }
    }

}