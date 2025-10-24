import {LightningElement, track, wire} from 'lwc';

import listSuppliers from '@salesforce/apex/ScrapSupplierAdminService.listSuppliers';
import getSupplierDetails from '@salesforce/apex/ScrapSupplierAdminService.getSupplierDetails';
import createShippingPoint from '@salesforce/apex/ScrapSupplierAdminService.createShippingPoint';
import createDriver from '@salesforce/apex/ScrapSupplierAdminService.createDriver';
import createManager from '@salesforce/apex/ScrapSupplierAdminService.createManager';
import searchAvailableTrucks from '@salesforce/apex/ScrapSupplierAdminService.searchAvailableTrucks';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';

import deleteShippingPoint from '@salesforce/apex/ScrapSupplierAdminService.deleteShippingPoint';
import deleteContact from '@salesforce/apex/ScrapSupplierAdminService.deleteContact';
import updateSupplierMainInfo from '@salesforce/apex/ScrapSupplierAdminService.updateSupplierMainInfo';
import updateShippingPoint from '@salesforce/apex/ScrapSupplierAdminService.updateShippingPoint';
import updateContact from '@salesforce/apex/ScrapSupplierAdminService.updateContact';
import getSupplierMonth from '@salesforce/apex/ScrapSupplierAdminService.getSupplierMonth';

import getSupplierScrapAccessMatrix from '@salesforce/apex/ScrapSupplierAdminService.getSupplierScrapAccessMatrix';
import setSupplierActivity from '@salesforce/apex/ScrapSupplierAdminService.setSupplierActivity';

import createTruck from '@salesforce/apex/ScrapSupplierAdminService.createTruck';
import updateTruckBasic from '@salesforce/apex/ScrapSupplierAdminService.updateTruckBasic';
import unlinkTruckFromSupplier from '@salesforce/apex/ScrapSupplierAdminService.unlinkTruckFromSupplier';



export default class ScrapSupplierInfoPanel extends LightningElement {
    // ----------------- DATA FROM APEX -----------------
    @track supplierTree = { commercial: [], corporate: [] };
    @track selected = null;        // SupplierDetails з Apex
    @track slotsGroups = [];     // [{ymKey, monthLabel, sumDeclared, sumFactual, rows:[...] }]
    @track slotsLoading = false;
    @track slotsError = null;
    // ----------------- STATE -----------------
    @track commercialOpen = true;
    @track nonCommercialOpen = true;
    @track query = '';
    @track selectedId = null;

    // draft forms visibility
    @track showAddZoneForm = false;
    @track showAddDriverForm = false;
    @track showAddManagerForm = false;
    @track showAddVehicleForm = false;

    @track limits = null;

    @track uiActive = true;                // відображення тогла
    @track showConfirmDeactivate = false;  // модалка підтвердження
    _pendingToggleValue = null;            // тимчасове значення

    editVehicles = [];
    vehiclesMarkedForDelete = new Set();

    get editVehiclesRendered() { return (this.editVehicles || []).filter(r => !r._markedForDelete); }
    get editVehiclesEmpty()    { return (this.editVehicles || []).length === 0; }

// ПРАВИЛЬНО (припускаю реальні значення; підстав свої точні):
    get typeOptions() {
        return [
            { label: 'Тягач',  value: 'Truck'  },
            { label: 'Причіп', value: 'Trailer' }
        ];
    }

    @track saving = false; // спінер модалки під час збереження


    _typeLabel(val) {
        const opt = this.typeOptions.find(o => o.value === val);
        return opt ? opt.label : (val || '');
    }

    get monthTitle() {
        const d = new Date();
        const fmt = new Intl.DateTimeFormat('uk-UA', { month: 'long', year: 'numeric' });
        return fmt.format(d).replace(/^\w/, c => c.toUpperCase());
    }

// класи для залишку
    get rem1Class() { return this._remainClass(this.limits?.rem1); }
    get rem2Class() { return this._remainClass(this.limits?.rem2); }
    get rem3Class() { return this._remainClass(this.limits?.rem3); }
    get remMClass() { return this._remainClass(this.limits?.remMonth); }
    _remainClass(v) {
        if (v === 0) return 'cell-zero';
        if (v < 0)  return 'cell-bad';
        return 'cell-ok';
    }

    async loadLimitsCard() {
        try {
            if (!this.selectedId) { this.limits = null; return; }
            const today = new Date();
            const res = await getSupplierMonth({
                supplierId: this.selectedId,
                year:  today.getFullYear(),
                month: today.getMonth() + 1
            });
            this.limits = res;
        } catch (e) {
            this.limits = null; // опційно toast
        }
    }

    // drafts
    zoneDraft = {};
    driverDraft = {};
    managerDraft = {};
    vehicleDraft = {};

    lookupSearchText = '';
    lookupResults = [];
    selectedLookupTruck = null;
    _lookupDebounce;

    @wire(listSuppliers, { query: '$query' })
    wiredSuppliers({ data, error }) {
        if (data) {
            this.supplierTree = {
                commercial: data.commercial || [],
                corporate: data.corporate || []
            };
            console.log('===DATA===')
            console.log(JSON.stringify(data,null,2));
        } else if (error) {
            // опційно: лог
            // console.error(error);
            this.supplierTree = { commercial: [], corporate: [] };
        }
    }


    // ----------------- GETTERS -----------------

    get commercialSorted() {
        return [...(this.supplierTree.commercial || [])].sort((a,b)=> (a.name||'').localeCompare(b.name||'', 'uk'));
    }
    get nonCommercialSorted() {
        return [...(this.supplierTree.corporate || [])].sort((a,b)=> (a.name||'').localeCompare(b.name||'', 'uk'));
    }

    get filteredCommercial() {
        const q = this._normalize(this.query);
        const list = this.commercialSorted;
        return q ? list.filter(s => this._matches(s, q)) : list;
    }
    get filteredNonCommercial() {
        const q = this._normalize(this.query);
        const list = this.nonCommercialSorted;
        return q ? list.filter(s => this._matches(s, q)) : list;
    }

    get contractsEmpty() {
        return !this.selected || !(this.selected.contracts && this.selected.contracts.length);
    }


    get showCommercialEmpty() { return this.filteredCommercial.length === 0; }
    get showNonCommercialEmpty() { return this.filteredNonCommercial.length === 0; }

