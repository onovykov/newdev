import {api, LightningElement, track, wire} from 'lwc';
import getByBranchAndGroup from '@salesforce/apex/ScrapTypeService.getByBranchAndGroup';
import getScrapDetails from '@salesforce/apex/ScrapTypeService.getScrapDetails';
import setActive from '@salesforce/apex/ScrapTypeService.setActive';
import updateDescription from '@salesforce/apex/ScrapTypeService.updateDescription';

import initAccess from '@salesforce/apex/ScrapAccessController.init';
import getRemainingSummary from '@salesforce/apex/ScrapTypeService.getRemainingSummary';

import {ShowToastEvent} from 'lightning/platformShowToastEvent';

export default class ScrapInfoPanel extends LightningElement {
    // Дані з Apex
    @track commercialGroups = [];
    @track corporateGroups = [];

    @api recordId; // Id ScrapType__c

    // Стан лівої панелі
    @track searchQueryString = '';
    @track commercialBranchOpen = true;
    @track corporateBranchOpen = true;
    @track groupOpenStateMap = {}; // {groupId: boolean}

    // Вибір
    @track selectedRecordId;
    @track selectedRecordDetails;

    @track supplierRemaining = { day: 0, decade: 0, month: 0, unit: 'т' };


    @track remaining = { day: 0, decade: 0, month: 0, unit: 'т' };
    @track limitsLoaded = false;

    async loadRemaining() {
        if (!this.selectedRecordId) return; // selectedRecordId = ScrapType__c
        try {
            const res = await getRemainingSummary({ scrapTypeId: this.selectedRecordId });
            this.remaining = res || { day: 0, decade: 0, month: 0, unit: 'т' };
        } catch (e) {
            this.toast('Помилка підрахунку лімітів', this.formatError(e), 'error');
        } finally {
            this.limitsLoaded = true;
        }
    }

// форматери для HTML
    get formattedRemainingTonsDay()    { return `${this.remaining.day} ${this.remaining.unit}`; }
    get formattedRemainingTonsDecade() { return `${this.remaining.decade} ${this.remaining.unit}`; }
    get formattedRemainingTonsMonth()  { return `${this.remaining.month} ${this.remaining.unit}`; }

    // Завантаження груп
    @wire(getByBranchAndGroup)
    wiredBuckets({ data, error }) {
        if (data) {
            this.commercialGroups = data.commercial || [];
            this.corporateGroups = data.corporate || [];
            [...this.commercialGroups, ...this.corporateGroups].forEach(groupRecord => {
                if (this.groupOpenStateMap[groupRecord.groupId] === undefined) {
                    this.groupOpenStateMap[groupRecord.groupId] = true;
                }
            });
        } else if (error) {
            this.toast('Помилка завантаження', this.formatError(error), 'error');
        }
    }

    // Деталі вибраного виду
    @wire(getScrapDetails, { scrapTypeId: '$selectedRecordId' })
    wiredDetails({ data, error }) {
        if (data) {
            this.selectedRecordDetails = data;
            this.editDesc = false;
            this.descriptionDraft = '';
        } else if (error) {
            this.toast('Помилка завантаження', this.formatError(error), 'error');
        }
    }

    // Рендер груп з урахуванням пошуку
    get commercialRenderedGroups() { return this.buildRenderedGroups(this.commercialGroups); }
    get corporateRenderedGroups()  { return this.buildRenderedGroups(this.corporateGroups); }
    get commercialEmpty() { return this.commercialRenderedGroups.length === 0; }
    get corporateEmpty()  { return this.corporateRenderedGroups.length === 0; }

