import {LightningElement, track, wire, api} from 'lwc';
import {getPicklistValues } from 'lightning/uiObjectInfoApi';
import {getObjectInfo} from 'lightning/uiObjectInfoApi';
import getTypeOfSARecordTypeId from '@salesforce/apex/LWC47_SpecialAcceptance.getTypeOfSARecordTypeId';
import saveCopySpecialAcceptanceRecord from '@salesforce/apex/LWC48_CopySpecialAcceptance.saveCopySpecialAcceptanceRecord';
import saveRenewSpecialAcceptanceRecord from '@salesforce/apex/LWC48_CopySpecialAcceptance.saveRenewSpecialAcceptanceRecord';
import saveEditSpecialAcceptanceRecord from '@salesforce/apex/LWC48_CopySpecialAcceptance.saveEditSpecialAcceptanceRecord';
import checkIfSAEmailIsFound from '@salesforce/apex/AP_Constant.checkIfSAEmailIsFound';
import loadPlacementTable from '@salesforce/apex/LWC48_CopySpecialAcceptance.loadPlacementTable';
import {NavigationMixin, CurrentPageReference} from 'lightning/navigation';
import {registerListener, unregisterAllListeners, fireEvent} from 'c/pubSub';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import getContentVersionId from '@salesforce/apex/LWC48_CopySpecialAcceptance.getContentVersionId';
import saveDocuments from '@salesforce/apex/LWC48_CopySpecialAcceptance.saveDocuments';
import getSADetail from '@salesforce/apex/LWC48_CopySpecialAcceptance.getSADetail';
import getProgramDetail from '@salesforce/apex/LWC48_CopySpecialAcceptance.getProgramDetail';
import deletePlacementTable from '@salesforce/apex/LWC48_CopySpecialAcceptance.deletePlacementTable';
import getNaceCode from '@salesforce/apex/LWC47_SpecialAcceptance.getNaceCode';
//RRA - 1780 - 19122023
import getProfiles from '@salesforce/apex/LWC14_Documents.getProfiles';

//import field
import NATURE_FIELD from '@salesforce/schema/ContentVersion.Nature__c';import SPECIAL_ACCEPTANCE_OBJECT from '@salesforce/schema/SpecialAcceptance__c';
import CONTENT_VERSION_OBJECT from '@salesforce/schema/ContentVersion';import REQUEST_OBJECT from '@salesforce/schema/Request__c';
import TYPE_FIELD from '@salesforce/schema/SpecialAcceptance__c.Type__c';import EXPOSUREBASED_FIELD from '@salesforce/schema/SpecialAcceptance__c.ExposureBasedOn__c';import SUBLOB_FIELD from '@salesforce/schema/SpecialAcceptance__c.SubLoB__c';
import COUNTRY_FIELD from '@salesforce/schema/SpecialAcceptance__c.Country__c';import REASON_FIELD from '@salesforce/schema/SpecialAcceptance__c.Reason__c';
import CURRENCY_FIELD from '@salesforce/schema/SpecialAcceptance__c.Currency__c';import LIMITTYPE_FIELD from '@salesforce/schema/SpecialAcceptance__c.LimitType__c';
import AXALEADER_FIELD from '@salesforce/schema/SpecialAcceptance__c.AxaLeader__c';import CATCOVERAGE_FIELD from '@salesforce/schema/SpecialAcceptance__c.CatCoverage__c';import TYPEFACPLACEMENT_FIELD from '@salesforce/schema/SpecialAcceptance__c.TypeFacPlacement__c';
import ISCEDEDEXPOSUREAUTOFACINLINE_FIELD from '@salesforce/schema/SpecialAcceptance__c.IsCededExposureAutofacInLine__c';import BOUND_FIELD from '@salesforce/schema/SpecialAcceptance__c.Bound__c';import PROPOSEDTOFAC_FIELD from '@salesforce/schema/SpecialAcceptance__c.ProposedToFac__c';import SA_TYPE_FIELD from '@salesforce/schema/Request__c.SA_Type__c';
import BROKERSTATUS_FIELD from '@salesforce/schema/Request__c.BrokerStatus__c';

//import custom labels
import saErrorMsg from '@salesforce/label/c.saErrorMsg';import OriginalYearNotInRightFormat from '@salesforce/label/c.OriginalYearNotInRightFormat';
import SelectLegalEntityOrNatural from '@salesforce/label/c.SelectLegalEntityOrNatural';import LimitUnlimitedErrMsg from '@salesforce/label/c.LimitUnlimitedErrMsg';
import FloodWindstormEarthquakeTerrorism from '@salesforce/label/c.FloodWindstormEarthquakeTerrorism';import NoFileIsFound from '@salesforce/label/c.NoFileIsFound';import DocumentSavedSuccessMsg from '@salesforce/label/c.DocumentSavedSuccessMsg';import RequiredFieldMissingSA from '@salesforce/label/c.RequiredFieldMissingSA';import SAUpdatedSuccessfully from '@salesforce/label/c.SAUpdatedSuccessfully';import SARenewedSuccessfully from '@salesforce/label/c.SARenewedSuccessfully';import PlacementTableLoadedSuccessfully from '@salesforce/label/c.PlacementTableLoadedSuccessfully';import PlacementTableDeletedSuccessfully from '@salesforce/label/c.PlacementTableDeletedSuccessfully';import EmailNotFound from '@salesforce/label/c.EmailNotFound';import errorMsg from '@salesforce/label/c.errorMsg';import constantPremiumValue from '@salesforce/label/c.constantPremiumValue';import powNetPremiumValue from '@salesforce/label/c.powNetPremiumValue';import ExtensionNotAuthorizedActorCEAXAXL from '@salesforce/label/c.ExtensionNotAuthorizedActorCEAXAXL';import ExtensionNotAuthorizedAGRE_ActorBasicSalesforceAccess from '@salesforce/label/c.ExtensionNotAuthorizedAGRE_ActorBasicSalesforceAccess';import ExtensionNotAuthorizedAGRE_ActorBasicSFPlatformAccess from '@salesforce/label/c.ExtensionNotAuthorizedAGRE_ActorBasicSFPlatformAccess';import ExtensionNotAuthorizedAGRE_Actor_C_E from '@salesforce/label/c.ExtensionNotAuthorizedAGRE_Actor_C_E';import ExtensionNotAuthorizedAGRECommunityExternalUser from '@salesforce/label/c.ExtensionNotAuthorizedAGRECommunityExternalUser';import ExtensionNotAuthorizedAGRECommunityInternalUser from '@salesforce/label/c.ExtensionNotAuthorizedAGRECommunityInternalUser';import ExtensionNotAuthorizedAGRESystemAdmin from '@salesforce/label/c.ExtensionNotAuthorizedAGRESystemAdmin';import ExtensionNotAuthorizedSystemAdministrator from '@salesforce/label/c.ExtensionNotAuthorizedSystemAdministrator';

export default class Lwc48CopySpecialAcceptance extends NavigationMixin(LightningElement) {
    label = {
        saErrorMsg,OriginalYearNotInRightFormat,SelectLegalEntityOrNatural,LimitUnlimitedErrMsg, FloodWindstormEarthquakeTerrorism,NoFileIsFound,DocumentSavedSuccessMsg,RequiredFieldMissingSA,SAUpdatedSuccessfully,SARenewedSuccessfully,PlacementTableLoadedSuccessfully,PlacementTableDeletedSuccessfully,EmailNotFound,errorMsg,constantPremiumValue,powNetPremiumValue,ExtensionNotAuthorizedActorCEAXAXL,
        ExtensionNotAuthorizedAGRE_ActorBasicSalesforceAccess, ExtensionNotAuthorizedAGRE_ActorBasicSFPlatformAccess,ExtensionNotAuthorizedAGRE_Actor_C_E,ExtensionNotAuthorizedAGRECommunityExternalUser, ExtensionNotAuthorizedAGRECommunityInternalUser, ExtensionNotAuthorizedAGRESystemAdmin,ExtensionNotAuthorizedSystemAdministrator
    }
    
    @api valLimit;@api acceptedFormats;toolTipAcceptedFormats;@api valUnlimitChk; @api valExposureBasedOn; @api selectedProgram;@api displayAutoFacFormVal = false;@api displayPCFormVal = false; @api displayLifeFormVal = false;
    @api isModalCopy = false;@api isModalRenew = false;@api isModalEdit = false;@api isCELoadSEReq = false; @api reasonOptVal;@api limitTypeOptVal;
    @api selectedSpecialAcceptance; @api covCedComOption; @api typeOfSARecordTypeId;@api programNatureOptionsVal;@api natureProgramVal;@api renewedProgramId; @api isUserCe = false;classeOverride;
    @track lstDocuments = [];@track lstSelectedDocument = [];@track lstSelectedDeleteDocumentId = []; @track selectedSaRequests = []; @track lstPublicDoc = []; @track saTypeOpt = []; @track brokerStatusOpt = []; @track lstBRPortalDocuments = [];@track searchNaceCodeLookupRecords = [];@track specialAcceptanceObj = {};
    isTotalAxaShareInvalid = false ; isAskToLoadPlacement = false;
    askToLoadPlacementMsg = "You are about to Load the Placement Table with a (take the type of the SA) type of Special Acceptance. It will not be possible to modify the value after the Placement Table is generated";
    showLoadPlacementTableBtn = false;disableLoadPlacementTable = false;
    dataSaRequest;titleCountSARequest = 'Special Acceptance Request (0)';
    spinnerSARequest = false;valueUWYear;valuePrincipalCedComp;selectedPool;copyDoc = true;progIdOfSelectedSA; selectedSAId;actionBtnName;disableDeleteBtn = true;
    isOpenDocModal = false;documentNames;uploadedDoc;displayDoc = false;titleCountDocument = 'My Documents (0)';typeOpt;subLobOpt;countryOpt;currencyOpt;axaLeaderOpt;
    catCoverageOpt;exposureBaseOpt;typeFacPlacementOpt;isCededExposureAutofacInLineOpt;boundOpt;proposedToFacOpt;selectedSubLOB;
    macroLobFromProgram;disableDeductibleAmount = false;disableLimitUnlimited = false;disableLimit = false;
    // RRA - 1163 - 22/06/2022
    tonHasErrorUnlimited = true;
    tonHasError = true;
    errors;
    disableDeductiblePercentage = false;
    spinnerSaveSpecialAcceptance = false;
    errorclass;
    referenceVal;
    isSubmit = false;
    btnNameclick;
    specialAcceptanceRecordToSave;
    submitMsg = 'You are going to submit the Special Acceptance.Submitting your Special Acceptance to AXA SA will prevent you to delete or modify it. Do you want to continue ?'; //RRA - ticket 1452 - 14022023
    disableAllFields = false;
    titleName;
    selectedProgramName;
    selectedProgramNature;
    isModalCopyRenew = false;
    saStatusCancelled = false;
    isSendModalOpen = false;
    titlePopUp;
    disableDateOfRequest = false;
    saType = null;
    isDelete = false;
    showDeleteBtn = false;
    informCedComAgreed = false;
    informCedComRefused = false;
    loadSAReadOnlyUGP = false;
    displayBRPortalDoc = false;
    titleCountBRPortalDocument = 'Broker/Reinsurer Documents (0)';
    isBoundDisable = true;
    isDeclaration = false;
    displayNaceCode = false;
    selectedNaceText = null;
    iconName = 'utility:display_text';
    messageFlag = false;
    loadingText = false;
    selectedNaceName;
    selectedNaceId;
    valOriginalInsuredActAutofac;
    txtNaceLookupClassName = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
    mapRateByCurrencyLabel = new Map();
    mapCurrency = new Map();
    
     //RRA - ticket 1780 - 19122023
     formatsFileAccepted(){
        getProfiles()
        .then(resultProfile => {
            if (resultProfile == 'Admin'){this.acceptedFormats = this.label.ExtensionNotAuthorizedSystemAdministrator;
            }else if (resultProfile == 'Admin_AGRE'){this.acceptedFormats = this.label.ExtensionNotAuthorizedAGRESystemAdmin;
            }else if (resultProfile == 'Actor_CE'){this.acceptedFormats = this.label.ExtensionNotAuthorizedAGRE_Actor_C_E;
            }else if (resultProfile == 'Agre_AXAXL'){this.acceptedFormats = this.label.ExtensionNotAuthorizedActorCEAXAXL;
            }else if (resultProfile == 'AgreActor_BasicSalesforce'){this.acceptedFormats = this.label.ExtensionNotAuthorizedAGRE_ActorBasicSalesforceAccess;
            }else if (resultProfile == 'AgreActor_BasicSFPlatform'){this.acceptedFormats = this.label.ExtensionNotAuthorizedAGRE_ActorBasicSFPlatformAccess	;
            }else if (resultProfile == 'Agre_CommunityExternal'){this.acceptedFormats = this.label.ExtensionNotAuthorizedAGRECommunityExternalUser;
            }else if (resultProfile == 'Agre_CommunityInternal'){this.acceptedFormats = this.label.ExtensionNotAuthorizedAGRECommunityInternalUser;
            }else if (resultProfile == 'SF_PlatformReadOnly'){this.acceptedFormats = 'No extension files';
            }
            let lstAcceptedFormats = this.acceptedFormats.replace(',', ',  ');
            this.toolTipAcceptedFormats = 'Accepted Formats  : ' + lstAcceptedFormats ;
        })
        .catch(error => {
            this.error = error;
        });
    }

    @wire(getObjectInfo, { objectApiName: SPECIAL_ACCEPTANCE_OBJECT })objectInfo;
    @wire(getObjectInfo, { objectApiName: CONTENT_VERSION_OBJECT })objectInfoContentVersion;
    @wire(getObjectInfo, { objectApiName: REQUEST_OBJECT })objectInfoRequest
    getUrlParamValue(url, key) {return new URL(url).searchParams.get(key);}
    @wire(CurrentPageReference) pageRef;
    connectedCallback() {
        let currentUrl = this.pageRef.state;
        let nameUrl = null;
        this.formatsFileAccepted();

        if(this.pageRef.attributes.apiName != null && this.pageRef.attributes.apiName != undefined){ nameUrl = this.pageRef.attributes.apiName;}
        else if(this.pageRef.attributes.name != null && this.pageRef.attributes.name != undefined){ nameUrl = this.pageRef.attributes.name;}

        if(nameUrl == 'SADetail__c'){
            this.actionBtnName = 'Edit';
            this.isModalEdit = true;
            this.titleName = 'Edit Special Acceptance';
            let param = 's__id';
            let paramValue = null;
            if(currentUrl != undefined && currentUrl != null){paramValue = currentUrl[param];}

            if(paramValue != null){
                let parameters = paramValue.split("-");
                if(parameters[0] != undefined){
                    this.selectedSpecialAcceptance = parameters[0];
                }
            }
        }
        else if(nameUrl == 'LoadSARequest'){let param = 's__id';
            let paramValue = null;
            if(currentUrl != undefined && currentUrl != null){paramValue = currentUrl[param];}

            this.isCELoadSEReq = true; this.isUserCe = true;this.titleName = 'Special Acceptance';this.displayDoc = true;this.displayBRPortalDoc = true;
            if(paramValue != null){
                let parameters = paramValue.split("-");
                if(parameters[0] != undefined){this.selectedSpecialAcceptance = parameters[0];}
                if(parameters[1] != undefined){this.valueUwYear = parameters[1];}
                if(parameters[2] != undefined){  this.valuePrincipalCedComp = parameters[2];}
                if(parameters[3] != undefined){this.selectedProgram = parameters[3];}
                if(parameters[4] != undefined){this.selectedPool = parameters[4];}
                if(parameters[5] != undefined){
                    if(parameters[5] == 'ugp'){
                        this.disableAllFields = true;
                        this.loadSAReadOnlyUGP = true;
                    }
                }
            }
        }

        if(this.isModalCopy == true){this.actionBtnName = 'Copy';this.titleName = 'Copy Special Acceptance';}
        else if(this.isModalRenew == true){this.actionBtnName = 'Renew';this.titleName = 'Renew Special Acceptance';}
        if(this.isModalCopy == true || this.isModalRenew == true){ this.isModalCopyRenew = true; }
         if(this.isModalRenew == true || this.isModalEdit == true){this.displayDoc = true;}
        registerListener('selectedProgramToCopy', this.getSelectedProgram, this);registerListener('copyDocumentValue', this.getCopyDocumentVal, this);registerListener('closeSendSaReqModal', this.closeSendSaReqModal, this);
        this.getSADetail();
    }

