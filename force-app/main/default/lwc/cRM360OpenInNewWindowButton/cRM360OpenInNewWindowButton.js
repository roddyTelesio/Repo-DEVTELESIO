import { LightningElement, api } from 'lwc';
import { FlowNavigationNextEvent} from 'lightning/flowSupport';

export default class CRM360OpenInNewWindowButton extends LightningElement {
    @api openLabel = "Full screen";
    @api url ;
    @api isDebug = false;

    handleOpenURL(event){
        try {
            window.open(this.url, '_blank').focus();
            if(this.isDebug) if(this.isDebug) console.log('navigateNextEvent dispatchedSuccesfully',this.url);
        } catch (ex) {
            if(this.isDebug) if(this.isDebug) console.log('Exception: ' + ex);
        }
    }
}