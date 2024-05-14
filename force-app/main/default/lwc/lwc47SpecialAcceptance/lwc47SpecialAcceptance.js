import {LightningElement, track, wire, api} from 'lwc';
import {getPicklistValues, getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import {getObjectInfo} from 'lightning/uiObjectInfoApi';
import getProgramDetail from '@salesforce/apex/LWC47_SpecialAcceptance.getProgramDetail';
import getTypeOfSARecordTypeId from '@salesforce/apex/LWC47_SpecialAcceptance.getTypeOfSARecordTypeId';
import saveSpecialAcceptanceRecord from '@salesforce/apex/LWC47_SpecialAcceptance.saveSpecialAcceptanceRecord';
import {NavigationMixin, CurrentPageReference} from 'lightning/navigation';
import {registerListener, unregisterAllListeners, fireEvent} from 'c/pubSub';
import {loadStyle, loadScript} from 'lightning/platformResourceLoader';
import HideLightningHeader from '@salesforce/resourceUrl/HideLightningHeader';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import getContentVersionId from '@salesforce/apex/LWC47_SpecialAcceptance.getContentVersionId';
import saveDocuments from '@salesforce/apex/LWC47_SpecialAcceptance.saveDocuments';
import deleteContentVersionDocument from '@salesforce/apex/LWC47_SpecialAcceptance.deleteContentVersionDocument';
import getProgramNature from '@salesforce/apex/LWC47_SpecialAcceptance.getProgramNature';
import checkForRenewSA from '@salesforce/apex/LWC47_SpecialAcceptance.checkForRenewSA';
import checkIfSAEmailIsFound from '@salesforce/apex/AP_Constant.checkIfSAEmailIsFound';
import deleteSpecialAcceptanceRecord from '@salesforce/apex/LWC47_SpecialAcceptance.deleteSpecialAcceptanceRecord';
import deactivateSpecialAcceptanceRecord from '@salesforce/apex/LWC47_SpecialAcceptance.deactivateSpecialAcceptanceRecord';
import reactivateSpecialAcceptanceRecord from '@salesforce/apex/LWC47_SpecialAcceptance.reactivateSpecialAcceptanceRecord';
import bindSpecialAcceptanceRecords from '@salesforce/apex/LWC47_SpecialAcceptance.bindSpecialAcceptanceRecords';
import Id from '@salesforce/user/Id';
import getNaceCode from '@salesforce/apex/LWC47_SpecialAcceptance.getNaceCode';

//import field
import NATURE_FIELD from '@salesforce/schema/ContentVersion.Nature__c';
import SPECIAL_ACCEPTANCE_OBJECT from '@salesforce/schema/SpecialAcceptance__c';
import CONTENT_VERSION_OBJECT from '@salesforce/schema/ContentVersion';
import TYPE_FIELD from '@salesforce/schema/SpecialAcceptance__c.Type__c';
import EXPOSUREBASED_FIELD from '@salesforce/schema/SpecialAcceptance__c.ExposureBasedOn__c';
import SUBLOB_FIELD from '@salesforce/schema/SpecialAcceptance__c.SubLoB__c';
import COUNTRY_FIELD from '@salesforce/schema/SpecialAcceptance__c.Country__c';
import REASON_FIELD from '@salesforce/schema/SpecialAcceptance__c.Reason__c';
import CURRENCY_FIELD from '@salesforce/schema/SpecialAcceptance__c.Currency__c';
import LIMITTYPE_FIELD from '@salesforce/schema/SpecialAcceptance__c.LimitType__c';
import AXALEADER_FIELD from '@salesforce/schema/SpecialAcceptance__c.AxaLeader__c';
import CATCOVERAGE_FIELD from '@salesforce/schema/SpecialAcceptance__c.CatCoverage__c';
import ORIGINAL_INSURED_FIELD from '@salesforce/schema/SpecialAcceptance__c.OriginalInsuredActivityAutofac__c';
import NACECODE_FIELD from '@salesforce/schema/SpecialAcceptance__c.NaceCode__c';
import TYPEFACPLACEMENT_FIELD from '@salesforce/schema/SpecialAcceptance__c.TypeFacPlacement__c';
import ISCEDEDEXPOSUREAUTOFACINLINE_FIELD from '@salesforce/schema/SpecialAcceptance__c.IsCededExposureAutofacInLine__c';
import BOUND_FIELD from '@salesforce/schema/SpecialAcceptance__c.Bound__c';
import PROPOSEDTOFAC_FIELD from '@salesforce/schema/SpecialAcceptance__c.ProposedToFac__c';

//import custom labels
import saErrorMsg from '@salesforce/label/c.saErrorMsg';
import OriginalYearNotInRightFormat from '@salesforce/label/c.OriginalYearNotInRightFormat';
import SelectLegalEntityOrNatural from '@salesforce/label/c.SelectLegalEntityOrNatural';
import LimitUnlimitedErrMsg from '@salesforce/label/c.LimitUnlimitedErrMsg';
import FloodWindstormEarthquakeTerrorism from '@salesforce/label/c.FloodWindstormEarthquakeTerrorism';
import limitTypeMandatory from '@salesforce/label/c.limitTypeMandatory'; //RRA - ticket 1523 - 26052023
import AskForSubmitSAMsg from '@salesforce/label/c.AskForSubmitSAMsg';
import AskForDeleteSAMsg from '@salesforce/label/c.AskForDeleteSAMsg';
import NoProgramIsSelectedForSA from '@salesforce/label/c.NoProgramIsSelectedForSA';
import DeleteDocumentSucessMsg from '@salesforce/label/c.DeleteDocumentSucessMsg';
import NoFileIsFound from '@salesforce/label/c.NoFileIsFound';
import DocumentSavedSuccessMsg from '@salesforce/label/c.DocumentSavedSuccessMsg';
import RequiredFieldMissingSA from '@salesforce/label/c.RequiredFieldMissingSA';
import EmailNotFound from '@salesforce/label/c.EmailNotFound';
import SACreatedSuccessMsg from '@salesforce/label/c.SACreatedSuccessMsg';
import ProgramNotRenewed from '@salesforce/label/c.ProgramNotRenewed';
import SACannotBeRenewedBindStatus from '@salesforce/label/c.SACannotBeRenewedBindStatus';
import SAAlreadyRenewed from '@salesforce/label/c.SAAlreadyRenewed';
import SACannotBeDeleted from '@salesforce/label/c.SACannotBeDeleted';
import DeactivateSASuccessMsg from '@salesforce/label/c.DeactivateSASuccessMsg';
import ReactivateSASuccessMsg from '@salesforce/label/c.ReactivateSASuccessMsg';
import SADeletedSuccessfully from '@salesforce/label/c.SADeletedSuccessfully';
import SABoundSuccessfully from '@salesforce/label/c.SABoundSuccessfully';
import errorMsg from '@salesforce/label/c.errorMsg';
import constantPremiumValue from '@salesforce/label/c.constantPremiumValue';
import powNetPremiumValue from '@salesforce/label/c.powNetPremiumValue';

const actionsCedingPortal = [
    { label: 'Copy', name: 'copy'},
    { label: 'Renew', name: 'renew'},
    { label: 'Delete', name: 'delete'}
];

const actionsCe = [
    { label: 'Copy', name: 'copy'},
    { label: 'Renew', name: 'renew'}
];

const columnsCedingPortal = [
    { label: 'Reference', fieldName: 'Reference__c' },
    { label: 'Program', fieldName: 'ProgramName' },
    { label: 'Name', fieldName: 'nameUrl', type: 'url', typeAttributes: {label: { fieldName: 'SpecialAcceptanceName__c' }, target: '_self'} },
    { label: 'L.O.B', fieldName: 'macroLobLabel'},
    { label: 'Sub - L.O.B', fieldName: 'SubLoB__c'},
    { label: 'Reason', fieldName: 'Reason__c'},
    { label: 'Type', fieldName: 'Type__c'},
    { label: 'Propose to FAC', fieldName: 'ProposedToFac__c'},
    { label: 'Bound?', fieldName: 'Bound__c'},
    { label: 'Status', fieldName: 'status'},
    { label: 'Active', fieldName: 'Active__c'},
    { label: 'Actions', type: 'action', fixedWidth: 70, typeAttributes: {rowActions: actionsCedingPortal, menuAlignment:'auto'}}
];

const columnsCe = [
    { label: 'Reference', fieldName: 'Reference__c' },
    { label: 'Program', fieldName: 'ProgramName' },
    { label: 'Name', fieldName: 'nameUrl', type: 'url', typeAttributes: {label: { fieldName: 'SpecialAcceptanceName__c' }, target: '_self'} },
    { label: 'L.O.B', fieldName: 'macroLobLabel'},
    { label: 'Sub - L.O.B', fieldName: 'SubLoB__c'},
    { label: 'Reason', fieldName: 'Reason__c'},
    { label: 'Type', fieldName: 'Type__c'},
    { label: 'Propose to FAC', fieldName: 'ProposedToFac__c'},
    { label: 'Bound?', fieldName: 'Bound__c'},
    { label: 'Status', fieldName: 'status'},
    { label: 'Active', fieldName: 'Active__c'},
    { label: 'Actions', type: 'action', fixedWidth: 70, typeAttributes: {rowActions: actionsCe, menuAlignment:'auto'}}
];

export default class Lwc47SpecialAcceptance extends NavigationMixin(LightningElement) {
    label = {
        saErrorMsg,
        OriginalYearNotInRightFormat,
        SelectLegalEntityOrNatural,
        LimitUnlimitedErrMsg,
        FloodWindstormEarthquakeTerrorism,
        AskForSubmitSAMsg,
        AskForDeleteSAMsg,
        NoProgramIsSelectedForSA,
        DeleteDocumentSucessMsg,
        NoFileIsFound,
        DocumentSavedSuccessMsg,
        RequiredFieldMissingSA,
        EmailNotFound,
        SACreatedSuccessMsg,
        ProgramNotRenewed,
        SACannotBeRenewedBindStatus,
        SAAlreadyRenewed,
        SACannotBeDeleted,
        DeactivateSASuccessMsg,
        ReactivateSASuccessMsg,
        SADeletedSuccessfully,
        SABoundSuccessfully,
        errorMsg,
        constantPremiumValue,
        powNetPremiumValue,
        limitTypeMandatory //RRA - ticket 1523 - 26052023
    }

    @api typeOfSARecordTypeId;
    @track lstDocuments = [];
    @track lstSelectedDocument = [];
    @track lstSelectedDeleteDocumentId = [];
    @track selectedSA = [];
    @track searchNaceCodeLookupRecords = [];
    isTotalAxaShareInvalid = false ; //MRA W-1251 13/09/2022 
    isDisabledFields = false; //RRA - ticket 1523 - 30052023
    error;
    wiredLob;
    wiredActivePCC;
    spinnerSpecialAcceptance = false;
    spinnerSaveSpecialAcceptance = false;
    data;
    columns = columnsCedingPortal;
    titleCountSpecialAcceptance = 'Special Acceptances (0)';
    titleCountDocument = 'My Documents (0)';
    isCopySa = false;
    isNewSa = false;
    isRenewSa = false;
    valUwYear;
    valPrincipalCedComp;
    valProgram;
    progObj;
    displayPCForm = false;
    displayLifeForm = false;
    displayAutoFacForm = false;
    typeOpt;
    subLobOpt;
    countryOpt;
    reasonOpt;
    currencyOpt;
    limitTypeOpt;
    axaLeaderOpt;
    catCoverageOpt;
    exposureBaseOpt;
    typeFacPlacementOpt;
    isCededExposureAutofacInLineOpt;
    boundOpt;
    proposedToFacOpt;
    selectedSubLOB;
    macroLobFromProgram;
    inceptionDateVal;
    expiryDateVal;
    daysDurationVal = 0;
    valTotalInsuredValueEuro;
    valLimitEuro;
    valTopLocationPdValues100Euro;
    valTopLocationBiValues100Euro;
    valMaximumPossibleLossMplEuro;
    valLossLimit100Euro;
    valExposureAmount100Euro;
    valCededExposureTreatyEuro;
    valCededExposureAutofacEuro;
    valCededExposureInternalFacultativeEuro;
    valCededExposureExternalFacultativeEuro;
    valDeductibleAmountEuro;
    valOriginalPolicyPremiumEuro;
    valOriginalPremium100Euro;
    valTreatyExposureEuro;
    valTotalSumRiskEuro;
    valAverageSumRisk;
    valAverageSumRiskEuro;
    valNumberHeads;
    valTotalSumRisk;
    valCatCoverage;
    valTotalInsuredValue;
    isOpenDocModal = false;
    documentNames;
    uploadedDoc;
    valRateExchange;
    valLimit;
    valTopLocationPdValues100;
    valTopLocationBiValues100;
    valMaximumPossibleLossMpl;
    valLossLimit100;
    valExposureAmount100;
    valCededExposureTreaty = 0;
    valCededExposureAutofac = 0;
    valCededExposureInternalFacultative = 0;
    valCededExposureExternalFacultative = 0;
    valDeductibleAmount;
    valOriginalPolicyPremium;
    valOriginalPremium100;
    valTreatyExposure;
    valTotalExposureAxaShare;
    valTotalExposureAxaShareEuro;
    valTotalExposureAxaSharePC;
    valTotalExposureAxaShareLife;
    valTotalExposureAxaShareAutoFac;
    valExposureBasedOn;
    valLimitType;
    valLimitUnlimited = false;
    valAxaShare;
    valTotalAxaShare;
    valTotalAxaShareEuro;
    valDeductiblePercentage;
    valPremiumRate;
    valOriginalNetRate;
    valOriginalDeductible;
    valTypeFacPlacement;
    valAutofacShare;
    valIsCededExposureAutofacInLine;
    valNetCededPremiumAutofac;
    valNetCededPremiumAutofacEuro;
    valFacLayer;
    valInXsOf;
    valAutofacCommission;
    valNetPremiumLayerEuro;
    valFloodLimit = '';
    valWindstormLimit = '';
    valEarthquakeLimit = '';
    valTerrorismLimit = '';
    disableLimit = false;

     // RRA - 1163 - 22/06/2022
    tonHasErrorUnlimited = true;
    tonHasError = true;
    errors;
    disableDeductibleAmount = false;
    disableDeductiblePercentage = false;
    disableLimitUnlimited = false;
    disableDeleteBtn = true;
    natureOpt;
    isFilterPopUp = true;
    selectedSpecialAcceptanceId;
    selectedProgramToCopy;
    programNatureOptions;
    natureProgram;
    valCopyDocument = true;
    isProgramRenewed = false;
    covCedComOpt;
    errorclass;
    legalEntityVal = false;
    naturalPersonVal = false;
    specialAcceptanceNameVal = null;
    referenceVal;
    disableSpecialAcceptanceName = false;
    isSubmit = false;
    submitMsg = 'You are going to submit the Special Acceptance.Submitting your Special Acceptance to AXA SA will prevent you to delete or modify it. Do you want to continue ?'; //RRA - ticket 134502122022 (Special Acceptance to AGR)
    btnNameclick;
    specialAcceptanceRecordToSave;
    isAskToDelete = false;
    deleteMsg = 'You are going to delete the Special Acceptance. Do you want to continue?';
    selectedRowSA;
    displayAutofacQS = false;
    displayAutofacXS = false;
    disableBindBtn = true;
    disableDeactivateBtn = true;
    disableReactivateBtn = true;
    isBind = false;
    isDeactivate = false;
    isReactivate = false;
    isAskToBindDeactReact = false;
    isAskToTitle;
    isAskToMsg;
    isCE = false;
    renewedProgId;
    controlSubLOBValues;
    totalDependentSubLOBValues = [];
    mapRateByCurrencyLabel = new Map();
    mapCurrency = new Map();
    displayNaceCode = false;
    selectedNaceText = null;
    iconName = 'utility:display_text';
    messageFlag = false;
    loadingText = false;
    hideButtons = false;
    selectedNaceName;
    selectedNaceId;
    valOriginalInsuredActAutofac;
    txtNaceLookupClassName = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';

    @wire(CurrentPageReference) pageRef;

    @wire(getObjectInfo, { objectApiName: SPECIAL_ACCEPTANCE_OBJECT })
    objectInfo;

    @wire(getObjectInfo, { objectApiName: CONTENT_VERSION_OBJECT })
    objectInfoContentVersion;

    getUrlParamValue(url, key) {
        return new URL(url).searchParams.get(key);
    }

    connectedCallback() {
        registerListener('yearSummary', this.getUWYear, this);
        registerListener('compSummary', this.getComp, this);
        registerListener('valueSelectedProgram', this.getProgram, this);
        registerListener('valueSelectedProgramNull', this.setProgramValueNull, this);
        registerListener('closeCopyRenewSAModal', this.closeCopyRenewSAOpenModal, this);
        this.selectedNaceText = null;
        this.valOriginalInsuredActAutofac = null;
        console.log('valLimitType == ', this.valLimitType);
        console.log('isDisabledFields == ', this.isDisabledFields);
        console.log('disableLimit == ', this.disableLimit);
        console.log('disableLimitUnlimited == ', this.disableLimitUnlimited);

        
        if (this.valLimitType === undefined){
            this.isDisabledFields = true; //RRA - ticket 1523 - 30052023
            this.disableLimit = true; //RRA - ticket 1523 - 30052023
            this.disableLimitUnlimited = true; //RRA - ticket 1523 - 30052023
        }

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

        if(nameUrl == 'Home'){
            //if(currentUrl.includes('cedingPortal/s/')){
            let param = 's__id';
            let paramValue = null;

            if(currentUrl != undefined && currentUrl != null){
                paramValue = currentUrl[param];
            }

            if(paramValue != null){
                let parameters = paramValue.split("-");
                if(parameters[0] != undefined){
                    this.valUwYear = parameters[0];
                }

                if(parameters[1] != undefined){
                    this.valPrincipalCedComp = parameters[1];
                }

                if(parameters[2] != undefined){
                    this.valProgram = parameters[2];
                }
            }
        }
        else if(nameUrl == 'SpecialAcceptance'){
            // else if(currentUrl.includes('lightning/n/SpecialAcceptance')){
            //CE user
            this.isCE = true;
            let param = 's__id';
            let paramValue = null;

            if(currentUrl != undefined && currentUrl != null){
                paramValue = currentUrl[param];
            }

            if(paramValue != null){
                let parameters = paramValue.split("-");
                if(parameters[0] != undefined){
                    this.valUwYear = parameters[0];
                }

                if(parameters[1] != undefined){
                    this.valPrincipalCedComp = parameters[1];
                }

                if(parameters[2] != undefined){
                    this.valProgram = parameters[2];
                }
            }
        }

        if(this.isCE == true){
            this.columns = columnsCe;
        }
        else{
            this.columns = columnsCedingPortal;
        }

        this.valCopyDocument = true;
        this.getProgramDetail();
    }

    setProgramValueNull(val){
        this.valProgram = null;
        this.getProgramDetail();
    }

    getUWYear(val){
        this.valUwYear = val;
    }

    getComp(val){
        this.valPrincipalCedComp = val;
    }

    getProgram(val){
        this.valProgram = val;
        this.getProgramDetail();
    }

    closeCopyRenewSAOpenModal(val){
        this.isCopySa = false;
        this.isNewSa = false;
        this.isRenewSa = false;
        this.valCopyDocument = true;
        this.getProgramDetail();
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfoContentVersion.data.defaultRecordTypeId', fieldApiName: NATURE_FIELD})
    setNaturePicklistOpt({error, data}) {
        if(data){
            this.natureOpt = data.values;
        }
        else{
            this.error = error;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$typeOfSARecordTypeId', fieldApiName: REASON_FIELD})
    setTypeOfSAPicklistOpt({error, data}) {
        if(data){
            this.reasonOpt = data.values;
        }
        else{
            this.error = error;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$typeOfSARecordTypeId', fieldApiName: LIMITTYPE_FIELD})
    setLimitTypePicklistOpt({error, data}) {
        if(data){
            //RRA - ticket 1523 - 31052023
            let defaulValue = [];
            defaulValue.unshift({'label' : '--None--', 'value' : '--None--'});
            for(var i = 0; i < data.values.length; i++){
                let limitTypeOpt = { ...data.values[i] };
                limitTypeOpt['value'] =  data.values[i].value;
                defaulValue.push(limitTypeOpt);
            }

            //this.limitTypeOpt = data.values;
              //RRA - ticket 1523 - 31052023
            this.limitTypeOpt = defaulValue;
            console.log('this.limitTypeOpt == ', this.limitTypeOpt);
            console.log('this.valLimitType 22 == ', this.valLimitType);
            
            //RRA - ticket 1523 - 05062023
             if (this.valLimitType === '--None--'){
                this.isDisabledFields = true; 
                this.disableLimit = true;
                this.disableLimitUnlimited = true; 
            }
        }
        else{
            this.error = error;
        }
    }
    
    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: PROPOSEDTOFAC_FIELD})
    setProposedToFacPicklistOpt({error, data}) {
        if(data){
            this.proposedToFacOpt = data.values;
        }
        else{
            this.error = error;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: BOUND_FIELD})
    setBoundPicklistOpt({error, data}) {
        if(data){
            this.boundOpt = data.values;
        }
        else{
            this.error = error;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: TYPEFACPLACEMENT_FIELD})
    setTypeFacPlacementPicklistOpt({error, data}) {
        if(data){
            this.typeFacPlacementOpt = data.values;
        }
        else{
            this.error = error;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: ISCEDEDEXPOSUREAUTOFACINLINE_FIELD})
    setIsCededExposureAutofacInLinePicklistOpt({error, data}) {
        if(data){
            this.isCededExposureAutofacInLineOpt = data.values;
        }
        else{
            this.error = error;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: EXPOSUREBASED_FIELD})
    setExposureBasePicklistOpt({error, data}) {
        if(data){
            this.exposureBaseOpt = data.values;
        }
        else{
            this.error = error;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: TYPE_FIELD})
    setTypePicklistOpt({error, data}) {
        if(data){
            this.typeOpt = data.values;
        }
        else{
            this.error = error;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: COUNTRY_FIELD})
    setCountryPicklistOpt({error, data}) {
        if(data){
            this.countryOpt = data.values;
        }
        else{
            this.error = error;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: CURRENCY_FIELD})
    setCurrencyPicklistOpt({error, data}) {
        if(data){//AMI 02/06/22 W0868
            let wireResults = data.values !== undefined ? data.values : [];
            let unsortedCurList = [];
            let sortedCurList = [];

            if(wireResults.length > 0){
                //get all picklist options first
                wireResults.forEach(ele => {
                    unsortedCurList.push({'label':ele.label,'value':ele.value});

                    this.mapCurrency.set(ele.value, ele.label);
                });
               
                //sort retrived options
                sortedCurList = unsortedCurList.sort((a,b) => (a.label > b.label) ? 1 : ((b.label > a.label) ? -1 : 0));

                //move eur
                let eurObj = sortedCurList.splice(sortedCurList.findIndex(ele => ele.label === 'EUR'), 1)[0];
                sortedCurList.splice(0, 0, eurObj);

                //move usd
                let usdObj = sortedCurList.splice(sortedCurList.findIndex(ele => ele.label === 'USD'), 1)[0];
                sortedCurList.splice(1, 0, usdObj);

                //move gbp
                let gbpObj = sortedCurList.splice(sortedCurList.findIndex(ele => ele.label === 'GBP'), 1)[0];
                sortedCurList.splice(2, 0, gbpObj);

                //set display prop
                this.currencyOpt = sortedCurList;
            }
        }
        else{
           this.error = error;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: AXALEADER_FIELD})
    setAXALeaderPicklistOpt({error, data}) {
        if(data){
            this.axaLeaderOpt = data.values;
        }
        else{
            this.error = error;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: CATCOVERAGE_FIELD})
    setCatCoveragePicklistOpt({error, data}) {
        if(data){
            this.catCoverageOpt = data.values;
            if(this.valCatCoverage == undefined || this.valCatCoverage == null){
                this.valCatCoverage = '2';
            }
        }
        else{
            this.error = error;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: SUBLOB_FIELD})
    setSubLOBPicklistValues({error, data}) {
        if(data) {
            this.subLobOpt = data.values;
        }
        else if(error) {
            this.error = JSON.stringify(error);
        }
    }

    handleOnChangeIncepDate(event){
        this.inceptionDateVal = event.detail.value;

        if(this.inceptionDateVal != undefined && this.inceptionDateVal != null && this.expiryDateVal != undefined && this.expiryDateVal != null){
            let ltaInceptionDate = new Date(this.inceptionDateVal+'T00:00');
            let utcLtaInceptionDate = Date.UTC(ltaInceptionDate.getFullYear(), ltaInceptionDate.getMonth(), ltaInceptionDate.getDate());
            let ltaExpiryDate = new Date(this.expiryDateVal+'T00:00');
            let utcLTAExpiryDate = Date.UTC(ltaExpiryDate.getFullYear(), ltaExpiryDate.getMonth(), ltaExpiryDate.getDate());
            let numDaysLTAExpiryDate = Math.floor((utcLTAExpiryDate - utcLtaInceptionDate) / (1000 * 60 * 60 * 24)) + 1;
            this.daysDurationVal = numDaysLTAExpiryDate;
        }
        else{
            this.daysDurationVal = 0;
        }
    }

    handleOnChangeExpDate(event){
        this.expiryDateVal = event.detail.value;

        if(this.inceptionDateVal != undefined && this.inceptionDateVal != null && this.expiryDateVal != undefined && this.expiryDateVal != null){
            let ltaInceptionDate = new Date(this.inceptionDateVal+'T00:00');
            let utcLtaInceptionDate = Date.UTC(ltaInceptionDate.getFullYear(), ltaInceptionDate.getMonth(), ltaInceptionDate.getDate());
            let ltaExpiryDate = new Date(this.expiryDateVal+'T00:00');
            let utcLTAExpiryDate = Date.UTC(ltaExpiryDate.getFullYear(), ltaExpiryDate.getMonth(), ltaExpiryDate.getDate());
            let numDaysLTAExpiryDate = Math.floor((utcLTAExpiryDate - utcLtaInceptionDate) / (1000 * 60 * 60 * 24)) + 1;
            this.daysDurationVal = numDaysLTAExpiryDate;
        }
        else{
            this.daysDurationVal = 0;
        }
    }

    handleChangeNature(event){
        let natureTypeVal = event.currentTarget.value;
        let docNameVal = event.currentTarget.name;
        let lstUpdatedDoc = [];

        for(let i = 0; i < this.lstDocuments.length; i++){
            let document = this.lstDocuments[i];

            if(this.lstDocuments[i].Id == docNameVal){
                document.Nature__c = natureTypeVal;
            }

            lstUpdatedDoc.push(document);
        }

        this.lstDocuments = lstUpdatedDoc;
    }

    initSAModal(){
        let inputs = this.template.querySelectorAll('lightning-input, lightning-combobox, lightning-textarea, lightning-dual-listbox');

        for(let i = 0; i < inputs.length; i++) {

            if(inputs[i].type == 'checkbox'){
                inputs[i].checked = false;
            }
            else{
                inputs[i].value = null;
            }
        }

        //General Information
        this.specialAcceptanceNameVal = null;
        this.disableSpecialAcceptanceName = false;
        this.macroLobFromProgram = null;
        this.selectedSubLOB = null;

        //Policy Information
        this.inceptionDateVal = null;
        this.expiryDateVal = null;
        this.daysDurationVal = 0;

        //Original Insured Value - Life
        this.valLimitType = null;
        this.valExposureBasedOn = null;
        this.valOriginalPolicyPremium = null;
        this.valOriginalPolicyPremiumEuro = null;

        //Original Insured Value - P&C
        this.valTotalInsuredValue = null;
        this.valTotalInsuredValueEuro = null;
        this.valLimit = null;
        this.valLimitEuro = null;
        this.valTotalExposureAxaSharePC = null;
        this.valDeductibleAmount = null;
        this.valDeductibleAmountEuro = null;
        this.valDeductiblePercentage = null;
        this.disableDeductibleAmount = false;
        this.disableDeductiblePercentage = false;

        //Original Insured Value - Autofac
        this.valTopLocationPdValues100 = null;
        this.valTopLocationPdValues100Euro = null;
        this.valTopLocationBiValues100 = null;
        this.valTopLocationBiValues100Euro = null;
        this.valMaximumPossibleLossMpl = null;
        this.valMaximumPossibleLossMplEuro = null;
        this.valLossLimit100 = null;
        this.valLossLimit100Euro = null;
        this.valExposureAmount100 = null;
        this.valExposureAmount100Euro = null;
        this.valTotalExposureAxaShareAutoFac = null;
        this.valCededExposureTreaty = 0;
        this.valCededExposureTreatyEuro = null;
        this.valCededExposureAutofac = 0;
        this.valCededExposureAutofacEuro = null;
        this.valCededExposureInternalFacultative = 0;
        this.valCededExposureInternalFacultativeEuro = null;
        this.valCededExposureExternalFacultative = 0;
        this.valCededExposureExternalFacultativeEuro = null;
        this.valTotalAxaShare = null;
        this.valTotalAxaShareEuro = null;
        this.valOriginalPremium100 = null;
        this.valOriginalPremium100Euro = null;
        this.valOriginalNetRate = null;

        //CAT Limits
        this.valCatCoverage = '2';

        //Life Insurance
        this.valNumberHeads = null;
        this.valRateExchange = null;
        this.valTreatyExposure = null;
        this.valTreatyExposureEuro = null;
        this.valTotalSumRisk = null;
        this.valTotalSumRiskEuro = null;
        this.valAverageSumRisk = null;
        this.valAverageSumRiskEuro = null;
        this.valAxaShare = null;
        this.valTotalExposureAxaShare = null;
        this.valTotalExposureAxaShareEuro = null;

        //Autofac Placement
        this.valAutofacShare = null;
        this.valFacLayer = null;
        this.valInXsOf = null;
        this.displayAutofacQS = false;
        this.displayAutofacXS = false;
        this.valTypeFacPlacement = null;

        //Document
        this.lstDocuments = [];
        this.titleCountDocument = 'My Documents (0)';
    }

    handleOpenNewModal(event){
        this.isCopySa = false;
        this.isNewSa = false;
        this.initSAModal();

        if(this.valProgram == null || this.valProgram == undefined || this.valProgram == ''){
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.NoProgramIsSelectedForSA, variant: 'error'}), );
        }
        else{
            this.isNewSa = true;
        }
    }

    handleCloseNewModal(event) {
        this.displayAutoFacForm = false;
        this.displayPCForm = false;
        this.displayLifeForm = false;
        this.isCopySa = false;
        this.isNewSa = false;
        this.getProgramDetail();
    }

    handleOpenNewDocumentModal(event){
        this.isOpenDocModal = true;
        this.documentNames = null;
    }

    handleChangeDocCheckbox(event){
        let checkboxChecked = event.currentTarget.checked;
        let docNameVal = event.currentTarget.name;
        let lstUpdatedDoc = [];
        let numOfDocChecked = 0;

        for(let i = 0; i < this.lstDocuments.length; i++){
            let document = this.lstDocuments[i];
            if(this.lstDocuments[i].Id == docNameVal){
                document.Checked = checkboxChecked;
                if(document.Checked == true){
                    numOfDocChecked = numOfDocChecked + 1;
                }
            }
             lstUpdatedDoc.push(document);
        }

        this.lstDocuments = lstUpdatedDoc;
        this.titleCountDocument = 'My Documents ('+ this.lstDocuments.length +')';

        if(numOfDocChecked > 0){
            this.disableDeleteBtn = false;
        }
        else{
            this.disableDeleteBtn = true;
        }
    }

    handleDeleteDocument(event){
        let selectedDocumentToDelete = [];
        this.disableDeleteBtn = true;

        for(let i = 0; i < this.lstDocuments.length; i++){
            if(this.lstDocuments[i].Checked == true){
                this.lstSelectedDocument.push(this.lstDocuments[i]);
                this.lstSelectedDeleteDocumentId.push(this.lstDocuments[i].Id);
                selectedDocumentToDelete.push(this.lstDocuments[i].Id);
            }
        }

        this.lstDocuments = this.lstDocuments.filter( function(e) { return this.indexOf(e) < 0; }, this.lstSelectedDocument);
        this.titleCountDocument = 'My Documents ('+ this.lstDocuments.length +')';    

        deleteContentVersionDocument({ lstDeletedDocument : selectedDocumentToDelete})
        .then(result => {
            this.dispatchEvent(new ShowToastEvent({title: 'Success', message: this.label.DeleteDocumentSucessMsg, variant: 'success' }),);
        })
        .catch(error => {
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error'}), );
        });
    }

    handleUploadFinished(event){
        this.documentNames = null;
        this.uploadedDoc = event.detail.files;

        for(let i = 0; i < this.uploadedDoc.length; i++){
            if(this.documentNames == null){
                this.documentNames = this.uploadedDoc[i].name + ';';
            }
            else{
                this.documentNames += this.uploadedDoc[i].name + ';';
            }
        }
    }

    handleSaveUploadDoc(event){
        if(this.uploadedDoc.length > 0){
            this.uploadHelper();
        }
        else{
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message:this.label.NoFileIsFound, variant: 'error'}), );
        }
    }

    uploadHelper(){
        let lstUploadedDocId = [];

        for(let i = 0; i < this.uploadedDoc.length; i++){
            lstUploadedDocId.push(this.uploadedDoc[i].documentId);
        }

        getContentVersionId({lstContentDocumentId : lstUploadedDocId})
        .then(result => {

            for(let i = 0; i < result.length; i++){
                let document = {};
                document['Name'] = result[i].Title;
                document['Nature__c'] = '';
                document['Checked'] = false;
                document['Id'] = result[i].Id;
                document['Viewable'] = true;

                if(this.isCE == true){
                    document['DocumentUrl'] = "/sfc/servlet.shepherd/document/download/"+ result[i].ContentDocumentId+"?operationContext=S1";
                }
                else{
                    document['DocumentUrl'] = "../sfc/servlet.shepherd/version/download/"+ result[i].Id+"?operationContext=S1";
                }
            
                document['SpecialAcceptance__c'] = null;
                document['ContentDocumentId'] = result[i].ContentDocumentId;
                this.lstDocuments.push(document);
            }

            this.titleCountDocument = 'My Documents ('+ this.lstDocuments.length +')';
            this.handleSaveDocument();
        })
        .catch(error => {
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error'}), );
        });

        this.isOpenDocModal = false;
        this.uploadedDoc = [];
    }

    handleSaveDocument(){
        if(this.lstDocuments != undefined){
            let lstSaveDocument = [];

            for (let i = 0; i < this.lstDocuments.length; i++){
                let objDocument = {};
                objDocument.Nature__c = this.lstDocuments[i].Nature__c;
                objDocument.Title = this.lstDocuments[i].Name;
                objDocument.Id = this.lstDocuments[i].Id;
                objDocument.SpecialAcceptance__c = null;
                objDocument.PathOnClient = this.lstDocuments[i].Name;
                objDocument.ContentDocumentId = this.lstDocuments[i].ContentDocumentId
                lstSaveDocument.push(objDocument);
            }

            saveDocuments({lstContentVersion : lstSaveDocument})
            .then(result => {
                this.dispatchEvent(new ShowToastEvent({title: 'Success', message: this.label.DocumentSavedSuccessMsg, variant: 'success' }),);
            })
            .catch(error => {
                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error'}), );
            });
        }
    }

    handleCloseUploadModal(event){
        this.isOpenDocModal = false;
    }

    handleSaveSubmitSA(event){
        this.isTotalAxaShareInvalid = false ;//MRA W-1251 13/09/2022
        this.spinnerSaveSpecialAcceptance = true;
        this.btnNameclick = event.currentTarget.name;
        this.errorclass = '';
        //MRA W-1251 13/09/2022 : START
        let totalAxaShareInput = this.template.querySelector('.TotalAxaShare__c');
        let totalExposureAxaShareInput = this.template.querySelector('.TotalExposureAxaShareAutofac');
        if(this.displayAutoFacForm){
            if (totalAxaShareInput.value !== totalExposureAxaShareInput.value) {
                this.isTotalAxaShareInvalid = true ;
            }
        }
        //MRA W-1251 13/09/2022 : END

        const allValid = [...this.template.querySelectorAll('lightning-input, lightning-combobox, lightning-textarea, lightning-dual-listbox')]
        .reduce((validSoFar, inputCmp) => {
                    inputCmp.reportValidity();
                    return validSoFar && inputCmp.checkValidity();
        }, true);

        if(allValid && !this.isTotalAxaShareInvalid){        //MRA W-1251 13/09/2022 
            let inputs = this.template.querySelectorAll('lightning-input, lightning-combobox, lightning-textarea, lightning-dual-listbox');
            let specialAcceptanceRecord = {};

            specialAcceptanceRecord['Program__c'] = this.valProgram;
            specialAcceptanceRecord['PrincipalCedingCompany__c'] = this.valPrincipalCedComp;
            specialAcceptanceRecord['UnderWrittingYear__c'] = this.valUwYear;
            specialAcceptanceRecord['Limit__c'] = this.valLimit; // RRA - 1240 - 16/08/2022
            specialAcceptanceRecord['LimitUnlimited__c'] = this.valLimitUnlimited; // RRA - 1240 - 16/08/2022 
            
            specialAcceptanceRecord['LimitType__c'] = null;
            specialAcceptanceRecord['ExposureBasedOn__c'] = null;
            
            //RRA - ticket 1523 - 15062023 - BUG error message
            if (this.displayPCForm || this.displayLifeForm){
                specialAcceptanceRecord['LimitType__c'] = this.valLimitType;
            }else if (this.displayAutoFacForm){
                specialAcceptanceRecord['ExposureBasedOn__c'] = this.valExposureBasedOn;
            }

            if(this.isCE == true){
                specialAcceptanceRecord['InternalStatus__c'] = 'Setup';
            }
            else{
                specialAcceptanceRecord['PortalStatus__c'] = 'Draft';
            }

            for(let input of inputs){
                if(input.name != ''){
                    if(input.type == 'checkbox'){
                        specialAcceptanceRecord[input.name] = input.checked;
                    }
                    else if(input.type == 'number' && input.name != 'OriginalUwYear__c'){
                        specialAcceptanceRecord[input.name] = parseFloat(input.value);
                    }
                    else{
                        specialAcceptanceRecord[input.name] = input.value;
                    }
                }
            }

            specialAcceptanceRecord['Reference__c'] = this.referenceVal;
            specialAcceptanceRecord['RecordTypeId'] = this.typeOfSARecordTypeId;

            if(this.displayAutoFacForm == true){
                specialAcceptanceRecord['NaceCode__c'] = this.selectedNaceText;
                specialAcceptanceRecord['OriginalInsuredActivityAutofac__c'] = this.valOriginalInsuredActAutofac;
            }

            console.log('specialAcceptanceRecord.Limit__c ==  ', specialAcceptanceRecord.Limit__c);
            console.log('specialAcceptanceRecord.LimitType__c ==  ', specialAcceptanceRecord.LimitType__c);
            console.log('specialAcceptanceRecord.LimitUnlimited__c ==  ', specialAcceptanceRecord.LimitUnlimited__c);
            console.log('specialAcceptanceRecord.ExposureBasedOn__c ==  ', specialAcceptanceRecord.ExposureBasedOn__c);

            if(specialAcceptanceRecord.OriginalUwYear__c != null && specialAcceptanceRecord.OriginalUwYear__c != '' && specialAcceptanceRecord.OriginalUwYear__c != undefined &&  specialAcceptanceRecord.OriginalUwYear__c.length != 4){
                this.spinnerSaveSpecialAcceptance = false;
                this.errorclass = 'slds-has-error';
                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.OriginalYearNotInRightFormat, variant: 'error' }),);
            }
            else if(specialAcceptanceRecord.NaturalPerson__c == false && specialAcceptanceRecord.LegalEntity__c == false){
                this.spinnerSaveSpecialAcceptance = false;
                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.SelectLegalEntityOrNatural, variant: 'error' }),);
            }
            else if(specialAcceptanceRecord.CatCoverage__c == '1' && ((specialAcceptanceRecord.FloodLimit__c == '' || isNaN(specialAcceptanceRecord.FloodLimit__c)) && (specialAcceptanceRecord.WindstormLimit__c == '' || isNaN(specialAcceptanceRecord.WindstormLimit__c)) && (specialAcceptanceRecord.EarthquakeLimit__c == '' || isNaN(specialAcceptanceRecord.EarthquakeLimit__c)) && (specialAcceptanceRecord.TerrorismLimit__c == '' || isNaN(specialAcceptanceRecord.TerrorismLimit__c)))){
                this.spinnerSaveSpecialAcceptance = false;
                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.FloodWindstormEarthquakeTerrorism, variant: 'error' }),);
            //RRA - ticket 1523 - 26052023
            }else if ((this.displayPCForm || this.displayLifeForm) && specialAcceptanceRecord.LimitType__c == '--None--' || specialAcceptanceRecord.LimitType__c == ''){
                this.spinnerSaveSpecialAcceptance = false;
                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.limitTypeMandatory, variant: 'error' }),);
            }
            //RRA - 1191 03082022 to commented for validation of LimitType__c and LimitUnlimited__c fields
            /*else if(this.displayLifeForm == false && (specialAcceptanceRecord.Limit__c == null || specialAcceptanceRecord.Limit__c == '' || isNaN(specialAcceptanceRecord.Limit__c)) && (specialAcceptanceRecord.LimitUnlimited__c == false || specialAcceptanceRecord.LimitUnlimited__c == null || specialAcceptanceRecord.LimitUnlimited__c == undefined || specialAcceptanceRecord.LimitUnlimited__c == '') && (specialAcceptanceRecord.LimitType__c != '1')){
                this.spinnerSaveSpecialAcceptance = false;
                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.LimitUnlimitedErrMsg, variant: 'error' }),);
            }*/
            // RRA - 1240 - 16/08/2022
            else if ((this.displayPCForm && specialAcceptanceRecord.Limit__c == null || specialAcceptanceRecord.Limit__c == '' || isNaN(specialAcceptanceRecord.Limit__c)) &&  specialAcceptanceRecord.LimitUnlimited__c == false && (specialAcceptanceRecord.LimitType__c != '1' && specialAcceptanceRecord.ExposureBasedOn__c == undefined)){ 
                this.spinnerSaveSpecialAcceptance = false;
                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.LimitUnlimitedErrMsg, variant: 'error' }),);
                console.log('this.valLimit 111 ==  ', this.valLimit);
                console.log('this.valLimitUnlimited 1111 ==  ', this.valLimitUnlimited);

            }else if ((this.displayAutoFacForm && specialAcceptanceRecord.Limit__c == null || specialAcceptanceRecord.Limit__c == '' || isNaN(specialAcceptanceRecord.Limit__c)) &&  specialAcceptanceRecord.LimitUnlimited__c == false && (specialAcceptanceRecord.ExposureBasedOn__c != 'Sums Insured' && specialAcceptanceRecord.LimitType__c == undefined)){ 
                this.spinnerSaveSpecialAcceptance = false;
                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.LimitUnlimitedErrMsg, variant: 'error' }),);
                console.log('this.valLimit 333 ==  ', this.valLimit);
                console.log('this.valLimitUnlimited 333 ==  ', this.valLimitUnlimited);
            }
            else if(this.btnNameclick == 'Submit'){
                this.specialAcceptanceRecordToSave = specialAcceptanceRecord;
                this.spinnerSaveSpecialAcceptance = false;
                this.isSubmit = true;
            }
            else if(this.btnNameclick == 'Save'){
                this.specialAcceptanceRecordToSave = specialAcceptanceRecord;
                this.saveSpecialAcceptanceRecord();
            }
        }
        else{
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.RequiredFieldMissingSA, variant: 'error'}), );
            this.spinnerSaveSpecialAcceptance = false;
        }
    }

    handleCloseSubmitModal(event){
        this.isSubmit = false;
    }

    handleAcceptSubmit(event){
        this.isSubmit = false;
        this.spinnerSaveSpecialAcceptance = true;

        checkIfSAEmailIsFound({pccId : this.valPrincipalCedComp})
        .then(result => {
            let saEmailNull = result.saEmailNull;

            if(saEmailNull == true){
                this.spinnerSaveSpecialAcceptance = false;
                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.EmailNotFound, variant: 'error'}), );
            }
            else if(saEmailNull == false){
                this.saveSpecialAcceptanceRecord();
            }
        })
        .catch(error => {
            this.spinnerSaveSpecialAcceptance = false;
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error'}), );
        });
    }

    saveSpecialAcceptanceRecord(){
        let lstUpdDocuments = [];

        for(let i = 0; i < this.lstDocuments.length; i++){
            lstUpdDocuments.push({ ...this.lstDocuments[i] });
        }

        this.lstDocuments = lstUpdDocuments;

        saveSpecialAcceptanceRecord({ specialAcceptanceObj : this.specialAcceptanceRecordToSave, lstDocumentToUpdate : this.lstDocuments, actionBtnClick : this.btnNameclick, isUserCE : this.isCE})
        .then(result => {
            if(result.hasOwnProperty('Error') && result.Error){
                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: result.Error, variant: 'error' }),);
                this.spinnerSaveSpecialAcceptance = false;
            }
            else{
                this.dispatchEvent(new ShowToastEvent({title: 'Success', message: this.label.SACreatedSuccessMsg, variant: 'success' }),);
                this.spinnerSaveSpecialAcceptance = false;
                this.handleCloseNewModal();
            }
            this.getProgramDetail();
        })
        .catch(error => {
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error'}), );
            this.spinnerSaveSpecialAcceptance = false;
        });
    }

    getProgramDetail(){
        this.natureProgram = null;
        this.displayAutoFacForm = false;
        this.displayPCForm = false;
        this.displayLifeForm = false;
        this.data = [];

        getProgramDetail({programId : this.valProgram, isUserCE : this.isCE})
        .then(result => {
            if(result.lstProgram.length != 0){
                let program = result.lstProgram[0];
                this.progObj = result.lstProgram[0];
                this.macroLobFromProgram = program.Macro_L_O_B__c;
                let newResult = result.lstSpecialAcceptance;

                this.data = newResult.map(row => {
                    let macroLobLabel = this.macroLobFromProgram;
                    if(this.isCE == true){
                        if(row.InternalStatus__c != undefined){
                            status = row.InternalStatus__c;
                        }
                    }
                    else{
                        if(row.PortalStatus__c != undefined){
                            status = row.PortalStatus__c;
                        }
                    }
                     return {...row , status, macroLobLabel}
                });

                this.titleCountSpecialAcceptance = 'Special Acceptances (' + this.data.length + ')';
                this.mapRateByCurrencyLabel = result.mapRateByCurrencyLabel;
                this.isProgramRenewed = result.isProgramRenewed;
                this.renewedProgId = result.renewedProgId;

                let inceptionDate = new Date(program.InceptionDate__c+'T00:00');
                let inceptionMonth;

                if((inceptionDate.getMonth() + 1) <= 9){
                    inceptionMonth = '0' + (inceptionDate.getMonth() + 1);
                }
                else{
                    inceptionMonth = inceptionDate.getMonth() + 1;
                }

                this.referenceVal = inceptionDate.getFullYear() + '-' + inceptionMonth + '-' + result.lastRefIndex;

                for(let i = 0; i < this.data.length; i++){
                    this.data[i]['ProgramName'] = this.data[i].Program__r.Name;

                    if(this.isCE == true){
                        this.data[i]['nameUrl'] = '../n/LoadSARequest?s__id='+this.data[i].Id+'-'+this.valUwYear+'-'+this.valPrincipalCedComp+'-'+this.valProgram+'-undefined-undefined';
                    }
                    else{
                        this.data[i]['nameUrl'] = '/cedingPortal/s/SADetail?s__id='+this.data[i].Id+'-'+this.valUwYear+'-'+this.valPrincipalCedComp+'-'+this.valProgram;
                    }
                }

                // If the Nature of the program = P&C & PCC =! AXA FAC IARD 🡪 P&C form
                // If the Nature of the program = Life & PCC =! AXA FAC IARD  🡪 Life form
                // If the PCC == AXA FAC IARD 🡪 Auto FAC form

                let saType = null;

                if(program.PrincipalCedingCompany__r != undefined && program.PrincipalCedingCompany__r.Name == 'AXA FAC IARD /FR (P)'){
                    this.displayAutoFacForm = true;
                    this.valLimitUnlimited = false;
                    //this.disableLimitUnlimited = false; //RRA - 1240 - 10/08/2022 (to commented for ticket 1523 - RRA - 30052023)
                    //this.disableLimit = false; //RRA - 1240 - 10/08/2022 (to commented for ticket 1523 - RRA - 30052023)
                    this.tonHasError = true;
                    this.tonHasErrorUnlimited = true;
                    //this.valLimit = null;
                    this.valLimitType = '--None--';
                    saType = 'Autofac';
                }
                else if(program.Nature__c == 'P&C'){
                    this.displayPCForm = true;
                    //this.template.querySelector('[data-id="limitUnlimitedVal"]').checked = false; //RRA - 1191 - 03/08/22 
                    this.valLimitUnlimited = false;
                    //this.disableLimitUnlimited = false; //RRA - 1240 - 10/08/2022 (to commented for ticket 1523 - RRA - 30052023)
                    //this.disableLimit = false; //RRA - 1240 - 10/08/2022 (to commented for ticket 1523 - RRA - 30052023)
                    this.tonHasError = true;
                    this.tonHasErrorUnlimited = true;
                    //this.valLimit = null;
                    this.valLimitType = '--None--';
                    saType = 'PC';
                }
                else if(program.Nature__c == 'Life'){
                    this.displayLifeForm = true;
                    //this.disableLimit = true; (to commented for ticket 1523 - RRA - 30052023)
                    //this.disableLimitUnlimited = false; (to commented for ticket 1523 - RRA - 30052023)
                    this.valLimit = null;
                    this.valLimitType = '1';
                    saType = 'Life';
                }

                this.natureProgram = program.Nature__c;
                this.covCedComOpt = result.lstCedingComp;

                getTypeOfSARecordTypeId({typeOfSA : saType})
                .then(result => {
                    this.typeOfSARecordTypeId = result;
                })
                .catch(error => {
                    this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error'}), );
                });
            }
            else{
                this.data = [];
                this.natureProgram = null;
                this.titleCountSpecialAcceptance = 'Special Acceptances (0)';
            }
        })
        .catch(error => {
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error'}), );
        });
    }

    handleOnchangeValue(event){
        let value = event.currentTarget.value;
        let fieldName = event.currentTarget.name;
        
        //RRA - ticket 1523 - 31052023
        let fieldNameLimiType = event.target.name;
        let fieldValueLimiType = event.target.value;
        
        console.log('fieldNameLimiType ==' , fieldNameLimiType);
        console.log('fieldValueLimiType ==' , fieldValueLimiType);

        if(fieldName == 'Currency__c'){
            if(this.mapCurrency.has(value)){
                let currencyLabel = this.mapCurrency.get(value);

                if(this.mapRateByCurrencyLabel[currencyLabel] != undefined){
                    this.valRateExchange = this.mapRateByCurrencyLabel[currencyLabel];
                }
                else{
                    this.valRateExchange = null;
                }

                this.valTotalInsuredValueEuro = parseFloat(this.valTotalInsuredValue) / parseFloat(this.valRateExchange);
                this.valLimitEuro = parseFloat(this.valLimit) / parseFloat(this.valRateExchange);
                this.valTopLocationPdValues100Euro = parseFloat(this.valTopLocationPdValues100) / parseFloat(this.valRateExchange);
                this.valTopLocationBiValues100Euro = parseFloat(this.valTopLocationBiValues100) / parseFloat(this.valRateExchange);
                this.valMaximumPossibleLossMplEuro = parseFloat(this.valMaximumPossibleLossMpl) / parseFloat(this.valRateExchange);
                this.valLossLimit100Euro = parseFloat(this.valLossLimit100) / parseFloat(this.valRateExchange);
                this.valExposureAmount100Euro = parseFloat(this.valExposureAmount100) / parseFloat(this.valRateExchange);
                this.valCededExposureTreatyEuro = parseFloat(this.valCededExposureTreaty) / parseFloat(this.valRateExchange);
                this.valInXsOf = this.valCededExposureTreatyEuro;
                this.valCededExposureAutofacEuro = parseFloat(this.valCededExposureAutofac) / parseFloat(this.valRateExchange);
                this.valFacLayer = this.valCededExposureAutofacEuro;
                this.valCededExposureInternalFacultativeEuro = parseFloat(this.valCededExposureInternalFacultative) / parseFloat(this.valRateExchange);
                this.valCededExposureExternalFacultativeEuro = parseFloat(this.valCededExposureExternalFacultative) / parseFloat(this.valRateExchange);
                this.valDeductibleAmountEuro = parseFloat(this.valDeductibleAmount) / parseFloat(this.valRateExchange);
                this.valOriginalPolicyPremiumEuro = parseFloat(this.valOriginalPolicyPremium) / parseFloat(this.valRateExchange);
                this.valOriginalPremium100Euro = parseFloat(this.valOriginalPremium100) / parseFloat(this.valRateExchange);
                this.valTotalSumRiskEuro = parseFloat(this.valTotalSumRisk) / parseFloat(this.valRateExchange);
                this.valAverageSumRisk = parseFloat(this.valTotalSumRisk) / parseFloat(this.valNumberHeads);
                this.valAverageSumRiskEuro = this.valAverageSumRisk / parseFloat(this.valRateExchange);
                this.valTotalAxaShareEuro = parseFloat(this.valTotalAxaShare) / parseFloat(this.valRateExchange);
                //this.valNetPremiumLayerEuro = parseFloat(this.valOriginalPremium100Euro) * (parseFloat(this.valAxaShare) / 100) * (1- (1 - 33,2411295999901 / 100) * (1 - (parseFloat(this.valAutofacCommission) / 100))); //RRA - 980 - 13/06/2022
                //MRA W-980 : Net Premium for the layer according AutoFac wording "rating for layers" (in EUR) : START
                let layer = parseInt(this.label.constantPremiumValue)*((Math.pow((this.searchMinimum(this.valCededExposureAutofacEuro + this.valCededExposureTreatyEuro,this.valTotalAxaShareEuro)/this.valTotalAxaShareEuro)*100,(parseFloat(this.label.powNetPremiumValue)))) - (Math.pow((this.searchMinimum(this.valCededExposureTreatyEuro ,this.valTotalAxaShareEuro)/this.valTotalAxaShareEuro)*100,(parseFloat(this.label.powNetPremiumValue)))) );
                this.valNetPremiumLayerEuro = parseFloat(this.valOriginalPremium100Euro*(1-(1-(layer/100)))*(1-(this.valAutofacCommission/100))) ;
                //MRA W-980 : Net Premium for the layer according AutoFac wording "rating for layers" (in EUR) : END

                console.log('this.valNetPremiumLayerEuro == ', this.valNetPremiumLayerEuro);

                if(this.displayAutoFacForm == true){
                    this.valAutofacShare = (parseFloat(this.valCededExposureAutofacEuro) / parseFloat(this.valTotalAxaShareEuro)) * 100;
                }

                if(this.displayAutoFacForm){
                    this.valTotalExposureAxaShareEuro = parseFloat(this.valTotalExposureAxaShareAutoFac) / parseFloat(this.valRateExchange);
                }
                else if(this.displayLifeForm){
                    this.valTotalExposureAxaShareEuro = parseFloat(this.valTotalExposureAxaShareLife) / parseFloat(this.valRateExchange);
                }
                else if(this.displayPCForm){
                    this.valTotalExposureAxaShareEuro = parseFloat(this.valTotalExposureAxaSharePC) / parseFloat(this.valRateExchange);
                }

                this.valNetCededPremiumAutofac = parseFloat(this.valOriginalPremium100) * (parseFloat(this.valAxaShare) / 100) * (parseFloat(this.valAutofacShare) / 100) * (1 - (parseFloat(this.valAutofacCommission) / 100));
                this.valNetCededPremiumAutofacEuro = parseFloat(this.valNetCededPremiumAutofac) / parseFloat(this.valRateExchange);
                this.valTreatyExposureEuro = parseFloat(this.valTreatyExposure) / parseFloat(this.valRateExchange);

            }
        }
        else if(fieldName == 'TotalInsuredValue__c'){
            //'= Total Insured Value x Rate of Exchange
            this.valTotalInsuredValueEuro = parseFloat(value) / parseFloat(this.valRateExchange);
            this.valTotalInsuredValue = value;

            if(this.displayPCForm == true){
                if(this.valLimitUnlimited == false){
                    this.disableLimit = false;
                }

                //MBE - 18/08
                //W-0975 - If limit type = loss limit, EML, Other, MPL et PML alors total exposure at AXA share = limit x AXA Share (%)

                if(this.valLimitType == '2' || this.valLimitType == '3' || this.valLimitType == '4' || this.valLimitType == '5' || this.valLimitType == '6'){
                    //MPL or PML
                    //New Rule for EML/OTHER/Loss Limit
                    this.valTotalExposureAxaSharePC = parseFloat(this.valLimit) * (parseFloat(this.valAxaShare) / 100);
                }
                else if(this.valLimitType == '1'){
                    //SI
                    this.valTotalExposureAxaSharePC = parseFloat(this.valTotalInsuredValue) * (parseFloat(this.valAxaShare) / 100);
                    this.disableLimit = true;
                    this.disableLimitUnlimited = true;
                    this.valLimit = null;
                }
                else{
                    this.valTotalExposureAxaSharePC = null;
                }

                this.valTotalExposureAxaShareEuro = parseFloat(this.valTotalExposureAxaSharePC) / parseFloat(this.valRateExchange);
            }
            else if(this.displayAutoFacForm == true){
                this.valOriginalNetRate = (parseFloat(this.valOriginalPremium100) / parseFloat(this.valTotalInsuredValue)) * 1000;
            }
        }
        else if(fieldName == 'Limit__c'){
            //'= Limit x Rate of Exchange
            this.valLimitEuro = parseFloat(value) / parseFloat(this.valRateExchange);
            this.valLimit = value;
            let inputBorder = this.template.querySelector('[data-id="limitVal"]');
            let inputBorderUnLimitedValue = this.template.querySelector('[data-id="limitUnlimitedVal"]');

            // RRA - 1163 - 23/06/2022
            if((value == null || value == '') && this.valLimitUnlimited == false){
                this.disableLimitUnlimited = false;
                this.disableLimit = false;
                this.tonHasError = true;
                //this.errors = 'Complete this fields.';
                this.tonHasErrorUnlimited = true;
            }
            else if ((value != null || value != '') && this.valLimitUnlimited == false){
                console.log('value == ', value);
                this.disableLimitUnlimited = true;
                this.tonHasError = true;
                this.errors = '';
                this.tonHasErrorUnlimited = false;
                inputBorder.className = '';
            }
           
            if(this.displayPCForm == true){
                if(this.valLimitUnlimited == false){
                    this.disableLimit = false;
                }

                if(this.valLimitType == '2' || this.valLimitType == '3' || this.valLimitType == '4' || this.valLimitType == '5' || this.valLimitType == '6'){
                    //MPL or PML
                    //New Rule for EML/OTHER/Loss Limit
                    this.valTotalExposureAxaSharePC = parseFloat(this.valLimit) * (parseFloat(this.valAxaShare) / 100);
                }
                else if(this.valLimitType == '1'){
                    //SI
                    this.valTotalExposureAxaSharePC = parseFloat(this.valTotalInsuredValue) * (parseFloat(this.valAxaShare) / 100);
                    this.disableLimit = true;
                    this.disableLimitUnlimited = false;
                    this.valLimit = null;
                }
                else{
                    this.valTotalExposureAxaSharePC = null;
                }

                this.valTotalExposureAxaShareEuro = parseFloat(this.valTotalExposureAxaSharePC) / parseFloat(this.valRateExchange);
            }
        }
        else if(fieldName == 'LimitUnlimited__c'){
            this.valLimitUnlimited = event.currentTarget.checked;

            //RRA - 1163 - 23/06/2022
            if(this.valLimitUnlimited == false && this.valLimitType != '1'){
                this.disableLimit = false;
                this.tonHasError = true;
                this.tonHasErrorUnlimited = true;
            }
            else if(this.valLimitUnlimited == true){
                let inputBorder = this.template.querySelector('[data-id="limitVal"]');
                this.disableLimit = true;
                this.tonHasError = false;
                this.errors = '';
                this.tonHasErrorUnlimited = true;
                inputBorder.className = '';
            }else if(this.valLimitUnlimited == false && this.valLimit ==null){
                this.tonHasError = true;
                this.tonHasErrorUnlimited = true;
            }
        }
        else if(fieldName == 'TopLocationPdValues100__c'){
            //'= Top location PD values 100% x Rate of Exchange
            this.valTopLocationPdValues100Euro = parseFloat(value) / parseFloat(this.valRateExchange);
            this.valTopLocationPdValues100 = value;
        }
        else if(fieldName == 'TopLocationBiValues100__c'){
            //'= Top location BI values 100% x Rate of Exchange
            this.valTopLocationBiValues100Euro = parseFloat(value) / parseFloat(this.valRateExchange);
            this.valTopLocationBiValues100 = value;
        }
        else if(fieldName == 'MaximumPossibleLossMpl__c'){
            //'= Maximum possible loss (MPL) x Rate of Exchange
            this.valMaximumPossibleLossMplEuro = parseFloat(value) / parseFloat(this.valRateExchange);
            this.valMaximumPossibleLossMpl = value;
        }
        else if(fieldName == 'LossLimit100__c'){
            //'= Loss Limit 100% (if applicable) x Rate of Exchange
            this.valLossLimit100Euro = parseFloat(value) / parseFloat(this.valRateExchange);
            this.valLossLimit100 = value;
        }
        else if(fieldName == 'AxaShare__c'){
            this.valAxaShare = value;

            if(this.displayAutoFacForm == true){
                this.valTotalExposureAxaShareAutoFac = parseFloat(this.valExposureAmount100) * (parseFloat(value) / 100);
                this.valTotalExposureAxaShareEuro = parseFloat(this.valTotalExposureAxaShareAutoFac) / parseFloat(this.valRateExchange);
                this.valNetCededPremiumAutofac = parseFloat(this.valOriginalPremium100) * (parseFloat(this.valAxaShare) / 100) * (parseFloat(this.valAutofacShare) / 100) * (1 - (parseFloat(this.valAutofacCommission) / 100));
                this.valNetCededPremiumAutofacEuro = parseFloat(this.valNetCededPremiumAutofac) / parseFloat(this.valRateExchange);
                //this.valNetPremiumLayerEuro = parseFloat(this.valOriginalPremium100Euro) * (parseFloat(this.valAxaShare) / 100) * (1- (1 - 33,2411295999901 / 100) * (1 - (parseFloat(this.valAutofacCommission) / 100))); //RRA - 980 - 13/06/2022
                //MRA W-980 : Net Premium for the layer according AutoFac wording "rating for layers" (in EUR) : START
                let layer = parseInt(this.label.constantPremiumValue)*((Math.pow((this.searchMinimum(this.valCededExposureAutofacEuro + this.valCededExposureTreatyEuro,this.valTotalAxaShareEuro)/this.valTotalAxaShareEuro)*100,(parseFloat(this.label.powNetPremiumValue)))) - (Math.pow((this.searchMinimum(this.valCededExposureTreatyEuro ,this.valTotalAxaShareEuro)/this.valTotalAxaShareEuro)*100,(parseFloat(this.label.powNetPremiumValue)))) );
                this.valNetPremiumLayerEuro = parseFloat(this.valOriginalPremium100Euro*(1-(1-(layer/100)))*(1-(this.valAutofacCommission/100))) ;
                //MRA W-980 : Net Premium for the layer according AutoFac wording "rating for layers" (in EUR) : END
                console.log('this.valNetPremiumLayerEuro22 == ', this.valNetPremiumLayerEuro);
            }
            else if(this.displayLifeForm == true){
                this.valTotalExposureAxaShareLife = parseFloat(this.valTotalSumRisk) * (parseFloat(value) / 100);
                this.valTotalExposureAxaShareEuro = parseFloat(this.valTotalExposureAxaShareLife) / parseFloat(this.valRateExchange);
            }
            else if(this.displayPCForm == true){
                if(this.valLimitUnlimited == false){
                    this.disableLimit = false;
                }

                if(this.valLimitType == '2' || this.valLimitType == '3' || this.valLimitType == '4' || this.valLimitType == '5' || this.valLimitType == '6'){
                    //MPL or PML
                    //New Rule for EML/OTHER/Loss Limit
                    this.valTotalExposureAxaSharePC = parseFloat(this.valLimit) * (parseFloat(this.valAxaShare) / 100);
                }
                else if(this.valLimitType == '1'){
                    //SI
                    this.valTotalExposureAxaSharePC = parseFloat(this.valTotalInsuredValue) * (parseFloat(this.valAxaShare) / 100);
                    this.disableLimit = true;
                    this.disableLimitUnlimited = false;
                    this.valLimit = null;
                }
                else{
                    this.valTotalExposureAxaSharePC = null;
                }
                this.valTotalExposureAxaShareEuro = parseFloat(this.valTotalExposureAxaSharePC) / parseFloat(this.valRateExchange);
            }
        }
        else if(fieldName == 'ExposureAmount100__c'){
            //'= Exposure amount at 100% x Rate of Exchange
            this.valExposureAmount100Euro = parseFloat(value) / parseFloat(this.valRateExchange);
            this.valExposureAmount100 = value;
            this.valTotalExposureAxaShareAutoFac = parseFloat(value) * (parseFloat(this.valAxaShare) / 100);
            this.valTotalExposureAxaShareEuro = parseFloat(this.valTotalExposureAxaShareAutoFac) / parseFloat(this.valRateExchange);
        }
        else if(fieldName == 'CededExposureTreaty__c'){
            //'= Ceded Exposure to Treaty x Rate of Exchange
            this.valCededExposureTreatyEuro = parseFloat(value) / parseFloat(this.valRateExchange);
            this.valInXsOf = this.valCededExposureTreatyEuro;
            this.valCededExposureTreaty = value;
            this.valTotalAxaShare = parseFloat(this.valCededExposureTreaty) + parseFloat(this.valCededExposureAutofac) + parseFloat(this.valCededExposureInternalFacultative) + parseFloat(this.valCededExposureExternalFacultative);
            this.valTotalAxaShareEuro = parseFloat(this.valTotalAxaShare) / parseFloat(this.valRateExchange);
            
            if(this.displayAutoFacForm == true){
                this.valAutofacShare = (parseFloat(this.valCededExposureAutofacEuro) / parseFloat(this.valTotalAxaShareEuro)) * 100;
            }
        }
        else if(fieldName == 'CededExposureAutofac__c'){
            //'= Ceded Exposure to Autofac x Rate of Exchange
            this.valCededExposureAutofacEuro = parseFloat(value) / parseFloat(this.valRateExchange);
            this.valFacLayer = this.valCededExposureAutofacEuro;
            this.valCededExposureAutofac = value;
            this.valTotalAxaShare = parseFloat(this.valCededExposureTreaty) + parseFloat(this.valCededExposureAutofac) + parseFloat(this.valCededExposureInternalFacultative) + parseFloat(this.valCededExposureExternalFacultative);
            this.valTotalAxaShareEuro = parseFloat(this.valTotalAxaShare) / parseFloat(this.valRateExchange);

            if(this.displayAutoFacForm == true){
                this.valAutofacShare = parseFloat(this.valCededExposureAutofacEuro) / (parseFloat(this.valTotalAxaShareEuro) * 100);
            }
        }
        else if(fieldName == 'CededExposureInternalFacultative__c'){
            //'= Ceded Exposure to internal facultative x Rate of Exchange
            this.valCededExposureInternalFacultativeEuro = parseFloat(value) / parseFloat(this.valRateExchange);
            this.valCededExposureInternalFacultative = value;
            this.valTotalAxaShare = parseFloat(this.valCededExposureTreaty) + parseFloat(this.valCededExposureAutofac) + parseFloat(this.valCededExposureInternalFacultative) + parseFloat(this.valCededExposureExternalFacultative);
            this.valTotalAxaShareEuro = parseFloat(this.valTotalAxaShare) / parseFloat(this.valRateExchange);
            
            if(this.displayAutoFacForm == true){
                this.valAutofacShare = (parseFloat(this.valCededExposureAutofacEuro) / parseFloat(this.valTotalAxaShareEuro)) * 100;
            }
        }
        else if(fieldName == 'CededExposureExternalFacultative__c'){
            //'= Ceded Exposure to external facultative x Rate of Exchange
            this.valCededExposureExternalFacultativeEuro = parseFloat(value) / parseFloat(this.valRateExchange);
            this.valCededExposureExternalFacultative = value;
            this.valTotalAxaShare = parseFloat(this.valCededExposureTreaty) + parseFloat(this.valCededExposureAutofac) + parseFloat(this.valCededExposureInternalFacultative) + parseFloat(this.valCededExposureExternalFacultative);
            this.valTotalAxaShareEuro = parseFloat(this.valTotalAxaShare) / parseFloat(this.valRateExchange);
            
            if(this.displayAutoFacForm == true){
                this.valAutofacShare = (parseFloat(this.valCededExposureAutofacEuro) / parseFloat(this.valTotalAxaShareEuro)) * 100;
            }
        }
        else if(fieldName == 'DeductibleAmount__c'){
            //'= Deductible (Amount) x Rate of Exchange
            this.valDeductibleAmountEuro = parseFloat(value) / parseFloat(this.valRateExchange);
            this.valDeductibleAmount = value;
            
            if(value == null || value == ''){
                this.disableDeductibleAmount = false;
                this.disableDeductiblePercentage = false;
            }
            else{
                this.disableDeductiblePercentage = true;
                this.valDeductiblePercentage = null;
            }    
        }
        else if(fieldName == 'DeductiblePercentage__c'){
            this.valDeductiblePercentage = value;
            
            if(value == null || value == ''){
                this.disableDeductibleAmount = false;
                this.disableDeductiblePercentage = false;
            }
            else{
                this.disableDeductibleAmount = true;
                this.valDeductibleAmount = null;
            }    
        }
        else if(fieldName == 'OriginalPolicyPremium__c'){
            //'= Original Policy Premium x Rate of Exchange
            this.valOriginalPolicyPremiumEuro = parseFloat(value) / parseFloat(this.valRateExchange);
            this.valOriginalPolicyPremium = value;
        }
        else if(fieldName == 'OriginalPremium100__c'){
            //'= Original Premium at 100% (net of brokerage and taxes) x Rate of Exchange
            this.valOriginalPremium100Euro = parseFloat(value) / parseFloat(this.valRateExchange);
            this.valOriginalPremium100 = value;
            this.valOriginalNetRate = (parseFloat(this.valOriginalPremium100) / parseFloat(this.valTotalInsuredValue)) * 1000;
            this.valNetCededPremiumAutofac = parseFloat(this.valOriginalPremium100) * (parseFloat(this.valAxaShare) / 100) * (parseFloat(this.valAutofacShare) / 100) * (1 - (parseFloat(this.valAutofacCommission) / 100));
            this.valNetCededPremiumAutofacEuro = parseFloat(this.valNetCededPremiumAutofac) / parseFloat(this.valRateExchange);
            //this.valNetPremiumLayerEuro = parseFloat(this.valOriginalPremium100Euro) * (parseFloat(this.valAxaShare) / 100) * (1- (1 - 33,2411295999901 / 100) * (1 - (parseFloat(this.valAutofacCommission) / 100))); //RRA - 980 - 13/06/2022
            //MRA W-980 : Net Premium for the layer according AutoFac wording "rating for layers" (in EUR) : START
            let layer = parseInt(this.label.constantPremiumValue)*((Math.pow((this.searchMinimum(this.valCededExposureAutofacEuro + this.valCededExposureTreatyEuro,this.valTotalAxaShareEuro)/this.valTotalAxaShareEuro)*100,(parseFloat(this.label.powNetPremiumValue)))) - (Math.pow((this.searchMinimum(this.valCededExposureTreatyEuro ,this.valTotalAxaShareEuro)/this.valTotalAxaShareEuro)*100,(parseFloat(this.label.powNetPremiumValue)))) );
            this.valNetPremiumLayerEuro = parseFloat(this.valOriginalPremium100Euro*(1-(1-(layer/100)))*(1-(this.valAutofacCommission/100))) ;
            //MRA W-980 : Net Premium for the layer according AutoFac wording "rating for layers" (in EUR) : END
            console.log('this.valNetPremiumLayerEuro33 == ', this.valNetPremiumLayerEuro);

        }
        else if(fieldName == 'TreatyExposure__c'){
            //'= Treaty Exposure x Rate of Exchange
            this.valTreatyExposureEuro = parseFloat(value) / parseFloat(this.valRateExchange);
            this.valTreatyExposure = value;
        }
        else if(fieldName == 'TotalSumRisk__c'){
            //'= Total Sum at Risk x Rate of Exchange
            this.valTotalSumRisk = value;
            this.valTotalSumRiskEuro = parseFloat(value) / parseFloat(this.valRateExchange);
            this.valAverageSumRisk = parseFloat(value) / parseFloat(this.valNumberHeads);
            this.valAverageSumRiskEuro = this.valAverageSumRisk / parseFloat(this.valRateExchange);

            if(this.displayLifeForm == true){
                this.valTotalExposureAxaShareLife = parseFloat(this.valTotalSumRisk) * (parseFloat(this.valAxaShare) / 100);
                this.valTotalExposureAxaShareEuro = parseFloat(this.valTotalExposureAxaShareLife) / parseFloat(this.valRateExchange);
            }
        }
        else if(fieldName == 'NumberHeads__c'){
            this.valNumberHeads = value;
            this.valAverageSumRisk = parseFloat(this.valTotalSumRisk) / parseInt(value);
            this.valAverageSumRiskEuro = parseFloat(this.valAverageSumRisk) / parseFloat(this.valRateExchange);
        }
        else if(fieldName == 'LimitType__c' || fieldNameLimiType == 'LimitType__c'){   //RRA - ticket 1523 - 31052023
            //SI	1	
            //MPL	2
            //PML	3	
            //EML	4	
            //Others
            //Total Exposure at AXA Share - P&C
            // '= If Limit type is LCI or Loss Limit or MPL or PML, then:
            // Total Exposure at AXA Share = Limit x AXA Share (%)

            // If Limit type is Sum Insured, then:  
            // Total Exposure at AXA Share = Total Insured Value x AXA Share (%) and Limit field is disabled
            this.valLimitType = value != null ? value : fieldValueLimiType;  //RRA - ticket 1523 - 31052023
            console.log('this.valLimitType ==' , this.valLimitType);
            
            if(this.displayPCForm == true){
                if(this.valLimitUnlimited == false){
                    this.disableLimit = false;
                }
                
                //RRA - ticket 1523 - 30052023 - choice of value is --None--
                if(this.valLimitType == '--None--' || this.valLimitType == null || this.valLimitType == undefined){
                    console.log('this.valLimitType empty okok');
                    this.isDisabledFields = true; 
                    this.disableLimit = true;
                    this.valTotalInsuredValue = null;
                    this.valAxaShare = null;
                    this.disableLimitUnlimited = true;
                    this.tonHasError = true;
                    this.tonHasErrorUnlimited= true;
                }else {
                    this.isDisabledFields = false; //RRA - ticket 1523 - 30052023
                    this.disableLimit = false; //RRA - ticket 1523 - 30052023
                    this.disableLimitUnlimited = false; //RRA - ticket 1523 - 3005
                    this.tonHasError = false;
                    this.tonHasErrorUnlimited= false;
                }

                if(this.valLimitType == '2' || this.valLimitType == '3' || this.valLimitType == '4' || this.valLimitType == '5' || this.valLimitType == '6'){
                    //MPL or PML
                    //New Rule for EML/OTHER/Loss Limit
                    this.valTotalExposureAxaSharePC = parseFloat(this.valLimit) * (parseFloat(this.valAxaShare) / 100);
                    //this.disableLimitUnlimited = false; //RRA - 1240 - 10/08/2022

                    console.log('this.valLimit == ', this.valLimit);
                    console.log('this.valLimitUnlimited == ', this.valLimitUnlimited);

                    if ((this.valLimit == null || this.valLimit == '' || this.valLimit == undefined || this.valLimit == 'undefined') && this.valLimitUnlimited == false){
                        this.disableLimit = false;// RRA - 1240 - 10/08/2022
                        this.disableLimitUnlimited = false;// RRA - 1240 - 10/08/2022
                        this.tonHasErrorUnlimited = true;// RRA - 1240- 10/08/2022
                        this.tonHasError= true;// RRA - 1240- 10/08/2022
                    }else if ((this.valLimit == null || this.valLimit == '' || this.valLimit == undefined || this.valLimit == 'undefined') && this.valLimitUnlimited == true){
                        this.disableLimit = true;// RRA - 1240 - 10/08/2022
                        this.disableLimitUnlimited = false;// RRA - 1240 - 10/08/2022
                        this.tonHasErrorUnlimited = true;// RRA - 1240- 10/08/2022
                        this.tonHasError= false;// RRA - 1240- 10/08/2022
                    }else if (this.valLimit != null && this.valLimitUnlimited == true){
                        this.disableLimit = false;// RRA - 1240 - 10/08/2022
                        this.disableLimitUnlimited = true;// RRA - 1240 - 10/08/2022
                        this.tonHasErrorUnlimited = false;// RRA - 1240- 10/08/2022
                        this.tonHasError= true;// RRA - 1240- 10/08/2022
                    }else if (this.valLimit != null && this.valLimitUnlimited == false){
                        this.disableLimit = false;// RRA - 1240 - 10/08/2022
                        this.disableLimitUnlimited = true;// RRA - 1240 - 10/08/2022
                        this.tonHasErrorUnlimited = false;// RRA - 1240- 10/08/2022
                        this.tonHasError= true;// RRA - 1240- 10/08/2022
                    }
                }
                else if(this.valLimitType == '1'){
                    //SI
                    this.valTotalExposureAxaSharePC = parseFloat(this.valTotalInsuredValue) * (parseFloat(this.valAxaShare) / 100);
                    this.disableLimit = true; //RRA - 1163 - 08/07/2022
                    this.disableLimitUnlimited = true; //RRA - 1163 - 08/07/2022
                    this.tonHasErrorUnlimited = false;// RRA - 1240- 10/08/2022
                    //this.template.querySelector('[data-id="limitUnlimitedVal"]').checked = false; //RRA - 1191 - 03/08/22 
                    this.tonHasError = false;
                    this.valLimit =  null;
                    this.valLimitEuro = null;
                    this.valLimitUnlimited = false;
                }
                else{
                    this.valTotalExposureAxaSharePC = null;
                    //this.disableLimit = false; //RRA - 1163 - 08/07/2022 (to commented for ticket 1523 - RRA - 31052023)
                    //this.disableLimitUnlimited = false; //RRA - 1163 - 08/07/2022 (to commented for ticket 1523 - RRA - 31052023)
                }
            }

        } else if(fieldName == 'ExposureBasedOn__c'){ //RRA - 1191 (ref 1163) -03/08/2022
            this.valExposureBasedOn = value;
            if(this.displayAutoFacForm){

                if(this.valExposureBasedOn == 'Loss Limit' || this.valExposureBasedOn == 'MPL' || this.valExposureBasedOn == 'Top Location'){
                    this.isDisabledFields = false; //RRA - ticket 1523 14062023
                     //New Rule for Top Location/MPL/Loss Limit
                     if ((this.valLimit == null || this.valLimit == '' || this.valLimit == undefined || this.valLimit == 'undefined') && this.valLimitUnlimited == false){
                        this.disableLimit = false;// RRA - 1240 - 10/08/2022
                        this.disableLimitUnlimited = false;// RRA - 1240 - 10/08/2022
                        this.tonHasErrorUnlimited = true;// RRA - 1240- 10/08/2022
                        this.tonHasError= true;// RRA - 1240- 10/08/2022
                    }else if ((this.valLimit == null || this.valLimit == '' || this.valLimit == undefined || this.valLimit == 'undefined') && this.valLimitUnlimited == true){
                        this.disableLimit = true;// RRA - 1240 - 10/08/2022
                        this.disableLimitUnlimited = false;// RRA - 1240 - 10/08/2022
                        this.tonHasErrorUnlimited = true;// RRA - 1240- 10/08/2022
                        this.tonHasError= false;// RRA - 1240- 10/08/2022
                    }else if (this.valLimit != null && this.valLimitUnlimited == true){
                        this.disableLimit = false;// RRA - 1240 - 10/08/2022
                        this.disableLimitUnlimited = true;// RRA - 1240 - 10/08/2022
                        this.tonHasErrorUnlimited = false;// RRA - 1240- 10/08/2022
                        this.tonHasError= true;// RRA - 1240- 10/08/2022
                    }else if (this.valLimit != null && this.valLimitUnlimited == false){
                        this.disableLimit = false;// RRA - 1240 - 10/08/2022
                        this.disableLimitUnlimited = true;// RRA - 1240 - 10/08/2022
                        this.tonHasErrorUnlimited = false;// RRA - 1240- 10/08/2022
                        this.tonHasError= true;// RRA - 1240- 10/08/2022
                    }
                }else if(this.valExposureBasedOn == 'Sums Insured'){
                    //SI
                    this.isDisabledFields = false; //RRA - ticket 1523 14062023
                    this.disableLimit = true; //RRA - 1191 (ref 1163) - 29/07/2022
                    this.disableLimitUnlimited = true; //RRA - 1191 (ref 1163) - 29/07/2022
                    this.template.querySelector('[data-id="limitUnlimitedVal"]').checked = false; //RRA - 1191 - 03/08/22 
                    this.tonHasErrorUnlimited = false;// RRA - 1240- 10/08/2022
                    this.tonHasError= false;
                    this.valLimit = null;
                    this.valLimitUnlimited = false;
                    this.valLimitEuro = null;
                }
                else{
                    this.disableLimit = false; //RRA - 1191 (ref 1163) - 29/07/2022
                    this.disableLimitUnlimited = false; //RRA - 1163 - 29/07/2022
                    this.isDisabledFields = false; //RRA - ticket 1523 14062023
                }
            }
        }
        else if(fieldName == 'AutofacCommission__c'){
            this.valAutofacCommission = value;
            this.valNetCededPremiumAutofac = parseFloat(this.valOriginalPremium100) * (parseFloat(this.valAxaShare) / 100) * (parseFloat(this.valAutofacShare) / 100) * (1 - (parseFloat(this.valAutofacCommission) / 100));
            this.valNetCededPremiumAutofacEuro = parseFloat(this.valNetCededPremiumAutofac) / parseFloat(this.valRateExchange);
            //this.valNetPremiumLayerEuro = parseFloat(this.valOriginalPremium100Euro) * (parseFloat(this.valAxaShare) / 100) * (1- (1 - 33,2411295999901 / 100) * (1 - (parseFloat(this.valAutofacCommission) / 100))); //RRA - 980 - 13/06/2022
            //MRA W-980 : Net Premium for the layer according AutoFac wording "rating for layers" (in EUR) : START
            let layer = parseInt(this.label.constantPremiumValue)*((Math.pow((this.searchMinimum(this.valCededExposureAutofacEuro + this.valCededExposureTreatyEuro,this.valTotalAxaShareEuro)/this.valTotalAxaShareEuro)*100,(parseFloat(this.label.powNetPremiumValue)))) - (Math.pow((this.searchMinimum(this.valCededExposureTreatyEuro ,this.valTotalAxaShareEuro)/this.valTotalAxaShareEuro)*100,(parseFloat(this.label.powNetPremiumValue)))) );
            this.valNetPremiumLayerEuro = parseFloat(this.valOriginalPremium100Euro*(1-(1-(layer/100)))*(1-(this.valAutofacCommission/100))) ;
            //MRA W-980 : Net Premium for the layer according AutoFac wording "rating for layers" (in EUR) : END
        }
        else if(fieldName == 'AutofacShare__c'){
            this.valAutofacShare = value;
            this.valNetCededPremiumAutofac = parseFloat(this.valOriginalPremium100) * (parseFloat(this.valAxaShare) / 100) * (parseFloat(this.valAutofacShare) / 100) * (1 - (parseFloat(this.valAutofacCommission) / 100));
            this.valNetCededPremiumAutofacEuro = parseFloat(this.valNetCededPremiumAutofac) / parseFloat(this.valRateExchange);
        }
        else if(fieldName == 'CatCoverage__c'){
            this.valCatCoverage = value;
        }
        else if(fieldName == 'FloodLimit__c'){
            this.valFloodLimit = value;
        }
        else if(fieldName == 'WindstormLimit__c'){
            this.valWindstormLimit = value;
        }
        else if(fieldName == 'EarthquakeLimit__c'){
            this.valEarthquakeLimit = value;
        }
        else if(fieldName == 'TerrorismLimit__c'){
            this.valTerrorismLimit = value;
        }
        else if(fieldName == 'TypeFacPlacement__c'){
            this.valTypeFacPlacement = value;
            if(value == 'QS'){
                this.displayAutofacQS = true;
                this.displayAutofacXS = false;
            }
            else if(value == 'XS'){
                this.displayAutofacQS = false;
                this.displayAutofacXS = true;
            }
        }
    }
    //MRA W-980 : Net Premium for the layer according AutoFac wording "rating for layers" (in EUR) : START
    searchMinimum(a,b){
        if (a<=b)
            return a ;
        else 
            return b ;
    }
    //MRA W-980 : Net Premium for the layer according AutoFac wording "rating for layers" (in EUR) : END

    deselectOtherCheckbox(event){
        let valueChecked = event.target.checked;
        let fieldName = event.target.name;
        
        if(valueChecked == true && fieldName == 'LegalEntity__c'){
            let checkboxes = this.template.querySelectorAll('[data-id="NaturalPerson"]')
            
            for(let i = 0; i < checkboxes.length; i++) {
                checkboxes[i].checked = false;
            }

            this.naturalPersonVal = false;
            this.disableSpecialAcceptanceName = false;
        }
        else if(valueChecked == true && fieldName == 'NaturalPerson__c'){
            let checkboxes = this.template.querySelectorAll('[data-id="LegalEntity"]')
            
            for(let i = 0; i < checkboxes.length; i++) {
                checkboxes[i].checked = false;
            }

            let specialAcceptanceNameVal = this.template.querySelectorAll('[data-id="SpecialAcceptanceName"]')
            
            for(let i = 0; i < specialAcceptanceNameVal.length; i++) {
                specialAcceptanceNameVal[i].value = this.referenceVal;
            }

            this.legalEntityVal = false;
            this.specialAcceptanceNameVal = this.referenceVal;
            this.disableSpecialAcceptanceName = true;
        }
        else if(valueChecked == false && fieldName == 'NaturalPerson__c'){
            this.disableSpecialAcceptanceName = false;
        }
    }

    handleRowAction(event){
        let actionName = event.detail.action.name;
        let selectedRowSA = { ...event.detail.row };
        this.selectedRowSA = selectedRowSA;
        this.selectedProgramToCopy = selectedRowSA.Program__c;
        this.selectedSpecialAcceptanceId = selectedRowSA.Id;

        switch(actionName){
            case 'copy':
                this.copySADetail(this.selectedProgramToCopy);
                break;
            case 'renew':
                this.renewSADetail(selectedRowSA);
                break;
            case 'delete':
                if(this.isCE == false){
                    this.deleteSA();
                }
                break;
        }
    }

    copySADetail(programCopy){
        this.isCopySa = false;
        this.isNewSa = false;
        this.valCopyDocument = true;

        getProgramNature({programId : programCopy, isUserCE : this.isCE})
        .then(result => {
            this.programNatureOptions = result.lstProgramNatureOption;
            this.isCopySa = true;
        })
        .catch(error => {
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error'}), );
        });
    }

    handleCloseCopySAOpenModal(){
        this.isCopySa = false;
        this.isNewSa = false;
    }

    renewSADetail(saRecord){
        checkForRenewSA({selectedSaId : saRecord.Id})
        .then(result => {
            if(this.isProgramRenewed == false){
                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.ProgramNotRenewed, variant: 'error'}), );
            }
            else if(saRecord.Bound__c != 'Yes'){
                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.SACannotBeRenewedBindStatus, variant: 'error'}), );
            }
            else if(result.isSARenewed == true){
                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.SAAlreadyRenewed, variant: 'error'}), );
            }
            else{
                this.isRenewSa = true;
            }
        })
        .catch(error => {
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error'}), );
        });
    }

    handleCloseRenewSAOpenModal(event){
        this.isCopySa = false;
        this.isNewSa = false;
        this.isRenewSa = false;
    }

    deleteSA(saRecord){
        this.isAskToDelete = true;
    }

    handleAcceptDelete(event){
        this.isAskToDelete = false;
        this.spinnerSpecialAcceptance = true;

        if(this.selectedRowSA.PortalStatus__c != 'Draft'){
            this.spinnerSpecialAcceptance = false;
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message:this.label.SACannotBeDeleted, variant: 'error'}), );
        }
        else{
            deleteSpecialAcceptanceRecord({ specialAcceptanceObj : this.selectedRowSA})
            .then(result => {
                this.spinnerSpecialAcceptance = false;
                this.getProgramDetail();
                this.dispatchEvent(new ShowToastEvent({title: 'Success', message: this.label.SADeletedSuccessfully, variant: 'success' }),);
            })
            .catch(error => {
                this.spinnerSpecialAcceptance = false;
                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error'}), );
            });
        }
    }

    handleCloseDeleteModal(event){
        this.isAskToDelete = false;
    }

    handleOnchangeCopyDocument(event){
        this.valCopyDocument = event.currentTarget.checked;
        fireEvent(this.pageRef, 'copyDocumentValue', this.valCopyDocument);
    }

    handleRowSelection(event) {
        this.selectedSA = this.template.querySelector('lightning-datatable').getSelectedRows();

        if(this.selectedSA.length > 0){
            this.disableBindBtn = false;
            this.disableDeactivateBtn = false;
            this.disableReactivateBtn = false;
        }
        else{
            this.disableBindBtn = true;
            this.disableDeactivateBtn = true;
            this.disableReactivateBtn = true;
        }
    }

    handleOnClickBtn(event){
        let btnNameclick = event.currentTarget.name;

        if(btnNameclick == 'Bind'){
            let saNotSubmissionAgreed = false;

            for(let i = 0; i < this.selectedSA.length; i++){
                if(this.selectedSA[i].status != 'Agreed' || this.selectedSA[i].Type__c != 'Submission'){
                    saNotSubmissionAgreed = true;
                }
            }

            if(saNotSubmissionAgreed == true){
                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: 'Bind action can only be applied to SA with submission type and status "agreed".', variant: 'error'}), );
            }
            else{
                this.isAskToBindDeactReact = true;
                this.isBind = true;
                this.isAskToTitle = 'Bind Special Acceptance(s)';
                this.isAskToMsg = 'You are going to bind the selected Special Acceptance(s). Do you want to continue?';
            }         
        }
        else if(btnNameclick == 'Deactivate'){
            this.isAskToBindDeactReact = true;
            this.isDeactivate = true;
            this.isAskToTitle = 'Deactivate Special Acceptance(s)';
            this.isAskToMsg = 'You are going to deactivate the Special Acceptance(s). Do you want to continue?';
        }
        else if(btnNameclick == 'Reactivate'){
            this.isAskToBindDeactReact = true;
            this.isReactivate = true;
            this.isAskToTitle = 'Reactivate Special Acceptance(s)';
            this.isAskToMsg = 'You are going to reactivate the Special Acceptance(s). Do you want to continue?';
        }
    }

    handleAcceptBindDeactReact(event){
        this.isAskToBindDeactReact = false;
        this.spinnerSpecialAcceptance = true;

        if(this.isBind == true){
            this.bindSA();
        }
        else if(this.isDeactivate == true){
            this.deactivateSA();
        }
        else if(this.isReactivate == true){
            this.reactivateSA();
        }
    }

    handleCloseBindDeactReactModal(event){
        this.isAskToBindDeactReact = false;
        this.isBind = false;
        this.isDeactivate = false;
    }

    deactivateSA(){
        let lstSelectedSa = [];

        for(let i = 0; i < this.selectedSA.length; i++){
            lstSelectedSa.push(this.selectedSA[i].Id);
        }

        deactivateSpecialAcceptanceRecord({ lstSpecialAcceptanceId : lstSelectedSa})
        .then(result => {
            this.spinnerSpecialAcceptance = false;
            this.getProgramDetail();
            this.dispatchEvent(new ShowToastEvent({title: 'Success', message: this.label.DeactivateSASuccessMsg, variant: 'success' }),);
        })
        .catch(error => {
            this.spinnerSpecialAcceptance = false;
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error'}), );
        });
    }

    reactivateSA(){
        this.spinnerSpecialAcceptance = false;
        let lstSelectedSa = [];

        for(let i = 0; i < this.selectedSA.length; i++){
            lstSelectedSa.push(this.selectedSA[i].Id);
        }

        reactivateSpecialAcceptanceRecord({ lstSpecialAcceptanceId : lstSelectedSa})
        .then(result => {
            this.spinnerSpecialAcceptance = false;
            this.getProgramDetail();
            this.dispatchEvent(new ShowToastEvent({title: 'Success', message: this.label.ReactivateSASuccessMsg, variant: 'success' }),);
        })
        .catch(error => {
            this.spinnerSpecialAcceptance = false;
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error'}), );
        });
    }

    bindSA(){
        let lstSelectedSa = [];

        for(let i = 0; i < this.selectedSA.length; i++){
            lstSelectedSa.push(this.selectedSA[i]);
        }

        bindSpecialAcceptanceRecords({ lstSelectedSpecialAcceptance : lstSelectedSa, isUserCE : this.isCE})
        .then(result => {
            this.spinnerSpecialAcceptance = false;
            this.getProgramDetail();
            this.dispatchEvent(new ShowToastEvent({title: 'Success', message: this.label.SABoundSuccessfully, variant: 'success' }),);
        })
        .catch(error => {
            this.spinnerSpecialAcceptance = false;
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error'}), );
        });
    }

    reasonChanged(event){
    }

    searchNaceLookUpField(event){
        let currentText = event.target.value;
        let selectRecId = [];
        if(currentText == ''){
            this.selectedNaceText = null;
            this.selectedNaceName = null;
            this.selectedNaceId = null;
        }

        this.loadingText = true;

        getNaceCode({ ObjectName: 'NACECode__c', fieldName: 'NACECode__c', value: currentText, selectedRecId : selectRecId })
        .then(result => {
            this.searchNaceCodeLookupRecords = result;
            this.loadingText = false;

            this.txtNaceLookupClassName =  result.length > 0 ? 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-is-open' : 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
            if(currentText.length > 0 && result.length == 0) {
                this.messageFlag = true;
            }
            else {
                this.messageFlag = false;
            }

            if(this.selectRecordId != null && this.selectRecordId.length > 0) {
                this.iconFlag = false;
                this.clearIconFlag = true;
            }
            else {
                this.iconFlag = true;
                this.clearIconFlag = false;
            }

            this.valOriginalInsuredActAutofac = null;
        })
        .catch(error => {
            this.error = error;
        });
    }

    setSelectedNaceCodeLookupRecord(event) {
        let recId = event.currentTarget.dataset.id;
        let selectName = event.currentTarget.dataset.name;
        let selectedOriginalInsuredAct = event.currentTarget.dataset.label;
        this.txtNaceLookupClassName = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
        this.selectedNaceText = selectName;
        this.selectedNaceName = selectName;
        this.selectedNaceId = recId;
        this.valOriginalInsuredActAutofac = selectedOriginalInsuredAct;
    }
}