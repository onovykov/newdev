import { LightningElement,api,track,wire } from 'lwc';
import GetResourceURL from '@salesforce/apex/DisplayImageController.getResourceURL'
import getUserLanguage from '@salesforce/apex/UserUtils.getUserLanguage';
export default class CustomCarouselWrapper extends LightningElement {
    @track slides;
    @api image ='';
    @api imageUA ='';
    @api imageRU ='';
    @track imgURL= false;
    resource;

    connectedCallback(){
        getUserLanguage().then(result =>{
            console.log('result---------> ' , result);
            if(result == 'uk'){
                this.resource = this.imageUA; 
            }else if(result == 'ru'){
                this.resource = this.imageRU;
            }else{
                this.resource = this.image;
            }
            GetResourceURL({resourceName :  this.resource}).then(data =>{
                let slides = [];
                data.forEach(res=>{
                    slides.push(
                        {['image'] : res}
                    );
                });
                this.slides = slides;
            });
        })
        .catch(error =>{
            console.error(error);
        })
    }
    
}