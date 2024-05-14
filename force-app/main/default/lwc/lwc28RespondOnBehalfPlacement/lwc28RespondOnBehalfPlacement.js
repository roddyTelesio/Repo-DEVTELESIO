import {LightningElement, track, wire, api} from 'lwc';
import {refreshApex} from '@salesforce/apex';
import {registerListener, fireEvent} from 'c/pubSub';
import {NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import {getObjectInfo} from 'lightning/uiObjectInfoApi';
import {getPicklistValues, getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';

export default class LWC28_RespondOnBehalfPlacement extends LightningElement {
    @api requestObj;
    @api stage;
    isStagePlacement = false;
    isStageLead = false;

    @wire(CurrentPageReference) pageRef;
    connectedCallback(){
        if(this.stage == 'Placement'){
            this.isStagePlacement = true;
        }
        else if(this.stage == 'Lead'){
            this.isStageLead = true;
        }
    }
}