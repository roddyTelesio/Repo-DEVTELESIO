import {LightningElement, track, wire, api} from 'lwc';
import {getPicklistValues} from 'lightning/uiObjectInfoApi';
import {getObjectInfo} from 'lightning/uiObjectInfoApi';
import PROGRAM_OBJECT from '@salesforce/schema/Program__c';
import UWYEAR_FIELD from '@salesforce/schema/Program__c.UwYear__c';
import getAcc from '@salesforce/apex/LWC01_WorkingScope.getPrincipalCedingAcc';
import getAccPortal from '@salesforce/apex/LWC01_WorkingScope.getPrincipalCedingAcc';
import {NavigationMixin, CurrentPageReference} from 'lightning/navigation';
import {registerListener, unregisterAllListeners, fireEvent} from 'c/pubSub';
import {loadStyle, loadScript} from 'lightning/platformResourceLoader';
import HideLightningHeader from '@salesforce/resourceUrl/HideLightningHeader';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import getProgramNature from '@salesforce/apex/LWC46_WorkingScopeSpecialAcceptance.getProgramNature';
import getPrograms from '@salesforce/apex/LWC46_WorkingScopeSpecialAcceptance.getPrograms';

//import custom labels
import WorkingScope from '@salesforce/label/c.Working_Scope';
import UWYear from '@salesforce/label/c.UWYear';
import PrincipalCedingCompany from '@salesforce/label/c.PrincipalCedingCompany';
import errorMsg from '@salesforce/label/c.errorMsg';

//import field
import NATURE_FIELD from '@salesforce/schema/Program__c.Nature__c';

export default class Lwc46WorkingScopeSpecialAcceptance extends NavigationMixin(LightningElement) {
    error;
    @api valueUwYear;
    @api valuePrincipalCedComp;
    @api isModalCopy = false;
    @api isModalNew = false;
    @api isModalRenew = false;
    @api isModalEdit = false;
    @api isCEUser = false;
    @api isCeLoadSaReq = false;
    @api valueCedingProgram;
    @api programModal;
    @api programRenewedModal;
    @api valueCedingProgramOldValue;
    @track natureOpt = [];
    uwYearOpt;
    cedingAccOpt;
    programOptions; 
    natureProgram;
    programNameModal;
    isModal = false;
    selectedNature = null;
    valueCEProgram;
    mapNature = new Map();

    label = {
        WorkingScope,
        UWYear,
        PrincipalCedingCompany,
        errorMsg
    };

    @wire(getObjectInfo, { objectApiName: PROGRAM_OBJECT })
    objectInfo;

    getUrlParamValue(url, key) {
        return new URL(url).searchParams.get(key);
    }

