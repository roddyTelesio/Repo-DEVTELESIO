import {LightningElement, track, wire, api} from 'lwc';
import getPrograms from '@salesforce/apex/LWC01_Programs.getPrograms';
import checkActivePCC from '@salesforce/apex/LWC01_Programs.checkActivePCC';
import getAcc from '@salesforce/apex/LWC01_WorkingScope.getPrincipalCedingAcc';
import getCoveredCedingCompanies from '@salesforce/apex/LWC01_Programs.getCoveredCedingCompanies';
import changeStatus from '@salesforce/apex/LWC01_HomePageActions.reactivateDeactivate';
import checkRequestExist from '@salesforce/apex/LWC01_HomePageActions.checkRequestExist'; //RRA - ticket 585 - 22032023
import deletePrograms from '@salesforce/apex/LWC01_HomePageActions.deleteRecords';
import updateRetainToLeadDeactivation from '@salesforce/apex/LWC01_Sections.updateRetainToLeadDeactivation'; //RRA - ticket 585 - 22032023
import {refreshApex} from '@salesforce/apex';
import {registerListener, unregisterAllListeners, fireEvent} from 'c/pubSub';
import {NavigationMixin, CurrentPageReference} from 'lightning/navigation';
import {getPicklistValues} from 'lightning/uiObjectInfoApi';
import {getObjectInfo} from 'lightning/uiObjectInfoApi';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import PROGRAM_OBJECT from '@salesforce/schema/Program__c';
import UWYEAR_FIELD from '@salesforce/schema/Program__c.UwYear__c';
import MACROLOB_FIELD from '@salesforce/schema/Program__c.Macro_L_O_B__c';
import LTA_FIELD from '@salesforce/schema/Program__c.LTA__c';
import STLT_FIELD from '@salesforce/schema/Program__c.STLT__c';
import TACITRENEWAL_FIELD from '@salesforce/schema/Program__c.TacitRenewal__c';
import Id from '@salesforce/user/Id';
import checkForRenewProgram from '@salesforce/apex/LWC01_Programs.checkForRenewProgram';

//import custom labels
import Programs from '@salesforce/label/c.Programs';
import NewProgram from '@salesforce/label/c.NewProgram';
import Reactivate from '@salesforce/label/c.Reactivate';
import Deactivate from '@salesforce/label/c.Deactivate';
import Delete from '@salesforce/label/c.Delete';
import CheckData from '@salesforce/label/c.CheckData';
import Copy from '@salesforce/label/c.Copy';
import Renew from '@salesforce/label/c.Renew';
import Close from '@salesforce/label/c.Close';
import Accept from '@salesforce/label/c.Accept';
import Cancel from '@salesforce/label/c.Cancel';
import LTA_TR_Identical_Review from '@salesforce/label/c.LTA_TR_Identical_Review';
import LTA_TR_Renegotiation from '@salesforce/label/c.LTA_TR_Renegotiation';
import Name from '@salesforce/label/c.Name';
import MacroLOB from '@salesforce/label/c.MacroLOB';
import Status from '@salesforce/label/c.Status';
import STLT from '@salesforce/label/c.STLT';
import InceptionDate from '@salesforce/label/c.InceptionDate';
import ExpiryDate from '@salesforce/label/c.ExpiryDate';
import TR from '@salesforce/label/c.TR';
import LTA from '@salesforce/label/c.LTA';
import LTA_InceptionDate from '@salesforce/label/c.LTA_InceptionDate';
import LTA_ExpiryDate from '@salesforce/label/c.LTA_ExpiryDate';
import Actions from '@salesforce/label/c.Actions';
import AskToDeleteProgram from '@salesforce/label/c.AskToDeleteProgram';
import AskToReactivateProgram from '@salesforce/label/c.AskToReactivateProgram';
import AskToDeactivateProgram from '@salesforce/label/c.AskToDeactivateProgram';
import PCCInactiveCopyNotAllowed from '@salesforce/label/c.PCCInactiveCopyNotAllowed';
import SomeLeadpresent from '@salesforce/label/c.SomeLeadpresent'; 
import SomeQuoteOrPlacementpresent from '@salesforce/label/c.SomeQuoteOrPlacementpresent'; 
import SomeSigningpresent from '@salesforce/label/c.SomeSigningpresent';
import errorMsg from '@salesforce/label/c.errorMsg';

const actions = [
    { label: Copy, name: 'copy'},
    { label: Renew, name: 'renew'}
];

const columns = [
    { label: 'Name', fieldName: 'nameUrl', type: 'url', typeAttributes: {label: {fieldName: 'Name'}, target: '_self'} },
    { label: MacroLOB, fieldName: 'Macro_L_O_B__c' },
    { label: Status, fieldName: 'Status__c' },
    { label: STLT, fieldName: 'STLT__c' },
    { label: InceptionDate, fieldName: 'InceptionDate__c'},
    { label: ExpiryDate, fieldName: 'Expirydate__c'},
    { label: TR, fieldName: 'TacitRenewal__c'},
    { label: LTA, fieldName: 'LTA__c'},
    { label: LTA_InceptionDate, fieldName: 'LTAInceptionDate__c'},
    { label: LTA_ExpiryDate, fieldName: 'LTAExpiryDate__c'},
    { label: Actions, type: 'action', fixedWidth: 70, typeAttributes: {rowActions: actions, menuAlignment:'auto'}}
];