    supplierItemClass(id){ return `sp-item ${this.selectedId===id ? 'active':''}`; }

    get commercialRendered() {
        return this.commercialSorted.map(s => ({ ...s, className: this.supplierItemClass(s.id) }));
    }
    get nonCommercialRendered() {
        return this.nonCommercialSorted.map(s => ({ ...s, className: this.supplierItemClass(s.id) }));
    }
    get filteredCommercialRendered() {
        return this.filteredCommercial.map(s => ({ ...s, className: this.supplierItemClass(s.id) }));
    }
    get filteredNonCommercialRendered() {
        return this.filteredNonCommercial.map(s => ({ ...s, className: this.supplierItemClass(s.id) }));
    }

    get zonesEmpty()    { return !this.selected || !(this.selected.shippingPoints && this.selected.shippingPoints.length); }
    get driversEmpty()  { return !this.selected || !(this.selected.drivers && this.selected.drivers.length); }
    get managersEmpty() { return !this.selected || !(this.selected.managers && this.selected.managers.length); }
    get vehiclesEmpty() { return !this.selected || !(this.selected.vehicles && this.selected.vehicles.length); }


    get noteText() {
        return (this.selected && this.selected.description && this.selected.description.trim())
            ? this.selected.description
            : 'Немає даних';
    }

    get commercialCaretClass() {
        return `caret ${this.commercialOpen ? 'caret-down' : 'caret-right'}`;
    }

    get nonCommercialCaretClass() {
        return `caret ${this.nonCommercialOpen ? 'caret-down' : 'caret-right'}`;
    }

    // ----------------- EVENTS -----------------
// ---- HELPERS (replace) ----
    _normalize(s) {
        const map = {
            'ё':'е','й':'и','ъ':'','ь':'',
            'є':'е','ї':'і','ґ':'г',
            // рос./укр → латиниця-подібні (щоб термін «ТОВ»/«TOV» теж ловився)
            'а':'a','е':'e','о':'o','р':'p','с':'c','у':'y','х':'x','і':'i','к':'k','т':'t','м':'m','н':'h','в':'b'
        };
        return (s ?? '')
            .toString()
            .toLowerCase()
            .normalize('NFKD')
            .replace(/[\u0300-\u036f]/g, '')
            .replace(/[ёйъьєїґ]/g, ch => ({'ё':'е','й':'и','ъ':'','ь':'','є':'е','ї':'і','ґ':'г'}[ch]))
            .replace(/[аероcухіктмнв]/g, ch => map[ch] ?? ch) // латин-мікси
            .replace(/[^a-z0-9\u0430-\u044f\u0456\u0457\u0454\s]/g, ' ') // зайві знаки → пробіл
            .replace(/\s+/g, ' ')
            .trim();
    }

    _matches(item, q) {
        if (!q) return true;
        const n = this._normalize;
        return (
            n(item?.name).includes(q) ||
            n(item?.zkpo).includes(q) ||
            n(item?.idErp).includes(q)
        );
    }

    _statusClass(status) {
        const s = (status || '').toLowerCase();
        if (s === 'activated' || s === 'active') return 'status-pill status-green';
        if (s === 'draft') return 'status-pill status-gray';
        if (s === 'expired' || s === 'terminated') return 'status-pill status-red';
        return 'status-pill status-blue';
    }


    computeStatusClass(status) {
        const s = (status || '').toLowerCase();
        let cls = 'status-pill';
        if (s === 'activated' || s === 'active') cls += ' status-green';
        else if (s === 'draft') cls += ' status-gray';
        else if (s === 'expired' || s === 'terminated') cls += ' status-red';
        else cls += ' status-blue';
        return cls;
    }


    // ---- SEARCH (keep/debounce) ----
    handleSearch = (e) => {
        const val = (e.target && e.target.value) ? e.target.value : '';
        clearTimeout(this._searchTmr);
        this._searchTmr = setTimeout(() => { this.query = val; }, 200);
    };



    toggleGroup = (e) => {
        const key = e.currentTarget.dataset.key;
        if (key==='commercial')   this.commercialOpen   = !this.commercialOpen;
        if (key==='nonCommercial') this.nonCommercialOpen = !this.nonCommercialOpen;
    };

    selectSupplier = (e) => {
        const id = e.currentTarget.dataset.id;
        this.selectedId = id;
        this.uiActive = true;

        getSupplierDetails({ accountId: id })
            .then(res => {
                console.log('activityType: ' + res.activityType);
                const all = [...(this.supplierTree.commercial || []), ...(this.supplierTree.corporate || [])];
                const hit = all.find(x => x.id === id);
                const typeLabel =
                    hit && hit.type
                        ? (String(hit.type).toUpperCase() === 'COMMERCIAL' ? 'Комерційний'
                            : String(hit.type).toUpperCase() === 'CORPORATE'  ? 'Корпоративний'
                                : hit.type)
                        : null;

                const primaryManager = (res.managers && res.managers.length) ? res.managers[0] : null;

                const contractsView = (res.contracts || []).map(c => ({
                    ...c,
                    activeClass: c.isActive ? 'status-pill status-green' : 'status-pill status-gray',
                    activeLabel: c.isActive ? 'Активний' : 'Не активний'
                }));

                this.selected = {
                    ...res,
                    contracts: contractsView,
                    typeLabel,
                    manager: primaryManager ? primaryManager.name : 'Немає даних',
                    address: res.address ? res.address : 'Немає даних',
                    description: res.description || null,
                    activityType: res.activityType || 'Active'
                };

                console.log('RESULT: ' + JSON.stringify(res,null,2));
            })

            .catch(() => {
                this.selected = null;
            });
        this.loadAvailableTypes();

        this.loadLimitsCard();  // <- додай цей виклик
        // this.loadSlotsHistory(id);

    };

    // toggle forms
    toggleAddZone    = ()=>{ this.showAddZoneForm    = !this.showAddZoneForm; };
    toggleAddDriver  = ()=>{ this.showAddDriverForm  = !this.showAddDriverForm; };
    toggleAddManager = ()=>{ this.showAddManagerForm = !this.showAddManagerForm; };
    toggleAddVehicle = ()=>{ this.showAddVehicleForm = !this.showAddVehicleForm; };


    handleLookupInput = (event) => {
        this.lookupSearchText = event.target.value || '';
        clearTimeout(this._lookupDebounce);
        this._lookupDebounce = setTimeout(() => this.runLookupSearch(), 250);
    };

