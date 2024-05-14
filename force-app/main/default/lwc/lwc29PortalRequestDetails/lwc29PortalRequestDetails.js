import {LightningElement, track, wire, api} from 'lwc';
import {getPicklistValues} from 'lightning/uiObjectInfoApi';
import {getObjectInfo} from 'lightning/uiObjectInfoApi';
import PROGRAM_OBJECT from '@salesforce/schema/Program__c';
import UWYEAR_FIELD from '@salesforce/schema/Program__c.UwYear__c';
import getAcc from '@salesforce/apex/LWC01_WorkingScope.getPrincipalCedingAcc';
import {NavigationMixin, CurrentPageReference} from 'lightning/navigation';
import {registerListener, unregisterAllListeners, fireEvent} from 'c/pubSub';

export default class LWC29_PortalRequestDetails extends LightningElement {

    @api valProgramId;
    @api valReinsurerId;
    @api valBrokerId;
    @api valStageName;
    isEndorsement = false;
    isSigning = false;
    isPlacement = false;
    isLead = false;
    isQuote = false;
    selectedRequestId;

    @wire(CurrentPageReference) pageRef;
    connectedCallback(){
        registerListener('year', this.getVal, this);
        registerListener('comp', this.getComp, this);

        //window.location.href --- old line 
        //Changes done due to issues after Summer '21
        let currentUrl = this.pageRef.state;
        let nameUrl = null;
        let param = 'c__details';
        let paramValue = null;

        if(this.pageRef.attributes.apiName != null && this.pageRef.attributes.apiName != undefined){
            nameUrl = this.pageRef.attributes.apiName;
        }
        else if(this.pageRef.attributes.name != null && this.pageRef.attributes.name != undefined){
            nameUrl = this.pageRef.attributes.name;
        }

        if(currentUrl != undefined && currentUrl != null){
            paramValue = currentUrl[param];
        }

        if(paramValue != null){
            let parameters = paramValue.split("-");
            if(parameters[0] != undefined){
                if(parameters[2] == 'Signing'){
                    this.isSigning = true;
                    this.valProgramId = parameters[0];
                    this.selectedRequestId = parameters[1];
                    this.valStageName = parameters[2];
                }else{
                    this.valProgramId = parameters[0];
                    this.valReinsurerId = parameters[1];
                    this.valBrokerId = parameters[2];
                    this.valStageName = parameters[3];
    
                    if(parameters[3] != undefined && parameters[3] != null){
                        if(parameters[3] == 'Endorsement'){
                            this.isEndorsement = true;
                        }
                        else if(parameters[3] == 'Placement'){
                            this.isPlacement = true;
                        }
                        else if(parameters[3] == 'Lead'){
                            this.isLead = true;
                        }
                        else if(parameters[3] == 'Quote'){
                            this.isQuote = true;
                        }
                    }
                }

            }
        }
    }

    getUrlParamValue(url, key) {
        return new URL(url).searchParams.get(key);
    }

    getVal(val){
        this.valueUWYear = val;
    }

    getComp(val){
        this.valuePrincipalCedComp = val;
    }

}