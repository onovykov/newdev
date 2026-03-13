// errorServiceDemo.js (add toggle for compact Run Log)
import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

import simulateCalloutOnly from '@salesforce/apex/ErrorServiceDemoController.simulateCalloutOnly';
import simulateEscalation from '@salesforce/apex/ErrorServiceDemoController.simulateEscalation';
import triggerNextReminder from '@salesforce/apex/ErrorServiceDemoController.triggerNextReminder';

import getWorkItems from '@salesforce/apex/ErrorServiceDemoController.getWorkItems';
import getPharosLogs from '@salesforce/apex/ErrorServiceDemoController.getPharosLogs';
import getNotificationLogs from '@salesforce/apex/ErrorServiceDemoController.getNotificationLogs';

export default class ErrorServiceDemo extends NavigationMixin(LightningElement) {
    @track isBusy = false;

    @track lastRun = null; // { ts, action, status }
    @track runLog = [];

    @track workItems = [];
    @track pharosLogs = [];
    @track notificationLogs = [];

    @track isRunLogOpen = false;

    connectedCallback() {
        this.refreshAllLists({ silent: true });
    }

    // ---------- computed ----------

    get lastRunText() {
        if (!this.lastRun) return '—';
        const dt = new Date(this.lastRun.ts);
        return `${dt.toLocaleString()} | ${this.lastRun.action} | ${this.lastRun.status}`;
    }

    get runLogToggleIcon() {
        return this.isRunLogOpen ? 'utility:chevrondown' : 'utility:chevronright';
    }

    get workItemsCount() {
        return this.workItems?.length ? `${this.workItems.length}` : '0';
    }
    get pharosLogsCount() {
        return this.pharosLogs?.length ? `${this.pharosLogs.length}` : '0';
    }
    get notificationLogsCount() {
        return this.notificationLogs?.length ? `${this.notificationLogs.length}` : '0';
    }

    // ---------- actions ----------

    async runCalloutOnly() {
        await this.runAction('SYSTEM_CALLOUT', async () => simulateCalloutOnly());
    }

    async runEscalation() {
        await this.runAction('SYSTEM_CALLOUT_ESCALATION', async () => simulateEscalation());
    }

    async runReminder() {
        await this.runAction('WORK_ITEM_REMINDER', async () => triggerNextReminder());
    }

    toggleRunLog() {
        this.isRunLogOpen = !this.isRunLogOpen;
    }

    // ---------- navigation ----------

    navigateTo(event) {
        const id = event.currentTarget?.dataset?.id;
        if (!id) return;

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: { recordId: id, actionName: 'view' }
        });
    }

    // ---------- refresh lists ----------

    async refreshAllLists({ silent } = { silent: false }) {
        const setBusy = !silent && !this.isBusy;
        if (setBusy) this.isBusy = true;

        try {
            const [work, pharos, notif] = await Promise.all([
                getWorkItems(),
                getPharosLogs(),
                getNotificationLogs()
            ]);

            this.workItems = this.decorateDates(work, 'CreatedDate');
            this.pharosLogs = this.decorateDates(pharos, 'CreatedDate');
            this.notificationLogs = this.decorateDates(notif, 'CreatedDate');

            if (!silent) this.addLog('REFRESH', 'Lists refreshed', 'info');
        } catch (e) {
            const msg = this.normalizeApexError(e);
            if (!silent) this.toast('Refresh failed', msg, 'error');
            this.addLog('REFRESH', `Failed: ${msg}`, 'error');
        } finally {
            if (setBusy) this.isBusy = false;
        }
    }

    decorateDates(rows, fieldName) {
        if (!Array.isArray(rows)) return [];
        return rows.map((r) => {
            const raw = r?.[fieldName];
            let text = '';
            try {
                text = raw ? new Date(raw).toLocaleString() : '';
            } catch (e) {
                text = String(raw || '');
            }
            return { ...r, CreatedDateText: text };
        });
    }

    // ---------- core runner ----------

    async runAction(actionName, apexCall) {
        if (this.isBusy) return;

        this.isBusy = true;
        this.lastRun = { ts: Date.now(), action: actionName, status: 'RUNNING' };

        // keep log collapsed by default; auto-open only on failure
        this.toast('Started', actionName, 'info');
        this.addLog(actionName, 'Started', 'info');

        try {
            const resultMsg = await apexCall();

            this.lastRun = { ts: Date.now(), action: actionName, status: 'SUCCESS' };
            this.toast('Done', resultMsg || actionName, 'success');
            this.addLog(actionName, resultMsg || 'Completed', 'success');

            await this.refreshAllLists({ silent: true });
        } catch (e) {
            const msg = this.normalizeApexError(e);
            this.lastRun = { ts: Date.now(), action: actionName, status: 'FAILED' };
            this.toast('Failed', msg, 'error');
            this.addLog(actionName, msg, 'error');
            this.isRunLogOpen = true;
            // eslint-disable-next-line no-console
            console.error('ErrorServiceDemo action failed:', e);
        } finally {
            this.isBusy = false;
        }
    }

    // ---------- helpers ----------

    addLog(tag, message, type) {
        const dt = new Date();
        const ts = dt.toLocaleString();
        const row = {
            id: `${Date.now()}-${Math.random()}`,
            ts,
            tag,
            message,
            type,
            className: `logList__row logList__row--${type || 'info'}`
        };
        const next = [row, ...this.runLog];
        this.runLog = next.slice(0, 20); // tighter: keep last 20
    }

    toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant, mode: 'dismissable' }));
    }

    normalizeApexError(error) {
        if (!error) return 'Unknown error';
        if (Array.isArray(error.body)) return error.body.map((e) => e.message).join(', ');
        if (error.body?.message) return error.body.message;
        if (error.body?.pageErrors?.length) return error.body.pageErrors[0].message;
        if (error.message) return error.message;
        return 'Unknown error';
    }
}