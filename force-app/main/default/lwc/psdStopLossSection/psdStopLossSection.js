import {
    LightningElement,
    api
} from 'lwc';

export default class PsdStopLossSection extends LightningElement {
    //public properties
    @api sectionRequest;
    @api readOnly = false;
    @api currencyOpt;
    @api natureOpt;
}