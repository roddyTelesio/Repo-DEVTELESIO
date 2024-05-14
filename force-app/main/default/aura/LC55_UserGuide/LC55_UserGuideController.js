({
    doInit: function(component, event, helper) {
        var pageReference = component.get("v.pageReference");
        var idFile = $A.get("$Label.c.Actor_New_Gen_User_guide");
        console.log('idFile == ', idFile);
        var openPreview = $A.get('e.lightning:openFiles');
        openPreview.fire({
            recordIds: [idFile]
        });
    },
    reInit : function(component, event, helper) {
        var pageReference = component.get("v.pageReference");
        $A.get('e.force:refreshView').fire();
    }
})