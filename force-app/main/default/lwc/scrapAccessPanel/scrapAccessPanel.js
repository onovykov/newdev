import { LightningElement, track, wire } from 'lwc';
import init from '@salesforce/apex/ScrapAccessController.init';
import togglePermission from '@salesforce/apex/ScrapAccessController.togglePermission';
import setPermissionsForSupplier from '@salesforce/apex/ScrapAccessController.setPermissionsForSupplier';
import setPermissionsForScrap from '@salesforce/apex/ScrapAccessController.setPermissionsForScrap';

import initAccess from '@salesforce/apex/ScrapAccessController.init';


export default class ScrapAccessPanel extends LightningElement {
    MODES = { SUPPLIER_TOP: 'SUPPLIER_TOP', SCRAP_TOP: 'SCRAP_TOP' };

    @track mode = this.MODES.SUPPLIER_TOP;
    @track selectedTopId;
    @track isLoading = true;

    @track suppliers = [];
    @track scraps = [];

    permissionsBySupplier = {};
    permissionsByScrap = {};

    @track searchQuery = '';
    @track showDropdown = false;
    isPicking = false;

    latinToCyrillicMap = {
        a:'а', b:'б', v:'в', h:'х', g:'г', d:'д', e:'е', z:'з', y:'й', i:'і',
        j:'й', k:'к', l:'л', m:'м', n:'н', o:'о', p:'п', r:'р', s:'с', t:'т',
        u:'у', f:'ф', c:'с', q:'к', w:'в', x:'кс'
    };
    cyrillicToLatinMap = {
        а:'a', б:'b', в:'v', г:'g', ґ:'g', д:'d', е:'e', є:'e', ж:'zh', з:'z', и:'y',
        і:'i', ї:'i', й:'i', к:'k', л:'l', м:'m', н:'n', о:'o', п:'p', р:'r', с:'s',
        т:'t', у:'u', ф:'f', х:'h', ц:'c', ч:'ch', ш:'sh', щ:'sch', ь:'', '’':'', 'ʼ':'',
        ы:'y', э:'e', ё:'e', ъ:''
    };

