import { LightningElement,api } from 'lwc';
import {registerListener, fireEvent} from 'c/pubSub';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
 
export default class Lwc01MessageToastOnFlow extends LightningElement {
    @api successOrErrorMessage;
    @api errorMessage;
    connectedCallback(){
        console.log('Begin toast = ');
        console.log('this.successOrErrorMessage ', this.successOrErrorMessage);
        if(this.successOrErrorMessage == 'Section Updated Successfully.'){
            //this.isLoading = true;
            //setTimeout(() => { eval("$A.get('e.force:refreshView').fire();");  }, 1000);
            this.dispatchEvent(new ShowToastEvent({title: 'Success', message: 'Section Updated Successfully.', variant: 'success' }),); 
            window.location.reload();
            //window.setTimeout(function(){location.reload()},1000)
        }else if(this.successOrErrorMessage == 'An error has occurred. Please contact your System Administrator.') {
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: 'An error has occurred. Please contact your System Administrator.<', variant: 'error' }),);
        }
        //this.isLoading = false;
    }
}