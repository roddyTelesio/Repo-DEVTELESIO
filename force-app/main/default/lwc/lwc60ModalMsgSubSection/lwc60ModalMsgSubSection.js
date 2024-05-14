import { api } from 'lwc';
import LightningModal from 'lightning/modal';
 
export default class Lwc60ModalMsgSubSection extends LightningModal {
    @api someDataSection;
    @api columnSections;
    @api label;
    //@api isDisableBtn = false;
    handleCancel(event) {
        this.close('OK');
    }
    
    /*handleGoHome(){
        let hostname = window.location.hostname;
        location.assign('https://' + hostname);
        console.log('hostname == ', hostname);
        
      
    }*/
}