    normalizeCyrillicBasic = (inputText) => {
        const text = (inputText || '').toLowerCase().replace(/\u00A0/g,' ').replace(/\s+/g,' ').trim();
        return text
            .replace(/[ёє]/g,'е')
            .replace(/[ї]/g,'і')
            .replace(/[ґ]/g,'г')
            .replace(/[’ʼ']/g,'')
            .replace(/[^a-zа-яёєіїґ0-9\s]/g,'');
    };

    mapLatinToCyrillic = (inputText) => {
        let result = '';
        for (const character of (inputText || '').toLowerCase()) {
            result += (this.latinToCyrillicMap[character] || character);
        }
        return result;
    };

    transliterateCyrillicToLatin = (inputText) => {
        let result = '';
        for (const character of (inputText || '')) {
            result += (this.cyrillicToLatinMap[character] || character);
        }
        return result;
    };


    @wire(init)
    wiredInit({ data, error }) {
        if (data) {
            this.suppliers = (data.suppliers || []).map((supplier) => {
                const nameNormalized = this.normalizeCyrillicBasic(supplier.name);
                return {
                    id: supplier.id,
                    name: supplier.name,
                    searchKeyCyr: nameNormalized,
                    searchKeyLat: this.transliterateCyrillicToLatin(nameNormalized)
                };
            });

            this.scraps = (data.scrapTypes || []).map((scrapType) => {
                const fullName = `${scrapType.name} ${scrapType.code || ''}`.trim();
                const nameNormalized = this.normalizeCyrillicBasic(fullName);
                return {
                    id: scrapType.id,
                    name: scrapType.name,
                    code: scrapType.code,
                    displayName: scrapType.code ? `${scrapType.name} (${scrapType.code})` : scrapType.name,
                    searchKeyCyr: nameNormalized,
                    searchKeyLat: this.transliterateCyrillicToLatin(nameNormalized)
                };
            });


            this.permissionsBySupplier = {};
            this.permissionsByScrap = {};
            for (const supplier of this.suppliers) this.permissionsBySupplier[supplier.id] = new Set();
            for (const scrap of this.scraps) this.permissionsByScrap[scrap.id] = new Set();

            for (const relation of (data.relations || [])) {
                if (relation.permitted) {
                    (this.permissionsBySupplier[relation.accountId] || (this.permissionsBySupplier[relation.accountId] = new Set()))
                        .add(relation.scrapTypeId);
                    (this.permissionsByScrap[relation.scrapTypeId] || (this.permissionsByScrap[relation.scrapTypeId] = new Set()))
                        .add(relation.accountId);
                }
            }

            const first = this.topOptionsSource[0];
            this.selectedTopId = first ? first.id : null;
        } else if (error) {
            // eslint-disable-next-line no-console
            console.error('Init error', error);
        }
        this.isLoading = false;
    }

    get searchPlaceholder() {
        return this.mode === this.MODES.SUPPLIER_TOP ? 'Пошук постачальника…' : 'Пошук брухту…';
    }
    get topOptionsSource() {
        if (this.mode === this.MODES.SUPPLIER_TOP) return this.suppliers;
        return this.scraps.map((s) => ({ id: s.id, name: s.displayName }));
    }
    get selectedTopName() {
        const source = this.topOptionsSource;
        const found = source.find((x) => x.id === this.selectedTopId);
        return found ? found.name : '—';
    }
    // get hasBottomItems() {
    //     const items = this.bottomItems;
    //     return Array.isArray(items) && items.length > 0;
    // }
    get bottomItems() {
        if (!this.selectedTopId) return [];
        if (this.mode === this.MODES.SUPPLIER_TOP) {
            const permittedSet = this.permissionsBySupplier[this.selectedTopId] || new Set();
            return this.scraps.map((s) => ({ id: s.id, name: s.displayName, enabled: permittedSet.has(s.id) }));
        } else {
            const permittedSet = this.permissionsByScrap[this.selectedTopId] || new Set();
            return this.suppliers.map((acc) => ({ id: acc.id, name: acc.name, enabled: permittedSet.has(acc.id) }));
        }
    }

    // get searchResults() {
    //     const query = (this.searchQuery || '').trim().toLowerCase();
    //     if (this.mode === this.MODES.SUPPLIER_TOP) {
    //         const list = this.suppliers;
    //         if (!query) return list.slice(0, 8);
    //         return list.filter((x) => (x.name || '').toLowerCase().includes(query)).slice(0, 20);
    //     }
    //     const list = this.scraps;
    //     if (!query) return list.slice(0, 8).map((s) => ({ id: s.id, name: s.displayName }));
    //     return list.filter((s) => s.searchable.includes(query)).slice(0, 20).map((s) => ({ id: s.id, name: s.displayName }));
    // }

    get searchResults() {
        const rawQuery = (this.searchQuery || '').trim();
        const queryCyr = this.normalizeCyrillicBasic(this.mapLatinToCyrillic(rawQuery));
        const queryLat = rawQuery.toLowerCase();

        if (this.mode === this.MODES.SUPPLIER_TOP) {
            const list = this.suppliers;
            if (!queryCyr && !queryLat) return list.slice(0, 8);
            return list
                .filter((row) =>
                    (queryCyr && row.searchKeyCyr.includes(queryCyr)) ||
                    (queryLat && row.searchKeyLat.includes(queryLat))
                )
                .slice(0, 20)
                .map((row) => ({ id: row.id, name: row.name }));
        }

        const list = this.scraps;
        if (!queryCyr && !queryLat) return list.slice(0, 8).map((s) => ({ id: s.id, name: s.displayName }));
        return list
            .filter((row) =>
                (queryCyr && row.searchKeyCyr.includes(queryCyr)) ||
                (queryLat && row.searchKeyLat.includes(queryLat))
            )
            .slice(0, 20)
            .map((row) => ({ id: row.id, name: row.displayName }));
    }


    get hasSearchResults() { return this.searchResults && this.searchResults.length > 0; }
    get headerTitle() {
        return this.mode === this.MODES.SUPPLIER_TOP
            ? `Доступ постачальника "${this.selectedTopName}" до брухту`
            : `Дозвіл брухту "${this.selectedTopName}" для постачальників`;
    }

    toggleMode = () => {
        this.mode = this.mode === this.MODES.SUPPLIER_TOP ? this.MODES.SCRAP_TOP : this.MODES.SUPPLIER_TOP;
        const first = this.topOptionsSource[0];
        this.selectedTopId = first ? first.id : null;
        this.searchQuery = '';
        this.showDropdown = false;
    };

    handleToggle = async (event) => {
        const bottomId = event.target.dataset.id;
        const enable = event.target.checked;

        if (this.mode === this.MODES.SUPPLIER_TOP) {
            this.applyLocalMutationSupplier(this.selectedTopId, bottomId, enable);
        } else {
            this.applyLocalMutationScrap(this.selectedTopId, bottomId, enable);
        }

        this.isLoading = true;
        try {
            const accountId = this.mode === this.MODES.SUPPLIER_TOP ? this.selectedTopId : bottomId;
            const scrapTypeId = this.mode === this.MODES.SUPPLIER_TOP ? bottomId : this.selectedTopId;
            await togglePermission({ accountId, scrapTypeId, permitted: enable });
        } catch (e) {
            const revertEnable = !enable;
            if (this.mode === this.MODES.SUPPLIER_TOP) {
                this.applyLocalMutationSupplier(this.selectedTopId, bottomId, revertEnable);
            } else {
                this.applyLocalMutationScrap(this.selectedTopId, bottomId, revertEnable);
            }
            // eslint-disable-next-line no-console
            console.error('togglePermission error', e);
        } finally {
            this.isLoading = false;
        }
    };

    handleSearchInput = (event) => { this.searchQuery = event.target.value; this.showDropdown = true; };
    openSearch = () => { this.showDropdown = true; };
    closeSearch = () => { this.showDropdown = false; };
    handlePickFromSearch = (event) => { this.selectedTopId = event.currentTarget.dataset.id; this.searchQuery = ''; this.showDropdown = false; };
    handleSearchKeydown = (event) => {
        if (event.key === 'Enter') {
            const first = this.searchResults && this.searchResults[0];
            if (first) { this.selectedTopId = first.id; this.searchQuery = ''; this.showDropdown = false; }
        }
    };
    handleSearchBlur = () => {
        setTimeout(() => {
            if (this.isPicking) { this.isPicking = false; this.showDropdown = true; this.focusSearchInput(); }
            else { this.showDropdown = false; }
        }, 0);
    };
    handleDropdownMousedown = (event) => { this.isPicking = true; event.preventDefault(); };
    focusSearchInput() { const el = this.template.querySelector('.search-input'); if (el) el.focus(); }

    // Масові дії
    handleSelectAll = async () => {
        if (!this.selectedTopId) return;
        this.isLoading = true;
        try {
            if (this.mode === this.MODES.SUPPLIER_TOP) {
                const accountId = this.selectedTopId;
                const scrapTypeIds = this.scraps.map((s) => s.id);
                this.applyLocalBulkSupplier(accountId, scrapTypeIds, true);
                await setPermissionsForSupplier({ accountId, scrapTypeIds, permitted: true });
            } else {
                const scrapTypeId = this.selectedTopId;
                const accountIds = this.suppliers.map((s) => s.id);
                this.applyLocalBulkScrap(scrapTypeId, accountIds, true);
                await setPermissionsForScrap({ scrapTypeId, accountIds, permitted: true });
            }
        } catch (e) {
            // Перезавантаж ініт при збої, аби не тримати неконсистентний локальний стан
            // eslint-disable-next-line no-console
            console.error('handleSelectAll error', e);
            // Можна викликати refreshApex(init), якщо викор. @wire; скорочено: просто нічого не робимо тут
        } finally {
            this.isLoading = false;
        }
    };

    handleClearAll = async () => {
        if (!this.selectedTopId) return;
        this.isLoading = true;
        try {
            if (this.mode === this.MODES.SUPPLIER_TOP) {
                const accountId = this.selectedTopId;
                const scrapTypeIds = this.scraps.map((s) => s.id);
                this.applyLocalBulkSupplier(accountId, scrapTypeIds, false);
                await setPermissionsForSupplier({ accountId, scrapTypeIds, permitted: false });
            } else {
                const scrapTypeId = this.selectedTopId;
                const accountIds = this.suppliers.map((s) => s.id);
                this.applyLocalBulkScrap(scrapTypeId, accountIds, false);
                await setPermissionsForScrap({ scrapTypeId, accountIds, permitted: false });
            }
        } catch (e) {
            // eslint-disable-next-line no-console
            console.error('handleClearAll error', e);
        } finally {
            this.isLoading = false;
        }
    };

    // Локальні мутації
    applyLocalMutationSupplier(supplierId, scrapId, enable) {
        const currentSet = this.permissionsBySupplier[supplierId] || new Set();
        const newSet = new Set(currentSet);
        if (enable) { newSet.add(scrapId); } else { newSet.delete(scrapId); }
        this.permissionsBySupplier = { ...this.permissionsBySupplier, [supplierId]: newSet };

        const reverseSet = this.permissionsByScrap[scrapId] || new Set();
        const newReverse = new Set(reverseSet);
        if (enable) { newReverse.add(supplierId); } else { newReverse.delete(supplierId); }
        this.permissionsByScrap = { ...this.permissionsByScrap, [scrapId]: newReverse };
    }
    applyLocalMutationScrap(scrapId, supplierId, enable) { this.applyLocalMutationSupplier(supplierId, scrapId, enable); }

    applyLocalBulkSupplier(supplierId, scrapIds, enable) {
        const newSet = new Set(this.permissionsBySupplier[supplierId] || []);
        for (const scrapId of scrapIds) {
            if (enable) newSet.add(scrapId); else newSet.delete(scrapId);
            const r = new Set(this.permissionsByScrap[scrapId] || []);
            if (enable) r.add(supplierId); else r.delete(supplierId);
            this.permissionsByScrap = { ...this.permissionsByScrap, [scrapId]: r };
        }
        this.permissionsBySupplier = { ...this.permissionsBySupplier, [supplierId]: newSet };
    }
    applyLocalBulkScrap(scrapId, supplierIds, enable) {
        for (const supplierId of supplierIds) {
            this.applyLocalMutationSupplier(supplierId, scrapId, enable);
        }
    }


    @track bottomSearch = '';
    @track filterEnabledOnly = false;   // «Лише активовані»
    @track filterDisabledOnly = false;  // «Лише неактивні»

    get bottomSearchPlaceholder() {
        return this.mode === this.MODES.SUPPLIER_TOP
            ? 'Фільтр брухту…'
            : 'Фільтр постачальників…';
    }

// базовий список (як і раніше), але нижче ми застосуємо фільтри/пошук
    get bottomBase() {
        return this.bottomItems; // використовує твою наявну логіку формування bottomItems
    }

// застосувати пошук + прапорці «лише активні / лише неактивні»
    get bottomFiltered() {
        // 1) пошук
        const raw = (this.bottomSearch || '').trim();
        const qCyr = this.normalizeCyrillicBasic(this.mapLatinToCyrillic(raw));
        const qLat = raw.toLowerCase();

        let list = this.bottomBase || [];
        if (qCyr || qLat) {
            list = list.filter((row) => {
                const name = row?.name || '';
                const cyr = this.normalizeCyrillicBasic(name);
                const lat = this.transliterateCyrillicToLatin(cyr);
                const hitCyr = qCyr ? cyr.includes(qCyr) : false;
                const hitLat = qLat ? lat.includes(qLat) : false;
                return hitCyr || hitLat;
            });
        }

        // 2) фільтри активності (взаємовиключні)
        if (this.filterEnabledOnly && !this.filterDisabledOnly) {
            list = list.filter(i => i.enabled === true);
        } else if (this.filterDisabledOnly && !this.filterEnabledOnly) {
            list = list.filter(i => i.enabled !== true);
        }
        // якщо ОБИДВА прапорці зняті — показуємо всі (нічого не робимо)
        // якщо раптом обидва обрані — можна показувати всі або зробити взаємовиключними у хендлерах (нижче)

        return list;
    }

    get bottomActive()   { return (this.bottomFiltered || []).filter(i => i.enabled === true); }
    get bottomInactive() { return (this.bottomFiltered || []).filter(i => i.enabled !== true); }

    get hasActiveGroup()   { return (this.bottomActive   && this.bottomActive.length)   > 0; }
    get hasInactiveGroup() { return (this.bottomInactive && this.bottomInactive.length) > 0; }

// ВАЖЛИВО: тепер «наявність елементів» рахуємо ПІСЛЯ фільтрів/пошуку
    get hasBottomItems()   { return (this.bottomFiltered && this.bottomFiltered.length) > 0; }

    handleBottomSearchInput = (e) => {
        this.bottomSearch = e.target.value || '';
    };

    handleFilterEnabledChange = (e) => {
        const checked = !!e.target.checked;
        this.filterEnabledOnly  = checked;
        if (checked) this.filterDisabledOnly = false;
    };

    handleFilterDisabledChange = (e) => {
        const checked = !!e.target.checked;
        this.filterDisabledOnly = checked;
        if (checked) this.filterEnabledOnly = false;
    };
}