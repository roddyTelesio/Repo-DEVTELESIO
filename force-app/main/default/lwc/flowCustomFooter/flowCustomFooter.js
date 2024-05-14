import { LightningElement, api, wire } from 'lwc';
import {FlowNavigationBackEvent, FlowNavigationNextEvent,FlowNavigationFinishEvent} from 'lightning/flowSupport';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import {fireEvent, registerListener} from 'c/pubSub';
import {CurrentPageReference } from 'lightning/navigation';
import updateToastMessageOnFlow from '@salesforce/apex/flowCustFootUpdateToastMess.updateToastMessageOnFlow';
import getInfoWorkingScope from '@salesforce/apex/flowCustFootUpdateToastMess.getInfoWorkingScope';
import {refreshApex} from '@salesforce/apex';

//RRA - ticket 1532 - 14062023  
//Custom Label
import NoSubsectionTickedAsPrincipale from '@salesforce/label/c.NoSubsectionTickedAsPrincipale';

//import { NavigationMixin } from 'lightning/navigation';


export default class customFooter extends LightningElement { //NavigationMixin(LightningElement) {}

    @api disablePrevious = false;
    @api disableNext = false;
    @api disableCancel = false;
    @api disableFinish = false;
    @api recordId; // Id Section

    @api nextLabel = "Next";
    @api previousLabel = "Cancel";
    @api finishLabel = "Finish";
    showLoadingSpinner = false;

    @api hideNextBtn = false;
    @api hidePreviousBtn = false;
    @api hideFinishBtn = false;
    @api lstSubSection;
    @api lstReinstatement;
    @api typeReins;
    @api typeReinsInDB;
    @api typeExistingReinsInDB;
    @api lstSubSecEvent;//RRA - ticket 1532 - 14062023     

    @api isDebug = false;

    @wire(CurrentPageReference) pageRef;
    
    //RRA - ticket 1532 - 14062023  
    label = {
        NoSubsectionTickedAsPrincipale
    }

    connectedCallback(){
        this.register();
        registerListener('changeReins', this.valReinsType, this);
        registerListener('typeOtherInDB', this.typeOthers, this);
        registerListener('typeExistingReinsInDB', this.typeExistingReins, this);
        this.updateToastMessageOnFlow();
        if(this.isDebug) console.log('hideNextBtn', this.hideNextBtn);
        if(this.isDebug) console.log('hidePreviousBtn', this.hidePreviousBtn);
        registerListener('requiredFieldPrincipSubSec', this.lstSubSecEvents, this);//RRA - ticket 1532 - 14062023        
    }

    updateToastMessageOnFlow (){
        updateToastMessageOnFlow({ idSection : this.recordId})
        .then(result => {
            refreshApex (result);
            console.log('Update SuccessErrorToastMessageOnFlow__c done')
        })
        .catch(error => {
            this.error = error;
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error'}), );
        });
    }

    get HideNextButton(){
        return this.hideNextBtn ? "slds-hide" : "";
    }

    get HidePreviousButton(){
        return this.hidePreviousBtn ? "slds-hide" : "slds-m-right_x-small";
    }

    get HideFinishButton(){
        return this.hideFinishBtn ? "slds-hide" : "slds-m-right_x-small";
    }

    register(){
        if(this.isDebug) console.log('event registered: customFooter');
        console.log('this.lstSubSection == ', this.lstSubSection);
    }

    valReinsType(val){
        console.log('valReqType = ', val);
        this.typeReins = val;

    }

    
    typeOthers(val){
        console.log('typeOthers = ', val);
        this.typeReinsInDB = val;
    }

    typeExistingReins(val){
        console.log('typeExistingReins = ', val);
        this.typeExistingReinsInDB = val;
    }
    
    //RRA - ticket 1532 - 14062023     
    lstSubSecEvents(val){
        console.log('lstSubSecEvent = ', val);
        this.lstSubSecEvent = val;
    }

