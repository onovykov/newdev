import { LightningElement, api } from 'lwc';
import getOrderItemSpecification from '@salesforce/apex/OrderItemDatatableController.getOrderItemSpecification';
import getUserLanguage from '@salesforce/apex/UserUtils.getUserLanguage';

import site_prodSpec_Name_to_Srandard from '@salesforce/label/c.Site_prodSpec_Name_to_Srandard';
import site_prodSpec_Product_Type from '@salesforce/label/c.Site_prodSpec_Product_Type';
import site_prodSpec_Drawing from '@salesforce/label/c.Site_prodSpec_Drawing';
import site_prodSpec_Product_Name from '@salesforce/label/c.Site_prodSpec_Product_Name';
import site_prodSpec_Specification from '@salesforce/label/c.Site_prodSpec_Specification';
import site_prodSpec_Product_Details from '@salesforce/label/c.Site_prodSpec_Product_Details';
import site_prodSpec_Exec_Category from '@salesforce/label/c.Site_prodSpec_Exec_Category';
import site_prodSpec_Marking_Type from '@salesforce/label/c.Site_prodSpec_Marking_Type';
import site_prodSpec_Imbalance from '@salesforce/label/c.Site_prodSpec_Imbalance';
import site_prodSpec_Oil_Hole from '@salesforce/label/c.Site_prodSpec_Oil_Hole';
import site_prodSpec_Plug_Type from '@salesforce/label/c.Site_prodSpec_Plug_Type';
import site_prodSpec_Cover_Type from '@salesforce/label/c.Site_prodSpec_Cover_Type';
import site_prodSpec_Cover_Material from '@salesforce/label/c.Site_prodSpec_Cover_Material';
import site_prodSpec_Packing_Type from '@salesforce/label/c.Site_prodSpec_Packing_Type';
import site_prodSpec_Inspection from '@salesforce/label/c.Site_prodSpec_Inspection';
import site_prodSpec_Purpose from '@salesforce/label/c.Site_prodSpec_Purpose';
import site_prodSpec_Has_Spec_Req from '@salesforce/label/c.Site_prodSpec_Has_Spec_Req';
import site_prodSpec_Weight_kg from '@salesforce/label/c.Site_prodSpec_Weight_kg';
import site_prodSpec_Shape from '@salesforce/label/c.Site_prodSpec_Shape';
import site_prodSpec_Steel_Grade from '@salesforce/label/c.Site_prodSpec_Steel_Grade';
import site_prodSpec_Standard from '@salesforce/label/c.Site_prodSpec_Standard';
import site_prodSpec_Axle_Box from '@salesforce/label/c.Site_prodSpec_Axle_Box';
import site_prodSpec_Bearer from '@salesforce/label/c.Site_prodSpec_Bearer';
import site_prodSpec_Wheel_Specification from '@salesforce/label/c.Site_prodSpec_Wheel_Specification';
import site_prodSpec_Axle_Specification from '@salesforce/label/c.Site_prodSpec_Axle_Specification';
import no from '@salesforce/label/c.No';
import yes from '@salesforce/label/c.Yes';

export default class OrderProductSpecification extends LightningElement {
    @api getSelectedOrderItem;
    orderItem;
    language;

    isWheels = false;
    isTyres = false;
    isWheelsets = false;
    isAxles = false;
    isWheelsOrAxles = false;

    labels = {
        site_prodSpec_Name_to_Srandard,
        site_prodSpec_Product_Type,
        site_prodSpec_Drawing,
        site_prodSpec_Specification,
        site_prodSpec_Product_Name,
        site_prodSpec_Product_Details,
        site_prodSpec_Exec_Category,
        site_prodSpec_Marking_Type,
        site_prodSpec_Imbalance,
        site_prodSpec_Oil_Hole,
        site_prodSpec_Plug_Type,
        site_prodSpec_Cover_Type,
        site_prodSpec_Cover_Material,
        site_prodSpec_Packing_Type,
        site_prodSpec_Inspection,
        site_prodSpec_Purpose,
        site_prodSpec_Has_Spec_Req,
        site_prodSpec_Weight_kg,
        site_prodSpec_Shape,
        site_prodSpec_Steel_Grade,
        site_prodSpec_Standard,
        site_prodSpec_Axle_Box,
        site_prodSpec_Bearer,
        site_prodSpec_Wheel_Specification,
        site_prodSpec_Axle_Specification,

        no,
        yes
    }

    connectedCallback() {
        getOrderItemSpecification({orderItemId: this.getSelectedOrderItem})
            .then(response => {
                this.isWheels = response.Drawing__r.WheelProduct__c === 'Wheels';
                this.isTyres = response.Drawing__r.WheelProduct__c === 'Tyres';
                this.isWheelsets = response.Drawing__r.WheelProduct__c === 'Wheelsets';
                this.isAxles = response.Drawing__r.WheelProduct__c === 'Axles';
                this.isWheelsOrAxles = this.isWheels || this.isAxles;

                this.orderItem = response;
                console.log('orderItem : ', this.orderItem);
            })
            .catch((error) => {
            console.error('Error: ', error);
            });

        getUserLanguage().then(result =>{
            this.language = result;
            console.log('language : ', this.language);
        })
    }

