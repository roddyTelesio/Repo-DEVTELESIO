({
    doInit: function(component, event, helper) {
        var pageReference = component.get("v.pageReference");
    },

    reInit : function(component, event, helper) {
        var pageReference = component.get("v.pageReference");
        //RRA - ticket 585 - 09/03/2023
        //$A.get('e.force:refreshView').fire();
        window.location.reload(true);
    }
});