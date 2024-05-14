import {LightningElement, track, wire, api} from 'lwc';
import {getPicklistValues, getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import {getObjectInfo} from 'lightning/uiObjectInfoApi';
import PROGRAM_OBJECT from '@salesforce/schema/Program__c';
import UWYEAR_FIELD from '@salesforce/schema/Program__c.UwYear__c';
import {NavigationMixin, CurrentPageReference} from 'lightning/navigation';
import {registerListener, unregisterAllListeners, fireEvent} from 'c/pubSub';
import {loadStyle, loadScript} from 'lightning/platformResourceLoader';
import HideLightningHeader from '@salesforce/resourceUrl/HideLightningHeader';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import Id from '@salesforce/user/Id';

//import field
import NATURE_FIELD from '@salesforce/schema/ContentVersion.Nature__c';
import SPECIAL_ACCEPTANCE_OBJECT from '@salesforce/schema/SpecialAcceptance__c';
import CONTENT_VERSION_OBJECT from '@salesforce/schema/ContentVersion';
import REQUEST_OBJECT from '@salesforce/schema/Request__c';
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
import SA_TYPE_FIELD from '@salesforce/schema/Request__c.SA_Type__c';
import BROKERSTATUS_FIELD from '@salesforce/schema/Request__c.BrokerStatus__c';

export default class Lwc50SAReadOnly extends NavigationMixin(LightningElement) {
    @api saObj;
    @api macroLobFromProgramVal;
    @api selectedSubLobVal;
    @api covCedComOptionVal;
    @api saRecordTypeId;
    @api displayAutoFacForm;
    @api displayPcForm;
    @api displayLifeForm;
    @api saTypeVal;
    @api reasonOptVal;
    @api limitTypeOptVal;
    @api isUgp;
    @track saTypeOpt = [];
    @track brokerStatusOpt = [];
    @track searchNaceCodeLookupRecords = [];
    typeOpt;
    subLobOpt;
    countryOpt;
    currencyOpt;
    axaLeaderOpt;
    catCoverageOpt;
    exposureBaseOpt;
    typeFacPlacementOpt;
    isCededExposureAutofacInLineOpt;
    boundOpt;
    proposedToFacOpt;
    displayNaceCode = false;
    selectedNaceText = null;
    iconName = 'standard:account';
    messageFlag = false;
    loadingText = false;
    selectedNaceName;
    selectedNaceId;
    txtNaceLookupClassName = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';

    @wire(getObjectInfo, { objectApiName: SPECIAL_ACCEPTANCE_OBJECT })
    objectInfo;

    @wire(getObjectInfo, { objectApiName: CONTENT_VERSION_OBJECT })
    objectInfoContentVersion;

    @wire(getObjectInfo, { objectApiName: REQUEST_OBJECT })
    objectInfoRequest

    getUrlParamValue(url, key) {
        return new URL(url).searchParams.get(key);
    }

    @wire(CurrentPageReference) pageRef;

    connectedCallback() {
    }

    @wire(getPicklistValues, { recordTypeId: '$saRecordTypeId', fieldApiName: REASON_FIELD})
    setTypeOfSAPicklistOpt({error, data}) {
        if(data){
            this.reasonOptVal = data.values;
        }
        else{
            this.error = error;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$saRecordTypeId', fieldApiName: LIMITTYPE_FIELD})
    setLimitTypePicklistOpt({error, data}) {
        if(data){
            this.limitTypeOptVal = data.values;
        }
        else{
            this.error = error;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfoRequest.data.defaultRecordTypeId', fieldApiName: SA_TYPE_FIELD})
    setSaTypePicklistOpt({error, data}) {
        if(data){
            this.saTypeOpt = [];

            for(let i = 0; i < data.values.length; i++){
                if(data.values[i].label != 'Leader'){
                    this.saTypeOpt.push({'label' : data.values[i].label, 'value' : data.values[i].value});
                }
            }
        }
        else{
            this.error = error;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfoRequest.data.defaultRecordTypeId', fieldApiName: BROKERSTATUS_FIELD})
    setBrokerStatusPicklistOpt({error, data}) {
        if(data){
            this.brokerStatusOpt = data.values;
        }
        else{
            this.error = error;
        }
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
}