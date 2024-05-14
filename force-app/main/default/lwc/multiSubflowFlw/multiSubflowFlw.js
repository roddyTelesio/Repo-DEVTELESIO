/**
 * @description       : 
 * @author            : Patrick Randrianarisoa
 * @group             : 
 * @last modified on  : 31-01-2024
 * @last modified by  : Patrick Randrianarisoa
 * Modifications Log
 * Ver   Date         Author                   Modification
 * 1.0   26-01-2024   Patrick Randrianarisoa   Initial Version
**/
import { LightningElement, track, api } from 'lwc';

export default class MultiSubflowFlw extends LightningElement {

    @track flowInstances = [];
    @track completedFlowCount = 0;
    @track renderFlow = false; 
    @api recordIds;

    @track inputVariable = [];

    connectedCallback() {
        console.log('PRA renderFlow');
        console.log(this.renderFlow);
        this.initializeFlowInstances();
    }
  
    initializeFlowInstances() {
        console.log('recordIds: ' , this.recordIds);
        this.renderFlow = true;
        let recIds = this.recordIds ? this.recordIds.split(',') : [];


        /*SBH COMMENT
        console.log('recIds ' , recIds);
        this.flowInstances = recIds.map((recordId, index) => ({
            key: 'flowInstance_' + index,
            recordId: recordId,
            inputVariables : [{ name: 'AgreementId', type: 'String', value: recordId }]
        }));

        console.log('flowInstance: ' , this.flowInstances);*/

        this.inputVariable = [{ name: 'AgreementIdList', type: 'String', value: recIds }]
        this.renderFlow = true; 
    }
  
    renderedCallback() { 
    //   this.flowInstances.forEach(instance => {
    //     const flowElement = this.template.querySelector(`[data-key="${instance.key}"]`);
    //     const inputVariables = [{ name: 'AgreementId', type: 'String', value: instance.recordId }];
    //     console.log('inputVariables : ', inputVariables);
    //     if (flowElement) {
    //       flowElement.startFlow('CLM_Subflow_update_treatyref_on_agreement', inputVariables);
    //     }
    //   });
        // this.initializeFlowInstances();
    }

    handleFlowStatusChange(event) {
        console.log('Flow Status Change Event:');
        console.log('Flow Status Change Event:', event.detail);
        const flowInstanceKey = event.target.dataset.key;
        const flowStatus = event.detail.status;

        if (flowStatus === 'FINISHED_SCREEN') {
            console.log('Flow Finished - Triggering handleFlowFinish');
            //window.location.reload();
            this.handleFlowFinish({ target: { dataset: { key: flowInstanceKey } } });
        }
    }

  
    handleFlowFinish(event) {
        console.log('Handling Flow Finish Event:', event);
        const finishedFlowKey = event.target.dataset.key;
        const finishedFlowInstance = this.flowInstances.find(instance => instance.key === finishedFlowKey);
    
        if (finishedFlowInstance) {
            finishedFlowInstance.completed = true;
            this.completedFlowCount++;
        
            console.log('Completed Flow Count:', this.completedFlowCount);
        
            if (this.completedFlowCount === this.flowInstances.length) {
                console.log('All flows have finished running. Dispatching "allflowsfinished" event.');
                this.dispatchEvent(new CustomEvent('allflowsfinished'));
            }
        }
    }

}