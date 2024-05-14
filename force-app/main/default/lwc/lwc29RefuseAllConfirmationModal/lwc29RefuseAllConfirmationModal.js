import {
    LightningElement,
    api
} from 'lwc';

import saveRequestRecord from '@salesforce/apex/LWC29_AnswerRequests.saveRequestRecord';
import saveRequest from '@salesforce/apex/LWC17_RespondOnBehalf.saveRequestRecord';

import {
    NavigationMixin
} from 'lightning/navigation';

import {
    ShowToastEvent
} from 'lightning/platformShowToastEvent';

import errorMsg from '@salesforce/label/c.errorMsg';
import RespondOnBehalfSavedSuccessfully from '@salesforce/label/c.RespondOnBehalfSavedSuccessfully';

export default class Lwc29RefuseAllConfirmationModal extends NavigationMixin(LightningElement) {
    //public properties
    @api refusalOptions;
    @api phase;
    @api allRequests;
    @api sectionReq;
    @api isPortal = false;

    //exposed properties
    isLoading = false;

    //private properties
    label = {
        errorMsg,
        RespondOnBehalfSavedSuccessfully
    }

    //save user response and close modal
    saveResponse() {
        //check if mandatory field is filled
        let isMandatoryFieldValid = this.validateInput();

        if (isMandatoryFieldValid) {
            //show loading
            this.isLoading = true;

            //final response to send for save
            let reqToSend = [];

            //get picklist value
            let reason = this.template.querySelector("[data-id='Reason Refusal']").value;

            //get comments value
            let comm = this.template.querySelector("[data-id='Comment Resp']").value;

            if (this.phase === 'Quote') {
                //loop in all requests for given program
                this.allRequests.map(ele => {
                    reqToSend.push({
                        ...ele,
                        Quote__c: '2',
                        ReasonRefusal__c: reason,
                        CommentsResponse__c: comm != null ? comm : ' '
                    });
                });

                if (this.isPortal) {
                    //send for database processing
                    this.databaseImplicitSaveForPortal(reqToSend, this.phase, []);
                } else {
                    //send for database processing
                    this.databaseImplicitSaveForInternal(reqToSend, this.phase, []);
                }
            } else {
                this.sectionReq.map(ele => {
                    reqToSend.push({
                        ...ele.parentRequest,
                        PlacementParticipation__c: '2',
                        ReasonRefusal__c: reason,
                        CommentsResponse__c: comm != null ? comm : ' '
                    });
                });

                if (this.isPortal) {
                    //send for database processing
                    this.databaseImplicitSaveForPortal(this.allRequests, this.phase, reqToSend);
                } else {
                    //send for database processing
                    this.databaseImplicitSaveForInternal(this.allRequests, this.phase, reqToSend);
                }
            }
        } else {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: this.label.errorMsg,
                variant: 'error'
            }), );
        }
    }

    //save request to data base  when on portal
    databaseImplicitSaveForPortal(listReqToUpdate, Phase, listParentReq) {
        saveRequestRecord({
                lstRequest: listReqToUpdate,
                phaseType: Phase,
                lstParentRequest: listParentReq,
                btnName: 'Send',
                quotedeadline: null,  //RRA - ticket 1574 - 02112023
                isChangedDateQuote: false,  //RRA - ticket 1574 - 02112023
                idRequestSelected: null, //RRA - ticket 1574 - 02112023
                isPortalAccess: true //RRA - ticket 1574 - 02112023
            })
            .then(result => {
                //stops loading
                this.isLoading = false;

                if (result.hasOwnProperty('Error') && result.Error) {
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Error',
                        message: result.Error,
                        variant: 'error'
                    }), );
                } else {
                    //notify parent to send mail
                    this.notifyParentToSendMail(result);

                    //close modal
                    this.closeComponent();
                }
            })
            .catch(error => {
                //stops loading
                this.isLoading = false;

                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: this.label.errorMsg,
                    variant: 'error'
                }), );
            });
    }

    //save request to data base  when on actor new gen
    databaseImplicitSaveForInternal(listReqToUpdate, Phase, listParentReq) {
        saveRequest({
                lstRequest: listReqToUpdate,
                phaseType: Phase,
                lstParentRequest: listParentReq,
                selectIdRequest: null, //RRA - ticket 1404 - 20022023 - Add this parameter for modif of 1404 ticket
                quotedeadline : null, //RRA - ticket 1574 - 02112023
                isChangedDateQuote : false //RRA - ticket 1574 - 02112023
            })
            .then(result => {
                //stops loading
                this.isLoading = false;

                if (result.hasOwnProperty('Error') && result.Error) {
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Error',
                        message: result.Error,
                        variant: 'error'
                    }), );
                } else {
                    //display status
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Success',
                        message: this.label.RespondOnBehalfSavedSuccessfully,
                        variant: 'success'
                    }), );

                    //close refuse all component
                    this.closeComponent();
                }
            })
            .catch(error => {
                //stops loading
                this.isLoading = false;

                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: this.label.errorMsg,
                    variant: 'error'
                }), );
            });
    }

    //validate mandatory field
    validateInput() {
        return [...this.template.querySelectorAll('lightning-combobox')]
            .reduce((validSoFar, inputCmp) => {
                inputCmp.reportValidity();
                return validSoFar && inputCmp.checkValidity();
            }, true);
    }

    //notify parent component to close modal
    closeComponent() {
        this.dispatchEvent(new CustomEvent('closecomponent'));
    }

    //notify parent component to send mail
    notifyParentToSendMail(resp) {
        this.dispatchEvent(new CustomEvent('sendmail', {
            detail: resp
        }));
    }

    //refresh parent component for respond on behalf
    refreshParentComp() {
        this.dispatchEvent(new CustomEvent('refresh'));
    }
}