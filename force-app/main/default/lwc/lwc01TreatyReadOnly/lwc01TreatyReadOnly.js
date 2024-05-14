import {LightningElement, track, wire, api} from 'lwc';
import {refreshApex} from '@salesforce/apex';
import {registerListener, fireEvent} from 'c/pubSub';
import {NavigationMixin, CurrentPageReference} from 'lightning/navigation';
import {getObjectInfo} from 'lightning/uiObjectInfoApi';
import {getPicklistValues, getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import getProgram from '@salesforce/apex/LWC01_NewTreaty.getProgram';
import getCovCedComByProgramId from '@salesforce/apex/LWC01_NewTreaty.getCovCedComByProgramId';
import getAllExistedCoveredCedingComForSection from '@salesforce/apex/LWC01_NewTreaty.getAllExistedCoveredCedingComForSection';
import getCovCedComByTreatyId from '@salesforce/apex/LWC01_NewTreaty.getCovCedComByTreatyId';
import getProgramDetails from '@salesforce/apex/LWC01_NewTreaty.getProgramDetails';
import getPoolsByTreatyId from '@salesforce/apex/LWC01_NewTreaty.getPoolsByTreatyId';
import getPools from '@salesforce/apex/LWC01_NewTreaty.getPools';
import saveTreatyRecord from '@salesforce/apex/LWC01_NewTreaty.saveTreatyRecord';
import getActorReferenceIndex from '@salesforce/apex/LWC01_NewTreaty.getActorReferenceIndex';
import checkTreatyName from '@salesforce/apex/LWC01_NewTreaty.checkTreatyName';
import checkFieldsVisibility from '@salesforce/apex/LWC01_NewTreaty.checkFieldsVisibility';

//import field
import TREATY_OBJECT from '@salesforce/schema/Treaty__c';
import LTA_FIELD from '@salesforce/schema/Treaty__c.LTA__c';
import LTARENEGO_FIELD from '@salesforce/schema/Treaty__c.LTARenegotiation__c';
import LTAPATTERN_FIELD from '@salesforce/schema/Treaty__c.LTAPattern__c';
import TACITRENEWAL_FIELD from '@salesforce/schema/Treaty__c.TacitRenewal__c';
import TYPEOFTREATY_FIELD from '@salesforce/schema/Treaty__c.TypeofTreaty__c';
import TYPEOFREINSURANCE_FIELD from '@salesforce/schema/Treaty__c.TypeofReinsurance__c';
import LOSSDEPOSIT_FIELD from '@salesforce/schema/Treaty__c.LossDeposit__c';
import PREMIUMDEPOSIT_FIELD from '@salesforce/schema/Treaty__c.PremiumDeposit__c';
import LOSSDEPOSITMODE_FIELD from '@salesforce/schema/Treaty__c.LossDepositMode__c';
import DEDUCTION_FIELD from '@salesforce/schema/Treaty__c.Deductions__c';
import ISPOOLED_FIELD from '@salesforce/schema/Treaty__c.IsPooled__c';
import PROGRAMNAME_FIELD from '@salesforce/schema/Treaty__c.Program__c';
import TREATYNAME_FIELD from '@salesforce/schema/Treaty__c.Name';
import WORDINGNAME_FIELD from '@salesforce/schema/Treaty__c.WordingName__c';
import WORDINGNAME2_FIELD from '@salesforce/schema/Treaty__c.WordingName2__c';
import WORDINGNAME3_FIELD from '@salesforce/schema/Treaty__c.WordingName3__c';
import WORDINGNAME4_FIELD from '@salesforce/schema/Treaty__c.WordingName4__c';
import INCEPDATE_FIELD from '@salesforce/schema/Treaty__c.Inceptiondate__c';
import EXPIRYDATE_FIELD from '@salesforce/schema/Treaty__c.Expirydate__c';
import ACTORREF_FIELD from '@salesforce/schema/Treaty__c.Actor_Reference__c';
import TREATYREF_FIELD from '@salesforce/schema/Treaty__c.TreatyReference__c';
import LTAINCEPTDATE_FIELD from '@salesforce/schema/Treaty__c.LTAInceptionDate__c';
import LTAEXPDATE_FIELD from '@salesforce/schema/Treaty__c.LTAExpiryDate__c';
import EARLYTERMDATE_FIELD from '@salesforce/schema/Treaty__c.EarlyTerminationDate__c';
import ADVNOTICE_FIELD from '@salesforce/schema/Treaty__c.Advance_notice__c';
import LAYERNUM_FIELD from '@salesforce/schema/Treaty__c.Layer__c';
import LOSSATTACH_FIELD from '@salesforce/schema/Treaty__c.LossAttachment__c';
import PLACEMENTSHARE_FIELD from '@salesforce/schema/Treaty__c.PlacementShare_Perc__c';
import NOTMANAGED_FIELD from '@salesforce/schema/Treaty__c.NotManagedByAgre__c';
import DEDUCTIONPERC_FIELD from '@salesforce/schema/Treaty__c.Deductions_Perc__c';
import WEBXLREF_FIELD from '@salesforce/schema/Treaty__c.WebXLReference__c';

//import field for pool
import POOLNAME_FIELD from '@salesforce/schema/Pool__c.Name';
import SHARERATE_FIELD from '@salesforce/schema/Pool__c.ShareRate__c';
import YEAR_FIELD from '@salesforce/schema/Pool__c.Year__c';

//import custom labels
import CoveredCedingCompanies from '@salesforce/label/c.CoveredCedingCompanies';
import ActorReferenceIndex from '@salesforce/label/c.ActorReferenceIndex';
import ProgramName from '@salesforce/label/c.ProgramName';
import Name from '@salesforce/label/c.Name';
import WordingName from '@salesforce/label/c.WordingName';
import InceptionDate from '@salesforce/label/c.InceptionDate';
import ExpiryDate from '@salesforce/label/c.ExpiryDate';
import ActorReference from '@salesforce/label/c.ActorReference';
import TreatyRef from '@salesforce/label/c.TreatyRef';
import LTAInformation from '@salesforce/label/c.LTAInformation';
import LTA from '@salesforce/label/c.LTA';
import LTAInceptionDate from '@salesforce/label/c.LTA_InceptionDate';
import LTAExpiryDate from '@salesforce/label/c.LTA_ExpiryDate';
import LTARenegotiation from '@salesforce/label/c.LTA_Renegotiation';
import EarlyTerminationDate from '@salesforce/label/c.EarlyTerminationDate';
import TacitRenewal from '@salesforce/label/c.TacitRenewal';
import AdvanceNotice from '@salesforce/label/c.AdvanceNotice';
import Type from '@salesforce/label/c.Type';
import LayerNumber from '@salesforce/label/c.LayerNumber';
import TypeOfReinsurance from '@salesforce/label/c.TypeOfReinsurance';
import LossAttachment from '@salesforce/label/c.LossAttachment';
import PlacementShare from '@salesforce/label/c.PlacementShare';
import Deductions from '@salesforce/label/c.Deductions';
import NotManagedByAgre from '@salesforce/label/c.NotManagedByAgre';
import DeductionsPerc from '@salesforce/label/c.DeductionsPerc';
import LossDeposit from '@salesforce/label/c.LossDeposit';
import LossDepositMode from '@salesforce/label/c.LossDepositMode';
import PremiumDeposit from '@salesforce/label/c.PremiumDeposit';
import Pooled from '@salesforce/label/c.Pooled';
import New from '@salesforce/label/c.New';
import Delete from '@salesforce/label/c.Delete';
import Cancel from '@salesforce/label/c.Cancel';
import Save from '@salesforce/label/c.Save';
import Close from '@salesforce/label/c.Close';
import Add  from '@salesforce/label/c.Add';
import TR_date from '@salesforce/label/c.TR_date';
import TreatyNameCopy from '@salesforce/label/c.TreatyNameCopy';
import Required_Fields from '@salesforce/label/c.Required_Fields';

import TreatyName_Unchanged from '@salesforce/label/c.TreatyName_Unchanged';
import TreatyName_Exists from '@salesforce/label/c.TreatyName_Exists';
import EmptyPool from '@salesforce/label/c.EmptyPool';
import lossDeptTreaty from '@salesforce/label/c.lossDeptTreaty';
import TotalPoolError from '@salesforce/label/c.TotalPoolError';
import PlacementError from '@salesforce/label/c.PlacementError';
import DeductError from '@salesforce/label/c.DeductError';
import TreatyUpdate from '@salesforce/label/c.TreatyUpdate';
import TreatyCreated from '@salesforce/label/c.TreatyCreated';
import FormEntriesInvalid from '@salesforce/label/c.FormEntriesInvalid';
import Ceded_Company_Empty from '@salesforce/label/c.Ceded_Company_Empty';
import DecimalPlacesErrorMessage from '@salesforce/label/c.DecimalPlacesErrorMessage';
import NumberErrorMessage from '@salesforce/label/c.NumberErrorMessage';
import maxHundredErrorMessage from '@salesforce/label/c.maxHundredErrorMessage';
import minHundredErrorMessage from '@salesforce/label/c.minHundredErrorMessage';
import TreatyTypeHelpText from '@salesforce/label/c.TreatyTypeHelpText';
import PlacementShareTypeHelpText from '@salesforce/label/c.PlacementShareTypeHelpText';
import twoDpErrorMessage from '@salesforce/label/c.twoDpErrorMessage';
import cocessionFieldsTotal from '@salesforce/label/c.cocessionFieldsTotal';
import errorMsg from '@salesforce/label/c.errorMsg';

const columns = [
      { label: 'Name', fieldName: 'AccountName'}
  ];

export default class LWC01_TreatyReadOnly extends NavigationMixin(LightningElement) {
    label = {
        CoveredCedingCompanies,
        ActorReferenceIndex,
        ProgramName,
        Name,
        WordingName,
        InceptionDate,
        ExpiryDate,
        ActorReference,
        TreatyRef,
        LTAInformation,
        LTA,
        LTAInceptionDate,
        LTAExpiryDate,
        LTARenegotiation,
        EarlyTerminationDate,
        TacitRenewal,
        AdvanceNotice,
        Type,
        LayerNumber,
        TypeOfReinsurance,
        LossAttachment,
        PlacementShare,
        Deductions,
        NotManagedByAgre, //RRA - ticket 1345 - 02122022
        DeductionsPerc,
        LossDeposit,
        LossDepositMode,
        PremiumDeposit,
        Pooled,
        New,
        Delete,
        Cancel,
        Save,
        Close,
        Add,
        TR_date,
        TreatyNameCopy,
        Required_Fields,
        TreatyName_Unchanged,
        TreatyName_Exists,
        EmptyPool,
        lossDeptTreaty,
        TotalPoolError,
        PlacementError,
        DeductError,
        TreatyUpdate,
        TreatyCreated,
        FormEntriesInvalid,
        Ceded_Company_Empty,
        DecimalPlacesErrorMessage,
        NumberErrorMessage,
        maxHundredErrorMessage,
        minHundredErrorMessage,
        TreatyTypeHelpText,
        PlacementShareTypeHelpText,
        twoDpErrorMessage,
        cocessionFieldsTotal,
        errorMsg
    }

    @api uwYearOpenModal;
    @api compOpenModal;
    @api selectedPrograms;
    @api isTreatyEdit = false;
    @api createPage = false;
    @api recordId;
    @api uwYearActorRef = null;
    @api isTreatyCopy = false;
    @api selectedRowTreaty;
    @track selectedLossDepositMode = [];
    @track lossDepositModeOpt2Arr = [];
    @track selectedCedCompIds = [];
    @track lstPool = [];
    @track setExistingAccountIdSections = new Set();
    ltaRenegOpt;
    ltaOpt;
    LtaPattern;
    ltaPatternOpt;
    TacitRenewalOpt;
    TypeOfTreatyOpt;
    TypeOfReinsuranceOpt;
    LossDepositOpt;
    PremiumDepositOpt;
    lossDepositModeOpt;
    DeductionOpt;
    LossAttachmentOpt;
    PooledOpt;
    ProgramName;
    InceptionDate;
    ExpiryDate;
    ActorReference;
    LTA;
    LTAInceptionDate;
    LTAExpiryDate;
    LTARenegotiation;
    EarlyTerminationDate;
    TacitRenewal;
    AdvanceNotice;
    program;
    programId;
    data;
    disableLTAPattern = true;
    columns = columns;
    selectedCoveredCedCom;
    dataPools;
    isPoolModalOpen = false;
    lstPools;
    selectedPool;
    nameEmpty = false;
    lossDepositEmpty = false;
    treatyRefEmpty = false;
    typeOfTreatyEmpty = false;
    typeOfReinsuranceEmpty = false;
    LTAPatternEmpty = false;
    layerEmpty = false;
    depositModeEmpty = false;
    premiumDepositEmpty = false;
    placementShareEmpty = false;
    lossAttachmentEmpty = false;
    pooledEmpty = false;
    deductionsEmpty = false;
    deductionsPercEmpty = false;
    PooledValue;
    LayerNumber;
    wiredActorReference;
    lastActorReference;
    lossDepositModeOpt2;
    deductionPercRequired;
    TRInceptiondate;
    spinnerTreaty = false;
    //variables for picklist dependency (Type of Treaty and Type of Reinnsurance)
    @track controllingTreatyValues = [];
    controlReinsuranceValues;
    totalDependentReinsuranceValues = []
    @track dependentReinsuranceValues = [];
    selectedTreaty;
    selectedReinsurance;
    isEmpty = true;
    selectedTreatyId = null;
    LossAttachmentValue;
    isPooled;
    DeductionsValue;
    LossDepositValue;
    PremiumDepositValue;
    lossDepositModeDisabled;
    lossDepositModeRequired;
    lossDepositDisabled;
    deductionDisabled;
    premiumRequired = false;
    premiumDisabled = true;
    titlePools = 'Pools (0)';
    titleCoveredCedingCompanies = this.label.CoveredCedingCompanies + ' (0)';
    totalTreatyPoolShare = 0;
    disableTreatyTypeField = false;
    disablePlacementShare = false;
    disableTreatyReferenceRenew = false;
    closePreviousPhasesClick = false;
    poolShareValueChange = false;

    @track objTreaty = {
        Program__c : PROGRAMNAME_FIELD,
        Name : TREATYNAME_FIELD,
        WordingName__c : WORDINGNAME_FIELD,
        WordingName2__c : WORDINGNAME2_FIELD,
        WordingName3__c : WORDINGNAME3_FIELD,
        WordingName4__c : WORDINGNAME4_FIELD,
        Inceptiondate__c : INCEPDATE_FIELD,
        Expirydate__c : EXPIRYDATE_FIELD,
        Actor_Reference__c : ACTORREF_FIELD,
        TreatyReference__c : TREATYREF_FIELD,
        TECH_LTA__c : LTA_FIELD,
        LTAInceptionDate__c	: LTAINCEPTDATE_FIELD,
        LTAExpiryDate__c : LTAEXPDATE_FIELD,
        LTARenegotiation__c : LTARENEGO_FIELD,
        LTAPattern__c : LTAPATTERN_FIELD,
        EarlyTerminationDate__c : EARLYTERMDATE_FIELD,
        TacitRenewal__c : TACITRENEWAL_FIELD,
        Advance_notice__c : ADVNOTICE_FIELD,
        TypeofTreaty__c : TYPEOFTREATY_FIELD,
        Layer__c : LAYERNUM_FIELD,
        TypeofReinsurance__c : TYPEOFREINSURANCE_FIELD,
        LossAttachment__c : LOSSATTACH_FIELD,
        PlacementShare_Perc__c : PLACEMENTSHARE_FIELD,
        Deductions__c : DEDUCTION_FIELD,
        NotManagedByAgre__c : NOTMANAGED_FIELD,
        Deductions_Perc__c : DEDUCTIONPERC_FIELD,
        LossDeposit__c : LOSSDEPOSIT_FIELD,
        LossDepositMode__c : LOSSDEPOSITMODE_FIELD,
        PremiumDeposit__c : PREMIUMDEPOSIT_FIELD,
        WebXLReference__c : WEBXLREF_FIELD,
        IsPooled__c : ISPOOLED_FIELD
    };

    @track objPool = {
        Name : POOLNAME_FIELD,
        ShareRate__c : SHARERATE_FIELD,
        Year__c : YEAR_FIELD,
    }

    @wire(CurrentPageReference) pageRef;
    connectedCallback(){
        registerListener('year', this.getVal, this);
        registerListener('comp', this.getComp, this);
        registerListener('refreshActorRef', this.refreshWiredLastActorReference, this);

        if(this.isTreatyCopy == true || this.isTreatyEdit == true){
            let lossDepositValue;
            let lossDepositLevelValue;
            let lossDepositModeValue;

            checkFieldsVisibility({selectedTreatyId: this.selectedRowTreaty.Id})
            .then(result => {
                this.disableTreatyTypeField = result['Type'];
                if(this.isTreatyEdit == true){
                    this.disablePlacementShare = result['PlacementShare'];
                }
            })
            .catch(error => {
                this.error = error;
            });

            if(this.isTreatyEdit == true){
                this.programId = this.selectedPrograms;
                getProgramDetails({treatyId: this.selectedRowTreaty.Id})
                .then(result => {

                    if(result[0].Program__r.TECH_ShowClosePreviousPhaseBtn__c == '2'){
                        this.closePreviousPhasesClick = true;
                    }

                    if(result[0].Program__r.RenewedFromProgram__c != null && result[0].Program__r.RenewedFromProgram__c != undefined){
                        this.disableTreatyReferenceRenew = true;
                    }

                    this.ProgramName = result[0].Program__r.Name;
                    this.uwYearOpenModal = result[0].Program__r.UwYear__c;
                    this.uwYearActorRef = result[0].Program__r.UwYear__c;
                    this.compOpenModal = result[0].Program__r.PrincipalCedingCompany__c;
                    this.isPooled = result[0].IsPooled__c;
                    this.objTreaty.Actor_Reference__c = this.selectedRowTreaty.Actor_Reference__c;
                    this.objTreaty.WebXLReference__c = this.selectedRowTreaty.WebXLReference__c;
                    this.objTreaty.TreatyReference__c = this.selectedRowTreaty.TreatyReference__c;
                    this.objTreaty.LTAPattern__c = this.selectedRowTreaty.LTAPattern__c;
                    this.objTreaty.TECH_LTA__c = result[0].Program__r.LTA__c;
                    this.objTreaty.LTAInceptionDate__c = result[0].Program__r.LTAInceptionDate__c;
                    this.objTreaty.LTAExpiryDate__c = result[0].Program__r.LTAExpiryDate__c;
                    this.objTreaty.LTARenegotiation__c = result[0].Program__r.LTARenegociation__c;
                    this.objTreaty.EarlyTerminationDate__c = result[0].Program__r.EarlyTerminationDate__c;
                    this.objTreaty.TacitRenewal__c = result[0].Program__r.TacitRenewal__c;
                    this.objTreaty.Advance_notice__c = result[0].Program__r.AdvanceNotice__c;
                    this.objTreaty.AGRe_Cession__c = this.selectedRowTreaty.AGRe_Cession__c;
                    this.objTreaty.Ceded_Re_Cession__c = this.selectedRowTreaty.Ceded_Re_Cession__c;
                    this.objTreaty.GI_Cession__c = this.selectedRowTreaty.GI_Cession__c;

                    if (this.isPooled == '1'){
                        this.PooledValue = true;
                    }
                    else {
                        this.PooledValue = false;
                        this.dataPools = [];
                    }

                    if(this.selectedReinsurance != undefined || this.selectedReinsurance != null){
                        this.isEmpty = false;
                    }
                    if(this.objTreaty.TECH_LTA__c == '1'){
                        this.disableLTAPattern = false;
                        if(this.objTreaty.LTAPattern__c == null){
                            this.LtaPattern = '1';
                        }
                    }
                    else{
                        this.LtaPattern = null;
                        this.objTreaty.LTAInceptionDate__c = null;
                        this.objTreaty.LTAExpiryDate__c = null;
                        this.objTreaty.LTARenegotiation__c = null;
                        this.objTreaty.EarlyTerminationDate__c = null;
                    }

                    if(this.objTreaty.TacitRenewal__c == '1'){
                        this.TRInceptiondate = result[0].Program__r.InceptionDate__c;
                    }
                    else{
                        this.TRInceptiondate = null;
                        this.objTreaty.Advance_notice__c = null;
                    }

                    lossDepositValue = result[0].Program__r.LossDeposit__c;
                    lossDepositLevelValue = result[0].Program__r.LossDepositLevel__c;
                    lossDepositModeValue = result[0].Program__r.LossDepositMode__c;
                    let lossDepositValueTreatyLevel = result[0].LossDeposit__c;
                    let lossDepositModeValueTreatyLevel = result[0].LossDepositMode__c;

                    if(lossDepositLevelValue == 'Treaty' && lossDepositValueTreatyLevel == '1'){
                        this.lossDepositModeDisabled = false;
                        this.lossDepositDisabled = false;
                        this.lossDepositModeRequired = true;
                        var selectedLossDepositModeStr = this.selectedRowTreaty.LossDepositMode__c;
                        if(selectedLossDepositModeStr != undefined){
                            this.selectedLossDepositMode = selectedLossDepositModeStr.split(';');
                        }
                    }
                    else{
                        if(lossDepositValue == '2'){
                            //Loss Deposit = No at Program Level
                            this.LossDepositValue = '2';
                            this.selectedLossDepositMode = null;
                            this.lossDepositModeDisabled = true;
                            this.lossDepositModeRequired = false;
                            this.lossDepositDisabled = true;
                        }
                        else if(lossDepositValue == '1'){
                            //Loss Deposit = Yes at Program Level
                            if(this.objTreaty.LossDeposit__c == undefined || lossDepositLevelValue == 'Program'){
                                this.objTreaty.LossDeposit__c = lossDepositValue;
                                this.LossDepositValue = '1';
                            }
                            else{
                                this.objTreaty.LossDeposit__c = lossDepositValueTreatyLevel;
                                this.LossDepositValue = lossDepositValueTreatyLevel;
                            }

                            if(lossDepositLevelValue == 'Program'){
                                this.lossDepositModeDisabled = true;
                                this.lossDepositDisabled = true;
                                this.lossDepositModeRequired = false;
                                var selectedLossDepositModeStr2 = lossDepositModeValue;
                                var selectedLossDepositModeStr = lossDepositModeValue;

                                if(selectedLossDepositModeStr2 != undefined){
                                    this.lossDepositModeOpt2 = selectedLossDepositModeStr2.split(';');
                                }
                                if(selectedLossDepositModeStr != undefined){
                                    this.selectedLossDepositMode = selectedLossDepositModeStr.split(';');
                                }
                            }
                            else if(lossDepositLevelValue == 'Treaty'){
                                this.lossDepositModeDisabled = (this.LossDepositValue == 1) ? false : true;
                                this.lossDepositModeRequired = (this.LossDepositValue == 1) ? true : false;
                                this.selectedLossDepositMode = (this.LossDepositValue == 1) ? lossDepositModeValue.split(';') : null;
                                this.lossDepositDisabled = false;
                            }
                        }
                    }
                })
                .catch(error => {
                    this.error = error;
                });
            }
            else{
                this.programId = this.recordId;
                this.ProgramName = this.selectedRowTreaty.TECH_ProgramName__c;
                this.isPooled = this.selectedRowTreaty.IsPooled__c;
                this.uwYearActorRef = this.uwYearOpenModal;
                this.LtaPattern = this.selectedRowTreaty.LTAPattern__c;

                if(this.isPooled == '1'){
                    this.PooledValue = true;
                }
                else{
                    this.PooledValue = false;
                    this.dataPools = [];
                }

                getProgramDetails({treatyId: this.selectedRowTreaty.Id})
                .then(result => {
                    this.uwYearActorRef = result[0].Program__r.UwYear__c;
                    this.compOpenModal = result[0].Program__r.PrincipalCedingCompany__c;
                    lossDepositValue = this.selectedRowTreaty.LossDeposit__c;
                    lossDepositLevelValue = result[0].Program__r.LossDepositLevel__c;
                    lossDepositModeValue = result[0].Program__r.LossDepositMode__c;
                    let lossDepositValueTreatyLevel = result[0].LossDeposit__c;
                    let lossDepositModeValueTreatyLevel = result[0].LossDepositMode__c;
                    this.objTreaty.LTAPattern__c = this.selectedRowTreaty.LTAPattern__c;
                    this.objTreaty.TECH_LTA__c = result[0].Program__r.LTA__c;
                    this.objTreaty.LTAInceptionDate__c = result[0].Program__r.LTAInceptionDate__c;
                    this.objTreaty.LTAExpiryDate__c = result[0].Program__r.LTAExpiryDate__c;
                    this.objTreaty.LTARenegotiation__c = result[0].Program__r.LTARenegociation__c;
                    this.objTreaty.EarlyTerminationDate__c = result[0].Program__r.EarlyTerminationDate__c;
                    this.objTreaty.TacitRenewal__c = result[0].Program__r.TacitRenewal__c;
                    this.objTreaty.Advance_notice__c = result[0].Program__r.AdvanceNotice__c;
                    this.objTreaty.AGRe_Cession__c = this.selectedRowTreaty.AGRe_Cession__c;
                    this.objTreaty.Ceded_Re_Cession__c = this.selectedRowTreaty.Ceded_Re_Cession__c;
                    this.objTreaty.GI_Cession__c = this.selectedRowTreaty.GI_Cession__c;

                    if(this.selectedReinsurance != undefined || this.selectedReinsurance != null){
                        this.isEmpty = false;
                    }

                    if(this.objTreaty.TacitRenewal__c == '1'){
                        this.TRInceptiondate = result[0].Program__r.InceptionDate__c;
                    }
                    else{
                        this.TRInceptiondate = null;
                        this.objTreaty.Advance_notice__c = null;
                    }

                    if(lossDepositLevelValue == 'Treaty' && lossDepositValueTreatyLevel == '1'){
                        this.lossDepositModeDisabled = false;
                        this.lossDepositDisabled = false;
                        this.lossDepositModeRequired = true;
                        var selectedLossDepositModeStr = this.selectedRowTreaty.LossDepositMode__c;
                        this.selectedLossDepositMode = selectedLossDepositModeStr.split(';');
                    }
                    else{
                        if(lossDepositValue == '2'){
                            //Loss Deposit = No at Treaty Level
                            this.LossDepositValue = '2';
                            this.selectedLossDepositMode = null;
                            this.lossDepositModeDisabled = true;
                            this.lossDepositModeRequired = false;
                        }
                        else if(lossDepositValue == '1'){
                            //Loss Deposit = Yes at Treaty Level
                            this.LossDepositValue = '1';
                            this.objTreaty.LossDeposit__c = lossDepositValue;

                            if(lossDepositLevelValue == 'Program'){
                                this.lossDepositModeDisabled = true;
                                this.lossDepositDisabled = true;
                                this.lossDepositModeRequired = false;
                                var selectedLossDepositModeStr2 = lossDepositModeValue;
                                var selectedLossDepositModeStr = lossDepositModeValue;

                                if(selectedLossDepositModeStr2 != undefined){
                                    this.lossDepositModeOpt2 = selectedLossDepositModeStr2.split(';');
                                }
                                if(selectedLossDepositModeStr != undefined){
                                    this.selectedLossDepositMode = selectedLossDepositModeStr.split(';');
                                }
                            }
                            else if(lossDepositLevelValue == 'Treaty'){
                                this.lossDepositModeDisabled = false;
                                this.lossDepositDisabled = false;
                                this.lossDepositModeRequired = true;
                                this.selectedLossDepositMode = lossDepositModeValue.split(';');
                            }
                        }
                    }
                    if(this.objTreaty.TECH_LTA__c == '1'){
                        this.disableLTAPattern = false;
                        if(this.selectedRowTreaty.LTAPattern__c != null){
                            this.LtaPattern = this.selectedRowTreaty.LTAPattern__c;
                        }else{
                            this.LtaPattern = '1';
                        }
                    }
                    else{
                        this.LtaPattern = null;
                        this.objTreaty.LTAInceptionDate__c = null;
                        this.objTreaty.LTAExpiryDate__c = null;
                        this.objTreaty.LTARenegotiation__c = null;
                        this.objTreaty.EarlyTerminationDate__c = null;
                    }
                })
                .catch(error => {
                    this.error = error;
                });

            }
            this.objTreaty.Name = this.selectedRowTreaty.Name;
            this.objTreaty.WordingName__c = this.selectedRowTreaty.WordingName__c;
            this.objTreaty.WordingName2__c = this.selectedRowTreaty.WordingName2__c;
            this.objTreaty.WordingName3__c = this.selectedRowTreaty.WordingName3__c;
            this.objTreaty.WordingName4__c = this.selectedRowTreaty.WordingName4__c;
            this.objTreaty.Inceptiondate__c = this.selectedRowTreaty.Inceptiondate__c;
            this.objTreaty.Expirydate__c = this.selectedRowTreaty.Expirydate__c;
            this.selectedTreaty = this.selectedRowTreaty.TypeofTreaty__c;
            this.LtaPattern = this.selectedRowTreaty.LTAPattern__c;

            if(this.objTreaty.LTA__c == '1'){
                this.disableLTAPattern = false;
                this.LtaPattern = this.selectedRowTreaty.LTAPattern__c;
            }
            else{
                this.LtaPattern = null;
                this.objTreaty.LTAInceptionDate__c = null;
                this.objTreaty.LTAExpiryDate__c = null;
                this.objTreaty.LTARenegotiation__c = null;
                this.objTreaty.EarlyTerminationDate__c = null;
            }

            if(this.objTreaty.TacitRenewal__c == '1'){
                this.TRInceptiondate = this.objTreaty.Inceptiondate__c;
            }
            else{
                this.TRInceptiondate = null;
                this.objTreaty.Advance_notice__c = null;
            }

            if(this.selectedTreaty == 'QS'){
                this.selectedTreaty = '3';
            }
            else if(this.selectedTreaty == 'SL'){
                this.selectedTreaty = '1';
            }
            else if(this.selectedTreaty == 'Surplus'){
                this.selectedTreaty = '4';
            }
            else if(this.selectedTreaty == 'XL'){
                this.selectedTreaty = '2';
            }

            //QS or Surplus -> Premium Editable
            //SL or XL -> Premium Disabled
            if(this.selectedTreaty == '3' || this.selectedTreaty == '4'){
                this.premiumDisabled = false;
                this.premiumRequired = true;
            }
            else if(this.selectedTreaty == '1' || this.selectedTreaty == '2'){
                this.premiumDisabled = true;
                this.premiumRequired = false;
            }

            this.LayerNumber = this.selectedRowTreaty.Layer__c;
            this.LtaPattern = this.selectedRowTreaty.LTAPattern__c;
            this.selectedReinsurance = this.selectedRowTreaty.TypeofReinsurance__c;
            this.LossAttachmentValue = this.selectedRowTreaty.LossAttachment__c;
            this.objTreaty.PlacementShare_Perc__c = this.selectedRowTreaty.PlacementShare_Perc__c;
            this.DeductionsValue = this.selectedRowTreaty.Deductions__c;
            this.objTreaty.NotManagedByAgre__c = this.selectedRowTreaty.NotManagedByAgre__c;
            this.objTreaty.Deductions_Perc__c = this.selectedRowTreaty.Deductions_Perc__c;
            this.LossDepositValue = this.selectedRowTreaty.LossDeposit__c;
            this.PremiumDepositValue = this.selectedRowTreaty.PremiumDeposit__c;
            this.selectedTreatyId = this.selectedRowTreaty.Id;
            this.getCovCedComByProgramId(this.programId);
            this.getPoolsByTreatyId(this.selectedTreatyId);

            if(this.DeductionsValue == '2'){
                this.deductionDisabled = true;
                this.objTreaty.Deductions_Perc__c = null;
            }
            else if(this.DeductionsValue == '1'){
                this.deductionDisabled = false;
            }
        }
        else{
            this.programId = this.recordId;
            this.objTreaty.NotManagedByAgre__c = false;
            this.isPooled = '2';

            getProgram({id: this.recordId})
            .then(result => {
                this.ProgramName = result[0].Name;
                this.objTreaty.WordingName__c = result[0].WordingName__c;
                this.objTreaty.WordingName2__c = result[0].WordingName2__c;
                this.objTreaty.WordingName3__c = result[0].WordingName3__c;
                this.objTreaty.WordingName4__c = result[0].WordingName4__c;
                this.objTreaty.Inceptiondate__c = result[0].InceptionDate__c;
                this.objTreaty.Expirydate__c = result[0].Expirydate__c;
                this.objTreaty.LTA__c = result[0].LTA__c;
                this.objTreaty.TECH_LTA__c = result[0].LTA__c;
                this.objTreaty.LTAInceptionDate__c = result[0].LTAInceptionDate__c;
                this.objTreaty.LTAExpiryDate__c = result[0].LTAExpiryDate__c;
                this.objTreaty.LTARenegotiation__c = result[0].LTARenegociation__c;
                this.objTreaty.TacitRenewal__c = result[0].TacitRenewal__c;
                this.objTreaty.EarlyTerminationDate__c= result[0].EarlyTerminationDate__c;
                this.objTreaty.Advance_notice__c = result[0].AdvanceNotice__c;
                this.programId = result[0].Id;
                this.uwYearOpenModal = result[0].UwYear__c;
                this.uwYearActorRef = result[0].UwYear__c;
                this.compOpenModal = result[0].PrincipalCedingCompany__c;

                //default value AGRe cession = 100
                this.template.querySelector('[data-id="AGReCession"]').value = 100.00;
                this.template.querySelector('[data-id="CededReCession"]').value = 0;
                this.template.querySelector('[data-id="GICession"]').value = 0;

                if(this.objTreaty.TacitRenewal__c == '1'){
                    this.TRInceptiondate =  this.objTreaty.Inceptiondate__c;
                }
                else{
                    this.TRInceptiondate = null;
                    this.objTreaty.Advance_notice__c = null;
                }

                if(this.objTreaty.TECH_LTA__c  == '1'){
                    this.disableLTAPattern = false;
                    this.LtaPattern = '1';
                }
                else{
                    this.LtaPattern = undefined;
                    const ltaPatternVal = this.template.querySelector('.ltaPatternClass');
                    ltaPatternVal.value = '';
                }

                if(result[0].LossDeposit__c == '2'){
                    //Loss Deposit = No at Program Level
                    this.LossDepositValue = '2';
                    this.selectedLossDepositMode = null;
                    this.lossDepositModeDisabled = true;
                    this.lossDepositModeRequired = false;
                    this.lossDepositDisabled = true;
                }
                else if(result[0].LossDeposit__c == '1'){
                    //Loss Deposit = Yes at Program Level
                    this.LossDepositValue = '1';
                    this.objTreaty.LossDeposit__c = result[0].LossDeposit__c;

                    if(result[0].LossDepositLevel__c == 'Program'){
                        this.lossDepositModeDisabled = true;
                        this.lossDepositDisabled = true;
                        this.lossDepositModeRequired = false;
                        var selectedLossDepositModeStr2 = result[0].LossDepositMode__c;
                        var selectedLossDepositModeStr = result[0].LossDepositMode__c;

                        if(selectedLossDepositModeStr2 != undefined){
                            this.lossDepositModeOpt2 = selectedLossDepositModeStr2.split(';');
                        }
                        if(selectedLossDepositModeStr != undefined){
                            this.selectedLossDepositMode = selectedLossDepositModeStr.split(';');
                        }

                    }
                    else if(result[0].LossDepositLevel__c == 'Treaty'){
                        this.lossDepositModeDisabled = false;
                        this.lossDepositDisabled = false;
                        this.lossDepositModeRequired = true;
                    }
                }
                this.getCovCedComByProgramId(this.programId);
            })
            .catch(error => {
                this.error = error;
            });
        }
    }

    reload(){
        if(!this.deductionPercRequired && this.deductionDisabled){
            this.isVisible = false;
            this.isVisible = true;
        }
    }

    getVal(val){
        this.uwYearOpenModal = val;
    }

    getComp(val){
        this.compOpenModal = val;
    }

    @wire(getObjectInfo, { objectApiName: TREATY_OBJECT })
    objectInfo;

    handleCloseTreatyModal(){
        if(this.isTreatyEdit == true){
            window.history.back();
            return false;
        }
        else if(this.createPage){
            window.history.back();
            return false;
        }
        else{
            fireEvent(this.pageRef, 'closeTreatyModal', false);
        }
    }

    handleValueChange(event){
        const fieldName = event.target.Name;
        if (fieldName == 'ProgramName'){
            this.ProgramName = this.selectedPrograms[0].Name;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: ISPOOLED_FIELD})
    setPooledPicklistOpt({error, data}) {
        if(data){
            this.PooledOpt = data.values;
        }else{
            this.error = error;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: LTARENEGO_FIELD})
    setLTARenegoPicklistOpt({error, data}) {
        if(data){
            this.ltaRenegOpt = data.values;
        }
        else{
            this.error = error;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: LTAPATTERN_FIELD})
    setLTAPatternOpt({error, data}) {
        if(data){
            this.ltaPatternOpt = data.values;
        }
        else{
            this.error = error;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: LTA_FIELD})
    setLTAPicklistOpt({error, data}) {
        if(data){
            this.ltaOpt = data.values;
        }
        else{
            this.error = error;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: TACITRENEWAL_FIELD})
    setTacitRenewalPicklistOpt({error, data}) {
        if(data){
            this.TacitRenewalOpt = data.values;
        }
        else{
            this.error = error;
        }
    }

    @wire(getPicklistValuesByRecordType, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', objectApiName: TREATY_OBJECT})
    typeOfTreatyPicklistOpt({error, data}) {
        if(data){
            let treatyOptions = [{label:'--None--', value:'--None--'}];
            data.picklistFieldValues.TypeofTreaty__c.values.forEach(key => {
                treatyOptions.push({
                    label : key.label,
                    value: key.value
                })
            });
            this.controllingTreatyValues = treatyOptions;
            let reinsuranceOptions = [{label:'--None--', value:'--None--'}];
            this.controlReinsuranceValues = data.picklistFieldValues.TypeofReinsurance__c.controllerValues;
            this.totalDependentReinsuranceValues = data.picklistFieldValues.TypeofReinsurance__c.values;

            this.totalDependentReinsuranceValues.forEach(key => {
                reinsuranceOptions.push({
                    label : key.label,
                    value: key.value
                })
            });
            this.dependentReinsuranceValues = reinsuranceOptions;
            this.generatePicklistValues();
        }
        else{
            this.error = error;
        }
    }

    handleTreatyChange(event){
        this.selectedTreaty = event.target.value;
        this.isEmpty = false;
        let dependValues = [];

        //QS - 3
        //SL - 1
        //Surplus - 4
        //XL - 2
        if(this.selectedTreaty == '3' || this.selectedTreaty == '4'){
            this.LayerNumber = '0';
            this.premiumRequired = true;
            this.premiumDisabled = false;
            this.selectedReinsurance = (this.selectedTreaty == '4')? '20' : null;
        }
        else{
            if(this.selectedTreaty == '1'){
                this.selectedReinsurance = '40';
            }
            else{
                this.selectedReinsurance = null;
            }
            this.LayerNumber = null;
            this.premiumRequired = false;
            this.premiumDisabled = true;
            this.PremiumDepositValue = null;
        }

        this.generatePicklistValues();
    }
    generatePicklistValues(){
        let dependValues = [];
        if(this.selectedTreaty){
            if(this.selectedTreaty == '--None--'){
                this.isEmpty = true;
                dependValues = [{label:'--None--', value:'--None--'}];
                this.selectedTreaty = null;
                this.selectedReinsurance = null;
                return;
            }
            this.totalDependentReinsuranceValues.forEach(treatyValues => {
                if(treatyValues.validFor[0] === this.controlReinsuranceValues[this.selectedTreaty]){
                    dependValues.push({
                        label : treatyValues.label,
                        value : treatyValues.value
                    })
                }
            })
            this.dependentReinsuranceValues = dependValues;
        }
    }

    handleReinsuranceChange(event){
        this.selectedReinsurance = event.target.value;
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: LOSSDEPOSIT_FIELD})
    setLossDepositPicklistOpt({error, data}) {
        if(data){
            this.LossDepositOpt = data.values;
        }
        else{
            this.error = error;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: PREMIUMDEPOSIT_FIELD})
    setPremiumDepositPicklistOpt({error, data}) {
        if(data){
            this.PremiumDepositOpt = data.values;
        }
        else{
            this.error = error;
        }
    }

	@wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: LOSSDEPOSITMODE_FIELD})
    setLossDepositModePicklistOpt({error, data}) {
        if(data){
            for (var i = 0; i < data.values.length; i++){
                if(this.lossDepositModeOpt2 != undefined){
                    if(this.lossDepositModeOpt2.includes(data.values[i].value)){
                        this.lossDepositModeOpt2Arr.push(data.values[i]);
                    }
                }
                else{
                    this.lossDepositModeOpt2Arr.push(data.values[i]);
                }
            }
        }
        else{
            this.error = error;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: DEDUCTION_FIELD})
    setDeductionPicklistOpt({error, data}) {
        if(data){
            this.DeductionOpt = data.values;
        }
        else{
            this.error = error;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: LOSSATTACH_FIELD})
    setLossAttachmentPicklistOpt({error, data}) {
        if(data){
            this.LossAttachmentOpt = data.values;
        }
        else{
            this.error = error;
        }
    }

    handleChangeLossDepositMode(event){
        this.selectedLossDepositMode = event.detail.value;
    }

    @wire(getPools, {uwyear: '$uwYearOpenModal'})
    getPools(result){
        if (result.data) {
            this.lstPools = result.data
            this.error = undefined;
        } else if (result.error) {
            this.error = result.error;
            this.lstPools = undefined;
        }
    }

    handleCoveredCedComRowSelection(event){
        this.selectedCoveredCedCom = event.detail.selectedRows;
    }

    handleOpenPoolModal(){
        this.isPoolModalOpen = true;
    }

    handleClosePoolModal(){
        this.isPoolModalOpen = false;
    }

    handleAddPool(event){
        let dataUpdPools = this.dataPools;
        this.dataPools = [];
        var lstPoolchecked = [];
        Array.from(this.template.querySelectorAll('lightning-input')).forEach(element => {
            if (element.checked && element.name == 'pool'){
                for (var i = 0; i < this.lstPools.length; i++){
                    if (this.lstPools[i].Id == element.value){
                        lstPoolchecked.push(this.lstPools[i]);
                    }
                }
            }
        });
        if (dataUpdPools != undefined){
            for(var j = 0; j < dataUpdPools.length; j++){
                lstPoolchecked.push(dataUpdPools[j]);
            }
        }
        dataUpdPools = this.getUniqueData(lstPoolchecked,'Id');
        let totalPoolShare = 0;
        let lstUpdDataPool = [];

        for(let i = 0; i < dataUpdPools.length; i++){
            let rowPool = { ...dataUpdPools[i] };
            lstUpdDataPool.push(rowPool);
            totalPoolShare = totalPoolShare + parseFloat(dataUpdPools[i].ShareRate__c);
        }

        dataUpdPools = lstUpdDataPool;
        this.titlePools = 'Pools (' + dataUpdPools.length + ')';
        let valueTotal = parseFloat(totalPoolShare).toFixed(6)
        this.totalTreatyPoolShare = valueTotal.replace('.',',');
        this.dataPools = dataUpdPools;
        this.handleClosePoolModal();
    }

    handleDeletePool(){
        let selectedPool = [];
        for(let i = 0; i < this.dataPools.length; i++){
            if(this.dataPools[i].Checked == true){
                selectedPool.push(this.dataPools[i]);
            }
        }

        this.dataPools = this.dataPools.filter( function(e) { return this.indexOf(e) < 0; },selectedPool );
        this.titlePools = 'Pools (' + this.dataPools.length + ')';
        let totalPoolShare = 0;

        for(let i = 0; i < this.dataPools.length; i++){
            totalPoolShare = totalPoolShare + parseFloat(this.dataPools[i].ShareRate__c);
        }

        let valueTotal = parseFloat(totalPoolShare).toFixed(6)
        this.totalTreatyPoolShare = valueTotal.replace('.',',');
    }

    getUniqueData(arr, comp) {
        const unique = arr.map(e => e[comp])
                         .map((e, i, final) => final.indexOf(e) === i && i)
                         .filter(e => arr[e]).map(e => arr[e]);
        return unique;
    }

    handleSaveTreaty(){
        this.spinnerTreaty = true;
        let inputs= this.template.querySelectorAll('lightning-input, lightning-combobox, lightning-dual-listbox');
        let dataInput = {};
        for(let input of inputs){
            if (input.name == 'NotManagedByAGRe'){
                dataInput[input.name] = input.checked;
            }else{
                dataInput[input.name] = input.value;
            }
        }
        let oldTreatyName =  this.objTreaty.Name;
        this.objTreaty.Program__c = this.programId;
        this.objTreaty.Name = dataInput.TreatyName.trim();
        this.objTreaty.WordingName__c = dataInput.WordingName;
        this.objTreaty.WordingName2__c = dataInput.WordingName2;
        this.objTreaty.WordingName3__c = dataInput.WordingName3;
        this.objTreaty.WordingName4__c = dataInput.WordingName4;
        this.objTreaty.Inceptiondate__c = dataInput.InceptionDate;
        this.objTreaty.Expirydate__c = dataInput.ExpiryDate;
        this.objTreaty.Actor_Reference__c = dataInput.ActorReference;
        this.objTreaty.WebXLReference__c = dataInput.TreatyReference;
        this.objTreaty.TreatyReference__c = dataInput.TreatyReference;
        this.objTreaty.LTA__c = dataInput.LTA;
        this.objTreaty.TECH_LTA__c = dataInput.LTA;
        this.objTreaty.LTAInceptionDate__c = dataInput.LTAInceptionDate;
        this.objTreaty.LTAExpiryDate__c = dataInput.LTAExpiryDate;
        this.objTreaty.LTARenegotiation__c = dataInput.LTARenegotiation;
        this.objTreaty.EarlyTerminationDate__c = dataInput.EarlyTerminationDate;
        this.objTreaty.TacitRenewal__c = dataInput.TacitRenewal;
        this.objTreaty.Advance_notice__c = dataInput.AdvanceNotice;
        this.objTreaty.TypeofTreaty__c = dataInput.TypeOfTreaty;
        this.objTreaty.Layer__c = dataInput.LayerNumber;
        this.objTreaty.LTAPattern__c = dataInput.LtaPattern == '--None--' ? '' : dataInput.LtaPattern;
        this.objTreaty.TypeofReinsurance__c = dataInput.TypeOfReinsurance;
        this.objTreaty.LossAttachment__c = dataInput.LossAttachment;
        this.objTreaty.PlacementShare_Perc__c = parseFloat(dataInput.PlacementShare);
        this.objTreaty.Deductions__c = dataInput.Deductions;
        this.objTreaty.NotManagedByAgre__c = dataInput.NotManagedByAGRe;
        this.objTreaty.Deductions_Perc__c = parseFloat(dataInput.DeductionsPerc);
        this.objTreaty.LossDeposit__c = dataInput.LossDeposit;
        this.objTreaty.LossDepositMode__c = dataInput.LossDepositMode;
        this.objTreaty.PremiumDeposit__c = dataInput.PremiumDeposit;
        this.objTreaty.IsPooled__c = dataInput.IsPooled;
        this.objTreaty.AGRe_Cession__c = parseFloat(dataInput.AGReCession);
        this.objTreaty.Ceded_Re_Cession__c = parseFloat(dataInput.CededReCession);
        this.objTreaty.GI_Cession__c = parseFloat(dataInput.GICession);


        if(this.objTreaty.Name == "" ||  ( this.objTreaty.LossDeposit__c == null && this.lossDepositDisabled == false)
        || this.objTreaty.WebXLReference__c == "" || this.objTreaty.TypeofTreaty__c == null
        || this.objTreaty.TypeofReinsurance__c == null || this.objTreaty.LossDepositMode__c == null
        || (this.objTreaty.PremiumDeposit__c == null && this.premiumRequired == true) || (this.objTreaty.PlacementShare_Perc__c == undefined || isNaN(this.objTreaty.PlacementShare_Perc__c))
        || this.objTreaty.LossAttachment__c == null || this.objTreaty.IsPooled__c == null
        || this.objTreaty.Layer__c == "" || this.objTreaty.Deductions__c == null
        || (this.objTreaty.Deductions__c == '1' && (this.objTreaty.Deductions_Perc__c == undefined || isNaN(this.objTreaty.Deductions_Perc__c) ))
        || (this.objTreaty.TECH_LTA__c == '1' && this.objTreaty.LTAPattern__c == '')){
            this.dispatchEvent(new ShowToastEvent({title: 'ERROR', message:this.label.Required_Fields, variant: 'error'}),);
               this.spinnerTreaty = false;

            if(this.objTreaty.Name == ""){
                this.nameEmpty = true;
            }

            if(this.objTreaty.LossDeposit__c == null && this.lossDepositDisabled == false){
                this.lossDepositEmpty = true;
            }

            if(this.objTreaty.WebXLReference__c == ""){
                this.treatyRefEmpty = true;
            }

            if(this.objTreaty.TypeofTreaty__c == null){
                this.typeOfTreatyEmpty = true;
            }

            if(this.objTreaty.TypeofReinsurance__c == null){
                this.typeOfReinsuranceEmpty = true;
            }
            else{
                this.typeOfReinsuranceEmpty = false;
            }

            if(this.objTreaty.PremiumDeposit__c == null && this.premiumRequired == true){
                this.premiumDepositEmpty = true;
            }

            if(this.objTreaty.PlacementShare_Perc__c == undefined || isNaN(this.objTreaty.PlacementShare_Perc__c)){
                this.placementShareEmpty = true;
            }

            if(this.objTreaty.LossAttachment__c == null){
                this.lossAttachmentEmpty = true;
            }

            if(this.objTreaty.IsPooled__c == null){
                this.pooledEmpty = true;
            }

            if(this.objTreaty.Deductions__c == null){
                this.deductionsEmpty = true;
            }

            if(this.objTreaty.Layer__c == ""){
                this.layerEmpty = true;
            }

            if(this.objTreaty.Deductions__c == '1' && (this.objTreaty.Deductions_Perc__c == undefined || isNaN(this.objTreaty.Deductions_Perc__c) ) ){
                this.deductionsPercEmpty = true;
            }

            if(this.objTreaty.TECH_LTA__c == '1' && this.objTreaty.LTAPattern__c == ''){
                this.LTAPatternEmpty = true;
            }
        }
        else{
            var lstAccountIdCovCedingCom = [];
            for(let i = 0; i < this.data.length;i++){
                if(this.data[i].Checked == true){
                    lstAccountIdCovCedingCom.push(this.data[i].AccountId);
                }
            }

            let poolSaveData = [];

            if (this.dataPools != undefined){
                for (var i = 0; i < this.dataPools.length; i++){
                    poolSaveData.push(this.dataPools[i].Id + ';' + parseFloat(this.dataPools[i].ShareRate__c));
                }
            }

            checkTreatyName({ treatyId : this.selectedTreatyId, programId : this.programId, treatyName : dataInput.TreatyName.trim(), isTreatyCopy : this.isTreatyCopy})
                .then(result => {
                if(result == true){
                    this.template.querySelector('[data-id="TreatyName"]').value = dataInput.TreatyName.trim();
                    this.spinnerTreaty = false;
                    this.nameEmpty = true;
                    if(this.isTreatyCopy == true && oldTreatyName == dataInput.TreatyName.trim()){
                        this.dispatchEvent(new ShowToastEvent({title: 'ERROR', message: this.label.TreatyName_Unchanged, variant: 'error'}),);
                    }
                    else{
                        this.dispatchEvent(new ShowToastEvent({title: 'ERROR', message: this.label.TreatyName_Exists, variant: 'error'}),);
                    }
                }
                else{
                    if(this.objTreaty.IsPooled__c == '1' && (this.dataPools == undefined || this.dataPools.length == 0)){
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Error',
                                message: this.label.EmptyPool,
                                variant: 'error'
                            }),
                        );
                           this.spinnerTreaty = false;

                    }
                    else if(this.objTreaty.LossDepositMode__c.length == 0 && this.lossDepositModeDisabled == false){
                        this.dispatchEvent(new ShowToastEvent({title: 'ERROR', message: this.label.lossDeptTreaty, variant: 'error'}),);
                        this.depositModeEmpty = true;
                        this.spinnerTreaty = false;
                    }
                    else if(this.objTreaty.IsPooled__c == '1' && parseFloat(this.totalTreatyPoolShare.replace(',','.')) > 100){
                           this.dispatchEvent(
                               new ShowToastEvent({
                                   title: 'Error',
                                   message: this.label.TotalPoolError,
                                   variant: 'error'
                               }),
                           );
                            this.spinnerTreaty = false;
                   }
                    else if(this.objTreaty.PlacementShare_Perc__c != "" && this.objTreaty.PlacementShare_Perc__c > 100) {
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Error',
                                message: this.label.PlacementError,
                                variant: 'error'
                            }),
                        );
                        this.spinnerTreaty = false;
                    }
                    else if(this.objTreaty.Deductions__c == '1' && this.objTreaty.Deductions_Perc__c != "" && this.objTreaty.Deductions_Perc__c > 100) {
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Error',
                                message: this.label.DeductError,
                                variant: 'error'
                            }),
                        );
                        this.spinnerTreaty = false;
                    }
                    else if(lstAccountIdCovCedingCom.length == 0 && this.isTreatyCopy != true){
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Error',
                                message: this.label.Ceded_Company_Empty,
                                variant: 'error'
                            }),
                        );
                        this.spinnerTreaty = false;
                    }
                    else{
                        let sumCession = 0;
                        if(isNaN(this.objTreaty.AGRe_Cession__c) == false){
                            sumCession += parseFloat(this.objTreaty.AGRe_Cession__c) ;
                        }
                        if(isNaN(this.objTreaty.Ceded_Re_Cession__c) == false){
                            sumCession += parseFloat(this.objTreaty.Ceded_Re_Cession__c);
                        }
                        if(isNaN(this.objTreaty.GI_Cession__c) == false){
                            sumCession += parseFloat(this.objTreaty.GI_Cession__c);
                        }
                        if(sumCession != 100){
                            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.cocessionFieldsTotal, variant: 'error' }),);
                            this.spinnerTreaty = false;
                        }
                        else{
                            const allValid = [...this.template.querySelectorAll('lightning-input, lightning-combobox, lightning-textarea')]
                            .reduce((validSoFar, inputCmp) => {
                                inputCmp.reportValidity();
                                return validSoFar && inputCmp.checkValidity();
                            }, true);

                            if(allValid){
                                saveTreatyRecord({ objectTreaty : this.objTreaty, lstAccIdCovCedCom : lstAccountIdCovCedingCom, lstPools : poolSaveData, treatyId : this.selectedTreatyId, editTreaty : this.isTreatyEdit})
                                .then(result => {
                                    this.objTreaty = {};
                                    this.dataInput = {};
                                    this.data = [];

                                    if(result.hasOwnProperty('Error') && result.Error){
                                        this.dispatchEvent(new ShowToastEvent({title: 'Error', message: result.Error, variant: 'error' }),);
                                        this.spinnerTreaty = false;
                                    }else{
                                        if(this.isTreatyEdit){
                                            this.dispatchEvent(new ShowToastEvent({title: 'Success', message: this.label.TreatyUpdate, variant: 'success' }),);
                                        }
                                        else if(this.createPage){
                                            this.dispatchEvent(new ShowToastEvent({title: 'Success', message: this.label.TreatyCreated, variant: 'success' }),);
                                            this[NavigationMixin.Navigate]({
                                                type: 'standard__recordPage',
                                                attributes: {
                                                    recordId: this.programId,
                                                    objectApiName: 'Program__c',
                                                    actionName: 'view',
                                                },
                                            });
                                        }
                                        else{
                                            this.dispatchEvent(new ShowToastEvent({title: 'Success', message: this.label.TreatyCreated, variant: 'success' }),);
                                        }
                                    }
                                    if(this.isTreatyEdit){
                                        fireEvent(this.pageRef, 'refreshTreaties', this.recordId);
                                        window.history.back();
                                        this.spinnerTreaty = false;
                                        return false;
                                    }
                                    else{
                                        fireEvent(this.pageRef, 'closeTreatyModal', false);
                                        fireEvent(this.pageRef, 'refreshTreaties', this.recordId);
                                        fireEvent(this.pageRef, 'refreshActorRef', 'refresh');
                                        this.spinnerTreaty = false;
                                    }

                                })
                                .catch(error => {
                                this.dispatchEvent(new ShowToastEvent({title: 'ERROR', message: this.label.errorMsg, variant: 'error'}),);
                                });
                            }
                            else{
                                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.FormEntriesInvalid, variant: 'error'}), );
                                this.spinnerTreaty = false;
                            }
                        }
                    }
                }
            })
            .catch(error => {
                this.spinnerTreaty = false;
                this.dispatchEvent(new ShowToastEvent({title: 'ERROR', message: this.label.errorMsg, variant: 'error'}),);
            });
        }
    }

    handleChangePooledValue(event){
        this.isPooled = event.detail.value;

        if (this.isPooled == '1'){
            this.PooledValue = true;
        }
        else{
            this.PooledValue = false;
            this.dataPools = [];
        }
    }

    getCovCedComByProgramId(programId){
        getCovCedComByProgramId({selectedProgramId: programId})
        .then(result => {
            this.data = result;
            var newData = [];
            for (var i = 0; i < this.data.length; i++) {
                var row = {};
                row['Id'] = this.data[i].Id;
                row['AccountName'] = this.data[i].Account__r.Name;
                row['AccountId'] = this.data[i].Account__r.Id;
                row['Checked'] = false;
                newData.push(row);
            }
            this.data = newData;
            this.titleCoveredCedingCompanies = this.label.CoveredCedingCompanies + ' (' + this.data.length + ')';
            this.error = undefined;

            if(this.isTreatyEdit || this.isTreatyCopy){
                this.getCovCedComByTreatyId(this.selectedTreatyId);
            }
            else{
                let updData = [];
                for (let i = 0; i < this.data.length; i++) {
                    let rowData = { ...this.data[i] };
                    rowData['Checked'] = true;
                    updData.push(rowData);
                }
                this.data = updData;
            }
        })
        .catch(error => {
            this.error = error;
            this.data = undefined;
        });
    }

    getCovCedComByTreatyId(treatyId){
        getCovCedComByTreatyId({selectedTreatyId: treatyId})
        .then(result => {
            let lstCovCedTreaty = result;
            let lstUpdCovCedTreaty = [];

            for(let i = 0; i < this.data.length; i++){
                let rowTreatyCovCed = { ...this.data[i] };
                for(let j = 0; j < lstCovCedTreaty.length; j++){
                    if(lstCovCedTreaty[j].Account__r.Id == rowTreatyCovCed.AccountId){
                        rowTreatyCovCed['Checked'] = true;
                    }
                }
                lstUpdCovCedTreaty.push(rowTreatyCovCed);
            }

            this.data = lstUpdCovCedTreaty;
            this.getAllExistedCoveredCedingComForSection(treatyId);
        })
        .catch(error => {
            this.error = error;
            this.selectedCoveredCedCom = undefined;
        });
    }

    getAllExistedCoveredCedingComForSection(treatyId){
        getAllExistedCoveredCedingComForSection({ treatyId : treatyId})
        .then(resultSect => {
            let lstExistingAccountIdSections = resultSect;
            this.setExistingAccountIdSections = new Set();
            let lstUpdData = [];

            for(let i = 0; i < lstExistingAccountIdSections.length; i++){
                this.setExistingAccountIdSections.add(lstExistingAccountIdSections[i]);
            }

            for(let i = 0; i < this.data.length; i++){
                let rowData = { ...this.data[i] };
                if(this.setExistingAccountIdSections.has(this.data[i].AccountId) && this.isTreatyCopy == false){
                    rowData['disableCheckbox'] = true;
                }
                lstUpdData.push(rowData);
            }

            this.data = lstUpdData;
        })
        .catch(error => {
            this.dispatchEvent(new ShowToastEvent({title: 'ERROR', message: this.label.errorMsg, variant: 'error'}),);
        });
    }

    handleChangeCovCedComCheckbox(event){
        let accountId = event.currentTarget.name;
        let covCedCheckValue = event.currentTarget.checked;
        let lstUpdCovCed = [];

       for(let i = 0; i < this.data.length; i++){
           let rowCovCed = { ...this.data[i] };
           if(rowCovCed.AccountId == accountId){
               rowCovCed['Checked'] = covCedCheckValue;
           }
           lstUpdCovCed.push(rowCovCed);
       }

       this.data = lstUpdCovCed;
    }

    getPoolsByTreatyId(treatyId){
        getPoolsByTreatyId({selectedTreatyId: treatyId})
        .then(result => {
            this.dataPools = result;
            this.titlePools = 'Pools (' + this.dataPools.length + ')';
            let totalPoolShare = 0;

            for(let i = 0; i < this.dataPools.length; i++){
                totalPoolShare = totalPoolShare + this.dataPools[i].ShareRate__c;
            }

            let valueTotal = parseFloat(totalPoolShare).toFixed(6)
            this.totalTreatyPoolShare = valueTotal.replace('.',',');
            this.error = undefined;
        })
        .catch(error => {
            this.error = error;
            this.dataPools = undefined;
        });
    }

    handleLossAttachmentChange(event){
        this.LossAttachmentValue = event.detail.value;
    }

    handleDeductionChange(event){
        this.DeductionsValue = event.detail.value;

        if(this.DeductionsValue == '2'){
            this.objTreaty.Deductions_Perc__c = undefined;
            this.deductionDisabled = true;
            this.deductionPercRequired = false;
        }
        else if(this.DeductionsValue == '1'){
            this.deductionDisabled = false;
            this.deductionPercRequired = true;
            this.deductionsPercEmpty = false;
        }

        if(!this.deductionPercRequired && this.deductionDisabled){
            Promise.resolve().then(() => {
                const inputEle = this.template.querySelector('.clear');
                inputEle.reportValidity();
            });
        }
    }

    handleLossDepositChange(event){
        this.LossDepositValue = event.detail.value;

        if(this.LossDepositValue == '2'){
            //LossDepositValue = No at Treaty Level
            this.lossDepositModeDisabled = true;
            this.lossDepositModeRequired = false;
            this.selectedLossDepositMode = null;
        }
        else if(this.LossDepositValue == '1'){
            //LossDepositValue = Yes at Treaty Level
            this.lossDepositModeDisabled = false;
            this.lossDepositModeRequired = true;
        }
    }

    handlePremiumDepositChange(event){
        this.PremiumDepositValue = event.detail.value;
    }

    refreshWiredLastActorReference(){
        return refreshApex(this.wiredActorReference);
    }

    @wire(getActorReferenceIndex, { uwYear : '$uwYearActorRef'})
    wiredGetActorReferenceIndex(result){
        this.wiredActorReference = result;
        if(result.data && this.isTreatyEdit == false){
            this.lastActorReference = result.data;
            this.objTreaty.Actor_Reference__c = result.data;
            this.objTreaty.WebXLReference__c = this.objTreaty.Actor_Reference__c;
            this.objTreaty.TreatyReference__c = this.objTreaty.Actor_Reference__c;
        }
        else if (result.error) {
            this.error = result.error;
        }
    }

    handleChangeWebXLRef(event){
        var webXLRef = event.detail.value;
    }

    handleValueChangePool(event){
        let fieldName = event.currentTarget.name;
        let eventId = event.currentTarget.id;
        let poolId = eventId.split('-')[0];
        let lstUpdPool = [];
        let valueTotalTreatyPoolShare = 0;

        for(let i = 0; i < this.dataPools.length; i++){
            let rowPool = { ...this.dataPools[i] };
            if(rowPool.Id == poolId){
                if(fieldName == 'Checkbox'){
                    let poolCheckValue = event.currentTarget.checked;
                    rowPool['Checked'] = poolCheckValue;
                }
                else if(fieldName == 'PoolShare'){
                    let poolShareRate = event.currentTarget.value;
                    rowPool['ShareRate__c'] = parseFloat(poolShareRate);
                    this.poolShareValueChange = true;
                }
            }

            valueTotalTreatyPoolShare = valueTotalTreatyPoolShare + parseFloat(rowPool.ShareRate__c);
            lstUpdPool.push(rowPool);
        }

        this.dataPools = lstUpdPool;
        this.totalTreatyPoolShare = parseFloat(valueTotalTreatyPoolShare).toFixed(6).replace('.',',');
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