    async runLookupSearch() {
        if (!this.selected?.id) return;
        const rows = await searchAvailableTrucks({
            supplierAccountId: this.selected.id,
            searchText: this.lookupSearchText,
            rowLimit: 50
        });
        this.lookupResults = rows || [];
    }

    handleLookupPick = (event) => {
        const truckId = event.currentTarget?.dataset?.id;
        const plateNumber = event.currentTarget?.dataset?.plate;
        const picked = (this.lookupResults || []).find(r => r.id === truckId);

        this.selectedLookupTruck = picked || null;
        this.lookupSearchText = plateNumber || '';
        this.lookupResults = [];
        this.isLookupOpen = false;
    };

    // drafts
    handleZoneDraft    = (e)=>{ this.zoneDraft[e.target.dataset.name]    = e.detail.value; };
    handleDriverDraft  = (e)=>{ this.driverDraft[e.target.dataset.name]  = e.detail.value; };
    handleManagerDraft = (e)=>{ this.managerDraft[e.target.dataset.name] = e.detail.value; };
    handleVehicleDraft = (e)=>{ this.vehicleDraft[e.target.dataset.name] = e.detail.value; };

    // ----------------- helpers -----------------
    _cloneSelected(){
        const s = this.selected;
        return JSON.parse(JSON.stringify(s));
    }
    _writeBackSelected(s){
        const listKey = s.type==='commercial' ? 'commercial' : 'nonCommercial';
        const list = [...this.suppliersAll[listKey]];
        const idx = list.findIndex(x=>x.id===s.id);
        list[idx] = s;
        this.suppliersAll = { ...this.suppliersAll, [listKey]: list };
    }

    saveZone = () => {
        if (!this.selected) return;
        const d = this.zoneDraft || {};
        const name = (d.zoneName || '').trim();
        const city = (d.zoneCity || '').trim();
        const address = (d.zoneAddress || '').trim();

        if (!name || !city || !address) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Помилка',
                message: 'Назва, місто та адреса обов’язкові',
                variant: 'error'
            }));
            return;
        }

        createShippingPoint({
            supplierId: this.selected.id,
            name: name,
            city: city,
            address: address
        })
            .then(sp => {
                this.selected.shippingPoints = [...(this.selected.shippingPoints || []), sp];
                this.zoneDraft = {};
                this.showAddZoneForm = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Створено ✅',
                        message: 'Нове місце завантаження успішно додано.',
                        variant: 'success'
                    })
                );

            })
            .catch(e => {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Помилка',
                    message: e.body ? e.body.message : e.message,
                    variant: 'error'
                }));
            });
    };

    saveDriver = () => {
        if (!this.selected) return;
        const d = this.driverDraft || {};

        const lastName   = (d.driverLastName || '').trim();
        const firstName  = (d.driverFirstName || '').trim();
        const middleName = (d.driverMiddleName || '').trim();
        const phone      = (d.driverPhone || '').trim();
        const email      = (d.driverEmail || '').trim();

        if (!lastName || !firstName || !phone) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Помилка',
                message: 'Прізвище, Ім’я та Телефон обов’язкові',
                variant: 'error'
            }));
            return;
        }

        createDriver({
            supplierAccountId: this.selected.id,
            lastName: lastName,
            firstName: firstName,
            middleName: middleName,
            email: email,
            phone: phone
        })
            .then(driverRow => {
                this.selected.drivers = [...(this.selected.drivers || []), driverRow];
                this.driverDraft = {};
                this.showAddDriverForm = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Створено ✅',
                        message: 'Нового водія успішно додано.',
                        variant: 'success'
                    })
                );

            })
            .catch(e => {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Помилка',
                    message: e?.body?.message || e?.message || 'Сталася помилка',
                    variant: 'error'
                }));
            });
    };

    saveManager = () => {
        if (!this.selectedId) return;

        const lastName  = (this.managerDraft.lastName || '').trim();
        const firstName = (this.managerDraft.firstName || '').trim();
        const middleName= (this.managerDraft.middleName || '').trim();
        const phone     = (this.managerDraft.phone || '').trim();
        const email     = (this.managerDraft.email || '').trim();

        if (!lastName || !firstName) {
            // опційно: toast/повідомлення
            return;
        }

        createManager({
            accountId: this.selectedId,
            firstName,
            middleName,
            lastName,
            phone,
            email
        })
            .then((row) => {
                // локально оновлюємо, щоб не впиратися в кеш
                const clone = this._cloneSelected();
                clone.managers = [...(clone.managers || []), row];
                this.selected = clone;

                this._updateHeaderFromSelected();
                this.selected = { ...this.selected };

                this.managerDraft = {};
                this.showAddManagerForm = false;
            })
            .catch(() => {
                // опційно: лог/toast
            });
    };


//     Для модального вікна

    // Модалка
    showEditModal = false;

// Робочі копії для модалки (щоб не чіпати this.selected поки не «Зберегти»)
    editZones = [];
    editDrivers = [];
    editManagers = [];

// Набори позначених на видалення (Id)
    zonesMarkedForDelete = new Set();
    contactsMarkedForDelete = new Set();