    @wire(CurrentPageReference) pageRef;
    connectedCallback() {
        //window.location.href --- old line 
        //Changes done due to issues after Summer '21
        let currentUrl = this.pageRef.state;
        let nameUrl = null;

        if(this.pageRef.attributes.apiName != null && this.pageRef.attributes.apiName != undefined){
            nameUrl = this.pageRef.attributes.apiName;
        }
        else if(this.pageRef.attributes.name != null && this.pageRef.attributes.name != undefined){
            nameUrl = this.pageRef.attributes.name;
        }

        if(nameUrl == 'SADetail__c'){
            // if(currentUrl.includes('cedingPortal/s/SADetail')){
            //Edit - Ceding Portal User
            this.isModalEdit = true;
            let param = 's__id';
            let paramValue = null;

            if(currentUrl != undefined && currentUrl != null){
                paramValue = currentUrl[param];
            }

            if(paramValue != null){
                let parameters = paramValue.split("-");
                if(parameters[1] != undefined){
                    this.valueUwYear = parameters[1];
                }

                if(parameters[2] != undefined){
                    this.valuePrincipalCedComp = parameters[2];
                }

                if(parameters[3] != undefined){
                    this.programModal = parameters[3];
                }
            }
        }
        else if(nameUrl == 'Home'){
            // else if(currentUrl.includes('cedingPortal/s/')){
            //Ceding Portal User
            let param = 's__id';
            let paramValue = null;

            if(currentUrl != undefined && currentUrl != null){
                paramValue = currentUrl[param];
            }

            if(paramValue != null){
                let parameters = paramValue.split("-");
                if(parameters[0] != undefined){
                    this.valueUwYear = parameters[0];
                }

                if(parameters[1] != undefined){
                    this.valuePrincipalCedComp = parameters[1];
                }

                if(parameters[2] != undefined){
                    this.valueCedingProgram = parameters[2];
                    this.valueCedingProgramOldValue = 'url';
                }
            }
        } 
        else if(nameUrl == 'SpecialAcceptance'){
            // else if(currentUrl.includes('lightning/n/SpecialAcceptance')){
            //CE user
            this.isCEUser = true;
            let param = 's__id';
            let paramValue = null;

            if(currentUrl != undefined && currentUrl != null){
                paramValue = currentUrl[param];
            }

            if(paramValue != null){
                let parameters = paramValue.split("-");
                if(parameters[0] != undefined){
                    this.valueUwYear = parameters[0];
                }

                if(parameters[1] != undefined){
                    this.valuePrincipalCedComp = parameters[1];
                }

                if(parameters[2] != undefined){
                    this.valueCEProgram = parameters[2];
                    this.valueCedingProgramOldValue = 'url';
                }
            }
        }
        else if(nameUrl == 'LoadSARequest'){
            // else if(currentUrl.includes('lightning/n/LoadSARequest')){
            //Edit - CE user
            let param = 's__id';
            let paramValue = null;

            if(currentUrl != undefined && currentUrl != null){
                paramValue = currentUrl[param];
            }

            this.isCEUser = true;
            this.isCeLoadSaReq = true;

            if(paramValue != null){
                let parameters = paramValue.split("-");
                if(parameters[1] != undefined){
                    this.valueUwYear = parameters[1];
                }

                if(parameters[2] != undefined){
                    this.valuePrincipalCedComp = parameters[2];
                }
            }
        }

        if(this.isModalCopy == true || this.isModalNew == true || this.isModalRenew == true || this.isModalEdit == true || this.isCeLoadSaReq == true){
            this.isModal = true;
        }
        else{
            this.isModal = false;
        }

        getAccPortal()
        .then(resultPortal => {
            this.cedingAccOpt = resultPortal;
            if(this.cedingAccOpt.length > 0){
                if(this.valuePrincipalCedComp == null || this.valuePrincipalCedComp == undefined){
                    this.valuePrincipalCedComp = this.cedingAccOpt[0].value;
                }

                if(this.isModal == false){
                    this.getPrograms();
                }
                
                fireEvent(this.pageRef, 'compSummary', this.valuePrincipalCedComp);
            }
        })
        .catch(error => {
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error'}), );
        });

        if(this.programRenewedModal != undefined && this.programRenewedModal != null){
            this.getProgramNature(this.programRenewedModal);
            this.valueCedingProgram = this.programRenewedModal;
            fireEvent(this.pageRef, 'valueSelectedProgram', this.programRenewedModal);
        }
        else if(this.programModal != undefined && this.programModal != null){
            this.getProgramNature(this.programModal);
            this.valueCedingProgram = this.programModal;
            fireEvent(this.pageRef, 'valueSelectedProgram', this.programModal);
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: UWYEAR_FIELD})
    setUWYearPicklistOptions({error, data}) {
        if(data){
            this.uwYearOpt = data.values;
            //window.location.href --- old line 
            //Changes done due to issues after Summer '21
            let currentUrl = this.pageRef.state;
            let nameUrl = null;

            if(this.pageRef.attributes.apiName != null && this.pageRef.attributes.apiName != undefined){
                nameUrl = this.pageRef.attributes.apiName;
            }
            else if(this.pageRef.attributes.name != null && this.pageRef.attributes.name != undefined){
                nameUrl = this.pageRef.attributes.name;
            }
            
            if(nameUrl == 'SADetail__c'){
            // if(currentUrl.includes('cedingPortal/s/SADetail')){
                let param = 's__id';
                let paramValue = null;

                if(currentUrl != undefined && currentUrl != null){
                    paramValue = currentUrl[param];
                }

                if(paramValue != null){
                    let parameters = paramValue.split("-");
                    if(parameters[1] != undefined){
                        this.valueUwYear = parameters[1];
                    }
                }

            }
            if(nameUrl == 'Home'){
            // else if(currentUrl.includes('cedingPortal/s/')){
                let param = 's__id';
                let paramValue = null;

                if(currentUrl != undefined && currentUrl != null){
                    paramValue = currentUrl[param];
                }

                if(paramValue != null){
                    let parameters = paramValue.split("-");
                    if(parameters[0] != undefined){
                        this.valueUwYear = parameters[0];
                    }
                }
                else if(this.valueUwYear == null || this.valueUwYear == undefined){
                     this.valueUwYear = data.values[data.values.length - 1].value;
                }
            }
            else if(this.valueUwYear == null || this.valueUwYear == undefined){
                 this.valueUwYear = data.values[data.values.length - 1].value;
            }

            if(this.isModal == false){
                this.getPrograms();
            }
        }
        else{
            this.error = error;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: NATURE_FIELD})
    setNaturePicklistOpt({error, data}) {
        if(data){
            this.natureOpt = [];
            this.mapNature = new Map();
            this.natureOpt.push({'label' : 'All', 'value' : 'All'});

            for(var i = 0; i < data.values.length; i++){
                let nature = { ...data.values[i] };
                nature['value'] =  data.values[i].label;
                this.natureOpt.push(nature);
                this.mapNature.set(data.values[i].value, data.values[i].label);
            }
        }
        else{
            this.error = error;
        }
    }

