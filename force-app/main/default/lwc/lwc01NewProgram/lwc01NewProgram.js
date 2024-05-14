import {LightningElement, track, wire, api} from 'lwc';
import {getRecord} from 'lightning/uiRecordApi';
import {registerListener, fireEvent, unregisterListener} from 'c/pubSub';
import {NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import {getObjectInfo } from 'lightning/uiObjectInfoApi';
import {getPicklistValues, getPicklistValuesByRecordType} from 'lightning/uiObjectInfoApi';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import getCoveredCedingComp from '@salesforce/apex/LWC01_NewProgram.getCoveredCedingComp';
import saveProgramRecord from '@salesforce/apex/LWC01_NewProgram.saveProgramRecord';
import getAcc from '@salesforce/apex/LWC01_WorkingScope.getPrincipalCedingAcc';
import getCoveredCedingCompaniesEdit from '@salesforce/apex/LWC01_NewProgram.getCoveredCedingCompanies';
import isProgramEmpty from '@salesforce/apex/LWC01_NewProgram.isProgramEmpty';
import getAllExistedCoveredCedingComForTreaty from '@salesforce/apex/LWC01_NewProgram.getAllExistedCoveredCedingComForTreaty';
import checkProgramName from '@salesforce/apex/LWC01_NewProgram.checkProgramName';
import getProgram from '@salesforce/apex/LWC01_NewProgram.getProgram';
import checkForFebruaryLeapYear from '@salesforce/apex/LWC01_NewProgram.checkForFebruaryLeapYear';

//import field
import NATURE_FIELD from '@salesforce/schema/Program__c.Nature__c';
import LOSSDEP_FIELD from '@salesforce/schema/Program__c.LossDeposit__c';
import LOSSDEPLEVEL_FIELD from '@salesforce/schema/Program__c.LossDepositLevel__c';
import LOSSDEPMODE_FIELD from '@salesforce/schema/Program__c.LossDepositMode__c';
import MACROLOB_FIELD from '@salesforce/schema/Program__c.Macro_L_O_B__c';
import STLT_FIELD from '@salesforce/schema/Program__c.STLT__c';
import LTA_FIELD from '@salesforce/schema/Program__c.LTA__c';
import LTARENEGOTIATION_FIELD from '@salesforce/schema/Program__c.LTARenegociation__c';
import TACITRENEWAL_FIELD from '@salesforce/schema/Program__c.TacitRenewal__c';
import ADVNOTICE_FIELD from '@salesforce/schema/Program__c.AdvanceNotice__c';
import EARLYTERMDATE_FIELD from '@salesforce/schema/Program__c.EarlyTerminationDate__c';
import EXPIRYDATE_FIELD from '@salesforce/schema/Program__c.Expirydate__c';
import INCEPDATE_FIELD from '@salesforce/schema/Program__c.InceptionDate__c';
import LTAEXPDATE_FIELD from '@salesforce/schema/Program__c.LTAExpiryDate__c';
import NAME_FIELD from '@salesforce/schema/Program__c.Name';
import WORDINGNAME_FIELD from '@salesforce/schema/Program__c.WordingName__c';
import UWYEAR_FIELD from '@salesforce/schema/Program__c.UwYear__c';
import LTAINCEPTDATE_FIELD from '@salesforce/schema/Program__c.LTAInceptionDate__c';
import PRINCIPLECEDINGCOMPANY_FIELD from '@salesforce/schema/Program__c.PrincipalCedingCompany__c';
import WORDINGNAME2_FIELD from '@salesforce/schema/Program__c.WordingName2__c';
import WORDINGNAME3_FIELD from '@salesforce/schema/Program__c.WordingName3__c';
import WORDINGNAME4_FIELD from '@salesforce/schema/Program__c.WordingName4__c';

//import object
import PROGRAM_OBJECT from '@salesforce/schema/Program__c';

//import custom labels
import InformationAboutProgram from '@salesforce/label/c.InformationAboutProgram';
import Name from '@salesforce/label/c.Name';
import WordingName from '@salesforce/label/c.WordingName';
import InceptionDate from '@salesforce/label/c.InceptionDate';
import ExpiryDate from '@salesforce/label/c.ExpiryDate';
import Nature from '@salesforce/label/c.Nature';
import LossDeposit from '@salesforce/label/c.LossDeposit';
import MacroLOB from '@salesforce/label/c.MacroLOB';
import LossDepositLevel from '@salesforce/label/c.LossDepositLevel';
import STLT from '@salesforce/label/c.STLT';
import LossDepositMode from '@salesforce/label/c.LossDepositMode';
import LTAInformation from '@salesforce/label/c.LTAInformation';
import LTA from '@salesforce/label/c.LTA';
import LTA_InceptionDate from '@salesforce/label/c.LTA_InceptionDate';
import LTA_ExpiryDate from '@salesforce/label/c.LTA_ExpiryDate';
import LTA_Renegotiation from '@salesforce/label/c.LTA_Renegotiation';
import EarlyTerminationDate from '@salesforce/label/c.EarlyTerminationDate';
import TacitRenewalInformation from '@salesforce/label/c.TacitRenewalInformation';
import TacitRenewal from '@salesforce/label/c.TacitRenewal';
import AdvanceNotice from '@salesforce/label/c.AdvanceNotice';
import CoveredCedingCompanies from '@salesforce/label/c.CoveredCedingCompanies';
import Delete from '@salesforce/label/c.Delete';
import New from '@salesforce/label/c.New';
import NewCoveredCedingCompany from '@salesforce/label/c.NewCoveredCedingCompany';
import Cancel from '@salesforce/label/c.Cancel';
import Save from '@salesforce/label/c.Save';
import Add from '@salesforce/label/c.Add';
import Close from '@salesforce/label/c.Close';
import TR_date from '@salesforce/label/c.TR_date';
import Save_header from '@salesforce/label/c.Save_header';
import Save_Message from '@salesforce/label/c.Save_Message';
import Yes from '@salesforce/label/c.Yes';
import No from '@salesforce/label/c.No';
import ProgramNameCopy from '@salesforce/label/c.ProgramNameCopy';
import Selected_Ceded_Company from '@salesforce/label/c.Selected_Ceded_Company';
import Required_Fields from '@salesforce/label/c.Required_Fields';
import Ceded_Company_Empty from '@salesforce/label/c.Ceded_Company_Empty';
import LTA_Error from '@salesforce/label/c.LTA_Error';
import LossDept_Program from '@salesforce/label/c.LossDept_Program';
import ExpiryDate_Error from '@salesforce/label/c.ExpiryDate_Error';
import LTAInception_Error from '@salesforce/label/c.LTAInception_Error';
import LTA_minPeriod from '@salesforce/label/c.LTA_minPeriod';
import ProgName_Unchanged from '@salesforce/label/c.ProgName_Unchanged'; 
import ProgName_Exists from '@salesforce/label/c.ProgName_Exists';
import Program_Updated from '@salesforce/label/c.Program_Updated'; 
import Program_Created from '@salesforce/label/c.Program_Created';
import InceptionDate_Error from '@salesforce/label/c.InceptionDate_Error';
import errorMsg from '@salesforce/label/c.errorMsg';

const columns = [
    { label: Name, fieldName: 'recName'}
];

const PROGFIELDS = [NAME_FIELD, LTA_FIELD, LOSSDEP_FIELD, LOSSDEPLEVEL_FIELD, LOSSDEPMODE_FIELD, MACROLOB_FIELD, NATURE_FIELD, STLT_FIELD, TACITRENEWAL_FIELD,
                UWYEAR_FIELD, WORDINGNAME_FIELD, PRINCIPLECEDINGCOMPANY_FIELD, EXPIRYDATE_FIELD, INCEPDATE_FIELD, LTAEXPDATE_FIELD, EARLYTERMDATE_FIELD,
                LTARENEGOTIATION_FIELD, LTAINCEPTDATE_FIELD, ADVNOTICE_FIELD, WORDINGNAME2_FIELD, WORDINGNAME3_FIELD, WORDINGNAME4_FIELD];

export default class LWC01_NewProgram extends NavigationMixin(LightningElement) {
    label = {
        Name,
        InformationAboutProgram,
        WordingName,
        InceptionDate,
        ExpiryDate,
        Nature,
        LossDeposit,
        MacroLOB,
        LossDepositLevel,
        STLT,
        LossDepositMode,
        LTAInformation,
        LTA,
        LTA_InceptionDate,
        LTA_ExpiryDate,
        LTA_Renegotiation,
        EarlyTerminationDate,
        TacitRenewalInformation,
        TacitRenewal,
        AdvanceNotice,
        CoveredCedingCompanies,
        Delete,
        New,
        NewCoveredCedingCompany,
        Cancel,
        Save,
        Add,
        Close,
        TR_date,
        Save_header,
        Save_Message,
        Yes,
        No,
        ProgramNameCopy,
        Selected_Ceded_Company,
        Required_Fields,
        Ceded_Company_Empty,
        LTA_Error,
        LossDept_Program,
        ExpiryDate_Error,
        LTAInception_Error,
        LTA_minPeriod,
        ProgName_Unchanged,
        ProgName_Exists,
        Program_Updated,
        Program_Created,
        InceptionDate_Error,
        errorMsg
    };

    @api uwYearOpenModal;
    @api compOpenModal;
    @api createPage;
    @api recordId;
    @api isProgramEdit = false;
    @api conditionPage = false;
    @api covData;
    @api isProgramCopy = false;
    @api selectedProgram;
    @api objectName = 'Account';
    @api fieldName = 'Name';
    @api Label;
    @api required = false;
    @api iconName = 'standard:account'
    @api LoadingText = false;
    @api allowEditableFields;
    @api lossDepLevelVal;
    @track controllingNatureValues = [];
    @track dependentMLobValues = [];
    @track searchRecords = [];
    @track selectedRecords = [];
    @track LossDepositModeValue = [];
    @track lstAccountIdCovCedingCom = [];
    @track setExistingAccountIdTreaties = new Set();
    createProgramPage;
    natureOpt;
    lossDepositOpt;
    lossDepositLevelOpt;
    lossDepositModeOpt;
    macroLobOpt;
    stltOpt;
    ltaOpt;
    ltaRenegotiationOpt;
    tacitRenewalOpt;
    columns = columns;
    isCompanyModalOpen = false;
    selectedCompany;
    titleCoveredCedingCompanies = this.label.CoveredCedingCompanies + ' (0)';
    error;
    falseValue = false;
    mapMacroLOb = new Map();
    controlMLobValues;
    totalDependentMLobValues = [];
    isEmpty = true;
    txtclassname = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
    messageFlag = false;
    searchText;
    emptyErrorMsg = 'slds-has-error';
    nameEmpty = false;
    natureEmpty = false;
    lossDepositEmpty = false;
    macroLobEmpty = false;
    lossDepositLevelEmpty = false;
    lossDepositModeEmpty = false;
    stltEmpty = false;
    ltaEmpty = false;
    tacitRenewEmpty = false;
    ltaExpiryDateEmpty = false;
    advanceNoticeEmpty = false;
    disableEarlyTerminationDate = true;
    ltaEarlyTerminationDateEmpty = false;
    inceptionDateEmpty = false;
    expiryDateEmpty = false;
    isRenderCallbackActionExecuted = false;
    LTARenegotiationValue;
    STLTValue;
    MacroLOBValue;
    LossDepositLevelValue;
    NatureValue;
    LossDepositValue;
    LTAValue;
    TacitRenewalValue;
    selectedProgramId = null;
    Name;
    WordingName1;
    WordingName2;
    WordingName3;
    WordingName4;
    InceptionDate;
    Expirydate;
    LTAInceptionDate;
    LTAExpiryDate;
    EarlyTerminationDate;
    AdvanceNotice;
    oldName;
    maxDate;
    cedingCompaniesChanged = false;
    lossDepLevelChanges = false;
    lossDepositModeChanged = false;
    lossDeptLevelRequired = false;
    minEarlyTermDate;
    maxEarlyTermDate;
    disabledLossDepoLevel;
    disabledLossDepoMode = true;//added by DMO 19022020 - also disable Loss Deposit Mode when Loss Deposit=No
    disableInceptionDateRenew = false;
    disableLTARenew = false;
    disableLTAExpiryDateRenew = false;
    disableLTAInceptionDateRenew = false;
    disableTRInceptionDateRenew = false;
    disableTRRenew = false;
    spinner = false;
    showLTA = false;
    showTR = false;

    @track objProgram = {
        Name : NAME_FIELD,
        LTA__c : LTA_FIELD,
        LossDeposit__c : LOSSDEP_FIELD,
        LossDepositLevel__c : LOSSDEPLEVEL_FIELD,
        LossDepositMode__c : LOSSDEPMODE_FIELD,
        Macro_L_O_B__c : MACROLOB_FIELD,
        Nature__c : NATURE_FIELD,
        STLT__c : STLT_FIELD,
        TacitRenewal__c : TACITRENEWAL_FIELD,
        UwYear__c : UWYEAR_FIELD,
        WordingName__c : WORDINGNAME_FIELD,
        PrincipalCedingCompany__c : PRINCIPLECEDINGCOMPANY_FIELD,
        Expirydate__c : EXPIRYDATE_FIELD,
        InceptionDate__c : INCEPDATE_FIELD,
        LTAExpiryDate__c : LTAEXPDATE_FIELD,
        EarlyTerminationDate__c : EARLYTERMDATE_FIELD,
        LTARenegociation__c : LTARENEGOTIATION_FIELD,
        LTAInceptionDate__c	: LTAINCEPTDATE_FIELD,
        AdvanceNotice__c : ADVNOTICE_FIELD,
        WordingName2__c : WORDINGNAME2_FIELD,
        WordingName3__c : WORDINGNAME3_FIELD,
        WordingName4__c : WORDINGNAME4_FIELD
    };

    @wire(getObjectInfo, { objectApiName: PROGRAM_OBJECT })
    objectInfo;

    @wire(getRecord, { recordId: '$recordId', fields: PROGFIELDS})
    wiredRecord({ error, data }) {
        if (data) {
            this.objProgram = data;
        }else if (error) {
            this.error = error;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: MACROLOB_FIELD})
    setMacroLobPicklistOpt({error, data}) {
        if(data){
            this.macroLobOpt = data.values;
            this.mapMacroLOb = new Map();
            for(var i = 0; i < data.values.length; i++){
                this.mapMacroLOb.set(data.values[i].value, data.values[i].label);
            }
        }else{
            this.error = error;
        }
    }

    @wire(getPicklistValuesByRecordType, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', objectApiName: PROGRAM_OBJECT})
    naturePicklistOpt({error, data}) {
        if(data){
            let natureOptions = [{label:'--None--', value:'--None--'}];
            data.picklistFieldValues.Nature__c.values.forEach(key => {
                natureOptions.push({
                    label : key.label,
                    value: key.value
                })
            });
            this.controllingNatureValues = natureOptions;
            let macroLobOptions = [{label:'--None--', value:'--None--'}];
            this.controlMLobValues = data.picklistFieldValues.Macro_L_O_B__c.controllerValues;
            this.totalDependentMLobValues = data.picklistFieldValues.Macro_L_O_B__c.values;

            this.totalDependentMLobValues.forEach(key => {
                macroLobOptions.push({
                    label : key.label,
                    value: key.value
                })
            });
            this.dependentMLobValues = macroLobOptions;
        }
        else{
            this.error = error;
        }
    }

    @wire(CurrentPageReference) pageRef;


    renderedCallback() {
        if (this.isRenderCallbackActionExecuted){
            return;
        }

        this.isRenderCallbackActionExecuted = true;
    }

    connectedCallback(){
        let maxYear = new Date().getFullYear() + 10;
        this.maxDate = maxYear+'-12-31';

        if(this.isProgramCopy == true || this.isProgramEdit == true){
            this.selectedProgramId = this.selectedProgram.Id;
            this.Name = this.selectedProgram.Name;
            this.oldName = this.selectedProgram.Name;
            this.InceptionDate = this.selectedProgram.InceptionDate__c;
            this.LTAExpiryDate = this.selectedProgram.LTAExpiryDate__c;
            this.LTAInceptionDate = this.selectedProgram.LTAInceptionDate__c;
            this.LTAValue = this.selectedProgram.LTA__c;

            if(this.LTAValue == '1'){
                this.showLTA = true;
            }
            this.NatureValue = this.selectedProgram.Nature__c;
            this.MacroLOBValue = this.selectedProgram.Macro_L_O_B__c;
            this.Expirydate = this.selectedProgram.Expirydate__c;
            this.STLTValue = this.selectedProgram.STLT__c;
            this.TacitRenewalValue = this.selectedProgram.TacitRenewal__c;
            if(this.TacitRenewalValue == '1'){
                this.showTR = true;
            }
            this.WordingName1 = this.selectedProgram.WordingName__c;
            this.WordingName2 = this.selectedProgram.WordingName2__c;
            this.WordingName3 = this.selectedProgram.WordingName3__c;
            this.WordingName4 = this.selectedProgram.WordingName4__c;
            this.LossDepositValue = this.selectedProgram.LossDeposit__c;

            var selectedLossDepositModeStr = this.selectedProgram.LossDepositMode__c;

            if(selectedLossDepositModeStr != undefined){
                this.LossDepositModeValue = selectedLossDepositModeStr.split(';');
            }

            this.LossDepositLevelValue = this.selectedProgram.LossDepositLevel__c;
            this.LTARenegotiationValue = this.selectedProgram.LTARenegociation__c;
            if(this.LTARenegotiationValue == '1'){
                this.disableEarlyTerminationDate = false;
                this.EarlyTerminationDate = this.selectedProgram.EarlyTerminationDate__c;
            }
            else{
                this.disableEarlyTerminationDate = true;
                this.EarlyTerminationDate = null;
            }
            this.AdvanceNotice = this.selectedProgram.AdvanceNotice__c;

            let maxDate1 = new Date(this.LTAExpiryDate+'T00:00');
            maxDate1.setDate(maxDate1.getDate() - 1);

            let maxMonth = (maxDate1.getMonth()+1).toString();
            if(maxMonth.length == 1){
                maxMonth = '0' + maxMonth;
            }

            let maxDay = (maxDate1.getDate()).toString();
            if(maxDay.length == 1){
                maxDay = '0' + maxDay;
            }

            let dayMaxEarlyTerm = (maxDate1.getDate()-1).toString();
            this.maxEarlyTermDate = maxDate1.getFullYear()+'-'+maxMonth+'-'+dayMaxEarlyTerm;

            let minDate = new Date(this.InceptionDate+'T00:00');
            minDate.setDate(minDate.getDate() - 1);

            let minMonth = (minDate.getMonth()+1).toString();
            if(minMonth.length == 1){
                minMonth = '0' + minMonth;
            }

            let minDay = (minDate.getDate()+2).toString();
            if(minDay.length == 1){
                minDay = '0' + minDay;
            }

            this.minEarlyTermDate = minDate.getFullYear()+'-'+minMonth+'-'+minDay;
            this.getProgram(this.selectedProgramId);
        }else{
            this.LTAValue = '2';
            this.TacitRenewalValue = '2';
        }
        if(this.isProgramCopy == false){
            this.covData = [];
        }
        else{
            this.titleCoveredCedingCompanies = this.label.CoveredCedingCompanies + ' (' + this.covData.length + ')';
        }
        if(this.isProgramEdit == true){
            this.getCoveredCedingCompaniesEdit(this.selectedProgramId);
            this.getAllExistedCoveredCedingComForTreaty(this.selectedProgramId);

            if(this.selectedProgram.RenewedFromProgram__c != null && this.selectedProgram.RenewedFromProgram__c != undefined){
                this.disableInceptionDateRenew = true;
                if(this.selectedProgram.TypeOfRenew__c == 'LTA/TR Identical Renew'){
                    this.disableLTARenew = true;
                    this.disableLTAExpiryDateRenew = true;
                    this.disableLTAInceptionDateRenew = true;
                    this.disableTRInceptionDateRenew = true;
                    this.disableTRRenew = true;
                }
                else if(this.selectedProgram.TypeOfRenew__c == 'LTA/TR Renegotiation'){
                    this.disableTRInceptionDateRenew = true;
                }
            }
        }

        if (this.LossDepositValue == '1'){
            this.disabledLossDepoLevel = false;
            if (this.LossDepositLevelValue == 'Treaty'){
                this.disabledLossDepoMode = true;
                this.LossDepositModeValue = '';
            }
            else{
                this.disabledLossDepoMode = false;
            }    
        }
        else if (this.LossDepositValue=='2'){
            this.disabledLossDepoLevel = true;
            this.disabledLossDepoMode = true;
            this.LossDepositLevelValue = '';
            this.LossDepositModeValue = '';
        }

        if (this.NatureValue != null){
            this.isEmpty = false;
        }

        registerListener('selectedCompany', this.getSelectedCompany, this);
        registerListener('year', this.getVal, this);
        registerListener('comp', this.getComp, this);
        registerListener('filterProgram', this.initProgram, this);
        registerListener('saveCondProgram', this.handleSaveProgramTP, this);
    }

    getProgram(selectedProgramId){
        getProgram({ programId : selectedProgramId})
        .then(result => {
            this.MacroLOBValue = result.Macro_L_O_B__c;
            this.STLTValue = result.STLT__c;
            this.TacitRenewalValue = result.TacitRenewal__c;
            this.LTAValue = result.LTA__c;

            if(this.TacitRenewalValue == '1'){
                this.showTR = true;
            }

            if(this.LTAValue == '1'){
                this.showLTA = true;
            }
        })
        .catch(error => {
            this.dispatchEvent(new ShowToastEvent({title: 'ERROR', message: this.label.errorMsg, variant: 'error'}),);
        });
    }

    initProgram(val){
        if(val == null){
            this.selectedProgramId = null;
            this.Name = null;
            this.InceptionDate = null;
            this.LTAExpiryDate = null;
            this.LTAInceptionDate = null;
            this.LTAValue = '2';
            this.NatureValue = null;
            this.MacroLOBValue = null;
            this.Expirydate = null;
            this.STLTValue = null;
            this.TacitRenewalValue = null;
            this.WordingName1 = null;
            this.WordingName2 = null;
            this.WordingName3 = null;
            this.WordingName4 = null;
            this.LossDepositValue = null;
            this.LossDepositModeValue = null;
            this.LossDepositLevelValue = null;
            this.LTARenegotiationValue = null;
            this.EarlyTerminationDate = null;
            this.AdvanceNotice = null;
        }
        else{
            this.selectedProgramId = val.Id;
            this.Name = val.Name;
            this.InceptionDate = val.InceptionDate__c;
            this.LTAExpiryDate = val.LTAExpiryDate__c;
            this.LTAInceptionDate = val.LTAInceptionDate__c;
            this.LTAValue = val.LTA__c;
            this.NatureValue = val.Nature__c;
            this.MacroLOBValue = val.Macro_L_O_B__c;
            this.Expirydate = val.Expirydate__c;
            this.STLTValue = val.STLT__c;
            this.TacitRenewalValue = val.TacitRenewal__c;
            this.WordingName1 = val.WordingName__c;
            this.WordingName2 = val.WordingName2__c;
            this.WordingName3 = val.WordingName3__c;
            this.WordingName4 = val.WordingName4__c;
            this.LossDepositValue = val.LossDeposit__c;

            var selectedLossDepositModeStr = val.LossDepositMode__c;
            if(selectedLossDepositModeStr != undefined){
                this.LossDepositModeValue = selectedLossDepositModeStr.split(';');
            }

            this.LossDepositLevelValue = val.LossDepositLevel__c;
            this.LTARenegotiationValue = val.LTARenegociation__c;
            this.EarlyTerminationDate = val.EarlyTerminationDate__c;
            this.AdvanceNotice = val.AdvanceNotice__c;

            if(this.LTAValue == '1'){
                this.showLTA = true;
            }

            if(this.TacitRenewalValue == '1'){
                this.showTR = true;
            }

            this.getCoveredCedingCompaniesEdit(this.selectedProgramId);
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: UWYEAR_FIELD})
    setPicklistOptions({error, data}) {
        if(data){
            if(this.createPage == 'yes' || this.conditionPage){
                this.uwYearOpenModal = data.values[data.values.length - 1].value;
            }
        }
        else{
            this.error = error;
        }
    }

    @wire(getAcc)
    setAccPicklistOptions({error, data}) {
        if(data){
            if(this.conditionPage){
                this.compOpenModal = data[0].value;
            }
         }
        else{
            this.error = error;
        }
    }

    handleNatureChange(event){
        this.NatureValue = event.target.value;
        this.isEmpty = false;
        let dependValues = [];
        if(this.NatureValue){
            if(this.NatureValue == '--None--'){
                this.isEmpty = true;
                dependValues = [{label:'--None--', value:'--None--'}];
                this.NatureValue = null;
                this.MacroLOBValue = null;
                return;
            }
            this.totalDependentMLobValues.forEach(natureValues => {
                if(natureValues.validFor[0] === this.controlMLobValues[this.NatureValue]){
                    dependValues.push({
                        label : natureValues.label,
                        value : natureValues.value
                    })
                }
            })
            this.dependentMLobValues = dependValues;
        }
    }

    handleMLobChange(event){
        this.MacroLOBValue = event.target.value;
    }

    handleLTAValue(event){
        let ltaValue = event.detail.value;

        if (ltaValue == '1'){
            if (this.TacitRenewalValue == '1'){
                this.TacitRenewalValue = '2';
                const tacitRenewalCombo = this.template.querySelector('.tacitRenewal');
                tacitRenewalCombo.value = '';
                this.showTR = false;
                this.AdvanceNotice = null;
            }
            this.LTARenegotiationValue = '2';
            this.LTAValue = ltaValue;
            this.showLTA = true;
            this.LTAInceptionDate = this.InceptionDate;
        }
        else{
            this.LTAValue = ltaValue;
            this.showLTA = false;
            this.LTAInceptionDate = null;
            this.LTAExpiryDate = null;
            this.LTARenegotiationValue = null;
            this.EarlyTerminationDate = null;
        }
    }

    handleTRValue(event){
        let tacitRenewalValue = event.detail.value;

        if (tacitRenewalValue == '1'){
            if (this.LTAValue == '1'){
                this.LTAValue = '2';
                const ltaCombo = this.template.querySelector('.lta');
                ltaCombo.value = '';
                this.LTAExpiryDate = null;
                this.LTARenegotiationValue = null;
                this.EarlyTerminationDate = null;
                this.showLTA = false;
            }
            this.TacitRenewalValue = tacitRenewalValue;
            this.showTR = true;   
        }
        else{
            this.TacitRenewalValue = tacitRenewalValue;
            this.showTR = false;
            this.AdvanceNotice = null;
        }
    }

    checkCreate(){
        if(this.createPage == 'yes'){
            this.createProgramPage = true;
        }
    }

    getSelectedCompany(val){
        this.selectedCompany = val;
    }

    getVal(val){
        this.uwYearOpenModal = val;
        if(this.conditionPage){
            this.selectedProgramId = null;
            this.Name = null;
            this.InceptionDate = null;
            this.LTAExpiryDate = null;
            this.LTAInceptionDate = null;
            this.LTAValue = null;
            this.MacroLOBValue = null;
            this.Expirydate = null;
            this.STLTValue = null;
            this.TacitRenewalValue = null;
            this.WordingName1 = null;
            this.WordingName2 = null;
            this.WordingName3 = null;
            this.WordingName4 = null;
            this.NatureValue = null;
            this.LossDepositValue = null;
            this.LossDepositModeValue = null;
            this.LossDepositLevelValue = null;
            this.LTARenegotiationValue = null;
            this.EarlyTerminationDate = null;
            this.AdvanceNotice = null;
            this.covData = [];
            this.checkIfProgramEmptyOnChangeValue();
        }
    }

    getComp(val){
        this.compOpenModal = val;
        if(this.conditionPage){
            this.selectedProgramId = null;
            this.Name = null;
            this.InceptionDate = null;
            this.LTAExpiryDate = null;
            this.LTAInceptionDate = null;
            this.LTAValue = null;
            this.MacroLOBValue = null;
            this.Expirydate = null;
            this.STLTValue = null;
            this.TacitRenewalValue = null;
            this.WordingName1 = null;
            this.WordingName2 = null;
            this.WordingName3 = null;
            this.WordingName4 = null;
            this.NatureValue = null;
            this.LossDepositValue = null;
            this.LossDepositModeValue = null;
            this.LossDepositLevelValue = null;
            this.LTARenegotiationValue = null;
            this.EarlyTerminationDate = null;
            this.AdvanceNotice = null;
            this.covData = [];
            this.checkIfProgramEmptyOnChangeValue();
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: NATURE_FIELD})
    setNaturePicklistOpt({error, data}) {
        if(data){
            this.natureOpt = data.values;
        }
        else{
            this.error = error;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: LOSSDEP_FIELD})
    setLossDepositPicklistOpt({error, data}) {
        if(data){
            this.lossDepositOpt = data.values;
        }
        else{
            this.error = error;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: LOSSDEPLEVEL_FIELD})
    setLossDepositLevelPicklistOpt({error, data}) {
        if(data){
            this.lossDepositLevelOpt = data.values;
        }
        else{
            this.error = error;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: LOSSDEPMODE_FIELD})
    setLossDepositModePicklistOpt({error, data}) {
        if(data){
            this.lossDepositModeOpt = data.values;
        }
        else{
            this.error = error;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: STLT_FIELD})
    setStltPicklistOpt({error, data}) {
        if(data){
            this.stltOpt = data.values;
        }
        else{
            this.error = error;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: LTA_FIELD})
    setLtaPicklistOpt({error, data}) {
        if(data){
            this.ltaOpt = data.values;
        }
        else{
            this.error = error;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: LTARENEGOTIATION_FIELD})
    setLtaRenegoPicklistOpt({error, data}) {
        if(data){
            this.ltaRenegotiationOpt = data.values;
        }
        else{
            this.error = error;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: TACITRENEWAL_FIELD})
    setTacitRenewalPicklistOpt({error, data}) {
        if(data){
            this.tacitRenewalOpt = data.values;
        }
        else{
            this.error = error;
        }
    }

    handleOpenCompanyModal() {
        this.isCompanyModalOpen = true;
    }

    handleCloseCompanyModal() {
        this.isCompanyModalOpen = false;
        this.selectedRecords = [];
    }

    handleChangeInceptionDt(event){
        this.EarlyTerminationDate = null;

        if(this.LTAExpiryDate != null){
            let maxDate = new Date(this.LTAExpiryDate+'T00:00');
            maxDate.setFullYear(maxDate.getFullYear() + 1);
            maxDate.setDate(maxDate.getDate() - 1);

            let month = (maxDate.getMonth()+1).toString();
            if(month.length == 1){
                month = '0' + month;
            }

            let day = (maxDate.getDate()).toString();
            if(day.length == 1){
                day = '0' + day;
            }

            let dayMaxEarlyTerm = (maxDate.getDate()-1).toString();

            this.maxEarlyTermDate = maxDate.getFullYear()+'-'+month+'-'+dayMaxEarlyTerm;
        }

        let enteredDate = event.target.value+'T00:00';
        let minDate = new Date(enteredDate);
        minDate.setDate(minDate.getDate() - 1);

        let minMonth = (minDate.getMonth()+1).toString();
        if(minMonth.length == 1){
            minMonth = '0' + minMonth;
        }

        let minDay = (minDate.getDate()+2).toString();
        if(minDay.length == 1){
            minDay = '0' + minDay;
        }

        //exp date
        let expDate = new Date(enteredDate);
        expDate.setFullYear(expDate.getFullYear() + 1);
        expDate.setDate(expDate.getDate() - 1);

        let month = (expDate.getMonth()+1).toString();
        if(month.length == 1){
            month = '0' + month;
        }

        let day = (expDate.getDate()).toString();
        if(day.length == 1){
            day = '0' + day;
        }

        this.Expirydate = expDate.getFullYear()+'-'+month+'-'+day;
        this.minEarlyTermDate = minDate.getFullYear()+'-'+minMonth+'-'+minDay;
        this.LTAInceptionDate = event.target.value;
        this.InceptionDate = event.target.value;
    }

    searchField(event) {
        var currentText = event.target.value;
        var selectRecId = [];
        for(let i = 0; i < this.selectedRecords.length; i++){
            selectRecId.push(this.selectedRecords[i].recId);
        }
        this.LoadingText = true;
        getCoveredCedingComp({ ObjectName: this.objectName, fieldName: this.fieldName, value: currentText, selectedRecId : selectRecId })
        .then(result => {
            this.searchRecords = result;
            this.LoadingText = false;

            this.txtclassname =  result.length > 0 ? 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-is-open' : 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
            if(currentText.length > 0 && result.length == 0) {
                this.messageFlag = true;
            }else {
                this.messageFlag = false;
            }

            if(this.selectRecordId != null && this.selectRecordId.length > 0) {
                this.iconFlag = false;
                this.clearIconFlag = true;
            }else {
                this.iconFlag = true;
                this.clearIconFlag = false;
            }
        })
        .catch(error => { this.error = error; });
    }

    setSelectedRecord(event) {
        var recId = event.currentTarget.dataset.id;
        var selectName = event.currentTarget.dataset.name;
        let isDuplicate = false;

        if(this.covData != []){
            for(var x = 0; x < this.covData.length; x++){
                if(this.covData[x]['recId'] == recId){
                    isDuplicate = true;
                }
            }
        }
        if(isDuplicate == true){
            this.dispatchEvent(new ShowToastEvent({title: 'ERROR', message: this.label.Selected_Ceded_Company, variant: 'error'}),);

        }else{
            let newsObject = { 'recId' : recId ,'recName' : selectName };
            this.selectedRecords.push(newsObject);
            this.txtclassname = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
            let selRecords = this.selectedRecords;
            this.searchText = null;
            const selectedEvent = new CustomEvent('selected', { detail: {selRecords}, });
            this.dispatchEvent(selectedEvent);
        }
    }

    removeRecord (event){
        let selectRecId = [];
        for(var i = 0; i < this.selectedRecords.length; i++){
            if(event.detail.name !== this.selectedRecords[i].recId){
                selectRecId.push(this.selectedRecords[i]);
            }
        }
        this.selectedRecords = [...selectRecId];
        let selRecords = this.selectedRecords;
        const selectedEvent = new CustomEvent('selected', { detail: {selRecords}, });
        this.dispatchEvent(selectedEvent);
    }

    handleSubmitCompany(){
        if (this.covData != undefined){
            for(var j = 0; j < this.covData.length; j++){
                    this.selectedRecords.push(this.covData[j]);
            }
        }
        this.isCompanyModalOpen = false;
        this.covData = this.getUniqueData(this.selectedRecords,'recId');
        this.titleCoveredCedingCompanies = this.label.CoveredCedingCompanies + ' (' + this.covData.length + ')';
        this.selectedRecords = [];
        this.cedingCompaniesChanged = true;
    }

    handleRemoveCompany(){
        this.cedingCompaniesChanged = true;
        let setCompanyToDelete = new Set();
        let lstCompanyNotToDelete = [];

        for(let i = 0; i < this.selectedCompany.length; i++){
            if(this.setExistingAccountIdTreaties.has(this.selectedCompany[i].recId)){
                lstCompanyNotToDelete.push(this.selectedCompany[i].recName);
            }
            else{
                setCompanyToDelete.add(this.selectedCompany[i].recId);
            }
        }

        let lstUpdCovData = [];

        for(let i = 0; i < this.covData.length; i++){
            if(!setCompanyToDelete.has(this.covData[i].recId)){
                var row = [];
                row['recName'] = this.covData[i].recName;
                row['recId'] = this.covData[i].recId;
                lstUpdCovData.push(row);
            }
        }

        this.covData = lstUpdCovData;
        this.titleCoveredCedingCompanies = this.label.CoveredCedingCompanies + ' (' + this.covData.length + ')';
        let companiesNotToDelete = null;
        
        if(lstCompanyNotToDelete.length != 0){
            for(let i = 0; i < lstCompanyNotToDelete.length; i++){
                if(companiesNotToDelete == null){
                    companiesNotToDelete = lstCompanyNotToDelete[i];
                }
                else{
                    companiesNotToDelete += ', ' + lstCompanyNotToDelete[i];
                }
            }

            let errorMsg = null;
            if(lstCompanyNotToDelete.length == 1){
                errorMsg = companiesNotToDelete + ' cannot be deleted since it is covered by some Treaty.';
            }
            else{
                errorMsg = companiesNotToDelete + ' cannot be deleted since they are covered by some Treaty.';
            }
            this.dispatchEvent(new ShowToastEvent({title: 'ERROR', message: errorMsg, variant: 'error'}),);
        }

    }

    handleRowSelection(event) {
        var selectedCompany = this.template.querySelector('lightning-datatable').getSelectedRows();
        fireEvent(this.pageRef, 'selectedCompany', selectedCompany);
    }

    lossDepositChange(event){
        var lossDepoVal = event.target.value;
        if(lossDepoVal == '1'){
            this.disabledLossDepoLevel = false;
            this.lossDeptLevelRequired = true;
        }
        else if(lossDepoVal == '2'){
            this.lossDepositLevelEmpty = false;
            this.lossDepositEmpty = false;
            this.lossDeptLevelRequired = false;
            this.disabledLossDepoLevel = true;
            this.disabledLossDepoMode = true;//added by DMO 19022020 - also disable Loss Deposit Mode when Loss Deposit=No
            //added by DMO 19022020 - clear values Loss Deposit Mode when Loss Deposit=No
            this.LossDepositLevelValue = '';
            this.LossDepositModeValue = '';
            const lossDepLevel = this.template.querySelector('.lossDepLevel');
            lossDepLevel.value = '';
            const lossDepMode = this.template.querySelector('.lossDepMode');
            lossDepMode.value = '';
        }
    }

    handleSaveProgram(){
        this.spinner = true;
        this.objProgram = {};
        let inputs = this.template.querySelectorAll('lightning-input, lightning-dual-listbox');
        let dataInput = {};

        for(let input of inputs){
            dataInput[input.name] = input.value;
        }

        this.objProgram.AdvanceNotice__c = dataInput.AdvanceNotice;
        this.objProgram.EarlyTerminationDate__c = dataInput.EarlyTerminationDate;
        this.objProgram.Expirydate__c = dataInput.ExpiryDate;
        this.objProgram.InceptionDate__c = dataInput.InceptionDate;
        this.objProgram.Name = dataInput.Name.trim();
        this.objProgram.WordingName__c = dataInput.WordingName;
        this.objProgram.PrincipalCedingCompany__c = this.compOpenModal;
        this.objProgram.UwYear__c = this.uwYearOpenModal;
        this.objProgram.WordingName2__c = dataInput.WordingName2;
        this.objProgram.WordingName3__c = dataInput.WordingName3;
        this.objProgram.WordingName4__c = dataInput.WordingName4;
        this.objProgram.LossDepositMode__c = dataInput.LossDepositMode;

        let comboValues= this.template.querySelectorAll('lightning-combobox');
        let dataCombo = {};
        for(let combo of comboValues){
            dataCombo[combo.name] = combo.value;
        }
        this.objProgram.LTA__c = dataCombo.LTA;
        if(this.objProgram.LTA__c == '1'){
            this.objProgram.LTAExpiryDate__c = dataInput.LTA_ExpiryDate;
            this.objProgram.LTAInceptionDate__c = dataInput.LTA_InceptionDate;
        }else{
            this.objProgram.LTAExpiryDate__c = null;
            this.objProgram.LTAInceptionDate__c = null;
        }

        this.objProgram.LTARenegociation__c = dataCombo.LTARenegotiation;
        this.objProgram.LossDeposit__c = dataCombo.LossDeposit;
        this.objProgram.LossDepositLevel__c = dataCombo.LossDepositLevel;
        this.objProgram.Macro_L_O_B__c = dataCombo.MacroLoB;
        this.objProgram.Nature__c = dataCombo.Nature;
        this.objProgram.STLT__c = dataCombo.STLT;
        this.objProgram.TacitRenewal__c = dataCombo.TacitRenewal;

        let updLstAccountIdCovCedingCom = [];

        if(this.objProgram.LossDepositMode__c.length == 0){
            this.objProgram.LossDepositMode__c = '';
        }

        if (this.covData != undefined){
            for (var i = 0; i < this.covData.length; i++){
                updLstAccountIdCovCedingCom.push(this.covData[i].recId);
            }
        }

        this.lstAccountIdCovCedingCom = updLstAccountIdCovCedingCom;

        if(this.objProgram.Name == "" || this.objProgram.InceptionDate__c == "" || this.objProgram.Expirydate__c == ""
         || this.objProgram.Nature__c == null || this.objProgram.LossDeposit__c == null || this.objProgram.Macro_L_O_B__c == null
         || this.objProgram.STLT__c == null || this.objProgram.LTA__c == null || this.objProgram.TacitRenewal__c == null
         || ((this.objProgram.LTA__c == '1') && (this.objProgram.LTAExpiryDate__c == "")) ||
         ((this.objProgram.TacitRenewal__c == '1') && (this.objProgram.AdvanceNotice__c == "" )) || ((this.objProgram.LTARenegociation__c == '1') && (this.objProgram.EarlyTerminationDate__c == "" ))
         || (this.objProgram.LossDeposit__c == '1' && (this.objProgram.LossDepositLevel__c == null || this.objProgram.LossDepositLevel__c == "" || this.objProgram.LossDepositLevel__c == undefined))
         ){
            this.dispatchEvent(new ShowToastEvent({title: 'ERROR', message: this.label.Required_Fields, variant: 'error'}),);
            this.spinner = false;
            if(this.objProgram.Name == ""){
                this.nameEmpty = true;
            }

            if(this.objProgram.InceptionDate__c == ""){
                this.inceptionDateEmpty = true;
            }
            else{
                this.inceptionDateEmpty = false;
            }

            if(this.objProgram.Expirydate__c == ""){
                this.expiryDateEmpty = true;
            }
            else{
                this.expiryDateEmpty = false;
            }

            if(this.objProgram.Nature__c == null){
                this.natureEmpty = true;
            }
            if(this.objProgram.LossDeposit__c == null){
                this.lossDepositEmpty = true;
            }
            if(this.objProgram.Macro_L_O_B__c == null){
                this.macroLobEmpty = true;
            }

            if(this.objProgram.LossDeposit__c == '1' && (this.objProgram.LossDepositLevel__c == null || this.objProgram.LossDepositLevel__c == "" || this.objProgram.LossDepositLevel__c == undefined)){
                this.lossDepositLevelEmpty = true;
            }

            if(this.objProgram.STLT__c == null){
                this.stltEmpty = true;
            }
            if(this.objProgram.LTA__c == null){
                this.ltaEmpty = true;
            }
            if(this.objProgram.TacitRenewal__c == null){
                this.tacitRenewEmpty = true;
            }
            if((this.objProgram.LTA__c == '1') && (this.objProgram.LTAExpiryDate__c == "")){
                this.ltaExpiryDateEmpty = true;
            }
            else{
                this.ltaExpiryDateEmpty = false;
            }

            if((this.objProgram.TacitRenewal__c == '1') && (this.objProgram.AdvanceNotice__c == "")){
                this.advanceNoticeEmpty = true;
            }
            else{
                this.advanceNoticeEmpty = false;
            }

            if((this.objProgram.LTARenegociation__c == '1') && (this.objProgram.EarlyTerminationDate__c == "")){
                this.ltaEarlyTerminationDateEmpty = true;
            }
            else{
                this.ltaEarlyTerminationDateEmpty = false;
            }
        }
        else if(this.uwYearOpenModal != dataInput.InceptionDate.split('-')[0]){
            this.spinner = false;
            this.dispatchEvent(new ShowToastEvent({title: 'ERROR', message: this.label.InceptionDate_Error, variant: 'error'}),);
            this.inceptionDateEmpty = true;
        }
        else if( this.objProgram.LossDepositLevel__c == 'Program' && this.objProgram.LossDepositMode__c.length == 0){
            this.spinner = false;
            this.dispatchEvent(new ShowToastEvent({title: 'ERROR', message: this.label.LossDept_Program, variant: 'error'}),);
        }
        else{
            this.ltaExpiryDateEmpty = false;
            this.advanceNoticeEmpty = false;
            this.ltaEarlyTerminationDateEmpty = false;
            this.inceptionDateEmpty = false;
            this.expiryDateEmpty = false;

            if(this.lstAccountIdCovCedingCom.length == 0){
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: this.label.Ceded_Company_Empty,
                        variant: 'error'
                    }),
                );
                this.spinner = false;
            }
            else{
                let numDaysEarlyTerm = 0;
                let numDaysExpiryDate = 0;
                let numDaysLTAExpiryDate = 0;
                let isLTAInceptionExpiryDateLeap = false;

                if(this.objProgram.LTA__c == '1'){
                    if(this.objProgram.LTAInceptionDate__c != "" ){
                        let ltaInceptionDate = new Date(this.objProgram.LTAInceptionDate__c+'T00:00');
                        let utcLtaInceptionDate = Date.UTC(ltaInceptionDate.getFullYear(), ltaInceptionDate.getMonth(), ltaInceptionDate.getDate());

                        if(this.objProgram.EarlyTerminationDate__c != ""){
                            let earlyTerminationDate = new Date(this.objProgram.EarlyTerminationDate__c+'T00:00');
                            let utcEarlyTerminationDate = Date.UTC(earlyTerminationDate.getFullYear(), earlyTerminationDate.getMonth(), earlyTerminationDate.getDate());
                            numDaysEarlyTerm = Math.floor((utcEarlyTerminationDate - utcLtaInceptionDate) / (1000 * 60 * 60 * 24));
                        }

                        if(this.objProgram.Expirydate__c != ""){
                            let expiryDate = new Date(this.objProgram.Expirydate__c+'T00:00');
                            let utcExpiryDate = Date.UTC(expiryDate.getFullYear(), expiryDate.getMonth(), expiryDate.getDate());
                            numDaysExpiryDate = Math.floor((utcExpiryDate - utcLtaInceptionDate) / (1000 * 60 * 60 * 24));
                        }

                        if(this.objProgram.LTAExpiryDate__c != ""){
                            let ltaExpiryDate = new Date(this.objProgram.LTAExpiryDate__c+'T00:00');
                            let utcLTAExpiryDate = Date.UTC(ltaExpiryDate.getFullYear(), ltaExpiryDate.getMonth(), ltaExpiryDate.getDate());
                            numDaysLTAExpiryDate = Math.floor((utcLTAExpiryDate - utcLtaInceptionDate) / (1000 * 60 * 60 * 24)) + 1;

                            let isLTAExpiryDateIsLeap = this.isYearLeap(ltaExpiryDate.getFullYear());
                            let isLTAIncepDateIsLeap = this.isYearLeap(ltaInceptionDate.getFullYear());
                            let yearBtwLTAIncepExp = (ltaExpiryDate.getFullYear() + ltaInceptionDate.getFullYear()) / 2;
                            let isYearBtwLeap = this.isYearLeap(yearBtwLTAIncepExp);

                            if(isLTAExpiryDateIsLeap == true || isLTAIncepDateIsLeap == true || isYearBtwLeap == true){
                                isLTAInceptionExpiryDateLeap = true;
                            }
                            else{
                                isLTAInceptionExpiryDateLeap = false;
                            }
                        }
                    }
                }

                checkForFebruaryLeapYear({ltaInceptionDate : this.objProgram.LTAInceptionDate__c, ltaExpiryDate : this.objProgram.LTAExpiryDate__c})
                .then(result => {
                    this.countLeapFebruary = result;
                    if(this.objProgram.LTA__c == '1' && this.objProgram.LTAInceptionDate__c != "" && this.objProgram.EarlyTerminationDate__c != "" && (numDaysEarlyTerm <= 0)){
                        this.spinner = false;
                        this.dispatchEvent(new ShowToastEvent({title: 'ERROR', message: this.label.LTA_Error, variant: 'error'}),);
                    }
                    else if(this.objProgram.Expirydate__c < this.objProgram.InceptionDate__c){
                        this.spinner = false;
                        this.dispatchEvent(new ShowToastEvent({title: 'ERROR', message: this.label.ExpiryDate_Error, variant: 'error'}),);
                    }
                    else if(this.objProgram.LTA__c == '1' && this.objProgram.LTAInceptionDate__c != "" && this.objProgram.Expirydate__c != "" && (numDaysExpiryDate <= 0)){
                        this.spinner = false;
                        this.dispatchEvent(new ShowToastEvent({title: 'ERROR', message: this.label.LTAInception_Error, variant: 'error'}),);
                    }
                    else if(this.objProgram.LTA__c == '1' && this.objProgram.LTAInceptionDate__c != "" && this.objProgram.LTAExpiryDate__c != "" && (numDaysLTAExpiryDate < 731) && this.countLeapFebruary > 0){
                        this.spinner = false;
                        this.dispatchEvent(new ShowToastEvent({title: 'ERROR', message: this.label.LTA_minPeriod, variant: 'error'}),);
                    }
                    else if(this.objProgram.LTA__c == '1' && this.objProgram.LTAInceptionDate__c != "" && this.objProgram.LTAExpiryDate__c != "" && (numDaysLTAExpiryDate < 730)){
                        this.spinner = false;
                        this.dispatchEvent(new ShowToastEvent({title: 'ERROR', message: this.label.LTA_minPeriod, variant: 'error'}),);
                    }
                    //AMI 02/06/22: W-0942
                    //Adding "LTARenegociation__c" param so as to execute verification only if renegociation is selected
                    else if( this.objProgram.LTA__c == '1' && this.objProgram.LTARenegociation__c === '1' && (this.objProgram.EarlyTerminationDate__c < this.objProgram.InceptionDate__c || this.objProgram.EarlyTerminationDate__c > this.objProgram.LTAExpiryDate__c) ){
                        this.spinner = false;
                        this.dispatchEvent(new ShowToastEvent({title: 'ERROR', message: 'The Early Termination Date should be between Inception Date and LTA Expiry Date', variant: 'error'}),);
                    }
                    else{
                        checkProgramName({ programName : dataInput.Name.trim(), programId : this.selectedProgramId, isProgramCopy : this.isProgramCopy, valueUWYear : this.uwYearOpenModal})
                        .then(result => {
                            if(result == true){
                                this.spinner = false;
                                this.nameEmpty = true;
                                this.Name = dataInput.Name.trim();
                                this.template.querySelector('[data-id="ProgramName"]').value = dataInput.Name.trim();
                                if(this.isProgramCopy == true && this.Name == dataInput.Name.trim()){
                                    this.dispatchEvent(new ShowToastEvent({title: 'ERROR', message: this.label.ProgName_Unchanged, variant: 'error'}),);
                                }else{
                                    this.dispatchEvent(new ShowToastEvent({title: 'ERROR', message: this.label.ProgName_Exists, variant: 'error'}),);
                                }
                            }else{
                                saveProgramRecord({ objProg : this.objProgram, lstAccIdCovCedCom : this.lstAccountIdCovCedingCom, programId : this.selectedProgramId, editProgram : this.isProgramEdit})
                                .then(result => {
                                    if(result.hasOwnProperty('Error') && result.Error){
                                        this.dispatchEvent(new ShowToastEvent({title: 'Error', message: result.Error, variant: 'error' }),);
                                    }
                                    else{
                                        fireEvent(this.pageRef, 'refreshActorRef', 'refresh');
                                        if(this.isProgramEdit || (this.isProgramEdit && this.conditionPage)){
                                            this.dispatchEvent(new ShowToastEvent({title: 'Success', message: this.label.Program_Updated, variant: 'success' }),);
                                            if(this.isProgramEdit && this.conditionPage == false){
                                                this[NavigationMixin.Navigate]({
                                                    type: 'standard__recordPage',
                                                    attributes: {
                                                    recordId: this.selectedProgramId,
                                                    objectApiName: 'Program__c',
                                                    actionName: 'view',
                                                },});
                                            }
                                        }
                                        else{
                                            this.dispatchEvent(new ShowToastEvent({title: 'Success', message: this.label.Program_Created, variant: 'success' }),);
                                        }
                                    }
                                    if((this.createPage =='yes' || this.isProgramEdit) && this.conditionPage == false){
                                        window.history.back();
                                        return false;
                                    }
                                    else if(this.conditionPage){
                                    }
                                    else{
                                        fireEvent(this.pageRef, 'closeProgramModal', false);
                                        fireEvent(this.pageRef, 'refreshProgram', 'refresh');
                                    }
                                    this.covData = [];
                                    this.spinner = false;
                                })
                                .catch(error => {
                                    this.dispatchEvent(new ShowToastEvent({title: 'ERROR', message: this.label.errorMsg, variant: 'error'}),);
                                    this.spinner = false;
                                });
                            }
                         })
                        .catch(error => {
                            this.spinner = false;
                            this.dispatchEvent(new ShowToastEvent({title: 'ERROR', message: this.label.errorMsg, variant: 'error'}),);
                        });
                    }
                })
                .catch(error => {
                    this.dispatchEvent(new ShowToastEvent({title: 'ERROR', message: this.label.errorMsg, variant: 'error'}),);
                });
            }
        }
    }

    handleSaveProgramTP(){
        this.spinner = true;
        this.objProgram = {};
        let inputs= this.template.querySelectorAll('lightning-input, lightning-dual-listbox');
        let dataInput = {};
        for(let input of inputs){
            dataInput[input.name] = input.value;
        }
        this.objProgram.AdvanceNotice__c = dataInput.AdvanceNotice;
        this.objProgram.EarlyTerminationDate__c = dataInput.EarlyTerminationDate;
        this.objProgram.Expirydate__c = dataInput.ExpiryDate;
        this.objProgram.InceptionDate__c = dataInput.InceptionDate;
        this.objProgram.Name = dataInput.Name;
        this.objProgram.WordingName__c = dataInput.WordingName;
        this.objProgram.PrincipalCedingCompany__c = this.compOpenModal;
        this.objProgram.UwYear__c = this.uwYearOpenModal;
        this.objProgram.WordingName2__c = dataInput.WordingName2;
        this.objProgram.WordingName3__c = dataInput.WordingName3;
        this.objProgram.WordingName4__c = dataInput.WordingName4;
        this.objProgram.LossDepositMode__c = dataInput.LossDepositMode;

        let comboValues= this.template.querySelectorAll('lightning-combobox');
        let dataCombo = {};
        for(let combo of comboValues){
            dataCombo[combo.name] = combo.value;
        }
        this.objProgram.LTA__c = dataCombo.LTA;
        if(this.objProgram.LTA__c == '1'){
            this.objProgram.LTAExpiryDate__c = dataInput.LTA_ExpiryDate;
            this.objProgram.LTAInceptionDate__c = dataInput.LTA_InceptionDate;
        }else{
            this.objProgram.LTAExpiryDate__c = null;
            this.objProgram.LTAInceptionDate__c = null;

        }
        this.objProgram.LTARenegociation__c = dataCombo.LTARenegotiation;
        this.objProgram.LossDeposit__c = dataCombo.LossDeposit;
        this.objProgram.LossDepositLevel__c = dataCombo.LossDepositLevel;
        this.objProgram.Macro_L_O_B__c = dataCombo.MacroLoB;
        this.objProgram.Nature__c = dataCombo.Nature;
        this.objProgram.STLT__c = dataCombo.STLT;
        this.objProgram.TacitRenewal__c = dataCombo.TacitRenewal;


        if (this.covData != undefined){
            for (var i = 0; i < this.covData.length; i++){
                this.lstAccountIdCovCedingCom.push(this.covData[i].recId);
            }
        }

        if(this.objProgram.Name == "" || this.objProgram.InceptionDate__c == "" || this.objProgram.Expirydate__c == "" || this.objProgram.Nature__c == null || this.objProgram.LossDeposit__c == null || this.objProgram.Macro_L_O_B__c == null || this.objProgram.LossDepositLevel__c == null || this.objProgram.STLT__c == null || this.objProgram.LTA__c == null || this.objProgram.TacitRenewal__c == null || ((this.objProgram.LTA__c == '1') && (this.objProgram.LTAExpiryDate__c == "")) || ((this.objProgram.TacitRenewal__c == '1') && (this.objProgram.AdvanceNotice__c == "" )) || ((this.objProgram.LTARenegociation__c == '1') && (this.objProgram.EarlyTerminationDate__c == "" ))
        || (this.objProgram.LossDeposit__c == '1' && (this.objProgram.LossDepositLevel__c == null || this.objProgram.LossDepositLevel__c == "" || this.objProgram.LossDepositLevel__c == undefined))
        ){
            this.dispatchEvent(new ShowToastEvent({title: 'ERROR', message: this.label.Required_Fields, variant: 'error'}),);
            this.spinner = false;
            if(this.objProgram.Name == ""){
                this.nameEmpty = true;
            }

            if(this.objProgram.InceptionDate__c == ""){
                this.inceptionDateEmpty = true;
            }
            else{
                this.inceptionDateEmpty = false;
            }

            if(this.objProgram.Expirydate__c == ""){
                this.expiryDateEmpty = true;
            }
            else{
                this.expiryDateEmpty = false;
            }

            if(this.objProgram.Nature__c == null){
                this.natureEmpty = true;
            }
            if(this.objProgram.LossDeposit__c == null){
                this.lossDepositEmpty = true;
            }
            if(this.objProgram.Macro_L_O_B__c == null){
                this.macroLobEmpty = true;
            }
            if(this.objProgram.LossDepositLevel__c == null){
                this.lossDepositLevelEmpty = true;
            }

            if(this.objProgram.LossDeposit__c == '1' && (this.objProgram.LossDepositLevel__c == null || this.objProgram.LossDepositLevel__c == "" || this.objProgram.LossDepositLevel__c == undefined)){
                this.lossDepositLevelEmpty = true;
            }

            if(this.objProgram.STLT__c == null){
                this.stltEmpty = true;
            }
            if(this.objProgram.LTA__c == null){
                this.ltaEmpty = true;
            }
            if(this.objProgram.TacitRenewal__c == null){
                this.tacitRenewEmpty = true;
            }
            if((this.objProgram.LTA__c == '1') && (this.objProgram.LTAExpiryDate__c == "")){
                this.ltaExpiryDateEmpty = true;
            }
            else{
                this.ltaExpiryDateEmpty = false;
            }

            if((this.objProgram.TacitRenewal__c == '1') && (this.objProgram.AdvanceNotice__c == "")){
                this.advanceNoticeEmpty = true;
            }
            else{
                this.advanceNoticeEmpty = false;
            }

            if((this.objProgram.LTARenegociation__c == '1') && (this.objProgram.EarlyTerminationDate__c == "")){
                this.ltaEarlyTerminationDateEmpty = true;
            }
            else{
                this.ltaEarlyTerminationDateEmpty = false;
            }
        }
        else if ( this.objProgram.LossDepositLevel__c == 'Program' && this.objProgram.LossDepositMode__.length == 0){
            this.spinner = false;
            this.dispatchEvent(new ShowToastEvent({title: 'ERROR', message: this.label.LossDept_Program, variant: 'error'}),);
        }
        else{
            this.ltaExpiryDateEmpty = false;
            this.advanceNoticeEmpty = false;
            this.ltaEarlyTerminationDateEmpty = false;
            this.inceptionDateEmpty = false;
            this.expiryDateEmpty = false;

            if(this.lstAccountIdCovCedingCom.length == 0){
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: this.label.Ceded_Company_Empty,
                        variant: 'error'
                    }),
                );
                this.spinner = false;
            }
            else{
                let numDaysEarlyTerm = 0;
                let numDaysExpiryDate = 0;
                let numDaysLTAExpiryDate = 0;
                let isLTAInceptionExpiryDateLeap = false;

                if(this.objProgram.LTA__c == '1'){
                    if(this.objProgram.LTAInceptionDate__c != "" ){
                        let ltaInceptionDate = new Date(this.objProgram.LTAInceptionDate__c+'T00:00');
                        let utcLtaInceptionDate = Date.UTC(ltaInceptionDate.getFullYear(), ltaInceptionDate.getMonth(), ltaInceptionDate.getDate());

                        if(this.objProgram.EarlyTerminationDate__c != ""){
                            let earlyTerminationDate = new Date(this.objProgram.EarlyTerminationDate__c+'T00:00');
                            let utcEarlyTerminationDate = Date.UTC(earlyTerminationDate.getFullYear(), earlyTerminationDate.getMonth(), earlyTerminationDate.getDate());
                            numDaysEarlyTerm = Math.floor((utcEarlyTerminationDate - utcLtaInceptionDate) / (1000 * 60 * 60 * 24));
                        }

                        if(this.objProgram.Expirydate__c != ""){
                            let expiryDate = new Date(this.objProgram.Expirydate__c+'T00:00');
                            let utcExpiryDate = Date.UTC(expiryDate.getFullYear(), expiryDate.getMonth(), expiryDate.getDate());
                            numDaysExpiryDate = Math.floor((utcExpiryDate - utcLtaInceptionDate) / (1000 * 60 * 60 * 24));
                        }

                        if(this.objProgram.LTAExpiryDate__c != ""){
                            let ltaExpiryDate = new Date(this.objProgram.LTAExpiryDate__c+'T00:00');
                            let utcLTAExpiryDate = Date.UTC(ltaExpiryDate.getFullYear(), ltaExpiryDate.getMonth(), ltaExpiryDate.getDate());
                            numDaysLTAExpiryDate = Math.floor((utcLTAExpiryDate - utcLtaInceptionDate) / (1000 * 60 * 60 * 24)) + 1;

                            let isLTAExpiryDateIsLeap = this.isYearLeap(ltaExpiryDate.getFullYear());
                            let isLTAIncepDateIsLeap = this.isYearLeap(ltaInceptionDate.getFullYear());
                            let yearBtwLTAIncepExp = (ltaExpiryDate.getFullYear() + ltaInceptionDate.getFullYear()) / 2;
                            let isYearBtwLeap = this.isYearLeap(yearBtwLTAIncepExp);

                            if(isLTAExpiryDateIsLeap == true || isLTAIncepDateIsLeap == true || isYearBtwLeap == true){
                                isLTAInceptionExpiryDateLeap = true;
                            }
                            else{
                                isLTAInceptionExpiryDateLeap = false;
                            }
                        }
                    }
                }

                checkForFebruaryLeapYear({ltaInceptionDate : this.objProgram.LTAInceptionDate__c, ltaExpiryDate : this.objProgram.LTAExpiryDate__c})
                .then(result => {
                    this.countLeapFebruary = result;
                    if(this.objProgram.LTA__c == '1' && this.objProgram.LTAInceptionDate__c != "" && this.objProgram.EarlyTerminationDate__c != "" && (numDaysEarlyTerm <= 0)){
                        this.spinner = false;
                        this.dispatchEvent(new ShowToastEvent({title: 'ERROR', message: this.label.LTA_Error, variant: 'error'}),);
                    }
                    else if(this.objProgram.LTA__c == '1' && this.objProgram.LTAInceptionDate__c != "" && this.objProgram.Expirydate__c != "" && (numDaysExpiryDate <= 0)){
                        this.spinner = false;
                        this.dispatchEvent(new ShowToastEvent({title: 'ERROR', message: this.label.LTAInception_Error, variant: 'error'}),);
                    }
                    else if(this.objProgram.LTA__c == '1' && this.objProgram.LTAInceptionDate__c != "" && this.objProgram.LTAExpiryDate__c != "" && (numDaysLTAExpiryDate < 731) && this.countLeapFebruary > 0){
                        this.spinner = false;
                        this.dispatchEvent(new ShowToastEvent({title: 'ERROR', message: this.label.LTA_minPeriod, variant: 'error'}),);
                    }
                    else if(this.objProgram.LTA__c == '1' && this.objProgram.LTAInceptionDate__c != "" && this.objProgram.LTAExpiryDate__c != "" && (numDaysLTAExpiryDate < 730)){
                        this.spinner = false;
                        this.dispatchEvent(new ShowToastEvent({title: 'ERROR', message: this.label.LTA_minPeriod, variant: 'error'}),);
                    }
                    else if(this.objProgram.Expirydate__c < this.objProgram.InceptionDate__c){
                        this.spinner = false;
                        this.dispatchEvent(new ShowToastEvent({title: 'ERROR', message: this.label.ExpiryDate_Error, variant: 'error'}),);
                    }
                    else{
                        checkProgramName({ programName : dataInput.Name, programId : this.selectedProgramId, isProgramCopy : this.isProgramCopy, valueUWYear : this.uwYearOpenModal})
                        .then(result => {
                            if(result == true){
                                this.spinner = false;
                                this.nameEmpty = true;
                                this.Name = dataInput.Name.trim();
                                this.dispatchEvent(new ShowToastEvent({title: 'ERROR', message: this.label.ProgName_Exists, variant: 'error'}),);
                            }else{
                                saveProgramRecord({ objProg : this.objProgram, lstAccIdCovCedCom : this.lstAccountIdCovCedingCom, programId : this.selectedProgramId, editProgram : this.isProgramEdit})
                                .then(result => {
                                    if(result.hasOwnProperty('Error') && result.Error){
                                        this.dispatchEvent(new ShowToastEvent({title: 'Error', message: result.Error, variant: 'error' }),);
                                    }else{
                                        if(this.isProgramEdit || (this.isProgramEdit && this.conditionPage)){
                                            this.dispatchEvent(new ShowToastEvent({title: 'Success', message: this.label.Program_Updated, variant: 'success' }),);
                                        }
                                        else{
                                            this.dispatchEvent(new ShowToastEvent({title: 'Success', message: this.label.Program_Created, variant: 'success' }),);
                                        }
                                    }
                                    if( (this.createPage =='yes' || this.isProgramEdit) && this.conditionPage == false){
                                        window.history.back();
                                        return false;
                                    }
                                    else if(this.conditionPage){
                                    }
                                    else{
                                        fireEvent(this.pageRef, 'closeProgramModal', false);
                                        fireEvent(this.pageRef, 'refreshProgram', 'refresh');
                                    }
                                    this.covData = [];
                                    this.spinner = false;
                                })
                                .catch(error => {
                                    this.dispatchEvent(new ShowToastEvent({title: 'ERROR', message: this.label.errorMsg, variant: 'error'}),);
                                    this.spinner = false;
                                });
                            }
                        })
                        .catch(error => {
                            this.spinner = false;
                            this.dispatchEvent(new ShowToastEvent({title: 'ERROR', message: this.label.errorMsg, variant: 'error'}),);
                        });
                    }
                })
                .catch(error => {
                    this.dispatchEvent(new ShowToastEvent({title: 'ERROR', message: this.label.errorMsg, variant: 'error'}),);
                });
            }
        }
    }

    lossDepModeChanged(event){
        this.lossDepositModeChanged = true;
    }

    handleCloseProgramModal(){
        if(this.createPage =='yes' || this.isProgramEdit){
            window.history.back();
            return false;
        }
        else{
            fireEvent(this.pageRef, 'closeProgramModal', false);
        }
    }

    getUniqueData(arr, comp) {
        const unique = arr.map(e => e[comp])
                          .map((e, i, final) => final.indexOf(e) === i && i)
                          .filter(e => arr[e]).map(e => arr[e]);
        return unique;
    }

    handleRenegotiationChange(event){
        this.LTARenegotiationValue = event.detail.value;
        if(this.LTARenegotiationValue == '1'){
            this.disableEarlyTerminationDate = false;
        }
        else{
            this.disableEarlyTerminationDate = true;
            this.EarlyTerminationDate = null;
        }
    }

    handleChangeExpDate(event){
        this.Expirydate = event.detail.value;
    }

    handleChangeLTAExpDate(event){
        this.LTAExpiryDate = event.detail.value;
        this.EarlyTerminationDate = null;
        let expDate = new Date(event.target.value+'T00:00');
        expDate.setDate(expDate.getDate() - 1);

        let month = (expDate.getMonth()+1).toString();
        if(month.length == 1){
            month = '0' + month;
        }

        let day = (expDate.getDate()).toString();
        if(day.length == 1){
            day = '0' + day;
        }

        this.maxEarlyTermDate = expDate.getFullYear()+'-'+month+'-'+day;
    }

    getCoveredCedingCompaniesEdit(selectedProgramId){
        getCoveredCedingCompaniesEdit({ programId : selectedProgramId})
        .then(result => {
            this.covData = result;
            var newData = [];
            for (var i = 0; i < this.covData.length; i++) {
                var row = [];
                row['recName'] = this.covData[i].Account__r.Name;
                row['recId'] = this.covData[i].Account__r.Id;
                newData.push(row);
            }
            this.covData = newData;
            this.titleCoveredCedingCompanies = this.label.CoveredCedingCompanies + ' (' + this.covData.length + ')';
        })
        .catch(error => {
            this.dispatchEvent(new ShowToastEvent({title: 'ERROR', message: this.label.errorMsg, variant: 'error'}),);
        });
    }

    getAllExistedCoveredCedingComForTreaty(selectedProgramId){
        getAllExistedCoveredCedingComForTreaty({ programId : selectedProgramId})
        .then(result => {
            let lstExistingAccountIdTreaties = result;
            this.setExistingAccountIdTreaties = new Set();

            for(let i = 0; i < lstExistingAccountIdTreaties.length; i++){
                this.setExistingAccountIdTreaties.add(lstExistingAccountIdTreaties[i]);
            }
        })
        .catch(error => {
            this.dispatchEvent(new ShowToastEvent({title: 'ERROR', message: this.label.errorMsg, variant: 'error'}),);
        });
    }

    checkIfProgramEmptyOnChangeValue(){
        isProgramEmpty({ uwYear : this.uwYearOpenModal, principalCedingCompany : this.compOpenModal})
        .then(result => {
            if(result == true){
                this.covData = [];
                this.isProgramEdit = false;
            }
            this.titleCoveredCedingCompanies = this.label.CoveredCedingCompanies + ' (' + this.covData.length + ')';
        })
        .catch(error => {
            this.dispatchEvent(new ShowToastEvent({title: 'ERROR', message: this.label.errorMsg, variant: 'error'}),);
        });
    }

    handleLossDepLevel(event){
        this.lossDepLevelChanges = true;
        this.lossDepLevelVal = event.target.value;
        if(this.lossDepLevelVal == 'Treaty' && this.lossDepositModeEmpty == true){
            this.lossDepositModeEmpty = false;
        }
        if (this.lossDepLevelVal=='Treaty')//added by DMO 11/3/2020 - Au niveau du programme lorsque Loss deposit level = treaty alors le champ Loss deposit mode devrait être grisé
        {
            this.LossDepositModeValue = '';
            this.disabledLossDepoMode = true;
            
        }
        else
            this.disabledLossDepoMode = false;
    }

    get lossDepModeRequired(){
        if(this.lossDepLevelVal == 'Program'){
            return true;
        }
        else{
            return false;
        }
    }

    isYearLeap(year){
        return new Date(year, 1, 29).getDate() === 29;
    }

    sortFields(fieldName, lstData, sortDirection) {
        let sortResult = Object.assign([], lstData);
        let lstSortedData = sortResult.sort(function(a,b){
            if(a[fieldName] < b[fieldName])
                return sortDirection === 'asc' ? -1 : 1;
            else if(a[fieldName] > b[fieldName])
                return sortDirection === 'asc' ? 1 : -1;
            else{
                return 0;
            }
        })
        return lstSortedData;
    }
}