// Відкрити/закрити
    openEditModal = () => {
        if (!this.selected) return;

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

        this.editVehicles = (this.selected.vehicles || []).map(v => this._decorate({
            ...v,
            _isNew: false,
            _isEditing: false,
            _dirty: false,
            _markedForDelete: false,
            _draft: {
                plateNumber: v.plateNumber || '',
                model:       v.model || '',
                type:        v.type || '',
                tonnage:     v.tonnage ?? null,
            },
            showDeleteIcon: true,
            showReturnIcon: false
        }));

        this.vehiclesMarkedForDelete = new Set();


// ЗАМІНИТИ функцію toRow всередині openEditModal:
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


        this.editZones    = (this.selected.shippingPoints || []).map(toRow);
        this.editDrivers  = (this.selected.drivers || []).map(toRow);
        this.editManagers = (this.selected.managers || []).map(toRow);

        this.zonesMarkedForDelete = new Set();
        this.contactsMarkedForDelete = new Set();
        this.showEditModal = true;
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

    closeEditModal = () => { this.showEditModal = false; };


    // ЗАМІНИТИ toggleMarkRemove повністю
    toggleMarkRemove = (event) => {
        const type = event.currentTarget.dataset.type; // 'zone'|'driver'|'manager'|'vehicle'
        const id   = event.currentTarget.dataset.id;

        const handle = (arr, set) => {
            const row = (arr || []).find(r => r.id === id);
            if (!row) return arr;

            if (row._isNew || this._isTempId(id)) {
                return (arr || []).filter(r => r.id !== id);
            }

            const mark = !set.has(id);
            if (mark) set.add(id); else set.delete(id);

            return (arr || []).map(r => r.id === id
                ? this._decorate({ ...r, _markedForDelete: mark, showDeleteIcon: !mark, showReturnIcon: mark })
                : r
            );
        };

        if (type === 'zone')    this.editZones    = handle(this.editZones,    this.zonesMarkedForDelete);
        if (type === 'driver')  this.editDrivers  = handle(this.editDrivers,  this.contactsMarkedForDelete);
        if (type === 'manager') this.editManagers = handle(this.editManagers, this.contactsMarkedForDelete);
        if (type === 'vehicle') this.editVehicles = handle(this.editVehicles, this.vehiclesMarkedForDelete);
    };

    saveEditModal = async () => {
        if (this.saving) return;      // запобігає повторним клікам
        this.saving = true;

        try {
            const updated = await updateSupplierMainInfo({
                accountId: this.selected.id,
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
            // локально оновити selected
            this.selected = {
                ...this.selected,
                name: updated.Name,
                phone: updated.Phone,
                email: updated.Email__c,
                description: updated.Description,
                billingStreet: updated.BillingStreet,
                billingCity: updated.BillingCity,
                billingState: updated.BillingState,
                billingPostalCode: updated.BillingPostalCode,
                billingCountry: updated.BillingCountry
            };

            // CHANGE in saveEditModal = async () => { ... }
            const newZones = (this.editZones || [])
                .filter(z => z._isNew && z._newCommitted && !this.zonesMarkedForDelete.has(z.id));

            const newDrivers = (this.editDrivers || [])
                .filter(d => d._isNew && d._newCommitted && !this.contactsMarkedForDelete.has(d.id));

            const newManagers = (this.editManagers || [])
                .filter(m => m._isNew && m._newCommitted && !this.contactsMarkedForDelete.has(m.id));

            const newVehicles = (this.editVehicles || [])
                .filter(v => v._isNew && v._newCommitted && !this.vehiclesMarkedForDelete.has(v.id));
            const vehiclesToUpdate = (this.editVehicles || [])
                .filter(v => v._dirty && !v._isNew && !this.vehiclesMarkedForDelete.has(v.id));


            const zonesToUpdate    = (this.editZones   || []).filter(z => z._dirty && !z._isNew && !this.zonesMarkedForDelete.has(z.id));
            const driversToUpdate  = (this.editDrivers || []).filter(c => c._dirty && !c._isNew && !this.contactsMarkedForDelete.has(c.id));
            const managersToUpdate = (this.editManagers|| []).filter(c => c._dirty && !c._isNew && !this.contactsMarkedForDelete.has(c.id));
// 0) СТВОРЕННЯ нових у БД

            const createdVehicles = [];
            for (const v of newVehicles) {
                const plate = (v.plateNumber || v._draft?.plateNumber || '').replace(/\s+/g, '');
                if (!plate) continue; // або кинути помилку/тост
                const row = await createTruck({
                    supplierAccountId: this.selected.id,
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

            for (const v of vehiclesToUpdate) {
                await updateTruckBasic({
                    truckId: v.id,
                    plateNumber: (v.plateNumber || '').replace(/\s+/g, ''),
                    model: v.model || '',
                    type:  v.type  || '',
                    tonnage: v.tonnage
                });
            }

            const createdZones = [];
            for (const z of newZones) {
                const row = await createShippingPoint({
                    supplierId: this.selected.id,
                    name: (z._draft?.name || z.name || '').trim(),
                    city: (z._draft?.city || z.city || '').trim(),
                    address: (z._draft?.address || z.address || '').trim()
                });
                createdZones.push(row);
            }
            const createdDrivers = [];
            for (const d of newDrivers) {
                const p = d._person || {};
                const row = await createDriver({
                    supplierAccountId: this.selected.id,
                    lastName: (p.lastName || '').trim(),
                    firstName: (p.firstName || '').trim(),
                    middleName: (p.middleName || '').trim(),
                    email: (d._draft?.email || d.email || '').trim(),
                    phone: (d._draft?.phone || d.phone || '').trim()
                });
                createdDrivers.push(row);
            }
            const createdManagers = [];
            for (const m of newManagers) {
                const p = m._person || {};
                const row = await createManager({
                    accountId: this.selected.id,
                    firstName: (p.firstName || '').trim(),
                    middleName: (p.middleName || '').trim(),
                    lastName: (p.lastName || '').trim(),
                    phone: (m._draft?.phone || m.phone || '').trim(),
                    email: (m._draft?.email || m.email || '').trim()
                });
                createdManagers.push(row);
            }

            // 0.1) Локально додати створені до selected.*
            if (createdZones.length)   this.selected.shippingPoints = [...(this.selected.shippingPoints||[]), ...createdZones];
            if (createdDrivers.length) this.selected.drivers        = [...(this.selected.drivers||[]),        ...createdDrivers];
            if (createdManagers.length)this.selected.managers       = [...(this.selected.managers||[]),       ...createdManagers];

            // ДАЛІ — твоя існуюча логіка:
            // 1) updateShippingPoint(...) для zonesToUpdate
            // 2) updateContact(...) для contactsToUpdate
            // 3) deleteShippingPoint(...) + deleteContact(...)
            // 4) локальний фільтр видалених

            // 1) ОНОВИТИ відредаговані ЗОНИ (які НЕ позначені на видалення)
            // const zonesToUpdate   = (this.editZones || []).filter(z => z._dirty && !z._isNew && !this.zonesMarkedForDelete.has(z.id));
            // const driversToUpdate = (this.editDrivers || []).filter(c => c._dirty && !c._isNew && !this.contactsMarkedForDelete.has(c.id));
            // const managersToUpdate= (this.editManagers || []).filter(c => c._dirty && !c._isNew && !this.contactsMarkedForDelete.has(c.id));

            for (const z of zonesToUpdate) {
                await updateShippingPoint({
                    id: z.id,
                    name:    z.name ?? null,
                    city:    z.city ?? null,
                    address: z.address ?? null
                });
            }

            const contactsToUpdate = [...driversToUpdate, ...managersToUpdate];

            for (const c of contactsToUpdate) {
                // НЕ дозволяємо редагувати ПІБ і відділ для водіїв — їх просто не відправляємо
                await updateContact({
                    contactId:  c.id,
                    firstName:  c.firstName  ?? null,   // для менеджера ок; для водія — просто не буде змін, бо disabled в UI
                    middleName: c.middleName ?? null,
                    lastName:   c.lastName   ?? null,
                    title:      c.title      ?? null,
                    department: c.dept       ?? null,   // для водія disabled => не зміниться
                    phone:      c.phone      ?? null,
                    mobile:     c.mobile     ?? null,
                    email:      c.email      ?? null
                });
            }

            const trucks = Array.from(this.vehiclesMarkedForDelete).filter(id => !this._isTempId(id));
            for (const truckId of trucks) {
                await unlinkTruckFromSupplier({
                    truckId,
                    supplierAccountId: this.selected.id
                });
            }
            if (trucks.length) {
                this.selected.vehicles = (this.selected.vehicles || []).filter(v => !this.vehiclesMarkedForDelete.has(v.id));
            }

            // У saveEditModal ПЕРЕД циклом deleteShippingPoint:
            const zones = Array.from(this.zonesMarkedForDelete)
                .filter(id => !this._isTempId(id));              // ← додати фільтр
            for (const zoneId of zones) {
                await deleteShippingPoint({ id: zoneId });
            }

// І для контактів:
            const contacts = Array.from(this.contactsMarkedForDelete)
                .filter(id => !this._isTempId(id));              // ← додати фільтр
            for (const contactId of contacts) {
                await deleteContact({ contactId });
            }

            // 1) Видалити позначені Місця
            // const zones = Array.from(this.zonesMarkedForDelete);
            //
            // for (const zoneId of zones) {
            //     await deleteShippingPoint({ id: zoneId });
            // }
            //
            // // 2) Видалити позначені Контакти (водії/менеджери)
            // const contacts = Array.from(this.contactsMarkedForDelete);
            // for (const contactId of contacts) {
            //     await deleteContact({ contactId });
            // }

            // 3) Локально оновити this.selected (без додаткового SOQL-запиту)
            if (zones.length) {
                this.selected.shippingPoints = (this.selected.shippingPoints || []).filter(z => !this.zonesMarkedForDelete.has(z.id));
            }
            if (contacts.length) {
                this.selected.drivers  = (this.selected.drivers  || []).filter(c => !this.contactsMarkedForDelete.has(c.id));
                this.selected.managers = (this.selected.managers || []).filter(c => !this.contactsMarkedForDelete.has(c.id));
            }
            this.selected = { ...this.selected }; // тригер перерендеру

            await this.refreshSelectedDetails();   // ← ключове

            this.showEditModal = false;

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Зміни збережено ✅',
                    message: 'Ваші зміни було збережено успішно.',
                    variant: 'success'
                })
            );

        } catch (e) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Помилка збереження',
                message: e?.body?.message || e?.message || 'Сталася помилка під час збереження',
                variant: 'error'
            }));
        } finally {
            this.saving = false;        // ← сховати спінер (модалка або ще відкрита при помилці, або вже закрита при успіху)
        }
    };

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


    handleMainInputChange = (event) => {
        const fieldName = event.target.dataset.name; // 'name' | 'phone' | 'email' | 'description'
        const fieldValue = event.detail.value;
        this.editedMain = { ...this.editedMain, [fieldName]: fieldValue };
    };

    _composeAddress(src) {
        const parts = [];
        if (src?.billingStreet)     parts.push(src.billingStreet.trim());
        if (src?.billingCity)       parts.push(src.billingCity.trim());
        if (src?.billingState)      parts.push(src.billingState.trim());
        if (src?.billingPostalCode) parts.push(src.billingPostalCode.trim());
        if (src?.billingCountry)    parts.push(src.billingCountry.trim());
        return parts.length ? parts.join(', ') : 'Немає даних';
    }

    async refreshSelectedDetails() {
        if (!this.selectedId) return;

        const res = await getSupplierDetails({ accountId: this.selectedId });

        const all = [...(this.supplierTree.commercial || []), ...(this.supplierTree.corporate || [])];
        const hit = all.find(x => x.id === this.selectedId);

        const typeLabel =
            hit && hit.type
                ? (String(hit.type).toUpperCase() === 'COMMERCIAL' ? 'Комерційний'
                    : String(hit.type).toUpperCase() === 'CORPORATE'  ? 'Корпоративний'
                        : hit.type)
                : null;

        const primaryManager = (res.managers && res.managers.length) ? res.managers[0] : null;

        // якщо ти формуєш contractsView з класами, не забудь застосувати тут теж
        const contractsView = (res.contracts || []).map(c => ({
            ...c,
            activeClass: c.isActive ? 'status-pill status-green' : 'status-pill status-gray',
            activeLabel: c.isActive ? 'Активний' : 'Не активний'
        }));

        this.selected = {
            ...res,
            contracts: contractsView,
            typeLabel,
            manager: primaryManager ? primaryManager.name : 'Немає даних',
            address: this._composeAddress(res),
            description: res.description || null,
            activityType: res.activityType || 'Active'
        };
    }

    _updateHeaderFromSelected() {
        const primaryManager = (this.selected?.managers && this.selected.managers.length) ? this.selected.managers[0] : null;
        this.selected = {
            ...this.selected,
            manager: primaryManager ? primaryManager.name : 'Немає даних',
            address: this._composeAddress(this.selected) // якщо _composeAddress вже є
        };
    }

    startRowEdit = (event) => {
        const type = event.currentTarget.dataset.type;
        const id   = event.currentTarget.dataset.id;

        const arm = (arr, toDraft) => arr.map(r => {
            if (r.id !== id) return r;
            return this._decorate({
                ...r,
                _isEditing: true,
                _draft: toDraft(r)   // локальна копія полів для інпутів
            });
        });

        if (type === 'zone')    this.editZones    = arm(this.editZones, r => ({ name: r.name || '', city: r.city || '', address: r.address || '' }));
        // if (type === 'driver')  this.editDrivers  = arm(this.editDrivers, r => ({ title: r.title || '', dept: r.dept || '', phone: r.phone || '', email: r.email || '' }));
        // if (type === 'manager') this.editManagers = arm(this.editManagers, r => ({ title: r.title || '', dept: r.dept || '', phone: r.phone || '', email: r.email || '' }));

// У startRowEdit ЗАМІНИТИ гілки для driver та manager:

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
        }

        if (type === 'vehicle') {
            const arm = (arr, toDraft) => arr.map(r => r.id === id
                ? this._decorate({ ...r, _isEditing: true, _draft: toDraft(r) })
                : r
            );
            this.editVehicles = arm(this.editVehicles, r => ({
                plateNumber: r.plateNumber || '',
                model:       r.model || '',
                type:        r.type || '',
                tonnage:     r.tonnage ?? null
            }));
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
        }


    };



    cancelRowEdit = (event) => {
        const type = event.currentTarget.dataset.type;
        const id   = event.currentTarget.dataset.id;

        // CHANGE in cancelRowEdit()
// CHANGE in cancelRowEdit
        const disarm = (arr) => arr
            .map(r => r.id === id
                ? this._decorate({ ...r, _isEditing:false, _draft: undefined })
                : r)
            // якщо новий і ще НЕ застейджений — прибираємо з таблиці
            .filter(r => !(r.id === id && r._isNew && !r._newCommitted));



        if (type === 'zone')    this.editZones    = disarm(this.editZones);
        if (type === 'driver')  this.editDrivers  = disarm(this.editDrivers);
        if (type === 'manager') this.editManagers = disarm(this.editManagers);
        if (type === 'vehicle') {
            const disarm = (arr) => arr
                .map(r => r.id === id ? this._decorate({ ...r, _isEditing:false, _draft: undefined }) : r)
                .filter(r => !(r.id === id && r._isNew && !r._newCommitted));
            this.editVehicles = disarm(this.editVehicles);
            return;
        }

    };


