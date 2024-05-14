import {LightningElement, wire, api} from 'lwc';
import {getPicklistValues} from 'lightning/uiObjectInfoApi';
import {getObjectInfo} from 'lightning/uiObjectInfoApi';
import PROGRAM_OBJECT from '@salesforce/schema/Program__c';
import UWYEAR_FIELD from '@salesforce/schema/Program__c.UwYear__c';
import getAcc from '@salesforce/apex/LWC01_WorkingScope.getPrincipalCedingAcc';
import getAccSignForPool from '@salesforce/apex/LWC01_WorkingScope.getPrincipalCedingAccSignForPool';
import getAccPortal from '@salesforce/apex/LWC01_PortalWorkingScope.getPrincipalCedingAccPortal';
import getProgramDetails from '@salesforce/apex/LWC01_WorkingScope.getProgramDetails';
import {NavigationMixin, CurrentPageReference} from 'lightning/navigation';
import {registerListener, unregisterAllListeners, fireEvent} from 'c/pubSub';
import {loadStyle, loadScript} from 'lightning/platformResourceLoader';
import HideLightningHeader from '@salesforce/resourceUrl/HideLightningHeader';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';


//import custom labels
import WorkingScope from '@salesforce/label/c.Working_Scope';
import UWYear from '@salesforce/label/c.UWYear';
import PrincipalCedingCompany from '@salesforce/label/c.PrincipalCedingCompany';
import errorMsg from '@salesforce/label/c.errorMsg';


export default class LWC01_WorkingScope extends NavigationMixin(LightningElement) {
    @api selectedYear;
    @api selectedComp;
    @api isModalOpen;
    @api createProg = false;
    @api isSignForPool = false;
    @api isDocument = false;
    @api isRenew;
    @api valueProgram;
    @api programOptions = [];
    @api showTiles = false;
    @api nameURLUpdated = null;
    error;
    valueUWYear;
    valuePrincipalCedComp;
    valueUWYearSummary;
    valuePrincipalCedCompSummary;
    uwYearOpt;
    cedingAccOpt;
    year;
    comp;
    stage;
    isTreatyPlacementPage = false;
    isSummaryPage = false;
    treatyPlacementUrl;
    valueProgramName;
    valuePCCName;
    program;
    isCurrentSession = false;
    isOnChangeUWY = false;
    isOnChangePcc = false;

    label = {
        WorkingScope,
        UWYear,
        PrincipalCedingCompany,
        errorMsg
    };

    @wire(CurrentPageReference) pageRef;

