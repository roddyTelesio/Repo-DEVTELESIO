import {LightningElement, track, wire, api} from 'lwc';
import {NavigationMixin, CurrentPageReference} from 'lightning/navigation';
import {registerListener, unregisterAllListeners, fireEvent} from 'c/pubSub';
import checkBroker from '@salesforce/apex/LWC25_PortalFilters.checkBrokerContact';
import getRequestsInfo from '@salesforce/apex/LWC26_PortalHomePage.getRequestsInfo';

const columns = [
    { label: '', fieldName: 'statusIcon' , type: 'button-icon', typeAttributes: { iconName: 'utility:record', iconClass: { fieldName: 'classStatusIcon' }, variant:'bare'}},
    { label: 'Status', fieldName: 'statusMessage'},
    { label: 'Name', fieldName: 'programUrl', type: 'url', typeAttributes: {label: {fieldName: 'programName'}, target: '_self'} },
    { label: 'Expected Answer Date', fieldName: 'expectedAnswerDate' },
    { label: 'Last Answer Date', fieldName: 'lastAnswerDate' }
];

export default class LWC26_PortalHomePage extends LightningElement {
    @api valueUWYear;
    @api valuePrincipalCedComp;
    @api valueReinsurerId = null;
    @api valIsBroker = false;
    @api lstRequests = [];
    @api current_valueReinsurerId; 
    @api current_valIsBroker; 
    @api current_uwYear;
    @api current_valueUWYear;
    @api current_valuePrincipalCedComp
    
    reinsurerOptions;
    columns = columns;
    error;
    reinsurerOptionsAll;
    spinner = false; 

    @wire(CurrentPageReference) pageRef;
    connectedCallback(){
        registerListener('year', this.getVal, this);
        registerListener('comp', this.getComp, this);
        registerListener('changeReinsurer', this.getReinsurer, this);        
        this.getRequestsInfo();
    }

    get requests(){
        return this.lstRequests;
    }
    
    getVal(val){
        this.valueUWYear = val;
        this.valueReinsurerId = null;
        //this.spinner = true; //RRA - ticket 1716 - 30102023
        this.getRequestsInfo();
    }

    getComp(val){
        this.valuePrincipalCedComp = val;
        this.valueReinsurerId = null;
        //this.spinner = true;  //RRA - ticket 1716 - 30102023
        this.getRequestsInfo();
    }

    getReinsurer(val){
        if(val == 'All'){
            this.valueReinsurerId = null;
        }
        else {
            this.valueReinsurerId = val;
        }
        
        //console.log('valueReinsurerId == ', this.valueReinsurerId);
       // this.spinner = true; //RRA - ticket 1716 - 30102023
        this.getRequestsInfo();
    }

    @wire(checkBroker)
    wiredCheckBroker(result){
        if(result.data) {
            this.valIsBroker = result.data;
            this.error = undefined;
            this.getRequestsInfo();
        }
        else if (result.error) {
            this.error = result.error;
        }
    }

    getRequestsInfo(){
        // this.spinner = true; //RRA - ticket 1716 - 30102023
         //RRA - ticket 1551 - 07082023
         let valueUWYearSessionPortal = sessionStorage.getItem('valueUWYearSessionPortal'); 
         let valuePccSessionPortal = sessionStorage.getItem('valuePccSessionPortal');
         
         console.log('valueUWYearSessionPortal== ' ,  valueUWYearSessionPortal);
         console.log('valuePccSessionPortal== ' ,  valuePccSessionPortal);
         let valueChangeReinsSessionPortal = sessionStorage.getItem('valueChangeReinsSessionPortal');
         let isPortalSession = sessionStorage.getItem('isPortalSession');
         console.log('isPortalSession== ' ,  isPortalSession);
         
          //RRA - ticket 1525 - 07072023 - avoid issue on variable event which execute on background=> store variable event on variable global
         if(this.current_valueReinsurerId != this.valueReinsurerId || 
            this.current_valIsBroker != this.valIsBroker|| 
            this.current_uwYear != this.uwYear || 
            this.current_valueUWYear != this.valueUWYear||
            this.current_valuePrincipalCedComp != this.valuePrincipalCedComp){
                
             this.current_valueReinsurerId = this.valueReinsurerId ;
             this.current_valIsBroker = this.valIsBroker ;
             this.current_valueUWYear =this.valueUWYear;
             this.current_valuePrincipalCedComp = this.valuePrincipalCedComp;
             
             console.log('current_valueUWYear== ' ,  this.current_valueUWYear);
             console.log('current_valuePrincipalCedComp== ' ,  this.current_valuePrincipalCedComp);
             console.log('current_valueReinsurerId== ' ,  this.current_valueReinsurerId);
             console.log('current_valIsBroker== ' ,  this.current_valIsBroker);
 
             //RRA - ticket 1551 - 07082023
             if (isPortalSession == 'true'){
                 this.getRequestsInfoOnPortal(null, this.valIsBroker, valueUWYearSessionPortal, valuePccSessionPortal);
             }else{
                 this.getRequestsInfoOnPortal (this.current_valueReinsurerId, this.current_valIsBroker, this.current_valueUWYear, this.current_valuePrincipalCedComp);
             }
         }else{
             return;
         }
     }
     