export default class LWC01_Programs extends NavigationMixin(LightningElement) {
    label = {
        Programs,
        NewProgram,
        Reactivate,
        Deactivate,
        Delete,
        CheckData,
        Copy,
        Renew,
        LTA_TR_Identical_Review,
        LTA_TR_Renegotiation,
        Name,
        MacroLOB,
        Status,
        STLT,
        InceptionDate,
        ExpiryDate,
        TR,
        LTA,
        LTA_InceptionDate,
        LTA_ExpiryDate,
        Close,
        Accept,
        Cancel,
        AskToDeleteProgram,
        AskToReactivateProgram,
        AskToDeactivateProgram,
        PCCInactiveCopyNotAllowed,
        errorMsg,
        SomeLeadpresent,
        SomeQuoteOrPlacementpresent,
        SomeSigningpresent
    };

    error;
    wiredPrograms;
    wiredActivePCC;
    @api valueUWYear;
    @api valuePrincipalCedComp;
    @api valueUWYearOnProgram;
    @api valuePrincipalCedCompOnProgram;
    @track dataCoveredCedingCompany = [];
    @track selectedRowProgram = [];
    data;
    columns = columns;
    titleCountProgram = this.label.Programs;
    isOpenModal = false;
    isOpenConfirmation = false;
    isDeleteOpen = false;
    openDelModal = true;
    macroLOBValues;
    stltValues;
    ltaValues;
    tacitRenewalValues;
    statusModalTitle;
    status;
    statusFunction;
    isCopy = false;
    isRenew = false;
    isRenewOpenModal = false;
    delMsgTitle;
    delMessage;
    spinner = false;
    displayErrorMsg = false;
    displayPopOptionBC = false;
    displayTreatySection = false;
    errorMessage;
    IdenticalRenewValue = false;
    RenegotiationRenewValue = false;
    typeOfRenewValue = false;
    titleTypeOfRenew = 'Renew Program';
    informRenewProgramMsg = '';
    informForRenewProgram = false;
    hideButtons = false;
    setUWYear = new Set();
    mapMacroLOb = new Map();
    mapLTA = new Map();
    mapSTLT = new Map();
    mapTacitRenewal = new Map();
    isChangePCC = false;
    isChangeUWY = false;
    isCurrSession = false;
    //AMI 08/06/22 W:0874
    //private attribute to determine next screen when lta regociation == true
    isLTARegociation = false;

    //AMI 10/06/22 W:0771
    //private property to determine when to show confirmation model after successfull program renew
    showRenewConfirmationModel = false;

    //AMI 10/06/22 W:0771
    //private property to store newly created program
    renewedProgram;

    @wire(getObjectInfo, { objectApiName: PROGRAM_OBJECT })
    objectInfo;

