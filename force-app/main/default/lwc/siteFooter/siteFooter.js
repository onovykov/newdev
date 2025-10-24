import { LightningElement } from 'lwc';
import IMAGES from "@salesforce/resourceUrl/SiteImages";
import getUserLanguage from '@salesforce/apex/UserUtils.getUserLanguage';
import getBusinessDivision from '@salesforce/apex/UserUtils.getBusinessDivision';
export default class SiteFooter extends LightningElement {

    siteFooterLogo;
    footerLogoUA = IMAGES + '/InterpipeLogoFooterLogo.png';
    footerLogoEN = IMAGES + '/interpipeLogoENFooter.png';
    footerLogoRU = IMAGES + '/interpipeLogoRUFooter.png';
    footerLogoKLW = IMAGES + '/LogoKLW_Footer.png';

    VectorYoutube = IMAGES + '/VectorYoutube.png';
    VectorLinkedIn = IMAGES  + '/VectorLinkedIn.png';
    VectorInstagram = IMAGES  + '/VectorInstagram.png';
    VectorFacebook = IMAGES + '/VectorFacebook.png';

    currentYear;


    connectedCallback(){
        const currentDate = new Date();
        this.currentYear = currentDate.getFullYear();
        getUserLanguage().then(result => {
            if(result == 'uk'){
                this.siteFooterLogo = this.footerLogoUA; 
            }else if(result =='ru'){
                this.siteFooterLogo = this.footerLogoRU;
            }else{
                this.siteFooterLogo = this.footerLogoEN;
            }

        }).catch(error =>{
            console.log(error);
        })

        getBusinessDivision().then(businessDivision => {
            if(businessDivision == 'Railway') {
                this.siteFooterLogo = this.footerLogoKLW;
            }
        })
    }
}