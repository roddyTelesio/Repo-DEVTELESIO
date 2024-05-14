import {LightningElement, track, wire, api} from 'lwc';
import {refreshApex} from '@salesforce/apex';
import {registerListener, fireEvent} from 'c/pubSub';
import {NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import {getPicklistValues} from 'lightning/uiObjectInfoApi';
import {getObjectInfo } from 'lightning/uiObjectInfoApi';
import getLeadRequestDetails from '@salesforce/apex/LWC34_TreatyDetails.getLeadRequestDetails';
import CURRENCY_FIELD from '@salesforce/schema/Section__c.Currency__c';
import SECTION_OBJECT from '@salesforce/schema/Section__c';
 
export default class Lwc34TreatyDetails extends LightningElement {
    @api selectedTreatyId;
    @api selectedRequestId;
    @track lstTreatySectionRequests = [];
    @track mapReinstatement = [];
    @track lstAllRequestSection = [];
    isPhaseTypeLead = false;
    currencyOpt;
    error;
    treatyName = '';
    treatyLossDeposit = '';
    treatyPremiumDeposit = '';
    treatyDeduction = '';

    @wire(CurrentPageReference) pageRef;
    connectedCallback(){
        this.getLeadRequestDetails();
    }
    getLeadRequestDetails(){
        getLeadRequestDetails({requestId: this.selectedRequestId, treatyId: this.selectedTreatyId})
        .then(result => {
            if(result['lstAllLeadRequests'].length > 0){
                var treatyRequest = result['lstAllLeadRequests'][0]['Treaty__r'];
                this.treatyName = treatyRequest['Layer__c'] + ' - ' + treatyRequest['Name'];
                this.treatyPremiumDeposit = treatyRequest['PremiumDeposit__c'];
                this.treatyLossDeposit = treatyRequest['LossDeposit__c'];
                this.treatyDeduction = treatyRequest['Deductions_Perc__c'];
                this.isPhaseTypeLead = true;
            }
            var lstUpdatedTreatyRequests = [];
            for(var i = 0; i < result['lstAllLeadRequests'].length; i++){
                let rowSection = { ...result['lstAllLeadRequests'][i] };
                rowSection['ReinstatementStr'] = rowSection['Section__r']['TECH_Reinstatement__c'];
                rowSection = this.setTypeOfTreatyQuoteValue(rowSection);
                rowSection['Number'] = rowSection['Section__r']['SectionNumber__c']
                rowSection['SectionName'] = rowSection['Section__r']['SectionNumber__c'] + ' - ' + rowSection['Section__r']['Name'];
                lstUpdatedTreatyRequests.push(rowSection);
            }
            this.lstTreatySectionRequests = lstUpdatedTreatyRequests;
            this.sortData('Number', 'asc');
        })
        .catch(error => {
            this.error = error;
        });
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

        if(rowSection.OrUnlimited__c == true){
            rowSection['disableLossCarryingForward'] = true;
        }
        else{
            rowSection['disableLossCarryingForward'] = false;
        }

        if(rowSection.NoClaimBonusAmount__c == null || rowSection.NoClaimBonusAmount__c == '' || rowSection.NoClaimBonusAmount__c == undefined){
            rowSection['disableNoClaimBonusPerc'] = false;
        }
        else{
            rowSection['disableNoClaimBonusPerc'] = true;
        }

        if(rowSection.NoClaimBonus__c == null || rowSection.NoClaimBonus__c == '' || rowSection.NoClaimBonus__c == undefined){
            rowSection['disableNoClaimBonusAmount'] = false;
        }
        else{
            rowSection['disableNoClaimBonusAmount'] = true;
        }

        if((rowSection.DepoPremium__c == null || rowSection.DepoPremium__c == '' || rowSection.DepoPremium__c == undefined) && (rowSection.MinPremium__c == null || rowSection.MinPremium__c == '' || rowSection.MinPremium__c == undefined)){
            rowSection['disableMDP'] = false;
        }
        else{
            rowSection['disableMDP'] = false;
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
            else if((typeOfTreaty == '4' || typeOfTreaty == '2') && typeOfQuote == '1'){
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
        }

        return rowSection;
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

        if(rowSection.OrUnlimited__c == true){
            rowSection['disableLossCarryingForward'] = true;
        }
        else{
            rowSection['disableLossCarryingForward'] = false;
        }

        if(rowSection.NoClaimBonusAmount__c == null || rowSection.NoClaimBonusAmount__c == '' || rowSection.NoClaimBonusAmount__c == undefined){
            rowSection['disableNoClaimBonusPerc'] = false;
        }
        else{
            rowSection['disableNoClaimBonusPerc'] = true;
        }

        if(rowSection.NoClaimBonus__c == null || rowSection.NoClaimBonus__c == '' || rowSection.NoClaimBonus__c == undefined){
            rowSection['disableNoClaimBonusAmount'] = false;
        }
        else{
            rowSection['disableNoClaimBonusAmount'] = true;
        }

        if((rowSection.DepoPremium__c == null || rowSection.DepoPremium__c == '' || rowSection.DepoPremium__c == undefined) && (rowSection.MinPremium__c == null || rowSection.MinPremium__c == '' || rowSection.MinPremium__c == undefined)){
            rowSection['disableMDP'] = false;
        }
        else{
            rowSection['disableMDP'] = false;
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
        if(this.mapReinstatement[rowSection.Section__c] != undefined){
            let reinstatementstr = this.mapReinstatement[rowSection.Section__c];
            rowSection['ReinstatementStr'] = reinstatementstr;
        }

        if(this.isPhaseTypeLead == true){
            if(rowSection.OverridingCommission__c == null || rowSection.OverridingCommission__c == ''){
                rowSection['OverridingCommission__c'] = 0;
            }

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
            else if((typeOfTreaty == '4' || typeOfTreaty == '2') && typeOfQuote == '1'){
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
        }

        return rowSection;
    }

    
    @wire(getObjectInfo, { objectApiName: SECTION_OBJECT })
    objectInfo;
 
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
    

    handleCloseTreatyDetailsModal(){
        fireEvent(this.pageRef, 'closeTreatyDetailsModal');
    }
     // sort section by section number
    sortData(fieldName, sortDirection) {
        let sortResult = Object.assign([], this.lstTreatySectionRequests);
        this.lstTreatySectionRequests = sortResult.sort(function(a,b){
                                        if(a[fieldName] < b[fieldName])
                                            return sortDirection === 'asc' ? -1 : 1;
                                        else if(a[fieldName] > b[fieldName])
                                            return sortDirection === 'asc' ? 1 : -1;
                                        else{
                                            return 0;
                                        }
        })
    }
}