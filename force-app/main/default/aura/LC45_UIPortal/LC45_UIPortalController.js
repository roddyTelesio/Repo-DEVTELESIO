({
    doInit : function(component, event, helper){
        helper.init(component);
	}

    ,handleClick : function(component, event, helper) {
        var source = event.getSource();
        var label = source.get("v.label");
        if(label=="Home"){
            var value = component.get("v.portalURL");
            var urlEvent = $A.get("e.force:navigateToURL");
            urlEvent.setParams({
                "url": value
            });

            urlEvent.fire();
        }
        else if(label=="My Profile"){
            var value = component.get("v.portalURL") + 'profile/' + component.get("v.UserInfo.Id");
            // var value = component.get("v.portalURL") + 'profile/0056E000006t75J';
            var urlEvent = $A.get("e.force:navigateToURL");
            urlEvent.setParams({
                "url": value
            });

            urlEvent.fire();
        }
        else if(label=="My Account"){
            var value = component.get("v.portalURL") + 'detail/'+ component.get("v.UserInfo.Contact.AccountId");
            var urlEvent = $A.get("e.force:navigateToURL");
            urlEvent.setParams({
                "url": value
            });

            urlEvent.fire();
        }
        else if(label=="Logout"){
            var value = component.get("v.portalURL") + 'login/';
            var urlEvent = $A.get("e.force:navigateToURL");
            urlEvent.setParams({
                "url": value
            });

            urlEvent.fire();
        }
    }
})