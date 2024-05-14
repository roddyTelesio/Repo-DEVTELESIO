// agreementCheckInListener.js
import { LightningElement, wire, api, track } from 'lwc';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

const AGREEMENT_OBJECT = 'Apttus__APTS_Agreement__c'; // Replace with your custom object API name
const AGREEMENT_ID_FIELD = 'Id'; // Replace with your field API name

export default class CheckInEventListener extends LightningElement {
    @api recordId;
    @track channelName = '/event/AgreementCheckIn__e';
    subscription = null;

    // Retrieve the AgreementId__c field value for the current record
    @wire(getRecord, { recordId: '$recordId', fields: [AGREEMENT_OBJECT + '.' + AGREEMENT_ID_FIELD] })
    agreementRecord;

    // Callback to handle received events
    handleAgreementCheckIn(event) {

        console.log('handleAgreementCheckIn: Start');
        const agreementId = getFieldValue(this.agreementRecord.data, AGREEMENT_OBJECT + '.' + AGREEMENT_ID_FIELD);
        const eventAgreementId = event.data.payload.AgreementId__c;
        console.log('handleAgreementCheckIn: agreementId ', agreementId);
        console.log('handleAgreementCheckIn: eventAgreementId ', eventAgreementId);
        if (agreementId === eventAgreementId) {
            // Refresh the current Lightning page if AgreementId__c matches
            location.reload();
        }
    }

    // Subscribe to the platform event when the component is connected
    connectedCallback() {
        this.subscribeToPlatformEvent();
    }

    // Unsubscribe from the platform event when the component is disconnected
    disconnectedCallback() {
        this.unsubscribeFromPlatformEvent();
    }

    // Subscribe to the platform event
    subscribeToPlatformEvent() {
        // Define the callback to handle received events
        const messageCallback = (response) => {
            console.log('subscribeToPlatformEvent:subscribeToPlatformEvent messageCallback response ', response);
            this.handleAgreementCheckIn(response);
        };

        // Subscribe to the event channel
        subscribe(this.channelName, -1, messageCallback).then((response) => {
            console.log('subscribeToPlatformEvent:subscribeToPlatformEvent messageCallback subscribe resp', response);
            this.subscription = response;
        });
    }

    // Unsubscribe from the platform event
    unsubscribeFromPlatformEvent() {
        if (this.subscription) {
            unsubscribe(this.subscription, (response) => {
                console.log('Unsubscribed from: ' + this.channelName);
            });
        }
    }
}