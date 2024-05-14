import { LightningElement, wire, api } from 'lwc';
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import checkExistingKeysIntObj from "@salesforce/apex/LWC56_SynchronizeIntermediateObj.checkExistingKeysIntObj";
import deleteAndRecalculateKeysIntObj from "@salesforce/apex/LWC56_SynchronizeIntermediateObj.deleteAndRecalculateKeysIntObj";
 
export default class Lwc56SynchronizeIntermediateObject extends LightningElement {
    @api recordId;
    @api isDisable = false;
    @api isKeyExist;
    @api displaySpinner;
    @api messageUser;
    @api isAppearMessage;
    //@wire(toastMsg)
    //toast;

    /*notification() {
        const evt = new ShowToastEvent({
            title: "Message",
            message: this.toast.data.Message__c,
            variant: "info"
        });
        this.dispatchEvent(evt);
    }*/

    connectedCallback() {
       // console.log('this.recordId222== ', this.recordId);
       // SRA - ticket 860 
        this.loadCheckExistingKeysIntObj();   
    }

    updateRecordView() {
        setTimeout(() => {
             eval("$A.get('e.force:refreshView').fire();");
        }, 1000); 
     }

    loadCheckExistingKeysIntObj(){
        console.log('this.recordId== ', this.recordId);
        checkExistingKeysIntObj({ idContact : this.recordId})
        .then(result => {
            if (result !=null){
                console.log('this.result== ', result);
                //this.dispatchEvent(new ShowToastEvent({title: 'Warning - No keys for the visibility of the requests', message: result, variant: 'warning', mode: 'dismissible'}), );
                this.isKeyExist = false;
                this.messageUser = 'This Contact seems have some sharing issues, please click above button to reinitialize';
                this.isAppearMessage = true;
            }else{
                
                this.isKeyExist = true;
                this.messageUser = null;
                //window.location.reload(true);
                //return false;
            }
            
        })
        .catch(error => {
            this.dispatchEvent(new ShowToastEvent({title: 'Error Message', message: error.message, variant: 'error'}), );
        });
    }

    handleClick(){
        this.displaySpinner = true;
        console.log('this.recordId== ', this.recordId);
        deleteAndRecalculateKeysIntObj({ idContact : this.recordId})
        .then(result => {
            if (result !=null){
                
                this.dispatchEvent(new ShowToastEvent({title: 'Successfully', message: result, variant: 'success'}), );
                this.isKeyExist = true;
                this.isAppearMessage = false;
                this.messageUser = null;
                //this.updateRecordView();
                this.displaySpinner = false;
            }else{
                this.isKeyExist = false;
            }
        })
        .catch(error => {
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: error.message, variant: 'error'}), );
        });
        
    }
}