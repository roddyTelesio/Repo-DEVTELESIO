import {LightningElement, track, wire, api} from 'lwc';
import {getPicklistValues, getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import {getObjectInfo} from 'lightning/uiObjectInfoApi';
import {NavigationMixin, CurrentPageReference} from 'lightning/navigation';
import {registerListener, unregisterAllListeners, fireEvent} from 'c/pubSub';
import {loadStyle, loadScript} from 'lightning/platformResourceLoader';
import HideLightningHeader from '@salesforce/resourceUrl/HideLightningHeader';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import Id from '@salesforce/user/Id';
import PROGRAM_OBJECT from '@salesforce/schema/Program__c';
import UWYEAR_FIELD from '@salesforce/schema/Program__c.UwYear__c';
import getAccPortal from '@salesforce/apex/LWC01_PortalWorkingScope.getPrincipalCedingAccPortal';
import checkBroker from '@salesforce/apex/LWC25_PortalFilters.checkBrokerContact';
import getRequestsInfoFilter from '@salesforce/apex/LWC55_SAExternalPortal.getRequestsInfoFilter';
import errorMsg from '@salesforce/label/c.errorMsg';

const columns = [
    { label: '', fieldName: 'statusIcon' , type: 'button-icon', typeAttributes: { iconName: 'utility:record', iconClass: { fieldName: 'classStatusIcon' }, variant:'bare'}},
    { label: 'Status', fieldName: 'statusMsg'},
    { label: 'Program Name', fieldName: 'TECH_ProgramName__c'},
    { label: 'Special Acceptance Name', fieldName: 'respondOnBehalfLink', type: 'url', typeAttributes: {label: {fieldName: 'saName'}, target: '_self'} },
    { label: 'Expected Answer Date', fieldName: 'ExpectedResponseDate__c' },
    { label: 'Last Answer Date', fieldName: 'ResponseDate__c' },
    { label: 'Bind Status', fieldName: 'bindStatus' }
];

export default class Lwc55SAExternalPortal extends NavigationMixin(LightningElement){
    label = {
        errorMsg
    }

    error;
    @api valIsBroker = false;
    @track lstRequests = [];
    valueUwYear;
    valuePrincipalCedComp;
    valueReinsurer;
    uwYearOpt;
    cedingAccOpt;
    reinsurerOptions;
    reinsurerOptionsAll;
    columns = columns;
    spinner = false;

    @wire(CurrentPageReference) pageRef;

    @wire(getObjectInfo, { objectApiName: PROGRAM_OBJECT })
    objectInfo;

    getUrlParamValue(url, key) {
        return new URL(url).searchParams.get(key);
    }

    connectedCallback(){
        //window.location.href --- old line 
        //Changes done due to issues after Summer '21
        let currentUrl = this.pageRef.state;
        let nameUrl = null;

        if(this.pageRef.attributes.apiName != null && this.pageRef.attributes.apiName != undefined){
            nameUrl = this.pageRef.attributes.apiName;
        }
        else if(this.pageRef.attributes.name != null && this.pageRef.attributes.name != undefined){
            nameUrl = this.pageRef.attributes.name;
        }

        if(nameUrl == 'specialAcceptance__c'){
            ///portal/s/specialAcceptance
            let param = 's__id';
            let paramValue = null;

            if(currentUrl != undefined && currentUrl != null){
                paramValue = currentUrl[param];
            }

            if(paramValue != null){
                let parameters = paramValue.split("-");

                if(parameters[0] != undefined){
                    this.valueUwYear = parameters[0];
                }

                if(parameters[1] != undefined){
                    this.valuePrincipalCedComp = parameters[1];
                }

                if(parameters[2] != undefined){
                    this.valueReinsurer = parameters[2];
                }

                this.getRequestsInfoFilter();  
            }
        }

        getAccPortal()
        .then(resultPortal => {
            this.cedingAccOpt = resultPortal;

            if(this.cedingAccOpt.length > 0 && (this.valuePrincipalCedComp == undefined || this.valuePrincipalCedComp == null)){
                this.valuePrincipalCedComp = this.cedingAccOpt[0].value;
            }

            this.getRequestsInfoFilter();
        })
        .catch(error => {
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error'}), );
        });
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: UWYEAR_FIELD})
    setPicklistOptions({error, data}) {
        if(data){
            this.uwYearOpt = data.values;

            if(this.valueUwYear == undefined || this.valueUwYear == null){
                this.valueUwYear = data.values[data.values.length - 1].value;
            }
            
            this.getRequestsInfoFilter();
        }
        else{
            this.error = error;
        }
    }

    @wire(checkBroker)
    wiredCheckBroker(result){
        if(result.data) {
            this.valIsBroker = result.data;
            this.error = undefined;
            this.getRequestsInfoFilter();
        }
        else if (result.error) {
            this.error = result.error;
        }
    }

    getRequestsInfoFilter(){
        this.spinner = true;
        getRequestsInfoFilter({reinsurerId: this.valueReinsurer, isBroker: this.valIsBroker, uwYear: this.valueUwYear, pcc: this.valuePrincipalCedComp})
        .then(result => {
            this.spinner = true;
            let reinsurerOpt = [];
            let reinsurerOptAll = [];
            let all = { label: "All", value:"All" };
            reinsurerOptAll.push(all);
            let resultReinsurerOpt = result.reinsurerOptionsAll;

            for(let i = 0; i < resultReinsurerOpt.length; i++){
                reinsurerOpt.push(resultReinsurerOpt[i]);
                reinsurerOptAll.push(resultReinsurerOpt[i]);
            }

            this.reinsurerOptionsAll = reinsurerOptAll;

            if(this.valueReinsurer == undefined || this.valueReinsurer == null){
                this.valueReinsurer = 'All';
            }

            this.lstRequests = result.lstRequests;
            
            // Not answered - red
            // Agreed - green
            // Refused	- green
            // Pending	- Orange/Yellow
            // Timeout	- grey
            // Notified - green
            // RRA - 1045
            let defaultIcon = 'slds-icon slds-icon-text-default slds-icon_x-small'; //grey
            let errorIcon = 'slds-icon slds-icon-text-error slds-icon_x-small'; //red
            let successIcon = 'slds-icon slds-icon-text-success slds-icon_x-small'; //green
            let warningIcon = 'slds-icon slds-icon-text-warning slds-icon_x-small'; //yellow
            // let orangeIcon = 'orangeIcon slds-icon--medium';
            let lstUpdRequests = [];

            for(let i = 0; i < this.lstRequests.length; i++){
                let row = {...this.lstRequests[i]};
                let lstSaRequests = row.lstRequests;
                let lstUpdSaRequests = [];

                for(let j = 0; j < lstSaRequests.length; j++){
                    let rowSaReq = {...lstSaRequests[j]};

                    if(rowSaReq['SA_Request_Status__c'] == 'Sent'){
                        rowSaReq['classStatusIcon'] = errorIcon;
                        rowSaReq['statusMsg'] = 'Not Answered';
                    }
                    else if(rowSaReq['SA_Request_Status__c'] == 'Agreed' || rowSaReq['SA_Request_Status__c'] == 'Refused' || rowSaReq['SA_Request_Status__c'] == 'Notified'){
                        rowSaReq['classStatusIcon'] = successIcon;
                        rowSaReq['statusMsg'] = rowSaReq['SA_Request_Status__c'];
                    }
                    else if(rowSaReq['SA_Request_Status__c'] == 'Timeout'){
                        rowSaReq['classStatusIcon'] = defaultIcon;
                        rowSaReq['statusMsg'] = rowSaReq['SA_Request_Status__c'];
                    }
                    else if(rowSaReq['SA_Request_Status__c'] == 'More Infor Required'){
                        rowSaReq['classStatusIcon'] = warningIcon;
                        rowSaReq['statusMsg'] = 'Pending';
                    }
                    else{
                        rowSaReq['statusMsg'] = rowSaReq['SA_Request_Status__c'];
                    }

                    if(rowSaReq.Special_Acceptance__r != undefined){
                        rowSaReq['saName'] = rowSaReq.Special_Acceptance__r.SpecialAcceptanceName__c;

                        if(rowSaReq.Special_Acceptance__r.Bound__c == '1'){
                            rowSaReq['bindStatus'] = 'Yes';
                        }
                        else if(rowSaReq.Special_Acceptance__r.Bound__c == '2'){
                            rowSaReq['bindStatus'] = 'No';
                        }
                        else{
                            rowSaReq['bindStatus'] = 'Pending';
                        }
                    }

                    let respondOnBehalfLink = '/portal/s/SARespondOnBehalf?s__id='+rowSaReq.Special_Acceptance__c+'-'+this.valueUwYear+'-'+this.valuePrincipalCedComp+'-'+rowSaReq.Program__c+'-'+rowSaReq.Broker__c+'-'+rowSaReq.Reinsurer__c+'-undefined-portalBR-undefined-'+rowSaReq.Id;
                    rowSaReq['respondOnBehalfLink'] = respondOnBehalfLink;
                    lstUpdSaRequests.push(rowSaReq);
                }

                let rowUpd = {};
                rowUpd['reinsurerName'] = row.reinsurerName;
                rowUpd['lstSaRequests'] = lstUpdSaRequests;
                lstUpdRequests.push(rowUpd);
            }

            this.lstRequests = lstUpdRequests;
            this.lstRequests = this.sortData('reinsurerName', 'asc', this.lstRequests); 
            this.error = undefined;
            this.spinner = false;
        })
        .catch(error => {
            this.error = error;
            this.spinner = false;
        });
    }

    handleChangeUWYr(event){
        this.valueUwYear = event.detail.value;
        this.valueReinsurer = null;
        this.getRequestsInfoFilter();
    }

    handleChangePCC(event){
        this.valuePrincipalCedComp = event.detail.value;
        this.valueReinsurer = null;
        this.getRequestsInfoFilter();
    }

    handleChangeReinsurer(event){
        this.valueReinsurer = event.detail.value;
        this.getRequestsInfoFilter();
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