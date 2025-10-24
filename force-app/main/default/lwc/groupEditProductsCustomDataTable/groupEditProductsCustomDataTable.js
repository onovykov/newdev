import LightningDatatable from 'lightning/datatable';
import customLookup from './customLookuptemplate.html';

export default class GroupEditProductsCustomDataTable extends LightningDatatable {

  static customTypes = {
    customLookup: {
      template: customLookup,
      typeAttributes: ['mainObjectApiName', 'targetFieldApiName',
        'fieldLabel', 'disabled', 'value', 'required', 'recordId']
    }
  }

}