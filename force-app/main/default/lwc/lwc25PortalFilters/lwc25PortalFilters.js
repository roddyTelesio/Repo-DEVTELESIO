import {LightningElement, track, wire, api} from 'lwc';
import {getPicklistValues} from 'lightning/uiObjectInfoApi';
import {getObjectInfo} from 'lightning/uiObjectInfoApi';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import PROGRAM_OBJECT from '@salesforce/schema/Program__c';
import UWYEAR_FIELD from '@salesforce/schema/Program__c.UwYear__c';
import getAcc from '@salesforce/apex/LWC01_WorkingScope.getPrincipalCedingAcc';
import {NavigationMixin, CurrentPageReference} from 'lightning/navigation';
import {registerListener, unregisterAllListeners, fireEvent} from 'c/pubSub';
import getReinsurer from '@salesforce/apex/LWC25_PortalFilters.getAccountReinsurer';
import getPrograms from '@salesforce/apex/LWC25_PortalFilters.getPrograms';
import checkBroker from '@salesforce/apex/LWC25_PortalFilters.checkBrokerContact';
import getProgramNatureWired from '@salesforce/apex/LWC25_PortalFilters.getProgramNature';
import getReinsurerLabelName from '@salesforce/apex/LWC25_PortalFilters.getReinsurerLabelName';
import Id from '@salesforce/user/Id';
import errorMsg from '@salesforce/label/c.errorMsg';

export default class LWC25_PortalFilters extends LightningElement {
    label = {
        errorMsg
    }

    @api valueUWYear;
    @api valuePrincipalCedComp;
    @api disableProgram = false;
    @api isPopUp = false;
    @api valueCedingProgram;
    @api valueCedingProgramOldValue;
    @track navigatorIndex = 0;
    records;
    valueReinsurer;
    valueReinsurerSummary;
    reinsurerOptions;
    reinsurerOptionsAll;
    valueProgram;
    error;
    programOptions;
    isBroker = false;
    isSummaryPage = false;
    isOpenModal = false;
    disableDocuments = true;
    showDocs = false;
    valueUWYearSummary;
    valuePrincipalCedCompSummary;
    allowDocumentPortalAccess = false;
    allowCedingPortalAccess = false;
    natureProgram;
    isChangedReins = false;
    isChangedUWY = false;
    isChangedPCC = false;
    indexValueReins = false;

    @wire(CurrentPageReference) pageRef;
    connectedCallback(){        
        registerListener('year', this.getVal, this);
        registerListener('yearChange', this.getValChange, this);
        registerListener('comp', this.getComp, this);
        registerListener('compChange', this.getCompChange, this);
        registerListener('changeReinsurer', this.getReinsurerPicklist, this);
        registerListener('programSummary', this.getProgram, this);
        registerListener('yearSummary', this.getValSummary, this);
        registerListener('compSummary', this.getCompSummary, this);
        registerListener('reinsurerOptionsAll', this.getReinsurerOptionsAll, this);
        registerListener('reinsurerOpt', this.getReinsurerOptions, this);
        registerListener('refreshReq', this.getRefresh, this); //RRA - ticket 1525 - 07072023
        registerListener('isChanged', this.getIsChangedReins, this); //RRA - ticket 1525 - 07072023
        registerListener('isChangedUWY', this.getIsChangedUWY, this); //RRA - ticket 1525 - 07072023
        registerListener('isChangedPCC', this.getIsChangedPCC, this); //RRA - ticket 1525 - 07072023
        registerListener('indexValueReins', this.getIndexValueReins, this); //RRA - ticket 1525 - 07072023
      
        //window.location.href --- old line 
        //Changes done due to issues after Summer '21
        let currentUrl = this.pageRef.state;
        let nameUrl = null;
        let param = 'c__portal';
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

        if(nameUrl == 'portal_summary__c'){
        // if(location.includes("summary")){
            //summary page
            this.isSummaryPage = true;
            this.disableDocuments = false;
            this.showDocs = true;
        }

        if(nameUrl != null && nameUrl.includes('cedingPortal')){
        // if(location.includes("cedingPortal")){
            this.allowCedingPortalAccess = true;
        }
            
        if(paramValue != null){
            let parameters = paramValue.split("-");

            if(parameters[0] != undefined){
                this.valueProgram = parameters[0];
            }

            if(parameters[1] != undefined){
                this.valueReinsurer = parameters[1];
                this.selectedReinsurer = parameters[1]; //SRA - 1045
                this.valueReinsurerSummary = parameters[1];

                if(this.isSummaryPage == true){
                    this.getReinsurerLabelName(this.valueProgram, this.valueReinsurerSummary);
                }
            }

            if(parameters[4] != undefined){
                this.selectedBroker = parameters[4]; //SRA - 1045
            }

            if(parameters[4] == null || parameters[4] == 'null'){
                this.selectedBroker = null; //SRA - 1045
            }

        }
        registerListener('closeDocumentModal', this.closeDocumentModal, this);
    }