    @wire(CurrentPageReference) pageRef;
    connectedCallback(){
        registerListener('year', this.getVal, this);
        registerListener('comp', this.getComp, this);
        registerListener('closeProgramModal', this.setIsOpenModalFalse, this);
        registerListener('openProgramModal', this.setIsOpenModalTrue, this);
        registerListener('refreshProgram', this.refreshData, this);
        registerListener('closeRenewProgramModal', this.closeRenewProgramModal, this);
        
         //RRA - ticket 0050 - 14122022 - Retrieve all events (ppcc / undWrtiYear / isChange PCC / is Change / UWY / CurrentSession)
        //RRA - ticcket 1560- 23082023
        registerListener('pccOnProgram', this.getPccOnProgram, this);
        registerListener('yearOnProgram', this.getYearOnProgram, this);
        registerListener('isOnChangePcc', this.getOnChangePcc, this);
        registerListener('isOnChangeUWY', this.getOnChangeUWY, this);
        registerListener('isCurrentSession', this.getCurrentSession, this);
        //registerListener('currentTreatyPlacement', this.getCurrentTreatyPlacement, this);

        
        // RRA - ticket 0050 - 14122022
        // Action clicked : TreatyPlacement to Home => Get the Session nameurl to retrieve tbe values pcc / uwy if no changes  have been made to pcc / uwy
        let sessionTreatyPlacToHome;
        let valueUWYTreatyPlacementToHome = sessionStorage.getItem('valueUWYTreatyPlacementToHome');
        let valuePCCTreatyPlacementToHome = sessionStorage.getItem('valuePCCTreatyPlacementToHome');
        let isOnChangePcc = sessionStorage.getItem('isOnChangePcc');
        let isOnChangeUWY = sessionStorage.getItem('isOnChangeUWY');
        let isTreatyPlacementPageToHome = sessionStorage.getItem('isTreatyPlacementPage');
        let currentSession = sessionStorage.getItem('nameUrl');
        let nameURLUpdated = sessionStorage.getItem('nameURLUpdated');

        console.log('isTreatyPlacementPageToHome Prog result== ' , isTreatyPlacementPageToHome); 
        console.log('valuePCCTreatyPlacementToHome Prog result== ' , valuePCCTreatyPlacementToHome);
        console.log('valueUWYTreatyPlacementToHome Prog result== ' , valueUWYTreatyPlacementToHome);
        console.log('isOnChangePcc Prog result== ' , isOnChangePcc);
        console.log('isOnChangeUWY Prog result== ' , isOnChangeUWY);
        console.log('currentSession Prog result== ' , currentSession);
        console.log('nameURLUpdated Prog result== ' , nameURLUpdated);
        
         //RRA - ticket 0050 - 10082023
        //RRA - ticket 1553 - Initialize method getPrograms 01082023
        /*if (isTreatyPlacementPageToHome == null){
            console.log('valueUWYear Prog result 11== ' , this.valueUWYear);
            console.log('valuePrincipalCedComp Prog result 11== ' , this.valuePrincipalCedComp);
            this.getPrograms(valueUWYTreatyPlacementToHome, valuePCCTreatyPlacementToHome);
        }*/
        
        //*Check if you are already in TreatyPlacement and have changed PCC or UWY
        //*If the values ​​of PCC or / and UWY have changed, the value returned by function getPrograms must be too
        if (isTreatyPlacementPageToHome == 'true' && (nameURLUpdated == 'TreatyPlacement' || nameURLUpdated == 'home')) {
            let currSess = currentSession.split('-');
            if (isOnChangePcc == 'true' && isOnChangeUWY == 'false' && valuePCCTreatyPlacementToHome != null && valueUWYTreatyPlacementToHome == null){
                console.log('is PCC Changed');
                sessionTreatyPlacToHome = '../n/TreatyPlacement?c__program=idProg-' + currSess[1] + '-' + valuePCCTreatyPlacementToHome + '-StageName-undefined-null-null-null';
            }else if (isOnChangePcc == 'false' && isOnChangeUWY == 'true' && valueUWYTreatyPlacementToHome != null && valuePCCTreatyPlacementToHome == null){
                console.log('is UWY Changed');
                sessionTreatyPlacToHome = '../n/TreatyPlacement?c__program=idProg-' + valueUWYTreatyPlacementToHome + '-' + currSess[2] + '-StageName-undefined-null-null-null';
            }else if (isOnChangePcc == 'true' && isOnChangeUWY == 'true' & valueUWYTreatyPlacementToHome != null &&  valuePCCTreatyPlacementToHome != null){
                console.log('is PCC and UWY Changed'); 
                sessionTreatyPlacToHome = '../n/TreatyPlacement?c__program=idProg-' + valueUWYTreatyPlacementToHome + '-' + valuePCCTreatyPlacementToHome + '-StageName-undefined-null-null-null';
            }else if (isOnChangePcc == 'false' && isOnChangeUWY == 'true' && valueUWYTreatyPlacementToHome != null && valuePCCTreatyPlacementToHome != null){
                console.log('valueUWYTreatyPlacementToHome != null==', valueUWYTreatyPlacementToHome); 
                sessionTreatyPlacToHome = '../n/TreatyPlacement?c__program=idProg-' + valueUWYTreatyPlacementToHome + '-' + valuePCCTreatyPlacementToHome + '-StageName-undefined-null-null-null';
            }else if (isOnChangePcc == 'true' && isOnChangeUWY == 'false' && valueUWYTreatyPlacementToHome != null && valuePCCTreatyPlacementToHome != null){
                sessionTreatyPlacToHome = '../n/TreatyPlacement?c__program=idProg-' + valueUWYTreatyPlacementToHome + '-' + valuePCCTreatyPlacementToHome + '-StageName-undefined-null-null-null';
            }else if (isOnChangePcc == 'false' && isOnChangeUWY == 'false' && valueUWYTreatyPlacementToHome != null && valuePCCTreatyPlacementToHome != null){
                sessionTreatyPlacToHome = '../n/TreatyPlacement?c__program=idProg-' + valueUWYTreatyPlacementToHome + '-' + valuePCCTreatyPlacementToHome + '-StageName-undefined-null-null-null';
            }else{
                console.log('KO'); 
            }
        }else{
            sessionTreatyPlacToHome = sessionStorage.getItem('nameUrl');
        }
        
        console.log(' sessionTreatyPlacToHome == ', sessionTreatyPlacToHome);
        console.log('this.isChangePCC== ' , this.isChangePCC);
        console.log('this.isChangeUWY== ' , this.isChangeUWY);
        
        //RRA - ticket 1560- 23082023
        if (this.valuePrincipalCedCompOnProgram == 'undefined' || this.valuePrincipalCedCompOnProgram == undefined || this.valuePrincipalCedCompOnProgram != this.valuePrincipalCedComp){
            this.valuePrincipalCedCompOnProgram = this.valuePrincipalCedComp;
        }

        if (this.valueUWYearOnProgram == 'undefined' || this.valueUWYearOnProgram == undefined || this.valueUWYearOnProgram != this.valueUWYear){
            this.valueUWYearOnProgram = this.valueUWYear;
        }
        
        console.log('this.valueUWYear== ' , this.valueUWYear);
        console.log('this.valuePrincipalCedComp== ' , this.valuePrincipalCedComp);
        
        console.log('this.valuePrincipalCedCompOnProgram== ' , this.valuePrincipalCedCompOnProgram);
        console.log('this.valueUWYearOnProgram== ' , this.valueUWYearOnProgram);
        
        
        if (this.isChangePCC && this.isChangeUWY == false){
            this.getPrograms(this.valueUWYearOnProgram, this.valuePrincipalCedCompOnProgram);
            console.log(' In the current Session, PCC has changed');
        }else if(this.isChangeUWY && this.isChangePCC == false){
            this.getPrograms(this.valueUWYearOnProgram, this.valuePrincipalCedCompOnProgram);
            console.log(' In the current Session, UnderWrittenYear has changed');
        }else {//if (this.isCurrSession && this.isChangePCC == false && this.isChangeUWY == false){
            if (sessionTreatyPlacToHome != undefined && sessionTreatyPlacToHome !='undefined'){
                console.log(' In the current Session, UnderWrittenYear and PCC has no changed');
                let splitSessionCurrent = sessionTreatyPlacToHome.split('=');
                let urlInfo = splitSessionCurrent[1];
                let splitURLInfo =  urlInfo.split('-');
                this.getPrograms(splitURLInfo[1], splitURLInfo[2]);
                this.valueUWYear = splitURLInfo[1];
                this.valuePrincipalCedComp = splitURLInfo[2];
            }
        }
    }