    handleChangeUWYr(event) {
        this.valueUwYear = event.detail.value;
        this.valueCedingProgram = null;
        
        if(this.isCEUser == true){
            this.valueCedingProgramOldValue = null;
        }
        this.getPrograms();
        fireEvent(this.pageRef, 'yearSummary', this.valueUwYear);
    }

    handleChangeCedingComp(event) {
        this.valuePrincipalCedComp = event.detail.value;
        this.valueCedingProgram = null;

        if(this.isCEUser == true){
            this.valueCedingProgramOldValue = null;
        }
        this.getPrograms();
        fireEvent(this.pageRef, 'compSummary', this.valuePrincipalCedComp);
    }

    handleOnChangeProgramCeding(event){
        this.valueCedingProgram = event.detail.value;
        this.valueCedingProgramOldValue = this.valueCedingProgram;
        this.getProgramNature(this.valueCedingProgram);
        fireEvent(this.pageRef, 'valueSelectedProgram', event.detail.value);
    }

    handleOnChangeNature(event){
        this.selectedNature = event.detail.value;
        this.valueCedingProgram = null;
        
        if(this.selectedNature == 'All'){
            this.selectedNature = null;
        }
        this.getPrograms();
    }

    getPrograms(){
        getPrograms({valUWYear : this.valueUwYear, valPrincipalCedComp : this.valuePrincipalCedComp, valNature : this.selectedNature, isCE : this.isCEUser})
        .then(result => {
            this.programOptions = result;

            if(this.programOptions.length == 0){
                this.valueCedingProgram = null;
                this.natureProgram = this.selectedNature;
                fireEvent(this.pageRef, 'valueSelectedProgramNull', 'null');
            }
            else if(this.isCEUser == true){
                if(this.valueCedingProgramOldValue == undefined || this.valueCedingProgramOldValue == null){
                    this.valueCEProgram = result[0].value;
                    fireEvent(this.pageRef, 'valueSelectedProgram', this.valueCEProgram);
                }
            }
            else{
                if((this.valueCedingProgram == this.valueCedingProgramOldValue) || this.valueCedingProgramOldValue == undefined){
                    this.valueCedingProgram = null;
                }
                
                if((this.valueCedingProgram == null || this.valueCedingProgram == undefined)){
                    this.valueCedingProgram = result[0].value;
                }

                if(this.isModalCopy == false){
                    this.getProgramNature(this.valueCedingProgram);
                }
                
                fireEvent(this.pageRef, 'valueSelectedProgram', this.valueCedingProgram);
            }              
            
        })
        .catch(error => {
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error'}), );
        });
    }

    getProgramNature(valProgId){
        getProgramNature({programId : valProgId})
        .then(result => {
            this.natureProgram = result.natureProgram;
            this.programNameModal = result.nameProgram;
        })
        .catch(error => {
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error'}), );
        });
    }

    handleOnChangeProgramCE(event){
        this.valueCEProgram = event.detail.value;
        fireEvent(this.pageRef, 'valueSelectedProgram', this.valueCEProgram);
    }
}