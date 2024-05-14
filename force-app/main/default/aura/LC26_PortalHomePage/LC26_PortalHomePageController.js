({
    navigate : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
        var urlEvent = $A.get("e.force:navigateToURL");
        var recId = window.location.href.split("/").pop();
        urlEvent.setParams({
              "url": "/summary"
            });
        urlEvent.fire();
    },
    fetchAccounts : function(component, event, helper) {
        component.set('v.mycolumns', [
            {label: 'Account Name', fieldName: 'linkName', type: 'url',
            typeAttributes: {label: { fieldName: 'Name' }, target: '_self'}},
            {label: 'Industry', fieldName: 'Industry', type: 'text'},
            {label: 'Type', fieldName: 'Type', type: 'Text'},
            {label: 'Type', fieldName: 'Type', type: 'Text'}
        ]);
        var action = component.get("c.getRequestsInfoTwo");
        action.setParams({
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                var records =response.getReturnValue();
                records.forEach(function(record){
                    record.linkName = '/portal/s/summary';
                });
                component.set("v.acctList", records);
            }
        });
        $A.enqueueAction(action);
    }
})