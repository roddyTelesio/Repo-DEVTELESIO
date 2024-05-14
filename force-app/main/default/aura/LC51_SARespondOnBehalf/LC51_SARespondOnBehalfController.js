({
    doInit: function(component, event, helper) {
        var pageReference = component.get("v.pageReference");
    }
    ,reInit : function(component, event, helper) {
        var pageReference = component.get("v.pageReference");
        $A.get('e.force:refreshView').fire();
    }
    ,closeModal: function(component, event, helper) {
        var closeRecordUrl = window.location.href;
        var closeRecordUrlId = closeRecordUrl.split('=')[1];
        var closeRecordId = closeRecordUrlId.split('-');
        // var urlPage = '../n/SpecialAcceptance?s_id=' +closeRecordId[0]+'-'+closeRecordId[1]+'-'+closeRecordId[2]+'-'+closeRecordId[3];

        // console.log('## urlPage', urlPage);
        // var navService = component.find("closeLoadSARequestModal");
        // var pageReference = {
        //     "type": "standard__webPage",
        //     "attributes": {url: urlPage, target: '_self'}
        // };
        // navService.navigate(pageReference);

        return false;
    }
});