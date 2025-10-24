import { LightningElement, api, track, wire } from 'lwc';
import GetResourceURL from '@salesforce/apex/DisplayImageController.getResourceURL';
import getUserLanguage from '@salesforce/apex/UserUtils.getUserLanguage';

export default class SiteBanner extends LightningElement {
  finalBannerText;
  @api Image1 = '';
  @api ImageKLW = '';
  @api BannerTextEN;
  @api BannerTextRU;
  @api BannerTextUA;
  @track img1URL;
  @track backgroundStyle = '';
  @track screenWidth;

  @wire(GetResourceURL, { resourceName: '$Image1', resourceNameKLW: '$ImageKLW' }) wiredResourceURL({ data, error }) {
    if (data) {
      let slides = [];
      data.forEach(res => {
        slides.push({ ['Image1']: res });
      });
      
      this.img1URL = slides[0].Image1;
      this.updateBackgroundStyle();
    } else if (error) {
      console.log(error);
    }
  }

  connectedCallback() {
    this.screenWidth = window.innerWidth;
    this.updateBackgroundStyle();
    window.addEventListener('resize', this.handleResize.bind(this));
    getUserLanguage().then((result) => {
      // console.log('result---------> ', result);
      if (result === 'uk') {
        this.finalBannerText = this.BannerTextUA;
      } else if (result === 'ru') {
        this.finalBannerText = this.BannerTextRU;
      } else {
        this.finalBannerText = this.BannerTextEN;
      }
      this.updateBackgroundStyle();
    });
  }

  handleResize() {
    this.screenWidth = window.innerWidth;
    this.updateBackgroundStyle();
  }

  updateBackgroundStyle() {
    if (this.screenWidth < 575.98) {
      this.backgroundStyle =
        'height: 48px; display: flex; align-items: center; justify-content: center; border-radius: 16px; background-color: #FFDD00; background-repeat: no-repeat; background-size: 100% 48px;';
    } else {
      this.backgroundStyle = `height: 130px; display: flex; align-items: center; background-image: url(${this.img1URL}); background-repeat: no-repeat; background-size: 100% 130px;`;
    }
  }
}