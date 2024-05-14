import { LightningElement, api } from 'lwc';
import {FlowNavigationBackEvent, FlowNavigationNextEvent} from 'lightning/flowSupport';

export default class Universign_FlowFooter extends LightningElement {

    //Cancel 
    @api disablePrevious = false;
    @api hidePreviousBtn = false;
    @api previousLabel = "Previous";

    //Refresh
    @api hideNextBtn = false;
    @api disableNext = false;
    @api nextLabel = "Next";

    //Relaunch
    @api hideRelaunchBtn = false;
    @api relaunchButtonLabel = 'Relaunch';
    @api disableRelaunchBtn = false;

    //Technicalities..
    @api selectedPrevious = false;
    @api isDebug = false;
    @api selection = 'Refresh';

    connectedCallback(){
        if(this.isDebug) console.log('hideNextBtn', this.hideNextBtn);
        if(this.isDebug) console.log('hidePreviousBtn', this.hidePreviousBtn);
    }

    get HideNextButton(){
        return this.hideNextBtn ? "slds-hide" : "";
    }

    get HidePreviousButton(){
        return this.hidePreviousBtn ? "slds-hide" : "slds-m-right_x-small";
    }

    get HideRelaunchButton(){
        return this.hideRelaunchBtn ? "slds-hide" : "slds-m-left_x-small";
    }

    handleNext(event){
        this.selection = 'Refresh'
        this.selectedPrevious = false;
        this.handleNavigate(event);
    }

    handlePrevious(event){
        this.selection = 'Cancel'
        this.selectedPrevious = true;
        this.handleNavigate(event);
    }

    handleRelaunchBtn(event){
        this.selection = 'Relaunch'
        this.selectedPrevious = true;
        this.handleNavigate(event);
    }

    handleNavigate(event){
        const navigateNextEvent = new FlowNavigationNextEvent();
        try {
            this.dispatchEvent(navigateNextEvent);
            if(this.isDebug) if(this.isDebug) console.log('navigateNextEvent dispatchedSuccesfully');
        } catch (ex) {
            if(this.isDebug) if(this.isDebug) console.log('Exception: ' + ex);
        }
    }

}