    get nameForDoc() {
        return this.orderItem.NameForDoc_Formula__c ? this.orderItem.NameForDoc_Formula__c : 'n/a';
    }

    get prodDetails() {
        return this.orderItem.ProdDetails__c ? this.orderItem.ProdDetails__c : 'n/a';
    }

    get imbalance() {
        return this.orderItem.KLWSpec__r.Imbalance__r ? this.orderItem.KLWSpec__r.Imbalance__r.Name : 'n/a';
    }

    get execCategory() {
        return this.orderItem.KLWSpec__r.ExecCategory__c ? this.orderItem.KLWSpec__r.ExecCategory__c : 'n/a';
    }

    get marking() {
        return this.orderItem.KLWSpec__r.Marking__r ? this.orderItem.KLWSpec__r.Marking__r.Name : 'n/a';
    }

    get steelGrade() {
        return this.orderItem.KLWSpec__r.SteelGrade__r ? this.orderItem.KLWSpec__r.SteelGrade__r.Name : 'n/a';
    }

    get standard() {
        return this.orderItem.KLWSpec__r.Standard__r ? this.orderItem.KLWSpec__r.Standard__r.Name : 'n/a';
    }

    get axleBox() {
        return this.orderItem.KLWSpec__r.AxleBox__r ? this.orderItem.KLWSpec__r.AxleBox__r.Name : 'n/a';
    }

    get bearer() {
        return this.orderItem.KLWSpec__r.Bearer__r ? this.orderItem.KLWSpec__r.Bearer__r.Name : 'n/a';
    }

    get oilHole() {
        return this.orderItem.OilHole__c ? this.orderItem.OilHole__c : 'n/a';
    }

    get coverType() {
        return this.orderItem.KLWSpec__r.CoatingType__r ? 
               this.language == 'uk' ? this.orderItem.KLWSpec__r.CoatingType__r.NameUKR__c :
               this.language == 'ru' ? this.orderItem.KLWSpec__r.CoatingType__r.Name :
               this.orderItem.KLWSpec__r.CoatingType__r.NameENG__c : 'n/a';
    }

    get cover() {
        return this.orderItem.KLWSpec__r.Coating__r ? this.orderItem.KLWSpec__r.Coating__r.Name : 'n/a';
    }

    get packing() {
        return this.orderItem.KLWSpec__r.Packing__r ? 
               this.language == 'uk' ? this.orderItem.KLWSpec__r.Packing__r.NameUKR__c :
               this.language == 'ru' ? this.orderItem.KLWSpec__r.Packing__r.Name :
               this.orderItem.KLWSpec__r.Packing__r.NameENG__c : 'n/a';
    }

    get inspection() {
        return this.orderItem.KLWSpec__r.Inspection__r ? 
               this.language == 'uk' ? this.orderItem.KLWSpec__r.Inspection__r.NameUKR__c :
               this.language == 'ru' ? this.orderItem.KLWSpec__r.Inspection__r.Name :
               this.orderItem.KLWSpec__r.Inspection__r.NameENG__c : 'n/a';
    }

    get purpose() {
        return this.orderItem.KLWSpec__r.Purpose__r ? this.orderItem.KLWSpec__r.Purpose__r.Name : 'n/a';
    }

    get purpose() {
        return this.orderItem.KLWSpec__r.Purpose__r ? 
               this.language == 'uk' ? this.orderItem.KLWSpec__r.Purpose__r.NameUKR__c :
               this.language == 'ru' ? this.orderItem.KLWSpec__r.Purpose__r.NameRUS__c :
               this.orderItem.KLWSpec__r.Purpose__r.Name : 'n/a';
    }

    get weightKG() {
        return this.orderItem.KLWSpec__r.WeightKG__c ? this.orderItem.KLWSpec__r.WeightKG__c : 'n/a';
    }

    get hasSpecReq() {
        return this.orderItem.HasSpecReq__c ? this.labels.yes : this.labels.no;
    }

    get shape() {
        return this.orderItem.KLWSpec__r.Shape__r ? this.orderItem.KLWSpec__r.Shape__r.Name : 'n/a';
    }

    get specWheel() {
        return this.orderItem.KLWSpec__r.SpecWheel__r ? this.orderItem.KLWSpec__r.SpecWheel__r.Name : 'n/a';
    }

    get specAxle() {
        return this.orderItem.KLWSpec__r.SpecAxle__r ? this.orderItem.KLWSpec__r.SpecAxle__r.Name : 'n/a';
    }

    get plugType() {
        return this.orderItem.KLWSpec__r.PlugType__r ? this.orderItem.KLWSpec__r.PlugType__r.Name : 'n/a';
    }
}