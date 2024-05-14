({
    init : function(component){
        var userInfo = component.get("c.getUserDetails");
        userInfo.setCallback(this, function(response){
            var state = response.getState();
            if(component.isValid() && state === "SUCCESS") {
                let userObj  = response.getReturnValue();
                if(userObj.SmallPhotoUrl != null || userObj.SmallPhotoUrl != ""){
                    component.set("v.photo" , true);
                }
                else{
                    component.set("v.photo" , false);
                }
                component.set("v.UserInfo" , userObj);
            }
        });
        $A.enqueueAction(userInfo)

        var portalInfo = component.get("c.getPortalURL");
        portalInfo.setCallback(this, function(response){
            var state = response.getState();
            if(component.isValid() && state === "SUCCESS") {
                component.set("v.portalURL" ,response.getReturnValue());
            }
        });
        $A.enqueueAction(portalInfo)
    }
})