        //RRA - ticket 1551 - 07082023
        getRequestsInfoOnPortal (valReinsId, valBroker, valUWY, valPCC){
            getRequestsInfo({reinsurerId: valReinsId, isBroker: valBroker, uwYear: valUWY, pcc: valPCC})
            .then(result => {
                console.log('valReinsId== ' ,  valReinsId);
                console.log('valBroker== ' ,  valBroker);
                console.log('valUWY== ' ,  valUWY);
                console.log('valPCC== ' ,  valPCC);
                
                    console.log('result== ' , result);
                this.spinner = true;
                let resultReinsurerOptInit = [];
                let reinsurerOptAll = [];
                let reinsurerOpt = [];
                let all = { label: "All", value:"All" };
                reinsurerOptAll.push(all);
                
                //RRA - ticket 1525 - 07072023
                resultReinsurerOptInit = result.reinsurerOptionsAll;
                for(let i = 0; i < resultReinsurerOptInit.length; i++){
                    reinsurerOptAll.push(resultReinsurerOptInit[i]);
                    reinsurerOpt.push(resultReinsurerOptInit[0][i]);
                }
        
                //console.log(' resultReinsurerOptInit == ',  resultReinsurerOptInit);
                console.log(' reinsurerOptAll == ',  reinsurerOptAll);      
                this.reinsurerOptionsAll = reinsurerOptAll;
        
                if(this.valueReinsurerId == undefined || this.valueReinsurerId == null){
                    this.valueReinsurerId = 'All';
                }
                this.lstRequests = result.lstRequests;
                this.lstRequests = this.sortData('reinsurerName', 'asc', this.lstRequests);
        
                console.log(' lstRequests == ',  this.lstRequests);  
                
                fireEvent(this.pageRef, 'reinsurerOptionsAll', this.reinsurerOptionsAll);
                fireEvent(this.pageRef, 'refreshReq', 'refresh');
                //RRA - To avoid performance issues caused by event listners from scroll ('touchOnStart / touchOnMove / Wheel', etc) / do not call Event.preventDefault() using {passive: true} on addEventListener 
                //reference https://github.com/WICG/EventListenerOptions/blob/gh-pages/explainer.md => 
                //document.addEventListener('touchstart', onTouchstart, {passive: true});
                //document.addEventListener('touchmove', onTouchmove, {passive: true});
                fireEvent(this.pageRef, 'changeReinsurer', this.valueReinsurerId);
                fireEvent(this.pageRef, 'reinsurerOpt', reinsurerOpt);
            
                this.error = undefined;
                this.spinner = false;
            })
            .catch(error => {
                this.error = error;
                this.spinner = false;
            });
        }

    sortData(fieldName, sortDirection, lstData) {
        let sortResult = Object.assign([], lstData);
        let lstSortedLstData = sortResult.sort(function(a,b){
            if(a[fieldName] < b[fieldName]){
                return sortDirection === 'asc' ? -1 : 1;
            }
            else if(a[fieldName] > b[fieldName]){
                return sortDirection === 'asc' ? 1 : -1;
            }
            else{
                return 0;
            }
        })
        return lstSortedLstData;
    }
}