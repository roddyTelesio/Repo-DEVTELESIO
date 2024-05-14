import {LightningElement, api,wire} from 'lwc';
import {NavigationMixin } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';

export default class Lwc01CallFlowHazardBassin extends NavigationMixin (LightningElement) {
    
    @api recordId
    @wire(getRecord, { recordId: '$recordId', layoutTypes: ['Full'], modes: ['View']})section; // MRA NEREE 31/08/2022 Control on subsection creation button
    //Navigate to flow page
    handleGenerateHazardBassin() {
        //this.saveSection();
        console.log('START button Flow HB');
        console.log('recordId == ',this.recordId);
         // MRA NEREE 31/08/2022 Control on subsection creation button : START
        if (this.section.data.apiName === 'Section__c' && this.section.error === undefined) {
            this[NavigationMixin.GenerateUrl]({
                type: 'standard__webPage',
                attributes: {
                    url: '/lightning/cmp/c__sfpegFlowEmbed_CMP?c__flow=Subsection_Creation_Hazard_Bassins&c__recordId='+ this.recordId +'&c__target=targetId&c__label=GenerateHazardBassin'
                }
            }).then(generatedUrl => {
                //console.log('generatedUrl == ',generatedUrl);
                window.open(generatedUrl);
        });

    }
        else{
        this.dispatchEvent(new ShowToastEvent({title: 'Save your section', message: 'Please save your section before generating Subsections', variant: 'error'}), );
        }
    // MRA NEREE 31/08/2022 Control on subsection creation button : END
    console.log('END button Flow HB');
    }
}