    closeDocumentModal(val){
        this.isOpenModal = false;
    }

    getUrlParamValue(url, key) {
        return new URL(url).searchParams.get(key);
    }

    getVal(val){
        this.valueUWYear = val;
    }

    getValChange(val){
        this.valueUWYear = val;
    }

    getCompChange(val){
        this.valuePrincipalCedComp = val;
    }

    getComp(val){
        this.valuePrincipalCedComp = val;
    }

    getProgram(val){
        this.valueProgram = val;
    }

    getValSummary(val){
        this.valueUWYearSummary = val;
    }

    getCompSummary(val){
        this.valuePrincipalCedCompSummary = val;
    }

    getReinsurerPicklist(val){
        if(val == null){
            this.valueReinsurer = 'All';
            this.indexValueReins = 0;
        }
        else{
            this.valueReinsurer = val;
        }
    }
    
    getReinsurerOptionsAll(val){
        //console.log('val = =', val);
        this.reinsurerOptionsAll = val;
    }

    getReinsurerOptions(val){
        this.reinsurerOptions = val;
    }
    
    //RRA - ticket 1525 - 07072023
    getRefresh(val){
        //console.log('val isChangedReins===', this.isChangedReins);
        //console.log('val isChangedUWY===', this.isChangedUWY);
        //console.log('val isChangedPCC===', this.isChangedPCC);
        if (this.isChangedReins && this.isChangedUWY == false && this.isChangedPCC == false){
            this.template.querySelector('[name="reinsurer2"]').selectedIndex = this.indexValueReins;
        }else if (this.isChangedReins == false && this.isChangedUWY && this.isChangedPCC == false){
            setTimeout(() =>
                this.template.querySelector('[name="reinsurer2"]').selectedIndex = 0 //set to All
            );
        }else if (this.isChangedReins == false && this.isChangedUWY == false && this.isChangedPCC){
            setTimeout(() =>
                this.template.querySelector('[name="reinsurer2"]').selectedIndex = 0 //set to All
            );
        }
    }
    
    //RRA - ticket 1525 - 07072023
    getIsChangedReins (val){
        this.isChangedReins = val;
    }
    
    //RRA - ticket 1525 - 07072023
    getIsChangedUWY(val){
        this.isChangedUWY = val;
    }
    
    //RRA - ticket 1525 - 07072023
    getIsChangedPCC(val){
        this.isChangedPCC = val;
    }
    
    //RRA - ticket 1525 - 07072023
    getIndexValueReins (val){
        this.indexValueReins = val;
    }