    buildRenderedGroups(sourceGroups) {
        const normalizedQuery = (this.searchQueryString || '').trim().toLowerCase();
        return (sourceGroups || []).map(groupRecord => {
            const isOpen = !!this.groupOpenStateMap[groupRecord.groupId];
            const filteredItems = (groupRecord.items || []).filter(itemRecord => {
                if (!normalizedQuery) return true;
                const normalizedName = (itemRecord.Name || '').toLowerCase();
                const normalizedCode = (itemRecord.ScrapTypeCode__c || '').toLowerCase();
                return normalizedName.includes(normalizedQuery) || normalizedCode.includes(normalizedQuery);
            }).map(itemRecord => ({
                ...itemRecord,
                itemCss: itemRecord.Id === this.selectedRecordId ? 'sp-item active' : 'sp-item'
            }));
            return {
                groupId: groupRecord.groupId,
                groupName: groupRecord.groupName,
                open: isOpen,
                caretCss: `caret ${isOpen ? 'open' : ''}`,
                items: filteredItems,
                showEmpty: filteredItems.length === 0
            };
        }).filter(viewGroup => viewGroup.items.length > 0 || normalizedQuery === '');
    }

    // Каретки гілок
    get commercialCaretCss() { return `caret ${this.commercialBranchOpen ? 'open' : ''}`; }
    get corporateCaretCss()  { return `caret ${this.corporateBranchOpen ? 'open' : ''}`; }

    // Формат поточного місяця
    get currentMonthLabel() {
        try {
            const now = new Date();
            return new Intl.DateTimeFormat('uk-UA', { month: 'long', year: 'numeric' }).format(now);
        } catch (e) {
            return 'поточний місяць';
        }
    }

    // Статусний бейдж
    get statusBadgeCss() {
        const isActive = this.selectedRecordDetails && this.selectedRecordDetails.IsActive__c;
        return isActive ? 'badge status-badge active' : 'badge status-badge inactive';
    }
    get statusBadgeText() {
        const isActive = this.selectedRecordDetails && this.selectedRecordDetails.IsActive__c;
        return isActive ? 'Активний' : 'Неактивний';
    }

    // Події
    handleSearchInput = (event) => { this.searchQueryString = event.target.value; };
    toggleBranchOpen = (event) => {
        const branchKey = event.currentTarget.dataset.key;
        if (branchKey === 'commercial') this.commercialBranchOpen = !this.commercialBranchOpen;
        if (branchKey === 'corporate')  this.corporateBranchOpen = !this.corporateBranchOpen;
    };
    toggleGroupOpen = (event) => {
        const groupId = event.currentTarget.dataset.groupId;
        this.groupOpenStateMap = { ...this.groupOpenStateMap, [groupId]: !this.groupOpenStateMap[groupId] };
    };
    handleSelectItem = (event) => {
        this.selectedRecordId = event.currentTarget.dataset.id;
        this.loadRemaining(); // підвантажити залишки для нового ScrapType
    };

    async handleToggleActive(event) {
        if (!this.selectedRecordId) return;
        try {
            this.selectedRecordDetails = await setActive({
                scrapTypeId: this.selectedRecordId,
                newIsActive: event.target.checked
            });
            this.toast('Оновлено', 'Статус активності змінено', 'success');
        } catch (ex) {
            this.toast('Помилка оновлення', this.formatError(ex), 'error');
        }
    }

    get selectedParentName() {
        return this.selectedRecordDetails && this.selectedRecordDetails.Parent__r
            ? this.selectedRecordDetails.Parent__r.Name
            : '';
    }

    // Утиліти
    toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
    formatError(err) {
        try { return err?.body?.message || err?.message || JSON.stringify(err); }
        catch (e) { return 'Unknown error'; }
    }

    remainingLimitsTonsDay = +(Math.random() * 100).toFixed(1);
    remainingLimitsTonsDecade = +(Math.random() * 500).toFixed(1);
    remainingLimitsTonsMonth = +(Math.random() * 1000).toFixed(1);

