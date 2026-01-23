import { LightningElement, track } from 'lwc';
import previewSoql from '@salesforce/apex/AdminConsoleController.previewSoql';
import executeUpdateByQuery from '@salesforce/apex/AdminConsoleController.executeUpdateByQuery';
import executeDeleteByQuery from '@salesforce/apex/AdminConsoleController.executeDeleteByQuery';
import rollbackFromContentVersion from '@salesforce/apex/RollbackService.rollbackFromContentVersion';

export default class AdminConsole extends LightningElement {
  soql = 'SELECT Id, Name FROM Account LIMIT 10';
  maxRows = 50;

  sObjectApi = 'Account';
  whereClause = '';
  configName = 'Default_Setting';
  snapshotLimit = 5000;

  setValuesJson = '{"Type":"Customer"}';
  snapshotId = '';

  previewMessage = '';
  execMessage = '';

  @track rows = [];
  @track columns = null;

  onSoql(e){ this.soql = e.target.value; }
  onMaxRows(e){ this.maxRows = e.target.value; }
  onObj(e){ this.sObjectApi = e.target.value; }
  onWhere(e){ this.whereClause = e.target.value; }
  onCfg(e){ this.configName = e.target.value; }
  onSnapLimit(e){ this.snapshotLimit = e.target.value; }
  onSetValues(e){ this.setValuesJson = e.target.value; }
  onSnapshotId(e){ this.snapshotId = e.target.value; }

  async preview() {
    this.previewMessage = 'Loading...';
    try {
      const res = await previewSoql({ soql: this.soql, maxRows: Number(this.maxRows) });
      this.previewMessage = `${res.message}. Rows: ${res.recordCount}`;
      this.rows = res.rows || [];

      // datatable columns
      this.columns = (res.columns || []).map(c => ({ label: c, fieldName: c }));
    } catch (e) {
      this.previewMessage = (e?.body?.message) || e.message;
    }
  }

  parseSetValues() {
    try {
      return JSON.parse(this.setValuesJson);
    } catch (e) {
      throw new Error('Invalid JSON in Set values');
    }
  }

  async dryRunUpdate() { await this.runUpdate(true); }
  async executeUpdate() { await this.runUpdate(false); }

  async runUpdate(dryRun) {
    this.execMessage = 'Running...';
    try {
      const setValues = this.parseSetValues();
      const fields = ['Id']; // MVP: snapshot only Id unless you want more fields
      const res = await executeUpdateByQuery({
        sObjectApi: this.sObjectApi,
        fieldsToSelect: fields,
        whereClause: this.whereClause,
        setValues: setValues,
        asyncConfigName: this.configName,
        dryRun: dryRun,
        snapshotLimit: Number(this.snapshotLimit)
      });

      this.snapshotId = res.snapshotContentVersionId;
      this.execMessage =
        `${res.message}\nMode=${res.result.mode}, Records=${res.result.recordCount}, JobId=${res.result.asyncJobId || ''}\nSnapshot=${res.snapshotContentVersionId}`;
    } catch (e) {
      this.execMessage = (e?.body?.message) || e.message;
    }
  }

  async dryRunDelete() { await this.runDelete(true); }
  async executeDelete() { await this.runDelete(false); }

  async runDelete(dryRun) {
    this.execMessage = 'Running...';
    try {
      const res = await executeDeleteByQuery({
        sObjectApi: this.sObjectApi,
        snapshotFields: ['Id','Name'], // recommend include Name at least
        whereClause: this.whereClause,
        asyncConfigName: this.configName,
        dryRun: dryRun,
        snapshotLimit: Number(this.snapshotLimit)
      });

      this.snapshotId = res.snapshotContentVersionId;
      this.execMessage =
        `${res.message}\nMode=${res.result.mode}, Records=${res.result.recordCount}, JobId=${res.result.asyncJobId || ''}\nSnapshot=${res.snapshotContentVersionId}`;
    } catch (e) {
      this.execMessage = (e?.body?.message) || e.message;
    }
  }

  async rollback() {
    this.execMessage = 'Rolling back...';
    try {
      const res = await rollbackFromContentVersion({
        sObjectApi: this.sObjectApi,
        contentVersionId: this.snapshotId,
        allOrNone: false
      });
      this.execMessage = `Rollback done. Total=${res.totalRows}, OK=${res.successCount}, Errors=${res.errorCount}`;
    } catch (e) {
      this.execMessage = (e?.body?.message) || e.message;
    }
  }
}