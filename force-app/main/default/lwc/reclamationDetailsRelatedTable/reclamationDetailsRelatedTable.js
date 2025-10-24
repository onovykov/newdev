import { LightningElement, track, wire,api } from 'lwc';
import { generateObjValPair, addDependentValues } from 'c/customDataTable';

import getDependentMapLwc from '@salesforce/apex/CreateReclamationController.getDependentMapLwc';
import getReclamationDetail from '@salesforce/apex/ReclamationDetailGroupController.getReclamationDetail';
typeToSubtype
var typeToSubtype = {
    'c1': ['s11','s12','s13','s14'],
    'c2': ['s21','s22','s23','s24'],
}

const DEPENDEE = 'Mistmatch_Type__c'
const DEPENDENT = 'Mistmatch_SubType__c'

export default class DemoDataTable extends LightningElement {
    @api recordId;
	@track data = []
	typeToSubtype = {};
    @track columns = [];
	mapData = [[{test:1}],[{test:3}]];
	columns = [
		
    ];
	groupedRecordByOrder =[];
	showData = false;

    testVal = {test:'123232313'};
    connectedCallback() {
        this.data = addDependentValues(this.data, typeToSubtype, DEPENDEE)
    }

    pickliListChanged(event) {
        event.stopPropagation();
		if (event.detail.fieldApiname === DEPENDEE) {
			this.data[event.detail.index].DEPENDEE = event.detail.value
			this.data[event.detail.index].dependentValues = generateObjValPair(typeToSubtype[event.detail.value])
			this.data[event.detail.index].DEPENDENT = typeToSubtype[event.detail.value][0]
		} else {
			this.data[event.detail.index].DEPENDENT = event.detail.value
		}
		this.data = [...this.data]
	}

	@wire(getDependentMapLwc, { })
	wiredMap(value) {
        //this.wiredRecords = value;
        const { data, error } = value;
		
		if(data){			
			typeToSubtype = data;			
			this.columns = [
				{ label: 'Item #', fieldName: 'urlTorecord',type:'url',
					typeAttributes: {
						label: { fieldName: 'ITENumber__c' },
						target: '_blank'}},
				{ label: 'Product Name', fieldName: 'productName',type:'text'},
				{ label: 'Meas Unit', fieldName: 'OrderQty__c',type:'text'},
				{ label: 'Order Qty', fieldName: 'OrderQty__c',type:'text'},
				{ label: 'Claim Qty', fieldName: 'ClaimQty__c',type:'text'},
				{ label: 'Claim Summary', fieldName: 'ClaimSum__c',type:'text'},
				{ label: 'Currency', fieldName: 'CurrencyIsoCode',type:'text',fixedWidth: 110},
				{ label: 'Mistmatch Type', fieldName: 'Mistmatch_Type__c',type:'text'},
				{ label: 'Mistmatch SubType', fieldName: 'Mistmatch_SubType__c',type:'text'},
				// { label: 'Mistmatch Type', fieldName: DEPENDEE, type: 'normalpicklist',
				// 	typeAttributes: {
				// 		picklistOptions: generateObjValPair(Object.keys(typeToSubtype)),
				// 		value: {fieldName: DEPENDEE},
				// 		index: {fieldName: 'index'},
				// 		fieldApiName: DEPENDEE
				// 	}
				// },
				// { label: 'Mistmatch SubType', fieldName: DEPENDENT, type: 'normalpicklist',
				// 	typeAttributes: {
				// 		picklistOptions: {fieldName: 'dependentValues'},
				// 		value: {fieldName: DEPENDENT},
				// 		index: {fieldName: 'index'},
				// 		fieldApiName: DEPENDENT
				// 	}
				// },
    		];
			this.data  = [
				{id: 1, userName: 'user1', Mistmatch_Type__c: 'Commercial', Mistmatch_SubType__c: 'price'},
				
			]
			this.data = addDependentValues(this.data, typeToSubtype, DEPENDEE);
			this.loadData(typeToSubtype,DEPENDEE);
			//console.log(this.countryToState);
		} else if (error) {
            console.log(error);
        }
	}

	loadData(typeToSubtype,DEPENDEE){
		
		getReclamationDetail({recordId:this.recordId})
		.then(
			(result)=>{
				
				let tempRecords = JSON.parse( JSON.stringify( result ) );           
            	tempRecords = tempRecords.map( row => {                           
                	return { ...row, productName: row.OrderItemID__r.Name__c ,
						urlTorecord: '/'+row.Id,

                    };
            })
			
			this.data = tempRecords;
			this.data = addDependentValues(this.data, typeToSubtype, DEPENDEE);

			var temporaryMap = {};
			
			this.data.forEach(record=> {
				
				if(temporaryMap[record.OrderID__c]==undefined){
					temporaryMap[record.OrderID__c] = [];
					temporaryMap[record.OrderID__c].push(Object.assign({}, record));
				} else {
					temporaryMap[record.OrderID__c].push(Object.assign({}, record));
				}
			
			})
			
			for (const key in temporaryMap) {
				
				this.groupedRecordByOrder.push(new Array(...temporaryMap[key]));
			}
			
			this.showData = true;
			}
			
		).catch(error => {
			console.log('Errorured:- '+error.body.message);
		});;
	}
	
	
}