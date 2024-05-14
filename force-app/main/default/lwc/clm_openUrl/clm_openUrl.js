import { LightningElement, api } from 'lwc';

export default class Clm_openURL extends LightningElement {
    @api url ;
    @api isDebug = false;

    connectedCallback(){
        try {
            // window.open(this.url, '_blank').focus();
            window.location.href = this.url
            if(this.isDebug) if(this.isDebug) console.log('navigateNextEvent dispatchedSuccesfully',this.url);
        } catch (ex) {
            if(this.isDebug) if(this.isDebug) console.log('Exception: ' + ex);
        }
    }
}