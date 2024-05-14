import {LightningElement, wire, api} from 'lwc';
import PROGRAM_OBJECT from '@salesforce/schema/Program__c';
import UWYEAR_FIELD from '@salesforce/schema/Program__c.UwYear__c';
import {getPicklistValues} from 'lightning/uiObjectInfoApi';
import {getObjectInfo} from 'lightning/uiObjectInfoApi';
import {refreshApex} from '@salesforce/apex';
import {registerListener, unregisterAllListeners, fireEvent} from 'c/pubSub';
import {NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import USER_ID from '@salesforce/user/Id';
import getAcc from '@salesforce/apex/LWC01_WorkingScope.getPrincipalCedingAcc';
import getPrograms from '@salesforce/apex/LWC11_TreatyPlacementFilters.getPrograms';
import getProgramDetails from '@salesforce/apex/LWC11_TreatyPlacementFilters.getProgramDetails';
import getTreaties from '@salesforce/apex/LWC11_TreatyPlacementFilters.getTreaties';
import getAccountBroker from '@salesforce/apex/LWC11_TreatyPlacementFilters.getAccountBroker';
import getAccountReinsurer from '@salesforce/apex/LWC11_TreatyPlacementFilters.getAccountReinsurer';
import getRequestRTId from '@salesforce/apex/LWC11_TreatyPlacementFilters.getRequestRTId';
import REQUEST_OBJECT from '@salesforce/schema/Request__c';
import REINSURER_STATUS_FIELD from '@salesforce/schema/Request__c.ReinsurerStatus__c';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import getSomeInfoSections from '@salesforce/apex/LWC60_ModalMsgSubSec.getSectionInfo'; //RRA - ticket 1533 - 12062023

//import component lwc
import modalPopUpWarningMsgSubSection from 'c/lwc60ModalMsgSubSection'; //RRA - ticket 1533 - 12062023

//Custom Label
import CannotRetrieveReinsurerStatusFilter from '@salesforce/label/c.CannotRetrieveReinsurerStatusFilter';
import NoSubSectionInSection from '@salesforce/label/c.NoSubSectionInSection';//RRA - ticket 1533 - 13062023

const columnSections = [
    { label: 'Layer Number', fieldName: 'fieldLayer__c', type: 'number', cellAttributes: { alignment: 'left' }}, 
    { label: 'Treaty Name', fieldName: 'TECH_TreatyName__c' },
    { label: 'Section Number', fieldName: 'SectionNumber__c' },
    { label: 'Section Name', fieldName: 'Name'},
];

export default class LWC11_TreatyPlacementFilters extends LightningElement{
    label = {
        CannotRetrieveReinsurerStatusFilter, 
        NoSubSectionInSection
    }

    @api valueUWYear;
    @api valuePrincipalCedComp;
    @api stage = 'Conditions';
    @api requestRTId;
    error;
    wiredprograms;
    wiredtreaties;
    wiredAccountBroker
    wiredAccountReinsurer
    valueProgram = null;
    programOptions;
    treatyOptions;
    spinner = false;
    isOpenModal = false;
    disableDocuments = true;
    isConditionPage = false;
    isQuotePage = false;
    isLeadPage = false;
    isQuoteOrLeadPage = false;
    brokerOptions;
    reinsurerOptions;
    reinsurerStatusOptions;
    valueReinsurerStatus = null;
    valueReinsurer = null;
    valueBroker = null;
    valueTreaty = null;
    isReset = false;
    dataSec = [];//RRA - ticket 1533 - 16062023
    columnSections = columnSections;//RRA - ticket 1533 - 16062023
    
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
        let refreshPopup = sessionStorage.getItem('refreshPopup');
        console.log('refreshPopup == ', refreshPopup);
        if (refreshPopup == 'isRefresh'){
            window.location.reload();
        }

        if(paramValue != null){
            let parameters = paramValue.split("-");
            if(parameters[0] != undefined){
                this.valueProgram = parameters[0];
                //RRA - ticket 1533 - 16062023
                this.getSomeInfoSectionsTreatyPlacement(this.valueProgram);
                this.valueUWYear = parameters[1];
                this.valuePrincipalCedComp = parameters[2];
                this.stage = parameters[3];
                if(parameters[4] != 'null' && parameters[4] != 'undefined' ){
                    this.valueTreaty = parameters[4];
                }
                if(parameters[5] != 'null' && parameters[5] != 'undefined' ){
                    this.valueBroker = parameters[5];
                }
                if(parameters[6] != 'null' && parameters[6] != 'undefined' ){
                    this.valueReinsurer = parameters[6];
                }
                if(parameters[7] != 'null' && parameters[7] != 'undefined' ){
                    this.valueReinsurerStatus = parameters[7];
                }

                if(this.stage == 'Conditions'){
                    this.isConditionPage = true;
                    this.isQuotePage = false;
                    this.isLeadPage = false;
                }
                if(this.stage == 'Quote'){
                    this.isConditionPage = false;
                    this.isQuotePage = true;
                    this.isLeadPage = false;
                }
                if(this.stage == 'Lead'){
                    this.isConditionPage = false;
                    this.isQuotePage = false;
                    this.isLeadPage = true;
                }
                if(this.stage == 'Placement'){
                }

                if(this.stage == 'Quote' || this.stage == 'Lead' || this.stage == 'Placement' || this.stage == 'Signing'){
                    this.isQuoteOrLeadPage = true;
                }
                else{
                    this.isQuoteOrLeadPage = false;
                }
            }
        }

        let rtIds;
        getRequestRTId()
        .then(result => {
           rtIds = result;

           if(rtIds != null && rtIds.length > 0){
               for(let rt of rtIds){
                   if(this.stage == rt.label){
                       this.requestRTId = rt.value;
                   }
               }
           }
        })
        .catch(error => {
            this.error = error;
            this.dispatchEvent(new ShowToastEvent({title: 'ERROR', message: this.label.CannotRetrieveReinsurerStatusFilter, variant: 'error'}),);

        });

        if(this.valueProgram == null){
            this.disableDocuments = true;
        }
        else{
            this.disableDocuments = false;
        }

        registerListener('yearChange', this.getVal, this);
        registerListener('compChange', this.getComp, this);
        registerListener('closeDocumentModal', this.closeDocumentModal, this);
        registerListener('refreshTreatyFilters', this.refreshWiredTreaties, this);
        registerListener('refreshBrokerFilters', this.refreshWiredAccountBroker, this);
        registerListener('refreshReinsurerFilters', this.refreshWiredAccountReinsurer, this);
        console.log('this.valueProgram66 == ',this.valueProgram);
    }

    checkDisableDocs(){
        if(this.valueProgram != null){
            this.disableDocuments = false;
        }
    }

    getUrlParamValue(url, key) {
        return new URL(url).searchParams.get(key);
    }

    @wire(getObjectInfo, { objectApiName: PROGRAM_OBJECT })
    objectInfo;

    getVal(val){
        this.valueUWYear = val;
        this.disableDocuments = true;
        this.valueProgram = null;
    }

    getComp(val){
        this.valuePrincipalCedComp = val;
        this.valueProgram = null;
        this.disableDocuments = true;
    }

    closeDocumentModal(val){
        this.isOpenModal = false;
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: UWYEAR_FIELD})
    setPicklistOptions({error, data}) {
        if(data){
            if(this.valueUWYear == null){
                this.valueUWYear = data.values[data.values.length - 1].value;
            }
        }
        else{
            this.error = error;
        }
    }

    @wire(getAcc)
    setAccPicklistOptions({error, data}) {
        if(data){
            if(this.valuePrincipalCedComp == null){
                this.valuePrincipalCedComp = data[0].value;
            }
        }
        else{
            this.error = error;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$requestRTId', fieldApiName: REINSURER_STATUS_FIELD})
    setReinsurerStatusPicklistOptions({error, data}) {
        if(data){
            let newReinsurerStatusOptions = [{label:'--All--', value:'--All--'}];
            data.values.forEach(key => {
                newReinsurerStatusOptions.push({
                    label : key.label,
                    value: key.value
                })
            });
            this.reinsurerStatusOptions = newReinsurerStatusOptions;
        }
        else{
            this.error = error;
        }
    }

    @wire(getPrograms, {valueUWYear: '$valueUWYear', valuePrincipalCedComp: '$valuePrincipalCedComp'})
    wiredGetPrograms(result){

        this.spinner = true;
        this.wiredprograms = result;
        if(result.data){
            if(result.data.length == 0){
                this.programOptions = result.data;
                fireEvent(this.pageRef, 'filterProgram', null);
            }
            else{
                this.programOptions = result.data;
                if(this.valueProgram == null){
                    this.valueProgram = result.data[0].value;
                    fireEvent(this.pageRef, 'valuePrograms', this.valueProgram); //RRA - ticket 0050 - 23082023
                    console.log('this.valueProgram77 == ',this.valueProgram);
                }

                this.checkDisableDocs();

                getProgramDetails({programId: this.valueProgram})
                .then(resultProg => {
                    let programObj = resultProg;
                    fireEvent(this.pageRef, 'filterProgram', programObj);

                    if(this.stage != resultProg.TECH_StageName__c){
                        window.location.href = '../n/TreatyPlacement?c__program='+this.valueProgram+'-'+resultProg.UwYear__c+'-'+resultProg.PrincipalCedingCompany__c+'-'+resultProg.TECH_StageName__c+'-undefined'+'-undefined'+'-undefined'+'-undefined';
                        this.stage = resultProg.TECH_StageName__c;
                    }

                })
                .catch(errorProg => {
                   this.error = errorProg;
                });
            }
        }
        else if(!result.data){
            fireEvent(this.pageRef, 'filterProgram', null);
        }
        else if(result.error){
            this.error = result.error;
        }
        this.spinner = false;
    }

    refreshData() {
        return refreshApex(this.wiredprograms);
    }

    handleChangeProgram(event) {
        this.disableDocuments = false;
        let progId = event.detail.value;
        this.valueProgram = event.detail.value;
        fireEvent(this.pageRef, 'valueProgram', this.valueProgram);
        sessionStorage.setItem('valueProgram', this.valueProgram);
        
        getProgramDetails({programId: progId})
        .then(result => {
            let programObj = result;
            fireEvent(this.pageRef, 'filterProgram', programObj);
            
            //MBE 16/12/2020 - W-0783 - TREATY - Changement de Working Scope
            window.location.href = '../n/TreatyPlacement?c__program='+progId+'-'+result.UwYear__c+'-'+result.PrincipalCedingCompany__c+'-'+result.TECH_StageName__c+'-undefined'+'-undefined'+'-undefined'+'-undefined';
            this.stage = result.TECH_StageName__c;
        })
        .catch(error => {
           this.error = error;
        });
    }
    
   //RRA - ticket 1533 - 16062023
   getSomeInfoSectionsTreatyPlacement(progId){
    let modalOpen = [];
    getSomeInfoSections({programId : progId})
    .then(resultSec => {
        console.log('progId== ', progId);
        console.log('resultSec treatyplacement== ', resultSec);
        if (resultSec.length > 0){
            for (let i=0;i<resultSec.length;i++){
                if (resultSec[i].Number_of_subsections__c == 0 && resultSec[i].Program__r.Macro_L_O_B__c == '25002' && resultSec[i].isNoSubSection__c == false){ //RRA - 1802
                    modalOpen.push('isOpen');
                    this.dataSec.push(resultSec[i]);
                }else if (resultSec[i].Number_of_subsections__c == 0 && resultSec[i].Program__r.Macro_L_O_B__c == '25002' && resultSec[i].isNoSubSection__c){ //RRA - 1802
                    modalOpen.push('isClosed');
                }else if (resultSec[i].Number_of_subsections__c > 0 && resultSec[i].Program__r.Macro_L_O_B__c == '25002') { //RRA - 1802
                    modalOpen.push('isClosed');
                }
            }
            console.log(' modalOpen treatyplacement== ',  modalOpen);
            //open modal warning message
            if (modalOpen.includes('isOpen')){
                if (this.dataSec.length > 0){
                    const result = modalPopUpWarningMsgSubSection.open({
                        label: this.label.NoSubSectionInSection,
                        size: 'large',
                        columnSections: [...this.columnSections],
                        //isDisableBtn : false,
                        someDataSection : [...this.dataSec]
                    });
                    console.log('result == ', result);
                    return;
                }
            }else{
                console.log('modal is not open');
            }
        }
    })
    .catch(error => {
        this.error = error;
        console.log('error');
    })
}

    handleOpenModal(){
        this.isOpenModal = true;
    }

    handleCloseModal() {
        this.isOpenModal = false;
    }

    refreshWiredTreaties(){
         return refreshApex(this.wiredtreaties);
     }

    @wire(getTreaties, {programId: '$valueProgram'})
    wiredGetTreaties(result){
        fireEvent(this.pageRef, 'valueProgram', this.valueProgram);
        this.spinner = true;
        this.wiredtreaties = result;
        if(result.data){
            if(result.data.length == 0){
                let newTreatyOptions = [{label:'--All--', value:'--All--'}];
                result.data.forEach(key => {
                    newTreatyOptions.push({
                        label : key.label,
                        value: key.value
                    })
                });
                this.treatyOptions = newTreatyOptions;
            }
            else{
                let newTreatyOptions = [{label:'--All--', value:'--All--'}];
                result.data.forEach(key => {
                    newTreatyOptions.push({
                        label : key.label,
                        value: key.value
                    })
                });
                this.treatyOptions = newTreatyOptions;
            }
        }
        else if(result.error){
            this.error = result.error;
        }
        this.spinner = false;
    }

    refreshWiredAccountBroker(){
        return refreshApex(this.wiredAccountBroker);
    }

    @wire(getAccountBroker, {programId: '$valueProgram', phase: '$stage'})
    wiredGetAccountBroker(result){
        this.wiredAccountBroker = result;
        if(result.data) {
            let newBrokerOptions = [{label:'--All--', value:'--All--'}];
            result.data.forEach(key => {
                if(Object.keys(key).length != 0){
                    newBrokerOptions.push({
                        label : key.label,
                        value: key.value
                    })
                }
            });
            this.brokerOptions = newBrokerOptions;
            this.error = undefined;
        }
        else if (result.error) {
            this.error = result.error;
        }
    }

    refreshWiredAccountReinsurer(){
        return refreshApex(this.wiredAccountReinsurer);
    }

    @wire(getAccountReinsurer, {programId: '$valueProgram', phase: '$stage'})
    wiredGetAccountReinsurer(result){
        this.wiredAccountReinsurer = result;
        if(result.data) {
            let newReinsurerOptions = [{label:'--All--', value:'--All--'}];
            result.data.forEach(key => {
                if(Object.keys(key).length != 0){
                   newReinsurerOptions.push({
                       label : key.label,
                       value: key.value
                   })
                }

            });
            this.reinsurerOptions = newReinsurerOptions;
            this.error = undefined;
        }
        else if (result.error) {
            this.error = result.error;
        }
    }

    handleChangeBroker(event){
        this.valueBroker = event.detail.value;
        if(this.valueBroker == '--All--'){
            fireEvent(this.pageRef, 'valueBroker', null);
        }
        else{
            fireEvent(this.pageRef, 'valueBroker', this.valueBroker);
        }
    }

    handleChangeReinsurer(event){
        this.valueReinsurer = event.detail.value;
        if(this.valueReinsurer == '--All--'){
            fireEvent(this.pageRef, 'valueReinsurer', null);
        }
        else{
            fireEvent(this.pageRef, 'valueReinsurer', this.valueReinsurer);
        }
    }

    handleChangeReinsurerStatus(event){
        this.valueReinsurerStatus = event.detail.value;
        if(this.valueReinsurerStatus == '--All--'){
            fireEvent(this.pageRef, 'valueReinsurerStatus', null);
        }
        else{
            fireEvent(this.pageRef, 'valueReinsurerStatus', this.valueReinsurerStatus);
        }
    }

    handleChangeTreaty(event){
        this.valueTreaty = event.detail.value;
        if(this.valueTreaty == '--All--'){
            fireEvent(this.pageRef, 'valueTreaty', null);
        }
        else{
            fireEvent(this.pageRef, 'valueTreaty', this.valueTreaty);
        }
    }
}