// універсальний onChange для інпутів у рядках модалки
    handleRowDraftInput = (event) => {
        const rowType   = event.currentTarget.dataset.type; // 'zone' | 'driver' | 'manager'
        const rowId     = event.currentTarget.dataset.id;   // Id рядка
        const fieldName = event.target.dataset.name;        // 'name'|'city'|'address'|'title'|'phone'|'email'|...
        const value     = event.detail.value;

        const patch = (arr) => arr.map(r => {
            if (r.id !== rowId) return r;
            const nextDraft = { ...(r._draft || {}), [fieldName]: value };
            return this._decorate({ ...r, _draft: nextDraft });
        });

        if (rowType === 'zone')    this.editZones    = patch(this.editZones);
        if (rowType === 'driver')  this.editDrivers  = patch(this.editDrivers);
        if (rowType === 'manager') this.editManagers = patch(this.editManagers);
        if (rowType === 'vehicle') {
            let v = value;
            if (fieldName === 'plateNumber' && typeof v === 'string') v = v.replace(/\s+/g, ''); // ← без пробілів
            if (fieldName === 'tonnage') v = (v === '' || v === null) ? null : Number(v);

            this.editVehicles = (this.editVehicles || []).map(r => {
                if (r.id !== rowId) return r;
                const nextDraft = { ...(r._draft || {}), [fieldName]: v };
                return this._decorate({ ...r, _draft: nextDraft, _dirty: true });
            });
            return;
        }

    };

    _decorate(r){
        return { ...r, rowClass: this._computeRowClass(r) };
    }

    handleRowEdit = (e) => {
        const type = e.currentTarget.dataset.type, id = e.currentTarget.dataset.id;
        const setEditing = (arr) => arr.map(r => r.id===id ? this._decorate({ ...r, _isEditing:true }) : r);
        if (type==='zone') this.editZones = setEditing(this.editZones);
        if (type==='driver') this.editDrivers = setEditing(this.editDrivers);
        if (type==='manager') this.editManagers = setEditing(this.editManagers);
    };

    handleRowCancel = (e) => {
        const type = e.currentTarget.dataset.type, id = e.currentTarget.dataset.id;
        // Повертаємо draft до поточного збереженого стану рядка і вимикаємо редагування
        const cancel = (arr) => arr.map(r => {
            if (r.id !== id) return r;
            return this._decorate({ ...r, _isEditing:false, _draft:{ ...r } });
        });
        if (type==='zone')    this.editZones    = cancel(this.editZones);
        if (type==='driver')  this.editDrivers  = cancel(this.editDrivers);
        if (type==='manager') this.editManagers = cancel(this.editManagers);
    };

