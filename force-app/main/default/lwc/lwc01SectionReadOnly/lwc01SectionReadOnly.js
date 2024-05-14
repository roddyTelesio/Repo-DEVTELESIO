import {LightningElement, track, wire, api} from 'lwc';
import {registerListener, fireEvent} from 'c/pubSub';
import {NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import {getObjectInfo} from 'lightning/uiObjectInfoApi';
import {getPicklistValues, getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import {refreshApex} from '@salesforce/apex';
import saveSectionRecord from '@salesforce/apex/LWC01_NewSection.saveSectionRecord';
import getSectionNumber from '@salesforce/apex/LWC01_NewSection.getSectionNumber';
import getReinstatements from '@salesforce/apex/LWC01_NewSection.getReinstatements';
import getPoolsSectionDetails from '@salesforce/apex/LWC01_NewSection.getPoolsSectionDetails';
import getPoolsTreatyDetails from '@salesforce/apex/LWC01_NewSection.getPoolsTreatyDetails';
import getCovCedCompBySectionId from '@salesforce/apex/LWC01_NewSection.getCovCedCompBySectionId';
import getCoveredCedingCompaniesByTreatyId from '@salesforce/apex/LWC01_NewSection.getCoveredCedingCompaniesByTreatyId';
import getOptionSectionNumber from '@salesforce/apex/LWC01_NewSection.getOptionSectionNumber';
import getProgramDetails from '@salesforce/apex/LWC01_NewSection.getProgramDetails';
import getSectionDetails from '@salesforce/apex/LWC01_NewSection.getSectionDetails';
import getTreatyDetails from '@salesforce/apex/LWC01_NewSection.getTreatyDetails';
import checkIfQuoteRequestPresent from '@salesforce/apex/LWC01_NewSection.checkIfQuoteRequestPresent';
import disableQuoteTypeForRenewProg from '@salesforce/apex/LWC01_NewSection.disableQuoteTypeForRenewProg';
import getAllSectionOption from '@salesforce/apex/LWC01_NewSection.getAllSectionOption';

import SECTION_OBJECT from '@salesforce/schema/Section__c';
import POOLTREATYSECTION_OBJECT from '@salesforce/schema/PoolTreatySection__c';
import REINSTATEMENT_OBJECT from '@salesforce/schema/Reinstatement__c';
import PROGRAMNAME_FIELD from '@salesforce/schema/Section__c.Program__c';
import TREATYNAME_FIELD from '@salesforce/schema/Section__c.Treaty__c';
import SECTIONNAME_FIELD from '@salesforce/schema/Section__c.Name';
import SECTIONNUMBER_FIELD from '@salesforce/schema/Section__c.SectionNumber__c';
import OPTION_FIELD from '@salesforce/schema/Section__c.Option__c';
import RELATEDSECTION_FIELD from '@salesforce/schema/Section__c.RelatedSection__c';
import RENEWEDSECTION_FIELD from '@salesforce/schema/Section__c.RenewedFromSectionOption__c';
import LOB_FIELD from '@salesforce/schema/Section__c.LoB__c';
import SUBLOB_FIELD from '@salesforce/schema/Section__c.SubLoB__c';
import REINSURANCE_FIELD from '@salesforce/schema/Section__c.NonTraditionalReinsuranceAndOrFinit__c';
import METHODDISTRIBUTION_FIELD from '@salesforce/schema/Section__c.MethodOfDistributionOfThePremium__c';
import TOTALEPI_FIELD from '@salesforce/schema/Section__c.TotalEPI__c';
import NATURE_FIELD from '@salesforce/schema/Section__c.Nature__c';
import POOLEDSECTION_FIELD from '@salesforce/schema/Section__c.PooledSectionOption__c';
import LIMITTYPE_FIELD from '@salesforce/schema/Section__c.LimitType__c';
import CURRENCY_FIELD from '@salesforce/schema/Section__c.Currency__c';
import UNLIMITED_FIELD from '@salesforce/schema/Section__c.Unlimited__c';
import LIMIT_FIELD from '@salesforce/schema/Section__c.Limit__c';
import LIMITPERCENT_FIELD from '@salesforce/schema/Section__c.LimitPercent__c';
import DEDUCTIBLE_FIELD from '@salesforce/schema/Section__c.Deductible__c';
import DEDUCTIBLEPERCENT_FIELD from '@salesforce/schema/Section__c.DeductiblePercent__c';
import AAL_FIELD from '@salesforce/schema/Section__c.AAL__c';
import AAD_FIELD from '@salesforce/schema/Section__c.AAD__c';
import TAL_FIELD from '@salesforce/schema/Section__c.TAL__c';
import EXPECTEDMDP_FIELD from '@salesforce/schema/Section__c.ExpectedMDP__c';
import EXPECTEDDP_FIELD from '@salesforce/schema/Section__c.ExpectedDP__c';
import EXPECTEDMP_FIELD from '@salesforce/schema/Section__c.ExpectedMP__c';
import REINSTATEMENT_FIELD from '@salesforce/schema/Section__c.Reinstatements__c';
import INCLUSION_FIELD from '@salesforce/schema/Section__c.InclusionOfCatastrophicGuarantees__c';
import EXCLUSION_FIELD from '@salesforce/schema/Section__c.ExclusionOfCatastrophicGuarantees__c';
import COMMENTS_FIELD from '@salesforce/schema/Section__c.Comments__c';
import QUOTETYPE_FIELD from '@salesforce/schema/Section__c.QuoteType__c';
import TECHNATUREPROGRAM_FIELD from '@salesforce/schema/Section__c.TECH_NatureProgram__c';
import TECHTYPEOFTREATY_FIELD from '@salesforce/schema/Section__c.TECH_TypeofTreaty__c';
import LINEAMOUNT_FIELD from '@salesforce/schema/Section__c.LineAmount__c';
import CEDEDLINE_FIELD from '@salesforce/schema/Section__c.CededLines__c';
import RETENTIONLINE_FIELD from '@salesforce/schema/Section__c.RetentionLine__c';
import CAPACITY_FIELD from '@salesforce/schema/Section__c.Capacity__c';
import CAPACITYPERRISK_FIELD from '@salesforce/schema/Section__c.CapacityPerRisk__c';
import EVENLIMIT_FIELD from '@salesforce/schema/Section__c.EventLimit__c';
import CESSIONPERC_FIELD from '@salesforce/schema/Section__c.Cession_Perc__c';
import RETENTIONPERC_FIELD from '@salesforce/schema/Section__c.Retention__c';
import CESSIONAMOUNT_FIELD from '@salesforce/schema/Section__c.CessionAmount__c';
import RETENTIONAMOUNT_FIELD from '@salesforce/schema/Section__c.RetentionAmount__c';
import CEDEDPREMIUM_FIELD from '@salesforce/schema/Section__c.CededPremium__c';
import SUBLOB_POOL_FIELD from '@salesforce/schema/PoolTreatySection__c.SubLoB__c';
import FLAG_LIMIT from '@salesforce/schema/Section__c.TECH_IsLimit__c';
import DEDUCTIBLE_LIMIT from '@salesforce/schema/Section__c.TECH_IsDeductible__c';

import INCL_EARTHQUAKE_FIELD from '@salesforce/schema/Section__c.Incl_Earthquake__c';
import INCL_TERRORISM_FIELD from '@salesforce/schema/Section__c.Incl_Terrorism__c';
import INCL_FLOOD_FIELD from '@salesforce/schema/Section__c.Incl_Flood__c';
import INCL_SRCC_FIELD from '@salesforce/schema/Section__c.Incl_SRCC__c';
import INCL_HURRICANE_FIELD from '@salesforce/schema/Section__c.Incl_Hurricane__c';
import INCL_OTHERS_FIELD from '@salesforce/schema/Section__c.Incl_Others__c';
import INCL_OTHERRISK_FIELD from '@salesforce/schema/Section__c.Incl_OtherRisks__c';
import INCL_ALL_FIELD from '@salesforce/schema/Section__c.Incl_All__c';
import EXCL_WAR_FIELD from '@salesforce/schema/Section__c.Excl_War__c';
import EXCL_NUCLEARRISK_FIELD from '@salesforce/schema/Section__c.Excl_NuclearRisks__c';
import EXCL_TERRORISM_FIELD from '@salesforce/schema/Section__c.Excl_Terrorism__c';
import EXCL_BIOLOGICAL_FIELD from '@salesforce/schema/Section__c.Excl_Biological__c';
import EXCL_NUCLEARBIOLOGICAL_FIELD from '@salesforce/schema/Section__c.Excl_NuclearBiological__c';
import EXCL_OTHERS_FIELD from '@salesforce/schema/Section__c.Excl_Others__c';
import EXCL_EPIDEMIC_FIELD from '@salesforce/schema/Section__c.Excl_Epidemic__c';
import EXCL_ALL_FIELD from '@salesforce/schema/Section__c.Excl_All__c';
import MAXLIMITAMOUNT_FIELD from '@salesforce/schema/Section__c.MaxLimitAmount__c';
import MINLIMTAMOUNT_FIELD from '@salesforce/schema/Section__c.MinLimitAmount__c';
import ORDER_REINS_FIELD from '@salesforce/schema/Reinstatement__c.Order__c';
import PERC_REINS_FIELD from '@salesforce/schema/Reinstatement__c.Percentage__c';
import PRORATA_REINS_FIELD from '@salesforce/schema/Reinstatement__c.Prorata__c';
import TYPE_REINS_FIELD from '@salesforce/schema/Reinstatement__c.Type__c';
import FREE_FIELD from '@salesforce/schema/Reinstatement__c.Free__c';
import EPI_FIELD from '@salesforce/schema/CoveredCedingCompany__c.EPI__c';
import ALLOCATION_KEY_FIELD from '@salesforce/schema/CoveredCedingCompany__c.AllocationKey__c';
import ACCOUNTID_FIELD from '@salesforce/schema/CoveredCedingCompany__c.Account__c';
import CoveredCedingCompanies from '@salesforce/label/c.CoveredCedingCompanies';
import RenewedFromSection_Option from '@salesforce/label/c.RenewedFromSection_Option';
import NonTraditionalReinsurance_FiniteRe from '@salesforce/label/c.NonTraditionalReinsurance_FiniteRe';
import MethodOfDistribution from '@salesforce/label/c.MethodOfDistribution';
import ExpectedMDP from '@salesforce/label/c.ExpectedMDP';
import ExpectedDP from '@salesforce/label/c.ExpectedDP';
import ExpectedMP from '@salesforce/label/c.ExpectedMP';
import Reinstatements from '@salesforce/label/c.Reinstatements';
import Reinstatement from '@salesforce/label/c.Reinstatement';
import Required_Fields from '@salesforce/label/c.Required_Fields';
import Ceded_Company_Empty from '@salesforce/label/c.Ceded_Company_Empty';
import Allocation_Key from '@salesforce/label/c.Allocation_Key';
import Inclusion_Catastrophy from '@salesforce/label/c.Inclusion_Catastrophy';
import Exclusion_Catastrophy from '@salesforce/label/c.Exclusion_Catastrophy';
import EmptyPool from '@salesforce/label/c.EmptyPool';
import Reinstatement_Empty from '@salesforce/label/c.Reinstatement_Empty';
import Section_Updated from '@salesforce/label/c.Section_Updated';
import Section_Created from '@salesforce/label/c.Section_Created';
import Max_Error from '@salesforce/label/c.Max_Error';
import Min_Error from '@salesforce/label/c.Min_Error';
import FormEntriesInvalid from '@salesforce/label/c.FormEntriesInvalid';
import DecimalPlacesErrorMessage from '@salesforce/label/c.DecimalPlacesErrorMessage';
import NumberErrorMessage from '@salesforce/label/c.NumberErrorMessage';
import maxHundredErrorMessage from '@salesforce/label/c.maxHundredErrorMessage';
import minHundredErrorMessage from '@salesforce/label/c.minHundredErrorMessage';
import QRTypeHelpText from '@salesforce/label/c.QRTypeHelpText';
import TAL from '@salesforce/label/c.TAL';
import errorMsg from '@salesforce/label/c.errorMsg';

const columnsReinstatements = [
    { label: 'Order', fieldName: 'Order'},
    { label: 'Percentage', fieldName: 'Percentage'},
    { label: 'Free', fieldName: 'FreeValue'},
    { label: 'Prorata', fieldName: 'Prorata'},
];

export default class LWC01_SectionReadOnly extends NavigationMixin(LightningElement) {
    label = {
        CoveredCedingCompanies,RenewedFromSection_Option, NonTraditionalReinsurance_FiniteRe,MethodOfDistribution,ExpectedMDP,errorMsg,
        ExpectedDP,ExpectedMP,Reinstatements,Reinstatement,Required_Fields,Ceded_Company_Empty,Allocation_Key,Inclusion_Catastrophy,Exclusion_Catastrophy,
        EmptyPool,Reinstatement_Empty,Section_Updated,Section_Created,Max_Error,Min_Error,FormEntriesInvalid,DecimalPlacesErrorMessage,NumberErrorMessage,maxHundredErrorMessage,minHundredErrorMessage,QRTypeHelpText,TAL
    }

    @api uwYearOpenModal;
    @api compOpenModal;
    @api selectedTreaties;
    @api selectedProgram;
    @api techNatureProgram;
    @api isSectionCopy = false;
    @api isSectionNewOption = false;
    @api recordId;
    @api isSectionEdit = false;
    @api selectedRowSectionCopy;
    @api createPage = false;
    @api sObjectName;
    @api selectedSectId = null;
    @api sectNumber = null;
    @api covCed;
    @api selectedTreatyId;
    @track totalDependentQuoteTypeValue = [];
    @track dataReinstatements = [];
    @track controllingLOBValues = [];
    @track dependentSubLOBValues = [];
    @track lstPools = [];
    @track subLoBPoolOpt = [];
    wiredPicklist;
    wiredLob;
    nameEmpty = false;
    quoteTypeEmpty = false;
    lobEmpty = false;
    sublobEmpty = false;
    nonTradReinsEmpty = false;
    natureEmpty = false;
    reinstatementsEmpty = false;
    currencyEmpty = false;
    limitTypeEmpty = false;
    lineAmountEmpty = false;
    cededLinesEmpty = false;
    retentionLineEmpty = false;
    retentionAmountEmpty = false;
    capacityPerRiskEmpty = false;
    eventLimitEmpty = false;
    cessionPercEmpty = false;
    retentionPercEmpty = false;
    cessionAmountEmpty = false;
    limitValueEmpty = false;
    maxLimitValueEmpty = false;
    minLimitValueEmpty = false;
    expectedMDPEmpty = false;
    expectedDPEmpty = false;
    expectedMPEmpty = false;
    deductibleValueEmpty = false;
    OptionOpt;
    ReinsuranceOpt;
    MethodDistributionOpt;
    NatureOpt;
    PooledOpt;
    LimitTypeOpt;
    CurrencyOpt;
    ReinstatementOpt;
    InclusionOpt;
    ExclusionOpt;
    QuoteRequestTypeOpt;
    prorataReinsOpt;
    PooledValue;
    isTypeOfTreatyXL;
    isTypeOfTreatyQS;
    isTypeOfTreatyAXAXLQS;/*1966*/
    isTypeOfTreatySurplus;
    isTypeOfTreatyStopLoss;
    treatyId;
    programId;
    ProgramName;
    TreatyName;
    Option = '2';
    RelatedSection;
    Renewed;
    InclusionValue;
    ExclusionValue;
    TotalEPIValue = 0;
    MethodDistribution;
    isMethodDistributionProrata = true;
    isInclusion;
    isExclusion;
    sectionId = null;
    dataCedingCompanyProrata;
    allDataReinstatements = [];
    columnsReinstatements = columnsReinstatements;
    selectedCoveredCedComProrata;
    typeOfTreaty;
    sectionNumber;
    dataCedingCompanyFixedKeys;
    selectedCoveredCedComFixedKey;
    openNewReinstatementModal = false;
    selectedReinstatement;
    TypeOfReinstatement = '';
    isTechNatureProgramLife;
    isFreeChecked = false;
    mapLOb = new Map();
    mapSubLOb = new Map();
    mapSubLobPool = new Map();
    showTAL = false;
    sectionTotalEPIValue = 0;
    selectedLOB;
    selectedSubLOB;
    isLOBEmpty = true;
    controlSubLOBValues;
    error;
    totalDependentSubLOBValues = [];
    totalAllocationFixedKey = 0;
    displaySection = false;
    ReinsuranceValue;
    NatureValue;
    isPooled;
    CommentsValue;
    QuoteRequestTypeValue;
    InEarthquakeValue;
    InTerrorismValue;
    InFloodValue;
    InSRCCValue;
    InHurricaneValue;
    InOthersValue;
    InOtherRisksValue;
    InAllValue = false;
    ExWarValue;
    ExNuclearRisksValue;
    ExTerrorismValue;
    ExBiologicalValue;
    ExNuclearBiologicalChemicalValue;
    ExOthersValue;
    ExEpidemicPandemicValue;
    ExAllValue;
    LimitTypeValue;
    CurrencyValue;
    UnlimitedValue;
    LimitValue;
    DeductibleValue;
    AALValue;
    AADValue;
    TALValue;
    ExpectedMDPValue;
    ExpectedDPValue;
    ExpectedMPValue;
    CapacityPerRiskValue;
    EvenLimitValue;
    CessionPercValue;
    RetentionPercValue;
    CessionAmountValue;
    RetensionAmountValue;
    CededPremiumValue;
    LineAmountValue;
    CededLineValue;
    RetentionLineValue;
    CapacityValue;
    MaxLimitAmountValue;
    MinLimitAmountValue;
    additionalSectionDetail = null;
    disableWhenUnlimited;
    isRowSelectionProrata = false;
    isRowSelectionFixed = false;
    TotalEPIFixed = 0;
    controlQuoteTypeValues;
    titleCoveredCedingCompaniesProrata = this.label.CoveredCedingCompanies + ' (0)';
    titleCoveredCedingCompaniesFixedKeys = this.label.CoveredCedingCompanies + ' (0)';
    titlePool = 'Pools (0)';
    isNewReinstatementDisable = true;
    mapReinstatementType = new Map();
    mapProrataLabelValue = new Map();
    mapProrataValueLabel = new Map();
    mapCurrency = new Map();
    orderReins = 1;
    titleReinstatement = 'Reinstatements (0)';
    disablePercentageReins = false;
    disableProrataReins = false;
    percentageReins = 0;
    prorataReins;
    totalPoolShareFromTreatyLevel = 0;
    unlimitedSelected = false;
    exclusionEmpty = false;
    disableMDP = false;
    disableDPandMP = false;
    displaySpinner = false;
    disableQRtype = false;
    QRtypeTitle = '';
    disableQuoteTypeRenew = false;
    closePreviousPhasesClick = false;
    limitFlag = true;
    deductibleFlag = true;
    lstAllSectionOptions;
    disableAllSectionOptions = true;

    @track objSection = {
        Program__c : PROGRAMNAME_FIELD, Treaty__c : TREATYNAME_FIELD, Name : SECTIONNAME_FIELD, SectionNumber__c : SECTIONNUMBER_FIELD,
        Option__c : OPTION_FIELD, RelatedSection__c : RELATEDSECTION_FIELD, RenewedFromSectionOption__c : RENEWEDSECTION_FIELD, LoB__c : LOB_FIELD, SubLoB__c : SUBLOB_FIELD, NonTraditionalReinsuranceAndOrFinit__c : REINSURANCE_FIELD,
        MethodOfDistributionOfThePremium__c : METHODDISTRIBUTION_FIELD, TotalEPI__c : TOTALEPI_FIELD, Nature__c : NATURE_FIELD, PooledSectionOption__c : POOLEDSECTION_FIELD, LimitType__c : LIMITTYPE_FIELD, Currency__c : CURRENCY_FIELD, Unlimited__c : UNLIMITED_FIELD,
        Limit__c : LIMIT_FIELD, LimitPercent__c : LIMITPERCENT_FIELD, Deductible__c : DEDUCTIBLE_FIELD, DeductiblePercent__c : DEDUCTIBLEPERCENT_FIELD,
        AAL__c : AAL_FIELD, AAD__c : AAD_FIELD, TAL__c : TAL_FIELD, ExpectedMDP__c : EXPECTEDMDP_FIELD, ExpectedDP__c : EXPECTEDDP_FIELD,
        ExpectedMP__c : EXPECTEDMP_FIELD, Reinstatements__c : REINSTATEMENT_FIELD, InclusionOfCatastrophicGuarantees__c : INCLUSION_FIELD,
        ExclusionOfCatastrophicGuarantees__c : EXCLUSION_FIELD, Comments__c : COMMENTS_FIELD, Incl_Earthquake__c : INCL_EARTHQUAKE_FIELD,
        Incl_Terrorism__c : INCL_TERRORISM_FIELD, Incl_Flood__c : INCL_FLOOD_FIELD, Incl_SRCC__c : INCL_SRCC_FIELD, Incl_Hurricane__c : INCL_HURRICANE_FIELD,
        Incl_Others__c : INCL_OTHERS_FIELD, Incl_OtherRisks__c : INCL_OTHERRISK_FIELD, Incl_All__c : INCL_ALL_FIELD, Excl_War__c : EXCL_WAR_FIELD,
        Excl_NuclearRisks__c : EXCL_NUCLEARRISK_FIELD, Excl_Terrorism__c : EXCL_TERRORISM_FIELD, Excl_Biological__c : EXCL_BIOLOGICAL_FIELD,
        Excl_NuclearBiological__c : EXCL_NUCLEARBIOLOGICAL_FIELD, Excl_Others__c : EXCL_OTHERS_FIELD, Excl_Epidemic__c : EXCL_EPIDEMIC_FIELD,
        Excl_All__c : EXCL_ALL_FIELD, QuoteType__c : QUOTETYPE_FIELD, TECH_NatureProgram__c : TECHNATUREPROGRAM_FIELD, TECH_TypeofTreaty__c : TECHTYPEOFTREATY_FIELD,
        CapacityPerRisk__c : CAPACITYPERRISK_FIELD, EventLimit__c : EVENLIMIT_FIELD, Cession_Perc__c : CESSIONPERC_FIELD, Retention__c : RETENTIONPERC_FIELD,
        CessionAmount__c : CESSIONAMOUNT_FIELD, RetentionAmount__c : RETENTIONAMOUNT_FIELD, CededPremium__c : CEDEDPREMIUM_FIELD, LineAmount__c : LINEAMOUNT_FIELD,
        CededLines__c : CEDEDLINE_FIELD, RetentionLine__c : RETENTIONLINE_FIELD, Capacity__c : CAPACITY_FIELD, MaxLimitAmount__c : MAXLIMITAMOUNT_FIELD,
        MinLimitAmount__c : MINLIMTAMOUNT_FIELD, TECH_IsLimit__c : FLAG_LIMIT, TECH_IsDeductible__c : DEDUCTIBLE_LIMIT
    };

    @wire(getObjectInfo, { objectApiName: SECTION_OBJECT })
    objectInfo;

    @wire(getObjectInfo, { objectApiName: POOLTREATYSECTION_OBJECT })
    objectInfoPoolTreatySection;

    @wire(CurrentPageReference) pageRef;
    renderedCallback() {
        const style = document.createElement('style');
        style.innerText = '.alignRight input { text-align: right;}';
        const ele = this.template.querySelector('.alignRight');
        if(ele != null){
            ele.appendChild(style);
        }

        const styleReports = document.createElement('style');
        styleReports.innerText = '.textReports .slds-form-element__label {color : rgb(175, 171, 171);}';
        const eleReports = this.template.querySelector('.textReports');
        if(eleReports != null){
            eleReports.appendChild(styleReports);
        }
    }
    connectedCallback(){
        registerListener('year', this.getVal, this);
        registerListener('comp', this.getComp, this);

        this.limitFlag = true;
        this.deductibleFlag = true;

        if(this.isSectionCopy == true || this.isSectionNewOption == true){
            this.compOpenModal = this.selectedRowSectionCopy.pcc;
            this.unlimitedSelected = (this.isSectionCopy) ? this.selectedRowSectionCopy.Unlimited__c : false;
            this.MethodDistribution = this.selectedRowSectionCopy.MethodOfDistributionOfThePremium__c;
            this.Option = this.selectedRowSectionCopy.Option__c;
            this.ProgramName = this.selectedRowSectionCopy.TECH_ProgramName__c;
            this.TreatyName = this.selectedRowSectionCopy.TECH_TreatyName__c;
            this.treatyId = this.selectedRowSectionCopy.Treaty__c;
            this.selectedTreatyId = this.selectedRowSectionCopy.Treaty__c;
            this.programId = this.selectedRowSectionCopy.Program__c;
            this.Renewed = this.selectedRowSectionCopy.TECH_RenewedSection_ID__c;

            if(this.MethodDistribution == 'EPI prorata'){
                this.isMethodDistributionProrata = true;
            }else{
               this.isMethodDistributionProrata = false;
            }
            this.getCoveredCedingCompaniesByTreatyId(this.programId, this.treatyId);
            this.getProgramDetails('copyOption');
        }
        else{
            this.ReinsuranceValue = '2';
        }

        if(this.createPage == true){
            this.populateCreatePageSectionInfo();
        }
        else if(this.isSectionNewOption == true){
            this.ReinsuranceValue = '2';
            this.TotalEPIValue = 0;
            this.RelatedSection = this.selectedRowSectionCopy.SectionNumber__c;
            this.Option = '1';
            this.typeOfTreaty = this.selectedRowSectionCopy.TECH_TypeofTreaty__c;
            this.techNatureProgram = this.selectedRowSectionCopy.TECH_NatureProgram__c;
            this.isPooled = this.selectedRowSectionCopy.Treaty__r.IsPooled__c;

            /*this.isLOBEmpty = false;
            this.selectedLOB = this.selectedRowSectionCopy.LoB__c;
            this.selectedSubLOB = this.selectedRowSectionCopy.SubLoB__c;*/

            if(this.isPooled == '1'){
                this.PooledValue = true;
            }else{
                this.PooledValue = false;
            }

            this.selectedSectId = this.selectedRowSectionCopy.Id;
            this.sectNumber = this.selectedRowSectionCopy.SectionNumber__c;

            if(this.techNatureProgram == '23002'){
                this.isTechNatureProgramLife = true;
            }
            else if(this.techNatureProgram == '23001'){
                this.isTechNatureProgramLife = false;
            }

            if(this.typeOfTreaty == '2'){this.CurrencyValue = this.selectedRowSectionCopy.Currency__c;this.isTypeOfTreatyXL = true;}
            else if(this.typeOfTreaty == '3'){this.CurrencyValue = this.selectedRowSectionCopy.Currency__c;this.isTypeOfTreatyQS = true;}
            /*1966*/
            else if(this.typeOfTreaty == '5'){this.CurrencyValue = this.selectedRowSectionCopy.Currency__c;this.isTypeOfTreatyAXAXLQS = true;}
            else if(this.typeOfTreaty == '4'){this.CurrencyValue = this.selectedRowSectionCopy.Currency__c;this.isTypeOfTreatySurplus = true;}
            else if(this.typeOfTreaty == '1'){this.CurrencyValue = this.selectedRowSectionCopy.Currency__c;this.isTypeOfTreatyStopLoss = true;}
            this.getOptionSectionNumber(this.selectedSectId,this.sectNumber);
        }
        else if(this.isSectionCopy == true){this.isLOBEmpty = false;
            this.TotalEPIValue = this.selectedRowSectionCopy.TotalEPI__c;this.sectionId = this.selectedRowSectionCopy.Id;
            this.selectedLOB = this.selectedRowSectionCopy.LoB__c;this.selectedSubLOB = this.selectedRowSectionCopy.SubLoB__c;
            this.SectionName = this.selectedRowSectionCopy.Name;this.limitFlag = this.selectedRowSectionCopy.TECH_IsLimit__c;
            this.deductibleFlag = this.selectedRowSectionCopy.TECH_IsDeductible__c;this.Renewed = this.selectedRowSectionCopy.TECH_RenewedSection_ID__c;
            this.ReinsuranceValue = this.selectedRowSectionCopy.NonTraditionalReinsuranceAndOrFinit__c;this.NatureValue = this.selectedRowSectionCopy.Nature__c;
            this.isPooled = this.selectedRowSectionCopy.Treaty__r.IsPooled__c;this.TypeOfReinstatement = this.selectedRowSectionCopy.Reinstatements__c;

            if(this.isPooled == '1'){this.PooledValue = true;
            }else{this.PooledValue = false;}
            this.CommentsValue = this.selectedRowSectionCopy.Comments__c;
            this.QuoteRequestTypeValue = this.selectedRowSectionCopy.QuoteType__c;
            this.techNatureProgram = this.selectedRowSectionCopy.TECH_NatureProgram__c;
            this.populateInclusionExclusionInfo(this.techNatureProgram);

            if(this.Option == '1' && this.selectedRowSectionCopy.Option__c == '1'){
                this.RelatedSection = this.selectedRowSectionCopy.TECH_RelatedSectionNumber__c;
                this.selectedSectId = this.selectedRowSectionCopy.Id;
                this.sectNumber = this.selectedRowSectionCopy.SectionNumber__c;
                this.getOptionSectionNumber(this.selectedRowSectionCopy.RelatedSection__c,this.sectNumber);
            }
            else if(this.Option == '1'){
                this.RelatedSection = this.selectedRowSectionCopy.TECH_RelatedSectionNumber__c;
                this.isSectionNewOption = true;
                this.selectedSectId = this.selectedRowSectionCopy.Id;
                this.sectNumber = this.selectedRowSectionCopy.SectionNumber__c;
            }else{this.getSectionNumber(this.treatyId);
            }
            this.populateConditionalTypeOfTreaty(this.selectedRowSectionCopy);

        }
        else if(this.isSectionEdit == true){
            this.populateSectionEdit();
        }
        else{
            this.selectedTreatyId = this.selectedTreaties[0];
            this.covCed = [];
            this.MethodDistribution = 'EPI prorata';

            getTreatyDetails({ selectedTreatyId : this.recordId})
            .then(result => {
                this.ProgramName = result.TECH_ProgramName__c;
                this.TreatyName = result.Name;
                this.treatyId = result.Id;
                this.programId = result.Program__c;
                this.uwYearOpenModal = result.Program__r.UwYear__c;

                this.compOpenModal = result.Program__r.PrincipalCedingCompany__c;
                this.typeOfTreaty = result.TypeofTreaty__c;
                this.techNatureProgram = result.TECH_ProgramNature__c;
                this.isPooled = result.IsPooled__c;
                if(this.isPooled == '1'){
                    this.PooledValue = true;
                } else{
                    this.PooledValue = false;
                }

                if(result.Program__r.LTA__c == '1'){this.showTAL = true;}
                if (this.techNatureProgram == '23002'){this.isTechNatureProgramLife = true;}
                else if(this.techNatureProgram == '23001'){this.isTechNatureProgramLife = false;}
                if(this.typeOfTreaty == '2'){this.isTypeOfTreatyXL = true;}
                else if(this.typeOfTreaty == '3'){this.isTypeOfTreatyQS = true;}
                else if(this.typeOfTreaty == '5'){this.isTypeOfTreatyAXAXLQS = true;}
                else if(this.typeOfTreaty == '4'){this.isTypeOfTreatySurplus = true;}
                else if(this.typeOfTreaty == '1'){this.isTypeOfTreatyStopLoss = true;}
                this.getCoveredCedingCompaniesByTreatyId(this.selectedProgram[0], this.selectedTreaties[0]);
                if (this.MethodDistribution == 'EPI prorata'){
                    this.isMethodDistributionProrata = true;
                }else{
                  this.isMethodDistributionProrata = false;
                }
                this.getSectionNumber(this.treatyId);
                this.refreshWiredPicklist();
                this.refreshWiredLob();

                if(this.wiredPicklist != null){
                    if(this.createPage == true && this.sObjectName == 'Treaty__c'){
                        this.getTreatyDetails('populateQuoteType');
                    }
                    else if(this.createPage == true && this.sObjectName == 'Section__c'){
                        this.getSectionDetails('populateQuoteType');
                    }
                    else{
                        this.populateQuoteTypePicklistValues(this.typeOfTreaty, this.wiredPicklist);
                    }
                }

                if(this.wiredLob != null){
                    if(this.isSectionEdit){
                        this.getProgramDetails('edit');
                    }
                    else if(this.createPage == true && this.sObjectName == 'Treaty__c'){
                        this.getTreatyDetails('populateLobSubLob');
                    }
                    else if(this.createPage == true && this.sObjectName == 'Section__c'){
                        this.getSectionDetails('populateLobSubLob');
                    }
                    else{
                        this.populateLobSubLobPicklistValues(this.techNatureProgram, this.wiredLob);
                    }
                }
            })
            .catch(error => {
                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error'}), );
            });
        }
        this.getPoolsDetail();
        this.displaySection = true;
        this.getAllSectionOption();
    }
    getVal(val){
        this.uwYearOpenModal = val;
    }
    getComp(val){
        this.compOpenModal = val;
    }
    @wire(getPicklistValuesByRecordType, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', objectApiName: SECTION_OBJECT})
    LOBPicklistValues({error, data}) {
        if(data) {
            this.error = null;
            this.wiredLob = data;

            if(this.isSectionEdit){
                this.getProgramDetails('edit');
            }
            else if(this.createPage == true && this.sObjectName == 'Treaty__c'){
                this.getTreatyDetails('populateLobSubLob');
            }
            else if(this.createPage == true && this.sObjectName == 'Section__c'){
                this.getSectionDetails('populateLobSubLob');
            }
            else{
                this.populateLobSubLobPicklistValues(this.techNatureProgram, data);
            }
        }
        else if(error) {
            this.error = JSON.stringify(error);
        }
    }
    changeCessionPerc(event){
        let val = event.target.value;
        this.CessionPercValue = parseFloat(val);
            this.RetentionPercValue = parseFloat(100 - val);
            if(this.CapacityPerRiskValue != ''){
                this.CessionAmountValue = Math.round(parseFloat(val)/100 * this.CapacityPerRiskValue);
                this.RetensionAmountValue = Math.round(parseFloat(this.RetentionPercValue)/100 * this.CapacityPerRiskValue);
            }
        if(this.TotalEPIValue != undefined){
            this.CededPremiumValue = parseFloat(val)/100 * parseFloat(this.TotalEPIValue);
        }
    }
    changeRetentionPerc(event){
        let val = event.target.value;
        this.RetentionPercValue = parseFloat(val);
            this.CessionPercValue = parseFloat(100 - val);
            if(this.CapacityPerRiskValue != ''){
                this.CessionAmountValue = Math.round(parseFloat(this.CessionPercValue)/100 * this.CapacityPerRiskValue);
                this.RetensionAmountValue = Math.round(parseFloat(val)/100 * this.CapacityPerRiskValue);
            }
    }
    changeCapacityRisk(event){
        let val = event.target.value;
        this.CapacityPerRiskValue = val;
        if(this.UnlimitedValue == undefined || this.UnlimitedValue == false){
            if(this.CapacityPerRiskValue != undefined && this.CapacityPerRiskValue != '' && this.CessionPercValue != undefined && this.CessionPercValue != ''){
                this.CessionAmountValue = Math.round(parseFloat(this.CessionPercValue)/100 * this.CapacityPerRiskValue);
            }
            if(this.CapacityPerRiskValue != undefined && this.CapacityPerRiskValue != '' && this.RetentionPercValue != undefined && this.RetentionPercValue != ''){
                this.RetensionAmountValue = Math.round(parseFloat(this.RetentionPercValue)/100 * this.CapacityPerRiskValue);
            }
        }
    }
    handleUnlimitedChange(event){
        this.UnlimitedValue = event.target.checked;
        if(this.UnlimitedValue == true){
            this.disableWhenUnlimited = true;
            this.unlimitedSelected = true;
            this.deductibleValueEmpty = false;
            this.CapacityPerRiskValue = '';
            this.CessionAmountValue = '';
            this.limitValueEmpty = false;
            this.LimitValue = '';
            this.RetensionAmountValue = '';
            if(this.template.querySelector('[data-id="maxLimit"]') != undefined){
                this.template.querySelector('[data-id="maxLimit"]').value = '';
            }
        }
        else if(this.UnlimitedValue == false){
            this.disableWhenUnlimited = false;
            this.unlimitedSelected = false;
        }
    }
    handleLOBChange(event) {
        this.selectedLOB = event.target.value;
        this.isLOBEmpty = false;
        let dependValues = [];

        if(this.template.querySelector('[data-id="subLOB"]') != undefined){
            this.template.querySelector('[data-id="subLOB"]').value = '';
        }

        if(this.selectedLOB) {
            if(this.selectedLOB === '--None--') {
                this.isLOBEmpty = true;
                dependValues = [{label:'--None--', value:'--None--'}];
                this.selectedLOB = null;
                this.selectedSubLOB = null;
                return;
            }

            this.totalDependentSubLOBValues.forEach(LOBValues => {
                if(LOBValues.validFor[0] === this.controlSubLOBValues[this.selectedLOB]) {
                    dependValues.push({ label: LOBValues.label, value: LOBValues.value});
                }
            })
            this.dependentSubLOBValues = dependValues;
        }
    }
    handleSubLOBChange(event) {
        this.selectedSubLOB = event.target.value;
    }
    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: QUOTETYPE_FIELD})
    setQuoteTypePicklistOpt({error, data}) {
        this.wiredPicklist = data;
        if(data){
            if(this.createPage == true && this.sObjectName == 'Treaty__c'){
                this.getTreatyDetails('populateQuoteType');
            }
            else if(this.createPage == true && this.sObjectName == 'Section__c'){
                this.getSectionDetails('populateQuoteType');
            }
            else{
                if(this.isSectionEdit == true){
                   getSectionDetails({ selectedSectionId : this.recordId})
                   .then(result => {
                       this.typeOfTreaty = result.TECH_TypeofTreaty__c;
                       this.populateQuoteTypePicklistValues(this.typeOfTreaty, data);
                   })
                   .catch(errorSection => {
//                       this.dispatchEvent(new ShowToastEvent({title: 'Error', message: errorSection.message, variant: 'error'}), );
                   });
                }
                else{this.populateQuoteTypePicklistValues(this.typeOfTreaty, data);}
            }
        }
        else{this.error = error;}
    }
    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: OPTION_FIELD})
    setOptionPicklistOpt({error, data}) {
        if(data){
            this.OptionOpt = data.values;
        }else{
            this.error = error;
        }
    }
    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: REINSURANCE_FIELD})
    setReinsurancePicklistOpt({error, data}) {
        if(data){
            this.ReinsuranceOpt = data.values;
        }else{
            this.error = error;
        }
    }
    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: NATURE_FIELD})
    setNaturePicklistOpt({error, data}) {
        if(data){
            this.NatureOpt = data.values;
        }else{
            this.error = error;
        }
    }
    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: METHODDISTRIBUTION_FIELD})
    setMethodDistributionPicklistOpt({error, data}) {
        if(data){
            this.MethodDistributionOpt = data.values;
            if(this.isSectionCopy == false && this.isSectionNewOption == false && this.isSectionEdit == false){
                this.MethodDistribution = 'EPI prorata';
            }

            if(this.createPage == true && this.Option == '2'){
               this.MethodDistribution = 'EPI prorata';
            }
        }else{
           this.error = error;
        }
    }
    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: POOLEDSECTION_FIELD})
    setPooledSectionPicklistOpt({error, data}) {
        if(data){
            this.PooledOpt = data.values;
        } else{
            this.error = error;
        }
    }
    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: LIMITTYPE_FIELD})
    setLimitTypePicklistOpt({error, data}) {
        if(data){
            this.LimitTypeOpt = data.values;
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
            this.mapCurrency = new Map();

            if(wireResults.length > 0){
                //get all picklist options first
                wireResults.forEach(ele => {
                    unsortedCurList.push({'label':ele.label,'value':ele.value});

                    this.mapCurrency.set(ele.label, ele.value);
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
                this.CurrencyOpt = sortedCurList;

                if(this.isSectionCopy){
                    this.CurrencyValue = this.mapCurrency.get(this.CurrencyValue);
                }
            }
        }
        else{
           this.error = error;
        }
    }
    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', objectApiName: REINSTATEMENT_OBJECT, fieldApiName: PRORATA_REINS_FIELD})
    setProrataReinsPicklistOpt({error, data}) {
        if(data){
            this.prorataReinsOpt = data.values;
            this.mapProrataLabelValue = new Map();
            this.mapProrataValueLabel = new Map();

            for(var i = 0; i < data.values.length; i++){
                this.mapProrataLabelValue.set(data.values[i].label, data.values[i].value);
                this.mapProrataValueLabel.set(data.values[i].value, data.values[i].label);
            }

        }else{
            this.error = error;
        }
    }
    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', objectApiName: REINSTATEMENT_OBJECT, fieldApiName: REINSTATEMENT_FIELD})
    setReinstatemnetPicklistOpt({error, data}) {
        if(data){
            this.ReinstatementOpt = data.values;
            this.mapReinstatementType = new Map();

            for(var i = 0; i < data.values.length; i++){
               this.mapReinstatementType.set(data.values[i].label, data.values[i].value);
            }

        }
        else{
           this.error = error;
        }
    }
    @wire(getPicklistValues, { recordTypeId: '$objectInfoPoolTreatySection.data.defaultRecordTypeId', fieldApiName: SUBLOB_POOL_FIELD})
    setSubLobPicklistOpt({error, data}) {
       if(data){
           this.subLoBPoolOpt = data.values;
           this.mapSubLobPool = new Map();

           for(var i = 0; i < data.values.length; i++){
               this.mapSubLobPool.set(data.values[i].label, data.values[i].value);
           }

       }
       else{
           this.error = error;
       }
    }
    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: INCLUSION_FIELD})
    setInclusionPicklistOpt({error, data}) {
       if(data){
           this.InclusionOpt = data.values;
       }
       else{
           this.error = error;
       }
    }
    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: EXCLUSION_FIELD})
    setExclusionPicklistOpt({error, data}) {
       if(data){
           this.ExclusionOpt = data.values;
       }
       else{
           this.error = error;
       }
    }
    refreshWiredPicklist(){
        return refreshApex(this.wiredPicklist);
    }
    refreshWiredLob(){
        return refreshApex(this.wiredLob);
    }
    getSectionNumber(treatyId){
        getSectionNumber({treatyId: treatyId})
        .then(result =>{
        if(result && this.isSectionNewOption == false && this.Option == '2' && this.isSectionEdit == false) {
            this.sectionNumber = result;
            this.error = undefined;
        }
        })
        .catch(error => {
            this.error = error;
            this.sectionNumber = undefined;
        });
    }
    getOptionSectionNumber(selectedSectionId,parentSectionNumber){
        getOptionSectionNumber({selectedSectionId:selectedSectionId,parentSectionNumber:parentSectionNumber})
       .then(result =>{
           if(result && this.Option == '1'){
               this.sectionNumber = result;
               this.error = undefined;
           }
       })
       .catch(error => {
           this.error = error;
           this.sectionNumber = undefined;
       });
    }
    handleCloseSectionModal(){
        if(this.isSectionEdit == true){
           window.history.back();
           return false;
        }
        else if(this.createPage){
            window.history.back();
            return false;
        }
        else{
           fireEvent(this.pageRef, 'closeSectionModal', false);
           this.isSectionCopy = false;
        }
    }
    handleSaveSection(){
        this.displaySpinner = true;
        let inputs= this.template.querySelectorAll('lightning-input, lightning-combobox, lightning-textarea');
        let dataInput = {};

        for(let input of inputs){
            if(input.type == 'checkbox'){
               dataInput[input.name] = input.checked;
            }
            else{dataInput[input.name] = input.value;}
        }

        this.objSection.Program__c = this.programId;
        this.objSection.Treaty__c = this.treatyId;
        this.objSection.Name = dataInput.SectionName;
        this.objSection.Option__c = dataInput.Option;
        this.objSection.SectionNumber__c = this.sectionNumber;

        if(this.isSectionNewOption == true || (this.createPage == true && this.objSection.Option__c == '1')){
            this.objSection.RelatedSection__c = this.selectedRowSectionCopy.Id;
        }
        else if((this.isSectionCopy == true && this.Option == '1') || (this.isSectionEdit == true && this.Option == '1')){
            this.objSection.RelatedSection__c = this.selectedRowSectionCopy.RelatedSection__c;
        }
        else{
           this.objSection.RelatedSection__c = dataInput.RelatedSection;
        }

        this.objSection.RenewedFromSectionOption__c = dataInput.Renewed;
        this.objSection.LoB__c = dataInput.LOB;
        this.objSection.SubLoB__c = dataInput.SubLOB;
        this.objSection.NonTraditionalReinsuranceAndOrFinit__c = dataInput.Reinsurance;
        this.objSection.MethodOfDistributionOfThePremium__c = dataInput.MethodDistribution;
        this.objSection.TotalEPI__c = dataInput.TotalEPI;
        this.objSection.Nature__c = dataInput.Nature;
        this.objSection.PooledSectionOption__c = dataInput.IsPooled;
        this.objSection.LimitType__c = dataInput.LimitType;
        this.objSection.Currency__c = dataInput.Currency;
        this.objSection.Unlimited__c = dataInput.Unlimited;
        this.objSection.Limit__c = dataInput.Limit;
        this.objSection.LimitPercent__c = parseFloat(dataInput.LimitPerc);

        if(this.isTypeOfTreatyXL == true){
            this.objSection.Deductible__c = parseFloat(this.DeductibleValue);
            this.objSection.DeductiblePercent__c = null;
        }
        else if(this.isTypeOfTreatyStopLoss == true){
            this.objSection.Deductible__c = null;
            this.objSection.DeductiblePercent__c = parseFloat(this.DeductibleValue);
        }
        else{
            this.objSection.Deductible__c = null;
            this.objSection.DeductiblePercent__c = null;
        }

        this.objSection.AAL__c = dataInput.AAL;
        this.objSection.AAD__c = dataInput.AAD;
        this.objSection.TAL__c = dataInput.TAL;
        this.objSection.ExpectedMDP__c = parseFloat(dataInput.ExpectedMDP);
        this.objSection.ExpectedDP__c = parseFloat(dataInput.ExpectedDP);
        this.objSection.ExpectedMP__c = parseFloat(dataInput.ExpectedMP);
        this.objSection.Reinstatements__c = dataInput.Reinstatements;
        this.objSection.InclusionOfCatastrophicGuarantees__c = dataInput.Inclusion;
        this.objSection.ExclusionOfCatastrophicGuarantees__c = dataInput.Exclusion;
        this.objSection.Comments__c = dataInput.Comments;
        this.objSection.QuoteType__c = dataInput.QuoteRequestType;
        this.objSection.TECH_TypeofTreaty__c = this.typeOfTreaty;
        this.objSection.Incl_Earthquake__c = dataInput.InEarthquake;
        this.objSection.Incl_Terrorism__c = dataInput.InTerrorism;
        this.objSection.Incl_Flood__c = dataInput.InFlood;
        this.objSection.Incl_SRCC__c = dataInput.InSRCC;
        this.objSection.Incl_Hurricane__c = dataInput.InHurricane;
        this.objSection.Incl_Others__c = dataInput.InOthers;
        this.objSection.Incl_OtherRisks__c = dataInput.InOtherRisks;
        this.objSection.Incl_All__c = dataInput.InAll;
        this.objSection.Excl_War__c = dataInput.ExWar;
        this.objSection.Excl_NuclearRisks__c = dataInput.ExNuclearRisks;
        this.objSection.Excl_Terrorism__c = dataInput.ExTerrorism;
        this.objSection.Excl_Biological__c = dataInput.ExBiological;
        this.objSection.Excl_NuclearBiological__c = dataInput.ExNuclearBiologicalChemical;
        this.objSection.Excl_Others__c = dataInput.ExOthers;
        this.objSection.Excl_Epidemic__c = dataInput.ExEpidemicPandemic;
        this.objSection.Excl_All__c = dataInput.ExAll;
        this.objSection.TECH_NatureProgram__c = this.techNatureProgram;
        this.objSection.CapacityPerRisk__c = dataInput.CapacityPerRisk;
        this.objSection.EventLimit__c = dataInput.EvenLimit;
        this.objSection.Cession_Perc__c = parseFloat(dataInput.CessionPerc);
        this.objSection.Retention__c = parseFloat(dataInput.RetentionPerc);
        this.objSection.CessionAmount__c = dataInput.CessionAmount;
        this.objSection.RetentionAmount__c = dataInput.RetensionAmount;
        this.objSection.CededPremium__c = parseFloat(dataInput.CededPremium);
        this.objSection.LineAmount__c = dataInput.LineAmount;
        this.objSection.CededLines__c = parseFloat(dataInput.CededLine);
        this.objSection.RetentionLine__c = dataInput.RetentionLine;
        this.objSection.Capacity__c = dataInput.Capacity;
        this.objSection.MaxLimitAmount__c = parseFloat(dataInput.MaxLimitAmount);
        this.objSection.MinLimitAmount__c = parseFloat(dataInput.MinLimitAmount);
        this.objSection.TECH_IsLimit__c = dataInput.isLimit;
        this.objSection.TECH_IsDeductible__c = dataInput.isDeductible;

        if(this.Renewed != undefined && this.Renewed != null){
            this.objSection.TECH_RenewedSection_ID__c = this.Renewed;

            for(let i = 0; i < this.lstAllSectionOptions.length; i++){
                if(this.lstAllSectionOptions[i].value == this.Renewed){
                    this.objSection.RenewedFromSectionOption__c = this.lstAllSectionOptions[i].label;
                }
            }
        }

        if(this.objSection.Name == ""  || this.objSection.QuoteType__c == null
            || this.objSection.LoB__c == null || this.objSection.SubLoB__c == null
            || this.objSection.NonTraditionalReinsuranceAndOrFinit__c == null || this.objSection.Nature__c == null
            || this.objSection.Currency__c == null || this.objSection.LimitType__c == null
            || ( this.isTypeOfTreatySurplus == true && (this.objSection.LineAmount__c == "" || this.objSection.CededLines__c == "" || this.objSection.RetentionLine__c == "" || this.objSection.RetentionAmount__c == "" ) )
            /*1966*/ || ( (this.isTypeOfTreatyQS == true || this.isTypeOfTreatyAXAXLQS == true) && (this.objSection.Cession_Perc__c == undefined || isNaN(this.objSection.Cession_Perc__c) || this.objSection.Retention__c == undefined || isNaN(this.objSection.Retention__c))
             /*1966*/ || ((this.isTypeOfTreatyQS == true || this.isTypeOfTreatyAXAXLQS == true) && this.objSection.Unlimited__c == false && (this.objSection.CapacityPerRisk__c == "" || isNaN(this.objSection.CapacityPerRisk__c) || this.objSection.CessionAmount__c == "" ||this.objSection.CessionAmount__c == ""|| isNaN(this.objSection.CessionAmount__c) || this.objSection.RetentionAmount__c == "" || this.objSection.RetentionAmount__c == "" || isNaN(this.objSection.RetentionAmount__c )))
            || ( this.isTypeOfTreatyStopLoss == true && this.objSection.Unlimited__c == false && (isNaN(this.objSection.LimitPercent__c) || this.objSection.LimitPercent__c == undefined || isNaN(this.objSection.DeductiblePercent__c) || this.objSection.DeductiblePercent__c == undefined) )
            || ( this.isTypeOfTreatyXL == true && ( (this.objSection.Unlimited__c == false && (isNaN(this.objSection.Limit__c) || this.objSection.Limit__c == undefined)) || isNaN(this.objSection.Deductible__c) == true || this.objSection.Deductible__c == undefined || this.objSection.Reinstatements__c == null  || this.objSection.Reinstatements__c == undefined  || this.objSection.Reinstatements__c == '') )
            || ( this.objSection.ExclusionOfCatastrophicGuarantees__c == null && this.objSection.InclusionOfCatastrophicGuarantees__c == null)  )){

            this.dispatchEvent(new ShowToastEvent({title: 'ERROR', message: this.label.Required_Fields, variant: 'error'}),);
            this.displaySpinner = false;

            if(this.objSection.Name == ""){
                this.nameEmpty = true;
            }
            if(this.objSection.ExclusionOfCatastrophicGuarantees__c == null && this.objSection.InclusionOfCatastrophicGuarantees__c == null){
                this.exclusionEmpty = true;
            }
            if(this.objSection.QuoteType__c == null){
                this.quoteTypeEmpty = true;
            }
            if(this.objSection.LoB__c == null){
                this.lobEmpty = true;
            }
            if(this.objSection.SubLoB__c == null){
                this.sublobEmpty = true;
            }
            if(this.objSection.NonTraditionalReinsuranceAndOrFinit__c == null){
                this.nonTradReinsEmpty = true;
            }
            if(this.objSection.Nature__c == null){
                this.natureEmpty = true;
            }
            if(this.objSection.Currency__c == null){
                this.currencyEmpty = true;
            }
            if(this.objSection.LimitType__c == null){
                this.limitTypeEmpty = true;
            }
            if(this.isTypeOfTreatySurplus == true && this.objSection.LineAmount__c == ""){
                this.lineAmountEmpty = true;
            }
            if(this.isTypeOfTreatySurplus == true && this.objSection.CededLines__c == ""){
                this.cededLinesEmpty = true;
            }
            if(this.isTypeOfTreatySurplus == true && this.objSection.RetentionLine__c == ""){
                this.retentionLineEmpty = true;
            }
            if(this.isTypeOfTreatySurplus == true && this.objSection.RetentionAmount__c == ""){
                this.retentionAmountEmpty = true;
            }
            if((this.isTypeOfTreatyQS == true || this.isTypeOfTreatyAXAXLQS == true) && (isNaN(this.objSection.CapacityPerRisk__c) || this.objSection.CapacityPerRisk__c == "" ) && this.objSection.Unlimited__c == false){
                this.capacityPerRiskEmpty = true;
            }
            if((this.isTypeOfTreatyQS == true || this.isTypeOfTreatyAXAXLQS == true) && (this.objSection.Cession_Perc__c == undefined ||  isNaN(this.objSection.Cession_Perc__c) )){
                this.cessionPercEmpty = true;
            }
            if((this.isTypeOfTreatyQS == true || this.isTypeOfTreatyAXAXLQS == true) && (isNaN(this.objSection.Retention__c) || this.objSection.Retention__c == undefined)){
                this.retentionPercEmpty = true;
            }
            if((this.isTypeOfTreatyQS == true || this.isTypeOfTreatyAXAXLQS == true) && (isNaN(this.objSection.CessionAmount__c) || this.objSection.CessionAmount__c == undefined || this.objSection.CessionAmount__c == "" )){
                this.cessionAmountEmpty = true;
            }
            if((this.isTypeOfTreatyQS == true || this.isTypeOfTreatyAXAXLQS == true) && ( isNaN(this.objSection.RetentionAmount__c) || this.objSection.RetentionAmount__c == undefined || this.objSection.RetentionAmount__c == "" )){
                this.retentionAmountEmpty = true;
            }
            if(this.isTypeOfTreatyStopLoss == true &&  this.objSection.Unlimited__c == false && (isNaN(this.objSection.LimitPercent__c)  || this.objSection.LimitPercent__c == undefined)){
                this.limitValueEmpty = true;
            }
            if(this.isTypeOfTreatyStopLoss == true && (isNaN(this.objSection.DeductiblePercent__c) || this.objSection.DeductiblePercent__c == undefined)){
                this.deductibleValueEmpty = true;
            }
            if(this.isTypeOfTreatyXL == true && this.objSection.Unlimited__c == false && (isNaN(this.objSection.Limit__c) || this.objSection.Limit__c == undefined)){
                this.limitValueEmpty = true;
            }
            if(this.isTypeOfTreatyXL == true && (isNaN(this.objSection.Deductible__c) || this.objSection.Deductible__c == "" || this.objSection.Deductible__c == undefined) ){
                this.deductibleValueEmpty = true;
            }
            if(this.isTypeOfTreatyXL == true && (this.objSection.Reinstatements__c == null || this.objSection.Reinstatements__c == '' || this.objSection.Reinstatements__c == undefined)){
                this.reinstatementsEmpty = true;
            }
        }
        else{
           var lstAccountIdCovCedingCom = [];
           var lstCovCedingCom = [];
           let totalFixedAllocationKey = 0;

           if(this.isMethodDistributionProrata){
                for(let i = 0; i < this.dataCedingCompanyProrata.length; i++){
                    let row = { ...this.dataCedingCompanyProrata[i] };
                    if(row.Checked == true){
                        lstAccountIdCovCedingCom.push(row.AccountId);
                        var objCoveredCedComp = {
                            AllocationKey__c : ALLOCATION_KEY_FIELD, EPI__c : EPI_FIELD, Account__c : ACCOUNTID_FIELD
                        }
                        objCoveredCedComp.AllocationKey__c = parseFloat(row.AllocationKeyFloat);
                        objCoveredCedComp.EPI__c = row.EPI;
                        objCoveredCedComp.Account__c = row.AccountId;
                        lstCovCedingCom.push(objCoveredCedComp);
                    }
                }
            }
            else{
               for(let i = 0; i < this.dataCedingCompanyFixedKeys.length; i++){
                   let row = { ...this.dataCedingCompanyFixedKeys[i] };
                   if(row.Checked == true){
                       lstAccountIdCovCedingCom.push(row.AccountId);
                       totalFixedAllocationKey =  totalFixedAllocationKey + parseFloat(this.dataCedingCompanyFixedKeys[i].AllocationKey);

                       var objCoveredCedComp = {
                           AllocationKey__c : ALLOCATION_KEY_FIELD, EPI__c : EPI_FIELD, Account__c : ACCOUNTID_FIELD
                       }
                       objCoveredCedComp.AllocationKey__c = parseFloat(row.AllocationKey);
                       objCoveredCedComp.EPI__c = row.EPI;
                       objCoveredCedComp.Account__c = row.AccountId;
                       lstCovCedingCom.push(objCoveredCedComp);
                   }
               }
               totalFixedAllocationKey = Math.round(totalFixedAllocationKey);
           }

           if(lstCovCedingCom.length == 0){
               this.displaySpinner = false;
               this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.Ceded_Company_Empty, variant: 'error'}), );
           }
           else if(this.isMethodDistributionProrata == false && totalFixedAllocationKey != 100){
               this.displaySpinner = false;
               this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.Allocation_Key, variant: 'error'}), );
           }
           else if(this.objSection.InclusionOfCatastrophicGuarantees__c == '1'
                   && this.objSection.Incl_Earthquake__c == false && this.objSection.Incl_Terrorism__c == false
                   && this.objSection.Incl_Flood__c == false && this.objSection.Incl_SRCC__c == false
                   && this.objSection.Incl_Hurricane__c == false && this.objSection.Incl_OtherRisks__c == false && this.objSection.Incl_All__c == false && this.objSection.Incl_Others__c == false){
               this.displaySpinner = false;
               this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.Inclusion_Catastrophy, variant: 'error'}), );
           }
           else if(this.objSection.ExclusionOfCatastrophicGuarantees__c == '1'
                   && this.objSection.Excl_War__c == false && this.objSection.Excl_NuclearRisks__c == false && this.objSection.Excl_Terrorism__c == false
                   && this.objSection.Excl_Biological__c == false && this.objSection.Excl_NuclearBiological__c == false
                   && this.objSection.Excl_Others__c == false && this.objSection.Excl_Epidemic__c == false && this.objSection.Excl_All__c == false && this.objSection.Excl_Others__c == false){
               this.displaySpinner = false;
               this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.Exclusion_Catastrophy, variant: 'error'}), );
           }
           else{
               var lstSelectedReinstatement = [];
               if (this.dataReinstatements != undefined){
                   for (var i = 0; i < this.dataReinstatements.length; i++){
                       var objReinstatement = {
                           Order__c : ORDER_REINS_FIELD, Percentage__c : PERC_REINS_FIELD, Prorata__c : PRORATA_REINS_FIELD, Type__c : TYPE_REINS_FIELD, Free__c : FREE_FIELD
                       }
                       objReinstatement.Order__c = this.dataReinstatements[i].Order;
                       objReinstatement.Percentage__c = this.dataReinstatements[i].Percentage.trim();
                       objReinstatement.Prorata__c = this.mapProrataLabelValue.get(this.dataReinstatements[i].Prorata);
                       objReinstatement.Free__c = this.dataReinstatements[i].Free;
                       if(this.TypeOfReinstatement != null){
                           objReinstatement.Type__c = this.TypeOfReinstatement;
                       }
                       lstSelectedReinstatement.push(objReinstatement);
                   }
               }

               if(this.typeOfTreaty == '2' && lstSelectedReinstatement.length < 0){
                   this.displaySpinner = false;
                   this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.Reinstatement_Empty, variant: 'Error' }),);
               }
               else{
                   let lstPoolsToSave = [];

                   for(let i = 0; i < this.lstPools.length - 1; i++){
                       let rowPool = { ...this.lstPools[i]};
                       if(rowPool.Checked == true){
                           lstPoolsToSave.push(rowPool)
                       }
                   }

                   if(this.PooledValue == true && lstPoolsToSave.length == 0){
                       this.displaySpinner = false;
                       this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.EmptyPool, variant: 'error'}), );
                   }
                   else{
                       const allValid = [...this.template.querySelectorAll('lightning-input, lightning-combobox, lightning-textarea')]
                       .reduce((validSoFar, inputCmp) => {
                           inputCmp.reportValidity();
                           return validSoFar && inputCmp.checkValidity();}, true);

                       if(allValid){
                           saveSectionRecord({ objectSection : this.objSection, lstCovCedCom : lstCovCedingCom, lstReinstatement : lstSelectedReinstatement, editSection : this.isSectionEdit, selectedSectionId : this.sectionId, createPageSection : this.createPage, isPooledValue : this.PooledValue, lstPool : lstPoolsToSave})
                           .then(result => {
                                if(result.hasOwnProperty('Error') && result.Error){
                                    this.displaySpinner = false;
                                   this.dispatchEvent(new ShowToastEvent({title: 'Error', message: result.Error, variant: 'error' }),);
                                }
                                else{
                                    if(this.isSectionEdit){
                                       this.dispatchEvent(new ShowToastEvent({title: 'Success', message: this.label.Section_Updated, variant: 'success' }),);
                                    }
                                    else if(this.createPage == true){
                                       this.dispatchEvent(new ShowToastEvent({title: 'Success', message: this.label.Section_Created, variant: 'success' }),);
                                    }

                                    if(this.isSectionEdit){
                                       window.history.back();
                                       fireEvent(this.pageRef, 'refreshSection', 'refresh');
                                       return false;
                                    }
                                    else{
                                       fireEvent(this.pageRef, 'closeSectionModal', false);
                                       fireEvent(this.pageRef, 'refreshSection', 'refresh');
                                       this.dispatchEvent(new ShowToastEvent({title: 'Success', message: this.label.Section_Created, variant: 'success' }),);
                                    }
                                    this.isSectionCopy = false;
                                    this.isSectionEdit = false;
                                    this.isSectionNewOption = false;
                                    this.createPage = false;
                                }
                                this.displaySpinner = false;
                            })
                           .catch(error => {
                                this.displaySpinner = false;
                                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error'}), );
                           });
                       }
                       else{
                           this.displaySpinner = false;
                           this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.FormEntriesInvalid, variant: 'error'}), );
                       }
                   }
               }
           }
       }
   }
   handleChangeInclusionValue(event){
       this.isInclusion = event.detail.value;
       if(this.isInclusion == '1'){
           this.InclusionValue = true;
       }else{
           this.InclusionValue = false;
       }
   }
   handleChangeExclusionValue(event){
       this.isExclusion = event.detail.value;
       if(this.isExclusion == '1'){
           this.ExclusionValue = true;
       }else{
           this.ExclusionValue = false;
       }
   }
   handleChangePooledValue(event){
       this.isPooled = event.detail.value;
       if(this.isPooled == '1'){
           this.PooledValue = true;
       }else{
           this.PooledValue = false;
       }
   }
   handleChangeTotalEPI(event){
       this.TotalEPIValue = event.target.value;
       if(this.CessionPercValue != undefined){
           this.CededPremiumValue = parseFloat(this.CessionPercValue)/100 * parseFloat(this.TotalEPIValue);
       }
   }
   handleMethodDistributionChange(event){
       this.MethodDistribution = event.target.value;
       let totalEPI = 0;
       let lengthOfSelectedCovCedCom = 0;

       if(this.MethodDistribution == 'EPI prorata'){
           this.isMethodDistributionProrata = true;
           let allocationKey = 0;
           let updDataCedingCompanyProrata = [];
           let updDataCedingCompanyProrataNew = [];

           for(var i = 0; i < this.dataCedingCompanyProrata.length; i++){
               let rowProrata = { ...this.dataCedingCompanyProrata[i] };
               let rowfixed = { ...this.dataCedingCompanyFixedKeys[i] };

               if((this.createPage == false) || this.isSectionEdit == true ||  this.isSectionCopy == true || this.isSectionNewOption == true){
                   rowProrata['Checked'] = rowfixed['Checked'];
                   rowProrata['EPI'] = rowfixed['EPI'];
               }
               if(rowProrata['Checked'] == true){
                   totalEPI = totalEPI + parseFloat(rowProrata.EPI);
                   lengthOfSelectedCovCedCom = lengthOfSelectedCovCedCom + 1;
               }

               updDataCedingCompanyProrataNew.push(rowProrata);
           }

           this.dataCedingCompanyProrata = updDataCedingCompanyProrataNew;

           for(var i = 0; i < this.dataCedingCompanyProrata.length; i++){
               let row = { ...this.dataCedingCompanyProrata[i] };
               allocationKey = 0;
               if(totalEPI == 0 && lengthOfSelectedCovCedCom > 0){
                   if(row.Checked == true){
                       allocationKey = 100 / lengthOfSelectedCovCedCom;
                   }
               }else{
                   if(row.Checked == true){
                       allocationKey = (parseFloat(this.dataCedingCompanyProrata[i].EPI) / totalEPI) * 100;
                   }
               }
               row['AllocationKeyFloat'] = allocationKey.toFixed(6);;
               updDataCedingCompanyProrata.push(row);
           }

           this.dataCedingCompanyProrata = updDataCedingCompanyProrata;
       }
       else{
           this.isMethodDistributionProrata = false;
           let lstUpdDataCedComFixed = [];

           for(var i = 0; i < this.dataCedingCompanyFixedKeys.length; i++){
               let rowProrata = { ...this.dataCedingCompanyProrata[i] };
               let rowfixed = { ...this.dataCedingCompanyFixedKeys[i] };

               if((this.createPage == false) || this.isSectionEdit == true ||  this.isSectionCopy == true || this.isSectionNewOption == true){
                   rowfixed['Checked'] = rowProrata['Checked'];
                   rowfixed['EPI'] = rowProrata['EPI'];
                   rowfixed['AllocationKey'] =  parseFloat(rowProrata['AllocationKeyFloat']).toFixed(6);

                   if(rowfixed.Checked == true){
                       totalEPI = totalEPI + parseFloat(rowfixed.EPI);
                   }
               }
               else{
                   rowfixed['AllocationKey'] = parseFloat(rowfixed.AllocationKey).toFixed(6);
                   if(rowfixed.Checked == true){
                       totalEPI = totalEPI + parseFloat(rowfixed.EPI);
                   }
               }
               lstUpdDataCedComFixed.push(rowfixed);
           }

           this.dataCedingCompanyFixedKeys = lstUpdDataCedComFixed;
       }

       this.TotalEPIValue = totalEPI;
       this.calculateEPICededToPool(totalEPI);
   }
   handleOpenReinstatementsModal(){
       this.openNewReinstatementModal = true;
       this.isFreeChecked = false;
       this.disablePercentageReins = false;
       this.disableProrataReins = false;
       this.percentageReins = null;
       this.prorataReins = null;
       let lengthReinstatement = this.dataReinstatements.length;
       this.orderReins = lengthReinstatement + 1;
   }
   handleCloseReinstatementsModal(){
       this.openNewReinstatementModal = false;
   }
   handleDeleteReinstatements(){
       let lstSelectedReinstatement = [];

       for(let i = 0; i < this.selectedReinstatement.length; i++){
           let rowReins = this.selectedReinstatement[i];
           lstSelectedReinstatement.push(rowReins);
       }

       let filterReins = this.dataReinstatements.filter( function(e) { return this.indexOf(e) < 0; },lstSelectedReinstatement );
       let newDataReinstatements = [];

       if(this.dataReinstatements.length == this.selectedReinstatement.length){
           this.dataReinstatements = [];
           this.allDataReinstatements = this.dataReinstatements;
           this.selectedReinstatement = [];
           this.titleReinstatement = 'Reinstatements ('+ this.dataReinstatements.length +')';
       }
       else{
           this.dataReinstatements = [];

           for(let i = 0; i < filterReins.length; i++){
               let newReins = filterReins[i];
               let order;
               if(i == 0){
                   order = 1;
               }else{
                   order = i+1;
               }
               newReins['Order'] = order.toString();
               newDataReinstatements.push(newReins);
           }

          this.dataReinstatements = newDataReinstatements;
          this.allDataReinstatements = this.dataReinstatements;
          this.selectedReinstatement = [];
          this.titleReinstatement = 'Reinstatements ('+ this.dataReinstatements.length +')';
      }
   }
   handleAddReinstatement(){
       var newReinstatement = {};
       this.dataReinstatements = [];
       let inputs = this.template.querySelectorAll('lightning-input, lightning-combobox');
       let dataInput = {};
       for(let input of inputs){
           if (input.type == 'checkbox'){
               dataInput[input.name] = input.checked;
           }
           else{
               dataInput[input.name] = input.value;
           }
       }
       newReinstatement['Order'] = dataInput.orderReins;
       newReinstatement['Percentage'] = dataInput.percentageReins;
       newReinstatement['Prorata'] = this.mapProrataValueLabel.get(dataInput.prorataReins);
       newReinstatement['Free'] = dataInput.Free;

       if(dataInput.Free == true){
           newReinstatement['FreeValue'] = 'Yes';
       }
       else{
           newReinstatement['FreeValue'] = 'No';
       }

       this.allDataReinstatements.push(newReinstatement);
       this.openNewReinstatementModal = false;
       this.dataReinstatements = this.allDataReinstatements;
       var selectedReinstatement1 = [];
       var deleteReinstatements2 = this.dataReinstatements.filter( function(e) { return this; },selectedReinstatement1 );
       this.dataReinstatements = deleteReinstatements2;
       this.titleReinstatement = 'Reinstatements ('+ this.dataReinstatements.length +')';
   }
   handleReinstatementsRowSelection(event){
       var allDatatable = this.template.querySelectorAll('lightning-datatable');
       for(var i = 0; i < allDatatable.length; i++){
           if (allDatatable[i].keyField == 'ReinstatementDatatable'){
               this.selectedReinstatement = allDatatable[i].getSelectedRows();
           }
       }
   }
   handleChangeReinstatementValue(event){
       this.TypeOfReinstatement = event.detail.value;

       if(this.TypeOfReinstatement == '3'){
           this.isNewReinstatementDisable = false;
       }
       else{
           this.isNewReinstatementDisable = true;
           this.dataReinstatements = [];
           this.allDataReinstatements = [];
           this.titleReinstatement = 'Reinstatements ('+ this.dataReinstatements.length +')';
       }
   }
   handleChangeFreeCheck(event){
       this.isFreeChecked = event.detail.checked;

       if(this.isFreeChecked == true){
           this.disablePercentageReins = true;
           this.disableProrataReins = true;
           this.prorataReins = 0;
           this.percentageReins = null;
       }
       else{
           this.disablePercentageReins = false;
           this.disableProrataReins = false;
       }
   }
   handleChangeProrataReins(event){
       this.prorataReins = event.detail.value;
   }
   handleChangePercentageReins(event){
       this.percentageReins = event.detail.value;
   }
   handleReinsuranceChange(event){
       this.ReinsuranceValue = event.detail.value;
   }
   handleNatureChange(event){
       this.NatureValue = event.detail.value;
   }
   handleQuoteRequestTypeChange(event){
       this.QuoteRequestTypeValue = event.detail.value;
   }
   populateSectionEdit(){
       this.getProgramDetails('edit');
       getSectionDetails({ selectedSectionId : this.selectedRowSectionCopy.Id})
       .then(result => {
           this.Renewed = result.TECH_RenewedSection_ID__c;
           this.additionalSectionDetail = result;
           this.limitFlag = result.TECH_IsLimit__c;
           this.deductibleFlag = result.TECH_IsDeductible__c;

           if(result.Program__r.TECH_ShowClosePreviousPhaseBtn__c == '2'){
               this.closePreviousPhasesClick = true;
           }

           if(result.LimitPercent__c == null || isNaN(result.LimitPercent__c) || result.LimitPercent__c == undefined){
               this.disableWhenUnlimited = result.Unlimited__c;
           }

           if(result.Option__c == '1'){
               this.RelatedSection = result.TECH_RelatedSectionNumber__c;
           }
           else{
              this.RelatedSection__c = this.selectedRowSectionCopy.RelatedSection__c;
           }

           if(result.Program__r.LTA__c == '1'){
               this.showTAL = true;
           }

           this.unlimitedSelected = result.Unlimited__c;
           this.isPooled = result.Treaty__r.IsPooled__c;

           if(this.isPooled == '1'){
               this.PooledValue = true;
           }
           else{
               this.PooledValue = false;
           }

           this.sectionTotalEPIValue = result.TotalEPI__c;
           this.populateConditionalTypeOfTreaty(result);

           if(result.Program__r.RenewedFromProgram__c != null && result.Program__r.RenewedFromProgram__c != undefined && result.Program__r.TypeOfRenew__c == 'LTA/TR Identical Renew'){
               this.checkDisableQuoteTypeForRenewProg(result.Treaty__c);
           }

       })
       .catch(error => {
           this.error = error;
           this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error'}), );
       });
       checkIfQuoteRequestPresent({ programId : this.selectedRowSectionCopy.Program__c, selectedSectionId : this.selectedRowSectionCopy.Id})
       .then(result => {
           this.disableQRtype = result;
            this.QRtypeTitle = this.label.QRTypeHelpText;
       })
       .catch(error => {
           this.error = error;
           this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error'}), );
       });

       this.selectedTreatyId = this.selectedRowSectionCopy.Treaty__c;
       this.typeOfTreaty = this.selectedRowSectionCopy.TECH_TypeofTreaty__c;
       this.ProgramName = this.selectedRowSectionCopy.Program__r.Name;
       this.TreatyName = this.selectedRowSectionCopy.Treaty__r.Name;
       this.SectionName = this.selectedRowSectionCopy.Name;
       this.sectionNumber = this.selectedRowSectionCopy.SectionNumber__c;
       this.Option = this.selectedRowSectionCopy.Option__c;
       this.selectedLOB = this.selectedRowSectionCopy.LoB__c;
       this.selectedSubLOB = this.selectedRowSectionCopy.SubLoB__c;
       this.ReinsuranceValue = this.selectedRowSectionCopy.NonTraditionalReinsuranceAndOrFinit__c;
       this.sectionId = this.selectedRowSectionCopy.Id;
       this.treatyId = this.selectedRowSectionCopy.Treaty__c;
       this.programId = this.selectedRowSectionCopy.Program__c;
       this.MethodDistribution = this.selectedRowSectionCopy.MethodOfDistributionOfThePremium__c;
       this.TypeOfReinstatement = this.selectedRowSectionCopy.Reinstatements__c;
       this.CurrencyValue = this.selectedRowSectionCopy.Currency__c;

       if(this.MethodDistribution == 'EPI prorata'){
           this.isMethodDistributionProrata = true;
       } else{
          this.isMethodDistributionProrata = false;
       }

       this.getCoveredCedingCompaniesByTreatyId(this.programId, this.treatyId);
       this.TotalEPIValue = this.selectedRowSectionCopy.TotalEPI__c;
       this.NatureValue = this.selectedRowSectionCopy.Nature__c;
       this.CommentsValue = this.selectedRowSectionCopy.Comments__c;
       this.refreshWiredPicklist();
       this.QuoteRequestTypeValue = this.selectedRowSectionCopy.QuoteType__c;
   }
   populateConditionalTypeOfTreaty(sectionRecord){
       this.LimitTypeValue = sectionRecord.LimitType__c;
       this.CurrencyValue = sectionRecord.Currency__c;
       this.UnlimitedValue = sectionRecord.Unlimited__c;
       this.typeOfTreaty = sectionRecord.TECH_TypeofTreaty__c;

       if(this.typeOfTreaty == '2'){
           this.isTypeOfTreatyXL = true;
           this.LimitValue = sectionRecord.Limit__c;
           this.DeductibleValue = sectionRecord.Deductible__c;
           this.AALValue = sectionRecord.AAL__c;
           this.AADValue = sectionRecord.AAD__c;
           this.TALValue = sectionRecord.TAL__c;
           this.ExpectedMDPValue = sectionRecord.ExpectedMDP__c;
           this.ExpectedDPValue = sectionRecord.ExpectedDP__c;
           this.ExpectedMPValue = sectionRecord.ExpectedMP__c;

           if(isNaN(this.ExpectedMDPValue) == true && (isNaN(this.ExpectedDPValue) == false || isNaN(this.ExpectedMPValue) == false)){
               this.disableMDP = true;
           }
           else if(isNaN(this.ExpectedMDPValue) == false && (isNaN(this.ExpectedDPValue) == true || isNaN(this.ExpectedMPValue) == true)){
               this.disableDPandMP = true;
           }

           getReinstatements({ selectedSectionId : sectionRecord.Id})
           .then(result => {
               this.dataReinstatements = [];
               for (var i = 0; i < result.length; i++) {
                   var newReinstatement = {};
                   var order = result[i].Order__c;
                   var percentage = result[i].Percentage__c;
                   var freeVal = result[i].Free__c;
                   newReinstatement['Order'] = order.toString();

                   if(result[i].Percentage__c != undefined){
                        newReinstatement['Percentage'] = percentage.toString();
                   }else{
                       newReinstatement['Percentage'] = ' ';
                   }

                   newReinstatement['Prorata'] = result[i].Prorata__c;
                   newReinstatement['Free'] = result[i].Free__c;
                   if(freeVal == true){
                       newReinstatement['FreeValue'] = 'Yes';
                   }else{
                       newReinstatement['FreeValue'] = 'No';
                   }
                   this.allDataReinstatements.push(newReinstatement);
               }

               if(result.length > 0){
                   if(result[0].Type__c != undefined){
                       this.TypeOfReinstatement = this.mapReinstatementType.get(result[0].Type__c);
                       if(result[0].Type__c == 'Others'){
                           this.isNewReinstatementDisable = false;
                           this.dataReinstatements = this.allDataReinstatements;
                           this.titleReinstatement = 'Reinstatements ('+ this.dataReinstatements.length +')';
                       }
                       else{
                           this.isNewReinstatementDisable = true;
                           this.dataReinstatements = [];
                           this.allDataReinstatements = [];
                           this.titleReinstatement = 'Reinstatements ('+ this.dataReinstatements.length +')';
                       }
                   }
               }
               else if(this.TypeOfReinstatement == '3'){
                   this.isNewReinstatementDisable = false;
               }

               let lstUpdtData = [];
               for(let i = 0; i < this.dataReinstatements.length; i++){
                let rowData = { ...this.dataReinstatements[i]};
                lstUpdtData.push(rowData);
               }
               this.dataReinstatements = lstUpdtData;


               if(this.isSectionCopy == true){
                this.TypeOfReinstatement = null;
                this.TypeOfReinstatement = this.selectedRowSectionCopy.Reinstatements__c;
               }
           })
           .catch(error => {
               this.error = error;
               this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error'}), );
           });
       }
       else if(this.typeOfTreaty == '3'|| this.typeOfTreaty == '5'){/*1966*/
           this.isTypeOfTreatyQS = (this.typeOfTreaty == '3') ? true : false;
           this.isTypeOfTreatyAXAXLQS = (this.typeOfTreaty == '5') ? true : false;
           this.CessionPercValue = (this.typeOfTreaty == '3') ? sectionRecord.Cession_Perc__c : (this.typeOfTreaty == '5') ? 100 : 0;
           this.RetentionPercValue = sectionRecord.Retention__c;
           
           this.CededPremiumValue = parseFloat(this.CessionPercValue)/100 * parseFloat(this.TotalEPIValue);  // RRA - 852

            console.log("Total EPI == ", this.TotalEPIValue);
            console.log("CededPremium__c == ", sectionRecord.CededPremium__c);
            console.log("CededPremium__c2 == ",  this.CededPremiumValue);
            console.log("CessionPercValue == ", this.CessionPercValue);

           //this.CededPremiumValue = sectionRecord.CededPremium__c;

           if(this.isSectionEdit == true){
               this.CapacityPerRiskValue = this.additionalSectionDetail.CapacityPerRisk__c;
               this.EvenLimitValue = this.additionalSectionDetail.EventLimit__c;
               this.CessionAmountValue = this.additionalSectionDetail.CessionAmount__c;
               this.RetensionAmountValue = this.additionalSectionDetail.RetentionAmount__c;
           }
           else{
               this.CapacityPerRiskValue = sectionRecord.CapacityPerRisk__c;
               this.EvenLimitValue = sectionRecord.EventLimit__c;
               this.CessionAmountValue = sectionRecord.CessionAmount__c;
               this.RetensionAmountValue = sectionRecord.RetentionAmount__c;
           }
       }
       else if(this.typeOfTreaty == '4'){
           this.isTypeOfTreatySurplus = true;
           this.LineAmountValue = sectionRecord.LineAmount__c;
           if(this.isSectionEdit == true){
               this.EvenLimitValue = this.additionalSectionDetail.EventLimit__c;
               this.CededLineValue = this.additionalSectionDetail.CededLines__c;
               this.RetentionLineValue = this.additionalSectionDetail.RetentionLine__c;
               this.CessionAmountValue = this.additionalSectionDetail.CessionAmount__c;
               this.RetensionAmountValue = this.additionalSectionDetail.RetentionAmount__c;
               this.CapacityValue = this.additionalSectionDetail.Capacity__c;
           } else{
               this.EvenLimitValue = sectionRecord.EventLimit__c;
               this.CededLineValue = sectionRecord.CededLines__c;
               this.RetentionLineValue = sectionRecord.RetentionLine__c;
               this.CessionAmountValue = sectionRecord.CessionAmount__c;
               this.RetensionAmountValue = sectionRecord.RetentionAmount__c;
               this.CapacityValue = sectionRecord.Capacity__c;
           }
       }
       else if(this.typeOfTreaty == '1'){
           this.isTypeOfTreatyStopLoss = true;
           this.LimitValue = sectionRecord.LimitPercent__c;
           this.DeductibleValue = sectionRecord.DeductiblePercent__c;
           this.TALValue = sectionRecord.TAL__c;
           this.ExpectedMDPValue = sectionRecord.ExpectedMDP__c;
           this.ExpectedDPValue = sectionRecord.ExpectedDP__c;
           this.ExpectedMPValue = sectionRecord.ExpectedMP__c;
           if(isNaN(this.ExpectedMDPValue) == true && (isNaN(this.ExpectedDPValue) == false || isNaN(this.ExpectedMPValue) == false)){
            this.disableMDP = true;
            }
            else if(isNaN(this.ExpectedMDPValue) == false && (isNaN(this.ExpectedDPValue) == true || isNaN(this.ExpectedMPValue) == true)){
                this.disableDPandMP = true;
            }

           if(this.isSectionEdit == true){
               this.MaxLimitAmountValue = this.additionalSectionDetail.MaxLimitAmount__c;
               this.MinLimitAmountValue = this.additionalSectionDetail.MinLimitAmount__c;
           }else{
               this.MaxLimitAmountValue = sectionRecord.MaxLimitAmount__c;
               this.MinLimitAmountValue = sectionRecord.MinLimitAmount__c;
           }
       }
   }
   populateInclusionExclusionInfo(techNatureProgram){
       if (techNatureProgram == '23002'){
           this.isTechNatureProgramLife = true;
           this.isExclusion = this.selectedRowSectionCopy.ExclusionOfCatastrophicGuarantees__c;

           if(this.isExclusion == '1'){
               this.ExclusionValue = true;
               this.ExWarValue = this.selectedRowSectionCopy.Excl_War__c;
               this.ExNuclearRisksValue = this.selectedRowSectionCopy.Excl_NuclearRisks__c;
               this.ExTerrorismValue = this.selectedRowSectionCopy.Excl_Terrorism__c;
               this.ExBiologicalValue = this.selectedRowSectionCopy.Excl_Biological__c;
               this.ExNuclearBiologicalChemicalValue = this.selectedRowSectionCopy.Excl_NuclearBiological__c;
               this.ExOthersValue = this.selectedRowSectionCopy.Excl_Others__c;
               this.ExEpidemicPandemicValue = this.selectedRowSectionCopy.Excl_Epidemic__c;
               this.ExAllValue = this.selectedRowSectionCopy.Excl_All__c;
           }else {
              this.ExclusionValue = false;
           }
       }else if(techNatureProgram == '23001'){
           this.isTechNatureProgramLife = false;
           this.isInclusion = this.selectedRowSectionCopy.InclusionOfCatastrophicGuarantees__c;

           if(this.isInclusion == '1'){
               this.InclusionValue = true;
               this.InEarthquakeValue = this.selectedRowSectionCopy.Incl_Earthquake__c;
               this.InTerrorismValue = this.selectedRowSectionCopy.Incl_Terrorism__c;
               this.InFloodValue = this.selectedRowSectionCopy.Incl_Flood__c;
               this.InSRCCValue = this.selectedRowSectionCopy.Incl_SRCC__c;
               this.InHurricaneValue = this.selectedRowSectionCopy.Incl_Hurricane__c;
               this.InOthersValue = this.selectedRowSectionCopy.Incl_Others__c;
               this.InOtherRisksValue = this.selectedRowSectionCopy.Incl_OtherRisks__c;
               this.InAllValue = this.selectedRowSectionCopy.Incl_All__c;
           }else {
               this.InclusionValue = false;
           }
       }
   }
   populateCreatePageSectionInfo(){
       if(this.sObjectName == 'Treaty__c'){
           getTreatyDetails({ selectedTreatyId : this.recordId})
           .then(result => {
               this.covCed = [];
               this.ProgramName = result.TECH_ProgramName__c;
               this.TreatyName = result.Name;
               this.treatyId = result.Id;
               this.programId = result.Program__c;
               this.uwYearOpenModal = result.Program__r.UwYear__c;
               this.compOpenModal = result.Program__r.PrincipalCedingCompany__c;
               this.typeOfTreaty = result.TypeofTreaty__c;
               this.techNatureProgram = result.TECH_ProgramNature__c
               this.TotalEPI__c = result.TotalEPI__c;
               this.isPooled = result.IsPooled__c;
               if(result.Program__r.LTA__c == '1'){
                   this.showTAL = true;
               }
               if(this.isPooled == '1'){
                   this.PooledValue = true;
               }else{
                   this.PooledValue = false;
               }
               if (this.techNatureProgram == '23002'){
                   this.isTechNatureProgramLife = true;
               }else if(this.techNatureProgram == '23001'){
                   this.isTechNatureProgramLife = false;
               }
               if(this.typeOfTreaty == '2'){
                   this.isTypeOfTreatyXL = true;
               }else if(this.typeOfTreaty == '3'){
                   this.isTypeOfTreatyQS = true;
               }else if(this.typeOfTreaty == '4'){
                   this.isTypeOfTreatySurplus = true;
               }else if(this.typeOfTreaty == '1'){
                   this.isTypeOfTreatyStopLoss = true;
               }else if(this.typeOfTreaty == '5'){this.isTypeOfTreatyAXAXLQS = true;this.CessionPercValue = 100/*1966*/
               }
               this.getCoveredCedingCompaniesByTreatyId(this.programId, this.treatyId);
           })
           .catch(error => {
               this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error'}), );
           });
       }
       else if(this.sObjectName == 'Section__c'){
           this.sectionId = this.recordId;
           getSectionDetails({ selectedSectionId : this.recordId})
           .then(result => {
               this.Renewed = result.TECH_RenewedSection_ID__c;
               this.sectionTotalEPIValue = result.TotalEPI__c;
               this.selectedRowSectionCopy = result;
               this.treatyId = result.Treaty__c;
               this.programId = result.Program__c;
               this.RelatedSection = result.SectionNumber__c;
               this.ProgramName = result.TECH_ProgramName__c;
               this.TreatyName = result.TECH_TreatyName__c;
               this.uwYearOpenModal = result.Program__r.UwYear__c;
               this.compOpenModal = result.Program__r.PrincipalCedingCompany__c;
               this.typeOfTreaty = result.TECH_TypeofTreaty__c;
               this.techNatureProgram = result.TECH_NatureProgram__c;
               this.TotalEPIValue = result.TotalEPI__c;
               this.MethodDistribution = result.MethodOfDistributionOfThePremium__c;

               if(result.Program__r.LTA__c == '1'){
                   this.showTAL = true;
               }
               if (this.MethodDistribution == 'EPI prorata'){
                   this.isMethodDistributionProrata = true;
               } else{
                  this.isMethodDistributionProrata = false;
               }

               if (this.techNatureProgram == '23002'){
                   this.isTechNatureProgramLife = true;
               }else if(this.techNatureProgram == '23001'){
                   this.isTechNatureProgramLife = false;
               }
               if(this.typeOfTreaty == '2'){
                   this.isTypeOfTreatyXL = true;
               } else if(this.typeOfTreaty == '3'){
                   this.isTypeOfTreatyQS = true;
               } else if(this.typeOfTreaty == '4'){
                   this.isTypeOfTreatySurplus = true;
               } else if(this.typeOfTreaty == '1'){
                   this.isTypeOfTreatyStopLoss = true;
               }else if(this.typeOfTreaty == '5'){this.isTypeOfTreatyAXAXLQS = true;this.CessionPercValue = 100/*1966*/
               }
               this.Option = '1';
               this.selectedSectId = this.sectionId;
               this.sectNumber = result.SectionNumber__c;
               this.getCovCedCompBySectionId(this.sectionId);
           })
           .catch(error => {
               this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error'}), );
           });
       }
   }
   populateLobSubLobPicklistValues(techNatureProgram, data){
       let LOBOptions = [];
       let controlNatureLOBValues = data.picklistFieldValues.LoB__c.controllerValues;
       let totalDependentNatureLOBValues = data.picklistFieldValues.LoB__c.values;
       totalDependentNatureLOBValues.forEach(key => {
           if(key.validFor[0] === controlNatureLOBValues[techNatureProgram]){
               LOBOptions.push({label : key.label, value : key.value})
           }
       })
       this.controllingLOBValues = LOBOptions;

       let subLOBOptions = [];
       let dependValues = [];
       this.controlSubLOBValues = data.picklistFieldValues.SubLoB__c.controllerValues;
       this.totalDependentSubLOBValues = data.picklistFieldValues.SubLoB__c.values;
       this.totalDependentSubLOBValues.forEach(key => {subLOBOptions.push({label : key.label, value: key.value})});
       this.dependentSubLOBValues = subLOBOptions;

       if(this.isSectionCopy == true){
           this.mapLOb = new Map();
           for(var i = 0; i < totalDependentNatureLOBValues.length; i++){
               this.mapLOb.set(totalDependentNatureLOBValues[i].label, totalDependentNatureLOBValues[i].value);
           }
           this.selectedLOB = this.mapLOb.get(this.selectedLOB);
           this.mapSubLOb = new Map();
           this.totalDependentSubLOBValues.forEach(LOBValues => {
               if(LOBValues.validFor[0] === this.controlSubLOBValues[this.selectedLOB]) {
                   this.mapSubLOb.set(LOBValues.label, LOBValues.value);
                   dependValues.push({ label: LOBValues.label, value: LOBValues.value})
               }
           })
           this.dependentSubLOBValues = dependValues;
           this.selectedSubLOB = this.mapSubLOb.get(this.selectedSubLOB);
       }
   }
   populateQuoteTypePicklistValues(TypeOfTreaty, data){
       let quoteTypeOptions = [];
       this.controlQuoteTypeValues = data.controllerValues;
       this.totalDependentQuoteTypeValue = data.values;
       this.totalDependentQuoteTypeValue.forEach(key => {
           for(var i = 0; i < key.validFor.length; i++ ){
               if(key.validFor[i] === this.controlQuoteTypeValues[TypeOfTreaty]){
                   quoteTypeOptions.push({label : key.label, value : key.value })
                   return;
               }
           }
       })
       this.QuoteRequestTypeOpt = quoteTypeOptions;
   }
   getCoveredCedingCompaniesByTreatyId(programId, treatyId){
       getCoveredCedingCompaniesByTreatyId({ selectedProgramId : programId, selectedTreatyId : treatyId})
       .then(result => {
           var dataResult = result;
           var newData = [];
           var selectAllCovCedComId = [];
           for (var i = 0; i < dataResult.length; i++) {
               var row = {};
               row['Id'] = dataResult[i].Id;
               row['AccountName'] = dataResult[i].Account__r.Name;
               row['AccountId'] = dataResult[i].Account__r.Id;
               row['EPI'] = 0;
               row['AllocationKey'] = (100 / dataResult.length).toFixed(6);
               row['Checked'] = true;
               newData.push(row);
               selectAllCovCedComId.push(dataResult[i].Id);
           }
           this.dataCedingCompanyFixedKeys = newData;
           var newDataProrata = [];

           for (var i = 0; i < dataResult.length; i++) {
               var row = {};
               row['Id'] = dataResult[i].Id;
               row['AccountName'] = dataResult[i].Account__r.Name;
               row['AccountId'] = dataResult[i].Account__r.Id;
               row['EPI'] = 0;
               row['Checked'] = true;
               if (this.TotalEPIValue == 0){
                   row['AllocationKeyFloat'] = 100 / dataResult.length;
               }else{
                   row['AllocationKeyFloat'] = 0;
               }
               newDataProrata.push(row);
           }

           this.dataCedingCompanyProrata = newDataProrata;
           this.titleCoveredCedingCompaniesProrata = this.label.CoveredCedingCompanies + ' (' + this.dataCedingCompanyProrata.length + ')';
           this.titleCoveredCedingCompaniesFixedKeys = this.label.CoveredCedingCompanies + ' (' + this.dataCedingCompanyFixedKeys.length + ')';

           if(this.isSectionEdit == true || this.isSectionCopy == true){
               this.getCovCedCompBySectionId(this.selectedRowSectionCopy.Id);
           }
           this.error = undefined;
       })
       .catch(error => {
           this.dataCedingCompanyProrata = undefined;
           this.dataCedingCompanyFixedKeys = undefined;
           this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error'}), );
       });
   }
   getCovCedCompBySectionId(sectionId){
       getCovCedCompBySectionId({ selectedSectionId : sectionId})
       .then(result => {
           this.isRowSelectionProrata = true;
           this.isRowSelectionFixed = true;
           let dataProrata = [];
           let selectAllCovCedComIdProrata = [];
           let totalEPIProrata = 0;

           for (let i = 0; i < this.dataCedingCompanyProrata.length; i++){
               let covCedComFound = false;
               for (let j = 0; j < result.length; j++) {
                   if(covCedComFound == false){
                       if(this.dataCedingCompanyProrata[i].AccountId == result[j].Account__r.Id){
                           let row1 = {};
                           row1['Id'] = result[j].Id;
                           row1['AccountName'] = result[j].Account__r.Name;
                           row1['AccountId'] = result[j].Account__r.Id;
                           row1['EPI'] = parseFloat(result[j].EPI__c);
                           row1['AllocationKeyFloat'] = parseFloat(result[j].AllocationKey__c);
                           row1['Checked'] = true;
                           selectAllCovCedComIdProrata.push(result[j].Id);
                           totalEPIProrata = totalEPIProrata + parseFloat(result[j].EPI__c);
                           dataProrata.push(row1);
                           covCedComFound = true;
                       }
                   }
               }

               if(covCedComFound == false){
                   let row2 = {};
                   row2['Id'] = this.dataCedingCompanyProrata[i].Id;
                   row2['AccountName'] = this.dataCedingCompanyProrata[i].AccountName;
                   row2['AccountId'] = this.dataCedingCompanyProrata[i].AccountId;
                   row2['EPI'] = parseFloat(this.dataCedingCompanyProrata[i].EPI);
                   row2['AllocationKeyFloat'] = 0;
                   row2['Checked'] = false;
                   dataProrata.push(row2);
               }
           }

           let dataFixedKeys = [];
           let selectAllCovCedComIdFixedKeys = [];

         for (let i = 0; i < this.dataCedingCompanyFixedKeys.length; i++){
              let covCedComFound = false;
              for (let j = 0; j < result.length; j++) {
                  if(covCedComFound == false){
                      if(this.dataCedingCompanyFixedKeys[i].AccountId == result[j].Account__r.Id){
                          let row1 = {};
                          row1['Id'] = result[j].Id;
                          row1['AccountName'] = result[j].Account__r.Name;
                          row1['AccountId'] = result[j].Account__r.Id;
                          row1['EPI'] = parseFloat(result[j].EPI__c);
                          row1['AllocationKey'] = parseFloat(result[j].AllocationKey__c).toFixed(6);
                          row1['Checked'] = true;
                          selectAllCovCedComIdFixedKeys.push(result[j].Id);
                          dataFixedKeys.push(row1);
                          covCedComFound = true;
                      }
                  }
              }

              if(covCedComFound == false){
                  let row = {};
                  row['Id'] = this.dataCedingCompanyFixedKeys[i].Id;
                  row['AccountName'] = this.dataCedingCompanyFixedKeys[i].AccountName;
                  row['AccountId'] = this.dataCedingCompanyFixedKeys[i].AccountId;
                  row['EPI'] = parseFloat(this.dataCedingCompanyFixedKeys[i].EPI);
                  row['AllocationKey'] = 0;
                  row['Checked'] = false;
                  dataFixedKeys.push(row);
              }
          }
          this.dataCedingCompanyFixedKeys = dataFixedKeys;
          this.dataCedingCompanyProrata = dataProrata;
          this.titleCoveredCedingCompaniesProrata = this.label.CoveredCedingCompanies + ' (' + this.dataCedingCompanyProrata.length + ')';
          this.titleCoveredCedingCompaniesFixedKeys = this.label.CoveredCedingCompanies + ' (' + this.dataCedingCompanyFixedKeys.length + ')';
       })
       .catch(error => {
           this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error'}), );
       });
   }
   getPoolsDetail(){
       getPoolsTreatyDetails({treatyId: this.selectedTreatyId})
       .then(result => {
           this.titlePool = 'Pools (' +result.length + ')';
           let lstUpdPool = [];
           let totalSectionEpiSharedCededValue = 0;
           let totalSectionEpiCededToPoolValue = 0;
           let totalTreatyShareRateValue = 0;
           let totalPoolShareTreaty = 0;

           for(let i = 0; i < result.length; i++){
               let treatyShareRate = result[i].TreatyShareRate__c;
               totalPoolShareTreaty += treatyShareRate;
               this.totalPoolShareFromTreatyLevel = totalPoolShareTreaty;
           }

           for(let i = 0; i < result.length; i++){
               let rowTreatyPoolShare = { ...result[i] };
               let sectionEpiSharedCededValue = (result[i].TreatyShareRate__c / totalPoolShareTreaty) * 100;
               totalSectionEpiSharedCededValue += sectionEpiSharedCededValue;
               let treatyShareRateValue = result[i].TreatyShareRate__c;
               totalTreatyShareRateValue += treatyShareRateValue;
               let sectionEpiCededToPoolValue = (sectionEpiSharedCededValue / 100) * this.TotalEPIValue;
               totalSectionEpiCededToPoolValue += sectionEpiCededToPoolValue;

               rowTreatyPoolShare['PoolShare'] = totalPoolShareTreaty.toFixed(6).replace('.',',');
               rowTreatyPoolShare['TreatyShareRate__c'] = result[i].TreatyShareRate__c.toFixed(6).replace('.',',');
               rowTreatyPoolShare['SectionEpiSharedCeded__c'] = sectionEpiSharedCededValue.toFixed(6).replace('.',',');
               rowTreatyPoolShare['SectionEpiCededToPool__c'] = this.addMillSeparator(Math.round(sectionEpiCededToPoolValue));
               rowTreatyPoolShare['Name'] = result[i].Pool__r.Name;
               rowTreatyPoolShare['Checked'] = true;
               rowTreatyPoolShare['disableSubLob'] = false;
               rowTreatyPoolShare['showPicklist'] = true;
               rowTreatyPoolShare['SubLoB__c'] = null;
               rowTreatyPoolShare['displayTreaty'] = true;
               lstUpdPool.push(rowTreatyPoolShare);
           }

           totalSectionEpiSharedCededValue = totalSectionEpiSharedCededValue.toFixed(6).replace('.',',');
           totalSectionEpiCededToPoolValue = Math.round(totalSectionEpiCededToPoolValue);
           totalTreatyShareRateValue = totalTreatyShareRateValue.toFixed(6).replace('.',',');

           if(this.isSectionEdit == true || this.isSectionCopy == true || this.isSectionNewOption == true){
               getPoolsSectionDetails({ sectionId : this.selectedRowSectionCopy.Id})
               .then(result => {
                   let lstPoolsSection = result;
                   let lstUpdPoolsSection = [];
                   let matchFound = false;
                   let totalSelectedPoolShareTreaty = 0;let totalSectionEpiSharedCededValue = 0;let totalSectionEpiCededToPoolValue = 0;

                   for(let i = 0; i < lstPoolsSection.length; i++){
                       for(let j = 0; j < lstUpdPool.length; j++){
                           if(lstPoolsSection[i].Pool__c == lstUpdPool[j].Pool__c){
                               let treatyShareRate = parseFloat(lstUpdPool[j].TreatyShareRate__c.replace(',','.'));
                               totalSelectedPoolShareTreaty += treatyShareRate;
                           }
                       }
                   }

                   for(let j = 0; j < lstUpdPool.length; j++){
                       let rowTreatyPool = { ...lstUpdPool[j] };
                       for(let i = 0; i < lstPoolsSection.length; i++){
                           if(lstPoolsSection[i].Pool__c == lstUpdPool[j].Pool__c){
                               let sectionEpiSharedCededValue = ((parseFloat(lstUpdPool[j].TreatyShareRate__c.replace(',','.'))) / totalSelectedPoolShareTreaty) * 100;
                               totalSectionEpiSharedCededValue += sectionEpiSharedCededValue;
                               let sectionEpiCededToPoolValue = (sectionEpiSharedCededValue / 100) * this.TotalEPIValue;
                               totalSectionEpiCededToPoolValue += sectionEpiCededToPoolValue;
                               matchFound = true;
                               rowTreatyPool['SubLoB__c'] = lstPoolsSection[i].SubLoB__c;
                               rowTreatyPool['PoolShare'] = totalPoolShareTreaty.toFixed(6).replace('.',',');
                               rowTreatyPool['SectionEpiSharedCeded__c'] = sectionEpiSharedCededValue.toFixed(6).replace('.',',');
                               rowTreatyPool['SectionEpiCededToPool__c'] = this.addMillSeparator(Math.round(sectionEpiCededToPoolValue));
                               rowTreatyPool['disableSubLob'] = false;
                           }
                       }
                       if(!matchFound){
                           if(lstPoolsSection.length !=0){
                            rowTreatyPool['Checked'] = (this.isSectionNewOption) ? true : false;
                           }else{
                            rowTreatyPool['Checked'] = true;
                           }

                           rowTreatyPool['disableSubLob'] = true;
                           rowTreatyPool['SubLoB__c'] = null;
                       }
                       lstUpdPoolsSection.push(rowTreatyPool);
                       matchFound = false;
                   }

                   lstUpdPool = lstUpdPoolsSection;
                   let rowTreatyTotalPoolShare = {};
                   rowTreatyTotalPoolShare['Name'] = 'Total';
                   rowTreatyTotalPoolShare['TreatyShareRate__c'] = parseFloat(totalSelectedPoolShareTreaty).toFixed(6).replace('.',',');
                   rowTreatyTotalPoolShare['SectionEpiSharedCeded__c'] = parseFloat(Math.round(totalSectionEpiSharedCededValue)).toFixed(6).replace('.',',');
                   rowTreatyTotalPoolShare['SectionEpiCededToPool__c'] = this.addMillSeparator(Math.round(totalSectionEpiCededToPoolValue));
                   rowTreatyTotalPoolShare['Checked'] = true;
                   rowTreatyTotalPoolShare['showPicklist'] = false;
                   lstUpdPool.push(rowTreatyTotalPoolShare);
                   this.lstPools = lstUpdPool;
                   this.recalculateRowValues();
               })
               .catch(error => {
                   this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error'}), );
               });
           }
           else{
               let rowTreatyTotalPoolShare = {};
               rowTreatyTotalPoolShare['Name'] = 'Total';
               rowTreatyTotalPoolShare['TreatyShareRate__c'] = totalTreatyShareRateValue;
               rowTreatyTotalPoolShare['SectionEpiSharedCeded__c'] = totalSectionEpiSharedCededValue;
               rowTreatyTotalPoolShare['SectionEpiCededToPool__c'] = this.addMillSeparator(totalSectionEpiCededToPoolValue);
               rowTreatyTotalPoolShare['Checked'] = true;
               rowTreatyTotalPoolShare['disableSubLob'] = false;
               rowTreatyTotalPoolShare['showPicklist'] = false;
               lstUpdPool.push(rowTreatyTotalPoolShare);
               this.lstPools = lstUpdPool;
           }
       })
       .catch(error => {
           this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error'}), );
           this.error = result.error;
       });
   }
   handleChangePoolCheckbox(event){
       let poolId = event.currentTarget.name;
       let poolCheckValue = event.currentTarget.checked;
       let lstUpdPool = [];

       for(let i = 0; i < this.lstPools.length; i++){
           let rowPool = { ...this.lstPools[i] };
           if(rowPool.Id == poolId){
               rowPool['Checked'] = poolCheckValue;
               if(poolCheckValue == true){
                   rowPool['disableSubLob'] = false;
               }
               else if(poolCheckValue == false){
                   rowPool['disableSubLob'] = true;
                   rowPool['SubLoB__c'] = null;
               }
           }
           lstUpdPool.push(rowPool);
       }
       this.lstPools = lstUpdPool;
       this.recalculateRowValues();
   }
   recalculateRowValues(){
          let lstUpdPool = [];
          let rowTotal = {...this.lstPools[this.lstPools.length-1]};
          let totalSectionEpiSharedCededValue = 0;
          let totalSectionEpiCededToPoolValue = 0;
          let totalTreatyShareRateValue = 0;
          let totalPoolShareTreaty = 0.0;

          for(let i = 0; i < this.lstPools.length; i++){
            if(this.lstPools[i]['Checked'] == true && this.lstPools[i]['Name'] != 'Total'){
                let treatyShareRate = parseFloat(this.lstPools[i].TreatyShareRate__c.replace(',','.'));
                totalPoolShareTreaty += treatyShareRate;
            }
        }
        for(let i = 0; i < this.lstPools.length; i++){
            let rowPool = { ...this.lstPools[i] };
            if(rowPool.Name != 'Total'){
                if(rowPool.Checked == true) {
                    let sectionEpiSharedCededValue = (parseFloat(rowPool['TreatyShareRate__c'].replace(',','.')) / totalPoolShareTreaty) * 100;
                    totalSectionEpiSharedCededValue += sectionEpiSharedCededValue;
                    let treatyShareRateValue = parseFloat(rowPool['TreatyShareRate__c'].replace(',','.'));
                    totalTreatyShareRateValue += treatyShareRateValue;
                    let sectionEpiCededToPoolValue = (sectionEpiSharedCededValue / 100) * this.TotalEPIValue;
                    totalSectionEpiCededToPoolValue += sectionEpiCededToPoolValue;
                    rowPool['PoolShare'] = this.totalPoolShareFromTreatyLevel.toFixed(6).replace('.',',');
                    rowPool['SectionEpiSharedCeded__c'] = sectionEpiSharedCededValue.toFixed(6).replace('.',',');
                    rowPool['SectionEpiCededToPool__c'] = this.addMillSeparator(Math.round(sectionEpiCededToPoolValue));
                }
                else{
                    rowPool['PoolShare'] = null;
                    rowPool['SectionEpiSharedCeded__c'] = null;
                    rowPool['SectionEpiCededToPool__c'] = null;
                }

                lstUpdPool.push(rowPool);
            }
        }
        rowTotal['SectionEpiSharedCeded__c'] = totalSectionEpiSharedCededValue.toFixed(6).replace('.',',');
        rowTotal['SectionEpiCededToPool__c'] = this.addMillSeparator(Math.round(totalSectionEpiCededToPoolValue));
        rowTotal['TreatyShareRate__c'] = totalTreatyShareRateValue.toFixed(6).replace('.',',');
        lstUpdPool.push(rowTotal);
        this.lstPools = lstUpdPool;
   }
   handleChangeSubLoBPool(event){
       let eventId = event.currentTarget.id;
       let poolId = eventId.split('-')[0];
       let poolSubLobValue = event.currentTarget.value;
       let lstUpdPool = [];

       for(let i = 0; i < this.lstPools.length; i++){
           let rowPool = { ...this.lstPools[i] };
           if(rowPool.Id == poolId){
               rowPool['SubLoB__c'] = poolSubLobValue;
           }
           lstUpdPool.push(rowPool);
       }
       this.lstPools = lstUpdPool;
   }
   calculateEPICededToPool(totalEPI){
       let lstUpdPool = [];
       for(let i = 0; i < this.lstPools.length; i++){
           let rowPool = { ...this.lstPools[i] };
           if(rowPool.Name != 'Total' && rowPool.Checked == true){
               let epiShareCededPool = rowPool.SectionEpiSharedCeded__c;
               epiShareCededPool = parseFloat(epiShareCededPool.replace(',', '.'));
               let epiCededPool = (epiShareCededPool / 100) * totalEPI;
               rowPool['SectionEpiCededToPool__c'] = this.addMillSeparator(Math.round(epiCededPool));
           }
           else{
               rowPool['SectionEpiCededToPool__c'] = this.addMillSeparator(Math.round(totalEPI));
           }
           lstUpdPool.push(rowPool);
       }
       this.lstPools = lstUpdPool;
   }
   handleChangeDeductible(event){
       this.DeductibleValue = event.target.value;
   }
    handleChangeLineAmount(event){
        this.LineAmountValue = parseFloat(event.currentTarget.value);
        this.CessionAmountValue = Math.round(parseFloat(this.LineAmountValue) * parseFloat(this.CededLineValue));
        this.RetensionAmountValue = Math.round(this.LineAmountValue * this.RetentionLineValue);
        this.CapacityValue = parseFloat(this.CessionAmountValue) + parseFloat(this.RetensionAmountValue);
    }
    calculateCession(event){
        this.CededLineValue = event.currentTarget.value;
        this.CessionAmountValue = Math.round(parseFloat(this.LineAmountValue) * parseFloat(this.CededLineValue));
        this.CapacityValue = parseFloat(this.CessionAmountValue) + parseFloat(this.RetensionAmountValue);
    }
    calculateRetention(event){
        this.RetentionLineValue = event.currentTarget.value;
        this.RetensionAmountValue = Math.round(this.LineAmountValue * this.RetentionLineValue);
        this.CapacityValue = parseFloat(this.CessionAmountValue) + parseFloat(this.RetensionAmountValue);
    }
    calculateCapacity(event){
        let amountName = event.currentTarget.name;
        if(amountName == 'CessionAmount'){
            this.CessionAmountValue = event.currentTarget.value;
        }else{
            this.RetensionAmountValue = event.currentTarget.value;
        }
        this.CapacityValue = parseFloat(this.CessionAmountValue) + parseFloat(this.RetensionAmountValue);
    }
    deselectCheckboxAll(event){
        let valueChecked = event.target.checked;
        if(valueChecked == true){
            let checkboxes = this.template.querySelectorAll('[data-id="InExAll"]')
            for(let i = 0; i < checkboxes.length; i++) {
                checkboxes[i].checked = false;
            }
            this.InAllValue = false;
        }
    }
    deselectAllCheckbox(event){
        let valueChecked = event.target.checked;
        if(valueChecked == true){
            let checkboxes = this.template.querySelectorAll('[data-id="InEx"]')
            for(let i = 0; i < checkboxes.length; i++) {
                checkboxes[i].checked = false;
            }
        }
    }
    handleProrataValueChange(event){
        let eventId = event.currentTarget.id;
        let covCedComId = eventId.split('-')[0];
        let fieldName = event.currentTarget.name;
        let lstUpdCovCedCom = [];
        let allocationKey = 0;
        let totalEPI = 0;
        let lengthOfSelectedProrata = 0;

        for(let i = 0; i < this.dataCedingCompanyProrata.length; i++){
            let row = { ...this.dataCedingCompanyProrata[i] };
            if(row.Id == covCedComId){
                if(fieldName == 'EPI'){
                    row['EPI'] = parseFloat(event.currentTarget.value);
                }else if(fieldName == 'CheckboxProrata'){
                    row['Checked'] = event.currentTarget.checked;
                }
            }
            if(row.Checked == true){
                totalEPI = totalEPI + parseFloat(row.EPI);
                lengthOfSelectedProrata = lengthOfSelectedProrata + 1;
            }
            lstUpdCovCedCom.push(row);
        }

        this.dataCedingCompanyProrata = lstUpdCovCedCom;
        this.TotalEPIValue = totalEPI;
        this.calculateEPICededToPool(totalEPI);

        if(this.isTypeOfTreatyStopLoss == true){
            this.MaxLimitAmountValue = Math.round( (this.LimitValue / 100) * totalEPI);
            this.MinLimitAmountValue = Math.round( (this.DeductibleValue / 100) * totalEPI);
        }

        if(this.CessionPercValue != undefined && this.TotalEPIValue != undefined){
            this.CededPremiumValue = parseFloat(this.CessionPercValue)/100 * parseFloat(this.TotalEPIValue);
        }

        let lstNewDataCedingCompany = [];
        for(let i = 0; i < this.dataCedingCompanyProrata.length; i++){
            let row = { ...this.dataCedingCompanyProrata[i] };
            allocationKey = 0;

            if(this.TotalEPIValue == 0 && lengthOfSelectedProrata > 0){
                if(row.Checked == true){
                    allocationKey = 100 / lengthOfSelectedProrata;
                }
            }
            else{
                if(row.Checked == true){
                    allocationKey = (parseFloat(this.dataCedingCompanyProrata[i].EPI) / this.TotalEPIValue) * 100;
                }
            }

            row['AllocationKeyFloat'] = allocationKey;
            lstNewDataCedingCompany.push(row);
        }

        this.dataCedingCompanyProrata = lstNewDataCedingCompany;
    }
    handleFixedValueChange(event){
        let eventId = event.currentTarget.id;
        let covCedComId = eventId.split('-')[0];
        let fieldName = event.currentTarget.name;
        let lstUpdCovCedCom = [];
        let totalAllocationKey = 0;
        let totalEPI = 0;
        let lengthOfSelectedFixed = 0;

        for(let i = 0; i < this.dataCedingCompanyFixedKeys.length; i++){
            let row = { ...this.dataCedingCompanyFixedKeys[i] };
            if(row.Id == covCedComId){
                if(fieldName == 'EPI'){
                    row['EPI'] = parseFloat(event.currentTarget.value);
                }
                else if(fieldName == 'AllocationKey'){
                    row['AllocationKey'] = parseFloat(event.currentTarget.value);
                }
                else if(fieldName == 'CheckboxFixed'){
                    row['Checked'] = event.currentTarget.checked;
                }
            }
            if(row.Checked == true){
                totalEPI = totalEPI + parseFloat(row.EPI);
                lengthOfSelectedFixed = lengthOfSelectedFixed + 1;
                totalAllocationKey = totalAllocationKey +  parseFloat(row.AllocationKey);
            }
            lstUpdCovCedCom.push(row);
        }

        this.dataCedingCompanyFixedKeys = lstUpdCovCedCom;
        this.TotalEPIValue = totalEPI;
        this.calculateEPICededToPool(totalEPI);
        totalAllocationKey = Math.round(totalAllocationKey);

        if(this.CessionPercValue != undefined && this.TotalEPIValue  != undefined){
            this.CededPremiumValue = parseFloat(this.CessionPercValue)/100 * parseFloat(this.TotalEPIValue);
        }
    }
    handleDisableDPandMD(event){
        if(isNaN(event.target.value) == false){
            this.disableDPandMP = true;
            this.disableMDP = false;
            this.template.querySelector('[data-id="ExpectedDP"]').value = '';
            this.template.querySelector('[data-id="ExpectedMP"]').value = '';
        }
        if(this.template.querySelector('[data-id="ExpectedMDP"]').value == ''){
            this.disableDPandMP = false;
        }
    }
    handleChangeMP(event){
        if(isNaN(event.target.value) == false){
            this.disableMDP = true;
            this.disableDPandMP = false;
            this.template.querySelector('[data-id="ExpectedMDP"]').value = '';
        }
        if(this.template.querySelector('[data-id="ExpectedDP"]').value == '' && event.target.value == ''){
            this.disableMDP = false;
        }
    }
    handleChangeDP(event){
        if(isNaN(event.target.value) == false){
            this.disableMDP = true;
            this.disableDPandMP = false;
            this.template.querySelector('[data-id="ExpectedMDP"]').value = '';
        }
        if(this.template.querySelector('[data-id="ExpectedMP"]').value == '' && event.target.value == ''){
            this.disableMDP = false;
        }
    }
    checkDisableQuoteTypeForRenewProg(selectedTreatyId){
        disableQuoteTypeForRenewProg({ treatyId : selectedTreatyId})
        .then(result => {
            this.disableQuoteTypeRenew = result;
        })
        .catch(error => {
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error'}), );
        });
    }
    getProgramDetails(pageType){
        getProgramDetails({ selectedProgramId : this.selectedRowSectionCopy.Program__c})
        .then(result => {
            if(pageType == 'copyOption'){
                if(result.LTA__c == '1'){
                    this.showTAL = true;
                }
                this.compOpenModal = result.PrincipalCedingCompany__c;
            }
            else{
                this.compOpenModal = result.PrincipalCedingCompany__c;
                this.uwYearOpenModal = result.UwYear__c;
                this.techNatureProgram = result.Nature__c;
                if(result.LTA__c == '1'){
                    this.showTAL = true;
                }
                this.populateInclusionExclusionInfo(this.techNatureProgram);
                if(this.wiredLob != null){
                    this.populateLobSubLobPicklistValues(this.techNatureProgram, this.wiredLob);
                }
            }
        })
        .catch(error => {
            this.error = error;
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error'}), );
        });
    }
    getSectionDetails(type){
        getSectionDetails({ selectedSectionId : this.recordId})
        .then(result => {
            this.sectionTotalEPIValue = result.TotalEPI__c;
            if(result.Program__r.LTA__c == '1'){
                this.showTAL = true;
            }
            if(type == 'populateLobSubLob'){
                this.techNatureProgram = result.TECH_NatureProgram__c;
                this.populateLobSubLobPicklistValues(this.techNatureProgram, this.wiredLob);
            }
            else if(type == 'populateQuoteType'){
                this.typeOfTreaty = result.TECH_TypeofTreaty__c;
                this.populateQuoteTypePicklistValues(this.typeOfTreaty, this.wiredPicklist);
            }
        })
        .catch(error => {
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error'}), );
        });
    }
    getTreatyDetails(type){
        getTreatyDetails({ selectedTreatyId : this.recordId})
        .then(result => {
            this.isPooled = result.IsPooled__c;
            if(this.isPooled == '1'){
                this.PooledValue = true;
            }else{
                this.PooledValue = false;
            }
            if(result.Program__r.LTA__c == '1'){
                this.showTAL = true;
            }
            if(type == 'populateQuoteType'){
                this.typeOfTreaty = result.TypeofTreaty__c;
                this.populateQuoteTypePicklistValues(this.typeOfTreaty, this.wiredPicklist);
                if(result.Program__r.LTA__c == '1'){
                    this.showTAL = true;
                }
            }
            else if(type == 'populateLobSubLob'){
                this.techNatureProgram = result.TECH_ProgramNature__c;
                this.populateLobSubLobPicklistValues(this.techNatureProgram, data);
            }
        })
        .catch(error => {
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error'}), );
        });
    }
    handleOnChangeLimit(event){
        let maxValue = (event.target.value / 100) * this.TotalEPIValue;
        this.LimitValue = event.target.value;
        this.MaxLimitAmountValue = Math.round(maxValue).toFixed(6);
    }
    handleOnChangeDeduc(event){
        let minValue = (event.target.value / 100) * this.TotalEPIValue;
        this.DeductibleValue = event.target.value;
        this.MinLimitAmountValue = Math.round(minValue).toFixed(6);
    }
    addMillSeparator(value) {
        return value.toString().replace(/\B(?=(\d{3})+(?!\d))/g, " ");
    }
    getAllSectionOption(){
        let selectedProgId = this.selectedRowSectionCopy.Program__c;
        getAllSectionOption({ programId : selectedProgId})
        .then(result => {
            this.lstAllSectionOptions = result.lstAllSectionOption;
            let isProgramRenewed = result.isProgramRenewed;

            if(isProgramRenewed == true && this.lstAllSectionOptions != undefined && this.lstAllSectionOptions.length > 0){
                this.disableAllSectionOptions = false;
            }
            else{
                this.disableAllSectionOptions = true;
            }
        })
        .catch(error => {
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error'}), );
        });
    }
    handleChangeRenew(event){
        this.Renewed = event.detail.value;
    }
}