    connectedCallback() {
        let currentTreatyPlacement = null;
        this.isTreatyPlacementPage = false;
        loadStyle(this, HideLightningHeader);
        registerListener('year', this.getVal, this);
        registerListener('comp', this.getComp, this);
        registerListener('yearSummary', this.getValSummary, this);
        registerListener('compSummary', this.getCompSummary, this);
        //window.location.href --- old line 
        //Changes done due to issues after Summer '21
        let currentUrl = this.pageRef.state;
        //RRA - ticket 0050 - 14122022 - Get current session on tab treaty placement
        let currentSession = sessionStorage.getItem('nameUrl');
        let pcc11 = sessionStorage.getItem('pcc11');
        //let currentSessionHome = sessionStorage.getItem('treatyPlacementPhaseFromHome');
        let currentSessionTreatyPlacement = sessionStorage.getItem('nameUrlUrl');
        //let nameTreatyPlacem = sessionStorage.getItem('nameUrlTP');

        console.log('currentUrl == ' , currentUrl);
        console.log('currentSession == ' , currentSession);
        console.log('this.pageRef.attributes == ' , this.pageRef.attributes);
        //console.log('currentSessionHome == ' , currentSessionHome);
        //console.log('currentSessionTreatyPlacement == ' , currentSessionTreatyPlacement);
        //console.log('nameTreatyPlacem == ' , nameTreatyPlacem);

        let nameUrl = null;
        let paramValue = null;

        if(this.pageRef.attributes.apiName != null && this.pageRef.attributes.apiName != undefined){
            nameUrl = this.pageRef.attributes.apiName;
            this.nameURLUpdated = this.pageRef.attributes.apiName;
        }
        else if(this.pageRef.attributes.pageName != null && this.pageRef.attributes.pageName != undefined){
            nameUrl = this.pageRef.attributes.pageName;
            this.nameURLUpdated = this.pageRef.attributes.pageName;
        }else if(this.pageRef.attributes.name != null && this.pageRef.attributes.name != undefined){
            nameUrl = this.pageRef.attributes.name;
        }else if(this.pageRef.attributes.objectApiName == 'Section__c' && this.pageRef.attributes.actionName == 'edit'){
            nameUrl = this.pageRef.attributes.objectApiName;
        }else if(this.pageRef.attributes.objectApiName == 'Treaty__c' && this.pageRef.attributes.actionName == 'edit'){
            nameUrl = this.pageRef.attributes.objectApiName;
        }
        console.log('nameUrl string == ' , nameUrl); 
        //console.log('this.isOnChangePcc boolean == ' , this.isOnChangePcc); 

        if(Object.keys(currentUrl).length > 0 && nameUrl == 'TreatyPlacement' && !nameUrl.includes("portal")){
            let param = 'c__program';
            paramValue = currentUrl[param];
        //RRA - ticket 0050 - 14122022 : 
        //*Check if current Session is present on tab Home => triggered event to retrieve value uwy / pcc / currentsession in the list programs displayed on Home*/
        }else if (currentSession != undefined && currentSession != null && nameUrl == 'home'){ 
            let valueUWYTreatyPlacementToHome = sessionStorage.getItem('valueUWYTreatyPlacementToHome');
            let valuePCCTreatyPlacementToHome = sessionStorage.getItem('valuePCCTreatyPlacementToHome');
            let isOnChangePcc = sessionStorage.getItem('isOnChangePcc');
            let isOnChangeUWY = sessionStorage.getItem('isOnChangeUWY');
            let isTreatyPlacementPageToHome = sessionStorage.getItem('isTreatyPlacementPage');
            
            console.log('isTreatyPlacementPageToHome == ' , isTreatyPlacementPageToHome); 
            console.log('valuePCCTreatyPlacementToHome == ' , valuePCCTreatyPlacementToHome);
            console.log('valueUWYTreatyPlacementToHome == ' , valueUWYTreatyPlacementToHome);
            console.log('valuePrincipalCedComp 00 == ' , this.valuePrincipalCedComp);
            console.log('valueUWYear 00== ' , this.valueUWYear);
            console.log('isOnChangePcc == ' , isOnChangePcc);
            console.log('isOnChangeUWY == ' , isOnChangeUWY); 
            
            //RRA - ticket 0050 - 12122023 : 
            //*Check if you are already in TreatyPlacement and have changed PCC or UWY
            //*Check if you have changed PCC and UWY in TreatyPlacement before being redirected to Home. In this case, 
            //*the values ​​of PCC and UWY are updated from the value paramValue */
            if (isTreatyPlacementPageToHome == 'true' && (nameUrl == 'TreatyPlacement' || nameUrl == 'home')) {
                
                let currSess = currentSession.split('-');
                if (isOnChangePcc == 'true' && isOnChangeUWY == 'false' && valuePCCTreatyPlacementToHome != null && valueUWYTreatyPlacementToHome == null){
                    console.log('is PCC Changed');
                    paramValue = '../n/TreatyPlacement?c__program=idProg-' + currSess[1] + '-' + valuePCCTreatyPlacementToHome + '-StageName-undefined-null-null-null';
                }else if (isOnChangePcc == 'false' && isOnChangeUWY == 'true' && valueUWYTreatyPlacementToHome != null && valuePCCTreatyPlacementToHome == null){
                    console.log('is UWY Changed');
                    paramValue = '../n/TreatyPlacement?c__program=idProg-' + valueUWYTreatyPlacementToHome + '-' + currSess[2] + '-StageName-undefined-null-null-null';
                }else if (isOnChangePcc == 'true' && isOnChangeUWY == 'true' & valueUWYTreatyPlacementToHome != null &&  valuePCCTreatyPlacementToHome != null){
                    console.log('is PCC and UWY Changed'); 
                    paramValue = '../n/TreatyPlacement?c__program=idProg-' + valueUWYTreatyPlacementToHome + '-' + valueUWYTreatyPlacementToHome + '-StageName-undefined-null-null-null';
                }else if (isOnChangePcc == 'false' && isOnChangeUWY == 'true' && valueUWYTreatyPlacementToHome != null && valuePCCTreatyPlacementToHome != null){
                    paramValue = '../n/TreatyPlacement?c__program=idProg-' + valueUWYTreatyPlacementToHome + '-' + valuePCCTreatyPlacementToHome + '-StageName-undefined-null-null-null';
                }else if (isOnChangePcc == 'true' && isOnChangeUWY == 'false' && valueUWYTreatyPlacementToHome != null && valuePCCTreatyPlacementToHome != null){
                    paramValue = '../n/TreatyPlacement?c__program=idProg-' + valueUWYTreatyPlacementToHome + '-' + valuePCCTreatyPlacementToHome + '-StageName-undefined-null-null-null';
                }
            }else{
                this.isCurrentSession = true;
                console.log('currentSession string == ' , currentSession); 
                fireEvent(this.pageRef, 'isOnChangePcc', this.isOnChangePcc);
                fireEvent(this.pageRef, 'isOnChangeUWY', this.isOnChangeUWY);
                fireEvent(this.pageRef, 'isCurrentSession', this.isCurrentSession); 
                console.log('ok  currentSession');
                let splitValue = currentSession.split('=');
                paramValue = splitValue[1];
            }
            
            console.log('paramValue home== ' ,  paramValue);
        //RRA - ticket 0050 - 14122022 : 
        //* Check if current Session is present on tab TreatyPlacement => triggered event to retrieve value uwy / pcc / in the list programs displayed on TreatyPlacement 
        }else if (currentSessionTreatyPlacement != undefined && currentSessionTreatyPlacement != null && nameUrl === 'TreatyPlacement'){ 
            this.isCurrentSession = true;
            fireEvent(this.pageRef, 'isOnChangePcc', this.isOnChangePcc);
            fireEvent(this.pageRef, 'isOnChangeUWY', this.isOnChangeUWY);
            fireEvent(this.pageRef, 'isCurrentSession', this.isCurrentSession); 
            fireEvent(this.pageRef, 'currentTreatyPlacement', currentTreatyPlacement); 
            console.log('ok  currentSession TreatyPlacement ');
            let splitValue = currentSessionTreatyPlacement.split('=');
            paramValue = splitValue[1];
            console.log('paramValue TreatyPlacement== ' ,  paramValue);
        }else if (currentSession != undefined && currentSession != null && nameUrl == 'Section__c'){
            let currSess = currentSession.split('-');
            paramValue = '../n/TreatyPlacement?c__program=idProg-' + currSess[1] + '-' + currSess[2] + '-StageName-undefined-null-null-null';
        }else if (currentSession != undefined && currentSession != null && nameUrl == 'Treaty__c'){
            let currSess = currentSession.split('-');
            paramValue = '../n/TreatyPlacement?c__program=idProg-' + currSess[1] + '-' + currSess[2] + '-StageName-undefined-null-null-null';
        }

        sessionStorage.setItem('nameUrlTP', nameUrl);

        if (nameUrl == 'TreatyPlacement'){
            currentTreatyPlacement = currentUrl.c__program;
            sessionStorage.setItem('nameUrlNew', currentTreatyPlacement);            
            console.log('currentTreatyPlacement paramValue== ' ,  currentTreatyPlacement);
        }
        

        if(paramValue != null){
            this.isTreatyPlacementPage = true;
            let parameters = paramValue.split("-");

            if(parameters[1] != undefined){
                this.valueUWYear = parameters[1];
                fireEvent(this.pageRef, 'yearOnProgram', this.valueUWYear);//RRA - ticket 0050 - 02082023 => Update UI UWY and PCC of Working Scope if renew o copy Program
            }

            if(parameters[2] != undefined){
                this.valuePrincipalCedComp = parameters[2];
                fireEvent(this.pageRef, 'pccOnProgram', this.valuePrincipalCedComp); //RRA - ticket 0050 - 02082023 => Update UI UWY and PCC of Working Scope if renew o copy Program
            }
           
            console.log('paramValue home renew valueUWYear== ' ,  this.valueUWYear);
            console.log('paramValue home renew valuePrincipalCedComp== ' ,  this.valuePrincipalCedComp);
            
           
          
        }else{
            sessionStorage.clear();
        }

        if(nameUrl == 'portal_summary__c'){
            //summary page
            this.isSummaryPage = true;
            let param = 'c__portal';
            let paramValue = null;

            if(currentUrl != undefined && currentUrl != null){
                paramValue = currentUrl[param];
            }else if (currentSession != undefined && currentSession != null && nameUrl === null){//RRA - ticket 0050 - 14122022 - Check if current Session is present on tab Home => triggered event to retrieve value uwy / pcc / currentsession in the list programs displayed on Home
                console.log('ok  currentSession');
                isCurrentSession = true;
                fireEvent(this.pageRef, 'isOnChangePcc', this.isOnChangePcc);
                fireEvent(this.pageRef, 'isOnChangeUWY', this.isOnChangeUWY);
                fireEvent(this.pageRef, 'isCurrentSession', this.isCurrentSession);
                //fireEvent(this.pageRef, 'currentTreatyPlacement', currentTreatyPlacement); 
                let splitValue = currentSession.split('=');
                paramValue = splitValue[1];
            }

            if(paramValue != null){
                let parameters = paramValue.split("-");

                if(parameters[2] != undefined){
                    this.valueUWYear = parameters[2];
                }

                if(parameters[3] != undefined){
                    this.valuePrincipalCedComp = parameters[3];
                }
            }
        }
        
        if(nameUrl != null && nameUrl.includes("portal")){
            //portal
            getAccPortal()
            .then(resultPortal => {
                this.cedingAccOpt = resultPortal;
                if(this.isTreatyPlacementPage == false && this.isSummaryPage == false){
                    this.valuePrincipalCedComp = resultPortal[0].value;
                    fireEvent(this.pageRef, 'comp', this.valuePrincipalCedComp);
                }
            })
            .catch(error => {
                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error'}), );
            });
        }

        //Added by SAU
        if(this.isSignForPool){
            this.isSummaryPage = true;
        }

        if(this.isDocument == 'true' || this.isDocument == true){
            getProgramDetails({id : this.valueProgram})
            .then(result => {
                this.valueProgramName = result[0].Name;
                this.valuePCCName = result[0].PrincipalCedingCompany__r.Name;
            })
            .catch(error => {
                this.error = error;
            });
        }
    }