    // RRA - ticket 0050 - 14122022
     getPrograms (uwrYear, Pcc){
        getPrograms({ valueUWYear : uwrYear, valuePrincipalCedComp : Pcc})
        .then(result => {
             //RRA - ticket 0050 - 26082023
            //sessionStorage.setItem('valueUWYTreatyPlacementToHome', uwrYear);
            //sessionStorage.setItem('isOnChangeUWY', true);
            
            console.log('result getPrograms uwrYear == ', uwrYear);
            console.log('result getPrograms Pcc == ', Pcc);
            this.spinner = true;
            console.log('result getPrograms== ', result);
            if(result != null){
                this.titleCountProgram = this.label.Programs + ' (' + result.length + ')';
                let nameUrl;
                
                this.data = result.map(row => {
                    nameUrl = '../n/TreatyPlacement?c__program='+row.Id+'-'+row.UwYear__c+'-'+row.PrincipalCedingCompany__c+'-'+row.TECH_StageName__c +'-undefined-null-null-null';
                    return {...row , nameUrl}
                });
                sessionStorage.setItem('nameUrl', nameUrl);
            }else {
                this.data = undefined;
                }
            this.spinner = false;
        })
        .catch(error => {
            this.error = error;
        });
    }

     // RRA - ticket 0050 - 14122022
     getPccOnProgram(val){
        console.log(' getPccOnProgram ==', val);
        this.valuePrincipalCedCompOnProgram = val;
    }
     
    // RRA - ticket 0050 - 14122022
    getYearOnProgram(val){
        console.log(' getYearOnProgram ==', val);
        this.valueUWYearOnProgram = val;
    }

    //RRA - ticket 0050 - 14122022
    getCurrentSession(val){
        this.isCurrSession = val;
    }

    //RRA - ticket 0050 - 14122022
    getOnChangePcc(val){
        this.isChangePCC = val;
    }

    //RRA - ticket 0050 - 14122022
    getOnChangeUWY(val){
        this.isChangeUWY = val;
    }

    // RRA - ticket 0050 - 15122022
    /*getCurrentTreatyPlacement(val){
        this.treatyPlacementPhase = val;
    }*/

    setIsOpenModalFalse(val){
        this.isOpenModal = val;
    }

    setIsOpenModalTrue(val){
        this.isOpenModal = val;
    }

    getVal(val){
        console.log(' getVal uwy ==', val);
        this.valueUWYear = val;
    }

    getComp(val){
        this.hideButtons = false;
        this.valuePrincipalCedComp = val;
        console.log('valuePrincipalCedComp getComp== ' ,  this.valuePrincipalCedComp);
    }

