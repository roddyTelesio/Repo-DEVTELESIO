import {LightningElement, track, wire, api} from 'lwc';
import {registerListener, unregisterAllListeners, fireEvent} from 'c/pubSub';
import {NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import checkActivePCC from '@salesforce/apex/LWC01_Programs.checkActivePCC';
import checkCCC from '@salesforce/apex/LWC01_Programs.checkCCC';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import Id from '@salesforce/user/Id';
import errorMsg from '@salesforce/label/c.errorMsg';

export default class LWC13_TreatyPlacementPage extends NavigationMixin(LightningElement){
    label = {
        errorMsg
    }

    @api objProgram;
    @track recId = [];
    conditions = false;
    isEdit = false;
    valueUWYear;
    valuePrincipalCedComp;
    allReadOnly = false;
    allReadOnlyProg = false;
    quote = false;
    lead = false;
    programId = null;
    placement = false;//added by DMO 17022020 - Placement tab
    signing = false;
    spinner = false;

    @wire(CurrentPageReference) pageRef;
    connectedCallback(){
        let param = 'c__program';
        let paramValue = null;

        //window.location.href --- old line
        //Changes done due to issues after Summer '21
        let url = this.pageRef.state;

        if(url != undefined && url != null){
            paramValue = url[param];
        }

        if(paramValue != null){
            let parameters = paramValue.split("-");

            if(parameters[0] != undefined){
                this.objProgram = parameters[0];
                this.isEdit = true;
            }

            if(parameters[3] != undefined){
                if(parameters[3] == 'Conditions'){
                    this.conditions = true;
                }
                else if(parameters[3] == 'Quote'){
                    this.quote = true;
                }
                else if(parameters[3] == 'Lead'){
                    this.lead = true;
                    this.programId = parameters[0];
                }
                //added by DMO 17022020 - Placement tab
                else if (parameters[3] == 'Placement'){
                    this.placement = true;
                    this.programId = parameters[0];
                }
                else if (parameters[3] == 'Signing'){
                    this.signing = true;
                    this.programId = parameters[0];
                }
                this.valueUWYear = parameters[1];
                this.valuePrincipalCedComp = parameters[2];
            }
        }
        else{
            this.conditions = true;
        }

        registerListener('filterProgram', this.getProgram, this);

        if(this.objProgram != undefined){
            this.checkActivePCC(this.valuePrincipalCedComp, this.objProgram.Id);
        }

    }

    checkActivePCC(valuePrincipalCedComp, programId){
        checkActivePCC({ valuePrincipalCedComp : valuePrincipalCedComp})
        .then(result => {
            if(result == false){
                this.allReadOnly = true;
                this.allReadOnlyProg = true;
            }
            else{
                checkCCC({ programId : programId})
                .then(resultCCC => {
                    if(resultCCC == false){
                        this.allReadOnlyProg = true;
//                        this.dispatchEvent(new ShowToastEvent({title: 'Info', message: 'Inactive CCC', variant: 'info'}),);
                    }
                })
                .catch(error => {
        //            this.dispatchEvent(new ShowToastEvent({title: 'ERROR', message: this.label.errorMsg, variant: 'error'}),);
                });
            }
        })
        .catch(error => {
//            this.dispatchEvent(new ShowToastEvent({title: 'ERROR', message: this.label.errorMsg, variant: 'error'}),);
        });
    }

    getUrlParamValue(url, key) {
        return new URL(url).searchParams.get(key);
    }

    getProgram(val){
        this.objProgram = val;
        if(this.objProgram != null){
            this.isEdit = true;
            this.recId.push(val.Id);

            this.checkActivePCC(this.valuePrincipalCedComp, this.objProgram.Id);
        }
    }

    handleSaveProgram(){
        this.spinner = true;
        fireEvent(this.pageRef, 'saveCondProgramTP', this.programId);
        this.spinner = false;
    }
}