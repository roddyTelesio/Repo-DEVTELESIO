import {LightningElement, track, wire, api} from 'lwc';
import {getPicklistValues, getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import {getObjectInfo} from 'lightning/uiObjectInfoApi';
import {NavigationMixin, CurrentPageReference} from 'lightning/navigation';
import {registerListener, unregisterAllListeners, fireEvent} from 'c/pubSub';
import {loadStyle, loadScript} from 'lightning/platformResourceLoader';
import HideLightningHeader from '@salesforce/resourceUrl/HideLightningHeader';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import Id from '@salesforce/user/Id';
import PROGRAM_OBJECT from '@salesforce/schema/Program__c';
import UWYEAR_FIELD from '@salesforce/schema/Program__c.UwYear__c';
import MACROLOB_FIELD from '@salesforce/schema/Program__c.Macro_L_O_B__c';
import getFilterValues from '@salesforce/apex/LWC54_SAGroupCover.getFilterValues';
import getSAR from '@salesforce/apex/LWC54_SAGroupCover.getSAR';
import getPrincipalCedingAcc from '@salesforce/apex/LWC54_SAGroupCover.getPrincipalCedingAcc';
import getProgramForGroupCover from '@salesforce/apex/LWC54_SAGroupCover.getProgramForGroupCover';
import generateGroupCoverSa from '@salesforce/apex/LWC54_SAGroupCover.generateGroupCoverSa';

//import custom labels
import pendingStatus from '@salesforce/label/c.PendingStatus';
import moreInforRequiredStatus from '@salesforce/label/c.MoreInforRequiredStatus';
import notAnsweredStatus from '@salesforce/label/c.NotAnsweredStatus';
import sentStatus from '@salesforce/label/c.SentStatus';
import SAGroupCoverErrMsg from '@salesforce/label/c.SAGroupCoverErrMsg';
import SAGroupCoverGeneratedSuccesfully from '@salesforce/label/c.SAGroupCoverGeneratedSuccesfully';
import errorMsg from '@salesforce/label/c.errorMsg';

const sarActions = [
    { label: 'Generate Group Cover SA', name: 'generateSa'}
];

const saColumns = [
    { label: 'Reference', fieldName: 'Reference__c' },
    { label: 'Program', fieldName: 'ProgramName' },
    { label: 'Name', fieldName: 'nameUrl', type: 'url', typeAttributes: {label: { fieldName: 'SpecialAcceptanceName__c' }, target: '_self'} },
    { label: 'L.O.B', fieldName: 'MacroLobLabel'},
    { label: 'Sub - L.O.B', fieldName: 'SubLoB__c'},
    { label: 'Reason', fieldName: 'Reason__c'},
    { label: 'Type', fieldName: 'Type__c'},
    { label: 'Propose to FAC', fieldName: 'ProposedToFac__c'},
    { label: 'Bound?', fieldName: 'Bound__c'},
    { label: 'Status', fieldName: 'InternalStatus__c'},
    { label: 'Active', fieldName: 'Active__c'}
];

const sarColumns = [
    { label: 'Special Acceptance Name', fieldName: 'SAName'},
    { label: 'Pool', fieldName: 'respondOnBehalfLink', type: 'url', typeAttributes: {label: { fieldName: 'poolName' }, target: '_self'} },
    { label: 'Last send date', fieldName: 'LastSentDate__c'},
    { label: 'Expected answer date', fieldName: 'ExpectedResponseDate__c'},
    { label: 'Response date', fieldName: 'ResponseDate__c'},
    { label: 'Status', fieldName: 'saRequestStatus'},
    { label: 'Actions', type: 'action', fixedWidth: 70, typeAttributes: {rowActions: sarActions, menuAlignment:'auto'}}
];

const programColumns = [
    { label: 'Program Name', fieldName: 'Name'}
];

export default class Lwc54SAGroupCover extends NavigationMixin(LightningElement){
    label = {
        pendingStatus,
        moreInforRequiredStatus,
        notAnsweredStatus,
        sentStatus,
        SAGroupCoverErrMsg,
        SAGroupCoverGeneratedSuccesfully,
        errorMsg
    }

    @track mapProgramOptionsByPCC = [];
    @track mapPoolOptionsByProgram = [];
    @track mapLstSADetailByProgPoolId = [];
    @track mapLstSADetailByProgId = [];
    @track selectedProgId = [];
    spinnerSA = false;
    spinnerSAR = false;
    spinnerProgram = false;
    saData;
    saColumns = saColumns;
    sarData;
    sarColumns = sarColumns;
    programData;
    programColumns = programColumns;
    titleCountSA = 'Special Acceptance (0)';
    titleCountSAR = 'Special Acceptance Request (0)';
    titleCountProgram = 'Program (0)';
    valueUwYear = null;
    valuePrincipalCedComp = null;
    valueProgram = null;
    valuePool = null;
    uwYearOpt;
    pccOpt;
    programOpt;
    poolOpt;
    isGenerateSaOpen = false;
    spinnerGenerateSa = false;
    pccGroupCoverOpt;
    valuePccGroupCover;
    valueProgramGroupCover;
    programOptGroupCover;
    disableSaveGroupCover = true;
    selectedRowSar;
    mapMacroLOb = new Map();

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

        if(nameUrl == 'SpecialAcceptanceGroupCover'){
            // if(currentUrl.includes('lightning/n/SpecialAcceptanceGroupCover')){
            let param = 's__id';
            let paramValue = null;

            if(currentUrl != undefined && currentUrl != null){
                paramValue = currentUrl[param];
            }

            if(paramValue != null){
                let parameters = paramValue.split("-");

                if(parameters[0] != undefined && parameters[0] != 'undefined'){
                    this.valueUwYear = parameters[0];
                }

                if(parameters[1] != undefined && parameters[1] != 'undefined'){
                    this.valuePrincipalCedComp = parameters[1];
                }

                if(parameters[2] != undefined && parameters[2] != 'undefined'){
                    this.valueProgram = parameters[2];
                }

                if(parameters[3] != undefined && parameters[3] != 'undefined'){
                    this.valuePool = parameters[3];
                }
            }

            this.getFilterValues();
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: UWYEAR_FIELD})
    setUWYearPicklistOptions({error, data}) {
        if(data){
            this.uwYearOpt = data.values;

            if(this.valueUwYear == null || this.valueUwYear == undefined){
                this.valueUwYear = data.values[data.values.length - 1].value;
                this.getFilterValues();
            }     
        }
        else{
            this.error = error;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: MACROLOB_FIELD})
    setMacroLOBOptions({error, data}) {
        if(data){
            this.mapMacroLOb = new Map();

            for(var i = 0; i < data.values.length; i++){
                this.mapMacroLOb.set(data.values[i].value, data.values[i].label);
            }
        }
        else{
            this.error = error;
        }
    }

    getFilterValues(){
        this.spinnerSA = true;
        getFilterValues({uwYearVal : this.valueUwYear, pccVal : this.valuePrincipalCedComp, programVal : this.valueProgram, poolVal : this.valuePool})
        .then(result => {
            this.pccOpt = result.lstPCCOption;
            this.mapProgramOptionsByPCC = result.mapProgramOptionsByPCC;
            this.mapPoolOptionsByProgram = result.mapPoolOptionsByProgram;
            this.mapLstSADetailByProgPoolId = result.mapLstSADetailByProgPoolId;
            this.mapLstSADetailByProgId = result.mapLstSADetailByProgId;

            if(this.pccOpt.length > 0){
                this.getFilters();  
            }
            else{
                this.valuePrincipalCedComp = null;
                this.valueProgram = null;
                this.valuePool = null;
                this.programOpt = [];
                this.poolOpt = [];
                this.saData = [];
                this.titleCountSA = 'Special Acceptance (' +this.saData.length+ ')';
            }

            this.spinnerSA = false;  
        })
        .catch(error => {
            this.spinnerSA = false;  
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error'}), );
        });
    }

    handleChangeUWYr(event){
        this.valueUwYear = event.detail.value;
        this.valuePrincipalCedComp = null;
        this.valueProgram = null;
        this.valuePool = null;
        this.getFilterValues();
    }

    handleChangePCC(event){
        this.spinnerSA = true;  
        this.valuePrincipalCedComp = event.detail.value;
        this.valueProgram = null;
        this.valuePool = null;
        this.saData = [];
        this.getFilters();
        this.spinnerSA = false;  
    }

    handleChangeProgram(event){
        this.spinnerSA = true;  
        this.valueProgram = event.detail.value;
        this.valuePool = null;
        this.getFilters();
        this.spinnerSA = false;  
    }

    handleChangePool(event){
        this.spinnerSA = true;  
        this.valuePool = event.detail.value;
        this.saData = [];
        this.getFilters();
        this.spinnerSA = false;  
    }

    getFilters(){
        if(this.pccOpt.length > 0){
            if(this.valuePrincipalCedComp == null || this.valuePrincipalCedComp == undefined){
                this.valuePrincipalCedComp = this.pccOpt[0].value;
            }
    
            if(this.mapProgramOptionsByPCC[this.valuePrincipalCedComp] != undefined){
                this.programOpt = this.mapProgramOptionsByPCC[this.valuePrincipalCedComp];
    
                if(this.programOpt.length > 0){
                    if(this.valueProgram == null || this.valueProgram == undefined){
                        this.valueProgram = this.programOpt[0].value;
                    }
    
                    if(this.mapPoolOptionsByProgram[this.valueProgram] != undefined){
                        let poolOptVal = this.mapPoolOptionsByProgram[this.valueProgram];
                        let poolOptAll = [];
                        this.poolOpt = [];
    
                        if(poolOptVal.length > 0){
                            let all = { label: "All", value:"All" };
                            poolOptAll.push(all);
                
                            for(let i = 0; i < poolOptVal.length; i++){
                                poolOptAll.push(poolOptVal[i]);
                            }
    
                            this.poolOpt = poolOptAll;
    
                            if(this.valuePool == null || this.valuePool == undefined){
                                this.valuePool = this.poolOpt[0].value;
                            }
    
                            let lstAllSa = [];
    
                            if(this.valuePool == 'All'){
                                if(this.mapLstSADetailByProgId[this.valueProgram] != undefined){
                                    lstAllSa = this.mapLstSADetailByProgId[this.valueProgram];
                                }
                            }
                            else{
                                if(this.mapLstSADetailByProgPoolId[this.valueProgram + '-' + this.valuePool] != undefined){
                                    lstAllSa = this.mapLstSADetailByProgPoolId[this.valueProgram + '-' + this.valuePool];
                                }
                            } 
    
                            this.saData = lstAllSa; 
    
                            for(let i = 0; i < this.saData.length; i++){
                                this.saData[i]['ProgramName'] = this.saData[i].Program__r.Name;
                                this.saData[i]['MacroLobLabel'] = this.mapMacroLOb.get(this.saData[i].TECH_MacroLobProgram__c);
                                this.saData[i]['nameUrl'] = '../n/LoadSARequest?s__id='+this.saData[i].Id+'-'+this.valueUwYear+'-'+this.valuePrincipalCedComp+'-'+this.valueProgram+'-'+this.valuePool+'-ugp';
                            }
    
                            this.titleCountSA = 'Special Acceptances (' +this.saData.length+ ')';
                        }
                    }
                }
            }
        }
    }

    handleSaRowSelection(event){
        this.spinnerSAR = true;
        let selectedRowSa = this.template.querySelector('lightning-datatable').getSelectedRows();
        let selectedSaId = [];

        for(let i = 0; i < selectedRowSa.length; i++){
            selectedSaId.push(selectedRowSa[i].Id);
        }

        getSAR({lstSAId : selectedSaId, poolVal : this.valuePool})
        .then(result => {
            this.sarData = result.lstSARequest;
            this.titleCountSAR = 'Special Acceptance Requests (' + this.sarData.length + ')';

            for(let i = 0; i < this.sarData.length; i++){
                let poolName = '';
                let respondOnBehalfLink = '';
                this.sarData[i]['SAName'] = this.sarData[i].Special_Acceptance__r.SpecialAcceptanceName__c;

                if(this.sarData[i].Pool__c != undefined){
                    poolName = this.sarData[i].Pool__r.Name;
                }
              
                if(this.sarData[i].Pool__c != undefined && this.sarData[i].Pool__c != null){
                    respondOnBehalfLink = '../n/SARespondOnBehalf?s__id='+this.sarData[i].Special_Acceptance__c+'-'+this.valueUwYear+'-'+this.valuePrincipalCedComp+'-'+this.valueProgram+'-'+this.sarData[i].Broker__c+'-'+this.sarData[i].Reinsurer__c+'-'+this.sarData[i].Pool__c+'-ugp-'+this.valuePool+'-'+this.sarData[i].Id;
                }  

                this.sarData[i]['poolName'] = poolName;
                this.sarData[i]['respondOnBehalfLink'] = respondOnBehalfLink;

                if(this.sarData[i]['SA_Request_Status__c'] == this.label.moreInforRequiredStatus){
                    this.sarData[i]['saRequestStatus'] = this.label.pendingStatus;
                }
                else if(this.sarData[i]['SA_Request_Status__c'] == this.label.sentStatus){
                    this.sarData[i]['saRequestStatus'] = this.label.notAnsweredStatus;
                }
                else{
                    this.sarData[i]['saRequestStatus'] = this.sarData[i]['SA_Request_Status__c'];
                }
            }

            this.spinnerSAR = false
        })
        .catch(error => {
            this.spinnerSAR = false;
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error'}), );
        });
    }

    handleSarRowAction(event){
        let actionName = event.detail.action.name;
        let selectedRowSar = { ...event.detail.row };
        this.selectedRowSar = selectedRowSar;
     
        switch (actionName){
            case 'generateSa':
                //display error msg if it is an existing sa group cover
                if(this.selectedRowSar.Special_Acceptance__r.TECH_LocalSA__c == null || this.selectedRowSar.Special_Acceptance__r.TECH_LocalSA__c == undefined){
                    this.isGenerateSaOpen = true;
                    this.getPrincipalCedingAcc();
                }
                else{
                    this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.SAGroupCoverErrMsg, variant: 'error'}), );
                }
                break;
        }
    }

    handleGenerateSa(event){
        this.spinnerGenerateSa = true;

        generateGroupCoverSa({lstSelectedProgram : this.selectedProgId, selectedSAR : this.selectedRowSar, selectedUwYear: this.valueUwYear, selectedPcc: this.valuePccGroupCover})
        .then(result => {
            this.spinnerGenerateSa = false;
            this.dispatchEvent(new ShowToastEvent({title: 'Success', message: this.label.SAGroupCoverGeneratedSuccesfully, variant: 'success' }),);   
            
            let progId = this.selectedProgId[0];
            let urlPage = '../n/SpecialAcceptance?s__id='+this.valueUwYear+'-'+this.valuePccGroupCover+'-'+progId;
        
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {url: urlPage, target: '_self'}
            });
        })
        .catch(error => {
            this.spinnerGenerateSa = false;
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error'}), );
        });   
    }

    handleCloseGenerateSa(){
        this.isGenerateSaOpen = false;
        this.programData = [];
        this.titleCountProgram = 'Program (0)';
        this.disableSaveGroupCover = true;
    }

    handleChangePCCGroupCover(event){
        this.valuePccGroupCover = event.detail.value;
        this.getProgramForGroupCover();
    }

    handleProgramRowSelection(event){
        let selectedRowProgram = this.template.querySelector('[data-id="programDatatable"]').getSelectedRows();
        this.selectedProgId = [];

        for(let i = 0; i < selectedRowProgram.length; i++){
            this.selectedProgId.push(selectedRowProgram[i].Id);
        }

        if(this.selectedProgId.length > 0){
            this.disableSaveGroupCover = false;
        }
        else{
            this.disableSaveGroupCover = true;
        }
    }

    getPrincipalCedingAcc(){
        getPrincipalCedingAcc()
        .then(result => {
            this.pccGroupCoverOpt = result;
            
            if(this.pccGroupCoverOpt.length > 0){
                this.valuePccGroupCover = this.pccGroupCoverOpt[0].value;
                this.getProgramForGroupCover();
            }
        })
        .catch(error => {
            this.spinnerSA = false;  
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error'}), );
        });
    }

    getProgramForGroupCover(){
        this.spinnerProgram = true;

        getProgramForGroupCover({ selectedUwYear: this.valueUwYear, selectedPcc: this.valuePccGroupCover, selectedSAR : this.selectedRowSar})
        .then(result => {
            this.programData = result.lstProgram;
            this.titleCountProgram = 'Programs (' +this.programData.length+ ')';
            this.spinnerProgram = false; 
        })
        .catch(error => {
            this.spinnerProgram = true;
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error'}), );
        });
    }
}