    closeRenewProgramModal(val){
        this.isRenewOpenModal = false;
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: UWYEAR_FIELD})
    setPicklistOptions({error, data}) {
        if(data){
            /*let valueUWYTreatyPlacementToHome = sessionStorage.getItem('valueUWYTreatyPlacementToHome');
            let isOnChangeUWY = sessionStorage.getItem('isOnChangeUWY');
            console.log('valueUWYTreatyPlacementToHome Prog result444== ' ,  valueUWYTreatyPlacementToHome);
            console.log('isOnChangeUWY Prog result444== ' , isOnChangeUWY);

           // RRA - ticket 0050 - 24082023 
           if (isOnChangeUWY){ 
                this.valueUWYear = valueUWYTreatyPlacementToHome;
           }else{*/
            
             // RRA - ticket 0050 - 26082023      
           for(var i = 0; i < data.values.length; i++){
            this.setUWYear.add(data.values[i].value);
            }
            console.log('this.valueUWYear av== ' , this.valueUWYear);
            this.valueUWYear =  (this.valueUWYear != undefined) ? this.valueUWYear : data.values[data.values.length - 1].value;
            console.log('this.valueUWYear ap== ' , this.valueUWYear);
        }
        else{
            this.error = error;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: TACITRENEWAL_FIELD})
    setTacitRenewalOptions({error, data}) {
        if(data){
            this.tacitRenewalValues = data.values;
            this.mapTacitRenewal = new Map();
            for(var i = 0; i < data.values.length; i++){
                this.mapTacitRenewal.set(data.values[i].label, data.values[i].value);
            }
        }
        else{
            this.error = error;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: STLT_FIELD})
    setSTLTOptions({error, data}) {
        if(data){
            this.stltValues = data.values;
            this.mapSTLT = new Map();
            for(var i = 0; i < data.values.length; i++){
                this.mapSTLT.set(data.values[i].label, data.values[i].value);
            }
        }
        else{
            this.error = error;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: MACROLOB_FIELD})
    setMacroLOBOptions({error, data}) {
        if(data){
            this.macroLOBValues = data.values;
            this.mapMacroLOb = new Map();
            for(var i = 0; i < data.values.length; i++){
                this.mapMacroLOb.set(data.values[i].label, data.values[i].value);
            }
        }
        else{
            this.error = error;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: LTA_FIELD})
    setLTAOptions({error, data}) {
        if(data){
            this.ltaValues = data.values;
            this.mapLTA = new Map();
            for(var i = 0; i < data.values.length; i++){
                this.mapLTA.set(data.values[i].label, data.values[i].value);
            }
        }
        else{
            this.error = error;
        }
    }

    @wire(getAcc)
    setAccPicklistOptions({error, data}) {
        if(data){
           //this.valuePrincipalCedComp = data[0].value; //RRA - ticket 0050 - 24082023 
           this.valuePrincipalCedComp =  (this.valuePrincipalCedComp != undefined) ? this.valuePrincipalCedComp : data[0].value;//RRA - ticket 0050 - 28082023 
        }
        else{
            this.error = error;
        }
    }
    
    @wire(getPrograms, {valueUWYear: '$valueUWYear', valuePrincipalCedComp: '$valuePrincipalCedComp'})
    wiredGetPrograms(result){
        console.log('result wiredGetPrograms== ', result);
        console.log('valueUWYear wiredGetPrograms == ', this.valueUWYear); 
        console.log('valueUWYearOnProgram wiredGetPrograms == ', this.valueUWYearOnProgram);
        console.log('valuePrincipalCedComp wiredGetPrograms == ', this.valuePrincipalCedComp);
        console.log('valuePrincipalCedCompOnProgram wiredGetPrograms == ', this.valuePrincipalCedCompOnProgram);
        
        //RRA - ticket 1560- 23082023
        if (this.valuePrincipalCedCompOnProgram == 'undefined' || this.valuePrincipalCedCompOnProgram == undefined || this.valuePrincipalCedCompOnProgram != this.valuePrincipalCedComp){
            fireEvent(this.pageRef, 'comp', this.valuePrincipalCedComp); //RRA - ticket 0050 - 25082023
            this.valuePrincipalCedCompOnProgram = this.valuePrincipalCedComp;
        }

        if (this.valueUWYearOnProgram == 'undefined' || this.valueUWYearOnProgram == undefined || this.valueUWYearOnProgram != this.valueUWYear){
            fireEvent(this.pageRef, 'year', this.valueUWYear); //RRA - ticket 0050 - 26082023
            this.valueUWYearOnProgram = this.valueUWYear ;
        }
        console.log('valueUWYearOnProgram wiredGetPrograms 2222222== ', this.valueUWYearOnProgram);
        console.log('valuePrincipalCedCompOnProgram wiredGetPrograms 2222222== ', this.valuePrincipalCedCompOnProgram);

        this.spinner = true;
        this.wiredPrograms = result;
        if(result.data){
            this.titleCountProgram = this.label.Programs + ' (' + result.data.length + ')';
            let nameUrl;
            let nameUrlTP = sessionStorage.getItem('nameUrlTP');
            let treatyPlacementPhase = sessionStorage.getItem('nameUrlNew');

            console.log('treatyPlacementPhase == ', treatyPlacementPhase);
            console.log('nameUrlTP == ', nameUrlTP);

            if (nameUrlTP == 'TreatyPlacement'){
                nameUrl = '../n/TreatyPlacement?c__program='+ treatyPlacementPhase;
                sessionStorage.setItem('nameUrlUrl', nameUrl);
            }/*else if (nameUrlTP == 'home'){
                if (treatyPlacementPhase != null){
                    nameUrl = '../n/TreatyPlacement?c__program='+ treatyPlacementPhase;
                    sessionStorage.setItem('treatyPlacementPhaseFromHome', treatyPlacementPhase);
                }else{
                    this.data = result.data.map(row => {
                        nameUrl = '../n/TreatyPlacement?c__program='+row.Id+'-'+row.UwYear__c+'-'+row.PrincipalCedingCompany__c+'-'+row.TECH_StageName__c +'-undefined-null-null-null';
                        return {...row , nameUrl}
                    });
                    // RRA - ticket 0050 - 14122022 - Set value nameUrl in sessionStorage to reuse in Home tab
                    sessionStorage.setItem('nameUrl', nameUrl);
                }
            }*/else{
                this.data = result.data.map(row => {
                    nameUrl = '../n/TreatyPlacement?c__program='+row.Id+'-'+this.valueUWYearOnProgram+'-'+this.valuePrincipalCedCompOnProgram+'-'+row.TECH_StageName__c +'-undefined-null-null-null';  //RRA - ticket 0050 - 10082023
                    return {...row , nameUrl}
                });
                // RRA - ticket 0050 - 14122022 - Set value nameUrl in sessionStorage to reuse in Home tab
                sessionStorage.setItem('nameUrl', nameUrl);
            }
             console.log('nameUrl == ', nameUrl);

            this.error = undefined; 
            this.spinner = false; //RRA - ticket 1716 - 30102023
        }
        else if(result.error){
            this.error = result.error;
            this.data = undefined;
        }
        this.spinner = false;
    }

    @wire(checkActivePCC, {valuePrincipalCedComp: '$valuePrincipalCedComp'})
    wiredCheckActivePCC(result){
        this.wiredActivePCC = result;
        if(result.data != undefined){
            if(result.data == false){
                this.hideButtons = true;
            }else{ //RRA - ticket 0050 - 04082023
                this.hideButtons = false;
            }
        }
        else if(result.error){
            this.error = result.error;
        }
    }

    handleRowSelection(event) {
        let selectedPrograms = this.template.querySelector('lightning-datatable').getSelectedRows();
        let programIds = [];

        if(selectedPrograms.length > 0){
            selectedPrograms.forEach((program)=>programIds.push(program.Id));
        }
        fireEvent(this.pageRef, 'hideBtns', this.hideButtons);
        fireEvent(this.pageRef, 'selectedPrograms', programIds);

    }

    handleOpenModal() {
        this.isOpenModal = true;
        this.isCopy = false;
    }

    handleCloseModal() {
        this.isOpenModal = false;
        this.isOpenConfirmation = false;
        this.isDeleteOpen = false;
    }

    deleteBtn(){
        var selectedPrograms = this.template.querySelector('lightning-datatable').getSelectedRows();
        if(selectedPrograms.length == 0){
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'No Programs selected',
                    variant: 'error',
                }),
            );
        }
        else{
            this.delMsgTitle = 'Delete Program';
            this.delMessage = this.label.AskToDeleteProgram;
            this.isDeleteOpen = true;
        }
    }

    refreshData() {
        return refreshApex(this.wiredPrograms);
    }

    reactivateBtn(){
        var selectedPrograms = this.template.querySelector('lightning-datatable').getSelectedRows();
        if(selectedPrograms.length == 0){
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'No Programs selected',
                    variant: 'error',
                }),
            );
        }
        else{
            this.statusModalTitle = 'Reactivate Program';
            this.status = this.label.AskToReactivateProgram;
            this.statusFunction = 'reactivate';
            this.isOpenConfirmation = true;
        }
    }

    deactivateBtn(){
        this.spinner = true;
        var selectedPrograms = this.template.querySelector('lightning-datatable').getSelectedRows();
        console.log('selectedPrograms == ' , selectedPrograms);
        if(selectedPrograms.length == 0){
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'No Programs selected',
                    variant: 'error',
                }),
            );
            this.spinner = false;
        }
        else{
            for(var key in selectedPrograms) {
                var obj = selectedPrograms[key];
                delete obj['Macro_L_O_B__c'];
                delete obj['STLT__c'];
                delete obj['LTA__c'];
                delete obj['TacitRenewal__c'];
            }
            checkRequestExist({lstRecords: selectedPrograms, objectName: 'Program', status: '2', isButtonActDeact : true}) //RRA - ticket 585 13032023
            .then(result => {
                console.log('result Prog error == ', result);
                if(result.hasOwnProperty('Error') && result.Error){
                    this.dispatchEvent(
                         new ShowToastEvent({
                             title: 'Error',
                             message: result.Error,
                             variant: 'error',
                         }),
                   );
                    this.spinner = false;
                }
                else{    
                    console.log('result Prog success == ', result);
                    //RRA - ticket 585 - 01032023
                    if (result.numbLeadRequest > 0){
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Error',
                                message: this.label.SomeLeadpresent,
                                variant: 'error',
                            }),
                        );
                        this.spinner = false;
                    }else if (result.numbPlacementRequest > 0){
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Error',
                                message: this.label.SomeQuoteOrPlacementpresent,
                                variant: 'error',
                            }),
                        );
                        this.spinner = false;
                    }else if (result.numbSigningRequest > 0){
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Error',
                                message: this.label.SomeSigningpresent,
                                variant: 'error',
                            }),
                        );
                        this.spinner = false;
                    }else{
                        this.statusModalTitle = 'Deactivate Program';
                        this.status = this.label.AskToDeactivateProgram;
                        this.statusFunction = 'deactivate';
                        this.isOpenConfirmation = true;
                        this.spinner = false;
                    }
                }
            })
            .catch(error => {
                this.error = error;
            }); 
        }
    }

    acceptStatusChange(){
        this.spinner = true;
        let lstIdPrograms = [];  //RRA - ticket 585 - 23032023 
        //let isRetainLeadExists = false; //RRA - ticket 585 - 23032023 
        var selectedPrograms = this.template.querySelector('lightning-datatable').getSelectedRows();

        //RRA - ticket 585 - 23032023 
        for (let i=0;i<selectedPrograms.length;i++){
            lstIdPrograms.push(selectedPrograms[i].Id);
        }

        if(selectedPrograms.length == 0){
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'No Programs selected',
                    variant: 'error',
                }),
            );
            this.spinner = false;
        }
        else{
            //RRA - ticket 585 - 21032023 => Don't applicate fields below on request SOQL from getProgram (Remove fields marked with toLabel in the SoQL query)
            for(var key in selectedPrograms) {
                var obj = selectedPrograms[key];
                delete obj['Macro_L_O_B__c'];
                delete obj['STLT__c'];
                delete obj['LTA__c'];
                delete obj['TacitRenewal__c'];
            }

            if(this.statusFunction == 'reactivate'){
                changeStatus({lstRecords: selectedPrograms, objectName: 'Program', status: '1', isButtonActDeact : false}) //RRA - ticket 585 06122022
                .then(result => {
                    if(result.hasOwnProperty('Error') && result.Error){
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Error',
                                message: result.Error,
                                variant: 'error',
                            }),
                        );
                        this.spinner = false;
                    }
                    else{
                        console.log('Success == ', result.Success);
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Success',
                                message: result.Success,
                                variant: 'success',
                            }),
                        );
                        fireEvent(this.pageRef, 'refreshProgram', 'refresh');
                        fireEvent(this.pageRef, 'refreshTreaties', 'refresh');
                        fireEvent(this.pageRef, 'refreshSection', 'refresh');
                        this.spinner = false;
                    }
                })
                .catch(error => {
                    this.error = error;
                });
            }
            else if(this.statusFunction == 'deactivate'){
                changeStatus({lstRecords: selectedPrograms, objectName: 'Program', status: '2', isButtonActDeact : true}) //RRA - ticket 585 06122022
                .then(result => {
                    if(result.hasOwnProperty('Error') && result.Error){
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Error',
                                message: result.Error,
                                variant: 'error',
                            }),
                        );
                        this.spinner = false;
                    }
                    else{
                         //RRA - ticket 585 - 23032023
                         //Update the retain to lead field to false if Status is cancelled
                        updateRetainToLeadDeactivation({lstIds: lstIdPrograms, objectName: 'Program'}) //RRA - ticket 585 23032023
                        .then(result => {
                            if(result.hasOwnProperty('Error') && result.Error){
                                this.dispatchEvent(
                                    new ShowToastEvent({
                                        title: 'Error',
                                        message: result.Error,
                                        variant: 'error',
                                    }),
                                );
                                this.spinnerSection = false;
                            }
                            else{
                                console.log('result program  update == ', result);
                                if(result == 'Updated successfully'){
                                    //fireEvent(this.pageRef, 'refreshProgram', 'refresh');
                                    fireEvent(this.pageRef, 'refreshTreaties', 'refresh');
                                    fireEvent(this.pageRef, 'refreshSection', 'refresh' );
                                }else if (result == null){
                                    //fireEvent(this.pageRef, 'refreshProgram', 'refresh');
                                    fireEvent(this.pageRef, 'refreshTreaties', 'refresh');
                                    fireEvent(this.pageRef, 'refreshSection', 'refresh' );
                                }else{
                                    this.dispatchEvent(
                                        new ShowToastEvent({
                                            title: 'Error',
                                            message: result,
                                            variant: 'error',
                                        }),
                                    );
                                    this.spinnerSection = false;
                                }
                            }
                        })
                        .catch(error => {
                            this.error = error;
                        });

                        //RRA - ticket 585 - 21032023
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Success',
                                message: result.Success,
                                variant: 'success',
                            }),
                        );
                        fireEvent(this.pageRef, 'refreshProgram', 'refresh');
                        fireEvent(this.pageRef, 'refreshTreaties', 'refresh');
                        fireEvent(this.pageRef, 'refreshSection', 'refresh');
                        console.log('Accept ok');
                        this.spinner = false;
                        
                    }
                })
                .catch(error => {
                    this.error = error;
                });
            }
         }
        this.isOpenConfirmation = false;
    }

    handleRowAction(event){
        var actionName = event.detail.action.name;
        this.selectedRowProgram = event.detail.row;
        this.selectedRowProgram.Macro_L_O_B__c = this.mapMacroLOb.get(this.selectedRowProgram.Macro_L_O_B__c);
        this.selectedRowProgram.LTA__c = this.mapLTA.get(this.selectedRowProgram.LTA__c);
        this.selectedRowProgram.STLT__c = this.mapSTLT.get(this.selectedRowProgram.STLT__c);
        this.selectedRowProgram.TacitRenewal__c = this.mapTacitRenewal.get(this.selectedRowProgram.TacitRenewal__c);
        switch (actionName) {
            case 'copy':
                this.copyProgramDetail();
                break;

            case 'renew':
                this.renewProgramDetail();
                break;
        }
    }

    copyProgramDetail(){
        getCoveredCedingCompanies({ selectedProgramId : this.selectedRowProgram.Id})
        .then(result => {
            this.dataCoveredCedingCompany = result;
            var newData = [];
            for (var i = 0; i < this.dataCoveredCedingCompany.length; i++) {
                var row = [];
                row['recName'] = this.dataCoveredCedingCompany[i].Account__r.Name;
                row['recId'] = this.dataCoveredCedingCompany[i].Account__r.Id;
                newData.push(row);
            }
            this.dataCoveredCedingCompany = newData;
        })
        .catch(error => { this.error = this.label.errorMsg; });


        if(this.hideButtons == true){
//             this.allReadOnly = true;
            this.dispatchEvent(new ShowToastEvent({title: 'Info',
                                    message: this.label.PCCInactiveCopyNotAllowed,
                                    variant: 'info',
                                }),);
        }
        else{
            this.isOpenModal = true;
            this.isCopy = true;
        }
    }

    acceptDelete(){
        this.spinner = true;
        var selectedPrograms = this.template.querySelector('lightning-datatable').getSelectedRows();
        deletePrograms({lstRecords: selectedPrograms, objectName: 'Program__c'})
        .then(result => {
            if(result.hasOwnProperty('Error') && result.Error){
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: result.Error,
                        variant: 'error',
                    }),
                );
                this.spinner = false;
            }
            else{
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: result.Success,
                        variant: 'success',
                    }),
                );
                this.spinner = false;
                fireEvent(this.pageRef, 'refreshProgram', 'refresh');
                fireEvent(this.pageRef, 'refreshTreaties', 'refresh');
                fireEvent(this.pageRef, 'refreshSection', 'refresh');
            }
        })
        .catch(error => {
            this.error = error;
        });
        this.isDeleteOpen = false;
    }

    renewProgramDetail(){
        this.checkForRenewProgram();
    }

    checkForRenewProgram(){
        let expiryDate = new Date(this.selectedRowProgram.Expirydate__c+'T00:00');
        let renewDate = new Date(expiryDate);
        renewDate.setDate(expiryDate.getDate()+1);
        let uwYearVal = (renewDate.getFullYear()).toString();
        console.log('renewDate == ',renewDate);
        console.log('uwYearVal == ',uwYearVal);
        console.log('setUWYear == ',this.setUWYear);
        console.log('this.setUWYear.has(uwYearVal) == ',this.setUWYear.has(uwYearVal));

        if(this.setUWYear.has(uwYearVal)){
            checkForRenewProgram({programId: this.selectedRowProgram.Id})
            .then(result => {
                let errorMsg = result.errorMsg;
                let displayScreen = result.displayScreen;

                //1. Display Working Scope, Program Name, Treaty, Section
                //2. Display Working Scope, Program Name
                //3. Display pop up with choice of renew between LTA/TR Identical Renew and LTA/TR Renegotiation

                //A. Standard Renew  - Display 1
                //C. LTA/TR Renegotiation - Display 1
                //B. LTA/TR Identical Renew - Display 2
                //B and C - Display 3

                //AMI 08/06/22 W:0874
                //public attribute to determine next screen when lta regociation == true
                this.isLTARegociation = result.ltaRenegociation;

                if(errorMsg == null || errorMsg == undefined){
                    if(displayScreen == '1'){
                        this.typeOfRenewValue = 'Standard Renew';
                        this.displayTreatySection = true;
                        this.isRenew = true;
                        this.isRenewOpenModal = true;
                        this.titleTypeOfRenew = 'Standard Renew Program';
                    }
                    else if(displayScreen == '2'){
                        this.typeOfRenewValue = 'LTA/TR Identical Renew';
                        this.displayTreatySection = false;
                        this.isRenew = true;
                        this.informForRenewProgram = true;

                        //AMI 08/06/22 W:0874
                        //adding new modal title and body message
                        this.titleTypeOfRenew = result.modalTitle !== undefined && result.modalTitle !== '' ? result.modalTitle: '';
                        this.informRenewProgramMsg = result.modalInfo !== undefined && result.modalInfo !== '' ? result.modalInfo: '';
                    }
                    else if(displayScreen == '3'){
                        //Display pop up to display options between B and C
                        this.displayPopOptionBC = true;
                    }
                }
                else{
                    this.isRenewOpenModal = true;
                    this.displayErrorMsg = true;
                    this.errorMessage = errorMsg;
                    this.titleTypeOfRenew = 'Renew Program';
                }
            })
            .catch(error => {
                this.error = error;

                //AMI 08/06/22 W:0874
                //reset attribute
                this.isLTARegociation = false;
            });
        }
        else{
            this.isRenewOpenModal = true;
            this.displayErrorMsg = true;
            this.errorMessage = 'Program cannot be renewed. New UW Year is not open yet.';
            this.titleTypeOfRenew = 'Renew Program';
        }
    }

    handleClosePopOptionBCModal(){
        this.displayPopOptionBC = false;
        this.IdenticalRenewValue == false;
        this.RenegotiationRenewValue == false;
        let checkboxesRenegotiation = this.template.querySelectorAll('[data-id="RenegotiationRenew"]');
        
        for(let i = 0; i < checkboxesRenegotiation.length; i++) {
            checkboxesRenegotiation[i].checked = false;
        }

        let checkboxesIdentical = this.template.querySelectorAll('[data-id="IdenticalRenew"]');
        for(let i = 0; i < checkboxesIdentical.length; i++) {
            checkboxesIdentical[i].checked = false;
        }
    }

    handleOpenRenewModelFromOption(){
        if(this.IdenticalRenewValue == false && this.RenegotiationRenewValue == false){
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: 'No Renew Option selected', variant: 'error',}),);
        }
        else{
            this.displayPopOptionBC = false;
            this.isRenew = true;
            this.isRenewOpenModal = true;

            if(this.IdenticalRenewValue == true){
                this.displayTreatySection = false;
                this.typeOfRenewValue = 'LTA/TR Identical Renew';
                this.titleTypeOfRenew = 'Identical Renew Program';
            }
            else if(this.RenegotiationRenewValue == true){
                this.displayTreatySection = true;
                this.typeOfRenewValue = 'LTA/TR Renegotiation';
                this.titleTypeOfRenew = 'Renegotiation Renew Program';
            }
        }
    }

    handleCloseRenewModal(){
        this.isRenewOpenModal = false;
        this.displayErrorMsg = false;
    }

    deselectRenegotiationRenewCheckbox(event){
        let valueChecked = event.target.checked;
        this.IdenticalRenewValue = valueChecked;

        if(valueChecked == true){
            let checkboxes = this.template.querySelectorAll('[data-id="RenegotiationRenew"]');
            for(let i = 0; i < checkboxes.length; i++) {
                checkboxes[i].checked = false;
            }
            this.RenegotiationRenewValue = false;
        }
    }

    deselectIdenticalRenewCheckbox(event){
        let valueChecked = event.target.checked;
        this.RenegotiationRenewValue = valueChecked;

        if(valueChecked == true){
            let checkboxes = this.template.querySelectorAll('[data-id="IdenticalRenew"]');
            for(let i = 0; i < checkboxes.length; i++) {
                checkboxes[i].checked = false;
            }
            this.IdenticalRenewValue = false;
        }
    }

    handleCloseInformRenewProgramModal(){
        this.informForRenewProgram = false;
    }

    handleOnclickNextInformRenew(){
        this.isRenewOpenModal = true;
        this.informForRenewProgram = false;

        //AMI 08/06/22 W:0874
        //determine next screen when lta regociation == true
        if(this.isLTARegociation){
            this.IdenticalRenewValue = false;
            this.RenegotiationRenewValue = true;

            this.handleOpenRenewModelFromOption();
        }
    }

    //AMI 10/06/22 W:0771
    //toggle boolean property to show modal confirmation after successfull update
    toggleRenewConfirmationModel(event){
        //set property to true
        this.showRenewConfirmationModel = true;
        console.log('### MRA = '+ this.showRenewConfirmationModel) ;
        //set renewedProgram
        this.renewedProgram = event.detail;
    }

    //AMI 10/06/22 W:0771
    //close confirmation modal and refresh parent component
    closeRenewConfirmationModelAndRefresh(){
        //set property to true
        this.showRenewConfirmationModel = false;

        // Navigate to home page.
        /*this[NavigationMixin.GenerateUrl]({
            type: 'standard__namedPage',
            attributes: {
                pageName: 'home'
            },
        }).then((url) => {
            window.location.href = url;
        });*/
    }

    //AMI 10/06/22 W:0771
    //close confirmation modal and redirect to newly created program
    closeRenewConfirmationModelAndRedirect(){
        //set property to true
        this.showRenewConfirmationModel = false;

        try {
            this[NavigationMixin.Navigate]({
                type: 'standard__navItemPage',
                attributes: {
                    apiName: "TreatyPlacement"
                },
                state: {
                    c__program: `${this.renewedProgram.Id}-${this.renewedProgram.UwYear__c}-${this.renewedProgram.PrincipalCedingCompany__c}-${this.renewedProgram.TECH_StageName__c}-undefined-null-null-null`
                }
            });
        }
        catch(err) {
           console.log('navigate to renewed prog failed',JSON.stringify(err));
        }
    }
}