import { LightningElement, api} from 'lwc';
 
export default class PsdQuotaShareSectionAXAXLQS extends LightningElement {
     //public properties
     @api sectionRequest;
     @api readOnly = false;
     @api currencyOpt;
     @api natureOpt;
}