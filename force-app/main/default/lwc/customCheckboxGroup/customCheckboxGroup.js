import { LightningElement, api } from 'lwc';

export default class CustomCheckboxGroup extends LightningElement {
    @api options = [];
    @api label;
    @api required = false;
    @api initialValue = '';

    showValidity = false;

    connectedCallback() {
        if(this.initialValue){
            this.updateCheckboxState();
        }
    }
    renderedCallback(){
        console.log(JSON.parse(JSON.stringify(this.template.querySelectorAll('.slds-required'))))
    }

    handleCheckboxChange(event) {
        const changedValue = event.detail.value;
        const isChecked = event.detail.isChecked;
        
        // Update the isChecked property in the options array
        const updatedOptions = this.options.map(option => ({
            ...option,
            isChecked: option.value === changedValue ? isChecked : option.isChecked
        }));
        
        this.options = updatedOptions;

        // Dispatch a change event to notify the parent component
        const changeEvent = new CustomEvent('change', {
            detail: {
                updatedOptions: updatedOptions
            }
        });
        this.dispatchEvent(changeEvent);
    }

    updateCheckboxState() {
        const initialValues = this.initialValue.split(',').map(value => value.trim());
        // console.log('initialValue', this.initialValue);
        const updatedOptions = this.options.map(option => ({
            ...option,
            isChecked: initialValues.includes(option.value) //Set to true if the value is contained in initialValue
        }));

        this.options = updatedOptions;
        // this.options.forEach(element => {
        //     console.log('this.questionnaireSections', JSON.parse(JSON.stringify(element)));
        // });
    }

    //updateCheckboxState() {
        //     let initialValues = this.initialValue.replace(/(\r\n|\n|\r)/gm, "")
        //     initialValues = this.initialValue.split(',').map(value => value.trim());
        //     console.log('this.initialValues', initialValues);
        //     let options = JSON.parse(JSON.stringify(this.options));
        //     options.forEach(element => {
        //         element.value = element.value.replace(/(\r\n|\n|\r)/gm, "");
        //         console.log(element);
        //     });
        //     let updatedOptions = options.map(option => ({
        //         ...option,
        //         isChecked: initialValues.includes(option.value) //Set to true if the value is contained in initialValue
        //     }));
            
           
        //     this.options = updatedOptions;
            
        // }

    @api reportValidity() {
        if (this.required && !this.options.filter(option => option.isChecked)?.length) {
            // console.log('not valid !!!!!!!!!!!!!!')
            this.showValidity = true;
            this.template.querySelector('.custom-checkbox-group').classList.add('red-border');
        } else {
            this.showValidity = false;
            this.template.querySelector('.custom-checkbox-group').classList.remove('red-border');
        }
    }
}