    @wire(checkBroker)
    wiredCheckBroker(result){
        if(result.data) {
            this.isBroker = result.data;
            this.error = undefined;
        }
        else if (result.error) {
            this.error = result.error;
        }
    }
    @wire(getObjectInfo, { objectApiName: PROGRAM_OBJECT })
    objectInfo;

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: UWYEAR_FIELD})
    setPicklistOptions({error, data}) {
        if(data){
            if(this.valueUWYear == null || this.valueUWYear == undefined){
                this.valueUWYear = data.values[data.values.length - 1].value;
            }
        }
        else{
            this.error = error;
        }
    }

    @wire(getPrograms, {valueUWYear: '$valueUWYearSummary', valuePrincipalCedComp: '$valuePrincipalCedCompSummary', isCedingPortal: '$allowCedingPortalAccess'})
    wiredGetPrograms(result){
        //this.spinner = true;
        this.wiredProgram = result;
        this.natureProgram = null;

        if(result.data){
            this.programOptions = result.data;

            if(this.allowCedingPortalAccess == true){
                if(this.programOptions.length == 0){
                    this.valueCedingProgram = null;
                    this.natureProgram = null;
                    fireEvent(this.pageRef, 'valueSelectedProgramNull', 'null');
                }
                else{
                    if((this.valueCedingProgram == this.valueCedingProgramOldValue) || this.valueCedingProgramOldValue == undefined){
                        this.valueCedingProgram = null;
                    }
                    if(this.valueCedingProgram == null || this.valueCedingProgram == undefined){
                        this.valueCedingProgram = result.data[0].value;  
                    }
                    fireEvent(this.pageRef, 'valueSelectedProgram', this.valueCedingProgram);
                }              
            }
            else if(this.valueProgram == null || this.valueProgram == undefined){
                this.valueProgram = result.data[0].value;
                fireEvent(this.pageRef, 'valueSelectedProgram', this.valueProgram);
            }
    
            this.error = undefined;
        }
        else if (result.error) {
            this.error = result.error;
        }
    }

    refreshData() {
        return refreshApex(this.wiredProgram);
    }

    handleOnChangeProgramCeding(event){
        this.valueCedingProgram = event.detail.value;
        this.valueCedingProgramOldValue = this.valueCedingProgram;
        fireEvent(this.pageRef, 'valueSelectedProgram', this.valueCedingProgram);
    }

    handleChangeReinsurer(event){
        console.log('handleChangeReinsurer');
        //this.valueReinsurer = event.detail.value;
        this.valueReinsurer = event.target.value;//RRA - ticket 1518 - 12052023
        let indexValueReins = event.target.selectedIndex; //RRA - ticket 1525 - 07072023
        
        console.log('this.valueReinsurer == ', this.valueReinsurer);
        //console.log('indexValueReins == ', indexValueReins);
        fireEvent(this.pageRef, 'changeReinsurer', this.valueReinsurer);
        fireEvent(this.pageRef, 'indexValueReins', indexValueReins);//RRA - ticket 1525 - 07072023
        fireEvent(this.pageRef, 'isChanged', true);//RRA - ticket 1525 - 07072023
        fireEvent(this.pageRef, 'isChangedPCC', false);//RRA - ticket 1525 - 07072023
        fireEvent(this.pageRef, 'isChangedUWY', false);//RRA - ticket 1525 - 07072023
    }
    
    handleOnKeyPress(event){
        var key = event.detail;
        console.log('key == ', key);
    }
    handleOnSelect(event){
        var select = event.detail;
        console.log('select 11== ', select);
    }

    handleOpenDocuments(){
        this.isOpenModal = true;
    }

    handleCloseModal() {
        this.isOpenModal = false;
    }

    //02/06: loading time issue: chenge simple function to -> wired function
    @wire(getProgramNatureWired, {programId: '$valueCedingProgram'})
    wiredGetProgramNature(result){
        if(result.data) {
            this.wiredProgramNature = result;
            this.natureProgram = result.data.natureProgram;
            this.error = undefined;
        }
        else if (result.error) {
            this.error = result.error;
        }
    }

    getReinsurerLabelName(programId, reinsurerId){
        getReinsurerLabelName({progId : programId, reinId : reinsurerId})
        .then(result => {
            let reinName = result.reinsurerLabelName;
            let reinsurerOpt = [];
            let selectedRein = { label: reinName, value: reinsurerId };
            reinsurerOpt.push(selectedRein);

            this.reinsurerOptions = reinsurerOpt;
        })
        .catch(error => {
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error'}), );
        });

    }
}