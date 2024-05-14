import {LightningElement, wire, api} from 'lwc';
import STAGE_FIELD from '@salesforce/schema/Program__c.TECH_StageName__c';
import {getPicklistValues} from 'lightning/uiObjectInfoApi';
import {getObjectInfo} from 'lightning/uiObjectInfoApi';
import PROGRAM_OBJECT from '@salesforce/schema/Program__c';
import UWYEAR_FIELD from '@salesforce/schema/Program__c.UwYear__c';
import getAcc from '@salesforce/apex/LWC01_WorkingScope.getPrincipalCedingAcc';
import {NavigationMixin, CurrentPageReference} from 'lightning/navigation';
import {registerListener, unregisterAllListeners, fireEvent} from 'c/pubSub';
import updateStage from '@salesforce/apex/LWC12_TreatyPlacementPath.updateStage';
import getPreviousStageName from '@salesforce/apex/LWC12_TreatyPlacementPath.getPreviousStageName';

export default class LWC12_TreatyPlacementPath extends LightningElement {

    error;
    picklistValues;
    selectedValue;
    program;
    uwyear;
    principalCedingComp;
    redirect = false;
    selectedTreatyId;
    selectedBrokerId;
    selectedReinsurerId;
    selectedReinsurerStatus;

    @wire(getObjectInfo, { objectApiName: PROGRAM_OBJECT })
    objectInfo;

    @wire(CurrentPageReference) pageRef;
    connectedCallback() {
        registerListener('yearChange', this.getVal, this);
        registerListener('compChange', this.getComp, this);
        registerListener('valueProgram', this.getProgram, this);
        registerListener('valueTreaty', this.getValueTreaty, this);
        registerListener('valueBroker', this.getValueBroker, this);
        registerListener('valueReinsurer', this.getValueReinsurer, this);
        registerListener('valueReinsurerStatus', this.getValueReinsurerStatus, this);
        registerListener('updateStageName', this.updateStageName, this);
    
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
                this.program = parameters[0];
            }

            if(parameters[1] != undefined){
                this.uwyear = parameters[1];
            }

            if(parameters[2] != undefined){
                this.principalCedingComp = parameters[2];
            }

            if(parameters[3] != undefined){
                this.selectedValue = parameters[3];
            }

            if(parameters[4] != undefined && parameters[4] != 'null' && parameters[4] != 'undefined'){
                this.selectedTreatyId = parameters[4];
            }

            if(parameters[5] != undefined && parameters[5] != 'null' && parameters[5] != 'undefined'){
                this.selectedBrokerId = parameters[5];
            }

            if(parameters[6] != undefined && parameters[6] != 'null' && parameters[6] != 'undefined'){
                this.selectedReinsurerId = parameters[6];
            }

            if(parameters[7] != undefined && parameters[7] != 'null' && parameters[7] != 'undefined'){
                this.selectedReinsurerStatus = parameters[7];
            }

        }
        else{
            this.selectedValue = 'Conditions';
        }

        registerListener('valueProgram', this.getValueProgram, this);
    }

    getUrlParamValue(url, key) {
        return new URL(url).searchParams.get(key);
    }

    getProgram(val){
        this.program = val;
    }

    getVal(val){
        this.uwyear = val;
    }

    getComp(val){
        this.principalCedingComp = val;
    }

    getValueTreaty(val){
        this.selectedTreatyId = val;
    }

    getValueReinsurer(val){
        this.selectedReinsurerId = val;
    }

    getValueBroker(val){
        this.selectedBrokerId = val;
    }

    getValueReinsurerStatus(val){
        this.selectedReinsurerStatus = val;
    }

    getValueProgram(val){
        this.program = val;
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: UWYEAR_FIELD})
    setUWPicklistOptions({error, data}) {
        if(data){
        }
        else{
            this.error = error;
        }
    }

    @wire(getAcc)
    setAccPicklistOptions({error, data}) {
        if(data){
        }
        else{
            this.error = error;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: STAGE_FIELD})
    setPicklistOptions({error, data}) {
        if(data){
            let itemsList = [];
            let selectedUpTo = 0;
            for (let item in data.values) {
                if (Object.prototype.hasOwnProperty.call(data.values, item)) {
                    let classList;
                    if(data.values[item].value === this.selectedValue) {
                        classList = 'slds-path__item slds-is-current slds-is-active';
                        selectedUpTo++;
                    }
                    else{
                        if(this.findIndexByKeyValue(data.values, "value", data.values[item].value) < this.findIndexByKeyValue(data.values, "value", this.selectedValue)){
                            classList = 'slds-path__item slds-is-complete';
                        }
                        else{
                            classList = 'slds-path__item slds-is-incomplete';
                        }
                    }

                    let newobj = {};
                    newobj.label = data.values[item].label;
                    newobj.value = data.values[item].value;

                    itemsList.push({
                        pItem: newobj,
                        classList: classList
                    });
                }
            }
            this.picklistValues = itemsList;
        }
        else{
            this.error = error;
        }
    }

    findIndexByKeyValue(arraytosearch, key, valuetosearch) {
        for (var i = 0; i < arraytosearch.length; i++) {
            if (arraytosearch[i][key] == valuetosearch) {
                return i;
            }
        }
        return null;
    }

    handleSelect(event){
        let pathStage = event.currentTarget.id;
        let stageChosen = pathStage.split('-')[0];

        getPreviousStageName({stageName : stageChosen, programId : this.program})
        .then(result => {
            let previousStageName = result.previousStageName;

            if(previousStageName == 'Signing'){
                let programStage = this.program + '-' + stageChosen;
                fireEvent(this.pageRef, 'stageSigningChange', programStage);
            }
            else{
                this.updateStage(stageChosen, this.program);
            }
        })
        .catch(error => {
        });
    }

    updateStage(stage, selectedProgram){
        updateStage({stageName : stage, programId : selectedProgram})
        .then(result => {
            window.location.href = '../n/TreatyPlacement?c__program='+selectedProgram+'-'+this.uwyear+'-'+this.principalCedingComp+'-'+stage+'-undefined'+'-undefined'+'-undefined'+'-undefined';
        })
        .catch(error => {
        });
    }

    updateStageName(val){
        let programId = val.split('-')[0];
        let stageChosen = val.split('-')[1];
        this.updateStage(stageChosen, programId);
    }
}