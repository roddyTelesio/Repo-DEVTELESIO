/**************************************************************************************
-- - Author        : Telesio
-- - Description   : Controller for Lightning Web Component LWC61_PreviewDownloadFile
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 17-OCT-2023  RRA   1.0      Ticket 1675 - Initial version
--------------------------------------------------------------------------------------
**************************************************************************************/
import { LightningElement, api, wire } from 'lwc';
import getRelatedFiles from '@salesforce/apex/LWC61_FilePreviewDownload.getRelatedFiles';
import {NavigationMixin} from 'lightning/navigation';
export default class Lwc61GeneralConditions extends NavigationMixin(LightningElement) {
    @api filesList =[];
    @api file;
    
    @wire(getRelatedFiles)
    wiredResult({data, error}){ 
        console.log('data 00== ', data);                        
        if(data){ 
            this.filesList = Object.keys(data.mapIdTitle).map(item=>({
            "label":data.mapIdTitle[item],
            "color":data.mapIdColorSize[item],
            "size" : (data.mapIdSize[item] / 1000000).toFixed(2)+ ' Mo',
            "value": item,
            "idConv":data.mapIdContIdConv[item],
            "url": "../sfc/servlet.shepherd/document/download/"+ item+"?operationContext=S1"
            }))
            
            console.log('filesList== ', this.filesList);
        }
        if(error){ 
            console.log(error)
        }
    }
    
    previewHandler(event){
        console.log(event.target.dataset.id)
        let baseUrl= 'https://'+ location.host;
        baseUrl = baseUrl.replace ('sandbox.my.site.com', 'sandbox.lightning.force.com')
        this[NavigationMixin.Navigate]({ 
            type:'standard__webPage',
            attributes:{ 
                //pageName:'filePreview'
                url: baseUrl + '/sfc/servlet.shepherd/version/renditionDownload?rendition=THUMB720BY480&versionId=' + event.target.dataset.id
            }
         }, false );
        
    }
}