// onChange інпутів у рядку
    handleRowFieldChange = (e) => {
        const type = e.currentTarget.dataset.type;
        const id   = e.currentTarget.dataset.id;
        const name = e.target.dataset.name;     // наприклад 'title' | 'phone' | 'city'
        const val  = e.detail.value;

        const patch = (arr) => arr.map(r => {
            if (r.id !== id) return r;
            const upd = { ...r, [name]: val };
            return this._decorate(upd);
        });

        if (type==='zone') this.editZones = patch(this.editZones);
        if (type==='driver') this.editDrivers = patch(this.editDrivers);
        if (type==='manager') this.editManagers = patch(this.editManagers);
    };

    handleRowSave = (event) => {
        const type = event.currentTarget.dataset.type;
        const id   = event.currentTarget.dataset.id;

        // знайти поточний рядок
        const arr = type === 'zone' ? this.editZones
            : type === 'driver' ? this.editDrivers
                : this.editManagers;
        const row = (arr || []).find(r => r.id === id);

        // Валідація лише для нових водіїв/менеджерів
        if ((type === 'driver' || type === 'manager') && row && row._isNew) {
            if (!this._validateNewContactRow(row)) return; // стоп, якщо не валідно
        }

        if (type === 'vehicle') {
            const commit = (arr) => arr.map(r => {
                if (r.id !== id) return r;

                // Мерджимо драфт у рядок
                const merged = { ...r, ...r._draft, _isEditing:false, _dirty:true };
                // Гарантовано чистимо пробіли у plateNumber
                merged.plateNumber = (merged.plateNumber || '').replace(/\s+/g, '');
                if (r._isNew) merged._newCommitted = true;

                merged._draft = { ...merged };
                return this._decorate(merged);
            });
            this.editVehicles = commit(this.editVehicles);
            return;
        }


        // CHANGE in handleRowSave
        const commit = (arr, rowType) => arr.map(r => {
            if (r.id !== id) return r;
            const merged = { ...r, ...r._draft, _isEditing:false, _dirty:true };

            // У commit() ПІСЛЯ const merged = { ...r, ...r._draft, _isEditing:false, _dirty:true };
            if (!r._isNew && (rowType === 'driver' || rowType === 'manager')) {
                const parts = [merged.lastName, merged.firstName, merged.middleName].filter(Boolean);
                merged.name = parts.join(' ').trim();
            }

            if (r._isNew) {
                merged._newCommitted = true; // NEW ← тепер цей новий врахується при головному «Зберегти»
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
        if (type === 'manager') this.editManagers = commit(this.editManagers,'manager');

    };

// NEW: тимчасові id для нових рядків у модалці
    _makeTempId(prefix = 'TMP') {
        return `${prefix}-${Math.random().toString(36).slice(2, 9)}`;
    }

// CHANGE: підсвітка «чернеток» у модалці
    _computeRowClass(r){
        let cls = '';
        if (r._markedForDelete) cls = 'row-marked';
        if (r._isEditing) cls = (cls ? cls + ' ' : '') + 'row-editing';
        if (r._isNew) cls = (cls ? cls + ' ' : '') + 'row-pending'; // NEW
        return cls;
    }

// NEW: додати нове місце завантаження у модалці (локально)
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

    // ДОДАТИ
    _isTempId(id){
        return !!id && (/^(TMP-|Z-|D-|M-|V-)/).test(id);  // ← додали V-
    }

    vehUnlink = async (e) => {
        const id = e.currentTarget?.dataset?.id;
        if (!id || !this.selected?.id) return;
        try {
            await unlinkTruckFromSupplier({ truckId: id, supplierAccountId: this.selected.id });
            this.selected.vehicles = (this.selected.vehicles || []).filter(v => v.id !== id);
            this.dispatchEvent(new ShowToastEvent({
                title: 'Відв’язано',
                message: 'Транспортний засіб відв’язано від постачальника.',
                variant: 'success'
            }));
        } catch (err) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Помилка',
                message: err?.body?.message || err?.message || 'Не вдалося відв’язати транспортний засіб.',
                variant: 'error'
            }));
        }
    };


