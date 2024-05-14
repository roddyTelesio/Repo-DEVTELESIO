import { LightningElement, api, wire } from 'lwc';
import {FlowNavigationBackEvent, FlowNavigationNextEvent,FlowNavigationFinishEvent} from 'lightning/flowSupport';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import {fireEvent, registerListener} from 'c/pubSub';
import {CurrentPageReference } from 'lightning/navigation';
import updateToastMessageOnFlow from '@salesforce/apex/flowCustFootUpdateToastMess.updateToastMessageOnFlow';
import {refreshApex} from '@salesforce/apex';

export default class SignatoryCustomFooter extends LightningElement {
    @api nextLabel = "Add";
    @api newContactLabel = "Create New Contact" ;
    @api disableNext = false;
    @api isDebug = false;
    @api addContact ; 

    handleCreateNewContact(){
        this.addContact = true ;
        const navigateNextEvent = new FlowNavigationNextEvent();
        try {
            this.dispatchEvent(navigateNextEvent);
            console.log('navigateNextEvent dispatchedSuccesfully',this.addContact);
            if(this.isDebug) if(this.isDebug) console.log('navigateNextEvent dispatchedSuccesfully');
        } catch (ex) {
            if(this.isDebug) if(this.isDebug) console.log('Exception: ' + ex);
        }
    }

    handleNext(){
        this.addContact = false ;
        const navigateNextEvent = new FlowNavigationNextEvent();
        try {
            this.dispatchEvent(navigateNextEvent);
            console.log('navigateNextEvent ',this.addContact);
            if(this.isDebug) if(this.isDebug) console.log('navigateNextEvent dispatchedSuccesfully');
        } catch (ex) {
            if(this.isDebug) if(this.isDebug) console.log('Exception: ' + ex);
        }
    }

}