    // get formattedRemainingTonsDay() {
    //     return this.remainingLimitsTonsDay === null ? '—' : `${this.remainingLimitsTonsDay} т.`;
    // }
    // get formattedRemainingTonsDecade() {
    //     return this.remainingLimitsTonsDecade === null ? '—' : `${this.remainingLimitsTonsDecade} т.`;
    // }
    // get formattedRemainingTonsMonth() {
    //     return this.remainingLimitsTonsMonth === null ? '—' : `${this.remainingLimitsTonsMonth} т.`;
    // }

    @track editDesc = false;
    @track descriptionDraft = '';


    toggleDescEdit = () => {
        if (!this.selectedRecordDetails) return;
        this.editDesc = !this.editDesc;
        this.descriptionDraft = this.editDesc
            ? (this.selectedRecordDetails?.Description__c || '')
            : '';
    };

    handleDescInput = (e) => { this.descriptionDraft = e.target.value; };

    handleDescCancel = () => {
        this.editDesc = false;
        this.descriptionDraft = '';
    };

    handleDescSave = async () => {
        if (!this.selectedRecordId) return;
        try {
            const updated = await updateDescription({
                scrapTypeId: this.selectedRecordId,
                newDescription: this.descriptionDraft
            });
            this.selectedRecordDetails = updated;   // миттєве відображення
            this.editDesc = false;
            this.toast('Збережено', 'Опис успішно оновлено', 'success');
        } catch (e) {
            this.toast('Не збережено', this.formatError(e), 'error');
        }
    };

    get descChanged() { return (this.descriptionDraft ?? '') !== (this.selectedRecordDetails?.Description__c ?? ''); }

    get descEditLabel() {
        return this.editDesc ? 'Скасувати' : 'Редагувати';
    }

//     для відображення таблички з доступами постачальника
    // ---- READ-ONLY табличка постачальників для вибраного брухту ----
    @track supplierSearch = '';
    @track suppliersAll = [];          // [{id, name}]
    accessLoaded = false;
    // індекс: { [scrapTypeId]: Set(accountId) }
    allowedByScrap = {};

    @wire(initAccess)
    wiredAccess({ data, error }) {
        if (data) {
            this.suppliersAll = data.suppliers || [];

            const idx = {};
            (data.relations || []).forEach(r => {
                if (r?.permitted === true && r.scrapTypeId && r.accountId) {
                    if (!idx[r.scrapTypeId]) idx[r.scrapTypeId] = new Set();
                    idx[r.scrapTypeId].add(r.accountId);
                }
            });
            this.allowedByScrap = idx;
            this.accessLoaded = true;
        } else if (error) {
            this.toast('Помилка завантаження доступів', this.formatError(error), 'error');
        }
    }

    handleSupplierSearch = (e) => { this.supplierSearch = e.target.value; };

    get permittedSuppliers() {
        const scrapId = this.selectedRecordId;
        if (!this.accessLoaded || !scrapId) return [];
        const allowed = this.allowedByScrap[scrapId];
        if (!allowed || allowed.size === 0) return [];

        const q = (this.supplierSearch || '').trim().toLowerCase();
        return this.suppliersAll.filter(s =>
            allowed.has(s.id) &&
            (!q || (s.name || '').toLowerCase().includes(q))
        );
    }
    get suppliersEmpty() { return this.permittedSuppliers.length === 0; }


    // Допоміжне: зібрати всі groupId
    get allGroupIds() {
        return [...(this.commercialGroups || []), ...(this.corporateGroups || [])].map(g => g.groupId);
    }

// Встановити стан для всіх груп
    setAllGroupsOpen(open) {
        const newMap = { ...this.groupOpenStateMap };
        this.allGroupIds.forEach(id => { newMap[id] = !!open; });
        this.groupOpenStateMap = newMap;
    }

// Кнопки тулбара
    expandAll = () => {
        this.commercialBranchOpen = true;
        this.corporateBranchOpen = true;
        this.setAllGroupsOpen(true);
    };

    collapseAll = () => {
        this.commercialBranchOpen = false;
        this.corporateBranchOpen = false;
        this.setAllGroupsOpen(false);
    };

}