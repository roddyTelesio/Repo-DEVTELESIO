({
    doInit: function(component, event, helper) {
        var pageReference = component.get("v.pageReference");
    },

    reInit : function(component, event, helper) {
        var pageReference = component.get("v.pageReference");
        $A.get('e.force:refreshView').fire();
    }
});