({
    init : function(component, event, helper) {
        //helper.getTemplates(component, event, helper);
        helper.getValidatedQuoteTerms(component, event, helper);
        helper.getTemplate(component, event, helper);
        helper.getMarketSegment(component, event, helper);
        helper.changeValueShowInPdfToFalse(component, event, helper);
        helper.fetchQuoteLineItemsHelper(component, event, helper);
        helper.fetchMeasureUnitValues(component, event, helper);
        helper.fetchMeasureUnits(component, event, helper);
    },
    
    saveAndShowGeneratedPDF : function(component, event, helper) {
        
       //console.log(component.get('v.defaultMeasureValues').values);
       let selInArr = []; 
       let selectedMeasure = component.get('v.defaultMeasureValues');
        if(selectedMeasure.length == 0){
            alert("Select measure unit");
            return
        } 
        for(let key in selectedMeasure){
            selInArr.push(selectedMeasure[key])
        }
        //console.log(selInArr);
        let strMeasure = selInArr.join();
        //console.log(selInArr.join());
       var selectedRows = event.getParam('selectedRows');
    let arrIds = [];    
    // Display that fieldName of the selected rows
    // get selected items for pdf creation
    var selectedIds = component.get('v.selectedQuoteItemIds');
    
        //updated
        var action = component.get("c.changeShowInPdfToTrue");
		action.setParams({ selectedQuoteLineItems : selectedIds
        });
   		action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
         //updated         
        let page = 'QuotePDFPage';
        if(component.get('v.template') == 'Pipes') {
            component.set('v.selectedMetric', component.get('v.metricOptionsMap')[component.get('v.selectedMetric')]);
            if(component.get('v.selectedLanguage') == 'English') page = 'QuotePDFPipesENG';
            if(component.get('v.selectedLanguage') == 'Russian') page = 'QuotePDFPipesRUS';
            if(component.get('v.selectedLanguage') == 'Spanish') page = 'QuotePDFPipesSP';
            if(component.get('v.selectedLanguage') == 'English (USA)') page = 'QuotePDFPipesUSA';
            
            //UKR page
            if(component.get('v.selectedLanguage') == 'Ukrainian') page = 'QuotePDFPipesUKR';
        } else if(component.get('v.template') == 'Wheels') {
            if(component.get('v.selectedLanguage') == 'English') page = 'QuotePDFWheelsENG';
            if(component.get('v.selectedLanguage') == 'Russian') page = 'QuotePDFWheelsRUS';
            
            //UKR page
            if(component.get('v.selectedLanguage') == 'Ukrainian') page = 'QuotePDFWheelsUKR';
        }
        component.set('v.pdfLink', '/apex/' + page + '?Id=' + component.get('v.recordId') + '&Quantity=Quantity' + '&MeasureUnits='+strMeasure);
        //console.log('/apex/' + page + '?Id=' + component.get('v.recordId') + '&Quantity=' + component.get('v.selectedMetric'));
        //console.log('v.pdfLink', '/apex/' + page + '?Id=' + component.get('v.recordId') + '&Quantity=' + component.get('v.selectedMetric') + '&MeasureUnits='+strMeasure);
        component.set('v.selectedTemplate', page);
        component.set('v.showGeneratedPDF', true);
            
          } else if (state === "ERROR") {
                console.log("not fine");
                helper.displayToast("Error", "Something went wrong", "error");
                $A.get("e.force:closeQuickAction").fire();
            }
        });
    $A.enqueueAction(action);
         
    },
    
    onTemplateChange : function(component, event, helper) {
        helper.getLanguages(component, event, helper);
    },
    
    saveOnQuote : function(component, event, helper) {
        let selInArr = []; 
        let selectedMeasure = component.get('v.defaultMeasureValues'); 
        for(let key in selectedMeasure){
            selInArr.push(selectedMeasure[key])
        }
        //console.log(selInArr);
        let strMeasure = selInArr.join();
        
        var quoteId = component.get('v.recordId');
        var template = component.get('v.selectedTemplate');
        var quantity = component.get('v.selectedMetric');
        var action = component.get('c.attachPDfLight');
        action.setParams({'quoteId': quoteId, 'pageName': template, 'quantity': quantity,'selectedMeasure':strMeasure});		
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(state === "SUCCESS") {
                //console.log("fine");
                helper.displayToast("Success", "PDF was saved succesfuuly to quote", "Success");
                
                $A.get("e.force:closeQuickAction").fire();
                $A.get('e.force:refreshView').fire();
                //helper.changeValueShowInPdfToFalse(component, event, helper);
            } else if (state === "ERROR") {
                console.log("not fine");
                helper.displayToast("Error", "Something went wrong", "error");
                $A.get("e.force:closeQuickAction").fire();
            }
            
        });
        $A.enqueueAction(action);
    },
    cancel : function (component, event, helper){
        //helper.changeValueShowInPdfToFalse(component, event, helper);
        $A.get("e.force:closeQuickAction").fire();
    },
 
    //get selected quoteLineItem push them in array
    getSelectedName: function (cmp, event) {
    var selectedRows = event.getParam('selectedRows');
    //var boolTest = cmp.get('v.showGeneratedPDF');    
    let arrIds = [];    
    // Display that fieldName of the selected rows    
        for (var i = 0; i < selectedRows.length; i++){
        //console.log(selectedRows[i].Id);
        arrIds.push(selectedRows[i].Id);    
    }
        cmp.set('v.selectedQuoteItemIds',arrIds);
        //var Test = cmp.get('v.selectedQuoteItemIds'); 
        //console.log(Test);   
        
}
})