// NEW: додати нового водія у модалці (локально)
    addDriverInModal = () => {
        const id = this._makeTempId('D');
        const row = this._decorate({
            id,
            name: '', // формується з ПІБ після збереження
            title: 'Водій',
            dept: 'Транспортний відділ',
            phone: '',
            email: '',
            // окремі поля для createDriver:
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

// NEW: додати нового менеджера у модалці (локально)
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

    // NEW: хендлери для ПІБ у нових контактів у модалці
    handlePersonNameDraft = (event) => {
        const type = event.currentTarget.dataset.type; // 'driver' | 'manager'
        const id   = event.currentTarget.dataset.id;
        const nameKey = event.target.dataset.name;     // 'firstName' | 'lastName' | 'middleName'
        const val  = event.detail.value;

        const patch = (arr) => arr.map(r => {
            if (r.id !== id) return r;
            const person = { ...(r._person || {}), [nameKey]: val };
            return this._decorate({ ...r, _person: person, _dirty: true });
        });

        if (type === 'driver')  this.editDrivers  = patch(this.editDrivers);
        if (type === 'manager') this.editManagers = patch(this.editManagers);
    };

    // NEW: валідація ПІБ+телефону для нових водіїв/менеджерів у модалці
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

            this.dispatchEvent(new ShowToastEvent({
                title: 'Неможливо зберегти',
                message: `Заповніть обов’язкові поля: ${missing}.`,
                variant: 'error'
            }));
            return false;
        }
        return true;
    }

    // ДОДАТИ в клас:
    _splitName(full) {
        const parts = (full || '').trim().split(/\s+/).filter(Boolean);
        const lastName   = parts[0] || '';
        const firstName  = parts[1] || '';
        const middleName = parts.slice(2).join(' ') || '';
        return { firstName, middleName, lastName };
    }

    // Відкрити обидві групи
    expandAll = () => {
        this.commercialOpen = true;
        this.nonCommercialOpen = true;
    };

// Закрити обидві групи
    collapseAll = () => {
        this.commercialOpen = false;
        this.nonCommercialOpen = false;
    };

// (опц.) стани для дизейблу кнопок
    get allOpened() { return this.commercialOpen && this.nonCommercialOpen; }
    get allCollapsed() { return !this.commercialOpen && !this.nonCommercialOpen; }

    @track availableTypes = [];   // [{id,name,code,groupName,permitted,active}]
    @track typesLoading   = false;
    @track typesError     = null;
    @track scrapSearch    = '';

    get typesEmpty() { return !(this.availableTypes && this.availableTypes.length); }

    get filteredAvailableTypes() {
        const q = this._normalize(this.scrapSearch);

        // 1) лишаємо тільки активні та дозволені
        const base = (this.availableTypes || []).filter(t => t.active === true && t.permitted === true);

        // 2) застосовуємо пошук
        if (!q) return base;
        const n = this._normalize.bind(this);
        return base.filter(t =>
            n(t.name).includes(q) || n(t.code).includes(q) || n(t.groupName).includes(q)
        );
    }


    handleScrapSearch = (e) => {
        const val = (e.target && e.target.value) ? e.target.value : '';
        clearTimeout(this._scrapTmr);
        this._scrapTmr = setTimeout(() => { this.scrapSearch = val; }, 200);
    };

    async loadAvailableTypes() {
        this.typesLoading = true;
        this.typesError = null;
        this.availableTypes = [];
        try {
            if (!this.selectedId) { this.typesLoading = false; return; }
            console.log('getSupplierScrapAccessMatrix: ' + this.selectedId);
            const rows = await getSupplierScrapAccessMatrix({ accountId: this.selectedId });
            console.log('rows: ' + JSON.stringify(rows,null,2));
            this.availableTypes = (rows || []).map(r => {
                const permitted = r.permitted === true;
                const active    = r.active === true;
                return {
                    id:        r.id,
                    name:      r.name,
                    code:      r.code,
                    groupName: r.groupName,
                    permitted,
                    active,
                    permittedClass: permitted ? 'status-pill status-green' : 'status-pill status-red',
                    permittedLabel: permitted ? 'Дозволено'               : 'Заборонено',
                    activeClass:    active    ? 'status-pill status-green' : 'status-pill status-gray',
                    activeLabel:    active    ? 'Активний'                 : 'Неактивний'
                };
            });

        } catch (e) {
            this.typesError = e;
        } finally {
            this.typesLoading = false;
        }
    }

    get hasFilteredTypes() {
        return (this.filteredAvailableTypes && this.filteredAvailableTypes.length > 0);
    }

    handleActiveToggleChange = (e) => {
        const nextVal = e.detail.checked === true;

        if (!nextVal) {
            // користувач клацнув "вимкнути"
            this._pendingToggleValue = false;
            this.showConfirmDeactivate = true;
        } else {
            // якщо хтось клацнув "увімкнути" — повертаємо назад,
            // бо активувати в UI не дозволено
            this.uiActive = true;
        }
    };

    async applyActivity(activityValue) {
        if (!this.selected?.id) return;
        try {
            await setSupplierActivity({
                accountId: this.selected.id,
                newActivityType: activityValue
            });

            if (this.selected) {
                this.selected.activityType = activityValue;
            }
            this.uiActive = (activityValue === 'Active' || activityValue === 'Potential');

            if (activityValue === 'Inactive') {
                // 🔴 Видаляємо зі списку
                const removeFrom = (arr) => (arr || []).filter(x => x.id !== this.selectedId);
                this.supplierTree = {
                    commercial: removeFrom(this.supplierTree.commercial),
                    corporate: removeFrom(this.supplierTree.corporate)
                };

                // 🔴 Закриваємо праву панель
                this.selectedId = null;
                this.selected = null;
            }

            this.dispatchEvent(new ShowToastEvent({
                title: activityValue === 'Inactive' ? 'Деактивовано' : 'Активовано',
                message: activityValue === 'Inactive'
                    ? 'Постачальника деактивовано. Активувати зможе лише адміністратор.'
                    : 'Постачальника активовано.',
                variant: 'success'
            }));
        } catch (e) {
            // відкотити тогл у попередній стан
            this.uiActive = (this.selected?.activityType === 'Active' || this.selected?.activityType === 'Potential');
            this.dispatchEvent(new ShowToastEvent({
                title: 'Не вдалося змінити активність',
                message: e?.body?.message || e?.message || 'Сталася помилка при зміні Activity_Type__c.',
                variant: 'error'
            }));
        } finally {
            this._pendingToggleValue = null;
            this.showConfirmDeactivate = false;
        }
    }


    confirmDeactivate = () => {
        this.showConfirmDeactivate = false;
        this.applyActivity('Inactive');
        this._pendingToggleValue = null;
    };

    cancelDeactivate = () => {
        this.showConfirmDeactivate = false;

        // 1) джерело істини
        this.uiActive = true;
        this._pendingToggleValue = null;

        // 2) синхронізувати сам інпут (після render)
        Promise.resolve().then(() => {
            const t = this.template.querySelector('.active-toggle');
            if (t) t.checked = true;         // повертаємо повзунок
        });
    };
// (за бажанням так само для зон/менеджерів)


    get editZonesRendered()    { return (this.editZones    || []).filter(r => !r._markedForDelete); }
    get editDriversRendered()  { return (this.editDrivers  || []).filter(r => !r._markedForDelete); }
    get editManagersRendered() { return (this.editManagers || []).filter(r => !r._markedForDelete); }

    get editZonesEmpty()    { return (this.editZones    || []).length === 0; }
    get editDriversEmpty()  { return (this.editDrivers  || []).length === 0; }
    get editManagersEmpty() { return (this.editManagers || []).length === 0; }

    vehCreateOpen = false;
    vehNew = {
        plate: '',
        model: '',
        type: '',
        tonnage: null,
        isScrapHauler: false
    };

    get vehCreateDisabled() {
        return !this.vehNew.plate || !this.vehNew.plate.trim();
    }

// --- UI toggle ---
    vehToggleCreate = () => {
        this.vehCreateOpen = !this.vehCreateOpen;
    };

// --- draft полів форми ---
    vehNewDraft = (e) => {
        const name = e.target?.dataset?.name;
        if (!name) return;

        // ✅ окремо обробляємо чекбокс
        if (name === 'isScrapHauler') {
            this.vehNew.isScrapHauler = !!(e.detail?.checked ?? e.target?.checked);
            return;
        }

        const val = e.detail?.value ?? e.target?.value;

        if (name === 'tonnage') {
            const num = Number(val);
            this.vehNew.tonnage = Number.isFinite(num) ? num : null;
        } else {
            this.vehNew[name] = (val ?? '').toString();
        }
    };


// --- створення і додавання ---
    vehCreate = async () => {
        if (this.vehCreateDisabled) return;
        if (!this.selected?.id) {                // ← див. пункт 2
            this.dispatchEvent(new ShowToastEvent({
                title: 'Не вибрано постачальника',
                message: 'Спочатку оберіть постачальника у списку зліва.',
                variant: 'error'
            }));
            return;
        }

        try {
            const cleanPlate = (this.vehNew.plate || '').replace(/\s+/g, '');
            const tonnage = Number.isFinite(this.vehNew.tonnage) ? this.vehNew.tonnage : null;
            const isScrap = !!this.vehNew.isScrapHauler;

            const v = await createTruck({
                supplierAccountId: this.selected.id,
                plateNumber: cleanPlate,
                model: (this.vehNew.model || '').trim(),
                type:  (this.vehNew.type  || '').trim(),
                tonnage: tonnage,
                isScrapHauler: isScrap
            });

            const next = Array.isArray(this.selected.vehicles) ? [...this.selected.vehicles] : [];
            next.push(v);
            this.selected = { ...this.selected, vehicles: next };

            this.vehNew = { plate: '', model: '', type: '', tonnage: null, isScrapHauler: false };
            this.vehCreateOpen = false;

        } catch (e) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Помилка створення машини',
                message: e?.body?.message || e?.message || 'Не вдалося створити транспортний засіб.',
                variant: 'error'
            }));
        }
    };

    get modalContentClass() {
        return `modal-content${this.saving ? ' is-saving' : ''}`;
    }
}