    getUrlParamValue(url, key) {
        return new URL(url).searchParams.get(key);
    }

    getVal(val){
        this.valueUWYear = val;
    }

    getComp(val){
        this.valuePrincipalCedComp = val;
    }

    getValSummary(val){
        this.valueUWYearSummary = val;
    }

    getCompSummary(val){
        this.valuePrincipalCedCompSummary = val;
    }

    @wire(getObjectInfo, { objectApiName: PROGRAM_OBJECT })
    objectInfo;

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: UWYEAR_FIELD})
    setPicklistOptions({error, data}) {
        if(data){
            this.uwYearOpt = data.values;
            if(this.isTreatyPlacementPage == false && this.isSummaryPage == false){
                
                this.valueUWYear = data.values[data.values.length - 1].value;
                fireEvent(this.pageRef, 'yearOnProgram', this.valueUWYear); //RRA - ticket 1553 - 31072023
                fireEvent(this.pageRef, 'year', this.valueUWYear);  //RRA - ticket 1551 - 03102023
            }
            console.log('valueUWYear == ', this.valueUWYear);

            let nameUrl = null;

            if(this.pageRef.attributes.apiName != null && this.pageRef.attributes.apiName != undefined){
                nameUrl = this.pageRef.attributes.apiName;
            }
            else if(this.pageRef.attributes.name != null && this.pageRef.attributes.name != undefined){
                nameUrl = this.pageRef.attributes.name;
            }

            if(nameUrl != null && nameUrl.includes("portal") && this.isSummaryPage == false){
                //(location.includes("portal") && this.isSummaryPage == false)
                fireEvent(this.pageRef, 'year', this.valueUWYear);
            }
        }
        else{
            this.error = error;
        }
    }

    @wire(getAccSignForPool)
    setAccPicklistOptionsSignForPool({error, data}) {
        if(data){
            let nameUrl = null;

            if(this.pageRef.attributes.apiName != null && this.pageRef.attributes.apiName != undefined){
                nameUrl = this.pageRef.attributes.apiName;
            }
            else if(this.pageRef.attributes.name != null && this.pageRef.attributes.name != undefined){
                nameUrl = this.pageRef.attributes.name;
            }

            if((nameUrl != null && nameUrl.includes("portal") == false) || (nameUrl == null)){
                //location.includes("portal") == false
                if(this.isSignForPool){
                    this.cedingAccOpt = data;
                    if(this.isTreatyPlacementPage == false){
                        if(this.valuePrincipalCedComp == null){
                            this.valuePrincipalCedComp = data[0].value;
                        }
                    }
                }
            }                   
        }
        else{
            this.error = error;
        }
    }

    @wire(getAcc)
    setAccPicklistOptions({error, data}) {
        if(data){   
            console.log('data== ', data);         
            let nameUrl = null;

            if(this.pageRef.attributes.apiName != null && this.pageRef.attributes.apiName != undefined){
                nameUrl = this.pageRef.attributes.apiName;
            }
            else if(this.pageRef.attributes.name != null && this.pageRef.attributes.name != undefined){
                nameUrl = this.pageRef.attributes.name;
            }
            
            //RRA - ticket 1551 - 03102023
            if (nameUrl == 'Home' && data.length == 0){
                console.log('ok data isempty');
                getAccPortal()
                .then(resultPortal => {
                    console.log('resultPortal== ', resultPortal);
                    this.cedingAccOpt = resultPortal;
                    if(this.isTreatyPlacementPage == false){
                        if(this.valuePrincipalCedComp == null || this.valuePrincipalCedComp == undefined){
                            this.valuePrincipalCedComp = resultPortal[0].value;
                            console.log('valuePrincipalCedComp resultPortal== ', this.valuePrincipalCedComp);
                            fireEvent(this.pageRef, 'comp', this.valuePrincipalCedComp);
                        }
                        
                    }
                })
                .catch(error => {
                    this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error'}), );
                });
            }
            
            if((nameUrl != null && nameUrl.includes("portal") == false) || (nameUrl == null)){
                //location.includes("portal") == false
                if(this.isSignForPool == false){
                    this.cedingAccOpt = data;
                    if(this.isTreatyPlacementPage == false){
                        if(this.valuePrincipalCedComp == null){
                            this.valuePrincipalCedComp = data[0].value;
                            fireEvent(this.pageRef, 'pccOnProgram', this.valuePrincipalCedComp); //RRA - ticket 1553 - 31072023
                        }
                    }
                } 
                console.log('valuePrincipalCedComp aa== ', this.valuePrincipalCedComp);
            }                   
        }
        else{
            this.error = error;
        }
    }

    handleChangeUWYr(event) {
        this.valueUWYear = event.detail.value;
        console.log('isCurrentSession year', this.isCurrentSession);
        console.log('uwy year', this.valueUWYear);
        console.log('valuePrincipalCedComp year', this.valuePrincipalCedComp);
        console.log('isTreatyPlacementPage', this.isTreatyPlacementPage);
        console.log('nameURLUpdated ', this.nameURLUpdated);

        //RRA - ticket 0050 - 14122022 - Check if current Session and change value of underwrittenyear exist => triggered event to retrieve value uwy_new / pcc_existing  in the list programs displayed on Home
        if((this.isTreatyPlacementPage == true || this.isTreatyPlacementPage == false) && this.nameURLUpdated == 'TreatyPlacement'){
            sessionStorage.setItem('valueUWYTreatyPlacementToHome', this.valueUWYear);
            sessionStorage.setItem('isOnChangeUWY', true);
            sessionStorage.setItem('isOnChangePcc', false);
            sessionStorage.setItem('isTreatyPlacementPage', this.isTreatyPlacementPage);
            fireEvent(this.pageRef, 'yearChange', this.valueUWYear);
            fireEvent(this.pageRef, 'year', this.valueUWYear); //RRA - Ticket 0050 - 02082023 => in condition, if uwy is changed, uwy in working scope is also updated
            
            fireEvent(this.pageRef, 'refreshReq', 'refresh'); //RRA - ticket 1525 - 07072023
            fireEvent(this.pageRef, 'isChangedUWY', true); //RRA - ticket 1525 - 07072023
            fireEvent(this.pageRef, 'isChangedPCC', false);//RRA - ticket 1525 - 07072023
            fireEvent(this.pageRef, 'isChanged', false);//RRA - ticket 1525 - 07072023
            
        }else if (this.isTreatyPlacementPage == true && this.nameURLUpdated == 'home'){
            this.isOnChangeUWY = true;
            fireEvent(this.pageRef, 'year', this.valueUWYear);  //RRA - ticket 1560 23082023
            fireEvent(this.pageRef, 'comp', this.valuePrincipalCedComp);  //RRA - ticket 1560 23082023
            fireEvent(this.pageRef, 'isChangedUWY', true); 
            fireEvent(this.pageRef, 'isChangedPCC', false);
            //fireEvent(this.pageRef, 'yearChange', this.valueUWYear);
            sessionStorage.setItem('valueUWYTreatyPlacementToHome', this.valueUWYear);
            sessionStorage.setItem('nameURLUpdated', this.nameURLUpdated);
            
            console.log('end isTreatyPlacementPage  home');
            
        }else if (this.isTreatyPlacementPage == false && this.nameURLUpdated == 'home'){
            console.log('Treatyplacement is false and it\'s home => uwy' );
            this.isOnChangeUWY = true;
            fireEvent(this.pageRef, 'comp', this.valuePrincipalCedComp);  //RRA - ticket 1560 23082023
            fireEvent(this.pageRef, 'year', this.valueUWYear);  //RRA - ticket 1560 23082023
            fireEvent(this.pageRef, 'isChangedUWY', true); 
            fireEvent(this.pageRef, 'isChangedPCC', false);
            //fireEvent(this.pageRef, 'yearChange', this.valueUWYear);
            fireEvent(this.pageRef, 'isOnChangeUWY', true);
            fireEvent(this.pageRef, 'isChangedPCC', false);
            console.log('Treatyplacement is false and it\'s home => uwy 11' );
        }
        else if(this.isSummaryPage == false){
            fireEvent(this.pageRef, 'year', this.valueUWYear);
            fireEvent(this.pageRef, 'refreshReq', 'refresh');//RRA - ticket 1525 - 07072023
            fireEvent(this.pageRef, 'isChangedUWY', true);//RRA - ticket 1525 - 07072023
            fireEvent(this.pageRef, 'isChangedPCC', false);//RRA - ticket 1525 - 07072023
            fireEvent(this.pageRef, 'isChanged', false);//RRA - ticket 1525 - 07072023
        }else{
            this.isOnChangeUWY = true;
            fireEvent(this.pageRef, 'yearChange', this.valueUWYear);
            fireEvent(this.pageRef, 'year', this.valueUWYear);  //RRA - ticket 1560 23082023
            fireEvent(this.pageRef, 'isOnChangeUWY', this.isOnChangeUWY);
            fireEvent(this.pageRef, 'isCurrentSession', this.isCurrentSession);
        }
    }

    handleChangeCedingComp(event) {
        this.valuePrincipalCedComp = event.detail.value;        
        console.log('isCurrentSession pcc', this.isCurrentSession);
        console.log('uwy pcc', this.valueUWYear);
        console.log('valuePrincipalCedComp pcc', this.valuePrincipalCedComp);
        console.log('isTreatyPlacementPage', this.isTreatyPlacementPage);
        console.log('nameURLUpdated', this.nameURLUpdated);
        
        //RRA - ticket 0050 - 14122022 - Check if current Session and change value of PCC exist => triggered event to retrieve value uwy_existing / pcc_new  in the list programs displayed on Home

        if(this.isTreatyPlacementPage == true && this.nameURLUpdated == 'TreatyPlacement'){
            console.log('is Treaty placement from pcc');
            sessionStorage.setItem('valuePCCTreatyPlacementToHome', this.valuePrincipalCedComp)
            sessionStorage.setItem('isOnChangeUWY', false);
            sessionStorage.setItem('isOnChangePcc', true);
            sessionStorage.setItem('isTreatyPlacementPage', this.isTreatyPlacementPage);
            sessionStorage.setItem('nameURLUpdated', this.nameURLUpdated);
            fireEvent(this.pageRef, 'compChange', this.valuePrincipalCedComp);           
            fireEvent(this.pageRef, 'comp', this.valuePrincipalCedComp); //RRA - Ticket 0050 - 02082023 => in condition, if pcc is changed, pcc in working scope is also updated

            fireEvent(this.pageRef, 'refreshReq', 'refresh');//RRA - ticket 1525 - 07072023
            fireEvent(this.pageRef, 'isChangedPCC', true);//RRA - ticket 1525 - 07072023
            fireEvent(this.pageRef, 'isChangedUWY', false);//RRA - ticket 1525 - 07072023
            fireEvent(this.pageRef, 'isChanged', false);//RRA - ticket 1525 - 07072023
            
        }else if(this.isTreatyPlacementPage == false && this.nameURLUpdated == 'TreatyPlacement'){
            console.log('is Treaty placement false from pcc');
            sessionStorage.setItem('valuePCCTreatyPlacementToHome', this.valuePrincipalCedComp)
            sessionStorage.setItem('isOnChangeUWY', false);
            sessionStorage.setItem('isOnChangePcc', true);
            sessionStorage.setItem('isTreatyPlacementPage', this.isTreatyPlacementPage);
            sessionStorage.setItem('nameURLUpdated', this.nameURLUpdated);
            fireEvent(this.pageRef, 'compChange', this.valuePrincipalCedComp);  
            fireEvent(this.pageRef, 'comp', this.valuePrincipalCedComp);
        }else if ((this.isTreatyPlacementPage == true || this.isTreatyPlacementPage == false) && this.nameURLUpdated == 'home'){
            console.log('is isTreatyPlacementPage to home');
            this.isOnChangePcc = true;
            fireEvent(this.pageRef, 'comp', this.valuePrincipalCedComp); //RRA - ticket 1560 23082023
            fireEvent(this.pageRef, 'year', this.valueUWYear);  //RRA - ticket 1560 24082023
            fireEvent(this.pageRef, 'isOnChangePCC', true);
            fireEvent(this.pageRef, 'isOnChangeUWY', false);
            //fireEvent(this.pageRef, 'compChange', this.valuePrincipalCedComp);
            sessionStorage.setItem('valuePCCTreatyPlacementToHome', this.valuePrincipalCedComp);
            sessionStorage.setItem('nameURLUpdated', this.nameURLUpdated);
        }else if(this.isSummaryPage == false){
            console.log('is isSummaryPage');
            fireEvent(this.pageRef, 'comp', this.valuePrincipalCedComp);
            fireEvent(this.pageRef, 'refreshReq', 'refresh');//RRA - ticket 1525 - 07072023
            fireEvent(this.pageRef, 'isChangedPCC', true);//RRA - ticket 1525 - 07072023
            fireEvent(this.pageRef, 'isChangedUWY', false);//RRA - ticket 1525 - 07072023
            fireEvent(this.pageRef, 'isChanged', false);//RRA - ticket 1525 - 07072023
        }else{
            this.isOnChangePcc = true;
            fireEvent(this.pageRef, 'comp', this.valuePrincipalCedComp);  //RRA - ticket 1560 23082023
            fireEvent(this.pageRef, 'compChange', this.valuePrincipalCedComp);
            fireEvent(this.pageRef, 'isOnChangePcc', this.isOnChangePcc);
            fireEvent(this.pageRef, 'isCurrentSession', this.isCurrentSession);
        }
    }
    
}