    getSelectedProgram(val){
        this.selectedProgram = val;
        this.getProgramDetail(this.selectedProgram);
    }

    getCopyDocumentVal(val){
        this.copyDoc = val;
    }

    closeSendSaReqModal(val){
        this.isSendModalOpen = false;
        this.getSADetail();
    }

    @wire(getPicklistValues, { recordTypeId: '$typeOfSARecordTypeId', fieldApiName: REASON_FIELD})
    setTypeOfSAPicklistOpt({error, data}) {
        if(data){
            this.reasonOptVal = data.values;
        }
        else{
            this.error = error;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$typeOfSARecordTypeId', fieldApiName: LIMITTYPE_FIELD})
    setLimitTypePicklistOpt({error, data}) {
        if(data){this.limitTypeOptVal = data.values;}
        else{this.error = error;}
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfoRequest.data.defaultRecordTypeId', fieldApiName: SA_TYPE_FIELD})
    setSaTypePicklistOpt({error, data}) {
        if(data){
            this.saTypeOpt = [];
            for(let i = 0; i < data.values.length; i++){
                if(data.values[i].label != 'Leader'){this.saTypeOpt.push({'label' : data.values[i].label, 'value' : data.values[i].value});}
            }
        }
        else{
            this.error = error;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfoRequest.data.defaultRecordTypeId', fieldApiName: BROKERSTATUS_FIELD})
    setBrokerStatusPicklistOpt({error, data}) {
        if(data){ this.brokerStatusOpt = data.values;}
        else{ this.error = error;}
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfoContentVersion.data.defaultRecordTypeId', fieldApiName: NATURE_FIELD})
    setNaturePicklistOpt({error, data}) {
        if(data){this.natureOpt = data.values;}
        else{this.error = error;}
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: PROPOSEDTOFAC_FIELD})
    setProposedToFacPicklistOpt({error, data}) {
        if(data){this.proposedToFacOpt = data.values;}
        else{ this.error = error;}
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: BOUND_FIELD})
    setBoundPicklistOpt({error, data}) {
        if(data){this.boundOpt = data.values;}
        else{this.error = error;}
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: TYPEFACPLACEMENT_FIELD})
    setTypeFacPlacementPicklistOpt({error, data}) {
        if(data){this.typeFacPlacementOpt = data.values;}
        else{this.error = error;}
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: ISCEDEDEXPOSUREAUTOFACINLINE_FIELD})
    setIsCededExposureAutofacInLinePicklistOpt({error, data}) {
        if(data){this.isCededExposureAutofacInLineOpt = data.values;}
        else{this.error = error;}
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: EXPOSUREBASED_FIELD})
    setExposureBasePicklistOpt({error, data}) {
        if(data){this.exposureBaseOpt = data.values;}
        else{this.error = error;}
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: TYPE_FIELD})
    setTypePicklistOpt({error, data}) {
        if(data){this.typeOpt = data.values;}
        else{this.error = error;}
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: COUNTRY_FIELD})
    setCountryPicklistOpt({error, data}) {
        if(data){this.countryOpt = data.values;}
        else{this.error = error;}
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
                sortedCurList = unsortedCurList.sort((a,b) => (a.label > b.label) ? 1 : ((b.label > a.label) ? -1 : 0));
                let eurObj = sortedCurList.splice(sortedCurList.findIndex(ele => ele.label === 'EUR'), 1)[0];
                sortedCurList.splice(0, 0, eurObj);
                let usdObj = sortedCurList.splice(sortedCurList.findIndex(ele => ele.label === 'USD'), 1)[0];
                sortedCurList.splice(1, 0, usdObj);
                let gbpObj = sortedCurList.splice(sortedCurList.findIndex(ele => ele.label === 'GBP'), 1)[0];
                sortedCurList.splice(2, 0, gbpObj);
                this.currencyOpt = sortedCurList;
            }
        }
        else{ this.error = error;}
    }
    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: AXALEADER_FIELD})
    setAXALeaderPicklistOpt({error, data}) {
        if(data){this.axaLeaderOpt = data.values;}
        else{ this.error = error;}
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: CATCOVERAGE_FIELD})
    setCatCoveragePicklistOpt({error, data}) {
        if(data){ this.catCoverageOpt = data.values;
            if(this.valCatCoverage == undefined || this.valCatCoverage == null){
                this.valCatCoverage = '2';
            }
        }
        else{this.error = error;}
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: SUBLOB_FIELD})
    setSubLOBPicklistValues({error, data}) {
        if(data) {this.subLobOpt = data.values;}
        else if(error) {this.error = JSON.stringify(error);}
    }

    getSADetail(){
        getSADetail({specialAcceptanceId : this.selectedSpecialAcceptance, isCE : this.isUserCe, isRenew : this.isModalRenew}) //1996
        .then(result => {         
            let profileName = result.userProfile;
            if(profileName == 'System Administrator' || profileName == 'AGRE_System Admin'){this.showDeleteBtn = true}          
            let saObj = { ...result.lstSpecialAcceptance[0] };
            this.selectedNaceText = saObj.NaceCode__c;
            this.valOriginalInsuredActAutofac = saObj.OriginalInsuredActivityAutofac__c;

            // RRA - ticket 1453 - 13032023
            if(saObj.Type__c == '2' && (saObj.InternalStatus__c == 'Agreed' || saObj.PortalStatus__c == 'Agreed')){this.isBoundDisable = false;}
            else if(saObj.IsInformCedCom__c == true && saObj.Type__c == '2' && (saObj.InternalStatus__c == 'Agreed' || saObj.PortalStatus__c == 'Agreed')){ this.isBoundDisable = false;}
            else if(saObj.IsInformCedCom__c == true && saObj.Type__c == '2' && (saObj.InternalStatus__c == 'Refused' || saObj.PortalStatus__c == 'Refused')){othis.isBoundDisable = true;}
            else if(saObj.IsInformCedCom__c == true && saObj.Type__c == '1'){this.isBoundDisable = true;}
            else{this.isBoundDisable = true;}
            if(saObj.Type__c == '1'){this.isDeclaration = true;}
            else if(saObj.Type__c == '2'){this.isDeclaration = false;}
            if(saObj.SentAgreFromSpecialAcceptance__c != null && saObj.SentAgreFromSpecialAcceptance__c != undefined){this.disableDateOfRequest = true;}
            if(this.isModalEdit == true && saObj.PortalStatus__c != 'Draft'){ this.disableAllFields = true; }
            else if(this.loadSAReadOnlyUGP == false){this.disableAllFields = false;}
            this.selectedSubLOB = saObj.SubLoB__c;
            if(this.isModalRenew == true){
                if(result.renewedProgram != null){
                    this.valuePrincipalCedComp = result.renewedProgram.PrincipalCedingCompany__c;this.valueUWYear = result.renewedProgram.UwYear__c;this.renewedProgramId = result.renewedProgram.Id;
                    //RRA - ticket 1537 - 31072023
                    saObj.SpaInceptionDate__c = (saObj.SpaInceptionDate__c != null || saObj.SpaInceptionDate__c != undefined) ? saObj.SpaInceptionDate__c : result.renewedProgram.InceptionDate__c;
                    saObj.SpaExpirationDate__c = (saObj.SpaExpirationDate__c != null || saObj.SpaExpirationDate__c != undefined) ? saObj.SpaExpirationDate__c : result.renewedProgram.Expirydate__c;
                }
                this.progIdOfSelectedSA = saObj.Program__c;
            }
            else{
                if(saObj.Program__r != undefined){
                    this.valuePrincipalCedComp = saObj.Program__r.PrincipalCedingCompany__c;
                    this.valueUWYear = saObj.Program__r.UwYear__c;
                    this.selectedProgramName = saObj.Program__r.Name;
                }
                this.progIdOfSelectedSA = saObj.Program__c;
            }

            this.selectedSAId = saObj.Id;
            this.lstDocuments = result.lstContentVersions;
            this.lstBRPortalDocuments = result.lstContentVersionsBRPortal;
            for(let i = 0; i < this.lstBRPortalDocuments.length; i++){
                    this.lstBRPortalDocuments[i]['Name'] = this.lstBRPortalDocuments[i].Title;
                    this.lstBRPortalDocuments[i]['Id'] = this.lstBRPortalDocuments[i].Id;
                    this.lstBRPortalDocuments[i]['Viewable'] = true;
                    if(this.isUserCe == true || this.loadSAReadOnlyUGP == true){this.lstBRPortalDocuments[i]['DocumentUrl'] = "/sfc/servlet.shepherd/document/download/"+ this.lstBRPortalDocuments[i].ContentDocumentId+"?operationContext=S1";}
                    else{this.lstBRPortalDocuments[i]['DocumentUrl'] = "../sfc/servlet.shepherd/version/download/"+ this.lstBRPortalDocuments[i].Id+"?operationContext=S1";}
                    this.lstBRPortalDocuments[i]['SpecialAcceptance__c'] = null;
            }

            for(let i = 0; i < this.lstDocuments.length; i++){
                    this.lstDocuments[i]['Name'] = this.lstDocuments[i].Title;
                    this.lstDocuments[i]['Checked'] = false;
                    this.lstDocuments[i]['Id'] = this.lstDocuments[i].Id;
                    this.lstDocuments[i]['Viewable'] = true;
                    this.lstDocuments[i]['NewRenewUpload'] = false;
                    if(this.isUserCe == true || this.loadSAReadOnlyUGP == true){this.lstDocuments[i]['DocumentUrl'] = "/sfc/servlet.shepherd/document/download/"+ this.lstDocuments[i].ContentDocumentId+"?operationContext=S1";}
                    else{this.lstDocuments[i]['DocumentUrl'] = "../sfc/servlet.shepherd/version/download/"+ this.lstDocuments[i].Id+"?operationContext=S1";}
                    this.lstDocuments[i]['SpecialAcceptance__c'] = null;
            }
            if(this.template.querySelectorAll('[data-id="reqAllCheckbox"]')[0] !== undefined)
                this.template.querySelectorAll('[data-id="reqAllCheckbox"]')[0].checked = false ; // MRA W-1123 : 19/07/2022 + bug load placment table
            this.titleCountDocument = 'My Documents (' + this.lstDocuments.length + ')';
            this.titleCountBRPortalDocument = 'Broker/Reinsurer Documents (' + this.lstBRPortalDocuments.length + ')';
            let reasonStr = saObj.Reason__c;

            if(reasonStr != undefined){saObj['Reason__c'] = reasonStr.split(';');}
            if(saObj.LimitType__c == '1' || saObj.LimitUnlimited__c == true){this.disableLimit = true;}
            if(saObj.Limit__c != null && saObj.Limit__c != undefined){ this.disableLimitUnlimited = true;}
            if(saObj.DeductibleAmount__c != null && saObj.DeductibleAmount__c != undefined){this.disableDeductiblePercentage = true; }
            if(saObj.NaturalPerson__c == true){saObj['disableSpecialAcceptanceName'] = true;}
            else{ saObj['disableSpecialAcceptanceName'] = false;}
            if(saObj.DeductiblePercentage__c != null && saObj.DeductiblePercentage__c != undefined){this.disableDeductibleAmount = true;}
            if(this.isModalCopy == true && this.isUserCe == true){saObj['Type__c'] = null;}

            if(this.isModalCopyRenew == true){saObj['BindRemainingDays__c'] = null;saObj['AdditionalPremium__c'] = null;saObj['Rationale__c'] = null;saObj['ProposedToFac__c'] = null;}
            this.specialAcceptanceObj = saObj;
            this.mapRateByCurrencyLabel = result.mapRateByCurrencyLabel;
            
            //RRA - ticket 1996 - 08042024
            if(this.mapCurrency.has(saObj['Currency__c'])){
                let currencyLabel = this.mapCurrency.get( saObj['Currency__c']);
                if(this.mapRateByCurrencyLabel[currencyLabel] != undefined){saObj.RateExchange__c = this.mapRateByCurrencyLabel[currencyLabel];}
                saObj['TotalInsuredValueEuro__c'] = parseFloat(saObj.TotalInsuredValue__c) / parseFloat(saObj.RateExchange__c);saObj['LimitEuro__c'] = parseFloat(saObj.Limit__c) / parseFloat(saObj.RateExchange__c);saObj['TopLocationPdValues100Euro__c'] = parseFloat(saObj.TopLocationPdValues100__c) / parseFloat(saObj.RateExchange__c);
                saObj['TopLocationBiValues100Euro__c'] = parseFloat(saObj.TopLocationBiValues100__c) / parseFloat(saObj.RateExchange__c);saObj['MaximumPossibleLossMplEuro__c'] = parseFloat(saObj.MaximumPossibleLossMpl__c) / parseFloat(saObj.RateExchange__c);
                saObj['LossLimit100Euro__c'] = parseFloat(saObj.LossLimit100__c) / parseFloat(saObj.RateExchange__c);saObj['ExposureAmount100Euro__c'] = parseFloat(saObj.ExposureAmount100__c) / parseFloat(saObj.RateExchange__c);
                saObj['CededExposureTreatyEuro__c'] = parseFloat(saObj.CededExposureTreaty__c) / parseFloat(saObj.RateExchange__c);saObj['InXsOf__c'] = saObj.CededExposureTreatyEuro__c;
                saObj['CededExposureAutofacEuro__c'] = parseFloat(saObj.CededExposureAutofac__c) / parseFloat(saObj.RateExchange__c);saObj['FacLayer__c'] = saObj.CededExposureAutofacEuro__c;
                saObj['CededExposureInternalFacultativeEuro__c'] = parseFloat(saObj.CededExposureInternalFacultative__c) / parseFloat(saObj.RateExchange__c);saObj['CededExposureExternalFacultativeEuro__c'] = parseFloat(saObj.CededExposureExternalFacultative__c) / parseFloat(saObj.RateExchange__c);
                saObj['DeductibleAmountEuro__c'] = parseFloat(saObj.DeductibleAmount__c) / parseFloat(saObj.RateExchange__c);saObj['OriginalPolicyPremiumEuro__c'] = parseFloat(saObj.OriginalPolicyPremium__c) / parseFloat(saObj.RateExchange__c);
                saObj['OriginalPremium100Euro__c'] = parseFloat(saObj.OriginalPremium100__c) / parseFloat(saObj.RateExchange__c);saObj['TotalSumRiskEuro__c'] = parseFloat(saObj.TotalSumRisk__c) / parseFloat(saObj.RateExchange__c);
                saObj['AverageSumRisk__c'] = parseFloat(saObj.TotalSumRisk__c) / parseFloat(saObj.NumberHeads__c);saObj['AverageSumRiskEuro__c'] = saObj.AverageSumRisk__c / parseFloat(saObj.RateExchange__c);saObj['TotalAxaShareEuro__c'] = parseFloat(saObj.TotalAxaShare__c) / parseFloat(saObj.RateExchange__c);
                let layer = parseInt(this.label.constantPremiumValue)*((Math.pow((this.searchMinimum(saObj.CededExposureAutofacEuro__c+saObj.CededExposureTreatyEuro__c,saObj.TotalAxaShareEuro__c)/saObj.TotalAxaShareEuro__c)*100,(parseFloat(this.label.powNetPremiumValue))) - (Math.pow((this.searchMinimum(saObj.CededExposureTreatyEuro__c,saObj.TotalAxaShareEuro__c)/saObj.TotalAxaShareEuro__c)*100,(parseFloat(this.label.powNetPremiumValue)))) ));saObj['NetPremiumLayerEuro__c'] = parseFloat(saObj.OriginalPremium100Euro__c*(1-(1-(layer/100)))*(1-(saObj.AutofacCommission__c/100))) ;
                if(this.displayAutoFacFormVal == true){saObj['AutofacShare__c'] = (parseFloat(saObj.CededExposureAutofacEuro__c) / parseFloat(saObj.TotalAxaShareEuro__c)) * 100;}
                saObj['TotalExposureAxaShareEuro__c'] = parseFloat(saObj.TotalExposureAxaShare__c) / parseFloat(saObj.RateExchange__c);saObj['NetCededPremiumAutofac__c'] = parseFloat(saObj.OriginalPremium100__c) * (parseFloat(saObj.AxaShare__c) / 100) * (parseFloat(saObj.AutofacShare__c) / 100) * (1 - (parseFloat(saObj.AutofacCommission__c) / 100));saObj['NetCededPremiumAutofacEuro__c'] = parseFloat(saObj.NetCededPremiumAutofac__c) / parseFloat(saObj.RateExchange__c);saObj['TreatyExposureEuro__c'] = parseFloat(saObj.TreatyExposure__c) / parseFloat(saObj.RateExchange__c);
                saObj.TotalInsuredValue__c =  parseFloat(saObj.TotalInsuredValue__c);
            }
            this.getProgramDetail(saObj.Program__c);
            if(this.isCELoadSEReq == true){
                if(saObj.Active__c == 'Cancelled'){this.saStatusCancelled = true;}
                else{this.saStatusCancelled = false;}
                let lstSaRequest = result.lstSARequest;
                let checkboxes = this.template.querySelectorAll('[data-id="reqCheckbox"]');
                for(let i = 0; i < checkboxes.length; i++) {checkboxes[i].checked = false;}

                lstSaRequest = lstSaRequest.map(row => {
                    let riskPoolName;let isLead = false;let isPlacement = false;
                    let isRoleDisable = false;let isRoleBrokerStatusDisable = false;let respondOnBehalfLink; let isPool = false;let isBroker = false;let displayRespondOnBehalfLink = false;let poolName;let brokerName; let reinsurerName;let originalReqStatus;
                    originalReqStatus = row.SA_Request_Status__c;

                    if(row.SA_Request_Status__c == 'Sent' && this.specialAcceptanceObj.Type__c == '2'){ displayRespondOnBehalfLink = true;}
                    if(row.SA_Request_Status__c != 'Setup'){isRoleBrokerStatusDisable = true;}
                    if(row.Broker__c != undefined){isBroker = true;}
                    if(row.Pool__c != undefined){
                        riskPoolName = row.Pool__r.Name;isPool = true;poolName = row.Pool__r.Name;
                    }
                    else if(row.RiskCarrier__c != undefined){riskPoolName = row.RiskCarrier__r.Name;}

                    if(row.SA_Type__c != undefined && row.SA_Type__c != null){
                        if(row.SA_Type__c == 'Leader'){isLead = true;}
                        else{ isPlacement = true;}
                    }
                    if(row.TECH_ReinsurerName__c != undefined && row.TECH_ReinsurerName__c != null){
                        respondOnBehalfLink = '../n/SARespondOnBehalf?s__id='+this.selectedSpecialAcceptance+'-'+this.valueUwYear+'-'+this.valuePrincipalCedComp+'-'+this.selectedProgram+'-'+row.Broker__c+'-'+row.Reinsurer__c+'-undefined-undefined-undefined-'+row.Id;
                    }
                    else if(row.Pool__c != undefined && row.Pool__c != null){
                        respondOnBehalfLink = '../n/SARespondOnBehalf?s__id='+this.selectedSpecialAcceptance+'-'+this.valueUwYear+'-'+this.valuePrincipalCedComp+'-'+this.selectedProgram+'-'+row.Broker__c+'-'+row.Reinsurer__c+'-'+row.Pool__c+'-undefined-undefined-'+row.Id;
                    }
                    if(row.TECH_BrokerName__c == undefined || row.TECH_BrokerName__c == null){brokerName = '';}
                    else{brokerName = row.TECH_BrokerName__c;}
                    if(row.TECH_ReinsurerName__c == undefined || row.TECH_ReinsurerName__c == null){ reinsurerName = '';}
                    else{reinsurerName = row.TECH_ReinsurerName__c;}
                    return {...row , riskPoolName, isLead, isPlacement, isRoleDisable, respondOnBehalfLink, isPool, displayRespondOnBehalfLink, poolName, brokerName, reinsurerName, isRoleBrokerStatusDisable, isBroker, originalReqStatus}
                });

                this.dataSaRequest = this.sortData(lstSaRequest, 'brokerName','reinsurerName', 'asc');
                this.titleCountSARequest = 'Special Acceptance Requests (' + this.dataSaRequest.length + ')';

                if(this.dataSaRequest != undefined && this.dataSaRequest.length > 0){this.showLoadPlacementTableBtn = false;}
                else{this.showLoadPlacementTableBtn = true;}

                if(result.lstClosedSigningReq.length > 0){this.disableLoadPlacementTable = false;}
                else{ this.disableLoadPlacementTable = true;}
            }
        })
        .catch(error => {
            this.dispatchEvent(new ShowToastEvent({title: 'Error 11', message: error.message, variant: 'error'}), );
        });
    }

    getProgramDetail(progId){
        getProgramDetail({programId : progId, isCE : this.isUserCe})
        .then(result => {
            let programObj = { ...result.lstProgram[0] };
            this.macroLobFromProgram = programObj.Macro_L_O_B__c;
            let saObj = this.specialAcceptanceObj;
            this.valLimit =  saObj['Limit__c'];
            this.valUnlimitChk =  saObj['LimitUnlimited__c'];
            this.valExposureBasedOn =  saObj['ExposureBasedOn__c'];
            if(this.isModalCopy == true){
                let inceptionDate = new Date(programObj.InceptionDate__c+'T00:00');
                let inceptionMonth;
                if((inceptionDate.getMonth() + 1) <= 9){
                    inceptionMonth = '0' + (inceptionDate.getMonth() + 1);
                }
                else{inceptionMonth = inceptionDate.getMonth() + 1;}
                this.referenceVal = inceptionDate.getFullYear() + '-' + inceptionMonth + '-' + result.lastRefIndex;
                saObj['Reference__c'] = this.referenceVal;
                if(saObj.NaturalPerson__c == true){saObj['SpecialAcceptanceName__c'] = saObj['Reference__c'];}
            }
            else if(this.isModalRenew == true){
                let renewedProgramObj = { ...result.lstRenewedProgram[0] };
                let inceptionDate = new Date(renewedProgramObj.InceptionDate__c+'T00:00');
                let inceptionMonth;

                if((inceptionDate.getMonth() + 1) <= 9){inceptionMonth = '0' + (inceptionDate.getMonth() + 1);}
                else{ inceptionMonth = inceptionDate.getMonth() + 1;}
                let referenceSelectedSA = saObj['Reference__c'];
                let lastRefIndexSelectedSAToRenew;

                if(referenceSelectedSA != null && referenceSelectedSA != undefined){
                    let params = referenceSelectedSA.split('-');
                    if(params[2] != undefined){
                        lastRefIndexSelectedSAToRenew = params[2];
                        this.referenceVal = inceptionDate.getFullYear() + '-' + inceptionMonth + '-' + lastRefIndexSelectedSAToRenew;
                        saObj['Reference__c'] = this.referenceVal;
                    }
                }
                if(saObj.NaturalPerson__c == true){saObj['SpecialAcceptanceName__c'] = saObj['Reference__c'];}
            }
            if(saObj.TypeFacPlacement__c == 'QS'){
                saObj['displayAutofacQS'] = true;saObj['displayAutofacXS'] = false;
            }
            else if(saObj.TypeFacPlacement__c == 'XS'){
                saObj['displayAutofacQS'] = false;saObj['displayAutofacXS'] = true;
            }
            else{
                saObj['displayAutofacQS'] = false;saObj['displayAutofacXS'] = false;
            }
            this.specialAcceptanceObj = saObj;
            this.saType = null;

            // If the Nature of the program = P&C & PCC =! AXA FAC IARD 🡪 P&C form
            // If the Nature of the program = Life & PCC =! AXA FAC IARD  🡪 Life form
            // If the PCC == AXA FAC IARD 🡪 Auto FAC form
            if(programObj.PrincipalCedingCompany__r != undefined && programObj.PrincipalCedingCompany__r.Name == 'AXA FAC IARD /FR (P)'){
                this.displayAutoFacFormVal = true;
                this.saType = 'Autofac';
            }
            else if(programObj.Nature__c == 'P&C'){
                this.displayPCFormVal = true;
                this.saType = 'PC';
            }
            else if(programObj.Nature__c == 'Life'){
                this.displayLifeFormVal = true;
                this.saType = 'Life';
            }
            //RRA - 1191 - 03/08/22 - Init value on Edit SA
                if(this.displayAutoFacFormVal || this.displayPCFormVal){
                    //** FORMULAR AUTOFAC */
                    //**********************/
                    if(saObj['ExposureBasedOn__c'] == 'Sums Insured'){
                        //SI
                        this.disableLimit = true; //RRA - 1191 (ref 1163) - 29/07/2022
                        this.disableLimitUnlimited = true; //RRA - 1191 (ref 1163) - 29/07/2022
                        this.tonHasErrorUnlimited = false;// RRA - 1240- 10/08/2022
                        this.template.querySelector('[data-id="limitUnlimitedVal"]').checked = false; //RRA - 1191 - 03/08/22 
                        this.tonHasError= false;
                        saObj['Limit__c'] = null;
                        saObj['LimitEuro__c'] = null;
                        saObj['LimitUnlimited__c'] = false;
                    }
                    else {
                            if (saObj['ExposureBasedOn__c'] !==undefined){
                                if ((saObj['Limit__c'] == null || saObj['Limit__c'] == undefined || saObj['Limit__c'] == 'undefined') && saObj['LimitUnlimited__c'] == false && saObj['ExposureBasedOn__c'] != 'Sums Insured'){//MRA W-1240 22/08/2022
                                    this.disableLimit = false;// RRA - 1240 - 10/08/2022
                                    this.disableLimitUnlimited = false;// RRA - 1240 - 10/08/2022
                                    this.tonHasErrorUnlimited = true;// RRA - 1240- 10/08/2022
                                    this.tonHasError= true;// RRA - 1240- 10/08/2022
                                    this.template.querySelector('[data-id="limitUnlimitedVal"]').checked = saObj['LimitUnlimited__c']; //RRA - 1240- 16/08/2022
                                }else if ((saObj['Limit__c'] == null || saObj['Limit__c'] == undefined || saObj['Limit__c'] == 'undefined') && saObj['LimitUnlimited__c'] == true){
                                    this.disableLimit = true;// RRA - 1240 - 10/08/2022
                                    this.disableLimitUnlimited = false;// RRA - 1240 - 10/08/2022
                                    this.tonHasErrorUnlimited = true;// RRA - 1240- 10/08/2022
                                    this.tonHasError= false;// RRA - 1240- 10/08/2022
                                    this.template.querySelector('[data-id="limitUnlimitedVal"]').checked = saObj['LimitUnlimited__c']; //RRA - 1240- 16/08/2022
                                }else if ((saObj['Limit__c'] != null || saObj['Limit__c'] != undefined || saObj['Limit__c'] != 'undefined') && saObj['LimitUnlimited__c'] == true){
                                    this.disableLimit = false;// RRA - 1240 - 10/08/2022
                                    this.disableLimitUnlimited = true;// RRA - 1240 - 10/08/2022
                                    this.tonHasErrorUnlimited = false;// RRA - 1240- 10/08/2022
                                    this.tonHasError= true;// RRA - 1240- 10/08/2022
                                    this.template.querySelector('[data-id="limitUnlimitedVal"]').checked = saObj['LimitUnlimited__c']; //RRA - 1240- 16/08/2022
                                }else if ((saObj['Limit__c'] != null || saObj['Limit__c'] != undefined || saObj['Limit__c'] != 'undefined') && saObj['LimitUnlimited__c'] == false){
                                    this.disableLimit = false;// RRA - 1240 - 10/08/2022
                                    this.disableLimitUnlimited = true;// RRA - 1240 - 10/08/2022
                                    this.tonHasErrorUnlimited = false;// RRA - 1240- 10/08/2022
                                    this.tonHasError= true;// RRA - 1240- 10/08/2022
                                    this.template.querySelector('[data-id="limitUnlimitedVal"]').checked = saObj['LimitUnlimited__c']; //RRA - 1240- 16/08/2022
                                }
                            }
                    }
                    //**FORMULAR P&C*/
                    //****************/
                    if (saObj['ExposureBasedOn__c'] !== undefined){  //RRA - ticket 1445 - 08032023
                        if(saObj.LimitUnlimited__c == false && saObj['ExposureBasedOn__c'] != 'Sums Insured'){//MRA W-1240 22/08/2022
                            this.disableLimit = false;
                        }
                    }
                    if(saObj.LimitType__c == '1'){
                        //SI
                        this.disableLimit = true;
                        this.disableLimitUnlimited = true;// RRA - 1063 - 08/07/2022
                        this.tonHasErrorUnlimited = false;// RRA - 1240- 10/08/2022

                        //RRA - ticket 1445 - 08032023
                        if (saObj['ExposureBasedOn__c'] === undefined){
                            saObj['LimitUnlimited__c'] = false;
                        }else{
                            this.template.querySelector('[data-id="limitUnlimitedVal"]').checked = false; //RRA - 1191 - 03/08/22 
                        }
                        this.tonHasError= false;
                        saObj['Limit__c'] = null;
                        saObj['LimitEuro__c'] = null;
                        saObj['LimitUnlimited__c'] = false;
                        }
                    else{
                            if (saObj['ExposureBasedOn__c'] !== undefined){ 
                                if ((saObj['Limit__c'] == null || saObj['Limit__c'] == undefined || saObj['Limit__c'] == 'undefined') && saObj['LimitUnlimited__c'] == false && saObj['ExposureBasedOn__c'] != 'Sums Insured'){
                                    this.disableLimit = false;// RRA - 1240 - 10/08/2022
                                    this.disableLimitUnlimited = false;// RRA - 1240 - 10/08/2022
                                    this.tonHasErrorUnlimited = true;// RRA - 1240- 10/08/2022
                                    this.tonHasError= true;// RRA - 1240- 10/08/2022
                                    this.template.querySelector('[data-id="limitUnlimitedVal"]').checked = saObj['LimitUnlimited__c'];
                                }
                            }else if ((saObj['Limit__c'] == null || saObj['Limit__c'] == undefined || saObj['Limit__c'] == 'undefined') && saObj['LimitUnlimited__c'] == true){
                                this.disableLimit = true;// RRA - 1240 - 10/08/2022
                                this.disableLimitUnlimited = false;// RRA - 1240 - 10/08/2022
                                this.tonHasErrorUnlimited = true;// RRA - 1240- 10/08/2022
                                this.tonHasError= false;// RRA - 1240- 10/08/2022
                                this.template.querySelector('[data-id="limitUnlimitedVal"]').checked = saObj['LimitUnlimited__c'];
                               // saObj['LimitUnlimited__c'] = true;
                            }else if (saObj['ExposureBasedOn__c'] !== undefined){
                                if ((saObj['Limit__c'] != null || saObj['Limit__c'] == undefined || saObj['Limit__c'] == 'undefined') && saObj['LimitUnlimited__c'] == true && saObj['ExposureBasedOn__c'] != 'Sums Insured'){
                                    this.disableLimit = false;// RRA - 1240 - 10/08/2022
                                    this.disableLimitUnlimited = true;// RRA - 1240 - 10/08/2022
                                    this.tonHasErrorUnlimited = false;// RRA - 1240- 10/08/2022
                                    this.tonHasError= true;// RRA - 1240- 10/08/2022
                                    this.template.querySelector('[data-id="limitUnlimitedVal"]').checked = saObj['LimitUnlimited__c'];
                                    //saObj['LimitUnlimited__c'] = true;
                                }else if ((saObj['Limit__c'] != null || saObj['Limit__c'] == undefined || saObj['Limit__c'] == 'undefined') && saObj['LimitUnlimited__c'] == false && saObj['ExposureBasedOn__c'] != 'Sums Insured'){
                                    this.disableLimit = false;// RRA - 1240 - 10/08/2022
                                    this.disableLimitUnlimited = true;// RRA - 1240 - 10/08/2022
                                    this.tonHasErrorUnlimited = false;// RRA - 1240- 10/08/2022
                                    this.tonHasError= true;// RRA - 1240- 10/08/2022
                                    this.template.querySelector('[data-id="limitUnlimitedVal"]').checked = saObj['LimitUnlimited__c'];
                                }
                            }
                    }
                }
            this.selectedProgramNature = programObj.Nature__c;
            this.covCedComOption = result.lstCedingComp;
            getTypeOfSARecordTypeId({typeOfSA : this.saType})
            .then(result => {
                this.typeOfSARecordTypeId = result;
            })
            .catch(error => {
                this.dispatchEvent(new ShowToastEvent({title: 'ERROR 44', message: this.label.errorMsg, variant: 'error'}),);
            });
        })
        .catch(error => {
            this.dispatchEvent(new ShowToastEvent({title: 'ERROR 55', message: this.label.errorMsg, variant: 'error'}),);
        });
    }

    handleOnChangeSaType(event){
        let value = event.currentTarget.value;
        let fieldName = event.currentTarget.name;
        this.specialAcceptanceObj[fieldName] = value;
    }
    
    handleOnchangeValue(event){
        let value = event.currentTarget.value;
        let fieldName = event.currentTarget.name;
        let saObj = this.specialAcceptanceObj;

        if(fieldName != null && fieldName != ''){
            saObj[fieldName] = value;
        }

        if(fieldName == 'Currency__c'){
            if(this.mapCurrency.has(value)){
                let currencyLabel = this.mapCurrency.get(value);
                if(this.mapRateByCurrencyLabel[currencyLabel] != undefined){saObj['RateExchange__c'] = this.mapRateByCurrencyLabel[currencyLabel]; }
                else{saObj['RateExchange__c'] = null;}
                saObj['TotalInsuredValueEuro__c'] = parseFloat(saObj.TotalInsuredValue__c) / parseFloat(saObj.RateExchange__c);
                saObj['LimitEuro__c'] = parseFloat(saObj.Limit__c) / parseFloat(saObj.RateExchange__c);
                saObj['TopLocationPdValues100Euro__c'] = parseFloat(saObj.TopLocationPdValues100__c) / parseFloat(saObj.RateExchange__c);
                saObj['TopLocationBiValues100Euro__c'] = parseFloat(saObj.TopLocationBiValues100__c) / parseFloat(saObj.RateExchange__c);
                saObj['MaximumPossibleLossMplEuro__c'] = parseFloat(saObj.MaximumPossibleLossMpl__c) / parseFloat(saObj.RateExchange__c);
                saObj['LossLimit100Euro__c'] = parseFloat(saObj.LossLimit100__c) / parseFloat(saObj.RateExchange__c);
                saObj['ExposureAmount100Euro__c'] = parseFloat(saObj.ExposureAmount100__c) / parseFloat(saObj.RateExchange__c);
                saObj['CededExposureTreatyEuro__c'] = parseFloat(saObj.CededExposureTreaty__c) / parseFloat(saObj.RateExchange__c);
                saObj['InXsOf__c'] = saObj.CededExposureTreatyEuro__c;
                saObj['CededExposureAutofacEuro__c'] = parseFloat(saObj.CededExposureAutofac__c) / parseFloat(saObj.RateExchange__c);
                saObj['FacLayer__c'] = saObj.CededExposureAutofacEuro__c;
                saObj['CededExposureInternalFacultativeEuro__c'] = parseFloat(saObj.CededExposureInternalFacultative__c) / parseFloat(saObj.RateExchange__c);
                saObj['CededExposureExternalFacultativeEuro__c'] = parseFloat(saObj.CededExposureExternalFacultative__c) / parseFloat(saObj.RateExchange__c);
                saObj['DeductibleAmountEuro__c'] = parseFloat(saObj.DeductibleAmount__c) / parseFloat(saObj.RateExchange__c);
                saObj['OriginalPolicyPremiumEuro__c'] = parseFloat(saObj.OriginalPolicyPremium__c) / parseFloat(saObj.RateExchange__c);
                saObj['OriginalPremium100Euro__c'] = parseFloat(saObj.OriginalPremium100__c) / parseFloat(saObj.RateExchange__c);
                saObj['TotalSumRiskEuro__c'] = parseFloat(saObj.TotalSumRisk__c) / parseFloat(saObj.RateExchange__c);
                saObj['AverageSumRisk__c'] = parseFloat(saObj.TotalSumRisk__c) / parseFloat(saObj.NumberHeads__c);
                saObj['AverageSumRiskEuro__c'] = saObj.AverageSumRisk__c / parseFloat(saObj.RateExchange__c);
                saObj['TotalAxaShareEuro__c'] = parseFloat(saObj.TotalAxaShare__c) / parseFloat(saObj.RateExchange__c);
                //MRA W-980 : Net Premium for the layer according AutoFac wording "rating for layers" (in EUR) : START
                //saObj['NetPremiumLayerEuro__c'] = parseFloat(saObj.OriginalPremium100Euro__c) * (parseFloat(saObj.AxaShare__c) / 100) * (1 - (1 - 33,2411295999901 / 100) * (1 - (parseFloat(saObj.AutofacCommission__c) / 100))); // RRA - 980 - 13/06/2022
                let layer = parseInt(this.label.constantPremiumValue)*((Math.pow((this.searchMinimum(saObj.CededExposureAutofacEuro__c+saObj.CededExposureTreatyEuro__c,saObj.TotalAxaShareEuro__c)/saObj.TotalAxaShareEuro__c)*100,(parseFloat(this.label.powNetPremiumValue))) - (Math.pow((this.searchMinimum(saObj.CededExposureTreatyEuro__c,saObj.TotalAxaShareEuro__c)/saObj.TotalAxaShareEuro__c)*100,(parseFloat(this.label.powNetPremiumValue)))) ));
                saObj['NetPremiumLayerEuro__c'] = parseFloat(saObj.OriginalPremium100Euro__c*(1-(1-(layer/100)))*(1-(saObj.AutofacCommission__c/100))) ;
                //MRA W-980 : Net Premium for the layer according AutoFac wording "rating for layers" (in EUR) : END

                if(this.displayAutoFacFormVal == true){
                    saObj['AutofacShare__c'] = (parseFloat(saObj.CededExposureAutofacEuro__c) / parseFloat(saObj.TotalAxaShareEuro__c)) * 100;
                }

                saObj['TotalExposureAxaShareEuro__c'] = parseFloat(saObj.TotalExposureAxaShare__c) / parseFloat(saObj.RateExchange__c);
                saObj['NetCededPremiumAutofac__c'] = parseFloat(saObj.OriginalPremium100__c) * (parseFloat(saObj.AxaShare__c) / 100) * (parseFloat(saObj.AutofacShare__c) / 100) * (1 - (parseFloat(saObj.AutofacCommission__c) / 100));
                saObj['NetCededPremiumAutofacEuro__c'] = parseFloat(saObj.NetCededPremiumAutofac__c) / parseFloat(saObj.RateExchange__c);
                saObj['TreatyExposureEuro__c'] = parseFloat(saObj.TreatyExposure__c) / parseFloat(saObj.RateExchange__c);

            }
        }
        else if(fieldName == 'TotalInsuredValue__c'){
            //'= Total Insured Value x Rate of Exchange
            saObj['TotalInsuredValueEuro__c'] = parseFloat(value) / parseFloat(saObj.RateExchange__c);
            saObj['TotalInsuredValue__c'] = value;

            if(this.displayPCFormVal == true){
                if(saObj.LimitUnlimited__c == false){
                    this.disableLimit = false;
                }

                //MBE - 18/08
                //W-0975 - If limit type = loss limit, EML, Other, MPL et PML alors total exposure at AXA share = limit x AXA Share (%)

                if(saObj.LimitType__c == '2' || saObj.LimitType__c == '3' || saObj.LimitType__c == '4' || saObj.LimitType__c == '5' || saObj.LimitType__c == '6'){
                    //MPL or PML
                    //New Rule for EML/OTHER/Loss Limit
                    saObj['TotalExposureAxaShare__c'] = parseFloat(saObj.Limit__c) * (parseFloat(saObj.AxaShare__c) / 100);
                }
                else if(saObj.LimitType__c == '1'){
                    //SI
                    saObj['TotalExposureAxaShare__c'] = parseFloat(saObj.TotalInsuredValue__c) * (parseFloat(saObj.AxaShare__c) / 100);
                    this.disableLimit = true; //RRA - 1240 - 16/08/2022
                    this.disableLimitUnlimited__c = true //RRA - 1240 - 16/08/2022
                    saObj['Limit__c'] = null;
                }
                else{
                    saObj['TotalExposureAxaShare__c'] = null;
                }

                saObj['TotalExposureAxaShareEuro__c'] = parseFloat(saObj.TotalExposureAxaShare__c) / parseFloat(saObj.RateExchange__c);
            }
            else if(this.displayAutoFacFormVal == true){
                saObj['OriginalNetRate__c'] = (parseFloat(saObj.OriginalPremium100__c) / parseFloat(saObj.TotalInsuredValue__c)) * 1000;
            }   
        }
        else if(fieldName == 'Limit__c'){
            //'= Limit x Rate of Exchange
            saObj['LimitEuro__c'] = parseFloat(value) / parseFloat(saObj.RateExchange__c);
            saObj['Limit__c'] = value;
            let inputBorder = this.template.querySelector('[data-id="Limit"]');

            // RRA - 1163 - 22/06/2022
            if(value == null || value == '' || value == undefined || value == 'undefined' && saObj['LimitUnlimited__c'] == false){
                this.disableLimitUnlimited = false;
                this.disableLimit = false;
                this.tonHasError = true;
                //this.errors = 'Complete this fields.';
                this.tonHasErrorUnlimited = true;
            }
            else if((value != null || value != '' || value != 'undefined') && saObj['LimitUnlimited__c'] == false){
                this.disableLimitUnlimited = true;
                this.tonHasError = true;
                this.errors = '';
                this.tonHasErrorUnlimited = false;
                inputBorder.className = '';
            }

            if(this.displayPCFormVal == true){
                if(saObj.LimitUnlimited__c == false){
                    this.disableLimit = false;
                } 

                if(saObj.LimitType__c == '2' || saObj.LimitType__c == '3' || saObj.LimitType__c == '4' || saObj.LimitType__c == '5' || saObj.LimitType__c == '6'){
                    //MPL or PML
                    //New Rule for EML/OTHER/Loss Limit
                    saObj['TotalExposureAxaShare__c'] = parseFloat(saObj.Limit__c) * (parseFloat(saObj.AxaShare__c) / 100);
                }
                else if(saObj.LimitType__c == '1'){
                    //SI
                    saObj['TotalExposureAxaShare__c'] = parseFloat(saObj.TotalInsuredValue__c) * (parseFloat(saObj.AxaShare__c) / 100);
                    this.disableLimit = true;
                    this.disableLimitUnlimited = false;
                    saObj['Limit__c'] = null;
                }
                else{
                    saObj['TotalExposureAxaShare__c'] = null;
                }

                saObj['TotalExposureAxaShareEuro__c'] = parseFloat(saObj.TotalExposureAxaShare__c) / parseFloat(saObj.RateExchange__c);
            }
        } 
        else if(fieldName == 'LimitUnlimited__c'){
            saObj['LimitUnlimited__c'] = event.currentTarget.checked;

            //RRA - 1163 - 22/06/2022
            if(saObj.LimitUnlimited__c == false && saObj.LimitType__c != '1'){
                this.disableLimit = false;     
                this.tonHasError = true;
                this.tonHasErrorUnlimited = true;
            }
            else if(saObj.LimitUnlimited__c == true){
                let inputBorder = this.template.querySelector('[data-id="Limit"]');
                this.disableLimit = true;
                this.errors = '';
                this.tonHasError = false;
                this.tonHasErrorUnlimited = true;
                inputBorder.className = '';
            }else if(saObj.LimitUnlimited__c == false && saObj.Limit__c ==null){
                this.tonHasError = true;
                this.tonHasErrorUnlimited = true;
            }

             //RRA - 1163 - 07/07/2022 Rectification
             if(saObj.LimitUnlimited__c == false && saObj.LimitType__c == '1'){              
                this.tonHasError = true;
                this.tonHasErrorUnlimited = false;
            }else if(saObj.LimitUnlimited__c == true){
                this.tonHasError = false;
                this.tonHasErrorUnlimited = true;
            }
        }
        else if(fieldName == 'TopLocationPdValues100__c'){
            //'= Top location PD values 100% x Rate of Exchange
            saObj['TopLocationPdValues100Euro__c'] = parseFloat(value) / parseFloat(saObj.RateExchange__c);
            saObj['TopLocationPdValues100__c'] = value;
        }
        else if(fieldName == 'TopLocationBiValues100__c'){
            //'= Top location BI values 100% x Rate of Exchange
            saObj['TopLocationBiValues100Euro__c'] = parseFloat(value) / parseFloat(saObj.RateExchange__c);
            saObj['TopLocationBiValues100__c'] = value;
        }
        else if(fieldName == 'MaximumPossibleLossMpl__c'){
            //'= Maximum possible loss (MPL) x Rate of Exchange
            saObj['MaximumPossibleLossMplEuro__c'] = parseFloat(value) / parseFloat(saObj.RateExchange__c);
            saObj['MaximumPossibleLossMpl__c'] = value;
        }
        else if(fieldName == 'LossLimit100__c'){
            //'= Loss Limit 100% (if applicable) x Rate of Exchange
            saObj['LossLimit100Euro__c'] = parseFloat(value) / parseFloat(saObj.RateExchange__c);
            saObj['LossLimit100__c'] = value;
        }
        else if(fieldName == 'AxaShare__c'){
            saObj['AxaShare__c'] = value;

            if(this.displayAutoFacFormVal == true){
                saObj['TotalExposureAxaShare__c'] = parseFloat(saObj.ExposureAmount100__c) * (parseFloat(value) / 100);
                saObj['TotalExposureAxaShareEuro__c'] = parseFloat(saObj.TotalExposureAxaShare__c) / parseFloat(saObj.RateExchange__c);
                saObj['NetCededPremiumAutofac__c'] = parseFloat(saObj.OriginalPremium100__c) * (parseFloat(saObj.AxaShare__c) / 100) * (parseFloat(saObj.AutofacShare__c) / 100) * (1 - (parseFloat(saObj.AutofacCommission__c) / 100));
                saObj['NetCededPremiumAutofacEuro__c'] = parseFloat(saObj.NetCededPremiumAutofac__c) / parseFloat(saObj.RateExchange__c);
                //MRA W-980 : Net Premium for the layer according AutoFac wording "rating for layers" (in EUR) : START
                //saObj['NetPremiumLayerEuro__c'] = parseFloat(saObj.OriginalPremium100Euro__c) * (parseFloat(saObj.AxaShare__c) / 100) * (1 - (1 - 33,2411295999901 / 100) * (1 - (parseFloat(saObj.AutofacCommission__c) / 100))); // RRA - 980 - 13/06/2022
                let layer = parseInt(this.label.constantPremiumValue)*((Math.pow((this.searchMinimum(saObj.CededExposureAutofacEuro__c+saObj.CededExposureTreatyEuro__c,saObj.TotalAxaShareEuro__c)/saObj.TotalAxaShareEuro__c)*100,(parseFloat(this.label.powNetPremiumValue)))) - (Math.pow((this.searchMinimum(saObj.CededExposureTreatyEuro__c,saObj.TotalAxaShareEuro__c)/saObj.TotalAxaShareEuro__c)*100,(parseFloat(this.label.powNetPremiumValue)))) );
                saObj['NetPremiumLayerEuro__c'] = parseFloat(saObj.OriginalPremium100Euro__c*(1-(1-(layer/100)))*(1-(saObj.AutofacCommission__c/100))) ;
                //MRA W-980 : Net Premium for the layer according AutoFac wording "rating for layers" (in EUR) : END
            }
            else if(this.displayLifeFormVal == true){
                saObj['TotalExposureAxaShare__c'] = parseFloat(saObj.TotalSumRisk__c) * (parseFloat(value) / 100);
                saObj['TotalExposureAxaShareEuro__c'] = parseFloat(saObj.TotalExposureAxaShare__c) / parseFloat(saObj.RateExchange__c);
            }
            else if(this.displayPCFormVal == true){
                /*if(saObj['LimitUnlimited__c'] == false){
                   // this.disableLimit = false;
                }*/

                if(saObj.LimitType__c == '2' || saObj.LimitType__c == '3' || saObj.LimitType__c == '4' || saObj.LimitType__c == '5' || saObj.LimitType__c == '6'){
                    //MPL or PML
                    //New Rule for EML/OTHER/Loss Limit
                    saObj['TotalExposureAxaShare__c'] = parseFloat(saObj.Limit__c) * (parseFloat(saObj.AxaShare__c) / 100);
                }
                else if(saObj.LimitType__c == '1'){
                    //SI
                    saObj['TotalExposureAxaShare__c'] = parseFloat(saObj.TotalInsuredValue__c) * (parseFloat(saObj.AxaShare__c) / 100);
                    this.disableLimit = true;
                    this.disableLimitUnlimited = false;
                    saObj['Limit__c'] = null;
                }
                else{
                    saObj['TotalExposureAxaShare__c'] = null;
                }

                saObj['TotalExposureAxaShareEuro__c'] = parseFloat(saObj.TotalExposureAxaShare__c) / parseFloat(saObj.RateExchange__c);
            }
        }
        else if(fieldName == 'ExposureAmount100__c'){
            //'= Exposure amount at 100% x Rate of Exchange
            saObj['ExposureAmount100Euro__c'] = parseFloat(value) / parseFloat(saObj.RateExchange__c);
            saObj['ExposureAmount100__c'] = value;
            saObj['TotalExposureAxaShare__c'] = parseFloat(value) * (parseFloat(saObj.AxaShare__c) / 100);
            saObj['TotalExposureAxaShareEuro__c'] = parseFloat(saObj.TotalExposureAxaShare__c) / parseFloat(saObj.RateExchange__c);
        }
        else if(fieldName == 'CededExposureTreaty__c'){
            //'= Ceded Exposure to Treaty x Rate of Exchange
            saObj['CededExposureTreatyEuro__c'] = parseFloat(value) / parseFloat(saObj.RateExchange__c);
            saObj['InXsOf__c'] = saObj.CededExposureTreatyEuro__c;
            saObj['CededExposureTreaty__c'] = value;
            saObj['TotalAxaShare__c'] = parseFloat(saObj.CededExposureTreaty__c) + parseFloat(saObj.CededExposureAutofac__c) + parseFloat(saObj.CededExposureInternalFacultative__c) + parseFloat(saObj.CededExposureExternalFacultative__c);
            saObj['TotalAxaShareEuro__c'] = parseFloat(saObj.TotalAxaShare__c) / parseFloat(saObj.RateExchange__c);
            
            if(this.displayAutoFacFormVal == true){
                saObj['AutofacShare__c'] = (parseFloat(saObj.CededExposureAutofacEuro__c) / parseFloat(saObj.TotalAxaShareEuro__c)) * 100;
            }
        }
        else if(fieldName == 'CededExposureAutofac__c'){
            //'= Ceded Exposure to Autofac x Rate of Exchange
            saObj['CededExposureAutofacEuro__c'] = parseFloat(value) / parseFloat(saObj.RateExchange__c);
            saObj['FacLayer__c'] = saObj.CededExposureAutofacEuro__c;
            saObj['CededExposureAutofac__c'] = value;
            saObj['TotalAxaShare__c'] = parseFloat(saObj.CededExposureTreaty__c) + parseFloat(saObj.CededExposureAutofac__c) + parseFloat(saObj.CededExposureInternalFacultative__c) + parseFloat(saObj.CededExposureExternalFacultative__c);
            saObj['TotalAxaShareEuro__c'] = parseFloat(saObj.TotalAxaShare__c) / parseFloat(saObj.RateExchange__c);

            if(this.displayAutoFacFormVal == true){
                saObj['AutofacShare__c'] = (parseFloat(saObj.CededExposureAutofacEuro__c) / parseFloat(saObj.TotalAxaShareEuro__c)) * 100;
            }
        }
        else if(fieldName == 'CededExposureInternalFacultative__c'){
            //'= Ceded Exposure to internal facultative x Rate of Exchange
            saObj['CededExposureInternalFacultativeEuro__c'] = parseFloat(value) / parseFloat(saObj.RateExchange__c);
            saObj['CededExposureInternalFacultative__c'] = value;
            saObj['TotalAxaShare__c'] = parseFloat(saObj.CededExposureTreaty__c) + parseFloat(saObj.CededExposureAutofac__c) + parseFloat(saObj.CededExposureInternalFacultative__c) + parseFloat(saObj.CededExposureExternalFacultative__c);
            saObj['TotalAxaShareEuro__c'] = parseFloat(saObj.TotalAxaShare__c) / parseFloat(saObj.RateExchange__c);
            
            if(this.displayAutoFacFormVal == true){
                saObj['AutofacShare__c'] = (parseFloat(saObj.CededExposureAutofacEuro__c) / parseFloat(saObj.TotalAxaShareEuro__c)) * 100;
            }
        }
        else if(fieldName == 'CededExposureExternalFacultative__c'){
            //'= Ceded Exposure to external facultative x Rate of Exchange
            saObj['CededExposureExternalFacultativeEuro__c'] = parseFloat(value) / parseFloat(saObj.RateExchange__c);
            saObj['CededExposureExternalFacultative__c'] = value;
            saObj['TotalAxaShare__c'] = parseFloat(saObj.CededExposureTreaty__c) + parseFloat(saObj.CededExposureAutofac__c) + parseFloat(saObj.CededExposureInternalFacultative__c) + parseFloat(saObj.CededExposureExternalFacultative__c);
            saObj['TotalAxaShareEuro__c'] = parseFloat(saObj.TotalAxaShare__c) / parseFloat(saObj.RateExchange__c);
            
            if(this.displayAutoFacFormVal == true){
                saObj['AutofacShare__c'] = (parseFloat(saObj.CededExposureAutofacEuro__c) / parseFloat(saObj.TotalAxaShareEuro__c)) * 100;
            }
        }
        else if(fieldName == 'DeductibleAmount__c'){
            //'= Deductible (Amount) x Rate of Exchange
            saObj['DeductibleAmountEuro__c'] = parseFloat(value) / parseFloat(saObj.RateExchange__c);
            saObj['DeductibleAmount__c'] = value;
            
            if(value == null || value == ''){
                this.disableDeductibleAmount = false;
                this.disableDeductiblePercentage = false;
            }
            else{
                this.disableDeductiblePercentage = true;
                saObj['DeductiblePercentage__c'] = null;
            }    
        }
        else if(fieldName == 'DeductiblePercentage__c'){
            saObj['DeductiblePercentage__c'] = value;
            if(value == null || value == ''){
                this.disableDeductibleAmount = false;
                this.disableDeductiblePercentage = false;
            }
            else{
                this.disableDeductibleAmount = true;
                saObj['DeductibleAmount__c'] = null;
            }    
        }
        else if(fieldName == 'OriginalPolicyPremium__c'){
            //'= Original Policy Premium x Rate of Exchange
            saObj['OriginalPolicyPremiumEuro__c'] = parseFloat(value) / parseFloat(saObj.RateExchange__c);
            saObj['OriginalPolicyPremium__c'] = value;
        }
        else if(fieldName == 'OriginalPremium100__c'){
            //'= Original Premium at 100% (net of brokerage and taxes) x Rate of Exchange
            saObj['OriginalPremium100Euro__c'] = parseFloat(value) / parseFloat(saObj.RateExchange__c);
            saObj['OriginalPremium100__c'] = value;
            saObj['OriginalNetRate__c'] = (parseFloat(saObj.OriginalPremium100__c) / parseFloat(saObj.TotalInsuredValue__c)) * 1000;
            saObj['NetCededPremiumAutofac__c'] = parseFloat(saObj.OriginalPremium100__c) * (parseFloat(saObj.AxaShare__c) / 100) * (parseFloat(saObj.AutofacShare__c) / 100) * (1 - (parseFloat(saObj.AutofacCommission__c) / 100));
            saObj['NetCededPremiumAutofacEuro__c'] = parseFloat(saObj.NetCededPremiumAutofac__c) / parseFloat(saObj.RateExchange__c);
                //MRA W-980 : Net Premium for the layer according AutoFac wording "rating for layers" (in EUR) : START
            //saObj['NetPremiumLayerEuro__c'] = parseFloat(saObj.OriginalPremium100Euro__c) * (parseFloat(saObj.AxaShare__c) / 100) * (1 - (1 - 33,2411295999901 / 100) * (1 - (parseFloat(saObj.AutofacCommission__c) / 100))); // RRA - 980 - 13/06/2022
            let layer = parseInt(this.label.constantPremiumValue)*((Math.pow((this.searchMinimum(saObj.CededExposureAutofacEuro__c+saObj.CededExposureTreatyEuro__c,saObj.TotalAxaShareEuro__c)/saObj.TotalAxaShareEuro__c)*100,(parseFloat(this.label.powNetPremiumValue)))) - (Math.pow((this.searchMinimum(saObj.CededExposureTreatyEuro__c,saObj.TotalAxaShareEuro__c)/saObj.TotalAxaShareEuro__c)*100,(parseFloat(this.label.powNetPremiumValue)))) );
            saObj['NetPremiumLayerEuro__c'] = parseFloat(saObj.OriginalPremium100Euro__c*(1-(1-(layer/100)))*(1-(saObj.AutofacCommission__c/100))) ;
            //MRA W-980 : Net Premium for the layer according AutoFac wording "rating for layers" (in EUR) : END

        }
        else if(fieldName == 'TreatyExposure__c'){
            //'= Treaty Exposure x Rate of Exchange
            saObj['TreatyExposureEuro__c'] = parseFloat(value) / parseFloat(saObj.RateExchange__c);
            saObj['TreatyExposureEuro__c'] = parseFloat(saObj.TreatyExposure__c) / parseFloat(saObj.RateExchange__c);
            saObj['TreatyExposure__c'] = value;
        }
        else if(fieldName == 'TotalSumRisk__c'){
            //'= Total Sum at Risk x Rate of Exchange
            saObj['TotalSumRisk__c'] = value;
            saObj['TotalSumRiskEuro__c'] = parseFloat(value) / parseFloat(saObj.RateExchange__c);
            saObj['AverageSumRisk__c'] = parseFloat(value) / parseFloat(saObj.NumberHeads__c);
            saObj['AverageSumRiskEuro__c'] = saObj.AverageSumRisk__c / parseFloat(saObj.RateExchange__c);

            if(this.displayLifeFormVal == true){
                saObj['TotalExposureAxaShare__c'] = parseFloat(saObj.TotalSumRisk__c) * (parseFloat(saObj.AxaShare__c) / 100);
                saObj['TotalExposureAxaShareEuro__c'] = parseFloat(saObj.TotalExposureAxaShare__c) / parseFloat(saObj.RateExchange__c);
            }
        }
        else if(fieldName == 'NumberHeads__c'){
            saObj['NumberHeads__c'] = value;
            saObj['AverageSumRisk__c'] = parseFloat(saObj.TotalSumRisk__c) / parseInt(value);
            saObj['AverageSumRiskEuro__c'] =  parseFloat(saObj.AverageSumRisk__c) / parseFloat(saObj.RateExchange__c);
        }
        else if(fieldName == 'LimitType__c'){
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
            saObj['LimitType__c'] = value;

            if(this.displayPCFormVal == true){
                if(saObj.LimitUnlimited__c == false){
                    this.disableLimit = false;
                }

                if(saObj.LimitType__c == '2' || saObj.LimitType__c == '3' || saObj.LimitType__c == '4' || saObj.LimitType__c == '5' || saObj.LimitType__c == '6'){
                    //MPL or PML
                    //New Rule for EML/OTHER/Loss Limit
                    saObj['TotalExposureAxaShare__c'] = parseFloat(saObj.Limit__c) * (parseFloat(saObj.AxaShare__c) / 100);
                    if ((saObj['Limit__c'] == null || saObj['Limit__c'] == '' || saObj['Limit__c'] == undefined || saObj['Limit__c'] == 'undefined') && saObj['LimitUnlimited__c'] == false){
                        this.disableLimit = false;// RRA - 1240 - 10/08/2022
                        this.disableLimitUnlimited = false;// RRA - 1240 - 10/08/2022
                        this.tonHasErrorUnlimited = true;// RRA - 1240- 10/08/2022
                        this.tonHasError= true;// RRA - 1240- 10/08/2022
                    }else if ((saObj['Limit__c'] == null || saObj['Limit__c'] == '' || saObj['Limit__c'] == undefined || saObj['Limit__c'] == 'undefined') && saObj['LimitUnlimited__c'] == true){
                        this.disableLimit = true;// RRA - 1240 - 10/08/2022
                        this.disableLimitUnlimited = false;// RRA - 1240 - 10/08/2022
                        this.tonHasErrorUnlimited = true;// RRA - 1240- 10/08/2022
                        this.tonHasError= false;// RRA - 1240- 10/08/2022
                    }else if ((saObj['Limit__c'] != null) && saObj['LimitUnlimited__c'] == true){
                        this.disableLimit = false;// RRA - 1240 - 10/08/2022
                        this.disableLimitUnlimited = true;// RRA - 1240 - 10/08/2022
                        this.tonHasErrorUnlimited = false;// RRA - 1240- 10/08/2022
                        this.tonHasError= true;// RRA - 1240- 10/08/2022
                    }else if (saObj['Limit__c'] != null && saObj['LimitUnlimited__c'] == false){
                        this.disableLimit = false;// RRA - 1240 - 10/08/2022
                        this.disableLimitUnlimited = true;// RRA - 1240 - 10/08/2022
                        this.tonHasErrorUnlimited = false;// RRA - 1240- 10/08/2022
                        this.tonHasError= true;// RRA - 1240- 10/08/2022
                    }
                }
                else if(saObj.LimitType__c == '1'){
                    //SI
                    saObj['TotalExposureAxaShare__c'] = parseFloat(saObj.TotalInsuredValue__c) * (parseFloat(saObj.AxaShare__c) / 100);
                    this.disableLimit = true;
                    this.disableLimitUnlimited = true;// RRA - 1063 - 08/07/2022
                    this.tonHasErrorUnlimited = false;// RRA - 1240- 10/08/2022
                    this.template.querySelector('[data-id="limitUnlimitedVal"]').checked = false; //RRA - 1191 - 03/08/22 
                    this.tonHasError= false;
                    saObj['Limit__c'] = null;
                    saObj['LimitEuro__c'] = null
                    saObj['LimitUnlimited__c'] = false;
                }
                else{

                    this.disableLimit = false;// RRA - 1063 - 08/07/2022
                    this.disableLimitUnlimited = false;// RRA - 1063 - 08/07/2022
                    
                }

                saObj['TotalExposureAxaShareEuro__c'] = parseFloat(saObj.TotalExposureAxaShare__c) / parseFloat(saObj.RateExchange__c);
            }
        } else if(fieldName == 'ExposureBasedOn__c'){ //RRA - 1191 (ref 1163) - 03/08/2022
            if(this.displayAutoFacFormVal ){
                saObj['ExposureBasedOn__c'] = value;

                if(saObj.ExposureBasedOn__c == 'Loss Limit' || saObj.ExposureBasedOn__c == 'MPL' || saObj.ExposureBasedOn__c == 'Top Location'){
                    
                    if ((saObj['Limit__c'] == null || saObj['Limit__c'] == '' || saObj['Limit__c'] == undefined || saObj['Limit__c'] == 'undefined') && saObj['LimitUnlimited__c'] == false){
                        this.disableLimit = false;// RRA - 1240 - 10/08/2022
                        this.disableLimitUnlimited = false;// RRA - 1240 - 10/08/2022
                        this.tonHasErrorUnlimited = true;// RRA - 1240- 10/08/2022
                        this.tonHasError= true;// RRA - 1240- 10/08/2022
                    }else if ((saObj['Limit__c'] == null || saObj['Limit__c'] == '' || saObj['Limit__c'] == undefined || saObj['Limit__c'] == 'undefined') && saObj['LimitUnlimited__c'] == true){
                        this.disableLimit = true;// RRA - 1240 - 10/08/2022
                        this.disableLimitUnlimited = false;// RRA - 1240 - 10/08/2022
                        this.tonHasErrorUnlimited = true;// RRA - 1240- 10/08/2022
                        this.tonHasError= false;// RRA - 1240- 10/08/2022
                    }else if (saObj['Limit__c'] != null && saObj['LimitUnlimited__c'] == true){
                        this.disableLimit = false;// RRA - 1240 - 10/08/2022
                        this.disableLimitUnlimited = true;// RRA - 1240 - 10/08/2022
                        this.tonHasErrorUnlimited = false;// RRA - 1240- 10/08/2022
                        this.tonHasError= true;// RRA - 1240- 10/08/2022
                    }else if (saObj['Limit__c'] != null && saObj['LimitUnlimited__c'] == false){
                        this.disableLimit = false;// RRA - 1240 - 10/08/2022
                        this.disableLimitUnlimited = true;// RRA - 1240 - 10/08/2022
                        this.tonHasErrorUnlimited = false;// RRA - 1240- 10/08/2022
                        this.tonHasError= true;// RRA - 1240- 10/08/2022
                    }
                }
                else if(saObj['ExposureBasedOn__c'] == 'Sums Insured'){
                    this.disableLimit = true; //RRA - 1191 (ref 1163) - 29/07/2022
                    this.disableLimitUnlimited = true; //RRA - 1191 (ref 1163) - 29/07/2022
                    this.tonHasErrorUnlimited = false;// RRA - 1240- 10/08/2022
                    this.template.querySelector('[data-id="limitUnlimitedVal"]').checked = false; //RRA - 1191 - 03/08/22 
                    this.tonHasError= false;
                    saObj['Limit__c'] = null;
                    saObj['LimitEuro__c'] = null ;
                    saObj['LimitUnlimited__c'] = false;
                }
                else{
                    this.disableLimit = false; //RRA - 1191 (ref 1163) - 29/07/2022
                    this.disableLimitUnlimited = false; //RRA - (ref 1163) - 29/07/2022
                }
            }
        }
        else if(fieldName == 'AutofacCommission__c'){
            saObj['AutofacCommission__c'] = value;
            saObj['NetCededPremiumAutofac__c'] = parseFloat(saObj.OriginalPremium100__c) * (parseFloat(saObj.AxaShare__c) / 100) * (parseFloat(saObj.AutofacShare__c) / 100) * (1 - (parseFloat(saObj.AutofacCommission__c) / 100));
            saObj['NetCededPremiumAutofacEuro__c'] = parseFloat(saObj.NetCededPremiumAutofac__c) / parseFloat(saObj.RateExchange__c);
                //MRA W-980 : Net Premium for the layer according AutoFac wording "rating for layers" (in EUR) : START
            //saObj['NetPremiumLayerEuro__c'] = parseFloat(saObj.OriginalPremium100Euro__c) * (parseFloat(saObj.AxaShare__c) / 100) * (1 - (1 - 33,2411295999901 / 100) * (1 - (parseFloat(saObj.AutofacCommission__c) / 100))); // RRA - 980 - 13/06/2022
            let layer = parseInt(this.label.constantPremiumValue)*((Math.pow((this.searchMinimum(saObj.CededExposureAutofacEuro__c+saObj.CededExposureTreatyEuro__c,saObj.TotalAxaShareEuro__c)/saObj.TotalAxaShareEuro__c)*100,(parseFloat(this.label.powNetPremiumValue)))) - (Math.pow((this.searchMinimum(saObj.CededExposureTreatyEuro__c,saObj.TotalAxaShareEuro__c)/saObj.TotalAxaShareEuro__c)*100,(parseFloat(this.label.powNetPremiumValue)))) );
            saObj['NetPremiumLayerEuro__c'] = parseFloat(saObj.OriginalPremium100Euro__c*(1-(1-(layer/100)))*(1-(saObj.AutofacCommission__c/100))) ;
            //MRA W-980 : Net Premium for the layer according AutoFac wording "rating for layers" (in EUR) : END

        }
        else if(fieldName == 'AutofacShare__c'){
            saObj['AutofacShare__c'] = value;
            saObj['NetCededPremiumAutofac__c'] = parseFloat(saObj.OriginalPremium100__c) * (parseFloat(saObj.AxaShare__c) / 100) * (parseFloat(saObj.AutofacShare__c) / 100) * (1 - (parseFloat(saObj.AutofacCommission__c) / 100));
            saObj['NetCededPremiumAutofacEuro__c'] = parseFloat(saObj.NetCededPremiumAutofac__c) / parseFloat(saObj.RateExchange__c);
        }
        else if(fieldName == 'CatCoverage__c'){
            saObj['CatCoverage__c'] = value;
        }
        else if(fieldName == 'FloodLimit__c'){
            saObj['FloodLimit__c'] = value;
        }
        else if(fieldName == 'WindstormLimit__c'){
            saObj['WindstormLimit__c'] = value;
        }
        else if(fieldName == 'EarthquakeLimit__c'){
            saObj['EarthquakeLimit__c'] = value;
        }
        else if(fieldName == 'TerrorismLimit__c'){
            saObj['TerrorismLimit__c'] = value;
        }
        else if(fieldName == 'TypeFacPlacement__c'){
            saObj['TypeFacPlacement__c'] = value;

            if(value == 'QS'){
                saObj['displayAutofacQS'] = true;
                saObj['displayAutofacXS'] = false;
            }
            else if(value == 'XS'){
                saObj['displayAutofacQS'] = false;
                saObj['displayAutofacXS'] = true;
            }
        }

        this.specialAcceptanceObj = saObj;
    }
    searchMinimum(a,b){
        if (a<=b)
            return a ;
        else 
            return b ;
    }


    handleCloseSAOpenModal(event){
        if(this.isModalEdit == true){
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: '/cedingPortal/s/?s__id='+this.valueUWYear+'-'+this.valuePrincipalCedComp+'-'+this.progIdOfSelectedSA
                }
            });
        }
        else if(this.isModalRenew == true){
            if(this.isUserCe == true){
                let urlPage = '../n/SpecialAcceptance?s__id='+this.valueUWYear+'-'+this.valuePrincipalCedComp+'-'+this.selectedProgram;
                this[NavigationMixin.Navigate]({
                    type: 'standard__webPage',
                    attributes: {url: urlPage, target: '_self'}
                });
            }
            else{
                this[NavigationMixin.Navigate]({
                    type: 'standard__webPage',
                    attributes: {
                        url: '/cedingPortal/s/?s__id='+this.valueUWYear+'-'+this.valuePrincipalCedComp+'-'+this.selectedProgram
                    }
                });
            }
        }
        else if(this.isCELoadSEReq == true){
            let urlPage;
            if(this.loadSAReadOnlyUGP == true){
                urlPage = '../n/SpecialAcceptanceGroupCover?s__id='+this.valueUWYear+'-'+this.valuePrincipalCedComp+'-'+this.selectedProgram+'-'+this.selectedPool;
            }
            else{
                urlPage = '../n/SpecialAcceptance?s__id='+this.valueUWYear+'-'+this.valuePrincipalCedComp+'-'+this.selectedProgram;
            }

            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {url: urlPage, target: '_self'}
            });
        }
        else{
            fireEvent(this.pageRef, 'closeCopyRenewSAModal', true);
        }
    }

    handleOpenNewDocumentModal(event){
        this.isOpenDocModal = true;
        this.documentNames = null;
    }

    handleCloseUploadModal(event){
        this.isOpenDocModal = false;
    }

    handleUploadFinished(event){
        this.documentNames = null;
        this.uploadedDoc = event.detail.files;

        for(var i = 0; i < this.uploadedDoc.length; i++){
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
                
                if(this.isUserCe == true || this.loadSAReadOnlyUGP == true){
                    document['DocumentUrl'] = "/sfc/servlet.shepherd/document/download/"+ result[i].ContentDocumentId+"?operationContext=S1";
                }
                else{
                    document['DocumentUrl'] = "../sfc/servlet.shepherd/version/download/"+ result[i].Id+"?operationContext=S1";
                }

                document['SpecialAcceptance__c'] = null;
                document['NewRenewUpload'] = true;
                document['ContentDocumentId'] = result[i].ContentDocumentId;
                this.lstDocuments.push(document);
            }

            this.titleCountDocument = 'My Documents ('+ this.lstDocuments.length +')';
            this.handleSaveDocument();
        })
        .catch(error => {
            this.dispatchEvent(new ShowToastEvent({title: 'ERROR 22', message: this.label.errorMsg, variant: 'error'}),);
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
                objDocument.PathOnClient = this.lstDocuments[i].Name;
                lstSaveDocument.push(objDocument);
            }

            saveDocuments({lstContentVersion : lstSaveDocument})
            .then(result => {
                this.dispatchEvent(new ShowToastEvent({title: 'Success', message: this.label.DocumentSavedSuccessMsg, variant: 'success' }),);
            })
            .catch(error => {
                this.dispatchEvent(new ShowToastEvent({title: 'ERROR', message: this.label.errorMsg, variant: 'error'}),);
            });
        }
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

        if(this.disableAllFields == true){
            this.disableDeleteBtn = true;
        }
        else if(numOfDocChecked > 0){
            this.disableDeleteBtn = false;
        }
        else{
            this.disableDeleteBtn = true;
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

    handleDeleteDocument(event){
        this.disableDeleteBtn = true;

        for(let i = 0; i < this.lstDocuments.length; i++){
            if(this.lstDocuments[i].Checked == true){
                this.lstSelectedDocument.push(this.lstDocuments[i]);
                if(this.isModalEdit == true || this.isCELoadSEReq == true){
                    this.lstSelectedDeleteDocumentId.push(this.lstDocuments[i].Id);
                }
                else if(this.lstDocuments[i].NewRenewUpload == true){
                    this.lstSelectedDeleteDocumentId.push(this.lstDocuments[i].Id);
                }
            }
        }

        this.lstDocuments = this.lstDocuments.filter( function(e) { return this.indexOf(e) < 0; }, this.lstSelectedDocument);
        this.titleCountDocument = 'My Documents ('+ this.lstDocuments.length +')';
    }

    deselectOtherCheckbox(event){
        let valueChecked = event.target.checked;
        let fieldName = event.target.name;
        let saObj = this.specialAcceptanceObj;

        if(valueChecked == true && fieldName == 'LegalEntity__c'){
            let checkboxes = this.template.querySelectorAll('[data-id="NaturalPerson"]');
           
            for(let i = 0; i < checkboxes.length; i++) {
                checkboxes[i].checked = false;
            }

            saObj['disableSpecialAcceptanceName'] = false;
            saObj['legalEntityRequired'] = true;
        }
        else if(valueChecked == true && fieldName == 'NaturalPerson__c'){
            let checkboxes = this.template.querySelectorAll('[data-id="LegalEntity"]');
            
            for(let i = 0; i < checkboxes.length; i++) {
                checkboxes[i].checked = false;
            }

            let specialAcceptanceNameVal = this.template.querySelectorAll('[data-id="SpecialAcceptanceName"]');

            for(let i = 0; i < specialAcceptanceNameVal.length; i++) {
                specialAcceptanceNameVal[i].value = saObj.Reference__c;
            }

            saObj['SpecialAcceptanceName__c'] = saObj.Reference__c;
            saObj['disableSpecialAcceptanceName'] = true;
        }
        else if(valueChecked == false && fieldName == 'NaturalPerson__c'){
            saObj['disableSpecialAcceptanceName'] = false;
        }

        this.specialAcceptanceObj = saObj;
    }

    handleOnChangeIncepDate(event){
        this.specialAcceptanceObj['SpaInceptionDate__c'] = event.detail.value;
        let SpaInceptionDate__c = event.detail.value;
        let SpaExpirationDate__c = this.specialAcceptanceObj.SpaExpirationDate__c;

        if(SpaInceptionDate__c != null && SpaInceptionDate__c != undefined && this.specialAcceptanceObj.SpaExpirationDate__c != undefined){
            let ltaInceptionDate = new Date(SpaInceptionDate__c+'T00:00');
            let utcLtaInceptionDate = Date.UTC(ltaInceptionDate.getFullYear(), ltaInceptionDate.getMonth(), ltaInceptionDate.getDate());
            let ltaExpiryDate = new Date(SpaExpirationDate__c+'T00:00');
            let utcLTAExpiryDate = Date.UTC(ltaExpiryDate.getFullYear(), ltaExpiryDate.getMonth(), ltaExpiryDate.getDate());
            let numDaysLTAExpiryDate = Math.floor((utcLTAExpiryDate - utcLtaInceptionDate) / (1000 * 60 * 60 * 24)) + 1;
            this.specialAcceptanceObj['SpaDurationDays__c'] = numDaysLTAExpiryDate;
        }
        else{
            this.specialAcceptanceObj['SpaDurationDays__c'] = 0;
        }
    }

    handleOnChangeExpDate(event){
        this.specialAcceptanceObj['SpaExpirationDate__c'] = event.detail.value;
        let SpaExpirationDate__c = event.detail.value;
        let SpaInceptionDate__c = this.specialAcceptanceObj.SpaInceptionDate__c;
        
        if(SpaExpirationDate__c != null && SpaExpirationDate__c != undefined && this.specialAcceptanceObj.SpaInceptionDate__c != undefined){
            let ltaInceptionDate = new Date(SpaInceptionDate__c+'T00:00');
            let utcLtaInceptionDate = Date.UTC(ltaInceptionDate.getFullYear(), ltaInceptionDate.getMonth(), ltaInceptionDate.getDate());
            let ltaExpiryDate = new Date(SpaExpirationDate__c+'T00:00');
            let utcLTAExpiryDate = Date.UTC(ltaExpiryDate.getFullYear(), ltaExpiryDate.getMonth(), ltaExpiryDate.getDate());
            let numDaysLTAExpiryDate = Math.floor((utcLTAExpiryDate - utcLtaInceptionDate) / (1000 * 60 * 60 * 24)) + 1;
            this.specialAcceptanceObj['SpaDurationDays__c'] = numDaysLTAExpiryDate;
        }
        else{
            this.specialAcceptanceObj['SpaDurationDays__c'] = 0;
        }
    }

    handleSaveSubmitSA(event){
        this.isTotalAxaShareInvalid = false ;//MRA W-1251 13/09/2022
        this.spinnerSaveSpecialAcceptance = true;
        this.btnNameclick = event.currentTarget.name;
        this.errorclass = '';
        //MRA W-1251 13/09/2022 : START
        let totalAxaShareInput = this.template.querySelector('.TotalAxaShare__c');
        let totalExposureAxaShareInput = this.template.querySelector('.TotalExposureAxaShare__c');
        if(this.displayAutoFacFormVal){
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

            if(this.isModalRenew == true){
                specialAcceptanceRecord['Program__c'] = this.renewedProgramId;
            }
            else{
                specialAcceptanceRecord['Program__c'] = this.selectedProgram;
            }

            specialAcceptanceRecord['PrincipalCedingCompany__c'] = this.valuePrincipalCedComp;
            specialAcceptanceRecord['UnderWrittingYear__c'] = this.valueUWYear;
            specialAcceptanceRecord['PortalStatus__c'] = 'Draft';
            specialAcceptanceRecord['RecordTypeId'] = this.typeOfSARecordTypeId;
            specialAcceptanceRecord['Limit__c'] =  this.valLimit; // RRA - 1240 - 16/08/2022
            specialAcceptanceRecord['LimitUnlimited__c'] = this.valUnlimitChk; // RRA - 1240 - 16/08/2022
            specialAcceptanceRecord['ExposureBasedOn__c'] = this.valExposureBasedOn; // RRA - 1240 - 16/08/2022

            if(this.actionBtnName == 'Renew'){
                specialAcceptanceRecord['RenewedFromSpecialAcceptance__c'] = this.selectedSpecialAcceptance;
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
            if(this.displayAutoFacFormVal == true){
                specialAcceptanceRecord['NaceCode__c'] = this.selectedNaceText;
                specialAcceptanceRecord['OriginalInsuredActivityAutofac__c'] = this.valOriginalInsuredActAutofac;
            }
            if(this.disableAllFields == true && this.isModalEdit == true){
                this.specialAcceptanceRecordToSave = specialAcceptanceRecord;
                if(this.btnNameclick == 'Submit'){
                    this.spinnerSaveSpecialAcceptance = false;
                    this.isSubmit = true;
                }
                else if(this.btnNameclick == 'Save'){
                    this.saveEditSpecialAcceptanceRecord();
                }
            }
            else if(this.btnNameclick == 'LoadPlacementTable' && (specialAcceptanceRecord.Type__c == null || specialAcceptanceRecord.Type__c == '' || specialAcceptanceRecord.Type__c == undefined)){
                this.spinnerSaveSpecialAcceptance = false;
                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.saErrorMsg, variant: 'error' }),);
            }
            else if(specialAcceptanceRecord.OriginalUwYear__c != null && specialAcceptanceRecord.OriginalUwYear__c != '' && specialAcceptanceRecord.OriginalUwYear__c != undefined &&  specialAcceptanceRecord.OriginalUwYear__c.length != 4){
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
            }
            else if ((specialAcceptanceRecord.Limit__c == null || specialAcceptanceRecord.Limit__c == '' || isNaN(specialAcceptanceRecord.Limit__c)) &&  specialAcceptanceRecord.LimitUnlimited__c == false && (specialAcceptanceRecord.LimitType__c != '1' && specialAcceptanceRecord.ExposureBasedOn__c == undefined)){ 
                this.spinnerSaveSpecialAcceptance = false;
                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.LimitUnlimitedErrMsg, variant: 'error' }),);
            }else if ((specialAcceptanceRecord.Limit__c == null || specialAcceptanceRecord.Limit__c == '' || isNaN(specialAcceptanceRecord.Limit__c)) &&  specialAcceptanceRecord.LimitUnlimited__c == false && (specialAcceptanceRecord.ExposureBasedOn__c != 'Sums Insured' && specialAcceptanceRecord.LimitType__c == undefined)){ 
                this.spinnerSaveSpecialAcceptance = false;
                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.LimitUnlimitedErrMsg, variant: 'error' }),);
            }
            else if(this.isModalCopy == true){
                this.specialAcceptanceRecordToSave = specialAcceptanceRecord;
                if(this.isUserCe == true){
                    this.saveCopySpecialAcceptanceRecord();
                }
                else{
                    if(this.btnNameclick == 'Submit'){
                        this.spinnerSaveSpecialAcceptance = false;
                        this.isSubmit = true;
                    }
                    else if(this.btnNameclick == 'Save'){
                        this.saveCopySpecialAcceptanceRecord();
                    }
                }
            }
            else if(this.isModalRenew == true){
                this.specialAcceptanceRecordToSave = specialAcceptanceRecord;
                if(this.isUserCe == true){
                    this.saveRenewSpecialAcceptanceRecord();
                }
                else{
                    if(this.btnNameclick == 'Submit'){
                        this.spinnerSaveSpecialAcceptance = false;
                        this.isSubmit = true;
                    }
                    else if(this.btnNameclick == 'Save'){
                        this.saveRenewSpecialAcceptanceRecord();
                    }
                }
            }
            else if(this.isModalEdit == true){
                this.specialAcceptanceRecordToSave = specialAcceptanceRecord;
                if(this.btnNameclick == 'Submit'){
                    this.spinnerSaveSpecialAcceptance = false;
                    this.isSubmit = true;
                }
                else if(this.btnNameclick == 'Save'){
                    this.saveEditSpecialAcceptanceRecord();
                }
            }
            else if(this.isCELoadSEReq == true){
                specialAcceptanceRecord.PortalStatus__c = null;
                this.specialAcceptanceRecordToSave = specialAcceptanceRecord;

                if(this.btnNameclick == 'send' || this.btnNameclick == 'update' || this.btnNameclick == 'remind' || this.btnNameclick == 'notify' || this.btnNameclick == 'informCedingCompany'){
                    this.spinnerSaveSpecialAcceptance = false;
                    this.handleSendUpdateRemindBtn();
                }
                else if(this.btnNameclick == 'LoadPlacementTable'){
                    this.spinnerSaveSpecialAcceptance = false;
                    this.isAskToLoadPlacement = true;
                    let typeVal = '';

                    if(this.specialAcceptanceRecordToSave.Type__c == '1'){
                        typeVal = 'Declaration';
                    }
                    else if(this.specialAcceptanceRecordToSave.Type__c == '2'){
                        typeVal = 'Submission';
                    }
                    this.askToLoadPlacementMsg = 'You are about to Load the Placement Table with a '+ typeVal +' Special Acceptance. It will not be possible to modify the value after the Placement Table is generated';
                }
                else{
                    this.saveEditSpecialAcceptanceRecord();
                }
            }
        }
        else if(this.btnNameclick == 'LoadPlacementTable' && (this.specialAcceptanceObj.Type__c == null || this.specialAcceptanceObj.Type__c == '' || this.specialAcceptanceObj.Type__c == undefined)){
            this.spinnerSaveSpecialAcceptance = false;
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.saErrorMsg, variant: 'error' }),);
        }
        else{
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.RequiredFieldMissingSA, variant: 'error'}), );
            this.spinnerSaveSpecialAcceptance = false;
            this.isAskToLoadPlacement = false;
        }
    }

    handleCloseSubmitModal(event){
        this.isSubmit = false;
    }

    handleAcceptSubmit(event){
        this.isSubmit = false;
        this.spinnerSaveSpecialAcceptance = true;

        checkIfSAEmailIsFound({pccId : this.valuePrincipalCedComp})
        .then(result => {
            let saEmailNull = result.saEmailNull;

            if(saEmailNull == true){
                this.spinnerSaveSpecialAcceptance = false;
                this.dispatchEvent(new ShowToastEvent({title: 'Error', message:this.label.EmailNotFound, variant: 'error'}), );
            }
            else if(saEmailNull == false){
                if(this.isModalCopy == true){
                    this.saveCopySpecialAcceptanceRecord();
                }
                else if(this.isModalRenew == true){
                    this.saveRenewSpecialAcceptanceRecord();
                }
                else if(this.isModalEdit == true){
                    this.saveEditSpecialAcceptanceRecord();
                }
            }
        })
        .catch(error => {
            this.spinnerSaveSpecialAcceptance = false;
            this.dispatchEvent(new ShowToastEvent({title: 'ERROR', message: this.label.errorMsg, variant: 'error'}),);
        });
    }

    saveEditSpecialAcceptanceRecord(){
        let SARecord = this.specialAcceptanceRecordToSave;
        let lstAllDocument = [];
        for(let i = 0; i < this.lstDocuments.length; i++){
            let doc = {...this.lstDocuments[i]};
            lstAllDocument.push(doc);
        }

        SARecord['Id'] = this.selectedSpecialAcceptance;
        let lstSaRequest = []; //MRA W-1281/1290 ( regression 1123) 
        if(this.dataSaRequest != undefined){
            for(let i = 0; i < this.dataSaRequest.length; i++){
                let req = {...this.dataSaRequest[i]};
                lstSaRequest.push(req);
            }
        }
        if(this.disableAllFields == true){
            let bindSaRecord = {};
            bindSaRecord['Id'] = this.selectedSpecialAcceptance;
            bindSaRecord['Bound__c'] =  this.specialAcceptanceRecordToSave.Bound__c;
            SARecord = {...bindSaRecord};
        }        
        saveEditSpecialAcceptanceRecord({ specialAcceptanceObj : SARecord, lstDocumentToUpdate: lstAllDocument, lstDeletedDocument : this.lstSelectedDeleteDocumentId, actionBtnClick : this.btnNameclick, lstRequest: lstSaRequest, isCE : this.isUserCe})
        .then(result => {
            if(result.hasOwnProperty('Error') && result.Error){
                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: result.Error, variant: 'error' }),);
                this.spinnerSaveSpecialAcceptance = false;
            }
            else{
                if(this.isCELoadSEReq == true){
                    if(this.btnNameclick == 'Save'){
                        this.dispatchEvent(new ShowToastEvent({title: 'Success', message: this.label.SAUpdatedSuccessfully, variant: 'success' }),);
                        this.spinnerSaveSpecialAcceptance = false;

                        let urlPage = '../n/SpecialAcceptance?s__id='+this.valueUWYear+'-'+this.valuePrincipalCedComp+'-'+this.selectedProgram;
                        this[NavigationMixin.Navigate]({
                            type: 'standard__webPage',
                            attributes: {url: urlPage, target: '_self'}
                        });
                    }
                    else if(this.btnNameclick == 'send' || this.btnNameclick == 'update' || this.btnNameclick == 'LoadPlacementTable'){
                        this.spinnerSaveSpecialAcceptance = false;
                        this.getSADetail();
                    }
                }
                else{
                    this.dispatchEvent(new ShowToastEvent({title: 'Success', message: this.label.SAUpdatedSuccessfully, variant: 'success' }),);
                    this.spinnerSaveSpecialAcceptance = false;

                    this[NavigationMixin.Navigate]({
                        type: 'standard__webPage',
                        attributes: {
                            url: '/cedingPortal/s/?s__id='+this.valueUWYear+'-'+this.valuePrincipalCedComp+'-'+this.progIdOfSelectedSA
                        }
                    });
                }
            }
        })
        .catch(error => {
            this.dispatchEvent(new ShowToastEvent({title: 'ERROR', message: this.label.errorMsg, variant: 'error'}),);
            this.spinnerSaveSpecialAcceptance = false;
        });
    }

    saveCopySpecialAcceptanceRecord(){
        let SARecord = this.specialAcceptanceRecordToSave;
        SARecord['Reference__c'] = this.referenceVal;
        SARecord['RenewedFromSpecialAcceptance__c'] = null;
        SARecord['Active__c'] = 'Active';

        if(this.isUserCe == true){
            SARecord['InternalStatus__c'] = 'Setup';
            SARecord['PortalStatus__c'] = null;
        }

        saveCopySpecialAcceptanceRecord({ specialAcceptanceObj : SARecord,  programIdOfSelectedSA: this.progIdOfSelectedSA, copyDoc : this.copyDoc, selectedSpecAccId : this.selectedSAId, actionBtnClick : this.btnNameclick })
        .then(result => {
            if(result.hasOwnProperty('Error') && result.Error){
                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: result.Error, variant: 'error' }),);
                this.spinnerSaveSpecialAcceptance = false;
            }
            else{
                this.dispatchEvent(new ShowToastEvent({title: 'Success', message: this.label.SACreatedSuccessMsg, variant: 'success' }),);
                this.spinnerSaveSpecialAcceptance = false;
                fireEvent(this.pageRef, 'closeCopyRenewSAModal', true);
            }
        })
        .catch(error => {
            this.dispatchEvent(new ShowToastEvent({title: 'ERROR', message: this.label.errorMsg, variant: 'error'}),);
            this.spinnerSaveSpecialAcceptance = false;
        });
    }

    saveRenewSpecialAcceptanceRecord(){
        let lstNewRenewDocument = [];
        let lstExistingDocumentToCreate = [];
        let SARecord = this.specialAcceptanceRecordToSave;

        if(this.isUserCe == true){
            SARecord['InternalStatus__c'] = 'Setup';
            SARecord['PortalStatus__c'] = null;
        }

        for(let i = 0; i < this.lstDocuments.length; i++){
            let doc = {...this.lstDocuments[i]};
            if(doc.NewRenewUpload == true){
                //to update content version with new nature value
                lstNewRenewDocument.push(doc);
            }
            else if(doc.NewRenewUpload == false){
                //to copy existing content version with new nature value
                lstExistingDocumentToCreate.push(doc);
            }
        }
        
        saveRenewSpecialAcceptanceRecord({specialAcceptanceObj : SARecord,  programIdOfSelectedSA: this.progIdOfSelectedSA, lstDocumentToUpdate: lstNewRenewDocument, lstDeletedDocument : this.lstSelectedDeleteDocumentId, lstDocumentToInsert : lstExistingDocumentToCreate, actionBtnClick : this.btnNameclick})
        .then(result => {
            if(result.hasOwnProperty('Error') && result.Error){
                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: result.Error, variant: 'error' }),);
                this.spinnerSaveSpecialAcceptance = false;
            }
            else{
                this.dispatchEvent(new ShowToastEvent({title: 'Success', message: this.label.SARenewedSuccessfully, variant: 'success' }),);
                this.spinnerSaveSpecialAcceptance = false;

                if(this.isUserCe == true){
                    let urlPage = '../n/SpecialAcceptance?s__id='+this.valueUWYear+'-'+this.valuePrincipalCedComp+'-'+this.selectedProgram;
                    this[NavigationMixin.Navigate]({
                        type: 'standard__webPage',
                        attributes: {url: urlPage, target: '_self'}
                    });
                }
                else{
                    this[NavigationMixin.Navigate]({
                        type: 'standard__webPage',
                        attributes: {
                            url: '/cedingPortal/s/?s__id='+this.valueUWYear+'-'+this.valuePrincipalCedComp+'-'+this.selectedProgram
                        }
                    });
                }
            }
        })
        .catch(error => {
            this.dispatchEvent(new ShowToastEvent({title: 'ERROR', message: this.label.errorMsg, variant: 'error'}),);
            this.spinnerSaveSpecialAcceptance = false;
        });
    }

    handleOnChangeProgramToCopy(event){
        this.selectedProgram = event.detail.value;
        this.getProgramDetail(this.selectedProgram);
    }

    handleLoadPlacementTable(event){
        this.isAskToLoadPlacement = false;
        this.spinnerSaveSpecialAcceptance = true;
        let saObj = {...this.specialAcceptanceRecordToSave};
        saObj['Id'] = this.selectedSpecialAcceptance;

        loadPlacementTable({ specialAcceptanceObj : saObj})
        .then(result => {
            if(result.hasOwnProperty('Error') && result.Error){
                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: result.Error, variant: 'error' }),);
                this.spinnerSaveSpecialAcceptance = false;
            }
            else{
                this.dispatchEvent(new ShowToastEvent({title: 'Success', message: this.label.PlacementTableLoadedSuccessfully, variant: 'success' }),);
                this.getSADetail();
                this.saveEditSpecialAcceptanceRecord();
            }
        })
        .catch(error => {
            this.dispatchEvent(new ShowToastEvent({title: 'ERROR', message: this.label.errorMsg, variant: 'error'}),);
            this.spinnerSaveSpecialAcceptance = false;
        });
    }

    handleCloseLoadPlacementModal(event){
        this.saveEditSpecialAcceptanceRecord();
        this.isAskToLoadPlacement = false;
    }

    handleOnchangeCopyDocument(event){
       this.copyDoc = event.currentTarget.checked;
    }
    handleSelectAll(event){
        let HeaderCheckbox = this.template.querySelectorAll('[data-id="reqAllCheckbox"]');
        let checkboxes = this.template.querySelectorAll('[data-id="reqCheckbox"]');
        for (let i = 0; i < checkboxes.length; i++){
            checkboxes[i].checked = HeaderCheckbox[0].checked;
            var event = new Event('change');
            checkboxes[i].dispatchEvent(event);
        }        
    }

    handleChangeReqValue(event){
        let idVal = event.currentTarget.id;
        let reqIdVal = idVal.split('-')[0];
        let nameVal = event.currentTarget.name;
        let lstUpdatedReq = [];

        for(let i = 0; i < this.dataSaRequest.length; i++){
            let req = this.dataSaRequest[i];

            if(this.dataSaRequest[i].Id == reqIdVal){
                if(nameVal == 'reqCheckbox'){
                    req.Checked = event.currentTarget.checked;
                }
                else if(nameVal == 'SaType'){
                    req.SA_Type__c = event.currentTarget.value;

                    if(this.isDeclaration == true){
                        let todayDate = new Date(); 
                        let date = todayDate.getDate();
                        let month = todayDate.getMonth() + 1;
                        let year = todayDate.getFullYear();

                        if(date.toString().length == 1){
                            date = '0' + date;
                        }

                        if(month.toString().length == 1){
                            month = '0' + month;
                        }

                        if(req.SA_Type__c == 'Follower'){
                            req.SA_Request_Status__c = 'Setup';
                            req.SpecialAcceptanceAnswer__c = null;
                            req.LastSentDate__c = null;
                            req.ExpectedResponseDate__c = null;
                            req.ResponseDate__c = null;
                        }
                        else if(req.SA_Type__c == 'Follower as Leader'){
                            req.SA_Request_Status__c = 'Agreed';
                            req.SpecialAcceptanceAnswer__c = 'Agree';
                            req.LastSentDate__c = year + '-' + month + '-' + date ;
                            req.ExpectedResponseDate__c = year + '-' + month + '-' + date ;
                            req.ResponseDate__c = year + '-' + month + '-' + date ;
                        }              
                    }
                }
                else if(nameVal == 'BrokerStatus'){req.BrokerStatus__c = event.currentTarget.value;}
                else if(nameVal == 'lastSentDate'){req.LastSentDate__c = event.currentTarget.value;}
                else if(nameVal == 'expectedResponseDate'){ req.ExpectedResponseDate__c = event.currentTarget.value;}
                else if(nameVal == 'responseDate'){ req.ResponseDate__c = event.currentTarget.value;}
            }
            lstUpdatedReq.push(req);
        }
        this.dataSaRequest = lstUpdatedReq;
    }

    handleSendUpdateRemindBtn(){
        let selectedRequests = [];
        let saRequestSetup = []; 
        let saRequestSentTimeoutMoreInfoRequired = []; 
        let saRequestSent = []; 
        let saRequestFollower = []; 
        let saRequestRefused = false; 
        let saRequestAllAgreed = true; 

        for(let i = 0; i < this.dataSaRequest.length; i++){
            if(this.dataSaRequest[i].Checked == true){
                selectedRequests.push(this.dataSaRequest[i]);
                if(this.dataSaRequest[i].SA_Request_Status__c == 'Setup' && this.dataSaRequest[i].SA_Type__c != 'Follower'){saRequestSetup.push(this.dataSaRequest[i]);}
                if((this.dataSaRequest[i].SA_Request_Status__c == 'Sent' || this.dataSaRequest[i].SA_Request_Status__c == 'Timeout' || this.dataSaRequest[i].SA_Request_Status__c == 'More Infor Required') && (this.dataSaRequest[i].SA_Type__c != 'Follower')){
                    saRequestSentTimeoutMoreInfoRequired.push(this.dataSaRequest[i]);
                }
                if(this.dataSaRequest[i].SA_Request_Status__c == 'Sent' && this.dataSaRequest[i].SA_Type__c != 'Follower'){saRequestSent.push(this.dataSaRequest[i]);}
                if(this.dataSaRequest[i].SA_Type__c == 'Follower'){saRequestFollower.push(this.dataSaRequest[i]);}
            }
            
            if(this.dataSaRequest[i].SA_Type__c != 'Follower' && this.dataSaRequest[i].SA_Request_Status__c != 'Agreed'){saRequestAllAgreed = false; }
            if(this.dataSaRequest[i].SA_Type__c != 'Follower' && this.dataSaRequest[i].SA_Request_Status__c == 'Refused'){saRequestRefused = true;}
        }

        if(this.btnNameclick != 'informCedingCompany' && selectedRequests.length == 0){
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: 'No Special Acceptance Requests selected.', variant: 'error',}), );
        }
        else{
            if(this.btnNameclick != 'notify' && this.btnNameclick != 'informCedingCompany' && this.specialAcceptanceObj.Type__c != '2'){
                let msgError = "You can't " + this.btnNameclick + " the Special Acceptance Requests because the Special Acceptance Type is not 'Submission.'";
                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: msgError, variant: 'error',}), );
            }
            else if(this.btnNameclick == 'send' && saRequestSetup.length == 0){
                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: 'SA request(s) can only be sent to Leaders, Pools and Followers as leader with SA request Status Setup.', variant: 'error',}), );
            }
            else if(this.btnNameclick == 'update' && saRequestSentTimeoutMoreInfoRequired.length == 0){
                // MBE - 09/02/2021 : W-0878 -> on ne peut plus faire ni de send ni d’update. Il faudrait pouvoir faire un update lorsqu’une request a pour status = More info Required.
                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: 'SA request(s) can only be updated for Leaders, Pools and Followers as leader with SA request Status Sent or Timeout or More Infor Required.', variant: 'error',}), );
            }
            else if(this.btnNameclick == 'remind' && saRequestSent.length == 0){
                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: 'SA request(s) can only be reminded for Leaders, Pools and Followers as leader with SA request Status Sent.', variant: 'error',}), );
            }
            else if(this.btnNameclick == 'notify' && saRequestAllAgreed == false){
                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: 'SA request(s) can only be notified for Followers when all the SA requests of Leaders, Pools and Followers as leader have status "agreed".', variant: 'error',}), );
            }
            else if(this.btnNameclick == 'notify' && saRequestFollower.length == 0){
                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: 'SA request(s) can only be notified for Followers.', variant: 'error',}), );
            }
            else if(this.btnNameclick == 'informCedingCompany' && (saRequestRefused == false && saRequestAllAgreed == false)){
                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: 'Inform ceding company button is available if at least one SAR of Leader, Pool, follower as leader have status "refused" or if all SAR of Leader, Pool, follower as leader have status "agreed".', variant: 'error',}), );
            }
            else{
                if(this.btnNameclick == 'send'){
                    this.selectedSaRequests = saRequestSetup;
                    this.titlePopUp = 'Send Special Acceptance Request(s)';
                }
                else if(this.btnNameclick == 'update'){
                    this.selectedSaRequests = saRequestSentTimeoutMoreInfoRequired;
                    this.titlePopUp = 'Update Special Acceptance Request(s)';
                }
                else if(this.btnNameclick == 'remind'){
                    this.selectedSaRequests = saRequestSent;
                    this.titlePopUp = 'Remind Special Acceptance Request(s)';
                }
                else if(this.btnNameclick == 'notify'){
                    this.selectedSaRequests = saRequestFollower;
                    this.titlePopUp = 'Notify Special Acceptance Request(s)';
                }
                else if(this.btnNameclick == 'informCedingCompany'){
                    this.selectedSaRequests = this.dataSaRequest;
                    this.informCedComAgreed = saRequestAllAgreed;
                    this.informCedComRefused = saRequestRefused;
                    this.titlePopUp = 'Inform Ceding Company';
                    this.specialAcceptanceRecordToSave['BindRemainingDays__c'] = this.specialAcceptanceObj.BindRemainingDays__c;
                    this.specialAcceptanceRecordToSave['SentAgreFromSpecialAcceptance__c'] = this.specialAcceptanceObj.SentAgreFromSpecialAcceptance__c;
                }
                let doc = [];
                for(let i = 0; i < this.lstDocuments.length; i++){
                    if(this.lstDocuments[i].Nature__c == 'Public'){
                        doc.push({...this.lstDocuments[i]});
                    }
                }

                this.lstPublicDoc = doc;
                this.isSendModalOpen = true;
                this.saveEditSpecialAcceptanceRecord();
            }
        }
    }

    handleCloseSendModal(event){this.isSendModalOpen = false;}
    handleOnclickDeleteSAR(event){this.isDelete = true;}
    handleCloseDeleteModal(event){ this.isDelete = false;}
    handleAcceptDelete(event){
        this.isDelete = false;
        this.spinnerSaveSpecialAcceptance = true;

        deletePlacementTable({specialAcceptanceId : this.selectedSpecialAcceptance})
        .then(result => {
            this.dispatchEvent(new ShowToastEvent({title: 'Success', message: this.label.PlacementTableDeletedSuccessfully, variant: 'success' }),);
            this.getSADetail();
            this.spinnerSaveSpecialAcceptance = false;
        })
        .catch(error => {
            this.dispatchEvent(new ShowToastEvent({title: 'ERROR', message: this.label.errorMsg, variant: 'error'}),);
        });
    }

    sortData(lstData, fieldName, fieldName2, sortDirection) {
        let sortResult = Object.assign([], lstData);

        lstData = sortResult.sort(function(a,b){
            if(a[fieldName] < b[fieldName])return sortDirection === 'asc' ? -1 : 1;
            else if(a[fieldName] > b[fieldName])return sortDirection === 'asc' ? 1 : -1;
            else {
                if(a[fieldName2] < b[fieldName2])return sortDirection === 'asc' ? -1 : 1;
                else if(a[fieldName2] > b[fieldName2])return sortDirection === 'asc' ? 1 : -1;
                else return 0;
            }
        })

        return lstData;
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
            if(currentText.length > 0 && result.length == 0) {this.messageFlag = true;}
            else {this.messageFlag = false;}

            if(this.selectRecordId != null && this.selectRecordId.length > 0) {
                this.iconFlag = false;
                this.clearIconFlag = true;
            }
            else {this.iconFlag = true; this.clearIconFlag = false;
            }
            this.valOriginalInsuredActAutofac = null;
        })
        .catch(error => {this.error = error;});
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