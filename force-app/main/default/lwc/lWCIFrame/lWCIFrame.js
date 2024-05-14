import { api, LightningElement } from 'lwc';

export default class LWCIFrame extends LightningElement {
  @api height = '500px';
  @api referrerPolicy = 'no-referrer';
  @api sandbox = '';
  @api url = '';
  @api width = '100%';
  
}