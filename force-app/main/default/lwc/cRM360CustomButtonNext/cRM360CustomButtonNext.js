import { LightningElement, api } from 'lwc';
import { FlowNavigationNextEvent} from 'lightning/flowSupport';

export default class CRM360CustomButtonNext extends LightningElement {
    @api nextLabel = "Refresh";
    handleNext(event){
        const navigateNextEvent = new FlowNavigationNextEvent();
        try {
            this.dispatchEvent(navigateNextEvent);
            if(this.isDebug) if(this.isDebug) console.log('navigateNextEvent dispatchedSuccesfully');
        } catch (ex) {
            if(this.isDebug) if(this.isDebug) console.log('Exception: ' + ex);
        }
    }
}