    handleFinish(){
        if(this.isDebug) console.log('handleFinishevent START');
        console.log('this.lstSubSecEvent == ', this.lstSubSecEvent);   
        let isPrincipaleSubSec = false;
        
        //RRA - ticket 1532 - 14062023     
        for (let i=0;i<this.lstSubSection.length;i++){
            let row ={...this.lstSubSection[i]};
            if (row.PrincipalSubSection__c){
                isPrincipaleSubSec = true;
            }
        }
        
        console.log('isPrincipaleSubSec == ', isPrincipaleSubSec);
        
        if (isPrincipaleSubSec){
            this.getWorkingScopeInfo(this.recordId);
        }else {
            if (this.lstSubSecEvent == undefined){ 
                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.NoSubsectionTickedAsPrincipale, variant: 'error'}), );
            }else{
                this.getWorkingScopeInfo(this.recordId);
            }
        }
         // Navigate to a URL
        //let openedWindow= '../r/Section__c/a0B2o0000217KpcEAE/edit';
         //window.open(openedWindow)

        if(this.isDebug) console.log('handleFinishevent END');
    }
    
    //refresh parent tab (tab home / treatyPlacement) from another tab (tab sunsection) if subsection page is clicked 
    //RRA - ticket 1532 - 22062023
    getWorkingScopeInfo (secId){
        getInfoWorkingScope({ idSection : secId})
            .then(resultSection => {
                let idProg;
                let uwy;
                let pcc;
                var hostname = window.location.hostname;
                console.log('resultSection == ',resultSection);
                if (resultSection.length > 0){
                    for (let i=0;i<resultSection.length;i++){
                            let rowSec = {...resultSection[i]};
                            uwy = rowSec.Program__r.UwYear__c;
                            pcc = rowSec.Program__r.PrincipalCedingCompany__c;
                            idProg = rowSec.Program__c;
                    }
                }
                window.opener.location = '../n/TreatyPlacement?c__program=' + idProg + '-' + uwy + '-' + pcc + '-Conditions-undefined'+'-undefined'+'-undefined'+'-undefined';//RRA - ticket 1533 - 19062023;
                window.close();
            })
            .catch(error => {
                this.error = error;
                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error'}), );
            });
    }

    handleNext(event){
        console.log('okok');
        console.log('this.nextLabel == ', this.nextLabel);
        console.log('this.record == ', this.record);
        console.log('this.typeReins == ', this.typeReins);
        console.log('this.typeReinsInDB == ', this.typeReinsInDB);
        console.log('this.lstReinstatement == ', this.lstReinstatement);
        console.log('this.typeExistingReinsInDB == ', this.typeExistingReinsInDB);
        //console.log('this.lstReinstatement[0].Type__c == ', this.lstReinstatement[0].Type__c);
        // Screen Create SubSection => Creation
        if (this.nextLabel == 'Save'){
            this.showLoadingSpinner = true;
            if ((this.typeReins != null || this.typeReins != undefined)  && (this.typeReins == '1' || this.typeReins == '2' || this.typeReins == '3')){
                const navigateNextEvent = new FlowNavigationNextEvent();
                try {
                    this.dispatchEvent(navigateNextEvent);
                    if(this.isDebug) if(this.isDebug) console.log('navigateNextEvent dispatchedSuccesfully');
                } catch (ex) {
                    if(this.isDebug) if(this.isDebug) console.log('Exception: ' + ex);
                }
            }else if (this.typeReinsInDB != undefined || this.typeReinsInDB != null){
                    const navigateNextEvent = new FlowNavigationNextEvent();
                    try {
                        this.dispatchEvent(navigateNextEvent);
                        if(this.isDebug) if(this.isDebug) console.log('navigateNextEvent dispatchedSuccesfully');
                    } catch (ex) {
                        if(this.isDebug) if(this.isDebug) console.log('Exception: ' + ex);
                    }
            }else if (this.typeExistingReinsInDB != undefined || this.typeExistingReinsInDB != null){
                    const navigateNextEvent = new FlowNavigationNextEvent();
                    try {
                        this.dispatchEvent(navigateNextEvent);
                        if(this.isDebug) if(this.isDebug) console.log('navigateNextEvent dispatchedSuccesfully');
                    } catch (ex) {
                        if(this.isDebug) if(this.isDebug) console.log('Exception: ' + ex);
                    }
            }else{
                fireEvent(this.pageRef, 'requiredFieldTypeReins', 'slds-has-error');
                console.log('okok222');
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: '** Required Field **',
                        message: 'Type of Reinstatement is required',
                        variant: 'error'
                    })
                );
            }

            this.showLoadingSpinner = false;
        // Screen list SubSection => Edition
        }else if (this.nextLabel == 'Add New Subsection'){
            this.showLoadingSpinner = true;
            const navigateNextEvent = new FlowNavigationNextEvent();
            try {
                this.dispatchEvent(navigateNextEvent);
                //fireEvent(this.pageRef, 'refreshCond', 'refreshConditions');
                if(this.isDebug) if(this.isDebug) console.log('navigateNextEvent dispatchedSuccesfully');
            } catch (ex) {
                if(this.isDebug) if(this.isDebug) console.log('Exception: ' + ex);
            }
            //window.location.assign(); //used to load a new SubSection
            //this.showLoadingSpinner = false;
           
        }
        
        
    }

    handlePrevious(event){
        // Check if lstSubSection exists => go to the previous list subsections
        if (this.lstSubSection != null || this.lstSubSection != undefined){ 
            const navigatePreviousEvent = new FlowNavigationBackEvent();
            try {
                this.dispatchEvent(navigatePreviousEvent);
                if(this.isDebug) if(this.isDebug) console.log('navigatePreviousEvent dispatchedSuccesfully');
            } catch (ex) {
                if(this.isDebug) console.log('Exception: ' + ex);
            }
        // if no, close the window subsection creation / Edit Subsections   
        }else{
            window.close();
        }
        
    }

}