import getSigningDetails from '@salesforce/apex/LWC30_SigningRequests.getSigningDetails';
export class lwc30MainMethod {
    detailsSigning (idProgram, idTreaty, idReinsurer, idBroker, reinsurerStatus, isClosePreviousBtnClick, lossDepositModeOpt){
        this.spinnerSigningRequest = true;
        this.isSetupRequest = false ; //MRA 14/07/2022 : W-0940
    //AMI 01/06/22: W-0940
        if(idProgram != null){
            getSigningDetails({programId:idProgram, treatyId: idTreaty, reinsurerId: idReinsurer, brokerId: idBroker, reinsurerStatus: reinsurerStatus, isClosePreviousBtnClick : isClosePreviousBtnClick, lossDepositModeOpt : lossDepositModeOpt})
            .then(result => {
                console.log('result s== ', result);
                //this.closePreviousBtnClick = false;
                let profileName = result.userProfile;
                this.displayTwoFieldForPremium = result.displayTwoFieldForPremium;
                this.spinnerSigningRequest = true;
                let updDataSigningRequest = [];
                let updDataSigningRequestClosePrev = [];
                let dataSigningRequest = result.lstSigningRequest;
                let mapIdReqReq = new Map();
                let mapTECH_RelatedLeadPlacementRequestReq = new Map();
                let mapIdTreatyReq = new Map();
                let isDeactivatedProg = result.isDeactivatedProg;  //RRA - ticket 585 - 13032023
                console.log('closePreviousBtnClick == ', this.closePreviousBtnClick);
                console.log('dataSigningRequestClosePreviousPhase == ', this.dataSigningRequestClosePreviousPhase);
                console.log('result.lstSigningRequest == ', result.lstSigningRequest);
                console.log('dataSigningRequest == ', dataSigningRequest);
                console.log('isDeactivatedProg == ', isDeactivatedProg);
                console.log('lossDepositModeOpt == ', lossDepositModeOpt);
                //RRA - ticket 585 - 07032023
                if (isDeactivatedProg){
                    this.disabledCloseButton = true;
                }else{
                    this.disabledCloseButton = false;
                }
                    if (this.closePreviousBtnClick){
                        if (this.dataSigningRequestClosePreviousPhase.length > 0 ){
                            for (let j=0;j<this.dataSigningRequestClosePreviousPhase.length;j++){
                                let rowClosePrev = {...this.dataSigningRequestClosePreviousPhase[j]}
                                mapIdReqReq.set(rowClosePrev.Id, rowClosePrev);
                                mapTECH_RelatedLeadPlacementRequestReq.set(rowClosePrev.TECH_RelatedLeadPlacementRequest__c + '_' + rowClosePrev.Treaty__c, rowClosePrev);
                                mapIdTreatyReq.set(rowClosePrev.Treaty__c, rowClosePrev);
                            }
                            for (let i=0;i<dataSigningRequest.length;i++){
                                let rowData = {...dataSigningRequest[i]};
                                //RRA - ticket 1414 - 31012023 - when values at Pool is changed
                                if (mapIdReqReq.has(rowData.Id)){
                                    rowData.SignedShare__c = mapIdReqReq.get(rowData.Id).SignedShare__c != null ? mapIdReqReq.get(rowData.Id).SignedShare__c : rowData.SignedShare__c;
                                    rowData.WrittenShare__c = mapIdReqReq.get(rowData.Id).WrittenShare__c !=null ? mapIdReqReq.get(rowData.Id).WrittenShare__c : rowData.WrittenShare__c;
                            //RRA - ticket 1404 - 08022023 - when values for same reinsurer attached on différent section / treaty
                                }else if (mapTECH_RelatedLeadPlacementRequestReq.has(rowData.TECH_RelatedLeadPlacementRequest__c + '_' + rowData.Treaty__c)){
                                    rowData.SignedShare__c = mapTECH_RelatedLeadPlacementRequestReq.get(rowData.TECH_RelatedLeadPlacementRequest__c + '_' + rowData.Treaty__c).SignedShare__c != null ? mapTECH_RelatedLeadPlacementRequestReq.get(rowData.TECH_RelatedLeadPlacementRequest__c + '_' + rowData.Treaty__c).SignedShare__c : rowData.SignedShare__c;
                                    rowData.WrittenShare__c = mapTECH_RelatedLeadPlacementRequestReq.get(rowData.TECH_RelatedLeadPlacementRequest__c + '_' + rowData.Treaty__c).WrittenShare__c != null ? mapTECH_RelatedLeadPlacementRequestReq.get(rowData.TECH_RelatedLeadPlacementRequest__c + '_' + rowData.Treaty__c).WrittenShare__c : rowData.WrittenShare__c;
                                }
                                updDataSigningRequestClosePrev.push(rowData);
                            }
                            console.log('updDataSigningRequestClosePrev == ', updDataSigningRequestClosePrev);
                            this.dataSigningRequest = updDataSigningRequestClosePrev
                            updateSigningReqClosePrevPhase({ lstReqClosePrevPhase : this.dataSigningRequest})
                            .then(result => {
                                console.log('update close prev sucessfully');
                            })
                            .catch(error => {
                                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.useLabel.errorMsg, variant: 'error'}), );
                                this.spinnerSigningRequest = false;
                            });
                        }else{
                            this.dataSigningRequest = dataSigningRequest; //RRA - 12052023 - Prod
                        }
                    }else{
                        this.dataSigningRequest = dataSigningRequest;
                    }
                //this.dataSigningRequest = this.closePreviousBtnClick == false ? result.lstSigningRequest : this.dataSigningRequestClosePreviousPhase;
                let lstFilteredSigningRequest = result.lstFilteredSigningRequest;
                let setFilteredDataSigningReq = new Set();
                let canDisableButtonNotify = false;
                for(let i = 0; i < lstFilteredSigningRequest.length; i++){
                    setFilteredDataSigningReq.add(lstFilteredSigningRequest[i].Id);
                }
                this.showClosePreviousPhaseBtn = result.showClosePreviousPhaseBtn;
                this.titleCountSigningRequest = 'Signing Requests (' + this.dataSigningRequest.length + ')';
                this.buttonSignPoolVisibility = result.isSignPoolVisible;
                this.buttonDeleteVisbility = result.isDeleteVisible;
                this.isProfileSuper = result.isDeleteVisible;
                this.disableBtnSend = false; //Note SAU: visibility for button requested on 23/06
                this.strPremiumOtherCurrencyLabel = 'Premium (' +result.currencyOtherLabel +')';
                this.totalCededPremiumOther = result.totalCededPremiumOther;
                this.totalCededPremiumEUR = result.totalCededPremiumEUR;
                this.allowAskForValidation = result.allowAskForValidation;
                this.contractualDocSigningPresent = result.contractualDocSigningPresent;
                let renewed = result.renewStatus;
                let isReinsurerStatusNotSetup = false;
                let isReinsurerStatusSetup = false;
                let updDataSigningPool = [];
                let isFlag = false;
                //AMI 01/06/22: W-0940
                //get total count request
                //this.nbrTotalReq = this.dataSigningRequest.length;
                for(let i = 0; i < this.dataSigningRequest.length; i++){
                    let rowReq = { ...this.dataSigningRequest[i] };
                    if (rowReq.ReinsurerStatus__c === 'Sent' || rowReq.ReinsurerStatus__c === 'TimeOut' || rowReq.ReinsurerStatus__c === 'Signed' || rowReq.ReinsurerStatus__c === 'Signed By R.M.'){
                        isFlag = true;
                    }
                    console.log('rowReq.isReopenPreviousPhase__c == ', rowReq.isReopenPreviousPhase__c);
                    console.log('rowReq.ReinsurerStatus__c == ', rowReq.ReinsurerStatus__c);
                    console.log('isFlag == ', isFlag);
                    //RRA - ticket 1410 / 1411 - 13042023
                    if(rowReq.ExpectedResponseDate__c === undefined && rowReq.isReopenPreviousPhase__c && isFlag === false){
                        console.log('11');
                        this.hideCheckbox = true ;
                    }else if(rowReq.ExpectedResponseDate__c === undefined && rowReq.isReopenPreviousPhase__c === false && isFlag){
                        console.log('22');
                        this.hideCheckbox = true ;
                    }else if (rowReq.ExpectedResponseDate__c !== undefined && rowReq.isReopenPreviousPhase__c && isFlag){
                        console.log('55');
                        this.hideCheckbox = false ;
                    }else if (rowReq.ExpectedResponseDate__c !== undefined && rowReq.isReopenPreviousPhase__c === false && isFlag){
                        console.log('33');
                        this.hideCheckbox = false ;
                    }else if (rowReq.ExpectedResponseDate__c === undefined && rowReq.isReopenPreviousPhase__c === false  && isFlag === false){
                        console.log('44');
                        this.hideCheckbox = true ;
                    }
                    /*if(rowReq.ExpectedResponseDate__c === undefined)
                        this.hideCheckbox = true ;
                    else 
                        this.hideCheckbox = false ;*/
    
                    //AMI 01/06/22: W-0940
                    //count req in sent status
                    if(this.dataSigningRequest[i] && this.dataSigningRequest[i].ReinsurerStatus__c === 'Setup'){
                        //this.nbrSetupReq ++;
                        this.isSetupRequest = true ;//MRA 14/07/2022 : W-0940
                    }
                    // RRA - 869
                    if (rowReq.SigningStatus__c == '4'){
                        canDisableButtonNotify = true;
                    }
                    //RRA - 872
                    //MBE - W-087
                    if(rowReq.TECH_RelatedLeadPlacementRequest__c != null && rowReq.TECH_RelatedLeadPlacementRequest__c != undefined){
                        if(rowReq.TECH_Recovery_RelatedLeadPlacementReq__c == 'Lead'){
                            rowReq['boldStyle'] = "font-weight: bold;";
                            rowReq['isLead'] = true;
                        }
                        else{
                            rowReq['boldStyle'] = "";
                            rowReq['isLead'] = false;
                        }
                    }
                    else{
                        rowReq['boldStyle'] = "";
                        rowReq['isLead'] = false;
                    }
    
                    rowReq['TreatyPlacementShare'] = parseFloat(rowReq.Treaty__r.PlacementShare_Perc__c).toFixed(6).replace('.',',');
    
                    if(setFilteredDataSigningReq.has(rowReq.Id)){
                        rowReq['displayInTable'] = true;
                    }
                    else{
                        rowReq['displayInTable'] = false;
                    }
    
                    rowReq['divId'] = rowReq.Id;
                    rowReq['divId2'] = rowReq.Id;
                    rowReq['WrittenShareVal'] = parseFloat(rowReq.WrittenShare__c).toFixed(6).replace('.',',');
                    rowReq['SignedShareVal'] = parseFloat(rowReq.SignedShare__c).toFixed(6).replace('.',',');
    
                    if(rowReq.RiskCarrier__r != undefined){
                        rowReq['RiskCarrierName'] = this.dataSigningRequest[i].RiskCarrier__r.Name;
                    }
    
                    if(rowReq.FinancialEntity__r != undefined){
                        rowReq['FinancialName'] = this.dataSigningRequest[i].FinancialEntity__r.Name;
                    }
    
                    rowReq['loadingTextRisk'] = false;
                    rowReq['searchLookupRecordsRisk'] = [];
                    rowReq['messageFlagRisk'] = false;
                    rowReq['loadingTextFinancial'] = false;
                    rowReq['searchLookupRecordsFinancial'] = [];
                    rowReq['messageFlagFinancial'] = false;
    
                    if(rowReq.Pool__c != null && rowReq.Pool__c != undefined){
                        rowReq['isRequestPool'] = true;
                        rowReq['disableSignedShare'] = true;
                        rowReq['ReinsurerPoolName'] = rowReq.Pool__r.Name;
                        rowReq['ReinsurerOrPoolName'] = rowReq.Pool__r.Name;
                    }
                    else{
                        if(rowReq.Broker__c == null || rowReq.Broker__c == undefined){
                            rowReq['disableRetro'] = true;
                        }
                        else{
                            rowReq['disableRetro'] = false;
                        }
    
                        rowReq['isRequestPool'] = false;
                        rowReq['ReinsurerPoolName'] = rowReq.TECH_ReinsurerName__c;
                        rowReq['ReinsurerName'] = rowReq.TECH_ReinsurerName__c;
                        rowReq['ReinsurerOrPoolName'] = rowReq.TECH_ReinsurerName__c;
                        rowReq['ReinsurerPoolName'] = 'MarketSubmission?c__program=' + this.selectedProgram + '-' + rowReq.Id;
                        rowReq['isPremiumDisable'] = true;
                    }
    
                    if(rowReq.isRequestPool == false || rowReq.isRequestPool == undefined || rowReq.isRequestPool == null){
                        if(rowReq.ReinsurerStatus__c != 'Setup' && profileName != 'System Administrator' && profileName != 'AGRE_System Admin' && profileName != 'AGRE_Delegated Admin'){
                            rowReq['disableSignedShare'] = true;
                            isReinsurerStatusNotSetup = true;
                        }
                        else{
                            this.requestsSetup.push(rowReq);
                        }
                    }
    
                    if(rowReq.ReinsurerStatus__c == 'Setup' && (rowReq.isRequestPool == false || rowReq.isRequestPool == undefined || rowReq.isRequestPool == null)){
                        isReinsurerStatusSetup = true;
                        rowReq['disableSignedShare'] = false;
                    }
    
                    //SAU -- update W-0729
                    //MBE --24/09
                    //Premium Deposit - Editable if Type of Treaty QS-3 or Surplus-4 and Premium Deposit of Treaty = 'Yes'
                    if((rowReq.Treaty__r.TypeofTreaty__c == '3' || rowReq.Treaty__r.TypeofTreaty__c == '4') && (rowReq.Treaty__r.PremiumDeposit__c == 'Yes')){
                        rowReq['isPremiumDisable'] = false;
                    }
    
                    if(rowReq.Treaty__r.Deductions__c == '2'){
                        rowReq['disableDeduction'] = true;
                    }
                    else{
                        rowReq['disableDeduction'] = false;
                    }
    
                    let lossDepositModeReqOpt;
                    /*if(rowReq.Program__r.LossDeposit__c == '2'){
                        rowReq['disableLossDepositMode'] = true;
                    }*/
                    console.log('isProfileSuper == ', this.isProfileSuper);
                    console.log('rowReq.Program__r.LossDepositLevel__c == ', rowReq.Program__r.LossDepositLevel__c);
                    console.log('rowReq.Program__r.LossDeposit__c == ', rowReq.Program__r.LossDeposit__c);
                    console.log('lossDepositModeOpt == ', lossDepositModeOpt);
                    
                    let lossDepositModeReqUpd = [];
                    if(rowReq.Program__r.LossDepositLevel__c != undefined){
                         //RRA - ticket 1421 - 06062023
                        if (this.isProfileSuper){
                                for(let j = 0; j < lossDepositModeOpt.length; j++){
                                    let row = { ...lossDepositModeOpt[j] };
                                    lossDepositModeReqUpd.push(row);
                                }
                                console.log('lossDepositModeReqUpd == ', lossDepositModeReqUpd);
                                rowReq['LossDepositModeOpt'] = lossDepositModeReqUpd;
                         }else{
                            if(rowReq.Program__r.LossDepositLevel__c == 'Program'){
                                //RRA - ticket 1421 - 06062023
                                if(rowReq.Program__r.LossDeposit__c == '2'){
                                    rowReq['disableLossDepositMode'] = true;
                                }else if(rowReq.Program__r.LossDeposit__c == '1'){
                                    rowReq['disableLossDepositMode'] = false;
                                }
                                lossDepositModeReqOpt = rowReq.Program__r.LossDepositMode__c; //RRA - ticket 1554 - 18082023
                            }
                            else if(rowReq.Program__r.LossDepositLevel__c == 'Treaty'){
                                if(rowReq.Treaty__r.LossDeposit__c == '2'){
                                    rowReq['disableLossDepositMode'] = true;
                                }else if(rowReq.Treaty__r.LossDeposit__c == '1'){
                                    rowReq['disableLossDepositMode'] = false;
                                }
                                lossDepositModeReqOpt = rowReq.Treaty__r.LossDepositMode__c; //RRA - ticket 1554 - 18082023
                            }
                        }
                    }else{
                        //RRA - ticket 1421 - 31072023
                        if (this.isProfileSuper){
                            if (rowReq.Program__r.LossDeposit__c == '2'){
                                for(let j = 0; j < lossDepositModeOpt.length; j++){
                                    let row = { ...lossDepositModeOpt[j] };
                                    lossDepositModeReqUpd.push(row);
                                }
                                console.log('lossDepositModeReqUpd == ', lossDepositModeReqUpd);
                                rowReq['LossDepositModeOpt'] = lossDepositModeReqUpd;
                            }
                         }else{
                            if (rowReq.Program__r.LossDeposit__c == '2'){
                                rowReq['disableLossDepositMode'] = true;
                            }else if(rowReq.Program__r.LossDeposit__c == '1'){
                                rowReq['disableLossDepositMode'] = false;
                                
                            }
                            rowReq['LossDepositModeOpt'] = (rowReq.LossDepositMode__c != null || rowReq.LossDepositMode__c != undefined) ? rowReq.LossDepositMode__c : rowReq.Program__r.LossDepositMode__c; //RRA - ticket 1421 - 10082023
                         }
                    }
                    if(lossDepositModeReqOpt != undefined){
                        let lossDepositModeExisted = lossDepositModeReqOpt.split(';');
                        let lossDepositModeReqUpd = [];
    
                        for(let i = 0; i < lossDepositModeExisted.length; i++){
                            for(let j = 0; j < lossDepositModeOpt.length; j++){
                                let row = { ...lossDepositModeOpt[j] };
                                if(row.value == lossDepositModeExisted[i]){
                                    lossDepositModeReqUpd.push(row);
                                }
                            }
                        }
                        rowReq['LossDepositModeOpt'] = lossDepositModeReqUpd;
                    }
    
                    if(rowReq.Pool__c != null){
                        updDataSigningPool.push(rowReq);
                    }
    
                    updDataSigningRequest.push(rowReq);
                }
    
                // RRA - 869
                if (canDisableButtonNotify == true){
                    console.log('Ok button CLose Signing and Notify Web XL is gray out');
                    this.disableThisButton = true;
                }
    
                this.dataSigningRequest = updDataSigningRequest;
                this.calculateTotalSignedWrittenShare();
    
                if(renewed == 'Identical Renew'){
                    this.disableReopenPreviousPhase = false;
                }
                else if(isReinsurerStatusNotSetup == true && this.isProfileSuper == false){
                    this.disableReopenPreviousPhase = true;
                }
                else{
                    this.disableReopenPreviousPhase = false;
                }
    
                if(isReinsurerStatusSetup == true || this.dataSigningRequest.length == 0){
                    this.disableUpdateRemind = true;
                }
                else{
                    this.disableUpdateRemind = false;
                }
    
                if(this.dataSigningRequest.length == 0 && this.isProfileSuper == false){
                    this.disableReopenPreviousPhase = true;
                }
    
                this.sortData('TECH_Layer__c', 'TECH_TreatyName__c', 'ReinsurerOrPoolName', 'asc');
                this.dataSigningPool = updDataSigningPool;
                this.error = undefined;
                this.spinnerSigningRequest = false;
    
                //Program - RRA - ticket 585 - 14032023
                if (isDeactivatedProg){
                    this.disableBtnSigning = true; 
                    this.disableBtnSend = true; 
                    this.disableReopenPreviousPhase = true; 
                    this.hideWrittenToSignBtn = true;
                    this.disableThisButton = true;
                }else {
                    this.disableBtnSigning = false; 
                    this.disableBtnSend = false; 
                    //RRA - ticket 1410- 13042023
                    if(isReinsurerStatusNotSetup == true && this.isProfileSuper == false){
                        this.disableReopenPreviousPhase = true;
                    }else if(this.dataSigningRequest.length == 0 && this.isProfileSuper == false){
                        this.disableReopenPreviousPhase = true;
                    }else{
                        this.disableReopenPreviousPhase = false;
                    }
    
                    //this.disableReopenPreviousPhase = false; 
                    this.hideWrittenToSignBtn = false;
                    this.disableThisButton = false;
                }
            })
            .catch(error => {
                console.log('error == ');
                this.error = error;
                console.log('error == ',this.error);
                this.spinnerSigningRequest = false;
                this.disableUpdateRemind = true;
                this.closePreviousBtnClick = false;
            });
        }
        else{
            this.dataSigningRequest = [];
            this.titleCountSigningRequest = 'Signing Requests (' + this.dataSigningRequest.length + ')';
            this.spinnerSigningRequest = false;
            this.closePreviousBtnClick = false;
        }
    }
}