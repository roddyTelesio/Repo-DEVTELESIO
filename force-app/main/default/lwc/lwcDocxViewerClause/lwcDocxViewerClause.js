import { LightningElement,api } from 'lwc';
import getDocumentDetails from '@salesforce/apex/LWCDOCVIEWER_SVC.getDocumentDetails';

export default class LwcDocxViewerClause extends LightningElement {
@api downloadUrl ;
@api docName ;
@api recordId ;
showClauseOnly = false ; 

connectedCallback(){
    getDocumentDetails({processId: this.recordId})
    .then(result => {
        if(!result.error){
            if(result.ObjectName === 'Apttus__APTS_Template__c' && result.tempType === 'Clause'){
                this.showClauseOnly = true ;
                this.downloadUrl = '/servlet/servlet.FileDownload?file=' + result.attach.Id ;
                this.docName = result.attach.Name ; 
            }
        }
        else {
            console.log('## ERROR = ' + result.error)
        }
    }).catch(error2 => {
        console.log('## ERROR = ', JSON.stringify(error2)) ;
    }); ;
}

}