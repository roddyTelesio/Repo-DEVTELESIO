import {LightningElement, track, wire, api} from 'lwc';
import {refreshApex} from '@salesforce/apex';
import {registerListener, fireEvent} from 'c/pubSub';
import {NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import {getObjectInfo} from 'lightning/uiObjectInfoApi';
import {getPicklistValues, getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import getRequestDetails from '@salesforce/apex/LWC17_RespondOnBehalf.getRequestDetails';
import saveRequestRecord from '@salesforce/apex/LWC17_RespondOnBehalf.saveRequestRecord';
import disableLeadPlacementInfo from '@salesforce/apex/LWC17_RespondOnBehalf.disableLeadPlacementInfo';
import getPlacementRequestRecordTypeId from '@salesforce/apex/LWC17_RespondOnBehalf.getPlacementRequestRecordTypeId';

//import field
import SECTION_OBJECT from '@salesforce/schema/Section__c';
import REQUEST_OBJECT from '@salesforce/schema/Request__c';
import CURRENCY_FIELD from '@salesforce/schema/Section__c.Currency__c';
import REINSTATEMENT_FIELD from '@salesforce/schema/Section__c.Reinstatements__c';
import EPINATURE_FIELD from '@salesforce/schema/Section__c.Nature__c';
import QUOTE_FIELD from '@salesforce/schema/Request__c.Quote__c';
import REASONFORREFUSAL_FIELD from '@salesforce/schema/Request__c.ReasonRefusal__c';
import PLACEMENT_PARTICIPATION_FIELD from '@salesforce/schema/Request__c.PlacementParticipation__c';
import DecimalPlacesErrorMessage from '@salesforce/label/c.DecimalPlacesErrorMessage';
import NumberErrorMessage from '@salesforce/label/c.NumberErrorMessage';
import twoDpErrorMessage from '@salesforce/label/c.twoDpErrorMessage';
import maxHundredErrorMessage from '@salesforce/label/c.maxHundredErrorMessage';
import minHundredErrorMessage from '@salesforce/label/c.minHundredErrorMessage';
import maxThousandErrorMessage from '@salesforce/label/c.maxThousandErrorMessage';
import PCCInactive from '@salesforce/label/c.PCCInactive';
import BRInactive from '@salesforce/label/c.BRInactive';
import RespondOnBehalfSavedSuccessfully from '@salesforce/label/c.RespondOnBehalfSavedSuccessfully';
import FormEntriesInvalid from '@salesforce/label/c.FormEntriesInvalid';
import errorMsg from '@salesforce/label/c.errorMsg';

export default class LWC17_RespondOnBehalf extends NavigationMixin(LightningElement) {
    label = {
        DecimalPlacesErrorMessage,
        NumberErrorMessage,
        twoDpErrorMessage,
        maxHundredErrorMessage,
        minHundredErrorMessage,
        maxThousandErrorMessage,
        PCCInactive,
        BRInactive,
        RespondOnBehalfSavedSuccessfully,
        FormEntriesInvalid,
        errorMsg
    }

    @api selectedReinsurerId;
    @api selectedTreatyId;
    @api selectedBrokerId;
    @api selectedReinsurerStatus;
    @api selectedProgramId;
    @api selectedPrincipleCedingCom;
    @api selectedRequestId;
    @api selectedUWYear;
    @api selectedStatus;
    @api placementRecordTypeId;
    @track lstTreaties = [];
    @track lstSectionRequestByTreatyId = [];
    @track lstAllRequestSection = [];
    @track lstUpdatedValue = [];
    @track leaderTypeOpt = [];
    @track mapParentRequestByTreaty = [];
    @track lstParentLeadRequest = [];
    quoteDeadline;//RRA - ticket 1541 -04072023
    wiredRequestDetails;
    isTreatyIdMatch = false;
    currencyOpt;
    reinstatementOpt;
    natureOpt;
    quoteOpt;
    reasonForRefusalOpt;
    disableSaveBtn = false; //to disable the save button, set it true
    phaseType;
    isPhaseTypeLead = false;
    isPhaseTypeQuote = false;
    isPhaseTypePlacement = false;
    programNameValue;
    inceptionDateValue;
    expiryDateValue;
    placementParticipationOpt;
    phaseStatus;
    disableLeadPlacementInfo = false;
    isProgRenewedAndIdentical = false;
    displaySpinner = false;
    activeAcc = true;
    isChangedDateValidity = false; //RRA - ticket 1574 - 06102023

    //AMI 13/07/22: W-0949 Portal -Quote / Placement - Ajout d'un bouton "refuse all"
    //              Exposed properties to show refuse all modal
    showRefuseAll = false;
    
    @wire(getObjectInfo, { objectApiName: SECTION_OBJECT })
    objectInfo;

    @wire(getObjectInfo, { objectApiName: REQUEST_OBJECT })
    objectInfoRequest;

    @wire(CurrentPageReference) pageRef;
    connectedCallback(){
        registerListener('isChangedDate', this.getIsChangedDateValidity, this); //RRA - ticket 1574 - 06102023
        this.getRequestDetails();
    }

 
    @wire(getPicklistValues, { recordTypeId: '$objectInfoRequest.data.defaultRecordTypeId', fieldApiName: PLACEMENT_PARTICIPATION_FIELD})
    setPlacementParticipationPicklistOpt({error, data}) {
        if(data){
            this.placementParticipationOpt = data.values;
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

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: REINSTATEMENT_FIELD})
    setReinstatementPicklistOpt({error, data}) {
        if(data){
            this.reinstatementOpt = data.values;
        }
        else{
            this.error = error;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: EPINATURE_FIELD})
    setNaturePicklistOpt({error, data}) {
        if(data){
            this.natureOpt = data.values;
        }
        else{
            this.error = error;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfoRequest.data.defaultRecordTypeId', fieldApiName: QUOTE_FIELD})
    setQuotePicklistOpt({error, data}) {
        if(data){
            this.quoteOpt = data.values;
        }else{
            this.error = error;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$placementRecordTypeId', fieldApiName: REASONFORREFUSAL_FIELD})
    setReasonForRefusalPicklistOpt({error, data}) {
        if(data){
            this.reasonForRefusalOpt = data.values;
        }
        else{
            this.error = error;
        }
    }
    
    //RRA - ticket 1574 - 06102023
    getIsChangedDateValidity(val){
        this.isChangedDateValidity = val;
    }

    getRequestDetails(){
        getRequestDetails({requestId: this.selectedRequestId})
        .then(result => {
            let reinsName = result.reinsName ;//MRA W-0953 8/09/2022 
            let brokerName = result.brokerName!=null?result.brokerName:'' ;//MRA W-0953 8/09/2022 
            this.isProgRenewedAndIdentical = result.isProgRenewedAndIdentical;
            this.lstAllRequestSection = result.lstRequestAll;
            console.log('lstAllRequestSection == ', this.lstAllRequestSection);
            this.lstTreaties = this.getUniqueData(result.lstTreaties, 'value');
            let mapSectionReqByTreaty = result.mapSectionRequestByTreatyId;
            this.mapParentRequestByTreaty = result.mapParentRequestByTreatyId;
           
            let isActDeactProg = result.isActivatedDeactivatedProg;  //RRA - ticket 585 - 06032023
            
            //Program / Treaty / Section - RRA - ticket 585 - 06032023
            if (isActDeactProg){
                this.disableSaveBtn = true;
            }else {
                this.disableSaveBtn = false;
            }
            
            if(result.pccActive == false){
                this.dispatchEvent(new ShowToastEvent({title: 'Info',message: this.label.PCCInactive,variant: 'info'}),);
                this.activeAcc = false;
            }
            else{
                if(result.accActive == false){
                    this.dispatchEvent(new ShowToastEvent({title: 'Info',message: this.label.BRInactive,variant: 'info'}),);
                    this.activeAcc = false;
                }
            }

            this.lstParentLeadRequest = result.lstParentLeadRequest;

            let selectedRequestObj = result.selectedRequestDetail;

            if(result.lstRequestAll.length > 0){
                this.selectedProgramId = result.lstRequestAll[0].Program__c;
                let requestPhase = result.requestPhaseType;

                disableLeadPlacementInfo({programId : this.selectedProgramId})
                .then(result => {
                    if(requestPhase != '3'){
                        //Disable Lead and Placement Respond on Behalf if phase is not quote
                        this.disableLeadPlacementInfo = result;
                    }
                })
                .catch(error => {
                    this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error'}), );
                });
                this.selectedPrincipleCedingCom = result.lstRequestAll[0].Program__r.PrincipalCedingCompany__c;
                this.selectedUWYear = result.lstRequestAll[0].Program__r.UwYear__c;
                this.selectedStatus = result.lstRequestAll[0].Program__r.TECH_StageName__c;
            }else{
                let requestPhase = result.requestPhaseType;
                this.selectedProgramId = result.selectedRequestDetail.Program__c;
                this.selectedPrincipleCedingCom = result.selectedRequestDetail.Program__r.PrincipalCedingCompany__c;
                this.selectedUWYear = result.selectedRequestDetail.Program__r.UwYear__c;
                this.selectedStatus = result.selectedRequestDetail.Program__r.TECH_StageName__c;
                if(requestPhase != '3'){
                    this.disableLeadPlacementInfo = true;
                }
            }

            this.phaseType = result.requestPhaseType;
            if(this.phaseType == '4'){
                this.isPhaseTypeLead = true;
                this.isPhaseTypeQuote = false;
                this.isPhaseTypePlacement = false;
                this.phaseStatus = 'Lead';
            }
            else if(this.phaseType == '3'){
                this.isPhaseTypeQuote = true;
                this.isPhaseTypeLead = false;
                this.isPhaseTypePlacement = false;
                this.phaseStatus = 'Quote';
            }
            else if(this.phaseType == '5'){
                this.isPhaseTypePlacement = true;
                this.isPhaseTypeLead = false;
                this.isPhaseTypeQuote = false;
                this.phaseStatus = 'Placement';
            }

            let lstUpdReq = [];
            let numQuotePlacementReinStatusNotSetupTimeout = 0;

            for(let key in mapSectionReqByTreaty){
                for(let i = 0; i < this.lstTreaties.length; i++){
                    if(this.lstTreaties[i].value == key){
                        let lstSectionRequest = mapSectionReqByTreaty[key];
                        let lstUpdSectionsRequest = [];
                        let numReinsurerStatusNotSetupRemind = 0;
                        let doesLeadRequestSetupTimeout = false;
                            for(let j = 0; j < lstSectionRequest.length; j++){
                                let rowSection = { ...lstSectionRequest[j] };
                                if(this.isPhaseTypePlacement == true){
                                    let disablePriceStructureDetails = false;
                                    
                                    if(rowSection['ReinsurerStatus__c'] == 'Setup' || rowSection['ReinsurerStatus__c'] == 'Timeout'){
                                        disablePriceStructureDetails = true;
                                        rowSection['errorMsg'] = 'Price Structure Detail is not available because this ' +this.phaseStatus+ ' request is in status '+rowSection.ReinsurerStatus__c;
                                    }
                                    else{
                                        numReinsurerStatusNotSetupRemind = numReinsurerStatusNotSetupRemind + 1;
                                    }

                                    rowSection['disablePriceStructureDetails'] = false; //MBE 09/09
                                    //MRA W-0953 8/09/2022 Transversal - Nom du réassureur à ajouter sur la page de réponse réassureur/courtier et le respond on behalf :START
                                    if (brokerName !== '')
                                        rowSection['Name'] = rowSection['Section__r']['SectionNumber__c'] + ' - ' + rowSection['TECH_SectionName__c'] + ' - ' + brokerName;
                                    else
                                    rowSection['Name'] = rowSection['Section__r']['SectionNumber__c'] + ' - ' + rowSection['TECH_SectionName__c']; 
                                    //MRA W-0953 8/09/2022 Transversal - Nom du réassureur à ajouter sur la page de réponse réassureur/courtier et le respond on behalf: END                                   
                                    //SAU
                                    rowSection['SectionNumber'] =  rowSection['Section__r']['SectionNumber__c'];
                                    rowSection = this.setTypeOfTreatyQuoteValue(rowSection);
                                    lstUpdSectionsRequest.push(rowSection);
                                    lstUpdSectionsRequest = this.sortSections(lstUpdSectionsRequest, 'SectionNumber', 'asc');
                                }
                                else if(this.isPhaseTypePlacement == false){
                                    if(this.isPhaseTypeLead == true){
                                        if(rowSection['ReinsurerStatus__c'] == 'Setup' || rowSection['ReinsurerStatus__c'] == 'Timeout'){
                                            doesLeadRequestSetupTimeout = true; //must disable accept checkbox if request is setup or timeout
                                        }
                                    }
                                    if(this.isPhaseTypeQuote == true){
                                        let disablePriceStructureDetails = false;
                                        if(rowSection['ReinsurerStatus__c'] == 'Setup' || rowSection['ReinsurerStatus__c'] == 'Timeout'){
                                            disablePriceStructureDetails = true;
                                            rowSection['errorMsg'] = 'Price Structure Detail is not available because this ' +this.phaseStatus+ ' request is in status '+rowSection.ReinsurerStatus__c;
                                        }else if(rowSection['QuoteType__c'] === '2'){
                                            //AMI 15/06/22 W-0943
                                            //do not display psd when quote is "For Information"
                                            disablePriceStructureDetails = true;
                                            rowSection['errorMsg'] = 'Price Structure Detail is not available because this Quote request is a \"For information\" request';
                                        }
                                        else{
                                            numQuotePlacementReinStatusNotSetupTimeout = numQuotePlacementReinStatusNotSetupTimeout + 1;
                                            numReinsurerStatusNotSetupRemind = numReinsurerStatusNotSetupRemind + 1;
                                        }
                                        rowSection['disablePriceStructureDetails'] = disablePriceStructureDetails;
                                    }
                                    //MRA W-0953 8/09/2022 Transversal - Nom du réassureur à ajouter sur la page de réponse réassureur/courtier et le respond on behalf : START
                                    if (this.isPhaseTypeLead && brokerName !== '') {
                                        rowSection['Name'] = rowSection['Section__r']['SectionNumber__c'] + ' - ' + rowSection['TECH_SectionName__c'] + ' - ' +  brokerName;
                                    }
                                    else{
                                    if (rowSection['TECH_BrokerName__c'] !== undefined) 
                                        rowSection['Name'] = rowSection['Section__r']['SectionNumber__c'] + ' - ' + rowSection['TECH_SectionName__c'] + ' - ' +  rowSection['TECH_BrokerName__c'];
                                    else
                                    rowSection['Name'] = rowSection['Section__r']['SectionNumber__c'] + ' - ' + rowSection['TECH_SectionName__c'];
                                    }
                                    //MRA W-0953 8/09/2022 Transversal - Nom du réassureur à ajouter sur la page de réponse réassureur/courtier et le respond on behalf : END
                                    rowSection['SectionNumber'] =  rowSection['Section__r']['SectionNumber__c'];
                                    rowSection = this.setTypeOfTreatyQuoteValue(rowSection);
                                    lstUpdSectionsRequest.push(rowSection);
                                    lstUpdSectionsRequest = this.sortSections(lstUpdSectionsRequest, 'SectionNumber', 'asc');
                                }
                            }
                        let deductionPerc = lstSectionRequest[0].Treaty__r.Deductions_Perc__c;
                        if(this.isPhaseTypeQuote == true){
                            let rowTreaty = {};
                            if(lstSectionRequest.length > 0){
                                //SRA - ticket 928.

                                rowTreaty['PremiumDeposit__c'] =  (lstSectionRequest[0].Treaty__r.PremiumDeposit__c == 'No') ||  (lstSectionRequest[0].Treaty__r.PremiumDeposit__c == undefined) ? 'No' : 'Yes';
                                rowTreaty['Deductions_Perc__c'] =  (lstSectionRequest[0].Treaty__r.Deductions_Perc__c == undefined) ? '0.000000 %' : deductionPerc.toFixed(6) + ' %';
                                rowTreaty['LossDeposit__c'] = lstSectionRequest[0].Program__r.LossDeposit__c;
                                
                                 //RRA - ticket 1541 and 1574 - 12102023
                                this.quoteDeadline = (lstSectionRequest[0].QuoteDeadline__c != null || lstSectionRequest[0].QuoteDeadline__c !=undefined) ? lstSectionRequest[0].QuoteDeadline__c : null;
                            }
                            let treatyLayer = lstUpdSectionsRequest[0]['Treaty__r']['Layer__c'];
                            let newLabel = treatyLayer + ' - ' + this.lstTreaties[i]['label'];
                            this.lstTreaties[i]['label'] = newLabel;
                            console.log('lstUpdSectionsRequest quote== ',lstUpdSectionsRequest);
                            this.lstSectionRequestByTreatyId.push({value:lstUpdSectionsRequest, key:this.lstTreaties[i], parentRequest: 'parent1', treatyDetail : rowTreaty, treatyLayer : treatyLayer });
                            this.sortTreaties('treatyLayer', 'asc');
                        }
                        else if(this.isPhaseTypeLead == true){
                            let rowTreaty = {};
                            if(lstSectionRequest.length > 0){
                                //SRA - ticket 928 
                                rowTreaty['PremiumDeposit__c'] =  (lstSectionRequest[0].Treaty__r.PremiumDeposit__c == 'No') ||  (lstSectionRequest[0].Treaty__r.PremiumDeposit__c == undefined) ? 'No' : 'Yes';
                                rowTreaty['Deductions_Perc__c'] =  (lstSectionRequest[0].Treaty__r.Deductions_Perc__c == undefined) ? '0.000000 %' : deductionPerc.toFixed(6) + ' %';
                                rowTreaty['LossDeposit__c'] = lstSectionRequest[0].Program__r.LossDeposit__c;
                            }
                            if(this.mapParentRequestByTreaty[key] != undefined){
                                let rowParentRequest = { ...this.mapParentRequestByTreaty[key] };
                                if(numReinsurerStatusNotSetupRemind > 0){ //if greater than 0 , must display the request info for treaty level
                                     rowParentRequest['disableInfo'] = false;
                                }
                                else{
                                     rowParentRequest['disableInfo'] = true;
                                }
                                rowParentRequest['doesLeadRequestSetupTimeout'] = doesLeadRequestSetupTimeout;
                                let treatyLayer = lstUpdSectionsRequest[0]['Treaty__r']['Layer__c'];
                                let newLabel = treatyLayer + ' - ' + this.lstTreaties[i]['label'];
                                this.lstTreaties[i]['label'] = newLabel;
                                console.log('lstUpdSectionsRequest lead== ',lstUpdSectionsRequest);
                                this.lstSectionRequestByTreatyId.push({value:lstUpdSectionsRequest, key:this.lstTreaties[i], parentRequest: rowParentRequest, treatyDetail : rowTreaty, treatyLayer : treatyLayer});
                                this.sortTreaties('treatyLayer', 'asc');
                            }
                        }
                        else if(this.isPhaseTypePlacement == true){
                                let rowTreaty = {};
                                if(lstSectionRequest.length > 0){
                                    //SRA - ticket 928 
                                    rowTreaty['PremiumDeposit__c'] =  (lstSectionRequest[0].Treaty__r.PremiumDeposit__c == 'No') ||  (lstSectionRequest[0].Treaty__r.PremiumDeposit__c == undefined) ? 'No' : 'Yes';
                                    rowTreaty['Deductions_Perc__c'] =  (lstSectionRequest[0].Treaty__r.Deductions_Perc__c == undefined) ? '0.000000 %' : deductionPerc.toFixed(6) + ' %';
                                    rowTreaty['LossDeposit__c'] = lstSectionRequest[0].Program__r.LossDeposit__c;

                                    /*rowTreaty['Deductions_Perc__c'] = lstSectionRequest[0].Treaty__r.Deductions_Perc__c;
                                    rowTreaty['PremiumDeposit__c'] = lstSectionRequest[0].Treaty__r.PremiumDeposit__c;
                                    rowTreaty['LossDeposit__c'] = lstSectionRequest[0].Treaty__r.LossDeposit__c;*/
                                }
                                if(this.mapParentRequestByTreaty[key] != undefined){
                                    let placementRequest = { ...this.mapParentRequestByTreaty[key] };
                                    if(placementRequest.ReinsurerStatus__c == 'Setup' || placementRequest.ReinsurerStatus__c == 'Timeout'){
                                         placementRequest['disableInfo'] = true;
                                    }
                                    else{
                                        numQuotePlacementReinStatusNotSetupTimeout = numQuotePlacementReinStatusNotSetupTimeout + 1;
                                        placementRequest['disableInfo'] = false;
                                    }
    
                                    if(placementRequest.PlacementParticipation__c == '1'){
                                        placementRequest['writtenSharePlacementRequired'] = true;
                                        placementRequest['writtenSharePlacementDisable'] = false;
                                        placementRequest['reasonForRefusalDisable'] = true;
                                        placementRequest['reasonForRefusalRequired'] = false;
                                    }
                                    else if(placementRequest.PlacementParticipation__c == '2'){
                                        placementRequest['writtenSharePlacementRequired'] = false;
                                        placementRequest['writtenSharePlacementDisable'] = true;
                                        placementRequest['reasonForRefusalDisable'] = false;
                                        placementRequest['reasonForRefusalRequired'] = true;
                                    }
                                    else{
                                        placementRequest['writtenSharePlacementRequired'] = false;
                                        placementRequest['writtenSharePlacementDisable'] = true;
                                        placementRequest['reasonForRefusalDisable'] = true;
                                        placementRequest['reasonForRefusalRequired'] = false;
                                    }

                                    let reasonForRefusalParentId = 'ReasonForRefusal' + '-' + placementRequest.Id;
                                    let writtenShareParentId = 'WrittenShare' + '-' + placementRequest.Id;
                                    placementRequest['reasonForRefusalParentId'] = reasonForRefusalParentId;
                                    placementRequest['writtenShareParentId'] = writtenShareParentId;

                                    if(this.isProgRenewedAndIdentical == true){
                                        placementRequest['reasonForRefusalDisable'] = true;
                                        placementRequest['reasonForRefusalRequired'] = false;
                                    }
                                    let treatyLayer = lstUpdSectionsRequest[0]['Treaty__r']['Layer__c'];
                                    let newLabel = treatyLayer + ' - ' + this.lstTreaties[i]['label'];
                                    this.lstTreaties[i]['label'] = newLabel;
                                    this.lstSectionRequestByTreatyId.push({value:lstUpdSectionsRequest, key:this.lstTreaties[i], parentRequest: placementRequest, treatyDetail : rowTreaty, treatyLayer : treatyLayer});
                                    this.sortTreaties('treatyLayer', 'asc');
                            }
                        }
                    }
                }
            }

            //RRA - ticket 585 - 06032023
            if (isActDeactProg == false){
                if(this.isPhaseTypeQuote == true  || this.isPhaseTypePlacement == true){
                    if(numQuotePlacementReinStatusNotSetupTimeout > 0){
                        this.disableSaveBtn = false;
                    }
                    else{
                        this.disableSaveBtn = true;
                    }
                }
             }

            for(let i = 0; i < this.lstAllRequestSection.length; i++){
                let rowReqSection = { ...this.lstAllRequestSection[i] };
                rowReqSection['checkIfPercentbadInput'] = false;
                lstUpdReq.push(rowReqSection);
            }

            if(this.lstAllRequestSection.length > 0){
                if(this.lstAllRequestSection[0].Program__r != undefined){
                    //MRA W-0953 8/09/2022 Transversal - Nom du réassureur à ajouter sur la page de réponse réassureur/courtier et le respond on behalf : START
                    if (this.isPhaseTypeLead || this.isPhaseTypePlacement) {
                        this.programNameValue = this.lstAllRequestSection[0].Program__r.Name+ ' - ' + reinsName; 
                    }
                    else{
                        if(this.lstAllRequestSection[0].TECH_ReinsurerName__c !== undefined)
                            this.programNameValue = this.lstAllRequestSection[0].Program__r.Name+ ' - ' + this.lstAllRequestSection[0].TECH_ReinsurerName__c; 
                        else
                            this.programNameValue = this.lstAllRequestSection[0].Program__r.Name
                    }
                    //MRA W-0953 8/09/2022 Transversal - Nom du réassureur à ajouter sur la page de réponse réassureur/courtier et le respond on behalf : END

                    this.inceptionDateValue = this.lstAllRequestSection[0].Program__r.InceptionDate__c;
                    this.expiryDateValue = this.lstAllRequestSection[0].Program__r.Expirydate__c;

                    if(this.inceptionDateValue != undefined){
                        let incepDate = new Date(this.inceptionDateValue+'T00:00').getDate();
                        if(incepDate < 10){
                           incepDate = '0'+incepDate;
                        }

                        let incepMonth = new Date(this.inceptionDateValue+'T00:00').getMonth() + 1;
                        if(incepMonth < 10){
                           incepMonth = '0'+incepMonth;
                        }

                        this.inceptionDateValue = incepDate + '/' + incepMonth + '/' + new Date(this.inceptionDateValue+'T00:00').getFullYear();
                    }

                    if(this.expiryDateValue != undefined){
                        let expDate = new Date(this.expiryDateValue+'T00:00').getDate();

                        if(expDate < 10){
                           expDate = '0'+expDate;
                        }

                        let expMonth = new Date(this.expiryDateValue+'T00:00').getMonth() + 1;
                        if(expMonth < 10){
                           expMonth = '0'+expMonth;
                        }

                        this.expiryDateValue = expDate + '/' + expMonth + '/' + new Date(this.expiryDateValue+'T00:00').getFullYear();
                    }
                }
            }
            this.lstAllRequestSection = lstUpdReq;

            getPlacementRequestRecordTypeId({phase : this.phaseStatus})
                                            .then(result => {
                                                this.placementRecordTypeId = result;
                                            })
                                            .catch(error => {
                                                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error'}), );
                                            });
        })
        .catch(error => {
            this.error = error;
        });
    }

    getUniqueData(arr, comp) {
        const unique = arr.map(e => e[comp])
                          .map((e, i, final) => final.indexOf(e) === i && i)
                          .filter(e => arr[e]).map(e => arr[e]);
        return unique;
    }

    setTypeOfTreatyQuoteValue(rowSection){
        let typeOfTreaty;
        let typeOfQuote;
        let ltaProgram;

        if(rowSection.Quote__c == '1'){
            rowSection['isQuoteYes'] = true;
            rowSection['isQuoteNo'] = false;
            rowSection['ReasonRefusal__c'] = '';
        }
        else if(rowSection.Quote__c == '2'){
            rowSection['isQuoteYes'] = false;
            rowSection['isQuoteNo'] = true;
        }

        //disable fields when program is Identical Renewed
        if(rowSection.OrUnlimited__c == true || this.isProgRenewedAndIdentical == true){
            rowSection['disableLossCarryingForward'] = true;
            rowSection['LossCarryingForward__c'] = '';
        }
        else{
            rowSection['disableLossCarryingForward'] = false;
        }

        if(this.isProgRenewedAndIdentical == true){
            rowSection['disableNoClaimBonusPerc'] = true;
        }
        else if(rowSection.NoClaimBonusAmount__c == null || rowSection.NoClaimBonusAmount__c == '' || rowSection.NoClaimBonusAmount__c == undefined){
            rowSection['disableNoClaimBonusPerc'] = false;
        }
        else{
            rowSection['disableNoClaimBonusPerc'] = true;
        }

        if(this.isProgRenewedAndIdentical == true){
            rowSection['disableNoClaimBonusAmount'] = true;
        }
        else if(rowSection.NoClaimBonus__c == null || rowSection.NoClaimBonus__c == '' || rowSection.NoClaimBonus__c == undefined){
            rowSection['disableNoClaimBonusAmount'] = false;
        }
        else{
            rowSection['disableNoClaimBonusAmount'] = true;
        }

        if((rowSection.DepoPremium__c == null || rowSection.DepoPremium__c == '' || rowSection.DepoPremium__c == undefined) && (rowSection.MinPremium__c == null || rowSection.MinPremium__c == '' || rowSection.MinPremium__c == undefined)){
            rowSection['disableMDP'] = false;
        }
        else{
            rowSection['disableMDP'] = true;
        }

        if(rowSection.MDP__c == null || rowSection.MDP__c == '' || rowSection.MDP__c == undefined){
            rowSection['disableMinPremium'] = false;
            rowSection['disableDepoPremium'] = false;
        }
        else{
            rowSection['disableMinPremium'] = true;
            rowSection['disableDepoPremium'] = true;
        }

        if(rowSection.Treaty__r != undefined){
           typeOfTreaty = rowSection.Treaty__r.TypeofTreaty__c;
        }

        if(rowSection.Section__r != undefined){
            typeOfQuote = rowSection.Section__r.QuoteType__c;
        }

        if(rowSection.Section__r != undefined){
            ltaProgram = rowSection.Program__r.LTA__c;
        }

        if(typeOfTreaty == '3'){
            rowSection['isTreatyTypeQS'] = true;
            rowSection['isTreatyTypeAXAXLQS'] = false;
        }
        else if(typeOfTreaty == '5'){/*1966*/
            rowSection['isTreatyTypeAXAXLQS'] = true;
            rowSection['isTreatyTypeQS'] = false;
        }
        else if(typeOfTreaty == '4'){
            rowSection['isTreatyTypeSurplus'] = true;
        }
        else if(typeOfTreaty == '2'){
            rowSection['isTreatyTypeXL'] = true;
        }
        else if(typeOfTreaty == '1'){
            rowSection['isTreatyTypeSL'] = true;
        }
        if(typeOfQuote == '1'){
            rowSection['isQuoteTypeFixedRate'] = true;
        }
        else if(typeOfQuote == '2'){
            rowSection['isQuoteTypeVariableRate'] = true;
        }
        else if(typeOfQuote == '3'){
            rowSection['isQuoteTypeFlatPremium'] = true;
        }
        else if(typeOfQuote == '4'){
            rowSection['isQuoteTypeMDP'] = true;
        }
        else if(typeOfQuote == '5'){
            rowSection['isQuoteTypeFlatCommission'] = true;
        }
        else if(typeOfQuote == '6'){
            rowSection['isQuoteTypeVariableCommission'] = true;
        }
        else if(typeOfQuote == '7'){
            rowSection['isQuoteTypePerHead'] = true;
        }
        else if(typeOfQuote == '8'){
            rowSection['isQuoteTypePerHeadVariable'] = true;
        }
        else if(typeOfQuote == '9'){
            rowSection['isQuoteTypeRiskPremiumBasis'] = true;
        }
        else if(typeOfQuote == '10'){
            rowSection['isQuoteTypePerHeadPremium'] = true;
        }

        if(ltaProgram == '1'){
            rowSection['LTAProgramYes'] = true;
        }
        else{
            rowSection['LTAProgramYes'] = false;
        }

        if(this.isPhaseTypeLead == true){
            if(rowSection.OverridingCommission__c == null || rowSection.OverridingCommission__c == ''){
                rowSection['OverridingCommission__c'] = 0;
            }
            //QS + (FlatCommission or VariableCommission or RiskPremiumBasis)
            if(typeOfTreaty == '3' && (typeOfQuote == '5' || typeOfQuote == '6' || typeOfQuote == '9')){
                let totalEPI = 0;
                let cessionPerc = 0;
                if(rowSection.Section__r.TotalEPI__c != undefined){
                    totalEPI = rowSection.Section__r.TotalEPI__c;
                }
                if(rowSection.Section__r.Cession_Perc__c != undefined){
                    cessionPerc = rowSection.Section__r.Cession_Perc__c;
                }

                let cededPremiumValue = totalEPI * (cessionPerc / 100);
                rowSection['CededPremium__c'] = Math.round(cededPremiumValue);
            }

            //(QS or Surplus) + PerHead
            else if((typeOfTreaty == '3' || typeOfTreaty == '4') && typeOfQuote == '7'){
                let totalEPI = 0;
                if(rowSection.Section__r.TotalEPI__c != undefined){
                    totalEPI = rowSection.Section__r.TotalEPI__c;
                }
                let cededPremiumValue = totalEPI;
                rowSection['CededPremium__c'] = Math.round(cededPremiumValue);
            }

            //Surplus + (FlatCommission or VariableCommission or RiskPremiumBasis)
            else if(typeOfTreaty == '4' && (typeOfQuote == '5' || typeOfQuote == '6' || typeOfQuote == '9')){
                let totalEPI = 0;
                if(rowSection.Section__r.TotalEPI__c != undefined){
                    totalEPI = rowSection.Section__r.TotalEPI__c;
                }
                let cededPremiumValue = totalEPI;
                rowSection['CededPremium__c'] = Math.round(cededPremiumValue);
            }

            //(SL or XL) + FixedRate
            else if((typeOfTreaty == '1' || typeOfTreaty == '2') && typeOfQuote == '1'){
                let totalEPI = 0;
                let fixedRate = 0;
                if(rowSection.Section__r.TotalEPI__c != undefined){
                    totalEPI = rowSection.Section__r.TotalEPI__c;
                }
                if(rowSection.FixedRate__c != undefined){
                    fixedRate = rowSection.FixedRate__c;
                }

                let cededPremiumValue = totalEPI * (fixedRate / 100);
                rowSection['CededPremium__c'] = Math.round(cededPremiumValue);
            }

            //(SL or XL) + FlatPremium
            else if((typeOfTreaty == '1' || typeOfTreaty == '2') && typeOfQuote == '3'){
                let flatPremium = 0;
                if(rowSection.FlatPremium__c != undefined){
                    flatPremium = rowSection.FlatPremium__c;
                }
                let cededPremiumValue = flatPremium;
                rowSection['CededPremium__c'] = Math.round(cededPremiumValue);
            }

            //(SL or XL) + MDP
            else if((typeOfTreaty == '1' || typeOfTreaty == '2') && typeOfQuote == '4'){
                let MDP = 0;
                if(rowSection.MDP__c != undefined){
                    MDP = rowSection.MDP__c;
                }
                let cededPremiumValue = MDP;
                rowSection['CededPremium__c'] = Math.round(cededPremiumValue);
            }

            //(SL or XL) + VariableRate
            else if((typeOfTreaty == '1' || typeOfTreaty == '2') && typeOfQuote == '2'){
                let totalEPI = 0;
                let minRate = 0;
                if(rowSection.Section__r.TotalEPI__c != undefined){
                    totalEPI = rowSection.Section__r.TotalEPI__c;
                }
                if(rowSection.MinRate__c != undefined){
                    minRate = rowSection.MinRate__c;
                }
                let cededPremiumValue = totalEPI * (minRate / 100);
                rowSection['CededPremium__c'] = Math.round(cededPremiumValue);
            }

            //(SL or XL) + PerHeadPremium
            else if((typeOfTreaty == '1' || typeOfTreaty == '2') && typeOfQuote == '10'){
                let totalEPI = 0;
                let perHeadPremium = 0;
                if(rowSection.Section__r.TotalEPI__c != undefined){
                    totalEPI = rowSection.Section__r.TotalEPI__c;
                }
                if(rowSection.PerHeadPremium__c != undefined){
                    perHeadPremium = rowSection.PerHeadPremium__c;
                }
                let cededPremiumValue = totalEPI * perHeadPremium;
                rowSection['CededPremium__c'] = Math.round(cededPremiumValue);
            }

            //(SL or XL) + PerHeadVariable
            else if((typeOfTreaty == '1' || typeOfTreaty == '2') && typeOfQuote == '8'){
                let totalEPI = 0;
                let minPerHeadAmount = 0;
                if(rowSection.Section__r.TotalEPI__c != undefined){
                    totalEPI = rowSection.Section__r.TotalEPI__c;
                }
                if(rowSection.MinPerHeadAmount__c != undefined){
                    minPerHeadAmount = rowSection.MinPerHeadAmount__c;
                }
                let cededPremiumValue = totalEPI * minPerHeadAmount;
                rowSection['CededPremium__c'] = Math.round(cededPremiumValue);
            }
        }

        if(rowSection.Section__r != undefined){
            //Build list since Section__r cannot be retrieved in html
            rowSection['Section__r.Name'] = rowSection.Section__r.Name;
            rowSection['Section__r.Currency__c'] = rowSection.Section__r.Currency__c;
            rowSection['Section__r.CapacityPerRisk__c'] = rowSection.Section__r.CapacityPerRisk__c;
            rowSection['Section__r.Unlimited__c'] = rowSection.Section__r.Unlimited__c;
            rowSection['Section__r.EventLimit__c'] = rowSection.Section__r.EventLimit__c;
            rowSection['Section__r.Cession_Perc__c'] = rowSection.Section__r.Cession_Perc__c;
            rowSection['Section__r.Retention__c'] = rowSection.Section__r.Retention__c;
            rowSection['Section__r.CessionAmount__c'] = rowSection.Section__r.CessionAmount__c;
            rowSection['Section__r.RetentionAmount__c'] = rowSection.Section__r.RetentionAmount__c;
            rowSection['Section__r.TotalEPI__c'] = rowSection.Section__r.TotalEPI__c;
            rowSection['Section__r.Nature__c'] = rowSection.Section__r.Nature__c;
            rowSection['Section__r.LineAmount__c'] = rowSection.Section__r.LineAmount__c;
            rowSection['Section__r.CededLines__c'] = rowSection.Section__r.CededLines__c;
            rowSection['Section__r.RetentionLine__c'] = rowSection.Section__r.RetentionLine__c;
            rowSection['Section__r.Capacity__c'] = rowSection.Section__r.Capacity__c;
            rowSection['Section__r.Limit__c'] = rowSection.Section__r.Limit__c;
            rowSection['Section__r.Deductible__c'] = rowSection.Section__r.Deductible__c;
            rowSection['Section__r.AAD__c'] = rowSection.Section__r.AAD__c;
            rowSection['Section__r.AAL__c'] = rowSection.Section__r.AAL__c;
            rowSection['Section__r.TAL__c'] = rowSection.Section__r.TAL__c;
            rowSection['Section__r.ExpectedDP__c'] = rowSection.Section__r.ExpectedDP__c;
            rowSection['Section__r.ExpectedMDP__c'] = rowSection.Section__r.ExpectedMDP__c;
            rowSection['Section__r.ExpectedMP__c'] = rowSection.Section__r.ExpectedMP__c;
            rowSection['Section__r.LimitPercent__c'] = rowSection.Section__r.LimitPercent__c;
            rowSection['Section__r.DeductiblePercent__c'] = rowSection.Section__r.DeductiblePercent__c;
            rowSection['Section__r.Limit__c'] = rowSection.Section__r.Limit__c;
            rowSection['Section__r.Deductible__c'] = rowSection.Section__r.Deductible__c;
            rowSection['Section__r.MaxLimitAmount__c'] = rowSection.Section__r.MaxLimitAmount__c;
            rowSection['Section__r.MinLimitAmount__c'] = rowSection.Section__r.MinLimitAmount__c;
            rowSection['Section__r.EventLimit__c'] = rowSection.Section__r.EventLimit__c;
            rowSection['Section__r.Cession_Perc__c'] = rowSection.Section__r.Cession_Perc__c;

            if(rowSection.Section__r.Reinstatements__c != undefined){
                if(rowSection.Section__r.Reinstatements__c == '1'){
                    rowSection['ReinstatementStr'] = 'None';
                }
                else if(rowSection.Section__r.Reinstatements__c == '2'){
                    rowSection['ReinstatementStr'] = 'Free and Unlimited';
                }
                else if(rowSection.Section__r.Reinstatements__c == '3'){
                    //Other
                    if(rowSection.Section__r.TECH_Reinstatement__c != undefined){
                        rowSection['ReinstatementStr'] = rowSection.Section__r.TECH_Reinstatement__c;
                    }
                }
            }
        }

        return rowSection;
    }

    handleCloseModal(){//'+this.selectedTreatyId+ => replace by null' RRA ticket 585 - 14032023
        fireEvent(this.pageRef, 'refreshReq', 'refresh');
        let urlPage = '../n/TreatyPlacement?c__program=' +this.selectedProgramId+'-'+this.selectedUWYear+'-'+this.selectedPrincipleCedingCom+'-'+this.selectedStatus+'-null-'+this.selectedBrokerId+'-'+this.selectedReinsurerId+'-'+this.selectedReinsurerStatus;
 
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {url: urlPage, target: '_self'}
        });
    }

    handleSave(){
        let phaseTypeRequest = null;
        let mapDataInput = [];
        let mapParentRequestDataInput = [];
        let lstUpdParentLeadRequest = [];

        this.displaySpinner = true;
        const allValid = [...this.template.querySelectorAll('lightning-input, lightning-combobox, lightning-textarea')]
            .reduce((validSoFar, inputCmp) => {
                        inputCmp.reportValidity();
                        return validSoFar && inputCmp.checkValidity();
            }, true);
        if (allValid) {
            if(this.isPhaseTypeQuote == true){
                phaseTypeRequest = 'Quote';
                let inputs = this.template.querySelectorAll('lightning-input, lightning-combobox, lightning-textarea');

                for(let input of inputs){
                    if(input.id != ''){
                        let id = input.id.split("-")[0];
                        let nameId = id + '-' + input.name + '-' + input.type;
                        if (input.type == 'checkbox'){
                            console.log('input.name == ', input.name);
                            mapDataInput.push({key:nameId, value:input.checked}); //RRA - ticket 1574 - 15102023 => this code is commented because of update field is2DaysEmailReminderSet__c before inserting in the database
                        }
                        else{
                            mapDataInput.push({key:nameId, value:input.value});
                        }
                    }
                }
            }
            else if(this.isPhaseTypeLead == true){
                phaseTypeRequest = 'Lead';
                let inputs= this.template.querySelectorAll('lightning-input, lightning-combobox, lightning-textarea');

                for(let input of inputs){
                    if(input.id != '' && input.name != 'Type__c'){
                        let id = input.id.split("-")[0];
                        let nameId = id + '-' + input.name + '-' + input.type;

                        if(input.name == 'Accept__c'){
                            mapParentRequestDataInput.push({key:nameId, value:input.checked});
                        }
                        else if(input.name == 'WrittenShare__c'){
                            let writtenShareVal = parseFloat(input.value);
                            mapParentRequestDataInput.push({key:nameId, value:writtenShareVal});
                        }
                        else if(input.name == 'CommentsResponse__c'){
                            mapParentRequestDataInput.push({key:nameId, value:input.value});
                        }
                        else if(input.name == 'CommentsReinsurerBroker__c'){ //RRA 1095
                            mapParentRequestDataInput.push({key:nameId, value:input.value});
                        }
                        else if(input.type == 'checkbox'){
                            mapDataInput.push({key:nameId, value:input.checked});
                        }
                        else{
                            mapDataInput.push({key:nameId, value:input.value});
                        }
                    }
                }

                for(let i = 0; i < this.lstParentLeadRequest.length; i++){
                    let rowParentRequest = { ...this.lstParentLeadRequest[i] };
                    for(let j = 0; j < mapParentRequestDataInput.length; j++){
                        let parentRequestId = mapParentRequestDataInput[j].key.split('-')[0];
                        let dataInputName = mapParentRequestDataInput[j].key.split('-')[1];
                        let dataInputValue = mapParentRequestDataInput[j].value;

                        if(this.lstParentLeadRequest[i].Id == parentRequestId){
                            rowParentRequest[dataInputName] = dataInputValue;
                        }
                    }

                    lstUpdParentLeadRequest.push(rowParentRequest);
                }
            }

            else if(this.isPhaseTypePlacement == true){
                phaseTypeRequest = 'Placement';
                let inputs= this.template.querySelectorAll('lightning-input, lightning-combobox, lightning-textarea');
                let lstPlacementRequest = [];

                for(let input of inputs){
                    if((input.id != '') && (input.name == 'PlacementParticipation__c' || input.name == 'ReasonRefusal__cPlacement' || input.name == 'WrittenShare__cPlacement' || input.name == 'CommentsResponse__cPlacement' || input.name == 'CommentsReinsurerBroker__cPlacement')){ //RRA 1095
                        let id = input.id.split("-")[0];
                        let name;
                        let val;
                        if(input.name == 'PlacementParticipation__c'){
                            name = input.name;
                        }
                        else{
                            name = input.name.split("Placement")[0];
                        }

                        if(input.name == 'WrittenShare__cPlacement'){
                            val = parseFloat(input.value);
                        }
                        else{
                            val = input.value;
                        }

                        let nameId = id + '-' + name + '-' + input.type;

                        mapParentRequestDataInput.push({key:nameId, value:val});
                    }
                }

                for(let i = 0; i < this.lstSectionRequestByTreatyId.length; i++){
                    let placementRequest = { ...this.lstSectionRequestByTreatyId[i].parentRequest };

                    for(let j = 0; j < mapParentRequestDataInput.length; j++){
                        let placementRequestId = mapParentRequestDataInput[j].key.split('-')[0];
                        let dataInputName = mapParentRequestDataInput[j].key.split('-')[1];
                        let dataInputValue = mapParentRequestDataInput[j].value;

                        if(placementRequest.Id == placementRequestId){
                            placementRequest[dataInputName] = dataInputValue;
                        }
                    }

                    lstPlacementRequest.push(placementRequest);
                }

                lstUpdParentLeadRequest = lstPlacementRequest;
            }

            let lstUpdAllRequest = [];
            let dataNotValid = false;
            for(let i = 0; i < this.lstAllRequestSection.length; i++){
                let rowRequest = { ...this.lstAllRequestSection[i] };
                if(rowRequest.checkIfPercentbadInput == true){
                    //dataNotValid = true;
                }

                for(let j = 0; j < mapDataInput.length; j++){
                    let requestId = mapDataInput[j].key.split('-')[0];
                    let dataInputName = mapDataInput[j].key.split('-')[1];
                    let dataInputValue = mapDataInput[j].value;
                    let dataInputType = mapDataInput[j].key.split('-')[2];

                    if(this.lstAllRequestSection[i].Id == requestId){
                        if(dataInputType == 'number'){
                            rowRequest[dataInputName] =  parseFloat(dataInputValue);
                        }
                        else{
                            rowRequest[dataInputName] = dataInputValue;
                        }
                    }
                }

                lstUpdAllRequest.push(rowRequest);
            }

            console.log('selectedIdRequest = ',this.selectedRequestId);
            console.log('lstUpdAllRequest = ',lstUpdAllRequest);
            console.log('selectedTreatyId = ',this.selectedTreatyId);
            console.log('quoteDeadline = ',this.quoteDeadline);
            console.log('isChangedDateValidity = ',this.isChangedDateValidity);
            //RRA - ticket 1404 - 08022023 => update the original Request on Lead Request if writtenShare has changed
            saveRequestRecord({ lstRequest : lstUpdAllRequest, phaseType : phaseTypeRequest, lstParentRequest : lstUpdParentLeadRequest, selectIdRequest : this.selectedRequestId, quotedeadline : this.quoteDeadline, isChangedDateQuote : this.isChangedDateValidity})//RRA - ticket 1541 - 15072023 and //RRA - ticket 1574 - 06102023
            .then(result => {
                if(result.hasOwnProperty('Error') && result.Error){   
                    this.dispatchEvent(new ShowToastEvent({title: 'Error', message: result.Error, variant: 'error' }),);
                    this.displaySpinner = false;
                }
                else{
                    console.log('result saveRequestRecord= ',result);
                    this.dispatchEvent(new ShowToastEvent({title: 'Success', message: this.label.RespondOnBehalfSavedSuccessfully, variant: 'success' }),);
                   this.displaySpinner = false;
                    this.handleCloseModal();
                }
            })
            .catch(error => {
                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error'}), );
               this.displaySpinner = false;
            });
        }
        else{
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.FormEntriesInvalid, variant: 'error'}), );
           this.displaySpinner = false;
        }
    }

    handleOnChangeInputValue(event){
        let eventId = event.currentTarget.id;
        let requestId = eventId.split('-')[0];
        let value = event.currentTarget.value;
        let fieldName = event.currentTarget.name;
        let lstUpdSectionRequestByTreatyId = [];

        for(let i = 0; i < this.lstSectionRequestByTreatyId.length; i++){
            let lstUpdSectionsRequest = [];
            let lstSectionRequests = this.lstSectionRequestByTreatyId[i].value;
            let lstTreatyId = this.lstSectionRequestByTreatyId[i].key;
            let parentUpdRequest = this.lstSectionRequestByTreatyId[i].parentRequest;
            let rowTreatyDetail = this.lstSectionRequestByTreatyId[i].treatyDetail;

            for(let j = 0; j < lstSectionRequests.length; j++){
                let rowSectionRequest = { ...lstSectionRequests[j] };
                if(rowSectionRequest.Id == requestId){
                    if(fieldName == 'OrUnlimited__c'){
                        let orUnlimitedCheck = event.currentTarget.checked;

                        //disable fields when program is Identical Renewed
                        if(orUnlimitedCheck == true || this.isProgRenewedAndIdentical == true){
                            rowSectionRequest['disableLossCarryingForward'] = true;
                            rowSectionRequest['LossCarryingForward__c'] = '';

                            let inputs = this.template.querySelectorAll('[data-id='+requestId+']');
                            for(let i = 0; i < inputs.length; i++) {
                                inputs[i].value = '';
                            }
                        }
                        else{
                            rowSectionRequest['disableLossCarryingForward'] = false;
                        }
                    }
                    else if(fieldName == 'NoClaimBonusAmount__c'){
                        let noClaimBonusAmountValue = event.currentTarget.value;
                        if(this.isProgRenewedAndIdentical == true){
                           rowSectionRequest['disableNoClaimBonusPerc'] = true;
                        }
                        else if(noClaimBonusAmountValue == null || noClaimBonusAmountValue == ''){
                            rowSectionRequest['disableNoClaimBonusPerc'] = false;
                        }
                        else{
                            rowSectionRequest['disableNoClaimBonusPerc'] = true;
                        }
                    }
                    else if(fieldName == 'NoClaimBonus__c'){
                        let noClaimBonusValue = event.currentTarget.value;
                        if(this.isProgRenewedAndIdentical == true){
                            rowSection['disableNoClaimBonusAmount'] = true;
                        }
                        else if(noClaimBonusValue == null || noClaimBonusValue == ''){
                            rowSectionRequest['disableNoClaimBonusAmount'] = false;
                        }
                        else{
                            rowSectionRequest['disableNoClaimBonusAmount'] = true;
                        }
                    }
                    else if(fieldName == 'MDP__c'){
                        let MDPValue = event.currentTarget.value;
                        if(MDPValue == null || MDPValue == ''){
                            rowSectionRequest['disableMinPremium'] = false;
                            rowSectionRequest['disableDepoPremium'] = false;
                        }
                        else{
                            rowSectionRequest['disableMinPremium'] = true;
                            rowSectionRequest['disableDepoPremium'] = true;
                        }
                    }
                    //AMI 16/06/22 W:0738
                    //disable mdp when depo premium or min premium is entered
                    //enable mdp when depo premium and min premium is entered
                    else if(fieldName == 'DepoPremium__c' || fieldName == 'MinPremium__c'){
                        let depoPre;
                        let minPre;

                        this.template.querySelectorAll('lightning-input').forEach(ele => {             
                            if(ele.name === 'DepoPremium__c' && ele.id.split('-')[0] ===  requestId){
                                depoPre = ele.value;
                            }else if(ele.name === 'MinPremium__c' && ele.id.split('-')[0] ===  requestId){
                                minPre = ele.value;
                            }
                        });

                        if(!depoPre && !minPre){
                            rowSectionRequest['disableMDP'] = false;
                        }else{
                            rowSectionRequest['disableMDP'] = true;
                        }
                    }
                }

                lstUpdSectionsRequest.push(rowSectionRequest);
            }

            lstUpdSectionRequestByTreatyId.push({value:lstUpdSectionsRequest, key:lstTreatyId, parentRequest: parentUpdRequest, treatyDetail : rowTreatyDetail });
        }

        this.lstSectionRequestByTreatyId = lstUpdSectionRequestByTreatyId;
    }

    handleQuoteChange(event){
        let eventId = event.currentTarget.id;
        let requestId = eventId.split('-')[0];
        let quoteValue = event.currentTarget.value;
        let lstUpdSectionRequestByTreatyId = [];

        for(let i = 0; i < this.lstSectionRequestByTreatyId.length; i++){
            let lstUpdSectionsRequest = [];
            let lstSectionRequests = this.lstSectionRequestByTreatyId[i].value;
            let lstTreatyId = this.lstSectionRequestByTreatyId[i].key;
            let parentUpdRequest = this.lstSectionRequestByTreatyId[i].parentRequest;
            let rowTreatyDetail = this.lstSectionRequestByTreatyId[i].treatyDetail;

            for(let j = 0; j < lstSectionRequests.length; j++){
                let rowSectionRequest = { ...lstSectionRequests[j] };
                if(rowSectionRequest.Id == requestId){
                    if(quoteValue == '1'){
                        rowSectionRequest['isQuoteYes'] = true;
                        rowSectionRequest['isQuoteNo'] = false;
                        rowSectionRequest['ReasonRefusal__c'] = '';
                    }
                    else if(quoteValue == '2'){
                        rowSectionRequest['isQuoteYes'] = false;
                        rowSectionRequest['isQuoteNo'] = true;
                        rowSectionRequest['ReasonRefusal__c'] = rowSectionRequest.ReasonRefusal__c;
                    }
                }

                lstUpdSectionsRequest.push(rowSectionRequest);
            }

            lstUpdSectionRequestByTreatyId.push({value:lstUpdSectionsRequest, key:lstTreatyId, parentRequest: parentUpdRequest, treatyDetail : rowTreatyDetail });
        }

        this.lstSectionRequestByTreatyId = lstUpdSectionRequestByTreatyId;
    }

    handleChangeLeadRequest(event){
        let eventId = event.currentTarget.id;
        let requestId = eventId.split('-')[0];
        let value = event.currentTarget.value;
        let fieldName = event.currentTarget.name;
        let lstUpdSectionRequestByTreatyId = [];

        if(value == '' || value == null){
            value = 0;
        }

        for(let i = 0; i < this.lstSectionRequestByTreatyId.length; i++){
            let lstUpdSectionsRequest = [];
            let lstSectionRequests = this.lstSectionRequestByTreatyId[i].value;
            let lstTreatyId = this.lstSectionRequestByTreatyId[i].key;
            let parentUpdRequest = this.lstSectionRequestByTreatyId[i].parentRequest;
            let rowTreatyDetail = this.lstSectionRequestByTreatyId[i].treatyDetail;
            let totalEPI = 0;
            let expectedMDP = 0; //RRA - ticket 1745 - 09112023
            let expectedDP = 0; //RRA - ticket 1745 - 09112023
            let expectedMP = 0; //RRA - ticket 1745 - 09112023

            for(let j = 0; j < lstSectionRequests.length; j++){
                let rowSectionRequest = { ...lstSectionRequests[j] };
                if(rowSectionRequest.Id == requestId){
                    let typeOfTreaty = rowSectionRequest.Treaty__r.TypeofTreaty__c;
                    let typeOfQuote = rowSectionRequest.Section__r.QuoteType__c;

                    if(fieldName == 'FixedRate__c'){
                        if((typeOfTreaty == '1' || typeOfTreaty == '2') && typeOfQuote == '1'){
                            if(rowSectionRequest.Section__r.TotalEPI__c != undefined){
                                totalEPI = rowSectionRequest.Section__r.TotalEPI__c;
                            }
                            
                            //RRA - ticket 1745 - 09112023
                            if(rowSectionRequest.Section__r.ExpectedMDP__c != undefined){
                                expectedMDP = rowSectionRequest.Section__r.ExpectedMDP__c;
                            }
                            //RRA - ticket 1745 - 09112023
                            if(rowSectionRequest.Section__r.ExpectedDP__c != undefined){
                                expectedDP = rowSectionRequest.Section__r.ExpectedDP__c;
                            }
                            //RRA - ticket 1745 - 09112023
                            if(rowSectionRequest.Section__r.ExpectedMP__c != undefined){
                                expectedMP = rowSectionRequest.Section__r.ExpectedMP__c;
                            }
                            
                            console.log('totalEPI FixedRate__c==', totalEPI);
                            console.log('expectedMDP FixedRate__c==', expectedMDP);
                            console.log('expectedDP FixedRate__c==', expectedDP);
                            console.log('expectedMP FixedRate__c==', expectedMP);
                            
                            let cededPremiumValue = totalEPI * (value / 100);
                            let mdp = cededPremiumValue * (expectedMDP/100); //RRA - ticket 1745 - 09112023
                            let expDP = cededPremiumValue * (expectedDP/100); //RRA - ticket 1745 - 09112023
                            let expMP = cededPremiumValue * (expectedMP/100); //RRA - ticket 1745 - 09112023
                            
                            rowSectionRequest['CededPremium__c'] = Math.round(cededPremiumValue);
                            rowSectionRequest['MDP__c'] = Math.round(mdp/100)*100; //RRA - ticket 1745 - 09112023
                            rowSectionRequest['DepoPremium__c'] = Math.round(expDP/100)*100; //RRA - ticket 1745 - 09112023
                            rowSectionRequest['MinPremium__c'] = Math.round(expMP/100)*100; //RRA - ticket 1745 - 09112023
                        }
                    }
                    else if(fieldName == 'FlatPremium__c'){
                        if((typeOfTreaty == '1' || typeOfTreaty == '2') && typeOfQuote == '3'){
                            rowSectionRequest['CededPremium__c'] = Math.round(value);
                        }
                    }
                    else if(fieldName == 'MDP__c'){
                        if((typeOfTreaty == '1' || typeOfTreaty == '2') && typeOfQuote == '4'){
                            rowSectionRequest['CededPremium__c'] = Math.round(value);
                        }
                    }
                    else if(fieldName == 'MinRate__c'){
                        if((typeOfTreaty == '1' || typeOfTreaty == '2') && typeOfQuote == '2'){
                            let totalEPI = 0;
                            if(rowSectionRequest.Section__r.TotalEPI__c != undefined){
                                totalEPI = rowSectionRequest.Section__r.TotalEPI__c;
                            }
                            
                             //RRA - ticket 1745 - 09112023
                             if(rowSectionRequest.Section__r.ExpectedMDP__c != undefined){
                                expectedMDP = rowSectionRequest.Section__r.ExpectedMDP__c;
                            }
                            //RRA - ticket 1745 - 09112023
                            if(rowSectionRequest.Section__r.ExpectedDP__c != undefined){
                                expectedDP = rowSectionRequest.Section__r.ExpectedDP__c;
                            }
                            //RRA - ticket 1745 - 09112023
                            if(rowSectionRequest.Section__r.ExpectedMP__c != undefined){
                                expectedMP = rowSectionRequest.Section__r.ExpectedMP__c;
                            }
                            
                            console.log('totalEPI MinRate__c==', totalEPI);
                            console.log('expectedMDP MinRate__c==', expectedMDP);
                            console.log('expectedDP MinRate__c==', expectedDP);
                            console.log('expectedMP MinRate__c==', expectedMP);
                            
                            let cededPremiumValue = totalEPI * (value / 100);
                            let mdp = cededPremiumValue * (expectedMDP/100); //RRA - ticket 1745 - 09112023
                            let expDP = cededPremiumValue * (expectedDP/100); //RRA - ticket 1745 - 09112023
                            let expMP = cededPremiumValue * (expectedMP/100); //RRA - ticket 1745 - 09112023
                            
                            rowSectionRequest['CededPremium__c'] = Math.round(cededPremiumValue);
                            rowSectionRequest['MDP__c'] = Math.round(mdp/100)*100; //RRA - ticket 1745 - 09112023
                            rowSectionRequest['DepoPremium__c'] = Math.round(expDP/100)*100; //RRA - ticket 1745 - 09112023
                            rowSectionRequest['MinPremium__c'] = Math.round(expMP/100)*100; //RRA - ticket 1745 - 09112023
                        }
                    }
                    else if(fieldName == 'PerHeadPremium__c'){
                        if((typeOfTreaty == '1' || typeOfTreaty == '2') && typeOfQuote == '10'){
                            let totalEPI = 0;
                            if(rowSectionRequest.Section__r.TotalEPI__c != undefined){
                                totalEPI = rowSectionRequest.Section__r.TotalEPI__c;
                            }
                            
                            //RRA - ticket 1745 - 09112023
                            if(rowSectionRequest.Section__r.ExpectedMDP__c != undefined){
                                expectedMDP = rowSectionRequest.Section__r.ExpectedMDP__c;
                            }
                            //RRA - ticket 1745 - 09112023
                            if(rowSectionRequest.Section__r.ExpectedDP__c != undefined){
                                expectedDP = rowSectionRequest.Section__r.ExpectedDP__c;
                            }
                            //RRA - ticket 1745 - 09112023
                            if(rowSectionRequest.Section__r.ExpectedMP__c != undefined){
                                expectedMP = rowSectionRequest.Section__r.ExpectedMP__c;
                            }
                            
                            console.log('totalEPI PerHeadPremium__c==', totalEPI);
                            console.log('expectedMDP PerHeadPremium__c==', expectedMDP);
                            console.log('expectedDP PerHeadPremium__c==', expectedDP);
                            console.log('expectedMP PerHeadPremium__c==', expectedMP);
                            
                            let cededPremiumValue = totalEPI * value;
                            let mdp = cededPremiumValue * (expectedMDP/100); //RRA - ticket 1745 - 09112023
                            let expDP = cededPremiumValue * (expectedDP/100); //RRA - ticket 1745 - 09112023
                            let expMP = cededPremiumValue * (expectedMP/100); //RRA - ticket 1745 - 09112023
                            
                            rowSectionRequest['CededPremium__c'] = Math.round(cededPremiumValue);
                            rowSectionRequest['MDP__c'] = Math.round(mdp/100)*100; //RRA - ticket 1745 - 09112023
                            rowSectionRequest['DepoPremium__c'] = Math.round(expDP/100)*100; //RRA - ticket 1745 - 09112023
                            rowSectionRequest['MinPremium__c'] = Math.round(expMP/100)*100; //RRA - ticket 1745 - 09112023
                        }
                    }
                    else if(fieldName == 'MinPerHeadAmount__c'){
                        if((typeOfTreaty == '1' || typeOfTreaty == '2') && typeOfQuote == '8'){
                            let totalEPI = 0;
                            if(rowSectionRequest.Section__r.TotalEPI__c != undefined){
                                totalEPI = rowSectionRequest.Section__r.TotalEPI__c;
                            }
                            //RRA - ticket 1745 - 09112023
                            if(rowSectionRequest.Section__r.ExpectedMDP__c != undefined){
                                expectedMDP = rowSectionRequest.Section__r.ExpectedMDP__c;
                            }
                            //RRA - ticket 1745 - 09112023
                            if(rowSectionRequest.Section__r.ExpectedDP__c != undefined){
                                expectedDP = rowSectionRequest.Section__r.ExpectedDP__c;
                            }
                            //RRA - ticket 1745 - 09112023
                            if(rowSectionRequest.Section__r.ExpectedMP__c != undefined){
                                expectedMP = rowSectionRequest.Section__r.ExpectedMP__c;
                            }
                            
                            console.log('totalEPI MinPerHeadAmount__c==', totalEPI);
                            console.log('expectedMDP MinPerHeadAmount__c==', expectedMDP);
                            console.log('expectedDP MinPerHeadAmount__c==', expectedDP);
                            console.log('expectedMP MinPerHeadAmount__c==', expectedMP);
                            
                            let cededPremiumValue = totalEPI * value;
                            let mdp = cededPremiumValue * (expectedMDP/100); //RRA - ticket 1745 - 09112023
                            let expDP = cededPremiumValue * (expectedDP/100); //RRA - ticket 1745 - 09112023
                            let expMP = cededPremiumValue * (expectedMP/100); //RRA - ticket 1745 - 09112023

                            rowSectionRequest['CededPremium__c'] = Math.round(cededPremiumValue);
                            rowSectionRequest['MDP__c'] = Math.round(mdp/100)*100; //RRA - ticket 1745 - 09112023
                            rowSectionRequest['DepoPremium__c'] = Math.round(expDP/100)*100; //RRA - ticket 1745 - 09112023
                            rowSectionRequest['MinPremium__c'] = Math.round(expMP/100)*100; //RRA - ticket 1745 - 09112023
                        }
                    }
                }

                lstUpdSectionsRequest.push(rowSectionRequest);
            }

            lstUpdSectionRequestByTreatyId.push({value:lstUpdSectionsRequest, key:lstTreatyId, parentRequest: parentUpdRequest, treatyDetail : rowTreatyDetail });
        }

        this.lstSectionRequestByTreatyId = lstUpdSectionRequestByTreatyId;
        
    }

    handleChangePlacementRequest(event){
        let eventId = event.currentTarget.id;
        let requestId = eventId.split('-')[0];
        let value = event.currentTarget.value;
        let fieldName = event.currentTarget.name;
        let lstUpdSectionRequestByTreatyId = [];

        if(value == '' || value == null){
            value = null;
        }

        for(let i = 0; i < this.lstSectionRequestByTreatyId.length; i++){
            let lstUpdSectionsRequest = [];
            let lstSectionRequests = this.lstSectionRequestByTreatyId[i].value;
            let lstTreatyId = this.lstSectionRequestByTreatyId[i].key;
            let rowTreatyDetail = this.lstSectionRequestByTreatyId[i].treatyDetail;
            let placementRequest = { ...this.lstSectionRequestByTreatyId[i].parentRequest };
            if(placementRequest.Id == requestId){
                if(value == '1'){
                    placementRequest['writtenSharePlacementRequired'] = true;
                    placementRequest['writtenSharePlacementDisable'] = false;
                    placementRequest['reasonForRefusalDisable'] = true;
                    placementRequest['reasonForRefusalRequired'] = false;
                    placementRequest['PlacementParticipation__c'] = value;
                    placementRequest['ReasonRefusal__c'] = null;
                    //to set ReasonForRefusal to null in screen
                    let dataId = '[data-id=ReasonForRefusal-'+requestId+']';

                    if(this.template.querySelector(dataId) != undefined){
                        this.template.querySelector(dataId).value = '';
                    }

                }
                else if(value == '2'){
                    placementRequest['writtenSharePlacementRequired'] = false;
                    placementRequest['writtenSharePlacementDisable'] = true;
                    placementRequest['reasonForRefusalDisable'] = false;
                    placementRequest['reasonForRefusalRequired'] = true;
                    placementRequest['PlacementParticipation__c'] = value;
                    placementRequest['WrittenShare__c'] = null;
                    //to set WrittenShare to null in screen
                    let dataId = '[data-id=WrittenShare-'+requestId+']';

                    if(this.template.querySelector(dataId) != undefined){
                        this.template.querySelector(dataId).value = '';
                    }
//                    this.disablePlacementShare = true;
                }

                if(this.isProgRenewedAndIdentical == true){
                    placementRequest['reasonForRefusalDisable'] = true;
                    placementRequest['reasonForRefusalRequired'] = false;
                }
            }

            lstUpdSectionRequestByTreatyId.push({value:lstSectionRequests, key:lstTreatyId, parentRequest: placementRequest, treatyDetail : rowTreatyDetail });
        }

        this.lstSectionRequestByTreatyId = lstUpdSectionRequestByTreatyId;
    }

    sortTreaties(fieldName, sortDirection) {
        let sortResult = Object.assign([], this.lstSectionRequestByTreatyId);
        this.lstSectionRequestByTreatyId = sortResult.sort(function(a,b){
            if(a[fieldName] < b[fieldName])
                return sortDirection === 'asc' ? -1 : 1;
            else if(a[fieldName] > b[fieldName])
                return sortDirection === 'asc' ? 1 : -1;
            else{
                return 0;
            }
        })
    }
    sortSections(lstData, fieldName, sortDirection) {
        let sortResult = Object.assign([], lstData);
        lstData = sortResult.sort(function(a,b){
            if(a[fieldName] < b[fieldName])
                return sortDirection === 'asc' ? -1 : 1;
            else if(a[fieldName] > b[fieldName])
                return sortDirection === 'asc' ? 1 : -1;
            else{
                return 0;
            }
        })
        return lstData;
    }

    //AMI 13/07/22: W-0949 Portal -Quote / Placement - Ajout d'un bouton "refuse all"
    //              getter to determine when to show refuse all modal
    get showRefuseAllModal(){
        return (this.phaseStatus === 'Quote' || this.phaseStatus === 'Placement');
    }

    //AMI 13/07/22: W-0949 Portal -Quote / Placement - Ajout d'un bouton "refuse all"
    //              handler to show refuse all modal
    showRefuseAllHandler(){
        //set property to true to render refuse all template
        this.showRefuseAll = true;
    }

    //AMI 13/07/22: W-0949 Portal -Quote / Placement - Ajout d'un bouton "refuse all"
    //              handler to close refuse all modal
    closeRefuseAllHandler(){
        //set property to true to render refuse all template
        this.showRefuseAll = false;
    }
    
    //RRA - ticket 1574 - 06102023
    handleChangeQuoteDeadline(event){
        this.selectedRequestId
        this.quoteDeadline = event.detail.value;
        fireEvent(this.pageRef, 'isChangedDate', true);
    }
}