({
    doInit: function(component, event, helper) {
        //window.location.href --- old line 
        //Changes done due to issues after Summer '21
        var recordUrlId = component.get("v.pageReference").state.c__id;
        var parameters = recordUrlId.split('-');
        var recordId = parameters[0];
        var reinsurerStatus = parameters[9];

        component.set("v.treatyId", parameters[5]);
        component.set("v.brokerId", parameters[6]);
        component.set("v.reinsurerId", parameters[7]);
        component.set("v.reinsurerStatus", parameters[8]);
        component.set("v.record", recordId);
        component.set("v.displayRespondOnBehalf", true);
    }
    ,closeModal: function(component, event, helper) {
        var closeRecordUrl = window.location.href;
        var closeRecordUrlId = closeRecordUrl.split('=')[1];
        var closeRecordId = closeRecordUrlId.split('-');
        var treatyId = closeRecordId[5];
        var brokerId = closeRecordId[6];
        var reinsurerId = closeRecordId[7];
        var reinsurerStatus = closeRecordId[8];

        var urlPage = '../n/TreatyPlacement?c__program=' +closeRecordId[1]+'-'+closeRecordId[2]+'-'+closeRecordId[3]+'-'+closeRecordId[4]+'-'+treatyId+'-'+brokerId+'-'+reinsurerId+'-'+reinsurerStatus;
        var navService = component.find("closeRespondOnBehalfModal");
        var pageReference = {
            "type": "standard__webPage",
            "attributes": {url: urlPage, target: '_self'}
        };
        navService.navigate(pageReference);

        return false;
    }
    ,reInit : function(component, event, helper) {
        var pageReference = component.get("v.pageReference");
        $A.get('e.force:refreshView').fire();
    }
});