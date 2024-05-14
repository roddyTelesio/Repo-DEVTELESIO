/**
 * An apex page controller that takes the user to the right start page based on credentials or lack thereof
 */
@IsTest 
public with sharing class CommunitiesLandingControllerTest {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Test class for CommunitiesLandingController
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 12-MAR-2021  NBI   1.0      Initial version (Standard class - modified)
--------------------------------------------------------------------------------------
**************************************************************************************/

    static User testUserAdmin;
    static List<User> lstPortalUser = new List<User>();
    static List<Account> lstAccount;
    static List<Contact> lstContact;
    static Map<String, Id> mapAccountRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectAcc});

    static {
        //create User
        testUserAdmin = TestFactory.createUserWithRole('testUserAdmin', TestFactory.getProfileAdminId(), TestFactory.getCERoleId());
        testUserAdmin.BypassTrigger__c = 'AP44_CreateSharingForUser';
        insert testUserAdmin;

        System.runAs(testUserAdmin){
            Map<String, Id> mapRequestRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});

            //create Account
            lstAccount = new List<Account> {
                    TestFactory.createAccount(mapAccountRecTypeId.get(AP_Constant.accRTPrincipalCedingCom),'Account A','C_0001'),
                    TestFactory.createAccount(mapAccountRecTypeId.get(AP_Constant.accRTPrincipalCedingCom),'Account B','C_0002'),
                    TestFactory.createAccount(mapAccountRecTypeId.get(AP_Constant.accRTCoveredCedingCompany),'Account C','C_0003'),
                    TestFactory.createAccount(mapAccountRecTypeId.get(AP_Constant.accRTCoveredCedingCompany),'Account D','C_0004'),
                    TestFactory.createAccount(mapAccountRecTypeId.get(AP_Constant.accRTBroker),'Account E','C_0005'),
                    TestFactory.createAccount(mapAccountRecTypeId.get(AP_Constant.accRTReinsurer),'Account F','C_0006'),
                    TestFactory.createAccount(mapAccountRecTypeId.get(AP_Constant.accRTBroker),'Broker A','C_0007'),
                    TestFactory.createAccount(mapAccountRecTypeId.get(AP_Constant.accRTBroker),'Broker B','C_0008'),
                    TestFactory.createAccount(mapAccountRecTypeId.get(AP_Constant.accRTReinsurer),'Reinsurer A','C_0009')
            };
            insert lstAccount;

            //create Ceding Portal Contact + Broker/Reinsurer Contact
            lstContact = new List<Contact> {
                    TestFactory.createContact('Account E - Covered Ceding', 'CedingPortal', lstAccount[2].Id, '2', '25009'),
                    TestFactory.createContact('Account E - Broker', 'BrokerPortal', lstAccount[4].Id, '2', '25009'),
                    TestFactory.createContact('Account F - Reinsurer', 'ReinsurerPortal', lstAccount[5].Id, '2', '25009')
            };

            lstContact[0].Email = 'test@test.com';
            lstContact[1].Email = 'test@test.com';
            lstContact[2].Email = 'test@test.com';
            insert lstContact;

            lstPortalUser = new List<User>{
                    TestFactory.createUser('testUserCedingPortal', TestFactory.getProfileInternalId()),
                    TestFactory.createUser('testUserBrokerPortal', TestFactory.getProfileExternalId()),
                    TestFactory.createUser('testUserReinsurerPortal', TestFactory.getProfileExternalId())
            };

            lstPortalUser[0].ContactId = lstContact[0].Id;
            lstPortalUser[1].ContactId = lstContact[1].Id;
            lstPortalUser[2].ContactId = lstContact[2].Id;
            lstPortalUser[0].BypassTrigger__c = 'AP44_CreateSharingForUser';
            lstPortalUser[1].BypassTrigger__c = 'AP44_CreateSharingForUser';
            lstPortalUser[2].BypassTrigger__c = 'AP44_CreateSharingForUser';

            insert lstPortalUser;
        }
    }

    /*
    public static void testCommunitiesLandingController() {
        // Instantiate a new controller with all parameters in the page
        CommunitiesLandingController controller = new CommunitiesLandingController();
        PageReference pageRef = controller.forwardToStartPage();
        //PageRef is either null or an empty object in test context
        if(pageRef != null){
            String url = pageRef.getUrl();
            if(url != null){
//                System.assertEquals(true, String.isEmpty(url));
                //show up in perforce
            }
        }
    }*/
    
    @IsTest 
    public static void testCommunitiesLandingControllerCeding(){
        System.runAs(lstPortalUser[0]) {
            Test.startTest();
            	CommunitiesLandingController controller = new CommunitiesLandingController();
            	CommunitiesLandingController.url = 'https://axa-re.force.com/cedingPortal/s/login/';
        		PageReference pageRef = controller.forwardToStartPage();
        		if(pageRef != null){
            		String url = pageRef.getUrl();
            		if(url != null){
		                System.assertEquals(false, String.isEmpty(url));
            		}
       		}
            Test.stopTest();
        }
    }
    
    @IsTest 
    public static void testCommunitiesLandingControllerBroker(){
        System.runAs(lstPortalUser[1]) {
            Test.startTest();
            	CommunitiesLandingController controller = new CommunitiesLandingController();
            	CommunitiesLandingController.url = 'https://axa-re.force.com/portal/s/login/';
        		PageReference pageRef = controller.forwardToStartPage();
        		if(pageRef != null){
            		String url = pageRef.getUrl();
            		if(url != null){
		                System.assertEquals(false, String.isEmpty(url));
            		}
       		}
            Test.stopTest();
        }
    }
    
    @IsTest 
    public static void testCommunitiesLandingControllerReins(){
        System.runAs(lstPortalUser[2]) {
            Test.startTest();
            	CommunitiesLandingController controller = new CommunitiesLandingController();
            	CommunitiesLandingController.url = 'https://axa-re.force.com/portal/s/login/';
        		PageReference pageRef = controller.forwardToStartPage();
        		if(pageRef != null){
            		String url = pageRef.getUrl();
            		if(url != null){
		                System.assertEquals(false, String.isEmpty(url));
            		}
       		}
            Test.stopTest();
        }
    }
}